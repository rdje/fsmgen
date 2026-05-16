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

my $isf_file = File::Spec->catfile($FindBin::Bin, '..', 'isf', 'i2c_master.isf');

subtest 'I2C-like fixture lowers to the expected scheduled FSM structure' => sub {
    my ($fsm, $report) = lower_i2c_fixture();

    like($fsm, qr/\A\(\?fsm:i2c_master\b/, 'scheduled FSM names the i2c_master module');
    like($fsm, qr/\(dev_addr 7\)/, 'scheduled FSM preserves dev_addr width');
    like($fsm, qr/\(reg_addr 8\)/, 'scheduled FSM preserves reg_addr width');
    like($fsm, qr/\(wdata 8\)/, 'scheduled FSM preserves wdata width');
    like($fsm, qr/\(rdata 8\)/, 'scheduled FSM preserves rdata width');
    like($fsm, qr/\(i2c_transfer_cnt 4\)/, 'scheduled FSM declares the repeat counter width');
    like($fsm, qr/\(<= \(is_read rw\) <start\)/, 'scheduled FSM samples rw on start');
    like($fsm, qr/\(<= \(addr dev_addr\) <start\)/, 'scheduled FSM samples dev_addr on start');
    like($fsm, qr/\(<= \(reg reg_addr\) <start\)/, 'scheduled FSM samples reg_addr on start');
    like($fsm, qr/\(<= \(data wdata\) <start\)/, 'scheduled FSM samples wdata on start');
    like($fsm, qr/\(= \(sda_val data\[7\]\)\)/, 'scheduled FSM drives SDA from the sampled write-data MSB');
    like($fsm, qr/\(<- \(data \(\| \(<< data 1\) 0\)\)\)/, 'scheduled FSM shifts write data after driving SDA');
    like($fsm, qr/\(<- \(rdata> \(\| \(<< rdata 1\) sda_in\)\)\)/, 'scheduled FSM shifts sampled SDA into rdata');
    unlike($fsm, qr/\bdata_bit\b/, 'scheduled FSM does not depend on an implicit data_bit input');

    is($report->{source}, 'i2c_master.isf', 'schedule report names the source fixture');
    is($report->{scheduled_fsm}, 'i2c_master.fsm', 'schedule report names the generated FSM');
    is($report->{clock}, 'clk', 'schedule report records the clock');
    is($report->{watchdog}, '65536', 'schedule report records the watchdog literal');
    is_deeply(
        $report->{reset},
        { name => 'rst_n', kind => 'async', polarity => 'active_low' },
        'schedule report records async active-low reset metadata',
    );
    is($report->{inputs}, 6, 'schedule report input count');
    is($report->{outputs}, 4, 'schedule report output count');
    is($report->{port_count}, 10, 'schedule report port count');
    is($report->{state_count}, 38, 'schedule report state count');
    is_deeply($report->{compile_issues}, [], 'schedule report has no compile issues');

    is_deeply(
        $report->{transactions},
        [
            {
                name => 'i2c_transfer',
                count => 38,
                states => [qw(
                  i2c_transfer_idle_0
                  i2c_transfer_drive_1
                  i2c_transfer_drive_2
                  i2c_transfer_drive_3
                  i2c_transfer_repeat_init_4
                  i2c_transfer_drive_5
                  i2c_transfer_drive_6
                  i2c_transfer_repeat_check_7
                  i2c_transfer_drive_8
                  i2c_transfer_switch_11
                  i2c_transfer_drive_9
                  i2c_transfer_drive_10
                  i2c_transfer_drive_12
                  i2c_transfer_drive_13
                  i2c_transfer_drive_14
                  i2c_transfer_repeat_init_15
                  i2c_transfer_drive_16
                  i2c_transfer_drive_17
                  i2c_transfer_repeat_check_18
                  i2c_transfer_drive_19
                  i2c_transfer_drive_20
                  i2c_transfer_switch_32
                  i2c_transfer_repeat_init_21
                  i2c_transfer_drive_22
                  i2c_transfer_shift_23
                  i2c_transfer_drive_24
                  i2c_transfer_repeat_check_25
                  i2c_transfer_repeat_init_26
                  i2c_transfer_drive_27
                  i2c_transfer_drive_28
                  i2c_transfer_drive_29
                  i2c_transfer_shift_30
                  i2c_transfer_repeat_check_31
                  i2c_transfer_drive_33
                  i2c_transfer_drive_34
                  i2c_transfer_drive_35
                  i2c_transfer_drive_36
                  i2c_transfer_done_37
                )],
            },
        ],
        'schedule report records the I2C-like transfer state order',
    );

    is_deeply(
        [map { $_->{name} } @{$report->{dt_blocks}}],
        [qw(scl sda)],
        'schedule report records the named drive DT blocks',
    );

    assert_storage($report, 'is_read', 'register', 'sample_alias', 1);
    assert_storage($report, 'addr', 'register', 'sample_alias', 7);
    assert_storage($report, 'reg', 'register', 'sample_alias', 8);
    assert_storage($report, 'data', 'register', 'sample_alias', 8);
    assert_storage($report, 'i2c_transfer_cnt', 'counter', 'repeat_counter', 4);
    assert_storage($report, 'rdata', 'register', 'data_register', 8);
    assert_storage($report, 'done', 'register', 'completion_pulse', 1);
};

subtest 'I2C-like fixture schedule JSON CLI matches the in-process report' => sub {
    my (undef, $in_process_report) = lower_i2c_fixture();
    my ($success, $error_message, $full_buf, $stdout_buf, $stderr_buf) = run(
        command => [
            './bin/fsmgen',
            '--strict',
            '--quiet',
            '--emit-schedule-json',
            $isf_file,
        ],
    );

    ok($success, 'strict schedule JSON generation succeeds for the I2C-like fixture');
    is(join('', @{$stderr_buf || []}), '', 'strict schedule JSON generation keeps stderr clean');
    is_deeply(
        decode_json(join('', @{$stdout_buf || []})),
        $in_process_report,
        'strict schedule JSON generation matches the in-process report',
    );
};

subtest 'I2C-like fixture reaches plain and strict HDL generation' => sub {
    my $tempdir = tempdir(CLEANUP => 1);
    my $plain_hdl = File::Spec->catfile($tempdir, 'i2c_master_plain.sv');
    my $strict_hdl = File::Spec->catfile($tempdir, 'i2c_master_strict.sv');

    run_hdl_generation(['./bin/fsmgen', '--quiet', '--output', $plain_hdl, $isf_file], $plain_hdl, 'plain');
    run_hdl_generation(['./bin/fsmgen', '--strict', '--quiet', '--output', $strict_hdl, $isf_file], $strict_hdl, 'strict');

    my $hdl = slurp($strict_hdl);
    like($hdl, qr/\bmodule\s+i2c_master\b/, 'strict generated HDL contains the I2C-like module');
    like($hdl, qr/\bI2C_TRANSFER_IDLE_0\b/, 'strict generated HDL contains scheduled state encodings');
    like($hdl, qr/\bsda_val\s*=\s*data\[7\]\s*;/, 'strict generated HDL drives SDA from the sampled write-data MSB');
    like($hdl, qr/\bdata\s*<<\s*1\b/, 'strict generated HDL emits the write-data left shift');
    like($hdl, qr/\brdata\s*<<\s*1\b/, 'strict generated HDL emits the read-data left shift');
    unlike($hdl, qr/\bdata_bit\b/, 'strict generated HDL does not expose an implicit data_bit input');
};

done_testing();

sub lower_i2c_fixture {
    my $actor = FSM::Adapter::ISF->new()->parse_file($isf_file);
    my $scheduler = FSM::Scheduler::ISF->new();
    my $result = $scheduler->lower($actor);
    my $report = decode_json($scheduler->report($actor));

    return ($result->{files}{'i2c_master.fsm'}, $report);
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

    ok($success, "$label HDL generation succeeds for the I2C-like fixture");
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
