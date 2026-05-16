#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use File::Spec;
use FindBin;
use IPC::Cmd qw(run);
use JSON::PP qw(decode_json);

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::Support::CapabilityManifest qw(build_capability_manifest);
use FSM::Support::ISFPublicInterfaceContract qw(
    build_isf_public_interface_contract
    isf_public_interface_contract_source
);

my $expected_owners = [
    'FSM::Adapter::ISF',
    'FSM::Scheduler::ISF',
    'FSM::Scheduler::ISF::Emitter::FSM',
    'FSM::Scheduler::ISF::Emitter::JSON',
];

subtest 'direct ISF identity and stability metadata is exact' => sub {
    assert_identity_flags(
        build_isf_public_interface_contract(),
        'direct ISF public-interface contract',
    );
};

subtest 'manifest ISF identity and stability metadata is exact' => sub {
    my @views = (
        {
            label => 'in-process capability manifest',
            payload => build_capability_manifest(),
        },
        {
            label => 'CLI capability manifest',
            payload => run_capability_manifest('--capability-manifest'),
        },
        {
            label => 'CLI capability manifest alias',
            payload => run_capability_manifest('--emit-capability-manifest'),
        },
    );

    for my $view (@views) {
        my $label = $view->{label};
        assert_identity_flags(
            $view->{payload}{embedding}{isf_public_interface},
            "$label ISF public-interface contract",
        );
    }
};

done_testing();

sub assert_identity_flags {
    my ($contract, $label) = @_;

    is($contract->{schema_version}, 1, "$label schema version is exact");
    is($contract->{status}, 'bounded_public', "$label status is exact");
    is(
        $contract->{contract_source},
        isf_public_interface_contract_source(),
        "$label contract source is exact",
    );
    is_deeply(
        $contract->{implementation_owners},
        $expected_owners,
        "$label implementation owners are exact",
    );
    assert_unique_scalar_list(
        $contract->{implementation_owners},
        "$label implementation owners",
    );

    ok(
        $contract->{live_contract_documentation},
        "$label marks live contract documentation",
    );
    ok(
        $contract->{evolves_with_isf_implementation},
        "$label marks implementation-coupled evolution",
    );
    ok(!$contract->{raw_actor_full_hash_stable}, "$label keeps raw actor full hash non-public");
    ok(!$contract->{lowering_ir_full_hash_stable}, "$label keeps LoweringIR full hash non-public");
    ok(
        $contract->{schedule_report_full_schema_stable},
        "$label marks schedule-report schema version 1 stable",
    );
    ok(
        $contract->{scheduled_fsm_text_is_review_artifact},
        "$label marks scheduled .fsm text as review artifact",
    );
}

sub assert_unique_scalar_list {
    my ($values, $label) = @_;
    my %seen;

    ok(ref($values) eq 'ARRAY', "$label is an array");
    for my $value (@{$values || []}) {
        ok(!ref($value), "$label entry '$value' is scalar");
        next if ref($value);
        ok(length($value), "$label entry '$value' is non-empty");
        ok(!$seen{$value}++, "$label does not duplicate '$value'");
    }
}

sub run_capability_manifest {
    my ($mode) = @_;
    my ($success, $error_message, $full_buf, $stdout_buf, $stderr_buf) = run(
        command => ['./bin/fsmgen', $mode],
    );

    ok($success, "$mode succeeds");
    is(join('', @{$stderr_buf || []}), '', "$mode keeps stderr clean");

    return decode_json(join('', @{$stdout_buf || []}));
}
