#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use Scalar::Util qw(blessed);
use File::Spec;
use FindBin;

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::AST::Node;
use FSM::HDL::FlattenedDT::Backend::SystemVerilog::IntermediateSignalFilterPolicySupport;
use FSM::HDL::FlattenedDT::Backend::SystemVerilog::IntermediateSignalSupport;

{
    package Local::FakeFactorizationSupport;
    use v5.20;
    use strict;
    use warnings;
    use feature qw(signatures);
    no warnings 'experimental::signatures';

    sub new ($class) {
        return bless { should_factor_call_count => 0 }, $class;
    }

    sub resolve_intermediate_signal_live_usage ($self, $signal_name, $signal_info) {
        return %{ $signal_info->{live_usage} || {} }
            ? $signal_info->{live_usage}
            : {
                used_in_final_expressions => 0,
                referenced_in_substitutions => 0,
                evidence_state => 'none',
            };
    }
}

{
    package Local::FakeASTSupport;
    use v5.20;
    use strict;
    use warnings;
    use feature qw(signatures);
    no warnings 'experimental::signatures';
    use Scalar::Util qw(blessed);

    sub new ($class) {
        return bless {}, $class;
    }

    sub is_arithmetic_operation ($self, $ast) {
        return 0 unless $ast && blessed($ast) && $ast->can('operator');
        return ($ast->operator || '') =~ /^[\+\-\*\/%]$/ ? 1 : 0;
    }

    sub is_logical_operation ($self, $ast) {
        return 0 unless $ast && blessed($ast) && $ast->can('operator');
        return ($ast->operator || '') =~ /^(?:&&|\|\||&|\|)$/ ? 1 : 0;
    }

    sub should_factor_logical_operation ($self, $ast) {
        $self->{should_factor_call_count}++;
        return 0 unless $self->is_logical_operation($ast);
        return ($ast->operator || '') =~ /^(?:&|\|)$/ ? 1 : 0;
    }

    sub should_factor_call_count ($self) {
        return $_[0]->{should_factor_call_count};
    }
}

{
    package Local::FakeRecoverySupport;
    use v5.20;
    use strict;
    use warnings;
    use feature qw(signatures);
    no warnings 'experimental::signatures';

    sub new ($class) {
        return bless {}, $class;
    }

    sub render_intermediate_signal_expression ($self, $signal_name, $signal_info) {
        return $signal_info->{rendered_expression};
    }

    sub resolve_intermediate_signal_runtime_ast ($self, $signal_name, $signal_info) {
        return $signal_info->{runtime_ast};
    }
}
subtest 'intermediate filter-policy support owns AST-aware and runtime-AST-miss heuristics' => sub {
    my $fake_backend = {
        enable_graph_factorization_support => Local::FakeFactorizationSupport->new(),
        enable_graph_ast_support => Local::FakeASTSupport->new(),
    };
    my $policy_support = FSM::HDL::FlattenedDT::Backend::SystemVerilog::IntermediateSignalFilterPolicySupport->new(
        flattened_dt => $fake_backend,
    );

    my $simple_negation = FSM::AST::UnaryOp->new(
        '!',
        FSM::AST::SignalRef->new('A'),
    );
    my $complex_negation = FSM::AST::UnaryOp->new(
        '!',
        FSM::AST::Literal->new('1'),
    );
    my $simple_comparison = FSM::AST::BinaryOp->new(
        '==',
        FSM::AST::SignalRef->new('A'),
        FSM::AST::Literal->new('1'),
    );
    my $arithmetic_sum = FSM::AST::BinaryOp->new(
        '+',
        FSM::AST::SignalRef->new('A'),
        FSM::AST::Literal->new('1'),
    );
    my $logical_or = FSM::AST::BinaryOp->new(
        '|',
        FSM::AST::SignalRef->new('A'),
        FSM::AST::SignalRef->new('B'),
    );

    ok(
        $policy_support->is_simple_negation($simple_negation),
        'filter-policy support recognizes simple unary signal negation',
    );
    ok(
        !$policy_support->is_simple_negation($complex_negation),
        'filter-policy support rejects non-signal unary negation as a simple negation',
    );
    ok(
        $policy_support->is_simple_comparison($simple_comparison),
        'filter-policy support recognizes signal-versus-literal comparisons',
    );
    ok(
        !$policy_support->is_simple_comparison($arithmetic_sum),
        'filter-policy support rejects arithmetic expressions as simple comparisons',
    );

    is(
        $policy_support->should_filter_ast_based(
            $simple_comparison,
            'cmp_sig',
            {
                usage_count => 1,
                live_usage => {
                    used_in_final_expressions => 1,
                    referenced_in_substitutions => 0,
                    evidence_state => 'final_expression',
                },
            },
        ),
        1,
        'filter-policy support filters simple comparisons',
    );
    is(
        $policy_support->should_filter_ast_based(
            $simple_negation,
            'neg_once',
            {
                usage_count => 1,
                live_usage => {
                    used_in_final_expressions => 1,
                    referenced_in_substitutions => 0,
                    evidence_state => 'final_expression',
                },
            },
        ),
        1,
        'filter-policy support filters a simple negation used only once',
    );
    is(
        $policy_support->should_filter_ast_based(
            $simple_negation,
            'neg_twice',
            {
                usage_count => 2,
                live_usage => {
                    used_in_final_expressions => 1,
                    referenced_in_substitutions => 0,
                    evidence_state => 'final_expression',
                },
            },
        ),
        0,
        'filter-policy support keeps a simple negation reused multiple times',
    );
    is(
        $policy_support->should_filter_ast_based(
            $arithmetic_sum,
            'arith_sig',
            {
                usage_count => 1,
                live_usage => {
                    used_in_final_expressions => 1,
                    referenced_in_substitutions => 0,
                    evidence_state => 'final_expression',
                },
            },
        ),
        0,
        'filter-policy support keeps arithmetic operations',
    );
    my $policy_call_count_before_low_use = $fake_backend->{enable_graph_ast_support}->should_factor_call_count;
    is(
        $policy_support->should_filter_ast_based(
            $logical_or,
            'logical_once',
            {
                usage_count => 1,
                live_usage => {
                    used_in_final_expressions => 1,
                    referenced_in_substitutions => 0,
                    evidence_state => 'final_expression',
                },
            },
        ),
        1,
        'filter-policy support filters low-use logical operations',
    );
    is(
        $fake_backend->{enable_graph_ast_support}->should_factor_call_count,
        $policy_call_count_before_low_use,
        'low-use logical operations do not run recursive factorization eligibility that cannot change the filter result',
    );
    is(
        $policy_support->should_filter_ast_based(
            $logical_or,
            'logical_twice',
            {
                usage_count => 2,
                live_usage => {
                    used_in_final_expressions => 1,
                    referenced_in_substitutions => 0,
                    evidence_state => 'final_expression',
                },
            },
        ),
        0,
        'filter-policy support keeps logical operations that qualify for factoring and are reused',
    );
    my $policy_call_count = $fake_backend->{enable_graph_ast_support}->should_factor_call_count;
    is(
        $policy_support->should_filter_ast_based(
            $logical_or,
            'factorizer_owned_logical',
            {
                usage_count => 2,
                source => 'ast_factorization',
                live_usage => {
                    used_in_final_expressions => 1,
                    referenced_in_substitutions => 0,
                    evidence_state => 'final_expression',
                },
            },
        ),
        0,
        'filter-policy support keeps a factorizer-owned multi-use logical operation from authoritative factorizer metadata',
    );
    is(
        $fake_backend->{enable_graph_ast_support}->should_factor_call_count,
        $policy_call_count,
        'factorizer-owned multi-use metadata avoids recursively re-proving logical factorization eligibility',
    );
    is(
        $policy_support->should_filter_ast_based(
            $logical_or,
            'substitution_live',
            {
                usage_count => 1,
                live_usage => {
                    used_in_final_expressions => 0,
                    referenced_in_substitutions => 1,
                    evidence_state => 'substitution_only',
                },
            },
        ),
        0,
        'filter-policy support keeps signals that are live only through substitutions',
    );

    my $runtime_ast_miss_kept = {
        live_usage => {
            used_in_final_expressions => 0,
            referenced_in_substitutions => 1,
            evidence_state => 'substitution_only',
        },
        runtime_ast_miss_reason => 'substituted_ast_missing',
    };
    is(
        $policy_support->should_filter_runtime_ast_miss('rescued_runtime_miss', $runtime_ast_miss_kept),
        0,
        'filter-policy support keeps runtime-AST-miss signals with substitution evidence',
    );
    is(
        $runtime_ast_miss_kept->{filter_fallback_source},
        'runtime_ast_miss_live_usage',
        'filter-policy support records the runtime-AST-miss fallback source',
    );
    is(
        $runtime_ast_miss_kept->{filter_fallback_reason},
        'substituted_ast_missing',
        'filter-policy support records the runtime-AST-miss fallback reason',
    );

    is(
        $policy_support->should_filter_runtime_ast_miss(
            'dead_runtime_miss',
            {
                live_usage => {
                    used_in_final_expressions => 0,
                    referenced_in_substitutions => 0,
                    evidence_state => 'none',
                },
                runtime_ast_miss_reason => 'no_runtime_ast',
            },
        ),
        1,
        'filter-policy support filters runtime-AST-miss signals with no live-usage evidence',
    );
};

subtest 'intermediate-signal support narrows to dispatcher behavior over recovery plus extracted policy' => sub {
    my $fake_backend = {
        enable_graph_factorization_support => Local::FakeFactorizationSupport->new(),
        enable_graph_ast_support => Local::FakeASTSupport->new(),
        backend_sv_intermediate_recovery_support => Local::FakeRecoverySupport->new(),
    };
    my $policy_support = FSM::HDL::FlattenedDT::Backend::SystemVerilog::IntermediateSignalFilterPolicySupport->new(
        flattened_dt => $fake_backend,
    );
    $fake_backend->{backend_sv_intermediate_filter_policy_support} = $policy_support;

    my $dispatcher = FSM::HDL::FlattenedDT::Backend::SystemVerilog::IntermediateSignalSupport->new(
        flattened_dt => $fake_backend,
    );

    is(
        $dispatcher->should_filter_consolidated_signal(
            '',
            'cmp_sig',
            {
                rendered_expression => 'A == 1',
                runtime_ast => FSM::AST::BinaryOp->new(
                    '==',
                    FSM::AST::SignalRef->new('A'),
                    FSM::AST::Literal->new('1'),
                ),
                usage_count => 1,
                source => 'ast_factorization',
                live_usage => {
                    used_in_final_expressions => 1,
                    referenced_in_substitutions => 0,
                    evidence_state => 'final_expression',
                },
            },
        ),
        1,
        'dispatcher delegates AST-backed filtering through the extracted policy owner',
    );

    is(
        $dispatcher->should_filter_consolidated_signal(
            '',
            'runtime_miss',
            {
                rendered_expression => 'A | B',
                usage_count => 1,
                source => 'runtime_ast_miss',
                runtime_ast_miss_reason => 'no_runtime_ast',
                live_usage => {
                    used_in_final_expressions => 0,
                    referenced_in_substitutions => 0,
                    evidence_state => 'none',
                },
            },
        ),
        1,
        'dispatcher delegates runtime-AST-miss fallback filtering through the extracted policy owner',
    );
};

done_testing();
