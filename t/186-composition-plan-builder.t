#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use File::Spec;
use File::Temp qw(tempdir);
use FindBin;

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::Composition::PlanBuilder;
use FSM::Pipeline::HDLGenerator;
use FSM::Pipeline::SourceFrontend;

subtest 'plan builder rebuilds the bounded C1 rtl passthrough lane' => sub {
    my $tempdir = tempdir(CLEANUP => 1);
    my $composition_path = File::Spec->catfile($tempdir, 'composition_plan_builder_c1_top.fsm');

    write_file(
        $composition_path,
        <<'FSM'
(?top:composition_plan_builder_c1_top
  (?ports:public_io
    core_clk
    rst_async_n
    data_in<8
    txd>
  )
  (?rtl:uart_tx)
)

(?rtlif:uart_tx
  core_clk:clock
  rst_async_n:reset
  data_in<8:data
  txd>:data
)
FSM
    );

    my $pipeline = new_pipeline();
    my $result = $pipeline->generate_hdl_from_file($composition_path);
    my $rebuilt = rebuild_plan($pipeline, $composition_path);

    is_deeply(
        plan_snapshot($rebuilt),
        plan_snapshot($result->{composition_plan}),
        'builder rebuilds the same bounded C1 rtl passthrough plan as the pipeline',
    );
};

subtest 'plan builder rebuilds the bounded C3 mixed explicit-link lane' => sub {
    my $tempdir = tempdir(CLEANUP => 1);
    my $composition_path = File::Spec->catfile($tempdir, 'composition_plan_builder_c3_top.fsm');

    write_file(
        $composition_path,
        <<'FSM'
(?top:composition_plan_builder_c3_top
  (?ports:public_io
    payload_in<8
    serial_out>
  )
  (?dtc:router route_src)
  (?rtl:uart_tx)
  (?wiring:wiring
    /payload_in/router.payload_in/
    /router.route_data/uart_tx.data_in/
    /uart_tx.txd/serial_out/
  )
)

(?dt:route_src
  (-route
    (route_data> = payload_in)
  )
  (+size
    (payload_in 8)
    (route_data 8)
  )
)

(?rtlif:uart_tx
  core_clk:clock
  rst_async_n:reset
  data_in<8:data
  txd>:data
)
FSM
    );

    my $pipeline = new_pipeline();
    my $result = $pipeline->generate_hdl_from_file($composition_path);
    my $rebuilt = rebuild_plan($pipeline, $composition_path);

    is_deeply(
        plan_snapshot($rebuilt),
        plan_snapshot($result->{composition_plan}),
        'builder rebuilds the same bounded C3 mixed explicit-link plan as the pipeline',
    );
};

subtest 'plan builder rebuilds the bounded C4 declared by-name lane' => sub {
    my $tempdir = tempdir(CLEANUP => 1);
    my $composition_path = File::Spec->catfile($tempdir, 'composition_plan_builder_c4_top.fsm');

    write_file(
        $composition_path,
        <<'FSM'
(?top:composition_plan_builder_c4_top
  (?ports:public_io
    core_clk
    rst_async_n
    =data_in<8
    =txd>
  )
  (?rtl:uart_tx)
)

(?rtlif:uart_tx
  core_clk:clock
  rst_async_n:reset
  data_in<8:data
  txd>:data
)
FSM
    );

    my $pipeline = new_pipeline();
    my $result = $pipeline->generate_hdl_from_file($composition_path);
    my $rebuilt = rebuild_plan($pipeline, $composition_path);

    is_deeply(
        plan_snapshot($rebuilt),
        plan_snapshot($result->{composition_plan}),
        'builder rebuilds the same bounded C4 declared by-name plan as the pipeline',
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

sub rebuild_plan {
    my ($pipeline, $composition_path) = @_;
    my $raw_ast = FSM::Pipeline::SourceFrontend->parse_fsm_file(
        fsm_file => $composition_path,
        debug_level => 0,
    );
    my $source_info = FSM::Pipeline::SourceFrontend->classify_source_ast($raw_ast);
    my $composition_spec = FSM::Pipeline::SourceFrontend->parse_composition_source(
        raw_ast => $raw_ast,
        debug_level => 0,
    );

    return FSM::Composition::PlanBuilder->build_plan(
        pipeline => $pipeline,
        composition_spec => $composition_spec,
        fsm_file => $composition_path,
        header => $source_info->{header},
        target_language => 'systemverilog',
        source_path_resolver => $pipeline->{source_path_resolver},
        rtl_interface_loader => $pipeline->{rtl_interface_loader},
    );
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
        targets => $net->targets,
    };
}

sub realized_instance_snapshot {
    my ($instance) = @_;
    return {
        kind => $instance->kind,
        instance_name => $instance->instance_name,
        module_name => $instance->module_name,
        source_name => $instance->source_name,
        metadata_path => $instance->module_info->{metadata_path},
        interface_ports => [map { port_snapshot($_) } @{$instance->interface_ports || []}],
        port_bindings => [map {
            +{
                port_name => $_->{port_name},
                signal_name => $_->{signal_name},
                connection_expr => $_->{connection_expr},
            }
        } @{$instance->port_bindings || []}],
    };
}

sub write_file {
    my ($path, $content) = @_;
    open my $fh, '>', $path or die "Cannot open $path for write: $!";
    print {$fh} $content or die "Cannot write $path: $!";
    close $fh or die "Cannot close $path: $!";
}
