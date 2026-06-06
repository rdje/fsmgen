package FSM::Composition::LinkedPlanBuilder;

=head1 NAME

FSM::Composition::LinkedPlanBuilder - Builder for explicit-link composition plans

=head1 DESCRIPTION

Builds the bounded explicit-link composition plans used by the active C2, C3,
and C4 lanes. This package owns explicit-wiring lane entry, endpoint
resolution, role validation, deterministic carrier-net allocation, system-port
auto-wiring, and realized-child rebinding for linked composition plans.

=cut

use v5.20;
use strict;
use warnings;
use Carp qw(confess);
use feature qw(signatures);
no warnings 'experimental::signatures';

use FSM::Composition::Link;
use FSM::Composition::AggregatePathSupport;
use FSM::Composition::ActualLiteralSupport;
use FSM::Composition::InterfacePortBuilder;
use FSM::Composition::Net;
use FSM::Composition::Plan;
use FSM::Composition::RealizedInstance;
use FSM::Composition::SameNameLinkBuilder;
use FSM::Composition::SourceExpressionSpecSupport;
use FSM::IR::StructuralRTLIR::ConnectionExpr qw(
    bit_select_expr
    bit_vector_literal_expr
    concat_expr
    index_access_expr
    member_access_expr
    normalized_binding
    open_expr
    repeat_expr
    render_expr
    signal_ref_binding
    signal_ref_expr
    slice_expr
);
use FSM::Package::PayloadLiteralSupport;
use FSM::Package::PayloadTypeSupport;

sub build_from_wiring_blocks ($class, %args) {
    my $lane = $args{lane} // '';
    my $wiring_blocks = $args{wiring_blocks} || [];
    my $fsm_file = $args{fsm_file};
    my $header = $args{header};

    my @links = map { @{$_->links || []} } @$wiring_blocks;
    confess
        "Composition source '$header' in '$fsm_file' is recognized and parsed into typed composition IR, ".
        "but explicit-link lane entry is blocked because the current active $lane lane requires explicit '?wiring' wiring. ".
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
    my $top_symbols = $top && $top->can('top_symbols') ? $top->top_symbols : undef;
    my $target_language = $args{target_language} // 'systemverilog';

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
            top_symbols => $top_symbols,
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
            top_symbols => $top_symbols,
        );

        $class->assert_link_roles($source, $target, $fsm_file, $header);

        my $source_width = $class->endpoint_width($source);
        my $target_width = $class->endpoint_width($target);

        confess
            "Composition source '$header' in '$fsm_file' links '".$source->{raw}."' (width $source_width) to '".$target->{raw}."' (width $target_width), ".
            "but explicit link is blocked because the current active composition lanes require exact width agreement. ".
            "See docs/COMPOSITION_SCOPE.md and docs/COMPOSITION_LEGACY_MAPPING.md.\n"
            unless (($source->{kind} || '') eq 'actual_open')
                || FSM::Composition::ActualLiteralSupport->is_target_width_bound_actual_kind($source->{kind} || '')
                || $source_width == $target_width;

        $class->assert_declared_type_compatibility($source, $target, $fsm_file, $header);
        $class->assert_actual_aggregate_type_compatibility($source, $target, $fsm_file, $header);
        $class->assert_expression_aggregate_type_compatibility($source, $target, $fsm_file, $header);

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
            my $binding_type_contract = $class->_binding_connection_type_contract(
                $source,
                $target_width,
            );

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
                    my $expr_text = render_expr($bound_connection_expr, $target->{port}->name, $target_language);
                    push @auxiliary_assignments, _assignment_line($target->{port}->name, $expr_text, $target_language);
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
                my $expr_text = render_expr($bound_connection_expr, $target->{port}->name, $target_language);
                push @auxiliary_assignments, _assignment_line($target->{port}->name, $expr_text, $target_language);
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
                %$binding_type_contract,
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
                push @auxiliary_assignments, _assignment_line($resolved_link->{target}{port}->name, $source->{port}->name, $target_language);
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
            my $binding_type_contract = $class->_binding_connection_type_contract($source, undef);
            $bindings_by_instance{$source->{instance_name}}{$source->{port}->name} = normalized_binding({
                port_name => $source->{port}->name,
                signal_name => $carrier_signal_name,
                %$binding_type_contract,
            });
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

            my $expr_text = render_expr($bound_connection_expr, $resolved_link->{target}{port}->name, $target_language);
            push @auxiliary_assignments, _assignment_line($resolved_link->{target}{port}->name, $expr_text, $target_language);
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
            my $binding_type_contract = $class->_binding_connection_type_contract(
                $source,
                undef,
            );
            $bindings_by_instance{$target->{instance_name}}{$target->{port}->name} = normalized_binding({
                port_name => $target->{port}->name,
                connection_expr => $class->source_connection_expr_for_carrier($source, $carrier_signal_name),
                %$binding_type_contract,
            });
            next;
        }

        my $binding_type_contract = $class->_binding_connection_type_contract($source, undef);
        $bindings_by_instance{$target->{instance_name}}{$target->{port}->name} = normalized_binding({
            port_name => $target->{port}->name,
            signal_name => $carrier_signal_name,
            %$binding_type_contract,
        });
    }

    for my $top_port_name (sort keys %{$top_ports_by_name || {}}) {
        my $top_port = $top_ports_by_name->{$top_port_name};
        next if $system_top_ports{$top_port_name};

        if ($top_port->direction eq 'input') {
            confess
                "Composition source '$header' in '$fsm_file' declares top input '$top_port_name', ".
                "but explicit-link top wiring is blocked because the current active $lane lane requires explicit '?wiring' usage for every non-system top input. ".
                "See docs/COMPOSITION_SCOPE.md and docs/COMPOSITION_LEGACY_MAPPING.md.\n"
                unless $top_port_usage{$top_port_name}{source};
        } else {
            confess
                "Composition source '$header' in '$fsm_file' declares top output '$top_port_name', ".
                "but explicit-link top wiring is blocked because the current active $lane lane requires explicit '?wiring' usage for every top output. ".
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

sub _assignment_line ($target_name, $expr_text, $target_language) {
    my $language = lc($target_language // 'systemverilog');
    return "    $target_name <= $expr_text;"
        if $language eq 'vhdl';
    return "    assign $target_name = $expr_text;";
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
    if ($opts{allow_top_expression_source}
        && defined($endpoint)
        && !ref($endpoint)
        && ($endpoint =~ /\A\{.*\}\z/s || index($endpoint, ',') >= 0))
    {
        if (my $top_expression_endpoint = $class->_resolve_top_expression_endpoint(
            $endpoint,
            $top_ports_by_name,
            $instances_by_name,
            $child_ports_by_instance,
            $fsm_file,
            $header,
            %opts,
        )) {
            return $top_expression_endpoint;
        }
    }

    if (my $actual_endpoint = $class->_resolve_actual_endpoint($endpoint, $fsm_file, $header, %opts)) {
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
            %opts,
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
            "but explicit actual binding is blocked because the first structural-actual slice only allows '=open', scalar '=0'/'=1', named literal actuals from composition-root '+constants' / '+enums' or imported packages like '=RESET_BYTE', '=mode.BUSY', '=shared.RESET_BYTE', or '=shared.mode.BUSY', unsized binary/decimal/octal/hex direct actuals, unsized signed decimal direct actuals like '=-1', '=0d-1', or '='sd-1', unsized signed binary/octal/hex direct actuals like '='sb1010', '='so7', or '='shA', and exact-width binary/decimal/octal/hex literal actuals in unsigned or signed form like '=8'b10100101', '=8'sb10100101', '=8'd165', '=8'sd-1', '=8'o245', '=8'so245', '=8'hA5', or '=8'shA5' as link sources into realized child input ports, plus literal actuals into declared top outputs. ".
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

sub assert_declared_type_compatibility ($class, $source, $target, $fsm_file, $header) {
    return unless ($source->{kind} || '') eq 'top_port' || ($source->{kind} || '') eq 'child_port';
    return unless ($target->{kind} || '') eq 'top_port' || ($target->{kind} || '') eq 'child_port';
    return unless FSM::Composition::InterfacePortBuilder->declared_type_conflicts($source->{port}, $target->{port});

    my $source_declared_type = FSM::Composition::InterfacePortBuilder->declared_type_label($source->{port});
    my $target_declared_type = FSM::Composition::InterfacePortBuilder->declared_type_label($target->{port});

    confess
        "Composition source '$header' in '$fsm_file' links '".$source->{raw}."' to '".$target->{raw}."', ".
        "but explicit link is blocked because those endpoints preserve incompatible declared type contracts ('".$source_declared_type."' vs '".$target_declared_type."'). ".
        "The current typed composition slice only allows direct port-to-port '?wiring' bindings when preserved declared type contracts stay compatible too. ".
        "See docs/COMPOSITION_SCOPE.md and docs/COMPOSITION_LEGACY_MAPPING.md.\n";
}

sub assert_actual_aggregate_type_compatibility ($class, $source, $target, $fsm_file, $header) {
    return unless ref($source) eq 'HASH' && (($source->{kind} || '') =~ /^actual_/);
    return unless ($target->{kind} || '') eq 'top_port' || ($target->{kind} || '') eq 'child_port';

    my $aggregate_type_spec = $source->{aggregate_type_spec};
    return unless ref($aggregate_type_spec) eq 'HASH';

    my $target_declared_type_spec = FSM::Composition::InterfacePortBuilder->declared_type_spec($target->{port});
    return unless ref($target_declared_type_spec) eq 'HASH';

    my $target_kind = $target_declared_type_spec->{kind} || '';
    return unless $target_kind eq 'list' || $target_kind eq 'record';
    return if FSM::Package::PayloadTypeSupport->payload_compatible_with_type_spec(
        $aggregate_type_spec,
        $target_declared_type_spec,
    );

    my $aggregate_type_label = FSM::Composition::InterfacePortBuilder->declared_type_label($aggregate_type_spec);
    my $target_type_label = FSM::Composition::InterfacePortBuilder->declared_type_label($target_declared_type_spec);

    confess
        "Composition source '$header' in '$fsm_file' uses actual source '".$source->{raw}."' as an explicit link source, ".
        "but explicit actual binding is blocked because whole aggregate actual contract '$aggregate_type_label' does not match target declared type '$target_type_label' on '".$target->{raw}."'. ".
        "The current typed composition slice only allows whole aggregate actual roots to target preserved aggregate contracts when packed shape and leaf widths stay compatible too. ".
        "See docs/COMPOSITION_SCOPE.md and docs/COMPOSITION_LEGACY_MAPPING.md.\n";
}

sub assert_expression_aggregate_type_compatibility ($class, $source, $target, $fsm_file, $header) {
    return unless ref($source) eq 'HASH';
    return unless (($source->{kind} || '') eq 'top_expr' || ($source->{kind} || '') eq 'child_expr');
    return unless ($target->{kind} || '') eq 'top_port' || ($target->{kind} || '') eq 'child_port';

    my $source_type_spec = $source->{inferred_type_spec};
    return unless ref($source_type_spec) eq 'HASH';

    my $target_declared_type_spec = FSM::Composition::InterfacePortBuilder->declared_type_spec($target->{port});
    return unless ref($target_declared_type_spec) eq 'HASH';

    my $target_kind = $target_declared_type_spec->{kind} || '';
    return unless $target_kind eq 'list' || $target_kind eq 'record';
    return if FSM::Package::PayloadTypeSupport->payload_compatible_with_type_spec(
        $source_type_spec,
        $target_declared_type_spec,
    );

    my $source_type_label = FSM::Package::PayloadTypeSupport->type_spec_label($source_type_spec);
    my $target_type_label = FSM::Composition::InterfacePortBuilder->declared_type_label($target_declared_type_spec);
    my $source_label = (($source->{kind} || '') eq 'top_expr') ? 'top expression' : 'child expression';

    confess
        "Composition source '$header' in '$fsm_file' uses $source_label '".$source->{raw}."' as an explicit link source, ".
        "but explicit aggregate-expression binding is blocked because expression contract '$source_type_label' does not match target declared type '$target_type_label' on '".$target->{raw}."'. ".
        "The current typed composition slice only allows top/child source expressions to target preserved aggregate contracts when aggregate shape stays compatible too. ".
        "See docs/COMPOSITION_SCOPE.md and docs/COMPOSITION_LEGACY_MAPPING.md.\n";
}

sub _resolve_actual_endpoint ($class, $endpoint, $fsm_file, $header, %opts) {
    return undef unless defined($endpoint) && length($endpoint);
    return undef unless $endpoint =~ /^=(.+)$/;

    my $payload = $1;
    if ($payload eq 'open' || $payload =~ /\A[01]\z/) {
        return FSM::Composition::ActualLiteralSupport->resolve_actual_payload(
            $payload,
            raw => $endpoint,
            key => "actual:$endpoint",
            fsm_file => $fsm_file,
            header => $header,
        );
    }

    if (my $resolved_payload = FSM::Composition::SourceExpressionSpecSupport->resolve_top_symbol_actual_payload($payload, $opts{top_symbols})) {
        my $resolved_actual = $class->_resolve_actual_endpoint(
            '='.$resolved_payload,
            $fsm_file,
            $header,
        );
        if ($resolved_actual) {
            $resolved_actual->{raw} = $endpoint;
            $resolved_actual->{key} = "actual:$endpoint";
            $resolved_actual->{symbol_name} = $payload;
            $resolved_actual->{resolved_payload} = $resolved_payload;
            return $resolved_actual;
        }
    }

    if (my $resolved_payload = FSM::Composition::SourceExpressionSpecSupport->resolve_top_symbol_payload($payload, $opts{top_symbols})) {
        my ($bits, $width, $reason) = FSM::Package::PayloadLiteralSupport->payload_to_bits_and_width($resolved_payload);
        if (defined $bits) {
            my $aggregate_type_spec = undef;
            if (ref($resolved_payload) eq 'HASH' && (($resolved_payload->{kind} || '') eq 'list' || ($resolved_payload->{kind} || '') eq 'map')) {
                $aggregate_type_spec = FSM::Package::PayloadTypeSupport->payload_to_type_spec($resolved_payload);
            }
            return {
                raw => $endpoint,
                key => "actual:$endpoint",
                kind => 'actual_literal',
                symbol_name => $payload,
                resolved_payload => $resolved_payload,
                aggregate_type_spec => $aggregate_type_spec,
                port => {
                    direction => 'actual',
                    width => $width,
                },
                connection_expr => bit_vector_literal_expr($bits),
            };
        }
        confess
            "Composition source '$header' in '$fsm_file' uses actual endpoint '=$payload', ".
            "but explicit actual binding is blocked because that whole aggregate root did not lower to one packed literal; reason '$reason' is outside the current aggregate-actual contract. ".
            "See docs/COMPOSITION_SCOPE.md and docs/COMPOSITION_LEGACY_MAPPING.md.\n";
    }

    return FSM::Composition::ActualLiteralSupport->resolve_actual_payload(
        $payload,
        raw => $endpoint,
        key => "actual:$endpoint",
        fsm_file => $fsm_file,
        header => $header,
    );
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
            inferred_type_spec => FSM::Package::PayloadTypeSupport->scalar_type_spec_from_width(1),
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
            inferred_type_spec => FSM::Package::PayloadTypeSupport->scalar_type_spec_from_width(abs($msb - $lsb) + 1),
        };
    }

    if ($endpoint =~ /\A(\w+)\.(\w+)((?:\.[A-Za-z_]\w*|\[\d+(?::\d+)?\])+)\z/) {
        my ($instance_name, $port_name, $path_text) = ($1, $2, $3);
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

        my ($connection_expr, $resolved_type_spec, $resolved_width) = $class->_resolve_aggregate_path_connection(
            base_expr => signal_ref_expr("$instance_name.$port_name"),
            root_type_spec => FSM::Composition::InterfacePortBuilder->declared_type_spec($port),
            path_text => $path_text,
            raw => $endpoint,
            context_label => 'child expression',
            base_label => "child endpoint '$instance_name.$port_name'",
            fsm_file => $fsm_file,
            header => $header,
        );

        return {
            raw => $endpoint,
            key => "child_expr:$endpoint",
            base_key => "child:$instance_name.$port_name",
            base_raw => "$instance_name.$port_name",
            kind => 'child_expr',
            expr_kind => 'aggregate_ref',
            expr_width => $resolved_width,
            connection_expr => $connection_expr,
            instance_name => $instance_name,
            instance => $instance,
            port_name => $port_name,
            port => $port,
            inferred_type_spec => $resolved_type_spec,
        };
    }

    return undef;
}

sub top_expression_spec ($class, $endpoint) {
    return FSM::Composition::SourceExpressionSpecSupport->top_expression_spec($endpoint);
}

sub top_expression_base_port_name ($class, $endpoint) {
    return FSM::Composition::SourceExpressionSpecSupport->top_expression_base_port_name($endpoint);
}

sub top_expression_inference_specs ($class, $endpoint) {
    return FSM::Composition::SourceExpressionSpecSupport->top_expression_inference_specs($endpoint);
}

sub top_expression_child_base_endpoints ($class, $endpoint) {
    return FSM::Composition::SourceExpressionSpecSupport->top_expression_child_base_endpoints($endpoint);
}

sub child_expression_spec ($class, $endpoint) {
    return FSM::Composition::SourceExpressionSpecSupport->child_expression_spec($endpoint);
}

sub child_expression_base_endpoint ($class, $endpoint) {
    return FSM::Composition::SourceExpressionSpecSupport->child_expression_base_endpoint($endpoint);
}

sub _resolve_top_expression_endpoint ($class, $endpoint, $top_ports_by_name, $instances_by_name, $child_ports_by_instance, $fsm_file, $header, %opts) {
    my $spec = FSM::Composition::SourceExpressionSpecSupport->parse_top_expression_spec(
        $endpoint,
        allow_plain_top_ref => 0,
        allow_literal_actual => 0,
        top_symbols => $opts{top_symbols},
        fsm_file => $fsm_file,
        header => $header,
    );
    if (!$spec && defined($endpoint) && ($endpoint =~ /\A\{.*\}\z/s || index($endpoint, ',') >= 0)) {
        confess
            "Composition source '$header' in '$fsm_file' uses top expression '$endpoint', ".
            "but explicit link endpoint resolution is blocked because concat operands currently accept only top-port names, top-port bit/slice forms, child endpoints like 'producer.payload', child-output bit/slice forms like 'producer.payload[3]' or 'producer.payload[7:4]', repeat groups like '{4{status_bus[0]}}', scalar '=0'/'=1' actuals, named literal actuals from composition-root '+constants' / '+enums' or imported packages like '=RESET_BYTE', '=mode.BUSY', '=shared.RESET_BYTE', or '=shared.mode.BUSY', intrinsic-width unsized binary/decimal/octal/hex actuals like '=0b1010', '='b1010', '=170', '=0d170', '='d170', '=0o7', '='o7', '=0xA5', '='hA5', or '=A5', intrinsic-width unsized signed decimal actuals like '=-1', '=0d-1', or '='sd-1', intrinsic-width unsized signed binary/octal/hex actuals like '='sb1010', '='so7', or '='shA5', and exact-width literal actuals like '=4'b1010', '=4'sb1010', '=4'd10', '=8'sd-1', '=3'o7', '=3'so7', '=4'hA', or '=4'shA'. ".
            "See docs/COMPOSITION_SCOPE.md and docs/COMPOSITION_LEGACY_MAPPING.md.\n";
    }
    return undef unless $spec;
    return undef
        if (($spec->{expr_kind} || '') eq 'aggregate_ref')
        && !$top_ports_by_name->{$spec->{port_name} || ''};

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
        inferred_type_spec => $class->_clone_structured_value($resolved_spec->{type_spec}),
        connection_expr => $resolved_spec->{connection_expr},
    };
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
            type_spec => $class->_endpoint_declared_or_scalar_type_spec($top_port),
        };
    }

    if ($expr_kind eq 'literal') {
        return {
            width => $spec->{width},
            connection_expr => bit_vector_literal_expr($spec->{bits}),
            base_ports => [],
            child_base_sources => [],
            type_spec => FSM::Package::PayloadTypeSupport->scalar_type_spec_from_width($spec->{width}),
        };
    }

    if ($expr_kind eq 'unsupported_aggregate_literal') {
        my $symbol_name = $spec->{symbol_name} || $spec->{raw} || 'aggregate';
        my $reason = $spec->{reason} || 'unsupported_aggregate';
        confess
            "Composition source '$header' in '$fsm_file' uses top expression '$endpoint', ".
            "but explicit link endpoint resolution is blocked because whole aggregate actual operand '$symbol_name' did not lower to one packed literal; reason '$reason' is outside the current aggregate-actual contract. ".
            "See docs/COMPOSITION_SCOPE.md and docs/COMPOSITION_LEGACY_MAPPING.md.\n";
    }

    if ($expr_kind eq 'child_signal_ref' || $expr_kind eq 'child_bit_select' || $expr_kind eq 'child_slice' || $expr_kind eq 'child_aggregate_ref') {
        my $instance_name = $spec->{instance_name} || '';
        my $port_name = $spec->{port_name} || '';
        my $instance = $instances_by_name->{$instance_name};
        my $context_label = $expr_kind eq 'child_signal_ref' ? 'child endpoint' : 'child expression';

        if (!$instance) {
            my $top_port = $top_ports_by_name->{$instance_name};
            if ($top_port) {
                my $path_text = $expr_kind eq 'child_aggregate_ref'
                    ? '.'.$port_name.($spec->{path_text} || '')
                    : $expr_kind eq 'child_bit_select'
                        ? '.'.$port_name.'['.$spec->{index}.']'
                        : $expr_kind eq 'child_slice'
                            ? '.'.$port_name.'['.$spec->{msb}.':'.$spec->{lsb}.']'
                            : '.'.$port_name;
                my ($connection_expr, $resolved_type_spec, $resolved_width) = $class->_resolve_aggregate_path_connection(
                    base_expr => signal_ref_expr($instance_name),
                    root_type_spec => FSM::Composition::InterfacePortBuilder->declared_type_spec($top_port),
                    path_text => $path_text,
                    raw => $spec->{raw},
                    context_label => 'top expression',
                    base_label => "top port '$instance_name'",
                    fsm_file => $fsm_file,
                    header => $header,
                );

                return {
                    width => $resolved_width,
                    connection_expr => $connection_expr,
                    base_ports => [$top_port],
                    child_base_sources => [],
                    type_spec => $resolved_type_spec,
                };
            }
        }

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
                type_spec => $class->_endpoint_declared_or_scalar_type_spec($port),
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
                type_spec => FSM::Package::PayloadTypeSupport->scalar_type_spec_from_width(1),
            };
        }

        if ($expr_kind eq 'child_aggregate_ref') {
            my ($connection_expr, $resolved_type_spec, $resolved_width) = $class->_resolve_aggregate_path_connection(
                base_expr => signal_ref_expr("$instance_name.$port_name"),
                root_type_spec => FSM::Composition::InterfacePortBuilder->declared_type_spec($port),
                path_text => $spec->{path_text},
                raw => $spec->{raw},
                context_label => 'child expression',
                base_label => "child endpoint '$instance_name.$port_name'",
                fsm_file => $fsm_file,
                header => $header,
            );

            return {
                width => $resolved_width,
                connection_expr => $connection_expr,
                base_ports => [],
                child_base_sources => [$base_endpoint],
                type_spec => $resolved_type_spec,
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
            type_spec => FSM::Package::PayloadTypeSupport->scalar_type_spec_from_width(abs($spec->{msb} - $spec->{lsb}) + 1),
        };
    }

    if ($expr_kind eq 'concat') {
        my @operand_exprs;
        my @base_ports;
        my @child_base_sources;
        my @operand_type_specs;
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
            push @operand_type_specs, $class->_clone_structured_value($resolved_operand->{type_spec});
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
            type_spec => {
                kind => 'list',
                width => $width,
                signed => 0,
                items => \@operand_type_specs,
            },
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
            type_spec => {
                kind => 'list',
                width => ($spec->{repeat_count} || 0) * $resolved_operand->{width},
                signed => 0,
                items => [
                    map { $class->_clone_structured_value($resolved_operand->{type_spec}) }
                        1 .. ($spec->{repeat_count} || 0)
                ],
            },
        };
    }

    if ($expr_kind eq 'aggregate_ref') {
        my $port_name = $spec->{port_name} || '';
        my $top_port = $top_ports_by_name->{$port_name};

        confess
            "Composition source '$header' in '$fsm_file' references top expression '$endpoint', ".
            "but explicit link endpoint resolution is blocked because '?ports' declares no top port named '$port_name'. ".
            "See docs/COMPOSITION_SCOPE.md and docs/COMPOSITION_LEGACY_MAPPING.md.\n"
            unless $top_port;

        my ($connection_expr, $resolved_type_spec, $resolved_width) = $class->_resolve_aggregate_path_connection(
            base_expr => signal_ref_expr($port_name),
            root_type_spec => FSM::Composition::InterfacePortBuilder->declared_type_spec($top_port),
            path_text => $spec->{path_text},
            raw => $spec->{raw},
            context_label => 'top expression',
            base_label => "top port '$port_name'",
            fsm_file => $fsm_file,
            header => $header,
        );

        return {
            width => $resolved_width,
            connection_expr => $connection_expr,
            base_ports => [$top_port],
            child_base_sources => [],
            type_spec => $resolved_type_spec,
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
        type_spec => FSM::Package::PayloadTypeSupport->scalar_type_spec_from_width($expr_width),
    };
}

sub _endpoint_declared_or_scalar_type_spec ($class, $port) {
    my $declared_type_spec = FSM::Composition::InterfacePortBuilder->declared_type_spec($port);
    return $declared_type_spec if ref($declared_type_spec) eq 'HASH';

    my $width = ref($port) eq 'HASH' ? $port->{width} : $port->width;
    return FSM::Package::PayloadTypeSupport->scalar_type_spec_from_width($width);
}

sub _resolve_aggregate_path_connection ($class, %args) {
    my $raw = $args{raw} // '';
    my $context_label = $args{context_label} || 'expression';
    my $base_label = $args{base_label} || 'base endpoint';
    my $fsm_file = $args{fsm_file};
    my $header = $args{header};

    my $result = FSM::Composition::AggregatePathSupport->resolve(
        root_type_spec => $args{root_type_spec},
        path_text => $args{path_text},
        base_expr => $args{base_expr},
    );

    $class->_confess_aggregate_path_resolution_error(
        $result,
        raw => $raw,
        context_label => $context_label,
        base_label => $base_label,
        fsm_file => $fsm_file,
        header => $header,
    ) unless $result->{ok};

    return (
        $result->{connection_expr},
        $class->_clone_structured_value($result->{type_spec}),
        $result->{width},
    );
}

sub _confess_aggregate_path_resolution_error ($class, $error, %args) {
    my $raw = $args{raw} // '';
    my $context_label = $args{context_label} || 'expression';
    my $base_label = $args{base_label} || 'base endpoint';
    my $fsm_file = $args{fsm_file};
    my $header = $args{header};
    my $code = $error->{code} || 'unknown';

    if ($code eq 'missing_declared_type') {
        confess
            "Composition source '$header' in '$fsm_file' uses $context_label '$raw', ".
            "but explicit link endpoint resolution is blocked because $base_label has no declared aggregate type. ".
            "Declare an aggregate '+types' alias on the endpoint before using member or item access in composition links. ".
            "See docs/COMPOSITION_SCOPE.md and docs/COMPOSITION_LEGACY_MAPPING.md.\n";
    }

    if ($code eq 'empty_path') {
        confess
            "Composition source '$header' in '$fsm_file' uses $context_label '$raw', ".
            "but explicit link endpoint resolution is blocked because aggregate path resolution received an empty path. ".
            "Use record member access like '.field' and list/scalar constant indexes like '[0]'. ".
            "See docs/COMPOSITION_SCOPE.md and docs/COMPOSITION_LEGACY_MAPPING.md.\n";
    }

    if ($code eq 'scalar_root') {
        confess
            "Composition source '$header' in '$fsm_file' uses $context_label '$raw', ".
            "but explicit link endpoint resolution is blocked because $base_label has scalar type '".
            ($error->{current_type_label} || 'unknown').
            "', so aggregate member or item access is not available. ".
            "See docs/COMPOSITION_SCOPE.md and docs/COMPOSITION_LEGACY_MAPPING.md.\n";
    }

    if ($code eq 'member_on_non_record') {
        confess
            "Composition source '$header' in '$fsm_file' uses $context_label '$raw', ".
            "but explicit link endpoint resolution is blocked because member access '.".$error->{member_name}."' is only valid on record-typed values; current path type is '".
            ($error->{current_type_label} || 'unknown')."'. ".
            "Use '[N]' for list items or declare a record member before generation. ".
            "See docs/COMPOSITION_SCOPE.md and docs/COMPOSITION_LEGACY_MAPPING.md.\n";
    }

    if ($code eq 'unknown_member') {
        confess
            "Composition source '$header' in '$fsm_file' uses $context_label '$raw', ".
            "but explicit link endpoint resolution is blocked because record type for $base_label has no member '".$error->{member_name}."'. ".
            "Known members: " . join(', ', @{ $error->{known_members} || [] }) . ". ".
            "See docs/COMPOSITION_SCOPE.md and docs/COMPOSITION_LEGACY_MAPPING.md.\n";
    }

    if ($code eq 'list_range_not_supported') {
        confess
            "Composition source '$header' in '$fsm_file' uses $context_label '$raw', ".
            "but explicit link endpoint resolution is blocked because list item access currently accepts one constant index, not a range. ".
            "Select one list element with '[N]' before generation. ".
            "See docs/COMPOSITION_SCOPE.md and docs/COMPOSITION_LEGACY_MAPPING.md.\n";
    }

    if ($code eq 'list_index_out_of_range') {
        confess
            "Composition source '$header' in '$fsm_file' uses $context_label '$raw', ".
            "but explicit link endpoint resolution is blocked because list index '".$error->{index}."' is outside the declared item range 0..".
            ($error->{max_index} // -1).". ".
            "See docs/COMPOSITION_SCOPE.md and docs/COMPOSITION_LEGACY_MAPPING.md.\n";
    }

    if ($code eq 'scalar_slice_out_of_range') {
        confess
            "Composition source '$header' in '$fsm_file' uses $context_label '$raw', ".
            "but explicit link endpoint resolution is blocked because scalar slice [".$error->{high}.":".$error->{low}."] exceeds resolved scalar width '".$error->{scalar_width}."'. ".
            "See docs/COMPOSITION_SCOPE.md and docs/COMPOSITION_LEGACY_MAPPING.md.\n";
    }

    if ($code eq 'scalar_index_out_of_range') {
        confess
            "Composition source '$header' in '$fsm_file' uses $context_label '$raw', ".
            "but explicit link endpoint resolution is blocked because scalar index '".$error->{index}."' exceeds resolved scalar width '".$error->{scalar_width}."'. ".
            "See docs/COMPOSITION_SCOPE.md and docs/COMPOSITION_LEGACY_MAPPING.md.\n";
    }

    if ($code eq 'index_on_non_indexable') {
        confess
            "Composition source '$header' in '$fsm_file' uses $context_label '$raw', ".
            "but explicit link endpoint resolution is blocked because index access is valid on list and scalar bit-vector values; current path type is '".
            ($error->{current_type_label} || 'unknown')."'. ".
            "See docs/COMPOSITION_SCOPE.md and docs/COMPOSITION_LEGACY_MAPPING.md.\n";
    }

    if ($code eq 'parse_error') {
        confess
            "Composition source '$header' in '$fsm_file' uses $context_label '$raw', ".
            "but explicit link endpoint resolution is blocked because aggregate path '".($error->{remaining} || '')."' could not be parsed. ".
            "Use record member access like '.field' and list/scalar constant indexes like '[0]'. ".
            "See docs/COMPOSITION_SCOPE.md and docs/COMPOSITION_LEGACY_MAPPING.md.\n";
    }

    if ($code eq 'missing_leaf_width') {
        confess
            "Composition source '$header' in '$fsm_file' uses $context_label '$raw', ".
            "but explicit link endpoint resolution is blocked because the resolved aggregate leaf has no positive packed width. ".
            "See docs/COMPOSITION_SCOPE.md and docs/COMPOSITION_LEGACY_MAPPING.md.\n";
    }

    confess
        "Composition source '$header' in '$fsm_file' uses $context_label '$raw', ".
        "but explicit link endpoint resolution is blocked because aggregate path resolution failed unexpectedly. ".
        "See docs/COMPOSITION_SCOPE.md and docs/COMPOSITION_LEGACY_MAPPING.md.\n";
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

    return $class->_clone_structured_value($source);
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

        return $class->rebind_source_expr_with_child_carriers(
            $source->{connection_expr},
            { $source->{base_raw} => $carrier_signal_name },
        ) if (($source->{expr_kind} || '') eq 'aggregate_ref');
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

    if ($kind eq 'member_access') {
        return member_access_expr(
            $class->rebind_source_expr_with_child_carriers($expr->{source_expr}, $carrier_by_child_base_endpoint),
            $expr->{member_name},
        );
    }

    if ($kind eq 'index_access') {
        return index_access_expr(
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
                $net->add_target($target);
            }
        }
        my $binding_type_contract = $class->_binding_connection_type_contract($source, undef);
        $bindings_by_instance->{$source->{instance_name}}{$source->{port}->name} = normalized_binding({
            port_name => $source->{port}->name,
            signal_name => $existing_carrier,
            %$binding_type_contract,
        });
        return $existing_carrier;
    }

    my $net_name = $class->allocate_net_name($source, $top_ports_by_name, $existing_nets, $preferred_name);
    push @{$existing_nets || []}, FSM::Composition::Net->new(
        name => $net_name,
        width => $source->{port}->width,
        source => $source->{raw},
        targets => [grep { defined($_) && length($_) } @{$targets || []}],
        declared_type_name => FSM::Composition::InterfacePortBuilder->declared_type_name($source->{port}),
        declared_type_spec => FSM::Composition::InterfacePortBuilder->declared_type_spec($source->{port}),
    );

    $carrier_signal_by_source->{$source_key} = $net_name;
    my $binding_type_contract = $class->_binding_connection_type_contract($source, undef);
    $bindings_by_instance->{$source->{instance_name}}{$source->{port}->name} = normalized_binding({
        port_name => $source->{port}->name,
        signal_name => $net_name,
        %$binding_type_contract,
    });
    return $net_name;
}

sub actual_connection_expr_for_target ($class, $source, $target_width, $fsm_file = undef, $header = undef) {
    return FSM::Composition::ActualLiteralSupport->actual_connection_expr_for_target(
        $source,
        $target_width,
        $fsm_file,
        $header,
    );
}

sub _binding_connection_type_contract ($class, $source, $target_width = undef) {
    return {
        connection_type_name => undef,
        connection_type_spec => undef,
    } unless ref($source) eq 'HASH';

    my $kind = $source->{kind} || '';
    if ($kind =~ /^actual_/) {
        return FSM::Composition::ActualLiteralSupport->binding_connection_type_contract(
            $source,
            $target_width,
        );
    }

    if ($kind eq 'top_expr' || $kind eq 'child_expr') {
        return {
            connection_type_name => undef,
            connection_type_spec => $class->_clone_structured_value($source->{inferred_type_spec}),
        };
    }

    if ($kind eq 'top_port' || $kind eq 'child_port') {
        return {
            connection_type_name => FSM::Composition::InterfacePortBuilder->declared_type_name($source->{port}),
            connection_type_spec => $class->_clone_structured_value(
                $class->_endpoint_declared_or_scalar_type_spec($source->{port})
            ),
        };
    }

    return {
        connection_type_name => undef,
        connection_type_spec => undef,
    };
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
        parameter_overrides => $instance->parameter_overrides,
        module_info => $instance->module_info,
        hdl_code => $instance->hdl_code,
    );
}

sub _clone_structured_value ($class, $value) {
    return undef unless defined $value;

    if (ref($value) eq 'HASH') {
        return {
            map { $_ => $class->_clone_structured_value($value->{$_}) }
                keys %$value
        };
    }

    if (ref($value) eq 'ARRAY') {
        return [map { $class->_clone_structured_value($_) } @$value];
    }

    return $value;
}

1;

__END__

=head1 METHODS

=head2 build_from_wiring_blocks

Builds a linked composition plan after validating that the active lane has at
least one explicit C<?wiring> entry.

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
