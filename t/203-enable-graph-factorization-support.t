#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use File::Spec;
use File::Temp qw(tempdir);
use FindBin;

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::HDL::ASTFactorization;
use FSM::HDL::FlattenedDT;
use FSM::Pipeline::SourceFrontend;

{
    package Local::ReusedRHSParser;
    use strict;
    use warnings;

    sub new {
        my ($class) = @_;
        return bless {
            ast => FSM::HDL::IntermediateSignalRef->new(signal_name => 'PARSED_FINAL_A'),
        }, $class;
    }

    sub parse_expression {
        my ($self, $expression) = @_;
        $self->{ast}{signal_name} = $expression;
        return $self->{ast};
    }
}

subtest 'enable-graph factorization support rebuilds the substitution and live-usage contract from a prepared backend context' => sub {
    my $fsm_module = parse_fsm_module(
        'enable_graph_factorization_contract',
        <<'FSM'
(?fsm:enable_graph_factorization_contract
  (+system
    (clock clk)
    (sreset rstn)
  )
  (+size
    (A 1)
    (B 1)
    (C 1)
    (D 1)
    (OUT1 1)
    (OUT2 1)
  )
  (idle
    (<(| A B)
      (OUT1 <= C)
    )
    (<(| A B)
      (OUT2 <= D)
    )
  )
)
FSM
    );

    my $prepared_backend = prepare_flattened_backend($fsm_module);
    my $policy_support = $prepared_backend->{enable_graph_factorization_policy_support};
    my $support = $prepared_backend->{enable_graph_factorization_support};

    my $counts = $policy_support->count_binary_logical_operation_occurrences();
    is(ref($counts), 'HASH', 'factorization policy support returns a logical-operation count map for the prepared backend context');

    my $factorizer = FSM::HDL::ASTFactorization->new(
        min_usage_count => 2,
        debug => 0,
        debug_level => 0,
    );

    my $fed_count = $policy_support->feed_asts_to_factorizer($factorizer);
    cmp_ok($fed_count, '>', 0, 'factorization policy support feeds the prepared AST set into a generic factorizer');

    my $factorization_result = $factorizer->analyze_and_factorize();
    my $signal_info = $factorization_result->{intermediate_signals}{A_or_B};
    ok($signal_info, 'factorization support preserves the shared A_or_B candidate through generic factorization analysis');
    is($signal_info->{usage_count}, 2, 'factorization support preserves the shared-expression usage count');

    my $substitution_count = $factorizer->substitute_expressions_with_intermediate_signals($factorizer->{ast_expressions});
    cmp_ok($substitution_count, '>', 0, 'factorization support can drive substituted AST generation through the generic factorizer');

    $prepared_backend->{ast_factorizer} = $factorizer;

    my ($substituted_expression) = grep {
        $support->ast_contains_signal($_->{ast}, 'A_or_B');
    } @{$factorizer->{ast_expressions}};
    ok($substituted_expression, 'factorization support can detect the shared intermediate inside substituted factorizer expressions');

    my $update_count = $support->update_original_asts_with_substituted_versions($factorizer);
    cmp_ok($update_count, '>', 0, 'factorization support synchronizes substituted ASTs back into the prepared backend structures');

    ok($support->is_signal_referenced_in_substitutions('A_or_B'), 'factorization support sees the shared intermediate in substituted expressions');
    ok(!$support->is_signal_actually_used_in_final_expressions('A_or_B'), 'factorization support keeps the distinction between substituted-factorizer evidence and final owner-side expressions');

    my $live_usage = $support->resolve_intermediate_signal_live_usage('A_or_B', $signal_info);
    is_deeply(
        $live_usage,
        {
            referenced_in_substitutions => 1,
            used_in_final_expressions => 0,
            evidence_state => 'substitutions',
            source => 'ast_live_usage_metadata',
        },
        'factorization support derives the expected live-usage evidence for the shared intermediate',
    );

    my %batch_signal_info = map { $_ => {} } qw(A_or_B BOTH FINAL_ONLY NONE);
    $prepared_backend->{intermediate_signals} = \%batch_signal_info;
    $prepared_backend->{state_enables}{batch_both} =
        FSM::HDL::IntermediateSignalRef->new(signal_name => 'BOTH');
    $prepared_backend->{lhs_assignments}{batch_final_only} = [{
        rhs => FSM::HDL::IntermediateSignalRef->new(signal_name => 'FINAL_ONLY'),
    }];

    my %scalar_live_usage;
    for my $signal_name (sort keys %batch_signal_info) {
        my %uncached_signal_info;
        $scalar_live_usage{$signal_name} =
            $support->resolve_intermediate_signal_live_usage($signal_name, \%uncached_signal_info);
    }

    my $batch_summary = $support->prime_intermediate_signal_live_usage(\%batch_signal_info);
    is($batch_summary->{signal_count}, 4, 'bulk live-usage preparation covers the complete consolidated registry');
    for my $signal_name (sort keys %batch_signal_info) {
        is_deeply(
            $support->resolve_intermediate_signal_live_usage(
                $signal_name,
                $batch_signal_info{$signal_name},
            ),
            $scalar_live_usage{$signal_name},
            "bulk live-usage metadata matches the scalar fallback for $signal_name",
        );
    }

    my $prior_intermediate_signals = $prepared_backend->{intermediate_signals};
    my $prior_expr_namer = $prepared_backend->{expr_namer};
    my $prior_lhs_assignments = $prepared_backend->{lhs_assignments};
    my %reused_rhs_signal_info = map { $_ => {} } qw(PARSED_FINAL_A PARSED_FINAL_B);
    $prepared_backend->{intermediate_signals} = \%reused_rhs_signal_info;
    $prepared_backend->{expr_namer} = Local::ReusedRHSParser->new();
    $prepared_backend->{lhs_assignments} = {
        parsed_final_a => [{ rhs => 'PARSED_FINAL_A' }],
        parsed_final_b => [{ rhs => 'PARSED_FINAL_B' }],
    };

    $support->prime_intermediate_signal_live_usage(\%reused_rhs_signal_info);
    for my $signal_name (sort keys %reused_rhs_signal_info) {
        ok(
            $reused_rhs_signal_info{$signal_name}{used_in_final_expressions},
            "bulk live-usage preparation scans reused parsed RHS roots for $signal_name",
        );
    }
    $prepared_backend->{intermediate_signals} = $prior_intermediate_signals;
    $prepared_backend->{expr_namer} = $prior_expr_namer;
    $prepared_backend->{lhs_assignments} = $prior_lhs_assignments;

    my $second_pass_factorizer = FSM::HDL::ASTFactorization->new(
        min_usage_count => 2,
        debug => 0,
        debug_level => 0,
    );
    my $second_pass_fed_count = $policy_support->feed_current_asts_to_second_pass($second_pass_factorizer);
    is(
        $second_pass_fed_count,
        0,
        'factorization policy support skips second-pass factoring when the substituted DT selector is a bare intermediate and the DTE remains a boundary gate',
    );
};

done_testing();

sub parse_fsm_module {
    my ($basename, $fsm_text) = @_;
    my $tempdir = tempdir(CLEANUP => 1);
    my $fsm_path = File::Spec->catfile($tempdir, "$basename.fsm");

    write_file($fsm_path, $fsm_text);
    my $raw_ast = FSM::Pipeline::SourceFrontend->parse_fsm_file(
        fsm_file => $fsm_path,
        debug_level => 0,
    );
    return FSM::Pipeline::SourceFrontend->create_fsm_module(
        raw_ast => $raw_ast,
        debug_level => 0,
    );
}

sub prepare_flattened_backend {
    my ($fsm_module) = @_;
    my $hdl_generator = FSM::HDL::FlattenedDT->new(debug => 0);
    $hdl_generator->{orchestrator}->reset_generation_state();
    $hdl_generator->{enable_graph_signal_support}->set_fsm_module_reference($fsm_module);
    $hdl_generator->{orchestrator}->flatten_all_decision_trees($fsm_module);
    $hdl_generator->{enable_graph_enable_support}->generate_enable_conditions($fsm_module);
    return $hdl_generator;
}

sub write_file {
    my ($path, $content) = @_;
    open my $fh, '>', $path or die "Cannot open $path for write: $!";
    print {$fh} $content or die "Cannot write $path: $!";
    close $fh or die "Cannot close $path: $!";
}
