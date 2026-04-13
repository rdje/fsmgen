#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use File::Spec;
use File::Temp qw(tempdir);
use FindBin;

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::HDL::FlattenedDT;
use FSM::HDL::FlattenedDT::Backend::SystemVerilog::GenerationPipelineSupport;
use FSM::Pipeline::SourceFrontend;

subtest 'generation pipeline support remains a compatibility shell over the extracted live post-flattening owners' => sub {
    my $fsm_module = parse_fsm_module(
        'sv_generation_pipeline_support_contract',
        <<'FSM'
(?fsm:sv_generation_pipeline_support_contract
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
    my $pipeline_support = FSM::HDL::FlattenedDT::Backend::SystemVerilog::GenerationPipelineSupport->new(
        flattened_dt => $prepared_backend,
    );

    my $expected_hdl = build_expected_hdl($prepared_backend, $fsm_module);
    my $generated_hdl = $pipeline_support->generate_systemverilog_module($fsm_module);

    normalize_generated_date(\$expected_hdl);
    normalize_generated_date(\$generated_hdl);

    is(
        $generated_hdl,
        $expected_hdl,
        'generation pipeline support compatibility shell rebuilds the same post-flattening HDL sequence as the extracted live owners',
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
    return $hdl_generator;
}

sub build_expected_hdl {
    my ($prepared_backend, $fsm_module) = @_;

    my $hdl = $prepared_backend->{backend_sv_scaffold}->generate_header($fsm_module);
    $hdl .= $prepared_backend->{backend_sv_scaffold}->generate_module_declaration($fsm_module);
    $hdl .= $prepared_backend->{backend_sv_scaffold}->generate_state_encoding($fsm_module);
    $hdl .= $prepared_backend->{backend_sv_scaffold}->generate_state_register($fsm_module);
    $hdl .= $prepared_backend->{backend_sv_internal_decl}->generate_internal_signal_declarations($fsm_module);
    $prepared_backend->{backend_sv_generation_prescan_preparation_support}
        ->prepare_enable_prescan();
    my $consolidated_intermediate_hdl = $prepared_backend->{backend_sv_consolidated_intermediate_stage_support}
        ->generate_consolidated_intermediate_block($fsm_module);
    $hdl .= $prepared_backend->{enable_graph_enable_support}
        ->generate_enable_conditions($fsm_module);
    $hdl .= $consolidated_intermediate_hdl;
    $hdl .= $prepared_backend->{backend_sv_generation_tail_support}
        ->generate_systemverilog_tail($fsm_module);

    return $hdl;
}

sub write_file {
    my ($path, $content) = @_;
    open my $fh, '>', $path or die "Cannot open $path for write: $!";
    print {$fh} $content or die "Cannot write $path: $!";
    close $fh or die "Cannot close $path: $!";
}

sub normalize_generated_date {
    my ($text_ref) = @_;
    return unless defined $text_ref && ref($text_ref) eq 'SCALAR';
    $$text_ref =~ s{// Date: .*}{// Date: <normalized>}g;
}
