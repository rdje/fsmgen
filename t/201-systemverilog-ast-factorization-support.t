#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use File::Spec;
use File::Temp qw(tempdir);
use FindBin;

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::HDL::FlattenedDT;
use FSM::HDL::FlattenedDT::Backend::SystemVerilog::ASTFactorizationSupport;
use FSM::Pipeline::SourceFrontend;

subtest 'ast factorization support rebuilds the direct factorization contract from a prepared backend context' => sub {
    my $fsm_module = parse_fsm_module(
        'sv_factorization_contract',
        <<'FSM'
(?fsm:sv_factorization_contract
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
    my $factorization_support = FSM::HDL::FlattenedDT::Backend::SystemVerilog::ASTFactorizationSupport->new(
        flattened_dt => $prepared_backend,
    );

    my $intermediate_signals = $factorization_support->run_global_ast_factorization();
    my $signal_info = $intermediate_signals->{A_or_B};
    my $substituted_ast = $factorization_support->get_substituted_ast_for_signal('A_or_B', $signal_info) || $signal_info->{ast};
    my $rendered_expression = $prepared_backend->{enable_graph}->ast_to_systemverilog($substituted_ast);

    ok($signal_info, 'factorization support keeps the shared A_or_B intermediate signal');
    is($signal_info->{usage_count}, 2, 'factorization support keeps the shared-expression usage count');
    is($rendered_expression, 'A | B', 'factorization support recovers the substituted AST for the shared expression');
    ok($prepared_backend->{ast_factorizer}, 'factorization support stores the factorizer on the backend context for downstream owners');
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
    $hdl_generator->{enable_graph}->set_fsm_module_reference($fsm_module);
    $hdl_generator->{orchestrator}->flatten_all_decision_trees($fsm_module);
    $hdl_generator->{enable_graph}->generate_enable_conditions($fsm_module);
    $hdl_generator->{enable_graph_factorization_support}->count_binary_logical_operation_occurrences();
    return $hdl_generator;
}

sub write_file {
    my ($path, $content) = @_;
    open my $fh, '>', $path or die "Cannot open $path for write: $!";
    print {$fh} $content or die "Cannot write $path: $!";
    close $fh or die "Cannot close $path: $!";
}
