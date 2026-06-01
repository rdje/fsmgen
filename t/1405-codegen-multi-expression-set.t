#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use File::Spec;
use File::Temp qw/ tempdir /;
use FindBin;
use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::Adapter::ISF;
use FSM::Scheduler::ISF;
use Lispish;
use FSM::Adapter::FSMGenFull;
use FSM::HDL::FlattenedDT;

# CODEGEN-MULTI-EXPRESSION-SET-ALIAS.2/.3
#
# A register written by two+ expression `(set …)`s in different states of one transaction must
# get a DISTINCT write-enable per write site. A prior bug collapsed distinct expression RHS to
# one `<reg>_expr_en` wire (generate_rhs_based_enable_name strips the expr-namer's
# disambiguating suffix): the later `assign` overwrote it, silently dropping the earlier write,
# and the onehot0 selector degenerated to the same name twice. The fix disambiguates colliding
# LHS-level enable names per register. verilator/yosys passed before (a duplicate identical
# assign is not a structural multi-driver), so this guards the wiring at the generated-SV level.

my $tempdir = tempdir(CLEANUP => 1);

sub lower_fsm {
    my ($source, $name) = @_;
    my $actor = FSM::Adapter::ISF->new()->parse_source($source, "$name.isf");
    return FSM::Scheduler::ISF->new()->lower($actor)->{files}{"$name.fsm"};
}

sub fsm_to_hdl {
    my ($fsm_text, $name) = @_;
    my $path = File::Spec->catfile($tempdir, "$name.fsm");
    open my $fh, '>', $path or die "write $path: $!";
    print $fh $fsm_text; close $fh;
    my $module = FSM::Adapter::FSMGenFull->new(debug => 0)->parse_fsm(Lispish::multi($path));
    return FSM::HDL::FlattenedDT->new(debug => 0)->generate_systemverilog($module);
}

subtest 'two expression (set)s to one register get distinct, non-aliased enables' => sub {
    my $hdl = fsm_to_hdl(lower_fsm(<<'ISF', 'dbl'), 'dbl');
(actor dbl
  (interface (input start) (input a (width 8)) (input b (width 8)) (output done) (output acc (width 8)))
  (transaction main
    (on start)
    (set acc (+ acc a))
    (set acc (+ acc b))
    (complete done)))
ISF
    # each write site drives its own per-state enable
    like($hdl, qr/\bassign acc_expr_en = main_set_1_acc_acc_a_en;/,   'first  (set acc (+ acc a)) -> acc_expr_en from set_1');
    like($hdl, qr/\bassign acc_expr_2_en = main_set_2_acc_acc_b_en;/, 'second (set acc (+ acc b)) -> a DISTINCT acc_expr_2_en from set_2');
    # the two enables must not both alias to the same dt enable (the bug)
    unlike($hdl, qr/\bassign acc_expr_en = main_set_2_acc_acc_b_en;/, 'the first enable is NOT aliased to the second write');
    # the two next-value mux arms gate on the distinct enables
    like($hdl, qr/if \(acc_expr_en\) begin/,   'one mux arm gates on acc_expr_en');
    like($hdl, qr/if \(acc_expr_2_en\) begin/, 'the other mux arm gates on the distinct acc_expr_2_en');
};

subtest 'a single expression (set) per register is unchanged (no churn)' => sub {
    my $hdl = fsm_to_hdl(lower_fsm(<<'ISF', 'one'), 'one');
(actor one
  (interface (input start) (input a (width 8)) (output done) (output acc (width 8)))
  (transaction main
    (on start)
    (set acc (+ acc a))
    (complete done)))
ISF
    like($hdl, qr/\bassign acc_expr_en = main_set_1_acc_acc_a_en;/, 'a single expression set keeps the bare acc_expr_en name');
    unlike($hdl, qr/acc_expr_2_en/, 'no disambiguator is introduced for a single write');
};

done_testing();
