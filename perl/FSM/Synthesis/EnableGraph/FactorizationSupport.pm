package FSM::Synthesis::EnableGraph::FactorizationSupport;

=head1 NAME

FSM::Synthesis::EnableGraph::FactorizationSupport - Own factorization analysis and substitution support for EnableGraph

=head1 DESCRIPTION

This package owns the bounded factorization-analysis and substitution-synchronization
family that used to live inline inside C<FSM::Synthesis::EnableGraph>. It centralizes:

=over 4

=item *

logical-operation counting and factorizer feed preparation

=item *

second-pass factorization eligibility checks

=item *

substitution synchronization back into owner-side AST structures

=item *

AST-based live-usage evidence for intermediate signals

=item *

high-count logical-operation discovery for factorization policy

=back

The broader synthesis owner still exposes the semantic AST helpers and
planning/report generation APIs around this support family.

=cut

use v5.20;
use strict;
use warnings;
use feature qw(signatures);
no warnings 'experimental::signatures';

use Data::Dumper;
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

=head2 count_binary_logical_operation_occurrences

Count logical sub-expressions across the current owner-side AST set and persist
the counts on the backend context for later factorization policy.

=cut

sub count_binary_logical_operation_occurrences ($self) {
    my $ctx = $self->{flattened_dt};
    my %logical_op_counts;

    fsm_debug("\n*** COUNT_LOGICAL_OPS: STARTING LOGICAL OPERATION COUNTING ***", 3);
    fsm_debug("COUNT_LOGICAL_OPS: This should happen BEFORE any intermediate signal creation!", 3);

    if (exists $ctx->{referenced_intermediate_signals} && %{$ctx->{referenced_intermediate_signals}}) {
        my $prescan_count = scalar(keys %{$ctx->{referenced_intermediate_signals}});
        fsm_debug("*** COUNT_LOGICAL_OPS: WARNING - Pre-scan has already identified $prescan_count intermediate signals! ***", 3);
        fsm_debug("*** This means the logical operation counting is happening TOO LATE! ***", 3);
        fsm_debug("Pre-scan signals: " . join(", ", sort keys %{$ctx->{referenced_intermediate_signals}}));
    } else {
        fsm_debug("COUNT_LOGICAL_OPS: Good - No pre-scan signals created yet", 3);
    }

    fsm_debug("COUNT_LOGICAL_OPS: Counting binary logical operation occurrences", 3);

    my @ast_expressions = $self->collect_all_wen_en_ast_expressions();
    for my $ast_info (@ast_expressions) {
        my $ast = $ast_info->{ast};
        $self->_count_logical_ops_in_ast($ast, \%logical_op_counts);
    }

    for my $signal_name (keys %{$ctx->{intermediate_signals} || {}}) {
        my $ast = $ctx->{enable_graph_intermediate_support}->_get_native_intermediate_signal_ast($signal_name);
        if ($ast && blessed($ast)) {
            $self->_count_logical_ops_in_ast($ast, \%logical_op_counts);
        } else {
            fsm_debug("COUNT_LOGICAL_OPS: Skipping '$signal_name' because no native intermediate AST is available", 3);
        }
    }

    $ctx->{binary_logical_op_counts} = \%logical_op_counts;

    my $total_ops = 0;
    my @high_count_ops;
    for my $op_signature (keys %logical_op_counts) {
        my $count = $logical_op_counts{$op_signature};
        $total_ops += $count;
        fsm_debug("  Logical operation '$op_signature' appears $count times", 3);
        if ($count > 1) {
            push @high_count_ops, "$op_signature ($count times)";
        }
    }

    fsm_debug("COUNT_LOGICAL_OPS: Found $total_ops total logical operations", 3);
    fsm_debug("COUNT_LOGICAL_OPS: Operations appearing multiple times: " . (@high_count_ops ? join(", ", @high_count_ops) : "None"));
    fsm_debug("COUNT_LOGICAL_OPS: Complete counts structure:", 3);
    fsm_debug(Data::Dumper::Dumper(\%logical_op_counts));
    fsm_debug("*** COUNT_LOGICAL_OPS: LOGICAL OPERATION COUNTING COMPLETE ***\n", 3);
    return \%logical_op_counts;
}

=head2 collect_all_wen_en_ast_expressions

Collect the owner-side enable and assignment-condition ASTs that participate in
first-pass factorization.

=cut

sub collect_all_wen_en_ast_expressions ($self) {
    my $ctx = $self->{flattened_dt};
    my @ast_expressions;

    fsm_debug("COLLECT_AST: Collecting all WEN/EN AST expressions", 3);

    if ($ctx->{assignment_analysis}) {
        for my $lhs (keys %{$ctx->{assignment_analysis}}) {
            my $lhs_analysis = $ctx->{assignment_analysis}->{$lhs};

            for my $rhs (keys %{$lhs_analysis->{rhs_groups}}) {
                my $rhs_group = $lhs_analysis->{rhs_groups}->{$rhs};

                for my $dt_enable (@{$rhs_group->{dt_specific_enables} || []}) {
                    if ($dt_enable->{enable_ast}) {
                        push @ast_expressions, {
                            ast => $dt_enable->{enable_ast},
                            context => "dt_enable:$dt_enable->{enable_name}",
                            usage_type => 'dt_enable',
                        };
                    }
                }

                if ($rhs_group->{lhs_level_enable} && $rhs_group->{lhs_level_enable}->{ast}) {
                    push @ast_expressions, {
                        ast => $rhs_group->{lhs_level_enable}->{ast},
                        context => "lhs_enable:$rhs_group->{lhs_level_enable}->{name}",
                        usage_type => 'lhs_enable',
                    };
                }
            }
        }
    }

    for my $lhs (keys %{$ctx->{lhs_assignments} || {}}) {
        for my $assignment (@{$ctx->{lhs_assignments}->{$lhs}}) {
            if ($assignment->{conditions_ast}) {
                push @ast_expressions, {
                    ast => $assignment->{conditions_ast},
                    context => "assignment_condition:$lhs:$assignment->{dt}",
                    usage_type => 'assignment_condition',
                };
            }
        }
    }

    fsm_debug("COLLECT_AST: Collected " . scalar(@ast_expressions) . " AST expressions", 3);
    return @ast_expressions;
}

=head2 feed_asts_to_factorizer

Feed first-pass factorization candidates from the current owner-side AST state
into one C<FSM::HDL::ASTFactorization> instance.

=cut

sub feed_asts_to_factorizer ($self, $factorizer) {
    my $ctx = $self->{flattened_dt};

    fsm_debug("FEED_ASTS: Feeding AST expressions to generic factorizer", 3);

    my $total_fed = 0;
    my $dt_enables_fed = 0;
    my $lhs_enables_fed = 0;
    my $assignment_conditions_fed = 0;

    if ($ctx->{assignment_analysis}) {
        my $total_lhs = scalar(keys %{$ctx->{assignment_analysis}});
        fsm_debug("FEED_ASTS: Processing $total_lhs LHS signals from assignment analysis", 3);

        for my $lhs (keys %{$ctx->{assignment_analysis}}) {
            my $lhs_analysis = $ctx->{assignment_analysis}{$lhs};
            my $rhs_count = scalar(keys %{$lhs_analysis->{rhs_groups}});
            fsm_debug("  LHS '$lhs' has $rhs_count RHS groups", 3);

            for my $rhs (keys %{$lhs_analysis->{rhs_groups}}) {
                my $rhs_group = $lhs_analysis->{rhs_groups}{$rhs};

                my $dt_enable_count = scalar(@{$rhs_group->{dt_specific_enables} || []});
                fsm_debug("    RHS '$rhs' has $dt_enable_count DT-specific enables", 3);

                for my $dt_enable (@{$rhs_group->{dt_specific_enables} || []}) {
                    if ($dt_enable->{enable_ast} && blessed($dt_enable->{enable_ast})) {
                        my $sv = eval { $dt_enable->{enable_ast}->to_systemverilog() } || "[NO SV REPRESENTATION]";

                        $factorizer->add_ast_expression(
                            $dt_enable->{enable_ast},
                            "dt_enable:$dt_enable->{enable_name}"
                        );
                        $total_fed++;
                        $dt_enables_fed++;
                        fsm_debug("  Fed DT-specific AST: $dt_enable->{enable_name}", 3);
                        fsm_debug("    Expression: $sv", 3);
                    } else {
                        fsm_debug("  SKIPPED DT-specific enable (no AST): $dt_enable->{enable_name}", 3);
                    }
                }

                if ($rhs_group->{lhs_level_enable}) {
                    my $lhs_enable = $rhs_group->{lhs_level_enable};
                    if ($lhs_enable->{ast} && blessed($lhs_enable->{ast})) {
                        my $sv = eval { $lhs_enable->{ast}->to_systemverilog() } || "[NO SV REPRESENTATION]";

                        $factorizer->add_ast_expression(
                            $lhs_enable->{ast},
                            "lhs_enable:$lhs_enable->{name}"
                        );
                        $total_fed++;
                        $lhs_enables_fed++;
                        fsm_debug("  Fed LHS-level AST: $lhs_enable->{name}", 3);
                        fsm_debug("    Expression: $sv", 3);
                    } else {
                        fsm_debug("  SKIPPED LHS-level enable (no AST): $lhs_enable->{name}", 3);
                    }
                }
            }
        }
    } else {
        fsm_debug("*** WARNING: No assignment_analysis available for AST feeding! ***", 3);
    }

    my $total_assignments = 0;
    for my $lhs (keys %{$ctx->{lhs_assignments} || {}}) {
        $total_assignments += scalar(@{$ctx->{lhs_assignments}{$lhs}});
    }

    fsm_debug("FEED_ASTS: Processing $total_assignments assignment conditions", 3);

    for my $lhs (keys %{$ctx->{lhs_assignments} || {}}) {
        for my $assignment (@{$ctx->{lhs_assignments}{$lhs}}) {
            if ($assignment->{conditions_ast} && blessed($assignment->{conditions_ast})) {
                my $sv = eval { $assignment->{conditions_ast}->to_systemverilog() } || "[NO SV REPRESENTATION]";

                $factorizer->add_ast_expression(
                    $assignment->{conditions_ast},
                    "assignment_condition:$lhs:$assignment->{dt}"
                );
                $total_fed++;
                $assignment_conditions_fed++;
                fsm_debug("  Fed assignment condition AST: $lhs from $assignment->{dt}", 3);
                fsm_debug("    Expression: $sv", 3);
            }
        }
    }

    my $fsmgen_intermediate_fed = 0;
    if ($ctx->{fsm_module} && $ctx->{fsm_module}->can('signals') && $ctx->{fsm_module}->signals) {
        fsm_debug("FEED_ASTS: Processing FSMGenFull intermediate signals", 3);
        my $fsm_signals = $ctx->{fsm_module}->signals;

        for my $signal_name (keys %$fsm_signals) {
            my $signal = $fsm_signals->{$signal_name};

            if ($signal && $signal->can('driving_ast') && $signal->driving_ast) {
                my $is_intermediate = 0;
                if ($signal->can('get_attribute')) {
                    $is_intermediate = $signal->get_attribute('is_intermediate');
                } elsif ($signal->can('attributes') && $signal->attributes) {
                    $is_intermediate = $signal->attributes->{is_intermediate};
                }

                if ($is_intermediate) {
                    my $driving_ast = $signal->driving_ast;
                    if (blessed($driving_ast)) {
                        my $sv = eval { $driving_ast->to_systemverilog() } || "[NO SV REPRESENTATION]";

                        $factorizer->add_ast_expression(
                            $driving_ast,
                            "fsmgen_intermediate:$signal_name"
                        );
                        $total_fed++;
                        $fsmgen_intermediate_fed++;
                        fsm_debug("  Fed FSMGenFull intermediate AST: $signal_name", 3);
                        fsm_debug("    Expression: $sv", 3);
                    }
                }
            }
        }
    }

    fsm_debug("FEED_ASTS: Total ASTs fed to factorizer: $total_fed", 3);
    fsm_debug("  - DT-specific enables: $dt_enables_fed", 3);
    fsm_debug("  - LHS-level enables: $lhs_enables_fed", 3);
    fsm_debug("  - Assignment conditions: $assignment_conditions_fed", 3);
    fsm_debug("  - FSMGenFull intermediate signals: $fsmgen_intermediate_fed", 3);

    return $total_fed;
}

=head2 _count_logical_ops_in_ast

Walk one AST recursively and count factorizable logical sub-expressions.

=cut

sub _count_logical_ops_in_ast ($self, $ast, $counts_ref) {
    my $ctx = $self->{flattened_dt};
    return unless $ast && blessed($ast);

    if ($self->_is_factorizable_sub_expression($ast)) {
        my $signature = eval { $ast->to_systemverilog() } || 'unknown';
        $counts_ref->{$signature}++;
        fsm_debug("    Found factorizable sub-expression: '$signature' (count: $counts_ref->{$signature})", 3);
    }

    if ($ast->isa('FSM::AST::BinaryOp') || $ast->isa('FSM::CoreAST::BinaryOp')) {
        $self->_count_logical_ops_in_ast($ast->left, $counts_ref) if $ast->can('left');
        $self->_count_logical_ops_in_ast($ast->right, $counts_ref) if $ast->can('right');
    } elsif ($ast->isa('FSM::AST::UnaryOp') || $ast->isa('FSM::CoreAST::UnaryOp')) {
        $self->_count_logical_ops_in_ast($ast->operand, $counts_ref) if $ast->can('operand');
    }
}

=head2 _is_factorizable_sub_expression

Return true when one AST should count as a factorizable sub-expression under
the current logical-operation usage policy.

=cut

sub _is_factorizable_sub_expression ($self, $ast) {
    my $ctx = $self->{flattened_dt};
    return 0 unless $ast && blessed($ast);

    if ($ast->isa('FSM::AST::Literal') || $ast->isa('FSM::CoreAST::Literal')) {
        return 0;
    }
    if ($ast->isa('FSM::AST::SignalRef') || $ast->isa('FSM::CoreAST::SignalRef')) {
        return 0;
    }

    if ($ast->isa('FSM::AST::UnaryOp') || $ast->isa('FSM::CoreAST::UnaryOp')) {
        fsm_debug("FACTORIZABLE: Unary operation - ALWAYS FACTOR", 3);
        return 1;
    }

    if ($ast->isa('FSM::AST::BinaryOp') || $ast->isa('FSM::CoreAST::BinaryOp')) {
        if ($ctx->{enable_graph}->is_arithmetic_operation($ast)) {
            fsm_debug("FACTORIZABLE: Arithmetic operation - ALWAYS FACTOR", 3);
            return 1;
        }

        if ($ctx->{enable_graph}->is_logical_operation($ast)) {
            my $signature = eval { $ast->to_systemverilog() } || 'unknown';
            my $count = ($ctx->{binary_logical_op_counts} || {})->{$signature} || 0;
            if ($count > 1) {
                fsm_debug("FACTORIZABLE: Logical operation '$signature' used $count times - FACTOR", 3);
                return 1;
            } else {
                fsm_debug("FACTORIZABLE: Logical operation '$signature' used only $count time - DON'T FACTOR", 3);
                return 0;
            }
        }

        fsm_debug("FACTORIZABLE: Other binary operation - ALWAYS FACTOR", 3);
        return 1;
    }

    return 1;
}

=head2 feed_current_asts_to_second_pass

Feed only the current AST expressions that still depend on intermediate
signals into one second-pass factorizer.

=cut

sub feed_current_asts_to_second_pass ($self, $second_pass_factorizer) {
    my $ctx = $self->{flattened_dt};

    fsm_debug("SECOND_PASS_FEED: Collecting current AST expressions", 3);

    my $total_fed = 0;

    if ($ctx->{assignment_analysis}) {
        for my $lhs (keys %{$ctx->{assignment_analysis}}) {
            my $lhs_analysis = $ctx->{assignment_analysis}{$lhs};

            for my $rhs (keys %{$lhs_analysis->{rhs_groups}}) {
                my $rhs_group = $lhs_analysis->{rhs_groups}{$rhs};

                for my $dt_enable (@{$rhs_group->{dt_specific_enables} || []}) {
                    if ($dt_enable->{enable_ast} && blessed($dt_enable->{enable_ast})) {
                        my $sv = eval { $ctx->{enable_graph}->ast_to_systemverilog($dt_enable->{enable_ast}) } || "[NO SV REPRESENTATION]";

                        if ($self->ast_contains_intermediate_signals($dt_enable->{enable_ast})) {
                            $second_pass_factorizer->add_ast_expression(
                                $dt_enable->{enable_ast},
                                "second_pass_dt_enable:$dt_enable->{enable_name}"
                            );
                            $total_fed++;
                            fsm_debug("  Fed second-pass DT enable: $dt_enable->{enable_name}", 3);
                            fsm_debug("    Expression: $sv", 3);
                        }
                    }
                }

                if ($rhs_group->{lhs_level_enable} && $rhs_group->{lhs_level_enable}{ast}) {
                    my $lhs_enable = $rhs_group->{lhs_level_enable};
                    if (blessed($lhs_enable->{ast})) {
                        my $sv = eval { $ctx->{enable_graph}->ast_to_systemverilog($lhs_enable->{ast}) } || "[NO SV REPRESENTATION]";

                        if ($self->ast_contains_intermediate_signals($lhs_enable->{ast})) {
                            $second_pass_factorizer->add_ast_expression(
                                $lhs_enable->{ast},
                                "second_pass_lhs_enable:$lhs_enable->{name}"
                            );
                            $total_fed++;
                            fsm_debug("  Fed second-pass LHS enable: $lhs_enable->{name}", 3);
                            fsm_debug("    Expression: $sv", 3);
                        }
                    }
                }
            }
        }
    }

    for my $lhs (keys %{$ctx->{lhs_assignments} || {}}) {
        for my $assignment (@{$ctx->{lhs_assignments}{$lhs}}) {
            if ($assignment->{conditions_ast} && blessed($assignment->{conditions_ast})) {
                my $sv = eval { $ctx->{enable_graph}->ast_to_systemverilog($assignment->{conditions_ast}) } || "[NO SV REPRESENTATION]";

                if ($self->ast_contains_intermediate_signals($assignment->{conditions_ast})) {
                    $second_pass_factorizer->add_ast_expression(
                        $assignment->{conditions_ast},
                        "second_pass_assignment:$lhs:$assignment->{dt}"
                    );
                    $total_fed++;
                    fsm_debug("  Fed second-pass assignment condition: $lhs from $assignment->{dt}", 3);
                    fsm_debug("    Expression: $sv", 3);
                }
            }
        }
    }

    fsm_debug("SECOND_PASS_FEED: Fed $total_fed expressions to second-pass factorizer", 3);
    return $total_fed;
}

=head2 ast_contains_intermediate_signals

Return true when one compound AST still depends on intermediate signals and is
therefore eligible for second-pass factorization.

=cut

sub ast_contains_intermediate_signals ($self, $ast) {
    my $ctx = $self->{flattened_dt};
    return 0 unless $ast && blessed($ast);

    if ($ast->isa('FSM::AST::SignalRef') || $ast->isa('FSM::CoreAST::SignalRef')) {
        my $signal_name = $ctx->{enable_graph}->extract_signal_name_from_ast($ast) || 'unknown';
        my $ast_sv = eval { $ctx->{enable_graph}->ast_to_systemverilog($ast) } || 'unknown';
        fsm_debug("  SECOND_PASS_FILTER: Bare signal reference '$signal_name' (AST: $ast_sv) - NOT factorizable", 3);
        return 0;
    }

    if ($ast->isa('FSM::HDL::IntermediateSignalRef')) {
        my $signal_name = $ast->{signal_name} || 'unknown';
        my $ast_sv = eval { $ctx->{enable_graph}->ast_to_systemverilog($ast) } || 'unknown';
        fsm_debug("  SECOND_PASS_FILTER: Bare intermediate signal reference '$signal_name' (AST: $ast_sv) - NOT factorizable", 3);
        return 0;
    }

    my $is_compound_with_intermediates = 0;

    if ($ast->isa('FSM::AST::BinaryOp') || $ast->isa('FSM::CoreAST::BinaryOp')) {
        my $left_has_intermediate = $ast->can('left') && $self->ast_has_intermediate_signals_recursive($ast->left);
        my $right_has_intermediate = $ast->can('right') && $self->ast_has_intermediate_signals_recursive($ast->right);

        if ($left_has_intermediate || $right_has_intermediate) {
            fsm_debug("  SECOND_PASS_FILTER: Compound binary expression contains intermediate signals - factorizable", 3);
            $is_compound_with_intermediates = 1;
        } else {
            fsm_debug("  SECOND_PASS_FILTER: Compound binary expression has no intermediate signals - not factorizable", 3);
        }
    } elsif ($ast->isa('FSM::AST::UnaryOp') || $ast->isa('FSM::CoreAST::UnaryOp')) {
        my $operand_has_intermediate = $ast->can('operand') && $self->ast_has_intermediate_signals_recursive($ast->operand);

        if ($operand_has_intermediate) {
            fsm_debug("  SECOND_PASS_FILTER: Compound unary expression contains intermediate signals - factorizable", 3);
            $is_compound_with_intermediates = 1;
        } else {
            fsm_debug("  SECOND_PASS_FILTER: Compound unary expression has no intermediate signals - not factorizable", 3);
        }
    } else {
        fsm_debug("  SECOND_PASS_FILTER: Not a compound expression - NOT factorizable", 3);
    }

    return $is_compound_with_intermediates;
}

=head2 ast_has_intermediate_signals_recursive

Return true when one AST subtree contains at least one intermediate signal
reference.

=cut

sub ast_has_intermediate_signals_recursive ($self, $ast) {
    my $ctx = $self->{flattened_dt};
    return 0 unless $ast && blessed($ast);

    if ($ast->isa('FSM::AST::SignalRef') || $ast->isa('FSM::CoreAST::SignalRef')) {
        my $signal_name = $ctx->{enable_graph}->extract_signal_name_from_ast($ast);
        if ($signal_name && $ctx->{enable_graph}->is_intermediate_signal($signal_name)) {
            return 1;
        }
    }

    if ($ast->isa('FSM::HDL::IntermediateSignalRef')) {
        return 1;
    }

    if ($ast->isa('FSM::AST::BinaryOp') || $ast->isa('FSM::CoreAST::BinaryOp')) {
        return 1 if $ast->can('left') && $self->ast_has_intermediate_signals_recursive($ast->left);
        return 1 if $ast->can('right') && $self->ast_has_intermediate_signals_recursive($ast->right);
    } elsif ($ast->isa('FSM::AST::UnaryOp') || $ast->isa('FSM::CoreAST::UnaryOp')) {
        return 1 if $ast->can('operand') && $self->ast_has_intermediate_signals_recursive($ast->operand);
    }

    return 0;
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

                        my $original_sv = eval { $ctx->{enable_graph}->ast_to_systemverilog($original_ast) } || "[NO SV REPRESENTATION]";
                        my $substituted_sv = eval { $ctx->{enable_graph}->ast_to_systemverilog($substituted_ast) } || "[NO SV REPRESENTATION]";

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

                        my $original_sv = eval { $ctx->{enable_graph}->ast_to_systemverilog($original_ast) } || "[NO SV REPRESENTATION]";
                        my $substituted_sv = eval { $ctx->{enable_graph}->ast_to_systemverilog($substituted_ast) } || "[NO SV REPRESENTATION]";

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

                my $original_sv = eval { $ctx->{enable_graph}->ast_to_systemverilog($original_ast) } || "[NO SV REPRESENTATION]";
                my $substituted_sv = eval { $ctx->{enable_graph}->ast_to_systemverilog($substituted_ast) } || "[NO SV REPRESENTATION]";

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

                        my $original_sv = eval { $ctx->{enable_graph}->ast_to_systemverilog($original_ast) } || "[NO SV REPRESENTATION]";
                        my $substituted_sv = eval { $ctx->{enable_graph}->ast_to_systemverilog($substituted_ast) } || "[NO SV REPRESENTATION]";

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

                        my $original_sv = eval { $ctx->{enable_graph}->ast_to_systemverilog($original_ast) } || "[NO SV REPRESENTATION]";
                        my $substituted_sv = eval { $ctx->{enable_graph}->ast_to_systemverilog($substituted_ast) } || "[NO SV REPRESENTATION]";

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

                my $original_sv = eval { $ctx->{enable_graph}->ast_to_systemverilog($original_ast) } || "[NO SV REPRESENTATION]";
                my $substituted_sv = eval { $ctx->{enable_graph}->ast_to_systemverilog($substituted_ast) } || "[NO SV REPRESENTATION]";

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
    return 0 unless $ast && blessed($ast);

    if ($ast->isa('FSM::AST::SignalRef') || $ast->isa('FSM::CoreAST::SignalRef')) {
        my $ast_signal_name = $ctx->{enable_graph}->extract_signal_name_from_ast($ast);
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

    for my $lhs (keys %{$ctx->{lhs_assignments} || {}}) {
        for my $assignment (@{$ctx->{lhs_assignments}->{$lhs}}) {
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

=head2 contains_frequently_used_operations

Return true when one AST contains any logical operation whose usage count is
high enough to justify factorization.

=cut

sub contains_frequently_used_operations ($self, $ast, $visited_signal_names = undef) {
    my $ctx = $self->{flattened_dt};
    return 0 unless $ast && blessed($ast);
    return 0 unless exists $ctx->{binary_logical_op_counts};

    $visited_signal_names //= {};

    my $result = $self->_ast_contains_frequently_used_logical_operation($ast, $visited_signal_names);
    my $ast_str = eval { $ctx->{enable_graph}->ast_to_systemverilog($ast) } || eval { $ast->to_systemverilog() } || ref($ast) || 'unknown_ast';

    if ($result) {
        fsm_debug("[FactorizationSupport.pm][contains_frequently_used_operations()] Expression '$ast_str' contains high-count logical operations - FACTOR", 3);
    } else {
        fsm_debug("[FactorizationSupport.pm][contains_frequently_used_operations()] Expression '$ast_str' contains no high-count logical operations - DON'T FACTOR", 3);
    }

    return $result;
}

=head2 _ast_contains_frequently_used_logical_operation

Recursive implementation for high-count logical-operation discovery, including
descent through intermediate-signal definitions when needed.

=cut

sub _ast_contains_frequently_used_logical_operation ($self, $ast, $visited_signal_names) {
    my $ctx = $self->{flattened_dt};
    return 0 unless $ast && blessed($ast);
    return 0 unless exists $ctx->{binary_logical_op_counts};

    if ($ctx->{enable_graph}->is_logical_operation($ast)) {
        my $signature = eval { $ast->to_systemverilog() } || eval { $ctx->{enable_graph}->ast_to_systemverilog($ast) } || '';
        my $count = $ctx->{binary_logical_op_counts}{$signature} || 0;
        if ($count > 1) {
            fsm_debug("[FactorizationSupport.pm][_ast_contains_frequently_used_logical_operation()] Found high-count logical op '$signature' ($count uses)", 3);
            return 1;
        }
    }

    my $signal_name;
    if ($ast->isa('FSM::HDL::IntermediateSignalRef')) {
        $signal_name = eval { $ast->signal_name } || $ast->{signal_name};
    } elsif ($ast->isa('FSM::AST::SignalRef') || $ast->isa('FSM::CoreAST::SignalRef')) {
        $signal_name = $ctx->{enable_graph}->extract_signal_name_from_ast($ast);
    }

    if (defined $signal_name && $signal_name ne '' && $ctx->{enable_graph}->is_intermediate_signal($signal_name)) {
        if ($visited_signal_names->{$signal_name}) {
            fsm_debug("[FactorizationSupport.pm][_ast_contains_frequently_used_logical_operation()] Skipping already-visited intermediate '$signal_name' to avoid recursion", 3);
        } else {
            $visited_signal_names->{$signal_name} = 1;
            my $intermediate_ast = $ctx->{enable_graph_intermediate_support}->get_intermediate_signal_ast($signal_name);
            if ($intermediate_ast && blessed($intermediate_ast)) {
                fsm_debug("[FactorizationSupport.pm][_ast_contains_frequently_used_logical_operation()] Descending into intermediate '$signal_name' AST", 3);
                if ($self->_ast_contains_frequently_used_logical_operation($intermediate_ast, $visited_signal_names)) {
                    delete $visited_signal_names->{$signal_name};
                    return 1;
                }
            }
            delete $visited_signal_names->{$signal_name};
        }
    }

    for my $accessor (qw(left right operand)) {
        next unless $ast->can($accessor);
        my $child = eval { $ast->$accessor() };
        next unless $child && blessed($child);
        return 1 if $self->_ast_contains_frequently_used_logical_operation($child, $visited_signal_names);
    }

    for my $accessor (qw(operands children)) {
        next unless $ast->can($accessor);
        my $children = eval { $ast->$accessor() };
        next unless ref($children) eq 'ARRAY';
        for my $child (@$children) {
            next unless $child && blessed($child);
            return 1 if $self->_ast_contains_frequently_used_logical_operation($child, $visited_signal_names);
        }
    }

    return 0;
}

1;
