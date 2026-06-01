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

my $isf_file = File::Spec->catfile($FindBin::Bin, '..', 'isf', 'burst_reader.isf');

subtest 'Burst-reader fixture lowers to the expected scheduled FSM structure' => sub {
    my ($fsm, $report) = lower_burst_fixture();

    like($fsm, qr/\A\(\?fsm:burst_reader\b/, 'scheduled FSM names the burst_reader module');
    like($fsm, qr/\(addr 32\)/, 'scheduled FSM preserves addr width');
    like($fsm, qr/\(burst_len 8\)/, 'scheduled FSM preserves burst_len width');
    like($fsm, qr/\(rdata 32\)/, 'scheduled FSM preserves rdata width');
    like($fsm, qr/\(read_burst_cc 9\)/, 'scheduled FSM declares latency counter width');
    like($fsm, qr/\(read_burst_cnt 8\)/, 'scheduled FSM declares repeat counter width');
    like($fsm, qr/\(read_burst_wd 17\)/, 'scheduled FSM declares watchdog counter width');
    like($fsm, qr/\(<= \(beats burst_len\) <start\)/, 'scheduled FSM samples burst_len as beats on start');
    like($fsm, qr/\(<= \(word rdata\)\)/, 'scheduled FSM samples rdata inside the repeat body');
    like($fsm, qr/\(<= \(read_burst_cnt beats\)\)/, 'scheduled FSM loads the repeat counter from sampled beats');
    like($fsm, qr/\(read_burst_repeat_init_3\b[^(]*\(= \(read_burst_inc 1\)\)\s*\(<= \(read_burst_cnt beats\)\)\s*\(-> read_burst_repeat_check_6\)/s,
        'scheduled FSM repeat init loads the counter and transitions straight to the check state');
    like($fsm, qr/\(-- read_burst_cnt\)/, 'scheduled FSM decrements the repeat counter');
    like($fsm, qr/\(\?read_burst_cnt\s+\(!=0 \(-> read_burst_await_4\)\)\s+\(=0 \(-> read_burst_drive_7\)\)/s,
        'scheduled FSM loops or exits based on the repeat counter (check-first)');
    like($fsm, qr/\(\?read_burst_wd\s+\(=0 \(-> read_burst_timeout\)\)\s+\(>0 \(-- read_burst_wd\)\)\s+\)/s,
        'scheduled FSM watchdog tests timeout and decrements only on the nonzero branch');
    like($fsm, qr/\(<1 \(done> 1\)\)/, 'scheduled FSM completes with a one-cycle delayed pulse');
    like($fsm, qr/\(<- \(last_error 1\)\)/, 'scheduled FSM records timeout error storage');

    is($report->{source}, 'burst_reader.isf', 'schedule report names the source fixture');
    is($report->{scheduled_fsm}, 'burst_reader.fsm', 'schedule report names the generated FSM');
    is($report->{clock}, 'clk', 'schedule report records the clock');
    is($report->{watchdog}, '65536', 'schedule report records the watchdog literal');
    is_deeply(
        $report->{reset},
        { name => 'rst_n', kind => 'async', polarity => 'active_low' },
        'schedule report records async active-low reset metadata',
    );
    is($report->{inputs}, 4, 'schedule report input count');
    is($report->{outputs}, 3, 'schedule report output count');
    is($report->{port_count}, 7, 'schedule report port count');
    is($report->{state_count}, 10, 'schedule report state count');
    is_deeply($report->{compile_issues}, [], 'schedule report has no compile issues');

    is_deeply(
        $report->{transactions},
        [
            {
                name => 'read_burst',
                count => 10,
                states => [qw(
                  read_burst_idle_0
                  read_burst_drive_1
                  read_burst_await_2
                  read_burst_repeat_init_3
                  read_burst_await_4
                  read_burst_sample_5
                  read_burst_repeat_check_6
                  read_burst_drive_7
                  read_burst_done_8
                  read_burst_timeout
                )],
            },
        ],
        'schedule report records the burst-reader state order',
    );

    is_deeply(
        [map { $_->{name} } @{$report->{dt_blocks}}],
        [qw(read_burst_cc_inc footer header)],
        'schedule report records latency counter and drive DT blocks',
    );

    assert_storage($report, 'read_burst_cc', 'counter', 'latency_counter', 9);
    assert_storage($report, 'read_burst_wd', 'counter', 'watchdog_counter', 17);
    assert_storage($report, 'base_addr', 'register', 'sample_alias', 32);
    assert_storage($report, 'beats', 'register', 'sample_alias', 8);
    assert_storage($report, 'read_burst_cnt', 'counter', 'repeat_counter', 8);
    assert_storage($report, 'word', 'register', 'sample_alias', 32);
    assert_storage($report, 'done', 'register', 'completion_pulse', 1);

    my ($last_error) = grep { $_->{name} eq 'last_error' } @{$report->{inferred_storage} || []};
    ok($last_error, 'timeout error storage entry exists');
    is($last_error->{kind}, 'register', 'timeout error storage kind');
    is($last_error->{role}, 'scheduler_error_status', 'timeout error storage reports its role');

    is_deeply(
        [sort map { $_->{target} } @{$report->{compatible_fanin_groups}}],
        [qw(done)],
        'schedule report records completion/timeout pulse compatibility',
    );
};

subtest 'Burst-reader fixture schedule JSON CLI matches the in-process report' => sub {
    my (undef, $in_process_report) = lower_burst_fixture();
    my ($success, $error_message, $full_buf, $stdout_buf, $stderr_buf) = run(
        command => [
            './bin/fsmgen',
            '--strict',
            '--quiet',
            '--emit-schedule-json',
            $isf_file,
        ],
    );

    ok($success, 'strict schedule JSON generation succeeds for the burst-reader fixture');
    is(join('', @{$stderr_buf || []}), '', 'strict schedule JSON generation keeps stderr clean');
    is_deeply(
        decode_json(join('', @{$stdout_buf || []})),
        $in_process_report,
        'strict schedule JSON generation matches the in-process report',
    );
};

subtest 'Burst-reader fixture reaches plain and strict HDL generation' => sub {
    my $tempdir = tempdir(CLEANUP => 1);
    my $plain_hdl = File::Spec->catfile($tempdir, 'burst_reader_plain.sv');
    my $strict_hdl = File::Spec->catfile($tempdir, 'burst_reader_strict.sv');

    run_hdl_generation(['./bin/fsmgen', '--quiet', '--output', $plain_hdl, $isf_file], $plain_hdl, 'plain');
    run_hdl_generation(['./bin/fsmgen', '--strict', '--quiet', '--output', $strict_hdl, $isf_file], $strict_hdl, 'strict');

    my $hdl = slurp($strict_hdl);
    like($hdl, qr/\bmodule\s+burst_reader\b/, 'strict generated HDL contains the burst_reader module');
    like($hdl, qr/\bREAD_BURST_AWAIT_2\b/, 'strict generated HDL contains scheduled await state encodings');
    like($hdl, qr/\bread_burst_cnt_next\s*=\s*beats\s*;/, 'strict generated HDL loads repeat counter from sampled beats');
    like($hdl, qr/\bread_burst_cnt_next\s*=\s*read_burst_cnt\s*-\s*1\s*;/, 'strict generated HDL decrements repeat counter');
    like($hdl, qr/\bread_burst_wd_next\s*=\s*read_burst_wd\s*-\s*1\s*;/, 'strict generated HDL decrements watchdog counter');
    like($hdl, qr/\bdone_pulse_delay_pipe\b/, 'strict generated HDL emits the completion pulse delay pipe');
};

done_testing();

sub lower_burst_fixture {
    my $actor = FSM::Adapter::ISF->new()->parse_file($isf_file);
    my $scheduler = FSM::Scheduler::ISF->new();
    my $result = $scheduler->lower($actor);
    my $report = decode_json($scheduler->report($actor));

    return ($result->{files}{'burst_reader.fsm'}, $report);
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

    ok($success, "$label HDL generation succeeds for the burst-reader fixture");
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
