#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use File::Spec;
use File::Temp qw(tempdir);
use FindBin;

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::AST::Node;
use FSM::HDL::FlattenedDT;
use FSM::HDL::FlattenedDT::Backend::SystemVerilog::ConsolidatedIntermediateRenderingSupport;
use FSM::HDL::FlattenedDT::Backend::SystemVerilog::ConsolidatedIntermediateStagePreparationSupport;
use FSM::HDL::FlattenedDT::Backend::SystemVerilog::ConsolidatedIntermediateStageSupport;
use FSM::Pipeline::SourceFrontend;

subtest 'consolidated intermediate stage support owns the live stage-6 handoff over prescan, stage preparation, validation, and rendering' => sub {
    my $fsm_module = parse_fsm_module(
        'sv_consolidated_stage_support_contract',
        <<'FSM'
(?fsm:sv_consolidated_stage_support_contract
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
    my $stage_support = FSM::HDL::FlattenedDT::Backend::SystemVerilog::ConsolidatedIntermediateStageSupport->new(
        flattened_dt => $prepared_backend,
    );
    my $stage_preparation_support = FSM::HDL::FlattenedDT::Backend::SystemVerilog::ConsolidatedIntermediateStagePreparationSupport->new(
        flattened_dt => $prepared_backend,
    );
    my $rendering_support = FSM::HDL::FlattenedDT::Backend::SystemVerilog::ConsolidatedIntermediateRenderingSupport->new(
        flattened_dt => $prepared_backend,
    );

    $prepared_backend->{backend_sv_generation_prescan_preparation_support}
        ->prepare_enable_prescan();
    my $prepared_block = $stage_preparation_support->prepare_consolidated_intermediate_block($fsm_module);
    my $expected_block = $rendering_support->render_prepared_consolidated_intermediate_block($prepared_block);
    delete $prepared_backend->{backend_sv_enable_prescan_prepared};
    my $generated_block = $stage_support->generate_consolidated_intermediate_block($fsm_module);

    is(
        $generated_block,
        $expected_block,
        'stage support rebuilds the same consolidated intermediate HDL block as prescan plus stage preparation plus validation plus rendering',
    );
    ok(
        $prepared_backend->{backend_sv_enable_prescan_prepared},
        'stage support marks the prescan prerequisite as prepared',
    );
};

subtest 'consolidated intermediate stage support runs operand-contract validation before rendering' => sub {
    my $fsm_module = parse_fsm_module(
        'sv_consolidated_stage_support_validation_contract',
        <<'FSM'
(?fsm:sv_consolidated_stage_support_validation_contract
  (+system
    (clock clk)
    (sreset rstn)
  )
  (+size
    (A 1)
    (OUT1 1)
  )
  (idle
    (<A
      (OUT1 <= 1)
    )
  )
)
FSM
    );

    my $prepared_backend = prepare_flattened_backend($fsm_module);
    my $stage_support = FSM::HDL::FlattenedDT::Backend::SystemVerilog::ConsolidatedIntermediateStageSupport->new(
        flattened_dt => $prepared_backend,
    );

    $prepared_backend->{state_enables}{idle} = FSM::AST::SignalRef->new('ghost_internal');
    my $error = capture_error(sub {
        $stage_support->generate_consolidated_intermediate_block($fsm_module);
    });

    like(
        $error,
        qr/Pre-generation operand contract validation failed/,
        'stage support fails before rendering when the pre-generation operand contract is broken',
    );
    like(
        $error,
        qr/ghost_internal/,
        'stage support validation failure keeps the offending operand name in the diagnostic',
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

sub capture_error {
    my ($code) = @_;
    my $ok = eval {
        $code->();
        1;
    };
    return $ok ? '' : ($@ || 'unknown error');
}
