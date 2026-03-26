#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use File::Spec;
use File::Temp qw(tempdir);
use FindBin;

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::Backend::GeneratedModuleEmitter;
use FSM::IR::IntentHIRBuilder;
use FSM::IR::LoweredRTLIRBuilder;
use FSM::Pipeline::GeneratedModuleInfoBuilder;
use FSM::Pipeline::SourceFrontend;
use FSM::Pipeline::HDLGenerator;

subtest 'lowered rtl ir builder rebuilds the bounded direct-root lowered surface from generated analysis inputs' => sub {
    my $tempdir = tempdir(CLEANUP => 1);
    my $fsm_path = File::Spec->catfile($tempdir, 'lowered_rtl_ir_builder_direct_root.fsm');

    write_file(
        $fsm_path,
        <<'FSM'
(?dt:lowered_rtl_ir_builder_direct_root
  (-route
    (<trigger
      (serial_out> = 8'1)
    )
    (<!trigger
      (serial_out> = 8'0)
    )
  )
  (+size
    (trigger 1)
    (serial_out 8)
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
    my $backend_result = FSM::Backend::GeneratedModuleEmitter->emit_from_fsm_module(
        fsm_module => $fsm_module,
        target_language => 'systemverilog',
        debug_level => 0,
    );

    my $rebuilt_lowered_rtl_ir = FSM::IR::LoweredRTLIRBuilder->build_from_generated_module_info(
        module_info => $module_info,
        fsm_module => $fsm_module,
        target_language => 'systemverilog',
        hdl_generator => $backend_result->{hdl_generator},
    );

    my $pipeline_for_full = new_pipeline();
    my $result = $pipeline_for_full->generate_hdl_from_file($fsm_path);

    is_deeply(
        $rebuilt_lowered_rtl_ir->as_hashref,
        $result->{lowered_rtl_ir},
        'builder rebuilds the same bounded direct-root lowered_rtl_ir surface as the pipeline',
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
