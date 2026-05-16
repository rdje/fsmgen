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

my $isf_file = File::Spec->catfile($FindBin::Bin, '..', 'isf', 'when_test.isf');

subtest 'when fixture lowers to the expected scheduled FSM structure' => sub {
    my ($fsm, $report) = lower_when_fixture();

    like($fsm, qr/\A\(\?fsm:when_test\b/, 'scheduled FSM names the when_test module');
    like($fsm, qr/\(mode 1\)/, 'scheduled FSM preserves mode input width');
    like($fsm, qr/\(result 32\)/, 'scheduled FSM preserves result output width');
    like($fsm, qr/\(test_tx_drive_1\n\s+\(= \(result_start 1\)\)\n\s+\(= \(result_val 0\)\)/,
        'entry drive initializes result to zero');
    like($fsm, qr/\(test_tx_when_2\n\s+\(\?mode\s+\(=1 \(-> test_tx_drive_3\)\)\s+\(=0 \(-> test_tx_when_5\)\)/s,
        'first when branches to true body or falls through to the second when');
    like($fsm, qr/\(test_tx_drive_3\n\s+\(= \(result_start 1\)\)\n\s+\(= \(result_val 42\)\)/,
        'first true-body drive writes 42');
    like($fsm, qr/\(test_tx_drive_4\n\s+\(= \(result_start 1\)\)\n\s+\(= \(result_val 1\)\)/,
        'second true-body drive writes 1');
    like($fsm, qr/\(test_tx_when_5\n\s+\(\?mode\s+\(=1 \(-> test_tx_drive_6\)\)\s+\(=0 \(-> test_tx_done_7\)\)/s,
        'second when branches to true body or falls through to completion');
    like($fsm, qr/\(test_tx_drive_6\n\s+\(= \(result_start 1\)\)\n\s+\(= \(result_val 7\)\)/,
        'second when true-body drive writes 7');
    like($fsm, qr/\(<1 \(done> 1\)\)/, 'completion remains a one-cycle delayed pulse');
    like($fsm, qr/\(-result\n\s+\(<- \(result> result_val\) <result_start\)/, 'result drive block remains available');

    is($report->{source}, 'when_test.isf', 'schedule report names the source fixture');
    is($report->{scheduled_fsm}, 'when_test.fsm', 'schedule report names the generated FSM');
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
    is($report->{state_count}, 8, 'schedule report state count');
    is_deeply($report->{compile_issues}, [], 'schedule report has no compile issues');

    is_deeply(
        $report->{transactions},
        [
            {
                name => 'test_tx',
                count => 8,
                states => [qw(
                  test_tx_idle_0
                  test_tx_drive_1
                  test_tx_when_2
                  test_tx_drive_3
                  test_tx_drive_4
                  test_tx_when_5
                  test_tx_drive_6
                  test_tx_done_7
                )],
            },
        ],
        'schedule report records the when transaction state order',
    );

    is_deeply(
        [map { $_->{name} } @{$report->{dt_blocks}}],
        [qw(result)],
        'schedule report records the result named drive DT block',
    );

    assert_storage($report, 'done', 'register', 'completion_pulse', 1);

    my ($fan_in) = grep { $_->{target} eq 'result_start' } @{$report->{compatible_fanin_groups} || []};
    ok($fan_in, 'schedule report records result_start compatible fan-in');
    is(scalar @{$fan_in->{sources}}, 4, 'result_start fan-in has one source per drive call');
    is_deeply(
        [sort map { $_->{owner} } @{$fan_in->{sources}}],
        [qw(test_tx test_tx test_tx test_tx)],
        'result_start fan-in sources are owned by the transaction',
    );
};

subtest 'when fixture schedule JSON CLI matches the in-process report' => sub {
    my (undef, $in_process_report) = lower_when_fixture();
    my ($success, $error_message, $full_buf, $stdout_buf, $stderr_buf) = run(
        command => [
            './bin/fsmgen',
            '--strict',
            '--quiet',
            '--emit-schedule-json',
            $isf_file,
        ],
    );

    ok($success, 'strict schedule JSON generation succeeds for the when fixture');
    is(join('', @{$stderr_buf || []}), '', 'strict schedule JSON generation keeps stderr clean');
    is_deeply(
        decode_json(join('', @{$stdout_buf || []})),
        $in_process_report,
        'strict schedule JSON generation matches the in-process report',
    );
};

subtest 'when fixture reaches plain and strict HDL generation' => sub {
    my $tempdir = tempdir(CLEANUP => 1);
    my $plain_hdl = File::Spec->catfile($tempdir, 'when_test_plain.sv');
    my $strict_hdl = File::Spec->catfile($tempdir, 'when_test_strict.sv');

    run_hdl_generation(['./bin/fsmgen', '--quiet', '--output', $plain_hdl, $isf_file], $plain_hdl, 'plain');
    run_hdl_generation(['./bin/fsmgen', '--strict', '--quiet', '--output', $strict_hdl, $isf_file], $strict_hdl, 'strict');

    my $hdl = slurp($strict_hdl);
    like($hdl, qr/\bmodule\s+when_test\b/, 'strict generated HDL contains the when_test module');
    like($hdl, qr/\bTEST_TX_WHEN_2\b/, 'strict generated HDL contains first when state encoding');
    like($hdl, qr/\bTEST_TX_WHEN_5\b/, 'strict generated HDL contains second when state encoding');
    like($hdl, qr/\bresult_val\s*=\s*0\s*;/, 'strict generated HDL emits initial result value');
    like($hdl, qr/\bresult_val\s*=\s*42\s*;/, 'strict generated HDL emits first true-body value');
    like($hdl, qr/\bresult_val\s*=\s*1\s*;/, 'strict generated HDL emits second true-body value');
    like($hdl, qr/\bresult_val\s*=\s*7\s*;/, 'strict generated HDL emits second when value');
    like($hdl, qr/\bdone_pulse_delay_pipe\b/, 'strict generated HDL implements delayed completion pulse state');
};

done_testing();

sub lower_when_fixture {
    my $actor = FSM::Adapter::ISF->new()->parse_file($isf_file);
    my $scheduler = FSM::Scheduler::ISF->new();
    my $result = $scheduler->lower($actor);
    my $report = decode_json($scheduler->report($actor));

    return ($result->{files}{'when_test.fsm'}, $report);
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

    ok($success, "$label HDL generation succeeds for the when fixture");
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
