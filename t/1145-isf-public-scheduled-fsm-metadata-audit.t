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
    isf_public_interface_dt_ordering_policy
);

subtest 'direct ISF scheduled .fsm metadata is exact' => sub {
    assert_scheduled_fsm_metadata(
        build_isf_public_interface_contract(),
        'direct ISF public-interface contract',
    );
};

subtest 'manifest ISF scheduled .fsm metadata is exact' => sub {
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
        assert_scheduled_fsm_metadata(
            $view->{payload}{embedding}{isf_public_interface},
            "$label ISF public-interface contract",
        );
    }
};

done_testing();

sub assert_scheduled_fsm_metadata {
    my ($contract, $label) = @_;
    my $policy = isf_public_interface_dt_ordering_policy();

    is(
        $contract->{scheduled_fsm_dt_ordering},
        $policy,
        "$label scheduled .fsm DT ordering policy is exact",
    );
    is(
        $contract->{schedule_report_dt_ordering},
        $policy,
        "$label schedule-report DT ordering policy matches the shared policy",
    );
    is(
        $contract->{scheduled_fsm_dt_ordering},
        $contract->{schedule_report_dt_ordering},
        "$label scheduled .fsm and schedule-report DT ordering policies stay paired",
    );
    ok(
        $contract->{scheduled_fsm_text_is_review_artifact},
        "$label marks scheduled .fsm text as a review artifact",
    );
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
