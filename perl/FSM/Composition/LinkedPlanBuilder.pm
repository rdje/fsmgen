package FSM::Composition::LinkedPlanBuilder;

=head1 NAME

FSM::Composition::LinkedPlanBuilder - Builder for explicit-link composition plans

=head1 DESCRIPTION

Builds the bounded explicit-link composition plans used by the active C2, C3,
and C4 lanes. This package owns explicit-toplink lane entry, endpoint
resolution, role validation, deterministic carrier-net allocation, system-port
auto-wiring, and realized-child rebinding for linked composition plans.

=cut

use v5.20;
use strict;
use warnings;
use Carp qw(confess);
use Math::BigInt ();
use feature qw(signatures);
no warnings 'experimental::signatures';

use FSM::Composition::Link;
use FSM::Composition::Net;
use FSM::Composition::Plan;
use FSM::Composition::RealizedInstance;
use FSM::Composition::SameNameLinkBuilder;
use FSM::IR::StructuralRTLIR::ConnectionExpr qw(
    bit_select_expr
    bit_vector_literal_expr
    concat_expr
    normalized_binding
    open_expr
    repeat_expr
    render_expr
    signal_ref_binding
    signal_ref_expr
    slice_expr
);

sub build_from_toplinks ($class, %args) {
    my $lane = $args{lane} // '';
    my $toplinks = $args{toplinks} || [];
    my $fsm_file = $args{fsm_file};
    my $header = $args{header};

    my @links = map { @{$_->links || []} } @$toplinks;
    confess
        "Composition source '$header' in '$fsm_file' is recognized and parsed into typed composition IR, ".
        "but explicit-link lane entry is blocked because the current active $lane lane requires explicit '?toplink' wiring. ".
        "See docs/COMPOSITION_SCOPE.md and docs/COMPOSITION_LEGACY_MAPPING.md.\n"
        unless @links;

    return $class->build_plan(
        %args,
        links => \@links,
    );
}

sub build_plan ($class, %args) {
    my $lane = $args{lane} // '';
    my $composition_spec = $args{composition_spec};
    my $top = $args{top};
    my $ports_block = $args{ports_block};
    my $ports = $args{ports} || [];
    my $links = $args{links} || [];
    my $realized_instances = $args{realized_instances} || [];
    my $fsm_file = $args{fsm_file};
    my $header = $args{header};

    my $top_ports_by_name = $class->assert_unique_top_ports($ports_block, $fsm_file, $header);
    my %instances_by_name;
    my %child_ports_by_instance;
    my %bindings_by_instance;
    my %reserved_targets;
    my %system_top_ports;
    my @system_auto_links;

    for my $instance (@$realized_instances) {
        confess
            "Composition source '$header' in '$fsm_file' declares duplicate child instance name '".$instance->instance_name."', ".
            "but composition shape is blocked because the active composition lanes require each realized child instance name to be unique. ".
            "See docs/COMPOSITION_SCOPE.md and docs/COMPOSITION_LEGACY_MAPPING.md.\n"
            if $instances_by_name{$instance->instance_name};

        $instances_by_name{$instance->instance_name} = $instance;
        $child_ports_by_instance{$instance->instance_name} = $class->index_ports_by_name($instance->interface_ports);
        $bindings_by_instance{$instance->instance_name} = {
            map { $_->name => undef } @{$instance->interface_ports}
        };
    }

    my @resolved_links_input = @$links;
    if ($lane eq 'C2' || $lane eq 'C3') {
        push @resolved_links_input, @{
            FSM::Composition::SameNameLinkBuilder->build_top_input_links(
                ports => $ports,
                explicit_links => $links,
                realized_instances => $realized_instances,
                fsm_file => $fsm_file,
                header => $header,
            )
        };
        push @resolved_links_input, @{
            FSM::Composition::SameNameLinkBuilder->build_top_output_links(
                ports => $ports,
                explicit_links => $links,
                realized_instances => $realized_instances,
                fsm_file => $fsm_file,
                header => $header,
            )
        };
        push @resolved_links_input, @{
            FSM::Composition::SameNameLinkBuilder->build_internal_same_name_links(
                ports => $ports,
                explicit_links => $links,
                realized_instances => $realized_instances,
                fsm_file => $fsm_file,
                header => $header,
            )
        };
    }

    for my $instance (@$realized_instances) {
        for my $system_port ($class->system_interface_ports($instance->interface_ports)->@*) {
            my $system_port_name = $system_port->name;
            my $top_port = $top_ports_by_name->{$system_port_name} or next;
            my $child_port = $child_ports_by_instance{$instance->instance_name}{$system_port_name} or next;

            confess
                "Composition source '$header' in '$fsm_file' declares top port '$system_port_name' as ".$top_port->direction.", ".
                "but the current active $lane lane requires '$system_port_name' to be an input when auto-wiring child system ports. ".
                "See docs/COMPOSITION_SCOPE.md and docs/COMPOSITION_LEGACY_MAPPING.md.\n"
                unless $top_port->direction eq 'input';

            confess
                "Composition source '$header' in '$fsm_file' realizes child port '".$instance->instance_name.".$system_port_name' as ".$child_port->direction.", ".
                "but the current active $lane lane expects child system ports to be inputs. ".
                "See docs/COMPOSITION_SCOPE.md and docs/COMPOSITION_LEGACY_MAPPING.md.\n"
                unless $child_port->direction eq 'input';

            $bindings_by_instance{$instance->instance_name}{$system_port_name} = $system_port_name;
            $reserved_targets{"child:".$instance->instance_name.".$system_port_name"} = "auto top input '$system_port_name'";
            $system_top_ports{$system_port_name} = 1;
            push @system_auto_links, FSM::Composition::Link->new(
                source => $system_port_name,
                target => $instance->instance_name.'.'.$system_port_name,
                raw_token => undef,
                origin_kind => 'auto_system_port_link',
            );
        }
    }

    my @resolved_links;
    my %links_by_source;
    my %source_endpoint_by_key;
    my %top_port_usage;
    my @auxiliary_assignments;
    my @nets;
    my %carrier_signal_by_source;

    for my $link (@resolved_links_input) {
        my $source = $class->resolve_endpoint(
            $link->source,
            $top_ports_by_name,
            \%instances_by_name,
            \%child_ports_by_instance,
            $fsm_file,
            $header,
            allow_top_expression_source => 1,
            allow_child_expression_source => 1,
        );
        my $target = $class->resolve_endpoint(
            $link->target,
            $top_ports_by_name,
            \%instances_by_name,
            \%child_ports_by_instance,
            $fsm_file,
            $header,
        );

        $class->assert_link_roles($source, $target, $fsm_file, $header);

        my $source_width = $class->endpoint_width($source);
        my $target_width = $class->endpoint_width($target);

        confess
            "Composition source '$header' in '$fsm_file' links '".$source->{raw}."' (width $source_width) to '".$target->{raw}."' (width $target_width), ".
            "but explicit link is blocked because the current active composition lanes require exact width agreement. ".
            "See docs/COMPOSITION_SCOPE.md and docs/COMPOSITION_LEGACY_MAPPING.md.\n"
            unless (($source->{kind} || '') eq 'actual_open')
                || (($source->{kind} || '') eq 'actual_scalar_literal')
                || (($source->{kind} || '') eq 'actual_unsized_binary')
                || (($source->{kind} || '') eq 'actual_unsized_decimal')
                || (($source->{kind} || '') eq 'actual_unsized_signed_decimal')
                || (($source->{kind} || '') eq 'actual_unsized_signed_binary')
                || (($source->{kind} || '') eq 'actual_unsized_signed_octal')
                || (($source->{kind} || '') eq 'actual_unsized_signed_hex')
                || (($source->{kind} || '') eq 'actual_unsized_octal')
                || (($source->{kind} || '') eq 'actual_unsized_hex')
                || $source_width == $target_width;

        my $target_key = $target->{key};
        if ($reserved_targets{$target_key}) {
            confess
                "Composition source '$header' in '$fsm_file' assigns explicit link driver '".$source->{raw}."' to target '".$target->{raw}."', ".
                "but explicit link is blocked because that target is already driven by ".$reserved_targets{$target_key}.". ".
                "See docs/COMPOSITION_SCOPE.md and docs/COMPOSITION_LEGACY_MAPPING.md.\n";
        }
        $reserved_targets{$target_key} = "explicit link '".$source->{raw}."'";

        if (($source->{kind} || '') =~ /^actual_/ || ($source->{kind} || '') eq 'top_expr') {
            my $bound_connection_expr = (($source->{kind} || '') =~ /^actual_/)
                ? $class->actual_connection_expr_for_target($source, $target_width, $fsm_file, $header)
                : $source->{connection_expr};

            if (($source->{kind} || '') eq 'top_expr') {
                for my $top_port_name (@{$source->{base_port_names} || []}) {
                    $top_port_usage{$top_port_name}{source} = 1;
                }

                if (@{$source->{child_base_sources} || []}) {
                    my %child_carrier_by_base_endpoint;
                    for my $child_base_source (@{$source->{child_base_sources} || []}) {
                        my $carrier_signal_name = $class->ensure_child_source_carrier(
                            $child_base_source,
                            [$target->{raw}],
                            $top_ports_by_name,
                            \@nets,
                            \%bindings_by_instance,
                            \%carrier_signal_by_source,
                        );
                        $child_carrier_by_base_endpoint{$child_base_source->{raw}} = $carrier_signal_name;
                    }

                    $bound_connection_expr = $class->rebind_source_expr_with_child_carriers(
                        $source->{connection_expr},
                        \%child_carrier_by_base_endpoint,
                    );
                }

                if ($target->{kind} eq 'top_port') {
                    my $expr_text = render_expr($bound_connection_expr, $target->{port}->name, 'systemverilog');
                    push @auxiliary_assignments, "    assign ".$target->{port}->name." = $expr_text;";
                    $top_port_usage{$target->{port}->name}{target} = 1;
                    push @resolved_links, {
                        link => $link,
                        source => $source,
                        target => $target,
                    };
                    next;
                }
            }
            elsif ($target->{kind} eq 'top_port') {
                my $expr_text = render_expr($bound_connection_expr, $target->{port}->name, 'systemverilog');
                push @auxiliary_assignments, "    assign ".$target->{port}->name." = $expr_text;";
                $top_port_usage{$target->{port}->name}{target} = 1;
                push @resolved_links, {
                    link => $link,
                    source => $source,
                    target => $target,
                };
                next;
            }

            $bindings_by_instance{$target->{instance_name}}{$target->{port}->name} = normalized_binding({
                port_name => $target->{port}->name,
                connection_expr => $bound_connection_expr,
            });
            push @resolved_links, {
                link => $link,
                source => $source,
                target => $target,
            };
            next;
        }

        my $source_key = $class->source_family_key($source);
        $source_endpoint_by_key{$source_key} ||= $class->source_family_endpoint($source);
        push @{$links_by_source{$source_key}}, {
            link => $link,
            source => $source,
            target => $target,
        };
        push @resolved_links, {
            link => $link,
            source => $source,
            target => $target,
        };
    }

    for my $source_key (sort keys %links_by_source) {
        my $source = $source_endpoint_by_key{$source_key};
        my @group = @{$links_by_source{$source_key}};

        if ($source->{kind} eq 'top_port') {
            for my $resolved_link (@group) {
                next unless $resolved_link->{target}{kind} eq 'top_port';
                push @auxiliary_assignments, "    assign ".$resolved_link->{target}{port}->name." = ".$source->{port}->name.";";
            }
            $carrier_signal_by_source{$source_key} = $source->{port}->name;
            next;
        }

        my @top_output_targets = grep { $_->{target}{kind} eq 'top_port' } @group;
        my $group_has_child_expr = grep { ($_->{source}{kind} || '') eq 'child_expr' } @group;

        my $carrier_signal_name;
        if (defined $carrier_signal_by_source{$source_key}) {
            $carrier_signal_name = $class->ensure_child_source_carrier(
                $source,
                [map { $_->{target}{raw} } @group],
                $top_ports_by_name,
                \@nets,
                \%bindings_by_instance,
                \%carrier_signal_by_source,
            );
        }
        elsif (!$group_has_child_expr && @top_output_targets == 1) {
            $carrier_signal_name = $top_output_targets[0]{target}{port}->name;
            $carrier_signal_by_source{$source_key} = $carrier_signal_name;
            $bindings_by_instance{$source->{instance_name}}{$source->{port}->name} = $carrier_signal_name;
        }
        else {
            my $preferred_net_name;
            if (@group) {
                my @implicit_internal_names = map {
                    my $raw_token = $_->{link}->raw_token;
                    defined($raw_token) && $raw_token =~ /^=implicit-internal:(\w+)$/ ? $1 : ()
                } @group;
                if (@implicit_internal_names == @group) {
                    my %names = map { $_ => 1 } @implicit_internal_names;
                    $preferred_net_name = $implicit_internal_names[0] if keys(%names) == 1;
                }
            }

            $carrier_signal_name = $class->ensure_child_source_carrier(
                $source,
                [map { $_->{target}{raw} } @group],
                $top_ports_by_name,
                \@nets,
                \%bindings_by_instance,
                \%carrier_signal_by_source,
                $preferred_net_name,
            );
        }

        for my $resolved_link (@group) {
            next unless $resolved_link->{target}{kind} eq 'top_port';

            my $bound_connection_expr = $class->source_connection_expr_for_carrier(
                $resolved_link->{source},
                $carrier_signal_name,
            );

            next
                if !$group_has_child_expr
                && @top_output_targets == 1
                && ($resolved_link->{source}{kind} || '') eq 'child_port'
                && $resolved_link->{target}{port}->name eq $carrier_signal_name;

            my $expr_text = render_expr($bound_connection_expr, $resolved_link->{target}{port}->name, 'systemverilog');
            push @auxiliary_assignments, "    assign ".$resolved_link->{target}{port}->name." = $expr_text;";
        }
    }

    for my $resolved_link (@resolved_links) {
        my $source = $resolved_link->{source};
        my $target = $resolved_link->{target};
        next if (($source->{kind} || '') =~ /^actual_/ || ($source->{kind} || '') eq 'top_expr');
        my $carrier_signal_name = $carrier_signal_by_source{$class->source_family_key($source)};

        if ($source->{kind} eq 'top_port') {
            $top_port_usage{$source->{port}->name}{source} = 1;
        }

        if ($target->{kind} eq 'top_port') {
            $top_port_usage{$target->{port}->name}{target} = 1;
            next;
        }

        if (($source->{kind} || '') eq 'child_expr') {
            $bindings_by_instance{$target->{instance_name}}{$target->{port}->name} = normalized_binding({
                port_name => $target->{port}->name,
                connection_expr => $class->source_connection_expr_for_carrier($source, $carrier_signal_name),
            });
            next;
        }

        $bindings_by_instance{$target->{instance_name}}{$target->{port}->name} = $carrier_signal_name;
    }

    for my $top_port_name (sort keys %{$top_ports_by_name || {}}) {
        my $top_port = $top_ports_by_name->{$top_port_name};
        next if $system_top_ports{$top_port_name};

        if ($top_port->direction eq 'input') {
            confess
                "Composition source '$header' in '$fsm_file' declares top input '$top_port_name', ".
                "but explicit-link top wiring is blocked because the current active $lane lane requires explicit '?toplink' usage for every non-system top input. ".
                "See docs/COMPOSITION_SCOPE.md and docs/COMPOSITION_LEGACY_MAPPING.md.\n"
                unless $top_port_usage{$top_port_name}{source};
        } else {
            confess
                "Composition source '$header' in '$fsm_file' declares top output '$top_port_name', ".
                "but explicit-link top wiring is blocked because the current active $lane lane requires explicit '?toplink' usage for every top output. ".
                "See docs/COMPOSITION_SCOPE.md and docs/COMPOSITION_LEGACY_MAPPING.md.\n"
                unless $top_port_usage{$top_port_name}{target};
        }
    }

    my @planned_instances;
    for my $instance (@$realized_instances) {
        my @port_bindings;
        for my $port (@{$instance->interface_ports}) {
            my $binding_value = $bindings_by_instance{$instance->instance_name}{$port->name};

            confess
                "Composition source '$header' in '$fsm_file' leaves child port '".$instance->instance_name.".".$port->name."' unconnected, ".
                "but realized child wiring is blocked because the current active $lane lane requires every realized child port to be wired explicitly, through declared connect-by-name, or through the shared system-input contract. ".
                "See docs/COMPOSITION_SCOPE.md and docs/COMPOSITION_LEGACY_MAPPING.md.\n"
                unless defined $binding_value;

            if (ref($binding_value) eq 'HASH') {
                push @port_bindings, normalized_binding({
                    %$binding_value,
                    port_name => $port->name,
                });
                next;
            }

            push @port_bindings, signal_ref_binding($port->name, $binding_value);
        }

        push @planned_instances, $class->clone_realized_instance_with_bindings($instance, \@port_bindings);
    }

    return FSM::Composition::Plan->new(
        lane => $lane,
        top_name => $top->name,
        ports => $ports,
        links => $links,
        resolved_links => [@system_auto_links, @resolved_links_input],
        nets => \@nets,
        instances => \@planned_instances,
        auxiliary_assignments => \@auxiliary_assignments,
        shared_datapath_candidates => [],
        raw_spec => $composition_spec,
    );
}

sub system_interface_ports ($class, $ports) {
    return [
        grep {
            my $type = $_->type || '';
            $type eq 'clock' || $type eq 'reset';
        } @{$ports || []}
    ];
}

sub index_ports_by_name ($class, $ports) {
    my %ports;

    for my $port (@{$ports || []}) {
        $ports{$port->name} = $port;
    }

    return \%ports;
}

sub assert_unique_top_ports ($class, $ports_block, $fsm_file, $header) {
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

sub resolve_endpoint ($class, $endpoint, $top_ports_by_name, $instances_by_name, $child_ports_by_instance, $fsm_file, $header, %opts) {
    if (my $actual_endpoint = $class->_resolve_actual_endpoint($endpoint, $fsm_file, $header)) {
        return $actual_endpoint;
    }

    if ($opts{allow_top_expression_source}) {
        if (my $top_expression_endpoint = $class->_resolve_top_expression_endpoint(
            $endpoint,
            $top_ports_by_name,
            $instances_by_name,
            $child_ports_by_instance,
            $fsm_file,
            $header,
        )) {
            return $top_expression_endpoint;
        }
    }

    if ($opts{allow_child_expression_source}) {
        if (my $child_expression_endpoint = $class->_resolve_child_expression_endpoint(
            $endpoint,
            $instances_by_name,
            $child_ports_by_instance,
            $fsm_file,
            $header,
        )) {
            return $child_expression_endpoint;
        }
    }

    if ($endpoint =~ /^(\w+)\.(\w+)$/) {
        my ($instance_name, $port_name) = ($1, $2);
        my $instance = $instances_by_name->{$instance_name};
        confess
            "Composition source '$header' in '$fsm_file' references child endpoint '$endpoint', ".
            "but explicit link endpoint resolution is blocked because no realized child instance named '$instance_name' exists. ".
            "See docs/COMPOSITION_SCOPE.md and docs/COMPOSITION_LEGACY_MAPPING.md.\n"
            unless $instance;

        my $port = $child_ports_by_instance->{$instance_name}{$port_name};
        confess
            "Composition source '$header' in '$fsm_file' references child endpoint '$endpoint', ".
            "but explicit link endpoint resolution is blocked because instance '$instance_name' has no port named '$port_name'. ".
            "See docs/COMPOSITION_SCOPE.md and docs/COMPOSITION_LEGACY_MAPPING.md.\n"
            unless $port;

        return {
            raw => $endpoint,
            key => "child:$instance_name.$port_name",
            kind => 'child_port',
            instance_name => $instance_name,
            instance => $instance,
            port_name => $port_name,
            port => $port,
        };
    }

    if ($endpoint =~ /^(\w+)$/) {
        my $port_name = $1;
        my $port = $top_ports_by_name->{$port_name};
        confess
            "Composition source '$header' in '$fsm_file' references top-level endpoint '$endpoint', ".
            "but explicit link endpoint resolution is blocked because '?ports' declares no top port with that name. ".
            "See docs/COMPOSITION_SCOPE.md and docs/COMPOSITION_LEGACY_MAPPING.md.\n"
            unless $port;

        return {
            raw => $endpoint,
            key => "top:$port_name",
            kind => 'top_port',
            port_name => $port_name,
            port => $port,
        };
    }

    confess
        "Composition source '$header' in '$fsm_file' uses explicit endpoint '$endpoint', ".
        "but explicit link endpoint resolution is blocked because that syntax is unsupported. ".
        "The current active composition lanes accept only top-port names, source-side top-port bit/slice expressions like 'data_bus[3]' or 'data_bus[7:4]', source-side child-port bit/slice expressions like 'producer.payload[3]' or 'producer.payload[7:4]', or 'instance.port' child endpoints. ".
        "See docs/COMPOSITION_SCOPE.md and docs/COMPOSITION_LEGACY_MAPPING.md.\n";
}

sub assert_link_roles ($class, $source, $target, $fsm_file, $header) {
    if (($target->{kind} || '') =~ /^actual_/) {
        confess
            "Composition source '$header' in '$fsm_file' uses actual endpoint '".$target->{raw}."' as an explicit link target, ".
            "but explicit actual binding is blocked because the first structural-actual slice only allows '=open', scalar '=0'/'=1', unsized binary/decimal/octal/hex direct actuals, unsized signed decimal direct actuals like '=-1', '=0d-1', or '='sd-1', unsized signed binary/octal/hex direct actuals like '='sb1010', '='so7', or '='shA', and exact-width binary/decimal/octal/hex literal actuals in unsigned or signed form like '=8'b10100101', '=8'sb10100101', '=8'd165', '=8'sd-1', '=8'o245', '=8'so245', '=8'hA5', or '=8'shA5' as link sources into realized child input ports, plus literal actuals into declared top outputs. ".
            "See docs/COMPOSITION_SCOPE.md and docs/COMPOSITION_LEGACY_MAPPING.md.\n";
    }

    if (($source->{kind} || '') =~ /^actual_/) {
        my $targets_child_input = $target->{kind} eq 'child_port' && $target->{port}->direction eq 'input';
        my $targets_top_output = $target->{kind} eq 'top_port' && $target->{port}->direction eq 'output';

        if (($source->{kind} || '') eq 'actual_open') {
            confess
                "Composition source '$header' in '$fsm_file' uses actual source '".$source->{raw}."' as an explicit link source, ".
                "but explicit actual binding is blocked because '=open' currently targets only realized child input ports, not declared top outputs. ".
                "See docs/COMPOSITION_SCOPE.md and docs/COMPOSITION_LEGACY_MAPPING.md.\n"
                unless $targets_child_input;

            return;
        }

        confess
            "Composition source '$header' in '$fsm_file' uses actual source '".$source->{raw}."' as an explicit link source, ".
            "but explicit actual binding is blocked because the first structural-actual slice only allows literal actual sources to target realized child input ports or declared top outputs. ".
            "See docs/COMPOSITION_SCOPE.md and docs/COMPOSITION_LEGACY_MAPPING.md.\n"
            unless $targets_child_input || $targets_top_output;

        return;
    }

    if (($source->{kind} || '') eq 'top_expr') {
        for my $base_port (@{$source->{base_ports} || []}) {
            confess
                "Composition source '$header' in '$fsm_file' uses top expression '".$source->{raw}."' as an explicit link source, ".
                "but explicit link is blocked because base top port '".$base_port->name."' is declared as ".$base_port->direction." instead of input. ".
                "See docs/COMPOSITION_SCOPE.md and docs/COMPOSITION_LEGACY_MAPPING.md.\n"
                unless $base_port->direction eq 'input';
        }

        confess
            "Composition source '$header' in '$fsm_file' uses top expression '".$source->{raw}."' as an explicit link source, ".
            "but explicit link is blocked because source-side top expressions currently target only realized child input ports or declared top outputs. ".
            "See docs/COMPOSITION_SCOPE.md and docs/COMPOSITION_LEGACY_MAPPING.md.\n"
            unless (
                ($target->{kind} eq 'child_port' && $target->{port}->direction eq 'input')
                || ($target->{kind} eq 'top_port' && $target->{port}->direction eq 'output')
            );

        return;
    }

    if (($source->{kind} || '') eq 'child_expr') {
        confess
            "Composition source '$header' in '$fsm_file' uses child expression '".$source->{raw}."' as an explicit link source, ".
            "but explicit link is blocked because base child port '".$source->{instance_name}.'.'.$source->{port}->name."' is ".$source->{port}->direction." instead of output. ".
            "See docs/COMPOSITION_SCOPE.md and docs/COMPOSITION_LEGACY_MAPPING.md.\n"
            unless $source->{port}->direction eq 'output';

        confess
            "Composition source '$header' in '$fsm_file' uses child expression '".$source->{raw}."' as an explicit link source, ".
            "but explicit link is blocked because source-side child expressions currently target only realized child input ports or declared top outputs. ".
            "See docs/COMPOSITION_SCOPE.md and docs/COMPOSITION_LEGACY_MAPPING.md.\n"
            unless (
                ($target->{kind} eq 'child_port' && $target->{port}->direction eq 'input')
                || ($target->{kind} eq 'top_port' && $target->{port}->direction eq 'output')
            );

        return;
    }

    if ($source->{kind} eq 'top_port') {
        confess
            "Composition source '$header' in '$fsm_file' uses top port '".$source->{raw}."' as an explicit link source, ".
            "but explicit link is blocked because that top port is declared as ".$source->{port}->direction." instead of input. ".
            "See docs/COMPOSITION_SCOPE.md and docs/COMPOSITION_LEGACY_MAPPING.md.\n"
            unless $source->{port}->direction eq 'input';
    } else {
        confess
            "Composition source '$header' in '$fsm_file' uses child endpoint '".$source->{raw}."' as an explicit link source, ".
            "but explicit link is blocked because that child port is ".$source->{port}->direction." instead of output. ".
            "See docs/COMPOSITION_SCOPE.md and docs/COMPOSITION_LEGACY_MAPPING.md.\n"
            unless $source->{port}->direction eq 'output';
    }

    if ($target->{kind} eq 'top_port') {
        confess
            "Composition source '$header' in '$fsm_file' uses top port '".$target->{raw}."' as an explicit link target, ".
            "but explicit link is blocked because that top port is declared as ".$target->{port}->direction." instead of output. ".
            "See docs/COMPOSITION_SCOPE.md and docs/COMPOSITION_LEGACY_MAPPING.md.\n"
            unless $target->{port}->direction eq 'output';
    } else {
        confess
            "Composition source '$header' in '$fsm_file' uses child endpoint '".$target->{raw}."' as an explicit link target, ".
            "but explicit link is blocked because that child port is ".$target->{port}->direction." instead of input. ".
            "See docs/COMPOSITION_SCOPE.md and docs/COMPOSITION_LEGACY_MAPPING.md.\n"
            unless $target->{port}->direction eq 'input';
    }
}

sub _resolve_actual_endpoint ($class, $endpoint, $fsm_file, $header) {
    return undef unless defined($endpoint) && length($endpoint);
    return undef unless $endpoint =~ /^=(.+)$/;

    my $payload = $1;
    if ($payload eq 'open') {
        return {
            raw => $endpoint,
            key => "actual:$endpoint",
            kind => 'actual_open',
            port => {
                direction => 'actual',
                width => 0,
            },
            connection_expr => open_expr(),
        };
    }

    if ($payload =~ /\A([01])\z/) {
        return {
            raw => $endpoint,
            key => "actual:$endpoint",
            kind => 'actual_scalar_literal',
            scalar_bit => $1,
            port => {
                direction => 'actual',
                width => 1,
            },
            connection_expr => bit_vector_literal_expr($1),
        };
    }

    if ($payload =~ /\A'b(.+)\z/i) {
        my $binary_bits = $class->_normalized_separated_digits($1, '[01]');
        if (defined $binary_bits) {
            return {
                raw => $endpoint,
                key => "actual:$endpoint",
                kind => 'actual_unsized_binary',
                binary_bits => $binary_bits,
                port => {
                    direction => 'actual',
                    width => 0,
                },
            };
        }
    }

    if ($payload =~ /\A0b(.+)\z/i) {
        my $binary_bits = $class->_normalized_separated_digits($1, '[01]');
        if (defined $binary_bits) {
            return {
                raw => $endpoint,
                key => "actual:$endpoint",
                kind => 'actual_unsized_binary',
                binary_bits => $binary_bits,
                port => {
                    direction => 'actual',
                    width => 0,
                },
            };
        }
    }

    if ($payload =~ /\A'sd(-?(?:[0-9](?:_?[0-9])*))\z/i) {
        if ($1 =~ /\A-(.+)\z/) {
            my $decimal_digits = $class->_normalized_separated_digits($1, '[0-9]');
            if (defined $decimal_digits) {
                return {
                    raw => $endpoint,
                    key => "actual:$endpoint",
                    kind => 'actual_unsized_signed_decimal',
                    decimal_digits => $decimal_digits,
                    port => {
                        direction => 'actual',
                        width => 0,
                    },
                };
            }
        }
    }

    if ($payload =~ /\A'sb(.+)\z/i) {
        my $binary_bits = $class->_normalized_separated_digits($1, '[01]');
        if (defined $binary_bits) {
            return {
                raw => $endpoint,
                key => "actual:$endpoint",
                kind => 'actual_unsized_signed_binary',
                binary_bits => $binary_bits,
                port => {
                    direction => 'actual',
                    width => 0,
                },
            };
        }
    }

    if ($payload =~ /\A'd(.+)\z/i) {
        my $decimal_digits = $class->_normalized_separated_digits($1, '[0-9]');
        if (defined $decimal_digits) {
            return {
                raw => $endpoint,
                key => "actual:$endpoint",
                kind => 'actual_unsized_decimal',
                decimal_digits => $decimal_digits,
                port => {
                    direction => 'actual',
                    width => 0,
                },
            };
        }
    }

    if ($payload =~ /\A0d(.+)\z/i) {
        if ($1 =~ /\A-(.+)\z/) {
            my $decimal_digits = $class->_normalized_separated_digits($1, '[0-9]');
            if (defined $decimal_digits) {
                return {
                    raw => $endpoint,
                    key => "actual:$endpoint",
                    kind => 'actual_unsized_signed_decimal',
                    decimal_digits => $decimal_digits,
                    port => {
                        direction => 'actual',
                        width => 0,
                    },
                };
            }
        }

        my $decimal_digits = $class->_normalized_separated_digits($1, '[0-9]');
        if (defined $decimal_digits) {
            return {
                raw => $endpoint,
                key => "actual:$endpoint",
                kind => 'actual_unsized_decimal',
                decimal_digits => $decimal_digits,
                port => {
                    direction => 'actual',
                    width => 0,
                },
            };
        }
    }

    if ($payload =~ /\A-(.+)\z/) {
        my $decimal_digits = $class->_normalized_separated_digits($1, '[0-9]');
        if (defined $decimal_digits) {
            return {
                raw => $endpoint,
                key => "actual:$endpoint",
                kind => 'actual_unsized_signed_decimal',
                decimal_digits => $decimal_digits,
                port => {
                    direction => 'actual',
                    width => 0,
                },
            };
        }
    }

    if ($payload =~ /\A'so(.+)\z/i) {
        my $octal_digits = $class->_normalized_separated_digits($1, '[0-7]');
        if (defined $octal_digits) {
            return {
                raw => $endpoint,
                key => "actual:$endpoint",
                kind => 'actual_unsized_signed_octal',
                octal_digits => $octal_digits,
                port => {
                    direction => 'actual',
                    width => 0,
                },
            };
        }
    }

    if ($payload =~ /\A'o(.+)\z/i) {
        my $octal_digits = $class->_normalized_separated_digits($1, '[0-7]');
        if (defined $octal_digits) {
            return {
                raw => $endpoint,
                key => "actual:$endpoint",
                kind => 'actual_unsized_octal',
                octal_digits => $octal_digits,
                port => {
                    direction => 'actual',
                    width => 0,
                },
            };
        }
    }

    if ($payload =~ /\A0o(.+)\z/i) {
        my $octal_digits = $class->_normalized_separated_digits($1, '[0-7]');
        if (defined $octal_digits) {
            return {
                raw => $endpoint,
                key => "actual:$endpoint",
                kind => 'actual_unsized_octal',
                octal_digits => $octal_digits,
                port => {
                    direction => 'actual',
                    width => 0,
                },
            };
        }
    }

    if ($payload =~ /\A'sh(.+)\z/i) {
        my $hex_digits = $class->_normalized_separated_digits($1, '[0-9A-Fa-f]');
        if (defined $hex_digits) {
            return {
                raw => $endpoint,
                key => "actual:$endpoint",
                kind => 'actual_unsized_signed_hex',
                hex_digits => $hex_digits,
                port => {
                    direction => 'actual',
                    width => 0,
                },
            };
        }
    }

    if ($payload =~ /\A'h(.+)\z/i) {
        my $hex_digits = $class->_normalized_separated_digits($1, '[0-9A-Fa-f]');
        if (defined $hex_digits) {
            return {
                raw => $endpoint,
                key => "actual:$endpoint",
                kind => 'actual_unsized_hex',
                hex_digits => $hex_digits,
                port => {
                    direction => 'actual',
                    width => 0,
                },
            };
        }
    }

    if ($payload =~ /\A0x(.+)\z/i) {
        my $hex_digits = $class->_normalized_separated_digits($1, '[0-9A-Fa-f]');
        if (defined $hex_digits) {
            return {
                raw => $endpoint,
                key => "actual:$endpoint",
                kind => 'actual_unsized_hex',
                hex_digits => $hex_digits,
                port => {
                    direction => 'actual',
                    width => 0,
                },
            };
        }
    }

    my $bare_decimal_digits = $class->_normalized_separated_digits($payload, '[0-9]');
    if (defined $bare_decimal_digits) {
        return {
            raw => $endpoint,
            key => "actual:$endpoint",
            kind => 'actual_unsized_decimal',
            decimal_digits => $bare_decimal_digits,
            port => {
                direction => 'actual',
                width => 0,
            },
        };
    }

    my $bare_hex_digits = $class->_normalized_separated_digits($payload, '[0-9A-Fa-f]');
    if (defined($bare_hex_digits) && $bare_hex_digits =~ /[A-Fa-f]/) {
        return {
            raw => $endpoint,
            key => "actual:$endpoint",
            kind => 'actual_unsized_hex',
            hex_digits => $bare_hex_digits,
            port => {
                direction => 'actual',
                width => 0,
            },
        };
    }

    my ($bits, $width) = $class->_actual_literal_bits_and_width($payload, $fsm_file, $header);
    return {
        raw => $endpoint,
        key => "actual:$endpoint",
        kind => 'actual_literal',
        port => {
            direction => 'actual',
            width => $width,
        },
        connection_expr => bit_vector_literal_expr($bits),
    };
}

sub _resolve_child_expression_endpoint ($class, $endpoint, $instances_by_name, $child_ports_by_instance, $fsm_file, $header) {
    return undef unless defined($endpoint) && length($endpoint);

    if ($endpoint =~ /\A(\w+)\.(\w+)\[(\d+)\]\z/) {
        my ($instance_name, $port_name, $index) = ($1, $2, 0 + $3);
        my $instance = $instances_by_name->{$instance_name};
        confess
            "Composition source '$header' in '$fsm_file' uses child expression '$endpoint', ".
            "but explicit link endpoint resolution is blocked because no realized child instance named '$instance_name' exists. ".
            "See docs/COMPOSITION_SCOPE.md and docs/COMPOSITION_LEGACY_MAPPING.md.\n"
            unless $instance;

        my $port = $child_ports_by_instance->{$instance_name}{$port_name};
        confess
            "Composition source '$header' in '$fsm_file' uses child expression '$endpoint', ".
            "but explicit link endpoint resolution is blocked because instance '$instance_name' has no port named '$port_name'. ".
            "See docs/COMPOSITION_SCOPE.md and docs/COMPOSITION_LEGACY_MAPPING.md.\n"
            unless $port;

        my $base_width = $port->width;
        confess
            "Composition source '$header' in '$fsm_file' uses child expression '$endpoint', ".
            "but explicit link endpoint resolution is blocked because bit index $index falls outside declared width $base_width of child endpoint '$instance_name.$port_name'. ".
            "See docs/COMPOSITION_SCOPE.md and docs/COMPOSITION_LEGACY_MAPPING.md.\n"
            unless defined($base_width) && $base_width > 0 && $index < $base_width;

        return {
            raw => $endpoint,
            key => "child_expr:$endpoint",
            base_key => "child:$instance_name.$port_name",
            base_raw => "$instance_name.$port_name",
            kind => 'child_expr',
            expr_kind => 'bit_select',
            expr_width => 1,
            index => $index,
            instance_name => $instance_name,
            instance => $instance,
            port_name => $port_name,
            port => $port,
        };
    }

    if ($endpoint =~ /\A(\w+)\.(\w+)\[(\d+):(\d+)\]\z/) {
        my ($instance_name, $port_name, $msb, $lsb) = ($1, $2, 0 + $3, 0 + $4);
        my $instance = $instances_by_name->{$instance_name};
        confess
            "Composition source '$header' in '$fsm_file' uses child expression '$endpoint', ".
            "but explicit link endpoint resolution is blocked because no realized child instance named '$instance_name' exists. ".
            "See docs/COMPOSITION_SCOPE.md and docs/COMPOSITION_LEGACY_MAPPING.md.\n"
            unless $instance;

        my $port = $child_ports_by_instance->{$instance_name}{$port_name};
        confess
            "Composition source '$header' in '$fsm_file' uses child expression '$endpoint', ".
            "but explicit link endpoint resolution is blocked because instance '$instance_name' has no port named '$port_name'. ".
            "See docs/COMPOSITION_SCOPE.md and docs/COMPOSITION_LEGACY_MAPPING.md.\n"
            unless $port;

        my $base_width = $port->width;
        confess
            "Composition source '$header' in '$fsm_file' uses child expression '$endpoint', ".
            "but explicit link endpoint resolution is blocked because slice bounds [$msb:$lsb] fall outside declared width $base_width of child endpoint '$instance_name.$port_name'. ".
            "See docs/COMPOSITION_SCOPE.md and docs/COMPOSITION_LEGACY_MAPPING.md.\n"
            unless defined($base_width) && $base_width > 0 && $msb < $base_width && $lsb < $base_width;

        return {
            raw => $endpoint,
            key => "child_expr:$endpoint",
            base_key => "child:$instance_name.$port_name",
            base_raw => "$instance_name.$port_name",
            kind => 'child_expr',
            expr_kind => 'slice',
            expr_width => abs($msb - $lsb) + 1,
            msb => $msb,
            lsb => $lsb,
            instance_name => $instance_name,
            instance => $instance,
            port_name => $port_name,
            port => $port,
        };
    }

    return undef;
}

sub _actual_literal_bits_and_width ($class, $payload, $fsm_file, $header) {
    if ($payload =~ /\A(\d+)'sb(.+)\z/i) {
        my ($declared_width, $raw_bits) = ($1, $2);
        my $bits = $class->_normalized_separated_digits($raw_bits, '[01]');
        return undef unless defined $bits;
        confess
            "Composition source '$header' in '$fsm_file' uses actual literal '=$payload', ".
            "but explicit actual binding is blocked because the declared signed binary width does not match the literal payload length. ".
            "See docs/COMPOSITION_SCOPE.md and docs/COMPOSITION_LEGACY_MAPPING.md.\n"
            unless length($bits) == $declared_width;
        return ($bits, 0 + $declared_width);
    }

    if ($payload =~ /\A(\d+)'sd(-?(?:[0-9](?:_?[0-9])*))\z/i) {
        my ($declared_width, $signed_decimal_text) = ($1, $2);
        my ($bits, $width) = $class->_signed_decimal_literal_bits_and_width(
            $declared_width,
            $signed_decimal_text,
            on_overflow => sub {
                return
                    "Composition source '$header' in '$fsm_file' uses actual literal '=$payload', ".
                    "but explicit actual binding is blocked because the declared signed decimal width cannot represent the literal payload value. ".
                    "See docs/COMPOSITION_SCOPE.md and docs/COMPOSITION_LEGACY_MAPPING.md.\n";
            },
        );
        return ($bits, $width) if defined $bits;
    }

    if ($payload =~ /\A(\d+)'b(.+)\z/i) {
        my ($declared_width, $raw_bits) = ($1, $2);
        my $bits = $class->_normalized_separated_digits($raw_bits, '[01]');
        return undef unless defined $bits;
        confess
            "Composition source '$header' in '$fsm_file' uses actual literal '=$payload', ".
            "but explicit actual binding is blocked because the declared binary width does not match the literal payload length. ".
            "See docs/COMPOSITION_SCOPE.md and docs/COMPOSITION_LEGACY_MAPPING.md.\n"
            unless length($bits) == $declared_width;
        return ($bits, 0 + $declared_width);
    }

    if ($payload =~ /\A(\d+)'d(.+)\z/i) {
        my ($declared_width, $raw_decimal_digits) = ($1, $2);
        my $decimal_digits = $class->_normalized_separated_digits($raw_decimal_digits, '[0-9]');
        return undef unless defined $decimal_digits;
        my ($bits, $width) = $class->_decimal_literal_bits_and_width(
            $declared_width,
            $decimal_digits,
            on_overflow => sub {
                return
                    "Composition source '$header' in '$fsm_file' uses actual literal '=$payload', ".
                    "but explicit actual binding is blocked because the declared decimal width cannot represent the literal payload value. ".
                    "See docs/COMPOSITION_SCOPE.md and docs/COMPOSITION_LEGACY_MAPPING.md.\n";
            },
        );
        return ($bits, $width) if defined $bits;
    }

    if ($payload =~ /\A(\d+)'o(.+)\z/i) {
        my ($declared_width, $raw_octal_digits) = ($1, $2);
        my $octal_digits = $class->_normalized_separated_digits($raw_octal_digits, '[0-7]');
        return undef unless defined $octal_digits;
        my ($bits, $width) = $class->_octal_literal_bits_and_width(
            $declared_width,
            $octal_digits,
            on_overflow => sub {
                return
                    "Composition source '$header' in '$fsm_file' uses actual literal '=$payload', ".
                    "but explicit actual binding is blocked because the declared octal width cannot represent the literal payload value. ".
                    "See docs/COMPOSITION_SCOPE.md and docs/COMPOSITION_LEGACY_MAPPING.md.\n";
            },
        );
        return ($bits, $width) if defined $bits;
    }

    if ($payload =~ /\A(\d+)'so(.+)\z/i) {
        my ($declared_width, $raw_octal_digits) = ($1, $2);
        my $octal_digits = $class->_normalized_separated_digits($raw_octal_digits, '[0-7]');
        return undef unless defined $octal_digits;
        my ($bits, $width) = $class->_octal_literal_bits_and_width(
            $declared_width,
            $octal_digits,
            on_overflow => sub {
                return
                    "Composition source '$header' in '$fsm_file' uses actual literal '=$payload', ".
                    "but explicit actual binding is blocked because the declared signed octal width cannot represent the literal payload value. ".
                    "See docs/COMPOSITION_SCOPE.md and docs/COMPOSITION_LEGACY_MAPPING.md.\n";
            },
        );
        return ($bits, $width) if defined $bits;
    }

    if ($payload =~ /\A(\d+)'h(.+)\z/i) {
        my ($declared_width, $raw_hex_digits) = ($1, $2);
        my $hex_digits = $class->_normalized_separated_digits($raw_hex_digits, '[0-9A-Fa-f]');
        return undef unless defined $hex_digits;
        my ($bits, $width) = $class->_hex_literal_bits_and_width(
            $declared_width,
            $hex_digits,
            on_overflow => sub {
                return
                    "Composition source '$header' in '$fsm_file' uses actual literal '=$payload', ".
                    "but explicit actual binding is blocked because the declared hex width cannot represent the literal payload value. ".
                    "See docs/COMPOSITION_SCOPE.md and docs/COMPOSITION_LEGACY_MAPPING.md.\n";
            },
        );
        return ($bits, $width) if defined $bits;
    }

    if ($payload =~ /\A(\d+)'sh(.+)\z/i) {
        my ($declared_width, $raw_hex_digits) = ($1, $2);
        my $hex_digits = $class->_normalized_separated_digits($raw_hex_digits, '[0-9A-Fa-f]');
        return undef unless defined $hex_digits;
        my ($bits, $width) = $class->_hex_literal_bits_and_width(
            $declared_width,
            $hex_digits,
            on_overflow => sub {
                return
                    "Composition source '$header' in '$fsm_file' uses actual literal '=$payload', ".
                    "but explicit actual binding is blocked because the declared signed hex width cannot represent the literal payload value. ".
                    "See docs/COMPOSITION_SCOPE.md and docs/COMPOSITION_LEGACY_MAPPING.md.\n";
            },
        );
        return ($bits, $width) if defined $bits;
    }

    confess
        "Composition source '$header' in '$fsm_file' uses actual endpoint '=$payload', ".
        "but explicit actual binding is blocked because the first structural-actual slice currently accepts only '=open', scalar '=0'/'=1', unsized binary/decimal/octal/hex direct actual forms like '=0b10', '='b10', '=0d10', '='d10', '=0o7', '='o7', '=0xA', '='hA', '=170', or '=A5', unsized signed decimal direct actual forms like '=-1', '=0d-1', or '='sd-1', unsized signed binary/octal/hex direct actual forms like '='sb1010', '='so7', or '='shA', or exact-width binary/decimal/octal/hex literal forms in unsigned or signed form like '=8'b10100101', '=8'sb10100101', '=8'd165', '=8'sd-1', '=8'o245', '=8'so245', '=8'hA5', or '=8'shA5'. ".
        "See docs/COMPOSITION_SCOPE.md and docs/COMPOSITION_LEGACY_MAPPING.md.\n";
}

sub top_expression_spec ($class, $endpoint) {
    return $class->_parse_top_expression_spec(
        $endpoint,
        allow_plain_top_ref => 0,
        allow_literal_actual => 0,
    );
}

sub top_expression_base_port_name ($class, $endpoint) {
    my $spec = $class->top_expression_spec($endpoint);
    return undef unless $spec;
    return $spec->{port_name};
}

sub top_expression_inference_specs ($class, $endpoint) {
    my $spec = $class->top_expression_spec($endpoint);
    return [] unless $spec;
    return $class->_collect_top_expression_inference_specs($spec);
}

sub top_expression_child_base_endpoints ($class, $endpoint) {
    my $spec = $class->top_expression_spec($endpoint);
    return [] unless $spec;

    my %seen_endpoint;
    my @base_endpoints;
    for my $child_spec (@{$class->_collect_top_expression_child_specs($spec)}) {
        my $base_endpoint = $child_spec->{instance_name}.'.'.$child_spec->{port_name};
        next if $seen_endpoint{$base_endpoint}++;
        push @base_endpoints, $base_endpoint;
    }

    return \@base_endpoints;
}

sub child_expression_spec ($class, $endpoint) {
    return undef unless defined($endpoint) && !ref($endpoint);

    if ($endpoint =~ /\A(\w+)\.(\w+)\[(\d+)\]\z/) {
        return {
            raw => $endpoint,
            instance_name => $1,
            port_name => $2,
            expr_kind => 'bit_select',
            index => 0 + $3,
        };
    }

    if ($endpoint =~ /\A(\w+)\.(\w+)\[(\d+):(\d+)\]\z/) {
        return {
            raw => $endpoint,
            instance_name => $1,
            port_name => $2,
            expr_kind => 'slice',
            msb => 0 + $3,
            lsb => 0 + $4,
        };
    }

    return undef;
}

sub child_expression_base_endpoint ($class, $endpoint) {
    my $spec = $class->child_expression_spec($endpoint);
    return undef unless $spec;
    return $spec->{instance_name}.'.'.$spec->{port_name};
}

sub _resolve_top_expression_endpoint ($class, $endpoint, $top_ports_by_name, $instances_by_name, $child_ports_by_instance, $fsm_file, $header) {
    my $spec = $class->top_expression_spec($endpoint);
    if (!$spec && defined($endpoint) && ($endpoint =~ /\A\{.*\}\z/s || index($endpoint, ',') >= 0)) {
        confess
            "Composition source '$header' in '$fsm_file' uses top expression '$endpoint', ".
            "but explicit link endpoint resolution is blocked because concat operands currently accept only top-port names, top-port bit/slice forms, child endpoints like 'producer.payload', child-output bit/slice forms like 'producer.payload[3]' or 'producer.payload[7:4]', repeat groups like '{4{status_bus[0]}}', scalar '=0'/'=1' actuals, intrinsic-width unsized binary/decimal/octal/hex actuals like '=0b1010', '='b1010', '=170', '=0d170', '='d170', '=0o7', '='o7', '=0xA5', '='hA5', or '=A5', intrinsic-width unsized signed binary/octal/hex actuals like '='sb1010', '='so7', or '='shA5', and exact-width literal actuals like '=4'b1010', '=4'sb1010', '=4'd10', '=8'sd-1', '=3'o7', '=3'so7', '=4'hA', or '=4'shA'. ".
            "See docs/COMPOSITION_SCOPE.md and docs/COMPOSITION_LEGACY_MAPPING.md.\n";
    }
    return undef unless $spec;
    my $resolved_spec = $class->_resolve_top_expression_spec(
        $spec,
        $top_ports_by_name,
        $instances_by_name,
        $child_ports_by_instance,
        $endpoint,
        $fsm_file,
        $header,
    );
    my @base_ports = @{$resolved_spec->{base_ports} || []};
    my @base_port_names = map { $_->name } @base_ports;
    my $single_base_port = @base_ports == 1 ? $base_ports[0] : undef;

    return {
        raw => $endpoint,
        key => "top_expr:$endpoint",
        kind => 'top_expr',
        base_port_name => $single_base_port ? $single_base_port->name : undef,
        base_port => $single_base_port,
        base_port_names => \@base_port_names,
        base_ports => \@base_ports,
        child_base_sources => $resolved_spec->{child_base_sources} || [],
        port_name => $single_base_port ? $single_base_port->name : undef,
        port => {
            direction => $single_base_port ? $single_base_port->direction : 'input',
            width => $resolved_spec->{width},
            type => $single_base_port ? $single_base_port->type : undef,
        },
        connection_expr => $resolved_spec->{connection_expr},
    };
}

sub _collect_top_expression_inference_specs ($class, $spec) {
    return [] unless ref($spec) eq 'HASH';

    my $expr_kind = $spec->{expr_kind} || '';
    if ($expr_kind eq 'bit_select' || $expr_kind eq 'slice') {
        return [{
            %$spec,
        }];
    }

    if ($expr_kind eq 'concat') {
        my @requirements;
        for my $operand_spec (@{$spec->{operands} || []}) {
            push @requirements, @{$class->_collect_top_expression_inference_specs($operand_spec)};
        }
        return \@requirements;
    }

    if ($expr_kind eq 'repeat') {
        return $class->_collect_top_expression_inference_specs($spec->{operand});
    }

    return [];
}

sub _collect_top_expression_child_specs ($class, $spec) {
    return [] unless ref($spec) eq 'HASH';

    my $expr_kind = $spec->{expr_kind} || '';
    if ($expr_kind eq 'child_signal_ref' || $expr_kind eq 'child_bit_select' || $expr_kind eq 'child_slice') {
        return [{
            %$spec,
        }];
    }

    if ($expr_kind eq 'concat') {
        my @child_specs;
        for my $operand_spec (@{$spec->{operands} || []}) {
            push @child_specs, @{$class->_collect_top_expression_child_specs($operand_spec)};
        }
        return \@child_specs;
    }

    if ($expr_kind eq 'repeat') {
        return $class->_collect_top_expression_child_specs($spec->{operand});
    }

    return [];
}

sub _parse_top_expression_spec ($class, $endpoint, %opts) {
    return undef unless defined($endpoint) && length($endpoint);

    my $repeat_spec = $class->_parse_repeat_group_spec($endpoint, %opts);
    return $repeat_spec if $repeat_spec;

    my $concat_payload = undef;
    if ($endpoint =~ /\A\{(.*)\}\z/s) {
        $concat_payload = $1;
    }
    elsif (index($endpoint, ',') >= 0) {
        $concat_payload = $endpoint;
    }

    if (defined $concat_payload) {
        my $operands = $class->_split_concat_operands($concat_payload) or return undef;
        my @operand_specs = map {
            my $operand_spec = $class->_parse_top_expression_spec(
                $_,
                allow_plain_top_ref => 1,
                allow_literal_actual => 1,
                allow_child_ref => 1,
            );
            return () unless $operand_spec;
            $operand_spec;
        } @$operands;
        return undef unless @operand_specs == @$operands;
        return {
            raw => $endpoint,
            expr_kind => 'concat',
            operands => \@operand_specs,
        };
    }

    if ($opts{allow_plain_top_ref} && $endpoint =~ /\A(\w+)\z/) {
        return {
            raw => $endpoint,
            port_name => $1,
            expr_kind => 'signal_ref',
        };
    }

    if ($opts{allow_child_ref} && $endpoint =~ /\A(\w+)\.(\w+)\z/) {
        return {
            raw => $endpoint,
            instance_name => $1,
            port_name => $2,
            expr_kind => 'child_signal_ref',
        };
    }

    if ($endpoint =~ /\A(\w+)\[(\d+)\]\z/) {
        return {
            raw => $endpoint,
            port_name => $1,
            expr_kind => 'bit_select',
            index => 0 + $2,
        };
    }

    if ($opts{allow_child_ref} && $endpoint =~ /\A(\w+)\.(\w+)\[(\d+)\]\z/) {
        return {
            raw => $endpoint,
            instance_name => $1,
            port_name => $2,
            expr_kind => 'child_bit_select',
            index => 0 + $3,
        };
    }

    if ($endpoint =~ /\A(\w+)\[(\d+):(\d+)\]\z/) {
        return {
            raw => $endpoint,
            port_name => $1,
            expr_kind => 'slice',
            msb => 0 + $2,
            lsb => 0 + $3,
        };
    }

    if ($opts{allow_child_ref} && $endpoint =~ /\A(\w+)\.(\w+)\[(\d+):(\d+)\]\z/) {
        return {
            raw => $endpoint,
            instance_name => $1,
            port_name => $2,
            expr_kind => 'child_slice',
            msb => 0 + $3,
            lsb => 0 + $4,
        };
    }

    if ($opts{allow_literal_actual} && $endpoint =~ /\A=(.+)\z/) {
        return undef if lc($1) eq 'open';
        my ($bits, $width) = $class->_expression_literal_bits_and_width($1) or return undef;
        return {
            raw => $endpoint,
            expr_kind => 'literal',
            bits => $bits,
            width => $width,
        };
    }

    return undef;
}

sub _parse_repeat_group_spec ($class, $endpoint, %opts) {
    return undef unless defined($endpoint) && $endpoint =~ /\A\{([1-9]\d*)\{(.*)\}\}\z/s;

    my ($repeat_count, $operand_text) = (0 + $1, $2);
    my $operand_spec = $class->_parse_top_expression_spec(
        $operand_text,
        allow_plain_top_ref => 1,
        allow_literal_actual => 1,
        allow_child_ref => 1,
    ) or return undef;

    return {
        raw => $endpoint,
        expr_kind => 'repeat',
        repeat_count => $repeat_count,
        operand => $operand_spec,
    };
}

sub _split_concat_operands ($class, $inner_text) {
    return undef unless defined $inner_text;

    my @operands;
    my $current = '';
    my $depth = 0;
    my @chars = split //, $inner_text;

    for my $char (@chars) {
        if ($char eq '{') {
            $depth++;
            $current .= $char;
            next;
        }

        if ($char eq '}') {
            return undef if $depth < 1;
            $depth--;
            $current .= $char;
            next;
        }

        if ($char eq ',' && $depth == 0) {
            my $operand = $current;
            $operand =~ s/\A\s+|\s+\z//g;
            return undef unless length $operand;
            push @operands, $operand;
            $current = '';
            next;
        }

        $current .= $char;
    }

    return undef if $depth != 0;

    $current =~ s/\A\s+|\s+\z//g;
    return undef unless length $current;
    push @operands, $current;

    return \@operands;
}

sub _expression_literal_bits_and_width ($class, $payload) {
    return ($1, 1)
        if defined($payload) && $payload =~ /\A([01])\z/;

    if (defined($payload) && $payload =~ /\A0b(.+)\z/i) {
        my $binary_bits = $class->_normalized_separated_digits($1, '[01]');
        return undef unless defined $binary_bits;
        return ($binary_bits, length($binary_bits));
    }

    if (defined($payload) && $payload =~ /\A'b(.+)\z/i) {
        my $binary_bits = $class->_normalized_separated_digits($1, '[01]');
        return undef unless defined $binary_bits;
        return ($binary_bits, length($binary_bits));
    }

    if (defined($payload) && $payload =~ /\A'sb(.+)\z/i) {
        my $binary_bits = $class->_normalized_separated_digits($1, '[01]');
        return undef unless defined $binary_bits;
        return ($binary_bits, length($binary_bits));
    }

    if (defined($payload) && $payload =~ /\A0o(.+)\z/i) {
        my $octal_digits = $class->_normalized_separated_digits($1, '[0-7]');
        return undef unless defined $octal_digits;
        return $class->_octal_literal_bits_and_width(length($octal_digits) * 3, $octal_digits);
    }

    if (defined($payload) && $payload =~ /\A'so(.+)\z/i) {
        my $octal_digits = $class->_normalized_separated_digits($1, '[0-7]');
        return undef unless defined $octal_digits;
        return $class->_octal_literal_bits_and_width(length($octal_digits) * 3, $octal_digits);
    }

    if (defined($payload) && $payload =~ /\A'o(.+)\z/i) {
        my $octal_digits = $class->_normalized_separated_digits($1, '[0-7]');
        return undef unless defined $octal_digits;
        return $class->_octal_literal_bits_and_width(length($octal_digits) * 3, $octal_digits);
    }

    if (defined($payload) && $payload =~ /\A0x(.+)\z/i) {
        my $hex_digits = $class->_normalized_separated_digits($1, '[0-9A-Fa-f]');
        return undef unless defined $hex_digits;
        return $class->_hex_literal_bits_and_width(length($hex_digits) * 4, $hex_digits);
    }

    if (defined($payload) && $payload =~ /\A'h(.+)\z/i) {
        my $hex_digits = $class->_normalized_separated_digits($1, '[0-9A-Fa-f]');
        return undef unless defined $hex_digits;
        return $class->_hex_literal_bits_and_width(length($hex_digits) * 4, $hex_digits);
    }

    if (defined($payload) && $payload =~ /\A'sh(.+)\z/i) {
        my $hex_digits = $class->_normalized_separated_digits($1, '[0-9A-Fa-f]');
        return undef unless defined $hex_digits;
        return $class->_hex_literal_bits_and_width(length($hex_digits) * 4, $hex_digits);
    }

    if (defined($payload) && $payload =~ /\A0d(.+)\z/i) {
        my $decimal_digits = $class->_normalized_separated_digits($1, '[0-9]');
        return undef unless defined $decimal_digits;
        return $class->_intrinsic_decimal_literal_bits_and_width($decimal_digits);
    }

    if (defined($payload) && $payload =~ /\A'd(.+)\z/i) {
        my $decimal_digits = $class->_normalized_separated_digits($1, '[0-9]');
        return undef unless defined $decimal_digits;
        return $class->_intrinsic_decimal_literal_bits_and_width($decimal_digits);
    }

    my $bare_hex_digits = $class->_normalized_separated_digits($payload, '[0-9A-Fa-f]');
    if (defined($bare_hex_digits) && $bare_hex_digits =~ /[A-Fa-f]/ && $payload !~ /\A0d/i) {
        return $class->_hex_literal_bits_and_width(length($bare_hex_digits) * 4, $bare_hex_digits);
    }

    my $bare_decimal_digits = $class->_normalized_separated_digits($payload, '[0-9]');
    if (defined $bare_decimal_digits) {
        return $class->_intrinsic_decimal_literal_bits_and_width($bare_decimal_digits);
    }

    if (defined($payload) && $payload =~ /\A(\d+)'b(.+)\z/i) {
        my ($declared_width, $raw_bits) = ($1, $2);
        my $bits = $class->_normalized_separated_digits($raw_bits, '[01]');
        return undef unless defined $bits;
        return undef unless length($bits) == $declared_width;
        return ($bits, 0 + $declared_width);
    }

    if (defined($payload) && $payload =~ /\A(\d+)'sb(.+)\z/i) {
        my ($declared_width, $raw_bits) = ($1, $2);
        my $bits = $class->_normalized_separated_digits($raw_bits, '[01]');
        return undef unless defined $bits;
        return undef unless length($bits) == $declared_width;
        return ($bits, 0 + $declared_width);
    }

    if (defined($payload) && $payload =~ /\A(\d+)'sd(-?(?:[0-9](?:_?[0-9])*))\z/i) {
        return $class->_signed_decimal_literal_bits_and_width($1, $2);
    }

    if (defined($payload) && $payload =~ /\A(\d+)'d(.+)\z/i) {
        my $decimal_digits = $class->_normalized_separated_digits($2, '[0-9]');
        return undef unless defined $decimal_digits;
        return $class->_decimal_literal_bits_and_width($1, $decimal_digits);
    }

    if (defined($payload) && $payload =~ /\A(\d+)'o(.+)\z/i) {
        my $octal_digits = $class->_normalized_separated_digits($2, '[0-7]');
        return undef unless defined $octal_digits;
        return $class->_octal_literal_bits_and_width($1, $octal_digits);
    }

    if (defined($payload) && $payload =~ /\A(\d+)'so(.+)\z/i) {
        my $octal_digits = $class->_normalized_separated_digits($2, '[0-7]');
        return undef unless defined $octal_digits;
        return $class->_octal_literal_bits_and_width($1, $octal_digits);
    }

    if (defined($payload) && $payload =~ /\A(\d+)'h(.+)\z/i) {
        my $hex_digits = $class->_normalized_separated_digits($2, '[0-9A-Fa-f]');
        return undef unless defined $hex_digits;
        return $class->_hex_literal_bits_and_width($1, $hex_digits);
    }

    if (defined($payload) && $payload =~ /\A(\d+)'sh(.+)\z/i) {
        my $hex_digits = $class->_normalized_separated_digits($2, '[0-9A-Fa-f]');
        return undef unless defined $hex_digits;
        return $class->_hex_literal_bits_and_width($1, $hex_digits);
    }

    return;
}

sub _normalized_separated_digits ($class, $text, $digit_class) {
    return undef unless defined($text) && !ref($text);
    return undef unless defined($digit_class) && !ref($digit_class) && length($digit_class);

    my $pattern = qr/\A(?:$digit_class)(?:_?(?:$digit_class))*\z/;
    return undef unless $text =~ $pattern;

    (my $normalized = $text) =~ s/_//g;
    return $normalized;
}

sub _decimal_literal_bits_and_width ($class, $declared_width, $decimal_digits, %opts) {
    return unless defined($declared_width) && $declared_width =~ /\A\d+\z/ && $declared_width > 0;
    $decimal_digits = $class->_normalized_separated_digits($decimal_digits, '[0-9]');
    return unless defined $decimal_digits;

    my $value = Math::BigInt->new($decimal_digits);
    return unless defined $value;

    my $bits = $value->as_bin();
    $bits =~ s/\A0b//;
    $bits = '0' unless length $bits;

    if (length($bits) < $declared_width) {
        $bits = ('0' x ($declared_width - length($bits))) . $bits;
        return ($bits, 0 + $declared_width);
    }

    if (length($bits) > $declared_width) {
        confess $opts{on_overflow}->()
            if $opts{on_overflow};
        return;
    }

    return ($bits, 0 + $declared_width);
}

sub _intrinsic_decimal_literal_bits_and_width ($class, $decimal_digits) {
    $decimal_digits = $class->_normalized_separated_digits($decimal_digits, '[0-9]');
    return unless defined $decimal_digits;

    my $value = Math::BigInt->new($decimal_digits);
    return unless defined $value;

    my $bits = $value->as_bin();
    $bits =~ s/\A0b//;
    $bits = '0' unless length $bits;

    return ($bits, length($bits));
}

sub _signed_decimal_literal_bits_and_width ($class, $declared_width, $signed_decimal_text, %opts) {
    return unless defined($declared_width) && $declared_width =~ /\A\d+\z/ && $declared_width > 0;
    return unless defined($signed_decimal_text) && !ref($signed_decimal_text);

    my $negative = ($signed_decimal_text =~ s/\A-//) ? 1 : 0;
    my $decimal_digits = $class->_normalized_separated_digits($signed_decimal_text, '[0-9]');
    return unless defined $decimal_digits;

    my $value = Math::BigInt->new($decimal_digits);
    return unless defined $value;
    $value->bneg() if $negative;

    return $class->_signed_integer_bits_and_width($declared_width, $value, %opts);
}

sub _signed_integer_bits_and_width ($class, $declared_width, $value, %opts) {
    return unless defined($declared_width) && $declared_width =~ /\A\d+\z/ && $declared_width > 0;
    return unless defined($value) && ref($value) && $value->isa('Math::BigInt');

    my $min_value = Math::BigInt->bone();
    $min_value->blsft($declared_width - 1);
    $min_value->bneg();

    my $max_value = Math::BigInt->bone();
    $max_value->blsft($declared_width - 1);
    $max_value->bdec();

    if ($value->copy()->bcmp($min_value) < 0 || $value->copy()->bcmp($max_value) > 0) {
        confess $opts{on_overflow}->()
            if $opts{on_overflow};
        return;
    }

    my $normalized_value = $value->copy();
    if ($normalized_value->is_neg()) {
        my $modulus = Math::BigInt->bone();
        $modulus->blsft($declared_width);
        $normalized_value->badd($modulus);
    }

    my $bits = $normalized_value->as_bin();
    $bits =~ s/\A0b//;
    $bits = '0' unless length $bits;

    if (length($bits) < $declared_width) {
        $bits = ('0' x ($declared_width - length($bits))) . $bits;
    }

    return ($bits, 0 + $declared_width);
}

sub _signed_bits_literal_bits_and_width ($class, $declared_width, $raw_bits, %opts) {
    return unless defined($declared_width) && $declared_width =~ /\A\d+\z/ && $declared_width > 0;
    $raw_bits = $class->_normalized_separated_digits($raw_bits, '[01]');
    return unless defined $raw_bits;

    my $intrinsic_width = length($raw_bits);
    return unless $intrinsic_width > 0;

    my $value = Math::BigInt->from_bin('0b'.$raw_bits);
    return unless defined $value;

    if (substr($raw_bits, 0, 1) eq '1') {
        my $modulus = Math::BigInt->bone();
        $modulus->blsft($intrinsic_width);
        $value->bsub($modulus);
    }

    return $class->_signed_integer_bits_and_width($declared_width, $value, %opts);
}

sub _binary_literal_bits_and_width ($class, $declared_width, $binary_bits, %opts) {
    return unless defined($declared_width) && $declared_width =~ /\A\d+\z/ && $declared_width > 0;
    $binary_bits = $class->_normalized_separated_digits($binary_bits, '[01]');
    return unless defined $binary_bits;

    my $bits = $binary_bits;
    if (length($bits) < $declared_width) {
        $bits = ('0' x ($declared_width - length($bits))) . $bits;
        return ($bits, 0 + $declared_width);
    }

    if (length($bits) > $declared_width) {
        my $overflow_bits = substr($bits, 0, length($bits) - $declared_width);
        if ($overflow_bits =~ /1/) {
            confess $opts{on_overflow}->()
                if $opts{on_overflow};
            return;
        }
        $bits = substr($bits, -$declared_width);
    }

    return ($bits, 0 + $declared_width);
}

sub _octal_literal_bits_and_width ($class, $declared_width, $octal_digits, %opts) {
    return unless defined($declared_width) && $declared_width =~ /\A\d+\z/ && $declared_width > 0;
    $octal_digits = $class->_normalized_separated_digits($octal_digits, '[0-7]');
    return unless defined $octal_digits;

    my %octal_bits = (
        0 => '000',
        1 => '001',
        2 => '010',
        3 => '011',
        4 => '100',
        5 => '101',
        6 => '110',
        7 => '111',
    );

    my $bits = join '', map { $octal_bits{$_} } split //, $octal_digits;
    if (length($bits) < $declared_width) {
        $bits = ('0' x ($declared_width - length($bits))) . $bits;
        return ($bits, 0 + $declared_width);
    }

    if (length($bits) > $declared_width) {
        my $overflow_bits = substr($bits, 0, length($bits) - $declared_width);
        if ($overflow_bits =~ /1/) {
            confess $opts{on_overflow}->()
                if $opts{on_overflow};
            return;
        }
        $bits = substr($bits, -$declared_width);
    }

    return ($bits, 0 + $declared_width);
}

sub _hex_literal_bits_and_width ($class, $declared_width, $hex_digits, %opts) {
    return unless defined($declared_width) && $declared_width =~ /\A\d+\z/ && $declared_width > 0;
    $hex_digits = $class->_normalized_separated_digits($hex_digits, '[0-9A-Fa-f]');
    return unless defined $hex_digits;

    my %hex_bits = (
        0 => '0000',
        1 => '0001',
        2 => '0010',
        3 => '0011',
        4 => '0100',
        5 => '0101',
        6 => '0110',
        7 => '0111',
        8 => '1000',
        9 => '1001',
        a => '1010',
        b => '1011',
        c => '1100',
        d => '1101',
        e => '1110',
        f => '1111',
    );

    my $bits = join '', map { $hex_bits{lc($_)} } split //, $hex_digits;
    if (length($bits) < $declared_width) {
        $bits = ('0' x ($declared_width - length($bits))) . $bits;
        return ($bits, 0 + $declared_width);
    }

    if (length($bits) > $declared_width) {
        my $overflow_bits = substr($bits, 0, length($bits) - $declared_width);
        if ($overflow_bits =~ /1/) {
            confess $opts{on_overflow}->()
                if $opts{on_overflow};
            return;
        }
        $bits = substr($bits, -$declared_width);
    }

    return ($bits, 0 + $declared_width);
}

sub _resolve_top_expression_spec ($class, $spec, $top_ports_by_name, $instances_by_name, $child_ports_by_instance, $endpoint, $fsm_file, $header) {
    my $expr_kind = $spec->{expr_kind} || '';

    if ($expr_kind eq 'signal_ref') {
        my $port_name = $spec->{port_name} || '';
        my $top_port = $top_ports_by_name->{$port_name};
        confess
            "Composition source '$header' in '$fsm_file' uses top expression '$endpoint', ".
            "but explicit link endpoint resolution is blocked because concat operand '".$spec->{raw}."' references undeclared top port '$port_name'. ".
            "See docs/COMPOSITION_SCOPE.md and docs/COMPOSITION_LEGACY_MAPPING.md.\n"
            unless $top_port;

        return {
            width => $top_port->width,
            connection_expr => signal_ref_expr($port_name),
            base_ports => [$top_port],
            child_base_sources => [],
        };
    }

    if ($expr_kind eq 'literal') {
        return {
            width => $spec->{width},
            connection_expr => bit_vector_literal_expr($spec->{bits}),
            base_ports => [],
            child_base_sources => [],
        };
    }

    if ($expr_kind eq 'child_signal_ref' || $expr_kind eq 'child_bit_select' || $expr_kind eq 'child_slice') {
        my $instance_name = $spec->{instance_name} || '';
        my $port_name = $spec->{port_name} || '';
        my $instance = $instances_by_name->{$instance_name};
        my $context_label = $expr_kind eq 'child_signal_ref' ? 'child endpoint' : 'child expression';

        confess
            "Composition source '$header' in '$fsm_file' uses $context_label '".$spec->{raw}."', ".
            "but explicit link endpoint resolution is blocked because no realized child instance named '$instance_name' exists. ".
            "See docs/COMPOSITION_SCOPE.md and docs/COMPOSITION_LEGACY_MAPPING.md.\n"
            unless $instance;

        my $port = $child_ports_by_instance->{$instance_name}{$port_name};
        confess
            "Composition source '$header' in '$fsm_file' uses $context_label '".$spec->{raw}."', ".
            "but explicit link endpoint resolution is blocked because instance '$instance_name' has no port named '$port_name'. ".
            "See docs/COMPOSITION_SCOPE.md and docs/COMPOSITION_LEGACY_MAPPING.md.\n"
            unless $port;

        confess
            "Composition source '$header' in '$fsm_file' uses $context_label '".$spec->{raw}."', ".
            "but explicit link is blocked because base child port '$instance_name.$port_name' is ".$port->direction." instead of output. ".
            "See docs/COMPOSITION_SCOPE.md and docs/COMPOSITION_LEGACY_MAPPING.md.\n"
            unless ($port->direction || '') eq 'output';

        my $base_width = $port->width;
        my $base_endpoint = {
            raw => "$instance_name.$port_name",
            key => "child:$instance_name.$port_name",
            kind => 'child_port',
            instance_name => $instance_name,
            instance => $instance,
            port_name => $port_name,
            port => $port,
        };

        if ($expr_kind eq 'child_signal_ref') {
            return {
                width => $base_width,
                connection_expr => signal_ref_expr("$instance_name.$port_name"),
                base_ports => [],
                child_base_sources => [$base_endpoint],
            };
        }

        if ($expr_kind eq 'child_bit_select') {
            confess
                "Composition source '$header' in '$fsm_file' uses child expression '".$spec->{raw}."', ".
                "but explicit link endpoint resolution is blocked because bit index ".$spec->{index}." falls outside declared width $base_width of child endpoint '$instance_name.$port_name'. ".
                "See docs/COMPOSITION_SCOPE.md and docs/COMPOSITION_LEGACY_MAPPING.md.\n"
                unless defined($base_width) && $base_width > 0 && $spec->{index} < $base_width;

            return {
                width => 1,
                connection_expr => bit_select_expr("$instance_name.$port_name", $spec->{index}),
                base_ports => [],
                child_base_sources => [$base_endpoint],
            };
        }

        confess
            "Composition source '$header' in '$fsm_file' uses child expression '".$spec->{raw}."', ".
            "but explicit link endpoint resolution is blocked because slice bounds [".$spec->{msb}.':'.$spec->{lsb}."] fall outside declared width $base_width of child endpoint '$instance_name.$port_name'. ".
            "See docs/COMPOSITION_SCOPE.md and docs/COMPOSITION_LEGACY_MAPPING.md.\n"
            unless defined($base_width) && $base_width > 0 && $spec->{msb} < $base_width && $spec->{lsb} < $base_width;

        return {
            width => abs($spec->{msb} - $spec->{lsb}) + 1,
            connection_expr => slice_expr("$instance_name.$port_name", $spec->{msb}, $spec->{lsb}),
            base_ports => [],
            child_base_sources => [$base_endpoint],
        };
    }

    if ($expr_kind eq 'concat') {
        my @operand_exprs;
        my @base_ports;
        my @child_base_sources;
        my %seen_port_name;
        my %seen_child_base_key;
        my $width = 0;

        for my $operand_spec (@{$spec->{operands} || []}) {
            my $resolved_operand = $class->_resolve_top_expression_spec(
                $operand_spec,
                $top_ports_by_name,
                $instances_by_name,
                $child_ports_by_instance,
                $endpoint,
                $fsm_file,
                $header,
            );
            push @operand_exprs, $resolved_operand->{connection_expr};
            $width += $resolved_operand->{width};
            for my $base_port (@{$resolved_operand->{base_ports} || []}) {
                next if $seen_port_name{$base_port->name}++;
                push @base_ports, $base_port;
            }
            for my $child_base_source (@{$resolved_operand->{child_base_sources} || []}) {
                next if $seen_child_base_key{$child_base_source->{key}}++;
                push @child_base_sources, $child_base_source;
            }
        }

        return {
            width => $width,
            connection_expr => concat_expr(@operand_exprs),
            base_ports => \@base_ports,
            child_base_sources => \@child_base_sources,
        };
    }

    if ($expr_kind eq 'repeat') {
        my $resolved_operand = $class->_resolve_top_expression_spec(
            $spec->{operand},
            $top_ports_by_name,
            $instances_by_name,
            $child_ports_by_instance,
            $endpoint,
            $fsm_file,
            $header,
        );

        return {
            width => ($spec->{repeat_count} || 0) * $resolved_operand->{width},
            connection_expr => repeat_expr($spec->{repeat_count}, $resolved_operand->{connection_expr}),
            base_ports => [@{$resolved_operand->{base_ports} || []}],
            child_base_sources => [@{$resolved_operand->{child_base_sources} || []}],
        };
    }

    my $port_name = $spec->{port_name};
    my $top_port = $top_ports_by_name->{$port_name};

    confess
        "Composition source '$header' in '$fsm_file' references top expression '$endpoint', ".
        "but explicit link endpoint resolution is blocked because '?ports' declares no top port named '$port_name'. ".
        "See docs/COMPOSITION_SCOPE.md and docs/COMPOSITION_LEGACY_MAPPING.md.\n"
        unless $top_port;

    my $top_width = $top_port->width;
    my ($expr_width, $connection_expr);

    if ($expr_kind eq 'bit_select') {
        confess
            "Composition source '$header' in '$fsm_file' uses top expression '$endpoint', ".
            "but explicit link endpoint resolution is blocked because bit index ".$spec->{index}." falls outside declared width $top_width of top port '$port_name'. ".
            "See docs/COMPOSITION_SCOPE.md and docs/COMPOSITION_LEGACY_MAPPING.md.\n"
            unless defined($top_width) && $top_width > 0 && $spec->{index} < $top_width;

        $expr_width = 1;
        $connection_expr = bit_select_expr($port_name, $spec->{index});
    }
    else {
        confess
            "Composition source '$header' in '$fsm_file' uses top expression '$endpoint', ".
            "but explicit link endpoint resolution is blocked because slice bounds [".$spec->{msb}.':'.$spec->{lsb}."] fall outside declared width $top_width of top port '$port_name'. ".
            "See docs/COMPOSITION_SCOPE.md and docs/COMPOSITION_LEGACY_MAPPING.md.\n"
            unless defined($top_width) && $top_width > 0 && $spec->{msb} < $top_width && $spec->{lsb} < $top_width;

        $expr_width = abs($spec->{msb} - $spec->{lsb}) + 1;
        $connection_expr = slice_expr($port_name, $spec->{msb}, $spec->{lsb});
    }

    return {
        width => $expr_width,
        connection_expr => $connection_expr,
        base_ports => [$top_port],
        child_base_sources => [],
    };
}

sub endpoint_width ($class, $endpoint) {
    return $endpoint->{expr_width}
        if ref($endpoint) eq 'HASH' && defined $endpoint->{expr_width};

    my $port = ref($endpoint) eq 'HASH' ? $endpoint->{port} : undef;
    return 0 unless $port;
    return $port->{width} if ref($port) eq 'HASH';
    return $port->width if ref($port) && $port->can('width');
    return 0;
}

sub source_family_key ($class, $source) {
    return $source->{base_key}
        if ref($source) eq 'HASH' && (($source->{kind} || '') eq 'child_expr');
    return ref($source) eq 'HASH' ? $source->{key} : undef;
}

sub source_family_endpoint ($class, $source) {
    return $source unless ref($source) eq 'HASH';

    if (($source->{kind} || '') eq 'child_expr') {
        return {
            raw => $source->{base_raw},
            key => $source->{base_key},
            kind => 'child_port',
            instance_name => $source->{instance_name},
            instance => $source->{instance},
            port_name => $source->{port_name},
            port => $source->{port},
        };
    }

    return $source;
}

sub source_connection_expr_for_carrier ($class, $source, $carrier_signal_name) {
    confess "Projected child sources require a real carrier signal name.\n"
        unless defined($carrier_signal_name) && length($carrier_signal_name);

    my $kind = ref($source) eq 'HASH' ? ($source->{kind} || '') : '';
    return signal_ref_expr($carrier_signal_name)
        if $kind eq 'child_port';

    if ($kind eq 'child_expr') {
        return bit_select_expr($carrier_signal_name, $source->{index})
            if (($source->{expr_kind} || '') eq 'bit_select');

        return slice_expr($carrier_signal_name, $source->{msb}, $source->{lsb})
            if (($source->{expr_kind} || '') eq 'slice');
    }

    confess "Unsupported source kind '$kind' reached source_connection_expr_for_carrier.\n";
}

sub rebind_source_expr_with_child_carriers ($class, $expr, $carrier_by_child_base_endpoint) {
    return undef unless ref($expr) eq 'HASH';

    my $kind = $expr->{kind} || '';
    if ($kind eq 'signal_ref') {
        my $signal_name = $expr->{signal_name} || '';
        return signal_ref_expr($carrier_by_child_base_endpoint->{$signal_name} // $signal_name);
    }

    if ($kind eq 'bit_select') {
        return bit_select_expr(
            $class->rebind_source_expr_with_child_carriers($expr->{source_expr}, $carrier_by_child_base_endpoint),
            $expr->{index},
        );
    }

    if ($kind eq 'slice') {
        return slice_expr(
            $class->rebind_source_expr_with_child_carriers($expr->{source_expr}, $carrier_by_child_base_endpoint),
            $expr->{msb},
            $expr->{lsb},
        );
    }

    if ($kind eq 'concat') {
        return concat_expr(map {
            $class->rebind_source_expr_with_child_carriers($_, $carrier_by_child_base_endpoint)
        } @{$expr->{operands} || []});
    }

    if ($kind eq 'repeat') {
        return repeat_expr(
            $expr->{repeat_count},
            $class->rebind_source_expr_with_child_carriers($expr->{operand}, $carrier_by_child_base_endpoint),
        );
    }

    if ($kind eq 'bit_vector_literal') {
        return bit_vector_literal_expr($expr->{bits});
    }

    if ($kind eq 'open') {
        return open_expr();
    }

    confess "Unsupported connection expression kind '$kind' reached rebind_source_expr_with_child_carriers.\n";
}

sub ensure_child_source_carrier ($class, $source, $targets, $top_ports_by_name, $existing_nets, $bindings_by_instance, $carrier_signal_by_source, $preferred_name = undef) {
    my $source_key = $class->source_family_key($source);
    confess "Child source carriers require a stable source-family key.\n"
        unless defined($source_key) && length($source_key);

    if (defined(my $existing_carrier = $carrier_signal_by_source->{$source_key})) {
        for my $net (@{$existing_nets || []}) {
            next unless $net->name eq $existing_carrier;
            my %seen_target = map { $_ => 1 } @{$net->targets || []};
            for my $target (@{$targets || []}) {
                next unless defined($target) && length($target);
                next if $seen_target{$target}++;
                push @{$net->targets}, $target;
            }
        }
        $bindings_by_instance->{$source->{instance_name}}{$source->{port}->name} = $existing_carrier;
        return $existing_carrier;
    }

    my $net_name = $class->allocate_net_name($source, $top_ports_by_name, $existing_nets, $preferred_name);
    push @{$existing_nets || []}, FSM::Composition::Net->new(
        name => $net_name,
        width => $source->{port}->width,
        source => $source->{raw},
        targets => [grep { defined($_) && length($_) } @{$targets || []}],
    );

    $carrier_signal_by_source->{$source_key} = $net_name;
    $bindings_by_instance->{$source->{instance_name}}{$source->{port}->name} = $net_name;
    return $net_name;
}

sub actual_connection_expr_for_target ($class, $source, $target_width, $fsm_file = undef, $header = undef) {
    return $source->{connection_expr}
        unless ref($source) eq 'HASH' && (($source->{kind} || '') =~ /^actual_/);

    return $source->{connection_expr}
        unless (($source->{kind} || '') eq 'actual_scalar_literal'
            || ($source->{kind} || '') eq 'actual_unsized_binary'
            || ($source->{kind} || '') eq 'actual_unsized_decimal'
            || ($source->{kind} || '') eq 'actual_unsized_signed_decimal'
            || ($source->{kind} || '') eq 'actual_unsized_signed_binary'
            || ($source->{kind} || '') eq 'actual_unsized_signed_octal'
            || ($source->{kind} || '') eq 'actual_unsized_signed_hex'
            || ($source->{kind} || '') eq 'actual_unsized_octal'
            || ($source->{kind} || '') eq 'actual_unsized_hex');

    confess "Scalar actuals require a positive target width before binding.\n"
        unless defined($target_width) && $target_width =~ /\A\d+\z/ && $target_width > 0;

    if (($source->{kind} || '') eq 'actual_scalar_literal') {
        my $scalar_bit = $source->{scalar_bit} // '';
        confess "Scalar actuals must preserve one-bit payload metadata.\n"
            unless $scalar_bit =~ /\A[01]\z/;

        my $bits = '0' x $target_width;
        substr($bits, -1, 1, $scalar_bit) if $scalar_bit eq '1';
        return bit_vector_literal_expr($bits);
    }

    if (($source->{kind} || '') eq 'actual_unsized_binary') {
        my $binary_bits = $source->{binary_bits} // '';
        my ($bits, undef) = $class->_binary_literal_bits_and_width(
            $target_width,
            $binary_bits,
            on_overflow => sub {
                return
                    "Composition source '$header' in '$fsm_file' uses actual literal '".$source->{raw}."', ".
                    "but explicit actual binding is blocked because unsized binary actual value does not fit direct target width $target_width. ".
                    "See docs/COMPOSITION_SCOPE.md and docs/COMPOSITION_LEGACY_MAPPING.md.\n";
            },
        );
        return bit_vector_literal_expr($bits);
    }

    if (($source->{kind} || '') eq 'actual_unsized_decimal') {
        my $decimal_digits = $source->{decimal_digits} // '';
        my ($bits, undef) = $class->_decimal_literal_bits_and_width(
            $target_width,
            $decimal_digits,
            on_overflow => sub {
                return
                    "Composition source '$header' in '$fsm_file' uses actual literal '".$source->{raw}."', ".
                    "but explicit actual binding is blocked because unsized decimal actual value does not fit direct target width $target_width. ".
                    "See docs/COMPOSITION_SCOPE.md and docs/COMPOSITION_LEGACY_MAPPING.md.\n";
            },
        );
        return bit_vector_literal_expr($bits);
    }

    if (($source->{kind} || '') eq 'actual_unsized_signed_decimal') {
        my $decimal_digits = $source->{decimal_digits} // '';
        my ($bits, undef) = $class->_signed_decimal_literal_bits_and_width(
            $target_width,
            "-$decimal_digits",
            on_overflow => sub {
                return
                    "Composition source '$header' in '$fsm_file' uses actual literal '".$source->{raw}."', ".
                    "but explicit actual binding is blocked because unsized signed decimal actual value does not fit signed direct target width $target_width. ".
                    "See docs/COMPOSITION_SCOPE.md and docs/COMPOSITION_LEGACY_MAPPING.md.\n";
            },
        );
        return bit_vector_literal_expr($bits);
    }

    if (($source->{kind} || '') eq 'actual_unsized_signed_binary') {
        my $binary_bits = $source->{binary_bits} // '';
        my ($bits, undef) = $class->_signed_bits_literal_bits_and_width(
            $target_width,
            $binary_bits,
            on_overflow => sub {
                return
                    "Composition source '$header' in '$fsm_file' uses actual literal '".$source->{raw}."', ".
                    "but explicit actual binding is blocked because unsized signed binary actual value does not fit signed direct target width $target_width. ".
                    "See docs/COMPOSITION_SCOPE.md and docs/COMPOSITION_LEGACY_MAPPING.md.\n";
            },
        );
        return bit_vector_literal_expr($bits);
    }

    if (($source->{kind} || '') eq 'actual_unsized_octal') {
        my $octal_digits = $source->{octal_digits} // '';
        my ($bits, undef) = $class->_octal_literal_bits_and_width(
            $target_width,
            $octal_digits,
            on_overflow => sub {
                return
                    "Composition source '$header' in '$fsm_file' uses actual literal '".$source->{raw}."', ".
                    "but explicit actual binding is blocked because unsized octal actual value does not fit direct target width $target_width. ".
                    "See docs/COMPOSITION_SCOPE.md and docs/COMPOSITION_LEGACY_MAPPING.md.\n";
            },
        );
        return bit_vector_literal_expr($bits);
    }

    if (($source->{kind} || '') eq 'actual_unsized_signed_octal') {
        my $octal_digits = $source->{octal_digits} // '';
        my ($intrinsic_bits, undef) = $class->_octal_literal_bits_and_width(length($octal_digits) * 3, $octal_digits);
        confess "Signed octal actuals must preserve intrinsic payload bits before widening.\n"
            unless defined $intrinsic_bits;
        my ($bits, undef) = $class->_signed_bits_literal_bits_and_width(
            $target_width,
            $intrinsic_bits,
            on_overflow => sub {
                return
                    "Composition source '$header' in '$fsm_file' uses actual literal '".$source->{raw}."', ".
                    "but explicit actual binding is blocked because unsized signed octal actual value does not fit signed direct target width $target_width. ".
                    "See docs/COMPOSITION_SCOPE.md and docs/COMPOSITION_LEGACY_MAPPING.md.\n";
            },
        );
        return bit_vector_literal_expr($bits);
    }

    if (($source->{kind} || '') eq 'actual_unsized_hex') {
        my $hex_digits = $source->{hex_digits} // '';
        my ($bits, undef) = $class->_hex_literal_bits_and_width(
            $target_width,
            $hex_digits,
            on_overflow => sub {
                return
                    "Composition source '$header' in '$fsm_file' uses actual literal '".$source->{raw}."', ".
                    "but explicit actual binding is blocked because unsized hex actual value does not fit direct target width $target_width. ".
                    "See docs/COMPOSITION_SCOPE.md and docs/COMPOSITION_LEGACY_MAPPING.md.\n";
            },
        );
        return bit_vector_literal_expr($bits);
    }

    if (($source->{kind} || '') eq 'actual_unsized_signed_hex') {
        my $hex_digits = $source->{hex_digits} // '';
        my ($intrinsic_bits, undef) = $class->_hex_literal_bits_and_width(length($hex_digits) * 4, $hex_digits);
        confess "Signed hex actuals must preserve intrinsic payload bits before widening.\n"
            unless defined $intrinsic_bits;
        my ($bits, undef) = $class->_signed_bits_literal_bits_and_width(
            $target_width,
            $intrinsic_bits,
            on_overflow => sub {
                return
                    "Composition source '$header' in '$fsm_file' uses actual literal '".$source->{raw}."', ".
                    "but explicit actual binding is blocked because unsized signed hex actual value does not fit signed direct target width $target_width. ".
                    "See docs/COMPOSITION_SCOPE.md and docs/COMPOSITION_LEGACY_MAPPING.md.\n";
            },
        );
        return bit_vector_literal_expr($bits);
    }

    confess "Unsupported actual kind '".$source->{kind}."' reached actual_connection_expr_for_target.\n";
}

sub allocate_net_name ($class, $source, $top_ports_by_name, $existing_nets, $preferred_name = undef) {
    my $base_name = $preferred_name // ("comp_link_" . $source->{instance_name} . "_" . $source->{port_name});
    $base_name =~ s/\W+/_/g;
    my %reserved = map { $_ => 1 } keys %{$top_ports_by_name || {}};
    $reserved{$_->name} = 1 for @{$existing_nets || []};

    my $candidate = $base_name;
    my $suffix = 0;
    while ($reserved{$candidate}) {
        $suffix++;
        $candidate = $base_name . "_" . $suffix;
    }

    return $candidate;
}

sub clone_realized_instance_with_bindings ($class, $instance, $port_bindings) {
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

=head1 METHODS

=head2 build_from_toplinks

Builds a linked composition plan after validating that the active lane has at
least one explicit C<?toplink> entry.

=head2 build_plan

Builds the generic linked composition plan for the active explicit-link lane,
including same-name convention expansion, system-port auto-wiring, carrier-net
allocation, endpoint resolution, and realized-child rebinding.

=head2 system_interface_ports

Returns the shared system ports from one interface-port list.

=head2 index_ports_by_name

Returns a name-indexed port hash for one interface or top-port list.

=head2 assert_unique_top_ports

Validates that the declared top-port block uses each port name at most once and
returns a name-indexed top-port hash.

=head2 resolve_endpoint

Resolves one explicit-link endpoint token into the normalized top-port or
child-port endpoint structure used by linked-plan assembly.

=head2 assert_link_roles

Validates that a resolved explicit-link source and target satisfy the active
top-input/child-output to child-input/top-output role contract.

=head2 allocate_net_name

Allocates the deterministic synthetic carrier-net name for one linked-plan
source, honoring existing top ports and nets.

=head2 clone_realized_instance_with_bindings

Clones a realized child instance while replacing its structural binding list
with the linked-plan bindings.

=cut
