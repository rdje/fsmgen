#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use File::Spec;
use File::Temp qw/ tempdir /;
use FindBin;

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use Lispish;
use FSM::Adapter::FSMGenFull;
use FSM::HDL::FlattenedDT;

my $tempdir = tempdir(CLEANUP => 1);
my $fsm_path = File::Spec->catfile($tempdir, 'guard_shorthand.fsm');

write_file($fsm_path, <<'FSM');
(?fsm:guard_shorthand
  (+system
    (clock clk)
    (sreset rstn)
  )
  (+size
    (A 8)
    (B 8)
    (req 1)
    (full 1)
    (mode 4)
    (count 4)
    (start 1)
    (REQ_HIT 1)
    (FULL_HIT 1)
    (MODE_HIT 1)
    (COUNT_HIT 1)
    (START_HIT 1)
  )
  (idle
    (<req
      (REQ_HIT = 1)
    )
    (<!full
      (FULL_HIT = 1)
    )
    (<mode==3
      (MODE_HIT = 1)
    )
    (<count<=3
      (COUNT_HIT = 1)
    )
    (START_HIT <= 1 <start)
    (-> busy <mode!=0)
  )
  (busy
    (A <= B)
  )
)
FSM

my $raw_ast = Lispish::multi($fsm_path);
my $adapter = FSM::Adapter::FSMGenFull->new(debug => 0);
my $fsm_module = $adapter->parse_fsm($raw_ast);

my $elements = state_elements($fsm_module, 'idle');
is(scalar(@$elements), 6, 'idle state keeps all shorthand-guard elements');

assert_binary_condition($elements->[0]->condition, '!=', 'req', '0', '<req lowers to req != 0');
assert_binary_condition($elements->[1]->condition, '==', 'full', '0', '<!full lowers to full == 0');
assert_binary_condition($elements->[2]->condition, '==', 'mode', '3', '<mode==3 lowers to equality comparison');
assert_binary_condition($elements->[3]->condition, '<=', 'count', '3', '<count<=3 lowers to relational comparison');
assert_binary_condition($elements->[4]->condition, '!=', 'start', '0', 'suffix <start lowers to start != 0');
assert_binary_condition($elements->[5]->condition, '!=', 'mode', '0', 'suffix <mode!=0 lowers to relational comparison');

my $hdl = FSM::HDL::FlattenedDT->new(debug => 0)->generate_systemverilog($fsm_module);

like($hdl, qr/\bidle_req_hit_1_en\s*=\s*idle_en\s*&\s*req\b/, 'generated HDL renders req shorthand through bare-signal truthiness');
like($hdl, qr/\bidle_full_hit_1_en\s*=\s*idle_en\s*&\s*!full\b/, 'generated HDL renders !full shorthand through direct negation');
like($hdl, qr/\bmode\s*==\s*3\b/, 'generated HDL contains equality shorthand lowering');
like($hdl, qr/\bcount\s*<=\s*3\b/, 'generated HDL contains relational shorthand lowering');
like($hdl, qr/\bidle_start_hit_1_en\s*=\s*idle_en\s*&\s*start\b/, 'generated HDL renders suffix truthiness shorthand through bare-signal truthiness');
like($hdl, qr/\bidle_next_state_busy_en\s*=\s*idle_en\s*&\s*mode\b/, 'generated HDL renders multibit nonzero suffix shorthand through bare-signal truthiness');

done_testing();

sub write_file {
    my ($path, $content) = @_;
    open my $fh, '>', $path or die "Cannot open $path for write: $!";
    print {$fh} $content or die "Cannot write $path: $!";
    close $fh or die "Cannot close $path: $!";
}

sub state_elements {
    my ($fsm_module, $state_name) = @_;
    my ($state) = grep { $_->name eq $state_name } @{ $fsm_module->states || [] };
    ok($state, "found state '$state_name'");
    return [] unless $state;

    my @elements;
    for my $dt (@{ $state->decision_trees || [] }) {
        push @elements, @{ $dt->elements || [] };
    }
    return \@elements;
}

sub assert_binary_condition {
    my ($condition, $operator, $lhs_name, $rhs_sv, $label) = @_;
    ok($condition->isa('FSM::CoreAST::BinaryOp'), "$label uses BinaryOp AST");
    is($condition->operator, $operator, "$label uses the expected operator");
    is($condition->left->signal->name, $lhs_name, "$label keeps the expected signal on the left");
    is($condition->right->to_systemverilog, $rhs_sv, "$label keeps the expected RHS literal");
}
