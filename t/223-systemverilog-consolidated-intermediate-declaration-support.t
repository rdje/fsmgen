#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use File::Spec;
use File::Temp qw(tempdir);
use FindBin;

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::HDL::FlattenedDT;
use FSM::HDL::FlattenedDT::Backend::SystemVerilog::ConsolidatedIntermediateDeclarationSupport;
use FSM::Pipeline::SourceFrontend;

subtest 'consolidated intermediate declaration support rebuilds prepared wire declarations from a prepared backend context' => sub {
    my $fsm_module = parse_fsm_module(
        'sv_consolidated_decl_contract',
        <<'FSM'
(?fsm:sv_consolidated_decl_contract
  (+system
    (clock clk)
    (sreset rstn)
  )
  (+size
    (A 1)
    (B 1)
    (C 1)
    (OUT1 1)
  )
  (idle
    (<(| A B)
      (OUT1 <= C)
    )
  )
)
FSM
    );

    my $hdl_generator = prepare_flattened_backend($fsm_module);
    my $declaration_support = FSM::HDL::FlattenedDT::Backend::SystemVerilog::ConsolidatedIntermediateDeclarationSupport->new(
        flattened_dt => $hdl_generator,
    );

    my $all_intermediate_signals = $hdl_generator->{backend_sv_consolidated_intermediate_support}
        ->collect_consolidated_intermediate_signals($fsm_module);
    my $plan = $hdl_generator->{backend_sv_consolidated_intermediate_planning_support}
        ->plan_consolidated_intermediate_signals($all_intermediate_signals);
    my $prepared_block = $hdl_generator->{backend_sv_consolidated_intermediate_prepared_block_support}
        ->build_prepared_consolidated_intermediate_block($all_intermediate_signals, $plan);
    my $declarations = $declaration_support->render_consolidated_intermediate_declarations($prepared_block);
    my $declared_signal = $prepared_block->{sorted_signals}[0];

    like(
        $declarations,
        qr/^\s*wire \Q$declared_signal\E;/m,
        'declaration support renders a wire declaration for the prepared kept signal',
    );
    unlike(
        $declarations,
        qr/\bassign\b/,
        'declaration support renders only declarations and no assign statements',
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
