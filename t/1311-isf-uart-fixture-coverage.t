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

my $isf_file = File::Spec->catfile($FindBin::Bin, '..', 'isf', 'uart_tx.isf');

subtest 'UART-like fixture lowers to the expected scheduled FSM structure' => sub {
    my ($fsm, $report) = lower_uart_fixture();

    like($fsm, qr/\A\(\?fsm:uart_tx\b/, 'scheduled FSM names the uart_tx module');
    like($fsm, qr/\(data 8\)/, 'scheduled FSM preserves data input width');
    like($fsm, qr/\(send_byte_cnt 4\)/, 'scheduled FSM declares repeat counter width');
    like($fsm, qr/\(<= \(byte_data data\) <start\)/, 'scheduled FSM samples data as byte_data on start');
    like($fsm, qr/\(= \(tx_val 0\)\)/, 'scheduled FSM drives UART start bit low');
    like($fsm, qr/\(= \(tx_val byte_data\[0\]\)\)/, 'scheduled FSM drives TX from the sampled byte LSB');
    like($fsm, qr/\(<- \(byte_data \(\| \(>> byte_data 1\) \(<< 0 7\)\)\)\)/,
        'scheduled FSM shifts byte_data right with zero fill');
    like($fsm, qr/\(send_byte_repeat_init_3\b\s*\(<= \(send_byte_cnt 8\)\)\s*\(-> send_byte_repeat_check_6\)/s,
        'scheduled FSM repeat init loads the counter and transitions straight to the check state');
    like($fsm, qr/\(-- send_byte_cnt\)/, 'scheduled FSM decrements the repeat counter');
    like($fsm, qr/\(\?send_byte_cnt\s+\(!=0 \(-> send_byte_drive_4\)\)\s+\(=0 \(-> send_byte_drive_7\)\)/s,
        'scheduled FSM loops or exits based on the repeat counter (check-first)');
    like($fsm, qr/\(= \(tx_val 1\)\)/, 'scheduled FSM drives UART stop bit high');
    like($fsm, qr/\(<1 \(done> 1\)\)/, 'scheduled FSM completes with a one-cycle delayed pulse');
    unlike($fsm, qr/\(= \(tx_val byte_data\)\)/, 'scheduled FSM does not drive one-bit TX from the full byte');

    is($report->{source}, 'uart_tx.isf', 'schedule report names the source fixture');
    is($report->{scheduled_fsm}, 'uart_tx.fsm', 'schedule report names the generated FSM');
    is($report->{clock}, 'clk', 'schedule report records the clock');
    is($report->{watchdog}, '65536', 'schedule report records the watchdog literal');
    is_deeply(
        $report->{reset},
        { name => 'rst_n', kind => 'async', polarity => 'active_low' },
        'schedule report records async active-low reset metadata',
    );
    is($report->{inputs}, 2, 'schedule report input count');
    is($report->{outputs}, 3, 'schedule report output count');
    is($report->{port_count}, 5, 'schedule report port count');
    is($report->{state_count}, 10, 'schedule report state count');
    is_deeply($report->{compile_issues}, [], 'schedule report has no compile issues');

    is_deeply(
        $report->{transactions},
        [
            {
                name => 'send_byte',
                count => 10,
                states => [qw(
                  send_byte_idle_0
                  send_byte_drive_1
                  send_byte_drive_2
                  send_byte_repeat_init_3
                  send_byte_drive_4
                  send_byte_shift_5
                  send_byte_repeat_check_6
                  send_byte_drive_7
                  send_byte_drive_8
                  send_byte_done_9
                )],
            },
        ],
        'schedule report records the UART-like send state order',
    );

    is_deeply(
        [map { $_->{name} } @{$report->{dt_blocks}}],
        [qw(busy tx)],
        'schedule report records the named drive DT blocks',
    );

    assert_storage($report, 'byte_data', 'register', 'sample_alias', 8);
    assert_storage($report, 'send_byte_cnt', 'counter', 'repeat_counter', 4);
    assert_storage($report, 'done', 'register', 'completion_pulse', 1);

    is_deeply(
        [sort map { $_->{target} } @{$report->{compatible_fanin_groups}}],
        [qw(busy_start tx_start)],
        'schedule report records compatible drive request fan-in groups',
    );
};

subtest 'UART-like fixture schedule JSON CLI matches the in-process report' => sub {
    my (undef, $in_process_report) = lower_uart_fixture();
    my ($success, $error_message, $full_buf, $stdout_buf, $stderr_buf) = run(
        command => [
            './bin/fsmgen',
            '--strict',
            '--quiet',
            '--emit-schedule-json',
            $isf_file,
        ],
    );

    ok($success, 'strict schedule JSON generation succeeds for the UART-like fixture');
    is(join('', @{$stderr_buf || []}), '', 'strict schedule JSON generation keeps stderr clean');
    is_deeply(
        decode_json(join('', @{$stdout_buf || []})),
        $in_process_report,
        'strict schedule JSON generation matches the in-process report',
    );
};

subtest 'UART-like fixture reaches plain and strict HDL generation' => sub {
    my $tempdir = tempdir(CLEANUP => 1);
    my $plain_hdl = File::Spec->catfile($tempdir, 'uart_tx_plain.sv');
    my $strict_hdl = File::Spec->catfile($tempdir, 'uart_tx_strict.sv');

    run_hdl_generation(['./bin/fsmgen', '--quiet', '--output', $plain_hdl, $isf_file], $plain_hdl, 'plain');
    run_hdl_generation(['./bin/fsmgen', '--strict', '--quiet', '--output', $strict_hdl, $isf_file], $strict_hdl, 'strict');

    my $hdl = slurp($strict_hdl);
    like($hdl, qr/\bmodule\s+uart_tx\b/, 'strict generated HDL contains the UART-like module');
    like($hdl, qr/\bSEND_BYTE_SHIFT_5\b/, 'strict generated HDL contains scheduled shift state encoding');
    like($hdl, qr/\btx_val\s*=\s*byte_data\[0\]\s*;/, 'strict generated HDL drives TX from byte_data[0]');
    like($hdl, qr/\bbyte_data\s*>>\s*1\b/, 'strict generated HDL emits byte_data shift-right');
    unlike($hdl, qr/tx_val\s*=\s*byte_data\s*;/, 'strict generated HDL does not drive TX from full byte_data');
};

done_testing();

sub lower_uart_fixture {
    my $actor = FSM::Adapter::ISF->new()->parse_file($isf_file);
    my $scheduler = FSM::Scheduler::ISF->new();
    my $result = $scheduler->lower($actor);
    my $report = decode_json($scheduler->report($actor));

    return ($result->{files}{'uart_tx.fsm'}, $report);
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

    ok($success, "$label HDL generation succeeds for the UART-like fixture");
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
