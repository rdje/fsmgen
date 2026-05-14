#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use File::Spec;
use File::Temp qw(tempdir);
use FindBin;
use IPC::Cmd qw(run);

subtest 'raw and aliased shift expressions reach SystemVerilog generation' => sub {
    my $tempdir = tempdir(CLEANUP => 1);
    my $fsm_path = File::Spec->catfile($tempdir, 'shift_expression_generation.fsm');
    my $hdl_path = File::Spec->catfile($tempdir, 'shift_expression_generation.sv');

    write_file($fsm_path, <<'FSM');
(?fsm:shift_expression_generation
  (+system
    (clock clk)
    (areset rst_n)
  )
  (+size
    (go 1)
    (BUS 8)
    (OUT_L 8)
    (OUT_R 8)
    (ALIAS_L 8)
    (ALIAS_R 8)
  )
  (idle
    (<go
      (<- (OUT_L (<< BUS 1)))
      (<- (OUT_R (>> BUS 1)))
      (<- (ALIAS_L (shl BUS 1)))
      (<- (ALIAS_R (shr BUS 1)))
    )
  )
)
FSM

    my ($success, $error_message, $full_buf, $stdout_buf, $stderr_buf) = run(
        command => [
            './bin/fsmgen',
            '--quiet',
            '--output',
            $hdl_path,
            $fsm_path,
        ],
    );

    ok($success, 'shift expression FSM generates HDL');
    is(join('', @{$stderr_buf || []}), '', 'shift expression generation keeps stderr clean');
    ok(-f $hdl_path, 'shift expression generation writes HDL output');

    my $hdl = slurp($hdl_path);
    like($hdl, qr/\bBUS\s*<<\s*1\b/, 'left shift is emitted in SystemVerilog');
    like($hdl, qr/\bBUS\s*>>\s*1\b/, 'right shift is emitted in SystemVerilog');
};

subtest 'shift expressions require exactly two operands' => sub {
    my $tempdir = tempdir(CLEANUP => 1);
    my $fsm_path = File::Spec->catfile($tempdir, 'bad_shift_expression_generation.fsm');
    my $hdl_path = File::Spec->catfile($tempdir, 'bad_shift_expression_generation.sv');

    write_file($fsm_path, <<'FSM');
(?fsm:bad_shift_expression_generation
  (+system
    (clock clk)
    (areset rst_n)
  )
  (+size
    (go 1)
    (BUS 8)
    (OUT_L 8)
  )
  (idle
    (<go
      (<- (OUT_L (<< BUS 1 0)))
    )
  )
)
FSM

    my ($success, $error_message, $full_buf) = run(
        command => [
            './bin/fsmgen',
            '--quiet',
            '--output',
            $hdl_path,
            $fsm_path,
        ],
    );

    ok(!$success, 'malformed shift expression is rejected');
    like(join('', @{$full_buf || []}), qr/requires exactly 2 operands/, 'malformed shift diagnostic is targeted');
    ok(!-f $hdl_path, 'malformed shift expression does not write HDL output');
};

done_testing();

sub write_file {
    my ($path, $content) = @_;
    open my $fh, '>', $path or die "cannot write $path: $!";
    print {$fh} $content;
    close $fh or die "cannot close $path: $!";
}

sub slurp {
    my ($path) = @_;
    open my $fh, '<', $path or die "cannot read $path: $!";
    my $text = do { local $/; <$fh> };
    close $fh or die "cannot close $path: $!";
    return $text;
}
