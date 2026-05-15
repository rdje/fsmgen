#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use File::Spec;
use File::Temp qw(tempdir);
use FindBin;

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::Pipeline::HDLGenerator;
use FSM::Pipeline::SourceGenerationOrchestrator;

{
    package Test::SourceOrchestratorRecordingExtension;

    use v5.20;
    use strict;
    use warnings;
    use feature qw(signatures);
    no warnings 'experimental::signatures';

    sub new ($class) {
        return bless {
            parse_calls => [],
            result_calls => [],
        }, $class;
    }

    sub after_parse_source ($self, $context) {
        push @{$self->{parse_calls}}, {
            stage => $context->stage,
            source_path => $context->source_path,
            source_kind => $context->source_info->{kind},
            has_raw_ast => ($context->raw_ast ? 1 : 0),
        };
    }

    sub after_generate_result ($self, $context) {
        push @{$self->{result_calls}}, {
            stage => $context->stage,
            source_path => $context->source_path,
            source_kind => $context->source_info->{kind},
            target_language => $context->target_language,
        };

        $context->result->{extension_marker} = {
            source_kind => $context->source_info->{kind},
            target_language => $context->target_language,
            parse_call_count => scalar(@{$self->{parse_calls}}),
        };
    }

    sub parse_calls ($self) { return $self->{parse_calls} }
    sub result_calls ($self) { return $self->{result_calls} }
}

subtest 'source generation orchestrator rebuilds the bounded direct-root result surface from a source file' => sub {
    my $tempdir = tempdir(CLEANUP => 1);
    my $fsm_path = File::Spec->catfile($tempdir, 'source_generation_orchestrator_direct_root.fsm');

    write_file(
        $fsm_path,
        <<'FSM'
(?dt:source_generation_orchestrator_direct_root
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
    my $direct_result = FSM::Pipeline::SourceGenerationOrchestrator->generate_from_file(
        pipeline => $pipeline_for_direct,
        fsm_file => $fsm_path,
    );

    my $pipeline_for_full = new_pipeline();
    my $pipeline_result = $pipeline_for_full->generate_hdl_from_file($fsm_path);

    is_deeply(
        generation_snapshot($direct_result),
        generation_snapshot($pipeline_result),
        'source orchestrator rebuilds the same bounded direct-root generation surface as the pipeline',
    );
};

subtest 'source generation orchestrator rebuilds the bounded composition result surface from a source file' => sub {
    my $tempdir = tempdir(CLEANUP => 1);
    my $composition_path = File::Spec->catfile($tempdir, 'source_generation_orchestrator_composition_top.fsm');

    write_file(
        $composition_path,
        <<'FSM'
(?top:source_generation_orchestrator_composition_top
  (?ports:public_io
    trigger
    serial_out>
  )
  (?dtc:producer producer_src)
  (?rtl:uart_tx)
  (?wiring:wiring
    /trigger/producer.trigger/
    /producer.serial_payload/uart_tx.data_in/
    /uart_tx.serial_out/serial_out/
  )
)

(?dt:producer_src
  (-route
    (<trigger
      (serial_payload> = 8'1)
    )
    (<!trigger
      (serial_payload> = 8'0)
    )
  )
  (+size
    (trigger 1)
    (serial_payload 8)
  )
)

(?rtlif:uart_tx
  core_clk:clock
  rst_async_n:reset
  data_in<8:data
  serial_out>:data
)
FSM
    );

    my $pipeline_for_source = new_pipeline();
    my $source_result = FSM::Pipeline::SourceGenerationOrchestrator->generate_from_file(
        pipeline => $pipeline_for_source,
        fsm_file => $composition_path,
    );

    my $pipeline_for_full = new_pipeline();
    my $pipeline_result = $pipeline_for_full->generate_hdl_from_file($composition_path);

    is_deeply(
        generation_snapshot($source_result),
        generation_snapshot($pipeline_result),
        'source orchestrator rebuilds the same bounded composition generation surface as the pipeline',
    );
};

subtest 'source generation orchestrator still drives extension hooks around direct and composition generation' => sub {
    my $tempdir = tempdir(CLEANUP => 1);
    my $fsm_path = File::Spec->catfile($tempdir, 'source_generation_orchestrator_hook_direct.fsm');
    my $composition_path = File::Spec->catfile($tempdir, 'source_generation_orchestrator_hook_composition.fsm');

    write_file(
        $fsm_path,
        <<'FSM'
(?fsm:source_generation_orchestrator_hook_direct
  (+system
    (clock clk)
    (sreset rstn)
  )
  (-idle
    (OUT <= 1)
  )
  (+size
    (OUT 1)
  )
)
FSM
    );

    write_file(
        $composition_path,
        <<'FSM'
(?top:source_generation_orchestrator_hook_composition
  (?ports:public_io
    clk
    rstn
    output_data>8
  )
  (?fsmc:child child_src)
)

(?fsm:child_src
  (+system
    (clock clk)
    (sreset rstn)
  )
  (-idle
    (output_data> <= 8'1)
  )
  (+size
    (output_data 8)
  )
)
FSM
    );

    my $extension = Test::SourceOrchestratorRecordingExtension->new;
    my $pipeline = new_pipeline($extension);

    my $direct_result = FSM::Pipeline::SourceGenerationOrchestrator->generate_from_file(
        pipeline => $pipeline,
        fsm_file => $fsm_path,
    );
    is($direct_result->{extension_marker}{parse_call_count}, 1, 'direct path sees one parse hook before result finalization');
    is($direct_result->{extension_marker}{source_kind}, 'fsm', 'direct path result hook sees FSM source kind');
    is($direct_result->{extension_marker}{target_language}, 'systemverilog', 'direct path result hook sees target language');

    my $composition_result = FSM::Pipeline::SourceGenerationOrchestrator->generate_from_file(
        pipeline => $pipeline,
        fsm_file => $composition_path,
    );
    is($composition_result->{extension_marker}{parse_call_count}, 2, 'composition path sees the second parse hook before result finalization');
    is($composition_result->{extension_marker}{source_kind}, 'composition', 'composition path result hook sees composition source kind');

    is(scalar(@{$extension->parse_calls}), 2, 'parse hook ran once per orchestrated generation call');
    is($extension->parse_calls->[0]{stage}, 'after_parse_source', 'parse hook keeps its typed stage name');
    ok($extension->parse_calls->[0]{has_raw_ast}, 'parse hook still receives raw parsed AST');
    is($extension->parse_calls->[1]{source_kind}, 'composition', 'composition parse hook sees composition classification');

    is(scalar(@{$extension->result_calls}), 2, 'result hook ran once per orchestrated generation call');
    is($extension->result_calls->[0]{stage}, 'after_generate_result', 'result hook keeps its typed stage name');
    is($extension->result_calls->[1]{source_kind}, 'composition', 'composition result hook sees composition classification');
};

done_testing();

sub new_pipeline {
    my ($extension) = @_;
    my %args = (
        debug_level => 0,
        target_language => 'systemverilog',
        quiet => 1,
    );
    $args{extensions} = [$extension] if $extension;
    return FSM::Pipeline::HDLGenerator->new(%args);
}

sub generation_snapshot {
    my ($result) = @_;
    return {
        fsm_module_name => ($result->{fsm_module} ? $result->{fsm_module}->name : undef),
        source_root_kind => ($result->{fsm_module} && $result->{fsm_module}->can('source_root_kind')
            ? $result->{fsm_module}->source_root_kind
            : undef),
        composition_plan => $result->{composition_plan} ? composition_plan_snapshot($result->{composition_plan}) : undef,
        composition_report => $result->{composition_report},
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

sub composition_plan_snapshot {
    my ($plan) = @_;
    return {
        lane => $plan->lane,
        top_name => $plan->top_name,
        port_count => scalar(@{$plan->ports || []}),
        link_count => scalar(@{$plan->links || []}),
        resolved_link_count => scalar(@{$plan->resolved_links || []}),
        net_count => scalar(@{$plan->nets || []}),
        instance_count => scalar(@{$plan->instances || []}),
        auxiliary_assignment_count => scalar(@{$plan->auxiliary_assignments || []}),
        shared_datapath_candidate_count => scalar(@{$plan->shared_datapath_candidates || []}),
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
        composition_report => $module_info->{composition_report},
        composition_child_count => $module_info->{composition_child_count},
        composition_generated_child_count => $module_info->{composition_generated_child_count},
        composition_standalone_dt_child_count => $module_info->{composition_standalone_dt_child_count},
    };
}

sub normalized_hdl_code {
    my ($hdl_code) = @_;
    return '' unless defined $hdl_code && length $hdl_code;

    $hdl_code =~ s{// Date: .*}{// Date: <normalized>}g;
    $hdl_code =~ s{
        (//\s+Consolidated\ intermediate\ signals.*?\n)
        (.*?)
        (\n\s*//\s+Unified\ WEN/EN\ Signal\ Generation\ from\ Phase\ 1\ Analysis)
    }{
        my ($header, $body, $footer) = ($1, $2, $3);
        my @body_lines = grep { length($_) } split /\n/, $body;
        $header . join("\n", sort @body_lines) . $footer;
    }gsex;
    return $hdl_code;
}

sub write_file {
    my ($path, $content) = @_;
    open my $fh, '>', $path or die "Cannot open $path for write: $!";
    print {$fh} $content or die "Cannot write $path: $!";
    close $fh or die "Cannot close $path: $!";
}
