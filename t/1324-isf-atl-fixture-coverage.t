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

my $repo_root = File::Spec->catdir($FindBin::Bin, '..');
my $isf_file = File::Spec->catfile($repo_root, 'isf', 'atl_trigger_batch_pipeline.isf');

subtest 'ATL temporary trigger-batch fixture lowers to one scheduled parent artifact' => sub {
    my ($files, $report) = lower_atl_fixture();

    is_deeply(
        sorted([keys %$files]),
        ['atl_trigger_batch_pipeline.fsm'],
        'lowering emits only the selected parent scheduled FSM',
    );

    my $fsm = $files->{'atl_trigger_batch_pipeline.fsm'};
    like($fsm, qr/\A\(\?fsm:atl_trigger_batch_pipeline\b/, 'scheduled FSM names atl_trigger_batch_pipeline');
    like($fsm, qr/\(reader_capture_start 1\)/, 'scheduled FSM exposes reader trigger handoff');
    like($fsm, qr/\(filter_process_start 1\)/, 'scheduled FSM exposes filter trigger handoff');
    like($fsm, qr/\(writer_emit_start 1\)/, 'scheduled FSM exposes writer trigger handoff');
    like($fsm, qr/run_atl_trigger_batch_/, 'scheduled FSM contains one temporary batch trigger state');
    unlike($fsm, qr/run_atl_trigger_[0-9]/, 'scheduled FSM does not split the batch into per-trigger states');
    like($fsm, qr/\(<1 \(reader_capture_start> 1\)\)/, 'temporary batch state pulses reader capture');
    like($fsm, qr/\(<1 \(filter_process_start> 1\)\)/, 'temporary batch state pulses filter process');
    like($fsm, qr/\(<1 \(writer_emit_start> 1\)\)/, 'temporary batch state pulses writer emit');
    like($fsm, qr/\(<1 \(done> 1\)\)/, 'fixture still completes with a one-cycle done pulse');

    assert_report_shape($report);
};

subtest 'ATL temporary trigger-batch fixture strict schedule JSON matches the in-process report' => sub {
    my (undef, $in_process_report) = lower_atl_fixture();
    my ($success, $stdout, $stderr) = run_cli(
        [
            './bin/fsmgen',
            '--strict',
            '--quiet',
            '--emit-schedule-json',
            $isf_file,
        ],
        'strict schedule JSON generation',
    );

    ok($success, 'strict schedule JSON generation succeeds for the ATL fixture');
    is($stderr, '', 'strict schedule JSON generation keeps stderr clean');
    is_deeply(
        decode_json($stdout),
        $in_process_report,
        'strict schedule JSON generation matches the in-process report',
    );
};

subtest 'ATL temporary trigger-batch fixture reaches plain and strict HDL generation' => sub {
    my $plain_dir = tempdir(CLEANUP => 1);
    my $plain_hdl = File::Spec->catfile($plain_dir, 'atl_trigger_batch_pipeline_plain.sv');
    my $plain = generate_hdl($plain_hdl, [], 'plain HDL generation');

    like($plain, qr/\bmodule\s+atl_trigger_batch_pipeline\b/, 'plain HDL contains the ATL parent module');
    like($plain, qr/\bRUN_ATL_TRIGGER_BATCH_1\b/, 'plain HDL contains the temporary batch trigger state encoding');

    my $strict_dir = tempdir(CLEANUP => 1);
    my $strict_hdl = File::Spec->catfile($strict_dir, 'atl_trigger_batch_pipeline_strict.sv');
    my $strict = generate_hdl($strict_hdl, ['--strict'], 'strict HDL generation');

    like($strict, qr/\bmodule\s+atl_trigger_batch_pipeline\b/, 'strict HDL contains the ATL parent module');
    like($strict, qr/\bRUN_ATL_TRIGGER_BATCH_1\b/, 'strict HDL contains the temporary batch trigger state encoding');
    like($strict, qr/\breader_capture_start\b/, 'strict HDL exposes reader trigger handoff');
    like($strict, qr/\bfilter_process_start\b/, 'strict HDL exposes filter trigger handoff');
    like($strict, qr/\bwriter_emit_start\b/, 'strict HDL exposes writer trigger handoff');
    like($strict, qr/\bdone_pulse_delay_pipe\b/, 'strict HDL implements delayed completion pulse state');
};

done_testing();

sub lower_atl_fixture {
    my $actor = FSM::Adapter::ISF->new()->parse_file($isf_file);
    my $scheduler = FSM::Scheduler::ISF->new();
    my $result = $scheduler->lower($actor);
    my $report = decode_json($scheduler->report($actor));

    return ($result->{files}, $report);
}

sub assert_report_shape {
    my ($report) = @_;

    is($report->{source}, 'atl_trigger_batch_pipeline.isf', 'schedule report names the ATL fixture');
    is($report->{scheduled_fsm}, 'atl_trigger_batch_pipeline.fsm', 'schedule report names the scheduled parent FSM');
    is($report->{clock}, 'clk', 'schedule report records the clock');
    is_deeply(
        $report->{reset},
        { name => 'rst_n', kind => 'async', polarity => 'active_low' },
        'schedule report records async active-low reset metadata',
    );
    is($report->{inputs}, 1, 'schedule report input count');
    is($report->{outputs}, 4, 'schedule report output count includes generated trigger outputs');
    is($report->{port_count}, 5, 'schedule report port count includes generated trigger handoffs');
    is($report->{state_count}, 3, 'schedule report state count');
    is_deeply($report->{compile_issues}, [], 'schedule report has no compile issues');

    is_deeply(
        $report->{transactions},
        [
            {
                name => 'run',
                count => 3,
                states => [qw(
                  run_idle_0
                  run_atl_trigger_batch_1
                  run_done_2
                )],
            },
        ],
        'schedule report records the temporary trigger-batch transaction state order',
    );

    my $actor_network = $report->{actor_network};
    is($actor_network->{kind}, 'static_declaration', 'actor network kind');
    is_deeply(
        $actor_network->{instances},
        [
            { name => 'reader', actor_type => 'packet_reader', declaration => 'actor' },
            { name => 'filter', actor_type => 'packet_filter', declaration => 'actor' },
            { name => 'writer', actor_type => 'packet_writer', declaration => 'actor' },
        ],
        'report records the three static actor instances',
    );
    is_deeply($actor_network->{groups}, [], 'temporary trigger-batch fixture has no permanent static group');
    is_deeply($actor_network->{event_waits}, [], 'fixture does not use actor event waits');
    is_deeply($actor_network->{data_movements}, [], 'fixture does not use ATL data movement');
    is_deeply(
        $actor_network->{transaction_triggers},
        [
            {
                owner_transaction  => 'run',
                context            => 'transaction_body',
                instance           => 'reader',
                target_transaction => 'capture',
                signal             => 'reader_capture_start',
                sink               => 'external_handoff',
            },
            {
                owner_transaction  => 'run',
                context            => 'transaction_body',
                instance           => 'filter',
                target_transaction => 'process',
                signal             => 'filter_process_start',
                sink               => 'external_handoff',
            },
            {
                owner_transaction  => 'run',
                context            => 'transaction_body',
                instance           => 'writer',
                target_transaction => 'emit',
                signal             => 'writer_emit_start',
                sink               => 'external_handoff',
            },
        ],
        'report records per-target trigger handoffs',
    );
    is_deeply(
        $actor_network->{group_schedules},
        [
            {
                group               => 'run_trigger_batch',
                owner_transaction   => 'run',
                context             => 'transaction_body',
                members             => [qw(reader filter writer)],
                target_transactions => [qw(capture process emit)],
                signals             => [qw(reader_capture_start filter_process_start writer_emit_start)],
                schedule            => 'same_cycle_external_trigger_batch',
                dependency_policy   => 'transaction_body_distinct_instances',
                storage             => 'none',
                source              => 'parent_trigger_state',
                sink                => 'external_handoff',
            },
        ],
        'report records the temporary trigger-batch schedule evidence',
    );
}

sub generate_hdl {
    my ($output_file, $extra_args, $label) = @_;
    my @command = ('./bin/fsmgen', @{$extra_args || []}, '--quiet', '--output', $output_file, $isf_file);
    my ($success, undef, $stderr) = run_cli(\@command, $label);

    ok($success, "$label succeeds for the ATL fixture");
    is($stderr, '', "$label keeps stderr clean");
    ok(-f $output_file, "$label writes the requested output");

    return slurp($output_file);
}

sub run_cli {
    my ($command, $label) = @_;
    my ($success, $error_message, $full_buf, $stdout_buf, $stderr_buf) =
      run(command => $command);

    diag("$label failed: $error_message") if !$success && defined $error_message;
    return (
        $success,
        join('', @{$stdout_buf || []}),
        join('', @{$stderr_buf || []}),
    );
}

sub slurp {
    my ($path) = @_;
    open my $fh, '<', $path or die "cannot read $path: $!";
    my $text = do { local $/; <$fh> };
    close $fh or die "cannot close $path: $!";
    return $text;
}

sub sorted {
    my ($values) = @_;
    return [sort @{$values || []}];
}
