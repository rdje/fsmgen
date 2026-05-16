#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use File::Spec;
use File::Temp qw(tempdir);
use FindBin;
use IPC::Cmd qw(run);
use JSON::PP qw(decode_json);

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::Adapter::ISF;
use FSM::Scheduler::ISF;

my $isf_file = File::Spec->catfile($FindBin::Bin, '..', 'isf', 'switch_test.isf');

subtest 'switch fixture lowers to the expected scheduled FSM structure' => sub {
    my ($fsm, $report) = lower_switch_fixture();

    like($fsm, qr/\A\(\?fsm:switch_test\b/, 'scheduled FSM names the switch_test module');
    like($fsm, qr/\(opcode 2\)/, 'scheduled FSM preserves opcode input width');
    like($fsm, qr/\(rdata 32\)/, 'scheduled FSM preserves rdata output width');
    like($fsm, qr/\(<= \(op opcode\) <start\)/, 'scheduled FSM samples opcode into op on start');
    like($fsm, qr/\(dispatch_switch_4\n\s+\(\?op/s, 'scheduled FSM emits a switch decision state over op');
    like($fsm, qr/\(=0 \(-> dispatch_drive_1\)\)/, 'switch branch 0 targets write result drive state');
    like($fsm, qr/\(=1 \(-> dispatch_drive_2\)\)/, 'switch branch 1 targets read result drive state');
    like($fsm, qr/\(=2 \(-> dispatch_drive_3\)\)/, 'switch branch 2 targets error result drive state');
    like($fsm, qr/\(default \(-> dispatch_done_5\)\)/, 'switch default falls through to completion');
    like($fsm, qr/\(= \(write_res_start 1\)\)/, 'write branch starts the write result drive');
    like($fsm, qr/\(= \(read_res_start 1\)\)/, 'read branch starts the read result drive');
    like($fsm, qr/\(= \(err_res_start 1\)\)/, 'error branch starts the error result drive');
    like($fsm, qr/\(<1 \(done> 1\)\)/, 'completion remains a one-cycle delayed pulse');

    is($report->{source}, 'switch_test.isf', 'schedule report names the source fixture');
    is($report->{scheduled_fsm}, 'switch_test.fsm', 'schedule report names the generated FSM');
    is($report->{clock}, 'clk', 'schedule report records the clock');
    is($report->{watchdog}, '65536', 'schedule report records the watchdog literal');
    is_deeply(
        $report->{reset},
        { name => 'rst_n', kind => 'async', polarity => 'active_low' },
        'schedule report records async active-low reset metadata',
    );
    is($report->{inputs}, 2, 'schedule report input count');
    is($report->{outputs}, 2, 'schedule report output count');
    is($report->{port_count}, 4, 'schedule report port count');
    is($report->{state_count}, 6, 'schedule report state count');
    is_deeply($report->{compile_issues}, [], 'schedule report has no compile issues');
    is_deeply($report->{compatible_fanin_groups}, [], 'distinct drive starts require no compatible fan-in group');

    is_deeply(
        $report->{transactions},
        [
            {
                name => 'dispatch',
                count => 6,
                states => [qw(
                  dispatch_idle_0
                  dispatch_switch_4
                  dispatch_drive_1
                  dispatch_drive_2
                  dispatch_drive_3
                  dispatch_done_5
                )],
            },
        ],
        'schedule report records the switch dispatch state order',
    );

    is_deeply(
        [map { $_->{name} } @{$report->{dt_blocks}}],
        [qw(err_res read_res write_res)],
        'schedule report records the named drive DT blocks',
    );

    assert_storage($report, 'op', 'register', 'sample_alias', 2);
    assert_storage($report, 'done', 'register', 'completion_pulse', 1);
};

subtest 'switch fixture schedule JSON CLI matches the in-process report' => sub {
    my (undef, $in_process_report) = lower_switch_fixture();
    my ($success, $error_message, $full_buf, $stdout_buf, $stderr_buf) = run(
        command => [
            './bin/fsmgen',
            '--strict',
            '--quiet',
            '--emit-schedule-json',
            $isf_file,
        ],
    );

    ok($success, 'strict schedule JSON generation succeeds for the switch fixture');
    is(join('', @{$stderr_buf || []}), '', 'strict schedule JSON generation keeps stderr clean');
    is_deeply(
        decode_json(join('', @{$stdout_buf || []})),
        $in_process_report,
        'strict schedule JSON generation matches the in-process report',
    );
};

subtest 'switch fixture reaches plain and strict HDL generation' => sub {
    my $tempdir = tempdir(CLEANUP => 1);
    my $plain_hdl = File::Spec->catfile($tempdir, 'switch_test_plain.sv');
    my $strict_hdl = File::Spec->catfile($tempdir, 'switch_test_strict.sv');

    run_hdl_generation(['./bin/fsmgen', '--quiet', '--output', $plain_hdl, $isf_file], $plain_hdl, 'plain');
    run_hdl_generation(['./bin/fsmgen', '--strict', '--quiet', '--output', $strict_hdl, $isf_file], $strict_hdl, 'strict');

    my $hdl = slurp($strict_hdl);
    like($hdl, qr/\bmodule\s+switch_test\b/, 'strict generated HDL contains the switch_test module');
    like($hdl, qr/\bDISPATCH_SWITCH_4\b/, 'strict generated HDL contains switch state encoding');
    like($hdl, qr/\bDISPATCH_DRIVE_1\b/, 'strict generated HDL contains write branch state encoding');
    like($hdl, qr/\bDISPATCH_DRIVE_2\b/, 'strict generated HDL contains read branch state encoding');
    like($hdl, qr/\bDISPATCH_DRIVE_3\b/, 'strict generated HDL contains error branch state encoding');
    like($hdl, qr/\brdata_next\s*=\s*42\s*;/, 'strict generated HDL drives write result value');
    like($hdl, qr/\brdata_next\s*=\s*7\s*;/, 'strict generated HDL drives read result value');
    like($hdl, qr/\brdata_next\s*=\s*0\s*;/, 'strict generated HDL drives error result value');
    like($hdl, qr/\bdone_pulse_delay_pipe\b/, 'strict generated HDL implements delayed completion pulse state');
};

done_testing();

sub lower_switch_fixture {
    my $actor = FSM::Adapter::ISF->new()->parse_file($isf_file);
    my $scheduler = FSM::Scheduler::ISF->new();
    my $result = $scheduler->lower($actor);
    my $report = decode_json($scheduler->report($actor));

    return ($result->{files}{'switch_test.fsm'}, $report);
}

sub assert_storage {
    my ($report, $name, $kind, $role, $width) = @_;
    my ($entry) = grep { $_->{name} eq $name } @{$report->{inferred_storage} || []};

    ok($entry, "storage entry '$name' exists");
    return unless $entry;
    is($entry->{kind}, $kind, "storage entry '$name' kind");
    is($entry->{role}, $role, "storage entry '$name' role");
    is($entry->{width}, $width, "storage entry '$name' width");
}

sub run_hdl_generation {
    my ($command, $output, $label) = @_;
    my ($success, $error_message, $full_buf, $stdout_buf, $stderr_buf) = run(command => $command);

    ok($success, "$label HDL generation succeeds for the switch fixture");
    is(join('', @{$stderr_buf || []}), '', "$label HDL generation keeps stderr clean");
    ok(-f $output, "$label HDL generation writes the requested output");
}

sub slurp {
    my ($path) = @_;
    open my $fh, '<', $path or die "cannot read $path: $!";
    my $text = do { local $/; <$fh> };
    close $fh or die "cannot close $path: $!";
    return $text;
}
