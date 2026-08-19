#!/usr/bin/env perl

use strict;
use warnings;

use bytes ();
use Digest::SHA qw(sha256_hex);
use File::Spec;
use FindBin;
use JSON::PP ();
use Test::More;

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::VIAL::ArchitectureScaleExecutionGraph;

my $class = 'FSM::VIAL::ArchitectureScaleExecutionGraph';
my $json = JSON::PP->new->canonical(1)->utf8(1);
my $reference_hial = slurp_raw(repo_path('ppif/ahb_lite_subordinate.ppif'));
my %expected = (
    operations => 65_537,
    scenarios => 1,
    vial_bytes => 918_547,
    limit_vial_bytes => 918_533,
    workload_identity =>
        'workload/4cfeb07b456d019431bccd57aa8f6e86480dcae47ffb6099c5f581274e091dc7',
    vial_sha256 =>
        '6883f40cafbf69ad93d811156ff6c2302623e9becae7215315a4ed756436a5c9',
);
my $expected_diagnostic = {
    schema_version => 1,
    severity => 'error',
    code => 'VIAL_LIMIT_ERROR',
    phase => 'limit',
    message => 'scenario exceeds 65536 expanded actions',
    semantic_path => '/packages/0/fixtures/0/scenarios/0',
    source_location => {
        source_name =>
            'generated/vial-scale/execution_graph/vial_architecture_scale.vial',
        start_line => 1,
        start_column => 959,
        start_byte => 958,
        end_line => 1,
        end_column => 918_541,
        end_byte_exclusive => 918_541,
    },
    notes => [],
};
my $expected_discrepancy = {
    code => 'VIAL_SCALE_LIMIT_INTERACTION',
    message => 'the 65536 expanded-action semantic cap precedes the selected'
        . ' 65537-operation execution boundary',
    path => '/requested_counts/operations_per_scenario',
    repair_owner => 'HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.4',
};

sub construction {
    return $class->construct({
        primary_axis => 'operations_per_scenario',
        level => 'over_limit_v1',
        reference_hial_text => $reference_hial,
    });
}

sub limit_construction {
    return $class->construct({
        primary_axis => 'operations_per_scenario',
        level => 'limit_v1',
        reference_hial_text => $reference_hial,
    });
}

subtest '65,537-operation construction adds exactly one complete operation' => sub {
    my $first = construction();
    my $second = construction();
    ok($first->{ok}, 'one-over construction satisfies the workload contract');
    diag($json->encode($first->{diagnostics})) unless $first->{ok};
    is($json->encode($second), $json->encode($first),
        'independent one-over construction is byte-identical');
    is($first->{specification}{requested_counts}{operations_per_scenario},
        $expected{operations},
        'construction retains exactly 65,537 operations in one scenario');
    is($first->{workload_identity}, $expected{workload_identity},
        'one-over workload identity is exact');

    my %input = map { $_->{role} => $_ } @{$first->{inputs}};
    is_deeply([sort keys %input], [qw(hial_source vial_source)],
        'construction contains only checked HIAL and generated VIAL source');
    is($input{hial_source}{content}, $reference_hial,
        'construction retains every checked-AHB source byte');
    is(bytes::length($input{vial_source}{content}), $expected{vial_bytes},
        'generated one-over VIAL byte count is exact');
    is(sha256_hex($input{vial_source}{content}), $expected{vial_sha256},
        'generated one-over VIAL identity is frozen');
    is(scalar(() = $input{vial_source}{content} =~ /\(scenario scenario_/g),
        $expected{scenarios}, 'source still authors exactly one scenario');
    is(scalar(() = $input{vial_source}{content} =~ /\(reset bus 1\)/g),
        $expected{operations},
        'source authors exactly 65,537 genuine reset operations');

    my ($limit_vial) = grep { $_->{role} eq 'vial_source' }
        @{limit_construction()->{inputs}};
    is(bytes::length($limit_vial->{content}), $expected{limit_vial_bytes},
        'the accepted limit source retains its exact byte count');
    is($expected{vial_bytes} - $expected{limit_vial_bytes}, 14,
        'the one-over delta is exactly one complete 14-byte operation record');

    my $reduced = $input{vial_source}{content};
    is(scalar($reduced =~ s/ \(reset bus 1\)(\)+\n)\z/$1/), 1,
        'the one-over source ends with one removable complete reset record');
    is(scalar($reduced
            =~ s/\(timeout \(cycles bus 65538\)\)/(timeout (cycles bus 65537))/),
        1, 'the one-over scenario timeout covers exactly its own operations');
    is($reduced, $limit_vial->{content},
        'removing that one operation reproduces the accepted limit source exactly');
};

subtest 'ordinary semantic stage rejects before any bridge construction' => sub {
    my $inputs =
        FSM::VIAL::ArchitectureScaleExecutionGraph::_test_execution_inputs(
            clone_json(construction()));
    is_deeply([sort keys %$inputs], ['semantic_rejection'],
        'the semantic stage returns only its authoritative rejection');
    is($inputs->{semantic_ir}, undef, 'no SemanticIR survives the cap');
    is($inputs->{bridge_manifest}, undef,
        'the canonical bridge is never constructed behind the earlier stage');
    is_deeply($inputs->{semantic_rejection}, [$expected_diagnostic],
        'the ordinary parser returns the one exact expanded-action diagnostic');
};

subtest 'public build returns only the semantic cap diagnostic' => sub {
    my $first = $class->build({construction => construction()});
    my $second = $class->build({construction => construction()});
    ok(!$first->{ok}, 'the first operation excess is rejected');
    is($json->encode($second), $json->encode($first),
        'independent operation over-limit rejection is byte-identical');
    is($first->{execution_ir}, undef,
        'semantic rejection exposes no partial execution IR');
    is($first->{plan}, undef, 'semantic rejection exposes no partial plan');
    is_deeply($first->{diagnostics}, [$expected_diagnostic],
        'build returns the one exact authoritative semantic diagnostic');
};

subtest 'evaluation records the selected semantic dominance' => sub {
    my $evaluation = $class->evaluate({construction => construction()});
    ok($evaluation->{ok}, 'one-over evaluation satisfies every closed oracle');
    diag($json->encode($evaluation->{diagnostics})) unless $evaluation->{ok};
    is($evaluation->{status}, 'expected_rejection',
        'evaluation classifies the operation excess as expected');
    is($evaluation->{observed_outcome}, 'rejected',
        'evaluation records the rejected outcome');
    is_deeply($evaluation->{diagnostics}, [$expected_diagnostic],
        'evaluation preserves the exact semantic diagnostic');
    is_deeply($evaluation->{metrics}, {},
        'rejection reports no measurements from a partial plan');
    is($evaluation->{semantic_ir_sha256}, undef,
        'no SemanticIR identity is claimed for a rejected source');
    is($evaluation->{bridge_manifest_sha256}, undef,
        'no bridge identity is claimed behind the earlier semantic stage');
    is_deeply($evaluation->{contract_discrepancies}, [$expected_discrepancy],
        'evaluation names the earlier semantic authority and its repair owner');

    my $forged = clone_json(construction());
    my ($vial) = grep { $_->{role} eq 'vial_source' } @{$forged->{inputs}};
    $vial->{content} .= ' ';
    my $accepted = eval { $class->build({construction => $forged}); 1 };
    ok(!$accepted, 'post-identity source padding fails closed');
    like($@, qr/construction is not canonical/,
        'mutation rejection names canonical regeneration');

    my $missing = eval {
        $class->construct({
            primary_axis => 'operations_per_scenario',
            level => 'over_limit_v1',
        });
        1;
    };
    ok(!$missing, 'one-over construction requires frozen checked-AHB source');
    like($@, qr/checked-AHB reference text is required/,
        'missing-source rejection names checked-AHB authority');

    my $unowned = eval {
        $class->construct({
            primary_axis => 'source_map_records',
            level => 'qualification_candidate_v1',
            reference_hial_text => $reference_hial,
        });
        1;
    };
    ok(!$unowned, 'the unimplemented source-map qualification stays unowned');
    like($@, qr/does not own the requested shape/,
        'unowned level rejection names the generator slice boundary');
};

done_testing();

sub repo_path {
    my ($relative) = @_;
    return File::Spec->catfile($FindBin::Bin, '..', split m{/}, $relative);
}

sub slurp_raw {
    my ($path) = @_;
    open my $fh, '<:raw', $path or die "Cannot read $path: $!";
    local $/;
    my $text = <$fh>;
    close $fh or die "Cannot close $path: $!";
    return $text;
}

sub clone_json {
    my ($value) = @_;
    return $json->decode($json->encode($value));
}

package FSM::VIAL::ArchitectureScaleExecutionGraph;

sub _test_execution_inputs {
    my ($construction) = @_;
    return _canonical_inputs($construction);
}
