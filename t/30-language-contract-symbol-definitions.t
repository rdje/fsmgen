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
    (W = P_LIST)
    (Z = ZERO)
    (FLAG = 1 <SEL=C0)
    (BUSY_SEEN = 1 <SEL=mode.BUSY)
    (PARAM_SEEN = 1 <SEL=P0)
  )
)
FSM

my $symbol_summary = $adapter->{signal_manager}->get_symbol_summary;
is($symbol_summary->{constants}, 3, '+constants summary count is correct');
is($symbol_summary->{defines}, 1, '+define summary count is correct');
is($symbol_summary->{params}, 7, '+params summary count is correct');
is($symbol_summary->{enums}, 1, '+enums summary count is correct');

my $elements = state_elements($fsm_module, '-dt');
is(scalar(@$elements), 14, 'symbol-contract DT has the expected number of elements');

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
is_parameter_ref_assignment($assignment_by_target{W}, 'P_LIST', 16, 'P_LIST aggregate param remains a named packed aggregate parameter reference');
is_literal_assignment($assignment_by_target{Z}, '0', 8, 'ZERO constant resolves through const_8b0');

my $params = $fsm_module->parameters;
is($params->{P_HEX}{value_text}, "'h10", 'semantic module records canonical hex parameter text');
is($params->{P_LIST}{value_kind}, 'list', 'semantic module records aggregate parameter kind');
is($params->{P_LIST}{value_width}, 16, 'semantic module records packed aggregate parameter width');
is($params->{P_FROM_CONST}{value_width}, 8, 'semantic module preserves width from referenced constant parameter value');
is($params->{P_FROM_AGG}{value_kind}, 'list', 'semantic module records referenced aggregate parameter kind');
is($params->{P_FROM_AGG}{value_width}, 16, 'semantic module records referenced aggregate parameter width');

my $intent_hir = FSM::IR::IntentHIRBuilder->build_from_fsm_module(
    fsm_module => $fsm_module,
);
is_deeply(
    $intent_hir->parameter_names,
    [qw(P0 P_BIN P_FROM_AGG P_FROM_CONST P_FROM_ENUM P_HEX P_LIST)],
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
like($hdl, qr/\bC\s*=\s*P0\b/s, 'generated HDL keeps scalar parameter reference on RHS');
like($hdl, qr/\bW\s*=\s*P_LIST\b/s, 'generated HDL keeps aggregate parameter reference on RHS');
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
