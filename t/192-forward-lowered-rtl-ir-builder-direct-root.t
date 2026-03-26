#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use File::Spec;
use File::Temp qw(tempdir);
use FindBin;

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::IR::LoweredRTLIRBuilder;
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

    my $pipeline_for_builder = new_pipeline();
    my $raw_ast = $pipeline_for_builder->parse_fsm_file($fsm_path);
    my $fsm_module = $pipeline_for_builder->create_fsm_module($raw_ast);
    my $intent_hir = $pipeline_for_builder->build_intent_hir($fsm_module);
    my $module_info = $pipeline_for_builder->analyze_fsm_module($fsm_module, $intent_hir);
    $pipeline_for_builder->generate_hdl_code($fsm_module);

    my $rebuilt_lowered_rtl_ir = FSM::IR::LoweredRTLIRBuilder->build_from_generated_module_info(
        module_info => $module_info,
        fsm_module => $fsm_module,
        target_language => 'systemverilog',
        hdl_generator => $pipeline_for_builder->{hdl_generator},
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
