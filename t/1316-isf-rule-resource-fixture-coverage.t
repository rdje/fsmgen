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

my $isf_file = File::Spec->catfile($FindBin::Bin, '..', 'isf', 'rule_resource_arbiter.isf');

subtest 'rule/resource fixture lowers to expected scheduled FSM and report structure' => sub {
    my ($fsm, $report) = lower_rule_resource_fixture();

    like($fsm, qr/\A\(\?fsm:rule_resource_arbiter\b/, 'scheduled FSM names the rule_resource_arbiter module');
    like($fsm, qr/\(force 1\)/, 'scheduled FSM preserves force input width');
    like($fsm, qr/\(high_req 1\)/, 'scheduled FSM preserves high request input width');
    like($fsm, qr/\(low_req 1\)/, 'scheduled FSM preserves low request input width');
    like($fsm, qr/\(out 1\)/, 'scheduled FSM preserves out output width');
    like($fsm, qr/\(valid 1\)/, 'scheduled FSM preserves valid output width');
    like($fsm, qr/\(err 1\)/, 'scheduled FSM preserves err output width');
    like($fsm, qr/\(main_update_1\n\s+\(<- \(out> 0\) <\(! force\)\)/, 'transaction write is suppressed by the higher priority force rule');
    like($fsm, qr/\(-force_out <force\n\s+\(<- \(out> 1\)\)/, 'force rule emits a guarded rule DT');
    like($fsm, qr/\(-high <high_req\n\s+\(<- \(valid> 1\)\)/, 'high rule emits the resource-winning guarded rule DT');
    like($fsm, qr/\(-low <\(& low_req \(! high_req\)\)\n\s+\(<- \(err> 1\)\)/, 'low rule is gated by the higher priority resource user');
    like($fsm, qr/\(<1 \(done> 1\)\)/, 'transaction completion remains a one-cycle delayed pulse');

    is($report->{source}, 'rule_resource_arbiter.isf', 'schedule report names the source fixture');
    is($report->{scheduled_fsm}, 'rule_resource_arbiter.fsm', 'schedule report names the scheduled FSM');
    is($report->{clock}, 'clk', 'schedule report records the clock');
    is($report->{watchdog}, '65536', 'schedule report records the watchdog literal');
    is_deeply(
        $report->{reset},
        { name => 'rst_n', kind => 'async', polarity => 'active_low' },
        'schedule report records async active-low reset metadata',
    );
    is($report->{inputs}, 4, 'schedule report input count');
    is($report->{outputs}, 4, 'schedule report output count');
    is($report->{port_count}, 8, 'schedule report port count');
    is($report->{state_count}, 3, 'schedule report transaction state count');
    is_deeply($report->{compile_issues}, [], 'schedule report has no compile issues');

    is_deeply(
        $report->{transactions},
        [
            {
                name => 'main',
                count => 3,
                states => [qw(main_idle_0 main_update_1 main_done_2)],
            },
        ],
        'schedule report records the main transaction state order',
    );
    is_deeply(
        $report->{dt_blocks},
        [
            { name => 'force_out', kind => 'rule', assignments => 1 },
            { name => 'high', kind => 'rule', assignments => 1 },
            { name => 'low', kind => 'rule', assignments => 1 },
        ],
        'schedule report records the three rule DT blocks',
    );
    is_deeply(
        $report->{priority_resolutions},
        [
            {
                target => 'out',
                winner => 'force_out',
                winner_kind => 'rule',
                loser => 'main',
                loser_kind => 'transaction',
            },
        ],
        'schedule report records rule-over-transaction priority resolution',
    );
    is_deeply(
        $report->{resource_arbitration},
        [
            {
                resource => 'shared_slot',
                kind => 'rule_slot',
                arbiter => 'priority',
                user => 'high',
                user_kind => 'rule',
                suppressed_by => [],
            },
            {
                resource => 'shared_slot',
                kind => 'rule_slot',
                arbiter => 'priority',
                user => 'low',
                user_kind => 'rule',
                suppressed_by => ['high'],
            },
        ],
        'schedule report records priority rule_slot arbitration',
    );

    assert_storage($report, 'out', 'register', 'data_register', 1);
    assert_storage($report, 'done', 'register', 'completion_pulse', 1);
};

subtest 'rule/resource fixture strict schedule JSON matches the in-process report' => sub {
    my (undef, $in_process_report) = lower_rule_resource_fixture();
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

    ok($success, 'strict schedule JSON generation succeeds for the rule/resource fixture');
    is($stderr, '', 'strict schedule JSON generation keeps stderr clean');
    is_deeply(
        decode_json($stdout),
        $in_process_report,
        'strict schedule JSON generation matches the in-process report',
    );
};

subtest 'rule/resource fixture reaches plain and strict HDL generation' => sub {
    my $tempdir = tempdir(CLEANUP => 1);
    my $plain_hdl = File::Spec->catfile($tempdir, 'rule_resource_plain.sv');
    my $strict_hdl = File::Spec->catfile($tempdir, 'rule_resource_strict.sv');

    run_hdl_generation(['./bin/fsmgen', '--quiet', '--output', $plain_hdl, $isf_file], $plain_hdl, 'plain');
    run_hdl_generation(['./bin/fsmgen', '--strict', '--quiet', '--output', $strict_hdl, $isf_file], $strict_hdl, 'strict');

    my $hdl = slurp($strict_hdl);
    like($hdl, qr/\bmodule\s+rule_resource_arbiter\b/, 'strict generated HDL contains the rule_resource_arbiter module');
    like($hdl, qr/\bMAIN_UPDATE_1\b/, 'strict generated HDL contains transaction update state encoding');
    like($hdl, qr/\bforce_out_en\s*=\s*force\s*;/, 'strict generated HDL preserves force rule guard');
    like($hdl, qr/\bhigh_en\s*=\s*high_req\s*;/, 'strict generated HDL preserves high rule guard');
    like($hdl, qr/\blow_en\s*=\s*intermediate_and_low_req_not_high_req_1\s*;/, 'strict generated HDL gates the low rule by the resource winner');
    like($hdl, qr/\bintermediate_and_low_req_not_high_req_1\s*=\s*low_req\s*&\s*!high_req\s*;/, 'strict generated HDL computes low request suppression');
    like($hdl, qr/\bout_next\s*=\s*0\s*;/, 'strict generated HDL keeps the transaction out write');
    like($hdl, qr/\bout_next\s*=\s*1\s*;/, 'strict generated HDL keeps the force rule out write');
    like($hdl, qr/\bvalid_next\s*=\s*1\s*;/, 'strict generated HDL keeps the high rule valid write');
    like($hdl, qr/\berr_next\s*=\s*1\s*;/, 'strict generated HDL keeps the low rule err write');
    like($hdl, qr/\bdone_pulse_delay_pipe\b/, 'strict generated HDL implements delayed completion pulse state');
};

done_testing();

sub lower_rule_resource_fixture {
    my $actor = FSM::Adapter::ISF->new()->parse_file($isf_file);
    my $scheduler = FSM::Scheduler::ISF->new();
    my $result = $scheduler->lower($actor);
    my $report = decode_json($scheduler->report($actor));

    return ($result->{files}{'rule_resource_arbiter.fsm'}, $report);
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
    my ($success, undef, $stderr) = run_cli($command, "$label HDL generation");

    ok($success, "$label HDL generation succeeds for the rule/resource fixture");
    is($stderr, '', "$label HDL generation keeps stderr clean");
    ok(-f $output, "$label HDL generation writes the requested output");
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
