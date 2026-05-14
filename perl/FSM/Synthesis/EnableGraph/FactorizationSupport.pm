package FSM::Synthesis::EnableGraph::FactorizationSupport;

=head1 NAME

FSM::Synthesis::EnableGraph::FactorizationSupport - Own factorization analysis and substitution support for EnableGraph

=head1 DESCRIPTION

This package owns the bounded substitution-synchronization and live-usage
evidence family that used to live inline inside C<FSM::Synthesis::EnableGraph>.
It centralizes:

=over 4

=item *

substitution synchronization back into owner-side AST structures

=item *

AST-based live-usage evidence for intermediate signals

=back

The paired C<FSM::Synthesis::EnableGraph::FactorizationPolicySupport> owner now
holds the logical-operation counting, factorizer-feed preparation, second-pass
eligibility checks, and high-count logical-operation policy.

=cut

use v5.20;
use strict;
use warnings;
use feature qw(signatures);
no warnings 'experimental::signatures';

use FSM::Debug;
use Scalar::Util qw(blessed);

=head2 new

Construct a factorization-support owner bound to one live
C<FSM::HDL::FlattenedDT> context.

=cut

sub new ($class, %args) {
    my $flattened_dt = $args{flattened_dt}
      or die "[FactorizationSupport.pm][new()] Missing required 'flattened_dt' argument";

    return bless {
        flattened_dt => $flattened_dt,
    }, $class;
}


=head2 count_unary_negations_in_original_expressions

Scan the current owner-side AST state for unary-negation patterns and emit the
debug summary used during substitution synchronization.

=cut

sub count_unary_negations_in_original_expressions ($self) {
    my $ctx = $self->{flattened_dt};

    my $neg_count = 0;
    my %neg_patterns;

    if ($ctx->{assignment_analysis}) {
        for my $lhs (keys %{$ctx->{assignment_analysis}}) {
            my $lhs_analysis = $ctx->{assignment_analysis}{$lhs};
            for my $rhs (keys %{$lhs_analysis->{rhs_groups}}) {
                my $rhs_group = $lhs_analysis->{rhs_groups}{$rhs};

                for my $dt_enable (@{$rhs_group->{dt_specific_enables} || []}) {
                    if ($dt_enable->{enable_ast} && blessed($dt_enable->{enable_ast})) {
                        my $sv = eval { $dt_enable->{enable_ast}->to_systemverilog() } || "[NO SV]";
                        if ($sv =~ /!\w+/) {
                            $neg_count++;
                            $neg_patterns{$sv}++;
                            fsm_debug("    UNARY_NEG: $sv in DT enable $dt_enable->{enable_name}", 3);
                        }
                    }
                }

                if ($rhs_group->{lhs_level_enable} && $rhs_group->{lhs_level_enable}{ast}) {
                    my $sv = eval { $rhs_group->{lhs_level_enable}{ast}->to_systemverilog() } || "[NO SV]";
                    if ($sv =~ /!\w+/) {
                        $neg_count++;
                        $neg_patterns{$sv}++;
                        fsm_debug("    UNARY_NEG: $sv in LHS enable $rhs_group->{lhs_level_enable}{name}", 3);
                    }
                }
            }
        }
    }

    fsm_debug("  Found $neg_count unary negations in expressions:", 3);
    for my $pattern (sort keys %neg_patterns) {
        fsm_debug("    '$pattern' appears $neg_patterns{$pattern} times", 3);
    }
}

=head2 update_original_asts_with_substituted_versions

Synchronize first-pass substituted ASTs back into the owner-side assignment and
enable structures.

=cut

sub update_original_asts_with_substituted_versions ($self, $factorizer) {
    my $ctx = $self->{flattened_dt};

    fsm_debug("UPDATE_ORIGINAL_ASTS: Synchronizing original ASTs with substituted versions", 3);

    my $context_to_substituted_ast = $self->_build_context_to_ast_map(
        $factorizer->{ast_expressions},
        debug_prefix => 'UPDATE_ORIGINAL_ASTS',
        log_context_map => 1,
    );
    my $updated_count = 0;
    my $dt_ast_updates = 0;
    my $lhs_ast_updates = 0;
    my $assignment_ast_updates = 0;

    if ($ctx->{assignment_analysis}) {
        fsm_debug("UPDATE_ORIGINAL_ASTS: Updating assignment_analysis structure", 3);

        for my $lhs (keys %{$ctx->{assignment_analysis}}) {
            my $lhs_analysis = $ctx->{assignment_analysis}{$lhs};

            for my $rhs (keys %{$lhs_analysis->{rhs_groups}}) {
                my $rhs_group = $lhs_analysis->{rhs_groups}{$rhs};

                for my $dt_enable_info (@{$rhs_group->{dt_specific_enables}}) {
                    my $enable_name = $dt_enable_info->{enable_name};
                    my $context_key = "dt_enable:$enable_name";

                    if (exists $context_to_substituted_ast->{$context_key}) {
                        my $original_ast = $dt_enable_info->{enable_ast};
                        my $substituted_ast = $context_to_substituted_ast->{$context_key};

                        my $original_sv = eval { $ctx->{enable_graph_ast_support}->ast_to_systemverilog($original_ast) } || "[NO SV REPRESENTATION]";
                        my $substituted_sv = eval { $ctx->{enable_graph_ast_support}->ast_to_systemverilog($substituted_ast) } || "[NO SV REPRESENTATION]";

                        $dt_enable_info->{enable_ast} = $substituted_ast;
                        $updated_count++;
                        $dt_ast_updates++;

                        fsm_debug("  *** UPDATED DT-specific enable AST: $enable_name ***", 3);
                        fsm_debug("    Original:  $original_sv", 3);
                        fsm_debug("    Updated:   $substituted_sv", 3);
                    } else {
                        fsm_debug("  No substitution found for DT enable: $dt_enable_info->{enable_name}", 3);
                    }
                }

                if ($rhs_group->{lhs_level_enable} && $rhs_group->{lhs_level_enable}{ast}) {
                    my $lhs_enable = $rhs_group->{lhs_level_enable};
                    my $enable_name = $lhs_enable->{name};
                    my $context_key = "lhs_enable:$enable_name";

                    if (exists $context_to_substituted_ast->{$context_key}) {
                        my $original_ast = $lhs_enable->{ast};
                        my $substituted_ast = $context_to_substituted_ast->{$context_key};

                        my $original_sv = eval { $ctx->{enable_graph_ast_support}->ast_to_systemverilog($original_ast) } || "[NO SV REPRESENTATION]";
                        my $substituted_sv = eval { $ctx->{enable_graph_ast_support}->ast_to_systemverilog($substituted_ast) } || "[NO SV REPRESENTATION]";

                        $lhs_enable->{ast} = $substituted_ast;
                        $updated_count++;
                        $lhs_ast_updates++;

                        fsm_debug("  *** UPDATED LHS-level enable AST: $enable_name ***", 3);
                        fsm_debug("    Original:  $original_sv", 3);
                        fsm_debug("    Updated:   $substituted_sv", 3);
                    } else {
                        fsm_debug("  No substitution found for LHS enable: $enable_name", 3);
                    }
                }
            }
        }
    } else {
        fsm_debug("*** WARNING: No assignment_analysis structure to update! ***", 3);
    }

    fsm_debug("UPDATE_ORIGINAL_ASTS: Updating lhs_assignments structure", 3);

    for my $lhs (keys %{$ctx->{lhs_assignments} || {}}) {
        for my $assignment (@{$ctx->{lhs_assignments}{$lhs}}) {
            next unless $assignment->{conditions_ast} && blessed($assignment->{conditions_ast});

            my $dt_name = $assignment->{dt};
            my $context_key = "assignment_condition:$lhs:$dt_name";

            if (exists $context_to_substituted_ast->{$context_key}) {
                my $original_ast = $assignment->{conditions_ast};
                my $substituted_ast = $context_to_substituted_ast->{$context_key};

                my $original_sv = eval { $ctx->{enable_graph_ast_support}->ast_to_systemverilog($original_ast) } || "[NO SV REPRESENTATION]";
                my $substituted_sv = eval { $ctx->{enable_graph_ast_support}->ast_to_systemverilog($substituted_ast) } || "[NO SV REPRESENTATION]";

                $assignment->{conditions_ast} = $substituted_ast;
                $updated_count++;
                $assignment_ast_updates++;

                fsm_debug("  *** UPDATED assignment condition AST: $lhs from $dt_name ***", 3);
                fsm_debug("    Original:  $original_sv", 3);
                fsm_debug("    Updated:   $substituted_sv", 3);
            } else {
                fsm_debug("  No substitution found for assignment condition: $lhs from $assignment->{dt}", 3);
            }
        }
    }

    fsm_debug("UPDATE_ORIGINAL_ASTS: Updated $updated_count AST expressions with substituted versions", 3);
    fsm_debug("  - DT-specific enable updates: $dt_ast_updates", 3);
    fsm_debug("  - LHS-level enable updates: $lhs_ast_updates", 3);
    fsm_debug("  - Assignment condition updates: $assignment_ast_updates", 3);

    if ($updated_count == 0) {
        fsm_debug("*** WARNING: NO AST UPDATES WERE PERFORMED! This suggests the substitution/update mechanism isn't working! ***", 3);
    }

    return $updated_count;
}

=head2 update_original_asts_with_second_pass_substitutions

Synchronize second-pass substituted ASTs back into the owner-side assignment
and enable structures.

=cut

sub update_original_asts_with_second_pass_substitutions ($self, $second_pass_factorizer) {
    my $ctx = $self->{flattened_dt};

    fsm_debug("UPDATE_SECOND_PASS: Updating original ASTs with second-pass substitutions", 3);

    my $second_pass_context_to_ast = $self->_build_context_to_ast_map(
        $second_pass_factorizer->{ast_expressions},
        debug_prefix => 'UPDATE_SECOND_PASS',
    );
    my $updated_count = 0;

    if ($ctx->{assignment_analysis}) {
        for my $lhs (keys %{$ctx->{assignment_analysis}}) {
            my $lhs_analysis = $ctx->{assignment_analysis}{$lhs};

            for my $rhs (keys %{$lhs_analysis->{rhs_groups}}) {
                my $rhs_group = $lhs_analysis->{rhs_groups}{$rhs};

                for my $dt_enable_info (@{$rhs_group->{dt_specific_enables}}) {
                    my $enable_name = $dt_enable_info->{enable_name};
                    my $context_key = "second_pass_dt_enable:$enable_name";

                    if (exists $second_pass_context_to_ast->{$context_key}) {
                        my $original_ast = $dt_enable_info->{enable_ast};
                        my $substituted_ast = $second_pass_context_to_ast->{$context_key};

                        my $original_sv = eval { $ctx->{enable_graph_ast_support}->ast_to_systemverilog($original_ast) } || "[NO SV REPRESENTATION]";
                        my $substituted_sv = eval { $ctx->{enable_graph_ast_support}->ast_to_systemverilog($substituted_ast) } || "[NO SV REPRESENTATION]";

                        $dt_enable_info->{enable_ast} = $substituted_ast;
                        $updated_count++;

                        fsm_debug("  *** SECOND-PASS UPDATED DT-specific enable AST: $enable_name ***", 3);
                        fsm_debug("    Original:  $original_sv", 3);
                        fsm_debug("    Updated:   $substituted_sv", 3);
                    }
                }

                if ($rhs_group->{lhs_level_enable} && $rhs_group->{lhs_level_enable}{ast}) {
                    my $lhs_enable = $rhs_group->{lhs_level_enable};
                    my $enable_name = $lhs_enable->{name};
                    my $context_key = "second_pass_lhs_enable:$enable_name";

                    if (exists $second_pass_context_to_ast->{$context_key}) {
                        my $original_ast = $lhs_enable->{ast};
                        my $substituted_ast = $second_pass_context_to_ast->{$context_key};

                        my $original_sv = eval { $ctx->{enable_graph_ast_support}->ast_to_systemverilog($original_ast) } || "[NO SV REPRESENTATION]";
                        my $substituted_sv = eval { $ctx->{enable_graph_ast_support}->ast_to_systemverilog($substituted_ast) } || "[NO SV REPRESENTATION]";

                        $lhs_enable->{ast} = $substituted_ast;
                        $updated_count++;

                        fsm_debug("  *** SECOND-PASS UPDATED LHS-level enable AST: $enable_name ***", 3);
                        fsm_debug("    Original:  $original_sv", 3);
                        fsm_debug("    Updated:   $substituted_sv", 3);
                    }
                }
            }
        }
    }

    for my $lhs (keys %{$ctx->{lhs_assignments} || {}}) {
        for my $assignment (@{$ctx->{lhs_assignments}{$lhs}}) {
            next unless $assignment->{conditions_ast} && blessed($assignment->{conditions_ast});

            my $dt_name = $assignment->{dt};
            my $context_key = "second_pass_assignment:$lhs:$dt_name";

            if (exists $second_pass_context_to_ast->{$context_key}) {
                my $original_ast = $assignment->{conditions_ast};
                my $substituted_ast = $second_pass_context_to_ast->{$context_key};

                my $original_sv = eval { $ctx->{enable_graph_ast_support}->ast_to_systemverilog($original_ast) } || "[NO SV REPRESENTATION]";
                my $substituted_sv = eval { $ctx->{enable_graph_ast_support}->ast_to_systemverilog($substituted_ast) } || "[NO SV REPRESENTATION]";

                $assignment->{conditions_ast} = $substituted_ast;
                $updated_count++;

                fsm_debug("  *** SECOND-PASS UPDATED assignment condition AST: $lhs from $dt_name ***", 3);
                fsm_debug("    Original:  $original_sv", 3);
                fsm_debug("    Updated:   $substituted_sv", 3);
            }
        }
    }

    fsm_debug("UPDATE_SECOND_PASS: Updated $updated_count AST expressions with second-pass substitutions", 3);
    return $updated_count;
}

=head2 _build_context_to_ast_map

Build the transient map from factorizer context labels back to substituted AST
objects for synchronization passes.

=cut

sub _build_context_to_ast_map ($self, $ast_expressions, %opts) {
    my %context_to_ast;
    my $debug_prefix = $opts{debug_prefix} // 'CONTEXT_MAP';
    my $log_context_map = $opts{log_context_map} // 0;

    $ast_expressions ||= [];
    fsm_debug("$debug_prefix: Factorizer has " . scalar(@$ast_expressions) . " AST expressions to check against", 3);

    for my $expr_info (@$ast_expressions) {
        my $context = $expr_info->{context};
        my $substituted_ast = $expr_info->{ast};
        $context_to_ast{$context} = $substituted_ast;

        if ($log_context_map) {
            my $sv = eval { $substituted_ast->to_systemverilog() } || "[NO SV REPRESENTATION]";
            fsm_debug("  Context '$context' -> AST: $sv", 3);
        }
    }

    return \%context_to_ast;
}

=head2 ast_contains_signal

Return true when one AST references the given signal name anywhere in the tree.

=cut

sub ast_contains_signal ($self, $ast, $signal_name) {
    my $ctx = $self->{flattened_dt};
    return 0 unless $ast && (blessed($ast) || ref($ast) eq 'HASH');

    if (ref($ast) eq 'HASH' && !blessed($ast)) {
        if (($ast->{type} || '') eq 'signal') {
            my $ast_signal_name = $ast->{name};
            return 1 if $ast_signal_name && $ast_signal_name eq $signal_name;
        }

        for my $key (qw(left right operand condition true_expr false_expr index expression)) {
            my $child = $ast->{$key};
            next unless $child && (blessed($child) || ref($child) eq 'HASH');
            return 1 if $self->ast_contains_signal($child, $signal_name);
        }

        for my $key (qw(operands children arguments expressions parts)) {
            my $children = $ast->{$key};
            next unless ref($children) eq 'ARRAY';
            for my $child (@$children) {
                next unless $child && (blessed($child) || ref($child) eq 'HASH');
                return 1 if $self->ast_contains_signal($child, $signal_name);
            }
        }

        return 0;
    }

    if ($ast->isa('FSM::AST::SignalRef') || $ast->isa('FSM::CoreAST::SignalRef') || $ast->isa('FSM::CoreAST::AggregateRef')) {
        my $ast_signal_name = $ctx->{enable_graph_capture_support}->extract_signal_name_from_ast($ast);
        return 1 if $ast_signal_name && $ast_signal_name eq $signal_name;
    }

    if ($ast->isa('FSM::HDL::IntermediateSignalRef')) {
        my $ast_signal_name = $ast->{signal_name};
        if ($ast_signal_name && $ast_signal_name eq $signal_name) {
            fsm_debug("    FOUND INTERMEDIATE: Signal '$signal_name' found as IntermediateSignalRef", 3);
            return 1;
        }
    }

    if ($ast->isa('FSM::HDL::SubstitutedBinaryOp')) {
        return 1 if $ast->{left} && $self->ast_contains_signal($ast->{left}, $signal_name);
        return 1 if $ast->{right} && $self->ast_contains_signal($ast->{right}, $signal_name);
    } elsif ($ast->isa('FSM::HDL::SubstitutedUnaryOp')) {
        return 1 if $ast->{operand} && $self->ast_contains_signal($ast->{operand}, $signal_name);
    }

    if ($ast->isa('FSM::AST::BinaryOp') || $ast->isa('FSM::CoreAST::BinaryOp')) {
        return 1 if $ast->can('left') && $self->ast_contains_signal($ast->left, $signal_name);
        return 1 if $ast->can('right') && $self->ast_contains_signal($ast->right, $signal_name);
    } elsif ($ast->isa('FSM::AST::UnaryOp') || $ast->isa('FSM::CoreAST::UnaryOp')) {
        return 1 if $ast->can('operand') && $self->ast_contains_signal($ast->operand, $signal_name);
    }

    return 0;
}

=head2 is_signal_referenced_in_substitutions

Return true when one intermediate signal is referenced anywhere in the current
substituted factorizer or owner-side AST state.

=cut

sub is_signal_referenced_in_substitutions ($self, $signal_name) {
    my $ctx = $self->{flattened_dt};

    fsm_debug("REFERENCE_CHECK: Checking if '$signal_name' is referenced in substitutions", 3);

    if ($ctx->{ast_factorizer} && $ctx->{ast_factorizer}->{ast_expressions}) {
        my $ast_expressions = $ctx->{ast_factorizer}->{ast_expressions};
        fsm_debug("  Checking " . scalar(@$ast_expressions) . " factorized expressions");

        for my $expr_info (@$ast_expressions) {
            my $ast = $expr_info->{ast};
            my $context = $expr_info->{context};

            if ($ast && blessed($ast) && $self->ast_contains_signal($ast, $signal_name)) {
                fsm_debug("  REFERENCE FOUND: Signal '$signal_name' is referenced in context '$context'", 3);
                return 1;
            }
        }
    } else {
        fsm_debug("  WARNING: No AST factorizer results available for reference checking", 3);
    }

    if ($ctx->{assignment_analysis}) {
        for my $lhs (keys %{$ctx->{assignment_analysis}}) {
            my $lhs_analysis = $ctx->{assignment_analysis}->{$lhs};

            for my $rhs (keys %{$lhs_analysis->{rhs_groups}}) {
                my $rhs_group = $lhs_analysis->{rhs_groups}->{$rhs};

                for my $dt_enable_info (@{$rhs_group->{dt_specific_enables}}) {
                    my $enable_ast = $dt_enable_info->{enable_ast};
                    if ($enable_ast && blessed($enable_ast) && $self->ast_contains_signal($enable_ast, $signal_name)) {
                        fsm_debug("  REFERENCE FOUND: Signal '$signal_name' in DT enable '$dt_enable_info->{enable_name}'", 3);
                        return 1;
                    }
                }

                if ($rhs_group->{lhs_level_enable} && $rhs_group->{lhs_level_enable}->{ast}) {
                    my $lhs_enable_ast = $rhs_group->{lhs_level_enable}->{ast};
                    if ($lhs_enable_ast && blessed($lhs_enable_ast) && $self->ast_contains_signal($lhs_enable_ast, $signal_name)) {
                        fsm_debug("  REFERENCE FOUND: Signal '$signal_name' in LHS enable '$rhs_group->{lhs_level_enable}->{name}'", 3);
                        return 1;
                    }
                }
            }
        }
    }

    for my $state_name (keys %{$ctx->{state_enables} || {}}) {
        my $enable_ast = $ctx->{state_enables}{$state_name};
        if ($enable_ast && blessed($enable_ast) && $self->ast_contains_signal($enable_ast, $signal_name)) {
            fsm_debug("  REFERENCE FOUND: Signal '$signal_name' in top-level state enable '$state_name'", 3);
            return 1;
        }
    }

    for my $dt_name (keys %{$ctx->{dt_enables} || {}}) {
        my $enable_ast = $ctx->{dt_enables}{$dt_name};
        if ($enable_ast && blessed($enable_ast) && $self->ast_contains_signal($enable_ast, $signal_name)) {
            fsm_debug("  REFERENCE FOUND: Signal '$signal_name' in top-level DT enable '$dt_name'", 3);
            return 1;
        }
    }

    for my $lhs (keys %{$ctx->{lhs_assignments} || {}}) {
        for my $assignment (@{$ctx->{lhs_assignments}->{$lhs}}) {
            if ($assignment->{conditions_ast} && blessed($assignment->{conditions_ast})) {
                if ($self->ast_contains_signal($assignment->{conditions_ast}, $signal_name)) {
                    fsm_debug("  REFERENCE FOUND: Signal '$signal_name' in assignment condition for LHS '$lhs'", 3);
                    return 1;
                }
            }
        }
    }

    fsm_debug("  REFERENCE NOT FOUND: Signal '$signal_name' is not referenced in any substituted expressions", 3);
    return 0;
}

=head2 is_signal_actually_used_in_final_expressions

Return true when one intermediate signal still appears in the final owner-side
enable or assignment-condition ASTs.

=cut

sub is_signal_actually_used_in_final_expressions ($self, $signal_name) {
    my $ctx = $self->{flattened_dt};

    fsm_debug("USAGE_CHECK: Checking if '$signal_name' is actually used in final expressions", 3);

    if ($ctx->{assignment_analysis}) {
        for my $lhs (keys %{$ctx->{assignment_analysis}}) {
            my $lhs_analysis = $ctx->{assignment_analysis}->{$lhs};

            for my $rhs (keys %{$lhs_analysis->{rhs_groups}}) {
                my $rhs_group = $lhs_analysis->{rhs_groups}->{$rhs};

                for my $dt_enable_info (@{$rhs_group->{dt_specific_enables}}) {
                    my $enable_ast = $dt_enable_info->{enable_ast};
                    if ($enable_ast && blessed($enable_ast) && $self->ast_contains_signal($enable_ast, $signal_name)) {
                        fsm_debug("    FOUND: Signal used in DT-specific enable $dt_enable_info->{enable_name}", 3);
                        return 1;
                    }
                }

                if ($rhs_group->{lhs_level_enable} && $rhs_group->{lhs_level_enable}->{ast}) {
                    my $lhs_enable_ast = $rhs_group->{lhs_level_enable}->{ast};
                    if ($lhs_enable_ast && blessed($lhs_enable_ast) && $self->ast_contains_signal($lhs_enable_ast, $signal_name)) {
                        fsm_debug("    FOUND: Signal used in LHS-level enable $rhs_group->{lhs_level_enable}->{name}", 3);
                        return 1;
                    }
                }
            }
        }
    }

    for my $state_name (keys %{$ctx->{state_enables} || {}}) {
        my $enable_ast = $ctx->{state_enables}{$state_name};
        if ($enable_ast && blessed($enable_ast) && $self->ast_contains_signal($enable_ast, $signal_name)) {
            fsm_debug("    FOUND: Signal used in top-level state enable $state_name", 3);
            return 1;
        }
    }

    for my $dt_name (keys %{$ctx->{dt_enables} || {}}) {
        my $enable_ast = $ctx->{dt_enables}{$dt_name};
        if ($enable_ast && blessed($enable_ast) && $self->ast_contains_signal($enable_ast, $signal_name)) {
            fsm_debug("    FOUND: Signal used in top-level DT enable $dt_name", 3);
            return 1;
        }
    }

    for my $lhs (keys %{$ctx->{lhs_assignments} || {}}) {
        for my $assignment (@{$ctx->{lhs_assignments}->{$lhs}}) {
            my $rhs_ast = undef;
            if ($assignment->{rhs} && blessed($assignment->{rhs})) {
                $rhs_ast = $assignment->{rhs};
            } elsif (defined($assignment->{rhs}) && $assignment->{rhs} ne '' && $ctx->{expr_namer} && $ctx->{expr_namer}->can('parse_expression')) {
                $rhs_ast = eval { $ctx->{expr_namer}->parse_expression($assignment->{rhs}) };
            }

            if ($rhs_ast && (blessed($rhs_ast) || ref($rhs_ast) eq 'HASH')) {
                if ($self->ast_contains_signal($rhs_ast, $signal_name)) {
                    fsm_debug("    FOUND: Signal used in assignment RHS for $lhs", 3);
                    return 1;
                }
            }

            if ($assignment->{conditions_ast} && blessed($assignment->{conditions_ast})) {
                if ($self->ast_contains_signal($assignment->{conditions_ast}, $signal_name)) {
                    fsm_debug("    FOUND: Signal used in assignment condition for $lhs", 3);
                    return 1;
                }
            }
        }
    }

    fsm_debug("    NOT FOUND: Signal '$signal_name' is not used in any final expressions", 3);
    return 0;
}

=head2 resolve_intermediate_signal_live_usage

Return cached-or-derived live-usage metadata for one intermediate signal.

=cut

sub resolve_intermediate_signal_live_usage ($self, $signal_name, $signal_info) {
    return {
        referenced_in_substitutions => 0,
        used_in_final_expressions => 0,
        evidence_state => 'none',
        source => 'ast_live_usage_metadata',
    } unless defined($signal_name) && $signal_name ne '';

    if ($signal_info
        && ref($signal_info) eq 'HASH'
        && exists $signal_info->{referenced_in_substitutions}
        && exists $signal_info->{used_in_final_expressions})
    {
        my $evidence_state = $signal_info->{live_usage_evidence_state} || 'none';
        return {
            referenced_in_substitutions => $signal_info->{referenced_in_substitutions} ? 1 : 0,
            used_in_final_expressions => $signal_info->{used_in_final_expressions} ? 1 : 0,
            evidence_state => $evidence_state,
            source => $signal_info->{live_usage_source} || 'ast_live_usage_metadata',
        };
    }

    my $referenced_in_substitutions = $self->is_signal_referenced_in_substitutions($signal_name) ? 1 : 0;
    my $used_in_final_expressions = $self->is_signal_actually_used_in_final_expressions($signal_name) ? 1 : 0;
    my $evidence_state = $referenced_in_substitutions
        ? ($used_in_final_expressions ? 'substitutions_and_final_expressions' : 'substitutions')
        : ($used_in_final_expressions ? 'final_expressions' : 'none');

    if ($signal_info && ref($signal_info) eq 'HASH') {
        $signal_info->{referenced_in_substitutions} = $referenced_in_substitutions;
        $signal_info->{used_in_final_expressions} = $used_in_final_expressions;
        $signal_info->{live_usage_evidence_state} = $evidence_state;
        $signal_info->{live_usage_source} = 'ast_live_usage_metadata';
    }

    fsm_debug("[FactorizationSupport.pm][resolve_intermediate_signal_live_usage()] '$signal_name' live usage => substitutions=$referenced_in_substitutions final_expressions=$used_in_final_expressions ($evidence_state)", 3);
    return {
        referenced_in_substitutions => $referenced_in_substitutions,
        used_in_final_expressions => $used_in_final_expressions,
        evidence_state => $evidence_state,
        source => 'ast_live_usage_metadata',
    };
}

1;
