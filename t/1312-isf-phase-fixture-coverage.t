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

my $isf_file = File::Spec->catfile($FindBin::Bin, '..', 'isf', 'phase_test.isf');

subtest 'phase fixture lowers to pass-through scheduled FSM structure' => sub {
    my ($fsm, $report) = lower_phase_fixture();

    like($fsm, qr/\A\(\?fsm:phase_test\b/, 'scheduled FSM names the phase_test module');
    like($fsm, qr/\(rdata 32\)/, 'scheduled FSM preserves rdata output width');
    like($fsm, qr/\(t_idle_0\n\s+\(= \(can_accept 1\)\)/, 'scheduled FSM exposes the idle can_accept marker');
    like($fsm, qr/\(t_phase_1\n\s+\(-> t_phase_2\)/, 'first transaction phase is a pass-through state');
    like($fsm, qr/\(t_phase_2\n\s+\(-> t_phase_3\)/, 'second transaction phase is a pass-through state');
    like($fsm, qr/\(t_phase_3\n\s+\(-> t_done_4\)/, 'last transaction phase exits to completion');
    like($fsm, qr/\(<1 \(done> 1\)\)/, 'completion remains a one-cycle delayed pulse');
    like($fsm, qr/\(-rdata\n\s+\(<- \(rdata> rdata_val\) <rdata_start\)/, 'rdata drive block remains available');
    unlike($fsm, qr/\(-done\b/, 'scheduled FSM no longer emits a reusable done drive block');
    unlike($fsm, qr/\(done_start\b/, 'scheduled FSM no longer declares a done drive request');
    unlike($fsm, qr/\(done_val\b/, 'scheduled FSM no longer declares a done drive payload');

    is($report->{source}, 'phase_test.isf', 'schedule report names the source fixture');
    is($report->{scheduled_fsm}, 'phase_test.fsm', 'schedule report names the generated FSM');
    is($report->{clock}, 'clk', 'schedule report records the clock');
    is_deeply(
        $report->{reset},
        { name => 'rst_n', kind => 'async', polarity => 'active_low' },
        'schedule report records async active-low reset metadata',
    );
    is($report->{inputs}, 1, 'schedule report input count');
    is($report->{outputs}, 2, 'schedule report output count');
    is($report->{port_count}, 3, 'schedule report port count');
    is($report->{state_count}, 5, 'schedule report state count');
    is_deeply($report->{compile_issues}, [], 'schedule report has no compile issues');
    is_deeply($report->{transaction_stages}, [], 'phase fixture does not claim ready/valid stage lowering');

    is_deeply(
        $report->{transactions},
        [
            {
                name => 't',
                count => 5,
                states => [qw(
                  t_idle_0
                  t_phase_1
                  t_phase_2
                  t_phase_3
                  t_done_4
                )],
            },
        ],
        'schedule report records the transaction phase state order',
    );

    is_deeply(
        [map { $_->{name} } @{$report->{dt_blocks}}],
        [qw(rdata)],
        'schedule report records only the rdata named drive DT block',
    );

    assert_storage($report, 'done', 'register', 'completion_pulse', 1);
    assert_storage($report, 'rdata_start', 'counter', 'drive_request', 1);
    assert_storage($report, 'rdata_val', 'counter', 'drive_payload', 32);
    my @done_drive_storage = grep {
        $_->{name} eq 'done_start' || $_->{name} eq 'done_val'
    } @{$report->{inferred_storage} || []};
    is_deeply(\@done_drive_storage, [], 'schedule report has no reusable done-drive storage');
};

subtest 'phase fixture schedule JSON CLI matches the in-process report' => sub {
    my (undef, $in_process_report) = lower_phase_fixture();
    my ($success, $error_message, $full_buf, $stdout_buf, $stderr_buf) = run(
        command => [
            './bin/fsmgen',
            '--strict',
            '--quiet',
            '--emit-schedule-json',
            $isf_file,
        ],
    );

    ok($success, 'strict schedule JSON generation succeeds for the phase fixture');
    is(join('', @{$stderr_buf || []}), '', 'strict schedule JSON generation keeps stderr clean');
    is_deeply(
        decode_json(join('', @{$stdout_buf || []})),
        $in_process_report,
        'strict schedule JSON generation matches the in-process report',
    );
};

subtest 'phase fixture reaches plain and strict HDL generation' => sub {
    my $tempdir = tempdir(CLEANUP => 1);
    my $plain_hdl = File::Spec->catfile($tempdir, 'phase_test_plain.sv');
    my $strict_hdl = File::Spec->catfile($tempdir, 'phase_test_strict.sv');

    run_hdl_generation(['./bin/fsmgen', '--quiet', '--output', $plain_hdl, $isf_file], $plain_hdl, 'plain');
    run_hdl_generation(['./bin/fsmgen', '--strict', '--quiet', '--output', $strict_hdl, $isf_file], $strict_hdl, 'strict');

    my $hdl = slurp($strict_hdl);
    like($hdl, qr/\bmodule\s+phase_test\b/, 'strict generated HDL contains the phase_test module');
    like($hdl, qr/\bT_PHASE_1\b/, 'strict generated HDL contains first phase state encoding');
    like($hdl, qr/\bT_PHASE_2\b/, 'strict generated HDL contains second phase state encoding');
    like($hdl, qr/\bT_PHASE_3\b/, 'strict generated HDL contains last phase state encoding');
    like($hdl, qr/\bdone_pulse_delay_pipe\b/, 'strict generated HDL implements delayed completion pulse state');
    unlike($hdl, qr/\bdone_val\b/, 'strict generated HDL has no reusable done-drive payload');
    unlike($hdl, qr/\bdone_start\b/, 'strict generated HDL has no reusable done-drive request');
};

done_testing();

sub lower_phase_fixture {
    my $actor = FSM::Adapter::ISF->new()->parse_file($isf_file);
    my $scheduler = FSM::Scheduler::ISF->new();
    my $result = $scheduler->lower($actor);
    my $report = decode_json($scheduler->report($actor));

    return ($result->{files}{'phase_test.fsm'}, $report);
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

    ok($success, "$label HDL generation succeeds for the phase fixture");
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
