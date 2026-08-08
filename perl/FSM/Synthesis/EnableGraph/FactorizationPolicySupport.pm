package FSM::Synthesis::EnableGraph::FactorizationPolicySupport;

=head1 NAME

FSM::Synthesis::EnableGraph::FactorizationPolicySupport - Own factorization policy, AST feed, and second-pass eligibility support for EnableGraph

=head1 DESCRIPTION

This package owns the bounded factorization-policy family around the older
direct synthesis/backend path. It centralizes:

=over 4

=item *

logical-operation counting over the prepared owner-side AST set

=item *

first-pass AST collection and factorizer feed preparation

=item *

second-pass AST feed and intermediate-signal eligibility checks

=item *

high-count logical-operation discovery for factorization policy

=back

The paired C<FSM::Synthesis::EnableGraph::FactorizationSupport> owner now keeps
the substitution-synchronization and live-usage-evidence family, while this
package owns the policy and feed side of the factorization flow.

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

Construct a factorization-policy support owner bound to one live
C<FSM::HDL::FlattenedDT> context.

=cut

sub new ($class, %args) {
    my $flattened_dt = $args{flattened_dt}
      or die "[FactorizationPolicySupport.pm][new()] Missing required 'flattened_dt' argument";

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
        fsm_warn("COUNT_LOGICAL_OPS: Pre-scan has already identified $prescan_count intermediate signals!");
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

    for my $state_name (sort keys %{$ctx->{state_enables} || {}}) {
        my $enable_ast = $ctx->{state_enables}{$state_name};
        next unless $enable_ast && blessed($enable_ast);

        push @ast_expressions, {
            ast => $enable_ast,
            context => "top_state_enable:$state_name",
            usage_type => 'top_state_enable',
        };
    }

    for my $dt_name (sort keys %{$ctx->{dt_enables} || {}}) {
        my $enable_ast = $ctx->{dt_enables}{$dt_name};
        next unless $enable_ast && blessed($enable_ast);

        push @ast_expressions, {
            ast => $enable_ast,
            context => "top_dt_enable:$dt_name",
            usage_type => 'top_dt_enable',
        };
    }

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
    my $top_state_enables_fed = 0;
    my $top_dt_enables_fed = 0;
    my $dt_enables_fed = 0;
    my $lhs_enables_fed = 0;
    my $assignment_conditions_fed = 0;

    for my $state_name (sort keys %{$ctx->{state_enables} || {}}) {
        my $enable_ast = $ctx->{state_enables}{$state_name};
        next unless $enable_ast && blessed($enable_ast);

        my $sv = eval { $ctx->{enable_graph_ast_support}->ast_to_systemverilog($enable_ast) }
            || eval { $enable_ast->to_systemverilog() }
            || "[NO SV REPRESENTATION]";
        $factorizer->add_ast_expression($enable_ast, "top_state_enable:$state_name");
        $total_fed++;
        $top_state_enables_fed++;
        fsm_debug("  Fed top-level state enable AST: $state_name", 3);
        fsm_debug("    Expression: $sv", 3);
    }

    for my $dt_name (sort keys %{$ctx->{dt_enables} || {}}) {
        my $enable_ast = $ctx->{dt_enables}{$dt_name};
        next unless $enable_ast && blessed($enable_ast);

        my $sv = eval { $ctx->{enable_graph_ast_support}->ast_to_systemverilog($enable_ast) }
            || eval { $enable_ast->to_systemverilog() }
            || "[NO SV REPRESENTATION]";
        $factorizer->add_ast_expression($enable_ast, "top_dt_enable:$dt_name");
        $total_fed++;
        $top_dt_enables_fed++;
        fsm_debug("  Fed top-level DT enable AST: $dt_name", 3);
        fsm_debug("    Expression: $sv", 3);
    }

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
        fsm_warn("No assignment_analysis available for AST feeding!");
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
    fsm_debug("  - Top-level state enables: $top_state_enables_fed", 3);
    fsm_debug("  - Top-level DT enables: $top_dt_enables_fed", 3);
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
    if ($ast->isa('FSM::CoreAST::ParameterRef')) {
        return 0;
    }
    if ($ast->isa('FSM::CoreAST::AggregateRef')) {
        return 0;
    }

    if ($ast->isa('FSM::AST::UnaryOp') || $ast->isa('FSM::CoreAST::UnaryOp')) {
        fsm_debug("FACTORIZABLE: Unary operation - ALWAYS FACTOR", 3);
        return 1;
    }

    if ($ast->isa('FSM::AST::BinaryOp') || $ast->isa('FSM::CoreAST::BinaryOp')) {
        if ($ctx->{enable_graph_ast_support}->is_arithmetic_operation($ast)) {
            fsm_debug("FACTORIZABLE: Arithmetic operation - ALWAYS FACTOR", 3);
            return 1;
        }

        if ($ctx->{enable_graph_ast_support}->is_logical_operation($ast)) {
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

    for my $state_name (sort keys %{$ctx->{state_enables} || {}}) {
        my $enable_ast = $ctx->{state_enables}{$state_name};
        next unless $enable_ast && blessed($enable_ast);

        my $sv = eval { $ctx->{enable_graph_ast_support}->ast_to_systemverilog($enable_ast) }
            || "[NO SV REPRESENTATION]";
        if ($self->ast_contains_intermediate_signals($enable_ast)) {
            $second_pass_factorizer->add_ast_expression(
                $enable_ast,
                "second_pass_top_state_enable:$state_name",
            );
            $total_fed++;
            fsm_debug("  Fed second-pass top-level state enable: $state_name", 3);
            fsm_debug("    Expression: $sv", 3);
        }
    }

    for my $dt_name (sort keys %{$ctx->{dt_enables} || {}}) {
        my $enable_ast = $ctx->{dt_enables}{$dt_name};
        next unless $enable_ast && blessed($enable_ast);

        my $sv = eval { $ctx->{enable_graph_ast_support}->ast_to_systemverilog($enable_ast) }
            || "[NO SV REPRESENTATION]";
        if ($self->ast_contains_intermediate_signals($enable_ast)) {
            $second_pass_factorizer->add_ast_expression(
                $enable_ast,
                "second_pass_top_dt_enable:$dt_name",
            );
            $total_fed++;
            fsm_debug("  Fed second-pass top-level DT enable: $dt_name", 3);
            fsm_debug("    Expression: $sv", 3);
        }
    }

    if ($ctx->{assignment_analysis}) {
        for my $lhs (keys %{$ctx->{assignment_analysis}}) {
            my $lhs_analysis = $ctx->{assignment_analysis}{$lhs};

            for my $rhs (keys %{$lhs_analysis->{rhs_groups}}) {
                my $rhs_group = $lhs_analysis->{rhs_groups}{$rhs};

                for my $dt_enable (@{$rhs_group->{dt_specific_enables} || []}) {
                    if ($dt_enable->{enable_ast} && blessed($dt_enable->{enable_ast})) {
                        my $sv = eval { $ctx->{enable_graph_ast_support}->ast_to_systemverilog($dt_enable->{enable_ast}) } || "[NO SV REPRESENTATION]";

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
                        my $sv = eval { $ctx->{enable_graph_ast_support}->ast_to_systemverilog($lhs_enable->{ast}) } || "[NO SV REPRESENTATION]";

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
            my $rhs_ast = undef;
            if ($assignment->{rhs} && blessed($assignment->{rhs})) {
                $rhs_ast = $assignment->{rhs};
            } elsif (defined($assignment->{rhs}) && $assignment->{rhs} ne '' && $ctx->{expr_namer} && $ctx->{expr_namer}->can('parse_expression')) {
                $rhs_ast = eval { $ctx->{expr_namer}->parse_expression($assignment->{rhs}) };
            }

            if ($rhs_ast && (blessed($rhs_ast) || ref($rhs_ast) eq 'HASH')) {
                my $sv = eval { $ctx->{enable_graph_ast_support}->ast_to_systemverilog($rhs_ast) } || "[NO SV REPRESENTATION]";

                if ($self->ast_contains_intermediate_signals($rhs_ast)) {
                    $second_pass_factorizer->add_ast_expression(
                        $rhs_ast,
                        "second_pass_assignment_rhs:$lhs:$assignment->{dt}"
                    );
                    $total_fed++;
                    fsm_debug("  Fed second-pass assignment RHS: $lhs from $assignment->{dt}", 3);
                    fsm_debug("    Expression: $sv", 3);
                }
            }

            if ($assignment->{conditions_ast} && blessed($assignment->{conditions_ast})) {
                my $sv = eval { $ctx->{enable_graph_ast_support}->ast_to_systemverilog($assignment->{conditions_ast}) } || "[NO SV REPRESENTATION]";

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
    return 0 unless $ast && (blessed($ast) || ref($ast) eq 'HASH');

    if (ref($ast) eq 'HASH' && !blessed($ast)) {
        if (($ast->{type} || '') eq 'signal') {
            my $signal_name = $ast->{name} || 'unknown';
            my $ast_sv = $signal_name;
            fsm_debug("  SECOND_PASS_FILTER: Bare signal reference '$signal_name' (AST: $ast_sv) - NOT factorizable", 3);
            return 0;
        }

        my $is_compound_with_intermediates = 0;
        if (($ast->{type} || '') eq 'binary_op') {
            my $left_has_intermediate = $ast->{left} && $self->ast_has_intermediate_signals_recursive($ast->{left});
            my $right_has_intermediate = $ast->{right} && $self->ast_has_intermediate_signals_recursive($ast->{right});

            if ($left_has_intermediate || $right_has_intermediate) {
                fsm_debug("  SECOND_PASS_FILTER: Compound binary expression contains intermediate signals - factorizable", 3);
                $is_compound_with_intermediates = 1;
            } else {
                fsm_debug("  SECOND_PASS_FILTER: Compound binary expression has no intermediate signals - not factorizable", 3);
            }
        } elsif (($ast->{type} || '') eq 'unary_op') {
            my $operand_has_intermediate = $ast->{operand} && $self->ast_has_intermediate_signals_recursive($ast->{operand});

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

    if ($ast->isa('FSM::AST::SignalRef') || $ast->isa('FSM::CoreAST::SignalRef') || $ast->isa('FSM::CoreAST::AggregateRef') || $ast->isa('FSM::CoreAST::ParameterRef')) {
        my $signal_name = $ctx->{enable_graph_capture_support}->extract_signal_name_from_ast($ast) || 'unknown';
        my $ast_sv = eval { $ctx->{enable_graph_ast_support}->ast_to_systemverilog($ast) } || 'unknown';
        fsm_debug("  SECOND_PASS_FILTER: Bare signal reference '$signal_name' (AST: $ast_sv) - NOT factorizable", 3);
        return 0;
    }

    if ($ast->isa('FSM::HDL::IntermediateSignalRef')) {
        my $signal_name = $ast->{signal_name} || 'unknown';
        my $ast_sv = eval { $ctx->{enable_graph_ast_support}->ast_to_systemverilog($ast) } || 'unknown';
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
    return 0 unless $ast && (blessed($ast) || ref($ast) eq 'HASH');

    if (ref($ast) eq 'HASH' && !blessed($ast)) {
        if (($ast->{type} || '') eq 'signal') {
            my $signal_name = $ast->{name};
            if ($signal_name && $ctx->{enable_graph_signal_support}->is_intermediate_signal($signal_name)) {
                return 1;
            }
        }

        for my $key (qw(left right operand condition true_expr false_expr index expression)) {
            my $child = $ast->{$key};
            next unless $child && (blessed($child) || ref($child) eq 'HASH');
            return 1 if $self->ast_has_intermediate_signals_recursive($child);
        }

        for my $key (qw(operands children arguments expressions parts)) {
            my $children = $ast->{$key};
            next unless ref($children) eq 'ARRAY';
            for my $child (@$children) {
                next unless $child && (blessed($child) || ref($child) eq 'HASH');
                return 1 if $self->ast_has_intermediate_signals_recursive($child);
            }
        }

        return 0;
    }

    if ($ast->isa('FSM::AST::SignalRef') || $ast->isa('FSM::CoreAST::SignalRef') || $ast->isa('FSM::CoreAST::AggregateRef')) {
        my $signal_name = $ctx->{enable_graph_capture_support}->extract_signal_name_from_ast($ast);
        if ($signal_name && $ctx->{enable_graph_signal_support}->is_intermediate_signal($signal_name)) {
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
    if (debug_enabled() && debug_level() >= 3) {
        my $ast_str = eval { $ctx->{enable_graph_ast_support}->ast_to_systemverilog($ast) }
            || eval { $ast->to_systemverilog() }
            || ref($ast)
            || 'unknown_ast';

        if ($result) {
            fsm_debug("[FactorizationPolicySupport.pm][contains_frequently_used_operations()] Expression '$ast_str' contains high-count logical operations - FACTOR", 3);
        } else {
            fsm_debug("[FactorizationPolicySupport.pm][contains_frequently_used_operations()] Expression '$ast_str' contains no high-count logical operations - DON'T FACTOR", 3);
        }
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

    if ($ctx->{enable_graph_ast_support}->is_logical_operation($ast)) {
        my $signature = eval { $ast->to_systemverilog() } || eval { $ctx->{enable_graph_ast_support}->ast_to_systemverilog($ast) } || '';
        my $count = $ctx->{binary_logical_op_counts}{$signature} || 0;
        if ($count > 1) {
            fsm_debug("[FactorizationPolicySupport.pm][_ast_contains_frequently_used_logical_operation()] Found high-count logical op '$signature' ($count uses)", 3);
            return 1;
        }
    }

    my $signal_name;
    if ($ast->isa('FSM::HDL::IntermediateSignalRef')) {
        $signal_name = eval { $ast->signal_name } || $ast->{signal_name};
    } elsif ($ast->isa('FSM::AST::SignalRef') || $ast->isa('FSM::CoreAST::SignalRef') || $ast->isa('FSM::CoreAST::AggregateRef')) {
        $signal_name = $ctx->{enable_graph_capture_support}->extract_signal_name_from_ast($ast);
    }

    if (defined $signal_name && $signal_name ne '' && $ctx->{enable_graph_signal_support}->is_intermediate_signal($signal_name)) {
        if ($visited_signal_names->{$signal_name}) {
            fsm_debug("[FactorizationPolicySupport.pm][_ast_contains_frequently_used_logical_operation()] Skipping already-visited intermediate '$signal_name' to avoid recursion", 3);
        } else {
            $visited_signal_names->{$signal_name} = 1;
            my $intermediate_ast = $ctx->{enable_graph_intermediate_support}->get_intermediate_signal_ast($signal_name);
            if ($intermediate_ast && blessed($intermediate_ast)) {
                fsm_debug("[FactorizationPolicySupport.pm][_ast_contains_frequently_used_logical_operation()] Descending into intermediate '$signal_name' AST", 3);
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
