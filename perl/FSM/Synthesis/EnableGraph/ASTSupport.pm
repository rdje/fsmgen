package FSM::Synthesis::EnableGraph::ASTSupport;

=head1 NAME

FSM::Synthesis::EnableGraph::ASTSupport - Own AST rendering and operator-classification support for EnableGraph

=head1 DESCRIPTION

This package owns the bounded AST rendering/classification family that used to
live inline inside C<FSM::Synthesis::EnableGraph>. It centralizes:

=over 4

=item *

AST-to-SystemVerilog rendering with operand-aware operator selection

=item *

single-bit operand classification used by logical-versus-bitwise rendering

=item *

AST operator classification for arithmetic, logical, and factorizable
expressions

=back

The broader C<EnableGraph> owner still provides shared backend context,
intermediate-signal classification, and assignment/reset helpers consumed by
this rendering/classification family.

=cut

use v5.20;
use strict;
use warnings;
use feature qw(signatures);
no warnings 'experimental::signatures';

use List::Util qw(min);
use Scalar::Util qw(blessed);

use FSM::Debug;
use FSM::Package::IntegerLiteralSupport;

=head2 new

Construct an AST-support owner bound to one live
C<FSM::HDL::FlattenedDT> context.

=cut

sub new ($class, %args) {
    my $flattened_dt = $args{flattened_dt}
      or die "[ASTSupport.pm][new()] Missing required 'flattened_dt' argument";

    return bless {
        flattened_dt => $flattened_dt,
    }, $class;
}

=head2 ast_to_systemverilog

Render one typed AST node into SystemVerilog using the current direct-backend
operator and precedence rules.

=cut

sub ast_to_systemverilog ($self, $ast) {
    return "1'b1" unless $ast && blessed($ast);

    my $sv = $self->_ast_to_systemverilog_internal($ast, undef);

    my ($package, $filename, $line, $subroutine) = caller(1);
    fsm_debug("*** AST_TO_SV_DEBUG: $sv ***", 3);
    fsm_debug("    Called from: $subroutine at line $line", 3);
    fsm_debug("    AST type: " . ref($ast), 3);

    return $sv;
}

=head2 ast_contains_factorizable_operators

Report whether one AST contains operators that qualify it for intermediate
factorization in the current backend policy.

=cut

sub ast_contains_factorizable_operators ($self, $ast) {
    return 0 unless $ast && blessed($ast);

    if ($ast->isa('FSM::AST::UnaryOp') || $ast->isa('FSM::CoreAST::UnaryOp')) {
        fsm_debug("    AST_OPERATORS: Found unary operation - FACTORIZABLE", 3);
        return 1;
    }

    if ($ast->isa('FSM::AST::BinaryOp') || $ast->isa('FSM::CoreAST::BinaryOp')) {
        if ($self->is_arithmetic_operation($ast)) {
            fsm_debug("    AST_OPERATORS: Found arithmetic operation - FACTORIZABLE", 3);
            return 1;
        }

        if ($self->is_logical_operation($ast)) {
            if ($self->should_factor_logical_operation($ast)) {
                fsm_debug("    AST_OPERATORS: Found multi-use logical operation - FACTORIZABLE", 3);
                return 1;
            } else {
                fsm_debug("    AST_OPERATORS: Found single-use logical operation - NOT factorizable", 3);
                return 0;
            }
        }

        fsm_debug("    AST_OPERATORS: Found other binary operation - FACTORIZABLE", 3);
        return 1;
    }

    if ($ast->isa('FSM::AST::Literal') || $ast->isa('FSM::CoreAST::Literal') ||
        $ast->isa('FSM::AST::SignalRef') || $ast->isa('FSM::CoreAST::SignalRef') ||
        $ast->isa('FSM::CoreAST::ParameterRef') ||
        $ast->isa('FSM::CoreAST::AggregateRef')) {
        fsm_debug("    AST_OPERATORS: Found literal/signal reference - NOT factorizable", 3);
        return 0;
    }

    if ($ast->can('left') && $self->ast_contains_factorizable_operators($ast->left)) {
        return 1;
    }
    if ($ast->can('right') && $self->ast_contains_factorizable_operators($ast->right)) {
        return 1;
    }
    if ($ast->can('operand') && $self->ast_contains_factorizable_operators($ast->operand)) {
        return 1;
    }

    return 0;
}

=head2 is_arithmetic_operation

Report whether one AST node is an arithmetic binary operation.

=cut

sub is_arithmetic_operation ($self, $ast) {
    return 0 unless $ast && blessed($ast);
    return 0 unless $ast->isa('FSM::AST::BinaryOp') || $ast->isa('FSM::CoreAST::BinaryOp');
    return 0 unless $ast->can('operator');

    my $op = $ast->operator || '';
    return $op =~ /^[\+\-\*\/\%\<<\>>]$/;
}

=head2 is_logical_operation

Report whether one AST node is a logical binary operation.

=cut

sub is_logical_operation ($self, $ast) {
    return 0 unless $ast && blessed($ast);
    return 0 unless $ast->isa('FSM::AST::BinaryOp') || $ast->isa('FSM::CoreAST::BinaryOp');
    return 0 unless $ast->can('operator');

    my $op = $ast->operator || '';
    return $op =~ /^(&&|\|\||&|\|)$/;
}

=head2 should_factor_logical_operation

Apply the current backend policy for whether one logical operation should be
factorized.

=cut

sub should_factor_logical_operation ($self, $ast) {
    return 0 unless $self->is_logical_operation($ast);
    return $self->{flattened_dt}->{enable_graph_factorization_policy_support}->contains_frequently_used_operations($ast);
}

=head2 _ast_to_systemverilog_internal

Internal recursive renderer for C<ast_to_systemverilog>.

=cut

sub _ast_to_systemverilog_internal ($self, $ast, $parent_precedence) {
    my $ctx = $self->{flattened_dt};

    return "0" unless $ast && blessed($ast);

    if ($ast->isa('FSM::AST::SignalRef') || $ast->isa('FSM::CoreAST::SignalRef')) {
        return $self->_render_signal_ref($ast);

    } elsif ($ast->isa('FSM::CoreAST::ParameterRef')) {
        return $ast->to_systemverilog();

    } elsif ($ast->isa('FSM::CoreAST::AggregateRef')) {
        return $ast->to_systemverilog();

    } elsif ($ast->isa('FSM::AST::Literal') || $ast->isa('FSM::CoreAST::Literal')) {
        my $normalized = FSM::Package::IntegerLiteralSupport->systemverilog_literal_from_literal_like($ast);
        return $normalized if defined $normalized;
        return $ast->value || "0";

    } elsif ($ast->isa('FSM::AST::BinaryOp') || $ast->isa('FSM::CoreAST::BinaryOp') || $ast->isa('FSM::HDL::SubstitutedBinaryOp')) {
        return $self->_render_binary_op($ast, $parent_precedence);

    } elsif ($ast->isa('FSM::AST::UnaryOp') || $ast->isa('FSM::CoreAST::UnaryOp') || $ast->isa('FSM::HDL::SubstitutedUnaryOp')) {
        return $self->_render_unary_op($ast);

    } elsif ($ast->isa('FSM::HDL::IntermediateSignalRef')) {
        return $ast->signal_name || "unknown_intermediate_signal";

    } else {
        my $node_type = ref($ast) || 'UNKNOWN';

        if ($ast->can('to_systemverilog')) {
            my $sv_result = eval { $ast->to_systemverilog() };
            if ($sv_result && $sv_result !~ /^unknown_expr_/) {
                fsm_debug("AST_TO_CLEAN_SV: Using to_systemverilog() method for '$node_type': $sv_result", 3);
                return $sv_result;
            } else {
                fsm_debug("AST_TO_CLEAN_SV: to_systemverilog() failed for '$node_type', using fallback", 3);
            }
        } else {
            fsm_debug("AST_TO_CLEAN_SV: No to_systemverilog() method for '$node_type'", 3);
        }

        if ($node_type =~ /BinaryOp$/) {
            return $self->_render_binary_op($ast, $parent_precedence);
        } elsif ($node_type =~ /UnaryOp$/) {
            return $self->_render_unary_op($ast);
        } elsif ($node_type =~ /SignalRef$/) {
            return $self->_render_signal_ref($ast);
        } elsif ($node_type =~ /Literal$/) {
            my $value = eval { $ast->value } || "0";
            my $normalized = FSM::Package::IntegerLiteralSupport->systemverilog_literal_from_literal_like($ast);
            return $normalized if defined $normalized;
            return $value;
        }

        fsm_debug("AST_TO_CLEAN_SV: Unknown AST node type '$node_type' - using safe fallback", 3);
        return "unknown_expr_" . lc($node_type =~ s/.*:://r);
    }
}

sub _render_signal_ref ($self, $ast) {
    my $ctx = $self->{flattened_dt};

    if ($ast->isa('FSM::CoreAST::SignalRef') && $ast->can('to_systemverilog')) {
        my $sv_result = eval { $ast->to_systemverilog() };
        return $sv_result if defined($sv_result) && $sv_result ne '';
    }

    my $name = $ctx->{enable_graph_capture_support}->extract_signal_name_from_ast($ast);
    return $name || "unknown_signal";
}

=head2 _render_binary_op

Internal binary-operator renderer with precedence and logical/bitwise
selection rules.

=cut

sub _render_binary_op ($self, $ast, $parent_precedence) {
    my $operator = eval { $ast->operator } || 'unknown';
    my $left = $ast->left;
    my $right = $ast->right;

    my $truthiness_render = $self->_render_truthiness_comparison($operator, $left, $right);
    return $truthiness_render if defined $truthiness_render;

    my $my_precedence = $self->_get_operator_precedence($operator);
    my $left_sv = $self->_ast_to_systemverilog_internal($left, $my_precedence);
    my $right_sv = $self->_ast_to_systemverilog_internal($right, $my_precedence);
    my $op_symbol = $self->_choose_operator_symbol($operator, $left, $right);

    if (($op_symbol eq '|' || $op_symbol eq '&')
        && $self->_bitwise_child_needs_grouping($left))
    {
        $left_sv = "($left_sv)";
    }

    if (($op_symbol eq '|' || $op_symbol eq '&')
        && $self->_bitwise_child_needs_grouping($right))
    {
        $right_sv = "($right_sv)";
    }

    if ($self->_right_child_needs_same_precedence_parentheses($operator, $right)) {
        $right_sv = "($right_sv)";
    }

    fsm_debug("*** OPERATOR_CHOICE_DEBUG: ***", 3);
    fsm_debug("  Original operator: '$operator'", 3);
    fsm_debug("  Chosen symbol: '$op_symbol'", 3);
    fsm_debug("  Left operand: '$left_sv' (AST type: " . (blessed($left) ? ref($left) : 'UNBLESSED') . ")", 3);
    fsm_debug("  Right operand: '$right_sv' (AST type: " . (blessed($right) ? ref($right) : 'UNBLESSED') . ")", 3);
    fsm_debug("  Left is 1-bit: " . ($self->_operand_is_single_bit($left) ? 'YES' : 'NO'), 3);
    fsm_debug("  Right is 1-bit: " . ($self->_operand_is_single_bit($right) ? 'YES' : 'NO'), 3);

    my $expr = "$left_sv $op_symbol $right_sv";

    fsm_debug("  Final expression: '$expr'", 3);
    fsm_debug("*** END OPERATOR_CHOICE_DEBUG ***", 3);

    return "($expr)" if $self->_needs_parentheses($my_precedence, $parent_precedence);
    return $expr;
}

sub _render_truthiness_comparison ($self, $operator, $left, $right) {
    return undef unless $operator eq '==' || $operator eq '!=';

    my ($signalish_operand, $literal_operand) = $self->_extract_truthiness_operands($left, $right);
    return undef unless $signalish_operand && $literal_operand;

    my $literal_value = $self->_literal_numeric_value($literal_operand);
    return undef unless defined $literal_value;

    my $operand_sv = $self->_ast_to_systemverilog_internal($signalish_operand, 10);

    if ($literal_value == 0) {
        return $operator eq '!='
            ? $self->_render_truthiness_value($signalish_operand, $operand_sv)
            : $self->_render_truthiness_negation($signalish_operand, $operand_sv);
    }

    if ($literal_value == 1 && $self->_operand_is_single_bit($signalish_operand)) {
        return $operator eq '=='
            ? $operand_sv
            : $self->_render_truthiness_negation($signalish_operand, $operand_sv);
    }

    return undef;
}

sub _render_truthiness_value ($self, $operand, $operand_sv) {
    return $operand_sv if $self->_operand_is_single_bit($operand);
    return "(|$operand_sv)";
}

sub _extract_truthiness_operands ($self, $left, $right) {
    if ($self->_is_truthiness_signal_operand($left) && $self->_is_literal_operand($right)) {
        return ($left, $right);
    }
    if ($self->_is_truthiness_signal_operand($right) && $self->_is_literal_operand($left)) {
        return ($right, $left);
    }
    return;
}

sub _is_truthiness_signal_operand ($self, $ast) {
    return 0 unless $ast && blessed($ast);
    return 1 if $ast->isa('FSM::AST::SignalRef') || $ast->isa('FSM::CoreAST::SignalRef');
    return 1 if $ast->isa('FSM::AST::IndexedRef') || $ast->isa('FSM::CoreAST::IndexedRef');
    return 1 if $ast->isa('FSM::CoreAST::AggregateRef');
    return 1 if $ast->isa('FSM::CoreAST::ParameterRef');
    return 1 if $ast->isa('FSM::HDL::IntermediateSignalRef');
    return 0;
}

sub _is_literal_operand ($self, $ast) {
    return 0 unless $ast && blessed($ast);
    return 1 if $ast->isa('FSM::AST::Literal') || $ast->isa('FSM::CoreAST::Literal');
    return 0;
}

sub _literal_numeric_value ($self, $literal) {
    return undef unless $self->_is_literal_operand($literal);

    my $text = eval { $literal->to_systemverilog() };
    $text = eval { $literal->value } unless defined $text && $text ne '';
    return undef unless defined $text;

    $text =~ s/\s+//g;
    $text =~ s/_//g;

    my $integer_value = FSM::Package::IntegerLiteralSupport->integer_from_scalar($text);
    return 0 + $integer_value->bstr if defined $integer_value;

    if ($text =~ /\A(\d+)'([bdhxBDHX])([0-9a-fA-FxXzZ]+)\z/) {
        my ($width, $radix_char, $digits) = ($1, lc($2), $3);
        return undef if $digits =~ /[xXzZ]/;
        return oct("0b$digits") if $radix_char eq 'b';
        return 0 + $digits if $radix_char eq 'd';
        return hex($digits) if $radix_char eq 'h' || $radix_char eq 'x';
    }

    return 0 + $text if $text =~ /\A\d+\z/;
    return undef;
}

sub _render_truthiness_negation ($self, $operand, $operand_sv) {
    return "(~|$operand_sv)" unless $self->_operand_is_single_bit($operand);

    return $self->_operand_needs_parens_for_negation($operand)
        ? "!($operand_sv)"
        : "!$operand_sv";
}

=head2 _get_operator_precedence

Internal SystemVerilog precedence lookup for binary operators.

=cut

sub _get_operator_precedence ($self, $operator) {
    my %precedence = (
        '||' => 1, '|'  => 2,
        '&&' => 3, '&'  => 4,
        '==' => 5, '!=' => 5, '<' => 5, '>' => 5, '<=' => 5, '>=' => 5,
        '+'  => 6, '-'  => 6,
        '*'  => 7, '/'  => 7, '%' => 7,
        '<<' => 8, '>>' => 8,
        '^'  => 9,
    );
    return $precedence{$operator} || 5;
}

=head2 _choose_operator_symbol

Internal selector for logical-versus-bitwise operator emission.

=cut

sub _choose_operator_symbol ($self, $operator, $left, $right) {
    my $ctx = $self->{flattened_dt};
    my $left_name = undef;
    my $right_name = undef;
    my $left_width = undef;
    my $right_width = undef;

    fsm_debug("_choose_operator_symbol: Entering with operator '$operator'", 3);

    if ($left && blessed($left)) {
        $left_name = $ctx->{enable_graph_capture_support}->extract_signal_name_from_ast($left);
        if ($left_name) {
            fsm_debug("_choose_operator_symbol: Extracted left signal name: '$left_name'", 3);
            if ($ctx->{fsm_module} && $ctx->{fsm_module}->signals) {
                fsm_debug("_choose_operator_symbol: FSM module has " . scalar(keys %{$ctx->{fsm_module}->signals}) . " signals", 3);
                if ($ctx->{fsm_module}->signals->{$left_name}) {
                    my $sig = $ctx->{fsm_module}->signals->{$left_name};
                    fsm_debug("_choose_operator_symbol: Found left signal '$left_name' in FSM signals", 3);
                    fsm_debug("_choose_operator_symbol: Left signal object type: " . ref($sig), 3);
                    if ($sig->can('width')) {
                        $left_width = $sig->width;
                        fsm_debug("_choose_operator_symbol: Left signal width from method: " . (defined $left_width ? $left_width : 'undef'), 3);
                    } else {
                        fsm_debug("_choose_operator_symbol: Left signal has no width() method", 3);
                    }
                } else {
                    fsm_debug("_choose_operator_symbol: Left signal '$left_name' NOT found in FSM signals", 3);
                    my @available = keys %{$ctx->{fsm_module}->signals};
                    my @first_10 = sort @available[0 .. min(9, $#available)];
                    fsm_debug("_choose_operator_symbol: Available signals: " . join(", ", @first_10), 3);
                }
            } else {
                fsm_debug("_choose_operator_symbol: No FSM module or signals available", 3);
            }
        }
    }

    if ($right && blessed($right)) {
        $right_name = $ctx->{enable_graph_capture_support}->extract_signal_name_from_ast($right);
        if ($right_name) {
            fsm_debug("_choose_operator_symbol: Extracted right signal name: '$right_name'", 3);
            if ($ctx->{fsm_module} && $ctx->{fsm_module}->signals) {
                if ($ctx->{fsm_module}->signals->{$right_name}) {
                    my $sig = $ctx->{fsm_module}->signals->{$right_name};
                    fsm_debug("_choose_operator_symbol: Found right signal '$right_name' in FSM signals", 3);
                    fsm_debug("_choose_operator_symbol: Right signal object type: " . ref($sig), 3);
                    if ($sig->can('width')) {
                        $right_width = $sig->width;
                        fsm_debug("_choose_operator_symbol: Right signal width from method: " . (defined $right_width ? $right_width : 'undef'), 3);
                    } else {
                        fsm_debug("_choose_operator_symbol: Right signal has no width() method", 3);
                    }
                } else {
                    fsm_debug("_choose_operator_symbol: Right signal '$right_name' NOT found in FSM signals", 3);
                }
            } else {
                fsm_debug("_choose_operator_symbol: No FSM module or signals available", 3);
            }
        }
    }

    fsm_debug("_choose_operator_symbol: Left operand name: " . ($left_name // 'undef') . ", width: " . (defined $left_width ? $left_width : 'undef'), 3);
    fsm_debug("_choose_operator_symbol: Right operand name: " . ($right_name // 'undef') . ", width: " . (defined $right_width ? $right_width : 'undef'), 3);

    if ($operator eq '&&') {
        if ($self->_operand_is_single_bit($left) && $self->_operand_is_single_bit($right)) {
            fsm_debug("_choose_operator_symbol: Both operands single-bit, using '&'", 3);
            return '&';
        } else {
            fsm_debug("_choose_operator_symbol: Operands not both single-bit, using '&&'", 3);
            return '&&';
        }
    } elsif ($operator eq '||') {
        if ($self->_operand_is_single_bit($left) && $self->_operand_is_single_bit($right)) {
            fsm_debug("_choose_operator_symbol: Both operands single-bit, using '|'", 3);
            return '|';
        } else {
            fsm_debug("_choose_operator_symbol: Operands not both single-bit, using '||'", 3);
            return '||';
        }
    } else {
        fsm_debug("_choose_operator_symbol: Using standard operator mapping for '$operator'", 3);
        return $self->_map_binary_operator($operator);
    }
}

=head2 _needs_parentheses

Internal precedence helper for binary rendering.

=cut

sub _needs_parentheses ($self, $my_precedence, $parent_precedence) {
    return 0 unless defined $parent_precedence;
    return $my_precedence < $parent_precedence;
}

sub _bitwise_child_needs_grouping ($self, $child) {
    return 0 unless $child && blessed($child);
    return 0 unless $child->can('operator');

    my $operator = $child->operator || '';
    return 0 if defined $self->_render_truthiness_comparison(
        $operator,
        $child->can('left') ? $child->left : undef,
        $child->can('right') ? $child->right : undef,
    );
    return $operator =~ /^(?:==|!=|<|>|<=|>=|&&|\|\|)$/ ? 1 : 0;
}

sub _right_child_needs_same_precedence_parentheses ($self, $parent_operator, $right_child) {
    return 0 unless $right_child && blessed($right_child);
    return 0 unless $right_child->isa('FSM::AST::BinaryOp')
        || $right_child->isa('FSM::CoreAST::BinaryOp')
        || $right_child->isa('FSM::HDL::SubstitutedBinaryOp');

    my $child_operator = eval { $right_child->operator } || '';
    return 0 unless $child_operator ne '';

    my $parent_precedence = $self->_get_operator_precedence($parent_operator);
    my $child_precedence = $self->_get_operator_precedence($child_operator);
    return 0 unless $parent_precedence == $child_precedence;

    my $parent_symbol = $self->_map_binary_operator($parent_operator);
    my $child_symbol = $self->_map_binary_operator($child_operator);
    return 0 if $parent_symbol eq $child_symbol
        && $parent_symbol =~ /^(?:\+|\*|&|\||\^|&&|\|\|)$/;

    return 1;
}

=head2 _map_binary_operator

Internal mapper from normalized operator names to emitted binary symbols.

=cut

sub _map_binary_operator ($self, $operator) {
    my %op_map = (
        'eq' => '==', 'ne' => '!=', 'lt' => '<', 'gt' => '>', 'le' => '<=', 'ge' => '>=',
        'add' => '+', 'sub' => '-', 'mul' => '*', 'div' => '/', 'mod' => '%',
        'and' => '&', 'or' => '|', 'xor' => '^',
        'shl' => '<<', 'shr' => '>>', 'sal' => '<<<', 'sar' => '>>>',
    );
    return $op_map{$operator} || $operator;
}

=head2 _signal_is_single_bit

Internal single-bit signal classifier for emitted operator selection.

=cut

sub _signal_is_single_bit ($self, $name) {
    my $ctx = $self->{flattened_dt};

    fsm_debug("    SIGNAL_IS_1BIT: Checking if signal '$name' is single-bit", 3);

    unless (defined $name) {
        fsm_debug("      RESULT: NOT single-bit (undefined name)", 3);
        return 0;
    }

    if ($ctx->{fsm_module} && $ctx->{fsm_module}->signals && $ctx->{fsm_module}->signals->{$name}) {
        fsm_debug("      PATH: Found signal in FSM module", 3);
        my $signal = $ctx->{fsm_module}->signals->{$name};
        fsm_debug("      Signal object type: " . ref($signal), 3);

        if ($signal->can('width')) {
            my $width = $signal->width;
            fsm_debug("      FSM module signal width: " . (defined($width) ? $width : 'UNDEFINED'), 3);
            my $result = (!$width || $width == 1) ? 1 : 0;
            fsm_debug("      RESULT: " . ($result ? 'single-bit' : 'multi-bit') . " (from FSM module)", 3);
            return $result;
        } else {
            fsm_debug("      Signal has no width() method", 3);
        }
    } else {
        fsm_debug("      PATH: Signal not found in FSM module (using heuristics)", 3);
        if (!$ctx->{fsm_module}) {
            fsm_debug("        Reason: No FSM module available", 3);
        } elsif (!$ctx->{fsm_module}->signals) {
            fsm_debug("        Reason: FSM module has no signals", 3);
        } else {
            fsm_debug("        Reason: Signal '$name' not in FSM module signals", 3);
            my @available = keys %{$ctx->{fsm_module}->signals};
            my $count = scalar(@available);
            fsm_debug("        Available signals ($count): " . join(", ", sort @available), 3);
        }
    }

    if ($ctx->{enable_graph_signal_support}->is_intermediate_signal($name)) {
        fsm_debug("      PATH: Intermediate signal (assuming 1-bit)", 3);
        fsm_debug("      RESULT: single-bit (intermediate signals are boolean)", 3);
        return 1;
    }

    if ($name =~ /_(?:en|wen)$/) {
        fsm_debug("      PATH: Generated enable/write-enable signal", 3);
        fsm_debug("      RESULT: single-bit (enable families are boolean)", 3);
        return 1;
    }

    if ($name =~ /^current_state$/) {
        fsm_debug("      PATH: State comparison signal", 3);
        fsm_debug("      RESULT: single-bit (state comparison)", 3);
        return 1;
    }

    fsm_debug("      PATH: Default fallback", 3);
    fsm_debug("      RESULT: multi-bit (conservative default)", 3);
    return 0;
}

sub _core_signal_ref_slice_width ($self, $ast) {
    return undef unless $ast && blessed($ast);
    return undef unless $ast->isa('FSM::CoreAST::SignalRef');
    return undef unless $ast->can('slice');

    my $slice = eval { $ast->slice };
    return undef unless ref($slice) eq 'ARRAY' && @$slice == 2;

    my ($high, $low) = @$slice;
    return undef unless defined($high) && defined($low);
    return undef if ref($high) || ref($low);
    return undef unless $high =~ /\A-?\d+\z/ && $low =~ /\A-?\d+\z/;

    return abs($high - $low) + 1;
}

=head2 _operand_is_single_bit

Internal single-bit AST classifier for emitted operator selection.

=cut

sub _operand_is_single_bit ($self, $ast) {
    my $ctx = $self->{flattened_dt};

    fsm_debug("    OPERAND_BIT_CHECK: Checking if operand is single-bit", 3);
    fsm_debug("      AST defined: " . (defined($ast) ? 'YES' : 'NO'), 3);
    fsm_debug("      AST blessed: " . (blessed($ast) ? 'YES' : 'NO'), 3);

    unless ($ast && blessed($ast)) {
        fsm_debug("      RESULT: NOT single-bit (undefined or not blessed)", 3);
        return 0;
    }

    fsm_debug("      AST type: " . ref($ast), 3);

    if ($ast->isa('FSM::CoreAST::SignalRef')) {
        my $slice_width = $self->_core_signal_ref_slice_width($ast);
        if (defined $slice_width) {
            my $result = $slice_width == 1 ? 1 : 0;
            fsm_debug("      PATH: CoreAST SignalRef slice width $slice_width", 3);
            fsm_debug("      RESULT: " . ($result ? 'single-bit' : 'multi-bit') . " (from slice width)", 3);
            return $result;
        }

        fsm_debug("      PATH: Regular SignalRef", 3);
        my $name = $ctx->{enable_graph_capture_support}->extract_signal_name_from_ast($ast);
        fsm_debug("      Signal name: '" . ($name || 'UNDEFINED') . "'", 3);
        my $result = $self->_signal_is_single_bit($name);
        fsm_debug("      RESULT: " . ($result ? 'single-bit' : 'multi-bit') . " (via _signal_is_single_bit)", 3);
        return $result;

    } elsif ($ast->isa('FSM::AST::SignalRef')) {
        fsm_debug("      PATH: Regular SignalRef", 3);
        my $name = $ctx->{enable_graph_capture_support}->extract_signal_name_from_ast($ast);
        fsm_debug("      Signal name: '" . ($name || 'UNDEFINED') . "'", 3);
        my $result = $self->_signal_is_single_bit($name);
        fsm_debug("      RESULT: " . ($result ? 'single-bit' : 'multi-bit') . " (via _signal_is_single_bit)", 3);
        return $result;

    } elsif ($ast->isa('FSM::AST::Literal') || $ast->isa('FSM::CoreAST::Literal')) {
        fsm_debug("      PATH: Literal", 3);
        my $value = eval { $ast->value } || '';
        fsm_debug("      Literal value: '$value'", 3);
        if ($value =~ /^1'b[01]$/ || $value =~ /^[01]$/) {
            fsm_debug("      RESULT: single-bit (1-bit literal)", 3);
            return 1;
        } else {
            fsm_debug("      RESULT: multi-bit (multi-bit literal)", 3);
            return 0;
        }

    } elsif ($ast->isa('FSM::AST::IndexedRef') || $ast->isa('FSM::CoreAST::IndexedRef')) {
        fsm_debug("      PATH: IndexedRef", 3);
        fsm_debug("      RESULT: single-bit (bit indexing)", 3);
        return 1;

    } elsif ($ast->isa('FSM::CoreAST::AggregateRef')) {
        fsm_debug("      PATH: AggregateRef", 3);
        my $width = eval { $ast->width };
        my $result = defined($width) && $width == 1 ? 1 : 0;
        fsm_debug("      RESULT: " . ($result ? 'single-bit' : 'multi-bit') . " (aggregate path width)", 3);
        return $result;

    } elsif ($ast->isa('FSM::CoreAST::ParameterRef')) {
        fsm_debug("      PATH: ParameterRef", 3);
        my $width = eval { $ast->width };
        my $result = defined($width) && $width == 1 ? 1 : 0;
        fsm_debug("      RESULT: " . ($result ? 'single-bit' : 'multi-bit') . " (parameter width)", 3);
        return $result;

    } elsif ($ast->isa('FSM::AST::BinaryOp') || $ast->isa('FSM::CoreAST::BinaryOp') || $ast->isa('FSM::HDL::SubstitutedBinaryOp')) {
        fsm_debug("      PATH: BinaryOp", 3);
        my $op = eval { $ast->operator } || '';
        fsm_debug("      Binary operator: '$op'", 3);
        if ($op =~ /^(==|!=|<|>|<=|>=)$/) {
            fsm_debug("      RESULT: single-bit (comparison operator)", 3);
            return 1;
        }
        if ($op =~ /^(&&|\|\||&|\|)$/) {
            fsm_debug("      Checking logical operator operands recursively...", 3);
            my $left_result = $self->_operand_is_single_bit($ast->left);
            my $right_result = $self->_operand_is_single_bit($ast->right);
            my $result = $left_result && $right_result;
            fsm_debug("      Left operand 1-bit: $left_result, Right operand 1-bit: $right_result", 3);
            fsm_debug("      RESULT: " . ($result ? 'single-bit' : 'multi-bit') . " (logical op on 1-bit inputs)", 3);
            return $result;
        }
        fsm_debug("      RESULT: multi-bit (other binary operator)", 3);
        return 0;

    } elsif ($ast->isa('FSM::AST::UnaryOp') || $ast->isa('FSM::CoreAST::UnaryOp') || $ast->isa('FSM::HDL::SubstitutedUnaryOp')) {
        fsm_debug("      PATH: UnaryOp", 3);
        my $op = eval { $ast->operator } || '';
        fsm_debug("      Unary operator: '$op'", 3);
        if ($op eq 'not' || $op eq '!') {
            fsm_debug("      RESULT: single-bit (logical NOT)", 3);
            return 1;
        } else {
            fsm_debug("      RESULT: multi-bit (other unary operator)", 3);
            return 0;
        }

    } elsif ($ast->isa('FSM::HDL::IntermediateSignalRef')) {
        fsm_debug("      PATH: IntermediateSignalRef", 3);
        my $signal_name = eval { $ast->signal_name } || 'UNKNOWN';
        fsm_debug("      Intermediate signal name: '$signal_name'", 3);
        fsm_debug("      RESULT: single-bit (intermediate signals are always boolean)", 3);
        return 1;
    } else {
        fsm_debug("      PATH: Unknown AST type - " . ref($ast), 3);
        fsm_debug("      RESULT: multi-bit (unknown type fallback)", 3);
    }

    fsm_debug("      RESULT: multi-bit (default fallback)", 3);
    return 0;
}

=head2 _render_unary_op

Internal unary-operator renderer.

=cut

sub _render_unary_op ($self, $ast) {
    my $operator = eval { $ast->operator } || 'not';
    my $operand = $ast->operand;
    my $operand_sv = $self->_ast_to_systemverilog_internal($operand, 10);
    my $op_symbol = $self->_map_unary_operator($operator);

    if ($operator eq 'not' || $operator eq '!') {
        return "(~|$operand_sv)" unless $self->_operand_is_single_bit($operand);

        if ($self->_operand_needs_parens_for_negation($operand)) {
            return "!($operand_sv)";
        } else {
            return "!$operand_sv";
        }
    } else {
        return "$op_symbol($operand_sv)";
    }
}

=head2 _map_unary_operator

Internal mapper from normalized unary operator names to emitted symbols.

=cut

sub _map_unary_operator ($self, $operator) {
    my %op_map = ( 'not' => '!', 'neg' => '-', 'pos' => '+' );
    return $op_map{$operator} || $operator;
}

=head2 _operand_needs_parens_for_negation

Internal negation-parenthesis helper.

=cut

sub _operand_needs_parens_for_negation ($self, $operand) {
    return 0 unless $operand && blessed($operand);
    return 0 if $operand->isa('FSM::AST::SignalRef') || $operand->isa('FSM::CoreAST::SignalRef');
    return 0 if $operand->isa('FSM::AST::Literal') || $operand->isa('FSM::CoreAST::Literal');
    return 0 if $operand->isa('FSM::AST::IndexedRef') || $operand->isa('FSM::CoreAST::IndexedRef');
    return 0 if $operand->isa('FSM::CoreAST::AggregateRef');
    return 0 if $operand->isa('FSM::CoreAST::ParameterRef');
    if ($operand->isa('FSM::AST::BinaryOp') || $operand->isa('FSM::CoreAST::BinaryOp') || $operand->isa('FSM::HDL::SubstitutedBinaryOp')) {
        my $operator = eval { $operand->operator } || '';
        return 0 if defined $self->_render_truthiness_comparison($operator, $operand->left, $operand->right);
    }
    return 1;
}

1;
