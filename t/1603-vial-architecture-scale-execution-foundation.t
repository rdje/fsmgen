#!/usr/bin/env perl

use strict;
use warnings;

use JSON::PP ();
use Test::More;
use File::Spec;
use FindBin;

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::HIAL::VIALBridge::Manifest;
use FSM::VIAL::ArchitectureScaleExecutionGraph;
use FSM::VIAL::ArchitectureScaleWorkload;
use FSM::VIAL::ExecutionBuilder;

my $class = 'FSM::VIAL::ArchitectureScaleExecutionGraph';
my $foundation = 'FSM::VIAL::ArchitectureScaleWorkload';
my $json = JSON::PP->new->canonical(1)->utf8(1);

sub construction {
    return $class->construct({
        primary_axis => 'bindings',
        level => 'gate_candidate_v1',
    });
}

subtest 'binding-gate construction is closed, canonical, and exact' => sub {
    my $first = construction();
    my $second = construction();
    ok($first->{ok}, 'binding gate constructs through the shared scale foundation');
    diag($json->encode($first->{diagnostics})) unless $first->{ok};
    is($json->encode($second), $json->encode($first),
        'independent construction reproduces byte-equal inputs and identity');
    is($first->{specification}{family}, 'execution_graph_v1',
        'construction cannot escape the execution-graph family');
    is($first->{specification}{requested_counts}{bindings}, 2_048,
        'construction retains the selected binding gate');
    is_deeply([map { $_->{role} } @{$first->{inputs}}],
        [qw(hial_source vial_source)],
        'construction contains exactly one ordinary HIAL and VIAL source');
    my ($hial) = grep { $_->{role} eq 'hial_source' } @{$first->{inputs}};
    my ($vial) = grep { $_->{role} eq 'vial_source' } @{$first->{inputs}};
    is(scalar(() = $hial->{content} =~ /\(event bridge_event_[0-9]{8} /g),
        2_042, 'HIAL carries the exact private ordinal-event family');
    is(scalar(() = $vial->{content} =~ /bridge_event_[0-9]{8}/g),
        2_042, 'VIAL declares every private event exactly once');

    my $bad_key = eval {
        $class->construct({
            primary_axis => 'bindings', level => 'gate_candidate_v1', extra => 1,
        });
        1;
    };
    ok(!$bad_key, 'unknown construction keys fail closed');
    like($@, qr/unknown key 'extra'/,
        'unknown-key failure names the closed invocation boundary');

    for my $case (
        [
            {primary_axis => 'scenarios', level => 'gate_candidate_v1'},
            qr/checked-AHB reference text is required/,
        ],
        [
            {primary_axis => 'bindings', level => 'qualification_candidate_v1'},
            qr/execution-graph gate slice does not own the requested shape/,
        ],
    ) {
        my ($bad, $failure) = @$case;
        my $accepted = eval { $class->construct($bad); 1 };
        ok(!$accepted, 'unfinished execution shapes cannot enter the foundation slice');
        like($@, $failure,
            'unfinished shape rejection names the bounded implementation frontier');
    }

    my $forged = $json->decode($json->encode($first));
    $forged->{inputs}[0]{content} .= ' ';
    my $forged_build = eval { $class->build({construction => $forged}); 1 };
    ok(!$forged_build, 'post-identity construction mutation fails closed');
    like($@, qr/construction is not canonical/,
        'forged construction rejection names canonical regeneration');
};

subtest 'qualification admission is caller-sealed and metadata-sealed' => sub {
    my $inputs = FSM::VIAL::ArchitectureScaleExecutionGraph::_canonical_inputs(
        construction(),
    );
    my $direct = FSM::VIAL::ExecutionBuilder
        ->build_architecture_scale_qualification($inputs->{arguments});
    ok(!$direct->{ok}, 'direct callers cannot invoke qualification binding');
    is($direct->{diagnostics}[0]{code}, 'VIAL_EXECUTION_INVOCATION_ERROR',
        'direct caller rejection uses the stable invocation family');
    like($direct->{diagnostics}[0]{message}, qr/private to FSM::VIAL::ArchitectureScaleExecutionGraph/,
        'direct caller rejection names the sole admitted generator');

    my $public = FSM::VIAL::ExecutionBuilder->build($inputs->{arguments});
    ok(!$public->{ok}, 'public execution binding still rejects the private capability');
    is($public->{diagnostics}[0]{code}, 'VIAL_CAPABILITY_ERROR',
        'public rejection retains the stable capability family');
    like($public->{diagnostics}[0]{message},
        qr/unknown execution capability 'hial_vial\.bridge_qualification\.architecture_scale_v1'/,
        'public rejection retains the exact private capability identity');

    my $manifest_data = $inputs->{bridge_manifest}->as_hashref;
    $manifest_data->{protocols}[0]{profile} = 'altered';
    my $forged_manifest = bless {data => $manifest_data},
        'FSM::HIAL::VIALBridge::Manifest';
    my %forged_args = (%{$inputs->{arguments}}, bridge_manifest => $forged_manifest);
    my $forged = FSM::VIAL::ArchitectureScaleExecutionGraph::_test_private_builder_call(
        \%forged_args,
    );
    ok(!$forged->{ok}, 'altered private protocol metadata fails closed');
    is($forged->{diagnostics}[0]{code}, 'VIAL_CAPABILITY_ERROR',
        'altered private metadata uses the stable capability family');
    is($forged->{diagnostics}[0]{semantic_path}, '/bridge_manifest/protocols',
        'altered private metadata identifies the sealed protocol locus');
};

subtest 'canonical gate reaches 2048 bindings with deterministic target-neutral proof' => sub {
    my $construction = construction();
    my $built = $class->build({construction => $construction});
    ok($built->{ok}, 'caller-sealed canonical binding succeeds');
    diag($json->encode($built->{diagnostics})) unless $built->{ok};
    my $ir = $built->{execution_ir}->as_hashref;
    is($ir->{resource_summary}{bindings}, 2_048,
        'resource summary reaches the exact selected binding gate');
    is(scalar(@{$ir->{bindings}{events}}), 2_042,
        'all non-foundation bindings are ordinal event bindings');
    is($ir->{operation_graph}{total_operation_count}, 1,
        'binding isolation uses one genuine reset operation');
    is($ir->{operation_graph}{total_fiber_count}, 1,
        'binding isolation uses one root fiber');
    is($ir->{operation_graph}{maximum_simultaneous_live_fibers}, 1,
        'binding isolation does not inflate live-fiber scale');
    my ($private_capability) = grep {
        $_->{capability_id}
            eq 'hial_vial.bridge_qualification.architecture_scale_v1'
    } @{$built->{plan}{capability_ledger}};
    is($private_capability->{classification}, 'qualification_only',
        'private capability is labelled as qualification evidence only');
    is($private_capability->{portable_class}, 'private_nonportable',
        'private capability cannot imply portable support');
    is_deeply($private_capability->{origins}, ['bridge_manifest'],
        'private capability has only the canonical bridge origin');

    my $evaluation = $class->evaluate({construction => $construction});
    ok($evaluation->{ok}, 'binding gate passes every reusable execution oracle');
    diag($json->encode($evaluation->{diagnostics})) unless $evaluation->{ok};
    is_deeply([sort keys %$evaluation],
        [sort @{$class->evaluation_keys}],
        'execution evaluation is a closed projection');
    is($evaluation->{status}, 'accepted', 'binding gate outcome is accepted');
    is($evaluation->{metrics}{bindings}, 2_048,
        'evaluation independently records exact bindings');
    is($evaluation->{metrics}{execution_events}, 2_042,
        'evaluation independently records exact events');
    cmp_ok($evaluation->{metrics}{serialized_plan_bytes}, '<=', 16_777_216,
        'binding-gate plan remains within the canonical serialized-plan cap');
    like($evaluation->{semantic_ir_sha256}, qr/\A[0-9a-f]{64}\z/,
        'semantic identity is a canonical digest');
    like($evaluation->{bridge_manifest_sha256}, qr/\A[0-9a-f]{64}\z/,
        'bridge identity is a canonical digest');
    like($evaluation->{plan_sha256}, qr/\A[0-9a-f]{64}\z/,
        'plan identity is a canonical digest');
    is_deeply($evaluation->{contract_discrepancies}, [],
        'accepted gate has no selected contract discrepancy');
};

done_testing();

package FSM::VIAL::ArchitectureScaleExecutionGraph;

sub _test_private_builder_call {
    my ($arguments) = @_;
    return FSM::VIAL::ExecutionBuilder
        ->build_architecture_scale_qualification($arguments);
}
