package FSM::Synthesis::EnableGraph::CaptureSupport;

=head1 NAME

FSM::Synthesis::EnableGraph::CaptureSupport - Own AST capture, condition conversion, and signal-name extraction support for EnableGraph

=head1 DESCRIPTION

This package owns the bounded AST capture/conversion family that used to live
inline inside C<FSM::Synthesis::EnableGraph>. It centralizes:

=over 4

=item *

condition-stack normalization into AST enable expressions

=item *

assignment and state-transition capture into the prepared LHS assignment
registry

=item *

condition/test selector conversion into typed AST nodes

=item *

signal-name and RHS extraction from typed AST nodes used by capture-time logic

=back

The broader C<EnableGraph> owner still provides shared backend context,
intermediate-signal classification, and AST rendering helpers consumed by this
support family.

=cut

use v5.20;
use strict;
use warnings;
use feature qw(signatures);
no warnings 'experimental::signatures';

use Carp qw(confess);
use Scalar::Util qw(blessed);

use FSM::AST::Node;
use FSM::Debug;
use FSM::Package::AggregatePathSupport;

=head2 new

Construct a capture-support owner bound to one live
C<FSM::HDL::FlattenedDT> context.

=cut

sub new ($class, %args) {
    my $flattened_dt = $args{flattened_dt}
      or die "[CaptureSupport.pm][new()] Missing required 'flattened_dt' argument";

    return bless {
        flattened_dt => $flattened_dt,
    }, $class;
}

=head2 create_condition_expression

Normalize one condition stack into a single AST expression suitable for
capture-time enable tracking.

=cut

sub create_condition_expression ($self, $condition_stack) {
    return FSM::AST::Utils::literal("1'b1") if !@$condition_stack;

    return $condition_stack->[0] if @$condition_stack == 1;
    return FSM::AST::Utils::and_tree(@$condition_stack);
}

=head2 register_assignment_capture

Append one captured assignment into the prepared LHS-assignment registry.

=cut

sub register_assignment_capture ($self, %args) {
    my $ctx = $self->{flattened_dt};
    my $lhs_ast = $args{lhs_ast};
    my $lhs_name_key = $args{lhs_name_key};

    if (!defined($lhs_name_key) || $lhs_name_key eq '') {
        $lhs_name_key = $self->extract_signal_name_from_ast($lhs_ast) // 'unknown_lhs';
    }

    push @{$ctx->{lhs_assignments}->{$lhs_name_key}}, {
        dt => $args{dt},
        lhs_ast => $lhs_ast,
        conditions_ast => $args{conditions_ast},
        rhs => $args{rhs},
        operator => $args{operator},
        assignment_intent => $args{assignment_intent} || {},
        source_provenance => $args{source_provenance} || {},
        output_exposure => $args{output_exposure} // 'auto',
        is_state_trans => 0,
    };

    $ctx->{all_lhs}->{$lhs_name_key} = 1;
    $ctx->{lhs_ast_map}->{$lhs_name_key} = $lhs_ast if blessed($lhs_ast);

    return $lhs_name_key;
}

=head2 register_transition_capture

Append one captured state transition as a normalized C<next_state> assignment.

=cut

sub register_transition_capture ($self, %args) {
    my $ctx = $self->{flattened_dt};
    my $target_state = $args{target_state};
    my $state_value = uc($target_state);

    push @{$ctx->{lhs_assignments}->{next_state}}, {
        dt => $args{dt},
        conditions_ast => $args{conditions_ast},
        rhs => $state_value,
        operator => '<-',
        assignment_intent => {
            operator_symbol => '<-',
            sequencing => 'clocked',
            register_style => 'output_named',
            assignment_family => 'state_transition',
        },
        source_provenance => {
            origin => 'state_transition',
            raw_target_state => $target_state,
        },
        output_exposure => 'auto',
        is_state_trans => 1,
    };

    $ctx->{all_lhs}->{next_state} = 1;
    $ctx->{lhs_ast_map}->{next_state} //= FSM::AST::Utils::signal_ref('next_state');

    return $state_value;
}

=head2 extract_assignment_capture_metadata

Normalize assignment-intent/operator metadata from one assignment node for
capture-time storage.

=cut

sub extract_assignment_capture_metadata ($self, $assignment_node) {
    my $assignment_intent = {};
    if ($assignment_node && $assignment_node->can('assignment_intent')) {
        my $intent = $assignment_node->assignment_intent;
        $assignment_intent = { %$intent } if ref($intent) eq 'HASH';
    }

    my $operator = ($assignment_node && $assignment_node->can('operator_symbol'))
        ? $assignment_node->operator_symbol
        : undef;
    if ((!defined($operator) || $operator eq '') && ref($assignment_intent) eq 'HASH') {
        $operator = $assignment_intent->{operator_symbol};
    }

    if (($assignment_node->isa('FSM::CoreAST::PulseAssignment') || $assignment_node->can('pulse_cycles'))
            && (!defined($operator) || $operator eq '' || $operator eq '=')
            && $assignment_node->can('pulse_cycles')) {
        my $cycles = eval { $assignment_node->pulse_cycles };
        $operator = '<' . $cycles if defined $cycles && $cycles =~ /^\d+$/;
    }

    if (!defined($operator) || $operator !~ /^(?:<-|<=|=|<-=|<=\+|<[0-9]+)$/) {
        my $node_type = ref($assignment_node) || 'UNKNOWN';
        my $intent_operator = (ref($assignment_intent) eq 'HASH') ? ($assignment_intent->{operator_symbol} // 'UNDEF') : 'NO_INTENT';
        my $pulse_cycles = $assignment_node->can('pulse_cycles') ? (eval { $assignment_node->pulse_cycles } // 'UNDEF') : 'N/A';
        die "[CaptureSupport.pm][extract_assignment_capture_metadata()] Missing or invalid operator_symbol for assignment node '$node_type' (resolved='$operator', intent='$intent_operator', pulse_cycles='$pulse_cycles')";
    }

    return {
        operator => $operator,
        assignment_intent => $assignment_intent,
        source_provenance => ($assignment_node->can('source_provenance') ? $assignment_node->source_provenance : {}),
        output_exposure => ($assignment_node->can('output_exposure') ? $assignment_node->output_exposure : 'auto'),
    };
}

=head2 capture_assignment_from_ast

Capture one AST assignment node into the prepared LHS-assignment registry.

=cut

sub capture_assignment_from_ast ($self, $dt_name, $assignment_node, $condition_stack) {
    my $lhs_signal_ast = $assignment_node->target;
    my $rhs_expr = $assignment_node->source;

    if ($lhs_signal_ast && blessed($lhs_signal_ast) && $lhs_signal_ast->isa('FSM::CoreAST::Concatenation')) {
        return $self->capture_lhs_deconstruct_assignment_from_ast(
            $dt_name,
            $assignment_node,
            $condition_stack,
        );
    }

    my $lhs_name = $self->extract_signal_name_from_ast($lhs_signal_ast) // 'unknown_lhs';

    fsm_debug("\n*** PHASE1 ASSIGNMENT NODE REACHED (AST WEB) ***", 3);
    fsm_debug("  DT: $dt_name", 3);
    fsm_debug("  LHS AST Node: " . ref($lhs_signal_ast), 3);
    fsm_debug("  LHS Name: " . $lhs_name, 3);

    fsm_debug("  CONDITION STACK ANALYSIS:", 3);
    fsm_debug("    Stack size: " . scalar(@$condition_stack), 3);
    if (@$condition_stack) {
        for my $i (0 .. $#$condition_stack) {
            my $cond = $condition_stack->[$i];
            if (blessed($cond) && $cond->can('to_systemverilog')) {
                fsm_debug("    Stack[$i]: '" . $cond->to_systemverilog() . "' (" . ref($cond) . ")", 3);
            } else {
                fsm_debug("    Stack[$i]: INVALID - " . (ref($cond) || 'SCALAR') . " - " . ($cond || 'UNDEF'), 3);
            }
        }
    } else {
        fsm_debug("    Stack: EMPTY", 3);
    }

    my $condition_ast = $self->create_condition_expression($condition_stack);
    my $actual_rhs = $self->extract_rhs_capture_value($rhs_expr);
    my $capture_metadata = $self->extract_assignment_capture_metadata($assignment_node);
    my $operator = $capture_metadata->{operator};
    my $assignment_intent = $capture_metadata->{assignment_intent};

    fsm_debug("  SEMANTIC ASSIGNMENT RESULT:", 3);
    fsm_debug("    LHS AST Node: " . ref($lhs_signal_ast), 3);
    fsm_debug("    LHS Name: " . $lhs_name, 3);
    fsm_debug("    RHS: $actual_rhs", 3);
    fsm_debug("    Operator: $operator", 3);
    fsm_debug("    Condition AST: " . (blessed($condition_ast) ? ref($condition_ast) : 'NOT_BLESSED'), 3);
    my $condition_signal_name = defined($condition_ast) ? $condition_ast->to_systemverilog() : 'UNDEFINED';
    fsm_debug("    Condition Signal Name: '$condition_signal_name'", 3);

    $self->register_assignment_capture(
        dt => $dt_name,
        lhs_name_key => $lhs_name,
        lhs_ast => $lhs_signal_ast,
        conditions_ast => $condition_ast,
        rhs => $actual_rhs,
        operator => $operator,
        assignment_intent => $assignment_intent,
        source_provenance => $capture_metadata->{source_provenance},
        output_exposure => $capture_metadata->{output_exposure},
    );

    fsm_debug("*** PHASE1 ASSIGNMENT NODE COMPLETE (AST WEB) ***\n", 3);
}

=head2 capture_lhs_deconstruct_assignment_from_ast

Split one C<Concatenation> LHS assignment into ordinary static partial
captures before assignment analysis. Authored operands map left-to-right onto
the high-to-low slices of the single RHS expression.

=cut

sub capture_lhs_deconstruct_assignment_from_ast ($self, $dt_name, $assignment_node, $condition_stack) {
    my $lhs_concat_ast = $assignment_node->target;
    my $rhs_expr = $assignment_node->source;
    my @operands = @{$lhs_concat_ast->operands || []};

    my $condition_ast = $self->create_condition_expression($condition_stack);
    my $capture_metadata = $self->extract_assignment_capture_metadata($assignment_node);
    my $operator = $capture_metadata->{operator};
    my $assignment_intent = $capture_metadata->{assignment_intent};
    my $source_provenance = ref($capture_metadata->{source_provenance}) eq 'HASH'
        ? $capture_metadata->{source_provenance}
        : {};
    my $deconstruct_contract = ref($source_provenance->{lhs_deconstruct}) eq 'HASH'
        ? $source_provenance->{lhs_deconstruct}
        : {};
    my @operand_widths = ref($deconstruct_contract->{operand_widths}) eq 'ARRAY'
        ? @{$deconstruct_contract->{operand_widths}}
        : ();
    my $total_width = $deconstruct_contract->{total_width};

    die "[CaptureSupport.pm][capture_lhs_deconstruct_assignment_from_ast()] Missing LHS deconstruct width contract"
        unless @operands
            && @operand_widths == @operands
            && defined($total_width)
            && $total_width > 0;

    fsm_debug("\n*** PHASE1 LHS DECONSTRUCT ASSIGNMENT NODE REACHED (AST WEB) ***", 3);
    fsm_debug("  DT: $dt_name", 3);
    fsm_debug("  LHS operand count: " . scalar(@operands), 3);
    fsm_debug("  RHS width: $total_width", 3);

    my $next_high = $total_width - 1;
    for my $index (0 .. $#operands) {
        my $lhs_operand_ast = $operands[$index];
        my $operand_width = $operand_widths[$index];
        die "[CaptureSupport.pm][capture_lhs_deconstruct_assignment_from_ast()] Invalid LHS deconstruct operand width"
            unless defined($operand_width) && $operand_width > 0;

        my $source_high = $next_high;
        my $source_low = $source_high - $operand_width + 1;
        my $lhs_name = $self->extract_signal_name_from_ast($lhs_operand_ast);
        die "[CaptureSupport.pm][capture_lhs_deconstruct_assignment_from_ast()] Could not recover LHS deconstruct operand signal name"
            unless defined($lhs_name) && $lhs_name ne '';

        my $fragment_rhs = $self->source_fragment_capture_value(
            $rhs_expr,
            $total_width,
            $source_high,
            $source_low,
        );

        my %fragment_provenance = %$source_provenance;
        delete $fragment_provenance{aggregate_type_spec};
        if (defined($source_provenance->{aggregate_symbol_name}) && $source_provenance->{aggregate_symbol_name} ne '') {
            my $aggregate_symbol_name = $source_provenance->{aggregate_symbol_name};
            $fragment_provenance{aggregate_symbol_name} = $source_high == $source_low
                ? $aggregate_symbol_name . "[$source_high]"
                : $aggregate_symbol_name . "[$source_high:$source_low]";
        }
        my $fragment_aggregate_type_spec = $self->source_fragment_aggregate_type_spec(
            $source_provenance,
            $total_width,
            $source_high,
            $source_low,
        );
        $fragment_provenance{aggregate_type_spec} = $fragment_aggregate_type_spec
            if ref($fragment_aggregate_type_spec) eq 'HASH';
        $fragment_provenance{lhs_deconstruct_fragment} = {
            index => $index,
            source_high => $source_high,
            source_low => $source_low,
            lhs_width => $operand_width,
        };
        $fragment_provenance{raw_value_expr_rendered} = $fragment_rhs;
        $fragment_provenance{width_contract} = {
            lhs_width => $operand_width,
            rhs_width => $operand_width,
            lhs_explicit => 1,
            rhs_explicit => 1,
            resolution => 'exact_match',
            final_width => $operand_width,
        };

        $self->register_assignment_capture(
            dt => $dt_name,
            lhs_name_key => $lhs_name,
            lhs_ast => $lhs_operand_ast,
            conditions_ast => $condition_ast,
            rhs => $fragment_rhs,
            operator => $operator,
            assignment_intent => $assignment_intent,
            source_provenance => \%fragment_provenance,
            output_exposure => $capture_metadata->{output_exposure},
        );

        fsm_debug("    LHS deconstruct fragment[$index]: $lhs_name <= $fragment_rhs", 3);
        $next_high = $source_low - 1;
    }

    fsm_debug("*** PHASE1 LHS DECONSTRUCT ASSIGNMENT NODE COMPLETE (AST WEB) ***\n", 3);
}

=head2 source_fragment_capture_value

Render the RHS slice that feeds one deconstructed LHS operand.

=cut

sub source_fragment_capture_value ($self, $rhs_expr, $total_width, $source_high, $source_low) {
    my $source_sv = $self->extract_rhs_capture_value($rhs_expr);
    return $source_sv
        if $source_high == $total_width - 1 && $source_low == 0;

    my $wrapped_source = $self->wrap_sv_expr_for_select($source_sv);
    return "${wrapped_source}[$source_high]"
        if $source_high == $source_low;
    return "${wrapped_source}[$source_high:$source_low]";
}

sub wrap_sv_expr_for_select ($self, $expr) {
    return $expr if defined($expr) && $expr =~ /^[a-zA-Z_][a-zA-Z0-9_]*$/;
    return "($expr)";
}

=head2 source_fragment_aggregate_type_spec

Return the aggregate/scalar type contract for one deconstructed RHS slice when
the source RHS carried a whole-aggregate type contract. Exact subaggregate
fragments keep their nested list/record type; arbitrary partial slices fall
back to a scalar width contract.

=cut

sub source_fragment_aggregate_type_spec ($self, $source_provenance, $total_width, $source_high, $source_low) {
    return unless ref($source_provenance) eq 'HASH';
    my $source_type_spec = ref($source_provenance->{aggregate_type_spec}) eq 'HASH'
        ? $source_provenance->{aggregate_type_spec}
        : undef;
    return unless $source_type_spec;
    return unless defined($total_width)
        && defined($source_high)
        && defined($source_low)
        && $total_width > 0
        && $source_high >= $source_low
        && $source_high < $total_width;

    my $type_width = $source_type_spec->{width};
    return unless defined($type_width) && $type_width == $total_width;

    return FSM::Package::AggregatePathSupport->type_spec_for_packed_fragment(
        root_type_spec => $source_type_spec,
        total_width => $total_width,
        high => $source_high,
        low => $source_low,
    );
}

=head2 capture_transition_from_ast

Capture one AST state-transition node into the prepared C<next_state>
assignment registry.

=cut

sub capture_transition_from_ast ($self, $dt_name, $transition_node, $condition_stack) {
    my $target_state = $transition_node->target_state;
    my $condition_ast = $self->create_condition_expression($condition_stack);

    my $state_value = $self->register_transition_capture(
        dt => $dt_name,
        target_state => $target_state,
        conditions_ast => $condition_ast,
    );

    my $condition_signal_name = defined($condition_ast) ? $condition_ast->to_systemverilog() : 'UNDEFINED';
    fsm_debug("    Recorded AST transition: next_state <= $state_value when (signal: '$condition_signal_name')", 3);

    return $state_value;
}

=head2 convert_condition_to_ast

Convert one parsed FSMGen condition node into the internal AST representation
used by the backend capture path.

=cut

sub convert_condition_to_ast ($self, $condition_node) {
    unless ($condition_node) {
        fsm_debug("    CONVERT_CONDITION_AST: WARNING - undefined condition node", 3);
        return FSM::AST::Utils::literal("1'b1");
    }

    fsm_debug("    CONVERT_CONDITION_AST: Node type: " . ref($condition_node));

    if ($condition_node->isa('FSM::CoreAST::AggregateRef')) {
        fsm_debug("    CONVERT_CONDITION_AST: AggregateRef -> keep typed aggregate AST leaf", 3);
        return $condition_node;

    } elsif ($condition_node->isa('FSM::CoreAST::SignalRef')) {
        my $signal_name = $condition_node->signal->name;
        fsm_debug("    CONVERT_CONDITION_AST: SignalRef -> signal_ref('$signal_name')", 3);
        return FSM::AST::Utils::signal_ref($signal_name);

    } elsif (ref($condition_node) eq 'FSM::CoreAST::UnaryOp' || ($condition_node->can('operator') && $condition_node->can('operand'))) {
        my $operator_type = 'unknown';
        if (ref($condition_node) eq 'HASH' && $condition_node->{type}) {
            $operator_type = $condition_node->{type};
        } elsif ($condition_node->can('type')) {
            $operator_type = $condition_node->type;
        }

        fsm_debug("    CONVERT_CONDITION_AST: UnaryOp with type: $operator_type", 3);

        if ($operator_type eq 'unary_op' || $operator_type eq 'not' || $operator_type eq '!') {
            my $operand_ast = $self->convert_condition_to_ast($condition_node->operand);
            my $result = FSM::AST::Utils::not_op($operand_ast);
            fsm_debug("    CONVERT_CONDITION_AST: UnaryOp(negation) -> NOT node", 3);
            return $result;
        } else {
            my $operand_ast = $self->convert_condition_to_ast($condition_node->operand);
            my $result = FSM::AST::UnaryOp->new($operator_type, $operand_ast);
            fsm_debug("    CONVERT_CONDITION_AST: UnaryOp($operator_type) -> UnaryOp node", 3);
            return $result;
        }

    } elsif (ref($condition_node) eq 'FSM::CoreAST::BinaryOp' || ($condition_node->can('left') && $condition_node->can('right') && $condition_node->can('operator'))) {
        my $left_ast = $self->convert_condition_to_ast($condition_node->left);
        my $right_ast = $self->convert_condition_to_ast($condition_node->right);
        my $op = $condition_node->operator;

        my $result;
        if ($op eq '==') {
            $result = FSM::AST::Utils::equals_op($left_ast, $right_ast);
        } elsif ($op eq '&&' || $op eq '&') {
            $result = FSM::AST::Utils::and_op($left_ast, $right_ast);
        } elsif ($op eq '||' || $op eq '|') {
            $result = FSM::AST::Utils::or_op($left_ast, $right_ast);
        } else {
            $result = FSM::AST::BinaryOp->new($op, $left_ast, $right_ast);
        }

        fsm_debug("    CONVERT_CONDITION_AST: BinaryOp($op) -> BinaryOp node", 3);
        return $result;

    } elsif ($condition_node->isa('FSM::CoreAST::Literal')) {
        my $value = $condition_node->value;
        fsm_debug("    CONVERT_CONDITION_AST: Literal -> literal('$value')", 3);
        return FSM::AST::Utils::literal($value);

    } else {
        my $node_type = ref($condition_node);
        fsm_debug("    CONVERT_CONDITION_AST: Unknown type '$node_type' - creating generic signal", 3);

        if ($condition_node->can('name')) {
            my $name = eval { $condition_node->name };
            if ($name) {
                fsm_debug("    CONVERT_CONDITION_AST: Found name attribute: $name", 3);
                return FSM::AST::Utils::signal_ref($name);
            }
        }

        return FSM::AST::Utils::signal_ref("condition");
    }
}

=head2 convert_test_value_to_ast

Convert one parsed test selector value token into an AST literal node.

=cut

sub convert_test_value_to_ast ($self, $test_value) {
    fsm_debug("    CONVERT_TEST_VALUE_AST: Converting test value: '$test_value'", 3);

    if ($test_value =~ /^=(\d+)$/) {
        my $val = $1;
        if ($val eq '0') {
            return FSM::AST::Utils::literal("1'b0");
        } elsif ($val eq '1') {
            return FSM::AST::Utils::literal("1'b1");
        } else {
            return FSM::AST::Utils::literal($val);
        }
    } elsif ($test_value =~ /^\d+$/) {
        if ($test_value eq '0') {
            return FSM::AST::Utils::literal("1'b0");
        } elsif ($test_value eq '1') {
            return FSM::AST::Utils::literal("1'b1");
        } else {
            return FSM::AST::Utils::literal($test_value);
        }
    } else {
        return FSM::AST::Utils::literal($test_value);
    }
}

=head2 parse_test_value_selector

Split one test selector token into an explicit comparison operator and raw
selector value.

=cut

sub parse_test_value_selector ($self, $test_value) {
    confess "[CaptureSupport.pm][parse_test_value_selector()] Missing test value selector"
        unless defined $test_value && $test_value ne '';

    if ($test_value =~ /^(==|!=|<=|>=|<|>|=)(.+)$/) {
        my ($operator, $raw_value) = ($1, $2);
        $operator = '==' if $operator eq '=';
        return ($operator, $raw_value);
    }

    confess
        "[CaptureSupport.pm][parse_test_value_selector()] Unsupported test value selector '$test_value'. ".
        "Active test-node selectors must use an explicit operator-prefixed token such as '=0', '=OTHER', '!=8'0', or '>8'3'";
}

=head2 build_test_condition_ast

Build one AST condition from a test signal and explicit selector token.

=cut

sub build_test_condition_ast ($self, $test_signal, $test_value) {
    my $test_signal_name = blessed($test_signal) && $test_signal->can('name')
        ? $test_signal->name
        : $test_signal;

    unless (defined($test_signal_name) && $test_signal_name ne '') {
        die "[CaptureSupport.pm][build_test_condition_ast()] Missing test signal name";
    }

    my ($operator, $raw_test_value) = $self->parse_test_value_selector($test_value);
    my $signal_ast = FSM::AST::Utils::signal_ref($test_signal_name);
    my $value_ast = $self->convert_test_value_to_ast($raw_test_value);

    return FSM::AST::Utils::equals_op($signal_ast, $value_ast)
        if $operator eq '==';

    return FSM::AST::BinaryOp->new($operator, $signal_ast, $value_ast);
}

=head2 extract_rhs_capture_value

Render one typed RHS AST into the normalized string form used by capture-time
assignment metadata.

=cut

sub extract_rhs_capture_value ($self, $expr) {
    return 'unknown_expr' unless $expr && blessed($expr);

    if ($expr->can('to_systemverilog')) {
        my $sv = eval { $expr->to_systemverilog() };
        return $sv if defined $sv && $sv ne '';
    }

    if ($expr->isa('FSM::CoreAST::Literal')) {
        return $expr->value;
    } elsif ($expr->isa('FSM::CoreAST::SignalRef')) {
        return $expr->signal->name;
    } elsif ($expr->isa('FSM::CoreAST::IndexedRef')) {
        return $expr->to_systemverilog;
    } elsif ($expr->isa('FSM::CoreAST::AggregateRef')) {
        return $expr->to_systemverilog;
    } elsif ($expr->isa('FSM::CoreAST::BinaryOp')) {
        my $left = $self->extract_rhs_capture_value($expr->left);
        my $right = $self->extract_rhs_capture_value($expr->right);
        return "$left " . $expr->operator . " $right";
    } elsif ($expr->isa('FSM::CoreAST::Concatenation')) {
        my @operand_strings;
        for my $operand (@{$expr->operands}) {
            push @operand_strings, $self->extract_rhs_capture_value($operand);
        }
        return '{' . join(', ', @operand_strings) . '}';
    }

    my $expr_type = ref($expr);
    $expr_type =~ s/^.*:://;
    return lc($expr_type) . '_expr';
}

=head2 extract_signal_name_from_ast

Recover one stable signal name from a typed signal-reference AST node or
nearby compatible structure.

=cut

sub extract_signal_name_from_ast ($self, $signal_ast) {
    return undef unless $signal_ast && blessed($signal_ast);

    if ($signal_ast->can('name') && defined($signal_ast->name)) {
        return $signal_ast->name;
    } elsif ($signal_ast->can('signal_name') && defined($signal_ast->signal_name)) {
        return $signal_ast->signal_name;
    } elsif ($signal_ast->can('signal') && $signal_ast->signal && $signal_ast->signal->can('name')) {
        return $signal_ast->signal->name;
    } else {
        my $sv_repr = eval { $signal_ast->to_systemverilog() };
        if ($sv_repr && $sv_repr =~ /^([a-zA-Z_][a-zA-Z0-9_]*)/) {
            return $1;
        }
    }

    return undef;
}

1;
