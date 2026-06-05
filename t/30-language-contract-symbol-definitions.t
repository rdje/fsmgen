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
use FSM::IR::IntentHIRBuilder;

my $tempdir = tempdir(CLEANUP => 1);

my ($adapter, $fsm_module) = parse_fsm_with_adapter(<<'FSM');
(?fsm:symbol_contract
  (+constants
    (C0 8'3)
    (ZERO const_8b0)
    (BYTE_PAIR (8'hA5 8'h3C))
    (BYTE_MASK (8'hF0 8'h0F))
    (BYTE_ONE_TWO (8'h01 8'h02))
    (BYTE_TWO_ONE (8'h02 8'h01))
    (FRAME ((mode 2'b10) (flag 1)))
    (FRAME_MASK ((mode 2'b01) (flag 0)))
    (NESTED ((meta ((flag 1) (mode 2'b10))) (payload (8'hA5 8'h3C))))
  )
  (+define (D0 8'4))
  (+params
    (P0 8)
    (P_HEX 0x10)
    (P_BIN 0b1010)
    (P_LIST (8'hA5 8'h3C))
    (P_FROM_CONST C0)
    (P_FROM_ENUM mode.BUSY)
    (P_FROM_AGG BYTE_PAIR)
    (P_FROM_PARAM P0)
    (P_FROM_PARAM_FORWARD P_FORWARD_BASE)
    (P_FORWARD_BASE 8'h3C)
    (P_AGG_FROM_PARAM P_LIST)
    (P_EXPR (+ P0 1))
    (P_EXPR_AGG_LEAF (+ BYTE_PAIR[1] FRAME.flag))
    (P_EXPR_CHAIN (* P_EXPR 2))
    (P_EXPR_NESTED_AGG_LEAF (+ NESTED.meta.mode NESTED.payload[1]))
    (P_EXPR_PARAM_AGG_LEAF (+ P_LIST[0] 1))
    (P_AGG_EXPR_AND (and BYTE_PAIR BYTE_MASK))
    (P_AGG_EXPR_ADD (+ BYTE_PAIR BYTE_ONE_TWO))
    (P_AGG_EXPR_SUB (- P_AGG_EXPR_ADD BYTE_ONE_TWO))
    (P_AGG_EXPR_MUL (* BYTE_ONE_TWO BYTE_TWO_ONE))
    (P_AGG_EXPR_DIV (/ P_AGG_EXPR_ADD BYTE_ONE_TWO))
    (P_AGG_EXPR_MOD (% P_AGG_EXPR_ADD BYTE_ONE_TWO))
    (P_AGG_EXPR_OR (or FRAME FRAME_MASK))
    (P_AGG_EXPR_NOT_LIST (~ BYTE_PAIR))
    (P_AGG_EXPR_NOT_LITERAL (~ (8'h0F 8'hF0)))
    (P_AGG_EXPR_NOT_RECORD (not FRAME))
    (P_AGG_EXPR_PARAM_XOR (xor P_AGG_EXPR_AND BYTE_MASK))
    (P_AGG_EXPR_EQ_LIST (== BYTE_PAIR BYTE_PAIR))
    (P_AGG_EXPR_EQ_RECORD_FALSE (== FRAME FRAME_MASK))
    (P_AGG_EXPR_NE_LIST (!= BYTE_PAIR BYTE_MASK))
    (P_AGG_EXPR_NE_RECORD_FALSE (!= FRAME FRAME))
  )
  (+enums
    (mode
      (IDLE 0)
      (BUSY 1)
    )
  )
  (+system
    (clock clk)
    (sreset rstn)
  )
  (+size
    (A 8)
    (B 8)
    (C 8)
    (D 8)
    (E 8)
    (F 4)
    (G 8)
    (H 1)
    (I 16)
    (J 8)
    (K 8)
    (L 16)
    (W 16)
    (Z 8)
    (SEL 8)
    (FLAG 1)
    (BUSY_SEEN 1)
    (PARAM_SEEN 1)
  )
  (-dt
    (A = C0)
    (B = D0)
    (C = P0)
    (D = mode.BUSY)
    (E = P_HEX)
    (F = P_BIN)
    (G = P_FROM_CONST)
    (H = P_FROM_ENUM)
    (I = P_FROM_AGG)
    (J = P_FROM_PARAM)
    (K = P_FROM_PARAM_FORWARD)
    (L = P_AGG_FROM_PARAM)
    (W = P_LIST)
    (Z = ZERO)
    (FLAG = 1 <SEL=C0)
    (BUSY_SEEN = 1 <SEL=mode.BUSY)
    (PARAM_SEEN = 1 <SEL=P0)
  )
)
FSM

my $symbol_summary = $adapter->{signal_manager}->get_symbol_summary;
is($symbol_summary->{constants}, 9, '+constants summary count is correct');
is($symbol_summary->{defines}, 1, '+define summary count is correct');
is($symbol_summary->{params}, 31, '+params summary count is correct');
is($symbol_summary->{enums}, 1, '+enums summary count is correct');

my $elements = state_elements($fsm_module, '-dt');
is(scalar(@$elements), 17, 'symbol-contract DT has the expected number of elements');

my %assignment_by_target;
my @conditional_assignments;
for my $element (@$elements) {
    if ($element->isa('FSM::CoreAST::ConditionalBranch')) {
        push @conditional_assignments, $element;
        my $assignment = $element->branches->[0]{actions}[0];
        $assignment_by_target{extract_target_name($assignment)} = $assignment;
    } elsif ($element->isa('FSM::CoreAST::Assignment') || $element->isa('FSM::CoreAST::RegisterAssignment')) {
        $assignment_by_target{extract_target_name($element)} = $element;
    }
}

is_literal_assignment($assignment_by_target{A}, '3', 8, 'C0 constant resolves to an 8-bit literal');
is_literal_assignment($assignment_by_target{B}, '4', 8, 'D0 define resolves to an 8-bit literal');
is_parameter_ref_assignment($assignment_by_target{C}, 'P0', undef, 'P0 param remains a named parameter reference');
is_literal_assignment($assignment_by_target{D}, '1', undef, 'mode.BUSY enum member resolves to a literal');
is_parameter_ref_assignment($assignment_by_target{E}, 'P_HEX', undef, 'P_HEX param remains a named parameter reference');
is_parameter_ref_assignment($assignment_by_target{F}, 'P_BIN', undef, 'P_BIN param remains a named parameter reference');
is_parameter_ref_assignment($assignment_by_target{G}, 'P_FROM_CONST', 8, 'P_FROM_CONST param remains a named parameter reference with explicit default width');
is_parameter_ref_assignment($assignment_by_target{H}, 'P_FROM_ENUM', undef, 'P_FROM_ENUM param remains a named parameter reference');
is_parameter_ref_assignment($assignment_by_target{I}, 'P_FROM_AGG', 16, 'P_FROM_AGG param remains a named packed aggregate parameter reference');
is_parameter_ref_assignment($assignment_by_target{J}, 'P_FROM_PARAM', undef, 'P_FROM_PARAM remains a named parameter reference after resolving a sibling param default');
is_parameter_ref_assignment($assignment_by_target{K}, 'P_FROM_PARAM_FORWARD', 8, 'P_FROM_PARAM_FORWARD remains a named parameter reference after resolving a forward sibling param default');
is_parameter_ref_assignment($assignment_by_target{L}, 'P_AGG_FROM_PARAM', 16, 'P_AGG_FROM_PARAM remains a named packed aggregate parameter reference after resolving a sibling aggregate param default');
is_parameter_ref_assignment($assignment_by_target{W}, 'P_LIST', 16, 'P_LIST aggregate param remains a named packed aggregate parameter reference');
is_literal_assignment($assignment_by_target{Z}, '0', 8, 'ZERO constant resolves through const_8b0');

my $params = $fsm_module->parameters;
is($params->{P_HEX}{value_text}, "'h10", 'semantic module records canonical hex parameter text');
is($params->{P_LIST}{value_kind}, 'list', 'semantic module records aggregate parameter kind');
is($params->{P_LIST}{value_width}, 16, 'semantic module records packed aggregate parameter width');
is($params->{P_FROM_CONST}{value_width}, 8, 'semantic module preserves width from referenced constant parameter value');
is($params->{P_FROM_AGG}{value_kind}, 'list', 'semantic module records referenced aggregate parameter kind');
is($params->{P_FROM_AGG}{value_width}, 16, 'semantic module records referenced aggregate parameter width');
is($params->{P_FROM_PARAM}{value_text}, '8', 'semantic module resolves sibling scalar parameter defaults');
is($params->{P_FROM_PARAM_FORWARD}{value_text}, "8'h3C", 'semantic module resolves forward sibling scalar parameter defaults');
is($params->{P_FROM_PARAM_FORWARD}{value_width}, 8, 'semantic module preserves width from forward sibling scalar parameter defaults');
is($params->{P_AGG_FROM_PARAM}{value_kind}, 'list', 'semantic module records sibling aggregate parameter kind');
is($params->{P_AGG_FROM_PARAM}{value_width}, 16, 'semantic module records sibling aggregate parameter width');
is($params->{P_EXPR}{value_text}, '(8 + 1)', 'semantic module records direct scalar parameter expressions');
is($params->{P_EXPR}{value_kind}, 'scalar', 'direct scalar parameter expressions stay scalar parameter values');
is($params->{P_EXPR_AGG_LEAF}{value_text}, "(8'h3C + 1)", 'semantic module records direct scalar expressions using aggregate constant leaves');
is($params->{P_EXPR_CHAIN}{value_text}, '((8 + 1) * 2)', 'semantic module records chained direct scalar parameter expressions');
is($params->{P_EXPR_NESTED_AGG_LEAF}{value_text}, "(2'b10 + 8'h3C)", 'semantic module records direct scalar expressions using nested aggregate scalar leaves');
is($params->{P_EXPR_PARAM_AGG_LEAF}{value_text}, "(8'hA5 + 1)", 'semantic module records direct scalar expressions using aggregate parameter leaves');
is($params->{P_AGG_EXPR_AND}{value_text}, "16'b1010000000001100", 'semantic module records folded aggregate bitwise and expressions');
is($params->{P_AGG_EXPR_AND}{value_kind}, 'list', 'aggregate bitwise list expressions stay aggregate parameter values');
is($params->{P_AGG_EXPR_AND}{value_width}, 16, 'aggregate bitwise list expressions preserve packed width');
is($params->{P_AGG_EXPR_ADD}{value_text}, "16'b1010011000111110", 'semantic module records folded aggregate add expressions');
is($params->{P_AGG_EXPR_ADD}{value_kind}, 'list', 'aggregate add list expressions stay aggregate parameter values');
is($params->{P_AGG_EXPR_SUB}{value_text}, "16'b1010010100111100", 'semantic module records folded aggregate subtract expressions');
is($params->{P_AGG_EXPR_MUL}{value_text}, "16'b0000001000000010", 'semantic module records folded aggregate multiply expressions');
is($params->{P_AGG_EXPR_DIV}{value_text}, "16'b1010011000011111", 'semantic module records folded aggregate divide expressions');
is($params->{P_AGG_EXPR_MOD}{value_text}, "16'b0000000000000000", 'semantic module records folded aggregate modulo expressions');
is($params->{P_AGG_EXPR_OR}{value_text}, "3'b111", 'semantic module records folded aggregate bitwise record expressions');
is($params->{P_AGG_EXPR_OR}{value_kind}, 'map', 'aggregate bitwise record expressions stay aggregate parameter values');
is_deeply($params->{P_AGG_EXPR_OR}{value_type_spec}{member_order}, [qw(mode flag)], 'aggregate bitwise record expressions preserve member order');
is($params->{P_AGG_EXPR_NOT_LIST}{value_text}, "16'b0101101011000011", 'semantic module records folded aggregate unary complement list expressions');
is($params->{P_AGG_EXPR_NOT_LIST}{value_kind}, 'list', 'aggregate unary complement list expressions stay aggregate parameter values');
is($params->{P_AGG_EXPR_NOT_LITERAL}{value_text}, "16'b1111000000001111", 'semantic module records folded aggregate unary complement literal expressions');
is($params->{P_AGG_EXPR_NOT_RECORD}{value_text}, "3'b010", 'semantic module records folded aggregate unary complement record expressions');
is($params->{P_AGG_EXPR_NOT_RECORD}{value_kind}, 'map', 'aggregate unary complement record expressions stay aggregate parameter values');
is_deeply($params->{P_AGG_EXPR_NOT_RECORD}{value_type_spec}{member_order}, [qw(mode flag)], 'aggregate unary complement record expressions preserve member order');
is($params->{P_AGG_EXPR_PARAM_XOR}{value_text}, "16'b0101000000000011", 'semantic module records aggregate bitwise expressions using aggregate parameter operands');
is($params->{P_AGG_EXPR_EQ_LIST}{value_text}, "1'b1", 'semantic module records folded aggregate list equality expressions');
is($params->{P_AGG_EXPR_EQ_LIST}{value_kind}, 'scalar', 'aggregate equality expressions fold to scalar parameter values');
is($params->{P_AGG_EXPR_EQ_LIST}{value_width}, 1, 'aggregate equality expressions preserve exact scalar result width');
is($params->{P_AGG_EXPR_EQ_RECORD_FALSE}{value_text}, "1'b0", 'semantic module records folded aggregate record false equality expressions');
is($params->{P_AGG_EXPR_NE_LIST}{value_text}, "1'b1", 'semantic module records folded aggregate list inequality expressions');
is($params->{P_AGG_EXPR_NE_RECORD_FALSE}{value_text}, "1'b0", 'semantic module records folded aggregate record false inequality expressions');

my $intent_hir = FSM::IR::IntentHIRBuilder->build_from_fsm_module(
    fsm_module => $fsm_module,
);
is_deeply(
    $intent_hir->parameter_names,
    [qw(P0 P_AGG_EXPR_ADD P_AGG_EXPR_AND P_AGG_EXPR_DIV P_AGG_EXPR_EQ_LIST P_AGG_EXPR_EQ_RECORD_FALSE P_AGG_EXPR_MOD P_AGG_EXPR_MUL P_AGG_EXPR_NE_LIST P_AGG_EXPR_NE_RECORD_FALSE P_AGG_EXPR_NOT_LIST P_AGG_EXPR_NOT_LITERAL P_AGG_EXPR_NOT_RECORD P_AGG_EXPR_OR P_AGG_EXPR_PARAM_XOR P_AGG_EXPR_SUB P_AGG_FROM_PARAM P_BIN P_EXPR P_EXPR_AGG_LEAF P_EXPR_CHAIN P_EXPR_NESTED_AGG_LEAF P_EXPR_PARAM_AGG_LEAF P_FORWARD_BASE P_FROM_AGG P_FROM_CONST P_FROM_ENUM P_FROM_PARAM P_FROM_PARAM_FORWARD P_HEX P_LIST)],
    'Intent HIR exposes direct-root parameter names from semantic module metadata'
);

is(scalar(@conditional_assignments), 3, 'symbol-contract DT has the expected number of conditional assignments');

my %conditional_by_target = map {
    my $assignment = $_->branches->[0]{actions}[0];
    extract_target_name($assignment) => $_;
} @conditional_assignments;

ok($conditional_by_target{FLAG}, 'FLAG conditional assignment was captured');
ok($conditional_by_target{BUSY_SEEN}, 'BUSY_SEEN conditional assignment was captured');
ok($conditional_by_target{PARAM_SEEN}, 'PARAM_SEEN conditional assignment was captured');

assert_condition_equality(
    $conditional_by_target{FLAG}->condition,
    'SEL',
    '3',
    'condition using C0 resolves to equality against literal 3'
);
assert_condition_equality(
    $conditional_by_target{BUSY_SEEN}->condition,
    'SEL',
    '1',
    'condition using mode.BUSY resolves to equality against literal 1'
);
assert_condition_parameter_equality(
    $conditional_by_target{PARAM_SEEN}->condition,
    'SEL',
    'P0',
    'condition using P0 keeps a parameter reference'
);

my $hdl = FSM::HDL::FlattenedDT->new(debug => 0)->generate_systemverilog($fsm_module);
like($hdl, qr/module\s+symbol_contract\b/s, 'symbol-contract FSM generates HDL through the active backend');
like($hdl, qr/module\s+symbol_contract\s*#\(/s, 'direct SystemVerilog module emits a parameter block');
like($hdl, qr/parameter\s+P0\s*=\s*8\b/s, 'direct SystemVerilog module declares scalar decimal parameter');
like($hdl, qr/parameter\s+P_HEX\s*=\s*'h10\b/s, 'direct SystemVerilog module declares canonical unsized hex parameter');
like($hdl, qr/parameter\s+P_LIST\s*=\s*16'b1010010100111100\b/s, 'direct SystemVerilog module declares packed aggregate parameter');
like($hdl, qr/parameter\s+P_FROM_PARAM_FORWARD\s*=\s*8'h3C\b/s, 'direct SystemVerilog module declares forward sibling parameter default');
like($hdl, qr/parameter\s+P_AGG_FROM_PARAM\s*=\s*16'b1010010100111100\b/s, 'direct SystemVerilog module declares sibling aggregate parameter default');
like($hdl, qr/parameter\s+P_EXPR\s*=\s*\(8 \+ 1\)/s, 'direct SystemVerilog module declares scalar parameter expression default');
like($hdl, qr/parameter\s+P_EXPR_AGG_LEAF\s*=\s*\(8'h3C \+ 1\)/s, 'direct SystemVerilog module declares aggregate-leaf scalar parameter expression default');
like($hdl, qr/parameter\s+P_EXPR_CHAIN\s*=\s*\(\(8 \+ 1\) \* 2\)/s, 'direct SystemVerilog module declares chained scalar parameter expression default');
like($hdl, qr/parameter\s+P_EXPR_NESTED_AGG_LEAF\s*=\s*\(2'b10 \+ 8'h3C\)/s, 'direct SystemVerilog module declares nested aggregate-leaf scalar parameter expression default');
like($hdl, qr/parameter\s+P_EXPR_PARAM_AGG_LEAF\s*=\s*\(8'hA5 \+ 1\)/s, 'direct SystemVerilog module declares aggregate parameter-leaf scalar expression default');
like($hdl, qr/parameter\s+P_AGG_EXPR_AND\s*=\s*16'b1010000000001100\b/s, 'direct SystemVerilog module declares folded aggregate bitwise list expression default');
like($hdl, qr/parameter\s+P_AGG_EXPR_ADD\s*=\s*16'b1010011000111110\b/s, 'direct SystemVerilog module declares folded aggregate add expression default');
like($hdl, qr/parameter\s+P_AGG_EXPR_SUB\s*=\s*16'b1010010100111100\b/s, 'direct SystemVerilog module declares folded aggregate subtract expression default');
like($hdl, qr/parameter\s+P_AGG_EXPR_MUL\s*=\s*16'b0000001000000010\b/s, 'direct SystemVerilog module declares folded aggregate multiply expression default');
like($hdl, qr/parameter\s+P_AGG_EXPR_DIV\s*=\s*16'b1010011000011111\b/s, 'direct SystemVerilog module declares folded aggregate divide expression default');
like($hdl, qr/parameter\s+P_AGG_EXPR_MOD\s*=\s*16'b0000000000000000\b/s, 'direct SystemVerilog module declares folded aggregate modulo expression default');
like($hdl, qr/parameter\s+P_AGG_EXPR_OR\s*=\s*3'b111\b/s, 'direct SystemVerilog module declares folded aggregate bitwise record expression default');
like($hdl, qr/parameter\s+P_AGG_EXPR_NOT_LIST\s*=\s*16'b0101101011000011\b/s, 'direct SystemVerilog module declares folded aggregate unary complement list expression default');
like($hdl, qr/parameter\s+P_AGG_EXPR_NOT_LITERAL\s*=\s*16'b1111000000001111\b/s, 'direct SystemVerilog module declares folded aggregate unary complement literal expression default');
like($hdl, qr/parameter\s+P_AGG_EXPR_NOT_RECORD\s*=\s*3'b010\b/s, 'direct SystemVerilog module declares folded aggregate unary complement record expression default');
like($hdl, qr/parameter\s+P_AGG_EXPR_PARAM_XOR\s*=\s*16'b0101000000000011\b/s, 'direct SystemVerilog module declares folded aggregate bitwise parameter-operand expression default');
like($hdl, qr/parameter\s+P_AGG_EXPR_EQ_LIST\s*=\s*1'b1\b/s, 'direct SystemVerilog module declares folded aggregate list equality default');
like($hdl, qr/parameter\s+P_AGG_EXPR_EQ_RECORD_FALSE\s*=\s*1'b0\b/s, 'direct SystemVerilog module declares folded aggregate record false equality default');
like($hdl, qr/parameter\s+P_AGG_EXPR_NE_LIST\s*=\s*1'b1\b/s, 'direct SystemVerilog module declares folded aggregate list inequality default');
like($hdl, qr/parameter\s+P_AGG_EXPR_NE_RECORD_FALSE\s*=\s*1'b0\b/s, 'direct SystemVerilog module declares folded aggregate record false inequality default');
like($hdl, qr/\bC\s*=\s*P0\b/s, 'generated HDL keeps scalar parameter reference on RHS');
like($hdl, qr/\bW\s*=\s*P_LIST\b/s, 'generated HDL keeps aggregate parameter reference on RHS');
like($hdl, qr/\bK\s*=\s*P_FROM_PARAM_FORWARD\b/s, 'generated HDL keeps forward-derived parameter reference on RHS');
like($hdl, qr/\bL\s*=\s*P_AGG_FROM_PARAM\b/s, 'generated HDL keeps sibling aggregate-derived parameter reference on RHS');
like($hdl, qr/\bSEL\s*==\s*P0\b/s, 'generated HDL keeps scalar parameter reference in guard equality');

done_testing();

sub parse_fsm_with_adapter {
    my ($fsm_text) = @_;
    my $fsm_path = File::Spec->catfile($tempdir, "symbols_" . int(rand(1_000_000)) . ".fsm");
    write_file($fsm_path, $fsm_text);

    my $raw_ast = Lispish::multi($fsm_path);
    my $adapter = FSM::Adapter::FSMGenFull->new(debug => 0);
    my $fsm_module = $adapter->parse_fsm($raw_ast);
    return ($adapter, $fsm_module);
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

sub extract_target_name {
    my ($assignment) = @_;
    return undef unless $assignment && $assignment->can('target');
    my $target = $assignment->target;
    return undef unless $target;

    if ($target->can('signal') && $target->signal && $target->signal->can('name')) {
        return $target->signal->name;
    }

    return undef;
}

sub is_literal_assignment {
    my ($assignment, $expected_value, $expected_width, $label) = @_;
    ok($assignment, "$label assignment exists");
    return unless $assignment;

    ok($assignment->source->isa('FSM::CoreAST::Literal'), "$label source is stored as a literal");
    return unless $assignment->source->isa('FSM::CoreAST::Literal');

    is($assignment->source->value, $expected_value, "$label value matches");
    if (defined $expected_width) {
        is($assignment->source->width, $expected_width, "$label width matches");
    } else {
        ok(!defined($assignment->source->width), "$label width remains implicit");
    }
}

sub is_parameter_ref_assignment {
    my ($assignment, $expected_name, $expected_width, $label) = @_;
    ok($assignment, "$label assignment exists");
    return unless $assignment;

    ok($assignment->source->isa('FSM::CoreAST::ParameterRef'), "$label source is stored as a parameter reference");
    return unless $assignment->source->isa('FSM::CoreAST::ParameterRef');

    is($assignment->source->name, $expected_name, "$label name matches");
    if (defined $expected_width) {
        is($assignment->source->width, $expected_width, "$label width matches");
    } else {
        ok(!defined($assignment->source->width), "$label width remains implicit");
    }
}

sub assert_condition_equality {
    my ($condition, $lhs_name, $rhs_value, $label) = @_;
    ok($condition->isa('FSM::CoreAST::BinaryOp'), "$label condition is a BinaryOp");
    return unless $condition->isa('FSM::CoreAST::BinaryOp');

    is($condition->operator, '==', "$label uses equality comparison");
    ok($condition->left->isa('FSM::CoreAST::SignalRef'), "$label left operand is a signal reference");
    ok($condition->right->isa('FSM::CoreAST::Literal'), "$label right operand is a literal");
    return unless $condition->left->isa('FSM::CoreAST::SignalRef') && $condition->right->isa('FSM::CoreAST::Literal');

    is($condition->left->signal->name, $lhs_name, "$label left signal matches");
    is($condition->right->value, $rhs_value, "$label right literal matches");
}

sub assert_condition_parameter_equality {
    my ($condition, $lhs_name, $rhs_name, $label) = @_;
    ok($condition->isa('FSM::CoreAST::BinaryOp'), "$label condition is a BinaryOp");
    return unless $condition->isa('FSM::CoreAST::BinaryOp');

    is($condition->operator, '==', "$label uses equality comparison");
    ok($condition->left->isa('FSM::CoreAST::SignalRef'), "$label left operand is a signal reference");
    ok($condition->right->isa('FSM::CoreAST::ParameterRef'), "$label right operand is a parameter reference");
    return unless $condition->left->isa('FSM::CoreAST::SignalRef') && $condition->right->isa('FSM::CoreAST::ParameterRef');

    is($condition->left->signal->name, $lhs_name, "$label left signal matches");
    is($condition->right->name, $rhs_name, "$label right parameter matches");
}

sub write_file {
    my ($path, $content) = @_;
    open my $fh, '>', $path or die "Cannot open $path for write: $!";
    print {$fh} $content or die "Cannot write $path: $!";
    close $fh or die "Cannot close $path: $!";
}
