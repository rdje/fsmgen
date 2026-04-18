#!/usr/bin/env perl

use strict;
use warnings;
use Test::More tests => 14;
use File::Spec;
use File::Temp qw/ tempdir /;
use IPC::Cmd qw(run);

my $tempdir = tempdir( CLEANUP => 1 );

my $neg_fsm = File::Spec->catfile($tempdir, 'comb_self_dep_neg.fsm');
my $neg_out = File::Spec->catfile($tempdir, 'comb_self_dep_neg.sv');
my $neg_indirect_fsm = File::Spec->catfile($tempdir, 'comb_self_dep_indirect_neg.fsm');
my $neg_indirect_out = File::Spec->catfile($tempdir, 'comb_self_dep_indirect_neg.sv');
my $neg_d_input_fsm = File::Spec->catfile($tempdir, 'd_input_self_dep_neg.fsm');
my $neg_d_input_out = File::Spec->catfile($tempdir, 'd_input_self_dep_neg.sv');
my $neg_d_input_guard_fsm = File::Spec->catfile($tempdir, 'd_input_guard_self_dep_neg.fsm');
my $neg_d_input_guard_out = File::Spec->catfile($tempdir, 'd_input_guard_self_dep_neg.sv');
my $neg_d_input_dual_fsm = File::Spec->catfile($tempdir, 'd_input_dual_self_dep_neg.fsm');
my $neg_d_input_dual_out = File::Spec->catfile($tempdir, 'd_input_dual_self_dep_neg.sv');
my $pos_fsm = File::Spec->catfile($tempdir, 'comb_self_dep_pos.fsm');
my $pos_out = File::Spec->catfile($tempdir, 'comb_self_dep_pos.sv');
my $pos_d_input_dual_mirror_fsm = File::Spec->catfile($tempdir, 'd_input_dual_mirror_pos.fsm');
my $pos_d_input_dual_mirror_out = File::Spec->catfile($tempdir, 'd_input_dual_mirror_pos.sv');

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

write_file($neg_d_input_fsm, <<'FSM_NEG_D_INPUT');
(+fsm d_input_self_dep_neg)
(+system
  (clock clk)
  (sreset rstn)
)
(-state0
  (A <= (+ A 1))
)
(+size
  (A 8)
)
FSM_NEG_D_INPUT

write_file($neg_d_input_guard_fsm, <<'FSM_NEG_D_INPUT_GUARD');
(+fsm d_input_guard_self_dep_neg)
(+system
  (clock clk)
  (sreset rstn)
)
(-state0
  (A <= B <A)
)
(+size
  (A 8)
  (B 8)
)
FSM_NEG_D_INPUT_GUARD

write_file($neg_d_input_dual_fsm, <<'FSM_NEG_D_INPUT_DUAL');
(+fsm d_input_dual_self_dep_neg)
(+system
  (clock clk)
  (sreset rstn)
)
(-state0
  (A <=+ (+ A 1))
)
(+size
  (A 8)
)
FSM_NEG_D_INPUT_DUAL

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

write_file($pos_d_input_dual_mirror_fsm, <<'FSM_POS_D_INPUT_DUAL_MIRROR');
(+fsm d_input_dual_mirror_pos)
(+system
  (clock clk)
  (sreset rstn)
)
(-state0
  (A <=+ (+ A_r 1))
)
(+size
  (A 8)
)
FSM_POS_D_INPUT_DUAL_MIRROR

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

my ($neg_d_input_success, $neg_d_input_error, $neg_d_input_full_buf, $neg_d_input_stdout_buf, $neg_d_input_stderr_buf) =
    run(command => ["./bin/fsmgen", "-o", $neg_d_input_out, "--quiet", $neg_d_input_fsm]);

ok(!$neg_d_input_success, "rejects D-input self-dependency with '<='");
my $neg_d_input_output = join('', @{ $neg_d_input_stdout_buf || [] }, @{ $neg_d_input_stderr_buf || [] }, ($neg_d_input_error || ''));
like(
    $neg_d_input_output,
    qr/Illegal D-input self-dependency/,
    "reports D-input self-dependency parser error"
);

my ($neg_d_input_guard_success, $neg_d_input_guard_error, $neg_d_input_guard_full_buf, $neg_d_input_guard_stdout_buf, $neg_d_input_guard_stderr_buf) =
    run(command => ["./bin/fsmgen", "-o", $neg_d_input_guard_out, "--quiet", $neg_d_input_guard_fsm]);

ok(!$neg_d_input_guard_success, "rejects D-input self-dependency through '<=' guard condition");
my $neg_d_input_guard_output = join('', @{ $neg_d_input_guard_stdout_buf || [] }, @{ $neg_d_input_guard_stderr_buf || [] }, ($neg_d_input_guard_error || ''));
like(
    $neg_d_input_guard_output,
    qr/Illegal D-input self-dependency/,
    "reports D-input self-dependency for guard condition"
);

my ($neg_d_input_dual_success, $neg_d_input_dual_error, $neg_d_input_dual_full_buf, $neg_d_input_dual_stdout_buf, $neg_d_input_dual_stderr_buf) =
    run(command => ["./bin/fsmgen", "-o", $neg_d_input_dual_out, "--quiet", $neg_d_input_dual_fsm]);

ok(!$neg_d_input_dual_success, "rejects D-input self-dependency with '<=+'");
my $neg_d_input_dual_output = join('', @{ $neg_d_input_dual_stdout_buf || [] }, @{ $neg_d_input_dual_stderr_buf || [] }, ($neg_d_input_dual_error || ''));
like(
    $neg_d_input_dual_output,
    qr/Illegal D-input self-dependency/,
    "reports D-input self-dependency parser error for '<=+'"
);

my ($pos_success, $pos_error, $pos_full_buf, $pos_stdout_buf, $pos_stderr_buf) =
    run(command => ["./bin/fsmgen", "-o", $pos_out, "--quiet", $pos_fsm]);

ok($pos_success, "allows synchronous self-dependency with '<-'")
    or diag("Error: " . ($pos_error || "unknown")
        . "\nStderr:\n" . join("", @{$pos_stderr_buf || []})
        . "\nStdout:\n" . join("", @{$pos_stdout_buf || []}));

ok(-e $pos_out, "writes output for synchronous self-dependency case");

my ($pos_d_input_dual_mirror_success, $pos_d_input_dual_mirror_error, $pos_d_input_dual_mirror_full_buf, $pos_d_input_dual_mirror_stdout_buf, $pos_d_input_dual_mirror_stderr_buf) =
    run(command => ["./bin/fsmgen", "-o", $pos_d_input_dual_mirror_out, "--quiet", $pos_d_input_dual_mirror_fsm]);

ok($pos_d_input_dual_mirror_success, "allows '<=+' feedback through generated '_r' Q mirror")
    or diag("Error: " . ($pos_d_input_dual_mirror_error || "unknown")
        . "\nStderr:\n" . join("", @{$pos_d_input_dual_mirror_stderr_buf || []})
        . "\nStdout:\n" . join("", @{$pos_d_input_dual_mirror_stdout_buf || []}));

ok(-e $pos_d_input_dual_mirror_out, "writes output for '<=+' Q mirror feedback case");

sub write_file {
    my ($path, $content) = @_;
    open my $fh, '>', $path or die "Cannot open $path for write: $!";
    print {$fh} $content or die "Cannot write $path: $!";
    close $fh or die "Cannot close $path: $!";
}
