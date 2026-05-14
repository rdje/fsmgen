#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use File::Spec;
use FindBin;
use IPC::Cmd qw(run);
use JSON::PP ();

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::Adapter::ISF;
use FSM::Scheduler::ISF;
use FSM::Support::ISFPublicInterfaceContract qw(
    build_isf_public_interface_contract
    isf_public_interface_schedule_report_multi_file_scope
    isf_public_interface_schedule_report_top_level_keys
);

subtest 'multi-file ISF report is parent-scoped with generated composition metadata' => sub {
    my $path = File::Spec->catfile($FindBin::Bin, '..', 'isf', 'spawn_parent.isf');
    my $actor = FSM::Adapter::ISF->new()->parse_file($path);
    my $scheduler = FSM::Scheduler::ISF->new();

    my $lowered = $scheduler->lower($actor);
    is_deeply(
        sorted([keys %{$lowered->{files}}]),
        [qw(child_worker.fsm spawn_parent.fsm spawn_parent_top.fsm)],
        'fixture still lowers to parent, child, and generated top files',
    );

    my $report = JSON::PP->new->decode($scheduler->report($actor));
    is_deeply(
        sorted([keys %$report]),
        sorted(isf_public_interface_schedule_report_top_level_keys()),
        'multi-file schedule report keeps the advertised top-level keys',
    );
    is($report->{source}, 'spawn_parent.isf', 'report source is the parent actor');
    is($report->{scheduled_fsm}, 'spawn_parent.fsm', 'report scheduled_fsm is the parent module');
    is_deeply(
        [map { $_->{name} } @{$report->{transactions}}],
        [qw(parent_main)],
        'report transaction summary is parent-scoped',
    );
    is_deeply(
        [map { $_->{name} } @{$report->{dt_blocks}}],
        [qw(rdata)],
        'report DT summary is parent-scoped',
    );
    is($report->{generated_composition}{kind}, 'spawn_generated_top', 'report exposes generated composition kind');
    is($report->{generated_composition}{top_module}, 'spawn_parent_top', 'report exposes generated top module');
    is($report->{generated_composition}{top_fsm}, 'spawn_parent_top.fsm', 'report exposes generated top file');
    is_deeply(
        $report->{generated_composition}{parent},
        { module => 'spawn_parent', scheduled_fsm => 'spawn_parent.fsm' },
        'report exposes parent composition summary',
    );
    is_deeply(
        [map { $_->{instance} } @{$report->{generated_composition}{instances}}],
        [qw(w0 w1 w2)],
        'report exposes spawned instance summaries',
    );

    my $cli_report = run_schedule_json($path);
    is_deeply(
        $cli_report->{generated_composition},
        $report->{generated_composition},
        'CLI multi-file schedule report exposes the same generated composition metadata',
    );

    my $contract = build_isf_public_interface_contract();
    is(
        $contract->{schedule_report_multi_file_scope},
        isf_public_interface_schedule_report_multi_file_scope(),
        'contract advertises the current multi-file schedule-report scope',
    );
};

done_testing();

sub sorted {
    my ($values) = @_;
    return [sort @{$values || []}];
}

sub run_schedule_json {
    my ($path) = @_;
    my ($success, $error_message, $full_buf, $stdout_buf, $stderr_buf) = run(
        command => ['./bin/fsmgen', '--emit-schedule-json', $path],
    );

    ok($success, '--emit-schedule-json succeeds for the multi-file fixture');
    is(join('', @{$stderr_buf || []}), '', '--emit-schedule-json keeps stderr clean');

    return JSON::PP->new->decode(join('', @{$stdout_buf || []}));
}
