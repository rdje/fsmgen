package FSM::Synthesis::EnableGraph::AssignmentSupport;

=head1 NAME

FSM::Synthesis::EnableGraph::AssignmentSupport - Own assignment analysis, mux planning, and assignment emission support for EnableGraph

=head1 DESCRIPTION

This package owns the bounded assignment-analysis and assignment-emission
family that used to live inline inside C<FSM::Synthesis::EnableGraph>. It
centralizes:

=over 4

=item *

unified assignment-analysis construction from captured LHS assignments

=item *

RHS grouping, enable-family shaping, and mux-plan construction

=item *

assignment-family classification and driven-signal discovery

=item *

reset/default/width lookup for prepared direct-backend assignment planning

=item *

final unified mux and delayed-pulse HDL emission

=back

The broader synthesis owner still owns AST capture, AST conversion/rendering,
and WEN/EN emission around this support family.

=cut

use v5.20;
use strict;
use warnings;
use feature qw(signatures);
no warnings 'experimental::signatures';

use FSM::Debug;
use FSM::Package::AggregatePathSupport;
use Scalar::Util qw(blessed);

=head2 new

Construct an assignment-support owner bound to one live
C<FSM::HDL::FlattenedDT> context.

=cut

sub new ($class, %args) {
    my $flattened_dt = $args{flattened_dt}
      or die "[AssignmentSupport.pm][new()] Missing required 'flattened_dt' argument";

    return bless {
        flattened_dt => $flattened_dt,
    }, $class;
}

=head2 build_unified_assignment_analysis

Build the normalized assignment-analysis structure for the current prepared
backend context from the captured LHS assignment registry.

=cut

sub build_unified_assignment_analysis ($self, $fsm_module = undef) {
    my $ctx = $self->{flattened_dt};
    fsm_debug("\n\n*** UNIFIED PHASE 1: BUILDING COMPLETE ASSIGNMENT ANALYSIS (AST WEB) ***", 3);

    for my $lhs_name_key (keys %{$ctx->{all_lhs}}) {
        next unless $ctx->{lhs_assignments}->{$lhs_name_key};

        my $raw_lhs_ast = $ctx->{lhs_ast_map}->{$lhs_name_key};
        my $lhs_ast = $self->normalize_lhs_ast_for_analysis($lhs_name_key, $raw_lhs_ast);
        my $normalized_assignments = $self->normalize_assignments_for_analysis(
            $lhs_name_key,
            $lhs_ast,
            $ctx->{lhs_assignments}->{$lhs_name_key},
        );
        my $lhs_name = blessed($lhs_ast) && $lhs_ast->can('name') ? $lhs_ast->name() : $lhs_name_key;

        fsm_debug("\n=== ANALYZING LHS AST: $lhs_name ===", 3);
        fsm_debug("  Found " . scalar(@{$ctx->{lhs_assignments}->{$lhs_name_key}}) . " captured assignments", 3);
        fsm_debug("  Normalized into " . scalar(@$normalized_assignments) . " assignment families", 3);

        $ctx->{assignment_analysis}->{$lhs_name_key} = {
            assignments => $normalized_assignments,
            rhs_groups => {},
            lhs_ast => $lhs_ast,
            multiplexer => {},
        };

        $self->group_assignments_by_rhs($lhs_name_key);
        $self->generate_complete_enable_structure($lhs_name_key);
        $self->build_multiplexer_config($lhs_name_key);

        fsm_debug("  *** COMPLETED ANALYSIS FOR LHS AST: $lhs_name ***", 3);
    }

    fsm_debug("\n*** UNIFIED PHASE 1 COMPLETE (AST WEB) ***", 3);
}

=head2 normalize_lhs_ast_for_analysis

Normalize one captured LHS AST to the base-signal view used by assignment
analysis and final mux generation.

=cut

sub normalize_lhs_ast_for_analysis ($self, $lhs_name_key, $lhs_ast) {
    return $lhs_ast unless blessed($lhs_ast);

    if ($lhs_ast->isa('FSM::CoreAST::SignalRef') && !$lhs_ast->slice) {
        return $lhs_ast;
    }

    if ($lhs_ast->can('signal') && $lhs_ast->signal) {
        return FSM::CoreAST::SignalRef->new($lhs_ast->signal);
    }

    return $lhs_ast;
}

=head2 normalize_assignments_for_analysis

Collapse same-context partial LHS writes into full-width effective assignment
families before enable generation and mux emission.

=cut

sub normalize_assignments_for_analysis ($self, $lhs_name_key, $lhs_ast, $assignments) {
    return [] unless $assignments && @$assignments;

    my $signal_width = $self->get_target_signal_width($lhs_name_key, $lhs_ast);
    return $assignments unless defined($signal_width) && $signal_width > 0;

    my %group_by_key;
    my @group_order;

    for my $assignment (@$assignments) {
        my $group_key = $self->assignment_context_group_key($assignment);
        if (!exists $group_by_key{$group_key}) {
            $group_by_key{$group_key} = [];
            push @group_order, $group_key;
        }
        push @{$group_by_key{$group_key}}, $assignment;
    }

    my @normalized;
    for my $group_key (@group_order) {
        my $group_assignments = $group_by_key{$group_key};
        push @normalized, $self->materialize_assignment_group(
            $lhs_name_key,
            $lhs_ast,
            $signal_width,
            $group_assignments,
        );
    }

    return \@normalized;
}

=head2 assignment_context_group_key

Build a stable same-context key used to merge partial writes that share one
DT/operator/enable context.

=cut

sub assignment_context_group_key ($self, $assignment) {
    my $condition_key = "1'b1";
    if ($assignment->{conditions_ast} && blessed($assignment->{conditions_ast}) && $assignment->{conditions_ast}->can('to_systemverilog')) {
        $condition_key = $assignment->{conditions_ast}->to_systemverilog();
    }

    return join "\x1E",
        ($assignment->{dt} // ''),
        ($assignment->{operator} // ''),
        ($assignment->{output_exposure} // 'auto'),
        ($assignment->{is_state_trans} ? 1 : 0),
        $condition_key;
}

=head2 materialize_assignment_group

Convert one same-context assignment group into a single full-width effective
assignment, preserving later fragment override order.

=cut

sub materialize_assignment_group ($self, $lhs_name_key, $lhs_ast, $signal_width, $group_assignments) {
    my $first_assignment = $group_assignments->[0];
    my $operator = $first_assignment->{operator} // '=';

    my @segments = ({
        dest_high => $signal_width - 1,
        dest_low => 0,
        source_expr => $self->initial_group_source_expr($lhs_name_key, $lhs_ast, $operator, $signal_width),
        source_natural_width => $signal_width,
        source_high => $signal_width - 1,
        source_low => 0,
    });

    for my $assignment (@$group_assignments) {
        my ($dest_high, $dest_low) = $self->assignment_target_range($assignment->{lhs_ast}, $signal_width);
        my $fragment_width = $dest_high - $dest_low + 1;

        $self->replace_segment_range(
            \@segments,
            $dest_high,
            $dest_low,
            $assignment->{rhs},
            $fragment_width,
        );
    }

    my %normalized = %$first_assignment;
    $normalized{lhs_ast} = $lhs_ast;
    $normalized{rhs} = $self->render_segment_expression(\@segments);
    $normalized{source_provenance} = {
        %{ref($first_assignment->{source_provenance}) eq 'HASH' ? $first_assignment->{source_provenance} : {}},
        partial_write_group_size => scalar(@$group_assignments),
    };
    my $aggregate_contracts = $self->aggregate_assignment_contract_entries($lhs_name_key, $group_assignments);
    $normalized{source_provenance}{aggregate_assignment_contracts} = $aggregate_contracts
        if @$aggregate_contracts;

    return \%normalized;
}

=head2 aggregate_assignment_contract_entries

Preserve raw per-assignment aggregate source/target contracts before partial
LHS writes collapse into one base-signal mux assignment.

=cut

sub aggregate_assignment_contract_entries ($self, $lhs_name_key, $group_assignments) {
    my @contracts;

    for my $assignment (@{$group_assignments || []}) {
        next unless ref($assignment) eq 'HASH';
        my $source_provenance = ref($assignment->{source_provenance}) eq 'HASH'
            ? $assignment->{source_provenance}
            : {};
        my $source_aggregate_type_spec = ref($source_provenance->{aggregate_type_spec}) eq 'HASH'
            ? $source_provenance->{aggregate_type_spec}
            : undef;
        next unless $source_aggregate_type_spec;

        my ($target_type_spec, $target_display) = $self->assignment_target_aggregate_contract(
            $lhs_name_key,
            $assignment->{lhs_ast},
        );
        next unless ref($target_type_spec) eq 'HASH';

        my %entry = (
            source_aggregate_type_spec => FSM::Package::AggregatePathSupport->clone_structured_value($source_aggregate_type_spec),
            target_aggregate_type_spec => FSM::Package::AggregatePathSupport->clone_structured_value($target_type_spec),
            target_display => $target_display,
        );
        $entry{aggregate_symbol_name} = $source_provenance->{aggregate_symbol_name}
            if defined($source_provenance->{aggregate_symbol_name}) && $source_provenance->{aggregate_symbol_name} ne '';
        $entry{raw_value_expr} = $source_provenance->{raw_value_expr}
            if defined($source_provenance->{raw_value_expr}) && $source_provenance->{raw_value_expr} ne '';

        push @contracts, \%entry;
    }

    return \@contracts;
}

=head2 assignment_target_aggregate_contract

Return the declared aggregate target type for one raw LHS AST, including the
leaf contract for C<AggregateRef> partial writes.

=cut

sub assignment_target_aggregate_contract ($self, $lhs_name_key, $lhs_ast) {
    return unless blessed($lhs_ast);

    if ($lhs_ast->isa('FSM::CoreAST::AggregateRef')) {
        my $target_type_spec = $lhs_ast->type_spec;
        my $target_display = eval { $lhs_ast->to_systemverilog } || $lhs_name_key;
        return ($target_type_spec, $target_display);
    }

    return if $lhs_ast->isa('FSM::CoreAST::IndexedRef') || $lhs_ast->isa('FSM::AST::IndexedRef');
    return unless $lhs_ast->isa('FSM::CoreAST::SignalRef') || $lhs_ast->isa('FSM::AST::SignalRef');
    return if $lhs_ast->can('slice') && $lhs_ast->slice;

    my $target_signal = $lhs_ast->can('signal') ? $lhs_ast->signal : undef;
    return unless $target_signal && blessed($target_signal) && $target_signal->can('declared_type_spec');

    my $target_type_spec = $target_signal->declared_type_spec;
    my $target_display = $lhs_ast->can('to_systemverilog') ? eval { $lhs_ast->to_systemverilog } : undef;
    return ($target_type_spec, $target_display || $lhs_name_key);
}

=head2 get_target_signal_width

Resolve the full-width size of one captured LHS signal family.

=cut

sub get_target_signal_width ($self, $lhs_name_key, $lhs_ast) {
    if ($lhs_ast && blessed($lhs_ast) && $lhs_ast->can('signal') && $lhs_ast->signal && $lhs_ast->signal->can('width')) {
        my $width = $lhs_ast->signal->width;
        return $width if defined($width) && $width > 0;
    }

    if ($lhs_ast && blessed($lhs_ast) && $lhs_ast->can('width')) {
        my $width = $lhs_ast->width;
        return $width if defined($width) && $width > 0;
    }

    my $signal_info = $self->get_signal_info($lhs_name_key);
    return $signal_info->{width} if $signal_info && $signal_info->{width};

    return 1;
}

=head2 assignment_target_range

Resolve the base-signal destination range covered by one captured assignment.

=cut

sub assignment_target_range ($self, $lhs_ast, $signal_width) {
    return ($signal_width - 1, 0) unless blessed($lhs_ast);

    if ($lhs_ast->isa('FSM::CoreAST::SignalRef') && $lhs_ast->slice) {
        my ($high, $low) = @{$lhs_ast->slice};
        return ($high, $low);
    }

    if ($lhs_ast->isa('FSM::CoreAST::IndexedRef')) {
        my $index = $lhs_ast->index;
        $index = $index->value if blessed($index) && $index->can('value');
        return ($index, $index) if defined $index && $index =~ /^\d+$/;
    }

    if ($lhs_ast->isa('FSM::CoreAST::AggregateRef')) {
        my ($aggregate_high, $aggregate_low) = $self->aggregate_ref_target_range($lhs_ast);
        return ($aggregate_high, $aggregate_low)
            if defined($aggregate_high) && defined($aggregate_low);
    }

    return ($signal_width - 1, 0);
}

=head2 aggregate_ref_target_range

Resolve one static aggregate member/index reference into the packed base-signal
range it occupies.

=cut

sub aggregate_ref_target_range ($self, $aggregate_ref) {
    return unless blessed($aggregate_ref) && $aggregate_ref->isa('FSM::CoreAST::AggregateRef');

    my $signal = $aggregate_ref->signal;
    my $root_type_spec = $signal && $signal->can('declared_type_spec')
        ? $signal->declared_type_spec
        : undef;
    my $range = FSM::Package::AggregatePathSupport->resolve_packed_range(
        root_type_spec => $root_type_spec,
        path_segments => $aggregate_ref->path,
    );
    return unless $range->{ok};
    return ($range->{high}, $range->{low});
}

=head2 initial_group_source_expr

Return the base full-width source used for untouched bits when one partial
assignment group does not write every bit.

=cut

sub initial_group_source_expr ($self, $lhs_name_key, $lhs_ast, $operator, $signal_width) {
    my $ctx = $self->{flattened_dt};

    if ($operator eq '<=' || $operator eq '<=-' || $operator eq '<=+') {
        return "${lhs_name_key}_q";
    }

    if ($operator eq '=') {
        my $default_value = $ctx->{enable_graph_signal_support}->get_default_value_from_ast($lhs_ast);
        if (defined($default_value) && $default_value ne $lhs_name_key) {
            return $default_value;
        }
        return $self->zero_literal_for_width($signal_width);
    }

    return $lhs_name_key;
}

=head2 zero_literal_for_width

Render a sized zero literal suitable for untouched combinational bits.

=cut

sub zero_literal_for_width ($self, $signal_width) {
    return "1'b0" if !defined($signal_width) || $signal_width <= 1;
    return "${signal_width}'b" . ('0' x $signal_width);
}

=head2 normalize_reset_literal_for_width

Render common scalar reset literals with the target width so generated flops
do not rely on implicit widening.

=cut

sub normalize_reset_literal_for_width ($self, $reset_value, $signal_width) {
    return $reset_value unless defined($reset_value);
    return $reset_value unless defined($signal_width) && $signal_width > 1;

    return $self->zero_literal_for_width($signal_width)
        if $reset_value =~ /^(?:0|1'b0|1'd0|1'h0)\z/i;
    return "${signal_width}'d1"
        if $reset_value =~ /^(?:1|1'b1|1'd1|1'h1)\z/i;

    return $reset_value;
}

=head2 replace_segment_range

Replace one destination range inside a descending segment map with a new source
expression segment.

=cut

sub replace_segment_range ($self, $segments, $dest_high, $dest_low, $source_expr, $source_width) {
    my (@before, @after);

    for my $segment (@$segments) {
        if ($segment->{dest_low} > $dest_high) {
            push @before, $segment;
            next;
        }
        if ($segment->{dest_high} < $dest_low) {
            push @after, $segment;
            next;
        }

        if ($segment->{dest_high} > $dest_high) {
            push @before, $self->segment_subrange($segment, $segment->{dest_high}, $dest_high + 1);
        }

        if ($segment->{dest_low} < $dest_low) {
            push @after, $self->segment_subrange($segment, $dest_low - 1, $segment->{dest_low});
        }
    }

    my $replacement = {
        dest_high => $dest_high,
        dest_low => $dest_low,
        source_expr => $source_expr,
        source_natural_width => $source_width,
        source_high => $source_width - 1,
        source_low => 0,
    };

    @$segments = (@before, $replacement, @after);
}

=head2 segment_subrange

Build one derived subsegment that preserves the original source-to-destination
bit mapping.

=cut

sub segment_subrange ($self, $segment, $new_dest_high, $new_dest_low) {
    my $new_source_low = $segment->{source_low} + ($new_dest_low - $segment->{dest_low});
    my $new_source_high = $new_source_low + ($new_dest_high - $new_dest_low);

    return {
        %$segment,
        dest_high => $new_dest_high,
        dest_low => $new_dest_low,
        source_high => $new_source_high,
        source_low => $new_source_low,
    };
}

=head2 render_segment_expression

Render one descending segment map back into a full-width SystemVerilog
expression.

=cut

sub render_segment_expression ($self, $segments) {
    my @parts = map { $self->render_segment_source($_) } @$segments;
    return $parts[0] if @parts == 1;
    return '{' . join(', ', @parts) . '}';
}

=head2 render_segment_source

Render one segment's source expression, slicing it when the segment only uses
part of the source expression.

=cut

sub render_segment_source ($self, $segment) {
    my $segment_width = $segment->{dest_high} - $segment->{dest_low} + 1;
    my $source_width = $segment->{source_high} - $segment->{source_low} + 1;

    if ($segment->{source_low} == 0
            && $segment->{source_high} == $segment->{source_natural_width} - 1
            && $segment_width == $source_width)
    {
        return $segment->{source_expr};
    }

    if ($self->source_expr_is_all_zero_literal($segment->{source_expr})) {
        return $self->zero_literal_for_width($segment_width);
    }

    my $wrapped_expr = $self->wrap_sv_expr_for_select($segment->{source_expr});
    if ($segment->{source_high} == $segment->{source_low}) {
        return "${wrapped_expr}[$segment->{source_high}]";
    }
    return "${wrapped_expr}[$segment->{source_high}:$segment->{source_low}]";
}

sub source_expr_is_all_zero_literal ($self, $expr) {
    return 0 unless defined($expr) && $expr ne '';
    my $normalized = $expr;
    $normalized =~ s/\s+//g;
    return 1 if $normalized =~ /^\d+'[bB]0+$/;
    return 1 if $normalized =~ /^\d+'[dDhH]0+$/;
    return 1 if $normalized eq '0';
    return 0;
}

=head2 wrap_sv_expr_for_select

Parenthesize complex expressions before applying a bit-select or part-select.

=cut

sub wrap_sv_expr_for_select ($self, $expr) {
    return $expr if $expr =~ /^[a-zA-Z_][a-zA-Z0-9_]*$/;
    return "($expr)";
}

=head2 group_assignments_by_rhs

Group the captured assignments for one LHS into stable RHS families inside the
prepared assignment-analysis structure.

=cut

sub group_assignments_by_rhs ($self, $lhs) {
    my $ctx = $self->{flattened_dt};
    my $lhs_analysis = $ctx->{assignment_analysis}->{$lhs};

    fsm_debug("  [AssignmentSupport.pm][group_assignments_by_rhs()] Grouping assignments by RHS value:", 3);

    for my $assignment (@{$lhs_analysis->{assignments}}) {
        my $rhs = $assignment->{rhs};
        my $dt = $assignment->{dt};
        my $conditions = $assignment->{conditions} || 'NONE';
        my $conditions_ast = $assignment->{conditions_ast};

        unless (exists $lhs_analysis->{rhs_groups}->{$rhs}) {
            $lhs_analysis->{rhs_groups}->{$rhs} = {
                assignments => [],
                dt_specific_enables => [],
                lhs_level_enable => undef,
                multiplexer_info => undef,
            };
        }

        push @{$lhs_analysis->{rhs_groups}->{$rhs}->{assignments}}, $assignment;

        my $debug_condition = $conditions;
        if ($conditions_ast && blessed($conditions_ast) && $conditions_ast->can('to_systemverilog')) {
            $debug_condition = $conditions_ast->to_systemverilog();
        }
        fsm_debug("    [AssignmentSupport.pm] RHS '$rhs' from DT '$dt' with condition '$debug_condition'", 3);
    }

    my $rhs_count = scalar(keys %{$lhs_analysis->{rhs_groups}});
    fsm_debug("  [AssignmentSupport.pm] Grouped into $rhs_count unique RHS values", 3);
}

=head2 generate_complete_enable_structure

Build DT-local enable families and LHS-level grouped enables for one analyzed
LHS signal.

=cut

sub generate_complete_enable_structure ($self, $lhs) {
    my $ctx = $self->{flattened_dt};
    my $signal_support = $ctx->{enable_graph_signal_support};
    my $lhs_analysis = $ctx->{assignment_analysis}->{$lhs};

    fsm_debug("  [AssignmentSupport.pm][generate_complete_enable_structure()] Generating complete enable structure:", 3);

    my %dt_assignments;
    for my $assignment (@{$lhs_analysis->{assignments}}) {
        my $dt_name = $assignment->{dt};
        my $rhs = $assignment->{rhs};

        $dt_assignments{$dt_name} //= {};
        $dt_assignments{$dt_name}{$rhs} //= [];
        push @{$dt_assignments{$dt_name}{$rhs}}, $assignment;
    }

    for my $dt_name (sort keys %dt_assignments) {
        my $clean_dt_name = $dt_name;
        $clean_dt_name =~ s/^-//;

        my $dt_enable;
        if ($ctx->{state_enables}->{$dt_name}) {
            $dt_enable = "${dt_name}_en";
        } elsif ($ctx->{dt_enables}->{$dt_name}) {
            $dt_enable = "${clean_dt_name}_en";
        } else {
            $dt_enable = "1'b1";
        }

        for my $rhs (sort keys %{$dt_assignments{$dt_name}}) {
            my $assignments = $dt_assignments{$dt_name}{$rhs};

            my @condition_asts;
            for my $assignment (@$assignments) {
                push @condition_asts, $assignment->{conditions_ast} if $assignment->{conditions_ast};
            }

            my $or_tree_of_conditions_ast;
            if (!@condition_asts) {
                $or_tree_of_conditions_ast = FSM::AST::Utils::literal("1'b1");
            } elsif (@condition_asts == 1) {
                $or_tree_of_conditions_ast = $condition_asts[0];
            } else {
                $or_tree_of_conditions_ast = FSM::AST::Utils::or_tree(@condition_asts);
            }

            my $dt_enable_ast = FSM::AST::Utils::signal_ref($dt_enable);
            my $complete_enable_ast = FSM::AST::Utils::and_op($dt_enable_ast, $or_tree_of_conditions_ast);

            my $clean_rhs = $signal_support->clean_signal_name($rhs);
            my $clean_lhs = $signal_support->clean_signal_name($lhs);
            my $dt_enable_name = "${clean_dt_name}_${clean_lhs}_${clean_rhs}_en";

            my $dt_enable_info = {
                dt => $dt_name,
                enable_name => $dt_enable_name,
                enable_ast => $complete_enable_ast,
                shared_signal => undef,
            };

            push @{$lhs_analysis->{rhs_groups}->{$rhs}->{dt_specific_enables}}, $dt_enable_info;

            my $debug_expr = $complete_enable_ast->to_systemverilog();
            fsm_debug("    [AssignmentSupport.pm] DT-specific enable: $dt_enable_name = $debug_expr", 3);
        }
    }

    for my $rhs (sort keys %{$lhs_analysis->{rhs_groups}}) {
        my $rhs_group = $lhs_analysis->{rhs_groups}->{$rhs};

        my @dt_enable_asts;
        for my $dt_enable_info (@{$rhs_group->{dt_specific_enables}}) {
            push @dt_enable_asts, FSM::AST::Utils::signal_ref($dt_enable_info->{enable_name});
        }

        my $lhs_enable_ast;
        if (@dt_enable_asts == 1) {
            $lhs_enable_ast = $dt_enable_asts[0];
        } else {
            $lhs_enable_ast = FSM::AST::Utils::or_tree(@dt_enable_asts);
        }

        my $lhs_enable_name = $signal_support->generate_rhs_based_enable_name($lhs, $rhs);

        $rhs_group->{lhs_level_enable} = {
            name => $lhs_enable_name,
            ast => $lhs_enable_ast,
            rhs_value => $rhs,
        };

        my $debug_expr = blessed($lhs_enable_ast) && $lhs_enable_ast->can('to_systemverilog')
            ? $lhs_enable_ast->to_systemverilog()
            : 'UNAVAILABLE';
        fsm_debug("    [AssignmentSupport.pm] LHS-level enable: $lhs_enable_name = $debug_expr", 3);
    }
}

=head2 build_multiplexer_config

Build the normalized mux configuration for one analyzed LHS signal.

=cut

sub build_multiplexer_config ($self, $lhs) {
    my $ctx = $self->{flattened_dt};
    my $signal_support = $ctx->{enable_graph_signal_support};
    my $lhs_analysis = $ctx->{assignment_analysis}->{$lhs};
    my $lhs_ast = $lhs_analysis->{lhs_ast};
    my $lhs_name = blessed($lhs_ast) && $lhs_ast->can('name') ? $lhs_ast->name() : 'UNKNOWN';

    my @mux_enables = ();
    my $priority = 0;

    for my $rhs (sort keys %{$lhs_analysis->{rhs_groups}}) {
        my $rhs_group = $lhs_analysis->{rhs_groups}->{$rhs};
        my $lhs_enable = $rhs_group->{lhs_level_enable};

        $rhs_group->{multiplexer_info} = {
            enable_signal => $lhs_enable->{name},
            rhs_value => $rhs,
            priority => $priority++,
        };

        push @mux_enables, $rhs_group->{multiplexer_info};
    }

    my $is_register = $self->is_register($lhs_ast, $lhs_name);
    my $mux_type = $is_register ? 'flop' : 'comb';
    my $default_value = $signal_support->get_default_value_from_ast($lhs_ast);

    $lhs_analysis->{multiplexer} = {
        type => $mux_type,
        enables => \@mux_enables,
        default_value => $default_value,
    };

    fsm_debug("  [AssignmentSupport.pm][build_multiplexer_config()] Multiplexer: type=$lhs_analysis->{multiplexer}->{type}, " . scalar(@mux_enables) . " enables", 3);
}

=head2 generate_signal_assignments

Emit the unified mux and delayed-pulse HDL block from the prepared
assignment-analysis structure.

=cut

sub generate_signal_assignments ($self, $fsm_module = undef) {
    my $ctx = $self->{flattened_dt};
    my $hdl = "\n  // Unified Multiplexer Logic from Phase 1 Analysis\n";

    fsm_debug("\n\n*** UNIFIED PHASE 3: GENERATING MULTIPLEXERS FROM ANALYSIS ***", 3);

    for my $lhs (sort keys %{$ctx->{assignment_analysis}}) {
        my $lhs_analysis = $ctx->{assignment_analysis}->{$lhs};
        my $multiplexer = $lhs_analysis->{multiplexer};
        my $assignment_type = $self->get_signal_assignment_type($lhs, $lhs_analysis);

        $hdl .= "\n  // Unified Multiplexer for LHS: $lhs\n";

        if ($assignment_type eq 'pulse_delayed') {
            $hdl .= $self->generate_unified_pulse_delay_logic($lhs, $lhs_analysis);
        } elsif ($multiplexer->{type} eq 'flop') {
            $hdl .= $self->generate_unified_flop_mux($lhs, $lhs_analysis);
        } else {
            $hdl .= $self->generate_unified_comb_mux($lhs, $lhs_analysis);
        }

        fsm_debug("  Generated unified multiplexer for $lhs (type: $multiplexer->{type}, assignment_type: $assignment_type)", 3);
    }

    fsm_debug("*** UNIFIED PHASE 3 COMPLETE ***", 3);
    return $hdl;
}

=head2 generate_unified_pulse_delay_logic

Emit the delayed-pulse runtime block for one pulse-delayed LHS family.

=cut

sub generate_unified_pulse_delay_logic ($self, $lhs, $lhs_analysis) {
    my $ctx = $self->{flattened_dt};
    my $lhs_ast = $lhs_analysis->{lhs_ast};
    my $lhs_name = blessed($lhs_ast) && $lhs_ast->can('name') ? $lhs_ast->name() : $lhs;
    my $delay_cycles = $self->get_pulse_delay_cycles_for_lhs($lhs, $lhs_analysis);
    my $active_level = $self->get_pulse_active_level_for_lhs($lhs, $lhs_analysis);
    my $rest_level = $active_level ? "1'b0" : "1'b1";
    my $pulse_level = $active_level ? "1'b1" : "1'b0";
    my $width = $self->get_lhs_width_from_analysis($lhs_analysis);

    if ($width != 1) {
        die "[AssignmentSupport.pm][generate_unified_pulse_delay_logic()] Delayed pulse target '$lhs_name' must be 1-bit, got width '$width'";
    }

    my @request_signals = map { $_->{enable_signal} } @{$lhs_analysis->{multiplexer}->{enables} || []};
    my $request_expr = @request_signals ? join(' | ', @request_signals) : "1'b0";
    my $event_control = $ctx->{enable_graph_module_planning_support}->sequential_event_control();
    my $reset_condition = $ctx->{enable_graph_module_planning_support}->reset_condition_expr();

    my $hdl = "  // Delayed pulse logic for: $lhs_name (<$delay_cycles, exact Q+$delay_cycles)\n";

    if ($delay_cycles == 0) {
        $hdl .= "  always_ff @($event_control) begin\n";
        $hdl .= "    if ($reset_condition) begin\n";
        $hdl .= "      $lhs_name <= $rest_level;\n";
        $hdl .= "    end else begin\n";
        $hdl .= "      $lhs_name <= ($request_expr) ? $pulse_level : $rest_level;\n";
        $hdl .= "    end\n";
        $hdl .= "  end\n";
        return $hdl;
    }

    my $pipe_name = "${lhs_name}_pulse_delay_pipe";
    my $pipe_tap = $delay_cycles == 1 ? $pipe_name : "${pipe_name}[" . ($delay_cycles - 1) . "]";
    my $shift_rhs = $delay_cycles == 1
        ? $request_expr
        : "{${pipe_name}[" . ($delay_cycles - 2) . ":0], $request_expr}";
    my $pipe_reset = $delay_cycles == 1
        ? "1'b0"
        : '{' . $delay_cycles . "{1'b0}}";

    $hdl .= "  always_ff @($event_control) begin\n";
    $hdl .= "    if ($reset_condition) begin\n";
    $hdl .= "      $lhs_name <= $rest_level;\n";
    $hdl .= "      $pipe_name <= $pipe_reset;\n";
    $hdl .= "    end else begin\n";
    $hdl .= "      $lhs_name <= $rest_level;\n";
    $hdl .= "      if ($pipe_tap) begin\n";
    $hdl .= "        $lhs_name <= $pulse_level;\n";
    $hdl .= "      end\n";
    $hdl .= "      $pipe_name <= $shift_rhs;\n";
    $hdl .= "    end\n";
    $hdl .= "  end\n";

    return $hdl;
}

=head2 get_pulse_delay_cycles_for_lhs

Return the unique pulse-delay cycle count for one analyzed pulse-delayed LHS
family.

=cut

sub get_pulse_delay_cycles_for_lhs ($self, $lhs, $lhs_analysis) {
    my %delay_values;
    for my $assignment (@{$lhs_analysis->{assignments} || []}) {
        my $op = $assignment->{operator} // '';
        if ($op =~ /^<(\d+)$/) {
            $delay_values{$1} = 1;
            next;
        }
        my $intent = $assignment->{assignment_intent};
        if (ref($intent) eq 'HASH' && defined($intent->{pulse_delay_cycles})) {
            $delay_values{$intent->{pulse_delay_cycles}} = 1;
        }
    }
    my @delays = sort { $a <=> $b } keys %delay_values;
    if (!@delays) {
        die "[AssignmentSupport.pm][get_pulse_delay_cycles_for_lhs()] Missing pulse delay metadata for LHS '$lhs'";
    }
    if (@delays > 1) {
        die "[AssignmentSupport.pm][get_pulse_delay_cycles_for_lhs()] Multiple pulse delays for LHS '$lhs' are unsupported: " . join(', ', @delays);
    }
    return $delays[0];
}

=head2 get_pulse_active_level_for_lhs

Return the unique active level for one analyzed pulse-delayed LHS family.

=cut

sub get_pulse_active_level_for_lhs ($self, $lhs, $lhs_analysis) {
    my %active_levels;
    for my $assignment (@{$lhs_analysis->{assignments} || []}) {
        my $intent = $assignment->{assignment_intent};
        if (ref($intent) eq 'HASH' && defined($intent->{pulse_active_level})) {
            $active_levels{int($intent->{pulse_active_level} ? 1 : 0)} = 1;
            next;
        }
        my $rhs = $assignment->{rhs};
        my $normalized = $self->normalize_rhs_logic_level($rhs);
        if (defined $normalized) {
            $active_levels{$normalized} = 1;
        }
    }
    my @levels = sort { $a <=> $b } keys %active_levels;
    if (!@levels) {
        die "[AssignmentSupport.pm][get_pulse_active_level_for_lhs()] Missing pulse active level metadata for LHS '$lhs'";
    }
    if (@levels > 1) {
        die "[AssignmentSupport.pm][get_pulse_active_level_for_lhs()] Conflicting pulse active levels for LHS '$lhs': " . join(', ', @levels);
    }
    return $levels[0];
}

=head2 normalize_rhs_logic_level

Normalize one scalar RHS token into a logic level when it clearly represents
`0` or `1`.

=cut

sub normalize_rhs_logic_level ($self, $rhs) {
    return undef unless defined $rhs;
    return 0 if $rhs =~ /^(?:0|1'b0|1'd0|1'h0)$/i;
    return 1 if $rhs =~ /^(?:1|1'b1|1'd1|1'h1)$/i;
    return undef;
}

=head2 generate_unified_flop_mux

Emit the sequential mux/runtime block for one analyzed flop-backed LHS family.

=cut

sub generate_unified_flop_mux ($self, $lhs, $lhs_analysis) {
    my $ctx = $self->{flattened_dt};
    my $signal_support = $ctx->{enable_graph_signal_support};
    my $lhs_ast = $lhs_analysis->{lhs_ast};
    my $lhs_name = blessed($lhs_ast) && $lhs_ast->can('name') ? $lhs_ast->name() : 'UNKNOWN';
    my $event_control = $ctx->{enable_graph_module_planning_support}->sequential_event_control();
    my $reset_condition = $ctx->{enable_graph_module_planning_support}->reset_condition_expr();
    my $assignment_type = $self->get_signal_assignment_type($lhs, $lhs_analysis);
    my $enable_graph = $ctx->{enable_graph};

    my $hdl = "  // Unified flop with mux for: $lhs_name ($assignment_type assignment)\n";

    if ($assignment_type eq 'register_out' || $assignment_type eq 'register_out_dual') {
        my $emit_next_output = ($assignment_type eq 'register_out_dual') ? 1 : 0;
        my $next_output_name = "next_${lhs_name}";

        $hdl .= "  always_comb begin\n";
        $hdl .= "    ${lhs_name}_next = $lhs_analysis->{multiplexer}->{default_value};  // Default value\n";

        for my $enable_info (@{$lhs_analysis->{multiplexer}->{enables}}) {
            my $enable_signal = $enable_info->{enable_signal};
            my $rhs_value = $enable_info->{rhs_value};

            $hdl .= "    if ($enable_signal) begin\n";
            $hdl .= "      ${lhs_name}_next = $rhs_value;\n";
            $hdl .= "    end\n";

            fsm_debug("    Unified flop mux (<-): $enable_signal -> $rhs_value", 3);
        }

        if ($emit_next_output) {
            $hdl .= "    $next_output_name = ${lhs_name}_next;\n";
            fsm_debug("    Unified flop mux (<-=): exposing '$next_output_name'", 3);
        }

        $hdl .= "  end\n";

        my $reset_value = $self->normalize_reset_literal_for_width(
            $signal_support->get_reset_value_from_ast($lhs_ast),
            $self->get_lhs_width_from_analysis($lhs_analysis),
        );

        $hdl .= "  always_ff @($event_control) begin\n";
        $hdl .= "    if ($reset_condition) begin\n";
        $hdl .= "      $lhs_name <= $reset_value;\n";
        $hdl .= "    end else begin\n";
        $hdl .= "      $lhs_name <= ${lhs_name}_next;\n";
        $hdl .= "    end\n";
        $hdl .= "  end\n";

    } elsif ($assignment_type eq 'register_in' || $assignment_type eq 'register_in_dual') {
        my $emit_q_output = ($assignment_type eq 'register_in_dual') ? 1 : 0;
        my $q_output_name = "${lhs_name}_r";

        $hdl .= "  always_comb begin\n";
        $hdl .= "    $lhs_name = ${lhs_name}_q;  // Default value is feedback from flop output\n";
        if ($emit_q_output) {
            $hdl .= "    $q_output_name = ${lhs_name}_q;\n";
        }

        for my $enable_info (@{$lhs_analysis->{multiplexer}->{enables}}) {
            my $enable_signal = $enable_info->{enable_signal};
            my $rhs_value = $enable_info->{rhs_value};

            $hdl .= "    if ($enable_signal) begin\n";
            $hdl .= "      $lhs_name = $rhs_value;\n";
            $hdl .= "    end\n";

            fsm_debug("    Unified flop mux (<=): $enable_signal -> $rhs_value", 3);
        }

        $hdl .= "  end\n";

        my $reset_value = $self->normalize_reset_literal_for_width(
            $signal_support->get_reset_value_from_ast($lhs_ast),
            $self->get_lhs_width_from_analysis($lhs_analysis),
        );

        $hdl .= "  always_ff @($event_control) begin\n";
        $hdl .= "    if ($reset_condition) begin\n";
        $hdl .= "      ${lhs_name}_q <= $reset_value;\n";
        $hdl .= "    end else begin\n";
        $hdl .= "      ${lhs_name}_q <= $lhs_name;\n";
        $hdl .= "    end\n";
        $hdl .= "  end\n";
    } else {
        die "[AssignmentSupport.pm][generate_unified_flop_mux()] Unsupported flop assignment_type '$assignment_type' for LHS '$lhs_name'";
    }

    return $hdl;
}

=head2 generate_unified_comb_mux

Emit the combinational mux/runtime block for one analyzed combinational LHS
family.

=cut

sub generate_unified_comb_mux ($self, $lhs, $lhs_analysis) {
    my $multiplexer = $lhs_analysis->{multiplexer};
    my $default_value = $multiplexer->{default_value};
    my $signal_width = $self->get_lhs_width_from_analysis($lhs_analysis);

    my $hdl = "  // Unified combinational mux for: $lhs\n";
    $hdl .= "  always_comb begin\n";
    my $safe_default = (
        defined($default_value)
        && $default_value ne ''
        && $default_value ne $lhs
    )
        ? $default_value
        : $self->zero_literal_for_width($signal_width);
    $hdl .= "    $lhs = $safe_default;  // Default value\n";

    for my $enable_info (@{$multiplexer->{enables}}) {
        my $enable_signal = $enable_info->{enable_signal};
        my $rhs_value = $enable_info->{rhs_value};

        $hdl .= "    if ($enable_signal) begin\n";
        $hdl .= "      $lhs = $rhs_value;\n";
        $hdl .= "    end\n";

        fsm_debug("    Unified comb mux: $enable_signal -> $rhs_value", 3);
    }

    $hdl .= "  end\n";
    return $hdl;
}

=head2 get_signal_assignment_type

Classify one analyzed LHS family into its normalized assignment contract.

=cut

sub get_signal_assignment_type ($self, $lhs, $lhs_analysis) {
    my $assignments = $lhs_analysis->{assignments};
    unless ($assignments && @$assignments) {
        fsm_debug("WARNING: No assignments found for LHS '$lhs', defaulting to 'mux_out'", 3);
        return 'mux_out';
    }

    my $has_register_assignment = 0;
    my $has_flop_assignment = 0;
    my $has_register_dual_assignment = 0;
    my $has_flop_dual_assignment = 0;
    my $has_comb_assignment = 0;
    my $has_pulse_assignment = 0;
    my %pulse_delays;

    for my $assignment (@$assignments) {
        my $operator = $assignment->{operator};
        if (!defined($operator) || $operator eq '') {
            die "[AssignmentSupport.pm][get_signal_assignment_type()] Missing operator in assignment analysis for LHS '$lhs'";
        }

        if ($operator eq '<-') {
            $has_register_assignment = 1;
        } elsif ($operator eq '<=') {
            $has_flop_assignment = 1;
        } elsif ($operator eq '<-=') {
            $has_register_dual_assignment = 1;
        } elsif ($operator eq '<=-' || $operator eq '<=+') {
            $has_flop_dual_assignment = 1;
        } elsif ($operator eq '=') {
            $has_comb_assignment = 1;
        } elsif ($operator =~ /^<(\d+)$/) {
            $has_pulse_assignment = 1;
            $pulse_delays{$1} = 1;
        } else {
            die "[AssignmentSupport.pm][get_signal_assignment_type()] Unsupported operator '$operator' in assignment analysis for LHS '$lhs'";
        }
    }

    my $sequential_family_count = 0;
    $sequential_family_count++ if $has_register_assignment;
    $sequential_family_count++ if $has_flop_assignment;
    $sequential_family_count++ if $has_register_dual_assignment;
    $sequential_family_count++ if $has_flop_dual_assignment;
    $sequential_family_count++ if $has_pulse_assignment;

    if ($has_comb_assignment && $sequential_family_count > 0) {
        die "[AssignmentSupport.pm][get_signal_assignment_type()] Mixed combinational '=' and sequential operators for LHS '$lhs' is unsupported";
    }

    if (keys(%pulse_delays) > 1) {
        die "[AssignmentSupport.pm][get_signal_assignment_type()] Multiple pulse delays for LHS '$lhs' are unsupported: " . join(', ', sort keys %pulse_delays);
    }

    if ($has_pulse_assignment && ($has_register_assignment || $has_flop_assignment || $has_register_dual_assignment || $has_flop_dual_assignment)) {
        die "[AssignmentSupport.pm][get_signal_assignment_type()] Mixed pulse-delayed and non-pulse sequential operators for LHS '$lhs' is unsupported";
    }

    if ($has_register_dual_assignment) {
        if ($has_flop_assignment || $has_flop_dual_assignment) {
            die "[AssignmentSupport.pm][get_signal_assignment_type()] Mixed '<-=' with '<='/'<=-'/'<=+' for LHS '$lhs' is unsupported";
        }
        return 'register_out_dual';
    }
    if ($has_flop_dual_assignment) {
        if ($has_register_assignment || $has_register_dual_assignment) {
            die "[AssignmentSupport.pm][get_signal_assignment_type()] Mixed '<=-'/'<=+' with '<-'/'<-=' for LHS '$lhs' is unsupported";
        }
        return 'register_in_dual';
    }
    if ($has_pulse_assignment) {
        return 'pulse_delayed';
    }
    if ($has_register_assignment) {
        return 'register_out';
    }
    if ($has_flop_assignment) {
        return 'register_in';
    }
    return 'mux_out';
}

=head2 get_driven_signals

Return the current normalized driven-signal set, including auxiliary outputs
for dual sequential assignment families.

=cut

sub get_driven_signals ($self) {
    my $ctx = $self->{flattened_dt};
    my %driven_signals;

    for my $lhs (keys %{$ctx->{all_lhs}}) {
        $driven_signals{$lhs} = 1;
        fsm_debug("[AssignmentSupport.pm][get_driven_signals()] DRIVEN_SIGNALS: '$lhs' is driven by FSM logic", 3);
    }

    for my $lhs (keys %{$ctx->{assignment_analysis} || {}}) {
        my $lhs_analysis = $ctx->{assignment_analysis}{$lhs};
        next unless $lhs_analysis;
        my $assignment_type = $self->get_signal_assignment_type($lhs, $lhs_analysis);

        if ($assignment_type eq 'register_out_dual') {
            my $next_name = "next_$lhs";
            $driven_signals{$next_name} = 1;
            fsm_debug("[AssignmentSupport.pm][get_driven_signals()] DRIVEN_SIGNALS: '$next_name' is driven by rm auxiliary output logic", 3);
        } elsif ($assignment_type eq 'register_in_dual') {
            my $q_name = "${lhs}_r";
            $driven_signals{$q_name} = 1;
            fsm_debug("[AssignmentSupport.pm][get_driven_signals()] DRIVEN_SIGNALS: '$q_name' is driven by mr auxiliary output logic", 3);
        }
    }

    return %driven_signals;
}

=head2 get_reset_value

Return the normalized reset value for one named backend LHS signal.

=cut

sub get_reset_value ($self, $lhs) {
    my $ctx = $self->{flattened_dt};

    fsm_debug("GET_RESET_VALUE: Determining reset value for LHS '$lhs'", 3);

    if ($lhs eq 'next_state') {
        my $reset_state = $self->get_fsm_reset_state();
        fsm_debug("GET_RESET_VALUE: State variable '$lhs' -> reset to '$reset_state'", 3);
        return $reset_state;
    }

    my $explicit_reset = $self->get_explicit_reset_value($lhs);
    if (defined $explicit_reset) {
        fsm_debug("GET_RESET_VALUE: Explicit reset for '$lhs' -> '$explicit_reset'", 3);
        return $explicit_reset;
    }

    my $signal_info = $self->get_signal_info($lhs);
    if ($signal_info && $signal_info->{width}) {
        my $width = $signal_info->{width};
        if ($width > 1) {
            my $reset_val = sprintf("%d'h%s", $width, "0" x int(($width + 3) / 4));
            fsm_debug("GET_RESET_VALUE: Multi-bit signal '$lhs' ($width bits) -> '$reset_val'", 3);
            return $reset_val;
        }
    }

    fsm_debug("GET_RESET_VALUE: Default single-bit reset for '$lhs' -> '1'b0'", 3);
    return "1'b0";
}

=head2 get_default_value

Return the normalized default/feedback value for one named backend LHS signal.

=cut

sub get_default_value ($self, $lhs) {
    return "current_state" if $lhs eq 'next_state';
    return $lhs;
}

=head2 get_fsm_reset_state

Return the normalized FSM reset-state token for the prepared backend context.

=cut

sub get_fsm_reset_state ($self) {
    my $ctx = $self->{flattened_dt};

    if ($ctx->{fsm_module}) {
        my $state_plan = $ctx->{enable_graph_module_planning_support}->build_state_register_plan($ctx->{fsm_module});
        if ($state_plan->{has_state_registers}) {
            my $reset_state = $state_plan->{reset_state_name};
            fsm_debug("FSM_RESET_STATE: Using first state as reset: '$reset_state'", 3);
            return $reset_state;
        }
    }

    fsm_debug("FSM_RESET_STATE: Defaulting to IDLE", 3);
    return "IDLE";
}

=head2 get_explicit_reset_value

Return the explicit reset value for one named LHS when the prepared backend
context carries such metadata.

=cut

sub get_explicit_reset_value ($self, $lhs) {
    my $ctx = $self->{flattened_dt};

    fsm_debug("EXPLICIT_RESET: Checking for explicit reset value for '$lhs'", 3);

    if ($ctx->{explicit_reset_values} && $ctx->{explicit_reset_values}{$lhs}) {
        my $reset_val = $ctx->{explicit_reset_values}{$lhs};
        fsm_debug("EXPLICIT_RESET: Found configured reset for '$lhs' -> '$reset_val'", 3);
        return $reset_val;
    }

    if ($ctx->{fsm_module} && $ctx->{fsm_module}->signals) {
        my $signals = $ctx->{fsm_module}->signals;
        if ($signals->{$lhs}) {
            my $signal = $signals->{$lhs};

            if ($signal->can('attributes') && $signal->attributes && $signal->attributes->{reset_value}) {
                my $reset_val = $signal->attributes->{reset_value};
                fsm_debug("EXPLICIT_RESET: Found signal attribute reset for '$lhs' -> '$reset_val'", 3);
                return $reset_val;
            }

            if ($signal->can('reset_value')) {
                my $reset_val = $signal->reset_value;
                if (defined $reset_val) {
                    fsm_debug("EXPLICIT_RESET: Found signal method reset for '$lhs' -> '$reset_val'", 3);
                    return $reset_val;
                }
            }
        }
    }

    fsm_debug("EXPLICIT_RESET: No explicit reset value found for '$lhs'", 3);
    return undef;
}

=head2 get_signal_info

Return normalized signal metadata from the prepared FSM module for one named
backend signal.

=cut

sub get_signal_info ($self, $lhs) {
    my $ctx = $self->{flattened_dt};

    fsm_debug("SIGNAL_INFO: Getting info for '$lhs'", 3);

    if ($ctx->{fsm_module} && $ctx->{fsm_module}->signals) {
        my $signals = $ctx->{fsm_module}->signals;
        if ($signals->{$lhs}) {
            my $signal = $signals->{$lhs};
            my $signal_info = {};

            if ($signal->can('width')) {
                my $width = $signal->width;
                if ($width && $width > 0) {
                    $signal_info->{width} = $width;
                    fsm_debug("SIGNAL_INFO: Found width for '$lhs' -> $width", 3);
                } else {
                    fsm_debug("SIGNAL_INFO: Width method returned invalid value for '$lhs'", 3);
                }
            } else {
                fsm_debug("SIGNAL_INFO: No width method for '$lhs'", 3);
            }

            return $signal_info if %$signal_info;
        } else {
            fsm_debug("SIGNAL_INFO: Signal '$lhs' not found in FSM signals", 3);
        }
    } else {
        fsm_debug("SIGNAL_INFO: No FSM module or signals available", 3);
    }

    return undef;
}

=head2 get_lhs_width_from_analysis

Return the normalized signal width for one prepared assignment-analysis entry.

=cut

sub get_lhs_width_from_analysis ($self, $lhs_analysis) {
    my $width;
    my $lhs_ast = $lhs_analysis->{lhs_ast};

    if ($lhs_analysis->{signal_info} && $lhs_analysis->{signal_info}->{width}) {
        my $signal_width = $lhs_analysis->{signal_info}->{width};
        if (defined($signal_width) && $signal_width > 0) {
            $width = $signal_width;
        }
    }

    if ($lhs_ast && blessed($lhs_ast)) {
        if ((!defined($width) || $width < 1) && $lhs_ast->can('signal') && $lhs_ast->signal && $lhs_ast->signal->can('width')) {
            my $signal_width = $lhs_ast->signal->width;
            if (defined($signal_width) && $signal_width > 0) {
                $width = $signal_width;
            }
        } elsif ((!defined($width) || $width < 1) && $lhs_ast->can('width')) {
            my $ast_width = $lhs_ast->width;
            if (defined($ast_width) && $ast_width > 0) {
                $width = $ast_width;
            }
        }

        if ((!defined($width) || $width < 1) && $lhs_ast->can('name')) {
            my $signal_info = $self->get_signal_info($lhs_ast->name);
            if ($signal_info && $signal_info->{width} && $signal_info->{width} > 0) {
                $width = $signal_info->{width};
            }
        }
    }

    $width = 1 unless (defined($width) && $width > 0);
    return $width;
}

=head2 is_register

Determine whether one prepared LHS AST should be treated as register-backed in
the unified assignment plan.

=cut

sub is_register ($self, $lhs_signal_ast, $lhs_name_for_debug) {
    my $ctx = $self->{flattened_dt};

    fsm_debug("IS_REGISTER: Analyzing signal '$lhs_name_for_debug' using AST node", 3);

    unless ($lhs_signal_ast) {
        fsm_debug("  WARNING: No signal AST node - using fallback assignment analysis", 3);
        return $self->fallback_register_analysis_from_assignments($lhs_name_for_debug);
    }

    fsm_debug("  Signal AST node type: " . ref($lhs_signal_ast), 3);

    if ($lhs_signal_ast->can('is_fsm_state_next') && $lhs_signal_ast->is_fsm_state_next()) {
        fsm_debug("  IS_REGISTER: Signal is FSM state next (combinational) - NOT a register", 3);
        return 0;
    }

    if ($lhs_signal_ast->can('is_fsm_state_register') && $lhs_signal_ast->is_fsm_state_register()) {
        fsm_debug("  IS_REGISTER: Signal is FSM state register - handled by dedicated FSM logic", 3);
        return 0;
    }

    if ($lhs_signal_ast->can('is_register') && defined($lhs_signal_ast->is_register)) {
        my $is_register = $lhs_signal_ast->is_register();
        fsm_debug("  IS_REGISTER: Signal has explicit is_register attribute: $is_register", 3);
        return $is_register ? 1 : 0;
    }

    fsm_debug("  IS_REGISTER: No explicit AST attribute - using assignment-based analysis", 3);
    return $self->fallback_register_analysis_from_assignments($lhs_name_for_debug);
}

=head2 fallback_register_analysis_from_assignments

Fall back to assignment-operator analysis when one LHS AST does not expose an
explicit register contract.

=cut

sub fallback_register_analysis_from_assignments ($self, $lhs_name) {
    my $ctx = $self->{flattened_dt};

    fsm_debug("  FALLBACK_REGISTER_ANALYSIS: Analyzing assignment patterns for '$lhs_name'", 3);

    my $assignments = $ctx->{lhs_assignments}->{$lhs_name} || [];
    my $assignment_count = scalar(@$assignments);

    fsm_debug("    Signal has $assignment_count assignments", 3);

    if ($assignment_count == 0) {
        fsm_debug("    No assignments - NOT a register", 3);
        return 0;
    }

    my $has_register_assignment = 0;
    my $has_combinational_assignment = 0;

    for my $assignment (@$assignments) {
        my $operator = $assignment->{operator} || '=';

        if ($operator eq '<-' || $operator eq '<=' || $operator eq '<-=' || $operator eq '<=-' || $operator eq '<=+' || $operator =~ /^<\d+$/) {
            $has_register_assignment = 1;
            fsm_debug("      Found sequential assignment (operator: '$operator')", 3);
        } elsif ($operator eq '=') {
            $has_combinational_assignment = 1;
            fsm_debug("      Found combinational assignment (operator: '=')", 3);
        }
    }

    if ($has_register_assignment && !$has_combinational_assignment) {
        fsm_debug("    Only register assignments - IS a register", 3);
        return 1;
    } elsif ($has_combinational_assignment && !$has_register_assignment) {
        fsm_debug("    Only combinational assignments - NOT a register", 3);
        return 0;
    } elsif ($has_register_assignment && $has_combinational_assignment) {
        fsm_debug("    Mixed assignments - defaulting to register for safety", 3);
        return 1;
    }

    fsm_debug("    Defaulting to combinational", 3);
    return 0;
}

1;
