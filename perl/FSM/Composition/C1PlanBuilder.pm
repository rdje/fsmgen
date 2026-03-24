package FSM::Composition::C1PlanBuilder;

use v5.20;
use strict;
use warnings;
use Carp qw(confess);
use feature qw(signatures);
no warnings 'experimental::signatures';

use FSM::Composition::Link;
use FSM::Composition::Plan;
use FSM::Composition::Port;
use FSM::Composition::RealizedInstance;
use FSM::IR::StructuralRTLIR::ConnectionExpr qw(signal_ref_binding);

sub build_plan ($class, %args) {
    my $composition_spec = $args{composition_spec};
    my $ports_block = $args{ports_block};
    my $ports = $args{ports} || [];
    my $realized_instance = $args{realized_instance};
    my $fsm_file = $args{fsm_file};
    my $header = $args{header};

    confess "C1PlanBuilder requires a composition_spec"
        unless $composition_spec;
    confess "C1PlanBuilder requires a realized_instance"
        unless $realized_instance;

    my $child_port_info = _index_ports_by_name($realized_instance->interface_ports);
    my @effective_ports = @$ports;

    if (@effective_ports) {
        $class->assert_port_exposure_matches_child(
            ports_block => $ports_block,
            realized_instance => $realized_instance,
            child_port_info => $child_port_info,
            fsm_file => $fsm_file,
            header => $header,
        );
    } else {
        @effective_ports = @{$class->infer_ports_from_child_interface(
            realized_instance => $realized_instance,
            fsm_file => $fsm_file,
            header => $header,
        )};
    }

    my @port_bindings = map {
        signal_ref_binding($_->name, $_->name)
    } @effective_ports;
    my @resolved_links = map {
        my $port = $_;
        FSM::Composition::Link->new(
            source => ($port->direction eq 'input' ? $port->name : $realized_instance->instance_name.'.'.$port->name),
            target => ($port->direction eq 'input' ? $realized_instance->instance_name.'.'.$port->name : $port->name),
            raw_token => undef,
            origin_kind => ($port->binding_mode || 'explicit') eq 'implicit_passthrough'
                ? 'inferred_c1_passthrough_link'
                : 'declared_c1_passthrough_link',
        );
    } @effective_ports;

    my $planned_instance = _clone_realized_instance_with_bindings($realized_instance, \@port_bindings);

    return FSM::Composition::Plan->new(
        lane => 'C1',
        top_name => $composition_spec->top->name,
        ports => \@effective_ports,
        links => [],
        resolved_links => \@resolved_links,
        nets => [],
        instances => [$planned_instance],
        raw_spec => $composition_spec,
    );
}

sub infer_ports_from_child_interface ($class, %args) {
    my $realized_instance = $args{realized_instance};
    my $fsm_file = $args{fsm_file};
    my $header = $args{header};
    my @child_ports = @{$realized_instance->interface_ports || []};

    confess
        "Composition source '$header' in '$fsm_file' omits explicit top-port declarations in the single-child passthrough C1 lane, ".
        "but realized child instance '".$realized_instance->instance_name."' exposes no ports to infer. ".
        "See docs/COMPOSITION_SCOPE.md and docs/COMPOSITION_LEGACY_MAPPING.md.\n"
        unless @child_ports;

    return [
        map {
            FSM::Composition::Port->new(
                name => $_->name,
                direction => $_->direction,
                width => $_->width,
                type => $_->type,
                raw_token => undef,
                binding_mode => 'implicit_passthrough',
                origin_kind => 'inferred_c1_passthrough_port',
            )
        } @child_ports
    ];
}

sub assert_port_exposure_matches_child ($class, %args) {
    my $ports_block = $args{ports_block};
    my $realized_instance = $args{realized_instance};
    my $child_port_info = $args{child_port_info} || {};
    my $fsm_file = $args{fsm_file};
    my $header = $args{header};
    my $top_ports_by_name = _assert_unique_top_ports($ports_block, $fsm_file, $header);

    for my $child_port_name (sort keys %$child_port_info) {
        confess
            "Composition source '$header' in '$fsm_file' is recognized and parsed into typed composition IR, ".
            "but C1 passthrough exposure is blocked because the current active C1 lane requires every child port to be explicitly exposed in '?ports'. ".
            "Missing top exposure for child port '$child_port_name' on instance '".$realized_instance->instance_name."'. ".
            "See docs/COMPOSITION_SCOPE.md and docs/COMPOSITION_LEGACY_MAPPING.md.\n"
            unless $top_ports_by_name->{$child_port_name};
    }

    for my $port (@{$ports_block->ports}) {
        my $child_port = $child_port_info->{$port->name};
        confess
            "Composition source '$header' in '$fsm_file' declares top port '".$port->name."', ".
            "but C1 passthrough exposure is blocked because the realized child interface has no port with that name. ".
            "See docs/COMPOSITION_SCOPE.md and docs/COMPOSITION_LEGACY_MAPPING.md.\n"
            unless $child_port;

        confess
            "Composition source '$header' in '$fsm_file' declares top port '".$port->name."' with width ".$port->width.", ".
            "but C1 passthrough exposure is blocked because child port '".$port->name."' has width ".$child_port->width.".".
            "See docs/COMPOSITION_SCOPE.md and docs/COMPOSITION_LEGACY_MAPPING.md.\n"
            unless $port->width == $child_port->width;

        confess
            "Composition source '$header' in '$fsm_file' declares top port '".$port->name."' as ".$port->direction.", ".
            "but C1 passthrough exposure is blocked because child port '".$port->name."' is ".$child_port->direction.".".
            "See docs/COMPOSITION_SCOPE.md and docs/COMPOSITION_LEGACY_MAPPING.md.\n"
            unless $port->direction eq $child_port->direction;
    }
}

sub _index_ports_by_name ($ports) {
    my %ports;

    for my $port (@{$ports || []}) {
        $ports{$port->name} = $port;
    }

    return \%ports;
}

sub _assert_unique_top_ports ($ports_block, $fsm_file, $header) {
    my %top_ports_by_name;
    for my $port (@{$ports_block->ports || []}) {
        confess
            "Composition source '$header' in '$fsm_file' declares duplicate top port '".$port->name."' in '?ports', ".
            "but composition shape is blocked because the active composition lanes require each top port name to be unique. ".
            "See docs/COMPOSITION_SCOPE.md and docs/COMPOSITION_LEGACY_MAPPING.md.\n"
            if $top_ports_by_name{$port->name};

        $top_ports_by_name{$port->name} = $port;
    }

    return \%top_ports_by_name;
}

sub _clone_realized_instance_with_bindings ($instance, $port_bindings) {
    return FSM::Composition::RealizedInstance->new(
        kind => $instance->kind,
        instance_name => $instance->instance_name,
        module_name => $instance->module_name,
        source_name => $instance->source_name,
        interface_ports => $instance->interface_ports,
        port_bindings => $port_bindings || [],
        module_info => $instance->module_info,
        hdl_code => $instance->hdl_code,
    );
}

1;

__END__

=head1 NAME

FSM::Composition::C1PlanBuilder - Builder for the bounded single-child C1 composition lane

=head1 DESCRIPTION

This module owns the extracted plan-construction logic for the single-child
passthrough C1 composition lane. It currently covers explicit passthrough
exposure validation, implicit top-port inference from one realized child
interface, and the final C1 plan assembly with direct passthrough links and
bindings.

=cut
