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

my $isf_file = File::Spec->catfile($FindBin::Bin, '..', 'isf', 'stream_stage_contract.isf');

subtest 'stage/contract fixture lowers to expected scheduled FSM and report structure' => sub {
    my ($fsm, $report) = lower_stage_contract_fixture();

    like($fsm, qr/\A\(\?fsm:stream_stage_contract\b/, 'scheduled FSM names the stream_stage_contract module');
    like($fsm, qr/\(data_in 8\)/, 'scheduled FSM preserves input payload width');
    like($fsm, qr/\(data_out 8\)/, 'scheduled FSM preserves output payload width');
    like($fsm, qr/\(main_contract_3_age 2\)/, 'scheduled FSM sizes the contract age counter');
    like($fsm, qr/\(main_idle_0\n\s+\(= \(can_accept 1\)\)\n\s+\(<= \(captured data_in\) <start\)/, 'idle state samples the payload on start');
    like($fsm, qr/\(main_set_1\n\s+\(<- \(data_out> captured\)\)\n\s+\(-> main_stage_2\)\n\s+\)/, 'set state forwards the sampled payload');
    like($fsm, qr/\(main_stage_2\n\s+\(= \(valid> 1\)\)\n\s+\(<ready\n\s+\(-> main_contract_3\)\n\s+\)\n\s+\)/, 'stage state drives valid and advances only under ready');
    like($fsm, qr/\(main_contract_3\n\s+\(= \(main_contract_3_arm 1\)\)\n\s+\(-> main_done_4\)\n\s+\)/, 'contract state arms the bounded eventual monitor');
    like($fsm, qr/\(<1 \(done> 1\)\)/, 'transaction completion remains a one-cycle delayed pulse');
    like($fsm, qr/\(-main_contract_3_monitor\n\s+\(<- \(main_contract_3_pending 1\) <\(& main_contract_3_arm \(! main_contract_3_pending\)\)\)/, 'contract monitor owns pending storage');
    like($fsm, qr/\(<- \(main_contract_3_fail 1\) <\(\| \(& main_contract_3_arm main_contract_3_pending\) \(& main_contract_3_pending \(! ack\) \(== main_contract_3_age 2\)\)\)\)/, 'contract monitor raises sticky fail on overlap or timeout');

    is($report->{source}, 'stream_stage_contract.isf', 'schedule report names the source fixture');
    is($report->{scheduled_fsm}, 'stream_stage_contract.fsm', 'schedule report names the scheduled FSM');
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
    is($report->{state_count}, 5, 'schedule report transaction state count');
    is_deeply($report->{compile_issues}, [], 'schedule report has no compile issues');

    is_deeply(
        $report->{transactions},
        [
            {
                name => 'main',
                count => 5,
                states => [qw(main_idle_0 main_set_1 main_stage_2 main_contract_3 main_done_4)],
            },
        ],
        'schedule report records the main transaction state order',
    );
    is_deeply(
        $report->{dt_blocks},
        [
            { name => 'main_contract_3_monitor', kind => 'temporal_contract_monitor', assignments => 5 },
        ],
        'schedule report records the temporal contract monitor DT block',
    );
    is_deeply(
        $report->{transaction_stages},
        [
            {
                transaction => 'main',
                name        => 'accept',
                kind        => 'ready_valid_barrier',
                state       => 'main_stage_2',
                ready       => 'ready',
                valid       => 'valid',
            },
        ],
        'schedule report records the ready/valid stage summary',
    );
    is_deeply(
        $report->{temporal_contracts},
        [
            {
                transaction          => 'main',
                name                 => 'ack_seen',
                kind                 => 'bounded_eventually',
                trigger              => 'main_contract_3',
                signal               => 'ack',
                within_cycles        => 3,
                pending_signal       => 'main_contract_3_pending',
                counter_signal       => 'main_contract_3_age',
                fail_signal          => 'main_contract_3_fail',
                overlap_policy       => 'fail',
                reset_policy         => {
                    name     => 'rst_n',
                    kind     => 'async',
                    polarity => 'active_low',
                },
                assertion_projection => 'systemverilog_sticky_fail',
            },
        ],
        'schedule report records the bounded eventual contract summary',
    );

    assert_storage($report, 'captured', 'register', 'sample_alias', 8);
    assert_storage($report, 'data_out', 'register', 'data_register', 8);
    assert_storage($report, 'done', 'register', 'completion_pulse', 1);
    assert_storage($report, 'main_contract_3_age', 'counter', 'temporal_contract_monitor', 2);
    assert_storage($report, 'main_contract_3_fail', 'register', 'temporal_contract_monitor', 1);
    assert_storage($report, 'main_contract_3_pending', 'register', 'temporal_contract_monitor', 1);
    assert_no_storage($report, 'main_contract_3_arm');
};

subtest 'stage/contract fixture strict schedule JSON matches the in-process report' => sub {
    my (undef, $in_process_report) = lower_stage_contract_fixture();
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

    ok($success, 'strict schedule JSON generation succeeds for the stage/contract fixture');
    is($stderr, '', 'strict schedule JSON generation keeps stderr clean');
    is_deeply(
        decode_json($stdout),
        $in_process_report,
        'strict schedule JSON generation matches the in-process report',
    );
};

subtest 'stage/contract fixture reaches plain and strict HDL generation' => sub {
    my $tempdir = tempdir(CLEANUP => 1);
    my $plain_hdl = File::Spec->catfile($tempdir, 'stage_contract_plain.sv');
    my $strict_hdl = File::Spec->catfile($tempdir, 'stage_contract_strict.sv');

    run_hdl_generation(['./bin/fsmgen', '--quiet', '--output', $plain_hdl, $isf_file], $plain_hdl, 'plain');
    run_hdl_generation(['./bin/fsmgen', '--strict', '--quiet', '--output', $strict_hdl, $isf_file], $strict_hdl, 'strict');

    my $hdl = slurp($strict_hdl);
    like($hdl, qr/\bmodule\s+stream_stage_contract\b/, 'strict generated HDL contains the stream_stage_contract module');
    like($hdl, qr/\bMAIN_STAGE_2\b/, 'strict generated HDL contains the ready/valid stage state encoding');
    like($hdl, qr/\bMAIN_CONTRACT_3\b/, 'strict generated HDL contains the contract arm state encoding');
    like($hdl, qr/\bmain_idle_0_captured_data_in_en\s*=\s*main_idle_0_en\s*&\s*start\s*;/, 'strict generated HDL captures payload under start');
    like($hdl, qr/\bmain_set_1_data_out_captured_en\s*=\s*main_set_1_en\s*&\s*1'b1\s*;/, 'strict generated HDL forwards captured payload');
    like($hdl, qr/\bmain_stage_2_next_state_main_contract_3_en\s*=\s*main_stage_2_en\s*&\s*ready\s*;/, 'strict generated HDL gates stage exit by ready');
    like($hdl, qr/\bmain_stage_2_valid_1_en\s*=\s*main_stage_2_en\s*&\s*1'b1\s*;/, 'strict generated HDL drives valid while the stage is active');
    like($hdl, qr/\bmain_contract_3_main_contract_3_arm_1_en\s*=\s*main_contract_3_en\s*&\s*1'b1\s*;/, 'strict generated HDL arms the contract monitor');
    like($hdl, qr/\bmain_contract_3_fail_next\s*=\s*1\s*;/, 'strict generated HDL carries the sticky fail update');
    like($hdl, qr/\bdone_pulse_delay_pipe\b/, 'strict generated HDL implements delayed completion pulse state');
    like($hdl, qr/assert \(!main_contract_3_fail\) else \$error\("temporal contract failed: main\.ack_seen"\);/, 'strict SystemVerilog projects the temporal assertion');
};

done_testing();

sub lower_stage_contract_fixture {
    my $actor = FSM::Adapter::ISF->new()->parse_file($isf_file);
    my $scheduler = FSM::Scheduler::ISF->new();
    my $result = $scheduler->lower($actor);
    my $report = decode_json($scheduler->report($actor));

    return ($result->{files}{'stream_stage_contract.fsm'}, $report);
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

sub assert_no_storage {
    my ($report, $name) = @_;
    my @entries = grep { $_->{name} eq $name } @{$report->{inferred_storage} || []};

    is(scalar(@entries), 0, "storage entry '$name' is not reported");
}

sub run_hdl_generation {
    my ($command, $output, $label) = @_;
    my ($success, undef, $stderr) = run_cli($command, "$label HDL generation");

    ok($success, "$label HDL generation succeeds for the stage/contract fixture");
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
