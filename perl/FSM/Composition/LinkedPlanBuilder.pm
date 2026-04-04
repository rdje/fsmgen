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

    for my $link (@resolved_links_input) {
        my $source = $class->resolve_endpoint(
            $link->source,
            $top_ports_by_name,
            \%instances_by_name,
            \%child_ports_by_instance,
            $fsm_file,
            $header,
            allow_top_expression_source => 1,
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
            if (($source->{kind} || '') eq 'top_expr') {
                confess
                    "Composition source '$header' in '$fsm_file' links top expression '".$source->{raw}."' directly to top output '".$target->{raw}."', ".
                    "but explicit-link topology is blocked because the current active $lane lane only supports top inputs driving child inputs. ".
                    "See docs/COMPOSITION_SCOPE.md and docs/COMPOSITION_LEGACY_MAPPING.md.\n"
                    if $target->{kind} eq 'top_port';

                for my $top_port_name (@{$source->{base_port_names} || []}) {
                    $top_port_usage{$top_port_name}{source} = 1;
                }
            }

            $bindings_by_instance{$target->{instance_name}}{$target->{port}->name} = normalized_binding({
                port_name => $target->{port}->name,
                connection_expr => $source->{connection_expr},
            });
            push @resolved_links, {
                link => $link,
                source => $source,
                target => $target,
            };
            next;
        }

        my $source_key = $source->{key};
        $source_endpoint_by_key{$source_key} = $source;
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

    my @nets;
    my @auxiliary_assignments;
    my %carrier_signal_by_source;

    for my $source_key (sort keys %links_by_source) {
        my $source = $source_endpoint_by_key{$source_key};
        my @group = @{$links_by_source{$source_key}};

        if ($source->{kind} eq 'top_port') {
            for my $resolved_link (@group) {
                confess
                    "Composition source '$header' in '$fsm_file' links top input '".$source->{raw}."' directly to top output '".$resolved_link->{target}{raw}."', ".
                    "but explicit-link topology is blocked because the current active $lane lane only supports top inputs driving child inputs. ".
                    "See docs/COMPOSITION_SCOPE.md and docs/COMPOSITION_LEGACY_MAPPING.md.\n"
                    if $resolved_link->{target}{kind} eq 'top_port';
            }
            $carrier_signal_by_source{$source_key} = $source->{port}->name;
            next;
        }

        my @top_output_targets = grep { $_->{target}{kind} eq 'top_port' } @group;

        my $carrier_signal_name;
        if (@top_output_targets == 1) {
            $carrier_signal_name = $top_output_targets[0]{target}{port}->name;
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

            my $net_name = $class->allocate_net_name($source, $top_ports_by_name, \@nets, $preferred_net_name);
            push @nets, FSM::Composition::Net->new(
                name => $net_name,
                width => $source->{port}->width,
                source => $source->{raw},
                targets => [map { $_->{target}{raw} } @group],
            );
            $carrier_signal_name = $net_name;

            for my $top_output_target (@top_output_targets) {
                push @auxiliary_assignments, "    assign ".$top_output_target->{target}{port}->name." = $carrier_signal_name;";
            }
        }
        $carrier_signal_by_source{$source_key} = $carrier_signal_name;
        $bindings_by_instance{$source->{instance_name}}{$source->{port}->name} = $carrier_signal_name;
    }

    for my $resolved_link (@resolved_links) {
        my $source = $resolved_link->{source};
        my $target = $resolved_link->{target};
        next if (($source->{kind} || '') =~ /^actual_/ || ($source->{kind} || '') eq 'top_expr');
        my $carrier_signal_name = $carrier_signal_by_source{$source->{key}};

        if ($source->{kind} eq 'top_port') {
            $top_port_usage{$source->{port}->name}{source} = 1;
        }

        if ($target->{kind} eq 'top_port') {
            $top_port_usage{$target->{port}->name}{target} = 1;
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
            $fsm_file,
            $header,
        )) {
            return $top_expression_endpoint;
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
        "The current active composition lanes accept only top-port names, source-side top-port bit/slice expressions like 'data_bus[3]' or 'data_bus[7:4]', or 'instance.port' child endpoints. ".
        "See docs/COMPOSITION_SCOPE.md and docs/COMPOSITION_LEGACY_MAPPING.md.\n";
}

sub assert_link_roles ($class, $source, $target, $fsm_file, $header) {
    if (($target->{kind} || '') =~ /^actual_/) {
        confess
            "Composition source '$header' in '$fsm_file' uses actual endpoint '".$target->{raw}."' as an explicit link target, ".
            "but explicit actual binding is blocked because the first structural-actual slice only allows '=open' and exact-width binary, decimal, or hex literal actuals as link sources into realized child input ports. ".
            "See docs/COMPOSITION_SCOPE.md and docs/COMPOSITION_LEGACY_MAPPING.md.\n";
    }

    if (($source->{kind} || '') =~ /^actual_/) {
        confess
            "Composition source '$header' in '$fsm_file' uses actual source '".$source->{raw}."' as an explicit link source, ".
            "but explicit actual binding is blocked because the first structural-actual slice only allows actual sources to target realized child input ports. ".
            "See docs/COMPOSITION_SCOPE.md and docs/COMPOSITION_LEGACY_MAPPING.md.\n"
            unless $target->{kind} eq 'child_port' && $target->{port}->direction eq 'input';

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
            "but explicit link is blocked because top expressions currently target only realized child input ports. ".
            "See docs/COMPOSITION_SCOPE.md and docs/COMPOSITION_LEGACY_MAPPING.md.\n"
            unless $target->{kind} eq 'child_port' && $target->{port}->direction eq 'input';

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

sub _actual_literal_bits_and_width ($class, $payload, $fsm_file, $header) {
    if ($payload =~ /\A([01])\z/) {
        return ($1, 1);
    }

    if ($payload =~ /\A(\d+)'b([01]+)\z/i) {
        my ($declared_width, $bits) = ($1, $2);
        confess
            "Composition source '$header' in '$fsm_file' uses actual literal '=$payload', ".
            "but explicit actual binding is blocked because the declared binary width does not match the literal payload length. ".
            "See docs/COMPOSITION_SCOPE.md and docs/COMPOSITION_LEGACY_MAPPING.md.\n"
            unless length($bits) == $declared_width;
        return ($bits, 0 + $declared_width);
    }

    if ($payload =~ /\A(\d+)'d(\d+)\z/i) {
        my ($declared_width, $decimal_digits) = ($1, $2);
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

    if ($payload =~ /\A(\d+)'h([0-9a-f]+)\z/i) {
        my ($declared_width, $hex_digits) = ($1, $2);
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

    confess
        "Composition source '$header' in '$fsm_file' uses actual endpoint '=$payload', ".
        "but explicit actual binding is blocked because the first structural-actual slice currently accepts only '=open', '=0', '=1', or exact-width binary/decimal/hex literal forms like '=8'b10100101', '=8'd165', or '=8'hA5'. ".
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

sub _resolve_top_expression_endpoint ($class, $endpoint, $top_ports_by_name, $fsm_file, $header) {
    my $spec = $class->top_expression_spec($endpoint);
    if (!$spec && defined($endpoint) && ($endpoint =~ /\A\{.*\}\z/s || index($endpoint, ',') >= 0)) {
        confess
            "Composition source '$header' in '$fsm_file' uses top expression '$endpoint', ".
            "but explicit link endpoint resolution is blocked because concat operands currently accept only top-port names, top-port bit/slice forms, and fixed-width literal actuals like '=4'b1010', '=4'd10', or '=4'hA'. ".
            "See docs/COMPOSITION_SCOPE.md and docs/COMPOSITION_LEGACY_MAPPING.md.\n";
    }
    return undef unless $spec;
    my $resolved_spec = $class->_resolve_top_expression_spec(
        $spec,
        $top_ports_by_name,
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

    return [];
}

sub _parse_top_expression_spec ($class, $endpoint, %opts) {
    return undef unless defined($endpoint) && length($endpoint);

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

    if ($endpoint =~ /\A(\w+)\[(\d+)\]\z/) {
        return {
            raw => $endpoint,
            port_name => $1,
            expr_kind => 'bit_select',
            index => 0 + $2,
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

    if (defined($payload) && $payload =~ /\A(\d+)'b([01]+)\z/i) {
        my ($declared_width, $bits) = ($1, $2);
        return undef unless length($bits) == $declared_width;
        return ($bits, 0 + $declared_width);
    }

    if (defined($payload) && $payload =~ /\A(\d+)'d(\d+)\z/i) {
        return $class->_decimal_literal_bits_and_width($1, $2);
    }

    if (defined($payload) && $payload =~ /\A(\d+)'h([0-9a-f]+)\z/i) {
        return $class->_hex_literal_bits_and_width($1, $2);
    }

    return;
}

sub _decimal_literal_bits_and_width ($class, $declared_width, $decimal_digits, %opts) {
    return unless defined($declared_width) && $declared_width =~ /\A\d+\z/ && $declared_width > 0;
    return unless defined($decimal_digits) && !ref($decimal_digits) && $decimal_digits =~ /\A\d+\z/;

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

sub _hex_literal_bits_and_width ($class, $declared_width, $hex_digits, %opts) {
    return unless defined($declared_width) && $declared_width =~ /\A\d+\z/ && $declared_width > 0;
    return unless defined($hex_digits) && !ref($hex_digits) && $hex_digits =~ /\A[0-9a-f]+\z/i;

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

sub _resolve_top_expression_spec ($class, $spec, $top_ports_by_name, $endpoint, $fsm_file, $header) {
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
        };
    }

    if ($expr_kind eq 'literal') {
        return {
            width => $spec->{width},
            connection_expr => bit_vector_literal_expr($spec->{bits}),
            base_ports => [],
        };
    }

    if ($expr_kind eq 'concat') {
        my @operand_exprs;
        my @base_ports;
        my %seen_port_name;
        my $width = 0;

        for my $operand_spec (@{$spec->{operands} || []}) {
            my $resolved_operand = $class->_resolve_top_expression_spec(
                $operand_spec,
                $top_ports_by_name,
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
        }

        return {
            width => $width,
            connection_expr => concat_expr(@operand_exprs),
            base_ports => \@base_ports,
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
    };
}

sub endpoint_width ($class, $endpoint) {
    my $port = ref($endpoint) eq 'HASH' ? $endpoint->{port} : undef;
    return 0 unless $port;
    return $port->{width} if ref($port) eq 'HASH';
    return $port->width if ref($port) && $port->can('width');
    return 0;
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
