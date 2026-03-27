package FSM::HDL::FlattenedDT::Backend::SystemVerilog::IntermediateSignalSupport;

=head1 NAME

FSM::HDL::FlattenedDT::Backend::SystemVerilog::IntermediateSignalSupport - Own direct SystemVerilog intermediate-signal AST support

=head1 DESCRIPTION

Owns the bounded runtime-AST and intermediate-signal support family for the
older direct generated-module SystemVerilog backend. This package centralizes
runtime AST recovery, rendered-expression caching, dependency recovery, width
inference, and AST-aware filtering so the remaining emitter path can consume
one explicit owner instead of keeping that logic inline.

=cut

use v5.20;
use strict;
use warnings;
use feature qw(signatures);
no warnings 'experimental::signatures';

use FSM::Debug;
use Scalar::Util qw(blessed);

sub new ($class, %args) {
    my $flattened_dt = $args{flattened_dt}
      or die "[IntermediateSignalSupport.pm][new()] Missing required 'flattened_dt' argument";

    return bless {
        flattened_dt => $flattened_dt,
    }, $class;
}

sub should_filter_consolidated_signal ($self, $expression, $signal_name, $signal_info) {
    # AST-BASED FILTERING - Use semantic analysis instead of string patterns
    # This replaces the old string-based regex filtering with proper AST analysis

    $expression = $self->render_intermediate_signal_expression($signal_name, $signal_info)
        unless defined($expression) && $expression ne '';
    fsm_debug("\n*** AST_FILTER_CHECK: Analyzing signal '$signal_name' ***", 3);
    fsm_debug("  Expression: '$expression'", 3);
    fsm_debug("  Source: $signal_info->{source}", 3);
    fsm_debug("  Usage count: " . ($signal_info->{usage_count} || 'unknown'));

    # Try to get the AST for this signal if available
    my $ast = $self->resolve_intermediate_signal_runtime_ast($signal_name, $signal_info);
    if ($ast && blessed($ast)) {
        fsm_debug("  Using runtime AST for filtering: " . ref($ast), 3);
    } else {
        my $miss_reason = ($signal_info && ref($signal_info) eq 'HASH')
            ? ($signal_info->{runtime_ast_miss_reason} || 'unknown_runtime_ast_miss')
            : 'unknown_runtime_ast_miss';
        fsm_debug("  No runtime AST available - falling back to explicit runtime-AST-miss filtering ($miss_reason)", 3);
    }

    # AST-based filtering when AST is available
    if ($ast && blessed($ast)) {
        return $self->should_filter_ast_based($ast, $signal_name, $signal_info);
    }

    # Fallback to explicit runtime-AST-miss filtering (legacy-named helper delegates here).
    return $self->should_filter_runtime_ast_miss($signal_name, $signal_info);
}

sub resolve_intermediate_signal_defining_ast ($self, $signal_name, $signal_info) {
    my $ctx = $self->{flattened_dt};
    return undef unless defined($signal_name) && $signal_name ne '';

    if ($signal_info && $signal_info->{defining_ast} && blessed($signal_info->{defining_ast})) {
        fsm_debug("[IntermediateSignalSupport.pm][resolve_intermediate_signal_defining_ast()] Using cached defining_ast for '$signal_name'", 3);
        return $signal_info->{defining_ast};
    }

    if ($signal_info && $signal_info->{ast} && blessed($signal_info->{ast})) {
        fsm_debug("[IntermediateSignalSupport.pm][resolve_intermediate_signal_defining_ast()] Using inline AST for '$signal_name'", 3);
        return $signal_info->{ast};
    }

    my $resolved_ast = $ctx->{enable_graph_intermediate_support}->get_intermediate_signal_ast($signal_name);
    if ($resolved_ast && blessed($resolved_ast)) {
        if ($signal_info && ref($signal_info) eq 'HASH') {
            $signal_info->{defining_ast} //= $resolved_ast;
            $signal_info->{ast} //= $resolved_ast unless exists $signal_info->{ast};
        }
        fsm_debug("[IntermediateSignalSupport.pm][resolve_intermediate_signal_defining_ast()] Resolved defining AST for '$signal_name' via EnableGraph", 3);
        return $resolved_ast;
    }

    fsm_debug("[IntermediateSignalSupport.pm][resolve_intermediate_signal_defining_ast()] No defining AST available for '$signal_name'", 3);
    return undef;
}

sub resolve_intermediate_signal_runtime_ast ($self, $signal_name, $signal_info) {
    my $ctx = $self->{flattened_dt};
    return undef unless defined($signal_name) && $signal_name ne '';

    if ($signal_info && $signal_info->{runtime_ast} && blessed($signal_info->{runtime_ast})) {
        $signal_info->{runtime_ast_resolution_state} = 'resolved' if ref($signal_info) eq 'HASH';
        fsm_debug("[IntermediateSignalSupport.pm][resolve_intermediate_signal_runtime_ast()] Using cached runtime_ast for '$signal_name'", 3);
        return $signal_info->{runtime_ast};
    }

    if ($signal_info
        && ref($signal_info) eq 'HASH'
        && ($signal_info->{runtime_ast_resolution_state} || '') eq 'missing')
    {
        my $miss_reason = $signal_info->{runtime_ast_miss_reason} || 'unknown_miss_reason';
        fsm_debug("[IntermediateSignalSupport.pm][resolve_intermediate_signal_runtime_ast()] Reusing cached runtime-AST miss for '$signal_name' ($miss_reason)", 3);
        return undef;
    }

    my $runtime_ast;
    my $runtime_ast_source;
    my $runtime_ast_miss_reason = 'no_ast_source';

    if ($ctx->{ast_factorizer}
        && $ctx->{ast_factorizer}->{intermediate_signals}
        && exists $ctx->{ast_factorizer}->{intermediate_signals}->{$signal_name})
    {
        my $substituted_ast = $ctx->{backend_sv_ast_factorization}->get_substituted_ast_for_signal($signal_name, $signal_info);
        if ($substituted_ast && blessed($substituted_ast)) {
            $runtime_ast = $substituted_ast;
            $runtime_ast_source = 'substituted_ast';
        }
    }

    if ((!$runtime_ast || !blessed($runtime_ast))) {
        my $defining_ast = $self->resolve_intermediate_signal_defining_ast($signal_name, $signal_info);
        if ($defining_ast && blessed($defining_ast)) {
            $runtime_ast = $defining_ast;
            $runtime_ast_source = 'defining_ast';
        }
    }

    if ($runtime_ast && blessed($runtime_ast)) {
        if ($signal_info && ref($signal_info) eq 'HASH') {
            $signal_info->{runtime_ast} = $runtime_ast;
            $signal_info->{runtime_ast_source} = $runtime_ast_source;
            $signal_info->{runtime_ast_resolution_state} = 'resolved';
            delete $signal_info->{runtime_ast_miss_reason};
        }
        fsm_debug("[IntermediateSignalSupport.pm][resolve_intermediate_signal_runtime_ast()] Resolved runtime AST for '$signal_name' via $runtime_ast_source", 3);
        return $runtime_ast;
    }
    if ($signal_info && ref($signal_info) eq 'HASH') {
        $signal_info->{runtime_ast_resolution_state} = 'missing';
        $signal_info->{runtime_ast_miss_reason} = $runtime_ast_miss_reason;
    }

    fsm_debug("[IntermediateSignalSupport.pm][resolve_intermediate_signal_runtime_ast()] No runtime AST available for '$signal_name'", 3);
    return undef;
}

sub render_intermediate_signal_expression ($self, $signal_name, $signal_info) {
    my $ctx = $self->{flattened_dt};
    return undef unless defined($signal_name) && $signal_name ne '';
    if ($signal_info
        && ref($signal_info) eq 'HASH'
        && defined($signal_info->{rendered_expression})
        && $signal_info->{rendered_expression} ne '')
    {
        fsm_debug("[IntermediateSignalSupport.pm][render_intermediate_signal_expression()] Using cached rendered expression for '$signal_name' via " . ($signal_info->{rendered_expression_source} || 'cache'), 3);
        return $signal_info->{rendered_expression};
    }

    my $runtime_ast = $self->resolve_intermediate_signal_runtime_ast($signal_name, $signal_info);
    if ($runtime_ast && blessed($runtime_ast)) {
        my $runtime_ast_source = ($signal_info && ref($signal_info) eq 'HASH')
            ? ($signal_info->{runtime_ast_source} || 'runtime_ast')
            : 'runtime_ast';
        if ($signal_info
            && ref($signal_info) eq 'HASH'
            && $runtime_ast_source =~ /cleaned_/
            && defined($signal_info->{expression})
            && $signal_info->{expression} ne '')
        {
            $signal_info->{rendered_expression} = $signal_info->{expression};
            $signal_info->{rendered_expression_source} = 'stored_expression_preserved_after_cleaned_runtime_ast';
            fsm_debug("[IntermediateSignalSupport.pm][render_intermediate_signal_expression()] Preserving stored expression for '$signal_name' after cleaned runtime-AST recovery", 3);
            return $signal_info->{expression};
        }

        my $expression = $ctx->{enable_graph}->ast_to_systemverilog($runtime_ast);
        if ($signal_info && ref($signal_info) eq 'HASH') {
            $signal_info->{rendered_expression} = $expression;
            $signal_info->{rendered_expression_source} = $runtime_ast_source;
        }
        fsm_debug("[IntermediateSignalSupport.pm][render_intermediate_signal_expression()] Rendered '$signal_name' from AST", 3);
        return $expression;
    }

    if ($signal_info && defined($signal_info->{expression}) && $signal_info->{expression} ne '') {
        if (ref($signal_info) eq 'HASH') {
            $signal_info->{rendered_expression} = $signal_info->{expression};
            $signal_info->{rendered_expression_source} = 'stored_expression';
        }
        fsm_debug("[IntermediateSignalSupport.pm][render_intermediate_signal_expression()] Falling back to stored expression for '$signal_name'", 3);
        return $signal_info->{expression};
    }

    my $expression = $ctx->{enable_graph_intermediate_support}->get_intermediate_signal_expression($signal_name);
    if (defined($expression) && $expression ne '' && $signal_info && ref($signal_info) eq 'HASH') {
        $signal_info->{expression} //= $expression;
        $signal_info->{rendered_expression} = $expression;
        $signal_info->{rendered_expression_source} = 'enable_graph_expression';
    }
    return $expression;
}

sub resolve_intermediate_signal_dependencies ($self, $signal_name, $signal_info) {
    return () unless defined($signal_name) && $signal_name ne '';

    if ($signal_info
        && ref($signal_info) eq 'HASH'
        && $signal_info->{dependency_signal_names}
        && ref($signal_info->{dependency_signal_names}) eq 'ARRAY')
    {
        return @{$signal_info->{dependency_signal_names}};
    }

    my @dependencies;
    my $dependency_source = 'none';

    my $expression = $self->render_intermediate_signal_expression($signal_name, $signal_info);
    my $runtime_ast = $self->resolve_intermediate_signal_runtime_ast($signal_name, $signal_info);
    if ($runtime_ast && blessed($runtime_ast)) {
        @dependencies = $self->{flattened_dt}->{enable_graph}->extract_intermediate_signals_from_ast($runtime_ast);
        $dependency_source = $signal_info->{runtime_ast_source} || 'runtime_ast';
        delete $signal_info->{dependency_fallback_source} if $signal_info && ref($signal_info) eq 'HASH';
    } else {
        if (defined($expression) && $expression ne '') {
            @dependencies = $self->extract_intermediate_signals_from_runtime_ast_miss($signal_name, $signal_info, $expression);
            if ($signal_info
                && ref($signal_info) eq 'HASH'
                && $signal_info->{runtime_ast}
                && blessed($signal_info->{runtime_ast}))
            {
                $dependency_source = $signal_info->{runtime_ast_source} || 'runtime_ast_recovery';
                delete $signal_info->{dependency_fallback_source};
            } else {
                $dependency_source = ($signal_info && ref($signal_info) eq 'HASH')
                    ? ($signal_info->{dependency_fallback_source} || 'runtime_ast_miss_unresolved')
                    : 'runtime_ast_miss_unresolved';
            }
        }
    }

    my %seen_dependencies;
    @dependencies = grep { defined($_) && $_ ne '' && !$seen_dependencies{$_}++ } @dependencies;

    if ($signal_info && ref($signal_info) eq 'HASH') {
        $signal_info->{dependency_signal_names} = [@dependencies];
        $signal_info->{dependency_source} = $dependency_source;
    }

    my $dependency_summary = @dependencies ? join(', ', @dependencies) : 'none';
    fsm_debug("[IntermediateSignalSupport.pm][resolve_intermediate_signal_dependencies()] '$signal_name' dependencies => $dependency_summary via $dependency_source", 3);
    return @dependencies;
}

sub extract_intermediate_signals_from_runtime_ast_miss ($self, $signal_name, $signal_info, $expression) {
    my $ctx = $self->{flattened_dt};
    return () unless defined($expression) && $expression ne '';

    my $debug_signal_name = defined($signal_name) && $signal_name ne ''
        ? $signal_name
        : '<compatibility_expression>';
    my $stored_expression = ($signal_info && ref($signal_info) eq 'HASH' && defined($signal_info->{expression}))
        ? $signal_info->{expression}
        : undef;
    my $miss_reason = ($signal_info && ref($signal_info) eq 'HASH')
        ? ($signal_info->{runtime_ast_miss_reason} || 'unknown_runtime_ast_miss')
        : 'unknown_runtime_ast_miss';
    my %seen_candidate_expressions;
    my @candidate_expressions = ([ $expression, 'rendered_expression' ]);

    if (defined($signal_name) && $signal_name ne '') {
        my $enable_graph_expression = $ctx->{enable_graph_intermediate_support}->get_intermediate_signal_expression($signal_name);
        if (defined($enable_graph_expression) && $enable_graph_expression ne '') {
            push @candidate_expressions, [ $enable_graph_expression, 'enable_graph_expression' ];
        }
    }

    for my $candidate_info (@candidate_expressions) {
        my ($candidate_expression, $candidate_source) = @$candidate_info;
        next unless defined($candidate_expression) && $candidate_expression ne '';
        next if $seen_candidate_expressions{$candidate_expression}++;

        my $is_known_failed_expression =
            $miss_reason eq 'expression_parse_failed'
            && defined($stored_expression)
            && $stored_expression ne ''
            && $candidate_expression eq $stored_expression;

        if ($is_known_failed_expression) {
            fsm_debug("[IntermediateSignalSupport.pm][extract_intermediate_signals_from_runtime_ast_miss()] Skipping redundant parse retry for '$debug_signal_name' via $candidate_source after known parse failure", 3);
        } else {
            my $parsed_ast = $self->recover_runtime_ast_from_dependency_expression(
                $signal_name,
                $signal_info,
                $candidate_expression,
                $candidate_source,
                0,
            );
            return $ctx->{enable_graph}->extract_intermediate_signals_from_ast($parsed_ast)
                if $parsed_ast && blessed($parsed_ast);
        }

        my $cleaned_expression = $ctx->{enable_graph}->clean_intermediate_expression($candidate_expression);
        if (defined($cleaned_expression)
            && $cleaned_expression ne ''
            && $cleaned_expression ne $candidate_expression
            && !$seen_candidate_expressions{$cleaned_expression}++)
        {
            my $cleaned_source = 'cleaned_' . $candidate_source;
            my $parsed_ast = $self->recover_runtime_ast_from_dependency_expression(
                $signal_name,
                $signal_info,
                $cleaned_expression,
                $cleaned_source,
                1,
            );
            return $ctx->{enable_graph}->extract_intermediate_signals_from_ast($parsed_ast)
                if $parsed_ast && blessed($parsed_ast);
        }
    }

    if (defined($signal_name) && $signal_name ne '') {
        my $signal_name_ast = $ctx->{enable_graph_intermediate_support}->build_dependency_recovery_ast_from_signal_name($signal_name);
        if ($signal_name_ast && blessed($signal_name_ast)) {
            my @dependencies = $ctx->{enable_graph}->extract_intermediate_signals_from_ast($signal_name_ast);
            if ($signal_info && ref($signal_info) eq 'HASH') {
                $signal_info->{dependency_fallback_source} = 'runtime_ast_miss_signal_name_ast';
            }
            return @dependencies;
        }
    }

    if ($signal_info && ref($signal_info) eq 'HASH') {
        $signal_info->{dependency_fallback_source} = 'runtime_ast_miss_unresolved';
    }
    fsm_debug(
        "[IntermediateSignalSupport.pm][extract_intermediate_signals_from_runtime_ast_miss()] No AST-backed dependency recovery remained for '$debug_signal_name'; leaving dependencies unresolved after runtime AST miss",
        3,
    );
    return ();
}

sub recover_runtime_ast_from_dependency_expression ($self, $signal_name, $signal_info, $candidate_expression, $candidate_source, $preserve_rendered_expression = 0) {
    my $ctx = $self->{flattened_dt};
    return undef unless defined($candidate_expression) && $candidate_expression ne '';
    return undef unless $ctx->{expr_namer};

    my $debug_signal_name = defined($signal_name) && $signal_name ne ''
        ? $signal_name
        : '<compatibility_expression>';
    my $parsed_ast = eval { $ctx->{expr_namer}->parse_expression($candidate_expression) };
    if ($parsed_ast && blessed($parsed_ast)) {
        my $runtime_ast_source = 'dependency_' . $candidate_source . '_ast';
        if ($signal_info && ref($signal_info) eq 'HASH') {
            $signal_info->{runtime_ast} = $parsed_ast;
            $signal_info->{runtime_ast_source} = $runtime_ast_source;
            $signal_info->{runtime_ast_resolution_state} = 'resolved';
            delete $signal_info->{runtime_ast_miss_reason};
            unless ($preserve_rendered_expression) {
                $signal_info->{rendered_expression} = $candidate_expression;
                $signal_info->{rendered_expression_source} = $candidate_source;
            }
            $signal_info->{expression} //= $candidate_expression;
            delete $signal_info->{dependency_fallback_source};
            if (defined($signal_name) && $signal_name ne '') {
                my $resolved_width = $self->resolve_intermediate_signal_width($signal_name, $signal_info);
                $signal_info->{width} = $resolved_width if defined($resolved_width) && $resolved_width > 0;
            }
        }
        fsm_debug("[IntermediateSignalSupport.pm][recover_runtime_ast_from_dependency_expression()] Recovered runtime AST for '$debug_signal_name' via $candidate_source", 3);
        return $parsed_ast;
    }

    my $error = $@;
    chomp $error if defined $error;
    fsm_debug("[IntermediateSignalSupport.pm][recover_runtime_ast_from_dependency_expression()] Failed compatibility parse for '$debug_signal_name' via $candidate_source: " . ($error || 'unknown parse failure'), 3);
    return undef;
}

sub resolve_intermediate_signal_width ($self, $signal_name, $signal_info, $signal_registry = undef, $seen_signals = undef) {
    my $ctx = $self->{flattened_dt};
    return 1 unless defined($signal_name) && $signal_name ne '';

    $signal_registry //= {};
    $seen_signals //= {};
    if ($seen_signals->{$signal_name}++) {
        my $cached_width = ($signal_info && defined($signal_info->{width}) && $signal_info->{width} > 0)
            ? $signal_info->{width}
            : 1;
        fsm_debug("[IntermediateSignalSupport.pm][resolve_intermediate_signal_width()] Detected recursive width lookup for '$signal_name'; using cached width $cached_width", 3);
        return $cached_width;
    }

    my $resolved_width;
    my $width_source = 'default_1bit';

    my $native_signal_info = $ctx->{enable_graph}->get_signal_info($signal_name);
    if ($native_signal_info && $native_signal_info->{width} && $native_signal_info->{width} > 0) {
        $resolved_width = $native_signal_info->{width};
        $width_source = 'native_signal_metadata';
    }

    if ((!defined($resolved_width) || $resolved_width < 1) && $signal_info && defined($signal_info->{width}) && $signal_info->{width} > 1) {
        $resolved_width = $signal_info->{width};
        $width_source = 'cached_width';
    }

    if (!defined($resolved_width) || $resolved_width < 1) {
        my $runtime_ast = $self->resolve_intermediate_signal_runtime_ast($signal_name, $signal_info);
        if ($runtime_ast && blessed($runtime_ast)) {
            my $ast_width = $self->infer_width_from_intermediate_ast($runtime_ast, $signal_registry, $seen_signals);
            if (defined($ast_width) && $ast_width > 0) {
                $resolved_width = $ast_width;
                $width_source = $signal_info->{runtime_ast_source} || 'runtime_ast';
            }
        }
    }

    if ((!defined($resolved_width) || $resolved_width < 1) && $signal_info && defined($signal_info->{width}) && $signal_info->{width} > 0) {
        $resolved_width = $signal_info->{width};
        $width_source = 'cached_width';
    }

    $resolved_width = 1 unless defined($resolved_width) && $resolved_width > 0;
    if ($signal_info && ref($signal_info) eq 'HASH') {
        $signal_info->{width} = $resolved_width;
        $signal_info->{width_source} = $width_source;
    }

    fsm_debug("[IntermediateSignalSupport.pm][resolve_intermediate_signal_width()] Resolved width $resolved_width for '$signal_name' via $width_source", 3);
    return $resolved_width;
}

sub infer_width_from_intermediate_ast ($self, $ast, $signal_registry = undef, $seen_signals = undef) {
    my $ctx = $self->{flattened_dt};
    return undef unless $ast && blessed($ast);

    $signal_registry //= {};
    $seen_signals //= {};

    if ($ast->isa('FSM::HDL::IntermediateSignalRef')) {
        my $referenced_signal_name = eval { $ast->signal_name } || $ast->{signal_name};
        if (defined($referenced_signal_name) && $referenced_signal_name ne '') {
            my $referenced_signal_info = $signal_registry->{$referenced_signal_name}
                || ($ctx->{ast_factorizer} && $ctx->{ast_factorizer}->{intermediate_signals}
                    ? $ctx->{ast_factorizer}->{intermediate_signals}->{$referenced_signal_name}
                    : undef);
            return $self->resolve_intermediate_signal_width($referenced_signal_name, $referenced_signal_info, $signal_registry, $seen_signals);
        }
        return 1;
    }

    if ($ast->isa('FSM::HDL::SubstitutedUnaryOp')) {
        my $operator = eval { $ast->operator } || $ast->{operator} || '';
        return 1 if $operator eq '!';
        my $operand = eval { $ast->operand } || $ast->{operand};
        my $operand_width = $self->infer_width_from_intermediate_ast($operand, $signal_registry, $seen_signals);
        return (defined($operand_width) && $operand_width > 0) ? $operand_width : 1;
    }

    if ($ast->isa('FSM::HDL::SubstitutedBinaryOp')) {
        my $operator = eval { $ast->operator } || $ast->{operator} || '';
        return 1 if $operator =~ /^(==|!=|<|>|<=|>=|&&|\|\|)$/;

        my $left = eval { $ast->left } || $ast->{left};
        my $right = eval { $ast->right } || $ast->{right};
        my $left_width = $self->infer_width_from_intermediate_ast($left, $signal_registry, $seen_signals);
        my $right_width = $self->infer_width_from_intermediate_ast($right, $signal_registry, $seen_signals);

        $left_width = 1 unless defined($left_width) && $left_width > 0;
        $right_width = 1 unless defined($right_width) && $right_width > 0;
        return $left_width > $right_width ? $left_width : $right_width;
    }

    my $width = eval { $ctx->{expr_namer}->infer_ast_width($ast) };
    return $width if defined($width) && $width > 0;

    return undef;
}

sub should_filter_ast_based ($self, $ast, $signal_name, $signal_info) {
    my $ctx = $self->{flattened_dt};
    # Pure AST-based filtering using semantic analysis

    fsm_debug("  AST_FILTER: Using AST-based filtering for " . ref($ast));

    my $usage_count = $signal_info->{usage_count} || 0;
    my $live_usage = $ctx->{enable_graph}->resolve_intermediate_signal_live_usage($signal_name, $signal_info);
    my $actually_used = $live_usage->{used_in_final_expressions} ? 1 : 0;

    # REFERENCE-AWARE FILTERING: Check if signal is referenced in substituted expressions
    # This is the fix for the bug where intermediate signals are referenced but not declared
    my $referenced_in_substitutions = $live_usage->{referenced_in_substitutions} ? 1 : 0;

    if ($referenced_in_substitutions) {
        fsm_debug("  AST_FILTER: Signal '$signal_name' is referenced in AST substitutions - KEEPING", 3);
        return 0; # Keep signals that are already referenced in substituted expressions
    }

    # AST_FILTER 1: TEMPORARILY DISABLED - Filter if not actually used
    # The usage tracking is not working correctly after AST substitution
    # So we're temporarily disabling this aggressive filtering
    if (!$actually_used || $usage_count == 0) {
        fsm_debug("  AST_FILTER: Signal appears unused (usage_count=$usage_count, actually_used=$actually_used) - but KEEPING due to usage tracking issues", 3);
        # return 1;  # DISABLED - usage tracking is broken
    }

    # AST_FILTER 2: Filter simple literals
    if ($ast->isa('FSM::AST::Literal') || $ast->isa('FSM::CoreAST::Literal')) {
        fsm_debug("  AST_FILTER: Simple literal - FILTERING", 3);
        return 1;
    }

    # AST_FILTER 3: Filter bare signal references (signal = signal)
    if ($ast->isa('FSM::AST::SignalRef') || $ast->isa('FSM::CoreAST::SignalRef')) {
        fsm_debug("  AST_FILTER: Bare signal reference - FILTERING", 3);
        return 1;
    }

    # AST_FILTER 4: Handle unary operations (like negation)
    if ($ast->isa('FSM::AST::UnaryOp') || $ast->isa('FSM::CoreAST::UnaryOp')) {
        # Check if it's a simple negation of a signal
        if ($self->is_simple_negation($ast)) {
            # Only factor if used multiple times
            if ($usage_count >= 2) {
                fsm_debug("  AST_FILTER: Simple negation used $usage_count times - KEEPING", 3);
                return 0;
            } else {
                fsm_debug("  AST_FILTER: Simple negation used only once - FILTERING", 3);
                return 1;
            }
        } else {
            # Complex unary operation - always keep
            fsm_debug("  AST_FILTER: Complex unary operation - KEEPING", 3);
            return 0;
        }
    }

    # AST_FILTER 5: Handle binary operations
    if ($ast->isa('FSM::AST::BinaryOp') || $ast->isa('FSM::CoreAST::BinaryOp')) {
        # Check if it's a simple comparison
        if ($self->is_simple_comparison($ast)) {
            fsm_debug("  AST_FILTER: Simple comparison - FILTERING", 3);
            return 1;
        }

        # Check if it's an arithmetic operation (always keep)
        if ($ctx->{enable_graph}->is_arithmetic_operation($ast)) {
            fsm_debug("  AST_FILTER: Arithmetic operation - KEEPING", 3);
            return 0;
        }

        # Check if it's a logical operation
        if ($ctx->{enable_graph}->is_logical_operation($ast)) {
            # Use the existing AST-based logical operation factorization logic
            my $should_factor = $ctx->{enable_graph}->should_factor_logical_operation($ast);
            if ($should_factor && $usage_count >= 2) {
                fsm_debug("  AST_FILTER: Multi-use logical operation - KEEPING", 3);
                return 0;
            } else {
                fsm_debug("  AST_FILTER: Low-use logical operation - FILTERING", 3);
                return 1;
            }
        }

        # Other binary operations - keep if used multiple times
        if ($usage_count >= 2) {
            fsm_debug("  AST_FILTER: Multi-use binary operation - KEEPING", 3);
            return 0;
        } else {
            fsm_debug("  AST_FILTER: Single-use binary operation - FILTERING", 3);
            return 1;
        }
    }

    # Default: keep complex expressions that are used multiple times
    if ($usage_count >= 2) {
        fsm_debug("  AST_FILTER: Complex multi-use expression - KEEPING", 3);
        return 0;
    } else {
        fsm_debug("  AST_FILTER: Complex single-use expression - FILTERING", 3);
        return 1;
    }
}

sub should_filter_runtime_ast_miss ($self, $signal_name, $signal_info) {
    my $miss_reason = ($signal_info && ref($signal_info) eq 'HASH')
        ? ($signal_info->{runtime_ast_miss_reason} || 'unknown_runtime_ast_miss')
        : 'unknown_runtime_ast_miss';
    my $live_usage = $self->{flattened_dt}->{enable_graph}->resolve_intermediate_signal_live_usage($signal_name, $signal_info);
    my $referenced_in_substitutions = $live_usage->{referenced_in_substitutions} ? 1 : 0;
    my $used_in_final_expressions = $live_usage->{used_in_final_expressions} ? 1 : 0;
    my $evidence_state = $live_usage->{evidence_state} || 'none';

    if ($signal_info && ref($signal_info) eq 'HASH') {
        $signal_info->{filter_fallback_source} = 'runtime_ast_miss_live_usage';
        $signal_info->{filter_fallback_reason} = $miss_reason;
    }

    fsm_debug("  RUNTIME_AST_MISS_FILTER: Evaluating '$signal_name' via live usage metadata ($evidence_state, miss_reason=$miss_reason)", 3);

    if ($referenced_in_substitutions) {
        fsm_debug("  RUNTIME_AST_MISS_FILTER: Signal '$signal_name' is referenced in AST substitutions - KEEPING", 3);
        return 0;
    }

    if ($used_in_final_expressions) {
        fsm_debug("  RUNTIME_AST_MISS_FILTER: Signal '$signal_name' is used in final AST expressions - KEEPING", 3);
        return 0;
    }

    fsm_debug("  RUNTIME_AST_MISS_FILTER: No AST-backed live-usage evidence for '$signal_name' - FILTERING", 3);
    return 1;
}

sub is_simple_negation ($self, $ast) {
    # Check if this is a simple negation of a signal (like !signal_name)
    return 0 unless $ast && blessed($ast);
    return 0 unless $ast->isa('FSM::AST::UnaryOp') || $ast->isa('FSM::CoreAST::UnaryOp');
    return 0 unless $ast->can('operator') && $ast->can('operand');

    my $op = $ast->operator || '';
    return 0 unless $op =~ /^(!|not)$/;

    my $operand = $ast->operand;
    return 0 unless $operand && blessed($operand);

    # Check if operand is a simple signal reference
    return ($operand->isa('FSM::AST::SignalRef') || $operand->isa('FSM::CoreAST::SignalRef'));
}

sub is_simple_comparison ($self, $ast) {
    # Check if this is a simple comparison like signal == constant
    return 0 unless $ast && blessed($ast);
    return 0 unless $ast->isa('FSM::AST::BinaryOp') || $ast->isa('FSM::CoreAST::BinaryOp');
    return 0 unless $ast->can('operator') && $ast->can('left') && $ast->can('right');

    my $op = $ast->operator || '';
    return 0 unless $op =~ /^(==|!=|<|>|<=|>=)$/;

    my $left = $ast->left;
    my $right = $ast->right;
    return 0 unless $left && blessed($left) && $right && blessed($right);

    # Check if one side is a signal and the other is a literal
    my $has_signal = ($left->isa('FSM::AST::SignalRef') || $left->isa('FSM::CoreAST::SignalRef')) ||
                     ($right->isa('FSM::AST::SignalRef') || $right->isa('FSM::CoreAST::SignalRef'));
    my $has_literal = ($left->isa('FSM::AST::Literal') || $left->isa('FSM::CoreAST::Literal')) ||
                      ($right->isa('FSM::AST::Literal') || $right->isa('FSM::CoreAST::Literal'));

    return $has_signal && $has_literal;
}

1;

__END__

=head1 METHODS

=head2 new

Constructs one intermediate-signal support owner bound to a specific
C<FSM::HDL::FlattenedDT> backend context.

=head2 should_filter_consolidated_signal

Applies the AST-first filter decision for one consolidated intermediate
signal, falling back to explicit runtime-AST-miss filtering when no runtime
AST can be resolved.

=head2 resolve_intermediate_signal_defining_ast

Finds the defining AST for one intermediate signal from cached metadata or the
enable graph, and caches the result back onto the signal metadata when found.

=head2 resolve_intermediate_signal_runtime_ast

Resolves the runtime AST for one intermediate signal from substituted ASTs or
the defining AST and records the result or miss metadata on the signal info.

=head2 render_intermediate_signal_expression

Renders one intermediate signal expression from its resolved runtime AST when
available, otherwise falls back to stored compatibility expressions or the
enable-graph string registry.

=head2 resolve_intermediate_signal_dependencies

Normalizes the dependency list for one intermediate signal from runtime ASTs
or the explicit runtime-AST-miss recovery path and caches the result.

=head2 extract_intermediate_signals_from_runtime_ast_miss

Attempts AST-backed dependency recovery for a signal whose runtime AST could
not be resolved, including cleaned-expression retries and signal-name fallback
recovery.

=head2 recover_runtime_ast_from_dependency_expression

Attempts to parse one compatibility expression into a runtime AST for
dependency recovery and updates the signal metadata when successful.

=head2 resolve_intermediate_signal_width

Normalizes one intermediate signal width from native signal metadata, runtime
AST inference, or cached width fallback.

=head2 infer_width_from_intermediate_ast

Infers an intermediate expression width recursively from the substituted AST
shape, including referenced intermediate signals.

=head2 should_filter_ast_based

Applies the AST-aware filter policy when a runtime AST is available.

=head2 should_filter_runtime_ast_miss

Applies the live-usage filter fallback for signals that still lack a runtime
AST.

=head2 is_simple_negation

Returns true when the AST is a simple unary negation over a signal reference.

=head2 is_simple_comparison

Returns true when the AST is a simple signal-versus-literal comparison.

=cut
