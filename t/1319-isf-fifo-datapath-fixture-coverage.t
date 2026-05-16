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

my $isf_file = File::Spec->catfile($FindBin::Bin, '..', 'isf', 'fifo_data_path.isf');

subtest 'FIFO datapath fixture lowers to scalarized scheduled bank access' => sub {
    my ($fsm, $report) = lower_fifo_datapath_fixture();

    like($fsm, qr/\A\(\?fsm:fifo_data_path\b/, 'scheduled FSM names the fifo_data_path module');
    like($fsm, qr/\(data_in 8\)/, 'scheduled FSM preserves data_in width');
    like($fsm, qr/\(data_out 8\)/, 'scheduled FSM preserves data_out width');
    like($fsm, qr/\(wr_ptr 2\)/, 'scheduled FSM preserves write pointer width');
    like($fsm, qr/\(rd_ptr 2\)/, 'scheduled FSM preserves read pointer width');
    like($fsm, qr/\(occupancy 3\)/, 'scheduled FSM preserves occupancy width');
    like(
        $fsm,
        qr/\(data_0 8\)[\s\S]*\(data_1 8\)[\s\S]*\(data_2 8\)[\s\S]*\(data_3 8\)/,
        'scheduled FSM declares the scalarized depth-4 data bank entries',
    );
    like(
        $fsm,
        qr/\(-accepted_push\s+<\(& write_req \(\| \(! \(== occupancy 4\)\) read_req\)\)[\s\S]*\(<- \(data_0 data_in\) <\(== wr_ptr 0\)\)[\s\S]*\(<- \(data_3 data_in\) <\(== wr_ptr 3\)\)/,
        'accepted push stores through per-entry write-pointer guards',
    );
    like(
        $fsm,
        qr/\(-accepted_pop\s+<\(& read_req \(! \(== occupancy 0\)\)\)[\s\S]*\(<- \(data_out> data_0\) <\(== rd_ptr 0\)\)[\s\S]*\(<- \(data_out> data_3\) <\(== rd_ptr 3\)\)/,
        'accepted pop loads through per-entry read-pointer guards',
    );

    is($report->{source}, 'fifo_data_path.isf', 'schedule report names the source fixture');
    is($report->{scheduled_fsm}, 'fifo_data_path.fsm', 'schedule report names the generated FSM');
    is($report->{clock}, 'clk', 'schedule report records the clock');
    is_deeply(
        $report->{reset},
        { name => 'rst_n', kind => 'async', polarity => 'active_low' },
        'schedule report records async active-low reset metadata',
    );
    is($report->{inputs}, 3, 'schedule report input count');
    is($report->{outputs}, 1, 'schedule report output count');
    is($report->{port_count}, 4, 'schedule report port count');
    is($report->{state_count}, 0, 'FIFO datapath fixture has rule-only scheduled behavior');
    is_deeply($report->{transactions}, [], 'FIFO datapath fixture has no transaction states');
    is_deeply($report->{compile_issues}, [], 'schedule report has no compile issues');

    is_deeply(
        $report->{dt_blocks},
        [
            { name => 'accepted_push', kind => 'rule', assignments => 4 },
            { name => 'accepted_pop',  kind => 'rule', assignments => 4 },
        ],
        'schedule report records the store and load rule DT blocks',
    );

    assert_storage($report, 'wr_ptr', 'register', 'actor_storage', 2);
    assert_storage($report, 'rd_ptr', 'register', 'actor_storage', 2);
    assert_storage($report, 'occupancy', 'register', 'actor_storage', 3);
    assert_storage($report, 'data_0', 'register', 'actor_storage', 8);
    assert_storage($report, 'data_1', 'register', 'actor_storage', 8);
    assert_storage($report, 'data_2', 'register', 'actor_storage', 8);
    assert_storage($report, 'data_3', 'register', 'actor_storage', 8);

    is(scalar(@{$report->{bank_accesses}}), 2, 'schedule report records store and load bank accesses');
    my %access_by_kind = map { $_->{kind} => $_ } @{$report->{bank_accesses}};
    assert_bank_access($access_by_kind{store}, 'store', 'accepted_push', 'wr_ptr', 'data_in', undef);
    assert_bank_access($access_by_kind{load}, 'load', 'accepted_pop', 'rd_ptr', undef, 'data_out');
};

subtest 'FIFO datapath fixture strict schedule JSON matches the in-process report' => sub {
    my (undef, $in_process_report) = lower_fifo_datapath_fixture();
    my ($success, $error_message, $full_buf, $stdout_buf, $stderr_buf) = run(
        command => [
            './bin/fsmgen',
            '--strict',
            '--quiet',
            '--emit-schedule-json',
            $isf_file,
        ],
    );

    ok($success, 'strict schedule JSON generation succeeds for the FIFO datapath fixture');
    is(join('', @{$stderr_buf || []}), '', 'strict schedule JSON generation keeps stderr clean');
    is_deeply(
        decode_json(join('', @{$stdout_buf || []})),
        $in_process_report,
        'strict schedule JSON generation matches the in-process report',
    );
};

subtest 'FIFO datapath fixture reaches plain and strict HDL generation' => sub {
    my $tempdir = tempdir(CLEANUP => 1);
    my $plain_hdl = File::Spec->catfile($tempdir, 'fifo_data_path_plain.sv');
    my $strict_hdl = File::Spec->catfile($tempdir, 'fifo_data_path_strict.sv');

    run_hdl_generation(['./bin/fsmgen', '--quiet', '--output', $plain_hdl, $isf_file], $plain_hdl, 'plain');
    run_hdl_generation(['./bin/fsmgen', '--strict', '--quiet', '--output', $strict_hdl, $isf_file], $strict_hdl, 'strict');

    my $hdl = slurp($strict_hdl);
    like($hdl, qr/\bmodule\s+fifo_data_path\b/, 'strict generated HDL contains the fifo_data_path module');
    unlike($hdl, qr/State encoding[\s\S]*parameter\s+/m, 'strict generated HDL does not invent states for rule-only datapath behavior');
    like($hdl, qr/\breg\s+\[7:0\]\s+data_0\s*;/, 'strict generated HDL declares scalarized data_0 storage');
    like($hdl, qr/\breg\s+\[7:0\]\s+data_3\s*;/, 'strict generated HDL declares scalarized data_3 storage');
    like($hdl, qr/\bdata_0_next\s*=\s*data_in\s*;/, 'strict generated HDL stores data_in into the selected first bank entry');
    like($hdl, qr/\bdata_3_next\s*=\s*data_in\s*;/, 'strict generated HDL stores data_in into the selected last bank entry');
    like($hdl, qr/\bdata_out_next\s*=\s*data_0\s*;/, 'strict generated HDL can load data_out from the first bank entry');
    like($hdl, qr/\bdata_out_next\s*=\s*data_3\s*;/, 'strict generated HDL can load data_out from the last bank entry');
    like(
        $hdl,
        qr/assert \(\$onehot0\(\{data_out_data_0_en, data_out_data_1_en, data_out_data_2_en, data_out_data_3_en\}\)\)/,
        'strict generated HDL keeps selector conflict assertion for the load mux',
    );
};

done_testing();

sub lower_fifo_datapath_fixture {
    my $actor = FSM::Adapter::ISF->new()->parse_file($isf_file);
    my $scheduler = FSM::Scheduler::ISF->new();
    my $result = $scheduler->lower($actor);
    my $report = decode_json($scheduler->report($actor));

    return ($result->{files}{'fifo_data_path.fsm'}, $report);
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

sub assert_bank_access {
    my ($entry, $kind, $owner, $index, $value, $target) = @_;

    ok($entry, "$kind bank access exists");
    return unless $entry;
    is($entry->{kind}, $kind, "$kind bank access kind");
    is($entry->{owner}, $owner, "$kind bank access owner");
    is($entry->{owner_kind}, 'rule', "$kind bank access owner kind");
    is($entry->{container_kind}, 'dt', "$kind bank access container kind");
    is($entry->{container_name}, $owner, "$kind bank access container name");
    is($entry->{bank}, 'data', "$kind bank access bank name");
    is($entry->{index}, $index, "$kind bank access index expression");
    is($entry->{value}, $value, "$kind bank access value");
    is($entry->{target}, $target, "$kind bank access target");
    is($entry->{width}, 8, "$kind bank access entry width");
    is($entry->{depth}, 4, "$kind bank access depth");
    is($entry->{same_cycle_policy}, 'read_before_write', "$kind bank access same-cycle policy");
    is_deeply(
        $entry->{scalar_entries},
        [qw(data_0 data_1 data_2 data_3)],
        "$kind bank access scalarized entries",
    );
}

sub run_hdl_generation {
    my ($command, $output, $label) = @_;
    my ($success, $error_message, $full_buf, $stdout_buf, $stderr_buf) = run(command => $command);

    ok($success, "$label HDL generation succeeds for the FIFO datapath fixture");
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
