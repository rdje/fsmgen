#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use File::Spec;
use FindBin;
use IPC::Cmd qw(run);
use JSON::PP qw(decode_json);

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::Adapter::ISF;
use FSM::Scheduler::ISF;
use FSM::Support::CapabilityManifest qw(build_capability_manifest);
use FSM::Support::ISFPublicInterfaceContract qw(
    build_isf_public_interface_contract
    isf_public_interface_schedule_report_interface_count_shape
    isf_public_interface_schedule_report_state_count_shape
);

subtest 'direct ISF schedule-report count metadata is exact' => sub {
    assert_count_metadata(
        build_isf_public_interface_contract(),
        'direct ISF public-interface contract',
    );
};

subtest 'manifest ISF schedule-report count metadata is exact' => sub {
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
        assert_count_metadata(
            $view->{payload}{embedding}{isf_public_interface},
            "$label ISF public-interface contract",
        );
    }
};

subtest 'APB schedule-report counts match actor interface and scheduled .fsm' => sub {
    my $isf_path = File::Spec->catfile($FindBin::Bin, '..', 'isf', 'apb_requester.isf');
    my $actor = FSM::Adapter::ISF->new()->parse_file($isf_path);
    my $scheduler = FSM::Scheduler::ISF->new();
    my $lowered = $scheduler->lower($actor);
    my $report = JSON::PP->new->decode($scheduler->report($actor));

    for my $field (qw(inputs outputs port_count state_count)) {
        like($report->{$field}, qr/\A(?:0|[1-9][0-9]*)\z/, "$field is a non-negative integer");
    }

    my $expected_inputs = scalar(@{$actor->{interface}{inputs} || []});
    my $expected_outputs = scalar(@{$actor->{interface}{outputs} || []});
    is($report->{inputs}, $expected_inputs, 'input count matches actor interface');
    is($report->{outputs}, $expected_outputs, 'output count matches actor interface');
    is($report->{port_count}, $report->{inputs} + $report->{outputs}, 'port_count equals inputs plus outputs');

    my $state_count = scheduled_state_count_from_fsm($lowered->{files}{'apb_requester.fsm'});
    is($report->{state_count}, $state_count, 'state_count matches scheduled .fsm state blocks');
};

done_testing();

sub assert_count_metadata {
    my ($contract, $label) = @_;

    is(
        $contract->{schedule_report_interface_count_shape},
        isf_public_interface_schedule_report_interface_count_shape(),
        "$label interface count shape is exact",
    );
    is(
        $contract->{schedule_report_state_count_shape},
        isf_public_interface_schedule_report_state_count_shape(),
        "$label state count shape is exact",
    );
}

sub scheduled_state_count_from_fsm {
    my ($fsm_text) = @_;
    my @states = $fsm_text =~ /^  \(([A-Za-z_][A-Za-z0-9_]*)\n/gm;
    return scalar(@states);
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
