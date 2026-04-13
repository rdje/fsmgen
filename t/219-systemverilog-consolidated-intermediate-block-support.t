#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use File::Spec;
use File::Temp qw(tempdir);
use FindBin;

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::HDL::FlattenedDT;
use FSM::HDL::FlattenedDT::Backend::SystemVerilog::ConsolidatedIntermediateBlockSupport;
use FSM::HDL::FlattenedDT::Backend::SystemVerilog::ConsolidatedIntermediateStagePreparationSupport;
use FSM::Pipeline::SourceFrontend;

subtest 'consolidated intermediate block support survives as a compatibility shell over the live stage-preparation owner' => sub {
    my $fsm_module = parse_fsm_module(
        'sv_consolidated_block_support_contract',
        <<'FSM'
(?fsm:sv_consolidated_block_support_contract
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
    my $support = FSM::HDL::FlattenedDT::Backend::SystemVerilog::ConsolidatedIntermediateBlockSupport->new(
        flattened_dt => $prepared_backend,
    );
    my $stage_preparation_support = FSM::HDL::FlattenedDT::Backend::SystemVerilog::ConsolidatedIntermediateStagePreparationSupport->new(
        flattened_dt => $prepared_backend,
    );

    my $expected_block = $stage_preparation_support->prepare_consolidated_intermediate_block($fsm_module);
    my $block = $support->prepare_consolidated_intermediate_block($fsm_module);

    is_deeply(
        $block,
        $expected_block,
        'block support rebuilds the prepared block handoff by delegating to the live stage-preparation owner',
    );

    ok(
        exists $block->{all_intermediate_signals}{A_or_B},
        'block support keeps the shared factorized carrier in the prepared full signal set',
    );
    ok(
        exists $block->{filtered_signals}{A_or_B},
        'block support keeps the shared factorized carrier in the prepared kept set',
    );
    is(
        $block->{sorted_signals}[0],
        'A_or_B',
        'block support keeps the shared factorized carrier at the front of the dependency-safe render order',
    );
    is(
        $block->{total_kept_count},
        scalar(keys %{ $block->{filtered_signals} }),
        'block support reports the kept consolidated signal count from the prepared kept set',
    );
    is(
        $block->{filtered_count},
        0,
        'block support reports that no consolidated signals were filtered away in the shared-carrier case',
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

sub write_file {
    my ($path, $content) = @_;
    open my $fh, '>', $path or die "Cannot open $path for write: $!";
    print {$fh} $content or die "Cannot write $path: $!";
    close $fh or die "Cannot close $path: $!";
}
