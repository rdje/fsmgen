#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use File::Spec;
use File::Temp qw(tempdir);
use FindBin;

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::HDL::FlattenedDT;
use FSM::HDL::FlattenedDT::Backend::SystemVerilog::ConsolidatedIntermediateSupport;
use FSM::Pipeline::SourceFrontend;

subtest 'consolidated intermediate support rebuilds the merged and normalized direct signal set from a prepared backend context' => sub {
    my $fsm_module = parse_fsm_module(
        'sv_consolidated_support_contract',
        <<'FSM'
(?fsm:sv_consolidated_support_contract
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
    my $support = FSM::HDL::FlattenedDT::Backend::SystemVerilog::ConsolidatedIntermediateSupport->new(
        flattened_dt => $prepared_backend,
    );

    my $signals = $support->collect_consolidated_intermediate_signals($fsm_module);
    my $signal_info = $signals->{A_or_B};

    ok($signal_info, 'consolidated intermediate support keeps the shared factorized carrier in the merged signal set');
    is($signal_info->{source}, 'ast_factorization', 'consolidated intermediate support preserves the factorization source tag for the shared carrier');
    is($signal_info->{width}, 1, 'consolidated intermediate support normalizes the shared carrier width');
    is_deeply($signal_info->{dependency_signal_names}, [], 'consolidated intermediate support normalizes the shared carrier dependency list');
    is($signal_info->{rendered_expression}, 'A | B', 'consolidated intermediate support caches the shared carrier rendered expression');
    is($signal_info->{runtime_ast_source}, 'substituted_ast', 'consolidated intermediate support resolves the shared carrier runtime AST through substituted AST lookup');
    is($signal_info->{used_in_final_expressions}, 0, 'consolidated intermediate support preserves the distinction between substitutions and final owner-side usage');
    is($signal_info->{live_usage_evidence_state}, 'substitutions', 'consolidated intermediate support normalizes live-usage evidence metadata for the shared carrier');
    is($signal_info->{live_usage_source}, 'ast_live_usage_metadata', 'consolidated intermediate support records the live-usage metadata source for the shared carrier');
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
