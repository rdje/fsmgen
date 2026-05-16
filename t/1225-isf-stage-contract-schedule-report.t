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
use FSM::Support::ISFPublicInterfaceContract qw(
    isf_public_interface_schedule_report_temporal_contract_assertion_projection_values
    isf_public_interface_schedule_report_temporal_contract_keys
    isf_public_interface_schedule_report_temporal_contract_kind_values
    isf_public_interface_schedule_report_temporal_contract_overlap_policy_values
    isf_public_interface_schedule_report_top_level_keys
    isf_public_interface_schedule_report_transaction_stage_keys
    isf_public_interface_schedule_report_transaction_stage_kind_values
);

subtest 'stage and temporal contract summaries expose bounded public metadata' => sub {
    my $report = report_source(stage_contract_source(), 'stage-contract-report.isf');

    is_deeply(
        sorted([keys %$report]),
        sorted(isf_public_interface_schedule_report_top_level_keys()),
        'report exposes exactly the advertised top-level keys',
    );

    is(scalar(@{$report->{transaction_stages}}), 1, 'one transaction stage summary is reported');
    my $stage = $report->{transaction_stages}[0];
    is_deeply(
        sorted([keys %$stage]),
        sorted(isf_public_interface_schedule_report_transaction_stage_keys()),
        'stage summary exposes exactly the advertised keys',
    );
    is_deeply(
        $stage,
        {
            transaction => 'main',
            name        => 'accept',
            kind        => 'ready_valid_barrier',
            state       => 'main_stage_1',
            ready       => 'ready',
            valid       => 'valid',
        },
        'stage summary preserves authored endpoints and generated state',
    );
    ok(
        advertised($stage->{kind}, isf_public_interface_schedule_report_transaction_stage_kind_values()),
        'stage kind is advertised',
    );

    is(scalar(@{$report->{temporal_contracts}}), 1, 'one temporal contract summary is reported');
    my $contract = $report->{temporal_contracts}[0];
    is_deeply(
        sorted([keys %$contract]),
        sorted(isf_public_interface_schedule_report_temporal_contract_keys()),
        'contract summary exposes exactly the advertised keys',
    );
    is_deeply(
        $contract,
        {
            transaction          => 'main',
            name                 => 'ack_seen',
            kind                 => 'bounded_eventually',
            trigger              => 'main_contract_2',
            signal               => 'ack',
            within_cycles        => 3,
            pending_signal       => 'main_contract_2_pending',
            counter_signal       => 'main_contract_2_age',
            fail_signal          => 'main_contract_2_fail',
            overlap_policy       => 'fail',
            reset_policy         => {
                name     => 'rst_n',
                kind     => 'async',
                polarity => 'active_low',
            },
            assertion_projection => 'systemverilog_sticky_fail',
        },
        'contract summary exposes bounded check metadata and reset policy',
    );
    ok(!exists $contract->{arm_signal}, 'contract summary does not expose the internal arm signal');
    ok(!exists $contract->{monitor_dt}, 'contract summary does not expose monitor-DT internals');
    ok(
        advertised($contract->{kind}, isf_public_interface_schedule_report_temporal_contract_kind_values()),
        'contract kind is advertised',
    );
    ok(
        advertised($contract->{overlap_policy}, isf_public_interface_schedule_report_temporal_contract_overlap_policy_values()),
        'contract overlap policy is advertised',
    );
    ok(
        advertised($contract->{assertion_projection}, isf_public_interface_schedule_report_temporal_contract_assertion_projection_values()),
        'contract assertion projection status is advertised',
    );
};

subtest 'CLI schedule report matches in-process stage and contract projection' => sub {
    my $tempdir = tempdir(CLEANUP => 1);
    my $path = File::Spec->catfile($tempdir, 'stage_contract_report.isf');
    write_file($path, stage_contract_source());

    my $cli_report = run_schedule_json($path);
    my $actor = FSM::Adapter::ISF->new()->parse_file($path);
    my $in_process_report = decode_json(FSM::Scheduler::ISF->new()->report($actor));

    is_deeply(
        $cli_report->{transaction_stages},
        $in_process_report->{transaction_stages},
        'CLI preserves the in-process stage projection',
    );
    is_deeply(
        $cli_report->{temporal_contracts},
        $in_process_report->{temporal_contracts},
        'CLI preserves the in-process temporal contract projection',
    );
};

done_testing();

sub stage_contract_source {
    return <<'ISF';
(actor stage_contract_report
  (clock clk)
  (reset (rst_n async active_low))
  (interface
    (input start)
    (input ready)
    (input ack)
    (output valid)
    (output done))
  (transaction main
    (on start)
    (stage accept (input ready) (output valid))
    (contract ack_seen (eventually ack (within 3)))
    (complete done)))
ISF
}

sub report_source {
    my ($source, $label) = @_;
    my $actor = FSM::Adapter::ISF->new()->parse_source($source, $label);
    return decode_json(FSM::Scheduler::ISF->new()->report($actor));
}

sub run_schedule_json {
    my ($path) = @_;
    my ($success, $error_message, $full_buf, $stdout_buf, $stderr_buf) = run(
        command => ['./bin/fsmgen', '--emit-schedule-json', $path],
    );

    ok($success, '--emit-schedule-json succeeds');
    is(join('', @{$stderr_buf || []}), '', '--emit-schedule-json keeps stderr clean');

    return decode_json(join('', @{$stdout_buf || []}));
}

sub write_file {
    my ($path, $content) = @_;
    open my $fh, '>', $path or die "Cannot open $path for write: $!";
    print {$fh} $content or die "Cannot write $path: $!";
    close $fh or die "Cannot close $path: $!";
}

sub advertised {
    my ($value, $values) = @_;
    my %advertised = map { $_ => 1 } @{$values || []};
    return $advertised{$value};
}

sub sorted {
    my ($values) = @_;
    return [sort @{$values || []}];
}
