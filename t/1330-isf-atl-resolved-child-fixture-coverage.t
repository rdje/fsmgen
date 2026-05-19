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

my $repo_root = File::Spec->catdir($FindBin::Bin, '..');
my $isf_file = File::Spec->catfile($repo_root, 'isf', 'atl_resolved_child_pipeline.isf');

subtest 'ATL resolved-child fixture lowers to parent plus child artifacts' => sub {
    my ($files, $report) = lower_atl_fixture();

    is_deeply(
        sorted([keys %$files]),
        [
            'atl_resolved_child_pipeline.fsm',
            'atl_resolved_child_pipeline__worker.fsm',
        ],
        'lowering emits exactly the parent and resolved child scheduled FSM artifacts',
    );

    ok(!exists $files->{'atl_resolved_child_pipeline_top.fsm'}, 'lowering emits no generated ATL top');

    my $parent = $files->{'atl_resolved_child_pipeline.fsm'};
    like($parent, qr/\A\(\?fsm:atl_resolved_child_pipeline\b/, 'parent scheduled FSM uses the fixture module name');
    like($parent, qr/\(worker_done 1\)/, 'parent exposes the worker event handoff input');
    like($parent, qr/\(worker_process_start 1\)/, 'parent exposes the worker trigger handoff output');
    like($parent, qr/\brun_atl_trigger_1\b/, 'parent contains the trigger handoff state');
    like($parent, qr/\brun_await_2\b/, 'parent contains the event wait state');
    like($parent, qr/\(<1 \(worker_process_start> 1\)\)/, 'trigger state pulses the worker process handoff');
    like($parent, qr/\(<worker_done\s+\(-> run_done_3\)\s+\)/, 'await state waits for the worker done handoff');

    my $child = $files->{'atl_resolved_child_pipeline__worker.fsm'};
    like($child, qr/\A\(\?fsm:atl_resolved_child_pipeline__worker\b/, 'child scheduled FSM uses the resolved child module name');
    like($child, qr/\(process_start 1\)/, 'child keeps its authored process_start input');
    like($child, qr/\(done 1\)/, 'child keeps its authored done output');
    like($child, qr/\bprocess_idle_0\b/, 'child keeps its process transaction entry state');

    assert_report_shape($report);
};

subtest 'ATL resolved-child fixture strict schedule JSON matches the in-process report' => sub {
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

    ok($success, 'strict schedule JSON generation succeeds for the ATL resolved-child fixture');
    is($stderr, '', 'strict schedule JSON generation keeps stderr clean');
    is_deeply(
        decode_json($stdout),
        $in_process_report,
        'strict schedule JSON generation matches the in-process report',
    );
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

    is($report->{source}, 'atl_resolved_child_pipeline.isf', 'schedule report names the ATL resolved-child fixture');
    is($report->{scheduled_fsm}, 'atl_resolved_child_pipeline.fsm', 'schedule report names the scheduled parent FSM');
    is($report->{clock}, 'clk', 'schedule report records the clock');
    is_deeply(
        $report->{reset},
        { name => 'rst_n', kind => 'async', polarity => 'active_low' },
        'schedule report records async active-low reset metadata',
    );
    is($report->{inputs}, 2, 'schedule report input count includes the worker event handoff');
    is($report->{outputs}, 2, 'schedule report output count includes the worker trigger handoff');
    is($report->{port_count}, 4, 'schedule report port count includes generated orchestration handoffs');
    is($report->{state_count}, 5, 'schedule report state count includes the default await timeout state');
    is_deeply($report->{compile_issues}, [], 'schedule report has no compile issues');
    is_deeply($report->{dt_blocks}, [], 'schedule report has no drive bodies');
    is_deeply($report->{library_uses}, [], 'ATL resolved child does not appear as a reusable-library use');

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
        'schedule report records the resolved-child transaction state order',
    );

    my $actor_network = $report->{actor_network};
    is($actor_network->{kind}, 'static_declaration', 'actor network kind');
    is_deeply(
        $actor_network->{instances},
        [
            {
                name            => 'worker',
                actor_type      => 'pkt_lib.packet_worker',
                declaration     => 'actor',
                type_resolution => 'library_actor_export',
                library         => 'common.packet',
                alias           => 'pkt_lib',
                export          => 'packet_worker',
                module          => 'atl_resolved_child_pipeline__worker',
                scheduled_fsm   => 'atl_resolved_child_pipeline__worker.fsm',
            },
        ],
        'report records the resolved child actor metadata',
    );
    is_deeply($actor_network->{groups}, [], 'fixture has no permanent static group');
    is_deeply($actor_network->{data_movements}, [], 'fixture does not use ATL data movement');
    is_deeply($actor_network->{association_schedules}, [], 'fixture does not use trigger-batch association schedules');
    is_deeply($actor_network->{group_schedules}, [], 'fixture does not use compatibility group schedule evidence');
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
        'report records the worker done event handoff',
    );
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

sub sorted {
    my ($values) = @_;
    return [sort @{$values || []}];
}
