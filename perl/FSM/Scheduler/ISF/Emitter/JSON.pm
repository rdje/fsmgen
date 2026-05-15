package FSM::Scheduler::ISF::Emitter::JSON;

use v5.20;
use strict;
use warnings;
use feature qw(signatures postderef);
no warnings 'experimental::signatures';
use JSON::PP ();
use FSM::Debug;

# Emits JSON schedule report from LoweringIR.
# Consumes the same IR as Emitter::FSM — no string coupling.

sub new($class, %args) { bless {}, $class }

sub emit($self, $ir) {
    fsm_trace_enter('Emitter::JSON emit', 2);

    my $report = {
        source         => $ir->{actor_name} . '.isf',
        scheduled_fsm  => $ir->{actor_name} . '.fsm',
        clock          => $ir->{clock},
        reset          => $self->_reset_summary($ir->{reset}),
        watchdog       => $ir->{watchdog},
        port_count     => scalar(@{$ir->{ports}}),
        inputs         => scalar(grep { $_->{direction} eq 'input'  } @{$ir->{ports}}),
        outputs        => scalar(grep { $_->{direction} eq 'output' } @{$ir->{ports}}),
        state_count    => scalar(@{$ir->{states}}),
        inferred_storage => $self->_storage_summary($ir),
        transactions   => $self->_transaction_summary($ir),
        transaction_waits => $self->_transaction_wait_summary($ir),
        transaction_stages => $self->_transaction_stage_summary($ir),
        temporal_contracts => $self->_temporal_contract_summary($ir),
        bank_accesses  => $self->_bank_access_summary($ir),
        transaction_port_bindings => $self->_transaction_port_binding_summary($ir),
        dt_blocks      => $self->_dt_summary($ir),
        generated_composition => $self->_generated_composition_summary($ir),
        library_uses   => $self->_library_use_summary($ir),
        compatible_fanin_groups => $self->_compatible_fanin_group_summary($ir),
        priority_resolutions => $self->_priority_resolution_summary($ir),
        resource_arbitration => $self->_resource_arbitration_summary($ir),
        compile_issues => $self->_compile_issue_summary($ir),
    };

    my $json = JSON::PP->new->ascii->canonical->pretty->encode($report);
    fsm_trace_exit('Emitter::JSON emit', 2);
    return $json;
}

sub _reset_summary($self, $reset) {
    return undef unless $reset;
    return {
        name     => $reset->{name},
        kind     => $reset->{kind} // 'sync',
        polarity => $reset->{polarity} // 'active_high',
    };
}

sub _storage_summary($self, $ir) {
    my @storage;
    my %seen;
    my %counter_widths = %{$ir->{counters} || {}};
    my %signal_widths = %{$ir->{signal_widths} || {}};
    my %storage_roles = %{$ir->{storage_roles} || {}};

    for my $declared (@{$ir->{declared_storage} || []}) {
        for my $signal (@{$declared->{signals} || []}) {
            my $name = $signal->{name};
            next if $seen{$name}++;
            my %entry = (
                name  => $name,
                kind  => 'register',
                role  => 'actor_storage',
                width => $signal->{width},
            );
            push @storage, \%entry;
        }
    }

    for my $s (@{$ir->{states}}) {
        for my $a (@{$s->{assignments}}) {
            next if $seen{$a->{lhs}}++;
            next if $a->{op} eq '=';  # combinational
            if (_is_scheduler_counter_name($a->{lhs}) && exists $counter_widths{$a->{lhs}}) {
                my %entry = (
                    name  => $a->{lhs},
                    kind  => 'counter',
                    width => $counter_widths{$a->{lhs}},
                );
                my $role = _storage_role_for_assignment($a, \%storage_roles);
                $entry{role} = $role if defined $role;
                push @storage, \%entry;
                next;
            }
            my %entry = (
                name  => $a->{lhs},
                kind  => _is_clocked_register_op($a->{op}) ? 'register' : 'counter',
            );
            my $role = _storage_role_for_assignment($a, \%storage_roles);
            $entry{role} = $role if defined $role;
            $entry{width} = $signal_widths{$a->{lhs}}
                if $entry{kind} eq 'register'
                    && exists($signal_widths{$a->{lhs}})
                    && $signal_widths{$a->{lhs}} > 0;
            push @storage, \%entry;
        }
    }

    for my $name (sort keys %counter_widths) {
        next if $seen{$name}++;
        my $contract_kind = _contract_monitor_storage_kind($name);
        next if defined($contract_kind) && $contract_kind eq 'combinational';

        my $kind = $contract_kind // 'counter';
        my %entry = (name => $name, kind => $kind);
        my $role = _storage_role_for_name($name, \%storage_roles);
        $entry{role} = $role if defined $role;
        $entry{width} = $counter_widths{$name}
            if defined($counter_widths{$name}) && $counter_widths{$name} > 0;
        push @storage, \%entry;
    }

    return \@storage;
}

sub _storage_role_for_assignment {
    my ($assignment, $storage_roles) = @_;
    my $name = $assignment->{lhs};
    my $role = _storage_role_for_name($name, $storage_roles);
    return $role if defined $role;

    my $source_kind = $assignment->{source_kind} // '';
    return 'sample_alias' if $source_kind eq 'sample_capture';
    return 'extract_field' if $source_kind eq 'extract_capture';
    return 'completion_pulse' if $source_kind eq 'complete_pulse' || $source_kind eq 'timeout_pulse';
    return 'data_register' if $source_kind eq 'update'
        || $source_kind eq 'shift'
        || $source_kind eq 'assemble';
    return undef;
}

sub _storage_role_for_name {
    my ($name, $storage_roles) = @_;
    return undef unless defined $name;
    return $storage_roles->{$name}
        if ref($storage_roles) eq 'HASH'
            && exists $storage_roles->{$name}
            && defined $storage_roles->{$name}
            && length $storage_roles->{$name};
    return undef;
}

sub _contract_monitor_storage_kind($name) {
    return undef unless defined($name) && $name =~ /_contract_[0-9]+_(arm|pending|age|fail)\z/;
    return 'combinational' if $1 eq 'arm';
    return 'counter' if $1 eq 'age';
    return 'register';
}

sub _is_scheduler_counter_name($name) {
    return $name =~ /_(?:cc|cnt|wd)\z/;
}

sub _is_clocked_register_op($op) {
    return $op eq '<=' || $op eq '<-' || $op =~ /^<\d+\z/;
}

sub _transaction_summary($self, $ir) {
    my @txs;
    my %tx_states;

    # Group states by transaction prefix
    for my $s (@{$ir->{states}}) {
        my ($tx_name) = ($s->{name} =~ /^(\w+?)_(?:idle|drive|await|done|repeat|sample|max_chk|when|switch|update|shift|asm|ext|extract|store|load|do|spawn|phase|stage|contract|wait)_/);
        ($tx_name) = ($s->{name} =~ /^(\w+)_timeout$/) unless $tx_name;
        push @{$tx_states{$tx_name}}, $s->{name};
    }

    for my $tx_name (sort keys %tx_states) {
        my $states = $tx_states{$tx_name};
        push @txs, {
            name   => $tx_name,
            states => $states,
            count  => scalar(@$states),
        };
    }

    return \@txs;
}

sub _transaction_wait_summary($self, $ir) {
    my @waits;
    my %state_by_name = map { $_->{name} => $_ } @{$ir->{states} || []};

    for my $state (@{$ir->{states} || []}) {
        next unless ($state->{kind} // '') eq 'wait';
        next unless $state->{wait_entry};

        my @wait_states = @{$state->{wait_state_names} || [$state->{name}]};
        my $last_state = $state_by_name{$wait_states[-1]};
        my $exit_state = undef;
        if ($last_state && ref($last_state->{transitions}) eq 'ARRAY' && @{$last_state->{transitions}}) {
            $exit_state = $last_state->{transitions}[0]{target};
        }

        my ($transaction) = ($state->{name} =~ /\A(.+)_wait_[0-9]+\z/);
        push @waits, {
            transaction    => $transaction,
            cycles         => 0 + ($state->{wait_cycles} // scalar(@wait_states)),
            entry_state    => $state->{name},
            exit_state     => $exit_state,
            counter_signal => undef,
        };
    }

    return \@waits;
}

sub _transaction_stage_summary($self, $ir) {
    my @stages;

    for my $state (@{$ir->{states}}) {
        next unless ($state->{kind} // '') eq 'stage';
        my ($transaction) = ($state->{name} =~ /\A(.+)_stage_[0-9]+\z/);
        push @stages, {
            transaction => $transaction,
            name        => $state->{stage_name},
            kind        => 'ready_valid_barrier',
            state       => $state->{name},
            ready       => $state->{ready},
            valid       => $state->{valid},
        };
    }

    return \@stages;
}

sub _temporal_contract_summary($self, $ir) {
    my @contracts;

    for my $contract (@{$ir->{temporal_contracts} || []}) {
        push @contracts, {
            transaction          => $contract->{transaction},
            name                 => $contract->{name},
            kind                 => $contract->{kind},
            trigger              => $contract->{trigger},
            signal               => $contract->{signal},
            within_cycles        => $contract->{within_cycles},
            pending_signal       => $contract->{pending_signal},
            counter_signal       => $contract->{counter_signal},
            fail_signal          => $contract->{fail_signal},
            overlap_policy       => $contract->{overlap_policy},
            reset_policy         => $self->_reset_summary($ir->{reset}),
            assertion_projection => 'none',
        };
    }

    return \@contracts;
}

sub _bank_access_summary($self, $ir) {
    return [
        map {
            my %entry = (
                kind              => $_->{kind},
                owner             => $_->{owner},
                owner_kind        => $_->{owner_kind},
                container_kind    => $_->{container_kind},
                container_name    => $_->{container_name},
                bank              => $_->{bank},
                index             => $_->{index},
                width             => $_->{width},
                depth             => $_->{depth},
                scalar_entries    => [ @{$_->{scalar_entries} || []} ],
                same_cycle_policy => $_->{same_cycle_policy},
                value             => exists($_->{value}) ? $_->{value} : undef,
                target            => exists($_->{target}) ? $_->{target} : undef,
            );
            \%entry;
        } @{$ir->{bank_accesses} || []}
    ];
}

sub _transaction_port_binding_summary($self, $ir) {
    return [
        map {
            {
                site_kind          => $_->{site_kind},
                owner              => $_->{owner},
                owner_kind         => $_->{owner_kind},
                target_transaction => $_->{target_transaction},
                role               => $_->{role},
                port               => $_->{port},
                actor_signal       => $_->{actor_signal},
                width              => $_->{width},
                instance           => exists($_->{instance}) ? $_->{instance} : undef,
                parent_port        => exists($_->{parent_port}) ? $_->{parent_port} : undef,
                child_port         => exists($_->{child_port}) ? $_->{child_port} : undef,
                start_signal       => $_->{start_signal},
                done_signal        => exists($_->{done_signal}) ? $_->{done_signal} : undef,
                trigger_source     => exists($_->{trigger_source}) ? $_->{trigger_source} : undef,
                payload_source     => exists($_->{payload_source}) ? $_->{payload_source} : undef,
            }
        } @{$ir->{transaction_port_bindings} || []}
    ];
}

sub _dt_summary($self, $ir) {
    my @dts;
    for my $dt (@{$ir->{dt_blocks}}) {
        push @dts, {
            name         => $dt->{name},
            kind         => $dt->{kind},
            assignments  => scalar(@{$dt->{assignments}}),
        };
    }
    return \@dts;
}

sub _generated_composition_summary($self, $ir) {
    my @spawn_instances = @{$ir->{spawn_instances} || []};
    return undef unless @spawn_instances;

    my $actor_name = $ir->{actor_name};
    my $children = $ir->{children} || {};

    my %spawn_child = map { $_->{child} => 1 } @spawn_instances;

    return {
        kind       => 'spawn_generated_top',
        top_module => "${actor_name}_top",
        top_fsm    => "${actor_name}_top.fsm",
        parent     => {
            module        => $actor_name,
            scheduled_fsm => "$actor_name.fsm",
        },
        children  => [
            map { $self->_generated_composition_child_summary($_, $children->{$_}) }
            sort keys %spawn_child
        ],
        instances => [
            map { $self->_generated_composition_instance_summary($_, $children->{$_->{child}}) }
            @spawn_instances
        ],
    };
}

sub _library_use_summary($self, $ir) {
    return [
        map {
            {
                library       => $_->{library},
                alias         => $_->{alias},
                export        => $_->{export},
                kind          => $_->{kind},
                instance      => $_->{instance},
                module        => $_->{module},
                scheduled_fsm => $_->{scheduled_fsm},
                parameters    => [
                    map {
                        {
                            name   => $_->{name},
                            source => $_->{source},
                            value  => _format_isf_value($_->{value}),
                        }
                    } @{$_->{parameters} || []}
                ],
                bindings      => [
                    map { _bounded_library_binding_summary($_) }
                    @{$_->{bindings} || []}
                ],
            }
        } @{$ir->{library_uses} || []}
    ];
}

sub _bounded_library_binding_summary($binding) {
    return {
        role         => $binding->{role},
        library_name => exists($binding->{library_name}) ? $binding->{library_name} : undef,
        parent_name  => $binding->{parent_name},
        width        => exists($binding->{width}) ? $binding->{width} : undef,
    };
}

sub _generated_composition_child_summary($self, $child_name, $child_ir) {
    $child_ir ||= {};
    return {
        transaction   => $child_name,
        module        => $child_name,
        scheduled_fsm => "$child_name.fsm",
        parameters    => [
            map {
                {
                    name    => $_->{name},
                    default => _format_isf_value($_->{value}),
                }
            } @{$child_ir->{params} || []}
        ],
    };
}

sub _generated_composition_instance_summary($self, $spawn, $child_ir) {
    my $instance = $spawn->{instance};
    my $child = $spawn->{child};

    return {
        instance           => $instance,
        child              => $child,
        start              => {
            parent_port => "${instance}_start",
            child_port  => 'start',
        },
        done               => {
            child_port  => 'done',
            parent_port => "${instance}_done",
        },
        parameter_bindings => _instance_parameter_bindings($spawn, $child_ir || {}),
        drive_handoffs     => [
            map { _bounded_drive_handoff_summary($_) }
            @{$spawn->{drive_handoffs} || []}
        ],
    };
}

sub _instance_parameter_bindings($spawn, $child_ir) {
    my %override_by_name = map { $_->{name} => $_ } @{$spawn->{parameter_overrides} || []};
    my @bindings;

    for my $param (@{$child_ir->{params} || []}) {
        my $name = $param->{name};
        my $override = $override_by_name{$name};
        push @bindings, {
            name   => $name,
            source => $override ? 'override' : 'default',
            value  => _format_isf_value($override ? $override->{value} : $param->{value}),
        };
    }

    return \@bindings;
}

sub _bounded_drive_handoff_summary($handoff) {
    return {
        drive    => $handoff->{drive},
        request  => {
            child_port  => $handoff->{request}{child_port},
            parent_port => $handoff->{request}{parent_port},
        },
        payloads => [
            map {
                {
                    parameter   => $_->{parameter},
                    child_port  => $_->{child_port},
                    parent_port => $_->{parent_port},
                    width       => $_->{width},
                }
            } @{$handoff->{payloads} || []}
        ],
    };
}

sub _compile_issue_summary($self, $ir) {
    my @issues;

    for my $issue (@{$ir->{conflict_issues} || []}) {
        next if ($issue->{severity} // '') eq 'error';
        push @issues, {
            code         => $issue->{code},
            severity     => $issue->{severity},
            target       => $issue->{target},
            domain       => $issue->{domain},
            proof_status => $issue->{proof_status},
            reason       => $issue->{reason},
            sources      => [
                map { _bounded_source_summary($_) } @{$issue->{sources} || []}
            ],
        };
    }

    return \@issues;
}

sub _compatible_fanin_group_summary($self, $ir) {
    my @groups;

    for my $group (@{$ir->{compatible_fanin_groups} || []}) {
        next if ($group->{kind} // '') eq 'same_target_value'
            && (($group->{domain} // '') eq 'request' || ($group->{domain} // '') eq 'pulse');
        my %summary = (
            kind    => $group->{kind},
            domain  => $group->{domain},
            sources => [
                map { _bounded_source_summary($_) } @{$group->{sources} || []}
            ],
        );
        for my $key (qw(target target_transaction fanin_target operator rhs)) {
            $summary{$key} = $group->{$key} if exists $group->{$key};
        }
        push @groups, \%summary;
    }

    return \@groups;
}

sub _priority_resolution_summary($self, $ir) {
    return [
        map {
            {
                target      => $_->{target},
                winner      => $_->{winner},
                winner_kind => $_->{winner_kind} // 'rule',
                loser       => $_->{loser},
                loser_kind  => $_->{loser_kind} // 'rule',
            }
        } @{$ir->{priority_resolution}{resolutions} || []}
    ];
}

sub _resource_arbitration_summary($self, $ir) {
    return [
        map {
            {
                resource      => $_->{resource},
                kind          => $_->{kind},
                arbiter       => $_->{arbiter},
                user          => $_->{user},
                user_kind     => 'rule',
                suppressed_by => [@{$_->{higher} || []}],
            }
        } @{$ir->{resource_arbitration}{grants} || []}
    ];
}

sub _bounded_source_summary($source) {
    return {
        owner       => $source->{owner},
        owner_kind  => $source->{owner_kind},
        source_kind => $source->{source_kind},
        target      => $source->{target},
        operator    => $source->{operator},
        rhs         => $source->{rhs},
        domain      => $source->{domain},
    };
}

sub _format_isf_value($value) {
    return '(' . join(' ', map { _format_isf_value($_) } @$value) . ')'
        if ref($value) eq 'ARRAY';
    return defined($value) ? "$value" : '';
}

1;
