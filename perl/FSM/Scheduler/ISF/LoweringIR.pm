package FSM::Scheduler::ISF::LoweringIR;

use v5.20;
use strict;
use warnings;
use feature qw(signatures postderef);
no warnings 'experimental::signatures';
use POSIX qw(log);
use Carp qw(confess);
use FSM::Package::IntegerLiteralSupport;

sub new($class, %args) { bless { debug => ($args{debug} // 0) }, $class }

my %SUPPORTED_TRANSACTION_CLAUSES = (
    transaction => {
        map { $_ => 1 } qw(
            on drive await sample update phase shift_left shift_right assemble
            extract complete when switch repeat latency do spawn await_all
            await_any params stage contract store load wait while until set
            atl_trigger atl_trigger_batch
        )
    },
    when => {
        map { $_ => 1 } qw(
            drive await sample complete repeat update set shift_left shift_right
            assemble extract when store load wait
        )
    },
    switch => {
        map { $_ => 1 } qw(
            drive await sample repeat update set shift_left shift_right assemble
            extract when store load wait
        )
    },
    repeat => {
        map { $_ => 1 } qw(
            drive await sample update set shift_left shift_right assemble extract
            store load wait do spawn await_all await_any
        )
    },
    while => {
        map { $_ => 1 } qw(
            drive await sample complete repeat update set shift_left shift_right
            assemble extract when store load wait
        )
    },
    until => {
        map { $_ => 1 } qw(
            drive await sample complete repeat update set shift_left shift_right
            assemble extract when store load wait
        )
    },
);

my %TRANSACTION_CONTEXT_LABEL = (
    transaction => 'transaction body',
    when        => 'when body',
    switch      => 'switch branch',
    repeat      => 'repeat body',
    while       => 'while body',
    until       => 'until body',
);

sub build_module($self, $actor) {
    my $domain_partition = $self->_build_domain_partition($actor);
    $self->_validate_child_transaction_refs($actor);
    $self->_validate_activation_domain_names($actor);
    my %generated_children = $self->_collect_generated_child_transaction_refs($actor);
    $self->_validate_transaction_parameter_clauses($actor, \%generated_children);
    $self->_validate_transaction_port_bindings($actor);

    my %child_irs;
    for my $cname (sort keys %generated_children) {
        my ($ct) = grep { $_->{name} eq $cname } @{$actor->{transactions}};
        next unless $ct;
        $child_irs{$cname} = $self->_build_child_ir($ct, $actor, $cname);
    }

    my @library_instances;
    for my $use (@{$actor->{library_uses} || []}) {
        my $module = $use->{module};
        confess "Library use '$use->{instance}' is missing a generated module name\n"
            unless defined($module) && !ref($module) && length($module);
        confess "Library use '$use->{instance}' generated module '$module' conflicts with another generated child\n"
            if exists $child_irs{$module};
        $child_irs{$module} = $self->_build_library_child_ir($use, $actor);
        push @library_instances, _library_instance_metadata($use);
    }

    for my $resolution (_resolved_atl_actor_type_resolutions($actor)) {
        my $instance = $resolution->{instance};
        confess "ATL static actor instance resolution is missing an instance name\n"
            unless defined($instance) && !ref($instance) && length($instance);

        my $module = $resolution->{module};
        confess "ATL static actor instance '$instance' is missing a generated module name\n"
            unless defined($module) && !ref($module) && length($module);
        confess "ATL static actor instance '$instance' generated module '$module' conflicts with another generated child\n"
            if exists $child_irs{$module};

        $child_irs{$module} = $self->_build_resolved_atl_child_ir($resolution, $actor);
    }

    my @atl_top_instances = $self->_select_atl_generated_top_instances($actor, \%child_irs);
    _mark_atl_data_link_child_interface_ports(\%child_irs, \@atl_top_instances);

    my $parent_ir = $self->_build_parent_ir($actor, \%generated_children);
    $parent_ir->{children} = \%child_irs;
    $parent_ir->{library_uses} = \@library_instances;
    $parent_ir->{atl_top_instances} = \@atl_top_instances;
    if (@atl_top_instances) {
        $parent_ir->{actor_network}{generated_tops} = [
            map { _atl_generated_top_report_entry($_) } @atl_top_instances
        ];
    }
    $parent_ir->{domain_partition} = $domain_partition if $domain_partition;
    return $parent_ir;
}

# --- Child IR (separate module) ---

sub _build_child_ir($self, $tx, $actor, $cname) {
    my ($states, $ctrs, $dts, $do_children, $spawn_refs, $contracts, $signal_widths, $storage_roles, $bank_accesses) =
        $self->_build_transaction($tx, $actor, 0);
    $states = [@$states]; $ctrs = { %$ctrs }; $dts = [@$dts];
    my %module_signal_widths = _declared_storage_signal_widths($actor);
    my %module_storage_roles = _declared_storage_roles($actor);
    my %module_signal_type_refs = (
        _actor_interface_signal_type_refs($actor),
        _declared_storage_signal_type_refs($actor),
        _transaction_port_signal_type_refs($tx),
    );
    _merge_signal_widths(\%module_signal_widths, $signal_widths, $tx->{name});
    _merge_storage_roles(\%module_storage_roles, $storage_roles, $tx->{name});

    my %used_drives = _collect_named_drive_call_names($tx->{clauses}, $actor->{drives} || {});
    _register_drive_call_signal_widths($actor, $ctrs, \%used_drives, \%module_storage_roles);

    my $ports = $self->_build_child_ports($actor, $tx, $states, $dts, \%used_drives);

    my $ir = {
        actor_name => $cname,
        clock      => $actor->{clock},
        reset      => $actor->{reset},
        watchdog   => $actor->{watchdog},
        actor_phases => _actor_metadata_declarations($actor, 'phases'),
        actor_stages => _actor_metadata_declarations($actor, 'stages'),
        package_imports => _actor_package_imports($actor),
        package_roots => _actor_package_roots($actor),
        type_declarations => _actor_type_declarations($actor),
        enum_declarations => _actor_enum_declarations($actor),
        constants  => _actor_constant_declarations($actor),
        params     => _transaction_param_declarations($tx, $actor),
        ports      => $ports,
        states     => $states,
        dt_blocks  => $dts,
        counters   => $ctrs,
        declared_storage => _declared_storage_for_ir($actor),
        signal_widths => \%module_signal_widths,
        signal_type_refs => \%module_signal_type_refs,
        storage_roles => \%module_storage_roles,
        children   => {},
        temporal_contracts => $contracts,
        bank_accesses => $bank_accesses,
    };

    # Inject entry state if missing (spawn targets need start handshake)
    if (!grep { $_->{kind} eq 'entry' } @{$ir->{states}}) {
        unshift @{$ir->{states}}, {
            name        => "${cname}_idle_0",
            kind        => 'entry',
            guard       => { port => 'start' },
            assignments => [],
            transitions => [],
        };
        # Link idle -> first state
        $ir->{states}[0]{transitions} = [{ target => $ir->{states}[1]{name}, condition => $ir->{states}[0]{guard} }];
    }

    my ($entry) = grep { $_->{kind} eq 'entry' } @{$ir->{states}};
    if ($entry) {
        $entry->{guard} = { port => 'start' };
        $entry->{transitions} = [];
        my ($n) = grep { $_->{kind} ne 'entry' && $_->{name} !~ /_timeout$/ } @{$ir->{states}};
        push @{$entry->{transitions}}, { target => $n->{name}, condition => $entry->{guard} } if $n;

        for my $state (@{$ir->{states}}) {
            next unless $state->{kind} eq 'terminal';
            $state->{transitions} = [{ target => $entry->{name} }];
        }
    }
    _finalize_ir($ir);
    return $ir;
}

sub _build_library_child_ir($self, $use, $parent_actor) {
    my $child_actor = _clone_isf_value($use->{actor});
    confess "Library use '$use->{instance}' does not carry a reusable actor shell\n"
        unless ref($child_actor) eq 'HASH';

    $child_actor->{actor_name} = $use->{module};
    my $ir = $self->_build_parent_ir($child_actor, {});
    $ir->{library_origin} = {
        parent_actor   => $parent_actor->{actor_name},
        library        => $use->{library},
        export         => $use->{export},
        instance       => $use->{instance},
        library_source => $use->{library_source},
    };
    return $ir;
}

sub _build_resolved_atl_child_ir($self, $resolution, $parent_actor) {
    my $child_actor = _clone_isf_value($resolution->{actor});
    confess "ATL static actor instance '$resolution->{instance}' does not carry a resolved actor shell\n"
        unless ref($child_actor) eq 'HASH';

    $child_actor->{actor_name} = $resolution->{module};
    my $ir = $self->_build_parent_ir($child_actor, {});
    $ir->{library_origin} = {
        parent_actor   => $parent_actor->{actor_name},
        library        => $resolution->{library},
        export         => $resolution->{export},
        instance       => $resolution->{instance},
        library_source => $resolution->{library_source},
        usage          => 'atl_static_instance',
    };
    return $ir;
}

sub _select_atl_generated_top_instances($self, $actor, $child_irs) {
    my @resolutions = _resolved_atl_actor_type_resolutions($actor);
    return () unless @resolutions;

    my $network = $actor->{actor_network} || {};
    my @triggers = @{$network->{transaction_triggers} || []};
    my @event_waits = @{$network->{event_waits} || []};
    my @data_movements = @{$network->{data_movements} || []};
    return () unless @triggers || @event_waits;

    my $actor_name = $actor->{actor_name};
    my $context = "ATL generated top for actor '$actor_name'";

    confess "$context cannot combine generated child wiring with static group metadata in the current subset\n"
        if @{$network->{groups} || []};
    confess "$context cannot combine generated child wiring with temporary association or group schedules in the current subset\n"
        if @{$network->{association_schedules} || []} || @{$network->{group_schedules} || []};

    my $top_module = "${actor_name}_top";
    confess "$context generated top module '$top_module' conflicts with a generated child module\n"
        if exists $child_irs->{$top_module};

    if (@resolutions == 2 && @triggers == 2 && @event_waits == 2 && !@data_movements) {
        my %resolution_by_instance = map { $_->{instance} => $_ } @resolutions;
        my %seen_instance;
        my @children;
        for my $index (0 .. 1) {
            my $trigger = $triggers[$index];
            my $event_wait = $event_waits[$index];
            my $instance = $trigger->{instance};
            confess "$context two-child handoff pair requires trigger and event to target the same resolved actor instance\n"
                unless defined($instance)
                    && length($instance)
                    && ($event_wait->{instance} // '') eq $instance;
            confess "$context two-child handoff sequence targets instance '$instance' more than once in the current subset\n"
                if $seen_instance{$instance}++;
            confess "$context cannot find resolved actor metadata for child instance '$instance'\n"
                unless exists $resolution_by_instance{$instance};
            push @children, _atl_generated_top_child_entry(
                $context,
                $actor,
                $child_irs,
                $resolution_by_instance{$instance},
                $trigger,
                $event_wait,
                [],
            );
        }

        return ({
            kind                 => 'resolved_children_trigger_event_sequence',
            top_module           => $top_module,
            top_fsm              => "$top_module.fsm",
            parent_module        => $actor_name,
            parent_scheduled_fsm => "$actor_name.fsm",
            children             => \@children,
            clock                => $actor->{clock},
            reset                => ref($actor->{reset}) eq 'HASH' ? $actor->{reset}{name} : undef,
        });
    }

    if (@resolutions == 2
        && @data_movements == 1
        && ($data_movements[0]{kind} // '') eq 'scalar_actor_handoff'
        && (@triggers >= 2 || @event_waits >= 2))
    {
        confess "$context two-child data route requires exactly one transaction trigger per source and sink child in the current subset; repeated activation remains deferred\n"
            unless @triggers == 2;
        confess "$context two-child data route requires exactly one event wait per source and sink child in the current subset; repeated waits remain deferred\n"
            unless @event_waits == 2;

        my $movement = $data_movements[0];
        my @ordered_instances = ($movement->{source_instance}, $movement->{sink_instance});
        my %resolution_by_instance = map { $_->{instance} => $_ } @resolutions;
        my %seen_instance;
        my @child_specs;
        my @route_owners = ($movement->{transaction});
        my @children;

        for my $instance (@ordered_instances) {
            confess "$context two-child data route references an empty child instance name\n"
                unless defined($instance) && length($instance);
            confess "$context two-child data route targets instance '$instance' more than once in the current subset\n"
                if $seen_instance{$instance}++;
            confess "$context cannot find resolved actor metadata for data-route child instance '$instance'\n"
                unless exists $resolution_by_instance{$instance};

            my $trigger = _single_atl_entry_for_instance($context, \@triggers, $instance, 'transaction trigger');
            my $event_wait = _single_atl_entry_for_instance($context, \@event_waits, $instance, 'event wait');
            push @route_owners, $trigger->{owner_transaction}, $event_wait->{transaction};
            push @child_specs, [
                $resolution_by_instance{$instance},
                $trigger,
                $event_wait,
            ];
        }

        my %route_owners = map { $_ => 1 }
            grep { defined($_) && !ref($_) && length($_) } @route_owners;
        confess "$context two-child data route requires source trigger, source event wait, data drive call, sink trigger, and sink event wait to belong to one parent transaction in the current subset; cross-transaction route continuation remains deferred\n"
            if keys(%route_owners) > 1;

        for my $child_spec (@child_specs) {
            push @children, _atl_generated_top_child_entry(
                $context,
                $actor,
                $child_irs,
                $child_spec->[0],
                $child_spec->[1],
                $child_spec->[2],
                \@data_movements,
            );
        }

        return ({
            kind                 => 'resolved_children_trigger_event_sequence',
            top_module           => $top_module,
            top_fsm              => "$top_module.fsm",
            parent_module        => $actor_name,
            parent_scheduled_fsm => "$actor_name.fsm",
            children             => \@children,
            clock                => $actor->{clock},
            reset                => ref($actor->{reset}) eq 'HASH' ? $actor->{reset}{name} : undef,
        });
    }

    confess "$context requires exactly one resolved ATL static actor instance in the current subset\n"
        unless @resolutions == 1;
    confess "$context requires exactly one transaction trigger and exactly one event wait in the current subset\n"
        unless @triggers == 1 && @event_waits == 1;

    my $resolution = $resolutions[0];
    my $instance = $resolution->{instance};
    my $module = $resolution->{module};
    my $trigger = $triggers[0];
    my $event_wait = $event_waits[0];

    confess "$context requires trigger and event handoffs to target the same resolved actor instance '$instance'\n"
        unless ($trigger->{instance} // '') eq $instance
            && ($event_wait->{instance} // '') eq $instance;
    confess "$context requires trigger and event handoffs to belong to the same parent transaction\n"
        unless ($trigger->{owner_transaction} // '') eq ($event_wait->{transaction} // '');
    confess "$context expects the selected trigger sink to be an external handoff before top wiring\n"
        unless ($trigger->{sink} // '') eq 'external_handoff';
    confess "$context expects the selected event source to be an external handoff before top wiring\n"
        unless ($event_wait->{source} // '') eq 'external_handoff';

    my $child = _atl_generated_top_child_entry(
        $context,
        $actor,
        $child_irs,
        $resolution,
        $trigger,
        $event_wait,
        \@data_movements,
    );

    return ({
        kind                 => 'resolved_child_trigger_event_handoff',
        top_module           => $top_module,
        top_fsm              => "$top_module.fsm",
        parent_module        => $actor_name,
        parent_scheduled_fsm => "$actor_name.fsm",
        instance             => $child->{instance},
        child_module         => $child->{child_module},
        child_scheduled_fsm  => $child->{child_scheduled_fsm},
        target_transaction   => $child->{target_transaction},
        trigger_parent_port  => $child->{trigger_parent_port},
        trigger_child_port   => $child->{trigger_child_port},
        event                => $child->{event},
        event_parent_port    => $child->{event_parent_port},
        event_child_port     => $child->{event_child_port},
        data_links           => $child->{data_links},
        clock                => $actor->{clock},
        reset                => ref($actor->{reset}) eq 'HASH' ? $actor->{reset}{name} : undef,
    });
}

sub _single_atl_entry_for_instance {
    my ($context, $entries, $instance, $label) = @_;
    my @matches = grep { ($_->{instance} // '') eq ($instance // '') } @{$entries || []};
    confess "$context two-child handoff sequence requires exactly one $label for child instance '$instance'\n"
        unless @matches == 1;
    return $matches[0];
}

sub _atl_generated_top_child_entry {
    my ($context, $actor, $child_irs, $resolution, $trigger, $event_wait, $data_movements) = @_;
    my $instance = $resolution->{instance};
    my $module = $resolution->{module};

    confess "$context cannot find resolved child module '$module'\n"
        unless exists $child_irs->{$module};

    my $child_actor = $resolution->{actor};
    confess "$context child instance '$instance' does not carry a resolved actor shell\n"
        unless ref($child_actor) eq 'HASH';
    confess "$context child instance '$instance' contains nested actor-network instances; recursive actor networks are deferred\n"
        if @{(($child_actor->{actor_network} || {})->{instances}) || []};
    confess "$context requires parent and child clocks to match before ATL child wiring; parent '$actor->{clock}' child '$child_actor->{clock}'\n"
        unless ($actor->{clock} // '') eq ($child_actor->{clock} // '');
    confess "$context requires parent and child reset policy to match before ATL child wiring\n"
        unless _atl_reset_signature($actor->{reset}) eq _atl_reset_signature($child_actor->{reset});

    my %child_tx_by_name = map { $_->{name} => $_ } @{$child_actor->{transactions} || []};
    my $target_transaction = $trigger->{target_transaction};
    my $child_tx = $child_tx_by_name{$target_transaction};
    confess "$context trigger targets missing child transaction '$target_transaction' on instance '$instance'\n"
        unless ref($child_tx) eq 'HASH';
    my $child_start_port = _atl_transaction_scalar_on_signal($child_tx, $context);

    my $child_ir = $child_irs->{$module};
    _ensure_atl_child_data_source_ports(
        $context,
        $instance,
        $child_ir,
        $child_actor,
        $data_movements,
    );
    my %child_ports = map { $_->{name} => $_ } @{$child_ir->{ports} || []};
    confess "$context child transaction '$target_transaction' scalar on signal '$child_start_port' is not a scalar child input port\n"
        unless exists($child_ports{$child_start_port})
            && ($child_ports{$child_start_port}{direction} || '') eq 'input'
            && ($child_ports{$child_start_port}{width} || 1) == 1;

    my $event_port = $event_wait->{event};
    confess "$context event '$event_port' is not a scalar child output port on instance '$instance'\n"
        unless exists($child_ports{$event_port})
            && ($child_ports{$event_port}{direction} || '') eq 'output'
            && ($child_ports{$event_port}{width} || 1) == 1;

    my @data_links = _atl_generated_top_data_links(
        $context,
        $instance,
        $trigger,
        $event_wait,
        $data_movements,
        \%child_ports,
    );

    return {
        instance             => $instance,
        child_module         => $module,
        child_scheduled_fsm  => "$module.fsm",
        target_transaction   => $target_transaction,
        trigger_parent_port  => $trigger->{signal},
        trigger_child_port   => $child_start_port,
        event                => $event_port,
        event_parent_port    => $event_wait->{signal},
        event_child_port     => $event_port,
        data_links           => \@data_links,
    };
}

sub _atl_generated_top_report_entry {
    my ($top) = @_;
    my $entry = {
        kind                 => $top->{kind},
        top_module           => $top->{top_module},
        top_fsm              => $top->{top_fsm},
        parent_module        => $top->{parent_module},
        parent_scheduled_fsm => $top->{parent_scheduled_fsm},
        clock                => $top->{clock},
        reset                => $top->{reset},
    };

    if (ref($top->{children}) eq 'ARRAY' && @{$top->{children}}) {
        $entry->{children} = [
            map {
                {
                    instance             => $_->{instance},
                    child_module         => $_->{child_module},
                    child_scheduled_fsm  => $_->{child_scheduled_fsm},
                    target_transaction   => $_->{target_transaction},
                    trigger_parent_port  => $_->{trigger_parent_port},
                    trigger_child_port   => $_->{trigger_child_port},
                    event                => $_->{event},
                    event_parent_port    => $_->{event_parent_port},
                    event_child_port     => $_->{event_child_port},
                }
            } @{$top->{children}}
        ];
        return $entry;
    }

    return {
        %$entry,
        instance             => $top->{instance},
        child_module         => $top->{child_module},
        child_scheduled_fsm  => $top->{child_scheduled_fsm},
        target_transaction   => $top->{target_transaction},
        trigger_parent_port  => $top->{trigger_parent_port},
        trigger_child_port   => $top->{trigger_child_port},
        event                => $top->{event},
        event_parent_port    => $top->{event_parent_port},
        event_child_port     => $top->{event_child_port},
    };
}

sub _mark_atl_data_link_child_interface_ports {
    my ($child_irs, $atl_top_instances) = @_;
    return unless ref($child_irs) eq 'HASH' && ref($atl_top_instances) eq 'ARRAY';

    for my $top (@$atl_top_instances) {
        next unless ref($top) eq 'HASH';
        my @children = ref($top->{children}) eq 'ARRAY' && @{$top->{children}}
            ? @{$top->{children}}
            : ($top);

        for my $child (@children) {
            my $child_module = $child->{child_module};
            my $child_ir = $child_irs->{$child_module};
            next unless ref($child_ir) eq 'HASH';

            my %port_by_name = map { $_->{name} => $_ } @{$child_ir->{ports} || []};
            my %already = map { $_->{name} => 1 } @{$child_ir->{explicit_interface_ports} || []};
            for my $data_link (@{$child->{data_links} || []}) {
                for my $child_endpoint (qw(child_sink_port child_source_port)) {
                    my $child_port = $data_link->{$child_endpoint};
                    next unless defined($child_port) && !ref($child_port) && length($child_port);
                    next if $already{$child_port}++;

                    my $port = $port_by_name{$child_port};
                    next unless ref($port) eq 'HASH';
                    push @{$child_ir->{explicit_interface_ports}}, {
                        name      => $port->{name},
                        direction => $port->{direction},
                        width     => $port->{width} || 1,
                    };
                }
            }
        }
    }
}

sub _ensure_atl_child_data_source_ports {
    my ($context, $instance, $child_ir, $child_actor, $data_movements) = @_;
    return unless ref($child_ir) eq 'HASH' && ref($child_actor) eq 'HASH';

    my %declared_outputs = map {
        $_->{name} => $_
    } @{($child_actor->{interface} || {})->{outputs} || []};
    my %seen = map { $_->{name} => 1 } @{$child_ir->{ports} || []};

    for my $movement (@{$data_movements || []}) {
        next unless (($movement->{kind} // '') eq 'scalar_actor_to_pin_handoff'
                || ($movement->{kind} // '') eq 'scalar_actor_handoff')
            && ($movement->{source_instance} // '') eq $instance;

        my $port_name = $movement->{source_endpoint};
        my $width = $movement->{width} || 1;
        my $declared = defined($port_name) && !ref($port_name)
            ? $declared_outputs{$port_name}
            : undef;
        my $instance_role = ($movement->{kind} // '') eq 'scalar_actor_handoff'
            ? 'source instance'
            : 'instance';
        confess "$context data movement '$movement->{drive}' requires a scalar child output port '$port_name' on $instance_role '$instance'\n"
            unless ref($declared) eq 'HASH'
                && ($declared->{width} || 1) == $width
                && $width == 1;

        _push_port($child_ir->{ports}, \%seen, $port_name, 'output', $width)
            unless $seen{$port_name};
    }
}

sub _atl_generated_top_data_links($context, $instance, $trigger, $event_wait, $data_movements, $child_ports) {
    my @movements = @{$data_movements || []};
    return () unless @movements;

    confess "$context supports at most one scalar pin-to/from-resolved-child data movement in the current subset\n"
        unless @movements == 1;

    my $movement = $movements[0];
    confess "$context data movement must belong to the same parent transaction as the trigger/event handoffs\n"
        unless ($movement->{transaction} // '') eq ($trigger->{owner_transaction} // '')
            && ($movement->{transaction} // '') eq ($event_wait->{transaction} // '');
    confess "$context data movement must be activated from a transaction body drive call in the current subset\n"
        unless ($movement->{context} // '') eq 'transaction_body'
            && defined($movement->{drive})
            && length($movement->{drive});
    confess "$context data movement must be a drive-call-cycle route without inserted storage\n"
        unless ($movement->{route_lifetime} // '') eq 'drive_call_cycle'
            && ($movement->{storage} // '') eq 'none';

    my $width = $movement->{width} || 1;
    confess "$context data movement '$movement->{drive}' must be scalar width 1 in the current subset\n"
        unless $width == 1;

    if (($movement->{kind} // '') eq 'scalar_pin_to_actor_handoff') {
        confess "$context can only wire scalar top-level input pin to resolved child input data movement when source is a top-level pin\n"
            unless ($movement->{source} // '') eq 'top_level_pin'
                && ($movement->{sink} // '') eq 'external_handoff'
                && ($movement->{source_instance} // '') eq 'pins';
        confess "$context data movement must target resolved actor instance '$instance'\n"
            unless ($movement->{sink_instance} // '') eq $instance;

        my $child_port = $movement->{sink_endpoint};
        confess "$context data movement '$movement->{drive}' requires a scalar child input port '$child_port' on instance '$instance'\n"
            unless defined($child_port)
                && !ref($child_port)
                && exists($child_ports->{$child_port})
                && ($child_ports->{$child_port}{direction} || '') eq 'input'
                && ($child_ports->{$child_port}{width} || 1) == $width;

        my $parent_port = $movement->{sink_signal};
        my $top_port = $movement->{source_signal};
        confess "$context data movement '$movement->{drive}' requires generated parent sink handoff and top source pin signals\n"
            unless _non_empty_scalar($parent_port) && _non_empty_scalar($top_port);

        return ({
            kind             => 'scalar_pin_to_resolved_child_handoff',
            drive            => $movement->{drive},
            top_source_port  => $top_port,
            parent_sink_port => $parent_port,
            child_sink_port  => $child_port,
            width            => $width,
        });
    }

    if (($movement->{kind} // '') eq 'scalar_actor_to_pin_handoff') {
        confess "$context can only wire scalar resolved child output to top-level output pin data movement when sink is a top-level pin\n"
            unless ($movement->{source} // '') eq 'external_handoff'
                && ($movement->{sink} // '') eq 'top_level_pin'
                && ($movement->{sink_instance} // '') eq 'pins';
        confess "$context data movement must source from resolved actor instance '$instance'\n"
            unless ($movement->{source_instance} // '') eq $instance;

        my $child_port = $movement->{source_endpoint};
        confess "$context data movement '$movement->{drive}' requires a scalar child output port '$child_port' on instance '$instance'\n"
            unless defined($child_port)
                && !ref($child_port)
                && exists($child_ports->{$child_port})
                && ($child_ports->{$child_port}{direction} || '') eq 'output'
                && ($child_ports->{$child_port}{width} || 1) == $width;

        my $parent_port = $movement->{source_signal};
        my $top_port = $movement->{sink_signal};
        confess "$context data movement '$movement->{drive}' requires generated parent source handoff and top sink pin signals\n"
            unless _non_empty_scalar($parent_port) && _non_empty_scalar($top_port);

        return ({
            kind               => 'scalar_resolved_child_to_pin_handoff',
            drive              => $movement->{drive},
            child_source_port  => $child_port,
            parent_source_port => $parent_port,
            top_sink_port      => $top_port,
            width              => $width,
        });
    }

    if (($movement->{kind} // '') eq 'scalar_actor_handoff') {
        confess "$context can only wire scalar generated-child actor-to-actor data movement through parent handoffs\n"
            unless ($movement->{source} // '') eq 'external_handoff'
                && ($movement->{sink} // '') eq 'external_handoff';

        if (($movement->{source_instance} // '') eq $instance) {
            my $child_port = $movement->{source_endpoint};
            confess "$context data movement '$movement->{drive}' requires a scalar child output port '$child_port' on source instance '$instance'\n"
                unless defined($child_port)
                    && !ref($child_port)
                    && exists($child_ports->{$child_port})
                    && ($child_ports->{$child_port}{direction} || '') eq 'output'
                    && ($child_ports->{$child_port}{width} || 1) == $width;

            my $parent_port = $movement->{source_signal};
            confess "$context data movement '$movement->{drive}' requires a generated parent source handoff signal\n"
                unless _non_empty_scalar($parent_port);

            return ({
                kind               => 'scalar_resolved_child_to_parent_handoff',
                drive              => $movement->{drive},
                child_source_port  => $child_port,
                parent_source_port => $parent_port,
                width              => $width,
            });
        }

        if (($movement->{sink_instance} // '') eq $instance) {
            my $child_port = $movement->{sink_endpoint};
            confess "$context data movement '$movement->{drive}' requires a scalar child input port '$child_port' on sink instance '$instance'\n"
                unless defined($child_port)
                    && !ref($child_port)
                    && exists($child_ports->{$child_port})
                    && ($child_ports->{$child_port}{direction} || '') eq 'input'
                    && ($child_ports->{$child_port}{width} || 1) == $width;

            my $parent_port = $movement->{sink_signal};
            confess "$context data movement '$movement->{drive}' requires a generated parent sink handoff signal\n"
                unless _non_empty_scalar($parent_port);

            return ({
                kind             => 'scalar_parent_to_resolved_child_handoff',
                drive            => $movement->{drive},
                parent_sink_port => $parent_port,
                child_sink_port  => $child_port,
                width            => $width,
            });
        }

        confess "$context data movement '$movement->{drive}' does not involve child instance '$instance'\n";
    }

    confess "$context can only wire scalar top-level input pin to resolved child input, resolved child output to top-level output, or selected generated-child actor-to-actor data movement in the current subset\n";
}

sub _non_empty_scalar {
    my ($value) = @_;
    return defined($value) && !ref($value) && length($value);
}

sub _atl_transaction_scalar_on_signal {
    my ($tx, $context) = @_;
    my @on_clauses = grep {
        ref($_) eq 'ARRAY'
            && @$_
            && defined($_->[0])
            && !ref($_->[0])
            && $_->[0] eq 'on'
    } @{$tx->{clauses} || []};

    confess "$context target transaction '$tx->{name}' requires exactly one scalar '(on SIGNAL)' clause before ATL child wiring\n"
        unless @on_clauses == 1
            && defined($on_clauses[0][1])
            && !ref($on_clauses[0][1])
            && _is_hdl_identifier($on_clauses[0][1]);

    return $on_clauses[0][1];
}

sub _atl_reset_signature {
    my ($reset) = @_;
    return 'none' unless ref($reset) eq 'HASH'
        && defined($reset->{name})
        && length($reset->{name});

    return join("\0",
        $reset->{name},
        $reset->{kind} // '',
        $reset->{polarity} // '',
    );
}

# --- Parent IR (composition top, non-spawned transactions only) ---

sub _build_parent_ir($self, $actor, $generated_children) {
    my @ports  = @{$self->_build_ports($actor)};
    my %ctrs;
    my @states;
    my @dts;
    my @spawn_instances;
    my @temporal_contracts;
    my @bank_accesses;
    my $transaction_port_bindings = _transaction_port_binding_metadata($actor);
    my %signal_widths = _declared_storage_signal_widths($actor);
    my %storage_roles = _declared_storage_roles($actor);
    my %signal_type_refs = (
        _actor_interface_signal_type_refs($actor),
        _declared_storage_signal_type_refs($actor),
    );
    my %local_drive_uses;
    my %spawn_drive_sources;
    my %transaction_by_name = map { $_->{name} => $_ } @{$actor->{transactions} || []};
    my $ti = 0;

    for my $movement (@{(($actor->{actor_network} || {})->{data_movements}) || []}) {
        my $width = $movement->{width} || 1;
        $signal_widths{$movement->{source_signal}} = $width
            if defined($movement->{source_signal}) && !ref($movement->{source_signal});
        $signal_widths{$movement->{sink_signal}} = $width
            if defined($movement->{sink_signal}) && !ref($movement->{sink_signal});
    }

    for my $tx (@{$actor->{transactions}}) {
        next if $generated_children->{$tx->{name}};
        my ($ss, $cs, $ds, $do, $sp, $contracts, $widths, $roles, $accesses) =
            $self->_build_transaction($tx, $actor, $ti++, $generated_children);
        _merge_signal_widths(\%signal_widths, $widths, $tx->{name});
        _merge_signal_type_refs(\%signal_type_refs, { _transaction_port_signal_type_refs($tx) });
        _merge_storage_roles(\%storage_roles, $roles, $tx->{name});
        my %tx_drive_uses = _collect_named_drive_call_names($tx->{clauses}, $actor->{drives} || {});
        $local_drive_uses{$_} = 1 for keys %tx_drive_uses;
        push @states, @$ss;
        for my $k (sort keys %$cs) {
            $ctrs{$k} = $cs->{$k};
        }
        push @dts, @$ds;
        push @temporal_contracts, @$contracts;
        for my $d (@$do)  {
            next if ref($d) eq 'HASH' && $d->{generated_child};
            my $c = ref($d) eq 'HASH' ? $d->{child} : $d;
            $ctrs{"${c}_start"} = 1;
            $ctrs{"${c}_done"} = 1;
        }
        for my $s (@$sp)  {
            _register_generated_activation_instance(
                $s,
                $tx->{name},
                'transaction',
                $actor,
                \@ports,
                \%ctrs,
                \%storage_roles,
                \@dts,
                \%transaction_by_name,
                \%spawn_drive_sources,
            );
        }
        push @spawn_instances, map { _clone_isf_value($_) } @$sp;
        push @bank_accesses, @$accesses;
    }

    my @rule_trigger_dts;
    my @rule_trigger_instances = _rule_trigger_generated_refs($actor, $generated_children);
    for my $s (@rule_trigger_instances) {
        _register_generated_activation_instance(
            $s,
            $s->{owner},
            'rule',
            $actor,
            \@ports,
            \%ctrs,
            \%storage_roles,
            \@rule_trigger_dts,
            \%transaction_by_name,
            \%spawn_drive_sources,
        );
    }
    push @spawn_instances, map { _clone_isf_value($_) } @rule_trigger_instances;

    push @dts, $self->_build_rules($actor, \%ctrs, \@bank_accesses, $generated_children, \%storage_roles);
    push @dts, @rule_trigger_dts;
    $self->_wire_do_children(\@states, \%ctrs, $actor, $generated_children);
    my $local_drive_filter = keys(%$generated_children) ? \%local_drive_uses : undef;
    $self->_build_drive_dts($actor, \@dts, \%ctrs, $local_drive_filter, \%spawn_drive_sources, \%storage_roles);

    my $ir = {
        actor_name => $actor->{actor_name},
        clock      => $actor->{clock},
        reset      => $actor->{reset},
        watchdog   => $actor->{watchdog},
        actor_phases => _actor_metadata_declarations($actor, 'phases'),
        actor_stages => _actor_metadata_declarations($actor, 'stages'),
        package_imports => _actor_package_imports($actor),
        package_roots => _actor_package_roots($actor),
        type_declarations => _actor_type_declarations($actor),
        enum_declarations => _actor_enum_declarations($actor),
        constants  => _actor_constant_declarations($actor),
        params     => _actor_param_declarations($actor),
        actor_network => _actor_network_for_ir($actor),
        ports      => \@ports,
        states     => \@states,
        dt_blocks  => \@dts,
        counters   => \%ctrs,
        declared_storage => _declared_storage_for_ir($actor),
        signal_widths => \%signal_widths,
        signal_type_refs => \%signal_type_refs,
        storage_roles => \%storage_roles,
        children   => {},
        spawn_instances => \@spawn_instances,
        temporal_contracts => \@temporal_contracts,
        bank_accesses => \@bank_accesses,
        transaction_port_bindings => $transaction_port_bindings,
    };
    $ir->{resource_arbitration} = _apply_rule_slot_resource_arbitration($ir, $actor);
    $ir->{priority_resolution} = _merge_priority_resolution(
        _apply_rule_priority_resolution($ir, $actor),
        _apply_rule_transaction_priority_resolution($ir, $actor),
    );
    _finalize_ir($ir);
    return $ir;
}

sub _actor_network_for_ir {
    my ($actor) = @_;
    my $network = $actor->{actor_network};
    return undef unless ref($network) eq 'HASH'
        && ref($network->{instances}) eq 'ARRAY'
        && @{$network->{instances}};

    my @event_waits = map {
        {
            transaction => $_->{transaction},
            context     => $_->{context},
            instance    => $_->{instance},
            event       => $_->{event},
            signal      => $_->{signal},
            source      => $_->{source},
        }
    } @{$network->{event_waits} || []};
    my @transaction_triggers = map {
        {
            owner_transaction  => $_->{owner_transaction},
            context            => $_->{context},
            instance           => $_->{instance},
            target_transaction => $_->{target_transaction},
            signal             => $_->{signal},
            sink               => $_->{sink},
        }
    } @{$network->{transaction_triggers} || []};
    my @data_movements = map {
        {
            kind            => $_->{kind},
            transaction     => $_->{transaction},
            context         => $_->{context},
            drive           => $_->{drive},
            source_instance => $_->{source_instance},
            source_endpoint => $_->{source_endpoint},
            source_signal   => $_->{source_signal},
            sink_instance   => $_->{sink_instance},
            sink_endpoint   => $_->{sink_endpoint},
            sink_signal     => $_->{sink_signal},
            width           => $_->{width},
            width_source    => $_->{width_source},
            route_lifetime  => $_->{route_lifetime},
            storage         => $_->{storage},
            source          => $_->{source},
            sink            => $_->{sink},
        }
    } @{$network->{data_movements} || []};
    my @groups = map {
        {
            name        => $_->{name},
            members     => [ @{$_->{members} || []} ],
            mode        => $_->{mode},
            declaration => $_->{declaration},
            source      => $_->{source},
            scheduling  => $_->{scheduling},
        }
    } @{$network->{groups} || []};
    my @group_schedules = map {
        {
            group               => $_->{group},
            owner_transaction   => $_->{owner_transaction},
            context             => $_->{context},
            members             => [ @{$_->{members} || []} ],
            target_transactions => [ @{$_->{target_transactions} || []} ],
            signals             => [ @{$_->{signals} || []} ],
            schedule            => $_->{schedule},
            dependency_policy   => $_->{dependency_policy},
            storage             => $_->{storage},
            source              => $_->{source},
            sink                => $_->{sink},
        }
    } @{$network->{group_schedules} || []};
    my @association_schedules = map {
        {
            association         => $_->{association},
            kind                => $_->{kind},
            lifetime            => $_->{lifetime},
            owner_transaction   => $_->{owner_transaction},
            context             => $_->{context},
            members             => [ @{$_->{members} || []} ],
            target_transactions => [ @{$_->{target_transactions} || []} ],
            signals             => [ @{$_->{signals} || []} ],
            schedule            => $_->{schedule},
            dependency_policy   => $_->{dependency_policy},
            storage             => $_->{storage},
            source              => $_->{source},
            sink                => $_->{sink},
        }
    } @{$network->{association_schedules} || []};

    return {
        kind      => $network->{kind} // 'static_declaration',
        instances => [
            map {
                my $instance = {
                    name        => $_->{name},
                    actor_type  => $_->{actor_type},
                    declaration => $_->{declaration},
                };
                for my $key (qw(type_resolution library alias export module scheduled_fsm)) {
                    $instance->{$key} = $_->{$key} if exists $_->{$key};
                }
                $instance;
            } @{$network->{instances}}
        ],
        groups => \@groups,
        generated_tops => [],
        association_schedules => \@association_schedules,
        group_schedules => \@group_schedules,
        event_waits => \@event_waits,
        transaction_triggers => \@transaction_triggers,
        data_movements => \@data_movements,
    };
}

sub _register_generated_activation_instance {
    my ($s, $owner, $owner_kind, $actor, $ports, $ctrs, $storage_roles, $dts, $transaction_by_name, $spawn_drive_sources) = @_;

    my $activation_kind = $s->{activation_kind} // 'spawn';
    my $context = $owner_kind eq 'rule'
        ? "Rule '$owner'"
        : "Transaction '$owner'";
    my $instance = $s->{instance};
    my $child = $s->{child};

    $ctrs->{"${instance}_start"} = 1;
    $ctrs->{"${instance}_done"} = 1;
    $storage_roles->{"${instance}_start"} = 'activation_start_handoff'
        if ref($storage_roles) eq 'HASH';
    $storage_roles->{"${instance}_done"} = 'activation_done_handoff'
        if ref($storage_roles) eq 'HASH';
    _ensure_port(
        $ports,
        "${instance}_start",
        'output',
        1,
        "$context: $activation_kind instance '$instance' generated start handoff",
    );
    _ensure_port(
        $ports,
        "${instance}_done",
        'input',
        1,
        "$context: $activation_kind instance '$instance' generated done handoff",
    );

    my $child_tx = $transaction_by_name->{$child};
    my @port_binding_assignments;
    my @port_binding_metadata;
    my %child_transaction_ports = _transaction_port_map($child_tx);

    if ($activation_kind eq 'trigger') {
        $ctrs->{"${instance}_done_seen"} = 1;
        $storage_roles->{"${instance}_done_seen"} = 'trigger_done_observe';
        push @port_binding_assignments, {
            lhs         => "${instance}_start",
            rhs         => $s->{trigger_source},
            op          => '=',
            source_kind => 'trigger_generated_start',
        };
        push @port_binding_assignments, {
            lhs         => "${instance}_done_seen",
            rhs         => "${instance}_done",
            op          => '=',
            source_kind => 'trigger_done_observe',
        };
    }

    for my $binding (@{$s->{port_bindings} || []}) {
        my $port = $child_transaction_ports{$binding->{port}};
        next unless $port;
        my $parent_port = "${instance}_$binding->{port}";
        if ($binding->{role} eq 'input') {
            _ensure_port(
                $ports,
                $parent_port,
                'output',
                $port->{width},
                "$context: $activation_kind instance '$instance' input binding '$binding->{port}' generated payload handoff",
            );
            my %assignment = (
                lhs         => $parent_port,
                rhs         => $activation_kind eq 'trigger'
                    ? _rule_trigger_payload_source_name($owner, $child, $binding->{port}, $s->{trigger_ordinal})
                    : _activation_binding_actor_expr_text($binding),
                op          => '=',
                source_kind => "${activation_kind}_input_binding",
            );
            $assignment{guard} = { port => $s->{trigger_source} }
                if $activation_kind eq 'trigger';
            push @port_binding_assignments, \%assignment;
        } else {
            _ensure_port(
                $ports,
                $parent_port,
                'input',
                $port->{width},
                "$context: $activation_kind instance '$instance' output binding '$binding->{port}' generated payload handoff",
            );
            my %assignment = (
                lhs         => $binding->{actor_signal},
                rhs         => $parent_port,
                op          => '=',
                source_kind => "${activation_kind}_output_binding",
            );
            $assignment{guard} = { port => "${instance}_done" }
                if $activation_kind eq 'do';
            push @port_binding_assignments, \%assignment;
        }
        $ctrs->{$parent_port} = $port->{width};
        $storage_roles->{$parent_port} = 'transaction_port_binding';
        push @port_binding_metadata, {
            role             => $binding->{role},
            child_port       => $binding->{port},
            parent_port      => $parent_port,
            actor_signal     => $binding->{actor_signal},
            actor_expr       => _clone_isf_value($binding->{actor_expr}),
            actor_expression => _activation_binding_actor_expr_text($binding),
            width            => $port->{width},
        };
    }

    if (@port_binding_assignments) {
        push @$dts, {
            name              => $activation_kind eq 'trigger'
                ? "${instance}_trigger_handoff"
                : "${instance}_port_bindings",
            kind              => $activation_kind eq 'trigger'
                ? 'trigger_generated_activation'
                : "${activation_kind}_port_binding",
            owner             => $owner,
            owner_kind        => $owner_kind,
            activation_kind   => $activation_kind,
            spawn_instance    => $instance,
            child_transaction => $child,
            assignments       => \@port_binding_assignments,
        };
    }
    if (@port_binding_metadata) {
        $s->{port_bindings} = \@port_binding_metadata;
    } else {
        delete $s->{port_bindings};
    }

    my %child_drive_uses = _collect_named_drive_call_names($child_tx->{clauses}, $actor->{drives} || {});
    my @drive_handoffs;
    for my $drive_name (sort keys %child_drive_uses) {
        my $prefix = "${instance}_${drive_name}";
        my @payloads;
        push @{$spawn_drive_sources->{$drive_name}}, {
            instance    => $instance,
            drive       => $drive_name,
            prefix      => $prefix,
            source_kind => 'spawn_drive_body',
        };
        _ensure_port(
            $ports,
            "${prefix}_start",
            'input',
            1,
            "$context: $activation_kind instance '$instance' named drive '$drive_name' generated request handoff",
        );
        $ctrs->{"${prefix}_start"} = 1;
        $storage_roles->{"${prefix}_start"} = 'drive_request';
        for my $param (@{($actor->{drives} || {})->{$drive_name}{params} || []}) {
            my $width = _drive_param_width($actor, $drive_name, $param);
            _ensure_port(
                $ports,
                "${prefix}_$param",
                'input',
                $width,
                "$context: $activation_kind instance '$instance' named drive '$drive_name' parameter '$param' generated payload handoff",
            );
            $ctrs->{"${prefix}_$param"} = $width;
            $storage_roles->{"${prefix}_$param"} = 'drive_payload';
            push @payloads, {
                parameter   => $param,
                child_port  => "${drive_name}_$param",
                parent_port => "${prefix}_$param",
                width       => $width,
            };
        }
        push @drive_handoffs, {
            drive   => $drive_name,
            request => {
                child_port  => "${drive_name}_start",
                parent_port => "${prefix}_start",
            },
            payloads => \@payloads,
        };
    }
    $s->{drive_handoffs} = \@drive_handoffs;

    return 1;
}

sub _collect_generated_child_transaction_refs($self, $actor) {
    return _generated_child_transaction_refs($actor);
}

sub _generated_child_transaction_refs {
    my ($actor) = @_;
    my %s;
    my $constant_values = _actor_constant_value_map($actor);
    for my $tx (@{$actor->{transactions}}) {
        for my $ref (_child_action_refs_from_transaction_clauses($tx->{clauses}, $tx->{name})) {
            my $clause = $ref->{clause};
            my $label = $ref->{label};
            if ($clause->[0] eq 'spawn') {
                $s{$clause->[1]} = 1;
                next;
            }
            if (
                $clause->[0] eq 'do'
                && ($label eq 'transaction body' || $label eq 'repeat body')
                && @{_do_parameter_overrides($clause, $tx->{name}, $label, $constant_values, $actor)}
            ) {
                $s{$clause->[1]} = 1;
            }
        }
    }
    for my $rule (@{$actor->{rules} || []}) {
        my $rule_name = $rule->{name};
        for my $action (@{$rule->{actions} || []}) {
            next unless ref($action) eq 'ARRAY' && @$action;
            next unless defined($action->[0]) && !ref($action->[0]) && $action->[0] eq 'trigger';
            $s{$action->[1]} = 1
                if @{_trigger_parameter_overrides($action, $rule_name, 'rule action', $constant_values, $actor)};
        }
    }
    return %s;
}

sub _child_action_refs_from_transaction_clauses {
    my ($clauses, $tx_name) = @_;
    my @refs;
    my $top_level_do_ordinal = 0;
    my $repeat_do_ordinal = 0;

    for my $clause (@{$clauses || []}) {
        next unless ref($clause) eq 'ARRAY' && @$clause;
        next unless defined($clause->[0]) && !ref($clause->[0]);

        my $keyword = $clause->[0];
        if ($keyword eq 'do' || $keyword eq 'spawn') {
            my %ref = (
                clause  => $clause,
                keyword => $keyword,
                label   => 'transaction body',
            );
            $ref{do_ordinal} = $top_level_do_ordinal++ if $keyword eq 'do';
            push @refs, \%ref;
            next;
        }

        if ($keyword eq 'repeat') {
            _push_repeat_body_child_action_refs(
                \@refs, $clause, 'transaction body', \$repeat_do_ordinal,
            );
            next;
        }

        if ($keyword eq 'when') {
            for my $body_clause (@{$clause}[2 .. $#$clause]) {
                next unless ref($body_clause) eq 'ARRAY' && @$body_clause;
                next unless defined($body_clause->[0]) && !ref($body_clause->[0]);
                next unless $body_clause->[0] eq 'repeat';
                _push_repeat_body_child_action_refs(
                    \@refs, $body_clause, 'when body', \$repeat_do_ordinal,
                );
            }
        }

        if ($keyword eq 'switch') {
            for my $branch (@{$clause}[2 .. $#$clause]) {
                next unless ref($branch) eq 'ARRAY' && @$branch >= 2;
                for my $body_clause (@{$branch}[1 .. $#$branch]) {
                    next unless ref($body_clause) eq 'ARRAY' && @$body_clause;
                    next unless defined($body_clause->[0]) && !ref($body_clause->[0]);
                    next unless $body_clause->[0] eq 'repeat';
                    _push_repeat_body_child_action_refs(
                        \@refs, $body_clause, 'switch branch', \$repeat_do_ordinal,
                    );
                }
            }
        }
    }

    return @refs;
}

sub _push_repeat_body_child_action_refs {
    my ($refs, $repeat_clause, $repeat_parent_label, $repeat_do_ordinal_ref) = @_;

    for my $body_clause (@{$repeat_clause}[2 .. $#$repeat_clause]) {
        next unless ref($body_clause) eq 'ARRAY' && @$body_clause;
        next unless defined($body_clause->[0]) && !ref($body_clause->[0]);
        next unless $body_clause->[0] eq 'do' || $body_clause->[0] eq 'spawn';
        my %ref = (
            clause              => $body_clause,
            keyword             => $body_clause->[0],
            label               => 'repeat body',
            repeat_parent_label => $repeat_parent_label,
        );
        $ref{repeat_do_ordinal} = $$repeat_do_ordinal_ref++
            if $body_clause->[0] eq 'do' && ref($repeat_do_ordinal_ref);
        push @$refs, \%ref;
    }
}

sub _validate_activation_domain_names($self, $actor) {
    my %declared_domains = _actor_declared_domain_names($actor);

    for my $tx (@{$actor->{transactions} || []}) {
        for my $child_ref (_child_action_refs_from_transaction_clauses($tx->{clauses}, $tx->{name})) {
            my $domain = _activation_domain_from_clause(
                $child_ref->{clause},
                $tx->{name},
                $child_ref->{label},
            );
            next unless defined $domain;
            next if $declared_domains{$domain};

            my $keyword = $child_ref->{keyword};
            my $target = $child_ref->{clause}[1];
            confess "Transaction '$tx->{name}': $keyword target '$target' uses unknown clock domain '$domain'\n";
        }
    }

    return 1;
}

sub _actor_declared_domain_names {
    my ($actor) = @_;

    if (_actor_has_clock_domains($actor)) {
        return map { $_->{name} => 1 } @{$actor->{clock_domains}{domains} || []};
    }

    my %domains = (default => 1);
    for my $entry (
        @{$actor->{interface}{inputs} || []},
        @{$actor->{interface}{outputs} || []},
        @{$actor->{storage} || []},
        @{$actor->{transactions} || []},
        @{$actor->{rules} || []},
        @{$actor->{library_uses} || []},
    ) {
        next unless ref($entry) eq 'HASH';
        my $domain = $entry->{domain};
        $domains{$domain} = 1
            if defined($domain) && !ref($domain) && length($domain);
    }

    return %domains;
}

sub _rule_trigger_generated_refs {
    my ($actor, $generated_children) = @_;
    my @refs;
    my %ordinals;
    my $constant_values = _actor_constant_value_map($actor);

    for my $rule (@{$actor->{rules} || []}) {
        my $rule_name = $rule->{name};
        for my $action (@{$rule->{actions} || []}) {
            next unless ref($action) eq 'ARRAY' && @$action;
            next unless defined($action->[0]) && !ref($action->[0]) && $action->[0] eq 'trigger';
            my $target = $action->[1];
            next unless defined($target) && !ref($target) && $generated_children->{$target};

            my $key = "$rule_name\0$target";
            my $ordinal = $ordinals{$key}++;
            my $instance = _generated_rule_trigger_instance_name($rule_name, $target, $ordinal);
            push @refs, {
                child               => $target,
                instance            => $instance,
                activation_kind     => 'trigger',
                owner               => $rule_name,
                owner_kind          => 'rule',
                trigger_ordinal     => $ordinal,
                trigger_source      => _rule_trigger_source_name($rule_name, $target, $ordinal),
                parameter_overrides => _trigger_parameter_overrides($action, $rule_name, 'rule action', $constant_values, $actor),
                port_bindings       => _activation_bindings_from_clause($action, $rule_name, 'rule trigger'),
            };
        }
    }

    return @refs;
}

sub _build_domain_partition($self, $actor) {
    return undef unless _actor_has_clock_domains($actor);

    my $clock_domains = $actor->{clock_domains};
    my $default_domain = $clock_domains->{default};
    my @domain_order = map { $_->{name} } @{$clock_domains->{domains} || []};
    my %groups;

    for my $domain (@{$clock_domains->{domains} || []}) {
        my $name = $domain->{name};
        $groups{$name} = {
            name          => $name,
            clock         => $domain->{clock},
            reset         => _clone_isf_value($domain->{reset}),
            scheduled_fsm => "$actor->{actor_name}__domain_${name}.fsm",
            ports         => { inputs => [], outputs => [] },
            storage       => [],
            transactions  => [],
            rules         => [],
            child_instances => [],
            library_uses  => [],
            crossings     => [],
        };
    }

    my %signal_domains = _actor_domain_signal_map($actor, $default_domain);
    my %transaction_domains = map {
        $_->{name} => _domain_for_entry($_, $default_domain)
    } @{$actor->{transactions} || []};
    my %constants = map { $_->{name} => 1 } @{$actor->{constants} || []};
    my %drive_use_domains;

    for my $input (@{$actor->{interface}{inputs} || []}) {
        push @{$groups{_domain_for_entry($input, $default_domain)}{ports}{inputs}}, $input->{name};
    }
    for my $output (@{$actor->{interface}{outputs} || []}) {
        push @{$groups{_domain_for_entry($output, $default_domain)}{ports}{outputs}}, $output->{name};
    }
    for my $storage (@{$actor->{storage} || []}) {
        push @{$groups{_domain_for_entry($storage, $default_domain)}{storage}}, $storage->{name};
    }
    for my $tx (@{$actor->{transactions} || []}) {
        push @{$groups{_domain_for_entry($tx, $default_domain)}{transactions}}, $tx->{name};
    }
    for my $rule (@{$actor->{rules} || []}) {
        push @{$groups{_domain_for_entry($rule, $default_domain)}{rules}}, $rule->{name};
    }
    for my $use (@{$actor->{library_uses} || []}) {
        push @{$groups{_domain_for_entry($use, $default_domain)}{library_uses}}, $use->{instance};
    }
    my @crossing_summaries;
    for my $crossing (@{$actor->{crossings} || []}) {
        next unless ($crossing->{kind} // '') eq 'event';
        push @crossing_summaries, {
            name               => $crossing->{name},
            kind               => 'event',
            source_domain      => $crossing->{from}{domain},
            source_signal      => $crossing->{from}{signal},
            destination_domain => $crossing->{to}{domain},
            destination_signal => $crossing->{to}{signal},
            ready_signal       => $crossing->{ready}{signal},
            instance           => "$crossing->{name}_cdc",
            module             => "$actor->{actor_name}__cdc_event_$crossing->{name}",
            outstanding_policy => 'single_outstanding_acknowledged',
            payload            => 'none',
        };
        push @{$groups{$crossing->{from}{domain}}{crossings}}, {
            event  => $crossing->{name},
            role   => 'source',
            signal => $crossing->{from}{signal},
            ready  => $crossing->{ready}{signal},
        } if exists $groups{$crossing->{from}{domain}};
        push @{$groups{$crossing->{to}{domain}}{crossings}}, {
            event  => $crossing->{name},
            role   => 'destination',
            signal => $crossing->{to}{signal},
        } if exists $groups{$crossing->{to}{domain}};
    }

    my %generated_children = _generated_child_transaction_refs($actor);
    my %do_ordinals;
    for my $tx (@{$actor->{transactions} || []}) {
        my $owner_domain = _domain_for_entry($tx, $default_domain);
        for my $child_ref (_child_action_refs_from_transaction_clauses($tx->{clauses}, $tx->{name})) {
            my $clause = $child_ref->{clause};
            my $keyword = $child_ref->{keyword};
            next unless $keyword eq 'spawn' || $keyword eq 'do';

            my $target = $clause->[1];
            my $activation_domain = _activation_domain_from_clause($clause, $tx->{name}, $child_ref->{label}) // $owner_domain;
            confess "Transaction '$tx->{name}': $keyword target '$target' uses unknown clock domain '$activation_domain'\n"
                unless exists $groups{$activation_domain};
            my $top_level_do = $keyword eq 'do' && ($child_ref->{label} // '') eq 'transaction body';
            my $repeat_body_generated_do = $keyword eq 'do'
                && ($child_ref->{label} // '') eq 'repeat body'
                && _repeat_body_do_is_generated_activation($clause, $target, \%generated_children);
            my $include_instance = $keyword eq 'spawn'
                || ($top_level_do && $generated_children{$target})
                || $repeat_body_generated_do;
            if ($include_instance) {
                my $ordinal = $do_ordinals{$tx->{name}} // 0;
                $do_ordinals{$tx->{name}} = $ordinal + 1 if $top_level_do;
                my $instance = $keyword eq 'spawn'
                    ? $clause->[3]
                    : $repeat_body_generated_do
                        ? _generated_repeat_do_instance_name($tx->{name}, $target, $child_ref->{repeat_do_ordinal} // 0)
                        : _generated_do_instance_name($tx->{name}, $target, $ordinal);
                push @{$groups{$activation_domain}{child_instances}}, {
                    kind   => $keyword,
                    owner  => $tx->{name},
                    child  => $target,
                    instance => $instance,
                };
            } elsif ($top_level_do) {
                $do_ordinals{$tx->{name}}++;
            }
        }
    }
    for my $ref (_rule_trigger_generated_refs($actor, \%generated_children)) {
        my ($rule) = grep { $_->{name} eq $ref->{owner} } @{$actor->{rules} || []};
        my $activation_domain = _domain_for_entry($rule, $default_domain);
        push @{$groups{$activation_domain}{child_instances}}, {
            kind     => 'trigger',
            owner    => $ref->{owner},
            child    => $ref->{child},
            instance => $ref->{instance},
        };
    }

    $self->_validate_transaction_domain_refs(
        $actor,
        \%signal_domains,
        \%transaction_domains,
        \%constants,
        \%drive_use_domains,
        $default_domain,
    );
    $self->_validate_rule_domain_refs(
        $actor,
        \%signal_domains,
        \%transaction_domains,
        \%constants,
        $default_domain,
    );
    $self->_validate_library_use_domain_refs($actor, \%signal_domains, $default_domain);
    _validate_drive_reuse_domains(\%drive_use_domains);

    return {
        kind => @domain_order > 1 ? 'multi_domain' : 'single_domain',
        default_domain => $default_domain,
        domains => [ map { $groups{$_} } @domain_order ],
        top_fsm => "$actor->{actor_name}_top.fsm",
        crossings => \@crossing_summaries,
    };
}

sub _actor_has_clock_domains {
    my ($actor) = @_;
    return ref($actor->{clock_domains}) eq 'HASH'
        && ref($actor->{clock_domains}{domains}) eq 'ARRAY'
        && @{$actor->{clock_domains}{domains}};
}

sub _domain_for_entry {
    my ($entry, $default_domain) = @_;
    return ref($entry) eq 'HASH' && defined($entry->{domain})
        ? $entry->{domain}
        : $default_domain;
}

sub _actor_domain_signal_map {
    my ($actor, $default_domain) = @_;
    my %signals;

    for my $input (@{$actor->{interface}{inputs} || []}) {
        $signals{$input->{name}} = {
            domain => _domain_for_entry($input, $default_domain),
            kind   => 'actor_input',
        };
    }
    for my $output (@{$actor->{interface}{outputs} || []}) {
        $signals{$output->{name}} = {
            domain => _domain_for_entry($output, $default_domain),
            kind   => 'actor_output',
        };
    }
    for my $storage (@{$actor->{storage} || []}) {
        my $domain = _domain_for_entry($storage, $default_domain);
        $signals{$storage->{name}} = {
            domain => $domain,
            kind   => 'actor_storage',
        };
        for my $signal (@{$storage->{signals} || []}) {
            $signals{$signal->{name}} = {
                domain => $domain,
                kind   => 'actor_storage',
            };
        }
    }
    for my $crossing (@{$actor->{crossings} || []}) {
        next unless ($crossing->{kind} // '') eq 'event';
        _register_domain_signal(
            \%signals,
            $crossing->{from}{signal},
            $crossing->{from}{domain},
            'crossing_request',
        );
        _register_domain_signal(
            \%signals,
            $crossing->{ready}{signal},
            $crossing->{from}{domain},
            'crossing_ready',
        );
        _register_domain_signal(
            \%signals,
            $crossing->{to}{signal},
            $crossing->{to}{domain},
            'crossing_pulse',
        );
    }

    return %signals;
}

sub _register_domain_signal {
    my ($signals, $name, $domain, $kind) = @_;
    return unless defined($name) && !ref($name) && length($name);
    if (exists $signals->{$name}) {
        my $existing = $signals->{$name};
        confess "ISF clock-domain violation: signal '$name' is owned by both domain '$existing->{domain}' and domain '$domain'\n"
            if defined($existing->{domain}) && defined($domain) && $existing->{domain} ne $domain;
        return 1;
    }
    $signals->{$name} = {
        domain => $domain,
        kind   => $kind,
    };
    return 1;
}

sub _validate_transaction_domain_refs($self, $actor, $signal_domains, $transaction_domains, $constants, $drive_use_domains, $default_domain) {
    for my $tx (@{$actor->{transactions} || []}) {
        my $domain = _domain_for_entry($tx, $default_domain);
        my %local_signals = _transaction_local_signal_domains($tx, $domain);
        for my $clause (@{$tx->{clauses} || []}) {
            _validate_transaction_clause_domain_refs(
                $clause,
                $actor,
                $tx,
                $domain,
                $signal_domains,
                \%local_signals,
                $transaction_domains,
                $constants,
                $drive_use_domains,
                'transaction body',
            );
        }
    }
    return 1;
}

sub _validate_rule_domain_refs($self, $actor, $signal_domains, $transaction_domains, $constants, $default_domain) {
    for my $rule (@{$actor->{rules} || []}) {
        my $domain = _domain_for_entry($rule, $default_domain);
        my %local_signals;
        if (my $when = $rule->{when}) {
            _validate_domain_expr_reads(
                $when->[1],
                $domain,
                $signal_domains,
                \%local_signals,
                $constants,
                "rule '$rule->{name}' guard",
            );
        }

        for my $action (@{$rule->{actions} || []}) {
            next unless ref($action) eq 'ARRAY' && @$action;
            my $keyword = $action->[0];
            next unless defined($keyword) && !ref($keyword);

            if ($keyword eq 'trigger') {
                my $target = $action->[1];
                _validate_same_domain_target(
                    "rule '$rule->{name}' trigger target '$target'",
                    $domain,
                    $transaction_domains->{$target},
                    'transaction',
                );
                for my $binding (_activation_bindings_from_clause($action, $rule->{name}, 'rule trigger')->@*) {
                    if ($binding->{role} eq 'input') {
                        _validate_domain_expr_reads(
                            $binding->{actor_expr},
                            $domain,
                            $signal_domains,
                            \%local_signals,
                            $constants,
                            "rule '$rule->{name}' trigger input binding '$binding->{port}'",
                        );
                    } else {
                        _validate_domain_signal_access(
                            $binding->{actor_signal},
                            'write',
                            $domain,
                            $signal_domains,
                            \%local_signals,
                            $constants,
                            "rule '$rule->{name}' trigger output binding '$binding->{port}'",
                        );
                    }
                }
                next;
            }
            next if $keyword eq 'priority';

            if ($keyword eq 'set') {
                _validate_domain_signal_access($action->[1], 'write', $domain, $signal_domains, \%local_signals, $constants, "rule '$rule->{name}' set action");
                _validate_domain_expr_reads($action->[2], $domain, $signal_domains, \%local_signals, $constants, "rule '$rule->{name}' set action");
                next;
            }
            if ($keyword eq 'store') {
                _validate_domain_signal_access($action->[1], 'write', $domain, $signal_domains, \%local_signals, $constants, "rule '$rule->{name}' store action");
                _validate_domain_expr_reads($action->[2], $domain, $signal_domains, \%local_signals, $constants, "rule '$rule->{name}' store index");
                _validate_domain_expr_reads($action->[3], $domain, $signal_domains, \%local_signals, $constants, "rule '$rule->{name}' store value");
                next;
            }
            if ($keyword eq 'load') {
                _validate_domain_signal_access($action->[1], 'read', $domain, $signal_domains, \%local_signals, $constants, "rule '$rule->{name}' load action");
                _validate_domain_expr_reads($action->[2], $domain, $signal_domains, \%local_signals, $constants, "rule '$rule->{name}' load index");
                _validate_domain_signal_access($action->[4], 'write', $domain, $signal_domains, \%local_signals, $constants, "rule '$rule->{name}' load target");
                next;
            }

            _validate_domain_signal_access($keyword, 'write', $domain, $signal_domains, \%local_signals, $constants, "rule '$rule->{name}' assignment");
            _validate_domain_expr_reads($action->[1], $domain, $signal_domains, \%local_signals, $constants, "rule '$rule->{name}' assignment");
        }
    }
    return 1;
}

sub _validate_library_use_domain_refs($self, $actor, $signal_domains, $default_domain) {
    my %local_signals;
    my %constants;
    for my $use (@{$actor->{library_uses} || []}) {
        my $domain = _domain_for_entry($use, $default_domain);
        for my $binding (@{$use->{bindings} || []}) {
            next unless ($binding->{role} // '') eq 'input' || ($binding->{role} // '') eq 'output';
            _validate_domain_signal_access(
                $binding->{parent_name},
                $binding->{role} eq 'input' ? 'read' : 'write',
                $domain,
                $signal_domains,
                \%local_signals,
                \%constants,
                "library use '$use->{instance}' $binding->{role} binding '$binding->{library_name}'",
            );
        }
    }
    return 1;
}

sub _transaction_local_signal_domains {
    my ($tx, $domain) = @_;
    my %signals;

    for my $direction (qw(inputs outputs)) {
        for my $port (@{($tx->{ports} || {})->{$direction} || []}) {
            $signals{$port->{name}} = $domain;
        }
    }
    _collect_transaction_local_signals($tx->{clauses}, $domain, \%signals);
    return %signals;
}

sub _collect_transaction_local_signals {
    my ($clauses, $domain, $signals) = @_;
    return unless ref($clauses) eq 'ARRAY';

    for my $clause (@$clauses) {
        next unless ref($clause) eq 'ARRAY' && @$clause;
        my $keyword = $clause->[0];
        next unless defined($keyword) && !ref($keyword);

        if (($keyword eq 'sample' || $keyword eq 'load') && @$clause >= 4) {
            $signals->{$clause->[-1]} = $domain
                if defined($clause->[-1]) && !ref($clause->[-1]);
            next;
        }
        if (($keyword eq 'update' || $keyword eq 'set' || $keyword eq 'shift_left' || $keyword eq 'shift_right')
            && defined($clause->[1])
            && !ref($clause->[1]))
        {
            $signals->{$clause->[1]} = $domain;
        }
        if ($keyword eq 'assemble') {
            my $as_idx = _as_index($clause, 2);
            if (defined($as_idx) && defined($clause->[$as_idx + 1]) && !ref($clause->[$as_idx + 1])) {
                $signals->{$clause->[$as_idx + 1]} = $domain;
            }
        }
        if ($keyword eq 'extract') {
            for my $item (@{$clause}[3 .. $#$clause]) {
                next if ref($item);
                $signals->{$item} = $domain if defined($item);
            }
        }

        if ($keyword eq 'when' || $keyword eq 'repeat' || $keyword eq 'while' || $keyword eq 'until') {
            _collect_transaction_local_signals([@{$clause}[2 .. $#$clause]], $domain, $signals);
        } elsif ($keyword eq 'switch') {
            for my $branch (@{$clause}[2 .. $#$clause]) {
                next unless ref($branch) eq 'ARRAY';
                _collect_transaction_local_signals([@{$branch}[1 .. $#$branch]], $domain, $signals);
            }
        }
    }
}

sub _validate_transaction_clause_domain_refs {
    my ($clause, $actor, $tx, $domain, $signal_domains, $local_signals, $transaction_domains, $constants, $drive_use_domains, $label) = @_;
    return unless ref($clause) eq 'ARRAY' && @$clause;

    my $keyword = $clause->[0];
    return unless defined($keyword) && !ref($keyword);
    my $context = "transaction '$tx->{name}'";

    if ($keyword eq 'domain' || $keyword eq 'ports' || $keyword eq 'params' || $keyword eq 'phase' || $keyword eq 'latency') {
        return 1;
    }
    if ($keyword eq 'stage') {
        for my $subclause (@{$clause}[2 .. $#$clause]) {
            next unless ref($subclause) eq 'ARRAY' && @$subclause == 2;
            my ($role, $signal) = @$subclause;
            next unless defined($role) && !ref($role);
            if ($role eq 'input') {
                _validate_domain_signal_access($signal, 'read', $domain, $signal_domains, $local_signals, $constants, "$context stage '$clause->[1]'");
            } elsif ($role eq 'output') {
                _validate_domain_signal_access($signal, 'write', $domain, $signal_domains, $local_signals, $constants, "$context stage '$clause->[1]'");
            }
        }
        return 1;
    }
    if ($keyword eq 'contract') {
        my $eventual = $clause->[2];
        _validate_domain_signal_access($eventual->[1], 'read', $domain, $signal_domains, $local_signals, $constants, "$context contract '$clause->[1]'")
            if ref($eventual) eq 'ARRAY' && @$eventual >= 2;
        return 1;
    }
    if ($keyword eq 'on' || $keyword eq 'await') {
        _validate_domain_signal_access($clause->[1], 'read', $domain, $signal_domains, $local_signals, $constants, "$context $keyword clause");
        if ($keyword eq 'on') {
            for my $subclause (@{$clause}[2 .. $#$clause]) {
                _validate_transaction_clause_domain_refs($subclause, $actor, $tx, $domain, $signal_domains, $local_signals, $transaction_domains, $constants, $drive_use_domains, 'on body');
            }
        }
        return 1;
    }
    if ($keyword eq 'await_all' || $keyword eq 'await_any') {
        _validate_domain_signal_access($clause->[1], 'read', $domain, $signal_domains, $local_signals, $constants, "$context $keyword clause");
        return 1;
    }
    if ($keyword eq 'sample') {
        _validate_domain_signal_access($clause->[1], 'read', $domain, $signal_domains, $local_signals, $constants, "$context sample clause");
        return 1;
    }
    if ($keyword eq 'complete') {
        _validate_domain_signal_access($clause->[1], 'write', $domain, $signal_domains, $local_signals, $constants, "$context complete clause");
        return 1;
    }
    if ($keyword eq 'wait') {
        _validate_domain_expr_reads($clause->[1], $domain, $signal_domains, $local_signals, $constants, "$context wait clause");
        return 1;
    }
    if ($keyword eq 'update' || $keyword eq 'set') {
        _validate_domain_signal_access($clause->[1], 'write', $domain, $signal_domains, $local_signals, $constants, "$context $keyword clause");
        _validate_domain_expr_reads($clause->[2], $domain, $signal_domains, $local_signals, $constants, "$context $keyword clause");
        return 1;
    }
    if ($keyword eq 'shift_left' || $keyword eq 'shift_right') {
        _validate_domain_signal_access($clause->[1], 'write', $domain, $signal_domains, $local_signals, $constants, "$context $keyword clause");
        _validate_domain_signal_access($clause->[1], 'read', $domain, $signal_domains, $local_signals, $constants, "$context $keyword clause");
        _validate_domain_expr_reads($clause->[2], $domain, $signal_domains, $local_signals, $constants, "$context $keyword clause");
        return 1;
    }
    if ($keyword eq 'assemble') {
        my $as_idx = _as_index($clause, 2);
        if (defined $as_idx) {
            for my $part (@{$clause}[1 .. $as_idx - 1]) {
                _validate_domain_expr_reads($part, $domain, $signal_domains, $local_signals, $constants, "$context assemble clause");
            }
            _validate_domain_signal_access($clause->[$as_idx + 1], 'write', $domain, $signal_domains, $local_signals, $constants, "$context assemble clause");
        }
        return 1;
    }
    if ($keyword eq 'extract') {
        _validate_domain_signal_access($clause->[1], 'read', $domain, $signal_domains, $local_signals, $constants, "$context extract clause");
        for my $item (@{$clause}[3 .. $#$clause]) {
            next if ref($item);
            _validate_domain_signal_access($item, 'write', $domain, $signal_domains, $local_signals, $constants, "$context extract clause");
        }
        return 1;
    }
    if ($keyword eq 'store') {
        _validate_domain_signal_access($clause->[1], 'write', $domain, $signal_domains, $local_signals, $constants, "$context store clause");
        _validate_domain_expr_reads($clause->[2], $domain, $signal_domains, $local_signals, $constants, "$context store index");
        _validate_domain_expr_reads($clause->[3], $domain, $signal_domains, $local_signals, $constants, "$context store value");
        return 1;
    }
    if ($keyword eq 'load') {
        _validate_domain_signal_access($clause->[1], 'read', $domain, $signal_domains, $local_signals, $constants, "$context load clause");
        _validate_domain_expr_reads($clause->[2], $domain, $signal_domains, $local_signals, $constants, "$context load index");
        _validate_domain_signal_access($clause->[4], 'write', $domain, $signal_domains, $local_signals, $constants, "$context load target");
        return 1;
    }
    if ($keyword eq 'drive') {
        if (defined($clause->[1]) && !ref($clause->[1]) && exists(($actor->{drives} || {})->{$clause->[1]})) {
            $drive_use_domains->{$clause->[1]}{$domain} = 1;
            for my $arg (@{$clause}[2 .. $#$clause]) {
                _validate_domain_expr_reads($arg, $domain, $signal_domains, $local_signals, $constants, "$context drive '$clause->[1]' call");
            }
        } else {
            for my $assignment (@{$clause}[2 .. $#$clause]) {
                next unless ref($assignment) eq 'ARRAY' && @$assignment >= 2;
                _validate_domain_signal_access($assignment->[0], 'write', $domain, $signal_domains, $local_signals, $constants, "$context inline drive");
                _validate_domain_expr_reads($assignment->[1], $domain, $signal_domains, $local_signals, $constants, "$context inline drive");
            }
        }
        return 1;
    }
    if ($keyword eq 'do' || $keyword eq 'spawn') {
        my $target = $clause->[1];
        _validate_same_domain_target(
            "$context $keyword target '$target'",
            $domain,
            $transaction_domains->{$target},
            'transaction',
        );
        if (my $activation_domain = _activation_domain_from_clause($clause, $tx->{name}, $label)) {
            _validate_same_domain_target(
                "$context $keyword instance domain '$activation_domain'",
                $domain,
                $activation_domain,
                'activation',
            );
        }
        for my $binding (_activation_bindings_from_clause($clause, $tx->{name}, $label)->@*) {
            if ($binding->{role} eq 'input') {
                _validate_domain_expr_reads($binding->{actor_expr}, $domain, $signal_domains, $local_signals, $constants, "$context $keyword input binding '$binding->{port}'");
            } else {
                _validate_domain_signal_access($binding->{actor_signal}, 'write', $domain, $signal_domains, $local_signals, $constants, "$context $keyword output binding '$binding->{port}'");
            }
        }
        return 1;
    }
    if ($keyword eq 'when' || $keyword eq 'while' || $keyword eq 'until') {
        _validate_domain_expr_reads($clause->[1], $domain, $signal_domains, $local_signals, $constants, "$context $keyword condition");
        for my $subclause (@{$clause}[2 .. $#$clause]) {
            _validate_transaction_clause_domain_refs($subclause, $actor, $tx, $domain, $signal_domains, $local_signals, $transaction_domains, $constants, $drive_use_domains, "$keyword body");
        }
        return 1;
    }
    if ($keyword eq 'repeat') {
        _validate_domain_expr_reads($clause->[1], $domain, $signal_domains, $local_signals, $constants, "$context repeat count");
        for my $subclause (@{$clause}[2 .. $#$clause]) {
            _validate_transaction_clause_domain_refs($subclause, $actor, $tx, $domain, $signal_domains, $local_signals, $transaction_domains, $constants, $drive_use_domains, 'repeat body');
        }
        return 1;
    }
    if ($keyword eq 'switch') {
        _validate_domain_expr_reads($clause->[1], $domain, $signal_domains, $local_signals, $constants, "$context switch selector");
        for my $branch (@{$clause}[2 .. $#$clause]) {
            next unless ref($branch) eq 'ARRAY';
            for my $subclause (@{$branch}[1 .. $#$branch]) {
                _validate_transaction_clause_domain_refs($subclause, $actor, $tx, $domain, $signal_domains, $local_signals, $transaction_domains, $constants, $drive_use_domains, 'switch branch');
            }
        }
        return 1;
    }

    return 1;
}

sub _validate_domain_expr_reads {
    my ($expr, $domain, $signal_domains, $local_signals, $constants, $context) = @_;
    return unless defined $expr;

    if (!ref($expr)) {
        _validate_domain_signal_access($expr, 'read', $domain, $signal_domains, $local_signals, $constants, $context);
        return 1;
    }
    return 1 unless ref($expr) eq 'ARRAY';

    for my $index (0 .. $#$expr) {
        next if $index == 0 && defined($expr->[$index]) && !ref($expr->[$index]);
        _validate_domain_expr_reads($expr->[$index], $domain, $signal_domains, $local_signals, $constants, $context);
    }
    return 1;
}

sub _validate_domain_signal_access {
    my ($name, $access, $domain, $signal_domains, $local_signals, $constants, $context) = @_;
    return 1 unless defined($name) && !ref($name) && _is_hdl_identifier($name);

    my ($owner_domain, $owner_kind);
    if (exists $signal_domains->{$name}) {
        $owner_domain = $signal_domains->{$name}{domain};
        $owner_kind = $signal_domains->{$name}{kind};
    } elsif (exists $local_signals->{$name}) {
        $owner_domain = $local_signals->{$name};
        $owner_kind = 'transaction_local';
    } else {
        return 1;
    }

    confess "ISF clock-domain violation: $context $access signal '$name' owned by domain '$owner_domain' from domain '$domain' without a crossing primitive\n"
        if defined($owner_domain) && defined($domain) && $owner_domain ne $domain;

    return 1;
}

sub _validate_same_domain_target {
    my ($context, $owner_domain, $target_domain, $target_kind) = @_;
    return 1 unless defined($target_domain) && defined($owner_domain);

    confess "ISF clock-domain violation: $context references $target_kind in domain '$target_domain' from domain '$owner_domain' without a crossing primitive\n"
        if $target_domain ne $owner_domain;

    return 1;
}

sub _validate_drive_reuse_domains {
    my ($drive_use_domains) = @_;

    for my $drive (sort keys %$drive_use_domains) {
        my @domains = sort keys %{$drive_use_domains->{$drive} || {}};
        confess "ISF clock-domain violation: drive '$drive' is called from multiple domains (" . join(', ', @domains) . ") without a safe cross-domain drive reuse rule\n"
            if @domains > 1;
    }
    return 1;
}

sub _validate_child_transaction_refs($self, $actor) {
    my %transactions = map { $_->{name} => 1 } @{$actor->{transactions} || []};
    my %transaction_by_name = map { $_->{name} => $_ } @{$actor->{transactions} || []};
    my %generated_children;
    my %generated_instances;
    my @child_refs;
    my $constant_values = _actor_constant_value_map($actor);

    for my $tx (@{$actor->{transactions} || []}) {
        my $tx_name = $tx->{name};
        for my $child_ref (_child_action_refs_from_transaction_clauses($tx->{clauses}, $tx_name)) {
            my $clause = $child_ref->{clause};
            my $keyword = $child_ref->{keyword};
            my $label = $child_ref->{label};

            _validate_child_action_clause($clause, $tx_name, $label);

            my $target = $clause->[1];
            confess "Transaction '$tx_name': $keyword target must be a scalar transaction name\n"
                unless defined($target) && !ref($target) && length($target);
            confess "Transaction '$tx_name': $keyword target '$target' is not a declared transaction\n"
                unless $transactions{$target};

            if ($keyword eq 'spawn') {
                confess "Transaction '$tx_name': spawn target '$target' conflicts with parent actor module name '$actor->{actor_name}'\n"
                    if $target eq $actor->{actor_name};
                $generated_children{$target} = 1;
            }
            $generated_children{$target} = 1
                if $keyword eq 'do'
                    && ($label eq 'transaction body' || $label eq 'repeat body')
                    && @{_do_parameter_overrides($clause, $tx_name, $label, $constant_values, $actor)};

            push @child_refs, {
                tx                  => $tx,
                tx_name             => $tx_name,
                clause              => $clause,
                keyword             => $keyword,
                target              => $target,
                label               => $label,
                repeat_parent_label => $child_ref->{repeat_parent_label},
                repeat_do_ordinal   => $child_ref->{repeat_do_ordinal},
            };
        }
    }
    for my $rule (@{$actor->{rules} || []}) {
        my $rule_name = $rule->{name};
        for my $action (@{$rule->{actions} || []}) {
            next unless ref($action) eq 'ARRAY' && @$action;
            next unless defined($action->[0]) && !ref($action->[0]) && $action->[0] eq 'trigger';

            _validate_rule_trigger_action_clause($action, $rule_name, 'rule action');

            my $target = $action->[1];
            confess "Rule '$rule_name': trigger target must be a scalar transaction name\n"
                unless defined($target) && !ref($target) && length($target);
            confess "Rule '$rule_name': trigger target '$target' is not a declared transaction\n"
                unless $transactions{$target};
            $generated_children{$target} = 1
                if @{_trigger_parameter_overrides($action, $rule_name, 'rule action', $constant_values, $actor)};
        }
    }

    for my $ref (@child_refs) {
        my $tx       = $ref->{tx};
        my $tx_name  = $ref->{tx_name};
        my $clause   = $ref->{clause};
        my $keyword  = $ref->{keyword};
        my $target   = $ref->{target};
        my $label    = $ref->{label};
        my $repeat_parent_label = $ref->{repeat_parent_label} // '';
        _validate_repeat_body_do_subset($ref);

        if ($keyword eq 'do'
            && $label eq 'repeat body'
            && _repeat_body_do_is_generated_activation($clause, $target, \%generated_children)) {
            my $nested_do_label = _nested_repeat_local_do_label($repeat_parent_label);
            my $uses_generated_params = _repeat_body_do_uses_generated_params($clause);
            my $uses_bindings = _repeat_body_do_uses_bindings($clause);
            my $uses_domain = _repeat_body_do_uses_domain($clause);
            my $nested_generated_child_do = (
                (!$uses_domain
                    || (($repeat_parent_label eq 'when body' || $repeat_parent_label eq 'switch branch') && $uses_generated_params))
                && (
                    (($repeat_parent_label eq 'when body' || $repeat_parent_label eq 'switch branch')
                        && !$uses_generated_params
                        && !$uses_bindings
                        && $generated_children{$target})
                    || (($repeat_parent_label eq 'when body' || $repeat_parent_label eq 'switch branch')
                        && $uses_generated_params)
                )
            );
            confess "Transaction '$tx_name': $nested_do_label nested repeat do supports only local child targets; target '$target' is already generated by another activation site\n"
                if defined($nested_do_label) && !$nested_generated_child_do;
        }

        my $repeat_body_generated_do = $keyword eq 'do'
            && $label eq 'repeat body'
            && _repeat_body_do_is_generated_activation($clause, $target, \%generated_children);
        my $generated_activation = $keyword eq 'spawn'
            || ($keyword eq 'do' && $label eq 'transaction body' && $generated_children{$target})
            || $repeat_body_generated_do;
        next unless $generated_activation;

        confess "Transaction '$tx_name': $keyword target '$target' conflicts with parent actor module name '$actor->{actor_name}'\n"
            if $target eq $actor->{actor_name};

        my $instance = $keyword eq 'spawn'
            ? $clause->[3]
            : $repeat_body_generated_do
                ? _generated_repeat_do_instance_name($tx_name, $target, $ref->{repeat_do_ordinal} // 0)
                : _generated_do_instance_name($tx_name, $target, _do_clause_ordinal($tx, $clause));

        confess "Transaction '$tx_name': $keyword instance '$instance' conflicts with parent actor instance name '$actor->{actor_name}'\n"
            if $instance eq $actor->{actor_name};
        if (my $previous = $generated_instances{$instance}) {
            my $duplicate_label = $keyword eq 'spawn' && $previous->{keyword} eq 'spawn'
                ? 'duplicate spawn instance'
                : 'duplicate generated child instance';
            confess "Transaction '$tx_name': $duplicate_label '$instance' in actor '$actor->{actor_name}'\n";
        }
        $generated_instances{$instance} = {
            keyword => $keyword,
            owner   => $tx_name,
            target  => $target,
        };

        my %declared_params = map {
            $_->{name} => $_
        } @{_transaction_param_declarations($transaction_by_name{$target}, $actor)};
        for my $override (@{_activation_parameter_overrides($clause, $tx_name, $label, $constant_values, $actor)}) {
            my $name = $override->{name};
            confess "Transaction '$tx_name': $keyword instance '$instance' overrides unknown parameter '$name' on child '$target'\n"
                unless exists $declared_params{$name};
            confess "Transaction '$tx_name': $keyword instance '$instance' parameter '$name' shape does not match child '$target' declaration\n"
                unless _param_values_shape_compatible($declared_params{$name}{value}, $override->{value});
        }
    }

    for my $ref (_rule_trigger_generated_refs($actor, \%generated_children)) {
        my $rule_name = $ref->{owner};
        my $target = $ref->{child};
        my $instance = $ref->{instance};

        confess "Rule '$rule_name': trigger target '$target' conflicts with parent actor module name '$actor->{actor_name}'\n"
            if $target eq $actor->{actor_name};
        confess "Rule '$rule_name': trigger instance '$instance' conflicts with parent actor instance name '$actor->{actor_name}'\n"
            if $instance eq $actor->{actor_name};
        if (my $previous = $generated_instances{$instance}) {
            confess "Rule '$rule_name': duplicate generated child instance '$instance' in actor '$actor->{actor_name}'\n";
        }
        $generated_instances{$instance} = {
            keyword => 'trigger',
            owner   => $rule_name,
            target  => $target,
        };

        my %declared_params = map {
            $_->{name} => $_
        } @{_transaction_param_declarations($transaction_by_name{$target}, $actor)};
        for my $override (@{$ref->{parameter_overrides} || []}) {
            my $name = $override->{name};
            confess "Rule '$rule_name': trigger instance '$instance' overrides unknown parameter '$name' on child '$target'\n"
                unless exists $declared_params{$name};
            confess "Rule '$rule_name': trigger instance '$instance' parameter '$name' shape does not match child '$target' declaration\n"
                unless _param_values_shape_compatible($declared_params{$name}{value}, $override->{value});
        }
    }

    return 1;
}

sub _validate_transaction_parameter_clauses($self, $actor, $generated_children) {
    for my $tx (@{$actor->{transactions} || []}) {
        my $params = _transaction_param_declarations($tx, $actor);
        next unless @$params;

        my $tx_name = $tx->{name};
        confess "Transaction '$tx_name': params are supported only on generated child transactions\n"
            unless $generated_children->{$tx_name};
    }
    return 1;
}

sub _validate_transaction_port_bindings($self, $actor) {
    my %transaction_by_name = map { $_->{name} => $_ } @{$actor->{transactions} || []};

    for my $tx (@{$actor->{transactions} || []}) {
        my $tx_name = $tx->{name};
        for my $ref (_child_action_refs_from_transaction_clauses($tx->{clauses}, $tx_name)) {
            my $clause = $ref->{clause};
            my $keyword = $ref->{keyword};
            my $label = $ref->{label};
            my $target = $clause->[1];
            next unless defined($target) && !ref($target) && exists $transaction_by_name{$target};
            my $context = $label eq 'repeat body'
                ? "Transaction '$tx_name': repeat-body $keyword target '$target'"
                : "Transaction '$tx_name': $keyword target '$target'";
            _validate_activation_bindings(
                $actor,
                $tx,
                $transaction_by_name{$target},
                _activation_bindings_from_clause($clause, $tx_name, $label),
                $context,
            );
        }
    }

    for my $rule (@{$actor->{rules} || []}) {
        my $rule_name = $rule->{name};
        for my $action (@{$rule->{actions} || []}) {
            next unless ref($action) eq 'ARRAY' && @$action;
            next unless defined($action->[0]) && !ref($action->[0]) && $action->[0] eq 'trigger';
            my $target = $action->[1];
            next unless defined($target) && !ref($target) && exists $transaction_by_name{$target};
            _validate_activation_bindings(
                $actor,
                undef,
                $transaction_by_name{$target},
                _activation_bindings_from_clause($action, $rule_name, 'rule trigger'),
                "Rule '$rule_name': trigger target '$target'",
                { allow_outputs => 0 },
            );
        }
    }

    return 1;
}

sub _transaction_port_binding_metadata {
    my ($actor) = @_;
    my %transaction_by_name = map { $_->{name} => $_ } @{$actor->{transactions} || []};
    my %generated_children = _generated_child_transaction_refs($actor);
    my @metadata;

    for my $tx (@{$actor->{transactions} || []}) {
        my $owner = $tx->{name};
        my $do_ordinal = 0;
        for my $ref (_child_action_refs_from_transaction_clauses($tx->{clauses}, $owner)) {
            my $clause = $ref->{clause};
            my $keyword = $ref->{keyword};
            my $label = $ref->{label};
            my $target = $clause->[1];
            next unless defined($target) && !ref($target) && exists $transaction_by_name{$target};
            my $current_do_ordinal;
            if ($keyword eq 'do' && $label eq 'transaction body') {
                $current_do_ordinal = $do_ordinal++;
            }
            my $repeat_body_generated_do = $keyword eq 'do'
                && $label eq 'repeat body'
                && _repeat_body_do_is_generated_activation($clause, $target, \%generated_children);

            my $bindings = _activation_bindings_from_clause($clause, $owner, $label);
            next unless @$bindings;
            my %target_ports = _transaction_port_map($transaction_by_name{$target});
            my $instance = $keyword eq 'spawn'
                ? ($clause->[3] // "${owner}_spawn")
                : $repeat_body_generated_do
                    ? _generated_repeat_do_instance_name($owner, $target, $ref->{repeat_do_ordinal} // 0)
                    : ($generated_children{$target} && defined($current_do_ordinal) ? _generated_do_instance_name($owner, $target, $current_do_ordinal) : undef);
            for my $binding (@$bindings) {
                push @metadata, _transaction_port_binding_entry(
                    binding            => $binding,
                    port               => $target_ports{$binding->{port}},
                    site_kind          => $keyword,
                    owner              => $owner,
                    owner_kind         => 'transaction',
                    target_transaction => $target,
                    instance           => $instance,
                );
            }
        }
    }

    for my $rule (@{$actor->{rules} || []}) {
        my $owner = $rule->{name};
        my %trigger_ordinals;
        for my $action (@{$rule->{actions} || []}) {
            next unless ref($action) eq 'ARRAY' && @$action;
            next unless defined($action->[0]) && !ref($action->[0]) && $action->[0] eq 'trigger';
            my $target = $action->[1];
            next unless defined($target) && !ref($target) && exists $transaction_by_name{$target};

            my $generated_trigger = $generated_children{$target} ? 1 : 0;
            my $trigger_ordinal;
            my $instance;
            if ($generated_trigger) {
                my $key = "$owner\0$target";
                $trigger_ordinal = $trigger_ordinals{$key}++;
                $instance = _generated_rule_trigger_instance_name($owner, $target, $trigger_ordinal);
            }

            my $bindings = _activation_bindings_from_clause($action, $owner, 'rule trigger');
            next unless @$bindings;
            my %target_ports = _transaction_port_map($transaction_by_name{$target});
            for my $binding (@$bindings) {
                push @metadata, _transaction_port_binding_entry(
                    binding            => $binding,
                    port               => $target_ports{$binding->{port}},
                    site_kind          => 'rule_trigger',
                    owner              => $owner,
                    owner_kind         => 'rule',
                    target_transaction => $target,
                    instance           => $instance,
                    trigger_source     => _rule_trigger_source_name($owner, $target, $trigger_ordinal),
                    payload_source     => $binding->{role} eq 'input'
                        ? _rule_trigger_payload_source_name($owner, $target, $binding->{port}, $trigger_ordinal)
                        : undef,
                );
            }
        }
    }

    return \@metadata;
}

sub _transaction_port_binding_entry {
    my (%args) = @_;
    my $binding = $args{binding};
    my $role = $binding->{role};
    my $port = $binding->{port};
    my $site_kind = $args{site_kind};
    my $target = $args{target_transaction};
    my $instance = $args{instance};

    return {
        site_kind          => $site_kind,
        owner              => $args{owner},
        owner_kind         => $args{owner_kind},
        target_transaction => $target,
        role               => $role,
        port               => $port,
        actor_signal       => $binding->{actor_signal},
        actor_expression   => _activation_binding_actor_expr_text($binding),
        width              => ($args{port} || {})->{width} // 1,
        instance           => $instance,
        parent_port        => defined($instance) ? "${instance}_$port" : undef,
        child_port         => defined($instance) ? $port : undef,
        start_signal       => defined($instance) ? "${instance}_start" : "${target}_start",
        done_signal        => $site_kind eq 'rule_trigger'
            ? undef
            : (defined($instance) ? "${instance}_done" : "${target}_done"),
        trigger_source     => $site_kind eq 'rule_trigger'
            ? ($args{trigger_source} // _rule_trigger_source_name($args{owner}, $target))
            : undef,
        payload_source     => $site_kind eq 'rule_trigger' && $role eq 'input'
            ? ($args{payload_source} // _rule_trigger_payload_source_name($args{owner}, $target, $port))
            : undef,
    };
}

sub _actor_param_declarations {
    my ($actor) = @_;
    return [] unless ref($actor) eq 'HASH';

    my $actor_name = $actor->{actor_name} // 'unknown';
    my @params;
    my %seen;
    for my $param (@{$actor->{params} || []}) {
        confess "Actor '$actor_name': params entries must be hash references\n"
            unless ref($param) eq 'HASH';
        my $name = $param->{name};
        confess "Actor '$actor_name': parameter names must be scalar HDL identifiers\n"
            unless _is_hdl_identifier($name);
        confess "Actor '$actor_name': duplicate parameter '$name'\n"
            if $seen{$name}++;
        my $value = $param->{value};
        my %resolved_value;
        if (!ref($value) && _is_enum_member_reference($value)) {
            confess "Actor '$actor_name': parameter '$name' enum member '$value' must resolve to a non-negative integer literal value\n"
                unless defined _non_negative_integer_from_literal(_param_resolved_value($param));
            %resolved_value = (resolved_value => _clone_isf_value(_param_resolved_value($param)));
        } elsif (ref($value)) {
            my ($resolved, $has_enum_leaf) = _resolve_actor_param_default_value(
                $value,
                "Actor '$actor_name': parameter '$name'",
                $actor,
            );
            %resolved_value = (resolved_value => _clone_isf_value($resolved))
                if $has_enum_leaf;
        } else {
            _validate_isf_param_value(
                $value,
                "Actor '$actor_name': parameter '$name'",
            );
        }
        push @params, {
            name  => $name,
            value => _clone_isf_value($value),
            (exists($param->{resolved_value}) ? (resolved_value => _clone_isf_value($param->{resolved_value})) : %resolved_value),
        };
    }

    return \@params;
}

sub _resolve_actor_param_default_value {
    my ($value, $context, $actor) = @_;

    if (!ref($value)) {
        return (_clone_isf_value($value), 0)
            if defined($value) && _is_numeric_or_exact_width_literal($value);
        if (_is_enum_member_reference($value)) {
            my $resolved_value = _resolve_actor_enum_member_value($actor, $value);
            confess "$context references unknown enum member '$value'\n"
                unless defined($resolved_value) && !ref($resolved_value);
            confess "$context enum member '$value' must resolve to a non-negative integer literal value\n"
                unless defined _non_negative_integer_from_literal($resolved_value);
            return (_clone_isf_value($resolved_value), 1);
        }
        confess "$context uses unsupported parameter value '$value'; actor parameter aggregate/list defaults accept numeric, exact-width, and enum member literal leaves only\n";
    }

    confess "$context uses unsupported parameter value shape; actor parameter defaults accept non-empty aggregate/list literals\n"
        unless ref($value) eq 'ARRAY' && @$value;

    my @resolved;
    my $has_enum_leaf = 0;
    for my $item (@$value) {
        my ($resolved_item, $item_has_enum_leaf) = _resolve_actor_param_default_value($item, $context, $actor);
        push @resolved, $resolved_item;
        $has_enum_leaf ||= $item_has_enum_leaf;
    }

    return (\@resolved, $has_enum_leaf);
}

sub _actor_package_imports {
    my ($actor) = @_;
    return [] unless ref($actor) eq 'HASH';
    return [ map { _clone_isf_value($_) } @{$actor->{package_imports} || []} ];
}

sub _actor_package_roots {
    my ($actor) = @_;
    return [] unless ref($actor) eq 'HASH';
    return [ map { _clone_isf_value($_) } @{$actor->{package_roots} || []} ];
}

sub _actor_type_declarations {
    my ($actor) = @_;
    return [] unless ref($actor) eq 'HASH';
    return [ map { _clone_isf_value($_) } @{$actor->{type_declarations} || []} ];
}

sub _actor_enum_declarations {
    my ($actor) = @_;
    return [] unless ref($actor) eq 'HASH';
    return [ map { _clone_isf_value($_) } @{$actor->{enum_declarations} || []} ];
}

sub _actor_constant_declarations {
    my ($actor) = @_;
    return [] unless ref($actor) eq 'HASH';

    my $actor_name = $actor->{actor_name} // 'unknown';
    my @constants;
    my %seen;
    for my $constant (@{$actor->{constants} || []}) {
        confess "Actor '$actor_name': constants entries must be hash references\n"
            unless ref($constant) eq 'HASH';
        my $name = $constant->{name};
        confess "Actor '$actor_name': constant names must be scalar HDL identifiers\n"
            unless _is_hdl_identifier($name);
        confess "Actor '$actor_name': duplicate constant '$name'\n"
            if $seen{$name}++;
        confess "Actor '$actor_name': constant '$name' requires a non-negative integer literal value\n"
            unless defined _non_negative_integer_from_literal(_constant_resolved_value($constant));
        push @constants, {
            name           => $name,
            value          => _clone_isf_value($constant->{value}),
            resolved_value => _clone_isf_value(_constant_resolved_value($constant)),
        };
    }

    return \@constants;
}

sub _actor_metadata_declarations {
    my ($actor, $key) = @_;
    return [] unless ref($actor) eq 'HASH';
    return [
        map {
            {
                name => $_->{name},
                body => _clone_isf_value($_->{body} || []),
            }
        } @{$actor->{$key} || []}
    ];
}

sub _library_instance_metadata {
    my ($use) = @_;
    my %override_by_name = map { $_->{name} => $_ } @{$use->{parameter_overrides} || []};
    my @parameters;
    for my $param (@{($use->{actor} || {})->{params} || []}) {
        my $override = $override_by_name{$param->{name}};
        push @parameters, {
            name   => $param->{name},
            source => $override ? 'override' : 'default',
            value  => _clone_isf_value($override ? $override->{value} : $param->{value}),
        };
    }

    return {
        library       => $use->{library},
        library_source=> $use->{library_source},
        alias         => $use->{alias},
        export        => $use->{export},
        kind          => $use->{kind} // 'actor',
        instance      => $use->{instance},
        module        => $use->{module},
        scheduled_fsm => $use->{scheduled_fsm},
        parameters    => \@parameters,
        parameter_overrides => _clone_isf_value($use->{parameter_overrides} || []),
        bindings      => _clone_isf_value($use->{bindings} || []),
        child_clock   => ($use->{actor} || {})->{clock},
        child_reset   => (($use->{actor} || {})->{reset} || {})->{name},
    };
}

sub _resolved_atl_actor_type_resolutions {
    my ($actor) = @_;
    my $resolutions = $actor->{_atl_actor_type_resolutions};
    return () unless ref($resolutions) eq 'HASH';
    return map { $resolutions->{$_} } sort keys %$resolutions;
}

sub _build_ports($self, $actor) {
    my @p;
    for my $i (@{$actor->{interface}{inputs}})  {
        my %port = ( name => $i->{name}, direction => 'input',  width => $i->{width} // 1 );
        $port{type} = $i->{type} if exists $i->{type};
        push @p, \%port;
    }
    for my $o (@{$actor->{interface}{outputs}}) {
        my %port = ( name => $o->{name}, direction => 'output', width => $o->{width} // 1 );
        $port{type} = $o->{type} if exists $o->{type};
        push @p, \%port;
    }
    my %seen = map { $_->{name} => 1 } @p;
    for my $wait (@{(($actor->{actor_network} || {})->{event_waits}) || []}) {
        _push_port(\@p, \%seen, $wait->{signal}, 'input', 1);
    }
    for my $trigger (@{(($actor->{actor_network} || {})->{transaction_triggers}) || []}) {
        _push_port(\@p, \%seen, $trigger->{signal}, 'output', 1);
    }
    for my $movement (@{(($actor->{actor_network} || {})->{data_movements}) || []}) {
        _push_port(\@p, \%seen, $movement->{source_signal}, 'input', $movement->{width} || 1);
        _push_port(\@p, \%seen, $movement->{sink_signal}, 'output', $movement->{width} || 1);
    }
    return \@p;
}

sub _declared_storage_for_ir {
    my ($actor) = @_;
    my @storage;

    for my $entry (@{$actor->{storage} || []}) {
        my @signals = map {
            my %signal = (
                name  => $_->{name},
                width => $_->{width},
            );
            $signal{type} = $_->{type} if exists $_->{type};
            $signal{type_spec} = _clone_isf_value($_->{type_spec})
                if exists $_->{type_spec};
            $signal{index} = $_->{index} if exists $_->{index};
            \%signal;
        } @{$entry->{signals} || []};

        my %copy = (
            kind    => $entry->{kind},
            name    => $entry->{name},
            width   => $entry->{width},
            signals => \@signals,
        );
        $copy{type} = $entry->{type} if exists $entry->{type};
        $copy{type_spec} = _clone_isf_value($entry->{type_spec})
            if exists $entry->{type_spec};
        $copy{depth} = $entry->{depth} if exists $entry->{depth};
        push @storage, \%copy;
    }

    return \@storage;
}

sub _declared_storage_signal_widths {
    my ($actor) = @_;
    my %widths;

    for my $entry (@{$actor->{storage} || []}) {
        for my $signal (@{$entry->{signals} || []}) {
            $widths{$signal->{name}} = $signal->{width};
        }
    }

    return %widths;
}

sub _actor_interface_signal_type_refs {
    my ($actor) = @_;
    my %types;

    for my $direction (qw(inputs outputs)) {
        for my $port (@{$actor->{interface}{$direction} || []}) {
            $types{$port->{name}} = $port->{type}
                if defined($port->{type}) && !ref($port->{type}) && length($port->{type});
        }
    }

    return %types;
}

sub _declared_storage_signal_type_refs {
    my ($actor) = @_;
    my %types;

    for my $entry (@{$actor->{storage} || []}) {
        for my $signal (@{$entry->{signals} || []}) {
            $types{$signal->{name}} = $signal->{type}
                if defined($signal->{type}) && !ref($signal->{type}) && length($signal->{type});
        }
    }

    return %types;
}

sub _transaction_port_signal_type_refs {
    my ($tx) = @_;
    my %types;

    for my $direction (qw(inputs outputs)) {
        for my $port (@{($tx->{ports} || {})->{$direction} || []}) {
            $types{$port->{name}} = $port->{type}
                if defined($port->{type}) && !ref($port->{type}) && length($port->{type});
        }
    }

    return %types;
}

sub _declared_storage_roles {
    my ($actor) = @_;
    my %roles;

    for my $entry (@{$actor->{storage} || []}) {
        for my $signal (@{$entry->{signals} || []}) {
            $roles{$signal->{name}} = 'actor_storage';
        }
    }

    return %roles;
}

sub _build_child_ports {
    my ($self, $actor, $tx, $states, $dts, $used_drives) = @_;

    my %actor_output_width = map {
        $_->{name} => ($_->{width} // 1)
    } @{$actor->{interface}{outputs} || []};

    my @ports;
    my %seen;
    for my $input (@{$actor->{interface}{inputs} || []}) {
        _push_port(\@ports, \%seen, $input->{name}, 'input', $input->{width} // 1);
    }

    for my $input (@{($tx->{ports} || {})->{inputs} || []}) {
        _push_port(\@ports, \%seen, $input->{name}, 'input', $input->{width} // 1);
    }

    my %assigned_public_outputs;
    for my $assignment (_all_ir_assignments($states, $dts)) {
        my $lhs = $assignment->{lhs};
        next unless defined($lhs) && !ref($lhs);
        next unless exists $actor_output_width{$lhs};
        next if ($assignment->{source_kind} // '') =~ /\Adrive_call_/;
        $assigned_public_outputs{$lhs} = 1;
    }

    for my $name (sort keys %assigned_public_outputs) {
        _push_port(\@ports, \%seen, $name, 'output', $actor_output_width{$name});
    }

    for my $output (@{($tx->{ports} || {})->{outputs} || []}) {
        _push_port(\@ports, \%seen, $output->{name}, 'output', $output->{width} // 1);
    }

    _push_port(\@ports, \%seen, 'start', 'input', 1);
    _push_port(\@ports, \%seen, 'done', 'output', 1);

    for my $drive_name (sort keys %{$used_drives || {}}) {
        my $drive = ($actor->{drives} || {})->{$drive_name} || next;
        _push_port(\@ports, \%seen, "${drive_name}_start", 'output', 1);
        for my $param (@{$drive->{params} || []}) {
            _push_port(\@ports, \%seen, "${drive_name}_$param", 'output',
                _drive_param_width($actor, $drive_name, $param));
        }
    }

    return \@ports;
}

sub _push_port {
    my ($ports, $seen, $name, $direction, $width) = @_;
    return if !defined($name) || ref($name) || !length($name);
    return if $seen->{$name}++;
    push @$ports, { name => $name, direction => $direction, width => $width || 1 };
}

sub _ensure_port {
    my ($ports, $name, $direction, $width, $context) = @_;
    for my $port (@$ports) {
        my $prefix = defined($context) && length($context)
            ? $context
            : 'ISF generated handoff';
        confess "$prefix port '$name' conflicts with existing actor interface port '$name'\n"
            if $port->{name} eq $name;
    }
    push @$ports, { name => $name, direction => $direction, width => $width, isf_handoff => 1 };
}

sub _collect_named_drive_call_names {
    my ($node, $drives) = @_;
    my %used;
    _collect_named_drive_call_names_into($node, $drives || {}, \%used);
    return %used;
}

sub _collect_named_drive_call_names_into {
    my ($node, $drives, $used) = @_;
    return unless ref($node) eq 'ARRAY';

    if (@$node >= 2
        && defined($node->[0])
        && !ref($node->[0])
        && $node->[0] eq 'drive'
        && defined($node->[1])
        && !ref($node->[1])
        && exists $drives->{$node->[1]})
    {
        $used->{$node->[1]} = 1;
    }

    for my $child (@$node) {
        _collect_named_drive_call_names_into($child, $drives, $used)
            if ref($child) eq 'ARRAY';
    }
}

sub _register_drive_call_signal_widths {
    my ($actor, $counters, $used_drives, $storage_roles) = @_;
    for my $drive_name (sort keys %{$used_drives || {}}) {
        my $drive = ($actor->{drives} || {})->{$drive_name} || next;
        $counters->{"${drive_name}_start"} = 1;
        $storage_roles->{"${drive_name}_start"} = 'drive_request'
            if ref($storage_roles) eq 'HASH';
        for my $param (@{$drive->{params} || []}) {
            $counters->{"${drive_name}_$param"} = _drive_param_width($actor, $drive_name, $param);
            $storage_roles->{"${drive_name}_$param"} = 'drive_payload'
                if ref($storage_roles) eq 'HASH';
        }
    }
}

sub _drive_param_width {
    my ($actor, $drive_name, $param) = @_;
    my $drive = ($actor->{drives} || {})->{$drive_name} || {};
    my $width = 1;
    for my $pair (@{$drive->{body} || []}) {
        next unless ref($pair) eq 'ARRAY' && @$pair >= 2 && $pair->[1] eq $param;
        for my $port (@{$actor->{interface}{outputs} || []}) {
            $width = $port->{width} if $port->{name} eq $pair->[0];
        }
    }
    return $width || 1;
}

sub _all_ir_assignments {
    my ($states, $dts) = @_;
    my @assignments;
    for my $state (@{$states || []}) {
        push @assignments, @{$state->{assignments} || []};
    }
    for my $dt (@{$dts || []}) {
        push @assignments, @{$dt->{assignments} || []};
    }
    return @assignments;
}

sub _build_signal_width_map {
    my ($actor, $tx) = @_;
    my %widths;
    for my $i (@{$actor->{interface}{inputs}})  { $widths{$i->{name}} = $i->{width} // 1; }
    for my $o (@{$actor->{interface}{outputs}}) { $widths{$o->{name}} = $o->{width} // 1; }
    for my $entry (@{$actor->{storage} || []}) {
        for my $signal (@{$entry->{signals} || []}) {
            $widths{$signal->{name}} = $signal->{width};
        }
    }
    for my $direction (qw(inputs outputs)) {
        for my $port (@{($tx->{ports} || {})->{$direction} || []}) {
            $widths{$port->{name}} = $port->{width} // 1;
        }
    }
    _collect_sample_widths($tx->{clauses}, \%widths);
    _collect_shift_widths($tx->{clauses}, \%widths);
    _collect_data_widths($tx->{clauses}, \%widths);
    _collect_extract_widths($tx->{clauses}, \%widths);
    _collect_data_widths($tx->{clauses}, \%widths);
    return \%widths;
}

sub _collect_sample_widths {
    my ($node, $widths) = @_;
    return unless ref($node) eq 'ARRAY';

    if (@$node >= 4 && $node->[0] eq 'sample' && $node->[2] eq 'as') {
        my ($source, $alias) = ($node->[1], $node->[3]);
        $widths->{$alias} = $widths->{$source} if exists $widths->{$source};
    }

    for my $child (@$node) {
        _collect_sample_widths($child, $widths) if ref($child) eq 'ARRAY';
    }
}

sub _collect_data_widths {
    my ($node, $widths) = @_;
    return unless ref($node) eq 'ARRAY';

    if (@$node >= 4 && $node->[0] eq 'assemble') {
        my ($target, @parts) = _parse_assemble_clause($node);
        my ($part_widths, $total) = _resolve_assemble_widths($target, \@parts, $widths);
        for my $idx (0 .. $#parts) {
            next unless defined($part_widths->[$idx]) && $part_widths->[$idx] > 0;
            my $part = $parts[$idx];
            $widths->{$part} = $part_widths->[$idx]
                unless exists($widths->{$part}) && defined($widths->{$part}) && $widths->{$part} > 0;
        }
        $widths->{$target} = $total
            if defined($total)
                && $total > 0
                && !(defined($widths->{$target}) && $widths->{$target} > 0);
    }

    for my $child (@$node) {
        _collect_data_widths($child, $widths) if ref($child) eq 'ARRAY';
    }
}

sub _collect_shift_widths {
    my ($node, $widths) = @_;
    return unless ref($node) eq 'ARRAY';

    if (@$node >= 4 && ($node->[0] eq 'shift_left' || $node->[0] eq 'shift_right')) {
        my $keyword = $node->[0];
        my $explicit_width = _parse_shift_width($node, $keyword);
        my $target = $node->[1];
        if (defined($explicit_width) && defined($target) && !ref($target)) {
            my $known_width = $widths->{$target};
            confess "$keyword explicit width $explicit_width conflicts with known width $known_width for '$target'\n"
                if defined($known_width) && $known_width > 0 && $known_width != $explicit_width;
            $widths->{$target} = $explicit_width unless defined($known_width) && $known_width > 0;
        }
    }

    for my $child (@$node) {
        _collect_shift_widths($child, $widths) if ref($child) eq 'ARRAY';
    }
}

sub _collect_extract_widths {
    my ($node, $widths) = @_;
    return unless ref($node) eq 'ARRAY';

    if (@$node >= 5 && $node->[0] eq 'extract') {
        my ($word, $fields, $explicit_widths) = _parse_extract_clause($node);
        my @field_widths = _resolve_extract_field_widths(
            $word,
            $fields,
            $explicit_widths,
            $widths,
            { strict => 0 },
        );
        for my $idx (0 .. $#$fields) {
            next unless defined($field_widths[$idx]) && $field_widths[$idx] > 0;
            my $field = $fields->[$idx];
            $widths->{$field} = $field_widths[$idx]
                unless exists($widths->{$field}) && defined($widths->{$field}) && $widths->{$field} > 0;
        }
    }

    for my $child (@$node) {
        _collect_extract_widths($child, $widths) if ref($child) eq 'ARRAY';
    }
}

sub _as_index {
    my ($cl, $start) = @_;
    for my $idx ($start .. $#$cl) {
        return $idx if defined $cl->[$idx] && !ref($cl->[$idx]) && $cl->[$idx] eq 'as';
    }
    return undef;
}

sub _parse_assemble_clause {
    my ($cl) = @_;
    my $as_idx = _as_index($cl, 2);
    confess "assemble requires '(assemble part... as target)'\n"
        unless defined $as_idx && $as_idx > 1 && $as_idx == $#$cl - 1;

    my @parts = @{$cl}[1 .. $as_idx - 1];
    my $target = $cl->[$as_idx + 1];
    for my $part (@parts) {
        confess "assemble parts must be scalar names\n"
            if !defined($part) || ref($part) || !length($part);
    }
    confess "assemble target must be a scalar name\n"
        if !defined($target) || ref($target) || !length($target);
    return ($target, @parts);
}

sub _resolve_assemble_widths {
    my ($target, $parts, $widths) = @_;
    my @part_widths;
    my @unknown_indices;
    my $known_total = 0;

    for my $idx (0 .. $#$parts) {
        my $part = $parts->[$idx];
        my $part_width = $widths->{$part};
        if (defined($part_width) && $part_width > 0) {
            $part_widths[$idx] = $part_width;
            $known_total += $part_width;
            next;
        }

        push @unknown_indices, $idx;
    }

    my $target_width = $widths->{$target};
    if (@unknown_indices == 1 && defined($target_width) && $target_width > 0) {
        my $idx = $unknown_indices[0];
        my $part = $parts->[$idx];
        my $inferred_width = $target_width - $known_total;
        confess "assemble known part widths sum $known_total leaves no positive width for '$part' in known width $target_width target '$target'\n"
            unless $inferred_width > 0;
        $part_widths[$idx] = $inferred_width;
        @unknown_indices = ();
    }

    return (\@part_widths, undef) if @unknown_indices;

    my $total = 0;
    $total += $_ for @part_widths;
    confess "assemble part widths sum $total conflicts with known width $target_width for '$target'\n"
        if defined($target_width) && $target_width > 0 && $target_width != $total;

    return (\@part_widths, $total);
}

sub _parse_extract_clause {
    my ($cl) = @_;
    confess "extract requires '(extract word as field...)'\n"
        unless @$cl >= 4 && defined $cl->[2] && !ref($cl->[2]) && $cl->[2] eq 'as';

    my $word = $cl->[1];
    my @items = @{$cl}[3 .. $#$cl];
    my @fields;
    my @explicit_widths;
    my $saw_widths;

    confess "extract word must be a scalar name\n"
        if !defined($word) || ref($word) || !length($word);
    confess "extract requires at least one scalar field\n" unless @items;

    for my $item (@items) {
        if (ref($item) eq 'ARRAY') {
            confess "extract field must be a scalar name\n"
                if @$item == 1 || grep { !defined($_) || ref($_) } @$item;
            confess "extract accepts at most one '(widths ...)' option\n"
                if $saw_widths;
            confess "extract optional arguments must be '(widths N...)'\n"
                unless @$item >= 2
                    && defined($item->[0])
                    && !ref($item->[0])
                    && $item->[0] eq 'widths';
            $saw_widths = 1;
            @explicit_widths = @{$item}[1 .. $#$item];
            for my $width (@explicit_widths) {
                confess "extract widths must be positive integers\n"
                    if !defined($width) || ref($width) || $width !~ /\A[1-9][0-9]*\z/;
                $width = 0 + $width;
            }
            next;
        }

        confess "extract fields must precede the '(widths ...)' option\n" if $saw_widths;
        confess "extract field must be a scalar name\n"
            if !defined($item) || ref($item) || !length($item);
        push @fields, $item;
    }

    confess "extract requires at least one scalar field\n" unless @fields;
    confess "extract '(widths ...)' count must match the field count\n"
        if @explicit_widths && @explicit_widths != @fields;

    return ($word, \@fields, \@explicit_widths);
}

sub _resolve_extract_field_widths {
    my ($word, $fields, $explicit_widths, $widths, $options) = @_;
    $options ||= {};
    my $strict = exists($options->{strict}) ? $options->{strict} : 1;
    my @field_widths;
    my @unknown_indices;
    my $known_total = 0;

    for my $idx (0 .. $#$fields) {
        my $field = $fields->[$idx];
        my $explicit_width = $explicit_widths->[$idx];
        my $known_width = $widths->{$field};

        confess "extract explicit width for '$field' conflicts with known width\n"
            if defined($explicit_width)
                && defined($known_width)
                && $known_width > 0
                && $explicit_width != $known_width;

        my $field_width = defined($explicit_width) ? $explicit_width : $known_width;
        if (defined($field_width) && $field_width > 0) {
            $field_widths[$idx] = $field_width;
            $known_total += $field_width;
            next;
        }

        push @unknown_indices, $idx;
    }

    my $word_width = $widths->{$word};
    if (@unknown_indices == 1 && defined($word_width) && $word_width > 0) {
        my $idx = $unknown_indices[0];
        my $field = $fields->[$idx];
        my $inferred_width = $word_width - $known_total;
        confess "extract known field widths sum $known_total leaves no positive width for '$field' in known width $word_width source '$word'\n"
            unless $inferred_width > 0;
        $field_widths[$idx] = $inferred_width;
        @unknown_indices = ();
    }

    for my $idx (@unknown_indices) {
        my $field = $fields->[$idx];
        confess "extract width for '$field' is unknown; add an interface width or '(widths ...)' option\n"
            if $strict;
    }

    my $total_field_width = 0;
    my $all_fields_known = 1;
    for my $idx (0 .. $#$fields) {
        my $field_width = $field_widths[$idx];
        if (defined($field_width) && $field_width > 0) {
            $total_field_width += $field_width;
            next;
        }
        $all_fields_known = 0;
    }
    confess "extract field widths sum $total_field_width conflicts with known width $word_width for '$word'\n"
        if $all_fields_known && defined($word_width) && $word_width > 0 && $word_width != $total_field_width;

    return @field_widths;
}

sub _parse_shift_right_width {
    return _parse_shift_width($_[0], 'shift_right');
}

sub _parse_shift_left_width {
    return _parse_shift_width($_[0], 'shift_left');
}

sub _parse_shift_width {
    my ($cl, $keyword) = @_;
    $keyword //= $cl->[0];
    my $width;

    for my $idx (3 .. $#$cl) {
        my $option = $cl->[$idx];
        confess "$keyword optional arguments must be '(width N)'\n"
            unless ref($option) eq 'ARRAY' && @$option == 2 && $option->[0] eq 'width';
        confess "$keyword accepts at most one '(width N)' option\n"
            if defined $width;
        confess "$keyword width must be a positive integer\n"
            if ref($option->[1]) || $option->[1] !~ /\A[1-9][0-9]*\z/;
        $width = 0 + $option->[1];
    }

    return $width;
}

sub _register_counter_width {
    my ($counters, $name, $width) = @_;
    $width = 8 unless defined($width) && $width > 0;
    $counters->{$name} = $width
        if !defined($counters->{$name}) || $counters->{$name} < $width;
}

sub _register_repeat_counters {
    my ($counters, $storage_roles, $repeat_counter, $repeat_width, $dynamic_wait_counters) = @_;
    _register_counter_width($counters, $repeat_counter, $repeat_width)
        if $counters;
    $storage_roles->{$repeat_counter} = 'repeat_counter'
        if ref($storage_roles) eq 'HASH';

    for my $entry (@{$dynamic_wait_counters || []}) {
        next unless ref($entry) eq 'HASH';
        _register_counter_width($counters, $entry->{name}, $entry->{width})
            if $counters;
        $storage_roles->{$entry->{name}} = 'dynamic_wait_counter'
            if ref($storage_roles) eq 'HASH';
    }
}

sub _repeat_count_width {
    my ($count, $widths) = @_;
    return 8 if ref($count);
    return $widths->{$count}
        if defined($count) && exists($widths->{$count}) && $widths->{$count} > 0;
    if (defined($count)) {
        my $literal_width = _literal_repeat_count_width($count);
        return $literal_width if defined $literal_width;
    }
    return 8;
}

sub _literal_repeat_count_width {
    my ($count) = @_;
    return undef unless defined($count) && !ref($count) && $count =~ /\A(?:\+)?([0-9]+)\z/;

    my $limit = 0 + $1;
    my $width = 1;
    my $max_value = 1;
    while ($max_value < $limit) {
        ++$width;
        $max_value = (2 ** $width) - 1;
    }
    return $width;
}

# --- Transaction → IR states ---
sub _build_transaction($self, $tx, $actor, $txi, $generated_children = undef) {
    my $tn  = $tx->{name};
    my $wd  = $actor->{watchdog};
    my $drives = $actor->{drives} || {};
    $generated_children ||= {};
    my $constant_values = _actor_constant_value_map($actor);
    _validate_supported_transaction_clauses($tx->{clauses}, $tn, 'transaction', undef, $generated_children);
    my $widths = _build_signal_width_map($actor, $tx);
    my @st;
    my %ct;
    my @dt;
    my @ps;
    my @doc;
    my @spc;
    my @dps;
    my @contracts;
    my @bank_accesses;
    my %contract_names;
    my %storage_roles;
    my $si  = 0; my $ha = 0; my $wdc; my $lat;
    my $do_ordinal = 0;
    my $repeat_do_ordinal = 0;

    my %transaction_ports = _transaction_port_map($tx);
    for my $port (values %transaction_ports) {
        $ct{$port->{name}} = $port->{width} // 1;
        $storage_roles{$port->{name}} = 'transaction_port';
    }

    for my $cl (@{$tx->{clauses}}) {
        next unless ref($cl) eq 'ARRAY';
        my $k = $cl->[0];
        if    ($k eq 'on')       { push @st, _ir_on($cl, $tn, $si++); }
        elsif ($k eq 'drive')    {
            push @st, _ir_transaction_drive_clause($cl, $tn, $si++, $drives, [splice @ps]);
        }
        elsif ($k eq 'await')    { $ha=1; $wdc="${tn}_wd"; my $wd_override = _parse_await_wd($cl); push @st, _ir_await($cl, $tn, $si++, $wd_override || $wd, [splice @ps]); }
        elsif ($k eq 'atl_trigger') { push @st, _ir_atl_trigger($cl, $tn, $si++, [splice @ps]); }
        elsif ($k eq 'atl_trigger_batch') { push @st, _ir_atl_trigger_batch($cl, $tn, $si++, [splice @ps]); }
        elsif ($k eq 'sample')   { push @ps, $cl; }
        elsif ($k eq 'wait') {
            my $wait = _wait_count_spec($cl, $tn, 'transaction body', $actor, $widths, 1);
            if ($wait->{kind} eq 'static') {
                if ($wait->{cycles} > 0) {
                    push @st, @{_ir_wait($cl, $tn, \$si, [splice @ps], $actor, 'transaction body', $wait)};
                }
            } else {
                my ($states, $counter, $width) = _ir_dynamic_wait($cl, $tn, \$si, $wait, [splice @ps]);
                push @st, @$states;
                _register_counter_width(\%ct, $counter, $width);
                $storage_roles{$counter} = 'dynamic_wait_counter';
            }
        }
        elsif ($k eq 'while') {
            push @st, @{
                _ir_while(
                    $cl, $tn, \$si, [splice @ps], $wd, $drives, $widths,
                    \%ct, \%storage_roles, $actor, \@bank_accesses,
                )
            };
        }
        elsif ($k eq 'until') {
            push @st, @{
                _ir_until(
                    $cl, $tn, \$si, [splice @ps], $wd, $drives, $widths,
                    \%ct, \%storage_roles, $actor, \@bank_accesses,
                )
            };
        }
        elsif ($k eq 'update' || $k eq 'set') { _push_sample_state(\@st,$tn,\@ps,\$si); push @st, _ir_update($cl,$tn,$si++,$k); }
        elsif ($k eq 'phase')       { push @st, _ir_phase($cl,$tn,$si++); }
        elsif ($k eq 'stage')       { _push_sample_state(\@st,$tn,\@ps,\$si); push @st, _ir_stage($cl,$tn,$si++,$actor); }
        elsif ($k eq 'contract')    {
            _push_sample_state(\@st, $tn, \@ps, \$si);
            my ($cs, $cdt, $cm) = _ir_contract(
                $cl, $tn, $si++, $actor, $widths, \%ct, \%storage_roles, \%contract_names,
            );
            push @st, $cs;
            push @dt, $cdt;
            push @contracts, $cm;
        }
        elsif ($k eq 'shift_left')  { _push_sample_state(\@st,$tn,\@ps,\$si); push @st, _ir_shift_left($cl,$tn,$si++,$widths); }
        elsif ($k eq 'shift_right') { _push_sample_state(\@st,$tn,\@ps,\$si); push @st, _ir_shift_right($cl,$tn,$si++,$widths); }
        elsif ($k eq 'assemble')    { _push_sample_state(\@st,$tn,\@ps,\$si); push @st, _ir_assemble($cl,$tn,$si++); }
        elsif ($k eq 'extract')     { _push_sample_state(\@st,$tn,\@ps,\$si); push @st, _ir_extract($cl,$tn,$si++,$widths); }
        elsif ($k eq 'store' || $k eq 'load') {
            _push_sample_state(\@st, $tn, \@ps, \$si);
            my ($state, $accesses) = _ir_bank_access($cl, $tn, $si++, $actor, $widths, 'transaction');
            push @st, $state;
            push @bank_accesses, @$accesses;
        }
        elsif ($k eq 'complete') { push @st, _ir_complete($cl, $tn, $si++); }
        elsif ($k eq 'when' && !@st) { push @st, _ir_when_activation($cl,$tn,$si++); }
        elsif ($k eq 'when')     {
            my ($ws) = _expand_when($cl,$tn,\$si,\@ps,$drives,$wd,$widths,\%ct,\%storage_roles,$actor,\@bank_accesses,\@spc,$constant_values,$generated_children,\$repeat_do_ordinal);
            push @st, @$ws;
        }
        elsif ($k eq 'switch')   {
            my ($ss) = _expand_switch($cl,$tn,\$si,\@ps,$drives,$wd,$widths,\%ct,\%storage_roles,$actor,\@bank_accesses,\@spc,$constant_values,$generated_children,\$repeat_do_ordinal);
            push @st, @$ss;
        }
        elsif ($k eq 'repeat')   { my ($rs,$rc,$rw,$rdw) = _ir_repeat($cl,$tn,\$si,\@ps,$wd,$drives,$widths,$actor,\@bank_accesses,\@spc,$constant_values,$generated_children,\$repeat_do_ordinal); push @st,@$rs; _register_repeat_counters(\%ct,\%storage_roles,$rc,$rw,$rdw); }
        elsif ($k eq 'latency')  { $lat = _parse_latency($cl, $tn); }
        elsif ($k eq 'params')   { next; }
        elsif ($k eq 'do')       {
            my $do_ref = _do_ref_from_clause($cl, $tn, $do_ordinal++, $generated_children, $constant_values, $actor);
            push @doc, $do_ref;
            push @spc, _clone_isf_value($do_ref) if $do_ref->{generated_child};
            push @st, _ir_do($cl, $tn, $si++, $do_ref);
        }
        elsif ($k eq 'spawn')    { push @spc, _spawn_ref_from_clause($cl,$tn,$constant_values,$actor); push @dps, "$spc[-1]{instance}_done"; push @st, _ir_spawn($cl,$tn,$si++); }
        elsif ($k eq 'await_all') { push @st, _ir_sync_all($tn,$si++,\@dps); @dps = (); }
        elsif ($k eq 'await_any') { push @st, _ir_sync_any($tn,$si++,\@dps); @dps = (); }
    }

    if (@ps) { push @st, _ir_sample_state($tn, \@ps, $si++); }

    # Watchdog
    if ($ha && $wdc) {
        my $lim = $wd // 65536;
        $ct{$wdc} = int(log($lim)/log(2)) + 1;
        $storage_roles{$wdc} = 'watchdog_counter';
        _inj_watchdog(\@st, $tn, $wdc, $lim, \%ct);
    }

    # Latency
    if ($lat) {
        my ($cc,$inc,$err,$cdt) = _inj_latency(\@st, $tn, $lat, $ha, \%ct);
        $ct{$cc} = int(log($lat->{max}//256)/log(2)) + 1;
        $storage_roles{$cc} = 'latency_counter';
        $ct{$inc} = 1; $ct{$err} = 1;
        push @dt, $cdt;
    }

    _merge_sequential(\@st) if 0;  # disabled — needs more work
    _link_states(\@st, $tn);
    $ct{can_accept} = 1;
    for my $s (@st) { next unless $s->{kind} eq 'entry'; unshift @{$s->{assignments}}, { lhs => 'can_accept', rhs => 1, op => '=' }; }
    return (\@st, \%ct, \@dt, \@doc, \@spc, \@contracts, { %{$widths || {}} }, \%storage_roles, \@bank_accesses);
}

sub _merge_signal_widths {
    my ($merged, $widths, $transaction) = @_;
    return unless ref($widths) eq 'HASH';

    for my $name (sort keys %$widths) {
        my $width = $widths->{$name};
        next unless defined($width) && $width > 0;
        confess "signal width for '$name' conflicts across transactions while merging '$transaction'\n"
            if defined($merged->{$name}) && $merged->{$name} > 0 && $merged->{$name} != $width;
        $merged->{$name} = $width;
    }
}

sub _merge_signal_type_refs {
    my ($merged, $types) = @_;
    return unless ref($types) eq 'HASH';

    for my $name (sort keys %$types) {
        my $type = $types->{$name};
        next unless defined($type) && !ref($type) && length($type);
        $merged->{$name} = $type;
    }
}

sub _merge_storage_roles {
    my ($merged, $roles, $transaction) = @_;
    return unless ref($roles) eq 'HASH';

    for my $name (sort keys %$roles) {
        my $role = $roles->{$name};
        next unless defined($role) && length($role);
        confess "storage role for '$name' conflicts across transactions while merging '$transaction'\n"
            if defined($merged->{$name}) && $merged->{$name} ne $role;
        $merged->{$name} = $role;
    }
}

sub _validate_supported_transaction_clauses {
    my ($clauses, $tn, $context, $context_depths, $generated_children) = @_;
    return unless ref($clauses) eq 'ARRAY';
    $context_depths ||= {};
    $generated_children ||= {};

    my $allowed = $SUPPORTED_TRANSACTION_CLAUSES{$context} || {};
    my $label = $TRANSACTION_CONTEXT_LABEL{$context} || $context;

    for my $clause (@$clauses) {
        confess "Transaction '$tn': transaction clauses must be list forms in $label\n"
            unless ref($clause) eq 'ARRAY';
        next unless @$clause;

        my $keyword = $clause->[0];
        confess "Transaction '$tn': transaction clause heads must be scalar in $label\n"
            unless defined($keyword) && !ref($keyword) && length($keyword);

        if (defined($keyword) && !ref($keyword) && $keyword eq 'contract' && $context ne 'transaction') {
            confess "Transaction '$tn': temporal '(contract ...)' clauses are supported only as top-level transaction clauses\n";
        }
        if (defined($keyword) && !ref($keyword) && $keyword eq 'stage' && $context ne 'transaction') {
            confess "Transaction '$tn': pipeline '(stage ...)' clauses are supported only as top-level transaction clauses\n";
        }
        if (defined($keyword) && !ref($keyword) && $keyword eq 'assign') {
            confess _removed_assign_clause_diagnostic($tn, $label);
        }
        confess "Transaction '$tn': unsupported '($keyword ...)' clause in $label\n"
            unless $allowed->{$keyword};

        if ($keyword eq 'on') {
            _validate_on_clause($clause, $tn, $label);
        } elsif ($keyword eq 'complete') {
            _validate_complete_clause($clause, $tn, $label);
        } elsif ($keyword eq 'sample') {
            _validate_sample_clause($clause, $tn, $label);
        } elsif ($keyword eq 'wait') {
            _validate_wait_clause($clause, $tn, $label);
        } elsif ($keyword eq 'update' || $keyword eq 'set') {
            _validate_update_clause($clause, $tn, $label, $keyword);
        } elsif ($keyword eq 'store' || $keyword eq 'load') {
            _validate_bank_access_clause($clause, $tn, $label);
        } elsif ($keyword eq 'shift_left' || $keyword eq 'shift_right') {
            _validate_shift_clause($clause, $tn, $label);
        } elsif ($keyword eq 'when') {
            _validate_when_clause($clause, $tn, $label);
            my %next_depths = (%$context_depths, when => (($context_depths->{when} // 0) + 1));
            _validate_supported_transaction_clauses([@{$clause}[2 .. $#$clause]], $tn, 'when', \%next_depths, $generated_children);
        } elsif ($keyword eq 'repeat') {
            _validate_repeat_clause($clause, $tn, $label);
            _validate_repeat_body_spawn_subset($clause, $tn, $label, $context_depths, $generated_children);
            _validate_supported_transaction_clauses([@{$clause}[2 .. $#$clause]], $tn, 'repeat', $context_depths, $generated_children);
        } elsif ($keyword eq 'while' || $keyword eq 'until') {
            _validate_loop_clause($clause, $tn, $label, $keyword);
            my %next_depths = (%$context_depths, $keyword => (($context_depths->{$keyword} // 0) + 1));
            _validate_supported_transaction_clauses([@{$clause}[2 .. $#$clause]], $tn, $keyword, \%next_depths, $generated_children);
        } elsif ($keyword eq 'await_all' || $keyword eq 'await_any') {
            _validate_sync_clause($clause, $tn, $label);
        } elsif ($keyword eq 'do' || $keyword eq 'spawn') {
            _validate_child_action_clause($clause, $tn, $label);
        } elsif ($keyword eq 'stage') {
            _validate_stage_clause($clause, $tn, $label);
        } elsif ($keyword eq 'contract') {
            _validate_contract_clause($clause, $tn, $label);
        } elsif ($keyword eq 'switch') {
            _validate_switch_clause($clause, $tn, $label);
            for my $branch (@{$clause}[2 .. $#$clause]) {
                next unless ref($branch) eq 'ARRAY';
                my %next_depths = (%$context_depths, switch => (($context_depths->{switch} // 0) + 1));
                _validate_supported_transaction_clauses([@{$branch}[1 .. $#$branch]], $tn, 'switch', \%next_depths, $generated_children);
            }
        }
    }
}

sub _validate_on_clause {
    my ($clause, $tn, $label) = @_;

    confess "Transaction '$tn': on requires '(on port [sample...])' in $label\n"
        unless @$clause >= 2
            && defined($clause->[1])
            && !ref($clause->[1])
            && length($clause->[1]);

    for my $i (2 .. $#$clause) {
        my $body_clause = $clause->[$i];
        confess "Transaction '$tn': on body supports only '(sample port as name)' clauses\n"
            unless ref($body_clause) eq 'ARRAY'
                && @$body_clause
                && defined($body_clause->[0])
                && !ref($body_clause->[0])
                && $body_clause->[0] eq 'sample';
        _validate_sample_clause($body_clause, $tn, 'on body');
    }

    return 1;
}

sub _validate_shift_clause {
    my ($clause, $tn, $label) = @_;
    my $keyword = $clause->[0];
    my $shape = $keyword eq 'shift_left'
        ? '(shift_left reg bit [(width N)])'
        : '(shift_right reg bit [(width N)])';

    confess "Transaction '$tn': $keyword requires '$shape' in $label\n"
        unless @$clause >= 3
            && @$clause <= 4
            && defined($clause->[1])
            && !ref($clause->[1])
            && length($clause->[1])
            && defined($clause->[2])
            && !ref($clause->[2])
            && length($clause->[2]);

    return 1;
}

sub _validate_when_clause {
    my ($clause, $tn, $label) = @_;

    confess "Transaction '$tn': when requires '(when condition body...)' in $label\n"
        unless @$clause >= 3
            && defined($clause->[1])
            && (
                (ref($clause->[1]) eq 'ARRAY' && @{$clause->[1]})
                || (!ref($clause->[1]) && length($clause->[1]))
            );

    for my $body_clause (@{$clause}[2 .. $#$clause]) {
        confess "Transaction '$tn': when body clauses must be list forms in $label\n"
            unless ref($body_clause) eq 'ARRAY';
    }

    return 1;
}

sub _validate_switch_clause {
    my ($clause, $tn, $label) = @_;

    confess "Transaction '$tn': switch requires '(switch signal (value body...)...)' in $label\n"
        unless @$clause >= 3
            && defined($clause->[1])
            && !ref($clause->[1])
            && length($clause->[1]);

    for my $branch (@{$clause}[2 .. $#$clause]) {
        confess "Transaction '$tn': switch branches require '(value body...)' in $label\n"
            unless ref($branch) eq 'ARRAY'
                && @$branch >= 2
                && defined($branch->[0])
                && !ref($branch->[0])
                && length($branch->[0]);

        for my $body_clause (@{$branch}[1 .. $#$branch]) {
            confess "Transaction '$tn': switch branches require '(value body...)' in $label\n"
                unless ref($body_clause) eq 'ARRAY';
        }
    }

    return 1;
}

sub _removed_assign_clause_diagnostic {
    my ($tn, $label) = @_;
    return "Transaction '$tn': removed '(assign ...)' clause is unsupported in $label; "
        . "use '(set var expr)' for explicit scalar flopped updates, "
        . "'(update var expr)' for the older transaction-local spelling, "
        . "'(drive ...)' for protocol/output drives, rule '(set port expr)' or '(port expr)' actions "
        . "for rule-driven assignments, or '(complete port)' for completion pulses\n";
}

sub _validate_stage_clause {
    my ($clause, $tn, $label) = @_;

    _parse_stage_handshake_clause($clause, $tn, $label);
    return 1;
}

sub _validate_contract_clause {
    my ($clause, $tn, $label) = @_;

    _parse_bounded_eventual_contract_clause($clause, $tn, $label);
    return 1;
}

sub _parse_stage_handshake_clause {
    my ($clause, $tn, $label) = @_;

    confess "Transaction '$tn': stage requires '(stage name (ready ready_signal) (valid valid_signal))' or '(stage name (input ready_signal) (output valid_signal))' in $label\n"
        unless ref($clause) eq 'ARRAY'
            && @$clause >= 2
            && defined($clause->[1])
            && !ref($clause->[1])
            && length($clause->[1]);

    my %seen;
    my %role_for = (
        input  => 'ready',
        ready  => 'ready',
        output => 'valid',
        valid  => 'valid',
    );
    my %parsed = (name => $clause->[1]);

    for my $subclause (@{$clause}[2 .. $#$clause]) {
        confess "Transaction '$tn': stage '$parsed{name}' subclauses must be '(ready ready_signal)'/'(valid valid_signal)' or '(input ready_signal)'/'(output valid_signal)' in $label\n"
            unless ref($subclause) eq 'ARRAY'
                && @$subclause == 2
                && defined($subclause->[0])
                && !ref($subclause->[0])
                && length($subclause->[0]);

        my ($head, $signal) = @$subclause;
        confess "Transaction '$tn': stage '$parsed{name}' has unsupported subclause '$head'\n"
            unless exists $role_for{$head};
        my $role = $role_for{$head};
        confess "Transaction '$tn': duplicate stage '$parsed{name}' $role endpoint\n"
            if $seen{$role}++;
        confess "Transaction '$tn': stage '$parsed{name}' $head signal must be scalar\n"
            unless defined($signal) && !ref($signal) && length($signal);

        $parsed{$role} = $signal;
    }

    confess "Transaction '$tn': stage '$parsed{name}' requires '(ready ready_signal)' or '(input ready_signal)'\n"
        unless defined($parsed{ready});
    confess "Transaction '$tn': stage '$parsed{name}' requires '(valid valid_signal)' or '(output valid_signal)'\n"
        unless defined($parsed{valid});

    return \%parsed;
}

sub _parse_bounded_eventual_contract_clause {
    my ($clause, $tn, $label) = @_;

    confess "Transaction '$tn': contract requires '(contract name (eventually signal within cycles))' or '(contract name (eventually signal (within cycles)))' in $label\n"
        unless ref($clause) eq 'ARRAY'
            && @$clause == 3
            && defined($clause->[1])
            && !ref($clause->[1])
            && length($clause->[1]);

    my $name = $clause->[1];
    my $eventual = $clause->[2];
    confess "Transaction '$tn': contract '$name' supports only '(eventually signal within cycles)' or '(eventually signal (within cycles))'\n"
        unless ref($eventual) eq 'ARRAY'
            && defined($eventual->[0])
            && !ref($eventual->[0])
            && $eventual->[0] eq 'eventually'
            && defined($eventual->[1])
            && !ref($eventual->[1])
            && length($eventual->[1]);

    my $within_cycles;
    if (
        @$eventual == 4
        && defined($eventual->[2])
        && !ref($eventual->[2])
        && $eventual->[2] eq 'within'
        && defined($eventual->[3])
        && !ref($eventual->[3])
        && $eventual->[3] =~ /\A[1-9][0-9]*\z/
    ) {
        $within_cycles = $eventual->[3];
    }
    elsif (
        @$eventual == 3
        && ref($eventual->[2]) eq 'ARRAY'
        && @{$eventual->[2]} == 2
        && defined($eventual->[2][0])
        && !ref($eventual->[2][0])
        && $eventual->[2][0] eq 'within'
        && defined($eventual->[2][1])
        && !ref($eventual->[2][1])
        && $eventual->[2][1] =~ /\A[1-9][0-9]*\z/
    ) {
        $within_cycles = $eventual->[2][1];
    }
    else {
        confess "Transaction '$tn': contract '$name' supports only '(eventually signal within cycles)' or '(eventually signal (within cycles))'\n";
    }

    return {
        name          => $name,
        signal        => $eventual->[1],
        within_cycles => 0 + $within_cycles,
    };
}

sub _validate_child_action_clause {
    my ($clause, $tn, $label) = @_;
    my $keyword = $clause->[0];

    if ($keyword eq 'do') {
        confess "Transaction '$tn': do requires '(do transaction [(domain name)] [(params (NAME value) ...)] [(bind ...)])' in $label\n"
            unless @$clause >= 2
                && defined($clause->[1])
                && !ref($clause->[1])
                && length($clause->[1]);

        my %seen_subclause;
        for my $subclause (@{$clause}[2 .. $#$clause]) {
            confess "Transaction '$tn': do subclauses must be '(domain ...)', '(params ...)', or '(bind ...)' in $label\n"
                unless ref($subclause) eq 'ARRAY'
                    && @$subclause
                    && defined($subclause->[0])
                    && !ref($subclause->[0])
                    && length($subclause->[0]);
            my $head = $subclause->[0];
            confess "Transaction '$tn': do has duplicate '$head' subclause in $label\n"
                if $seen_subclause{$head}++;
            if ($head eq 'params') {
                _validate_activation_params_clause_shape($subclause, $tn, 'do', $clause->[1], $label);
                next;
            }
            if ($head eq 'domain') {
                _activation_domain_from_clause(['do', $clause->[1], $subclause], $tn, $label);
                next;
            }
            if ($head eq 'bind') {
                _parse_activation_bind_clause($subclause, "Transaction '$tn': do target '$clause->[1]'");
                next;
            }
            confess "Transaction '$tn': do has unsupported '$head' subclause in $label\n";
        }
        _activation_bindings_from_clause($clause, $tn, $label);
        return 1;
    }

    confess "Transaction '$tn': spawn requires '(spawn transaction as instance [(domain name)] [(params (NAME value) ...)] [(bind ...)])' in $label\n"
        unless @$clause >= 4
            && defined($clause->[1])
            && !ref($clause->[1])
            && length($clause->[1])
            && defined($clause->[2])
            && !ref($clause->[2])
            && $clause->[2] eq 'as'
            && defined($clause->[3])
            && !ref($clause->[3])
            && length($clause->[3]);

    my %seen_subclause;
    for my $subclause (@{$clause}[4 .. $#$clause]) {
        confess "Transaction '$tn': spawn subclauses must be '(domain ...)', '(params ...)', or '(bind ...)' in $label\n"
            unless ref($subclause) eq 'ARRAY'
                && @$subclause
                && defined($subclause->[0])
                && !ref($subclause->[0])
                && length($subclause->[0]);
        my $head = $subclause->[0];
        confess "Transaction '$tn': spawn has duplicate '$head' subclause in $label\n"
            if $seen_subclause{$head}++;
        if ($head eq 'params') {
            _validate_activation_params_clause_shape($subclause, $tn, 'spawn', $clause->[3], $label);
            next;
        }
        if ($head eq 'domain') {
            _activation_domain_from_clause(['spawn', $clause->[1], 'as', $clause->[3], $subclause], $tn, $label);
            next;
        }
        if ($head eq 'bind') {
            _parse_activation_bind_clause($subclause, "Transaction '$tn': spawn instance '$clause->[3]'");
            next;
        }
        confess "Transaction '$tn': spawn has unsupported '$head' subclause in $label\n";
    }

    return 1;
}

sub _validate_rule_trigger_action_clause {
    my ($clause, $rule_name, $label) = @_;

    confess "Rule '$rule_name': trigger requires '(trigger transaction [(params (NAME value) ...)] [(bind ...)])' in $label\n"
        unless ref($clause) eq 'ARRAY'
            && @$clause >= 2
            && defined($clause->[0])
            && !ref($clause->[0])
            && $clause->[0] eq 'trigger'
            && defined($clause->[1])
            && !ref($clause->[1])
            && length($clause->[1]);

    my $target = $clause->[1];
    my %seen_subclause;
    for my $subclause (@{$clause}[2 .. $#$clause]) {
        confess "Rule '$rule_name': trigger subclauses must be '(params ...)' or '(bind ...)' in $label\n"
            unless ref($subclause) eq 'ARRAY'
                && @$subclause
                && defined($subclause->[0])
                && !ref($subclause->[0])
                && length($subclause->[0]);
        my $head = $subclause->[0];
        confess "Rule '$rule_name': trigger has duplicate '$head' subclause in $label\n"
            if $seen_subclause{$head}++;
        if ($head eq 'params') {
            _validate_activation_params_clause_shape($subclause, $rule_name, 'trigger', $target, $label);
            next;
        }
        if ($head eq 'bind') {
            _parse_activation_bind_clause($subclause, "Rule '$rule_name': trigger target '$target'");
            next;
        }
        confess "Rule '$rule_name': trigger has unsupported '$head' subclause in $label\n";
    }

    return 1;
}

sub _validate_sync_clause {
    my ($clause, $tn, $label) = @_;
    my $keyword = $clause->[0];

    confess "Transaction '$tn': $keyword requires '($keyword done_port)' in $label\n"
        unless @$clause == 2
            && defined($clause->[1])
            && !ref($clause->[1])
            && length($clause->[1]);

    return 1;
}

sub _transaction_param_declarations {
    my ($tx, $actor) = @_;
    return [] unless ref($tx) eq 'HASH';

    my $tx_name = $tx->{name} // 'unknown';
    my @param_clauses = grep {
        ref($_) eq 'ARRAY' && @$_ && defined($_->[0]) && !ref($_->[0]) && $_->[0] eq 'params'
    } @{$tx->{clauses} || []};

    confess "Transaction '$tx_name': transaction parameters allow at most one '(params ...)' clause\n"
        if @param_clauses > 1;
    return [] unless @param_clauses;

    my $params_clause = $param_clauses[0];
    confess "Transaction '$tx_name': params require '(params (NAME value) ...)'\n"
        unless @$params_clause >= 2;

    my @params;
    my %seen;
    for my $entry (@{$params_clause}[1 .. $#$params_clause]) {
        confess "Transaction '$tx_name': params entries require '(NAME value)'\n"
            unless ref($entry) eq 'ARRAY' && @$entry == 2;
        my ($name, $value) = @$entry;
        confess "Transaction '$tx_name': parameter names must be scalar HDL identifiers\n"
            unless _is_hdl_identifier($name);
        confess "Transaction '$tx_name': duplicate parameter '$name'\n"
            if $seen{$name}++;
        _validate_transaction_param_value(
            $value,
            "Transaction '$tx_name': parameter '$name'",
            $actor,
        );
        my %param = (
            name  => $name,
            value => _clone_isf_value($value),
        );
        $param{resolved_value} = _clone_isf_value(_resolve_actor_enum_member_value($actor, $value))
            if _is_enum_member_reference($value);
        if (ref($value)) {
            my ($resolved_value, $has_enum_leaf) = _resolve_transaction_param_default_value(
                $value,
                "Transaction '$tx_name': parameter '$name'",
                $actor,
            );
            $param{resolved_value} = _clone_isf_value($resolved_value)
                if $has_enum_leaf;
        }
        push @params, \%param;
    }

    return \@params;
}

sub _spawn_ref_from_clause {
    my ($clause, $tn, $constant_values, $actor, $label) = @_;
    $label //= 'transaction body';
    my $instance = $clause->[3] // "${tn}_spawn";
    my $ref = {
        child => $clause->[1],
        instance => $instance,
        parameter_overrides => _spawn_parameter_overrides($clause, $tn, $label, $constant_values, $actor),
    };
    my $domain = _activation_domain_from_clause($clause, $tn, $label);
    $ref->{domain} = $domain if defined $domain;
    my $port_bindings = _activation_bindings_from_clause($clause, $tn, $label);
    $ref->{port_bindings} = $port_bindings if @$port_bindings;
    return $ref;
}

sub _do_ref_from_clause {
    my ($clause, $tn, $ordinal, $generated_children, $constant_values, $actor) = @_;
    my $child = $clause->[1];
    my $generated_child = $generated_children && $generated_children->{$child} ? 1 : 0;
    my $ref = {
        child           => $child,
        activation_kind => 'do',
        generated_child => $generated_child,
    };

    my $overrides = _do_parameter_overrides($clause, $tn, 'transaction body', $constant_values, $actor);
    if ($generated_child) {
        my $instance = _generated_do_instance_name($tn, $child, $ordinal);
        $ref->{instance} = $instance;
        $ref->{parameter_overrides} = $overrides;
        my $domain = _activation_domain_from_clause($clause, $tn, 'transaction body');
        $ref->{domain} = $domain if defined $domain;
        my $port_bindings = _activation_bindings_from_clause($clause, $tn, 'transaction body');
        $ref->{port_bindings} = $port_bindings if @$port_bindings;
    }

    return $ref;
}

sub _repeat_do_ref_from_clause {
    my ($clause, $tn, $ordinal, $constant_values, $actor, $generated_children) = @_;
    my $child = $clause->[1];
    my $overrides = _do_parameter_overrides($clause, $tn, 'repeat body', $constant_values, $actor);
    my $generated_child = (
        @$overrides
            || (ref($generated_children) eq 'HASH' && $generated_children->{$child})
    ) ? 1 : 0;
    my $ref = {
        child           => $child,
        activation_kind => 'do',
        generated_child => $generated_child,
    };

    if ($generated_child) {
        $ref->{instance} = _generated_repeat_do_instance_name($tn, $child, $ordinal);
        $ref->{parameter_overrides} = $overrides;
        my $domain = _activation_domain_from_clause($clause, $tn, 'repeat body');
        $ref->{domain} = $domain if defined $domain;
        my $port_bindings = _activation_bindings_from_clause($clause, $tn, 'repeat body');
        $ref->{port_bindings} = $port_bindings if @$port_bindings;
    }

    return $ref;
}

sub _repeat_body_do_is_generated_activation {
    my ($clause, $target, $generated_children) = @_;
    return 1 if _repeat_body_do_uses_generated_params($clause);
    return 1 if ref($generated_children) eq 'HASH'
        && defined($target)
        && !ref($target)
        && $generated_children->{$target};
    return 0;
}

sub _repeat_body_do_uses_generated_params {
    my ($clause) = @_;
    return 0 unless ref($clause) eq 'ARRAY' && @$clause >= 3;
    for my $subclause (@{$clause}[2 .. $#$clause]) {
        next unless ref($subclause) eq 'ARRAY'
            && @$subclause
            && defined($subclause->[0])
            && !ref($subclause->[0]);
        return 1 if $subclause->[0] eq 'params';
    }
    return 0;
}

sub _repeat_body_do_uses_bindings {
    my ($clause) = @_;
    return 0 unless ref($clause) eq 'ARRAY' && @$clause >= 3;
    for my $subclause (@{$clause}[2 .. $#$clause]) {
        next unless ref($subclause) eq 'ARRAY'
            && @$subclause
            && defined($subclause->[0])
            && !ref($subclause->[0]);
        return 1 if $subclause->[0] eq 'bind';
    }
    return 0;
}

sub _repeat_body_do_uses_domain {
    my ($clause) = @_;
    return 0 unless ref($clause) eq 'ARRAY' && @$clause >= 3;
    for my $subclause (@{$clause}[2 .. $#$clause]) {
        next unless ref($subclause) eq 'ARRAY'
            && @$subclause
            && defined($subclause->[0])
            && !ref($subclause->[0]);
        return 1 if $subclause->[0] eq 'domain';
    }
    return 0;
}

sub _spawn_parameter_overrides {
    my ($clause, $tn, $label, $constant_values, $actor) = @_;
    return _activation_parameter_overrides($clause, $tn, $label, $constant_values, $actor);
}

sub _do_parameter_overrides {
    my ($clause, $tn, $label, $constant_values, $actor) = @_;
    return _activation_parameter_overrides($clause, $tn, $label, $constant_values, $actor);
}

sub _trigger_parameter_overrides {
    my ($clause, $rule_name, $label, $constant_values, $actor) = @_;
    return _activation_parameter_overrides($clause, $rule_name, $label, $constant_values, $actor);
}

sub _activation_parameter_overrides {
    my ($clause, $tn, $label, $constant_values, $actor) = @_;
    return [] unless ref($clause) eq 'ARRAY' && @$clause;
    my $keyword = $clause->[0];
    return [] unless defined($keyword) && !ref($keyword) && ($keyword eq 'spawn' || $keyword eq 'do' || $keyword eq 'trigger');
    my $start = $keyword eq 'spawn' ? 4 : 2;
    return [] if $#$clause < $start;

    my $instance = $keyword eq 'spawn'
        ? $clause->[3]
        : $clause->[1];
    for my $subclause (@{$clause}[$start .. $#$clause]) {
        next unless ref($subclause) eq 'ARRAY'
            && @$subclause
            && defined($subclause->[0])
            && !ref($subclause->[0])
            && $subclause->[0] eq 'params';
        return _parse_activation_params_clause($subclause, $tn, $keyword, $instance, $label, $constant_values, $actor);
    }
    return [];
}

sub _activation_domain_from_clause {
    my ($clause, $tn, $label) = @_;
    return undef unless ref($clause) eq 'ARRAY' && @$clause;
    my $keyword = $clause->[0];
    return undef unless defined($keyword) && !ref($keyword) && ($keyword eq 'spawn' || $keyword eq 'do');
    my $start = $keyword eq 'spawn' ? 4 : 2;
    return undef if $#$clause < $start;

    my $domain;
    for my $subclause (@{$clause}[$start .. $#$clause]) {
        next unless ref($subclause) eq 'ARRAY'
            && @$subclause
            && defined($subclause->[0])
            && !ref($subclause->[0])
            && $subclause->[0] eq 'domain';
        confess "Transaction '$tn': $keyword has duplicate '(domain ...)' subclause in $label\n"
            if defined $domain;
        confess "Transaction '$tn': $keyword domain requires '(domain name)' in $label\n"
            unless @$subclause == 2 && _is_hdl_identifier($subclause->[1]);
        $domain = $subclause->[1];
    }

    return $domain;
}

sub _parse_spawn_params_clause {
    my ($params_clause, $tn, $instance, $label, $constant_values, $actor) = @_;
    return _parse_activation_params_clause($params_clause, $tn, 'spawn', $instance, $label, $constant_values, $actor);
}

sub _parse_activation_params_clause {
    my ($params_clause, $tn, $activation_kind, $instance, $label, $constant_values, $actor) = @_;
    _validate_activation_params_clause_shape($params_clause, $tn, $activation_kind, $instance, $label);

    my @overrides;
    for my $entry (@{$params_clause}[1 .. $#$params_clause]) {
        my ($name, $value) = @$entry;
        my $resolved_value = _resolve_activation_param_value(
            $value,
            "Transaction '$tn': $activation_kind instance '$instance' parameter '$name'",
            $constant_values,
            $actor,
            1,
        );
        push @overrides, {
            name  => $name,
            value => $resolved_value,
        };
    }

    return \@overrides;
}

sub _validate_activation_params_clause_shape {
    my ($params_clause, $tn, $activation_kind, $instance, $label) = @_;
    confess "Transaction '$tn': $activation_kind params require '(params (NAME value) ...)' in $label\n"
        unless ref($params_clause) eq 'ARRAY'
            && @$params_clause >= 2
            && defined($params_clause->[0])
            && !ref($params_clause->[0])
            && $params_clause->[0] eq 'params';

    my %seen;
    for my $entry (@{$params_clause}[1 .. $#$params_clause]) {
        confess "Transaction '$tn': $activation_kind params entries require '(NAME value)' in $label\n"
            unless ref($entry) eq 'ARRAY' && @$entry == 2;
        my ($name, $value) = @$entry;
        confess "Transaction '$tn': $activation_kind parameter override names must be scalar HDL identifiers\n"
            unless _is_hdl_identifier($name);
        confess "Transaction '$tn': $activation_kind instance '$instance' has duplicate parameter override '$name'\n"
            if $seen{$name}++;
        confess "Transaction '$tn': $activation_kind instance '$instance' parameter '$name' value must be defined in $label\n"
            unless defined $value;
    }

    return 1;
}

sub _generated_do_instance_name {
    my ($owner, $child, $ordinal) = @_;
    return "${owner}_${child}_do_$ordinal";
}

sub _generated_repeat_do_instance_name {
    my ($owner, $child, $ordinal) = @_;
    return "${owner}_${child}_repeat_do_$ordinal";
}

sub _generated_rule_trigger_instance_name {
    my ($rule, $target, $ordinal) = @_;
    return "${rule}_${target}_trigger_$ordinal";
}

sub _do_clause_ordinal {
    my ($tx, $target_clause) = @_;
    my $ordinal = 0;
    for my $clause (@{$tx->{clauses} || []}) {
        next unless ref($clause) eq 'ARRAY'
            && @$clause
            && defined($clause->[0])
            && !ref($clause->[0])
            && $clause->[0] eq 'do';
        return $ordinal if $clause == $target_clause;
        ++$ordinal;
    }
    return 0;
}

sub _activation_bindings_from_clause {
    my ($clause, $owner, $label) = @_;
    return [] unless ref($clause) eq 'ARRAY' && @$clause;

    my $keyword = $clause->[0];
    my $start = $keyword eq 'spawn' ? 4 : 2;
    return [] if $#$clause < $start;

    my @bindings;
    my $saw_bind;
    for my $subclause (@{$clause}[$start .. $#$clause]) {
        confess "Transaction '$owner': activation subclauses must be list forms in $label\n"
            unless ref($subclause) eq 'ARRAY'
                && @$subclause
                && defined($subclause->[0])
                && !ref($subclause->[0])
                && length($subclause->[0]);
        my $head = $subclause->[0];
        next if ($keyword eq 'spawn' || $keyword eq 'do' || $keyword eq 'trigger') && $head eq 'params';
        next if ($keyword eq 'spawn' || $keyword eq 'do') && $head eq 'domain';
        confess "Transaction '$owner': activation has duplicate '(bind ...)' subclause in $label\n"
            if $head eq 'bind' && $saw_bind++;
        confess "Transaction '$owner': activation supports only '(bind ...)' subclauses in $label\n"
            unless $head eq 'bind';
        @bindings = @{_parse_activation_bind_clause($subclause, "Transaction '$owner': activation")};
    }

    return \@bindings;
}

sub _parse_activation_bind_clause {
    my ($clause, $context) = @_;
    confess "$context bind requires '(bind (input port signal) ...)'\n"
        unless ref($clause) eq 'ARRAY'
            && @$clause >= 2
            && defined($clause->[0])
            && !ref($clause->[0])
            && $clause->[0] eq 'bind';

    my @bindings;
    my %seen;
    for my $entry (@{$clause}[1 .. $#$clause]) {
        confess "$context bind entries must be '(input port signal)' or '(output port signal)'\n"
            unless ref($entry) eq 'ARRAY' && @$entry == 3;
        my ($role, $port, $actor_endpoint) = @$entry;
        confess "$context bind role must be input or output\n"
            unless defined($role) && !ref($role) && ($role eq 'input' || $role eq 'output');
        confess "$context bind transaction port must be a scalar HDL identifier\n"
            unless _is_hdl_identifier($port);
        if ($role eq 'output') {
            confess "$context output bind actor target must be a scalar HDL identifier\n"
                unless _is_hdl_identifier($actor_endpoint);
        } else {
            confess "$context input bind expression must be a scalar signal, numeric/exact-width literal, or non-empty list expression\n"
                unless _is_activation_input_binding_expr_shape($actor_endpoint);
        }
        confess "$context has duplicate binding for transaction port '$port'\n"
            if $seen{$port}++;

        my $actor_expr = _clone_isf_value($actor_endpoint);
        my $actor_signal = _is_hdl_identifier($actor_endpoint) ? $actor_endpoint : undef;
        push @bindings, {
            role             => $role,
            port             => $port,
            actor_signal     => $actor_signal,
            actor_expr       => $actor_expr,
            actor_expression => _format_isf_expr($actor_expr),
        };
    }

    return \@bindings;
}

sub _validate_activation_bindings {
    my ($actor, $owner_tx, $target_tx, $bindings, $context, $options) = @_;
    $options ||= {};
    $bindings ||= [];

    my %ports = _transaction_port_map($target_tx);
    my @declared_ports = sort keys %ports;
    confess "$context requires '(bind ...)' because transaction '$target_tx->{name}' declares ports\n"
        if @declared_ports && !@$bindings;
    confess "$context has '(bind ...)' but transaction '$target_tx->{name}' declares no ports\n"
        if !@declared_ports && @$bindings;

    my %seen;
    for my $binding (@$bindings) {
        my $port_name = $binding->{port};
        confess "$context binds unknown transaction port '$port_name' on '$target_tx->{name}'\n"
            unless exists $ports{$port_name};

        my $port = $ports{$port_name};
        confess "$context binding for port '$port_name' uses role '$binding->{role}' but the transaction declares '$port->{direction}'\n"
            unless $binding->{role} eq $port->{direction};
        confess "$context output binding for port '$port_name' is not supported on rule triggers yet\n"
            if exists($options->{allow_outputs}) && !$options->{allow_outputs} && $binding->{role} eq 'output';
        confess "$context has duplicate binding for transaction port '$port_name'\n"
            if $seen{$port_name}++;

        if ($binding->{role} eq 'input') {
            _validate_activation_input_binding_expr($actor, $owner_tx, $binding, $port, $context);
        } else {
            my $signal = $binding->{actor_signal};
            my $info = _binding_signal_info($actor, $owner_tx, $signal);
            confess "$context binding for port '$port_name' references unknown actor signal '$signal'\n"
                unless $info;
            confess "$context output binding for port '$port_name' targets actor input '$signal', but actor inputs are read-only\n"
                if $info->{kind} eq 'actor_input';

            my $port_width = $port->{width} // 1;
            my $signal_width = $info->{width} // 1;
            confess "$context binding for port '$port_name' width $port_width does not match actor signal '$signal' width $signal_width\n"
                unless $port_width == $signal_width;
        }
    }

    for my $port_name (@declared_ports) {
        confess "$context does not bind transaction port '$port_name'\n"
            unless $seen{$port_name};
    }

    return 1;
}

sub _transaction_port_map {
    my ($tx) = @_;
    my %ports;
    for my $direction (qw(input output)) {
        my $key = "${direction}s";
        for my $port (@{($tx->{ports} || {})->{$key} || []}) {
            $ports{$port->{name}} = {
                name      => $port->{name},
                direction => $direction,
                width     => $port->{width} // 1,
            };
        }
    }
    return %ports;
}

sub _binding_signal_info {
    my ($actor, $tx, $name) = @_;
    return undef unless _is_hdl_identifier($name);

    for my $input (@{$actor->{interface}{inputs} || []}) {
        return { kind => 'actor_input', width => $input->{width} // 1 }
            if $input->{name} eq $name;
    }
    for my $output (@{$actor->{interface}{outputs} || []}) {
        return { kind => 'actor_output', width => $output->{width} // 1 }
            if $output->{name} eq $name;
    }
    for my $entry (@{$actor->{storage} || []}) {
        for my $signal (@{$entry->{signals} || []}) {
            return { kind => 'actor_storage', width => $signal->{width} // 1 }
                if $signal->{name} eq $name;
        }
    }

    if ($tx) {
        my $widths = _build_signal_width_map($actor, $tx);
        return { kind => 'transaction_variable', width => $widths->{$name} }
            if exists $widths->{$name};
    }

    return undef;
}

sub _is_hdl_identifier {
    my ($value) = @_;
    return defined($value) && !ref($value) && $value =~ /\A[A-Za-z_]\w*\z/;
}

sub _is_enum_member_reference {
    my ($value) = @_;
    return defined($value)
        && !ref($value)
        && $value =~ /\A[A-Za-z_]\w*(?:\.[A-Za-z_]\w*)+\z/;
}

sub _is_activation_input_binding_expr_shape {
    my ($expr) = @_;
    return 1 if ref($expr) eq 'ARRAY' && @$expr;
    return 0 if ref($expr);
    return 0 unless defined($expr) && length($expr);
    return 1 if _is_hdl_identifier($expr);
    return 1 if _is_numeric_or_exact_width_literal($expr);
    return 0;
}

sub _activation_binding_actor_expr_text {
    my ($binding) = @_;
    return $binding->{actor_expression}
        if ref($binding) eq 'HASH' && exists($binding->{actor_expression});
    return _format_isf_expr($binding->{actor_expr})
        if ref($binding) eq 'HASH' && exists($binding->{actor_expr});
    return $binding->{actor_signal};
}

sub _validate_activation_input_binding_expr {
    my ($actor, $owner_tx, $binding, $port, $context) = @_;
    my $port_name = $binding->{port};
    my $expr = exists($binding->{actor_expr}) ? $binding->{actor_expr} : $binding->{actor_signal};
    my $actor_signal = $binding->{actor_signal};

    if (defined $actor_signal) {
        my $info = _binding_signal_info($actor, $owner_tx, $actor_signal);
        confess "$context binding for port '$port_name' references unknown actor signal '$actor_signal'\n"
            unless $info;
        confess "$context input binding for port '$port_name' reads actor output '$actor_signal', but actor output readback is not public\n"
            if $info->{kind} eq 'actor_output';

        my $port_width = $port->{width} // 1;
        my $signal_width = $info->{width} // 1;
        confess "$context binding for port '$port_name' width $port_width does not match actor signal '$actor_signal' width $signal_width\n"
            unless $port_width == $signal_width;
        return 1;
    }

    my %seen_refs;
    for my $ref (_activation_binding_expr_signals($expr)) {
        next if $seen_refs{$ref}++;
        my $info = _binding_signal_info($actor, $owner_tx, $ref);
        confess "$context input binding expression for port '$port_name' references unknown actor signal '$ref'\n"
            unless $info;
        confess "$context input binding expression for port '$port_name' reads actor output '$ref', but actor output readback is not public\n"
            if $info->{kind} eq 'actor_output';
    }

    my $widths = _build_signal_width_map($actor, $owner_tx || { clauses => [] });
    my $expr_width = _activation_binding_expr_width($expr, $widths);
    my $port_width = $port->{width} // 1;
    confess "$context input binding expression for port '$port_name' width $expr_width does not match transaction port width $port_width\n"
        if defined($expr_width) && $expr_width > 0 && $expr_width != $port_width;

    return 1;
}

sub _activation_binding_expr_signals {
    my ($expr) = @_;
    return () unless defined $expr;
    if (!ref($expr)) {
        return _is_hdl_identifier($expr) ? ($expr) : ();
    }
    return () unless ref($expr) eq 'ARRAY';

    my @signals;
    for my $index (0 .. $#$expr) {
        next if $index == 0 && !ref($expr->[$index]);
        push @signals, _activation_binding_expr_signals($expr->[$index]);
    }
    return @signals;
}

sub _activation_binding_expr_width {
    my ($expr, $widths) = @_;
    my $known = _known_expr_width($expr, $widths);
    return $known if defined $known;
    return undef unless ref($expr) eq 'ARRAY' && @$expr;

    my $op = $expr->[0];
    return undef if ref($op);
    my @operand_widths = map { _activation_binding_expr_width($_, $widths) } @{$expr}[1 .. $#$expr];

    if ($op eq 'concat') {
        return undef if grep { !defined($_) || $_ <= 0 } @operand_widths;
        my $total = 0;
        $total += $_ for @operand_widths;
        return $total;
    }

    return 1 if $op =~ /\A(?:==|!=|<|<=|>|>=|&&|\|\|)\z/;
    return 1 if $op eq '!';
    return $operand_widths[0] if ($op eq '~' || $op eq '<<' || $op eq '>>') && defined($operand_widths[0]);
    if ($op =~ /\A(?:\+|-|\*|\/|%|&|\||\^)\z/) {
        return undef if grep { !defined($_) || $_ <= 0 } @operand_widths;
        my $max = 1;
        for my $width (@operand_widths) {
            $max = $width if $width > $max;
        }
        return $max;
    }

    return undef;
}

sub _validate_isf_param_value {
    my ($value, $context) = @_;
    if (!ref($value)) {
        confess "$context uses unsupported parameter value '$value'; first ISF parameter binding accepts numeric, exact-width, and aggregate/list literals only\n"
            unless defined($value) && _is_numeric_or_exact_width_literal($value);
        return 1;
    }

    confess "$context uses unsupported parameter value shape; first ISF parameter binding accepts non-empty aggregate/list literals only\n"
        unless ref($value) eq 'ARRAY' && @$value;

    for my $item (@$value) {
        _validate_isf_param_value($item, $context);
    }
    return 1;
}

sub _validate_transaction_param_value {
    my ($value, $context, $actor) = @_;

    if (!ref($value)) {
        confess "$context uses undefined parameter value; transaction parameter defaults accept numeric, exact-width, aggregate/list, and scalar enum member literals only\n"
            unless defined($value);
        return 1 if _is_numeric_or_exact_width_literal($value);
        if (_is_enum_member_reference($value)) {
            my $resolved_value = _resolve_actor_enum_member_value($actor, $value);
            confess "$context references unknown enum member '$value'\n"
                unless defined($resolved_value) && !ref($resolved_value);
            confess "$context enum member '$value' must resolve to a non-negative integer literal value\n"
                unless defined _non_negative_integer_from_literal($resolved_value);
            return 1;
        }

        confess "$context uses unsupported parameter value '$value'; transaction parameter defaults accept numeric, exact-width, aggregate/list, and scalar enum member literals only\n";
    }

    confess "$context uses unsupported parameter value shape; transaction parameter defaults accept non-empty aggregate/list literals\n"
        unless ref($value) eq 'ARRAY' && @$value;

    _resolve_transaction_param_default_value($value, $context, $actor);

    return 1;
}

sub _resolve_transaction_param_default_value {
    my ($value, $context, $actor) = @_;

    if (!ref($value)) {
        return (_clone_isf_value($value), 0)
            if defined($value) && _is_numeric_or_exact_width_literal($value);
        if (_is_enum_member_reference($value)) {
            my $resolved_value = _resolve_actor_enum_member_value($actor, $value);
            confess "$context references unknown enum member '$value'\n"
                unless defined($resolved_value) && !ref($resolved_value);
            confess "$context enum member '$value' must resolve to a non-negative integer literal value\n"
                unless defined _non_negative_integer_from_literal($resolved_value);
            return (_clone_isf_value($resolved_value), 1);
        }

        confess "$context uses unsupported parameter value '$value'; transaction parameter aggregate/list defaults accept numeric, exact-width, and enum member literal leaves only\n";
    }

    confess "$context uses unsupported parameter value shape; transaction parameter defaults accept non-empty aggregate/list literals\n"
        unless ref($value) eq 'ARRAY' && @$value;

    my @resolved;
    my $has_enum_leaf = 0;
    for my $item (@$value) {
        my ($resolved_item, $item_has_enum_leaf) = _resolve_transaction_param_default_value($item, $context, $actor);
        push @resolved, $resolved_item;
        $has_enum_leaf ||= $item_has_enum_leaf;
    }

    return (\@resolved, $has_enum_leaf);
}

sub _resolve_activation_param_value {
    my ($value, $context, $constant_values, $actor, $allow_enum_member) = @_;
    $constant_values ||= {};
    $allow_enum_member //= 0;

    if (!ref($value)) {
        confess "$context uses undefined parameter value; activation parameter values accept numeric, exact-width, actor-constant, scalar enum member, and aggregate/list literal values only\n"
            unless defined($value);
        return _clone_isf_value($value)
            if _is_numeric_or_exact_width_literal($value);
        return _clone_isf_value($constant_values->{$value})
            if _is_hdl_identifier($value) && exists $constant_values->{$value};
        if (_is_enum_member_reference($value)) {
            confess "$context uses unsupported aggregate/list override leaf '$value'; activation parameter aggregate/list overrides accept numeric, exact-width, actor-constant, and enum member leaves only when enum members resolve to non-negative integer literal values\n"
                unless $allow_enum_member;
            my $resolved_value = _resolve_actor_enum_member_value($actor, $value);
            confess "$context references unknown enum member '$value'\n"
                unless defined($resolved_value) && !ref($resolved_value);
            confess "$context enum member '$value' must resolve to a non-negative integer literal value\n"
                unless defined _non_negative_integer_from_literal($resolved_value);
            return _clone_isf_value($resolved_value);
        }

        confess "$context uses unsupported parameter value '$value'; activation parameter values accept numeric, exact-width, actor-constant, scalar enum member, and aggregate/list literal values only\n";
    }

    confess "$context uses unsupported parameter value shape; activation parameter values accept non-empty aggregate/list literal values only\n"
        unless ref($value) eq 'ARRAY' && @$value;

    return [
        map {
            _resolve_activation_param_value($_, $context, $constant_values, $actor, $allow_enum_member)
        } @$value
    ];
}

sub _is_numeric_or_exact_width_literal {
    my ($value) = @_;
    return 0 unless defined($value) && !ref($value);
    return 1 if $value =~ /\A\d+\z/;
    return 1 if $value =~ /\A\d+'[bBoOdDhH][0-9a-fA-F_xXzZ]+\z/;
    return 0;
}

sub _param_values_shape_compatible {
    my ($declared, $override) = @_;
    return 1 if !ref($declared) && !ref($override);
    return 0 unless ref($declared) eq 'ARRAY' && ref($override) eq 'ARRAY';
    return 0 unless @$declared == @$override;
    for my $index (0 .. $#$declared) {
        return 0 unless _param_values_shape_compatible($declared->[$index], $override->[$index]);
    }
    return 1;
}

sub _clone_isf_value {
    my ($value) = @_;
    return [ map { _clone_isf_value($_) } @$value ] if ref($value) eq 'ARRAY';
    return { map { $_ => _clone_isf_value($value->{$_}) } keys %$value } if ref($value) eq 'HASH';
    return $value;
}

sub _actor_constant_value_map {
    my ($actor) = @_;
    my %values;
    return \%values unless ref($actor) eq 'HASH';

    for my $constant (@{$actor->{constants} || []}) {
        next unless ref($constant) eq 'HASH';
        my $name = $constant->{name};
        next unless _is_hdl_identifier($name);
        $values{$name} = _clone_isf_value(_constant_resolved_value($constant));
    }

    return \%values;
}

sub _resolve_actor_enum_member_value {
    my ($actor, $member_ref) = @_;
    return undef unless ref($actor) eq 'HASH' && _is_enum_member_reference($member_ref);

    my $symbols = $actor->{enum_symbols} || {};
    if ($member_ref =~ /\A([A-Za-z_]\w*)\.([A-Za-z_]\w*)\.([A-Za-z_]\w*)\z/) {
        my ($package_name, $enum_name, $member_name) = ($1, $2, $3);
        return _clone_isf_value(((($symbols->{packages} || {})->{$package_name} || {})->{$enum_name} || {})->{$member_name});
    }

    if ($member_ref =~ /\A([A-Za-z_]\w*)\.([A-Za-z_]\w*)\z/) {
        my ($enum_name, $member_name) = ($1, $2);
        return _clone_isf_value((($symbols->{local} || {})->{$enum_name} || {})->{$member_name});
    }

    return undef;
}

sub _constant_resolved_value {
    my ($constant) = @_;
    return undef unless ref($constant) eq 'HASH';
    return exists($constant->{resolved_value})
        ? $constant->{resolved_value}
        : $constant->{value};
}

sub _param_resolved_value {
    my ($param) = @_;
    return undef unless ref($param) eq 'HASH';
    return exists($param->{resolved_value})
        ? $param->{resolved_value}
        : $param->{value};
}

sub _validate_repeat_clause {
    my ($clause, $tn, $label) = @_;

    confess "Transaction '$tn': repeat requires '(repeat count body...)' in $label\n"
        unless @$clause >= 3
            && defined($clause->[1])
            && !ref($clause->[1])
            && length($clause->[1]);

    return 1;
}

sub _validate_repeat_body_spawn_subset {
    my ($clause, $tn, $label, $context_depths, $generated_children) = @_;
    $context_depths ||= {};
    $generated_children ||= {};
    my @pending_spawns;
    my $awaiting_multi_pending_drain = 0;
    my $pending_local_do_before_drain = 0;
    my $pending_generated_do_before_drain = 0;
    my $pending_generated_do_kind_before_drain;
    my $top_level_repeat = $label eq 'transaction body';
    my $when_body_repeat = $label eq 'when body'
        && _context_depths_match_exactly($context_depths, { when => 1 });
    my $switch_branch_repeat = $label eq 'switch branch'
        && _context_depths_match_exactly($context_depths, { switch => 1 });
    my $pending_local_do_label = $when_body_repeat
        ? 'when-body'
        : $switch_branch_repeat
            ? 'switch-branch'
            : undef;
    my $pending_generated_do_label = $when_body_repeat
        ? 'when-body'
        : $switch_branch_repeat
            ? 'switch-branch'
            : undef;

    for my $body_clause (@{$clause}[2 .. $#$clause]) {
        next unless ref($body_clause) eq 'ARRAY' && @$body_clause;
        my $keyword = $body_clause->[0];
        next unless defined($keyword) && !ref($keyword);

        if ($keyword eq 'spawn') {
            confess "Transaction '$tn': repeat-body spawn is supported only for top-level repeat clauses, top-level when-body nested repeat clauses, or top-level switch-branch nested repeat clauses\n"
                unless $top_level_repeat || $when_body_repeat || $switch_branch_repeat;
            confess "Transaction '$tn': repeat-body spawn cannot follow multi-pending await_any before same-body await_all drains outstanding children\n"
                if $awaiting_multi_pending_drain;
            confess "Transaction '$tn': $pending_local_do_label nested repeat spawn cannot follow local do while generated spawns are pending; drain with same-body '(await_all done)' before spawning again\n"
                if defined $pending_local_do_label && $pending_local_do_before_drain && @pending_spawns;
            confess "Transaction '$tn': $pending_generated_do_label nested repeat spawn cannot follow $pending_generated_do_kind_before_drain while generated spawns are pending; drain with same-body '(await_all done)' before spawning again\n"
                if defined $pending_generated_do_label && $pending_generated_do_before_drain && @pending_spawns;
            for my $subclause (@{$body_clause}[4 .. $#$body_clause]) {
                confess "Transaction '$tn': repeat-body spawn subclauses must be '(params ...)', '(bind ...)', or '(domain ...)' in the spawn domain subset\n"
                    unless ref($subclause) eq 'ARRAY'
                        && @$subclause
                        && defined($subclause->[0])
                        && !ref($subclause->[0])
                        && length($subclause->[0]);
                my $head = $subclause->[0];
                next if $head eq 'params' || $head eq 'bind' || $head eq 'domain';
                confess "Transaction '$tn': repeat-body spawn supports only optional '(params ...)', '(bind ...)', and '(domain ...)' subclauses in the spawn domain subset\n";
            }
            push @pending_spawns, $body_clause->[3];
            next;
        }

        if ($keyword eq 'do') {
            confess "Transaction '$tn': repeat-body do is supported only for top-level repeat clauses, top-level when-body nested repeat clauses, or top-level switch-branch nested repeat clauses\n"
                unless $top_level_repeat || $when_body_repeat || $switch_branch_repeat;
            my $uses_generated_params = _repeat_body_do_uses_generated_params($body_clause);
            my $uses_bindings = _repeat_body_do_uses_bindings($body_clause);
            my $uses_domain = _repeat_body_do_uses_domain($body_clause);
            my $target = $body_clause->[1];
            my $generated_do = _repeat_body_do_is_generated_activation($body_clause, $target, $generated_children);
            for my $subclause (@{$body_clause}[2 .. $#$body_clause]) {
                confess "Transaction '$tn': repeat-body generated do supports only static '(params ...)', '(bind ...)', and '(domain ...)' in the generated blocking-do subset\n"
                    unless ref($subclause) eq 'ARRAY'
                        && @$subclause
                        && defined($subclause->[0])
                        && !ref($subclause->[0])
                        && ($subclause->[0] eq 'params' || $subclause->[0] eq 'bind' || $subclause->[0] eq 'domain');
            }
            my $nested_do_label = $when_body_repeat ? 'when-body' : $switch_branch_repeat ? 'switch-branch' : undef;
            if ($when_body_repeat) {
                confess "Transaction '$tn': when-body nested repeat generated do bindings require static '(params ...)' overrides in the current nested generated blocking-do subset\n"
                    if $uses_bindings && !$uses_generated_params;
                confess "Transaction '$tn': when-body nested repeat generated do domain metadata requires static '(params ...)' overrides in the current nested generated blocking-do subset\n"
                    if $uses_domain && !$uses_generated_params;
            } elsif ($switch_branch_repeat) {
                confess "Transaction '$tn': switch-branch nested repeat generated do bindings require static '(params ...)' overrides in the current nested generated blocking-do subset\n"
                    if $uses_bindings && !$uses_generated_params;
                confess "Transaction '$tn': switch-branch nested repeat generated do domain metadata requires static '(params ...)' overrides in the current nested generated blocking-do subset\n"
                    if $uses_domain && !$uses_generated_params;
            }
            confess "Transaction '$tn': repeat-body generated do bindings require static '(params ...)' overrides in the current generated blocking-do subset\n"
                if $top_level_repeat && $uses_bindings && !$uses_generated_params;
            confess "Transaction '$tn': repeat-body generated do domain metadata requires static '(params ...)' overrides in the current generated blocking-do subset\n"
                if $top_level_repeat && $uses_domain && !$uses_generated_params;
            if (@pending_spawns) {
                my $plain_local_do = !$uses_generated_params && !$uses_bindings && !$uses_domain && !$generated_do;
                my $plain_generated_child_do = !$uses_generated_params && !$uses_bindings && !$uses_domain && $generated_do;
                my $static_parameter_generated_do = $uses_generated_params && !$uses_bindings && !$uses_domain && $generated_do;
                my $static_bound_generated_do = $uses_generated_params && $uses_bindings && !$uses_domain && $generated_do;
                my $static_domain_generated_do = $uses_generated_params && $uses_domain && $generated_do;
                my $allowed_static_parameter_generated_do = defined($pending_generated_do_label) && $static_parameter_generated_do;
                my $allowed_static_bound_generated_do = defined($pending_generated_do_label) && $static_bound_generated_do;
                my $allowed_static_domain_generated_do = ($when_body_repeat || $switch_branch_repeat) && $static_domain_generated_do;
                my $allowed_local_do_after_multi_pending_await_any =
                    ($when_body_repeat || $switch_branch_repeat)
                    && $plain_local_do
                    && $awaiting_multi_pending_drain;
                my $allowed_generated_child_do_after_multi_pending_await_any =
                    ($when_body_repeat || $switch_branch_repeat)
                    && $plain_generated_child_do
                    && $awaiting_multi_pending_drain;
                my $allowed_static_parameter_generated_do_after_multi_pending_await_any =
                    ($when_body_repeat || $switch_branch_repeat)
                    && $static_parameter_generated_do
                    && $awaiting_multi_pending_drain;
                my $allowed_static_bound_generated_do_after_multi_pending_await_any =
                    ($when_body_repeat || $switch_branch_repeat)
                    && $static_bound_generated_do
                    && $awaiting_multi_pending_drain;
                my $allowed_static_domain_generated_do_after_multi_pending_await_any =
                    ($when_body_repeat || $switch_branch_repeat)
                    && $static_domain_generated_do
                    && $awaiting_multi_pending_drain;
                my $allowed_pending_do = $plain_local_do
                    || (defined $pending_generated_do_label && $plain_generated_child_do)
                    || $allowed_static_parameter_generated_do
                    || $allowed_static_bound_generated_do
                    || $allowed_static_domain_generated_do;
                my $supported_pending_do = ($when_body_repeat || $switch_branch_repeat)
                    ? "local plain '(do child)', plain generated-child '(do child)', static generated '(do child (params ...))', static bound generated '(do child (params ...) (bind ...))', or static same-domain generated '(do child (params ...) [(bind ...)] (domain ...))'"
                    : defined($pending_generated_do_label)
                        ? "local plain '(do child)', plain generated-child '(do child)', static generated '(do child (params ...))', or static bound generated '(do child (params ...) (bind ...))'"
                    : "local plain '(do child)'";
                confess "Transaction '$tn': $pending_local_do_label nested repeat local do while generated spawns are pending is supported only before a later same-body '(await_all done)' drain, with no prior multi-pending await_any observation\n"
                    if defined $pending_local_do_label
                        && $plain_local_do
                        && $awaiting_multi_pending_drain
                        && !$allowed_local_do_after_multi_pending_await_any;
                confess "Transaction '$tn': $pending_generated_do_label nested repeat generated-child do while generated spawns are pending is supported only before a later same-body '(await_all done)' drain, with no prior multi-pending await_any observation\n"
                    if defined $pending_generated_do_label
                        && $plain_generated_child_do
                        && $awaiting_multi_pending_drain
                        && !$allowed_generated_child_do_after_multi_pending_await_any;
                confess "Transaction '$tn': $pending_generated_do_label nested repeat generated do with static params while generated spawns are pending is supported only before a later same-body '(await_all done)' drain, with no prior multi-pending await_any observation\n"
                    if $allowed_static_parameter_generated_do
                        && $awaiting_multi_pending_drain
                        && !$allowed_static_parameter_generated_do_after_multi_pending_await_any;
                confess "Transaction '$tn': $pending_generated_do_label nested repeat generated do with static params and bindings while generated spawns are pending is supported only before a later same-body '(await_all done)' drain, with no prior multi-pending await_any observation\n"
                    if $allowed_static_bound_generated_do
                        && $awaiting_multi_pending_drain
                        && !$allowed_static_bound_generated_do_after_multi_pending_await_any;
                confess "Transaction '$tn': $pending_generated_do_label nested repeat generated do with static params and same-domain metadata while generated spawns are pending is supported only before a later same-body '(await_all done)' drain, with no prior multi-pending await_any observation\n"
                    if $allowed_static_domain_generated_do
                        && $awaiting_multi_pending_drain
                        && !$allowed_static_domain_generated_do_after_multi_pending_await_any;
                confess "Transaction '$tn': $pending_generated_do_label nested repeat do while generated spawns are pending supports only $supported_pending_do in the current subset\n"
                    if defined $pending_generated_do_label && !$awaiting_multi_pending_drain && !$allowed_pending_do;
                confess "Transaction '$tn': $pending_local_do_label nested repeat do while generated spawns are pending supports only local plain '(do child)' in the current subset\n"
                    if !defined $pending_generated_do_label && defined $pending_local_do_label && !$awaiting_multi_pending_drain && !$allowed_pending_do;
                confess "Transaction '$tn': repeat-body do cannot appear while repeat-body spawn clauses are pending; wait for spawned children before blocking do\n"
                    unless defined $pending_local_do_label
                        && $allowed_pending_do
                        && (!$awaiting_multi_pending_drain
                            || $allowed_local_do_after_multi_pending_await_any
                            || $allowed_generated_child_do_after_multi_pending_await_any
                            || $allowed_static_parameter_generated_do_after_multi_pending_await_any
                            || $allowed_static_bound_generated_do_after_multi_pending_await_any
                            || $allowed_static_domain_generated_do_after_multi_pending_await_any);
                $pending_local_do_before_drain = 1 if $plain_local_do;
                if ($plain_generated_child_do || $allowed_static_parameter_generated_do || $allowed_static_bound_generated_do || $allowed_static_domain_generated_do) {
                    $pending_generated_do_before_drain = 1;
                    $pending_generated_do_kind_before_drain = $plain_generated_child_do
                        ? 'generated-child do'
                        : $allowed_static_domain_generated_do
                            ? 'generated do with static params and same-domain metadata'
                            : $allowed_static_bound_generated_do
                                ? 'generated do with static params and bindings'
                                : 'generated do with static params';
                }
            }
            next;
        }

        if ($keyword eq 'await_all' || $keyword eq 'await_any') {
            confess "Transaction '$tn': repeat-body $keyword is supported only after repeat-body spawn clauses\n"
                unless @pending_spawns;
            my $allowed_branch_local_do_before_post_await_any =
                ($when_body_repeat || $switch_branch_repeat)
                && $pending_local_do_before_drain
                && !$pending_generated_do_before_drain
                && $keyword eq 'await_any'
                && @pending_spawns > 1
                && !$awaiting_multi_pending_drain;
            my $allowed_branch_generated_child_do_before_post_await_any =
                ($when_body_repeat || $switch_branch_repeat)
                && !$pending_local_do_before_drain
                && $pending_generated_do_before_drain
                && ($pending_generated_do_kind_before_drain // '') eq 'generated-child do'
                && $keyword eq 'await_any'
                && @pending_spawns > 1
                && !$awaiting_multi_pending_drain;
            my $allowed_branch_static_parameter_generated_do_before_post_await_any =
                ($when_body_repeat || $switch_branch_repeat)
                && !$pending_local_do_before_drain
                && $pending_generated_do_before_drain
                && ($pending_generated_do_kind_before_drain // '') eq 'generated do with static params'
                && $keyword eq 'await_any'
                && @pending_spawns > 1
                && !$awaiting_multi_pending_drain;
            my $allowed_when_static_bound_generated_do_before_post_await_any =
                $when_body_repeat
                && !$pending_local_do_before_drain
                && $pending_generated_do_before_drain
                && ($pending_generated_do_kind_before_drain // '') eq 'generated do with static params and bindings'
                && $keyword eq 'await_any'
                && @pending_spawns > 1
                && !$awaiting_multi_pending_drain;
            confess "Transaction '$tn': $pending_local_do_label nested repeat local do while generated spawns are pending requires same-body '(await_all done)' drain; '(await_any done)' after the do remains deferred\n"
                if defined $pending_local_do_label && $pending_local_do_before_drain && $keyword eq 'await_any' && !$allowed_branch_local_do_before_post_await_any;
            confess "Transaction '$tn': $pending_generated_do_label nested repeat $pending_generated_do_kind_before_drain while generated spawns are pending requires same-body '(await_all done)' drain; '(await_any done)' after the do remains deferred\n"
                if defined $pending_generated_do_label
                    && $pending_generated_do_before_drain
                    && $keyword eq 'await_any'
                    && !$allowed_branch_generated_child_do_before_post_await_any
                    && !$allowed_branch_static_parameter_generated_do_before_post_await_any
                    && !$allowed_when_static_bound_generated_do_before_post_await_any;
            if ($keyword eq 'await_any' && @pending_spawns > 1) {
                $awaiting_multi_pending_drain = 1;
                next;
            }
            @pending_spawns = ();
            $awaiting_multi_pending_drain = 0;
            $pending_local_do_before_drain = 0;
            $pending_generated_do_before_drain = 0;
            $pending_generated_do_kind_before_drain = undef;
            next;
        }
    }

    confess "Transaction '$tn': $pending_local_do_label nested repeat local do while generated spawns are pending requires later same-body '(await_all done)' before the nested repeat check can loop\n"
        if defined $pending_local_do_label && $pending_local_do_before_drain && @pending_spawns;
    confess "Transaction '$tn': $pending_generated_do_label nested repeat $pending_generated_do_kind_before_drain while generated spawns are pending requires later same-body '(await_all done)' before the nested repeat check can loop\n"
        if defined $pending_generated_do_label && $pending_generated_do_before_drain && @pending_spawns;
    confess "Transaction '$tn': when-body nested repeat multi-pending await_any requires later same-body '(await_all done)' before the nested repeat check can loop\n"
        if $when_body_repeat && $awaiting_multi_pending_drain;
    confess "Transaction '$tn': when-body nested repeat spawn requires same-body '(await_all done)' or single-pending '(await_any done)' before the nested repeat check can loop\n"
        if $when_body_repeat && @pending_spawns;
    confess "Transaction '$tn': switch-branch nested repeat multi-pending await_any requires later same-body '(await_all done)' before the nested repeat check can loop\n"
        if $switch_branch_repeat && $awaiting_multi_pending_drain;
    confess "Transaction '$tn': switch-branch nested repeat spawn requires same-body '(await_all done)' or single-pending '(await_any done)' before the nested repeat check can loop\n"
        if $switch_branch_repeat && @pending_spawns;
    confess "Transaction '$tn': repeat-body spawn requires same-body '(await_all done)' before the repeat check can loop\n"
        if $top_level_repeat && @pending_spawns;

    return 1;
}

sub _validate_repeat_body_do_subset {
    my ($ref) = @_;
    return 1 unless ref($ref) eq 'HASH'
        && ($ref->{keyword} // '') eq 'do'
        && ($ref->{label} // '') eq 'repeat body';

    my $tn = $ref->{tx_name};
    my $clause = $ref->{clause};
    if (my $nested_do_label = _nested_repeat_local_do_label($ref->{repeat_parent_label})) {
        my @subclauses = ref($clause) eq 'ARRAY' ? @{$clause}[2 .. $#$clause] : ();
        my $uses_generated_params = _repeat_body_do_uses_generated_params($clause);
        my $uses_bindings = _repeat_body_do_uses_bindings($clause);
        my $uses_domain = _repeat_body_do_uses_domain($clause);

        if ($nested_do_label eq 'when-body') {
            for my $subclause (@subclauses) {
                confess "Transaction '$tn': when-body nested repeat do supports only plain '(do child)', static '(do child (params ...))', static bound '(do child (params ...) (bind ...))', or static same-domain '(do child (params ...) [(bind ...)] (domain ...))' in the current nested generated blocking-do subset\n"
                    unless ref($subclause) eq 'ARRAY'
                        && @$subclause
                        && defined($subclause->[0])
                        && !ref($subclause->[0])
                        && ($subclause->[0] eq 'params' || $subclause->[0] eq 'bind' || $subclause->[0] eq 'domain');
            }
            confess "Transaction '$tn': when-body nested repeat generated do bindings require static '(params ...)' overrides in the current nested generated blocking-do subset\n"
                if $uses_bindings && !$uses_generated_params;
            confess "Transaction '$tn': when-body nested repeat generated do domain metadata requires static '(params ...)' overrides in the current nested generated blocking-do subset\n"
                if $uses_domain && !$uses_generated_params;
        } elsif ($nested_do_label eq 'switch-branch') {
            for my $subclause (@subclauses) {
                confess "Transaction '$tn': switch-branch nested repeat do supports only plain '(do child)', static '(do child (params ...))', static bound '(do child (params ...) (bind ...))', or static same-domain '(do child (params ...) [(bind ...)] (domain ...))' in the current nested generated blocking-do subset\n"
                    unless ref($subclause) eq 'ARRAY'
                        && @$subclause
                        && defined($subclause->[0])
                        && !ref($subclause->[0])
                        && ($subclause->[0] eq 'params' || $subclause->[0] eq 'bind' || $subclause->[0] eq 'domain');
            }
            confess "Transaction '$tn': switch-branch nested repeat generated do bindings require static '(params ...)' overrides in the current nested generated blocking-do subset\n"
                if $uses_bindings && !$uses_generated_params;
            confess "Transaction '$tn': switch-branch nested repeat generated do domain metadata requires static '(params ...)' overrides in the current nested generated blocking-do subset\n"
                if $uses_domain && !$uses_generated_params;
        }
        return 1;
    }

    my @subclauses = ref($clause) eq 'ARRAY' ? @{$clause}[2 .. $#$clause] : ();
    my $uses_generated_params = _repeat_body_do_uses_generated_params($clause);
    my $uses_bindings = _repeat_body_do_uses_bindings($clause);
    my $uses_domain = _repeat_body_do_uses_domain($clause);

    for my $subclause (@subclauses) {
        confess "Transaction '$tn': repeat-body generated do supports only static '(params ...)', '(bind ...)', and '(domain ...)' in the generated blocking-do subset\n"
            unless ref($subclause) eq 'ARRAY'
                && @$subclause
                && defined($subclause->[0])
                && !ref($subclause->[0])
                && ($subclause->[0] eq 'params' || $subclause->[0] eq 'bind' || $subclause->[0] eq 'domain');
    }

    confess "Transaction '$tn': repeat-body generated do bindings require static '(params ...)' overrides in the current generated blocking-do subset\n"
        if $uses_bindings && !$uses_generated_params;
    confess "Transaction '$tn': repeat-body generated do domain metadata requires static '(params ...)' overrides in the current generated blocking-do subset\n"
        if $uses_domain && !$uses_generated_params;

    return 1;
}

sub _nested_repeat_local_do_label {
    my ($repeat_parent_label) = @_;
    return 'when-body'     if ($repeat_parent_label // '') eq 'when body';
    return 'switch-branch' if ($repeat_parent_label // '') eq 'switch branch';
    return undef;
}

sub _context_depths_match_exactly {
    my ($context_depths, $expected_depths) = @_;
    $context_depths ||= {};
    $expected_depths ||= {};

    my %names = map { $_ => 1 } (keys %$context_depths, keys %$expected_depths);
    for my $name (keys %names) {
        return 0 unless ($context_depths->{$name} // 0) == ($expected_depths->{$name} // 0);
    }

    return 1;
}

sub _validate_loop_clause {
    my ($clause, $tn, $label, $kind) = @_;

    confess "Transaction '$tn': $kind requires '($kind condition body...)' in $label\n"
        unless @$clause >= 3
            && defined($clause->[1])
            && (
                (ref($clause->[1]) eq 'ARRAY' && @{$clause->[1]})
                || (!ref($clause->[1]) && length($clause->[1]))
            );

    for my $body_clause (@{$clause}[2 .. $#$clause]) {
        confess "Transaction '$tn': $kind body clauses must be non-empty list forms in $label\n"
            unless ref($body_clause) eq 'ARRAY' && @$body_clause;
    }

    return 1;
}

sub _validate_wait_clause {
    my ($clause, $tn, $label, $actor) = @_;

    _confess_wait_requires($tn, $label)
        unless @$clause == 2
            && defined($clause->[1]);

    if (defined $actor) {
        _wait_cycles($clause, $tn, $label, $actor);
    } else {
        my $count = $clause->[1];
        if (ref($count)) {
            _confess_wait_requires($tn, $label)
                unless _is_wait_expression_shape($count);
        } else {
            _confess_wait_requires($tn, $label)
                unless defined(_non_negative_integer_from_literal($count)) || _is_hdl_identifier($count);
        }
    }

    return 1;
}

sub _wait_cycles {
    my ($clause, $tn, $label, $actor, $widths) = @_;

    my $spec = _wait_count_spec($clause, $tn, $label, $actor, $widths, 0);
    return $spec->{cycles};
}

sub _wait_count_spec {
    my ($clause, $tn, $label, $actor, $widths, $allow_dynamic) = @_;

    _confess_wait_requires($tn, $label)
        unless @$clause == 2
            && defined($clause->[1]);

    my $count = $clause->[1];
    if (!ref($count)) {
        my $literal_value = _non_negative_integer_from_literal($count);
        return {
            kind   => 'static',
            cycles => $literal_value,
            source => $count,
        } if defined $literal_value;

        if (_is_hdl_identifier($count)) {
            my $constant = _actor_constant_by_name($actor, $count);
            if ($constant) {
                my $constant_value = _non_negative_integer_from_literal(_constant_resolved_value($constant));
                confess "Transaction '$tn': wait constant '$count' must resolve to a non-negative integer literal in $label\n"
                    unless defined $constant_value;
                return {
                    kind   => 'static',
                    cycles => $constant_value,
                    source => $count,
                };
            }

            my $param = _actor_param_by_name($actor, $count);
            if ($param) {
                my $param_value = _non_negative_integer_from_literal(_param_resolved_value($param));
                confess "Transaction '$tn': wait parameter '$count' must resolve to a non-negative integer literal in $label\n"
                    unless defined $param_value;
                return {
                    kind   => 'static',
                    cycles => $param_value,
                    source => $count,
                };
            }

            my $width = _dynamic_wait_source_width($count, $widths);
            if (defined $width) {
                confess "Transaction '$tn': runtime dynamic wait count '$count' is not supported in $label in the current dynamic-wait slice\n"
                    unless $allow_dynamic;
                return {
                    kind   => 'runtime_scalar',
                    source => $count,
                    width  => $width,
                };
            }

            confess "Transaction '$tn': wait count '$count' is neither a declared actor constant, actor parameter, nor a known-width runtime scalar in $label\n";
        }

        _confess_wait_requires($tn, $label);
    }

    if (_is_wait_expression_shape($count)) {
        my $source = _format_isf_expr($count);
        confess "Transaction '$tn': runtime dynamic wait count expression '$source' must use a supported expression operator shape in $label\n"
            unless _is_supported_wait_expression_shape($count);

        my $unknown_ref = _first_unknown_wait_expression_ref($count, $widths);
        confess "Transaction '$tn': runtime dynamic wait count expression '$source' references unknown-width signal '$unknown_ref' in $label\n"
            if defined $unknown_ref;

        my $width = _wait_expression_width($count, $widths);
        if (defined $width) {
            confess "Transaction '$tn': runtime dynamic wait count expression '$source' is not supported in $label in the current dynamic-wait slice\n"
                unless $allow_dynamic;
            return {
                kind   => 'runtime_expression',
                source => $source,
                width  => $width,
            };
        }

        confess "Transaction '$tn': runtime dynamic wait count expression '$source' must have a known positive width in $label\n";
    }

    _confess_wait_requires($tn, $label);
}

sub _confess_wait_requires {
    my ($tn, $label) = @_;
    confess "Transaction '$tn': wait requires '(wait non_negative_integer_literal_or_constant_or_parameter_or_known_width_runtime_scalar_or_expression)' in $label\n";
}

sub _is_wait_expression_shape {
    my ($count) = @_;
    return ref($count) eq 'ARRAY' && @$count;
}

sub _is_supported_wait_expression_shape {
    my ($expr) = @_;
    return 1 unless ref($expr);
    return 0 unless ref($expr) eq 'ARRAY' && @$expr;

    my $op = $expr->[0];
    return 0 unless defined($op) && !ref($op);

    my @operands = grep { defined($_) } @{$expr}[1 .. $#$expr];
    return 0 unless @operands == @$expr - 1;
    return 0 unless _wait_expression_operator_accepts_arity($op, scalar(@operands));

    for my $operand (@operands) {
        return 0 unless _is_supported_wait_expression_shape($operand);
    }

    return 1;
}

sub _wait_expression_operator_accepts_arity {
    my ($op, $arity) = @_;
    return $arity >= 1 if $op eq 'concat';
    return $arity == 1 if $op =~ /\A(?:!|~)\z/;
    return $arity == 2 if $op =~ /\A(?:<<|>>)\z/;
    return $arity >= 2 if $op =~ /\A(?:\+|-|\*|\/|%|&|\||\^|==|!=|<|<=|>|>=|&&|\|\|)\z/;
    return 0;
}

sub _dynamic_wait_source_width {
    my ($source, $widths) = @_;
    return undef unless defined($source) && !ref($source) && _is_hdl_identifier($source);
    return undef unless ref($widths) eq 'HASH';
    return undef unless exists($widths->{$source});

    my $width = $widths->{$source};
    return undef unless defined($width) && !ref($width) && $width =~ /\A[1-9][0-9]*\z/;
    return 0 + $width;
}

sub _first_unknown_wait_expression_ref {
    my ($expr, $widths) = @_;
    return undef unless ref($widths) eq 'HASH';

    my %seen;
    for my $ref (_activation_binding_expr_signals($expr)) {
        next if $seen{$ref}++;
        return $ref unless exists($widths->{$ref})
            && defined($widths->{$ref})
            && !ref($widths->{$ref})
            && $widths->{$ref} =~ /\A[1-9][0-9]*\z/;
    }

    return undef;
}

sub _wait_expression_width {
    my ($expr, $widths) = @_;
    return undef unless ref($widths) eq 'HASH';
    my $width = _activation_binding_expr_width($expr, $widths);
    return undef unless defined($width) && !ref($width) && $width =~ /\A[1-9][0-9]*\z/;
    return 0 + $width;
}

sub _actor_constant_by_name {
    my ($actor, $name) = @_;
    return undef unless ref($actor) eq 'HASH' && defined($name) && !ref($name);

    for my $constant (@{$actor->{constants} || []}) {
        next unless ref($constant) eq 'HASH';
        return $constant if ($constant->{name} // '') eq $name;
    }

    return undef;
}

sub _actor_param_by_name {
    my ($actor, $name) = @_;
    return undef unless ref($actor) eq 'HASH' && defined($name) && !ref($name);

    for my $param (@{$actor->{params} || []}) {
        next unless ref($param) eq 'HASH';
        return $param if ($param->{name} // '') eq $name;
    }

    return undef;
}

sub _non_negative_integer_from_literal {
    my ($literal) = @_;
    return undef unless defined($literal) && !ref($literal);

    my $integer = FSM::Package::IntegerLiteralSupport->integer_from_literal_like($literal);
    return undef unless defined $integer;
    return undef unless $integer->bcmp(0) >= 0;
    return 0 + $integer->bstr;
}

sub _validate_update_clause {
    my ($clause, $tn, $label, $keyword) = @_;
    $keyword //= 'update';

    confess "Transaction '$tn': $keyword requires '($keyword var expr)' in $label\n"
        unless @$clause == 3
            && defined($clause->[1])
            && !ref($clause->[1])
            && length($clause->[1])
            && defined($clause->[2]);

    return 1;
}

sub _validate_bank_access_clause {
    my ($clause, $tn, $label) = @_;
    my $keyword = $clause->[0];

    if ($keyword eq 'store') {
        confess "Transaction '$tn': store requires '(store <bank-name> <index> <value>)' in $label\n"
            unless @$clause == 4
                && defined($clause->[1])
                && !ref($clause->[1])
                && length($clause->[1])
                && defined($clause->[2])
                && !ref($clause->[2])
                && length($clause->[2])
                && defined($clause->[3]);
        return 1;
    }

    confess "Transaction '$tn': load requires '(load <bank-name> <index> as <target>)' in $label\n"
        unless @$clause == 5
            && defined($clause->[1])
            && !ref($clause->[1])
            && length($clause->[1])
            && defined($clause->[2])
            && !ref($clause->[2])
            && length($clause->[2])
            && defined($clause->[3])
            && !ref($clause->[3])
            && $clause->[3] eq 'as'
            && defined($clause->[4])
            && !ref($clause->[4])
            && length($clause->[4]);

    return 1;
}

sub _validate_complete_clause {
    my ($clause, $tn, $label) = @_;

    confess "Transaction '$tn': complete requires '(complete port)' in $label\n"
        unless @$clause == 2
            && defined($clause->[1])
            && !ref($clause->[1])
            && length($clause->[1]);

    return 1;
}

sub _validate_sample_clause {
    my ($clause, $tn, $label) = @_;

    confess "Transaction '$tn': sample requires '(sample port as name)' in $label\n"
        unless @$clause == 4
            && defined($clause->[1])
            && !ref($clause->[1])
            && length($clause->[1])
            && defined($clause->[2])
            && !ref($clause->[2])
            && $clause->[2] eq 'as'
            && defined($clause->[3])
            && !ref($clause->[3])
            && length($clause->[3]);

    return 1;
}

# --- Individual clause → IR ---
sub _sample_assignments {
    my ($samples) = @_;
    my @assignments;

    for my $sample (@$samples) {
        next unless ref($sample) eq 'ARRAY' && @$sample >= 4;
        next unless $sample->[0] eq 'sample' && $sample->[2] eq 'as';
        push @assignments, { lhs => $sample->[3], rhs => $sample->[1], op => '<=', source_kind => 'sample_capture' };
    }

    return @assignments;
}

sub _push_sample_state {
    my ($states, $tn, $pending_samples, $state_index_ref) = @_;
    return unless $pending_samples && @$pending_samples;
    my $index = $$state_index_ref;
    $$state_index_ref++;
    push @$states, _ir_sample_state($tn, [splice @$pending_samples], $index);
}

sub _inline_on_samples {
    my ($cl) = @_;
    my @samples;

    for my $j (2 .. $#$cl) {
        my $sample = $cl->[$j];
        next unless ref($sample) eq 'ARRAY' && $sample->[0] eq 'sample';
        push @samples, $sample;
    }

    return _sample_assignments(\@samples);
}

sub _ir_on {
    my ($cl, $tn, $i) = @_;
    my $event = $cl->[1];
    my $guard = !ref($event) ? { port => $event } : { expr => $event };
    my @assignments = map { +{ %$_, guard => $guard } } _inline_on_samples($cl);

    return {
        name        => "${tn}_idle_$i",
        kind        => 'entry',
        guard       => $guard,
        assignments => \@assignments,
        transitions => [],
    };
}

sub _ir_when_activation {
    my ($cl, $tn, $i) = @_;
    my $event = $cl->[1];
    my $guard = !ref($event) ? { port => $event } : { expr => $event };
    my @assignments = map { +{ %$_, guard => $guard } } _inline_on_samples($cl);

    return {
        name        => "${tn}_idle_$i",
        kind        => 'entry',
        guard       => $guard,
        assignments => \@assignments,
        transitions => [],
    };
}
sub _ir_data_op  { my ($op,$cl,$tn,$i,$widths)=@_; $op eq'shift_left' ? _ir_shift_left($cl,$tn,$i,$widths) : $op eq'shift_right' ? _ir_shift_right($cl,$tn,$i,$widths) : $op eq'assemble' ? _ir_assemble($cl,$tn,$i) : $op eq'extract' ? _ir_extract($cl,$tn,$i,$widths) : _ir_update($cl,$tn,$i,$op) }
sub _ir_named_drive_call {
    my ($cl, $tn, $i, $def, $pending_samples) = @_;
    my $name = $cl->[1];
    my @params = @{$def->{params}};
    my @actuals = @{$cl}[2 .. $#$cl];
    my @assignments = (
        _sample_assignments($pending_samples || []),
        { lhs => "${name}_start", rhs => 1, op => '=', source_kind => 'drive_call_start' },
    );

    confess "Transaction '$tn': drive '$name' expects " . scalar(@params) . " actual(s), got " . scalar(@actuals) . "\n"
        if @actuals > @params;

    for my $pi (0 .. $#params) {
        my $arg = $actuals[$pi];
        confess "Transaction '$tn': drive '$name' missing actual for '$params[$pi]'\n"
            unless defined $arg;
        push @assignments, { lhs => "${name}_$params[$pi]", rhs => _format_isf_expr($arg), op => '=', source_kind => 'drive_call_param' };
    }

    return {
        name        => "${tn}_drive_$i",
        kind        => 'sequential',
        assignments => \@assignments,
        transitions => [],
    };
}
sub _ir_drive   { my ($cl,$tn,$ps,$i)=@_; my @a; for(@$ps){push @a,{lhs=>$_->[3],rhs=>$_->[1],op=>'<=',source_kind=>'sample_capture'}} my$first=(ref($cl->[1])eq'ARRAY')?1:2; for my $j($first..$#$cl){my$x=$cl->[$j];next unless ref($x)eq'ARRAY'&&@$x>=2;push @a,{lhs=>$x->[0],rhs=>_format_isf_expr($x->[1]),op=>'=',source_kind=>'inline_drive'}} {name=>"${tn}_drive_$i",kind=>'sequential',assignments=>\@a,transitions=>[]} }
sub _ir_drive_call { my ($body,$tn,$ps,$i)=@_; return undef; }

sub _is_inline_drive_clause {
    my ($cl) = @_;
    return 0 unless ref($cl) eq 'ARRAY' && @$cl >= 2;
    my $first = (ref($cl->[1]) eq 'ARRAY') ? 1 : 2;
    return 0 if $first > $#$cl;
    for my $entry (@{$cl}[$first .. $#$cl]) {
        return 1 if ref($entry) eq 'ARRAY' && @$entry >= 2;
    }
    return 0;
}

sub _ir_transaction_drive_clause {
    my ($cl, $tn, $state_index, $drives, $pending_samples) = @_;
    my $name = $cl->[1];
    if (!ref($name) && ($drives || {})->{$name}) {
        return _ir_named_drive_call($cl, $tn, $state_index, $drives->{$name}, $pending_samples);
    }
    confess "Transaction '$tn': drive '$name' not defined\n"
        if !ref($name) && !_is_inline_drive_clause($cl);
    return _ir_drive($cl, $tn, $pending_samples, $state_index);
}
sub _ir_await {
    my ($cl, $tn, $i, $wd, $pending_samples) = @_;
    my @assignments = _sample_assignments($pending_samples || []);

    return {
        name        => "${tn}_await_$i",
        kind        => 'await',
        assignments => \@assignments,
        transitions => [],
        guard       => { port => $cl->[1] },
        watchdog    => { name => "${tn}_wd", limit => $wd // 65536 },
    };
}
sub _ir_atl_trigger {
    my ($cl, $tn, $i, $pending_samples) = @_;
    my @assignments = (
        _sample_assignments($pending_samples || []),
        {
            lhs         => $cl->[1],
            rhs         => 1,
            op          => '<1',
            source_kind => 'atl_actor_transaction_trigger',
        },
    );

    return {
        name        => "${tn}_atl_trigger_$i",
        kind        => 'sequential',
        assignments => \@assignments,
        transitions => [],
    };
}
sub _ir_atl_trigger_batch {
    my ($cl, $tn, $i, $pending_samples) = @_;
    my @assignments = _sample_assignments($pending_samples || []);
    for my $signal (@{$cl}[1 .. $#$cl]) {
        push @assignments, {
            lhs         => $signal,
            rhs         => 1,
            op          => '<1',
            source_kind => 'atl_actor_transaction_trigger_batch',
        };
    }

    return {
        name        => "${tn}_atl_trigger_batch_$i",
        kind        => 'sequential',
        assignments => \@assignments,
        transitions => [],
    };
}
sub _ir_wait {
    my ($cl, $tn, $ir, $pending_samples, $actor, $label, $wait_spec) = @_;
    $label //= 'transaction body';
    $wait_spec //= _wait_count_spec($cl, $tn, $label, $actor, undef, 0);
    my $cycles = $wait_spec->{cycles};
    my @states;

    return \@states if $cycles == 0;

    for my $cycle (1 .. $cycles) {
        my @assignments = $cycle == 1 ? _sample_assignments($pending_samples || []) : ();
        push @states, {
            name        => "${tn}_wait_" . $$ir++,
            kind        => 'wait',
            assignments => \@assignments,
            transitions => [],
        };
    }

    if (@states) {
        $states[0]{wait_entry} = 1;
        $states[0]{wait_cycles} = $cycles;
        $states[0]{wait_count_kind} = 'static';
        $states[0]{wait_count_source} = $wait_spec->{source};
        $states[0]{wait_state_names} = [map { $_->{name} } @states];
    }

    return \@states;
}

sub _ir_dynamic_wait {
    my ($cl, $tn, $ir, $wait_spec, $pending_samples) = @_;
    my $state_name = "${tn}_wait_" . $$ir++;
    my $counter = "${state_name}_cnt";
    my @sample_assignments = _sample_assignments($pending_samples || []);
    my $loop_state_name = @sample_assignments ? "${state_name}_loop" : undef;
    my @wait_state_names = ($state_name);
    push @wait_state_names, $loop_state_name if defined $loop_state_name;

    my $state = {
        name                 => $state_name,
        kind                 => 'wait',
        assignments          => [
            @sample_assignments,
            {
                lhs         => $counter,
                rhs         => undef,
                op          => '--',
                source_kind => 'dynamic_wait_counter_decrement',
            },
        ],
        transitions          => [],
        wait_entry           => 1,
        wait_count_kind      => $wait_spec->{kind},
        wait_count_source    => $wait_spec->{source},
        wait_counter         => $counter,
        wait_counter_width   => $wait_spec->{width},
        wait_state_names     => \@wait_state_names,
        dynamic_wait_entry   => 1,
    };
    if (@sample_assignments) {
        my $loop_state = {
            name                  => $loop_state_name,
            kind                  => 'wait',
            assignments           => [
                {
                    lhs         => $counter,
                    rhs         => undef,
                    op          => '--',
                    source_kind => 'dynamic_wait_counter_decrement',
                },
            ],
            transitions           => [],
            wait_counter          => $counter,
            wait_counter_width    => $wait_spec->{width},
            dynamic_wait_loop_for => $state_name,
        };
        $state->{pending_sample_assignments} = \@sample_assignments;
        $state->{dynamic_wait_loop_state} = $loop_state_name;
        return ([$state, $loop_state], $counter, $wait_spec->{width});
    }

    return ([$state], $counter, $wait_spec->{width});
}

sub _ir_while {
    my ($cl, $tn, $ir, $pending_samples, $wd, $drives, $widths, $counters, $storage_roles, $actor, $bank_accesses) = @_;
    my $condition = $cl->[1];
    my @body_clauses = @{$cl}[2 .. $#$cl];
    my @entry_assignments = _sample_assignments($pending_samples || []);
    my $loop_id = $$ir;
    my $entry = {
        name        => "${tn}_while_entry_" . $$ir++,
        kind        => 'loop_while',
        condition   => $condition,
        assignments => \@entry_assignments,
        transitions => [],
        loop_entry  => 1,
        loop_id     => $loop_id,
        loop_kind   => 'while',
        loop_condition => _format_isf_expr($condition),
        loop_body_clause_count => scalar(@body_clauses),
    };

    my $body_states = _expand_loop_body(
        \@body_clauses, $tn, $ir, [], $wd, $drives, $widths,
        $counters, $storage_roles, $actor, $bank_accesses, 'while body',
    );
    my $back = {
        name        => "${tn}_while_check_" . $$ir++,
        kind        => 'loop_while',
        condition   => $condition,
        assignments => [],
        transitions => [],
        loop_id     => $loop_id,
        loop_kind   => 'while',
    };

    my @decision_names = ($entry->{name}, $back->{name});
    my @body_names = map { $_->{name} } @$body_states;
    for my $state ($entry, $back) {
        $state->{loop_body_start} = $body_names[0];
        $state->{loop_decision_state_names} = [@decision_names];
        $state->{loop_body_state_names} = [@body_names];
    }
    $entry->{loop_decision_state_names} = [@decision_names];
    $entry->{loop_body_state_names} = [@body_names];

    return [$entry, @$body_states, $back];
}

sub _ir_until {
    my ($cl, $tn, $ir, $pending_samples, $wd, $drives, $widths, $counters, $storage_roles, $actor, $bank_accesses) = @_;
    my $condition = $cl->[1];
    my @body_clauses = @{$cl}[2 .. $#$cl];
    my $loop_id = $$ir;
    my $body_states = _expand_loop_body(
        \@body_clauses, $tn, $ir, $pending_samples || [], $wd, $drives,
        $widths, $counters, $storage_roles, $actor, $bank_accesses,
        'until body',
    );
    my $check = {
        name        => "${tn}_until_check_" . $$ir++,
        kind        => 'loop_until',
        condition   => $condition,
        assignments => [],
        transitions => [],
        loop_entry  => 1,
        loop_id     => $loop_id,
        loop_kind   => 'until',
        loop_condition => _format_isf_expr($condition),
        loop_body_clause_count => scalar(@body_clauses),
        loop_body_start => $body_states->[0]{name},
        loop_decision_state_names => [],
        loop_body_state_names => [map { $_->{name} } @$body_states],
    };
    $check->{loop_decision_state_names} = [$check->{name}];

    return [@$body_states, $check];
}

sub _ir_complete{ my ($cl,$tn,$i)=@_; {name=>"${tn}_done_$i",kind=>'terminal',assignments=>[{lhs=>$cl->[1],rhs=>1,op=>'<1',source_kind=>'complete_pulse'}],transitions=>[]} }
sub _ir_update   { my ($cl,$tn,$i,$source_kind)=@_; $source_kind //= 'update'; my$rhs=_format_isf_expr($cl->[2]); {name=>"${tn}_${source_kind}_$i",kind=>'sequential',assignments=>[{lhs=>$cl->[1],rhs=>$rhs,op=>'<-',source_kind=>$source_kind}],transitions=>[]} }
sub _ir_bank_access {
    my ($cl, $tn, $i, $actor, $widths, $owner_kind) = @_;
    my $spec = _parse_bank_access_for_lowering($cl, $actor, $widths, $tn, 'transaction');
    my @assignments = _bank_access_assignments($spec);
    my $kind = $spec->{kind};
    my $state = {
        name        => "${tn}_${kind}_$i",
        kind        => "bank_$kind",
        assignments => \@assignments,
        transitions => [],
    };

    return ($state, [
        _bank_access_metadata(
            $spec,
            owner      => $tn,
            owner_kind => $owner_kind || 'transaction',
            container_kind => 'state',
            container_name => $state->{name},
        )
    ]);
}
sub _ir_shift_left {
    my ($cl, $tn, $i, $widths) = @_;
    $widths ||= {};
    my $reg = $cl->[1];
    my $bit = $cl->[2];
    my $explicit_width = _parse_shift_left_width($cl);
    my $known_width = $widths->{$reg};

    confess "shift_left explicit width $explicit_width conflicts with known width $known_width for '$reg'\n"
        if defined($explicit_width)
            && defined($known_width)
            && $known_width > 0
            && $explicit_width != $known_width;

    return {
        name        => "${tn}_shift_$i",
        kind        => 'sequential',
        assignments => [{ lhs => $reg, rhs => "(| (<< $reg 1) $bit)", op => '<-', source_kind => 'shift' }],
        transitions => [],
    };
}
sub _ir_shift_right {
    my ($cl, $tn, $i, $widths) = @_;
    my $reg = $cl->[1];
    my $bit = $cl->[2];
    my $explicit_width = _parse_shift_right_width($cl);
    my $known_width = $widths->{$reg};

    confess "shift_right explicit width $explicit_width conflicts with known width $known_width for '$reg'\n"
        if defined($explicit_width)
            && defined($known_width)
            && $known_width > 0
            && $explicit_width != $known_width;

    my $width = defined($explicit_width) ? $explicit_width : $known_width;
    confess "shift_right width for '$reg' is unknown; add an interface width or '(width N)' option\n"
        unless defined($width) && $width > 0;

    my $insert = $width - 1;

    return {
        name        => "${tn}_shift_$i",
        kind        => 'sequential',
        assignments => [{ lhs => $reg, rhs => "(| (>> $reg 1) (<< $bit $insert))", op => '<-', source_kind => 'shift' }],
        transitions => [],
    };
}
sub _ir_assemble  { my ($cl,$tn,$i)=@_; my($var,@parts)=_parse_assemble_clause($cl);my$rhs='(concat '.join(' ',@parts).')'; {name=>"${tn}_asm_$i",kind=>'sequential',assignments=>[{lhs=>$var,rhs=>$rhs,op=>'<-',source_kind=>'assemble'}],transitions=>[]} }
sub _ir_extract {
    my ($cl, $tn, $i, $widths) = @_;
    my ($word, $fields, $explicit_widths) = _parse_extract_clause($cl);
    my @assignments;
    my @field_widths = _resolve_extract_field_widths($word, $fields, $explicit_widths, $widths);
    my $word_width = $widths->{$word};
    my $total_field_width = 0;
    $total_field_width += $_ for @field_widths;

    my $high = (defined($word_width) && $word_width > 0)
        ? $word_width - 1
        : $total_field_width - 1;

    for my $idx (0 .. $#$fields) {
        my $field = $fields->[$idx];
        my $field_width = $field_widths[$idx];
        my $low = $high - $field_width + 1;
        my $rhs = "(slice $word $high $low)";
        $high = $low - 1;
        push @assignments, { lhs => $field, rhs => $rhs, op => '<=', source_kind => 'extract_capture' };
    }

    return {
        name        => "${tn}_ext_$i",
        kind        => 'sequential',
        assignments => \@assignments,
        transitions => [],
    };
}
sub _format_isf_expr {
    my ($expr) = @_;
    return $expr unless ref($expr) eq 'ARRAY';
    return '(' . join(' ', map { _format_isf_expr($_) } grep { defined($_) } @$expr) . ')';
}

sub _parse_bank_access_for_lowering {
    my ($cl, $actor, $widths, $owner, $owner_kind) = @_;
    my $kind = $cl->[0];
    my %banks = _actor_bank_storage_by_name($actor);
    my $bank_name = $cl->[1];
    my $bank = $banks{$bank_name};
    my $context = "$owner_kind '$owner'";

    confess "$context: $kind references unknown actor-owned bank '$bank_name'\n"
        unless $bank;

    my $index = $cl->[2];
    my $literal_index = _literal_integer_value($index);
    confess "$context: $kind index '$index' is outside bank '$bank_name' depth $bank->{depth}\n"
        if defined($literal_index)
            && ($literal_index < 0 || $literal_index >= $bank->{depth});

    my %spec = (
        kind          => $kind,
        bank          => $bank,
        bank_name     => $bank_name,
        index         => $index,
        index_text    => _format_isf_expr($index),
        literal_index => $literal_index,
    );

    if ($kind eq 'store') {
        my $value = $cl->[3];
        $spec{value} = $value;
        $spec{value_text} = _format_isf_expr($value);
        _validate_bank_access_width(
            $context,
            $kind,
            "store value",
            $spec{value_text},
            _known_expr_width($value, $widths),
            $bank->{width},
            $bank_name,
        );
        return \%spec;
    }

    my $target = $cl->[4];
    confess "$context: load target must be a scalar HDL identifier\n"
        unless _is_hdl_identifier($target);
    $spec{target} = $target;
    _validate_bank_access_width(
        $context,
        $kind,
        "load target",
        $target,
        _known_expr_width($target, $widths),
        $bank->{width},
        $bank_name,
    );
    $widths->{$target} = $bank->{width}
        if ref($widths) eq 'HASH' && !exists($widths->{$target});
    return \%spec;
}

sub _actor_bank_storage_by_name {
    my ($actor) = @_;
    return map {
        (($_->{kind} // '') eq 'bank') ? ($_->{name} => $_) : ()
    } @{$actor->{storage} || []};
}

sub _bank_access_assignments {
    my ($spec) = @_;
    my @assignments;
    my @signals = @{$spec->{bank}{signals} || []};

    for my $signal (@signals) {
        my $entry_index = $signal->{index};
        next if defined($spec->{literal_index}) && $spec->{literal_index} != $entry_index;

        my %assignment = (
            op          => '<-',
            source_kind => "bank_$spec->{kind}",
            bank        => $spec->{bank_name},
            bank_index  => $entry_index,
            index       => $spec->{index_text},
        );

        if ($spec->{kind} eq 'store') {
            $assignment{lhs} = $signal->{name};
            $assignment{rhs} = $spec->{value_text};
        } else {
            $assignment{lhs} = $spec->{target};
            $assignment{rhs} = $signal->{name};
        }

        $assignment{guard} = _bank_entry_guard($spec->{index_text}, $entry_index)
            unless defined($spec->{literal_index});
        push @assignments, \%assignment;
    }

    return @assignments;
}

sub _bank_entry_guard {
    my ($index, $entry_index) = @_;
    return { expr => "(== $index $entry_index)", expr_ast => ['==', $index, $entry_index] };
}

sub _bank_access_metadata {
    my ($spec, %extra) = @_;
    my %metadata = (
        kind             => $spec->{kind},
        bank             => $spec->{bank_name},
        index            => $spec->{index_text},
        width            => $spec->{bank}{width},
        depth            => $spec->{bank}{depth},
        scalar_entries   => [ map { $_->{name} } @{$spec->{bank}{signals} || []} ],
        same_cycle_policy => 'read_before_write',
        %extra,
    );
    $metadata{value} = $spec->{value_text} if $spec->{kind} eq 'store';
    $metadata{target} = $spec->{target} if $spec->{kind} eq 'load';
    return \%metadata;
}

sub _validate_bank_access_width {
    my ($context, $kind, $role, $name, $known_width, $bank_width, $bank_name) = @_;
    return 1 unless defined($known_width) && $known_width > 0;
    confess "$context: $kind $role '$name' width $known_width does not match bank '$bank_name' entry width $bank_width\n"
        unless $known_width == $bank_width;
    return 1;
}

sub _known_expr_width {
    my ($expr, $widths) = @_;
    return undef unless defined($expr);
    if (!ref($expr)) {
        return $widths->{$expr}
            if ref($widths) eq 'HASH' && exists($widths->{$expr});
        return 0 + $1 if $expr =~ /\A([1-9][0-9]*)'[bBoOdDhH][0-9a-fA-F_xXzZ]+\z/;
    }
    return undef;
}

sub _literal_integer_value {
    my ($value) = @_;
    return undef unless defined($value) && !ref($value);
    return 0 + $value if $value =~ /\A\d+\z/;
    return undef unless $value =~ /\A\d+'([bBoOdDhH])([0-9a-fA-F_]+)\z/;

    my ($base_code, $digits) = (lc($1), $2);
    return undef if $digits =~ /[xXzZ]/;
    $digits =~ s/_//g;
    my %base = (b => 2, o => 8, d => 10, h => 16);
    return undef unless exists $base{$base_code};

    my $result = 0;
    for my $digit (split //, $digits) {
        my $value = $digit =~ /\A[0-9]\z/ ? 0 + $digit : 10 + ord(lc($digit)) - ord('a');
        return undef if $value >= $base{$base_code};
        $result = $result * $base{$base_code} + $value;
    }
    return $result;
}
sub _ir_sample_state { my ($tn,$ps,$i)=@_; my @a; for(@$ps){push @a,{lhs=>$_->[3],rhs=>$_->[1],op=>'<=',source_kind=>'sample_capture'}} {name=>"${tn}_sample_$i",kind=>'sequential',assignments=>\@a,transitions=>[]} }
sub _ir_phase { my ($cl,$tn,$i)=@_; my $name=$cl->[1]; {name=>"${tn}_phase_$i",kind=>'sequential',assignments=>[],transitions=>[],phase_name=>$name} }
sub _ir_stage {
    my ($cl, $tn, $i, $actor) = @_;
    my $stage = _parse_stage_handshake_clause($cl, $tn, 'transaction body');
    my %inputs = map { $_->{name} => 1 } @{$actor->{interface}{inputs} || []};
    my %outputs = map { $_->{name} => 1 } @{$actor->{interface}{outputs} || []};

    confess "Transaction '$tn': stage '$stage->{name}' input '$stage->{ready}' is not an actor input\n"
        unless $inputs{$stage->{ready}};
    confess "Transaction '$tn': stage '$stage->{name}' output '$stage->{valid}' is not an actor output\n"
        unless $outputs{$stage->{valid}};

    return {
        name        => "${tn}_stage_$i",
        kind        => 'stage',
        stage_name  => $stage->{name},
        ready       => $stage->{ready},
        valid       => $stage->{valid},
        assignments => [
            { lhs => $stage->{valid}, rhs => 1, op => '=', source_kind => 'stage_valid' },
        ],
        transitions => [],
    };
}

sub _ir_contract {
    my ($cl, $tn, $i, $actor, $widths, $counters, $storage_roles, $seen_contracts) = @_;
    my $contract = _parse_bounded_eventual_contract_clause($cl, $tn, 'transaction body');
    my %interface_signals = map {
        $_->{name} => 1
    } (@{$actor->{interface}{inputs} || []}, @{$actor->{interface}{outputs} || []});

    confess "Transaction '$tn': duplicate contract '$contract->{name}'\n"
        if $seen_contracts->{$contract->{name}}++;
    confess "Transaction '$tn': contract '$contract->{name}' signal '$contract->{signal}' is not an actor interface signal\n"
        unless $interface_signals{$contract->{signal}};

    my $signals = _contract_monitor_signals($tn, $i);
    _validate_contract_monitor_signal_names($tn, $contract, $signals, $actor, $widths, $counters);

    my ($arm, $pending, $age, $fail) = @{$signals}{qw(arm pending age fail)};
    my $observed = $contract->{signal};
    my $last_cycle = $contract->{within_cycles} - 1;
    my $age_width = _unsigned_width_for_max($last_cycle);
    $counters->{$arm} = 1;
    $counters->{$pending} = 1;
    $counters->{$age} = $age_width;
    $counters->{$fail} = 1;
    if (ref($storage_roles) eq 'HASH') {
        $storage_roles->{$pending} = 'temporal_contract_monitor';
        $storage_roles->{$age}     = 'temporal_contract_monitor';
        $storage_roles->{$fail}    = 'temporal_contract_monitor';
    }

    my $arm_start_guard = "(& $arm (! $pending))";
    my $expiry_guard = "(& $pending (! $observed) (== $age $last_cycle))";
    my $clear_guard = "(| (& $pending $observed) $expiry_guard)";
    my $fail_guard = "(| (& $arm $pending) $expiry_guard)";
    my @monitor_assignments = (
        {
            lhs         => $pending,
            rhs         => 1,
            op          => '<-',
            guard       => { expr => $arm_start_guard },
            source_kind => 'contract_pending_set',
        },
        {
            lhs         => $pending,
            rhs         => 0,
            op          => '<-',
            guard       => { expr => $clear_guard },
            source_kind => 'contract_pending_clear',
        },
        {
            lhs         => $age,
            rhs         => 0,
            op          => '<-',
            guard       => { expr => $arm_start_guard },
            source_kind => 'contract_age_reset',
        },
        {
            lhs         => $fail,
            rhs         => 1,
            op          => '<-',
            guard       => { expr => $fail_guard },
            source_kind => 'contract_fail',
        },
    );

    if ($contract->{within_cycles} > 1) {
        my $advance_guard = "(& $pending (! $observed) (! (== $age $last_cycle)))";
        splice @monitor_assignments, 3, 0, {
            lhs         => $age,
            rhs         => "(+ $age 1)",
            op          => '<-',
            guard       => { expr => $advance_guard },
            source_kind => 'contract_age_increment',
        };
    }

    my $state = {
        name          => $signals->{state},
        kind          => 'contract',
        contract_name => $contract->{name},
        assignments   => [
            { lhs => $arm, rhs => 1, op => '=', source_kind => 'contract_arm_request' },
        ],
        transitions   => [],
    };
    my $dt = {
        name        => $signals->{monitor},
        kind        => 'temporal_contract_monitor',
        assignments => \@monitor_assignments,
    };
    my $summary = {
        transaction     => $tn,
        name            => $contract->{name},
        kind            => 'bounded_eventually',
        trigger         => $signals->{state},
        signal          => $contract->{signal},
        within_cycles   => $contract->{within_cycles},
        arm_signal      => $signals->{arm},
        pending_signal  => $signals->{pending},
        counter_signal  => $signals->{age},
        fail_signal     => $signals->{fail},
        monitor_dt      => $signals->{monitor},
        overlap_policy  => 'fail',
    };

    return ($state, $dt, $summary);
}

sub _contract_monitor_signals {
    my ($tn, $i) = @_;
    my $prefix = "${tn}_contract_$i";
    return {
        state   => $prefix,
        monitor => "${prefix}_monitor",
        arm     => "${prefix}_arm",
        pending => "${prefix}_pending",
        age     => "${prefix}_age",
        fail    => "${prefix}_fail",
    };
}

sub _validate_contract_monitor_signal_names {
    my ($tn, $contract, $signals, $actor, $widths, $counters) = @_;
    my %reserved;
    $reserved{$_->{name}} = 1 for @{$actor->{interface}{inputs} || []};
    $reserved{$_->{name}} = 1 for @{$actor->{interface}{outputs} || []};
    $reserved{$_} = 1 for keys %{$widths || {}};
    $reserved{$_} = 1 for keys %{$counters || {}};

    for my $role (qw(arm pending age fail)) {
        my $signal = $signals->{$role};
        confess "Transaction '$tn': contract '$contract->{name}' generated signal '$signal' collides with an existing signal\n"
            if $reserved{$signal};
    }

    return 1;
}

sub _unsigned_width_for_max {
    my ($max_value) = @_;
    return 1 unless defined($max_value) && $max_value > 0;

    my $width = 1;
    my $max_representable = 1;
    while ($max_representable < $max_value) {
        ++$width;
        $max_representable = (2 ** $width) - 1;
    }
    return $width;
}
sub _ir_placeholder{ my ($cl,$tn,$i)=@_; {name=>"${tn}_$cl->[0]_$i",kind=>'sequential',assignments=>[],transitions=>[]} }
sub _ir_do {
    my ($cl, $tn, $i, $do_ref, $label) = @_;
    $label //= 'transaction body';
    my $c = $cl->[1];
    my $prefix = (ref($do_ref) eq 'HASH' && $do_ref->{generated_child})
        ? $do_ref->{instance}
        : $c;
    my @assignments;
    if (ref($do_ref) eq 'HASH' && $do_ref->{generated_child}) {
        @assignments = (
            { lhs => "${prefix}_start", rhs => 1, op => '=', source_kind => 'do_start' },
        );
    } else {
        my @bindings = @{_activation_bindings_from_clause($cl, $tn, $label)};
        @assignments = (
            _activation_input_assignments(\@bindings, 'do_input_binding'),
            { lhs => "${prefix}_start", rhs => 1, op => '=', source_kind => 'do_start' },
            _activation_output_assignments(\@bindings, "${prefix}_done", 'do_output_binding'),
        );
    }
    return {
        name        => "${tn}_do_$i",
        kind        => 'await',
        assignments => \@assignments,
        transitions => [],
        guard       => { port => "${prefix}_done" },
    };
}

sub _ir_spawn {
    my ($cl, $tn, $i) = @_;
    my $inst = $cl->[3] || "${tn}_$i";
    return {
        name        => "${tn}_spawn_$i",
        kind        => 'sequential',
        assignments => [{ lhs => "${inst}_start", rhs => 1, op => '=', source_kind => 'spawn_start' }],
        transitions => [],
    };
}

sub _activation_input_assignments {
    my ($bindings, $source_kind) = @_;
    return map {
        +{
            lhs         => $_->{port},
            rhs         => _activation_binding_actor_expr_text($_),
            op          => '=',
            source_kind => $source_kind,
        }
    } grep { $_->{role} eq 'input' } @$bindings;
}

sub _activation_output_assignments {
    my ($bindings, $done, $source_kind) = @_;
    return map {
        +{
            lhs         => $_->{actor_signal},
            rhs         => $_->{port},
            op          => '=',
            guard       => { port => $done },
            source_kind => $source_kind,
        }
    } grep { $_->{role} eq 'output' } @$bindings;
}
sub _ir_when     { my ($cl,$tn,$i)=@_; {name=>"${tn}_when_$i",kind=>'branch',condition=>$cl->[1],body_clauses=>[@{$cl}[2..$#$cl]],assignments=>[],transitions=>[]} }
sub _expand_when { my ($cl,$tn,$ir,$ps,$drives,$wd,$widths,$counters,$storage_roles,$actor,$bank_accesses,$spawn_refs,$constant_values,$generated_children,$repeat_do_ordinal_ref)=@_; my @s; my $bstate=_ir_when($cl,$tn,$$ir++); push @s,$bstate; my @body_states; my @lp;
    for my $bc(@{$bstate->{body_clauses}}){next unless ref($bc)eq'ARRAY';my$bk=$bc->[0];
        if($bk eq'drive'){push @body_states,_ir_transaction_drive_clause($bc,$tn,$$ir++,$drives,[splice @lp])}
        elsif($bk eq'await'){push @body_states,_ir_await($bc,$tn,$$ir++,$wd,[splice @lp])}
        elsif($bk eq'sample'){push @lp,$bc}
        elsif($bk eq'wait'){
            my $wait = _wait_count_spec($bc,$tn,'when body',$actor,$widths,1);
            if ($wait->{kind} eq 'static') {
                if ($wait->{cycles} > 0) {
                    push @body_states,@{_ir_wait($bc,$tn,$ir,[splice @lp],$actor,'when body',$wait)};
                }
            } else {
                my ($states,$counter,$width)=_ir_dynamic_wait($bc,$tn,$ir,$wait,[splice @lp]);
                push @body_states,@$states;
                _register_counter_width($counters,$counter,$width) if $counters;
                $storage_roles->{$counter}='dynamic_wait_counter' if ref($storage_roles)eq'HASH';
            }
        }
        elsif($bk eq'complete'){push @body_states,_ir_complete($bc,$tn,$$ir++)}
        elsif($bk eq'repeat'){my($rs,$rc,$rw,$rdw)=_ir_repeat($bc,$tn,$ir,\@lp,$wd,$drives,$widths,$actor,$bank_accesses,$spawn_refs,$constant_values,$generated_children,$repeat_do_ordinal_ref);push @body_states,@$rs;_register_repeat_counters($counters,$storage_roles,$rc,$rw,$rdw)}
        elsif($bk eq'update'||$bk eq'set'||$bk eq'shift_left'||$bk eq'shift_right'||$bk eq'assemble'||$bk eq'extract'){_push_sample_state(\@body_states,$tn,\@lp,$ir);push @body_states,_ir_data_op($bk,$bc,$tn,$$ir++,$widths)}
        elsif($bk eq'store'||$bk eq'load'){_push_sample_state(\@body_states,$tn,\@lp,$ir);my($state,$accesses)=_ir_bank_access($bc,$tn,$$ir++,$actor,$widths,'transaction');push @body_states,$state;push @$bank_accesses,@$accesses if ref($bank_accesses)eq'ARRAY'}
        elsif($bk eq'when'){my($ws)=_expand_when($bc,$tn,$ir,\@lp,$drives,$wd,$widths,$counters,$storage_roles,$actor,$bank_accesses);push @body_states,@$ws}}
    if(@lp){push @body_states,_ir_sample_state($tn,\@lp,$$ir++)}
    if(@body_states){$bstate->{true_target}=$body_states[0]{name};$bstate->{branch_state_names}=[map { $_->{name} } @body_states];push @s,@body_states}
    return (\@s);
}

sub _is_default_switch_value {
    my ($value) = @_;
    return defined($value)
        && !ref($value)
        && ($value eq 'default' || $value eq '_');
}

sub _canonical_switch_value_key {
    my ($value) = @_;
    return '__default__' if _is_default_switch_value($value);
    return defined($value) ? "$value" : '';
}

sub _expand_switch { my ($cl,$tn,$ir,$ps,$drives,$wd,$widths,$counters,$storage_roles,$actor,$bank_accesses,$spawn_refs,$constant_values,$generated_children,$repeat_do_ordinal_ref)=@_; my $signal=$cl->[1]; my @branches; my @branch_state_names; my @branch_end_names; my %seen_val; my @s;
    for my $i(2..$#$cl){my$br=$cl->[$i];next unless ref($br)eq'ARRAY'&&@$br>=2;my$val=$br->[0];my@bc=@{$br}[1..$#$br];
        my $seen_key = _canonical_switch_value_key($val);
        confess "Switch '$tn': duplicate value '$val'\n" if$seen_val{$seen_key}++;my@body_states;my@lp;
        for my $bc2(@bc){next unless ref($bc2)eq'ARRAY';my$bk2=$bc2->[0];
            if($bk2 eq'drive'){push @body_states,_ir_transaction_drive_clause($bc2,$tn,$$ir++,$drives,[splice @lp])}
            elsif($bk2 eq'await'){push @body_states,_ir_await($bc2,$tn,$$ir++,$wd,[splice @lp])}
            elsif($bk2 eq'sample'){push @lp,$bc2}
            elsif($bk2 eq'wait'){
                my $wait = _wait_count_spec($bc2,$tn,'switch body',$actor,$widths,1);
                if ($wait->{kind} eq 'static') {
                    if ($wait->{cycles} > 0) {
                        push @body_states,@{_ir_wait($bc2,$tn,$ir,[splice @lp],$actor,'switch body',$wait)};
                    }
                } else {
                    my ($states,$counter,$width)=_ir_dynamic_wait($bc2,$tn,$ir,$wait,[splice @lp]);
                    push @body_states,@$states;
                    _register_counter_width($counters,$counter,$width) if $counters;
                    $storage_roles->{$counter}='dynamic_wait_counter' if ref($storage_roles)eq'HASH';
                }
            }
            elsif($bk2 eq'repeat'){my($rs,$rc,$rw,$rdw)=_ir_repeat($bc2,$tn,$ir,\@lp,$wd,$drives,$widths,$actor,$bank_accesses,$spawn_refs,$constant_values,$generated_children,$repeat_do_ordinal_ref);push @body_states,@$rs;_register_repeat_counters($counters,$storage_roles,$rc,$rw,$rdw)}
            elsif($bk2 eq'update'||$bk2 eq'set'||$bk2 eq'shift_left'||$bk2 eq'shift_right'||$bk2 eq'assemble'||$bk2 eq'extract'){_push_sample_state(\@body_states,$tn,\@lp,$ir);push @body_states,_ir_data_op($bk2,$bc2,$tn,$$ir++,$widths)}
            elsif($bk2 eq'store'||$bk2 eq'load'){_push_sample_state(\@body_states,$tn,\@lp,$ir);my($state,$accesses)=_ir_bank_access($bc2,$tn,$$ir++,$actor,$widths,'transaction');push @body_states,$state;push @$bank_accesses,@$accesses if ref($bank_accesses)eq'ARRAY'}
            elsif($bk2 eq'when'){my($ws)=_expand_when($bc2,$tn,$ir,\@lp,$drives,$wd,$widths,$counters,$storage_roles,$actor,$bank_accesses);push @body_states,@$ws}}
        if(@lp||!@body_states){push @body_states,_ir_sample_state($tn,\@lp,$$ir++)if@lp;push @body_states,{name=>"${tn}_switch_${val}_" . $$ir++,kind=>'sequential',assignments=>[],transitions=>[]}unless@body_states}
        push @branches,{value=>$val,body_start=>$body_states[0]{name}};
        push @branch_state_names, map { $_->{name} } @body_states;
        push @branch_end_names, $body_states[-1]{name};
        push @s,@body_states}
    my $sw_name="${tn}_switch_" . $$ir++;
    my $bstate={name=>$sw_name,kind=>'switch',signal=>$signal,branches=>\@branches,has_default_branch=>scalar(grep { _is_default_switch_value($_->{value}) } @branches) ? 1 : 0,branch_state_names=>\@branch_state_names,branch_end_names=>\@branch_end_names,assignments=>[],transitions=>[]};
    unshift @s,$bstate; return (\@s);
}
sub _ir_sync_all { my ($tn,$i,$dps)=@_; {name=>"${tn}_await_all_$i",kind=>'sync_all',assignments=>[],transitions=>[],done_ports=>[@$dps]} }
sub _ir_sync_any { my ($tn,$i,$dps)=@_; {name=>"${tn}_await_any_$i",kind=>'sync_any',assignments=>[],transitions=>[],done_ports=>[@$dps]} }

sub _expand_loop_body {
    my ($body_clauses, $tn, $ir, $pending_samples, $wd, $drives, $widths, $counters, $storage_roles, $actor, $bank_accesses, $body_label) = @_;
    my @states;
    my @lp = @{$pending_samples || []};
    $body_label //= 'loop body';

    for my $bc (@$body_clauses) {
        next unless ref($bc) eq 'ARRAY';
        my $bk = $bc->[0];

        if ($bk eq 'drive') {
            push @states, _ir_transaction_drive_clause($bc, $tn, $$ir++, $drives, [splice @lp]);
        } elsif ($bk eq 'await') {
            push @states, _ir_await($bc, $tn, $$ir++, $wd, [splice @lp]);
        } elsif ($bk eq 'sample') {
            push @lp, $bc;
        } elsif ($bk eq 'wait') {
            my $wait = _wait_count_spec($bc, $tn, $body_label, $actor, $widths, 1);
            if ($wait->{kind} eq 'static') {
                if ($wait->{cycles} > 0) {
                    push @states, @{_ir_wait($bc, $tn, $ir, [splice @lp], $actor, $body_label, $wait)};
                }
            } else {
                my ($dynamic_states, $counter, $counter_width) = _ir_dynamic_wait($bc, $tn, $ir, $wait, [splice @lp]);
                push @states, @$dynamic_states;
                _register_counter_width($counters, $counter, $counter_width) if $counters;
                $storage_roles->{$counter} = 'dynamic_wait_counter'
                    if ref($storage_roles) eq 'HASH';
            }
        } elsif ($bk eq 'complete') {
            push @states, _ir_complete($bc, $tn, $$ir++);
        } elsif ($bk eq 'repeat') {
            my ($rs, $rc, $rw, $rdw) = _ir_repeat($bc, $tn, $ir, \@lp, $wd, $drives, $widths, $actor, $bank_accesses);
            push @states, @$rs;
            _register_repeat_counters($counters, $storage_roles, $rc, $rw, $rdw);
        } elsif ($bk eq 'update' || $bk eq 'set' || $bk eq 'shift_left' || $bk eq 'shift_right' || $bk eq 'assemble' || $bk eq 'extract') {
            _push_sample_state(\@states, $tn, \@lp, $ir);
            push @states, _ir_data_op($bk, $bc, $tn, $$ir++, $widths);
        } elsif ($bk eq 'store' || $bk eq 'load') {
            _push_sample_state(\@states, $tn, \@lp, $ir);
            my ($state, $accesses) = _ir_bank_access($bc, $tn, $$ir++, $actor, $widths, 'transaction');
            push @states, $state;
            push @$bank_accesses, @$accesses if ref($bank_accesses) eq 'ARRAY';
        } elsif ($bk eq 'when') {
            my ($ws) = _expand_when($bc, $tn, $ir, \@lp, $drives, $wd, $widths, $counters, $storage_roles, $actor, $bank_accesses);
            push @states, @$ws;
        }
    }

    if (@lp) {
        push @states, _ir_sample_state($tn, \@lp, $$ir++);
    }

    return \@states;
}

sub _ir_repeat {
    my ($cl,$tn,$ir,$ps,$wd,$drives,$widths,$actor,$bank_accesses,$spawn_refs,$constant_values,$generated_children,$repeat_do_ordinal_ref)=@_; my $ctr="${tn}_cnt"; my @s; my @lp; my @dynamic_wait_counters; my @spawn_done_ports;
    my $width = _repeat_count_width($cl->[1], $widths);
    push @s, {name=>"${tn}_repeat_init_".$$ir++,kind=>'sequential',assignments=>[{lhs=>$ctr,rhs=>$cl->[1],op=>'<='}],transitions=>[]};
    for my $bc(@{$cl}[2..$#$cl]){next unless ref($bc)eq'ARRAY';my $bk=$bc->[0];
        if($bk eq'drive'){push @s,_ir_transaction_drive_clause($bc,$tn,$$ir++,$drives,[splice @lp])}
        elsif($bk eq'await'){push @s,_ir_await($bc,$tn,$$ir++,$wd,[splice @lp])}
        elsif($bk eq'sample'){push @lp,$bc}
        elsif($bk eq'wait'){
            my $wait = _wait_count_spec($bc,$tn,'repeat body',$actor,$widths,1);
            if ($wait->{kind} eq 'static') {
                if ($wait->{cycles} > 0) {
                    push @s,@{_ir_wait($bc,$tn,$ir,[splice @lp],$actor,'repeat body',$wait)};
                }
            } else {
                my ($states,$counter,$counter_width)=_ir_dynamic_wait($bc,$tn,$ir,$wait,[splice @lp]);
                push @s,@$states;
                push @dynamic_wait_counters,{name=>$counter,width=>$counter_width};
            }
        }
        elsif($bk eq'update'||$bk eq'set'||$bk eq'shift_left'||$bk eq'shift_right'||$bk eq'assemble'||$bk eq'extract'){_push_sample_state(\@s,$tn,\@lp,$ir);push @s,_ir_data_op($bk,$bc,$tn,$$ir++,$widths)}
        elsif($bk eq'store'||$bk eq'load'){_push_sample_state(\@s,$tn,\@lp,$ir);my($state,$accesses)=_ir_bank_access($bc,$tn,$$ir++,$actor,$widths,'transaction');push @s,$state;push @$bank_accesses,@$accesses if ref($bank_accesses)eq'ARRAY'}
        elsif($bk eq'spawn'){
            _push_sample_state(\@s,$tn,\@lp,$ir);
            my $spawn_ref = _spawn_ref_from_clause($bc,$tn,$constant_values || {},$actor,'repeat body');
            push @$spawn_refs, $spawn_ref if ref($spawn_refs) eq 'ARRAY';
            push @spawn_done_ports, "$spawn_ref->{instance}_done";
            push @s,_ir_spawn($bc,$tn,$$ir++);
        }
        elsif($bk eq'do'){
            _push_sample_state(\@s,$tn,\@lp,$ir);
            my $repeat_do_ordinal = ref($repeat_do_ordinal_ref) ? $$repeat_do_ordinal_ref++ : 0;
            my $do_ref = _repeat_do_ref_from_clause($bc,$tn,$repeat_do_ordinal,$constant_values || {},$actor,$generated_children);
            push @$spawn_refs, _clone_isf_value($do_ref)
                if ref($spawn_refs) eq 'ARRAY' && $do_ref->{generated_child};
            push @s,_ir_do($bc,$tn,$$ir++,$do_ref,'repeat body');
        }
        elsif($bk eq'await_all'){
            _push_sample_state(\@s,$tn,\@lp,$ir);
            push @s,_ir_sync_all($tn,$$ir++,\@spawn_done_ports);
            @spawn_done_ports = ();
        }
        elsif($bk eq'await_any'){
            _push_sample_state(\@s,$tn,\@lp,$ir);
            push @s,_ir_sync_any($tn,$$ir++,\@spawn_done_ports);
            @spawn_done_ports = () if @spawn_done_ports <= 1;
        }}
    if(@lp){push @s,_ir_sample_state($tn,\@lp,$$ir++)}
    my $fb=$s[0]{name};
    push @s, {name=>"${tn}_repeat_check_".$$ir++,kind=>'repeat_check',assignments=>[{lhs=>$ctr,rhs=>"(- $ctr 1)",op=>'<-'}],transitions=>[],loop_target=>$fb,counter=>$ctr};
    return (\@s,$ctr,$width,\@dynamic_wait_counters);
}

sub _apply_rule_slot_resource_arbitration {
    my ($ir, $actor) = @_;
    my @resources = @{$actor->{resources} || []};
    my %rule_dt = map {
        (($_->{kind} // '') eq 'rule') ? ($_->{name} => $_) : ()
    } @{$ir->{dt_blocks} || []};
    my %original_guard = map {
        $_ => (_guard_condition_expr($rule_dt{$_}{dte_guard}) // '1')
    } keys %rule_dt;
    my $model = _build_rule_priority_model($actor);
    my @grants;

    for my $resource (@resources) {
        my @users = @{$resource->{users} || []};
        next unless @users;

        my $resource_name = $resource->{name} // '<unnamed>';
        my $kind = $resource->{kind} // '';
        my $arbiter = $resource->{arbiter} // '';

        _resource_arbitration_error(
            'isf_resource_unsupported_kind',
            $resource_name,
            "resource kind '$kind' is not enforced yet",
        ) unless $kind eq 'rule_slot';

        _resource_arbitration_error(
            'isf_resource_unsupported_arbiter',
            $resource_name,
            "arbiter '$arbiter' is not enforced yet for rule_slot resources",
        ) unless $arbiter eq 'priority';

        for my $user (@users) {
            _resource_arbitration_error(
                'isf_resource_unknown_user',
                $resource_name,
                "user '$user' is not a lowered rule",
            ) unless $rule_dt{$user};
        }

        for my $left_idx (0 .. $#users) {
            my $left = $users[$left_idx];
            for my $right_idx ($left_idx + 1 .. $#users) {
                my $right = $users[$right_idx];
                my $left_over_right = _priority_dominates($model, $left, $right);
                my $right_over_left = _priority_dominates($model, $right, $left);

                if ($left_over_right && $right_over_left) {
                    _resource_arbitration_error(
                        'isf_resource_priority_cycle',
                        $resource_name,
                        "priority cycle leaves no unique winner between '$left' and '$right'",
                    );
                }

                if (!$left_over_right && !$right_over_left) {
                    _resource_arbitration_error(
                        'isf_resource_priority_incomplete',
                        $resource_name,
                        "priority arbiter needs an ordering between '$left' and '$right'",
                    );
                }
            }
        }

        for my $user (@users) {
            my @higher = sort grep {
                $_ ne $user && _priority_dominates($model, $_, $user)
            } @users;
            my $dt = $rule_dt{$user};
            my @higher_conditions = map { $original_guard{$_} // '1' } @higher;

            push @grants, {
                resource => $resource_name,
                kind     => $kind,
                arbiter  => $arbiter,
                user     => $user,
                higher   => [@higher],
            };
            push @{$dt->{resource_grants}}, {
                resource => $resource_name,
                higher   => [@higher],
            };

            next unless @higher;
            $dt->{dte_guard} = _combine_rule_dte_with_resource_suppressors(
                $dt->{dte_guard},
                \@higher_conditions,
            );
            _mark_rule_assignments_resource_suppressed($dt, \@higher);
        }
    }

    return { grants => \@grants, issues => [] };
}

sub _combine_rule_dte_with_resource_suppressors {
    my ($guard, $suppressor_conditions) = @_;
    my @terms;
    my $existing = _guard_condition_expr($guard);
    push @terms, $existing if defined($existing) && $existing ne '1';

    my @conditions = grep { defined($_) && length($_) } @$suppressor_conditions;
    if (@conditions == 1) {
        push @terms, "(! $conditions[0])";
    } elsif (@conditions > 1) {
        push @terms, '(! (| ' . join(' ', @conditions) . '))';
    }

    return { port => '1' } unless @terms;
    return { expr => $terms[0] } if @terms == 1;
    return { expr => '(& ' . join(' ', @terms) . ')' };
}

sub _mark_rule_assignments_resource_suppressed {
    my ($dt, $higher_rules) = @_;
    for my $assignment (@{$dt->{assignments} || []}) {
        my %seen = map { $_ => 1 } @{$assignment->{resource_suppressed_by} || []};
        for my $higher (@$higher_rules) {
            next if $seen{$higher}++;
            push @{$assignment->{resource_suppressed_by}}, $higher;
        }
    }
}

sub _resource_arbitration_error {
    my ($code, $resource_name, $reason) = @_;
    confess "ISF resource arbitration '$code' on resource '$resource_name': $reason\n";
}

sub _apply_rule_priority_resolution {
    my ($ir, $actor) = @_;
    my $model = _build_rule_priority_model($actor);
    my @records = _rule_data_assignment_refs($ir);
    my %by_target;
    my @issues;
    my @resolutions;

    for my $record (@records) {
        push @{$by_target{$record->{target}}}, $record;
    }

    for my $target (sort keys %by_target) {
        my $target_records = $by_target{$target};
        next unless @$target_records > 1;

        for my $left_idx (0 .. $#$target_records) {
            my $left = $target_records->[$left_idx];
            for my $right_idx ($left_idx + 1 .. $#$target_records) {
                my $right = $target_records->[$right_idx];
                next if _rule_assignment_pair_compatible($left, $right);
                next if _condition_terms_prove_disjoint($left, $right);

                if (($left->{operator} // '') ne ($right->{operator} // '')) {
                    push @issues, _priority_conflict_issue(
                        code         => 'isf_priority_mixed_timing_conflict',
                        proof_status => 'mixed_timing',
                        target       => $target,
                        reason       => 'priority cannot resolve mixed timing operators',
                        left         => $left,
                        right        => $right,
                    );
                    next;
                }

                my $left_over_right = _priority_dominates($model, $left->{rule}, $right->{rule});
                my $right_over_left = _priority_dominates($model, $right->{rule}, $left->{rule});

                if ($left_over_right && $right_over_left) {
                    push @issues, _priority_conflict_issue(
                        code         => 'isf_priority_cycle_conflict',
                        proof_status => 'priority_cycle',
                        target       => $target,
                        reason       => 'priority cycle leaves no unique winner',
                        left         => $left,
                        right        => $right,
                    );
                    next;
                }

                if ($left_over_right) {
                    _suppress_priority_assignment($right, $left, \@resolutions);
                } elsif ($right_over_left) {
                    _suppress_priority_assignment($left, $right, \@resolutions);
                }
            }
        }
    }

    _apply_rule_assignment_suppressions(\@records);

    return {
        resolutions => \@resolutions,
        issues      => \@issues,
    };
}

sub _apply_rule_transaction_priority_resolution {
    my ($ir, $actor) = @_;
    my $model = _build_owner_priority_model($actor);
    my @records = (_rule_data_assignment_refs($ir), _transaction_data_assignment_refs($ir));
    my %by_target;
    my @issues;
    my @resolutions;

    for my $record (@records) {
        push @{$by_target{$record->{target}}}, $record;
    }

    for my $target (sort keys %by_target) {
        my $target_records = $by_target{$target};
        next unless @$target_records > 1;

        for my $left_idx (0 .. $#$target_records) {
            my $left = $target_records->[$left_idx];
            for my $right_idx ($left_idx + 1 .. $#$target_records) {
                my $right = $target_records->[$right_idx];
                next unless _owner_kind_pair($left, $right, 'rule', 'transaction');
                next if _rule_assignment_pair_compatible($left, $right);

                if (($left->{operator} // '') ne ($right->{operator} // '')) {
                    push @issues, _priority_conflict_issue(
                        code         => 'isf_priority_mixed_timing_conflict',
                        proof_status => 'mixed_timing',
                        target       => $target,
                        reason       => 'priority cannot resolve mixed timing operators',
                        left         => $left,
                        right        => $right,
                    );
                    next;
                }

                my $left_owner = _priority_record_owner($left);
                my $right_owner = _priority_record_owner($right);
                my $left_over_right = _priority_dominates($model, $left_owner, $right_owner);
                my $right_over_left = _priority_dominates($model, $right_owner, $left_owner);

                if ($left_over_right && $right_over_left) {
                    push @issues, _priority_conflict_issue(
                        code         => 'isf_priority_cycle_conflict',
                        proof_status => 'priority_cycle',
                        target       => $target,
                        reason       => 'priority cycle leaves no unique winner',
                        left         => $left,
                        right        => $right,
                    );
                    next;
                }

                if (!$left_over_right && !$right_over_left) {
                    push @issues, _priority_conflict_issue(
                        code         => 'isf_conflicting_rule_transaction_writes',
                        proof_status => 'proved_conflict',
                        target       => $target,
                        reason       => 'overlapping rule/transaction data writes need actor-level priority',
                        left         => $left,
                        right        => $right,
                    );
                    next;
                }

                my ($winner, $loser) = $left_over_right ? ($left, $right) : ($right, $left);
                if (($winner->{owner_kind} // '') eq 'transaction' && ($loser->{owner_kind} // '') eq 'rule') {
                    push @issues, _priority_conflict_issue(
                        code         => 'isf_priority_transaction_winner_unsupported',
                        proof_status => 'not_doable',
                        target       => $target,
                        reason       => 'transaction-over-rule priority needs state-active guards before non-state rule suppression can be lowered',
                        left         => $winner,
                        right        => $loser,
                    );
                    next;
                }

                _suppress_priority_assignment($loser, $winner, \@resolutions);
            }
        }
    }

    _apply_rule_assignment_suppressions(\@records);

    return {
        resolutions => \@resolutions,
        issues      => \@issues,
    };
}

sub _merge_priority_resolution {
    my @results = @_;
    my @resolutions;
    my @issues;

    for my $result (@results) {
        next unless ref($result) eq 'HASH';
        push @resolutions, @{$result->{resolutions} || []};
        push @issues, @{$result->{issues} || []};
    }

    return {
        resolutions => \@resolutions,
        issues      => \@issues,
    };
}

sub _build_rule_priority_model {
    my ($actor) = @_;
    my %rules = map { $_->{name} => 1 } @{$actor->{rules} || []};
    my %edges;

    for my $priority (@{$actor->{priorities} || []}) {
        my ($higher, undef, $lower) = @$priority;
        next unless $rules{$higher} && $rules{$lower};
        $edges{$higher}{$lower} = 1;
    }

    for my $rule (@{$actor->{rules} || []}) {
        my $higher = $rule->{name};
        for my $action (@{$rule->{actions} || []}) {
            next unless ref($action) eq 'ARRAY'
                && defined($action->[0])
                && !ref($action->[0])
                && $action->[0] eq 'priority';
            my $lower = $action->[2];
            next unless $rules{$higher} && $rules{$lower};
            $edges{$higher}{$lower} = 1;
        }
    }

    return { edges => \%edges };
}

sub _build_owner_priority_model {
    my ($actor) = @_;
    my %owners = (
        map({ $_->{name} => 1 } @{$actor->{rules} || []}),
        map({ $_->{name} => 1 } @{$actor->{transactions} || []}),
    );
    my %rules = map { $_->{name} => 1 } @{$actor->{rules} || []};
    my %edges;

    for my $priority (@{$actor->{priorities} || []}) {
        my ($higher, undef, $lower) = @$priority;
        next unless $owners{$higher} && $owners{$lower};
        $edges{$higher}{$lower} = 1;
    }

    for my $rule (@{$actor->{rules} || []}) {
        my $higher = $rule->{name};
        for my $action (@{$rule->{actions} || []}) {
            next unless ref($action) eq 'ARRAY'
                && defined($action->[0])
                && !ref($action->[0])
                && $action->[0] eq 'priority';
            my $lower = $action->[2];
            next unless $rules{$higher} && $rules{$lower};
            $edges{$higher}{$lower} = 1;
        }
    }

    return { edges => \%edges };
}

sub _rule_data_assignment_refs {
    my ($ir) = @_;
    my @records;

    for my $dt (@{$ir->{dt_blocks} || []}) {
        next unless ($dt->{kind} // '') eq 'rule';
        my $assignment_index = 0;
        my $rule_condition = _guard_condition_expr($dt->{dte_guard}) // '1';
        my $rule_condition_terms = $dt->{dte_guard_terms};
        for my $assignment (@{$dt->{assignments} || []}) {
            if (($assignment->{source_kind} // '') eq 'rule_action' && defined $assignment->{lhs}) {
                my $activation_condition = _combine_condition_exprs(
                    $rule_condition,
                    _guard_condition_expr($assignment->{guard}),
                );
                push @records, {
                    rule             => $dt->{name},
                    owner            => $dt->{name},
                    owner_kind       => 'rule',
                    source_kind      => 'rule_action',
                    target           => $assignment->{lhs},
                    operator         => $assignment->{op},
                    rhs              => $assignment->{rhs},
                    assignment       => $assignment,
                    rule_condition   => $activation_condition,
                    owner_condition  => $activation_condition,
                    condition_terms   => $rule_condition_terms,
                    assignment_index => $assignment_index,
                };
            }
            $assignment_index++;
        }
    }

    return @records;
}

sub _transaction_data_assignment_refs {
    my ($ir) = @_;
    my @records;

    for my $state (@{$ir->{states} || []}) {
        my $transaction = _transaction_owner_from_state_name($state->{name});
        next unless defined($transaction) && length($transaction);

        my $assignment_index = 0;
        for my $assignment (@{$state->{assignments} || []}) {
            my $current_index = $assignment_index++;
            my $source_kind = _state_assignment_source_kind($state, $assignment);
            next unless _assignment_domain_hint($assignment, $source_kind) eq 'data';
            next unless defined $assignment->{lhs};

            push @records, {
                transaction      => $transaction,
                owner            => $transaction,
                owner_kind       => 'transaction',
                source_kind      => $source_kind,
                target           => $assignment->{lhs},
                operator         => $assignment->{op},
                rhs              => $assignment->{rhs},
                assignment       => $assignment,
                state            => $state->{name},
                state_kind       => $state->{kind},
                owner_condition  => _guard_condition_expr($assignment->{guard}) // '1',
                assignment_index => $current_index,
            };
        }
    }

    for my $dt (@{$ir->{dt_blocks} || []}) {
        next unless ($dt->{kind} // '') eq 'spawn_port_binding';
        next unless (_dt_assignment_owner_kind($dt) // '') eq 'transaction';

        my $assignment_index = 0;
        for my $assignment (@{$dt->{assignments} || []}) {
            my $current_index = $assignment_index++;
            my $source_kind = _dt_assignment_source_kind($dt, $assignment);
            next unless _assignment_domain_hint($assignment, $source_kind) eq 'data';
            next unless defined $assignment->{lhs};

            push @records, {
                transaction      => _dt_assignment_owner($dt),
                owner            => _dt_assignment_owner($dt),
                owner_kind       => 'transaction',
                source_kind      => $source_kind,
                target           => $assignment->{lhs},
                operator         => $assignment->{op},
                rhs              => $assignment->{rhs},
                assignment       => $assignment,
                state            => $dt->{name},
                state_kind       => $dt->{kind},
                owner_condition  => _combine_condition_exprs(
                    _guard_condition_expr($dt->{dte_guard}) // '1',
                    _guard_condition_expr($assignment->{guard}) // '1',
                ),
                assignment_index => $current_index,
            };
        }
    }

    return @records;
}

sub _rule_assignment_pair_compatible {
    my ($left, $right) = @_;
    return ($left->{operator} // '') eq ($right->{operator} // '')
        && _priority_record_rhs($left) eq _priority_record_rhs($right);
}

sub _priority_record_rhs {
    my ($record) = @_;
    return defined($record->{rhs}) ? "$record->{rhs}" : '';
}

sub _priority_dominates {
    my ($model, $higher, $lower) = @_;
    return 0 unless defined($higher) && defined($lower) && length($higher) && length($lower);
    return _priority_dominates_walk($model->{edges} || {}, $higher, $lower, {});
}

sub _priority_dominates_walk {
    my ($edges, $current, $target, $seen) = @_;
    my $next_edges = $edges->{$current} || {};
    return 1 if $next_edges->{$target};
    return 0 if $seen->{$current}++;

    for my $next (sort keys %$next_edges) {
        return 1 if _priority_dominates_walk($edges, $next, $target, $seen);
    }

    return 0;
}

sub _suppress_priority_assignment {
    my ($lower, $higher, $resolutions) = @_;
    my $higher_owner = _priority_record_owner($higher);
    my $lower_owner = _priority_record_owner($lower);
    $lower->{suppressed_by}{$higher_owner} = _priority_record_condition($higher);
    push @$resolutions, {
        target      => $lower->{target},
        winner      => $higher_owner,
        winner_kind => $higher->{owner_kind} // 'rule',
        loser       => $lower_owner,
        loser_kind  => $lower->{owner_kind} // 'rule',
    };
}

sub _apply_rule_assignment_suppressions {
    my ($records) = @_;

    for my $record (@$records) {
        my $suppressed_by = $record->{suppressed_by} || {};
        my @higher_rules = sort keys %$suppressed_by;
        next unless @higher_rules;

        my $assignment = $record->{assignment};
        my %merged = map { $_ => 1 } @{$assignment->{priority_suppressed_by} || []};
        $merged{$_} = 1 for @higher_rules;
        $assignment->{priority_suppressed_by} = [sort keys %merged];
        $assignment->{guard} = _combine_assignment_guard_with_priority_suppressors(
            $assignment->{guard},
            [ map { $suppressed_by->{$_} } @higher_rules ],
        );
    }
}

sub _priority_record_owner {
    my ($record) = @_;
    return $record->{owner} if defined($record->{owner}) && length($record->{owner});
    return $record->{rule} if defined($record->{rule}) && length($record->{rule});
    return $record->{transaction} if defined($record->{transaction}) && length($record->{transaction});
    return '';
}

sub _priority_record_condition {
    my ($record) = @_;
    return $record->{owner_condition}
        if defined($record->{owner_condition}) && length($record->{owner_condition});
    return $record->{rule_condition}
        if defined($record->{rule_condition}) && length($record->{rule_condition});
    return '1';
}

sub _combine_assignment_guard_with_priority_suppressors {
    my ($guard, $suppressor_conditions) = @_;
    my @terms;
    my $existing = _guard_condition_expr($guard);
    push @terms, $existing if defined($existing) && $existing ne '1';
    push @terms, map { _negated_condition_expr($_) } @$suppressor_conditions;

    return undef unless @terms;
    return { expr => $terms[0] } if @terms == 1;
    return { expr => '(& ' . join(' ', @terms) . ')' };
}

sub _combine_condition_exprs {
    my @raw_conditions = grep {
        defined($_) && length($_) && $_ ne '1'
    } @_;

    my @conditions = map { _condition_and_terms($_) } @raw_conditions;
    return '1' unless @conditions;
    return $conditions[0] if @conditions == 1;
    return '(& ' . join(' ', @conditions) . ')';
}

sub _condition_and_terms {
    my ($condition) = @_;
    return () unless defined($condition) && !ref($condition) && length($condition);
    return () if $condition eq '1';

    my @terms = _split_top_level_and_expr($condition);
    return map { _condition_and_terms($_) } @terms
        if @terms > 1 || (@terms == 1 && $terms[0] ne $condition);
    return ($condition);
}

sub _split_top_level_and_expr {
    my ($condition) = @_;
    return ($condition)
        unless defined($condition)
            && !ref($condition)
            && $condition =~ /\A\(&\s+(.+)\)\z/s;

    my $body = $1;
    my @terms;
    my $term = '';
    my $depth = 0;

    for my $idx (0 .. length($body) - 1) {
        my $char = substr($body, $idx, 1);
        if ($char =~ /\s/ && $depth == 0) {
            push @terms, $term if length $term;
            $term = '';
            next;
        }

        $term .= $char;
        if ($char eq '(') {
            $depth++;
        } elsif ($char eq ')') {
            $depth--;
            return ($condition) if $depth < 0;
        }
    }

    return ($condition) if $depth != 0;
    push @terms, $term if length $term;
    return @terms ? @terms : ($condition);
}

sub _guard_condition_expr {
    my ($guard) = @_;
    return undef unless $guard && ref($guard) eq 'HASH';
    return undef if defined($guard->{port}) && $guard->{port} eq '1';
    return $guard->{port} if defined($guard->{port}) && length($guard->{port});
    return $guard->{expr} if defined($guard->{expr}) && length($guard->{expr});
    if (defined($guard->{signal}) && defined($guard->{op})) {
        return "$guard->{signal}$guard->{op}$guard->{value}";
    }
    return undef;
}

sub _guard_literal_terms {
    my ($guard) = @_;
    return _condition_literal_terms($guard->{expr_ast})
        if $guard && ref($guard) eq 'HASH' && exists $guard->{expr_ast};
    my $condition = _guard_condition_expr($guard);
    return {} unless defined($condition);
    return _condition_literal_terms($condition);
}

sub _merge_literal_term_sets {
    my @sets = grep { defined $_ } @_;
    return undef unless @sets;

    my %merged;
    for my $terms (@sets) {
        next unless ref($terms) eq 'HASH';
        return { __unsat => 1 } if $terms->{__unsat};
        for my $signal (sort keys %$terms) {
            next if $signal eq '__unsat';
            if (exists($merged{$signal})) {
                return { __unsat => 1 }
                    if $signal =~ /\Aeq:/ && $merged{$signal} ne $terms->{$signal};
                return { __unsat => 1 }
                    if $signal !~ /\Aeq:/ && $merged{$signal} != $terms->{$signal};
            }
            $merged{$signal} = $terms->{$signal};
        }
    }

    return \%merged;
}

sub _condition_literal_terms {
    my ($condition) = @_;
    return {} unless defined($condition);

    if (!ref($condition)) {
        return {} if $condition eq '1';
        return { $1 => 0 } if $condition =~ /\A!([A-Za-z_]\w*)\z/;
        return { "eq:$1" => _condition_term_value($3) }
            if $condition =~ /\A([A-Za-z_]\w*(?:\[[^\]]+\])?)(==|=)(.+)\z/
                && defined(_condition_term_value($3));
        return { $condition => 1 } if _is_condition_signal_term($condition);
        return undef;
    }

    return undef unless ref($condition) eq 'ARRAY' && @$condition;
    my $head = $condition->[0];
    return undef unless defined($head) && !ref($head);

    if ($head eq '&') {
        my %merged;
        for my $operand (@{$condition}[1 .. $#$condition]) {
            my $terms = _condition_literal_terms($operand);
            next unless defined $terms;
            return { __unsat => 1 } if $terms->{__unsat};
            for my $signal (sort keys %$terms) {
                next if $signal eq '__unsat';
                if (exists($merged{$signal})) {
                    return { __unsat => 1 }
                        if $signal =~ /\Aeq:/ && $merged{$signal} ne $terms->{$signal};
                    return { __unsat => 1 }
                        if $signal !~ /\Aeq:/ && $merged{$signal} != $terms->{$signal};
                }
                $merged{$signal} = $terms->{$signal};
            }
        }
        return \%merged;
    }

    if (($head eq '==' || $head eq '=') && @$condition == 3) {
        my ($signal, $value) = @{$condition}[1, 2];
        return undef unless defined($signal) && !ref($signal) && _is_condition_signal_term($signal);
        my $term_value = _condition_term_value($value);
        return undef unless defined $term_value;
        return { "eq:$signal" => $term_value };
    }

    if (($head eq '!' || $head eq '~') && @$condition == 2) {
        my $operand = $condition->[1];
        return { $operand => 0 }
            if defined($operand) && !ref($operand) && _is_condition_signal_term($operand);
        if (ref($operand) eq 'ARRAY'
            && @$operand == 2
            && defined($operand->[0])
            && !ref($operand->[0])
            && ($operand->[0] eq '!' || $operand->[0] eq '~')
            && defined($operand->[1])
            && !ref($operand->[1])
            && _is_condition_signal_term($operand->[1])) {
            return { $operand->[1] => 1 };
        }
        return undef;
    }

    return undef;
}

sub _condition_term_value {
    my ($value) = @_;
    return undef unless defined($value) && !ref($value);
    $value =~ s/\A\s+|\s+\z//g;
    return undef unless _is_numeric_or_exact_width_literal($value);
    return $value;
}

sub _is_condition_signal_term {
    my ($term) = @_;
    return defined($term)
        && !ref($term)
        && $term =~ /\A[A-Za-z_]\w*(?:\[[^\]]+\])?\z/;
}

sub _condition_terms_prove_disjoint {
    my ($left, $right) = @_;
    my $left_terms = $left->{condition_terms};
    my $right_terms = $right->{condition_terms};

    return 0 unless ref($left_terms) eq 'HASH' && ref($right_terms) eq 'HASH';
    return 1 if $left_terms->{__unsat} || $right_terms->{__unsat};

    for my $signal (sort keys %$left_terms) {
        next if $signal eq '__unsat';
        next unless exists $right_terms->{$signal};
        return 1 if $signal =~ /\Aeq:/ && $left_terms->{$signal} ne $right_terms->{$signal};
        return 1 if $signal !~ /\Aeq:/ && $left_terms->{$signal} != $right_terms->{$signal};
    }

    return 0;
}

sub _negated_condition_expr {
    my ($condition) = @_;
    $condition = '1' unless defined($condition) && length($condition);
    return "(! $condition)";
}

sub _priority_conflict_issue {
    my (%args) = @_;
    return {
        code         => $args{code},
        severity     => 'error',
        proof_status => $args{proof_status},
        target       => $args{target},
        domain       => 'data',
        reason       => $args{reason},
        sources      => [
            _priority_source_summary($args{left}),
            _priority_source_summary($args{right}),
        ],
    };
}

sub _priority_source_summary {
    my ($record) = @_;
    return {
        owner            => _priority_record_owner($record),
        owner_kind       => $record->{owner_kind} // 'rule',
        source_kind      => $record->{source_kind} // 'rule_action',
        target           => $record->{target},
        operator         => $record->{operator},
        rhs              => $record->{rhs},
        domain           => 'data',
        assignment_index => $record->{assignment_index},
    };
}

sub _finalize_ir {
    my ($ir) = @_;
    $ir->{priority_resolution} ||= { resolutions => [], issues => [] };
    $ir->{assignment_provenance} = _build_assignment_provenance($ir);
    $ir->{compatible_fanin_groups} = _build_compatible_fanin_groups($ir->{assignment_provenance});
    $ir->{conflict_issues} = [
        @{$ir->{priority_resolution}{issues} || []},
        @{_build_conflict_issues($ir->{assignment_provenance})},
    ];
    _confess_conflict_issues($ir->{conflict_issues});
    return $ir;
}

sub _build_assignment_provenance {
    my ($ir) = @_;
    my @records;

    for my $state (@{$ir->{states} || []}) {
        my $assignment_index = 0;
        for my $assignment (@{$state->{assignments} || []}) {
            push @records, _state_assignment_provenance($state, $assignment, $assignment_index++);
        }
    }

    for my $dt (@{$ir->{dt_blocks} || []}) {
        my $assignment_index = 0;
        for my $assignment (@{$dt->{assignments} || []}) {
            push @records, _dt_assignment_provenance($dt, $assignment, $assignment_index++);
        }
    }

    return \@records;
}

sub _state_assignment_provenance {
    my ($state, $assignment, $assignment_index) = @_;
    my $owner = _transaction_owner_from_state_name($state->{name});
    my $source_kind = _state_assignment_source_kind($state, $assignment);

    return {
        owner            => $owner // $state->{name},
        owner_kind       => defined($owner) ? 'transaction' : 'generated',
        source_kind      => $source_kind,
        target           => $assignment->{lhs},
        operator         => $assignment->{op},
        rhs              => $assignment->{rhs},
        domain           => _assignment_domain_hint($assignment, $source_kind),
        condition_terms   => _guard_literal_terms($assignment->{guard}),
        assignment_index => $assignment_index,
        priority_suppressed_by => _assignment_priority_suppressed_by($assignment),
        resource_suppressed_by => _assignment_resource_suppressed_by($assignment),
        activation       => {
            container_kind   => 'state',
            container_name   => $state->{name},
            state_kind       => $state->{kind},
            state_guard      => _clone_provenance_value($state->{guard}),
            assignment_guard => _clone_provenance_value($assignment->{guard}),
        },
    };
}

sub _dt_assignment_provenance {
    my ($dt, $assignment, $assignment_index) = @_;
    my $source_kind = _dt_assignment_source_kind($dt, $assignment);

    return {
        owner            => _dt_assignment_owner($dt),
        owner_kind       => _dt_assignment_owner_kind($dt),
        source_kind      => $source_kind,
        target           => $assignment->{lhs},
        operator         => $assignment->{op},
        rhs              => $assignment->{rhs},
        domain           => _assignment_domain_hint($assignment, $source_kind),
        condition_terms   => _merge_literal_term_sets(
            (($dt->{kind} // '') eq 'rule' ? $dt->{dte_guard_terms} : _guard_literal_terms($dt->{dte_guard})),
            _guard_literal_terms($assignment->{guard}),
        ),
        assignment_index => $assignment_index,
        priority_suppressed_by => _assignment_priority_suppressed_by($assignment),
        resource_suppressed_by => _assignment_resource_suppressed_by($assignment),
        activation       => {
            container_kind   => 'dt',
            container_name   => $dt->{name},
            dt_kind          => $dt->{kind},
            dte_guard        => _clone_provenance_value($dt->{dte_guard}),
            assignment_guard => _clone_provenance_value($assignment->{guard}),
        },
    };
}

sub _transaction_owner_from_state_name {
    my ($name) = @_;
    return undef unless defined $name;
    return $1 if $name =~ /^(.+)_(?:idle|drive|await|done|repeat|sample|max_chk|when|switch|update|set|shift|asm|ext|extract|store|load|do|spawn|phase|stage|contract|wait|while|until)_/;
    return $1 if $name =~ /^(.+)_timeout$/;
    return undef;
}

sub _state_assignment_source_kind {
    my ($state, $assignment) = @_;
    return $assignment->{source_kind} if defined $assignment->{source_kind};

    my $name = $state->{name} // '';
    my $kind = $state->{kind} // '';
    my $target = $assignment->{lhs} // '';
    my $op = $assignment->{op} // '';

    return 'scheduler_can_accept' if $target eq 'can_accept';
    return 'drive_call_start' if $name =~ /_drive_/ && $target =~ /_start\z/ && $op eq '=';
    return 'drive_call_param' if $name =~ /_drive_/ && $op eq '=';
    return 'do_start' if $name =~ /_do_/ && $target =~ /_start\z/;
    return 'spawn_start' if $name =~ /_spawn_/ && $target =~ /_start\z/;
    return 'timeout_pulse' if $name =~ /_timeout\z/ && $op =~ /^<[0-9]+$/;
    return 'timeout_status' if $name =~ /_timeout\z/;
    return 'complete_pulse' if $kind eq 'terminal' && $op =~ /^<[0-9]+$/;
    return 'sample_capture' if $name =~ /_(?:idle|sample)_/ && $op eq '<=';
    return 'extract_capture' if $name =~ /_ext_/ && $op eq '<=';
    return 'latency_counter_init' if $target =~ /_cc\z/ && $op eq '<-';
    return 'latency_increment_request' if $target =~ /_inc\z/ && $op eq '=';
    return 'latency_error' if $target =~ /_lerr\z/;
    return 'repeat_counter' if $name =~ /_repeat_/;
    return 'update' if $name =~ /_update_/;
    return 'set' if $name =~ /_set_/;
    return 'shift' if $name =~ /_shift_/;
    return 'assemble' if $name =~ /_asm_/;
    return 'inline_drive' if $name =~ /_drive_/;
    return 'state_assignment';
}

sub _dt_assignment_source_kind {
    my ($dt, $assignment) = @_;
    return $assignment->{source_kind} if defined $assignment->{source_kind};

    my $kind = $dt->{kind} // '';
    my $target = $assignment->{lhs} // '';
    my $op = $assignment->{op} // '';

    return 'rule_trigger_source'
        if $kind eq 'rule' && $op =~ /^<[0-9]+$/ && $target =~ /^\Q$dt->{name}\E_/;
    return 'rule_action' if $kind eq 'rule';
    return 'rule_trigger_fanin' if $kind eq 'rule_trigger_fanin';
    return 'drive_body' if $kind eq 'drive';
    return 'latency_counter' if $kind eq 'latency_counter';
    return 'contract_monitor' if $kind eq 'temporal_contract_monitor';
    return 'dt_assignment';
}

sub _dt_assignment_owner {
    my ($dt) = @_;
    return $dt->{owner} if defined($dt->{owner}) && length($dt->{owner});
    return $1 if ($dt->{kind} // '') eq 'rule_trigger_fanin' && ($dt->{name} // '') =~ /^(.+)_trigger_fanin\z/;
    return $dt->{name};
}

sub _dt_assignment_owner_kind {
    my ($dt) = @_;
    return $dt->{owner_kind} if defined($dt->{owner_kind}) && length($dt->{owner_kind});
    my $kind = $dt->{kind} // '';
    return 'rule' if $kind eq 'rule';
    return 'drive' if $kind eq 'drive';
    return 'transaction' if $kind eq 'rule_trigger_fanin';
    return 'generated';
}

sub _assignment_domain_hint {
    my ($assignment, $source_kind) = @_;
    my $target = $assignment->{lhs} // '';
    my $op = $assignment->{op} // '';
    my $rhs = defined($assignment->{rhs}) ? "$assignment->{rhs}" : '';

    return 'request' if $source_kind =~ /(?:_start|_fanin)\z/ && $rhs eq '1';
    return 'request' if $target =~ /_start\z/ && $op eq '=' && $rhs eq '1';
    return 'request' if $source_kind eq 'rule_trigger_fanin';
    return 'pulse' if $op =~ /^<[0-9]+$/ && $rhs eq '1';
    return 'capture' if $source_kind =~ /(?:sample|extract)_capture/;
    return 'helper' if $source_kind =~ /^(?:scheduler_|latency_|repeat_|timeout_status|contract_)/;
    return 'data';
}

sub _clone_provenance_value {
    my ($value) = @_;
    return undef unless defined $value;
    if (ref($value) eq 'HASH') {
        my %copy;
        for my $key (sort keys %$value) {
            $copy{$key} = _clone_provenance_value($value->{$key});
        }
        return \%copy;
    }
    if (ref($value) eq 'ARRAY') {
        return [ map { _clone_provenance_value($_) } @$value ];
    }
    return $value;
}

sub _assignment_priority_suppressed_by {
    my ($assignment) = @_;
    return [] unless ref($assignment->{priority_suppressed_by}) eq 'ARRAY';
    return [ @{$assignment->{priority_suppressed_by}} ];
}

sub _assignment_resource_suppressed_by {
    my ($assignment) = @_;
    return [] unless ref($assignment->{resource_suppressed_by}) eq 'ARRAY';
    return [ @{$assignment->{resource_suppressed_by}} ];
}

sub _build_compatible_fanin_groups {
    my ($records) = @_;
    my @groups;

    push @groups, _same_target_value_groups($records);
    push @groups, _domain_fanin_groups($records, 'request');
    push @groups, _domain_fanin_groups($records, 'pulse');
    push @groups, _rule_trigger_fanin_groups($records);

    return \@groups;
}

sub _same_target_value_groups {
    my ($records) = @_;
    return _group_compatible_records(
        $records,
        sub {
            my ($record) = @_;
            return undef if ($record->{domain} // '') eq 'helper';
            return _group_key(
                'same_target_value',
                $record->{domain},
                $record->{target},
                $record->{operator},
                _record_rhs($record),
            );
        },
        sub {
            my ($key, $members) = @_;
            return {
                kind     => 'same_target_value',
                domain   => $members->[0]{domain},
                target   => $members->[0]{target},
                operator => $members->[0]{operator},
                rhs      => _record_rhs($members->[0]),
                sources  => [ map { _fanin_source_summary($_) } @$members ],
            };
        },
    );
}

sub _domain_fanin_groups {
    my ($records, $domain) = @_;
    return _group_compatible_records(
        $records,
        sub {
            my ($record) = @_;
            return undef unless ($record->{domain} // '') eq $domain;
            return undef if $domain eq 'pulse' && !_is_one_cycle_pulse_record($record);
            return _group_key($domain, $record->{target});
        },
        sub {
            my ($key, $members) = @_;
            my $group = {
                kind    => $domain,
                domain  => $domain,
                target  => $members->[0]{target},
                sources => [ map { _fanin_source_summary($_) } @$members ],
            };
            if ($domain eq 'pulse') {
                $group->{operator} = $members->[0]{operator};
                $group->{rhs} = _record_rhs($members->[0]);
            }
            return $group;
        },
    );
}

sub _rule_trigger_fanin_groups {
    my ($records) = @_;
    return _group_compatible_records(
        $records,
        sub {
            my ($record) = @_;
            return undef unless ($record->{source_kind} // '') eq 'rule_trigger_source';
            my $target = _rule_trigger_target_transaction($record);
            return undef unless defined $target && length $target;
            return _group_key('rule_trigger_fanin', $target);
        },
        sub {
            my ($key, $members) = @_;
            my $target = _rule_trigger_target_transaction($members->[0]);
            return {
                kind               => 'rule_trigger_fanin',
                domain             => 'request',
                target_transaction => $target,
                fanin_target       => "${target}_start",
                sources            => [ map { _fanin_source_summary($_) } @$members ],
            };
        },
    );
}

sub _group_compatible_records {
    my ($records, $key_for, $group_builder) = @_;
    my %by_key;
    my @order;

    for my $record (@$records) {
        my $key = $key_for->($record);
        next unless defined $key;
        push @order, $key unless exists $by_key{$key};
        push @{$by_key{$key}}, $record;
    }

    my @groups;
    for my $key (@order) {
        my $members = $by_key{$key};
        next unless @$members > 1;
        push @groups, $group_builder->($key, $members);
    }

    return @groups;
}

sub _group_key {
    return join "\0", map { defined($_) ? $_ : '' } @_;
}

sub _record_rhs {
    my ($record) = @_;
    return defined($record->{rhs}) ? "$record->{rhs}" : '';
}

sub _is_one_cycle_pulse_record {
    my ($record) = @_;
    return ($record->{operator} // '') =~ /^<[0-9]+$/ && _record_rhs($record) eq '1';
}

sub _rule_trigger_target_transaction {
    my ($record) = @_;
    my $owner = $record->{owner};
    my $target = $record->{target};
    return undef unless defined($owner) && defined($target);
    my $prefix = "${owner}_";
    return undef unless index($target, $prefix) == 0;
    return substr($target, length($prefix));
}

sub _fanin_source_summary {
    my ($record) = @_;
    return {
        owner            => $record->{owner},
        owner_kind       => $record->{owner_kind},
        source_kind      => $record->{source_kind},
        target           => $record->{target},
        operator         => $record->{operator},
        rhs              => $record->{rhs},
        domain           => $record->{domain},
        activation       => _clone_provenance_value($record->{activation}),
        assignment_index => $record->{assignment_index},
        priority_suppressed_by => _clone_provenance_value($record->{priority_suppressed_by}),
    };
}

sub _build_conflict_issues {
    my ($records) = @_;
    my @issues;
    my @data_records = grep { ($_->{domain} // '') eq 'data' && defined $_->{target} } @$records;

    for my $left_idx (0 .. $#data_records) {
        my $left = $data_records[$left_idx];
        for my $right_idx ($left_idx + 1 .. $#data_records) {
            my $right = $data_records[$right_idx];
            next unless ($left->{target} // '') eq ($right->{target} // '');
            next if _compatible_record_pair($left, $right);
            next if _condition_terms_prove_disjoint($left, $right);
            next if _priority_resolved_record_pair($left, $right);
            next if _resource_resolved_record_pair($left, $right);

            if (_both_owner_kind($left, $right, 'rule')) {
                push @issues, _conflict_issue(
                    code         => 'isf_conflicting_rule_writes',
                    severity     => 'error',
                    proof_status => 'proved_conflict',
                    target       => $left->{target},
                    reason       => 'overlapping rule data writes select different values',
                    left         => $left,
                    right        => $right,
                );
                next;
            }

            if (_owner_kind_pair($left, $right, 'rule', 'drive')) {
                push @issues, _conflict_issue(
                    code         => 'isf_unproven_rule_drive_overlap',
                    severity     => 'warning',
                    proof_status => 'not_doable',
                    target       => $left->{target},
                    reason       => 'compile-time proof for rule/drive overlap is not doable yet',
                    left         => $left,
                    right        => $right,
                );
            }
        }
    }

    return \@issues;
}

sub _compatible_record_pair {
    my ($left, $right) = @_;
    return 0 unless ($left->{target} // '') eq ($right->{target} // '');

    if (($left->{domain} // '') eq ($right->{domain} // '')
        && ($left->{domain} // '') ne 'helper'
        && ($left->{operator} // '') eq ($right->{operator} // '')
        && _record_rhs($left) eq _record_rhs($right)) {
        return 1;
    }

    return 1 if ($left->{domain} // '') eq 'request' && ($right->{domain} // '') eq 'request';
    return 1 if ($left->{domain} // '') eq 'pulse'
        && ($right->{domain} // '') eq 'pulse'
        && _is_one_cycle_pulse_record($left)
        && _is_one_cycle_pulse_record($right);

    return 0;
}

sub _priority_resolved_record_pair {
    my ($left, $right) = @_;
    return 0 unless _priority_resolvable_owner_pair($left, $right);
    return 1 if _record_priority_suppressed_by($left, $right->{owner});
    return 1 if _record_priority_suppressed_by($right, $left->{owner});
    return 0;
}

sub _priority_resolvable_owner_pair {
    my ($left, $right) = @_;
    my %allowed = map { $_ => 1 } qw(rule transaction);
    return $allowed{$left->{owner_kind} // ''} && $allowed{$right->{owner_kind} // ''};
}

sub _resource_resolved_record_pair {
    my ($left, $right) = @_;
    return 0 unless _both_owner_kind($left, $right, 'rule');
    return 1 if _record_resource_suppressed_by($left, $right->{owner});
    return 1 if _record_resource_suppressed_by($right, $left->{owner});
    return 0;
}

sub _record_priority_suppressed_by {
    my ($record, $owner) = @_;
    return 0 unless defined($owner);
    my $suppressed_by = $record->{priority_suppressed_by};
    return 0 unless ref($suppressed_by) eq 'ARRAY';
    for my $higher (@$suppressed_by) {
        return 1 if defined($higher) && $higher eq $owner;
    }
    return 0;
}

sub _record_resource_suppressed_by {
    my ($record, $owner) = @_;
    return 0 unless defined($owner);
    my $suppressed_by = $record->{resource_suppressed_by};
    return 0 unless ref($suppressed_by) eq 'ARRAY';
    for my $higher (@$suppressed_by) {
        return 1 if defined($higher) && $higher eq $owner;
    }
    return 0;
}

sub _both_owner_kind {
    my ($left, $right, $kind) = @_;
    return ($left->{owner_kind} // '') eq $kind && ($right->{owner_kind} // '') eq $kind;
}

sub _owner_kind_pair {
    my ($left, $right, $first, $second) = @_;
    my $left_kind = $left->{owner_kind} // '';
    my $right_kind = $right->{owner_kind} // '';
    return 1 if $left_kind eq $first && $right_kind eq $second;
    return 1 if $left_kind eq $second && $right_kind eq $first;
    return 0;
}

sub _conflict_issue {
    my (%args) = @_;
    return {
        code         => $args{code},
        severity     => $args{severity},
        proof_status => $args{proof_status},
        target       => $args{target},
        domain       => 'data',
        reason       => $args{reason},
        sources      => [
            _fanin_source_summary($args{left}),
            _fanin_source_summary($args{right}),
        ],
    };
}

sub _confess_conflict_issues {
    my ($issues) = @_;
    for my $issue (@$issues) {
        next unless ($issue->{severity} // '') eq 'error';
        confess _format_conflict_issue($issue) . "\n";
    }
}

sub _format_conflict_issue {
    my ($issue) = @_;
    my ($left, $right) = @{$issue->{sources}};
    return "ISF conflict '$issue->{code}' on target '$issue->{target}': "
        . "$issue->{reason}; "
        . _format_conflict_source($left)
        . ' conflicts with '
        . _format_conflict_source($right);
}

sub _format_conflict_source {
    my ($source) = @_;
    my $rhs = defined($source->{rhs}) ? $source->{rhs} : '';
    return "$source->{owner_kind} '$source->{owner}' "
        . "($source->{source_kind}, $source->{operator} $rhs)";
}

# --- Post-processing ---
sub _link_states {
    my ($st,$tn)=@_;
    return unless @$st;

    my $e = $st->[0]{name};
    my %idx_by_name = map { $st->[$_]{name} => $_ } 0 .. $#$st;
    my %branch_exit_target;

    for my $i (0 .. $#$st) {
        my $s = $st->[$i];
        next unless $s->{kind} eq 'switch';

        my $last_branch_idx = $i;
        for my $name (@{$s->{branch_state_names} || []}) {
            next unless defined $idx_by_name{$name};
            $last_branch_idx = $idx_by_name{$name} if $idx_by_name{$name} > $last_branch_idx;
        }

        my $exit_target = $last_branch_idx < $#$st ? $st->[$last_branch_idx + 1]{name} : $e;
        $s->{switch_exit_target} = $exit_target;
        for my $name (@{$s->{branch_end_names} || []}) {
            $branch_exit_target{$name} = $exit_target;
        }
    }

    for my $i (0 .. $#$st) {
        my $s = $st->[$i];
        next unless $s->{kind} eq 'branch';

        my $last_branch_idx = $i;
        for my $name (@{$s->{branch_state_names} || []}) {
            next unless defined $idx_by_name{$name};
            $last_branch_idx = $idx_by_name{$name} if $idx_by_name{$name} > $last_branch_idx;
        }

        my $exit_target = $last_branch_idx < $#$st ? $st->[$last_branch_idx + 1]{name} : $e;
        if ($last_branch_idx > $i) {
            my $body_tail = $st->[$last_branch_idx]{name};
            $exit_target = $branch_exit_target{$body_tail} if $branch_exit_target{$body_tail};
        } elsif ($branch_exit_target{$s->{name}}) {
            $exit_target = $branch_exit_target{$s->{name}};
        }
        $s->{branch_exit_target} = $exit_target;
    }

    for my $i (0 .. $#$st) {
        my $s = $st->[$i];
        next unless ($s->{kind} eq 'loop_while' || $s->{kind} eq 'loop_until') && $s->{loop_entry};

        my $last_loop_idx = $i;
        for my $name (
            @{$s->{loop_body_state_names} || []},
            @{$s->{loop_decision_state_names} || []},
        ) {
            next unless defined $idx_by_name{$name};
            $last_loop_idx = $idx_by_name{$name} if $idx_by_name{$name} > $last_loop_idx;
        }

        my $exit_target = $last_loop_idx < $#$st ? $st->[$last_loop_idx + 1]{name} : $e;
        for my $name (@{$s->{loop_decision_state_names} || []}) {
            next unless defined $idx_by_name{$name};
            $st->[$idx_by_name{$name}]{loop_exit_target} = $exit_target;
            $st->[$idx_by_name{$name}]{loop_body_start} = $s->{loop_body_start};
        }
        $s->{loop_exit_target} = $exit_target;
    }

    for my $i (0 .. $#$st) {
        my $s = $st->[$i];
        next unless $s->{dynamic_wait_entry};

        my $last_idx = _state_region_last_index(\%idx_by_name, $s->{wait_state_names}, $i);
        my $exit_idx = $last_idx + 1;
        my $exit_target = $exit_idx <= $#$st ? $st->[$exit_idx]{name} : $e;
        $s->{dynamic_wait_next_wait_state} = $st->[$exit_idx]
            if $exit_idx <= $#$st && $st->[$exit_idx]{dynamic_wait_entry};
        $s->{dynamic_wait_exit_target} = $exit_target;
        if (defined($s->{dynamic_wait_loop_state})) {
            my $loop_state = _state_by_name(\%idx_by_name, $st, $s->{dynamic_wait_loop_state});
            if ($loop_state) {
                $loop_state->{dynamic_wait_next_wait_state} = $s->{dynamic_wait_next_wait_state};
                $loop_state->{dynamic_wait_exit_target} = $exit_target;
            }
        }
    }

    for my $i(0..$#$st){my $s=$st->[$i];my $n=$i<$#$st?$st->[$i+1]{name}:undef;my $next=$branch_exit_target{$s->{name}}||$n;
        my $next_state = $i < $#$st ? $st->[$i + 1] : undef;
        if($s->{dynamic_wait_entry}){_link_dynamic_wait_state($s)}
        elsif($s->{dynamic_wait_loop_for}){_link_dynamic_wait_loop_state($s)}
        elsif($s->{kind}eq'switch'){_link_switch_state($s,\%idx_by_name,$st,$n,$e)}
        elsif($s->{kind}eq'loop_while'||$s->{kind}eq'loop_until'){_link_loop_state($s,\%idx_by_name,$st)}
        elsif($next_state&&$next_state->{dynamic_wait_entry}){_link_dynamic_wait_predecessor($tn,$s,$next_state)}
        elsif($s->{kind}eq'entry'&&$n){push @{$s->{transitions}},{target=>$n,condition=>$s->{guard}}}
        elsif($s->{kind}eq'await'&&$next){push @{$s->{transitions}},{target=>$next,condition=>$s->{guard}};push @{$s->{transitions}},{target=>"${tn}_timeout",condition=>{signal=>$s->{watchdog}{name},op=>'=',value=>0}}}
        elsif($s->{kind}eq'stage'&&$next){push @{$s->{transitions}},{target=>$next,condition=>{port=>$s->{ready}}}}
        elsif($s->{kind}eq'repeat_check'){push @{$s->{transitions}},{target=>$s->{loop_target},condition=>{signal=>$s->{counter},op=>'!=',value=>0}};push @{$s->{transitions}},{target=>$next,condition=>{signal=>$s->{counter},op=>'=',value=>0}}if$next}
        elsif(($s->{kind}eq'sequential'||$s->{kind}eq'contract'||$s->{kind}eq'wait'||$s->{kind}eq'bank_store'||$s->{kind}eq'bank_load')&&$next){push @{$s->{transitions}},{target=>$next}}
        elsif($s->{kind}eq'branch'){my$skip=$s->{branch_exit_target}||$n||$e;push @{$s->{transitions}},{target=>$skip}}
        elsif($s->{kind}eq'sync_all'&&$next){push @{$s->{transitions}},{target=>$next}}
        elsif($s->{kind}eq'sync_any'&&$next){push @{$s->{transitions}},{target=>$next}}
        elsif($s->{kind}eq'terminal'){push @{$s->{transitions}},{target=>$e}}}

    _append_dynamic_wait_zero_sample_clones($st,\%idx_by_name);
}

sub _state_region_last_index {
    my ($idx_by_name, $state_names, $fallback_idx) = @_;
    my $last_idx = $fallback_idx;
    for my $name (@{$state_names || []}) {
        next unless defined $name;
        next unless exists $idx_by_name->{$name};
        $last_idx = $idx_by_name->{$name}
            if $idx_by_name->{$name} > $last_idx;
    }
    return $last_idx;
}

sub _link_switch_state {
    my ($state, $idx_by_name, $states, $next_target, $entry_target) = @_;
    my $skip = $state->{switch_exit_target} || $next_target || $entry_target;
    my @explicit_conditions;
    my $has_dynamic_branch;

    for my $branch (@{$state->{branches} || []}) {
        next if _is_default_switch_value($branch->{value});
        push @explicit_conditions, _switch_value_condition_expr($state->{signal}, $branch->{value});
    }

    for my $branch (@{$state->{branches} || []}) {
        my $body = _state_by_name($idx_by_name, $states, $branch->{body_start});
        if ($body && $body->{dynamic_wait_entry}) {
            $has_dynamic_branch = 1;
            last;
        }
    }

    if (!$has_dynamic_branch) {
        push @{$state->{transitions}}, { target => $skip }
            unless $state->{has_default_branch};
        for my $branch (@{$state->{branches} || []}) {
            next if _is_default_switch_value($branch->{value});
            push @{$state->{transitions}}, {
                target    => $branch->{body_start},
                condition => {
                    signal => $state->{signal},
                    value  => $branch->{value},
                },
            };
        }
        return;
    }

    my $default_condition = _switch_default_condition_expr(\@explicit_conditions);
    $state->{switch_transitions_materialized} = 1;

    for my $branch (@{$state->{branches} || []}) {
        my $body = _state_by_name($idx_by_name, $states, $branch->{body_start});
        my $condition = _is_default_switch_value($branch->{value})
            ? $default_condition
            : _switch_value_condition_expr($state->{signal}, $branch->{value});

        if ($body && $body->{dynamic_wait_entry}) {
            _link_dynamic_wait_entry_edge($state, $body, $condition);
        } elsif (_is_default_switch_value($branch->{value})) {
            push @{$state->{transitions}}, {
                target    => $branch->{body_start},
                condition => { expr => $condition },
            };
        } else {
            push @{$state->{transitions}}, {
                target    => $branch->{body_start},
                condition => {
                    signal => $state->{signal},
                    value  => $branch->{value},
                },
            };
        }
    }

    if (!$state->{has_default_branch}) {
        push @{$state->{transitions}}, {
            target    => $skip,
            condition => { expr => $default_condition },
        };
    }
}

sub _state_by_name {
    my ($idx_by_name, $states, $name) = @_;
    return undef unless defined $name;
    return undef unless ref($idx_by_name) eq 'HASH' && exists $idx_by_name->{$name};
    return $states->[$idx_by_name->{$name}];
}

sub _switch_value_condition_expr {
    my ($signal, $value) = @_;
    return "(== $signal $value)";
}

sub _switch_default_condition_expr {
    my ($explicit_conditions) = @_;
    my @conditions = grep { defined($_) && length($_) } @{$explicit_conditions || []};
    return '1' unless @conditions;
    return _negated_condition_expr($conditions[0]) if @conditions == 1;
    return _negated_condition_expr('(| ' . join(' ', @conditions) . ')');
}

sub _link_loop_state {
    my ($state, $idx_by_name, $states) = @_;
    my $condition = _loop_condition_expr($state);
    my @edges;

    if (($state->{kind} // '') eq 'loop_while') {
        @edges = (
            {
                branch    => 1,
                target    => $state->{loop_body_start},
                condition => $condition,
            },
            {
                branch    => 0,
                target    => $state->{loop_exit_target},
                condition => _negated_condition_expr($condition),
            },
        );
    } else {
        @edges = (
            {
                branch    => 1,
                target    => $state->{loop_exit_target},
                condition => $condition,
            },
            {
                branch    => 0,
                target    => $state->{loop_body_start},
                condition => _negated_condition_expr($condition),
            },
        );
    }

    my $materialize = 0;
    for my $edge (@edges) {
        my $target_state = _state_by_name($idx_by_name, $states, $edge->{target});
        if ($target_state && $target_state->{dynamic_wait_entry}) {
            $materialize = 1;
            last;
        }
    }

    if (!$materialize) {
        for my $edge (@edges) {
            next unless $edge->{target};
            push @{$state->{transitions}}, {
                target    => $edge->{target},
                condition => { loop_branch => $edge->{branch} },
            };
        }
        return;
    }

    $state->{loop_transitions_materialized} = 1;
    for my $edge (@edges) {
        next unless $edge->{target};
        my $target_state = _state_by_name($idx_by_name, $states, $edge->{target});
        if ($target_state && $target_state->{dynamic_wait_entry}) {
            _link_dynamic_wait_entry_edge($state, $target_state, $edge->{condition});
        } else {
            push @{$state->{transitions}}, {
                target    => $edge->{target},
                condition => { expr => $edge->{condition} },
            };
        }
    }
}

sub _loop_condition_expr {
    my ($state) = @_;
    my $condition = $state->{condition};
    return !ref($condition) ? $condition : _format_isf_expr($condition);
}

sub _link_dynamic_wait_state {
    my ($state) = @_;
    my $counter = $state->{wait_counter};
    my $exit_target = $state->{dynamic_wait_exit_target};
    my $width = $state->{wait_counter_width} // 1;

    confess "Runtime dynamic wait state '$state->{name}' has no sampled counter\n"
        unless defined($counter) && length($counter);
    confess "Runtime dynamic wait state '$state->{name}' has no exit target\n"
        unless defined($exit_target) && length($exit_target);

    my $final_cycle_condition = "(== $counter 1)";
    my $next_dynamic_wait = $state->{dynamic_wait_next_wait_state};
    if ($next_dynamic_wait) {
        _link_dynamic_wait_entry_edge(
            $state,
            $next_dynamic_wait,
            $final_cycle_condition,
        );
    } else {
        push @{$state->{transitions}}, {
            target    => $exit_target,
            condition => { signal => $counter, op => '=', value => 1 },
        };
    }
    my $loop_target = $state->{dynamic_wait_loop_state} // $state->{name};
    push @{$state->{transitions}}, {
        target    => $loop_target,
        condition => { signal => $counter, op => '>', value => 1 },
    } if $width > 1;
}

sub _link_dynamic_wait_loop_state {
    my ($state) = @_;
    my $counter = $state->{wait_counter};
    my $exit_target = $state->{dynamic_wait_exit_target};
    my $width = $state->{wait_counter_width} // 1;

    confess "Runtime dynamic wait loop state '$state->{name}' has no sampled counter\n"
        unless defined($counter) && length($counter);
    confess "Runtime dynamic wait loop state '$state->{name}' has no exit target\n"
        unless defined($exit_target) && length($exit_target);

    my $final_cycle_condition = "(== $counter 1)";
    my $next_dynamic_wait = $state->{dynamic_wait_next_wait_state};
    if ($next_dynamic_wait) {
        _link_dynamic_wait_entry_edge(
            $state,
            $next_dynamic_wait,
            $final_cycle_condition,
        );
    } else {
        push @{$state->{transitions}}, {
            target    => $exit_target,
            condition => { signal => $counter, op => '=', value => 1 },
        };
    }
    push @{$state->{transitions}}, {
        target    => $state->{name},
        condition => { signal => $counter, op => '>', value => 1 },
    } if $width > 1;
}

sub _link_dynamic_wait_predecessor {
    my ($tn, $state, $wait_state) = @_;
    my $kind = $state->{kind} // '';
    my $source = $wait_state->{wait_count_source};

    my $base_condition = _dynamic_wait_predecessor_condition_expr($state);
    confess "Transaction '$tn': runtime dynamic wait count '$source' cannot follow state '$state->{name}' of kind '$kind' in the current dynamic-wait slice\n"
        unless defined $base_condition;

    _preserve_dynamic_wait_predecessor_alternatives($tn, $state);
    _link_dynamic_wait_entry_edge($state, $wait_state, $base_condition);
}

sub _dynamic_wait_predecessor_condition_expr {
    my ($state) = @_;
    my $kind = $state->{kind} // '';

    return _guard_condition_expr($state->{guard}) // '1'
        if $kind eq 'entry';
    return '1'
        if $kind eq 'sequential'
            || $kind eq 'contract'
            || $kind eq 'bank_load'
            || $kind eq 'bank_store'
            || ($kind eq 'wait' && !$state->{dynamic_wait_entry});
    return _guard_condition_expr($state->{guard})
        if $kind eq 'await';
    return $state->{ready}
        if $kind eq 'stage' && defined($state->{ready}) && length($state->{ready});
    return "(== $state->{counter} 0)"
        if $kind eq 'repeat_check' && defined($state->{counter}) && length($state->{counter});
    return _sync_all_condition_expr($state->{done_ports})
        if $kind eq 'sync_all';
    return _sync_any_condition_expr($state->{done_ports})
        if $kind eq 'sync_any';
    return _branch_condition_expr($state)
        if $kind eq 'branch';
    return undef;
}

sub _preserve_dynamic_wait_predecessor_alternatives {
    my ($tn, $state) = @_;
    my $kind = $state->{kind} // '';

    if ($kind eq 'await') {
        push @{$state->{transitions}}, {
            target    => "${tn}_timeout",
            condition => { signal => $state->{watchdog}{name}, op => '=', value => 0 },
        } if $state->{watchdog} && defined($state->{watchdog}{name});
    } elsif ($kind eq 'repeat_check') {
        push @{$state->{transitions}}, {
            target    => $state->{loop_target},
            condition => { signal => $state->{counter}, op => '!=', value => 0 },
        } if defined($state->{loop_target}) && defined($state->{counter});
    } elsif ($kind eq 'branch') {
        my $skip = $state->{branch_exit_target};
        my $condition = _branch_condition_expr($state);
        push @{$state->{transitions}}, {
            target    => $skip,
            condition => { expr => _negated_condition_expr($condition) },
        } if defined($skip) && defined($condition);
    }
}

sub _branch_condition_expr {
    my ($state) = @_;
    return undef unless $state && ref($state) eq 'HASH';
    my $condition = $state->{condition};
    return undef unless defined $condition;
    return !ref($condition) ? $condition : _format_isf_expr($condition);
}

sub _sync_all_condition_expr {
    my ($ports) = @_;
    my @ports = grep { defined($_) && length($_) } @{$ports || []};
    return '1' unless @ports;
    return $ports[0] if @ports == 1;
    return '(& ' . join(' ', @ports) . ')';
}

sub _sync_any_condition_expr {
    my ($ports) = @_;
    my @ports = grep { defined($_) && length($_) } @{$ports || []};
    return '1' unless @ports;
    return $ports[0] if @ports == 1;
    return '(| ' . join(' ', @ports) . ')';
}

sub _link_dynamic_wait_entry_edge {
    my ($state, $wait_state, $base_condition, $carried_sample_wait) = @_;
    my $source = $wait_state->{wait_count_source};
    my $counter = $wait_state->{wait_counter};
    my $enter_target = _dynamic_wait_entry_target($wait_state, $carried_sample_wait);

    my $enter_condition = _combine_condition_exprs($base_condition, $source);
    my $bypass_condition = _combine_condition_exprs($base_condition, "(== $source 0)");

    push @{$state->{assignments}}, {
        lhs         => $counter,
        rhs         => $source,
        op          => '<-',
        guard       => { expr => $enter_condition },
        source_kind => 'dynamic_wait_counter_load',
    };
    push @{$state->{transitions}}, {
        target    => $enter_target,
        condition => { expr => $enter_condition },
    };

    my $next_dynamic_wait = $wait_state->{dynamic_wait_next_wait_state};
    my $sample_source_wait = $carried_sample_wait;
    $sample_source_wait //= $wait_state
        if _dynamic_wait_has_pending_samples($wait_state);

    if ($next_dynamic_wait) {
        _link_dynamic_wait_entry_edge(
            $state,
            $next_dynamic_wait,
            $bypass_condition,
            $sample_source_wait,
        );
    } else {
        my $target = _dynamic_wait_zero_bypass_target($wait_state, $sample_source_wait);
        push @{$state->{transitions}}, {
            target    => $target,
            condition => { expr => $bypass_condition },
        };
    }
}

sub _dynamic_wait_entry_target {
    my ($wait_state, $carried_sample_wait) = @_;
    return $wait_state->{name}
        unless _dynamic_wait_has_pending_samples($carried_sample_wait);
    return $wait_state->{name}
        if ($carried_sample_wait->{name} // '') eq ($wait_state->{name} // '');

    return _dynamic_wait_pending_entry_clone_target($wait_state, $carried_sample_wait);
}

sub _dynamic_wait_pending_entry_clone_target {
    my ($wait_state, $carried_sample_wait) = @_;
    my $source_name = $carried_sample_wait->{name};
    my $clone_name = join('_', $wait_state->{name}, 'sample_from', $source_name);

    $wait_state->{dynamic_wait_pending_entry_clone_requests}{$source_name} //= {
        name                       => $clone_name,
        source_name                => $source_name,
        pending_sample_assignments => [
            map { _clone_assignment($_) } @{$carried_sample_wait->{pending_sample_assignments} || []},
        ],
    };

    return $clone_name;
}

sub _dynamic_wait_zero_bypass_target {
    my ($wait_state, $sample_source_wait) = @_;
    $sample_source_wait //= $wait_state;
    return $wait_state->{dynamic_wait_exit_target}
        unless _dynamic_wait_has_pending_samples($sample_source_wait);

    return _dynamic_wait_carried_zero_sample_clone_target($wait_state, $sample_source_wait)
        if ($sample_source_wait->{name} // '') ne ($wait_state->{name} // '');

    my $clone = $wait_state->{dynamic_wait_zero_sample_clone_name}
        //= "$wait_state->{name}_zero_sample";
    return $clone;
}

sub _dynamic_wait_carried_zero_sample_clone_target {
    my ($wait_state, $sample_source_wait) = @_;
    my $source_name = $sample_source_wait->{name};
    my $clone_name = join('_', $source_name, 'zero_sample_after', $wait_state->{name});

    $wait_state->{dynamic_wait_carried_zero_sample_clone_requests}{$source_name} //= {
        name                       => $clone_name,
        source_name                => $source_name,
        pending_sample_assignments => [
            map { _clone_assignment($_) } @{$sample_source_wait->{pending_sample_assignments} || []},
        ],
    };

    return $clone_name;
}

sub _dynamic_wait_has_pending_samples {
    my ($wait_state) = @_;
    return 0 unless $wait_state && ref($wait_state) eq 'HASH';
    return ref($wait_state->{pending_sample_assignments}) eq 'ARRAY'
        && @{$wait_state->{pending_sample_assignments}};
}

sub _append_dynamic_wait_zero_sample_clones {
    my ($states, $idx_by_name) = @_;
    my @clones;
    my %planned_clone;

    for my $wait_state (@$states) {
        next unless ($wait_state->{dynamic_wait_entry} // 0);
        my $clone_name = $wait_state->{dynamic_wait_zero_sample_clone_name};
        if (_dynamic_wait_has_pending_samples($wait_state) && defined($clone_name) && length($clone_name)) {
            next if exists $idx_by_name->{$clone_name} || $planned_clone{$clone_name}++;

            my $target_name = $wait_state->{dynamic_wait_exit_target};
            my $target_state = _state_by_name($idx_by_name, $states, $target_name);
            confess "Runtime dynamic wait '$wait_state->{name}' cannot build zero-count sample target '$target_name'\n"
                unless $target_state;
            push @clones, _clone_dynamic_wait_zero_sample_target(
                $wait_state,
                $target_state,
                $clone_name,
            );
        }

        for my $source_name (sort keys %{$wait_state->{dynamic_wait_pending_entry_clone_requests} || {}}) {
            my $request = $wait_state->{dynamic_wait_pending_entry_clone_requests}{$source_name};
            my $entry_clone_name = $request->{name};
            next unless defined($entry_clone_name) && length($entry_clone_name);
            next if exists $idx_by_name->{$entry_clone_name} || $planned_clone{$entry_clone_name}++;

            push @clones, _clone_dynamic_wait_pending_entry_target(
                $wait_state,
                $request,
            );
        }

        for my $source_name (sort keys %{$wait_state->{dynamic_wait_carried_zero_sample_clone_requests} || {}}) {
            my $request = $wait_state->{dynamic_wait_carried_zero_sample_clone_requests}{$source_name};
            my $carried_clone_name = $request->{name};
            next unless defined($carried_clone_name) && length($carried_clone_name);
            next if exists $idx_by_name->{$carried_clone_name} || $planned_clone{$carried_clone_name}++;

            my $target_name = $wait_state->{dynamic_wait_exit_target};
            my $target_state = _state_by_name($idx_by_name, $states, $target_name);
            confess "Runtime dynamic wait '$request->{source_name}' cannot build carried zero-count sample target '$target_name'\n"
                unless $target_state;
            my %sample_wait = (
                name                       => $request->{source_name},
                pending_sample_assignments => [
                    map { _clone_assignment($_) } @{$request->{pending_sample_assignments} || []},
                ],
            );
            push @clones, _clone_dynamic_wait_zero_sample_target(
                \%sample_wait,
                $target_state,
                $carried_clone_name,
            );
        }
    }

    for my $clone (@clones) {
        $idx_by_name->{$clone->{name}} = scalar(@$states);
        push @$states, $clone;
    }
}

sub _clone_dynamic_wait_pending_entry_target {
    my ($wait_state, $request) = @_;

    my %clone = %$wait_state;
    $clone{name} = $request->{name};
    $clone{assignments} = [
        map { _clone_assignment($_) } @{$request->{pending_sample_assignments} || []},
        map { _clone_assignment($_) } @{$wait_state->{assignments} || []},
    ];
    $clone{transitions} = [
        map { _clone_transition($_) } @{$wait_state->{transitions} || []},
    ];
    $clone{carried_sample_entry_clone_of} = $wait_state->{name};
    $clone{carried_sample_source_wait} = $request->{source_name};
    delete $clone{wait_entry};
    delete $clone{wait_state_names};
    delete $clone{wait_cycles};
    delete $clone{wait_count_kind};
    delete $clone{wait_count_source};
    delete $clone{wait_counter};
    delete $clone{wait_counter_width};
    delete $clone{dynamic_wait_entry};
    delete $clone{dynamic_wait_loop_for};
    delete $clone{dynamic_wait_loop_state};
    delete $clone{dynamic_wait_exit_target};
    delete $clone{dynamic_wait_next_wait_state};
    delete $clone{dynamic_wait_zero_sample_clone_name};
    delete $clone{dynamic_wait_pending_entry_clone_requests};
    delete $clone{dynamic_wait_carried_zero_sample_clone_requests};
    delete $clone{pending_sample_assignments};
    delete $clone{loop_entry};

    return \%clone;
}

sub _clone_dynamic_wait_zero_sample_target {
    my ($wait_state, $target_state, $clone_name) = @_;

    confess "Runtime dynamic wait '$wait_state->{name}' with pending samples cannot zero-bypass to state '$target_state->{name}' because that state cannot materialize pending samples without changing timing in the current pending-sample slice\n"
        unless _dynamic_wait_zero_sample_target_accepts_samples($wait_state, $target_state);

    my %clone = %$target_state;
    $clone{name} = $clone_name;
    $clone{assignments} = [
        map { _clone_assignment($_) } @{$wait_state->{pending_sample_assignments}},
        map { _clone_assignment($_) } @{$target_state->{assignments} || []},
    ];
    $clone{transitions} = [
        map { _clone_transition($_) } @{$target_state->{transitions} || []},
    ];
    $clone{zero_sample_clone_of} = $target_state->{name};
    delete $clone{wait_entry};
    delete $clone{wait_state_names};
    delete $clone{wait_cycles};
    delete $clone{wait_count_kind};
    delete $clone{wait_count_source};
    delete $clone{wait_counter};
    delete $clone{wait_counter_width};
    delete $clone{dynamic_wait_entry};
    delete $clone{dynamic_wait_loop_for};
    delete $clone{dynamic_wait_loop_state};
    delete $clone{dynamic_wait_exit_target};
    delete $clone{dynamic_wait_next_wait_state};
    delete $clone{dynamic_wait_zero_sample_clone_name};
    delete $clone{dynamic_wait_pending_entry_clone_requests};
    delete $clone{dynamic_wait_carried_zero_sample_clone_requests};
    delete $clone{pending_sample_assignments};
    delete $clone{loop_entry};

    return \%clone;
}

sub _dynamic_wait_zero_sample_target_accepts_samples {
    my ($wait_state, $target_state) = @_;
    my $kind = $target_state->{kind} // '';
    return 0 if $target_state->{dynamic_wait_entry} || $target_state->{dynamic_wait_loop_for};

    return 1 if $kind eq 'wait';
    return 1 if $kind eq 'await'
        && !grep { ($_->{source_kind} // '') =~ /\Ado_/ } @{$target_state->{assignments} || []};
    return 1 if $kind eq 'terminal'
        && @{$target_state->{assignments} || []}
        && !grep { ($_->{source_kind} // '') ne 'complete_pulse' } @{$target_state->{assignments} || []};
    return 1 if $kind eq 'stage'
        && _dynamic_wait_zero_sample_target_is_independent_data_op($wait_state, $target_state, qw(stage_valid latency_increment_request));
    return 1 if $kind eq 'contract'
        && _dynamic_wait_zero_sample_target_is_independent_data_op($wait_state, $target_state, qw(contract_arm_request latency_increment_request));
    return 1 if ($kind eq 'repeat_check' || $kind eq 'loop_while' || $kind eq 'loop_until')
        && _dynamic_wait_zero_sample_target_is_independent_control_state($wait_state, $target_state);
    return 1 if ($kind eq 'sync_all' || $kind eq 'sync_any')
        && _dynamic_wait_zero_sample_target_is_independent_sync_state($wait_state, $target_state);
    return 1 if _dynamic_wait_zero_sample_target_is_phase_marker($target_state);

    if ($kind eq 'sequential') {
        for my $assignment (@{$target_state->{assignments} || []}) {
            my $source_kind = $assignment->{source_kind} // '';
            return 1
                if $source_kind eq 'drive_call_start'
                    || $source_kind eq 'inline_drive'
                    || $source_kind eq 'sample_capture';
        }
        return 1 if _dynamic_wait_zero_sample_target_is_independent_setter($wait_state, $target_state);
        return 1 if _dynamic_wait_zero_sample_target_is_independent_data_op($wait_state, $target_state, qw(shift latency_increment_request));
        return 1 if _dynamic_wait_zero_sample_target_is_independent_data_op($wait_state, $target_state, qw(assemble latency_increment_request));
        return 1 if _dynamic_wait_zero_sample_target_is_independent_data_op($wait_state, $target_state, qw(extract_capture latency_increment_request));
        return 1 if _dynamic_wait_zero_sample_target_is_independent_data_op($wait_state, $target_state, qw(spawn_start latency_increment_request));
    }
    return 1 if $kind eq 'bank_load'
        && _dynamic_wait_zero_sample_target_is_independent_data_op($wait_state, $target_state, qw(bank_load latency_increment_request));
    return 1 if $kind eq 'bank_store'
        && _dynamic_wait_zero_sample_target_is_independent_data_op($wait_state, $target_state, qw(bank_store latency_increment_request));

    return 0;
}

sub _dynamic_wait_zero_sample_target_is_independent_setter {
    my ($wait_state, $target_state) = @_;
    return _dynamic_wait_zero_sample_target_is_independent_data_op($wait_state, $target_state, qw(set update latency_increment_request));
}

sub _dynamic_wait_zero_sample_target_is_independent_control_state {
    my ($wait_state, $target_state) = @_;
    return 0 unless _dynamic_wait_has_pending_samples($wait_state);

    my %pending_sample = _dynamic_wait_pending_sample_names($wait_state);
    return 0 unless %pending_sample;

    for my $assignment (@{$target_state->{assignments} || []}) {
        return 0 if _dynamic_wait_assignment_touches_pending_sample($assignment, \%pending_sample);
    }

    for my $transition (@{$target_state->{transitions} || []}) {
        return 0 if _dynamic_wait_condition_touches_pending_sample($transition->{condition}, \%pending_sample);
    }

    for my $condition ($target_state->{loop_condition}, $target_state->{condition}) {
        my $text = ref($condition) ? _format_isf_expr($condition) : $condition;
        return 0 if _dynamic_wait_text_touches_pending_sample($text, \%pending_sample);
    }

    return @{$target_state->{transitions} || []} ? 1 : 0;
}

sub _dynamic_wait_zero_sample_target_is_phase_marker {
    my ($target_state) = @_;
    return 0 unless ($target_state->{kind} // '') eq 'sequential';
    return 0 unless defined($target_state->{phase_name}) && length($target_state->{phase_name});
    return 0 if @{$target_state->{assignments} || []};
    return @{$target_state->{transitions} || []} ? 1 : 0;
}

sub _dynamic_wait_zero_sample_target_is_independent_sync_state {
    my ($wait_state, $target_state) = @_;
    return 0 unless _dynamic_wait_has_pending_samples($wait_state);

    my %pending_sample = _dynamic_wait_pending_sample_names($wait_state);
    return 0 unless %pending_sample;

    for my $port (@{$target_state->{done_ports} || []}) {
        return 0 if _dynamic_wait_text_touches_pending_sample($port, \%pending_sample);
    }

    for my $transition (@{$target_state->{transitions} || []}) {
        return 0 if _dynamic_wait_condition_touches_pending_sample($transition->{condition}, \%pending_sample);
    }

    return @{$target_state->{transitions} || []} ? 1 : 0;
}

sub _dynamic_wait_zero_sample_target_is_independent_data_op {
    my ($wait_state, $target_state, @source_kinds) = @_;
    return 0 unless _dynamic_wait_has_pending_samples($wait_state);

    my %pending_sample = _dynamic_wait_pending_sample_names($wait_state);
    return 0 unless %pending_sample;

    my %accepted_source_kind = map { $_ => 1 } @source_kinds;
    my $has_data_op = 0;
    for my $assignment (@{$target_state->{assignments} || []}) {
        my $source_kind = $assignment->{source_kind} // '';
        return 0 unless $accepted_source_kind{$source_kind};
        $has_data_op = 1 unless $source_kind eq 'latency_increment_request';
        return 0 if _dynamic_wait_assignment_touches_pending_sample($assignment, \%pending_sample);
    }

    for my $transition (@{$target_state->{transitions} || []}) {
        return 0 if _dynamic_wait_condition_touches_pending_sample($transition->{condition}, \%pending_sample);
    }

    return $has_data_op ? 1 : 0;
}

sub _dynamic_wait_pending_sample_names {
    my ($wait_state) = @_;
    return map {
        my $lhs = $_->{lhs};
        defined($lhs) && !ref($lhs) && length($lhs) ? ($lhs => 1) : ();
    } @{$wait_state->{pending_sample_assignments} || []};
}

sub _dynamic_wait_assignment_touches_pending_sample {
    my ($assignment, $pending_sample) = @_;
    return 1 if $pending_sample->{$assignment->{lhs} // ''};
    return 1 if _dynamic_wait_text_touches_pending_sample($assignment->{rhs}, $pending_sample);
    return _dynamic_wait_condition_touches_pending_sample($assignment->{guard}, $pending_sample);
}

sub _dynamic_wait_condition_touches_pending_sample {
    my ($condition, $pending_sample) = @_;
    return 0 unless ref($condition) eq 'HASH';
    for my $key (qw(expr signal port)) {
        return 1 if _dynamic_wait_text_touches_pending_sample($condition->{$key}, $pending_sample);
    }
    return 0;
}

sub _dynamic_wait_text_touches_pending_sample {
    my ($text, $pending_sample) = @_;
    return 0 unless defined($text) && !ref($text);
    for my $name (keys %$pending_sample) {
        return 1 if $text =~ /(?<![A-Za-z0-9_])\Q$name\E(?![A-Za-z0-9_])/;
    }
    return 0;
}

sub _clone_assignment {
    my ($assignment) = @_;
    my %clone = %$assignment;
    $clone{guard} = { %{$assignment->{guard}} }
        if ref($assignment->{guard}) eq 'HASH';
    return \%clone;
}

sub _clone_transition {
    my ($transition) = @_;
    my %clone = %$transition;
    $clone{condition} = { %{$transition->{condition}} }
        if ref($transition->{condition}) eq 'HASH';
    return \%clone;
}

sub _inj_watchdog {
    my ($st,$tn,$wn,$lim,$ctrs)=@_;
    $ctrs->{last_error} = 1;
    unshift @{$st->[0]{assignments}},{lhs=>$wn,rhs=>"(- $lim 1)",op=>'<=',source_kind=>'watchdog_init'};
    push @$st,{name=>"${tn}_timeout",kind=>'terminal',assignments=>[{lhs=>'done',rhs=>1,op=>'<1',source_kind=>'timeout_pulse'},{lhs=>'last_error',rhs=>1,op=>'<-',source_kind=>'timeout_status'}],transitions=>[]};
}

sub _inj_latency {
    my ($st,$tn,$lat,$ha,$ctrs)=@_;
    $ctrs->{last_error} = 1; my $cc="${tn}_cc";my $inc="${tn}_inc";my $err="${tn}_lerr";my $min=$lat->{min}//1;my $max=$lat->{max}//256;
    unshift @{$st->[0]{assignments}},{lhs=>$cc,rhs=>0,op=>'<-',source_kind=>'latency_counter_init'};
    for my $s(@$st){next if $s->{kind}eq'entry'||$s->{kind}eq'terminal'||$s->{name}=~/_timeout$/;unshift @{$s->{assignments}},{lhs=>$inc,rhs=>1,op=>'=',source_kind=>'latency_increment_request'}}
    my($done)=grep{$_->{kind}eq'terminal'&&$_->{name}!~/_timeout$/}@$st;
    if($done){push @{$done->{assignments}},{lhs=>$err,rhs=>1,op=>'=',guard=>{signal=>$cc,op=>'<',value=>$min},source_kind=>'latency_error'}}
    if(!$ha&&$max){my $mc="${tn}_max_chk";push @$st,{name=>$mc,kind=>'sequential',assignments=>[],transitions=>[{target=>"${tn}_timeout",condition=>{signal=>$cc,op=>'=',value=>$max}}]};
        push @$st,{name=>"${tn}_timeout",kind=>'terminal',assignments=>[{lhs=>$err,rhs=>1,op=>'=',source_kind=>'latency_error'},{lhs=>'done',rhs=>1,op=>'<1',source_kind=>'timeout_pulse'},{lhs=>'last_error',rhs=>1,op=>'<-',source_kind=>'timeout_status'}],transitions=>[]}}
    my $dt={name=>"${tn}_cc_inc",kind=>'latency_counter',assignments=>[{lhs=>$cc,rhs=>"(+ $cc 1)",op=>'<-',guard=>{port=>$inc},source_kind=>'latency_counter'}]};
    return ($cc,$inc,$err,$dt);
}

sub _build_rules {
    my ($self, $actor, $ctrs, $bank_accesses, $generated_children, $storage_roles) = @_;
    my @d;
    my %fanin_by_transaction;
    my %payload_by_transaction;
    my %seen_fanin_source;
    my %generated_trigger_ordinals;
    my $widths = _build_signal_width_map($actor, { clauses => [] });
    my %transaction_by_name = map { $_->{name} => $_ } @{$actor->{transactions} || []};
    $generated_children ||= {};

    for my $r (@{$actor->{rules} || []}) {
        my $c = $self->_rule_cond($r->{when});
        my $terms = _rule_cond_terms($r->{when});
        my @a;

        for my $ac (@{$r->{actions}}) {
            next unless ref($ac) eq 'ARRAY';
            my $a0 = $ac->[0];

            if ($a0 eq 'trigger') {
                my $target = $ac->[1];
                my $generated_trigger = $generated_children->{$target} ? 1 : 0;
                my $trigger_ordinal;
                if ($generated_trigger) {
                    my $key = "$r->{name}\0$target";
                    $trigger_ordinal = $generated_trigger_ordinals{$key}++;
                }
                my $source = _rule_trigger_source_name($r->{name}, $target, $trigger_ordinal);
                push @a, { lhs => $source, rhs => 1, op => '<1', source_kind => 'rule_trigger_source' };
                $ctrs->{$source} = 1 if $ctrs;
                $storage_roles->{$source} = 'rule_trigger_source'
                    if ref($storage_roles) eq 'HASH';
                $ctrs->{"${target}_start"} = 1 if $ctrs && !$generated_trigger;
                my %target_ports = _transaction_port_map($transaction_by_name{$target});
                for my $binding (@{_activation_bindings_from_clause($ac, $r->{name}, 'rule trigger')}) {
                    next unless $binding->{role} eq 'input';
                    my $payload = _rule_trigger_payload_source_name($r->{name}, $target, $binding->{port}, $trigger_ordinal);
                    my $width = ($target_ports{$binding->{port}} || {})->{width} // 1;
                    push @a, {
                        lhs         => $payload,
                        rhs         => _activation_binding_actor_expr_text($binding),
                        op          => '<-',
                        source_kind => 'rule_trigger_payload_source',
                    };
                    $ctrs->{$payload} = $width if $ctrs;
                    $storage_roles->{$payload} = 'rule_trigger_payload_source'
                        if ref($storage_roles) eq 'HASH';
                    $ctrs->{$binding->{port}} = $width if $ctrs;
                    push @{$payload_by_transaction{$target}{$binding->{port}}}, {
                        trigger_source => $source,
                        payload_source => $payload,
                        width          => $width,
                    };
                }
                if (!$generated_trigger) {
                    push @{$fanin_by_transaction{$target}}, $source
                        unless $seen_fanin_source{"$target\0$source"}++;
                }
            } elsif ($a0 eq 'priority') {
                # Parsed metadata; arbitration enforcement is a later slice.
            } elsif ($a0 eq 'store' || $a0 eq 'load') {
                my $spec = _parse_bank_access_for_lowering($ac, $actor, $widths, $r->{name}, 'rule');
                push @a, _bank_access_assignments($spec);
                push @$bank_accesses, _bank_access_metadata(
                    $spec,
                    owner          => $r->{name},
                    owner_kind     => 'rule',
                    container_kind => 'dt',
                    container_name => $r->{name},
                ) if ref($bank_accesses) eq 'ARRAY';
            } elsif ($a0 eq 'set') {
                push @a, {
                    lhs         => $ac->[1],
                    rhs         => _format_isf_expr($ac->[2]),
                    op          => '<-',
                    source_kind => 'rule_action',
                };
            } else {
                push @a, { lhs => $a0, rhs => _format_isf_expr($ac->[1]), op => '<-', source_kind => 'rule_action' };
            }
        }

        push @d, {
            name            => $r->{name},
            kind            => 'rule',
            dte_guard       => $c,
            dte_guard_terms => $terms,
            assignments     => \@a,
        };
    }

    for my $target (sort keys %fanin_by_transaction) {
        my @sources = @{$fanin_by_transaction{$target}};
        my $rhs = @sources == 1 ? $sources[0] : '(| ' . join(' ', @sources) . ')';
        push @d, {
            name        => "${target}_trigger_fanin",
            kind        => 'rule_trigger_fanin',
            assignments => [
                { lhs => "${target}_start", rhs => $rhs, op => '=', source_kind => 'rule_trigger_fanin' },
                _rule_trigger_payload_fanin_assignments($payload_by_transaction{$target} || {}),
            ],
        };
    }

    return @d;
}
sub _rule_trigger_source_name {
    my ($rule, $target, $ordinal) = @_;
    return defined($ordinal)
        ? "${rule}_${target}_trigger_$ordinal"
        : "${rule}_${target}";
}
sub _rule_trigger_payload_source_name {
    my ($rule, $target, $port, $ordinal) = @_;
    return defined($ordinal)
        ? "${rule}_${target}_trigger_${ordinal}_${port}_payload"
        : "${rule}_${target}_$port";
}
sub _rule_trigger_payload_fanin_assignments {
    my ($by_port) = @_;
    my @assignments;
    for my $port (sort keys %$by_port) {
        for my $source (@{$by_port->{$port} || []}) {
            push @assignments, {
                lhs         => $port,
                rhs         => $source->{payload_source},
                op          => '=',
                guard       => { port => $source->{trigger_source} },
                source_kind => 'rule_trigger_payload_fanin',
            };
        }
    }
    return @assignments;
}
sub _rule_cond {
    my ($self, $w) = @_;
    return { port => '1' } unless $w && ref($w) eq 'ARRAY' && @$w >= 2;
    return ref($w->[1])
        ? { expr => _format_isf_expr($w->[1]) }
        : { port => $w->[1] };
}
sub _rule_cond_terms {
    my ($w) = @_;
    return {} unless $w && ref($w) eq 'ARRAY' && @$w >= 2;
    return _condition_literal_terms($w->[1]);
}

sub _substitute_named_drive_body_expr {
    my ($value, $param_signal) = @_;
    if (ref($value) eq 'ARRAY') {
        return [ map { _substitute_named_drive_body_expr($_, $param_signal) } @$value ];
    }
    return $param_signal->{$value}
        if defined($value) && !ref($value) && exists $param_signal->{$value};
    return $value;
}

sub _build_drive_dts {
    my ($self, $actor, $dts, $ctrs, $local_drive_uses, $extra_drive_sources, $storage_roles) = @_;
    my $drives = $actor->{drives} || {};
    for my $name (sort keys %$drives) {
        my $def = $drives->{$name};
        my $body = $def->{body};
        my @params = @{$def->{params}};
        my @sources;

        push @sources, { prefix => $name, source_kind => 'drive_body' }
            if !$local_drive_uses || $local_drive_uses->{$name};
        push @sources, @{$extra_drive_sources->{$name} || []};
        next unless @sources;

        my @assignments;

        for my $source (@sources) {
            my $prefix = $source->{prefix};
            $ctrs->{"${prefix}_start"} = 1;
            $storage_roles->{"${prefix}_start"} = 'drive_request'
                if ref($storage_roles) eq 'HASH';
            for my $p (@params) {
                $ctrs->{"${prefix}_$p"} = _drive_param_width($actor, $name, $p);
                $storage_roles->{"${prefix}_$p"} = 'drive_payload'
                    if ref($storage_roles) eq 'HASH';
            }

            my %param_signal = map { $_ => "${prefix}_$_" } @params;
            for my $pair (@$body) {
                next unless ref($pair) eq 'ARRAY' && @$pair >= 2;
                my $lhs = $pair->[0];
                my $rhs = _substitute_named_drive_body_expr($pair->[1], \%param_signal);
                push @assignments, {
                    lhs         => $lhs,
                    rhs         => _format_isf_expr($rhs),
                    op          => '<-',
                    guard       => { port => "${prefix}_start" },
                    source_kind => $source->{source_kind} || 'drive_body',
                };
            }
        }

        push @$dts, { name => $name, kind => 'drive', assignments => \@assignments };
    }
}

sub _parse_latency {
    my ($cl, $tn) = @_;
    my %result;

    my @options = grep { defined } @{$cl}[1 .. $#$cl];

    confess "Transaction '$tn': latency requires '(latency (min N) (max M))'\n"
        unless @options;

    for my $option (@options) {
        confess "Transaction '$tn': latency options must be '(min N)' or '(max N)'\n"
            unless ref($option) eq 'ARRAY'
                && @$option == 2
                && defined($option->[0])
                && !ref($option->[0])
                && ($option->[0] eq 'min' || $option->[0] eq 'max')
                && defined($option->[1])
                && !ref($option->[1])
                && $option->[1] =~ /\A[1-9][0-9]*\z/;

        my $key = $option->[0];
        confess "Transaction '$tn': duplicate latency '$key' option\n"
            if exists $result{$key};
        $result{$key} = $option->[1];
    }

    confess "Transaction '$tn': latency min must be less than or equal to max\n"
        if exists($result{min}) && exists($result{max}) && $result{min} > $result{max};

    return \%result;
}
sub _parse_await_wd { my($cl)=@_; for my $i(2..$#$cl){my$x=$cl->[$i];return$x->[1]if ref($x)eq'ARRAY'&&$x->[0]eq'watchdog'} undef }

sub _wire_do_children {
    my ($self,$st,$ctrs,$actor,$generated_children)=@_;
    $generated_children ||= {};
    my %ctx = map { $_->{name} => 1 } @{$actor->{transactions}};
    my %need;
    for my $tx (@{$actor->{transactions}}) {
        for my $ref (_child_action_refs_from_transaction_clauses($tx->{clauses}, $tx->{name})) {
            next unless ($ref->{keyword} // '') eq 'do';
            my $target = $ref->{clause}[1];
            next if $generated_children->{$target};
            $need{$target} = 1 if $ctx{$target};
        }
    }
    for my $c (sort keys %need) {my $s="${c}_start";my $d="${c}_done";
        $ctrs->{$s}=1 if ref($ctrs)eq'HASH';
        $ctrs->{$d}=1 if ref($ctrs)eq'HASH';
        my($en)=grep{$_->{name}=~/^\Q$c\E_idle_/}@$st;if($en){$en->{guard}={port=>$s};$en->{transitions}=[];my($nx)=grep{$_->{name}=~/^\Q$c\E_/&&$_->{kind}ne'entry'&&$_->{name}!~/_timeout$/}@$st;push @{$en->{transitions}},{target=>$nx->{name},condition=>$en->{guard}}if$nx}
        my($tm)=grep{$_->{name}=~/^\Q$c\E_(?:done|complete)_/&&$_->{kind}eq'terminal'}@$st;unshift @{$tm->{assignments}},{lhs=>$d,rhs=>1,op=>'<1'}if$tm}
}

sub _merge_sequential {
    my ($st) = @_;
    my @merged;
    for my $s (@$st) {
        if (@merged && $merged[-1]{kind} eq 'sequential' && $s->{kind} eq 'sequential'
            && $merged[-1]{name} !~ /_repeat_check/ && $merged[-1]{name} !~ /_repeat_init/
            && $s->{name} !~ /_repeat_init/) {
            push @{$merged[-1]{assignments}}, @{$s->{assignments}};
            $merged[-1]{transitions} = $s->{transitions};
            $merged[-1]{name} = $s->{name};
        } else {
            push @merged, $s;
        }
    }
    @$st = @merged;
}

1;
