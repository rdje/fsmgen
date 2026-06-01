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

my $isf_file = File::Spec->catfile($FindBin::Bin, '..', 'isf', 'spi_master.isf');

subtest 'SPI-like fixture lowers to the expected scheduled FSM structure' => sub {
    my ($fsm, $report) = lower_spi_fixture();

    like($fsm, qr/\A\(\?fsm:spi_master\b/, 'scheduled FSM names the spi_master module');
    like($fsm, qr/\(tx_data 8\)/, 'scheduled FSM preserves tx_data width');
    like($fsm, qr/\(rx_data 8\)/, 'scheduled FSM preserves rx_data width');
    like($fsm, qr/\(spi_transfer_cnt 4\)/, 'scheduled FSM declares the repeat counter width');
    like($fsm, qr/\(<= \(tx_byte tx_data\) <start\)/, 'scheduled FSM samples tx_data on start');
    like($fsm, qr/\(= \(cs_val 0\)\)/, 'scheduled FSM asserts active-low CS');
    like($fsm, qr/\(= \(mosi_val tx_byte\[7\]\)\)/, 'scheduled FSM drives MOSI from the current transmit MSB');
    unlike($fsm, qr/\(= \(mosi_val tx_byte\)\)/, 'scheduled FSM does not drive one-bit MOSI from the full transmit byte');
    like($fsm, qr/\(<- \(tx_byte \(\| \(<< tx_byte 1\) 0\)\)\)/, 'scheduled FSM shifts the transmit byte left');
    like($fsm, qr/\(<- \(rx_data> \(\| \(<< rx_data 1\) miso\)\)\)/, 'scheduled FSM shifts sampled MISO into rx_data');
    like($fsm, qr/\(spi_transfer_repeat_init_2\b\s*\(<= \(spi_transfer_cnt 8\)\)\s*\(-> spi_transfer_repeat_check_8\)/s,
        'scheduled FSM repeat init loads the counter and transitions straight to the check state');
    like($fsm, qr/\(-- spi_transfer_cnt\)/, 'scheduled FSM decrements the repeat counter');
    like($fsm, qr/\(\?spi_transfer_cnt\s+\(>0 \(-> spi_transfer_drive_3\)\)\s+\(=0 \(-> spi_transfer_drive_9\)\)/s,
        'scheduled FSM loops or exits based on the repeat counter (check-first)');
    like($fsm, qr/\(<1 \(done> 1\)\)/, 'scheduled FSM completes with a one-cycle delayed pulse');

    is($report->{source}, 'spi_master.isf', 'schedule report names the source fixture');
    is($report->{scheduled_fsm}, 'spi_master.fsm', 'schedule report names the generated FSM');
    is($report->{clock}, 'clk', 'schedule report records the clock');
    is($report->{watchdog}, '65536', 'schedule report records the watchdog literal');
    is_deeply(
        $report->{reset},
        { name => 'rst_n', kind => 'async', polarity => 'active_low' },
        'schedule report records async active-low reset metadata',
    );
    is($report->{inputs}, 3, 'schedule report input count');
    is($report->{outputs}, 5, 'schedule report output count');
    is($report->{port_count}, 8, 'schedule report port count');
    is($report->{state_count}, 11, 'schedule report state count');
    is_deeply($report->{compile_issues}, [], 'schedule report has no compile issues');

    is_deeply(
        $report->{transactions},
        [
            {
                name => 'spi_transfer',
                count => 11,
                states => [qw(
                  spi_transfer_idle_0
                  spi_transfer_drive_1
                  spi_transfer_repeat_init_2
                  spi_transfer_drive_3
                  spi_transfer_shift_4
                  spi_transfer_drive_5
                  spi_transfer_shift_6
                  spi_transfer_drive_7
                  spi_transfer_repeat_check_8
                  spi_transfer_drive_9
                  spi_transfer_done_10
                )],
            },
        ],
        'schedule report records the SPI transfer state order',
    );

    is_deeply(
        [map { $_->{name} } @{$report->{dt_blocks}}],
        [qw(cs mosi sclk)],
        'schedule report records the named drive DT blocks',
    );

    assert_storage($report, 'tx_byte', 'register', 'sample_alias', 8);
    assert_storage($report, 'spi_transfer_cnt', 'counter', 'repeat_counter', 4);
    assert_storage($report, 'rx_data', 'register', 'data_register', 8);
    assert_storage($report, 'done', 'register', 'completion_pulse', 1);

    is_deeply(
        [sort map { $_->{target} } @{$report->{compatible_fanin_groups}}],
        [qw(cs_start sclk_start)],
        'schedule report records compatible request fan-in groups',
    );
};

subtest 'SPI-like fixture schedule JSON CLI matches the in-process report' => sub {
    my (undef, $in_process_report) = lower_spi_fixture();
    my ($success, $error_message, $full_buf, $stdout_buf, $stderr_buf) = run(
        command => [
            './bin/fsmgen',
            '--strict',
            '--quiet',
            '--emit-schedule-json',
            $isf_file,
        ],
    );

    ok($success, 'strict schedule JSON generation succeeds for the SPI-like fixture');
    is(join('', @{$stderr_buf || []}), '', 'strict schedule JSON generation keeps stderr clean');
    is_deeply(
        decode_json(join('', @{$stdout_buf || []})),
        $in_process_report,
        'strict schedule JSON generation matches the in-process report',
    );
};

subtest 'SPI-like fixture reaches plain and strict HDL generation' => sub {
    my $tempdir = tempdir(CLEANUP => 1);
    my $plain_hdl = File::Spec->catfile($tempdir, 'spi_master_plain.sv');
    my $strict_hdl = File::Spec->catfile($tempdir, 'spi_master_strict.sv');

    run_hdl_generation(['./bin/fsmgen', '--quiet', '--output', $plain_hdl, $isf_file], $plain_hdl, 'plain');
    run_hdl_generation(['./bin/fsmgen', '--strict', '--quiet', '--output', $strict_hdl, $isf_file], $strict_hdl, 'strict');

    my $hdl = slurp($strict_hdl);
    like($hdl, qr/\bmodule\s+spi_master\b/, 'strict generated HDL contains the SPI-like module');
    like($hdl, qr/\bSPI_TRANSFER_IDLE_0\b/, 'strict generated HDL contains scheduled state encodings');
    like($hdl, qr/\bmosi_val_tx_byte_7_en\b/, 'strict generated HDL preserves the explicit MOSI bit-select selector');
    like($hdl, qr/\btx_byte\s*<<\s*1\b/, 'strict generated HDL emits the transmit left shift');
    like($hdl, qr/\brx_data\s*<<\s*1\b/, 'strict generated HDL emits the receive left shift');
};

done_testing();

sub lower_spi_fixture {
    my $actor = FSM::Adapter::ISF->new()->parse_file($isf_file);
    my $scheduler = FSM::Scheduler::ISF->new();
    my $result = $scheduler->lower($actor);
    my $report = decode_json($scheduler->report($actor));

    return ($result->{files}{'spi_master.fsm'}, $report);
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

    ok($success, "$label HDL generation succeeds for the SPI-like fixture");
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
