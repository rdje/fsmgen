#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use File::Spec;
use File::Temp qw(tempdir);
use FindBin;

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::AST::Node;
use FSM::HDL::ASTFactorization;
use FSM::HDL::FlattenedDT;
use FSM::Pipeline::SourceFrontend;
use FSM::Debug qw(
    capture_fsm_debug_state
    restore_fsm_debug_state
    set_fsm_debug_level
);

my $saved_debug_state = capture_fsm_debug_state();
END { restore_fsm_debug_state($saved_debug_state) if $saved_debug_state }

{
    package Local::CountedLogicalAST;
    use strict;
    use warnings;

    sub new {
        my ($class) = @_;
        return bless { signature_count => 0 }, $class;
    }

    sub to_systemverilog {
        my ($self) = @_;
        $self->{signature_count}++;
        return 'A | B';
    }

    sub signature_count {
        return $_[0]->{signature_count};
    }
}

{
    package Local::CountedASTSupport;
    use strict;
    use warnings;

    sub new {
        my ($class) = @_;
        return bless { render_count => 0 }, $class;
    }

    sub is_logical_operation {
        return 1;
    }

    sub ast_to_systemverilog {
        my ($self) = @_;
        $self->{render_count}++;
        return 'A | B';
    }

    sub render_count {
        return $_[0]->{render_count};
    }
}

subtest 'enable-graph factorization policy support rebuilds the factorization-policy and AST-feed contract from a prepared backend context' => sub {
    my $fsm_module = parse_fsm_module(
        'enable_graph_factorization_policy_contract',
        <<'FSM'
(?fsm:enable_graph_factorization_policy_contract
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
    my $support = $prepared_backend->{enable_graph_factorization_policy_support};

    my $counts = $support->count_binary_logical_operation_occurrences();
    is(ref($counts), 'HASH', 'factorization policy support returns a logical-operation count map for the prepared backend context');

    my @ast_expressions = $support->collect_all_wen_en_ast_expressions();
    cmp_ok(scalar(@ast_expressions), '>', 0, 'factorization policy support collects the prepared enable and assignment AST expressions');

    my ($intermediate_backed_expression) = grep {
        my $sv = eval { $_->{ast}->to_systemverilog() } || '';
        $sv =~ /intermediate_or_A_B_/;
    } @ast_expressions;
    ok($intermediate_backed_expression, 'factorization policy support exposes the prepared AST set through its current intermediate-backed owner expressions');
    ok(
        !$support->ast_contains_intermediate_signals($intermediate_backed_expression->{ast}),
        'factorization policy support does not second-pass factor a bare intermediate-backed DT selector',
    );
    ok($support->ast_has_intermediate_signals_recursive($intermediate_backed_expression->{ast}), 'factorization policy support recognizes intermediate-backed subtrees recursively');

    my $factorizer = FSM::HDL::ASTFactorization->new(
        min_usage_count => 2,
        debug => 0,
        debug_level => 0,
    );

    my $fed_count = $support->feed_asts_to_factorizer($factorizer);
    cmp_ok($fed_count, '>', 0, 'factorization policy support feeds the prepared AST set into a generic factorizer');

    my $factorization_result = $factorizer->analyze_and_factorize();
    my $signal_info = $factorization_result->{intermediate_signals}{A_or_B};
    ok($signal_info, 'factorization policy support preserves the shared A_or_B candidate through generic factorization analysis');
    is($signal_info->{usage_count}, 2, 'factorization policy support preserves the shared-expression usage count');

    my $logical_ast = FSM::AST::BinaryOp->new(
        '|',
        FSM::AST::SignalRef->new('A'),
        FSM::AST::SignalRef->new('B'),
    );
    my $logical_signature = $prepared_backend->{enable_graph_ast_support}->ast_to_systemverilog($logical_ast);
    $prepared_backend->{binary_logical_op_counts} = {
        $logical_signature => 2,
    };
    ok($support->contains_frequently_used_operations($logical_ast), 'factorization policy support recognizes a seeded high-count logical expression as worth factoring');

    my $substitution_count = $factorizer->substitute_expressions_with_intermediate_signals($factorizer->{ast_expressions});
    cmp_ok($substitution_count, '>', 0, 'generic factorizer can substitute the shared candidate into the collected AST set');

    my $second_pass_factorizer = FSM::HDL::ASTFactorization->new(
        min_usage_count => 2,
        debug => 0,
        debug_level => 0,
    );
    my $second_pass_fed_count = $support->feed_current_asts_to_second_pass($second_pass_factorizer);
    is(
        $second_pass_fed_count,
        0,
        'factorization policy support skips second-pass factoring for bare selector intermediates because DTE gating is emitted at the DT boundary',
    );
};

subtest 'disabled factorization-policy tracing does not render full AST diagnostics' => sub {
    set_fsm_debug_level(0);
    my $ast = Local::CountedLogicalAST->new();
    my $ast_support = Local::CountedASTSupport->new();
    my $support = FSM::Synthesis::EnableGraph::FactorizationPolicySupport->new(
        flattened_dt => {
            binary_logical_op_counts => {
                'A | B' => 2,
            },
            enable_graph_ast_support => $ast_support,
        },
    );

    ok(
        $support->contains_frequently_used_operations($ast),
        'factorization policy still recognizes the seeded high-count logical operation',
    );
    is(
        $ast->signature_count,
        1,
        'factorization policy renders only the signature required for the decision',
    );
    is(
        $ast_support->render_count,
        0,
        'disabled tracing performs no additional full-AST diagnostic render',
    );
};

restore_fsm_debug_state($saved_debug_state);
$saved_debug_state = undef;

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
