use strict;
use warnings;
use lib 'perl', 't/lib';
use Test::More;
use JSON::PP;
use Digest::SHA qw(sha256_hex);
use File::Spec;
use File::Temp qw(tempdir);
use FSM::Test::ProjectDataLocality;
use FSM::Test::LibraryDocumentOriginAuthority;
use FSM::Adapter::ISF::Parser;
use Lispish;

{
    package FSM::Test::DocumentSelectedFormMutation;
    use parent -norequire, 'FSM::Test::LibraryDocumentOriginAuthority::Parser';
    sub _parse_library_form {
        my ($self, $form, @args) = @_;
        $form->[1] = 'forged.library';
        return $self->SUPER::_parse_library_form($form, @args);
    }
    package FSM::Test::DocumentLateCloneMutation;
    use parent -norequire, 'FSM::Test::LibraryDocumentOriginAuthority::Parser';
    sub _finalize_actor_crossings {
        my ($self, $actor, @args) = @_;
        my $result = $self->SUPER::_finalize_actor_crossings($actor, @args);
        if ($self->{mutation} eq 'target') {
            $actor->{library_uses}[0]{actor}{transactions}[0]{clauses}[0][1] = 'forged_guard';
        } elsif ($self->{mutation} eq 'instance') {
            $actor->{library_uses}[0]{instance} = 'forged_instance';
        } elsif ($self->{mutation} eq 'coverage') {
            pop @{$actor->{library_uses}};
        } elsif ($self->{mutation} eq 'parameter_kind') {
            $actor->{library_uses}[0]{parameter_overrides}[0]{value} = 2;
        } else {die 'unknown finalization control'}
        return $result;
    }
}

my $json = JSON::PP->new->canonical;
my @boundaries;
my @inputs = sort glob 'docs/audits/conditional-origin-library-20261002/current-bound/*.json';
is(scalar @inputs, 24, 'entire immutable source-producer cohort');
subtest 'library cause matching excludes the actual caller regex echo' => sub {
    my $pattern = qr/library_reason_only_in_caller_argument/;
    my $error = library_refusal_with_echo($pattern);
    is(first_line($error), 'library origin independent document set required',
        'actual constructor supplies the independent-document reason');
    like($error, $pattern, 'real Carp trace echoes the caller expectation');
    ok(!diagnostic_matches($error, $pattern), 'caller expectation cannot authenticate another cause');
    rejected(sub {FSM::Test::LibraryDocumentOriginAuthority->from_documents('missing.isf', {}, [])},
        qr/library origin independent document set required/, 'actual constructor positive');
    if (my $capture = $ENV{FSMGEN_DOCUMENT_ORIGIN_CAPTURE}) {
        write_file("$capture/diagnostic-echo.json", $json->encode({error => $error,
            expected => 'library_reason_only_in_caller_argument',
            matched => diagnostic_matches($error, $pattern) ? 1 : 0}) . "\n");
    }
};
for my $input (@inputs) {
    my $original = $json->decode(read_file($input));
    subtest "independent imported documents $original->{case}{name}" => sub {
        my ($label, $documents, $directory) = external_documents($original);
        local $ENV{FSMLIB} = $directory;
        my $ordinary = FSM::Adapter::ISF::Parser->new->parse_source($documents->{$label}, $label);
        my $ordinary_json = $json->encode($ordinary);
        my $authority = authority_class()->from_documents($label, $documents, [$directory]);
        my $actor = $authority->actor;
        my $proof = $authority->proof;
        is($json->encode($actor), $ordinary_json, 'complete canonical ordinary actor and kinds unchanged');
        ok($authority->validate($json->decode($json->encode($actor)), $json->decode($json->encode($proof))),
            'whole actor/proof opaque reload authenticated against independent bytes');
        is(scalar @{$proof->{actors}}, 3, 'complete root and exported source constructors');
        is(scalar @{$proof->{uses}}, 2, 'complete actual use clones');
        is_deeply([map {$_->{source_label}} @{$proof->{documents}}], [sort keys %$documents],
            'literal complete document-set coverage');
        for my $record (@{$proof->{actors}}) {
            is($record->{ledger}{source_sha256}, sha256_hex($documents->{$record->{source_label}}),
                'original actor registry uses its own complete document bytes');
        }
        for my $edge (@{$proof->{uses}}) {
            is($json->encode([map {$_->{width}} @{$edge->{target}{interface}{inputs}}]), '[1,1,"3","3"]',
                'original complete cloned private width kinds');
            is($edge->{source_label}, $proof->{actors}[$edge->{actor_id}]{source_label}, 'exact original document edge');
            is($json->encode($edge->{ledger}), $json->encode($proof->{actors}[$edge->{actor_id}]{ledger}),
                'complete selected producer ledger survives actual clone');
        }
        my @controls;
        for my $name (qw(actor_identity actor_kind schema_kind document_hash producer_kind source_operation alias export instance path coverage target)) {
            my ($bad_actor, $bad_proof) = ($json->decode($ordinary_json), $json->decode($json->encode($proof)));
            mutate($name, $bad_actor, $bad_proof);
            my $before = $json->encode([$bad_actor, $bad_proof]);
            my $accepted = eval {$authority->validate($bad_actor, $bad_proof); 1};
            my $diagnostic = $@;
            ok(!$accepted, "actual $name mutation refuses");
            like($diagnostic, qr/differs from authoritative document set/, 'precise independent authentication boundary');
            is($json->encode([$bad_actor, $bad_proof]), $before, 'submitted whole products remain untouched');
            push @controls, {name => $name, actor => $bad_actor, proof => $bad_proof,
                accepted => $accepted ? 1 : 0, diagnostic => $diagnostic};
        }
        my $copy = $authority->proof;
        $copy->{uses}[0]{instance} = 'changed_returned_view';
        is($json->encode($authority->proof), $json->encode($proof), 'returned complete proof is detached');
        is($json->encode($ordinary), $ordinary_json, 'independent ordinary original remains untouched');
        if (my $capture = $ENV{FSMGEN_DOCUMENT_ORIGIN_CAPTURE}) {
            write_file("$capture/$original->{case}{name}.json", $json->encode({case => $original->{case},
                baseline_source => $original->{source}, label => $label, documents => $documents,
                search_roots => [$directory], ordinary => $ordinary, instrumented => $actor, proof => $proof,
                controls => \@controls}) . "\n");
        }
    };
}

subtest 'actual document authority membership and source failures refuse' => sub {
    my $original = $json->decode(read_file($inputs[0]));
    my ($label, $documents, $directory) = external_documents($original);
    my ($external) = grep {$_ ne $label} keys %$documents;
    my $mutated = {%$documents, $external => $documents->{$external} . ' ; changed complete bytes'};
    rejected(sub {authority_class()->from_documents($label, $mutated, [$directory])},
        qr/selected source bytes differ/, 'independently supplied wrong complete bytes');
    my $missing = {%$documents}; delete $missing->{$external};
    rejected(sub {authority_class()->from_documents($label, $missing, [$directory])},
        qr/selected document authority missing/, 'actual selected document missing');
    my $extra = {%$documents, "$directory/unused.isf" => '(library unused.lib (exports (actor none)))'};
    rejected(sub {authority_class()->from_documents($label, $extra, [$directory])},
        qr/document membership differs/, 'unused supplied document is not accepted as a graph member');
    rejected(sub {authority_class()->from_documents($label, undef, [$directory])},
        qr/independent document set required/, 'absent independent source authority');
    rejected(sub {authority_class()->from_documents($label, $documents, ['/foreign'])},
        qr/repository-relative document identity/, 'absolute persisted search root');
    rejected(sub {authority_class()->from_documents($label, $documents, ['../foreign'])},
        qr/repository-relative document identity/, 'escaping persisted search root');
    {
        local $ENV{FSMLIB} = $directory;
        rejected(sub {FSM::Test::DocumentSelectedFormMutation->new->parse_documents($label, $documents)},
            qr/actual selected form differs from authority/, 'actual producer form mutation cannot forge a selected document');
    }
    for my $closed (
        ['package', '(actor closed (imports (package pkg)))', qr/package source authority is not qualified/],
        ['ATL', '(actor closed (instance child of Worker))', qr/ATL source authority is not qualified/],
    ) {
        rejected(sub {authority_class()->from_documents('closed.isf', {'closed.isf' => $closed->[1]}, [])},
            $closed->[2], "$closed->[0] remains closed");
    }
};

subtest 'same-source resolution takes precedence over a competing external file' => sub {
    my $original = $json->decode(read_file($inputs[0]));
    my ($label, $documents, $directory) = external_documents($original);
    my $source = $original->{source};
    my $authority = authority_class()->from_documents($label, {$label => $source}, [$directory]);
    is_deeply([map {$_->{source_label}} @{$authority->proof->{documents}}], [$label], 'only actual selected root is authorized');
    is_deeply([map {$_->{source_label}} @{$authority->proof->{uses}}], [$label, $label], 'canonical same-source clones selected');
    if (my $capture = $ENV{FSMGEN_DOCUMENT_ORIGIN_CAPTURE}) {
        write_file("$capture/precedence.json", $json->encode({case => $original->{case}, label => $label,
            documents => {$label => $source}, actor => $authority->actor, proof => $authority->proof}) . "\n");
    }
};

subtest 'two aliases retain actual distinct external constructor selections' => sub {
    my $original = $json->decode(read_file('docs/audits/conditional-origin-library-20261002/current-bound/reused_export.json'));
    my ($label, $documents, $directory) = external_documents($original);
    $documents->{$label} =~ s/\(imports \(library common.choice as lib\)\)/(imports (library common.choice as lib) (library common.choice as again))/;
    $documents->{$label} =~ s/\(use lib.worker as second/(use again.worker as second/;
    my $authority = authority_class()->from_documents($label, $documents, [$directory]);
    local $ENV{FSMLIB} = $directory;
    my $ordinary = FSM::Adapter::ISF::Parser->new->parse_source($documents->{$label}, $label);
    is($json->encode($authority->actor), $json->encode($ordinary), 'whole independently parsed alias product unchanged');
    my $proof = $authority->proof;
    is(scalar @{$proof->{actors}}, 5, 'actual canonical resolver rebuilds both external exported actors for each alias');
    is_deeply([map {$_->{actor_id}} @{$proof->{uses}}], [1, 3], 'each clone selects its exact constructor reference');
    is_deeply([map {$_->{alias}} @{$proof->{resolutions}}], ['lib','again'], 'declared import aliases retain separate actual resolution');
    is($json->encode($proof->{uses}[0]{target}), $json->encode($proof->{uses}[1]{target}),
        'identical complete bodies do not merge distinct actual constructor selections');
    if (my $capture = $ENV{FSMGEN_DOCUMENT_ORIGIN_CAPTURE}) {
        write_file("$capture/aliases.json", $json->encode({label => $label, documents => $documents,
            actor => $authority->actor, ordinary => $ordinary, proof => $proof}) . "\n");
    }
};
subtest 'matching embedded source digests cannot authenticate a different original operation' => sub {
    my $original = $json->decode(read_file('docs/audits/conditional-origin-library-20261002/current-bound/identical_export_twins.json'));
    my ($label, $documents, $directory) = external_documents($original);
    my $authority = authority_class()->from_documents($label, $documents, [$directory]);
    my $other_documents = {%$documents};
    my ($selected) = grep {/common\.choice\.isf\z/} keys %$documents;
    $other_documents->{$selected} =~ s/\(select seen allow datain other\)/(when allow (set seen datain)) (when (! allow) (set seen other))/
        or die 'selected literal source operation missing';
    write_file($selected, $other_documents->{$selected});
    my $other = authority_class()->from_documents($label, $other_documents, [$directory]);
    is($json->encode($other->actor), $json->encode($authority->actor), 'different complete original documents yield identical complete actors');
    isnt($json->encode($other->proof), $json->encode($authority->proof), 'fully consistent origins/digests retain different original source operation');
    ok($other->validate($other->actor, $other->proof), 'substituted proof is valid against its own independently supplied bytes');
    rejected(sub {$authority->validate($other->actor, $other->proof)},
        qr/proof differs from authoritative document set/, 'matching embedded digest does not replace original authority');
    if (my $capture = $ENV{FSMGEN_DOCUMENT_ORIGIN_CAPTURE}) {
        write_file("$capture/source-twin.json", $json->encode({label => $label, documents => $documents,
            other_documents => $other_documents, actor => $authority->actor, proof => $authority->proof,
            other_actor => $other->actor, other_proof => $other->proof}) . "\n");
    }
};
subtest 'final canonical clone changes refuse before document-proof publication' => sub {
    my $original = $json->decode(read_file($inputs[0]));
    my ($label, $documents, $directory) = external_documents($original);
    local $ENV{FSMLIB} = $directory;
    my @controls;
    for my $name (qw(target instance coverage parameter_kind)) {
        my $parser = FSM::Test::DocumentLateCloneMutation->new;
        $parser->{mutation} = $name;
        my $actor = eval {$parser->parse_documents($label, $documents)};
        my $diagnostic = $@;
        ok(!defined($actor), "actual late $name mutation cannot publish provenance");
        like($diagnostic, qr/library origin final use (?:target or identity|coverage) differs/,
            'precise final whole edge/target/kind publication boundary');
        push @controls, {name => $name, actor => $actor, declined_proof => $parser->proof, diagnostic => $diagnostic};
    }
    if (my $capture = $ENV{FSMGEN_DOCUMENT_ORIGIN_CAPTURE}) {
        write_file("$capture/finalization.json", $json->encode({case => $original->{case}, label => $label,
            documents => $documents, controls => \@controls}) . "\n");
    }
};
if (my $capture = $ENV{FSMGEN_DOCUMENT_ORIGIN_CAPTURE}) {
    write_file("$capture/boundaries.json", $json->encode(\@boundaries) . "\n");
}
done_testing;

sub authority_class { $ENV{FSMGEN_DOCUMENT_ORIGIN_AUTHORITY_CLASS} || 'FSM::Test::LibraryDocumentOriginAuthority' }
sub mutate {
    my ($name, $actor, $proof) = @_;
    if ($name eq 'actor_identity') {$actor->{actor_name} = 'forged_actor'}
    elsif ($name eq 'actor_kind') {$actor->{interface}{inputs}[0]{width} = '1'}
    elsif ($name eq 'schema_kind') {$proof->{schema_version} = '1'}
    elsif ($name eq 'document_hash') {$proof->{documents}[0]{source_sha256} = 'forged_digest'}
    elsif ($name eq 'producer_kind') {$proof->{uses}[0]{actor_id} = "$proof->{uses}[0]{actor_id}"}
    elsif ($name eq 'source_operation') {$proof->{uses}[0]{ledger}{catalog}[0]{operation} = 'forged_operation'}
    elsif ($name eq 'alias') {$proof->{uses}[0]{alias} = 'forged_alias'}
    elsif ($name eq 'export') {$proof->{uses}[0]{export} = 'forged_export'}
    elsif ($name eq 'instance') {$proof->{uses}[0]{instance} = 'forged_instance'}
    elsif ($name eq 'path') {$proof->{uses}[0]{path}[1] = 1}
    elsif ($name eq 'coverage') {pop @{$proof->{actors}}}
    elsif ($name eq 'target') {$proof->{uses}[0]{target}{transactions}[0]{clauses}[0] = ['forged_target']}
    else {die "unknown control $name"}
}
sub external_documents {
    my ($original) = @_;
    my $directory = File::Spec->abs2rel(tempdir(CLEANUP => 1));
    my $label = "$directory/authority-root.isf"; # parse_source, deliberately not a file
    my $forms = source_forms($original->{source});
    my %documents;
    for my $form (@$forms) {
        if ($form->[0] eq 'actor') {$documents{$label} = source_form($form)}
        else {
            die 'unexpected source root' unless $form->[0] eq 'library';
            my $path = "$directory/$form->[1].isf";
            $documents{$path} = source_form($form);
            write_file($path, $documents{$path});
        }
    }
    return ($label, \%documents, $directory);
}
sub source_form {
    die 'undefined authored fixture atom' unless defined $_[0];
    ref($_[0]) eq 'ARRAY' ? '(' . join(' ', map {source_form($_)} @{$_[0]}) . ')' : $_[0];
}
# Preserve the original restricted fixture tokens, including singleton (c).
# Canonical normalized ASTs include an undefined singleton tail and are not a
# source serializer. The production parser is still used for every product.
sub source_forms {
    my ($source) = @_;
    my @tokens = $source =~ /\(|\)|[^\s()]+/g;
    my (@roots, @stack);
    for my $token (@tokens) {
        if ($token eq '(') {
            my $form = [];
            push @{(@stack ? $stack[-1] : \@roots)}, $form;
            push @stack, $form;
        } elsif ($token eq ')') {
            die 'unmatched fixture close' unless @stack;
            pop @stack;
        } else {
            die 'non-list fixture root' unless @stack;
            push @{$stack[-1]}, $token;
        }
    }
    die 'unclosed fixture form' if @stack;
    return \@roots;
}
sub read_file {open my $file, '<:raw', $_[0] or die $!; local $/; my $text = <$file>; close $file or die $!; $text}
sub write_file {open my $file, '>:raw', $_[0] or die $!; print {$file} $_[1] or die $!; close $file or die $!}
sub rejected {
    my ($code, $reason, $name) = @_;
    my $accepted = eval {$code->(); 1};
    my $error = $@;
    ok(!$accepted, $name);
    ok(diagnostic_matches($error, $reason), 'precise authority refusal');
    push @boundaries, {name => $name, accepted => $accepted ? 1 : 0, error => $error};
}
sub first_line {(split /\n/, $_[0] // '')[0] // ''}
sub diagnostic_matches {
    my ($error, $pattern) = @_;
    my $subject = $ENV{FSMGEN_LIBRARY_DIAGNOSTIC_FULL_STACK} ? $error : first_line($error);
    return $subject =~ $pattern ? 1 : 0;
}
sub library_refusal_with_echo {
    my ($pattern) = @_;
    eval {FSM::Test::LibraryDocumentOriginAuthority->from_documents('missing.isf', {}, [])};
    return $@;
}
