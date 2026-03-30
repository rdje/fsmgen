#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use File::Spec;
use File::Temp qw(tempdir);
use FindBin;

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::HDL::FlattenedDT;
use FSM::HDL::FlattenedDT::Backend::SystemVerilog::ConsolidatedIntermediateStagePreparationSupport;
use FSM::Pipeline::SourceFrontend;

subtest 'consolidated intermediate stage-preparation support rebuilds the live prepared block from extracted owners' => sub {
    my $fsm_module = parse_fsm_module(
        'sv_consolidated_stage_preparation_support_contract',
        <<'FSM'
(?fsm:sv_consolidated_stage_preparation_support_contract
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
    my $support = FSM::HDL::FlattenedDT::Backend::SystemVerilog::ConsolidatedIntermediateStagePreparationSupport->new(
        flattened_dt => $prepared_backend,
    );

    my $all_intermediate_signals = $prepared_backend->{backend_sv_consolidated_intermediate_support}
        ->collect_consolidated_intermediate_signals($fsm_module);
    my $plan = $prepared_backend->{backend_sv_consolidated_intermediate_planning_support}
        ->plan_consolidated_intermediate_signals($all_intermediate_signals);
    my $expected_block = $prepared_backend->{backend_sv_consolidated_intermediate_prepared_block_support}
        ->build_prepared_consolidated_intermediate_block($all_intermediate_signals, $plan);

    my $prepared_block = $support->prepare_consolidated_intermediate_block($fsm_module);

    is_deeply(
        $prepared_block,
        $expected_block,
        'stage-preparation support rebuilds the same prepared block contract as explicit collection, planning, and prepared-block projection',
    );

    ok(
        exists $prepared_block->{all_intermediate_signals}{A_or_B},
        'stage-preparation support keeps the shared factorized carrier in the prepared full signal set',
    );
    ok(
        exists $prepared_block->{filtered_signals}{A_or_B},
        'stage-preparation support keeps the shared factorized carrier in the prepared kept set',
    );
    is(
        $prepared_block->{sorted_signals}[0],
        'A_or_B',
        'stage-preparation support keeps the shared factorized carrier at the front of the dependency-safe render order',
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
