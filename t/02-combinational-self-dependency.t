#!/usr/bin/env perl

use strict;
use warnings;
use Test::More tests => 6;
use File::Spec;
use File::Temp qw/ tempdir /;
use IPC::Cmd qw(run);

my $tempdir = tempdir( CLEANUP => 1 );

my $neg_fsm = File::Spec->catfile($tempdir, 'comb_self_dep_neg.fsm');
my $neg_out = File::Spec->catfile($tempdir, 'comb_self_dep_neg.sv');
my $neg_indirect_fsm = File::Spec->catfile($tempdir, 'comb_self_dep_indirect_neg.fsm');
my $neg_indirect_out = File::Spec->catfile($tempdir, 'comb_self_dep_indirect_neg.sv');
my $pos_fsm = File::Spec->catfile($tempdir, 'comb_self_dep_pos.fsm');
my $pos_out = File::Spec->catfile($tempdir, 'comb_self_dep_pos.sv');

write_file($neg_fsm, <<'FSM_NEG');
(+fsm comb_self_dep_neg)
(+system
  (clock clk)
  (sreset rstn)
)
(-state0
  (A = A)
)
(+size
  (A 8)
)
FSM_NEG

write_file($neg_indirect_fsm, <<'FSM_NEG_INDIRECT');
(+fsm comb_self_dep_indirect_neg)
(+system
  (clock clk)
  (sreset rstn)
)
(-state0
  (A = B)
  (B = A)
)
(+size
  (A 8)
  (B 8)
)
FSM_NEG_INDIRECT

write_file($pos_fsm, <<'FSM_POS');
(+fsm comb_self_dep_pos)
(+system
  (clock clk)
  (sreset rstn)
)
(-state0
  (A <- A)
)
(+size
  (A 8)
)
FSM_POS

my ($neg_success, $neg_error, $neg_full_buf, $neg_stdout_buf, $neg_stderr_buf) =
    run(command => ["./bin/fsmgen", "-o", $neg_out, "--quiet", $neg_fsm]);

ok(!$neg_success, "rejects combinational self-dependency with '='");
my $neg_output = join('', @{ $neg_stdout_buf || [] }, @{ $neg_stderr_buf || [] }, ($neg_error || ''));
like(
    $neg_output,
    qr/Illegal combinational self-dependency/,
    "reports combinational self-dependency parser error"
);

my ($neg_indirect_success, $neg_indirect_error, $neg_indirect_full_buf, $neg_indirect_stdout_buf, $neg_indirect_stderr_buf) =
    run(command => ["./bin/fsmgen", "-o", $neg_indirect_out, "--quiet", $neg_indirect_fsm]);

ok(!$neg_indirect_success, "rejects indirect combinational self-dependency cycle with '='");
my $neg_indirect_output = join('', @{ $neg_indirect_stdout_buf || [] }, @{ $neg_indirect_stderr_buf || [] }, ($neg_indirect_error || ''));
like(
    $neg_indirect_output,
    qr/Illegal combinational self-dependency/,
    "reports combinational self-dependency for indirect '=' cycle"
);

my ($pos_success, $pos_error, $pos_full_buf, $pos_stdout_buf, $pos_stderr_buf) =
    run(command => ["./bin/fsmgen", "-o", $pos_out, "--quiet", $pos_fsm]);

ok($pos_success, "allows synchronous self-dependency with '<-'")
    or diag("Error: " . ($pos_error || "unknown")
        . "\nStderr:\n" . join("", @{$pos_stderr_buf || []})
        . "\nStdout:\n" . join("", @{$pos_stdout_buf || []}));

ok(-e $pos_out, "writes output for synchronous self-dependency case");

sub write_file {
    my ($path, $content) = @_;
    open my $fh, '>', $path or die "Cannot open $path for write: $!";
    print {$fh} $content or die "Cannot write $path: $!";
    close $fh or die "Cannot close $path: $!";
}
