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
    isf_public_interface_schedule_report_clock_shape
    isf_public_interface_schedule_report_scheduled_fsm_shape
    isf_public_interface_schedule_report_source_shape
    isf_public_interface_schedule_report_watchdog_shape
);

subtest 'direct ISF schedule-report scalar metadata is exact' => sub {
    assert_scalar_metadata(
        build_isf_public_interface_contract(),
        'direct ISF public-interface contract',
    );
};

subtest 'manifest ISF schedule-report scalar metadata is exact' => sub {
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
        assert_scalar_metadata(
            $view->{payload}{embedding}{isf_public_interface},
            "$label ISF public-interface contract",
        );
    }
};

subtest 'schedule reports follow advertised scalar metadata' => sub {
    my $apb_report = report_for_file('isf/apb_requester.isf');
    is($apb_report->{source}, 'apb_requester.isf', 'APB report source basename is actor-derived');
    is($apb_report->{scheduled_fsm}, 'apb_requester.fsm', 'APB report scheduled_fsm basename is actor-derived');
    is($apb_report->{clock}, 'clk', 'APB report clock is the actor clock signal');
    is($apb_report->{watchdog}, '65536', 'APB report watchdog is scalar when configured');

    my $no_watchdog_report = report_for_source(no_watchdog_source());
    is($no_watchdog_report->{source}, 'scalar_probe.isf', 'inline report source basename is actor-derived');
    is($no_watchdog_report->{scheduled_fsm}, 'scalar_probe.fsm', 'inline report scheduled_fsm basename is actor-derived');
    is($no_watchdog_report->{clock}, 'clk_i', 'inline report clock is the actor clock signal');
    ok(!defined($no_watchdog_report->{watchdog}), 'watchdog is null when omitted');
};

done_testing();

sub assert_scalar_metadata {
    my ($contract, $label) = @_;

    my @checks = (
        [schedule_report_source_shape => isf_public_interface_schedule_report_source_shape()],
        [schedule_report_scheduled_fsm_shape => isf_public_interface_schedule_report_scheduled_fsm_shape()],
        [schedule_report_clock_shape => isf_public_interface_schedule_report_clock_shape()],
        [schedule_report_watchdog_shape => isf_public_interface_schedule_report_watchdog_shape()],
    );

    for my $check (@checks) {
        my ($field, $expected) = @$check;
        is($contract->{$field}, $expected, "$label $field is exact");
    }
}

sub report_for_file {
    my ($relpath) = @_;
    my $path = File::Spec->catfile($FindBin::Bin, '..', split m{/}, $relpath);
    my $actor = FSM::Adapter::ISF->new()->parse_file($path);
    return JSON::PP->new->decode(FSM::Scheduler::ISF->new()->report($actor));
}

sub report_for_source {
    my ($source) = @_;
    my $actor = FSM::Adapter::ISF->new()->parse_source($source, 'inline-scalar-probe.isf');
    return JSON::PP->new->decode(FSM::Scheduler::ISF->new()->report($actor));
}

sub no_watchdog_source {
    return <<'ISF';
(actor scalar_probe
  (clock clk_i)
  (reset rst_i)
  (interface
    (input start)
    (output done))
  (transaction main
    (on start)
    (complete done)))
ISF
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
