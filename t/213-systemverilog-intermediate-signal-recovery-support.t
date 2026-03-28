#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use Scalar::Util qw(blessed);
use File::Spec;
use File::Temp qw(tempdir);
use FindBin;

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::HDL::FlattenedDT;
use FSM::HDL::FlattenedDT::Backend::SystemVerilog::IntermediateSignalRecoverySupport;
use FSM::Pipeline::SourceFrontend;

subtest 'intermediate recovery support rebuilds runtime AST, render, dependency, and width metadata from a prepared backend context' => sub {
    my $fsm_module = parse_fsm_module(
        'sv_intermediate_recovery_contract',
        <<'FSM'
(?fsm:sv_intermediate_recovery_contract
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
    my $recovery_support = FSM::HDL::FlattenedDT::Backend::SystemVerilog::IntermediateSignalRecoverySupport->new(
        flattened_dt => $prepared_backend,
    );

    my $intermediate_signals = $prepared_backend->{backend_sv_global_factorization}->run_global_ast_factorization();
    my $signal_info = $intermediate_signals->{A_or_B};

    ok($signal_info, 'recovery support test fixture keeps the shared A_or_B intermediate signal');

    my $runtime_ast = $recovery_support->resolve_intermediate_signal_runtime_ast('A_or_B', $signal_info);
    ok(blessed($runtime_ast), 'recovery support resolves a substituted runtime AST for the shared intermediate signal');
    is($signal_info->{runtime_ast_source}, 'substituted_ast', 'recovery support records the substituted AST source');

    my $rendered_expression = $recovery_support->render_intermediate_signal_expression('A_or_B', $signal_info);
    is($rendered_expression, 'A | B', 'recovery support renders the substituted AST back to SystemVerilog text');

    my @dependencies = $recovery_support->resolve_intermediate_signal_dependencies('A_or_B', $signal_info);
    is_deeply(\@dependencies, [], 'recovery support keeps non-intermediate leaf operands out of the intermediate dependency list');

    my $resolved_width = $recovery_support->resolve_intermediate_signal_width('A_or_B', $signal_info, $intermediate_signals);
    is($resolved_width, 1, 'recovery support infers the expected 1-bit width for the shared logical carrier');
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
    $hdl_generator->{enable_graph_factorization_policy_support}->count_binary_logical_operation_occurrences();
    return $hdl_generator;
}

sub write_file {
    my ($path, $content) = @_;
    open my $fh, '>', $path or die "Cannot open $path for write: $!";
    print {$fh} $content or die "Cannot write $path: $!";
    close $fh or die "Cannot close $path: $!";
}
