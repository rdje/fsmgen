#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use File::Spec;
use File::Temp qw(tempdir);
use FindBin;

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::HDL::FlattenedDT;
use FSM::HDL::FlattenedDT::Backend::SystemVerilog::ConsolidatedIntermediateRenderingSupport;
use FSM::HDL::FlattenedDT::Backend::SystemVerilog::ConsolidatedIntermediateStagePreparationSupport;
use FSM::Pipeline::SourceFrontend;

subtest 'consolidated intermediate rendering support rebuilds final rendering from a prepared block contract' => sub {
    my $fsm_module = parse_fsm_module(
        'sv_consolidated_rendering_support_contract',
        <<'FSM'
(?fsm:sv_consolidated_rendering_support_contract
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
    my $stage_preparation_support = FSM::HDL::FlattenedDT::Backend::SystemVerilog::ConsolidatedIntermediateStagePreparationSupport->new(
        flattened_dt => $prepared_backend,
    );
    my $rendering_support = FSM::HDL::FlattenedDT::Backend::SystemVerilog::ConsolidatedIntermediateRenderingSupport->new(
        flattened_dt => $prepared_backend,
    );

    my $prepared_block = $stage_preparation_support->prepare_consolidated_intermediate_block($fsm_module);
    my $rendered_block = $rendering_support->render_prepared_consolidated_intermediate_block($prepared_block);
    my $expected_block = expected_rendered_block($prepared_backend, $prepared_block);

    is(
        $rendered_block,
        $expected_block,
        'rendering support rebuilds the same consolidated block as declaration plus assignment owners',
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
    $hdl_generator->{enable_graph_factorization_policy_support}->count_binary_logical_operation_occurrences();
    $hdl_generator->{enable_graph_enable_support}->prescan_wen_en_for_intermediate_signals();
    return $hdl_generator;
}

sub expected_rendered_block {
    my ($prepared_backend, $prepared_block) = @_;
    my $declaration_support = $prepared_backend->{backend_sv_consolidated_intermediate_declaration_support};
    my $assignment_support = $prepared_backend->{backend_sv_consolidated_intermediate_assignment_support};
    my $filtered_signals = $prepared_block->{filtered_signals} || {};
    my $block = '';

    if (%{$filtered_signals}) {
        $block .= "  // Consolidated intermediate signals (AST factorization + pre-scan)\n";
        $block .= $declaration_support->render_consolidated_intermediate_declarations($prepared_block);
        $block .= "\n";
        $block .= $assignment_support->render_consolidated_intermediate_assignments($prepared_block);
        $block .= "\n";
    }

    return $block;
}

sub write_file {
    my ($path, $content) = @_;
    open my $fh, '>', $path or die "Cannot open $path for write: $!";
    print {$fh} $content or die "Cannot write $path: $!";
    close $fh or die "Cannot close $path: $!";
}
