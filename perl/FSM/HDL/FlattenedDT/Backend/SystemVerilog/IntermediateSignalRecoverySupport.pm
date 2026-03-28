package FSM::HDL::FlattenedDT::Backend::SystemVerilog::IntermediateSignalRecoverySupport;

=head1 NAME

FSM::HDL::FlattenedDT::Backend::SystemVerilog::IntermediateSignalRecoverySupport - Own direct SystemVerilog intermediate-signal recovery and metadata normalization support

=head1 DESCRIPTION

Owns the bounded runtime-AST and metadata-recovery family for the older direct
generated-module SystemVerilog backend. This package centralizes:

=over 4

=item *

defining-AST and substituted runtime-AST lookup

=item *

rendered-expression recovery and caching

=item *

intermediate dependency recovery, including explicit runtime-AST-miss fallback

=back

The paired
C<FSM::HDL::FlattenedDT::Backend::SystemVerilog::IntermediateSignalSupport>
now narrows to filter policy over the normalized metadata this package
produces, the paired
C<FSM::HDL::FlattenedDT::Backend::SystemVerilog::IntermediateSignalWidthSupport>
now owns width normalization and inference, and this package owns the “figure
out the real intermediate signal payload” side of the direct backend path.

=cut

use v5.20;
use strict;
use warnings;
use feature qw(signatures);
no warnings 'experimental::signatures';

use FSM::Debug;
use Scalar::Util qw(blessed);

=head2 new

Construct one intermediate-signal recovery owner bound to a specific
C<FSM::HDL::FlattenedDT> backend context.

=cut

sub new ($class, %args) {
    my $flattened_dt = $args{flattened_dt}
      or die "[IntermediateSignalRecoverySupport.pm][new()] Missing required 'flattened_dt' argument";

    return bless {
        flattened_dt => $flattened_dt,
    }, $class;
}

=head2 resolve_intermediate_signal_defining_ast

Find the defining AST for one intermediate signal from cached metadata or the
enable graph, and cache the resolved AST back onto the signal metadata when
found.

=cut

sub resolve_intermediate_signal_defining_ast ($self, $signal_name, $signal_info) {
    my $ctx = $self->{flattened_dt};
    return undef unless defined($signal_name) && $signal_name ne '';

    if ($signal_info && $signal_info->{defining_ast} && blessed($signal_info->{defining_ast})) {
        fsm_debug("[IntermediateSignalRecoverySupport.pm][resolve_intermediate_signal_defining_ast()] Using cached defining_ast for '$signal_name'", 3);
        return $signal_info->{defining_ast};
    }

    if ($signal_info && $signal_info->{ast} && blessed($signal_info->{ast})) {
        fsm_debug("[IntermediateSignalRecoverySupport.pm][resolve_intermediate_signal_defining_ast()] Using inline AST for '$signal_name'", 3);
        return $signal_info->{ast};
    }

    my $resolved_ast = $ctx->{enable_graph_intermediate_support}->get_intermediate_signal_ast($signal_name);
    if ($resolved_ast && blessed($resolved_ast)) {
        if ($signal_info && ref($signal_info) eq 'HASH') {
            $signal_info->{defining_ast} //= $resolved_ast;
            $signal_info->{ast} //= $resolved_ast unless exists $signal_info->{ast};
        }
        fsm_debug("[IntermediateSignalRecoverySupport.pm][resolve_intermediate_signal_defining_ast()] Resolved defining AST for '$signal_name' via EnableGraph", 3);
        return $resolved_ast;
    }

    fsm_debug("[IntermediateSignalRecoverySupport.pm][resolve_intermediate_signal_defining_ast()] No defining AST available for '$signal_name'", 3);
    return undef;
}

=head2 resolve_intermediate_signal_runtime_ast

Resolve the runtime AST for one intermediate signal from substituted ASTs or a
defining AST and record the result or miss metadata on the signal info.

=cut

sub resolve_intermediate_signal_runtime_ast ($self, $signal_name, $signal_info) {
    my $ctx = $self->{flattened_dt};
    return undef unless defined($signal_name) && $signal_name ne '';

    if ($signal_info && $signal_info->{runtime_ast} && blessed($signal_info->{runtime_ast})) {
        $signal_info->{runtime_ast_resolution_state} = 'resolved' if ref($signal_info) eq 'HASH';
        fsm_debug("[IntermediateSignalRecoverySupport.pm][resolve_intermediate_signal_runtime_ast()] Using cached runtime_ast for '$signal_name'", 3);
        return $signal_info->{runtime_ast};
    }

    if ($signal_info
        && ref($signal_info) eq 'HASH'
        && ($signal_info->{runtime_ast_resolution_state} || '') eq 'missing')
    {
        my $miss_reason = $signal_info->{runtime_ast_miss_reason} || 'unknown_miss_reason';
        fsm_debug("[IntermediateSignalRecoverySupport.pm][resolve_intermediate_signal_runtime_ast()] Reusing cached runtime-AST miss for '$signal_name' ($miss_reason)", 3);
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
        fsm_debug("[IntermediateSignalRecoverySupport.pm][resolve_intermediate_signal_runtime_ast()] Resolved runtime AST for '$signal_name' via $runtime_ast_source", 3);
        return $runtime_ast;
    }

    if ($signal_info && ref($signal_info) eq 'HASH') {
        $signal_info->{runtime_ast_resolution_state} = 'missing';
        $signal_info->{runtime_ast_miss_reason} = $runtime_ast_miss_reason;
    }

    fsm_debug("[IntermediateSignalRecoverySupport.pm][resolve_intermediate_signal_runtime_ast()] No runtime AST available for '$signal_name'", 3);
    return undef;
}

=head2 render_intermediate_signal_expression

Render one intermediate signal expression from its resolved runtime AST when
available, otherwise fall back to stored compatibility expressions or the
enable-graph registry.

=cut

sub render_intermediate_signal_expression ($self, $signal_name, $signal_info) {
    my $ctx = $self->{flattened_dt};
    return undef unless defined($signal_name) && $signal_name ne '';
    if ($signal_info
        && ref($signal_info) eq 'HASH'
        && defined($signal_info->{rendered_expression})
        && $signal_info->{rendered_expression} ne '')
    {
        fsm_debug("[IntermediateSignalRecoverySupport.pm][render_intermediate_signal_expression()] Using cached rendered expression for '$signal_name' via " . ($signal_info->{rendered_expression_source} || 'cache'), 3);
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
            fsm_debug("[IntermediateSignalRecoverySupport.pm][render_intermediate_signal_expression()] Preserving stored expression for '$signal_name' after cleaned runtime-AST recovery", 3);
            return $signal_info->{expression};
        }

        my $expression = $ctx->{enable_graph_ast_support}->ast_to_systemverilog($runtime_ast);
        if ($signal_info && ref($signal_info) eq 'HASH') {
            $signal_info->{rendered_expression} = $expression;
            $signal_info->{rendered_expression_source} = $runtime_ast_source;
        }
        fsm_debug("[IntermediateSignalRecoverySupport.pm][render_intermediate_signal_expression()] Rendered '$signal_name' from AST", 3);
        return $expression;
    }

    if ($signal_info && defined($signal_info->{expression}) && $signal_info->{expression} ne '') {
        if (ref($signal_info) eq 'HASH') {
            $signal_info->{rendered_expression} = $signal_info->{expression};
            $signal_info->{rendered_expression_source} = 'stored_expression';
        }
        fsm_debug("[IntermediateSignalRecoverySupport.pm][render_intermediate_signal_expression()] Falling back to stored expression for '$signal_name'", 3);
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

=head2 resolve_intermediate_signal_dependencies

Normalize the dependency list for one intermediate signal from runtime ASTs or
the explicit runtime-AST-miss recovery path and cache the result.

=cut

sub resolve_intermediate_signal_dependencies ($self, $signal_name, $signal_info) {
    my $ctx = $self->{flattened_dt};
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
        @dependencies = $ctx->{enable_graph_signal_support}->extract_intermediate_signals_from_ast($runtime_ast);
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
    fsm_debug("[IntermediateSignalRecoverySupport.pm][resolve_intermediate_signal_dependencies()] '$signal_name' dependencies => $dependency_summary via $dependency_source", 3);
    return @dependencies;
}

=head2 extract_intermediate_signals_from_runtime_ast_miss

Attempt AST-backed dependency recovery for a signal whose runtime AST could not
be resolved, including cleaned-expression retries and signal-name fallback
recovery.

=cut

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
            fsm_debug("[IntermediateSignalRecoverySupport.pm][extract_intermediate_signals_from_runtime_ast_miss()] Skipping redundant parse retry for '$debug_signal_name' via $candidate_source after known parse failure", 3);
        } else {
            my $parsed_ast = $self->recover_runtime_ast_from_dependency_expression(
                $signal_name,
                $signal_info,
                $candidate_expression,
                $candidate_source,
                0,
            );
            return $ctx->{enable_graph_signal_support}->extract_intermediate_signals_from_ast($parsed_ast)
                if $parsed_ast && blessed($parsed_ast);
        }

        my $cleaned_expression = $ctx->{enable_graph_signal_support}->clean_intermediate_expression($candidate_expression);
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
            return $ctx->{enable_graph_signal_support}->extract_intermediate_signals_from_ast($parsed_ast)
                if $parsed_ast && blessed($parsed_ast);
        }
    }

    if (defined($signal_name) && $signal_name ne '') {
        my $signal_name_ast = $ctx->{enable_graph_intermediate_support}->build_dependency_recovery_ast_from_signal_name($signal_name);
        if ($signal_name_ast && blessed($signal_name_ast)) {
            my @dependencies = $ctx->{enable_graph_signal_support}->extract_intermediate_signals_from_ast($signal_name_ast);
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
        "[IntermediateSignalRecoverySupport.pm][extract_intermediate_signals_from_runtime_ast_miss()] No AST-backed dependency recovery remained for '$debug_signal_name'; leaving dependencies unresolved after runtime AST miss",
        3,
    );
    return ();
}

=head2 recover_runtime_ast_from_dependency_expression

Attempt to parse one compatibility expression into a runtime AST for
dependency recovery and update the signal metadata when successful.

=cut

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
                my $resolved_width = $ctx->{backend_sv_intermediate_width_support}->resolve_intermediate_signal_width($signal_name, $signal_info);
                $signal_info->{width} = $resolved_width if defined($resolved_width) && $resolved_width > 0;
            }
        }
        fsm_debug("[IntermediateSignalRecoverySupport.pm][recover_runtime_ast_from_dependency_expression()] Recovered runtime AST for '$debug_signal_name' via $candidate_source", 3);
        return $parsed_ast;
    }

    my $error = $@;
    chomp $error if defined $error;
    fsm_debug("[IntermediateSignalRecoverySupport.pm][recover_runtime_ast_from_dependency_expression()] Failed compatibility parse for '$debug_signal_name' via $candidate_source: " . ($error || 'unknown parse failure'), 3);
    return undef;
}

1;

__END__

=head1 METHODS

=head2 new

Constructs one intermediate-signal recovery owner bound to a specific
C<FSM::HDL::FlattenedDT> backend context.

=head2 resolve_intermediate_signal_defining_ast

Finds the defining AST for one intermediate signal from cached metadata or the
enable graph and caches the result when found.

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

=cut
