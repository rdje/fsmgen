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

my $fsm_module = parse_fsm_module(<<'FSM');
(?fsm:state_dt_dte_guard_contract
  (+system
    (clock clk)
    (sreset rstn)
  )
  (+size
    (req 1)
    (ready 1)
    (done 1)
    (OUT_A 1)
    (OUT_B 1)
  )
  (idle <req
    (= (OUT_A 1))
    (-> active <done)
  )
  (active <(& req ready)
    (= (OUT_B 1))
    (-> idle)
  )
)
FSM

my %state_by_name = map { $_->name => $_ } @{$fsm_module->states || []};

ok($state_by_name{idle}->dt_enable_condition, 'regular state DT stores its header DTE guard');
assert_binary_condition(
    $state_by_name{idle}->dt_enable_condition,
    '!=',
    'req',
    '0',
    'regular state DT <req DTE guard',
);
ok($state_by_name{active}->dt_enable_condition, 'regular state DT stores expression DTE guard');

my $hdl_gen = FSM::HDL::FlattenedDT->new(debug => 0);
my $hdl = $hdl_gen->generate_systemverilog($fsm_module);

like(
    $hdl,
    qr/\bassign\s+idle_en\s*=\s*\(current_state\s*==\s*IDLE\)\s*\|\s*req\s*;/,
    'state DT DTE renders scalar header activation through shared AST support',
);
like(
    $hdl,
    qr/\bassign\s+active_en\s*=\s*\(current_state\s*==\s*ACTIVE\)\s*\|\s*intermediate_and_req_ready_\d+\s*;/,
    'state DT DTE bitwise-ORs state decode with expression header activation',
);
like(
    $hdl,
    qr/\bassign\s+intermediate_and_req_ready_\d+\s*=\s*req\s*&\s*ready\s*;/,
    'state DT expression DTE intermediate is assigned',
);
like(
    $hdl,
    qr/\bassign\s+idle_out_a_1_en\s*=\s*idle_en\s*&\s*1'b1\s*;/,
    'state DT scalar DTE gates normal output enable boundary',
);
like(
    $hdl,
    qr/\bassign\s+idle_next_state_active_en\s*=\s*idle_en\s*&\s*done\s*;/,
    'state DT scalar DTE also gates transition output enable boundary',
);
like(
    $hdl,
    qr/\bassign\s+active_out_b_1_en\s*=\s*active_en\s*&\s*1'b1\s*;/,
    'state DT expression DTE gates normal output enable boundary',
);
like(
    $hdl,
    qr/\bassign\s+active_next_state_idle_en\s*=\s*active_en\s*&\s*1'b1\s*;/,
    'state DT expression DTE also gates transition output enable boundary',
);

my $shared_guard_module = parse_fsm_module(<<'FSM');
(?fsm:shared_dte_guard_factor_contract
  (+system
    (clock clk)
    (sreset rstn)
  )
  (+size
    (mode 2)
    (OUT_A 1)
    (OUT_B 1)
  )
  (idle <mode=3
    (= (OUT_A 1))
    (-> active)
  )
  (active <mode=3
    (= (OUT_B 1))
    (-> idle)
  )
)
FSM

my $shared_hdl = FSM::HDL::FlattenedDT->new(debug => 0)->generate_systemverilog($shared_guard_module);

like(
    $shared_hdl,
    qr/\bwire\s+mode_eq_const_3\s*;/,
    'shared lowered DTE guard expression receives one factored wire declaration',
);
like(
    $shared_hdl,
    qr/\bassign\s+mode_eq_const_3\s*=\s*mode\s*==\s*3\s*;\s*\/\/ Source:\s*ast_factorization\b/,
    'shared lowered DTE guard expression is emitted by the AST factorizer',
);
like(
    $shared_hdl,
    qr/\bassign\s+idle_en\s*=\s*\(current_state\s*==\s*IDLE\)\s*\|\s*mode_eq_const_3\s*;/,
    'idle state DTE reuses the factored lowered guard expression',
);
like(
    $shared_hdl,
    qr/\bassign\s+active_en\s*=\s*\(current_state\s*==\s*ACTIVE\)\s*\|\s*mode_eq_const_3\s*;/,
    'active state DTE reuses the same factored lowered guard expression',
);
unlike(
    $shared_hdl,
    qr/\bassign\s+(?:idle|active)_en\s*=\s*[^;]*mode\s*==\s*3\s*;/,
    'state DTE assignments do not inline the shared guard after factorization',
);

done_testing();

sub parse_fsm_module {
    my ($fsm_text) = @_;
    my $fsm_path = File::Spec->catfile($tempdir, 'state_dt_dte_guard.fsm');
    write_file($fsm_path, $fsm_text);

    my $raw_ast = Lispish::multi($fsm_path);
    my $adapter = FSM::Adapter::FSMGenFull->new(debug => 0);
    return $adapter->parse_fsm($raw_ast);
}

sub write_file {
    my ($path, $content) = @_;
    open my $fh, '>', $path or die "Cannot open $path for write: $!";
    print {$fh} $content or die "Cannot write $path: $!";
    close $fh or die "Cannot close $path: $!";
}

sub assert_binary_condition {
    my ($condition, $operator, $lhs_name, $rhs_sv, $label) = @_;
    ok($condition->isa('FSM::CoreAST::BinaryOp'), "$label uses BinaryOp AST");
    is($condition->operator, $operator, "$label uses the expected operator");
    is($condition->left->signal->name, $lhs_name, "$label keeps the expected signal on the left");
    is($condition->right->to_systemverilog, $rhs_sv, "$label keeps the expected RHS literal");
}
