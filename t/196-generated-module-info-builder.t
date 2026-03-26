#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use File::Spec;
use File::Temp qw(tempdir);
use FindBin;

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::Backend::GeneratedModuleEmitter;
use FSM::Pipeline::GeneratedModuleInfoBuilder;
use FSM::Pipeline::HDLGenerator;

subtest 'generated module-info builder rebuilds the bounded direct-root module_info surface from semantic inputs' => sub {
    my $tempdir = tempdir(CLEANUP => 1);
    my $fsm_path = File::Spec->catfile($tempdir, 'generated_module_info_builder_root.fsm');

    write_file(
        $fsm_path,
        <<'FSM'
(?dt:generated_module_info_builder_root
  (-left
    (<trigger
      (serial_out> = 1)
    )
  )
  (-right
    (<!trigger
      (serial_out> = 0)
    )
  )
  (+size
    (trigger 1)
    (serial_out 1)
  )
)
FSM
    );

    my $pipeline_for_builder = new_pipeline();
    my $raw_ast = $pipeline_for_builder->parse_fsm_file($fsm_path);
    my $fsm_module = $pipeline_for_builder->create_fsm_module($raw_ast);
    my $intent_hir = $pipeline_for_builder->build_intent_hir($fsm_module);
    my $module_info = FSM::Pipeline::GeneratedModuleInfoBuilder->build_from_fsm_module(
        fsm_module => $fsm_module,
        intent_hir => $intent_hir,
    );
    my $backend_result = FSM::Backend::GeneratedModuleEmitter->emit_from_fsm_module(
        fsm_module => $fsm_module,
        target_language => 'systemverilog',
        debug_level => 0,
    );
    FSM::Pipeline::GeneratedModuleInfoBuilder->enrich_with_generated_analysis(
        module_info => $module_info,
        fsm_module => $fsm_module,
        target_language => 'systemverilog',
        hdl_generator => $backend_result->{hdl_generator},
    );
    my $structural_rtl_ir = $pipeline_for_builder->build_structural_rtl_ir($module_info, $fsm_module);
    $module_info->{structural_rtl_ir} = $structural_rtl_ir->as_hashref;

    my $pipeline_for_full = new_pipeline();
    my $pipeline_result = $pipeline_for_full->generate_hdl_from_file($fsm_path);

    is_deeply(
        module_info_snapshot($module_info),
        module_info_snapshot($pipeline_result->{module_info}),
        'builder rebuilds the same bounded generated module_info surface as the pipeline',
    );

    is_deeply(
        FSM::Pipeline::GeneratedModuleInfoBuilder->output_drive_families_from_module_info($module_info),
        $pipeline_result->{module_info}{output_drive_families},
        'builder query returns the same normalized output-drive-family surface',
    );

    is_deeply(
        FSM::Pipeline::GeneratedModuleInfoBuilder->standalone_dt_multi_drive_targets_from_module_info($module_info),
        $pipeline_result->{module_info}{standalone_dt_multi_drive_targets},
        'builder query returns the same grouped standalone-DT multi-drive-target surface',
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

sub module_info_snapshot {
    my ($module_info) = @_;
    return {
        module_name => $module_info->{module_name},
        source_root_kind => $module_info->{source_root_kind},
        regular_state_count => $module_info->{regular_state_count},
        regular_state_names => $module_info->{regular_state_names},
        state_count => $module_info->{state_count},
        standalone_dt_count => $module_info->{standalone_dt_count},
        standalone_dt_names => $module_info->{standalone_dt_names},
        signal_count => $module_info->{signal_count},
        signal_names => $module_info->{signal_names},
        signal_analysis => $module_info->{signal_analysis},
        explicit_system_contract => $module_info->{explicit_system_contract},
        system_contract => $module_info->{system_contract},
        requires_implicit_system_ports => $module_info->{requires_implicit_system_ports},
        standalone_dt_enable_families => $module_info->{standalone_dt_enable_families},
        standalone_dt_module_enable_family => $module_info->{standalone_dt_module_enable_family},
        parameter_count => $module_info->{parameter_count},
        parameter_names => $module_info->{parameter_names},
        intent_hir => $module_info->{intent_hir},
        lowered_rtl_ir => $module_info->{lowered_rtl_ir},
        structural_rtl_ir => $module_info->{structural_rtl_ir},
        output_drive_family_count => $module_info->{output_drive_family_count},
        output_drive_families => $module_info->{output_drive_families},
        standalone_dt_multi_drive_target_count => $module_info->{standalone_dt_multi_drive_target_count},
        standalone_dt_multi_drive_targets => $module_info->{standalone_dt_multi_drive_targets},
    };
}

sub write_file {
    my ($path, $content) = @_;
    open my $fh, '>', $path or die "Cannot open $path for write: $!";
    print {$fh} $content or die "Cannot write $path: $!";
    close $fh or die "Cannot close $path: $!";
}
