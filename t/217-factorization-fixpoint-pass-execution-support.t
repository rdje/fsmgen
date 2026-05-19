#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use File::Spec;
use File::Temp qw(tempdir);
use FindBin;

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::AST::Node;
use FSM::HDL::Factorization::Fixpoint::PassExecutionSupport;
use FSM::HDL::Factorization::Fixpoint::PassSupport;
use FSM::HDL::FlattenedDT;
use FSM::Pipeline::SourceFrontend;

subtest 'fixpoint pass-execution support rebuilds the prepared no-new-candidate termination contract' => sub {
    my $fsm_module = parse_fsm_module(
        'fixpoint_pass_execution_support_contract',
        <<'FSM'
(?fsm:fixpoint_pass_execution_support_contract
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
    my $execution_support = FSM::HDL::Factorization::Fixpoint::PassExecutionSupport->new(
        flattened_dt => $prepared_backend,
        pass_support => $pass_support,
    );

    my $primary_intermediate_signals = $pass_support->resolve_primary_intermediate_signals($prepared_backend->{ast_factorizer});
    inject_second_pass_compound_expression($prepared_backend, 'A_or_B');

    my %all_additional_signals;
    my %seen_signatures;

    my $outcome = $execution_support->run_factorization_pass(
        pass_number => 2,
        primary_intermediate_signals => $primary_intermediate_signals,
        all_additional_signals => \%all_additional_signals,
        seen_signatures => \%seen_signatures,
    );

    cmp_ok($outcome->{fed_count}, '>', 0, 'pass-execution support feeds the prepared post-substitution AST set into the per-pass factorizer');
    ok(defined $outcome->{signature} && $outcome->{signature} ne '', 'pass-execution support records the deterministic per-pass signature');
    is($outcome->{status}, 'terminate', 'pass-execution support reports the prepared fixture as an immediate terminating pass');
    is($outcome->{termination_reason}, 'no_new_factorization_candidates', 'pass-execution support keeps the no-new-candidate termination reason');
    is($outcome->{factorization_candidates}, 0, 'pass-execution support reports no second-pass factorization candidates for the prepared fixture');
    is($outcome->{new_signal_count}, 0, 'pass-execution support reports no new second-pass signals for the prepared fixture');
    is($outcome->{substitution_count}, 0, 'pass-execution support performs no substitutions when no second-pass candidates exist');
    is($outcome->{update_count}, 0, 'pass-execution support performs no owner-side AST updates when no second-pass candidates exist');
    is(scalar(keys %seen_signatures), 1, 'pass-execution support records the seen signature for future repeated-input detection');
};

subtest 'fixpoint pass-execution support short-circuits repeated pass signatures before factorization' => sub {
    my $fsm_module = parse_fsm_module(
        'fixpoint_pass_execution_repeat_contract',
        <<'FSM'
(?fsm:fixpoint_pass_execution_repeat_contract
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
    my $execution_support = FSM::HDL::Factorization::Fixpoint::PassExecutionSupport->new(
        flattened_dt => $prepared_backend,
        pass_support => $pass_support,
    );

    my $primary_intermediate_signals = $pass_support->resolve_primary_intermediate_signals($prepared_backend->{ast_factorizer});
    inject_second_pass_compound_expression($prepared_backend, 'A_or_B');

    my %all_additional_signals;
    my %seeded_signatures;

    my $first_outcome = $execution_support->run_factorization_pass(
        pass_number => 2,
        primary_intermediate_signals => $primary_intermediate_signals,
        all_additional_signals => \%all_additional_signals,
        seen_signatures => \%seeded_signatures,
    );

    my %repeat_signatures = (
        $first_outcome->{signature} => 1,
    );
    my $repeat_outcome = $execution_support->run_factorization_pass(
        pass_number => 2,
        primary_intermediate_signals => $primary_intermediate_signals,
        all_additional_signals => \%all_additional_signals,
        seen_signatures => \%repeat_signatures,
    );

    cmp_ok($repeat_outcome->{fed_count}, '>', 0, 'pass-execution support still rebuilds the per-pass AST input before repeated-signature detection');
    is($repeat_outcome->{status}, 'terminate', 'pass-execution support terminates immediately on a repeated input signature');
    is($repeat_outcome->{termination_reason}, 'repeated_input_signature', 'pass-execution support preserves the repeated-signature termination reason');
    is($repeat_outcome->{factorization_candidates}, 0, 'pass-execution support does not proceed to candidate creation once the repeated signature is detected');
    is($repeat_outcome->{new_signal_count}, 0, 'pass-execution support accepts no new signals on a repeated signature');
    is($repeat_outcome->{substitution_count}, 0, 'pass-execution support performs no substitutions on a repeated signature');
    is($repeat_outcome->{update_count}, 0, 'pass-execution support performs no owner-side AST updates on a repeated signature');
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
