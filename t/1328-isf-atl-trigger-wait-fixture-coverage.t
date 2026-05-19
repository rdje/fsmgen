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
my $isf_file = File::Spec->catfile($repo_root, 'isf', 'atl_trigger_wait_pipeline.isf');

subtest 'ATL trigger-wait fixture lowers to one scheduled parent artifact' => sub {
    my ($files, $report) = lower_atl_fixture();

    is_deeply(
        sorted([keys %$files]),
        ['atl_trigger_wait_pipeline.fsm'],
        'lowering emits only the selected parent scheduled FSM',
    );

    my $fsm = $files->{'atl_trigger_wait_pipeline.fsm'};
    like($fsm, qr/\A\(\?fsm:atl_trigger_wait_pipeline\b/, 'scheduled FSM names atl_trigger_wait_pipeline');
    like($fsm, qr/\(worker_done 1\)/, 'scheduled FSM exposes worker event handoff input');
    like($fsm, qr/\(worker_process_start 1\)/, 'scheduled FSM exposes worker trigger handoff output');
    like($fsm, qr/\brun_atl_trigger_1\b/, 'scheduled FSM contains the trigger handoff state');
    like($fsm, qr/\brun_await_2\b/, 'scheduled FSM contains the event wait state');
    like($fsm, qr/\(<1 \(worker_process_start> 1\)\)/, 'trigger state pulses the worker process handoff');
    like($fsm, qr/\(<worker_done\s+\(-> run_done_3\)\s+\)/, 'await state waits for the worker done handoff');
    like($fsm, qr/\(<1 \(done> 1\)\)/, 'fixture completes with a one-cycle done pulse');

    assert_report_shape($report);
};

subtest 'ATL trigger-wait fixture strict schedule JSON matches the in-process report' => sub {
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

    ok($success, 'strict schedule JSON generation succeeds for the ATL trigger-wait fixture');
    is($stderr, '', 'strict schedule JSON generation keeps stderr clean');
    is_deeply(
        decode_json($stdout),
        $in_process_report,
        'strict schedule JSON generation matches the in-process report',
    );
};

subtest 'ATL trigger-wait fixture reaches plain and strict HDL generation' => sub {
    my $plain_dir = tempdir(CLEANUP => 1);
    my $plain_hdl = File::Spec->catfile($plain_dir, 'atl_trigger_wait_pipeline_plain.sv');
    my $plain = generate_hdl($plain_hdl, [], 'plain HDL generation');

    like($plain, qr/\bmodule\s+atl_trigger_wait_pipeline\b/, 'plain HDL contains the ATL parent module');
    like($plain, qr/\bRUN_ATL_TRIGGER_1\b/, 'plain HDL contains the trigger state encoding');
    like($plain, qr/\bRUN_AWAIT_2\b/, 'plain HDL contains the event wait state encoding');
    like($plain, qr/\bRUN_TIMEOUT\b/, 'plain HDL contains the default await timeout state encoding');
    like($plain, qr/\bworker_done\b/, 'plain HDL exposes the worker done handoff');
    like($plain, qr/\bworker_process_start\b/, 'plain HDL exposes the worker process trigger handoff');

    my $strict_dir = tempdir(CLEANUP => 1);
    my $strict_hdl = File::Spec->catfile($strict_dir, 'atl_trigger_wait_pipeline_strict.sv');
    my $strict = generate_hdl($strict_hdl, ['--strict'], 'strict HDL generation');

    like($strict, qr/\bmodule\s+atl_trigger_wait_pipeline\b/, 'strict HDL contains the ATL parent module');
    like($strict, qr/\bRUN_ATL_TRIGGER_1\b/, 'strict HDL contains the trigger state encoding');
    like($strict, qr/\bRUN_AWAIT_2\b/, 'strict HDL contains the event wait state encoding');
    like($strict, qr/\bRUN_TIMEOUT\b/, 'strict HDL contains the default await timeout state encoding');
    like($strict, qr/\bworker_done\b/, 'strict HDL exposes the worker done handoff');
    like($strict, qr/\bworker_process_start\b/, 'strict HDL exposes the worker process trigger handoff');
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

    is($report->{source}, 'atl_trigger_wait_pipeline.isf', 'schedule report names the ATL trigger-wait fixture');
    is($report->{scheduled_fsm}, 'atl_trigger_wait_pipeline.fsm', 'schedule report names the scheduled parent FSM');
    is($report->{clock}, 'clk', 'schedule report records the clock');
    is_deeply(
        $report->{reset},
        { name => 'rst_n', kind => 'async', polarity => 'active_low' },
        'schedule report records async active-low reset metadata',
    );
    is($report->{inputs}, 2, 'schedule report input count includes worker event handoff input');
    is($report->{outputs}, 2, 'schedule report output count includes worker trigger handoff output');
    is($report->{port_count}, 4, 'schedule report port count includes generated orchestration handoffs');
    is($report->{state_count}, 5, 'schedule report state count includes the default await timeout state');
    is_deeply($report->{compile_issues}, [], 'schedule report has no compile issues');
    is_deeply($report->{dt_blocks}, [], 'schedule report has no drive bodies');
    is_deeply(
        $report->{transactions},
        [
            {
                name => 'run',
                count => 5,
                states => [qw(
                  run_idle_0
                  run_atl_trigger_1
                  run_await_2
                  run_done_3
                  run_timeout
                )],
            },
        ],
        'schedule report records the trigger-wait transaction state order',
    );

    my $actor_network = $report->{actor_network};
    is($actor_network->{kind}, 'static_declaration', 'actor network kind');
    is_deeply(
        $actor_network->{instances},
        [
            { name => 'worker', actor_type => 'packet_worker', declaration => 'actor' },
        ],
        'report records the worker static actor instance',
    );
    is_deeply($actor_network->{groups}, [], 'trigger-wait fixture has no permanent static group');
    is_deeply($actor_network->{data_movements}, [], 'fixture does not use ATL data movement');
    is_deeply($actor_network->{association_schedules}, [], 'fixture does not use trigger-batch association schedules');
    is_deeply($actor_network->{group_schedules}, [], 'fixture does not use compatibility group schedule evidence');
    is_deeply(
        $actor_network->{event_waits},
        [
            {
                transaction => 'run',
                context     => 'transaction_body',
                instance    => 'worker',
                event       => 'done',
                signal      => 'worker_done',
                source      => 'external_handoff',
            },
        ],
        'report records the worker done event wait handoff',
    );
    is_deeply(
        $actor_network->{transaction_triggers},
        [
            {
                owner_transaction  => 'run',
                context            => 'transaction_body',
                instance           => 'worker',
                target_transaction => 'process',
                signal             => 'worker_process_start',
                sink               => 'external_handoff',
            },
        ],
        'report records the worker process trigger handoff',
    );
}

sub generate_hdl {
    my ($output_file, $extra_args, $label) = @_;
    my @command = ('./bin/fsmgen', @{$extra_args || []}, '--quiet', '--output', $output_file, $isf_file);
    my ($success, undef, $stderr) = run_cli(\@command, $label);

    ok($success, "$label succeeds for the ATL trigger-wait fixture");
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
