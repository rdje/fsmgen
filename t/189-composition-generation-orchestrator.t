#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use File::Spec;
use File::Temp qw(tempdir);
use FindBin;

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::Backend::GeneratedModuleEmitter;
use FSM::Composition::GenerationOrchestrator;
use FSM::Pipeline::SourceFrontend;
use FSM::Pipeline::HDLGenerator;

subtest 'composition generation orchestrator rebuilds the bounded result surface from parsed inputs' => sub {
    my $tempdir = tempdir(CLEANUP => 1);
    my $composition_path = File::Spec->catfile($tempdir, 'composition_generation_orchestrator_top.fsm');

    write_file(
        $composition_path,
        <<'FSM'
(?top:composition_generation_orchestrator_top
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

    my $pipeline = FSM::Pipeline::HDLGenerator->new(
        debug_level => 0,
        target_language => 'systemverilog',
        quiet => 1,
    );

    my $statistics_seed = FSM::Backend::GeneratedModuleEmitter->statistics_from_generator(undef);
    my $pipeline_result = $pipeline->generate_hdl_from_file($composition_path);
    my $raw_ast = FSM::Pipeline::SourceFrontend->parse_fsm_file(
        fsm_file => $composition_path,
        debug_level => 0,
    );
    my $source_info = FSM::Pipeline::SourceFrontend->classify_source_ast($raw_ast);
    $source_info->{composition_spec} = FSM::Pipeline::SourceFrontend->parse_composition_source(
        raw_ast => $raw_ast,
        debug_level => 0,
    );

    my $orchestrated_result = FSM::Composition::GenerationOrchestrator->generate_from_source(
        pipeline => $pipeline,
        source_info => $source_info,
        raw_ast => $raw_ast,
        fsm_file => $composition_path,
        target_language => 'systemverilog',
        source_path_resolver => $pipeline->{source_path_resolver},
        rtl_interface_loader => $pipeline->{rtl_interface_loader},
        statistics_seed => $statistics_seed,
    );

    is_deeply(
        generation_snapshot($orchestrated_result),
        generation_snapshot($pipeline_result),
        'orchestrator rebuilds the same bounded composition generation surface as the pipeline',
    );
};

done_testing();

sub generation_snapshot {
    my ($result) = @_;
    return {
        fsm_module => $result->{fsm_module},
        composition_plan => plan_snapshot($result->{composition_plan}),
        composition_report => $result->{composition_report},
        intent_hir => $result->{intent_hir},
        lowered_rtl_ir => $result->{lowered_rtl_ir},
        structural_rtl_ir => $result->{structural_rtl_ir},
        module_info => $result->{module_info},
        top_module_text => final_module_text($result->{hdl_code}),
        statistics => $result->{statistics},
    };
}

sub final_module_text {
    my ($hdl_code) = @_;
    return '' unless defined $hdl_code && length $hdl_code;

    my @modules = ($hdl_code =~ /(module\b.*?endmodule)/sg);
    return @modules ? $modules[-1] : $hdl_code;
}

sub plan_snapshot {
    my ($plan) = @_;
    return {
        lane => $plan->lane,
        top_name => $plan->top_name,
        ports => [map { port_snapshot($_) } @{$plan->ports || []}],
        links => [map { link_snapshot($_) } @{$plan->links || []}],
        resolved_links => [map { resolved_link_snapshot($_) } @{$plan->resolved_links || []}],
        nets => [map { net_snapshot($_) } @{$plan->nets || []}],
        instances => [map { realized_instance_snapshot($_) } @{$plan->instances || []}],
        auxiliary_assignment_count => scalar(@{$plan->auxiliary_assignments || []}),
        shared_datapath_candidate_count => scalar(@{$plan->shared_datapath_candidates || []}),
    };
}

sub port_snapshot {
    my ($port) = @_;
    return {
        name => $port->name,
        direction => $port->direction,
        width => $port->width,
        type => $port->type,
        binding_mode => $port->binding_mode,
        origin_kind => $port->origin_kind,
    };
}

sub link_snapshot {
    my ($link) = @_;
    return {
        source => $link->source,
        target => $link->target,
        origin_kind => $link->origin_kind,
    };
}

sub resolved_link_snapshot {
    my ($entry) = @_;
    if (ref($entry) eq 'HASH') {
        return {
            source => $entry->{source}{raw},
            source_kind => $entry->{source}{kind},
            target => $entry->{target}{raw},
            target_kind => $entry->{target}{kind},
            origin_kind => $entry->{link} ? $entry->{link}->origin_kind : undef,
        };
    }

    return link_snapshot($entry);
}

sub net_snapshot {
    my ($net) = @_;
    return {
        name => $net->name,
        width => $net->width,
        source => $net->source,
        targets => [@{$net->targets || []}],
    };
}

sub realized_instance_snapshot {
    my ($instance) = @_;
    return {
        kind => $instance->kind,
        instance_name => $instance->instance_name,
        module_name => $instance->module_name,
        source_name => $instance->source_name,
        interface_ports => [
            map {
                +{
                    name => $_->name,
                    direction => $_->direction,
                    width => $_->width,
                    type => $_->type,
                }
            } @{$instance->interface_ports || []}
        ],
        port_bindings => [@{$instance->port_bindings || []}],
    };
}

sub write_file {
    my ($path, $content) = @_;
    open my $fh, '>', $path or die "Cannot open $path for write: $!";
    print {$fh} $content or die "Cannot write $path: $!";
    close $fh or die "Cannot close $path: $!";
}
