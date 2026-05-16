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

my $isf_file = File::Spec->catfile($FindBin::Bin, '..', 'isf', 'fifo_controller.isf');

subtest 'FIFO controller fixture lowers to the expected rule-only scheduled matrix' => sub {
    my ($fsm, $report) = lower_fifo_controller_fixture();

    like($fsm, qr/\A\(\?fsm:fifo_update_matrix\b/, 'scheduled FSM names the fifo_update_matrix module');
    like($fsm, qr/\(write_req 1\)/, 'scheduled FSM preserves write_req width');
    like($fsm, qr/\(data_in 8\)/, 'scheduled FSM preserves data_in width for interface review');
    like($fsm, qr/\(read_req 1\)/, 'scheduled FSM preserves read_req width');
    like($fsm, qr/\(full 1\)/, 'scheduled FSM preserves full width');
    like($fsm, qr/\(empty 1\)/, 'scheduled FSM preserves empty width');
    like($fsm, qr/\(data_out 8\)/, 'scheduled FSM preserves data_out width for interface review');
    like($fsm, qr/\(wr_ptr 2\)/, 'scheduled FSM preserves write pointer width');
    like($fsm, qr/\(rd_ptr 2\)/, 'scheduled FSM preserves read pointer width');
    like($fsm, qr/\(occupancy 3\)/, 'scheduled FSM preserves occupancy width');

    like(
        $fsm,
        qr/\(-idle_occ0\s+<\(& \(! write_req\) \(! read_req\) \(== occupancy 0\)\)[\s\S]*\(<- \(occupancy 0\)\)[\s\S]*\(<- \(empty> 1\)\)[\s\S]*\(<- \(full> 0\)\)/,
        'idle occupancy 0 drives empty and not full',
    );
    like(
        $fsm,
        qr/\(-push_only_occ3\s+<\(& write_req \(! read_req\) \(== occupancy 3\)\)[\s\S]*\(<- \(occupancy 4\)\)[\s\S]*\(<- \(full> 1\)\)/,
        'push-only from occupancy 3 reaches full occupancy',
    );
    like(
        $fsm,
        qr/\(-pop_only_occ1\s+<\(& \(! write_req\) read_req \(== occupancy 1\)\)[\s\S]*\(<- \(occupancy 0\)\)[\s\S]*\(<- \(empty> 1\)\)/,
        'pop-only from occupancy 1 reaches empty occupancy',
    );
    like(
        $fsm,
        qr/\(-push_pop_occ4\s+<\(& write_req read_req \(== occupancy 4\)\)[\s\S]*\(<- \(occupancy 4\)\)[\s\S]*\(<- \(full> 1\)\)/,
        'push+pop from full preserves full occupancy',
    );
    like(
        $fsm,
        qr/\(-write_at_3\s+<\(& write_req \(\| \(! \(== occupancy 4\)\) read_req\) \(== wr_ptr 3\)\)[\s\S]*\(<- \(wr_ptr 0\)\)/,
        'write pointer wraps from entry 3 to entry 0',
    );
    like(
        $fsm,
        qr/\(-read_from_3\s+<\(& read_req \(! \(== occupancy 0\)\) \(== rd_ptr 3\)\)[\s\S]*\(<- \(rd_ptr 0\)\)/,
        'read pointer wraps from entry 3 to entry 0',
    );
    unlike($fsm, qr/\bdata_0\b/, 'controller fixture does not invent data-bank storage');

    is($report->{source}, 'fifo_update_matrix.isf', 'schedule report source follows the actor name');
    is($report->{scheduled_fsm}, 'fifo_update_matrix.fsm', 'schedule report names the generated FSM');
    is($report->{clock}, 'clk', 'schedule report records the clock');
    is_deeply(
        $report->{reset},
        { name => 'rst_n', kind => 'async', polarity => 'active_low' },
        'schedule report records async active-low reset metadata',
    );
    is($report->{inputs}, 3, 'schedule report input count');
    is($report->{outputs}, 3, 'schedule report output count');
    is($report->{port_count}, 6, 'schedule report port count');
    is($report->{state_count}, 0, 'FIFO controller fixture has rule-only scheduled behavior');
    is_deeply($report->{transactions}, [], 'FIFO controller fixture has no transaction states');
    is_deeply($report->{compile_issues}, [], 'schedule report has no compile issues');
    is(scalar(@{$report->{dt_blocks}}), 28, 'schedule report records every FIFO controller rule DT');
    is(scalar(@{$report->{compatible_fanin_groups}}), 9, 'schedule report records compatible same-value fan-in groups');
    is_deeply($report->{bank_accesses}, [], 'controller fixture has no bank-access summaries');

    is_deeply(
        [map { $_->{name} } @{$report->{dt_blocks}}],
        [
            qw(
              idle_occ0 idle_occ1 idle_occ2 idle_occ3 idle_occ4
              push_only_occ0 push_only_occ1 push_only_occ2 push_only_occ3 push_only_occ4
              pop_only_occ0 pop_only_occ1 pop_only_occ2 pop_only_occ3 pop_only_occ4
              push_pop_occ0 push_pop_occ1 push_pop_occ2 push_pop_occ3 push_pop_occ4
              write_at_0 write_at_1 write_at_2 write_at_3
              read_from_0 read_from_1 read_from_2 read_from_3
            )
        ],
        'schedule report preserves FIFO controller rule DT order',
    );

    assert_storage($report, 'wr_ptr', 'register', 'actor_storage', 2);
    assert_storage($report, 'rd_ptr', 'register', 'actor_storage', 2);
    assert_storage($report, 'occupancy', 'register', 'actor_storage', 3);
};

subtest 'FIFO controller fixture strict schedule JSON matches the in-process report' => sub {
    my (undef, $in_process_report) = lower_fifo_controller_fixture();
    my ($success, $error_message, $full_buf, $stdout_buf, $stderr_buf) = run(
        command => [
            './bin/fsmgen',
            '--strict',
            '--quiet',
            '--emit-schedule-json',
            $isf_file,
        ],
    );

    ok($success, 'strict schedule JSON generation succeeds for the FIFO controller fixture');
    is(join('', @{$stderr_buf || []}), '', 'strict schedule JSON generation keeps stderr clean');
    is_deeply(
        decode_json(join('', @{$stdout_buf || []})),
        $in_process_report,
        'strict schedule JSON generation matches the in-process report',
    );
};

subtest 'FIFO controller fixture reaches plain and strict HDL generation' => sub {
    my $tempdir = tempdir(CLEANUP => 1);
    my $plain_hdl = File::Spec->catfile($tempdir, 'fifo_update_matrix_plain.sv');
    my $strict_hdl = File::Spec->catfile($tempdir, 'fifo_update_matrix_strict.sv');

    run_hdl_generation(['./bin/fsmgen', '--quiet', '--output', $plain_hdl, $isf_file], $plain_hdl, 'plain');
    run_hdl_generation(['./bin/fsmgen', '--strict', '--quiet', '--output', $strict_hdl, $isf_file], $strict_hdl, 'strict');

    my $hdl = slurp($strict_hdl);
    like($hdl, qr/\bmodule\s+fifo_update_matrix\b/, 'strict generated HDL contains the fifo_update_matrix module');
    unlike($hdl, qr/State encoding[\s\S]*parameter\s+/m, 'strict generated HDL does not invent states for rule-only controller behavior');
    unlike($hdl, qr/\bdata_0\b/, 'strict generated HDL does not invent scalarized data-bank storage');
    like($hdl, qr/\breg\s+\[2:0\]\s+occupancy\s*;/, 'strict generated HDL declares occupancy storage');
    like($hdl, qr/\breg\s+\[1:0\]\s+wr_ptr\s*;/, 'strict generated HDL declares write pointer storage');
    like($hdl, qr/\breg\s+\[1:0\]\s+rd_ptr\s*;/, 'strict generated HDL declares read pointer storage');
    like($hdl, qr/\boccupancy_next\s*=\s*4\s*;/, 'strict generated HDL can drive occupancy to full depth');
    like($hdl, qr/\bwr_ptr_next\s*=\s*0\s*;/, 'strict generated HDL wraps the write pointer');
    like($hdl, qr/\brd_ptr_next\s*=\s*0\s*;/, 'strict generated HDL wraps the read pointer');
    like($hdl, qr/selector multi-value conflict: occupancy/, 'strict generated HDL keeps occupancy selector assertion');
    like($hdl, qr/selector multi-value conflict: wr_ptr/, 'strict generated HDL keeps write pointer selector assertion');
    like($hdl, qr/selector multi-value conflict: rd_ptr/, 'strict generated HDL keeps read pointer selector assertion');
};

done_testing();

sub lower_fifo_controller_fixture {
    my $actor = FSM::Adapter::ISF->new()->parse_file($isf_file);
    my $scheduler = FSM::Scheduler::ISF->new();
    my $result = $scheduler->lower($actor);
    my $report = decode_json($scheduler->report($actor));

    return ($result->{files}{'fifo_update_matrix.fsm'}, $report);
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

    ok($success, "$label HDL generation succeeds for the FIFO controller fixture");
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
