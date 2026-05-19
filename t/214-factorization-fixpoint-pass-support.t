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
use FSM::HDL::Factorization::Fixpoint::PassSupport;
use FSM::HDL::FlattenedDT;
use FSM::Pipeline::SourceFrontend;

subtest 'fixpoint pass support rebuilds the per-pass signature and collision contract from a prepared backend context' => sub {
    my $fsm_module = parse_fsm_module(
        'fixpoint_pass_support_contract',
        <<'FSM'
(?fsm:fixpoint_pass_support_contract
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
    (<(& (| A B) C)
      (OUT1 <= C)
    )
    (<(& (| A B) D)
      (OUT2 <= D)
    )
  )
)
FSM
    );

    my $prepared_backend = prepare_factorized_backend($fsm_module);
    my $pass_support = FSM::HDL::Factorization::Fixpoint::PassSupport->new(
        flattened_dt => $prepared_backend,
    );

    my $primary_intermediate_signals = $pass_support->resolve_primary_intermediate_signals($prepared_backend->{ast_factorizer});
    ok($primary_intermediate_signals->{A_or_B}, 'pass support exposes the live primary intermediate-signal map from the prepared first-pass factorizer');

    inject_second_pass_compound_expression($prepared_backend, 'A_or_B');

    my $second_pass_factorizer = FSM::HDL::ASTFactorization->new(
        min_usage_count => 2,
        debug => 0,
        debug_level => 0,
    );
    my $fed_count = $prepared_backend->{enable_graph_factorization_policy_support}->feed_current_asts_to_second_pass($second_pass_factorizer);
    cmp_ok($fed_count, '>', 0, 'pass support test fixture exposes post-substitution ASTs to a second-pass factorizer');

    my $signature = $pass_support->build_expression_signature($second_pass_factorizer);
    my @signature_parts = split(/ \|\| /, $signature);
    cmp_ok(scalar(@signature_parts), '>', 0, 'pass support builds a non-empty signature for the second-pass AST set');
    is_deeply(\@signature_parts, [sort @signature_parts], 'pass support sorts the signature deterministically across pass inputs');

    my $shared_ast = FSM::AST::BinaryOp->new(
        '|',
        FSM::AST::SignalRef->new('A'),
        FSM::AST::SignalRef->new('B'),
    );
    my $novel_ast = FSM::AST::BinaryOp->new(
        '|',
        FSM::AST::SignalRef->new('C'),
        FSM::AST::SignalRef->new('D'),
    );

    my $pass_signals = {
        A_or_B => {
            %{$primary_intermediate_signals->{A_or_B}},
        },
        brand_new => {
            ast => $novel_ast,
            usage_count => 3,
        },
    };
    my %all_additional_signals = (
        A_or_B_1 => {
            ast => $shared_ast,
            usage_count => 2,
        },
        existing_extra => {
            ast => $shared_ast,
            usage_count => 2,
        },
    );

    my $rename_count = $pass_support->rename_colliding_pass_signals(
        $pass_signals,
        \%all_additional_signals,
        $primary_intermediate_signals,
        pass_number => 2,
    );
    is($rename_count, 1, 'pass support renames one colliding second-pass signal');
    ok(!exists $pass_signals->{A_or_B}, 'pass support removes the original colliding second-pass key');
    ok(exists $pass_signals->{A_or_B_2}, 'pass support picks the next free suffixed name when both the primary name and _1 are already reserved');

    my $new_unique_signals = $pass_support->select_new_unique_signals(
        $pass_signals,
        \%all_additional_signals,
        $primary_intermediate_signals,
    );
    ok(!exists $new_unique_signals->{existing_extra}, 'pass support does not invent a stale earlier-pass key when it is absent from the current pass');
    ok(exists $new_unique_signals->{A_or_B_2}, 'pass support keeps the renamed unique signal');
    ok(exists $new_unique_signals->{brand_new}, 'pass support keeps genuinely new second-pass signals');

    ok(
        eval { $pass_support->log_new_unique_signals($new_unique_signals, pass_number => 2); 1 },
        'pass support can emit the per-pass new-signal debug summary without failing',
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

sub prepare_factorized_backend {
    my ($fsm_module) = @_;
    my $hdl_generator = FSM::HDL::FlattenedDT->new(debug => 0);
    $hdl_generator->{orchestrator}->reset_generation_state();
    $hdl_generator->{enable_graph_signal_support}->set_fsm_module_reference($fsm_module);
    $hdl_generator->{orchestrator}->flatten_all_decision_trees($fsm_module);
    $hdl_generator->{enable_graph_enable_support}->generate_enable_conditions($fsm_module);
    $hdl_generator->{enable_graph_factorization_policy_support}->count_binary_logical_operation_occurrences();
    $hdl_generator->{backend_sv_global_factorization}->run_global_ast_factorization();
    return $hdl_generator;
}

sub inject_second_pass_compound_expression {
    my ($prepared_backend, $intermediate_signal_name) = @_;

    $prepared_backend->{state_enables}{__test_second_pass_compound} = FSM::AST::BinaryOp->new(
        '&',
        FSM::HDL::IntermediateSignalRef->new(signal_name => $intermediate_signal_name),
        FSM::AST::SignalRef->new('C'),
    );
}

sub write_file {
    my ($path, $content) = @_;
    open my $fh, '>', $path or die "Cannot open $path for write: $!";
    print {$fh} $content or die "Cannot write $path: $!";
    close $fh or die "Cannot close $path: $!";
}
