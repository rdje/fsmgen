package FSM::Synthesis::EnableGraph::SignalSupport;

=head1 NAME

FSM::Synthesis::EnableGraph::SignalSupport - Own signal-facing and intermediate-classification support for EnableGraph

=head1 DESCRIPTION

This package owns the remaining signal-facing support family around the older
direct synthesis/backend path. It centralizes:

=over 4

=item *

AST-based intermediate signal naming

=item *

expression cleanup for compatibility/intermediate rendering

=item *

FSM-module reference attachment and AST-based reset/default lookup

=item *

intermediate-signal extraction and classification

=item *

enable-signal name cleanup and RHS-based enable naming

=back

The broader C<EnableGraph> shell now stays thin while callers ask this support
owner directly for the signal/intermediate behavior they need.

=cut

use v5.20;
use strict;
use warnings;
use feature qw(signatures);
no warnings 'experimental::signatures';

use Data::Dumper;
use Scalar::Util qw(blessed refaddr);

use FSM::Debug;

=head2 new

Construct one signal-support owner bound to a live
C<FSM::HDL::FlattenedDT> backend context.

=cut

sub new ($class, %args) {
    my $flattened_dt = $args{flattened_dt}
      or die "[SignalSupport.pm][new()] Missing required 'flattened_dt' argument";

    return bless {
        flattened_dt => $flattened_dt,
    }, $class;
}

=head2 generate_ast_based_signal_name

Generate one systematic intermediate-signal name from an AST tree using the
current signal-name mapping rules.

=cut

sub generate_ast_based_signal_name($self, $ast) {
    return "unknown_signal" unless $ast && blessed($ast);

    fsm_debug("AST_SIGNAL_NAME: Generating name for " . ref($ast), 3);

    if ($ast->isa('FSM::AST::SignalRef') || $ast->isa('FSM::CoreAST::SignalRef')) {
        my $signal_name = $self->{flattened_dt}->{enable_graph_capture_support}->extract_signal_name_from_ast($ast);
        return $signal_name || "unknown_signal";

    } elsif ($ast->isa('FSM::CoreAST::ParameterRef')) {
        my $parameter_name = eval { $ast->name } || 'parameter_ref';
        $parameter_name =~ s/[^a-zA-Z0-9_]+/_/g;
        $parameter_name =~ s/^_+|_+$//g;
        return $parameter_name || 'parameter_ref';

    } elsif ($ast->isa('FSM::CoreAST::AggregateRef')) {
        my $aggregate_name = eval { $ast->to_systemverilog() } || 'aggregate_ref';
        $aggregate_name =~ s/[^a-zA-Z0-9_]+/_/g;
        $aggregate_name =~ s/^_+|_+$//g;
        return $aggregate_name || 'aggregate_ref';

    } elsif ($ast->isa('FSM::AST::Literal') || $ast->isa('FSM::CoreAST::Literal')) {
        my $value = $ast->value;
        if ($value eq "1'b1") {
            return "const_1";
        } elsif ($value eq "1'b0") {
            return "const_0";
        } else {
            my $clean_value = $value;
            $clean_value =~ s/[^a-zA-Z0-9_]/_/g;
            return "const_$clean_value";
        }

    } elsif ($ast->isa('FSM::AST::BinaryOp') || $ast->isa('FSM::CoreAST::BinaryOp')) {
        my $left_name = $self->generate_ast_based_signal_name($ast->left);
        my $right_name = $self->generate_ast_based_signal_name($ast->right);
        my $op = $ast->operator;
        my $op_name = $self->map_operator_to_name($op);
        return "${left_name}_${op_name}_${right_name}";

    } elsif ($ast->isa('FSM::AST::UnaryOp') || $ast->isa('FSM::CoreAST::UnaryOp')) {
        my $operand_name = $self->generate_ast_based_signal_name($ast->operand);
        my $op = $ast->operator || "not";
        my $op_name = $self->map_operator_to_name($op);
        return "${op_name}_${operand_name}";

    } else {
        my $type_name = ref($ast);
        $type_name =~ s/^.*:://;
        return lc($type_name) . "_expr";
    }
}

=head2 map_operator_to_name

Map one rendered operator into the normalized signal-name fragment used for
AST-based intermediate naming.

=cut

sub map_operator_to_name($self, $operator) {
    my %op_map = (
        '&&' => 'and',
        '&'  => 'and',
        '||' => 'or',
        '|'  => 'or',
        '==' => 'eq',
        '!=' => 'ne',
        '!'  => 'not',
        '+'  => 'plus',
        '-'  => 'minus',
        '*'  => 'mult',
        '/'  => 'div',
        '<'  => 'lt',
        '>'  => 'gt',
        '<=' => 'le',
        '>=' => 'ge'
    );

    return $op_map{$operator} || "op";
}

=head2 clean_intermediate_expression

Normalize one compatibility/intermediate expression string into cleaner
SystemVerilog text for fallback parsing and dependency recovery.

=cut

sub clean_intermediate_expression($self, $expression) {
    fsm_debug("CLEAN_EXPR: Input expression: '$expression'", 3);

    $expression =~ s/^\((.+)\)$/$1/;
    $expression =~ s/\s*&\s*&\s*/&&/g;
    $expression =~ s/\s*\|\s*\|\s*/||/g;
    $expression =~ s/\s*[&|]\s*$//;
    $expression =~ s/^\s*[&|]\s*//;

    my $open_count = ($expression =~ tr/\(//);
    my $close_count = ($expression =~ tr/\)//);

    if ($open_count > $close_count) {
        $expression .= ')' x ($open_count - $close_count);
    } elsif ($close_count > $open_count) {
        $expression = '(' x ($close_count - $open_count) . $expression;
    }

    $expression =~ s/\s*&\s*([a-zA-Z_][a-zA-Z0-9_]*)\s*&/ && $1/g;
    $expression =~ s/([a-zA-Z_][a-zA-Z0-9_]*)\s*&\s*&/$1 &&/g;
    $expression =~ s/\s+/ /g;
    $expression =~ s/^\s+|\s+$//g;
    $expression =~ s/([a-zA-Z_][a-zA-Z0-9_]*)\s*[&|]\s*\)/$1)/g;
    $expression =~ s/\(\s*[&|]\s*([a-zA-Z_][a-zA-Z0-9_]*)/(signal/g;

    fsm_debug("CLEAN_EXPR: Output expression: '$expression'", 3);
    return $expression;
}

=head2 set_fsm_module_reference

Attach the current live FSM module reference to the backend context for later
signal-width and metadata lookup.

=cut

sub set_fsm_module_reference($self, $fsm_module) {
    my $ctx = $self->{flattened_dt};
    $ctx->{fsm_module} = $fsm_module;
    fsm_debug("FSM_MODULE_REF: Stored reference to FSM module: " . ($fsm_module ? $fsm_module->name : 'undef'), 3);
}

=head2 extract_intermediate_signals_from_ast

Extract the direct intermediate-signal dependencies referenced by one AST.

=cut

sub extract_intermediate_signals_from_ast($self, $ast) {
    my @signal_names;
    my %seen_node_ids;
    my %seen_signal_names;
    $self->_collect_intermediate_signals_from_ast($ast, \@signal_names, \%seen_node_ids, \%seen_signal_names);

    my $summary = @signal_names ? join(', ', @signal_names) : 'none';
    fsm_debug("[SignalSupport.pm][extract_intermediate_signals_from_ast()] Extracted " . scalar(@signal_names) . " intermediate signal(s): $summary", 3);
    return @signal_names;
}

=head2 _collect_intermediate_signals_from_ast

Internal recursive collector for C<extract_intermediate_signals_from_ast>.

=cut

sub _collect_intermediate_signals_from_ast($self, $ast, $signal_names, $seen_node_ids, $seen_signal_names) {
    return unless $ast && (blessed($ast) || ref($ast) eq 'HASH');

    my $node_id = refaddr($ast);
    $node_id = sprintf('%p', $ast) unless defined $node_id;
    return if $seen_node_ids->{$node_id}++;

    if (ref($ast) eq 'HASH' && !blessed($ast)) {
        if (($ast->{type} || '') eq 'signal') {
            my $signal_name = $ast->{name};
            if (defined($signal_name) && $signal_name ne '' && $self->is_intermediate_signal($signal_name)) {
                if (!$seen_signal_names->{$signal_name}++) {
                    push @$signal_names, $signal_name;
                    fsm_debug("[SignalSupport.pm][_collect_intermediate_signals_from_ast()] Found intermediate signal ref '$signal_name' from parsed expression tree", 3);
                }
            }
        }

        for my $key (qw(left right operand condition true_expr false_expr index expression)) {
            my $child = $ast->{$key};
            next unless $child && (blessed($child) || ref($child) eq 'HASH');
            $self->_collect_intermediate_signals_from_ast($child, $signal_names, $seen_node_ids, $seen_signal_names);
        }

        for my $key (qw(operands children arguments expressions parts)) {
            my $children = $ast->{$key};
            next unless ref($children) eq 'ARRAY';
            for my $child (@$children) {
                next unless $child && (blessed($child) || ref($child) eq 'HASH');
                $self->_collect_intermediate_signals_from_ast($child, $signal_names, $seen_node_ids, $seen_signal_names);
            }
        }

        return;
    }

    if ($ast->isa('FSM::HDL::IntermediateSignalRef')) {
        my $signal_name = eval { $ast->signal_name } || $ast->{signal_name};
        if (defined($signal_name) && $signal_name ne '' && !$seen_signal_names->{$signal_name}++) {
            push @$signal_names, $signal_name;
            fsm_debug("[SignalSupport.pm][_collect_intermediate_signals_from_ast()] Found direct intermediate ref '$signal_name'", 3);
        }
        return;
    }

    if ($ast->isa('FSM::AST::SignalRef') ||
        $ast->isa('FSM::CoreAST::SignalRef') ||
        $ast->isa('FSM::AST::IndexedRef') ||
        $ast->isa('FSM::CoreAST::IndexedRef') ||
        $ast->isa('FSM::CoreAST::AggregateRef'))
    {
        my $signal_name = $self->{flattened_dt}->{enable_graph_capture_support}->extract_signal_name_from_ast($ast);
        if (defined($signal_name) && $signal_name ne '' && $self->is_intermediate_signal($signal_name)) {
            if (!$seen_signal_names->{$signal_name}++) {
                push @$signal_names, $signal_name;
                fsm_debug("[SignalSupport.pm][_collect_intermediate_signals_from_ast()] Found intermediate signal ref '$signal_name'", 3);
            }
        }
    }

    for my $accessor (qw(left right operand condition true_expr false_expr index expression)) {
        next unless $ast->can($accessor);
        my $child = eval { $ast->$accessor() };
        next unless $child && blessed($child);
        $self->_collect_intermediate_signals_from_ast($child, $signal_names, $seen_node_ids, $seen_signal_names);
    }

    for my $accessor (qw(operands children arguments expressions parts)) {
        next unless $ast->can($accessor);
        my $children = eval { $ast->$accessor() };
        next unless ref($children) eq 'ARRAY';
        for my $child (@$children) {
            next unless $child && blessed($child);
            $self->_collect_intermediate_signals_from_ast($child, $signal_names, $seen_node_ids, $seen_signal_names);
        }
    }
}

=head2 get_reset_value_from_ast

Resolve the effective reset value for one LHS AST using direct AST metadata
first and the normalized assignment-analysis fallback second.

=cut

sub get_reset_value_from_ast($self, $lhs_ast) {
    my $ctx = $self->{flattened_dt};
    my $lhs_name = $ctx->{enable_graph_capture_support}->extract_signal_name_from_ast($lhs_ast);

    unless (defined $lhs_name) {
        fsm_debug("WARNING: Could not extract signal name from AST, using fallback", 3);
        $lhs_name = 'unknown_signal';
    }
    fsm_debug("GET_RESET_VALUE_FROM_AST: Getting reset value for '$lhs_name'", 3);

    if ($lhs_ast->can('reset_value')) {
        my $reset_val = $lhs_ast->reset_value();
        if (defined $reset_val) {
            fsm_debug("  AST reset_value: '$reset_val'", 3);
            return $self->_normalize_reset_value_for_lhs($lhs_name, $lhs_ast, $reset_val);
        }
    }

    if ($lhs_ast->can('signal')) {
        my $signal = $lhs_ast->signal;
        if ($signal && $signal->can('get_attribute')) {
            my $reset_val = $signal->get_attribute('reset_value');
            if (defined $reset_val) {
                fsm_debug("  LHS signal reset_value: '$reset_val'", 3);
                return $self->_normalize_reset_value_for_lhs($lhs_name, $lhs_ast, $reset_val);
            }
        }
        if ($signal && $signal->can('attributes') && $signal->attributes) {
            my $reset_val = $signal->attributes->{reset_value};
            if (defined $reset_val) {
                fsm_debug("  LHS signal attribute reset_value: '$reset_val'", 3);
                return $self->_normalize_reset_value_for_lhs($lhs_name, $lhs_ast, $reset_val);
            }
        }
    }

    fsm_debug("  No AST reset value, using fallback", 3);
    return $ctx->{enable_graph_assignment_support}->get_reset_value($lhs_name);
}

sub _normalize_reset_value_for_lhs ($self, $lhs_name, $lhs_ast, $reset_val) {
    my $width = $self->_reset_target_width($lhs_name, $lhs_ast);
    return $reset_val unless defined($width) && $width > 1;

    return "${width}'b" . ('0' x $width)
        if $reset_val =~ /^(?:0|1'b0|1'd0|1'h0)\z/i;
    return "${width}'d1"
        if $reset_val =~ /^(?:1|1'b1|1'd1|1'h1)\z/i;

    return $reset_val;
}

sub _reset_target_width ($self, $lhs_name, $lhs_ast) {
    if ($lhs_ast && blessed($lhs_ast) && $lhs_ast->can('signal') && $lhs_ast->signal && $lhs_ast->signal->can('width')) {
        my $width = $lhs_ast->signal->width;
        return $width if defined($width) && $width > 0;
    }

    if ($lhs_ast && blessed($lhs_ast) && $lhs_ast->can('width')) {
        my $width = $lhs_ast->width;
        return $width if defined($width) && $width > 0;
    }

    my $ctx = $self->{flattened_dt};
    my $signal_info = $ctx->{enable_graph_assignment_support}->get_signal_info($lhs_name);
    return $signal_info->{width} if $signal_info && $signal_info->{width};
    return 1;
}

=head2 get_default_value_from_ast

Resolve the effective default value for one LHS AST using AST metadata first
and the normalized assignment-analysis fallback second.

=cut

sub get_default_value_from_ast($self, $lhs_ast) {
    my $ctx = $self->{flattened_dt};

    fsm_debug("DEBUG: lhs_ast object type: " . ref($lhs_ast), 3);
    fsm_debug("DEBUG: lhs_ast blessed: " . (blessed($lhs_ast) || 'NOT BLESSED'), 3);
    if (blessed($lhs_ast)) {
        fsm_debug("DEBUG: lhs_ast can name: " . ($lhs_ast->can('name') ? 'YES' : 'NO'), 3);
        my @methods = qw(name signal type operands);
        for my $method (@methods) {
            fsm_debug("DEBUG: lhs_ast can $method: " . ($lhs_ast->can($method) ? 'YES' : 'NO'), 3);
        }
    }

    my $lhs_name = $ctx->{enable_graph_capture_support}->extract_signal_name_from_ast($lhs_ast);
    unless (defined $lhs_name) {
        fsm_debug("WARNING: Could not extract signal name from AST, using fallback", 3);
        $lhs_name = 'unknown_signal';
    }
    fsm_debug("GET_DEFAULT_VALUE_FROM_AST: Getting default value for '$lhs_name'", 3);

    if ($lhs_ast->can('default_value')) {
        my $default_val = $lhs_ast->default_value();
        if (defined $default_val) {
            fsm_debug("  AST default_value: '$default_val'", 3);
            return $default_val;
        }
    }

    if ($lhs_ast->can('reset_value')) {
        my $reset_val = $lhs_ast->reset_value();
        if (defined $reset_val) {
            fsm_debug("  Using AST reset_value as default: '$reset_val'", 3);
            return $reset_val;
        }
    }

    if ($lhs_ast->can('signal')) {
        my $signal = $lhs_ast->signal;
        if ($signal && $signal->can('get_attribute')) {
            my $reset_val = $signal->get_attribute('reset_value');
            if (defined $reset_val) {
                fsm_debug("  Using LHS signal reset_value as default: '$reset_val'", 3);
                return $reset_val;
            }
        }
        if ($signal && $signal->can('attributes') && $signal->attributes) {
            my $reset_val = $signal->attributes->{reset_value};
            if (defined $reset_val) {
                fsm_debug("  Using LHS signal attribute reset_value as default: '$reset_val'", 3);
                return $reset_val;
            }
        }
    }

    fsm_debug("  No AST default value, using fallback", 3);
    return $ctx->{enable_graph_assignment_support}->get_default_value($lhs_name);
}

=head2 is_intermediate_signal

Report whether one signal name should be treated as an intermediate signal that
must be tracked or declared by the direct backend path.

=cut

sub is_intermediate_signal($self, $signal_name) {
    my $ctx = $self->{flattened_dt};

    fsm_debug("IS_INTERMEDIATE_SIGNAL: Checking '$signal_name'", 3);

    if (exists $ctx->{intermediate_signals}->{$signal_name}) {
        fsm_debug("  -> YES: Found in intermediate_signals registry", 3);
        return 1;
    }
    if (exists $ctx->{global_expressions}->{$signal_name}) {
        fsm_debug("  -> YES: Found in global_expressions registry", 3);
        return 1;
    }

    if ($ctx->{ast_factorizer} && $ctx->{ast_factorizer}->{intermediate_signals}) {
        if (exists $ctx->{ast_factorizer}->{intermediate_signals}->{$signal_name}) {
            fsm_debug("  -> YES: Found in AST factorizer results", 3);
            return 1;
        }
    }

    if ($ctx->{referenced_intermediate_signals} && exists $ctx->{referenced_intermediate_signals}->{$signal_name}) {
        fsm_debug("  -> YES: Found in pre-scan referenced signals", 3);
        return 1;
    }

    if ($self->_fsm_module_signal_declares_intermediate($signal_name)) {
        fsm_debug("  -> YES: FSM module signal metadata marks this as an intermediate signal", 3);
        return 1;
    }

    if ($self->is_signal_ast_based_intermediate($signal_name)) {
        fsm_debug("  -> YES: AST-based intermediate signal detected", 3);
        return 1;
    }

    fsm_debug("  -> NO: Not an intermediate signal", 3);
    return 0;
}

=head2 _fsm_module_signal_declares_intermediate

Internal FSM-module metadata check for whether one signal is explicitly marked
as intermediate.

=cut

sub _fsm_module_signal_declares_intermediate($self, $signal_name) {
    my $ctx = $self->{flattened_dt};
    return 0 unless defined($signal_name) && $signal_name ne '';
    return 0 unless $ctx->{fsm_module} && $ctx->{fsm_module}->can('signals') && $ctx->{fsm_module}->signals;

    my $signal = $ctx->{fsm_module}->signals->{$signal_name} or return 0;

    if (blessed($signal) && $signal->can('get_attribute')) {
        my $marked = $signal->get_attribute('is_intermediate');
        return 1 if defined($marked) && $marked;
    }

    if (blessed($signal) && $signal->can('attributes') && ref($signal->attributes) eq 'HASH') {
        my $marked = $signal->attributes->{is_intermediate};
        return 1 if defined($marked) && $marked;
    }

    if (blessed($signal) && $signal->can('is_intermediate') && $signal->can('driving_ast') && $signal->driving_ast) {
        return 1 if $signal->is_intermediate;
    }

    return 0;
}

=head2 is_signal_ast_based_intermediate

Report whether one signal name should count as intermediate based on AST-based
factorization evidence instead of flat string heuristics.

=cut

sub is_signal_ast_based_intermediate($self, $signal_name) {
    my $ctx = $self->{flattened_dt};

    fsm_debug("AST_INTERMEDIATE_CHECK: Checking if '$signal_name' is an AST-based intermediate signal", 3);

    if ($ctx->{ast_factorizer} && $ctx->{ast_factorizer}->{intermediate_signals}) {
        if (exists $ctx->{ast_factorizer}->{intermediate_signals}->{$signal_name}) {
            my $signal_info = $ctx->{ast_factorizer}->{intermediate_signals}->{$signal_name};

            if ($signal_info->{ast} && blessed($signal_info->{ast})) {
                my $contains_operators = $ctx->{enable_graph_ast_support}->ast_contains_factorizable_operators($signal_info->{ast});
                if ($contains_operators) {
                    fsm_debug("  AST_INTERMEDIATE: Signal '$signal_name' contains factorizable operators - INTERMEDIATE", 3);
                    return 1;
                }
            }
        }
    }

    my $native_ast = $ctx->{enable_graph_intermediate_support}->_get_native_intermediate_signal_ast($signal_name);
    if ($native_ast && blessed($native_ast)) {
        my $contains_operators = $ctx->{enable_graph_ast_support}->ast_contains_factorizable_operators($native_ast);
        if ($contains_operators) {
            fsm_debug("  AST_INTERMEDIATE: Signal '$signal_name' resolved to native AST with operators - INTERMEDIATE", 3);
            return 1;
        }
    }

    if ($ctx->{expression_usage} && exists $ctx->{expression_usage}->{$signal_name}) {
        my $usage_count = $ctx->{expression_usage}->{$signal_name};
        if ($usage_count > 1) {
            fsm_debug("  AST_INTERMEDIATE: Signal '$signal_name' is multi-use ($usage_count times) - LIKELY INTERMEDIATE", 3);
            return 1;
        }
    }

    fsm_debug("  AST_INTERMEDIATE: Signal '$signal_name' shows no AST-based operator indicators - NOT INTERMEDIATE", 3);
    return 0;
}

=head2 _signal_name_indicates_ast_operators

Internal AST-metadata-only check for whether one signal name corresponds to an
operator-bearing AST-generated intermediate.

=cut

sub _signal_name_indicates_ast_operators($self, $signal_name) {
    my $ctx = $self->{flattened_dt};

    fsm_debug("\n*** _signal_name_indicates_ast_operators: Analyzing signal '$signal_name' ***", 3);
    fsm_debug("    AST_NAME_PATTERN: Using PURE AST metadata approach - no string patterns!", 3);

    fsm_debug("    CHECKING REGISTRY #1: global_expressions (AST factorization registry)", 3);
    if ($ctx->{global_expressions}) {
        fsm_debug("      Registry has " . scalar(keys %{$ctx->{global_expressions}}) . " entries", 3);
        for my $expr (keys %{$ctx->{global_expressions}}) {
            if ($ctx->{global_expressions}->{$expr} eq $signal_name) {
                fsm_debug("      FOUND: Signal '$signal_name' maps to expression: '$expr'", 3);
                my $ast = eval { $ctx->{expr_namer}->parse_expression($expr) } if $ctx->{expr_namer};
                if ($ast && blessed($ast) && $ctx->{enable_graph_ast_support}->ast_contains_factorizable_operators($ast)) {
                    fsm_debug("    AST_NAME_METADATA: Signal '$signal_name' has AST metadata with operators - INTERMEDIATE", 3);
                    return 1;
                }
                fsm_debug("    AST_NAME_METADATA: Signal '$signal_name' has AST metadata without factorizable operators - NOT intermediate", 3);
                return 0;
            }
        }
        fsm_debug("      NOT FOUND: Signal '$signal_name' not found in global_expressions registry", 3);
    } else {
        fsm_debug("      WARNING: global_expressions registry is empty or not initialized", 3);
    }

    fsm_debug("    CHECKING REGISTRY #2: fsm_module->signals (FSMGenFull signal registry)", 3);
    if ($ctx->{fsm_module} && $ctx->{fsm_module}->can('signals') && $ctx->{fsm_module}->signals) {
        my $signals = $ctx->{fsm_module}->signals;
        fsm_debug("      Registry has " . scalar(keys %$signals) . " signals", 3);

        my @or_signals = grep { /^or_/ } keys %$signals;
        if (@or_signals) {
            fsm_debug("      FOUND OR SIGNALS: " . join(", ", @or_signals), 3);
        } else {
            fsm_debug("      NO OR SIGNALS found in registry!", 3);
        }

        if (exists $signals->{$signal_name}) {
            my $signal = $signals->{$signal_name};
            fsm_debug("      FOUND: Signal '$signal_name' in FSMGenFull signals registry", 3);
            fsm_debug("      Signal object type: " . (ref($signal) || "UNTYPED"), 3);
            fsm_debug("      Signal blessed: " . (blessed($signal) ? "YES" : "NO"), 3);

            fsm_debug("      CHECK #1: Checking 'attributes' hash method", 3);
            if (blessed($signal) && $signal->can('attributes')) {
                fsm_debug("        Signal has 'attributes' method", 3);
                my $attrs = $signal->attributes || {};
                fsm_debug("        Attributes: " . join(", ", map {"$_=>".(defined $attrs->{$_} ? $attrs->{$_} : "undef")} keys %$attrs), 3);
                if (exists $attrs->{is_intermediate}) {
                    fsm_debug("        Found 'is_intermediate' attribute: " . ($attrs->{is_intermediate} ? "TRUE" : "FALSE"), 3);
                    if ($attrs->{is_intermediate}) {
                        fsm_debug("    AST_NAME_METADATA: Signal '$signal_name' found in FSMGenFull with is_intermediate=1 - INTERMEDIATE", 3);
                        return 1;
                    }
                } else {
                    fsm_debug("        No 'is_intermediate' attribute found", 3);
                }
            } else {
                fsm_debug("        Signal doesn't have 'attributes' method", 3);
            }

            fsm_debug("      CHECK #2: Checking direct 'is_intermediate' method or property", 3);
            my $has_method = blessed($signal) && $signal->can('is_intermediate');
            my $is_hash = ref($signal) eq 'HASH';
            my $has_property = $is_hash && exists $signal->{is_intermediate};

            fsm_debug("        Has is_intermediate method: " . ($has_method ? "YES" : "NO"), 3);
            fsm_debug("        Is hash ref: " . ($is_hash ? "YES" : "NO"), 3);
            fsm_debug("        Has is_intermediate property: " . ($has_property ? "YES" : "NO"), 3);

            if ($has_method || $has_property) {
                my $is_intermediate = $has_method ? $signal->is_intermediate() : $signal->{is_intermediate};
                fsm_debug("        is_intermediate value: " . (defined $is_intermediate ? ($is_intermediate ? "TRUE" : "FALSE") : "UNDEF"), 3);
                if ($is_intermediate) {
                    fsm_debug("    AST_NAME_METADATA: Signal '$signal_name' found in FSMGenFull with is_intermediate - INTERMEDIATE", 3);
                    return 1;
                }
            }

            fsm_debug("      CHECK #3: Dumping signal object structure", 3);
            my $dump = Data::Dumper->new([$signal])->Terse(1)->Indent(0)->Dump;
            $dump =~ s/\n/ /g;
            fsm_debug("        SIGNAL DUMP: $dump", 3);
            if ($dump =~ /is_intermediate[\s=>'\"]*([^,}\s'\"]+)/) {
                my $value = $1;
                fsm_debug("        Found is_intermediate='$value' in dump", 3);
                if ($value && $value !~ /^(0|false|no|undef|null)$/i) {
                    fsm_debug("    AST_NAME_METADATA: Signal '$signal_name' has is_intermediate in dump - INTERMEDIATE", 3);
                    return 1;
                }
            } else {
                fsm_debug("        No is_intermediate found in dump", 3);
            }

            fsm_debug("      CHECK #4: Checking for driving_ast property", 3);
            if (blessed($signal) && $signal->can('driving_ast') && $signal->driving_ast) {
                fsm_debug("        Signal has driving_ast", 3);
                my $driving_ast = $signal->driving_ast;
                if (blessed($driving_ast)) {
                    fsm_debug("        AST type: " . ref($driving_ast), 3);
                    my $contains_operators = $ctx->{enable_graph_ast_support}->ast_contains_factorizable_operators($driving_ast);
                    fsm_debug("        Contains factorizable operators: " . ($contains_operators ? "YES" : "NO"), 3);
                    if ($contains_operators) {
                        fsm_debug("    AST_NAME_METADATA: Signal '$signal_name' has driving_ast with operators - INTERMEDIATE", 3);
                        return 1;
                    }
                }
            } else {
                fsm_debug("        Signal doesn't have driving_ast or it's not set", 3);
            }

            if ($signal_name =~ /^or_\d+_\d+$/) {
                fsm_debug("      CHECK #5: Last resort - Signal matches or_* pattern", 3);
                fsm_debug("    AST_NAME_METADATA: Signal '$signal_name' matches or_* pattern - CONSIDERING INTERMEDIATE", 3);
                if (exists $signals->{$signal_name}) {
                    fsm_debug("        Signal exists in fsm_module->signals registry - DEFINITELY INTERMEDIATE", 3);
                    return 1;
                }
            }
        } else {
            fsm_debug("      NOT FOUND: Signal '$signal_name' not found in FSMGenFull signals registry", 3);
        }
    } else {
        fsm_debug("      WARNING: FSM module signals registry is empty or not initialized", 3);
        if (!$ctx->{fsm_module}) {
            fsm_debug("        Reason: fsm_module is not set", 3);
        } elsif (!$ctx->{fsm_module}->can('signals')) {
            fsm_debug("        Reason: fsm_module doesn't have signals method", 3);
        } elsif (!$ctx->{fsm_module}->signals) {
            fsm_debug("        Reason: fsm_module->signals returns empty", 3);
        }
    }

    fsm_debug("    AST_NAME_METADATA: Signal '$signal_name' not found in any registry - NOT intermediate", 3);
    return 0;
}

=head2 clean_signal_name

Normalize one signal-like token into the backend-safe identifier form used by
the current direct enable-family naming rules.

=cut

sub clean_signal_name($self, $name) {
    $name = lc($name);
    $name =~ s/[^a-zA-Z0-9_]/_/g;
    $name =~ s/__+/_/g;
    $name =~ s/^_+//;
    $name =~ s/_+$//;

    if ($name eq '0') {
        return '0';
    } elsif ($name eq '1') {
        return '1';
    }

    $name =~ s/^(\d)/_$1/;
    return $name;
}

=head2 generate_rhs_based_enable_name

Generate the normalized enable-signal name for one LHS/RHS assignment family.

=cut

sub generate_rhs_based_enable_name($self, $lhs, $rhs) {
    my $ctx = $self->{flattened_dt};
    my $clean_lhs = $self->clean_signal_name($lhs);
    my $rhs_suffix;

    if ($rhs =~ /^\d+$/) {
        $rhs_suffix = $rhs;

    } elsif ($rhs =~ /^\d+'[bdhBDH]([0-9a-fA-F_]+)$/) {
        $rhs_suffix = $rhs;
        $rhs_suffix =~ s/'/_/g;
        $rhs_suffix = $self->clean_signal_name($rhs_suffix);

    } elsif ($rhs =~ /^([a-zA-Z_][a-zA-Z0-9_]*)\[(\d+):(\d+)\]$/) {
        my ($signal, $high, $low) = ($1, $2, $3);
        $rhs_suffix = "${signal}_${high}_${low}";

    } elsif ($rhs =~ /^([a-zA-Z_][a-zA-Z0-9_]*)\[(\d+)\]$/) {
        my ($signal, $index) = ($1, $2);
        $rhs_suffix = "${signal}_${index}";

    } elsif ($rhs =~ /^[a-zA-Z_][a-zA-Z0-9_]*$/) {
        $rhs_suffix = $rhs;

    } else {
        my $expr_name = $ctx->{expr_namer}->parse_and_name_expression($rhs);
        $expr_name =~ s/_expr\d*$//;
        $expr_name =~ s/^expr_//;
        $rhs_suffix = $expr_name || "complex";
    }

    $rhs_suffix = $self->clean_signal_name($rhs_suffix);
    return "${clean_lhs}_${rhs_suffix}_en";
}

1;
