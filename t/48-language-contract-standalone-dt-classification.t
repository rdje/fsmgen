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

subtest 'general/combinational DT blocks now keep explicit standalone_dt classification' => sub {
    my $fsm_module = parse_fsm_module(<<'FSM');
(?fsm:standalone_dt_contract
  (+system
    (clock clk)
    (sreset rstn)
  )
  (+size
    (REG_OUT 1)
    (DT_OUT 1)
    (IN 1)
  )
  (idle
    (REG_OUT <= IN)
  )
  (-misc
    (DT_OUT = REG_OUT)
  )
  (-mycombDT
    (DT_OUT = 0)
  )
)
FSM

    my @states = @{$fsm_module->states || []};
    is(scalar(@states), 3, 'FSM keeps one FSM-state DT plus two standalone DT blocks');

    my ($regular_state) = grep { $_->name eq 'idle' } @states;
    my ($misc_dt) = grep { $_->name eq '-misc' } @states;
    my ($comb_dt) = grep { $_->name eq '-mycombDT' } @states;

    ok($regular_state, 'regular FSM-state DT stays present');
    ok($misc_dt, 'first standalone DT block stays present');
    ok($comb_dt, 'second standalone DT block stays present');

    is($regular_state->state_type, 'normal', 'regular FSM-state DT keeps normal state_type');
    is($misc_dt->state_type, 'standalone_dt', 'hyphen-prefixed general DT gets standalone_dt state_type');
    is($comb_dt->state_type, 'standalone_dt', 'another hyphen-prefixed general DT also gets standalone_dt state_type');

    ok($regular_state->is_regular_state, 'regular FSM-state DT stays in the encoded-state family');
    ok(!$regular_state->can('is_standalone_dt') || !$regular_state->is_standalone_dt, 'regular FSM-state DT is not marked as standalone');
    ok(!$misc_dt->is_regular_state, 'standalone DT is not treated as a regular encoded state');
    ok($misc_dt->is_standalone_dt, 'standalone DT is marked explicitly');
    ok(!$comb_dt->is_regular_state, 'second standalone DT is not treated as a regular encoded state');
    ok($comb_dt->is_standalone_dt, 'second standalone DT is marked explicitly');
};

subtest 'general/combinational DT blocks stay out of the encoded state plan and use DT-style enables' => sub {
    my $fsm_module = parse_fsm_module(<<'FSM');
(?fsm:standalone_dt_enable_contract
  (+system
    (clock clk)
    (sreset rstn)
  )
  (+size
    (REG_OUT 1)
    (DT_OUT 1)
    (IN 1)
  )
  (idle
    (REG_OUT <= IN)
  )
  (-misc
    (DT_OUT = REG_OUT)
  )
)
FSM

    my $hdl_gen = FSM::HDL::FlattenedDT->new(debug => 0);
    my $hdl = $hdl_gen->generate_systemverilog($fsm_module);
    my $state_plan = $hdl_gen->{enable_graph_module_planning_support}->build_state_register_plan($fsm_module);

    ok($state_plan->{has_state_registers}, 'regular state plan stays enabled when a real FSM state exists');
    is($state_plan->{state_count}, 1, 'standalone DT blocks do not count as encoded states');
    is(join(',', map { $_->{localparam_name} } @{$state_plan->{encodings} || []}), 'IDLE', 'state encodings include only the FSM-state DT');

    ok(exists $hdl_gen->{state_enables}->{idle}, 'FSM-state DT keeps a regular state enable');
    ok(!exists $hdl_gen->{state_enables}->{'-misc'}, 'standalone DT does not get a regular-state enable');
    ok(exists $hdl_gen->{dt_enables}->{'-misc'}, 'standalone DT gets a DT-style enable');

    like($hdl, qr/\bassign\s+misc_en\s*=\s*1'b1\s*;/, 'generated HDL emits a DT-style enable for the standalone DT');
    unlike($hdl, qr/current_state\s*==\s*MISC/, 'generated HDL does not encode the standalone DT as a regular state');
};

subtest 'standalone DT blocks accept optional DTE guards using the normal guard grammar' => sub {
    my $fsm_module = parse_fsm_module(<<'FSM');
(?fsm:standalone_dt_guard_contract
  (+system
    (clock clk)
    (sreset rstn)
  )
  (+size
    (req 1)
    (hold 1)
    (mode 2)
    (ready 1)
    (OUT_A 1)
    (OUT_B 1)
    (OUT_C 1)
    (OUT_D 1)
    (OUT_E 1)
  )
  (-route <req
    (= (OUT_A 1))
  )
  (-neg <!hold
    (= (OUT_B 1))
  )
  (-mode_hit <mode=3
    (= (OUT_C 1))
  )
  (-expr_guard <(& req ready)
    (= (OUT_D 1))
  )
  (-plain
    (= (OUT_E 1))
  )
)
FSM

    my %state_by_name = map { $_->name => $_ } @{$fsm_module->states || []};

    ok($state_by_name{'-route'}->dt_enable_condition, 'truthy shorthand guard is stored as the DT enable condition');
    assert_binary_condition(
        $state_by_name{'-route'}->dt_enable_condition,
        '!=',
        'req',
        '0',
        'standalone DT <req DTE guard',
    );
    assert_binary_condition(
        $state_by_name{'-neg'}->dt_enable_condition,
        '==',
        'hold',
        '0',
        'standalone DT <!hold DTE guard',
    );
    assert_binary_condition(
        $state_by_name{'-mode_hit'}->dt_enable_condition,
        '==',
        'mode',
        '3',
        'standalone DT <mode=3 DTE guard',
    );
    is($state_by_name{'-plain'}->dt_enable_condition, undef, 'unguarded standalone DT keeps the default DTE');

    my $hdl = FSM::HDL::FlattenedDT->new(debug => 0)->generate_systemverilog($fsm_module);

    like($hdl, qr/\bassign\s+route_en\s*=\s*req\s*;/, 'truthy standalone DT DTE emits through shared AST rendering');
    like($hdl, qr/\bassign\s+neg_en\s*=\s*!hold\s*;/, 'negated standalone DT DTE emits through shared AST rendering');
    like($hdl, qr/\bassign\s+mode_hit_en\s*=\s*mode\s*==\s*3\s*;/, 'comparison standalone DT DTE emits as the top-level DT enable');
    like($hdl, qr/\bassign\s+expr_guard_en\s*=\s*intermediate_and_req_ready_\d+\s*;/, 'expression standalone DT DTE emits through a backed intermediate');
    like($hdl, qr/\bassign\s+intermediate_and_req_ready_\d+\s*=\s*req\s*&\s*ready\s*;/, 'expression standalone DT DTE intermediate is assigned');
    like($hdl, qr/\bassign\s+plain_en\s*=\s*1'b1\s*;/, 'unguarded standalone DT defaults DTE to one');
    like($hdl, qr/\bassign\s+route_out_a_1_en\s*=\s*route_en\s*&\s*1'b1\s*;/, 'truthy DTE gates the standalone DT output enable boundary');
    like($hdl, qr/\bassign\s+expr_guard_out_d_1_en\s*=\s*expr_guard_en\s*&\s*1'b1\s*;/, 'expression DTE gates the standalone DT output enable boundary');
};

done_testing();

sub parse_fsm_module {
    my ($fsm_text) = @_;
    my $fsm_path = File::Spec->catfile($tempdir, 'standalone_dt_' . int(rand(1_000_000)) . '.fsm');
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
