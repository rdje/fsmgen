#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use File::Spec;
use File::Temp qw(tempdir);
use FindBin;

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::HDL::FlattenedDT;
use FSM::HDL::FlattenedDT::Backend::SystemVerilog::GenerationStructuralPreludeSupport;
use FSM::Pipeline::SourceFrontend;

subtest 'generation structural prelude support remains a compatibility shell over the extracted scaffold and internal-declaration owners' => sub {
    my $fsm_module = parse_fsm_module(
        'sv_generation_structural_prelude_support_contract',
        <<'FSM'
(?fsm:sv_generation_structural_prelude_support_contract
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
    my $structural_prelude_support = FSM::HDL::FlattenedDT::Backend::SystemVerilog::GenerationStructuralPreludeSupport->new(
        flattened_dt => $prepared_backend,
    );

    my $expected_prefix = build_expected_structural_prelude($prepared_backend, $fsm_module);
    my $generated_prefix = $structural_prelude_support->generate_structural_prelude($fsm_module);

    is(
        $generated_prefix,
        $expected_prefix,
        'generation structural prelude support compatibility shell rebuilds the same structural HDL prefix as the extracted live owners',
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

sub build_expected_structural_prelude {
    my ($prepared_backend, $fsm_module) = @_;

    my $hdl = $prepared_backend->{backend_sv_scaffold}->generate_header($fsm_module);
    $hdl .= $prepared_backend->{backend_sv_scaffold}->generate_module_declaration($fsm_module);
    $hdl .= $prepared_backend->{backend_sv_scaffold}->generate_state_encoding($fsm_module);
    $hdl .= $prepared_backend->{backend_sv_scaffold}->generate_state_register($fsm_module);
    $hdl .= $prepared_backend->{backend_sv_internal_decl}->generate_internal_signal_declarations($fsm_module);

    return $hdl;
}

sub write_file {
    my ($path, $content) = @_;
    open my $fh, '>', $path or die "Cannot open $path for write: $!";
    print {$fh} $content or die "Cannot write $path: $!";
    close $fh or die "Cannot close $path: $!";
}
