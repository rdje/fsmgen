use strict;
use warnings;
use lib 'perl', 't/lib';
use Test::More;
use Digest::SHA qw(sha256_hex);
use FSM::Test::DiagnosticCause qw(diagnostic_cause_matches);
use JSON::PP;
use FSM::Test::ConditionalOriginAuthority;

my $json = JSON::PP->new->canonical;
my $base = 'docs/audits/conditional-origin-parser-20261002/current-corrected';
my @paths = sort glob "$base/*.json";
is(scalar @paths, 54, 'complete qualified predecessor membership');
for my $path (@paths) {
    my ($name) = $path =~ m{/([^/]+)\.json$};
    subtest "independently supplied source authority $name" => sub {
        my $saved = $json->decode(read_file($path));
        my $authority = FSM::Test::ConditionalOriginAuthority->from_source($saved->{source}, $saved->{label});
        is($saved->{ledger}{actor_sha256}, sha256_hex($json->encode($saved->{instrumented})),
            'immutable historical actor digest still authenticates exact original bytes/kinds');
        my $actor = with_width_source_identity($saved->{instrumented});
        my $ledger = clone($saved->{ledger});
        $ledger->{actor_sha256} = sha256_hex($json->encode($actor));
        is($json->encode($authority->actor), $json->encode(with_width_source_identity($saved->{ordinary})),
            'complete current actor adds only exact source identity to immutable independent product');
        is($json->encode($authority->ledger), $json->encode($ledger),
            'complete reconstructed origins match immutable qualified product');
        ok($authority->validate($actor, $ledger), 'opaque actor and ledger JSON reload authenticates against caller source');
        my $actor_before = $json->encode($actor);
        my $ledger_before = $json->encode($ledger);
        my @controls;
        for my $mutation (qw(source_identity catalog_owner catalog_form target omission duplicate schema_kind extra_field actor_identity actor_kind actor_source_identity actor_source_omission)) {
            my $bad_actor = clone($actor);
            my $bad_ledger = clone($ledger);
            my $group = @{$bad_ledger->{entries}} ? 'entries' : 'residuals';
            if ($mutation eq 'source_identity') {$bad_ledger->{source_sha256} = '0' x 64}
            elsif ($mutation eq 'catalog_owner') {$bad_ledger->{catalog}[0]{owner}{name} = 'forged_source_owner'}
            elsif ($mutation eq 'catalog_form') {$bad_ledger->{catalog}[0]{source_form}[1] = 'forged_source_operand'}
            elsif ($mutation eq 'target') {$bad_ledger->{$group}[0]{target}[1] = 'forged_target'}
            elsif ($mutation eq 'omission') {shift @{$bad_ledger->{$group}}}
            elsif ($mutation eq 'duplicate') {push @{$bad_ledger->{$group}}, clone($bad_ledger->{$group}[0])}
            elsif ($mutation eq 'schema_kind') {$bad_ledger->{schema_version} = '1'}
            elsif ($mutation eq 'extra_field') {$bad_ledger->{extra} = 'forged'}
            elsif ($mutation eq 'actor_identity') {$bad_actor->{actor_name} = 'forged_actor'}
            elsif ($mutation eq 'actor_source_identity') {$bad_actor->{_width_source_actor_name} = 'forged_source_actor'}
            elsif ($mutation eq 'actor_source_omission') {delete $bad_actor->{_width_source_actor_name}}
            else {
                my $width = $bad_actor->{interface}{inputs}[0]{width};
                $bad_actor->{interface}{inputs}[0]{width} = '' . $width;
                isnt($json->encode([$bad_actor->{interface}{inputs}[0]{width}]), $json->encode([$width]),
                    'actual existing input width changes original JSON kind');
                is_deeply([sort keys %$bad_actor], [sort keys %$actor], 'kind mutation fabricates no actor field');
            }
            my $accepted = eval {$authority->validate($bad_actor, $bad_ledger); 1};
            my $diagnostic = $@;
            ok(!$accepted, "$mutation actually refuses");
            ok(diagnostic_cause_matches($diagnostic, $mutation =~ /\Aactor_(?:identity|kind|source_identity|source_omission)\z/
                ? 'conditional origin actor differs from authoritative source'
                : 'conditional origin ledger differs from authoritative source'),
                'precise source-bound diagnostic');
            push @controls, {name => $mutation, actor => $bad_actor, ledger => $bad_ledger,
                accepted => $accepted ? JSON::PP::true : JSON::PP::false, diagnostic => $diagnostic};
        }
        is($json->encode($actor), $actor_before, 'verification preserves complete submitted actor');
        is($json->encode($ledger), $ledger_before, 'verification preserves complete submitted ledger');
        my $returned_actor = $authority->actor;
        $returned_actor->{name} = 'changed_return';
        my $returned_ledger = $authority->ledger;
        $returned_ledger->{catalog}[0]{owner}{name} = 'changed_return';
        ok($authority->validate($actor, $ledger), 'returned views are detached from source authority');
        if (my $dir = $ENV{FSMGEN_ORIGIN_AUTHORITY_CAPTURE}) {
            write_file("$dir/$name.json", $json->encode({source => $saved->{source}, label => $saved->{label},
                actor => $actor, ledger => $ledger, reconstructed_actor => $authority->actor,
                reconstructed_ledger => $authority->ledger, controls => \@controls}) . "\n");
        }
    };
}

subtest 'identical complete actors require the independently supplied source intent' => sub {
    my $macro = $json->decode(read_file("$base/twin_macro.json"));
    my $authored = $json->decode(read_file("$base/twin_authored.json"));
    is($json->encode($macro->{instrumented}), $json->encode($authored->{instrumented}), 'whole actors are identical');
    my $authority = FSM::Test::ConditionalOriginAuthority->from_source($macro->{source}, $macro->{label});
    my $forged = clone($authored->{ledger});
    my $actor = with_width_source_identity($authored->{instrumented});
    $forged->{actor_sha256} = sha256_hex($json->encode($actor));
    $forged->{source_sha256} = $macro->{ledger}{source_sha256};
    ok(!eval {$authority->validate($actor, $forged); 1},
        'valid authored-when catalog plus matching embedded digest cannot replace select intent');
    ok(diagnostic_cause_matches($@, 'conditional origin ledger differs from authoritative source'), 'source operation authenticates independently of target shape');
};

subtest 'missing independent source authority refuses' => sub {
    my $saved = $json->decode(read_file("$base/twin_macro.json"));
    for my $source (undef, '', {}, $saved->{ledger}{source_sha256}) {
        ok(!eval {FSM::Test::ConditionalOriginAuthority->from_source($source, 'probe.isf'); 1},
            'missing, malformed or digest-only input cannot create source authority');
    }
    my $empty = bless {}, 'FSM::Test::ConditionalOriginAuthority';
    ok(!eval {$empty->validate($saved->{instrumented}, $saved->{ledger}); 1},
        'uninitialized verifier refuses even a valid complete ledger');
    ok(diagnostic_cause_matches($@, 'conditional origin independent source authority required'), 'bounded absent-authority diagnostic');
};

subtest 'unqualified imports stay closed at the local authority boundary' => sub {
    my $source = '(actor import_probe (imports (library missing.lib as lib)))';
    ok(!eval {FSM::Test::ConditionalOriginAuthority->from_source($source, 'import_probe.isf'); 1},
        'local proof cannot claim imported document authenticity');
    ok(diagnostic_cause_matches($@, 'conditional origin imported source authority is not qualified'),
        'explicit boundary refuses before external document resolution');
};
done_testing;

sub clone {$json->decode($json->encode($_[0]))}
sub with_width_source_identity {
    my ($historical) = @_;
    die "historical source actor already has width identity\n" if exists $historical->{_width_source_actor_name};
    my $actor = clone($historical);
    $actor->{_width_source_actor_name} = $historical->{actor_name};
    return $actor;
}
sub read_file {open my $f, '<:raw', $_[0] or die $!; local $/; return <$f>}
sub write_file {open my $f, '>:raw', $_[0] or die $!; print {$f} $_[1] or die $!; close $f or die $!}
