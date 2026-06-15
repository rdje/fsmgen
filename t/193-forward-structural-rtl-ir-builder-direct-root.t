#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use File::Spec;
use File::Temp qw(tempdir);
use FindBin;

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::IR::IntentHIRBuilder;
use FSM::IR::StructuralRTLIRBuilder;
use FSM::Pipeline::GeneratedModuleInfoBuilder;
use FSM::Pipeline::SourceFrontend;
use FSM::Pipeline::HDLGenerator;

subtest 'structural rtl ir builder rebuilds the bounded direct-root structural surface from generated analysis inputs' => sub {
    my $tempdir = tempdir(CLEANUP => 1);
    my $fsm_path = File::Spec->catfile($tempdir, 'structural_rtl_ir_builder_direct_root.fsm');

    write_file(
        $fsm_path,
        <<'FSM'
(?fsm:structural_rtl_ir_builder_direct_root
  (+system
    (clock clk)
    (asreset rstn)
  )
  (+size
    (IN 8)
    (OUT 8)
  )
  (IDLE
    (OUT> <= IN)
  )
)
FSM
    );

    my $raw_ast = FSM::Pipeline::SourceFrontend->parse_fsm_file(
        fsm_file => $fsm_path,
        debug_level => 0,
    );
    my $fsm_module = FSM::Pipeline::SourceFrontend->create_fsm_module(
        raw_ast => $raw_ast,
        debug_level => 0,
    );
    my $intent_hir = FSM::IR::IntentHIRBuilder->build_from_fsm_module(
        fsm_module => $fsm_module,
    );
    my $module_info = FSM::Pipeline::GeneratedModuleInfoBuilder->build_from_fsm_module(
        fsm_module => $fsm_module,
        intent_hir => $intent_hir,
    );
    my $pipeline_for_full = new_pipeline();
    my $result = $pipeline_for_full->generate_hdl_from_file($fsm_path);
    FSM::Pipeline::GeneratedModuleInfoBuilder->enrich_with_generated_analysis(
        module_info => $module_info,
        fsm_module => $fsm_module,
        target_language => 'systemverilog',
        hdl_generator => $pipeline_for_full->{hdl_generator},
    );

    my $rebuilt_structural_rtl_ir = FSM::IR::StructuralRTLIRBuilder->build_from_generated_module_info(
        module_info => $module_info,
        fsm_module => $fsm_module,
        hdl_generator => $pipeline_for_full->{hdl_generator},
        target_language => 'systemverilog',
    );

    is_deeply(
        $rebuilt_structural_rtl_ir->as_hashref,
        $result->{structural_rtl_ir},
        'builder rebuilds the same bounded direct-root structural_rtl_ir surface as the pipeline',
    );
};

done_testing();

sub new_pipeline {
    return FSM::Pipeline::HDLGenerator->new(
        debug_level => 0,
        target_language => 'systemverilog',
        quiet => 1,
    );
}

sub write_file {
    my ($path, $content) = @_;
    open my $fh, '>', $path or die "Cannot open $path for write: $!";
    print {$fh} $content or die "Cannot write $path: $!";
    close $fh or die "Cannot close $path: $!";
}
