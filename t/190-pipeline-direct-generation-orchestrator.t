#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use File::Spec;
use File::Temp qw(tempdir);
use FindBin;

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::Pipeline::DirectGenerationOrchestrator;
use FSM::Pipeline::HDLGenerator;
use FSM::Pipeline::SourceFrontend;

subtest 'direct generation orchestrator rebuilds the bounded direct-root result surface from parsed inputs' => sub {
    my $tempdir = tempdir(CLEANUP => 1);
    my $fsm_path = File::Spec->catfile($tempdir, 'direct_generation_orchestrator_root.fsm');

    write_file(
        $fsm_path,
        <<'FSM'
(?dt:direct_generation_orchestrator_root
  (-route
    (serial_out> = trigger)
  )
  (+size
    (trigger 1)
    (serial_out 1)
  )
)
FSM
    );

    my $pipeline_for_direct = new_pipeline();
    my $raw_ast = FSM::Pipeline::SourceFrontend->parse_fsm_file(
        fsm_file => $fsm_path,
        debug_level => 0,
    );
    my $source_info = FSM::Pipeline::SourceFrontend->classify_source_ast($raw_ast);
    my $direct_result = FSM::Pipeline::DirectGenerationOrchestrator->generate_from_source(
        pipeline => $pipeline_for_direct,
        raw_ast => $raw_ast,
        source_info => $source_info,
    );

    my $pipeline_for_full = new_pipeline();
    my $pipeline_result = $pipeline_for_full->generate_hdl_from_file($fsm_path);

    is_deeply(
        generation_snapshot($direct_result),
        generation_snapshot($pipeline_result),
        'orchestrator rebuilds the same bounded direct-root generation surface as the pipeline',
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

sub generation_snapshot {
    my ($result) = @_;
    return {
        fsm_module_name => ($result->{fsm_module} ? $result->{fsm_module}->name : undef),
        source_root_kind => ($result->{fsm_module} && $result->{fsm_module}->can('source_root_kind')
            ? $result->{fsm_module}->source_root_kind
            : undef),
        intent_hir => $result->{intent_hir},
        lowered_rtl_ir => $result->{lowered_rtl_ir},
        structural_rtl_ir => $result->{structural_rtl_ir},
        module_info => module_info_snapshot($result->{module_info}),
        hdl_code => normalized_hdl_code($result->{hdl_code}),
        statistics => $result->{statistics},
        source_info_kind => ($result->{source_info} || {})->{kind},
        source_info_header => ($result->{source_info} || {})->{header},
    };
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

sub normalized_hdl_code {
    my ($hdl_code) = @_;
    return '' unless defined $hdl_code && length $hdl_code;

    $hdl_code =~ s{// Date: .*}{// Date: <normalized>}g;
    return $hdl_code;
}

sub write_file {
    my ($path, $content) = @_;
    open my $fh, '>', $path or die "Cannot open $path for write: $!";
    print {$fh} $content or die "Cannot write $path: $!";
    close $fh or die "Cannot close $path: $!";
}
