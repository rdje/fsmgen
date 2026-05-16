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
my $isf_file = File::Spec->catfile($repo_root, 'isf', 'fifo_library_use.isf');

subtest 'FIFO library fixture lowers to importer, child, and generated top artifacts' => sub {
    my ($files, $report) = lower_fifo_library_fixture();

    is_deeply(
        sorted([keys %$files]),
        [qw(fifo_library_use.fsm fifo_library_use__u_fifo.fsm fifo_library_use_top.fsm)],
        'lowering emits the expected FIFO library file set',
    );

    my $importer_fsm = $files->{'fifo_library_use.fsm'};
    my $child_fsm = $files->{'fifo_library_use__u_fifo.fsm'};
    my $top_fsm = $files->{'fifo_library_use_top.fsm'};

    like($importer_fsm, qr/\A\(\?fsm:fifo_library_use\b/, 'importer scheduled FSM names fifo_library_use');
    like($child_fsm, qr/\A\(\?fsm:fifo_library_use__u_fifo\b/, 'child scheduled FSM names the specialized FIFO module');
    like($top_fsm, qr/\A\(\?top:fifo_library_use_top\b/, 'generated top names fifo_library_use_top');
    like($top_fsm, qr/\(\?fsmc:fifo_library_use fifo_library_use\)/, 'generated top instantiates the importer actor');
    like(
        $top_fsm,
        qr/\(\?fsmc:u_fifo fifo_library_use__u_fifo\s+\(params[\s\S]*?\(OCC_WIDTH 3\)[\s\S]*?\)/,
        'generated top instantiates the specialized FIFO child with fixed parameters',
    );

    like(
        $child_fsm,
        qr/\(\+params[\s\S]*\(DATA_WIDTH 8\)[\s\S]*\(DEPTH 4\)[\s\S]*\(PTR_WIDTH 2\)[\s\S]*\(OCC_WIDTH 3\)/,
        'FIFO child preserves fixed-shape parameter provenance',
    );
    like($child_fsm, qr/\(\+size[\s\S]*\(data_0 8\)[\s\S]*\(data_3 8\)/, 'FIFO child declares scalarized data entries');
    like($child_fsm, qr/\(-push_pop_occ4\s+<\(& write_req read_req \(== occupancy 4\)\)/, 'FIFO child includes the full push+pop controller case');
    like(
        $child_fsm,
        qr/\(-accepted_push\s+<\(& write_req \(\| \(! \(== occupancy 4\)\) read_req\)\)[\s\S]*\(<- \(data_0 data_in\) <\(== wr_ptr 0\)\)[\s\S]*\(<- \(data_3 data_in\) <\(== wr_ptr 3\)\)/,
        'FIFO child stores accepted pushes through the scalarized bank',
    );
    like(
        $child_fsm,
        qr/\(-accepted_pop\s+<\(& read_req \(! \(== occupancy 0\)\)\)[\s\S]*\(<- \(data_out> data_0\) <\(== rd_ptr 0\)\)[\s\S]*\(<- \(data_out> data_3\) <\(== rd_ptr 3\)\)/,
        'FIFO child loads accepted pops from the scalarized bank',
    );

    for my $link (
        ['write_req', 'u_fifo.write_req', 'write request'],
        ['data_in',   'u_fifo.data_in',   'write data'],
        ['read_req',  'u_fifo.read_req',  'read request'],
        ['u_fifo.full',     'full',     'full output'],
        ['u_fifo.empty',    'empty',    'empty output'],
        ['u_fifo.data_out', 'data_out', 'read data output'],
    ) {
        my ($lhs, $rhs, $label) = @$link;
        like($top_fsm, qr/\(\Q$lhs\E \Q$rhs\E\)/, "generated top wires FIFO $label");
    }

    assert_report_shape($report);
};

subtest 'FIFO library fixture strict schedule JSON matches the in-process report' => sub {
    my (undef, $in_process_report) = lower_fifo_library_fixture();
    my ($success, $error_message, $full_buf, $stdout_buf, $stderr_buf) = run(
        command => [
            './bin/fsmgen',
            '--strict',
            '--quiet',
            '--emit-schedule-json',
            $isf_file,
        ],
    );

    ok($success, 'strict schedule JSON generation succeeds for the FIFO library fixture');
    is(join('', @{$stderr_buf || []}), '', 'strict schedule JSON generation keeps stderr clean');
    is_deeply(
        decode_json(join('', @{$stdout_buf || []})),
        $in_process_report,
        'strict schedule JSON generation matches the in-process report',
    );
};

subtest 'FIFO library fixture reaches plain and strict generated-top HDL generation' => sub {
    my ($files) = lower_fifo_library_fixture();

    my $plain_dir = tempdir(CLEANUP => 1);
    my $plain_hdl = File::Spec->catfile($plain_dir, 'fifo_library_use_plain.sv');
    run_generation(
        ['./bin/fsmgen', '--quiet', '--outdir', $plain_dir, '--output', $plain_hdl, $isf_file],
        $plain_dir,
        $plain_hdl,
        $files,
        'plain',
    );

    my $strict_dir = tempdir(CLEANUP => 1);
    my $strict_hdl = File::Spec->catfile($strict_dir, 'fifo_library_use_strict.sv');
    run_generation(
        ['./bin/fsmgen', '--strict', '--quiet', '--outdir', $strict_dir, '--output', $strict_hdl, $isf_file],
        $strict_dir,
        $strict_hdl,
        $files,
        'strict',
    );

    my $hdl = slurp($strict_hdl);
    like($hdl, qr/\bmodule\s+fifo_library_use_top\b/, 'strict HDL contains the generated top module');
    like($hdl, qr/\bmodule\s+fifo_library_use__u_fifo\s*#\(/, 'strict HDL contains the parameterized FIFO child module');
    like(
        $hdl,
        qr/fifo_library_use__u_fifo\s+#\([\s\S]*?\.DATA_WIDTH\(8\)[\s\S]*?\.DEPTH\(4\)[\s\S]*?\.PTR_WIDTH\(2\)[\s\S]*?\.OCC_WIDTH\(3\)[\s\S]*?\)\s+u_fifo\s*\(/,
        'strict generated top applies fixed FIFO parameter bindings',
    );
    like(
        $hdl,
        qr/u_fifo\s*\([\s\S]*?\.data_in\(data_in\)[\s\S]*?\.data_out\(data_out\)[\s\S]*?\.empty\(empty\)[\s\S]*?\.full\(full\)[\s\S]*?\.read_req\(read_req\)[\s\S]*?\.write_req\(write_req\)/,
        'strict generated top wires FIFO interface ports',
    );
    like($hdl, qr/\breg\s+\[7:0\]\s+data_0\b/, 'strict HDL contains scalarized FIFO entry data_0');
    like($hdl, qr/\breg\s+\[7:0\]\s+data_3\b/, 'strict HDL contains scalarized FIFO entry data_3');
    like($hdl, qr/\bassign\s+accepted_push_data_0_data_in_en\s*=\s*accepted_push_en\s*&\s*\(~\|wr_ptr\)/, 'strict HDL gates accepted push entry 0 by write pointer');
    like($hdl, qr/\bassign\s+accepted_pop_data_out_data_0_en\s*=\s*accepted_pop_en\s*&\s*\(~\|rd_ptr\)/, 'strict HDL gates accepted pop entry 0 by read pointer');
};

done_testing();

sub lower_fifo_library_fixture {
    my $actor = FSM::Adapter::ISF->new()->parse_file($isf_file);
    my $scheduler = FSM::Scheduler::ISF->new();
    my $result = $scheduler->lower($actor);
    my $report = decode_json($scheduler->report($actor));

    return ($result->{files}, $report);
}

sub assert_report_shape {
    my ($report) = @_;

    is($report->{source}, 'fifo_library_use.isf', 'schedule report names the source fixture');
    is($report->{scheduled_fsm}, 'fifo_library_use.fsm', 'schedule report names the importing actor FSM');
    is($report->{clock}, 'clk', 'schedule report records the clock');
    is_deeply(
        $report->{reset},
        { name => 'rst_n', kind => 'async', polarity => 'active_low' },
        'schedule report records async active-low reset metadata',
    );
    is($report->{inputs}, 3, 'schedule report input count');
    is($report->{outputs}, 3, 'schedule report output count');
    is($report->{port_count}, 6, 'schedule report port count');
    is($report->{state_count}, 0, 'importing actor has no local states');
    is_deeply($report->{compile_issues}, [], 'schedule report has no compile issues');
    is_deeply($report->{dt_blocks}, [], 'importing actor has no local DT blocks');

    is(scalar(@{$report->{library_uses}}), 1, 'schedule report exposes one FIFO library use');
    my $use = $report->{library_uses}[0];
    is($use->{library}, 'common.fifo', 'report records FIFO library namespace');
    is($use->{alias}, 'fifo_lib', 'report records FIFO import alias');
    is($use->{export}, 'fifo', 'report records FIFO actor export');
    is($use->{kind}, 'actor', 'report records actor export kind');
    is($use->{instance}, 'u_fifo', 'report records FIFO instance');
    is($use->{module}, 'fifo_library_use__u_fifo', 'report records generated child module');
    is($use->{scheduled_fsm}, 'fifo_library_use__u_fifo.fsm', 'report records generated child artifact');

    is_deeply(
        [map { $_->{name} . '=' . $_->{value} . ':' . $_->{source} } @{$use->{parameters}}],
        [
            qw(
              DATA_WIDTH=8:override
              DEPTH=4:override
              PTR_WIDTH=2:override
              OCC_WIDTH=3:override
            )
        ],
        'report records fixed FIFO parameter overrides',
    );
    is_deeply(
        [map { join ':', map { defined $_ ? $_ : '<null>' } @{$_}{qw(role parent_name library_name width)} } @{$use->{bindings}}],
        [
            'clock:clk:<null>:1',
            'reset:rst_n:<null>:1',
            'input:write_req:write_req:1',
            'input:data_in:data_in:8',
            'input:read_req:read_req:1',
            'output:full:full:1',
            'output:empty:empty:1',
            'output:data_out:data_out:8',
        ],
        'report records FIFO library bindings',
    );
}

sub run_generation {
    my ($command, $outdir, $output, $files, $label) = @_;
    my ($success, $error_message, $full_buf, $stdout_buf, $stderr_buf) = run(command => $command);

    ok($success, "$label generated-top HDL generation succeeds for the FIFO library fixture");
    is(join('', @{$stderr_buf || []}), '', "$label generated-top HDL generation keeps stderr clean");
    ok(-f $output, "$label generated-top HDL generation writes the requested output");

    for my $basename (sort keys %$files) {
        my $path = File::Spec->catfile($outdir, $basename);
        ok(-f $path, "$label generation writes $basename");
        is(slurp($path), $files->{$basename}, "$label $basename matches in-process lowering");
    }
}

sub sorted {
    my ($values) = @_;
    return [sort @$values];
}

sub slurp {
    my ($path) = @_;
    open my $fh, '<', $path or die "cannot read $path: $!";
    my $text = do { local $/; <$fh> };
    close $fh or die "cannot close $path: $!";
    return $text;
}
