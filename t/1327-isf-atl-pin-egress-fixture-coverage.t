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
my $isf_file = File::Spec->catfile($repo_root, 'isf', 'atl_pin_egress_pipeline.isf');

subtest 'ATL pin-egress fixture lowers to one scheduled parent artifact' => sub {
    my ($files, $report) = lower_atl_fixture();

    is_deeply(
        sorted([keys %$files]),
        ['atl_pin_egress_pipeline.fsm'],
        'lowering emits only the selected parent scheduled FSM',
    );

    my $fsm = $files->{'atl_pin_egress_pipeline.fsm'};
    like($fsm, qr/\A\(\?fsm:atl_pin_egress_pipeline\b/, 'scheduled FSM names atl_pin_egress_pipeline');
    like($fsm, qr/\(producer_payload 1\)/, 'scheduled FSM exposes producer payload source handoff');
    like($fsm, qr/\(result 1\)/, 'scheduled FSM preserves result as a top-level output sink');
    like($fsm, qr/\(publish_result_start 1\)/, 'scheduled FSM exposes the named drive request');
    like($fsm, qr/\brun_drive_1\b/, 'scheduled FSM contains the selected drive state');
    like($fsm, qr/\(= \(publish_result_start 1\)\)/, 'drive state requests the pin-egress route');
    like($fsm, qr/\(<- \(result>\s+producer_payload\) <publish_result_start\)/,
        'drive body gates the actor to top-level pin scalar route with the drive request');
    like($fsm, qr/\(<1 \(done> 1\)\)/, 'fixture completes with a one-cycle done pulse');

    assert_report_shape($report);
};

subtest 'ATL pin-egress fixture strict schedule JSON matches the in-process report' => sub {
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

    ok($success, 'strict schedule JSON generation succeeds for the ATL pin-egress fixture');
    is($stderr, '', 'strict schedule JSON generation keeps stderr clean');
    is_deeply(
        decode_json($stdout),
        $in_process_report,
        'strict schedule JSON generation matches the in-process report',
    );
};

subtest 'ATL pin-egress fixture reaches plain and strict HDL generation' => sub {
    my $plain_dir = tempdir(CLEANUP => 1);
    my $plain_hdl = File::Spec->catfile($plain_dir, 'atl_pin_egress_pipeline_plain.sv');
    my $plain = generate_hdl($plain_hdl, [], 'plain HDL generation');

    like($plain, qr/\bmodule\s+atl_pin_egress_pipeline\b/, 'plain HDL contains the ATL parent module');
    like($plain, qr/\bRUN_DRIVE_1\b/, 'plain HDL contains the drive state encoding');
    like($plain, qr/\bproducer_payload\b/, 'plain HDL exposes the producer payload handoff');
    like($plain, qr/\bresult\b/, 'plain HDL exposes the top-level result sink');

    my $strict_dir = tempdir(CLEANUP => 1);
    my $strict_hdl = File::Spec->catfile($strict_dir, 'atl_pin_egress_pipeline_strict.sv');
    my $strict = generate_hdl($strict_hdl, ['--strict'], 'strict HDL generation');

    like($strict, qr/\bmodule\s+atl_pin_egress_pipeline\b/, 'strict HDL contains the ATL parent module');
    like($strict, qr/\bRUN_DRIVE_1\b/, 'strict HDL contains the drive state encoding');
    like($strict, qr/\bproducer_payload\b/, 'strict HDL exposes the producer payload handoff');
    like($strict, qr/\bresult\b/, 'strict HDL exposes the top-level result sink');
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

    is($report->{source}, 'atl_pin_egress_pipeline.isf', 'schedule report names the ATL pin-egress fixture');
    is($report->{scheduled_fsm}, 'atl_pin_egress_pipeline.fsm', 'schedule report names the scheduled parent FSM');
    is($report->{clock}, 'clk', 'schedule report records the clock');
    is_deeply(
        $report->{reset},
        { name => 'rst_n', kind => 'async', polarity => 'active_low' },
        'schedule report records async active-low reset metadata',
    );
    is($report->{inputs}, 2, 'schedule report input count includes producer handoff input');
    is($report->{outputs}, 2, 'schedule report output count includes result sink output');
    is($report->{port_count}, 4, 'schedule report port count includes generated pin-egress handoff');
    is($report->{state_count}, 3, 'schedule report state count');
    is_deeply($report->{compile_issues}, [], 'schedule report has no compile issues');
    is_deeply(
        $report->{dt_blocks},
        [
            {
                name        => 'publish_result',
                kind        => 'drive',
                assignments => 1,
            },
        ],
        'schedule report records the named pin-egress drive body',
    );
    is_deeply(
        $report->{transactions},
        [
            {
                name => 'run',
                count => 3,
                states => [qw(
                  run_idle_0
                  run_drive_1
                  run_done_2
                )],
            },
        ],
        'schedule report records the pin-egress transaction state order',
    );

    my $actor_network = $report->{actor_network};
    is($actor_network->{kind}, 'static_declaration', 'actor network kind');
    is_deeply(
        $actor_network->{instances},
        [
            { name => 'producer', actor_type => 'packet_reader', declaration => 'actor' },
        ],
        'report records the producer static actor instance',
    );
    is_deeply($actor_network->{groups}, [], 'pin-egress fixture has no permanent static group');
    is_deeply($actor_network->{event_waits}, [], 'fixture does not use actor event waits');
    is_deeply($actor_network->{transaction_triggers}, [], 'fixture does not use actor transaction triggers');
    is_deeply($actor_network->{association_schedules}, [], 'fixture does not use trigger-batch association schedules');
    is_deeply($actor_network->{group_schedules}, [], 'fixture does not use compatibility group schedule evidence');
    is_deeply(
        $actor_network->{data_movements},
        [
            {
                kind            => 'scalar_actor_to_pin_handoff',
                transaction     => 'run',
                context         => 'transaction_body',
                drive           => 'publish_result',
                source_instance => 'producer',
                source_endpoint => 'payload',
                source_signal   => 'producer_payload',
                sink_instance   => 'pins',
                sink_endpoint   => 'result',
                sink_signal     => 'result',
                width           => 1,
                width_source    => 'top_level_output_pin_scalar_one_bit',
                route_lifetime  => 'drive_call_cycle',
                storage         => 'none',
                source          => 'external_handoff',
                sink            => 'top_level_pin',
            },
        ],
        'report records the scalar actor to top-level pin route evidence',
    );
}

sub generate_hdl {
    my ($output_file, $extra_args, $label) = @_;
    my @command = ('./bin/fsmgen', @{$extra_args || []}, '--quiet', '--output', $output_file, $isf_file);
    my ($success, undef, $stderr) = run_cli(\@command, $label);

    ok($success, "$label succeeds for the ATL pin-egress fixture");
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
