use strict;
use warnings;
use lib 'perl', 't/lib';
use Test::More;
use JSON::PP;
use Digest::SHA qw(sha256_hex);
use File::Path qw(make_path);
use File::Spec;
use File::Temp qw(tempdir);
use FSM::Test::ProjectDataLocality;
use FSM::Test::DiagnosticCause qw(diagnostic_cause_matches);
use FSM::Scheduler::ISF;
use FSM::Test::ConditionalOriginAuthority;
use FSM::Test::LibraryDocumentOriginAuthority;
use FSM::Test::ATLDocumentOriginAuthority;

# These immutable fixtures were qualified through actual producers and a
# separate source/cause oracle. Never write into the archived document set.
my $fixture = 'docs/audits/source-origin-validator-causes-20261003';
my $json = JSON::PP->new->canonical;
my $inputs = read_json("$fixture/inputs.json");
my $bindings = read_json("$fixture/bindings.json");
my @contexts = @{read_json("$fixture/products.json")->{contexts}};
require "./$fixture/late-packages.pl";
my $workspace = File::Spec->abs2rel(tempdir(CLEANUP => 1));

my $local = $inputs->{local}{product};
my $parser = FSM::Test::ConditionalOriginParser->new;
my $local_actor = $parser->parse_source($local->{source}, $local->{label});
my $local_ledger = $parser->ledger;
my $authority = FSM::Test::ConditionalOriginAuthority->from_source($local->{source}, $local->{label});
my $macro = $inputs->{twin_macro}{product};
my $authored = $inputs->{twin_authored}{product};
my $twin_authority = FSM::Test::ConditionalOriginAuthority->from_source($macro->{source}, $macro->{label});

my (%documents, %authorities, %whole_products);
for my $kind (qw(library ATL)) {
    my $saved = $inputs->{$kind}{product};
    my $directory = "$workspace/$kind";
    make_path($directory);
    my %sources;
    for my $path (sort keys %{$saved->{documents}}) {
        my ($name) = $path =~ m{/([^/]+)$};
        $sources{"$directory/$name"} = $saved->{documents}{$path};
    }
    my $label = "$directory/authority-root.isf";
    write_file($_, $sources{$_}) for grep {$_ ne $label} sort keys %sources;
    $documents{$kind} = [$label, \%sources, [$directory]];
    $authorities{$kind} = $kind eq 'library'
        ? FSM::Test::LibraryDocumentOriginAuthority->from_documents($label, \%sources, [$directory])
        : FSM::Test::ATLDocumentOriginAuthority->from_documents($label, \%sources, [$directory]);
    local $ENV{FSMLIB} = $directory;
    my $ordinary = FSM::Adapter::ISF::Parser->new->parse_source($sources{$label}, $label);
    die 'ordinary whole actor differs' unless $json->encode($ordinary)
        eq $json->encode($authorities{$kind}->actor);
    $whole_products{$kind} = {
        actor => $authorities{$kind}->actor,
        proof => $authorities{$kind}->proof,
        ordinary => $ordinary,
    };
}

is(scalar @contexts, 25, 'complete independently declared validator/finalizer context cohort');
my @products;
for my $context (@contexts) {
    subtest "complete validator/finalizer cause $context->{id}" => sub {
        my @bands = $context->{kind} =~ /_late$/
            ? qw(positive wrong_source_echo wrong_source_plain wrong_label_echo)
            : qw(positive wrong_argument_echo wrong_argument_plain);
        for my $band (@bands) {
            my $payload = payload_for($context, $band);
            # No expected-pattern argument enters the failing real API call.
            my $accepted = eval {invoke($context->{kind}, $payload); 1};
            my $error = $@;
            ok(!$accepted, "$band actually refuses");
            my $matched = diagnostic_cause_matches($error, $context->{expected});
            # Rehost the exact prior consumer only after the producer returns.
            # This is a private falsification mode, not an alternative contract.
            if ($ENV{FSMGEN_VALIDATOR_CAUSE_PRIOR_CONSUMER}) {
                my $diagnostic = $error;
                my $statement = $bindings->{sites}{$context->{site}}{statement};
                $matched = eval 'local $@=$error;' . $statement;
                die $@ if $@;
            }
            is($matched ? 1 : 0, $band eq 'positive' ? 1 : 0,
                "$band authenticates only its complete cause");
            push @products, {
                %$context, band => $band, payload => $payload,
                accepted => $accepted ? 1 : 0, matched => $matched ? 1 : 0,
                error => $error, first_line => (split /\n/, $error)[0] // '',
            };
        }
    };
}
if (my $capture = $ENV{FSMGEN_VALIDATOR_CAUSE_CAPTURE}) {
    write_file("$capture/products.json", $json->encode({
        contexts => \@contexts, products => \@products,
        original => {actor => $local_actor, ledger => $local_ledger},
        documents => \%documents, authorities => \%whole_products,
    }) . "\n");
}
done_testing;

sub payload_for {
    my ($context, $band) = @_;
    my ($kind, $variant) = @$context{qw(kind variant)};
    if ($kind =~ /_late$/) {
        if ($band eq 'positive') {
            return {source => $inputs->{same}{product}{source}, label => 'late.isf', variant => $variant}
                if $kind eq 'same_late';
            return {documents => $documents{$kind eq 'library_late' ? 'library' : 'ATL'}, variant => $variant};
        }
        my $source = $band eq 'wrong_source_echo' ? "; $context->{wanted}\n(not_actor)" : '(not_actor)';
        my $label = $band eq 'wrong_label_echo' ? "$context->{wanted}.isf" : 'wrong.isf';
        return {source => $source, label => $label, documents => [$label, {$label => $source}, []], variant => $variant};
    }
    return {actor => $band eq 'wrong_argument_echo' ? $context->{wanted} : 'unrelated argument', variant => $variant}
        if $band ne 'positive';
    return {source => $inputs->{scheduler}{source}} if $kind eq 'scheduler';
    if ($kind eq 'generic') {
        my $ledger = clone($local_ledger);
        if ($variant eq 'omission') {shift @{$ledger->{entries}}}
        elsif ($variant eq 'duplicate') {push @{$ledger->{entries}}, clone($ledger->{entries}[0])}
        elsif ($variant eq 'wrong_path') {$ledger->{entries}[0]{path}[-1] = 9999}
        elsif ($variant eq 'changed_target') {$ledger->{entries}[0]{target}[1] = 'other'}
        elsif ($variant eq 'forged_origin') {
            $ledger->{entries}[0]{origin}{calls} = [];
            $ledger->{catalog}[$ledger->{entries}[0]{origin}{catalog_id}]{owner}{name} = 'forged';
        }
        elsif ($variant eq 'source_identity') {$ledger->{source_sha256} = '0' x 64}
        elsif ($variant eq 'unknown_field') {$ledger->{entries}[0]{extra} = 1}
        else {$ledger->{schema_version} = '1'}
        return {actor => clone($local_actor), ledger => $ledger};
    }
    if ($kind eq 'local') {
        my ($actor, $ledger) = (clone($local_actor), clone($local_ledger));
        if ($variant eq 'actor') {$actor->{actor_name} = 'forged'}
        else {$ledger->{schema_version} = 9}
        return {actor => $actor, ledger => $ledger};
    }
    if ($kind eq 'twins') {
        my $ledger = clone($authored->{ledger});
        $ledger->{source_sha256} = $macro->{ledger}{source_sha256};
        return {actor => clone($authored->{instrumented}), ledger => $ledger};
    }
    return {actor => clone($local_actor), ledger => clone($local_ledger)} if $kind eq 'missing';
    my ($actor, $proof) = ($authorities{$kind}->actor, $authorities{$kind}->proof);
    if ($variant eq 'actor') {$actor->{actor_name} = 'forged'}
    else {$proof->{schema_version} = 9}
    return {actor => $actor, proof => $proof};
}

sub invoke {
    my ($kind, $payload) = @_;
    if ($kind eq 'scheduler') {
        my $actor = exists($payload->{source})
            ? FSM::Adapter::ISF::Parser->new->parse_source($payload->{source}, 'first_samples.isf')
            : $payload->{actor};
        return FSM::Scheduler::ISF->new->lower($actor);
    }
    if ($kind eq 'generic') {
        return $parser->validate($payload->{actor}, $payload->{ledger}) if exists $payload->{ledger};
        my $ledger = {
            schema_version => 1, actor_sha256 => sha256_hex($json->encode($payload->{actor})),
            source_sha256 => '0' x 64, catalog => [], entries => [], residuals => [],
        };
        return FSM::Test::ConditionalOriginParser->new->validate($payload->{actor}, $ledger);
    }
    if ($kind eq 'local' || $kind eq 'twins') {
        my $verifier = exists($payload->{ledger})
            ? ($kind eq 'twins' ? $twin_authority : $authority)
            : bless({}, 'FSM::Test::ConditionalOriginAuthority');
        return $verifier->validate($payload->{actor}, $payload->{ledger} || {});
    }
    if ($kind eq 'missing') {
        my $verifier = exists($payload->{ledger}) ? bless({}, 'FSM::Test::ConditionalOriginAuthority') : $authority;
        return $verifier->validate($payload->{actor}, $payload->{ledger} || {});
    }
    if ($kind eq 'library' || $kind eq 'ATL') {
        my $verifier = exists($payload->{proof}) ? $authorities{$kind}
            : bless({}, $kind eq 'library' ? 'FSM::Test::LibraryDocumentOriginAuthority' : 'FSM::Test::ATLDocumentOriginAuthority');
        return $verifier->validate($payload->{actor}, $payload->{proof} || {});
    }
    return FSM::Test::LibraryLateTargetMutation->new->parse_source($payload->{source}, $payload->{label})
        if $kind eq 'same_late';
    my $producer = $kind eq 'library_late'
        ? FSM::Test::DocumentLateCloneMutation->new : FSM::Test::ATLLateOriginMutation->new;
    $producer->{mutation} = $payload->{variant};
    local $ENV{FSMLIB} = join ':', @{$payload->{documents}[2]};
    return $producer->parse_documents(@{$payload->{documents}}[0, 1]);
}

sub clone {return $json->decode($json->encode($_[0]))}
sub read_json {
    open my $file, '<:raw', $_[0] or die $!;
    local $/;
    my $value = $json->decode(<$file>);
    close $file or die $!;
    return $value;
}
sub write_file {
    open my $file, '>:raw', $_[0] or die $!;
    print {$file} $_[1] or die $!;
    close $file or die $!;
}
