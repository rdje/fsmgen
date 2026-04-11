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
  )
  (+define (D0 8'4))
  (+params
    (P0 8)
    (P_HEX 0x10)
    (P_BIN 0b1010)
    (P_LIST (8'hA5 8'h3C))
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
    (W 16)
    (Z 8)
    (SEL 8)
    (FLAG 1)
    (BUSY_SEEN 1)
  )
  (-dt
    (A = C0)
    (B = D0)
    (C = P0)
    (D = mode.BUSY)
    (E = P_HEX)
    (F = P_BIN)
    (W = P_LIST)
    (Z = ZERO)
    (FLAG = 1 <SEL=C0)
    (BUSY_SEEN = 1 <SEL=mode.BUSY)
  )
)
FSM

my $symbol_summary = $adapter->{signal_manager}->get_symbol_summary;
is($symbol_summary->{constants}, 2, '+constants summary count is correct');
is($symbol_summary->{defines}, 1, '+define summary count is correct');
is($symbol_summary->{params}, 4, '+params summary count is correct');
is($symbol_summary->{enums}, 1, '+enums summary count is correct');

my $elements = state_elements($fsm_module, '-dt');
is(scalar(@$elements), 10, 'symbol-contract DT has the expected number of elements');

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
is_literal_assignment($assignment_by_target{C}, '8', undef, 'P0 param resolves to a scalar literal');
is_literal_assignment($assignment_by_target{D}, '1', undef, 'mode.BUSY enum member resolves to a literal');
is_literal_assignment($assignment_by_target{E}, "'h10", undef, 'P_HEX param resolves to a canonical unsized hex literal');
is_literal_assignment($assignment_by_target{F}, "'b1010", undef, 'P_BIN param resolves to a canonical unsized binary literal');
is_literal_assignment($assignment_by_target{W}, '1010010100111100', 16, 'P_LIST aggregate param resolves to one packed literal');
is_literal_assignment($assignment_by_target{Z}, '0', 8, 'ZERO constant resolves through const_8b0');

my $params = $fsm_module->parameters;
is($params->{P_HEX}{value_text}, "'h10", 'semantic module records canonical hex parameter text');
is($params->{P_LIST}{value_kind}, 'list', 'semantic module records aggregate parameter kind');
is($params->{P_LIST}{value_width}, 16, 'semantic module records packed aggregate parameter width');

my $intent_hir = FSM::IR::IntentHIRBuilder->build_from_fsm_module(
    fsm_module => $fsm_module,
);
is_deeply(
    $intent_hir->parameter_names,
    [qw(P0 P_BIN P_HEX P_LIST)],
    'Intent HIR exposes direct-root parameter names from semantic module metadata'
);

is(scalar(@conditional_assignments), 2, 'symbol-contract DT has the expected number of conditional assignments');

my %conditional_by_target = map {
    my $assignment = $_->branches->[0]{actions}[0];
    extract_target_name($assignment) => $_;
} @conditional_assignments;

ok($conditional_by_target{FLAG}, 'FLAG conditional assignment was captured');
ok($conditional_by_target{BUSY_SEEN}, 'BUSY_SEEN conditional assignment was captured');

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

my $hdl = FSM::HDL::FlattenedDT->new(debug => 0)->generate_systemverilog($fsm_module);
like($hdl, qr/module\s+symbol_contract\b/s, 'symbol-contract FSM generates HDL through the active backend');

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

sub write_file {
    my ($path, $content) = @_;
    open my $fh, '>', $path or die "Cannot open $path for write: $!";
    print {$fh} $content or die "Cannot write $path: $!";
    close $fh or die "Cannot close $path: $!";
}
