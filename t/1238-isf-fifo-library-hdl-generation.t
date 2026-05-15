#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use File::Spec;
use File::Temp qw(tempdir);
use FindBin;
use IPC::Cmd qw(run);

my $repo_root = File::Spec->catdir($FindBin::Bin, '..');
my $fixture = File::Spec->catfile($repo_root, 'isf', 'fifo_library_use.isf');

subtest 'FIFO library fixture reaches generated top SystemVerilog' => sub {
    my $dir = tempdir(CLEANUP => 1);
    my $output = File::Spec->catfile($dir, 'fifo_library_use.sv');

    my ($success, $error_message, $full_buf, $stdout_buf, $stderr_buf) = run(
        command => [
            File::Spec->catfile($repo_root, 'bin', 'fsmgen'),
            '--quiet',
            '--outdir',
            $dir,
            '--output',
            $output,
            $fixture,
        ],
    );

    ok($success, 'CLI generation succeeds for the FIFO library fixture');
    is(join('', @{$stderr_buf || []}), '', 'CLI generation keeps stderr empty');
    ok(-f File::Spec->catfile($dir, 'fifo_library_use.fsm'), 'CLI writes importing actor .fsm');
    ok(-f File::Spec->catfile($dir, 'fifo_library_use__u_fifo.fsm'), 'CLI writes specialized FIFO child .fsm');
    ok(-f File::Spec->catfile($dir, 'fifo_library_use_top.fsm'), 'CLI writes generated top .fsm');
    ok(-f $output, 'CLI writes generated SystemVerilog');

    my $hdl = slurp($output);
    like($hdl, qr/\bmodule\s+fifo_library_use_top\b/, 'HDL contains generated top module');
    like($hdl, qr/\bmodule\s+fifo_library_use__u_fifo\s*#\(/, 'HDL contains parameterized FIFO child module');
    like($hdl, qr/fifo_library_use__u_fifo\s+#\([\s\S]*?\.DATA_WIDTH\(8\)[\s\S]*?\.DEPTH\(4\)[\s\S]*?\.PTR_WIDTH\(2\)[\s\S]*?\.OCC_WIDTH\(3\)[\s\S]*?\)\s+u_fifo\s*\(/, 'generated top applies fixed FIFO parameter bindings');
    like($hdl, qr/u_fifo\s*\([\s\S]*?\.data_in\(data_in\)[\s\S]*?\.data_out\(data_out\)[\s\S]*?\.empty\(empty\)[\s\S]*?\.full\(full\)[\s\S]*?\.read_req\(read_req\)[\s\S]*?\.write_req\(write_req\)/, 'generated top wires FIFO interface ports');
    like($hdl, qr/\breg\s+\[7:0\]\s+data_0\b/, 'HDL contains scalarized FIFO entry data_0');
    like($hdl, qr/\breg\s+\[7:0\]\s+data_3\b/, 'HDL contains scalarized FIFO entry data_3');
    like($hdl, qr/\bassign\s+accepted_push_data_0_data_in_en\s*=\s*accepted_push_en\s*&\s*\(~\|wr_ptr\)/, 'HDL gates accepted push entry 0 by write pointer');
    like($hdl, qr/\bassign\s+accepted_pop_data_out_data_0_en\s*=\s*accepted_pop_en\s*&\s*\(~\|rd_ptr\)/, 'HDL gates accepted pop entry 0 by read pointer');
};

subtest 'AST factorization keeps CoreAST signal identities distinct in generated HDL' => sub {
    my $dir = tempdir(CLEANUP => 1);
    my $output = File::Spec->catfile($dir, 'fifo_library_use.sv');

    my ($success) = run(
        command => [
            File::Spec->catfile($repo_root, 'bin', 'fsmgen'),
            '--quiet',
            '--outdir',
            $dir,
            '--output',
            $output,
            $fixture,
        ],
    );
    ok($success, 'CLI generation succeeds for factorization audit');

    my $hdl = slurp($output);
    like($hdl, qr/\bassign\s+not_write_req\s*=\s*!write_req;/, 'factorization emits not_write_req helper');
    like($hdl, qr/\bassign\s+not_read_req\s*=\s*!read_req;/, 'factorization emits not_read_req helper');
    like($hdl, qr/\bassign\s+not_write_req_and_not_read_req\s*=\s*not_write_req\s*&\s*not_read_req;/, 'combined helper preserves both distinct source signals');
    unlike($hdl, qr/\bassign\s+not_write_req_and_not_read_req\s*=\s*not_read_req\s*&\s*not_read_req;/, 'combined helper does not collapse write_req identity into read_req');
    unlike($hdl, qr/wr_ptr_eq_const_2\s*=\s*.*rd_ptr_eq_const_2/, 'wr_ptr factorized helper does not reuse rd_ptr identity');
    unlike($hdl, qr/occupancy_eq_const_3\s*=\s*.*rd_ptr_eq_const_3/, 'occupancy factorized helper does not reuse rd_ptr identity');
};

done_testing();

sub slurp {
    my ($path) = @_;
    open my $fh, '<', $path or die "cannot read $path: $!";
    my $text = do { local $/; <$fh> };
    close $fh or die "cannot close $path: $!";
    return $text;
}
