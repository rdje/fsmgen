package FSM::Scheduler::ISF::LoweringIR;

use v5.20;
use strict;
use warnings;
use feature qw(signatures postderef);
no warnings 'experimental::signatures';
use POSIX qw(log);
use Carp qw(confess);

sub new($class, %args) { bless { debug => ($args{debug} // 0) }, $class }

my %SUPPORTED_TRANSACTION_CLAUSES = (
    transaction => {
        map { $_ => 1 } qw(
            on drive await sample update phase shift_left shift_right assemble
            extract complete when switch repeat latency do spawn await_all
            await_any params stage contract
        )
    },
    when => {
        map { $_ => 1 } qw(
            drive await sample complete repeat update shift_left shift_right
            assemble extract when
        )
    },
    switch => {
        map { $_ => 1 } qw(
            drive await sample repeat update shift_left shift_right assemble
            extract when
        )
    },
    repeat => {
        map { $_ => 1 } qw(
            drive await sample update shift_left shift_right assemble extract
        )
    },
);

my %TRANSACTION_CONTEXT_LABEL = (
    transaction => 'transaction body',
    when        => 'when body',
    switch      => 'switch branch',
    repeat      => 'repeat body',
);

sub build_module($self, $actor) {
    $self->_validate_child_transaction_refs($actor);
    my %spawned = $self->_collect_spawn_refs($actor);
    $self->_validate_transaction_parameter_clauses($actor, \%spawned);

    my %child_irs;
    for my $cname (sort keys %spawned) {
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

    my $parent_ir = $self->_build_parent_ir($actor, \%spawned);
    $parent_ir->{children} = \%child_irs;
    $parent_ir->{library_uses} = \@library_instances;
    return $parent_ir;
}

# --- Child IR (separate module) ---

sub _build_child_ir($self, $tx, $actor, $cname) {
    my ($states, $ctrs, $dts, $do_children, $spawn_refs, $contracts, $signal_widths, $storage_roles) =
        $self->_build_transaction($tx, $actor, 0);
    $states = [@$states]; $ctrs = { %$ctrs }; $dts = [@$dts];
    my %module_signal_widths = _declared_storage_signal_widths($actor);
    my %module_storage_roles = _declared_storage_roles($actor);
    _merge_signal_widths(\%module_signal_widths, $signal_widths, $tx->{name});
    _merge_storage_roles(\%module_storage_roles, $storage_roles, $tx->{name});

    my %used_drives = _collect_named_drive_call_names($tx->{clauses}, $actor->{drives} || {});
    _register_drive_call_signal_widths($actor, $ctrs, \%used_drives, \%module_storage_roles);

    my $ports = $self->_build_child_ports($actor, $states, $dts, \%used_drives);

    my $ir = {
        actor_name => $cname,
        clock      => $actor->{clock},
        reset      => $actor->{reset},
        watchdog   => $actor->{watchdog},
        params     => _transaction_param_declarations($tx),
        ports      => $ports,
        states     => $states,
        dt_blocks  => $dts,
        counters   => $ctrs,
        declared_storage => _declared_storage_for_ir($actor),
        signal_widths => \%module_signal_widths,
        storage_roles => \%module_storage_roles,
        children   => {},
        temporal_contracts => $contracts,
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

# --- Parent IR (composition top, non-spawned transactions only) ---

sub _build_parent_ir($self, $actor, $spawned) {
    my @ports  = @{$self->_build_ports($actor)};
    my %ctrs;
    my @states;
    my @dts;
    my @spawn_instances;
    my @temporal_contracts;
    my %signal_widths = _declared_storage_signal_widths($actor);
    my %storage_roles = _declared_storage_roles($actor);
    my %local_drive_uses;
    my %spawn_drive_sources;
    my %transaction_by_name = map { $_->{name} => $_ } @{$actor->{transactions} || []};
    my $ti = 0;

    for my $tx (@{$actor->{transactions}}) {
        next if $spawned->{$tx->{name}};
        my ($ss, $cs, $ds, $do, $sp, $contracts, $widths, $roles) = $self->_build_transaction($tx, $actor, $ti++);
        _merge_signal_widths(\%signal_widths, $widths, $tx->{name});
        _merge_storage_roles(\%storage_roles, $roles, $tx->{name});
        my %tx_drive_uses = _collect_named_drive_call_names($tx->{clauses}, $actor->{drives} || {});
        $local_drive_uses{$_} = 1 for keys %tx_drive_uses;
        push @states, @$ss;
        for my $k (sort keys %$cs) {
            $ctrs{$k} = $cs->{$k};
        }
        push @dts, @$ds;
        push @temporal_contracts, @$contracts;
        for my $c (@$do)  { $ctrs{"${c}_start"} = 1; $ctrs{"${c}_done"} = 1; }
        for my $s (@$sp)  {
            $ctrs{"$s->{instance}_start"} = 1;
            $ctrs{"$s->{instance}_done"} = 1;
            _ensure_port(
                \@ports,
                "$s->{instance}_start",
                'output',
                1,
                "Transaction '$tx->{name}': spawn instance '$s->{instance}' generated start handoff",
            );
            _ensure_port(
                \@ports,
                "$s->{instance}_done",
                'input',
                1,
                "Transaction '$tx->{name}': spawn instance '$s->{instance}' generated done handoff",
            );
            my $child_tx = $transaction_by_name{$s->{child}};
            my %child_drive_uses = _collect_named_drive_call_names($child_tx->{clauses}, $actor->{drives} || {});
            my @drive_handoffs;
            for my $drive_name (sort keys %child_drive_uses) {
                my $prefix = "$s->{instance}_${drive_name}";
                my @payloads;
                push @{$spawn_drive_sources{$drive_name}}, {
                    instance    => $s->{instance},
                    drive       => $drive_name,
                    prefix      => $prefix,
                    source_kind => 'spawn_drive_body',
                };
                _ensure_port(
                    \@ports,
                    "${prefix}_start",
                    'input',
                    1,
                    "Transaction '$tx->{name}': spawn instance '$s->{instance}' named drive '$drive_name' generated request handoff",
                );
                $ctrs{"${prefix}_start"} = 1;
                $storage_roles{"${prefix}_start"} = 'drive_request';
                for my $param (@{($actor->{drives} || {})->{$drive_name}{params} || []}) {
                    my $width = _drive_param_width($actor, $drive_name, $param);
                    _ensure_port(
                        \@ports,
                        "${prefix}_$param",
                        'input',
                        $width,
                        "Transaction '$tx->{name}': spawn instance '$s->{instance}' named drive '$drive_name' parameter '$param' generated payload handoff",
                    );
                    $ctrs{"${prefix}_$param"} = $width;
                    $storage_roles{"${prefix}_$param"} = 'drive_payload';
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
        }
        push @spawn_instances, map { _clone_isf_value($_) } @$sp;
    }

    push @dts, $self->_build_rules($actor, \%ctrs);
    $self->_wire_do_children(\@states, \%ctrs, $actor);
    my $local_drive_filter = keys(%$spawned) ? \%local_drive_uses : undef;
    $self->_build_drive_dts($actor, \@dts, \%ctrs, $local_drive_filter, \%spawn_drive_sources, \%storage_roles);

    my $ir = {
        actor_name => $actor->{actor_name},
        clock      => $actor->{clock},
        reset      => $actor->{reset},
        watchdog   => $actor->{watchdog},
        params     => _actor_param_declarations($actor),
        ports      => \@ports,
        states     => \@states,
        dt_blocks  => \@dts,
        counters   => \%ctrs,
        declared_storage => _declared_storage_for_ir($actor),
        signal_widths => \%signal_widths,
        storage_roles => \%storage_roles,
        children   => {},
        spawn_instances => \@spawn_instances,
        temporal_contracts => \@temporal_contracts,
    };
    $ir->{resource_arbitration} = _apply_rule_slot_resource_arbitration($ir, $actor);
    $ir->{priority_resolution} = _merge_priority_resolution(
        _apply_rule_priority_resolution($ir, $actor),
        _apply_rule_transaction_priority_resolution($ir, $actor),
    );
    _finalize_ir($ir);
    return $ir;
}

sub _collect_spawn_refs($self, $actor) {
    my %s;
    for my $tx (@{$actor->{transactions}}) {
        for my $c (@{$tx->{clauses}}) {
            next unless ref($c) eq 'ARRAY' && $c->[0] eq 'spawn';
            $s{$c->[1]} = 1;
        }
    }
    return %s;
}

sub _validate_child_transaction_refs($self, $actor) {
    my %transactions = map { $_->{name} => 1 } @{$actor->{transactions} || []};
    my %transaction_by_name = map { $_->{name} => $_ } @{$actor->{transactions} || []};
    my %spawn_instances;

    for my $tx (@{$actor->{transactions} || []}) {
        my $tx_name = $tx->{name};
        for my $clause (@{$tx->{clauses} || []}) {
            next unless ref($clause) eq 'ARRAY' && @$clause;
            my $keyword = $clause->[0];
            next unless defined($keyword) && !ref($keyword);
            next unless $keyword eq 'do' || $keyword eq 'spawn';

            _validate_child_action_clause($clause, $tx_name, 'transaction body');

            my $target = $clause->[1];
            confess "Transaction '$tx_name': $keyword target must be a scalar transaction name\n"
                unless defined($target) && !ref($target) && length($target);
            confess "Transaction '$tx_name': $keyword target '$target' is not a declared transaction\n"
                unless $transactions{$target};

            next unless $keyword eq 'spawn';
            confess "Transaction '$tx_name': spawn target '$target' conflicts with parent actor module name '$actor->{actor_name}'\n"
                if $target eq $actor->{actor_name};

            my $instance = $clause->[3];
            confess "Transaction '$tx_name': spawn instance '$instance' conflicts with parent actor instance name '$actor->{actor_name}'\n"
                if $instance eq $actor->{actor_name};
            confess "Transaction '$tx_name': duplicate spawn instance '$instance' in actor '$actor->{actor_name}'\n"
                if $spawn_instances{$instance}++;

            my %declared_params = map {
                $_->{name} => $_
            } @{_transaction_param_declarations($transaction_by_name{$target})};
            for my $override (@{_spawn_parameter_overrides($clause, $tx_name, 'transaction body')}) {
                my $name = $override->{name};
                confess "Transaction '$tx_name': spawn instance '$instance' overrides unknown parameter '$name' on child '$target'\n"
                    unless exists $declared_params{$name};
                confess "Transaction '$tx_name': spawn instance '$instance' parameter '$name' shape does not match child '$target' declaration\n"
                    unless _param_values_shape_compatible($declared_params{$name}{value}, $override->{value});
            }
        }
    }

    return 1;
}

sub _validate_transaction_parameter_clauses($self, $actor, $spawned) {
    for my $tx (@{$actor->{transactions} || []}) {
        my $params = _transaction_param_declarations($tx);
        next unless @$params;

        my $tx_name = $tx->{name};
        confess "Transaction '$tx_name': params are supported only on spawned child transactions\n"
            unless $spawned->{$tx_name};
    }
    return 1;
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
        _validate_isf_param_value(
            $param->{value},
            "Actor '$actor_name': parameter '$name'",
        );
        push @params, {
            name  => $name,
            value => _clone_isf_value($param->{value}),
        };
    }

    return \@params;
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

sub _build_ports($self, $actor) {
    my @p;
    for my $i (@{$actor->{interface}{inputs}})  { push @p, { name => $i->{name}, direction => 'input',  width => $i->{width} // 1 }; }
    for my $o (@{$actor->{interface}{outputs}}) { push @p, { name => $o->{name}, direction => 'output', width => $o->{width} // 1 }; }
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
            $signal{index} = $_->{index} if exists $_->{index};
            \%signal;
        } @{$entry->{signals} || []};

        my %copy = (
            kind    => $entry->{kind},
            name    => $entry->{name},
            width   => $entry->{width},
            signals => \@signals,
        );
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
    my ($self, $actor, $states, $dts, $used_drives) = @_;

    my %actor_output_width = map {
        $_->{name} => ($_->{width} // 1)
    } @{$actor->{interface}{outputs} || []};

    my @ports;
    my %seen;
    for my $input (@{$actor->{interface}{inputs} || []}) {
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
    _collect_sample_widths($tx->{clauses}, \%widths);
    _collect_shift_widths($tx->{clauses}, \%widths);
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
        my $total = 0;
        for my $part (@parts) {
            return unless exists($widths->{$part}) && $widths->{$part} > 0;
            $total += $widths->{$part};
        }
        my $known_width = $widths->{$target};
        confess "assemble part widths sum $total conflicts with known width $known_width for '$target'\n"
            if defined($known_width) && $known_width > 0 && $known_width != $total;
        $widths->{$target} = $total if $total > 0;
    }

    for my $child (@$node) {
        _collect_data_widths($child, $widths) if ref($child) eq 'ARRAY';
    }
}

sub _collect_shift_widths {
    my ($node, $widths) = @_;
    return unless ref($node) eq 'ARRAY';

    if (@$node >= 4 && $node->[0] eq 'shift_right') {
        my $explicit_width = _parse_shift_right_width($node);
        my $target = $node->[1];
        if (defined($explicit_width) && defined($target) && !ref($target)) {
            my $known_width = $widths->{$target};
            confess "shift_right explicit width $explicit_width conflicts with known width $known_width for '$target'\n"
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
        for my $idx (0 .. $#$fields) {
            next unless defined $explicit_widths->[$idx];
            my $field = $fields->[$idx];
            $widths->{$field} = $explicit_widths->[$idx] unless exists $widths->{$field};
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

sub _parse_shift_right_width {
    my ($cl) = @_;
    my $width;

    for my $idx (3 .. $#$cl) {
        my $option = $cl->[$idx];
        confess "shift_right optional arguments must be '(width N)'\n"
            unless ref($option) eq 'ARRAY' && @$option == 2 && $option->[0] eq 'width';
        confess "shift_right accepts at most one '(width N)' option\n"
            if defined $width;
        confess "shift_right width must be a positive integer\n"
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
sub _build_transaction($self, $tx, $actor, $txi) {
    my $tn  = $tx->{name};
    my $wd  = $actor->{watchdog};
    my $drives = $actor->{drives} || {};
    _validate_supported_transaction_clauses($tx->{clauses}, $tn, 'transaction');
    my $widths = _build_signal_width_map($actor, $tx);
    my @st;
    my %ct;
    my @dt;
    my @ps;
    my @doc;
    my @spc;
    my @dps;
    my @contracts;
    my %contract_names;
    my %storage_roles;
    my $si  = 0; my $ha = 0; my $wdc; my $lat;

    for my $cl (@{$tx->{clauses}}) {
        next unless ref($cl) eq 'ARRAY';
        my $k = $cl->[0];
        if    ($k eq 'on')       { push @st, _ir_on($cl, $tn, $si++); }
        elsif ($k eq 'drive')    {
            if (!ref($cl->[1]) && @$cl >= 2) {
                # Call: (drive name arg1 arg2 ...)
                my $name = $cl->[1];
                confess "Transaction '$tn': drive '$name' not defined\n" unless $drives->{$name};
                push @st, _ir_named_drive_call($cl, $tn, $si++, $drives->{$name}, [splice @ps]);
            } else {
                push @st, _ir_drive($cl, $tn, [splice @ps], $si++);
            }
        }
        elsif ($k eq 'await')    { $ha=1; $wdc="${tn}_wd"; my $wd_override = _parse_await_wd($cl); push @st, _ir_await($cl, $tn, $si++, $wd_override || $wd, [splice @ps]); }
        elsif ($k eq 'sample')   { push @ps, $cl; }
        elsif ($k eq 'update')      { _push_sample_state(\@st,$tn,\@ps,\$si); push @st, _ir_update($cl,$tn,$si++); }
        elsif ($k eq 'phase')       { push @st, _ir_phase($cl,$tn,$si++); }
        elsif ($k eq 'stage')       { _push_sample_state(\@st,$tn,\@ps,\$si); push @st, _ir_stage($cl,$tn,$si++,$actor); }
        elsif ($k eq 'contract')    {
            _push_sample_state(\@st, $tn, \@ps, \$si);
            my ($cs, $cdt, $cm) = _ir_contract(
                $cl, $tn, $si++, $actor, $widths, \%ct, \%contract_names,
            );
            push @st, $cs;
            push @dt, $cdt;
            push @contracts, $cm;
        }
        elsif ($k eq 'shift_left')  { _push_sample_state(\@st,$tn,\@ps,\$si); push @st, _ir_shift_left($cl,$tn,$si++); }
        elsif ($k eq 'shift_right') { _push_sample_state(\@st,$tn,\@ps,\$si); push @st, _ir_shift_right($cl,$tn,$si++,$widths); }
        elsif ($k eq 'assemble')    { _push_sample_state(\@st,$tn,\@ps,\$si); push @st, _ir_assemble($cl,$tn,$si++); }
        elsif ($k eq 'extract')     { _push_sample_state(\@st,$tn,\@ps,\$si); push @st, _ir_extract($cl,$tn,$si++,$widths); }
        elsif ($k eq 'complete') { push @st, _ir_complete($cl, $tn, $si++); }
        elsif ($k eq 'when' && !@st) { push @st, _ir_when_activation($cl,$tn,$si++); }
        elsif ($k eq 'when')     {
            my ($ws) = _expand_when($cl,$tn,\$si,\@ps,$drives,$wd,$widths,\%ct,\%storage_roles);
            push @st, @$ws;
        }
        elsif ($k eq 'switch')   {
            my ($ss) = _expand_switch($cl,$tn,\$si,\@ps,$drives,$wd,$widths,\%ct,\%storage_roles);
            push @st, @$ss;
        }
        elsif ($k eq 'repeat')   { my ($rs,$rc,$rw) = _ir_repeat($cl,$tn,\$si,\@ps,$wd,$drives,$widths); push @st,@$rs; _register_counter_width(\%ct,$rc,$rw); $storage_roles{$rc} = 'repeat_counter'; }
        elsif ($k eq 'latency')  { $lat = _parse_latency($cl, $tn); }
        elsif ($k eq 'params')   { next; }
        elsif ($k eq 'do')       { push @doc, $cl->[1]; push @st, _ir_do($cl,$tn,$si++); }
        elsif ($k eq 'spawn')    { push @spc, _spawn_ref_from_clause($cl,$tn); push @dps, "$spc[-1]{instance}_done"; push @st, _ir_spawn($cl,$tn,$si++); }
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
    return (\@st, \%ct, \@dt, \@doc, \@spc, \@contracts, { %{$widths || {}} }, \%storage_roles);
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
    my ($clauses, $tn, $context) = @_;
    return unless ref($clauses) eq 'ARRAY';

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
        } elsif ($keyword eq 'update') {
            _validate_update_clause($clause, $tn, $label);
        } elsif ($keyword eq 'shift_left' || $keyword eq 'shift_right') {
            _validate_shift_clause($clause, $tn, $label);
        } elsif ($keyword eq 'when') {
            _validate_when_clause($clause, $tn, $label);
            _validate_supported_transaction_clauses([@{$clause}[2 .. $#$clause]], $tn, 'when');
        } elsif ($keyword eq 'repeat') {
            _validate_repeat_clause($clause, $tn, $label);
            _validate_supported_transaction_clauses([@{$clause}[2 .. $#$clause]], $tn, 'repeat');
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
                _validate_supported_transaction_clauses([@{$branch}[1 .. $#$branch]], $tn, 'switch');
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
        ? '(shift_left reg bit)'
        : '(shift_right reg bit [(width N)])';

    confess "Transaction '$tn': $keyword requires '$shape' in $label\n"
        unless @$clause >= 3
            && @$clause <= ($keyword eq 'shift_right' ? 4 : 3)
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
        . "use '(update var expr)' for transaction-local flopped updates, "
        . "'(drive ...)' for protocol/output drives, rule '(port expr)' actions "
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

    confess "Transaction '$tn': stage requires '(stage name (input ready_signal) (output valid_signal))' in $label\n"
        unless ref($clause) eq 'ARRAY'
            && @$clause >= 2
            && defined($clause->[1])
            && !ref($clause->[1])
            && length($clause->[1]);

    my %seen;
    my %parsed = (name => $clause->[1]);

    for my $subclause (@{$clause}[2 .. $#$clause]) {
        confess "Transaction '$tn': stage '$parsed{name}' subclauses must be '(input ready_signal)' or '(output valid_signal)' in $label\n"
            unless ref($subclause) eq 'ARRAY'
                && @$subclause == 2
                && defined($subclause->[0])
                && !ref($subclause->[0])
                && length($subclause->[0]);

        my ($head, $signal) = @$subclause;
        confess "Transaction '$tn': stage '$parsed{name}' has unsupported subclause '$head'\n"
            unless $head eq 'input' || $head eq 'output';
        confess "Transaction '$tn': duplicate stage '$parsed{name}' subclause '$head'\n"
            if $seen{$head}++;
        confess "Transaction '$tn': stage '$parsed{name}' $head signal must be scalar\n"
            unless defined($signal) && !ref($signal) && length($signal);

        $parsed{ready} = $signal if $head eq 'input';
        $parsed{valid} = $signal if $head eq 'output';
    }

    confess "Transaction '$tn': stage '$parsed{name}' requires '(input ready_signal)'\n"
        unless defined($parsed{ready});
    confess "Transaction '$tn': stage '$parsed{name}' requires '(output valid_signal)'\n"
        unless defined($parsed{valid});

    return \%parsed;
}

sub _parse_bounded_eventual_contract_clause {
    my ($clause, $tn, $label) = @_;

    confess "Transaction '$tn': contract requires '(contract name (eventually signal (within cycles)))' in $label\n"
        unless ref($clause) eq 'ARRAY'
            && @$clause == 3
            && defined($clause->[1])
            && !ref($clause->[1])
            && length($clause->[1]);

    my $name = $clause->[1];
    my $eventual = $clause->[2];
    confess "Transaction '$tn': contract '$name' supports only '(eventually signal (within cycles))'\n"
        unless ref($eventual) eq 'ARRAY'
            && @$eventual == 3
            && defined($eventual->[0])
            && !ref($eventual->[0])
            && $eventual->[0] eq 'eventually'
            && defined($eventual->[1])
            && !ref($eventual->[1])
            && length($eventual->[1])
            && ref($eventual->[2]) eq 'ARRAY'
            && @{$eventual->[2]} == 2
            && defined($eventual->[2][0])
            && !ref($eventual->[2][0])
            && $eventual->[2][0] eq 'within'
            && defined($eventual->[2][1])
            && !ref($eventual->[2][1])
            && $eventual->[2][1] =~ /\A[1-9][0-9]*\z/;

    return {
        name          => $name,
        signal        => $eventual->[1],
        within_cycles => 0 + $eventual->[2][1],
    };
}

sub _validate_child_action_clause {
    my ($clause, $tn, $label) = @_;
    my $keyword = $clause->[0];

    if ($keyword eq 'do') {
        confess "Transaction '$tn': do requires '(do transaction)' in $label\n"
            unless @$clause == 2
                && defined($clause->[1])
                && !ref($clause->[1])
                && length($clause->[1]);
        return 1;
    }

    confess "Transaction '$tn': spawn requires '(spawn transaction as instance [(params (NAME value) ...)])' in $label\n"
        unless (@$clause == 4 || @$clause == 5)
            && defined($clause->[1])
            && !ref($clause->[1])
            && length($clause->[1])
            && defined($clause->[2])
            && !ref($clause->[2])
            && $clause->[2] eq 'as'
            && defined($clause->[3])
            && !ref($clause->[3])
            && length($clause->[3]);

    _parse_spawn_params_clause($clause->[4], $tn, $clause->[3], $label)
        if @$clause == 5;

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
    my ($tx) = @_;
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
        _validate_isf_param_value(
            $value,
            "Transaction '$tx_name': parameter '$name'",
        );
        push @params, {
            name  => $name,
            value => _clone_isf_value($value),
        };
    }

    return \@params;
}

sub _spawn_ref_from_clause {
    my ($clause, $tn) = @_;
    my $instance = $clause->[3] // "${tn}_spawn";
    return {
        child => $clause->[1],
        instance => $instance,
        parameter_overrides => _spawn_parameter_overrides($clause, $tn, 'transaction body'),
    };
}

sub _spawn_parameter_overrides {
    my ($clause, $tn, $label) = @_;
    return [] unless ref($clause) eq 'ARRAY' && @$clause >= 5;
    return _parse_spawn_params_clause($clause->[4], $tn, $clause->[3], $label);
}

sub _parse_spawn_params_clause {
    my ($params_clause, $tn, $instance, $label) = @_;
    confess "Transaction '$tn': spawn params require '(params (NAME value) ...)' in $label\n"
        unless ref($params_clause) eq 'ARRAY'
            && @$params_clause >= 2
            && defined($params_clause->[0])
            && !ref($params_clause->[0])
            && $params_clause->[0] eq 'params';

    my @overrides;
    my %seen;
    for my $entry (@{$params_clause}[1 .. $#$params_clause]) {
        confess "Transaction '$tn': spawn params entries require '(NAME value)' in $label\n"
            unless ref($entry) eq 'ARRAY' && @$entry == 2;
        my ($name, $value) = @$entry;
        confess "Transaction '$tn': spawn parameter override names must be scalar HDL identifiers\n"
            unless _is_hdl_identifier($name);
        confess "Transaction '$tn': spawn instance '$instance' has duplicate parameter override '$name'\n"
            if $seen{$name}++;
        _validate_isf_param_value(
            $value,
            "Transaction '$tn': spawn instance '$instance' parameter '$name'",
        );
        push @overrides, {
            name  => $name,
            value => _clone_isf_value($value),
        };
    }

    return \@overrides;
}

sub _is_hdl_identifier {
    my ($value) = @_;
    return defined($value) && !ref($value) && $value =~ /\A[A-Za-z_]\w*\z/;
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

sub _validate_repeat_clause {
    my ($clause, $tn, $label) = @_;

    confess "Transaction '$tn': repeat requires '(repeat count body...)' in $label\n"
        unless @$clause >= 3
            && defined($clause->[1])
            && !ref($clause->[1])
            && length($clause->[1]);

    return 1;
}

sub _validate_update_clause {
    my ($clause, $tn, $label) = @_;

    confess "Transaction '$tn': update requires '(update var expr)' in $label\n"
        unless @$clause == 3
            && defined($clause->[1])
            && !ref($clause->[1])
            && length($clause->[1])
            && defined($clause->[2]);

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
sub _ir_data_op  { my ($op,$cl,$tn,$i,$widths)=@_; $op eq'shift_left' ? _ir_shift_left($cl,$tn,$i) : $op eq'shift_right' ? _ir_shift_right($cl,$tn,$i,$widths) : $op eq'assemble' ? _ir_assemble($cl,$tn,$i) : $op eq'extract' ? _ir_extract($cl,$tn,$i,$widths) : _ir_update($cl,$tn,$i) }
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
sub _ir_drive   { my ($cl,$tn,$ps,$i)=@_; my @a; for(@$ps){push @a,{lhs=>$_->[3],rhs=>$_->[1],op=>'<=',source_kind=>'sample_capture'}} for my $j(2..$#$cl){my$x=$cl->[$j];next unless ref($x)eq'ARRAY'&&@$x>=2;push @a,{lhs=>$x->[0],rhs=>$x->[1],op=>'=',source_kind=>'inline_drive'}} {name=>"${tn}_drive_$i",kind=>'sequential',assignments=>\@a,transitions=>[]} }
sub _ir_drive_call { my ($body,$tn,$ps,$i)=@_; return undef; }
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
sub _ir_complete{ my ($cl,$tn,$i)=@_; {name=>"${tn}_done_$i",kind=>'terminal',assignments=>[{lhs=>$cl->[1],rhs=>1,op=>'<1',source_kind=>'complete_pulse'}],transitions=>[]} }
sub _ir_update   { my ($cl,$tn,$i)=@_; my$rhs=_format_isf_expr($cl->[2]); {name=>"${tn}_update_$i",kind=>'sequential',assignments=>[{lhs=>$cl->[1],rhs=>$rhs,op=>'<-',source_kind=>'update'}],transitions=>[]} }
sub _ir_shift_left { my ($cl,$tn,$i)=@_; my$reg=$cl->[1];my$bit=$cl->[2]; {name=>"${tn}_shift_$i",kind=>'sequential',assignments=>[{lhs=>$reg,rhs=>"(| (<< $reg 1) $bit)",op=>'<-',source_kind=>'shift'}],transitions=>[]} }
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
    my @field_widths;
    my $total_field_width = 0;

    for my $idx (0 .. $#$fields) {
        my $field = $fields->[$idx];
        my $explicit_width = $explicit_widths->[$idx];
        my $known_width = $widths->{$field};

        confess "extract explicit width for '$field' conflicts with known width\n"
            if defined($explicit_width)
                && defined($known_width)
                && $known_width > 0
                && $explicit_width != $known_width;

        $field_widths[$idx] = defined($explicit_width) ? $explicit_width : $known_width;
        confess "extract width for '$field' is unknown; add an interface width or '(widths ...)' option\n"
            unless defined($field_widths[$idx]) && $field_widths[$idx] > 0;
        $total_field_width += $field_widths[$idx];
    }

    my $word_width = $widths->{$word};
    confess "extract field widths sum $total_field_width conflicts with known width $word_width for '$word'\n"
        if defined($word_width) && $word_width > 0 && $word_width != $total_field_width;

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
    return '(' . join(' ', map { _format_isf_expr($_) } @$expr) . ')';
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
    my ($cl, $tn, $i, $actor, $widths, $counters, $seen_contracts) = @_;
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
sub _ir_do       { my ($cl,$tn,$i)=@_; my $c=$cl->[1]; {name=>"${tn}_do_$i",kind=>'await',assignments=>[{lhs=>"${c}_start",rhs=>1,op=>'=',source_kind=>'do_start'}],transitions=>[],guard=>{port=>"${c}_done"}} }
sub _ir_spawn    { my ($cl,$tn,$i)=@_; my $inst=$cl->[3]||"${tn}_$i"; {name=>"${tn}_spawn_$i",kind=>'sequential',assignments=>[{lhs=>"${inst}_start",rhs=>1,op=>'=',source_kind=>'spawn_start'}],transitions=>[]} }
sub _ir_when     { my ($cl,$tn,$i)=@_; {name=>"${tn}_when_$i",kind=>'branch',condition=>$cl->[1],body_clauses=>[@{$cl}[2..$#$cl]],assignments=>[],transitions=>[]} }
sub _expand_when { my ($cl,$tn,$ir,$ps,$drives,$wd,$widths,$counters,$storage_roles)=@_; my @s; my $bstate=_ir_when($cl,$tn,$$ir++); push @s,$bstate; my @body_states; my @lp;
    for my $bc(@{$bstate->{body_clauses}}){next unless ref($bc)eq'ARRAY';my$bk=$bc->[0];
        if($bk eq'drive'){my$n=$bc->[1];confess qq{drive $n not defined} unless !ref($n)&&$drives->{$n};push @body_states,_ir_named_drive_call($bc,$tn,$$ir++,$drives->{$n},[splice @lp])}
        elsif($bk eq'await'){push @body_states,_ir_await($bc,$tn,$$ir++,$wd,[splice @lp])}
        elsif($bk eq'sample'){push @lp,$bc}
        elsif($bk eq'complete'){push @body_states,_ir_complete($bc,$tn,$$ir++)}
        elsif($bk eq'repeat'){my($rs,$rc,$rw)=_ir_repeat($bc,$tn,$ir,\@lp,$wd,$drives,$widths);push @body_states,@$rs;_register_counter_width($counters,$rc,$rw) if $counters;$storage_roles->{$rc}='repeat_counter' if ref($storage_roles)eq'HASH'}
        elsif($bk eq'update'||$bk eq'shift_left'||$bk eq'shift_right'||$bk eq'assemble'||$bk eq'extract'){_push_sample_state(\@body_states,$tn,\@lp,$ir);push @body_states,_ir_data_op($bk,$bc,$tn,$$ir++,$widths)}
        elsif($bk eq'when'){my($ws)=_expand_when($bc,$tn,$ir,\@lp,$drives,$wd,$widths,$counters,$storage_roles);push @body_states,@$ws}}
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

sub _expand_switch { my ($cl,$tn,$ir,$ps,$drives,$wd,$widths,$counters,$storage_roles)=@_; my $signal=$cl->[1]; my @branches; my @branch_state_names; my @branch_end_names; my %seen_val; my @s;
    for my $i(2..$#$cl){my$br=$cl->[$i];next unless ref($br)eq'ARRAY'&&@$br>=2;my$val=$br->[0];my@bc=@{$br}[1..$#$br];
        my $seen_key = _canonical_switch_value_key($val);
        confess "Switch '$tn': duplicate value '$val'\n" if$seen_val{$seen_key}++;my@body_states;my@lp;
        for my $bc2(@bc){next unless ref($bc2)eq'ARRAY';my$bk2=$bc2->[0];
            if($bk2 eq'drive'){my$n=$bc2->[1];confess qq{drive $n not defined} unless !ref($n)&&$drives->{$n};push @body_states,_ir_named_drive_call($bc2,$tn,$$ir++,$drives->{$n},[splice @lp])}
            elsif($bk2 eq'await'){push @body_states,_ir_await($bc2,$tn,$$ir++,$wd,[splice @lp])}
            elsif($bk2 eq'sample'){push @lp,$bc2}
            elsif($bk2 eq'repeat'){my($rs,$rc,$rw)=_ir_repeat($bc2,$tn,$ir,\@lp,$wd,$drives,$widths);push @body_states,@$rs;_register_counter_width($counters,$rc,$rw) if $counters;$storage_roles->{$rc}='repeat_counter' if ref($storage_roles)eq'HASH'}
            elsif($bk2 eq'update'||$bk2 eq'shift_left'||$bk2 eq'shift_right'||$bk2 eq'assemble'||$bk2 eq'extract'){_push_sample_state(\@body_states,$tn,\@lp,$ir);push @body_states,_ir_data_op($bk2,$bc2,$tn,$$ir++,$widths)}
            elsif($bk2 eq'when'){my($ws)=_expand_when($bc2,$tn,$ir,\@lp,$drives,$wd,$widths,$counters,$storage_roles);push @body_states,@$ws}}
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

sub _ir_repeat {
    my ($cl,$tn,$ir,$ps,$wd,$drives,$widths)=@_; my $ctr="${tn}_cnt"; my @s; my @lp;
    my $width = _repeat_count_width($cl->[1], $widths);
    push @s, {name=>"${tn}_repeat_init_".$$ir++,kind=>'sequential',assignments=>[{lhs=>$ctr,rhs=>$cl->[1],op=>'<='}],transitions=>[]};
    for my $bc(@{$cl}[2..$#$cl]){next unless ref($bc)eq'ARRAY';my $bk=$bc->[0];
        if($bk eq'drive'){my$n=$bc->[1];if(!ref($n)&&$drives->{$n}){push @s,_ir_named_drive_call($bc,$tn,$$ir++,$drives->{$n},[splice @lp])}else{push @s,_ir_drive($bc,$tn,[splice @lp],$$ir++)}}
        elsif($bk eq'await'){push @s,_ir_await($bc,$tn,$$ir++,$wd,[splice @lp])}
        elsif($bk eq'sample'){push @lp,$bc}
        elsif($bk eq'update'||$bk eq'shift_left'||$bk eq'shift_right'||$bk eq'assemble'||$bk eq'extract'){_push_sample_state(\@s,$tn,\@lp,$ir);push @s,_ir_data_op($bk,$bc,$tn,$$ir++,$widths)}}
    if(@lp){push @s,_ir_sample_state($tn,\@lp,$$ir++)}
    my $fb=$s[0]{name};
    push @s, {name=>"${tn}_repeat_check_".$$ir++,kind=>'repeat_check',assignments=>[{lhs=>$ctr,rhs=>"(- $ctr 1)",op=>'<-'}],transitions=>[],loop_target=>$fb,counter=>$ctr};
    return (\@s,$ctr,$width);
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
    my @conditions = grep {
        defined($_) && length($_) && $_ ne '1'
    } @_;

    return '1' unless @conditions;
    return $conditions[0] if @conditions == 1;
    return '(& ' . join(' ', @conditions) . ')';
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
    return $1 if $name =~ /^(.+)_(?:idle|drive|await|done|repeat|sample|max_chk|when|switch|update|shift|asm|ext|extract|do|spawn|phase|stage|contract)_/;
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
    return $1 if ($dt->{kind} // '') eq 'rule_trigger_fanin' && ($dt->{name} // '') =~ /^(.+)_trigger_fanin\z/;
    return $dt->{name};
}

sub _dt_assignment_owner_kind {
    my ($dt) = @_;
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

    for my $i(0..$#$st){my $s=$st->[$i];my $n=$i<$#$st?$st->[$i+1]{name}:undef;my $next=$branch_exit_target{$s->{name}}||$n;
        if($s->{kind}eq'entry'&&$n){push @{$s->{transitions}},{target=>$n,condition=>$s->{guard}}}
        elsif($s->{kind}eq'await'&&$next){push @{$s->{transitions}},{target=>$next,condition=>$s->{guard}};push @{$s->{transitions}},{target=>"${tn}_timeout",condition=>{signal=>$s->{watchdog}{name},op=>'=',value=>0}}}
        elsif($s->{kind}eq'stage'&&$next){push @{$s->{transitions}},{target=>$next,condition=>{port=>$s->{ready}}}}
        elsif($s->{kind}eq'repeat_check'){push @{$s->{transitions}},{target=>$s->{loop_target},condition=>{signal=>$s->{counter},op=>'!=',value=>0}};push @{$s->{transitions}},{target=>$next,condition=>{signal=>$s->{counter},op=>'=',value=>0}}if$next}
        elsif(($s->{kind}eq'sequential'||$s->{kind}eq'contract')&&$next){push @{$s->{transitions}},{target=>$next}}
        elsif($s->{kind}eq'switch'){my$skip=$s->{switch_exit_target}||$n||$e;push @{$s->{transitions}},{target=>$skip} unless $s->{has_default_branch};for my$br(@{$s->{branches}}){next if _is_default_switch_value($br->{value});push @{$s->{transitions}},{target=>$br->{body_start},condition=>{signal=>$s->{signal},value=>$br->{value}}}}}
        elsif($s->{kind}eq'branch'){my$skip=$s->{branch_exit_target}||$n||$e;push @{$s->{transitions}},{target=>$skip}}
        elsif($s->{kind}eq'sync_all'&&$next){push @{$s->{transitions}},{target=>$next}}
        elsif($s->{kind}eq'sync_any'&&$next){push @{$s->{transitions}},{target=>$next}}
        elsif($s->{kind}eq'terminal'){push @{$s->{transitions}},{target=>$e}}}
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
    my ($self, $actor, $ctrs) = @_;
    my @d;
    my %fanin_by_transaction;
    my %seen_fanin_source;

    for my $r (@{$actor->{rules} || []}) {
        my $c = $self->_rule_cond($r->{when});
        my @a;

        for my $ac (@{$r->{actions}}) {
            next unless ref($ac) eq 'ARRAY';
            my $a0 = $ac->[0];

            if ($a0 eq 'trigger') {
                my $target = $ac->[1];
                my $source = _rule_trigger_source_name($r->{name}, $target);
                push @a, { lhs => $source, rhs => 1, op => '<1', source_kind => 'rule_trigger_source' };
                $ctrs->{$source} = 1 if $ctrs;
                $ctrs->{"${target}_start"} = 1 if $ctrs;
                push @{$fanin_by_transaction{$target}}, $source
                    unless $seen_fanin_source{"$target\0$source"}++;
            } elsif ($a0 eq 'priority') {
                # Parsed metadata; arbitration enforcement is a later slice.
            } else {
                push @a, { lhs => $a0, rhs => _format_isf_expr($ac->[1]), op => '<-', source_kind => 'rule_action' };
            }
        }

        push @d, { name => $r->{name}, kind => 'rule', dte_guard => $c, assignments => \@a };
    }

    for my $target (sort keys %fanin_by_transaction) {
        my @sources = @{$fanin_by_transaction{$target}};
        my $rhs = @sources == 1 ? $sources[0] : '(| ' . join(' ', @sources) . ')';
        push @d, {
            name        => "${target}_trigger_fanin",
            kind        => 'rule_trigger_fanin',
            assignments => [{ lhs => "${target}_start", rhs => $rhs, op => '=', source_kind => 'rule_trigger_fanin' }],
        };
    }

    return @d;
}
sub _rule_trigger_source_name { my ($rule, $target) = @_; "${rule}_${target}" }
sub _rule_cond { my($self,$w)=@_; return {port=>'1'} unless $w&&ref($w)eq'ARRAY'&&@$w>=2; {port=>$w->[1]} }

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
                my $rhs = $pair->[1];
                $rhs = $param_signal{$rhs} if exists $param_signal{$rhs};
                push @assignments, {
                    lhs         => $lhs,
                    rhs         => $rhs,
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
    my ($self,$st,$ctrs,$actor)=@_;
    my %ctx = map { $_->{name} => 1 } @{$actor->{transactions}};
    my %need;
    for my $tx(@{$actor->{transactions}}){for my $cl(@{$tx->{clauses}}){next unless ref($cl)eq'ARRAY'&&$cl->[0]eq'do';$need{$cl->[1]}=1 if$ctx{$cl->[1]}}}
    for my $c (sort keys %need) {my $s="${c}_start";my $d="${c}_done";
        my($en)=grep{$_->{name}=~/^${c}_idle_/}@$st;if($en){$en->{guard}={port=>$s};$en->{transitions}=[];my($nx)=grep{$_->{name}=~/^${c}_/&&$_->{kind}ne'entry'&&$_->{name}!~/_timeout$/}@$st;push @{$en->{transitions}},{target=>$nx->{name},condition=>$en->{guard}}if$nx}
        my($tm)=grep{$_->{name}=~/^${c}_(?:done|complete)_/&&$_->{kind}eq'terminal'}@$st;unshift @{$tm->{assignments}},{lhs=>$d,rhs=>1,op=>'<1'}if$tm}
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
