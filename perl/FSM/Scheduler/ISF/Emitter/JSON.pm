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

    my $report = $self->report_hash($ir);
    my $json = $self->emit_report_hash($report);
    fsm_trace_exit('Emitter::JSON emit', 2);
    return $json;
}

sub report_hash($self, $ir) {
    my $report = {
        schema_version => 1,
        source         => $ir->{actor_name} . '.isf',
        scheduled_fsm  => $ir->{actor_name} . '.fsm',
        clock          => $ir->{clock},
        reset          => $self->_reset_summary($ir->{reset}),
        watchdog       => $ir->{watchdog},
        actor_phases   => $self->_actor_metadata_summary($ir, 'actor_phases'),
        actor_stages   => $self->_actor_metadata_summary($ir, 'actor_stages'),
        actor_params    => $self->_actor_param_summary($ir),
        actor_constants => $self->_actor_constant_summary($ir),
        port_count     => scalar(@{$ir->{ports}}),
        inputs         => scalar(grep { $_->{direction} eq 'input'  } @{$ir->{ports}}),
        outputs        => scalar(grep { $_->{direction} eq 'output' } @{$ir->{ports}}),
        state_count    => scalar(@{$ir->{states}}),
        inferred_storage => $self->_storage_summary($ir),
        transactions   => $self->_transaction_summary($ir),
        transaction_waits => $self->_transaction_wait_summary($ir),
        transaction_loops => $self->_transaction_loop_summary($ir),
        loop_early_exits => $self->_loop_early_exit_summary($ir),
        transaction_stages => $self->_transaction_stage_summary($ir),
        temporal_contracts => $self->_temporal_contract_summary($ir),
        bank_accesses  => $self->_bank_access_summary($ir),
        transaction_port_bindings => $self->_transaction_port_binding_summary($ir),
        dt_blocks      => $self->_dt_summary($ir),
        actor_network  => $self->_actor_network_summary($ir),
        generated_composition => $self->_generated_composition_summary($ir),
        library_uses   => $self->_library_use_summary($ir),
        compatible_fanin_groups => $self->_compatible_fanin_group_summary($ir),
        priority_resolutions => $self->_priority_resolution_summary($ir),
        resource_arbitration => $self->_resource_arbitration_summary($ir),
        compile_issues => $self->_compile_issue_summary($ir),
        clock_domains => $self->_clock_domain_summary($ir),
        crossings     => $self->_crossing_summary($ir),
    };

    return $report;
}

sub multi_domain_report_hash($self, $ir, $domain_report_by_name) {
    my $partition = $ir->{domain_partition} || {};
    my $report = $self->report_hash($ir);
    my ($top_inputs, $top_outputs) = _multi_domain_top_port_counts($partition);

    $report->{scheduled_fsm} = $partition->{top_fsm} // "$ir->{actor_name}_top.fsm";
    $report->{port_count} = $top_inputs + $top_outputs;
    $report->{inputs} = $top_inputs;
    $report->{outputs} = $top_outputs;
    $report->{state_count} = 0;
    $report->{inferred_storage} = [];
    $report->{transactions} = [];
    $report->{transaction_waits} = [];
    $report->{transaction_loops} = [];
    $report->{loop_early_exits} = [];
    $report->{transaction_stages} = [];
    $report->{temporal_contracts} = [];
    $report->{bank_accesses} = [];
    $report->{transaction_port_bindings} = [];
    $report->{dt_blocks} = [];
    $report->{actor_network} = undef;
    $report->{generated_composition} = undef;
    $report->{library_uses} = [];
    $report->{compatible_fanin_groups} = [];
    $report->{priority_resolutions} = [];
    $report->{resource_arbitration} = [];
    $report->{compile_issues} = [];
    $report->{clock_domains} = $self->_clock_domain_summary($ir, $domain_report_by_name);
    $report->{crossings} = $self->_crossing_summary($ir);

    return $report;
}

sub emit_report_hash($self, $report) {
    return JSON::PP->new->ascii->canonical->pretty->encode($report);
}

sub _reset_summary($self, $reset) {
    return undef unless $reset;
    return {
        name     => $reset->{name},
        kind     => $reset->{kind} // 'sync',
        polarity => $reset->{polarity} // 'active_high',
    };
}

sub _clock_domain_summary($self, $ir, $domain_report_by_name = undef) {
    my $partition = $ir->{domain_partition};
    return [] unless ref($partition) eq 'HASH'
        && ref($partition->{domains}) eq 'ARRAY'
        && @{$partition->{domains}};

    my $default_domain = $partition->{default_domain};
    return [
        map {
            $self->_clock_domain_entry_summary($_, $default_domain, $domain_report_by_name)
        } @{$partition->{domains}}
    ];
}

sub _clock_domain_entry_summary($self, $domain, $default_domain, $domain_report_by_name) {
    my $domain_report = ref($domain_report_by_name) eq 'HASH'
        ? $domain_report_by_name->{$domain->{name}}
        : undef;

    return {
        name          => $domain->{name},
        default       => ($domain->{name} // '') eq ($default_domain // '') ? JSON::PP::true : JSON::PP::false,
        clock         => $domain->{clock},
        reset         => $self->_reset_summary($domain->{reset}),
        scheduled_fsm => $domain->{scheduled_fsm},
        ports         => {
            inputs  => [@{$domain->{ports}{inputs} || []}],
            outputs => [@{$domain->{ports}{outputs} || []}],
        },
        storage       => [@{$domain->{storage} || []}],
        transactions  => [@{$domain->{transactions} || []}],
        rules         => [@{$domain->{rules} || []}],
        library_uses  => [@{$domain->{library_uses} || []}],
        child_instances => [
            map { _clock_domain_child_instance_summary($_) }
            @{$domain->{child_instances} || []}
        ],
        crossings     => [
            map { _clock_domain_crossing_endpoint_summary($_) }
            @{$domain->{crossings} || []}
        ],
        state_count    => ref($domain_report) eq 'HASH' ? $domain_report->{state_count} : undef,
        dt_block_count => ref($domain_report) eq 'HASH' && ref($domain_report->{dt_blocks}) eq 'ARRAY'
            ? scalar(@{$domain_report->{dt_blocks}})
            : undef,
    };
}

sub _clock_domain_child_instance_summary($instance) {
    return {
        kind     => $instance->{kind},
        owner    => $instance->{owner},
        child    => $instance->{child},
        instance => $instance->{instance},
    };
}

sub _clock_domain_crossing_endpoint_summary($endpoint) {
    return {
        activation => $endpoint->{activation},
        role       => $endpoint->{role},
        start      => $endpoint->{start},
        done       => $endpoint->{done},
    } if exists $endpoint->{activation};
    return {
        event  => $endpoint->{event},
        role   => $endpoint->{role},
        signal => $endpoint->{signal},
        ready  => exists($endpoint->{ready}) ? $endpoint->{ready} : undef,
    };
}

sub _crossing_summary($self, $ir) {
    my $partition = $ir->{domain_partition};
    return [] unless ref($partition) eq 'HASH' && ref($partition->{crossings}) eq 'ARRAY';

    return [
        map { _crossing_event_summary($_, $partition) }
        @{$partition->{crossings}}
    ];
}

sub _crossing_event_summary($crossing, $partition) {
    return _crossing_activation_summary($crossing, $partition)
        if ($crossing->{kind} // '') eq 'activation';
    return {
        name               => $crossing->{name},
        kind               => $crossing->{kind},
        source_domain      => $crossing->{source_domain},
        source_signal      => $crossing->{source_signal},
        destination_domain => $crossing->{destination_domain},
        destination_signal => $crossing->{destination_signal},
        ready_signal       => $crossing->{ready_signal},
        instance           => $crossing->{instance},
        module             => $crossing->{module},
        outstanding_policy => $crossing->{outstanding_policy},
        payload            => $crossing->{payload},
        top_fsm            => $partition->{top_fsm},
    };
}

# Cross-domain activation crossing: a distinct report shape from the event
# crossing — one declaration owns two CDC children (a start synchronizer
# SRC->DST and a done synchronizer DST->SRC).
sub _crossing_activation_summary($crossing, $partition) {
    return {
        name               => $crossing->{name},
        kind               => 'activation',
        child              => $crossing->{child},
        source_domain      => $crossing->{source_domain},
        destination_domain => $crossing->{destination_domain},
        start_signal       => $crossing->{start_signal},
        done_signal        => $crossing->{done_signal},
        start_instance     => $crossing->{start_instance},
        start_module       => $crossing->{start_module},
        done_instance      => $crossing->{done_instance},
        done_module        => $crossing->{done_module},
        outstanding_policy => $crossing->{outstanding_policy},
        payload            => $crossing->{payload},
        top_fsm            => $partition->{top_fsm},
    };
}

sub _multi_domain_top_port_counts($partition) {
    my (%input, %output);

    for my $domain (@{$partition->{domains} || []}) {
        $input{$domain->{clock}} = 1 if defined($domain->{clock}) && !ref($domain->{clock}) && length($domain->{clock});
        if (ref($domain->{reset}) eq 'HASH') {
            my $reset = $domain->{reset}{name};
            $input{$reset} = 1 if defined($reset) && !ref($reset) && length($reset);
        }
        $input{$_} = 1 for @{$domain->{ports}{inputs} || []};
        $output{$_} = 1 for @{$domain->{ports}{outputs} || []};
    }

    return (scalar(keys %input), scalar(keys %output));
}

sub _actor_constant_summary($self, $ir) {
    return [
        map {
            {
                name  => $_->{name},
                value => _format_isf_value($_->{value}),
            }
        } @{$ir->{constants} || []}
    ];
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
            $entry{type} = $signal->{type}
                if defined($signal->{type}) && !ref($signal->{type}) && length($signal->{type});
            my $type_kind = _declared_type_kind($signal->{type_spec});
            $entry{type_kind} = $type_kind if defined $type_kind;
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
    return 'rule_trigger_source' if $source_kind eq 'rule_trigger_source';
    return 'rule_trigger_payload_source' if $source_kind eq 'rule_trigger_payload_source';
    return 'atl_trigger_start_handoff'
        if $source_kind eq 'atl_actor_transaction_trigger'
            || $source_kind eq 'atl_actor_transaction_trigger_batch';
    return 'scheduler_error_status' if $source_kind eq 'timeout_status';
    return 'data_register' if $source_kind eq 'update'
        || $source_kind eq 'set'
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

sub _declared_type_kind {
    my ($type_spec) = @_;
    return undef unless ref($type_spec) eq 'HASH';
    my $kind = $type_spec->{kind};
    return undef unless defined($kind) && !ref($kind) && length($kind);
    return $kind;
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
        my ($tx_name) = ($s->{name} =~ /^(\w+?)_(?:idle|drive|await|atl_trigger|atl_trigger_batch|done|repeat|sample|max_chk|when|switch|update|set|shift|asm|ext|extract|store|load|do|spawn|phase|stage|assert|cover|assume|wait|while|until)_/);
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
        my $count_kind = $state->{wait_count_kind} // 'static';
        my $is_runtime_count = _is_runtime_wait_count_kind($count_kind);
        my $counter_signal = $is_runtime_count
            ? $state->{wait_counter}
            : undef;
        my $counter_width = $is_runtime_count
            ? $state->{wait_counter_width}
            : undef;
        push @waits, {
            transaction    => $transaction,
            cycles         => $is_runtime_count
                ? undef
                : 0 + ($state->{wait_cycles} // scalar(@wait_states)),
            count_kind     => $count_kind,
            count_source   => $state->{wait_count_source},
            entry_state    => $state->{name},
            exit_state     => $exit_state,
            counter_signal => $counter_signal,
            counter_width  => $counter_width,
        };
    }

    return \@waits;
}

sub _is_runtime_wait_count_kind($count_kind) {
    return defined($count_kind) && $count_kind =~ /\Aruntime_/;
}

sub _actor_metadata_summary($self, $ir, $key) {
    return [
        map {
            {
                name => $_->{name},
                body => _clone_report_value($_->{body} || []),
            }
        } @{$ir->{$key} || []}
    ];
}

sub _actor_param_summary($self, $ir) {
    return [
        map {
            {
                name  => $_->{name},
                value => _clone_report_value($_->{value}),
            }
        } @{$ir->{params} || []}
    ];
}

sub _transaction_loop_summary($self, $ir) {
    my @loops;

    for my $state (@{$ir->{states} || []}) {
        next unless $state->{loop_entry};
        my $kind = $state->{kind} // '';
        next unless $kind eq 'loop_while' || $kind eq 'loop_until';

        my $exit_state = undef;
        for my $transition (@{$state->{transitions} || []}) {
            my $branch = ($transition->{condition} || {})->{loop_branch};
            my $is_exit =
                (defined($branch) && $branch == 0 && $kind eq 'loop_while')
                || (defined($branch) && $branch == 1 && $kind eq 'loop_until');
            next unless $is_exit;
            $exit_state = $transition->{target};
            last;
        }

        my ($transaction) = ($state->{name} =~ /\A(.+)_(?:while|until)_/);
        push @loops, {
            transaction       => $transaction,
            kind              => $state->{loop_kind},
            condition         => $state->{loop_condition},
            entry_state       => $kind eq 'loop_until' ? $state->{loop_body_start} : $state->{name},
            decision_states   => [@{$state->{loop_decision_state_names} || []}],
            body_start        => $state->{loop_body_start},
            body_states       => [@{$state->{loop_body_state_names} || []}],
            exit_state        => $exit_state,
            body_clause_count => 0 + ($state->{loop_body_clause_count} // 0),
        };
    }

    return \@loops;
}

# ISF-LOOP-EARLY-EXIT.4: schedule-report metadata for `(exit-when COND)` / `(continue-when COND)`
# sites. Each is a `loop_exit_when` decision state; `kind` distinguishes them, `condition` is the
# formatted guard, and `target` is the resolved true-edge (the loop exit for exit-when, the loop's
# tail check for continue-when).
sub _loop_early_exit_summary($self, $ir) {
    my @sites;
    for my $state (@{$ir->{states} || []}) {
        next unless $state->{loop_exit_when};
        my ($transaction) = ($state->{name} =~ /\A(.+)_(?:exit|continue)_when_[0-9]+\z/);
        push @sites, {
            transaction => $transaction,
            kind        => ($state->{loop_continue_when} ? 'continue_when' : 'exit_when'),
            state       => $state->{name},
            condition   => $state->{exit_when_condition},
            target      => $state->{loop_exit_target},
        };
    }
    return \@sites;
}

sub _clone_report_value($value) {
    return [ map { _clone_report_value($_) } @$value ] if ref($value) eq 'ARRAY';
    return { map { $_ => _clone_report_value($value->{$_}) } keys %$value } if ref($value) eq 'HASH';
    return $value;
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
            assertion_projection => 'systemverilog_sticky_fail',
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
                actor_signal        => $_->{actor_signal},
                actor_expression    => $_->{actor_expression},
                actor_endpoint_kind => $_->{actor_endpoint_kind},
                binding_timing      => $_->{binding_timing},
                authored_timing_mode => exists($_->{authored_timing_mode})
                    ? $_->{authored_timing_mode} : undef,
                width               => $_->{width},
                instance            => exists($_->{instance}) ? $_->{instance} : undef,
                parent_port         => exists($_->{parent_port}) ? $_->{parent_port} : undef,
                child_port          => exists($_->{child_port}) ? $_->{child_port} : undef,
                start_signal        => $_->{start_signal},
                done_signal         => exists($_->{done_signal}) ? $_->{done_signal} : undef,
                trigger_source      => exists($_->{trigger_source}) ? $_->{trigger_source} : undef,
                payload_source      => exists($_->{payload_source}) ? $_->{payload_source} : undef,
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

sub _actor_network_summary($self, $ir) {
    my $network = $ir->{actor_network};
    return undef unless ref($network) eq 'HASH'
        && ref($network->{instances}) eq 'ARRAY'
        && @{$network->{instances}};

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
        groups => [
            map {
                {
                    name        => $_->{name},
                    members     => [ @{$_->{members} || []} ],
                    mode        => $_->{mode},
                    declaration => $_->{declaration},
                    source      => $_->{source},
                    scheduling  => $_->{scheduling},
                }
            } @{$network->{groups} || []}
        ],
        generated_tops => [
            map { _actor_network_generated_top_summary($_) } @{$network->{generated_tops} || []}
        ],
        group_schedules => [
            map {
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
            } @{$network->{group_schedules} || []}
        ],
        association_schedules => [
            map {
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
            } @{$network->{association_schedules} || []}
        ],
        event_waits => [
            map {
                {
                    transaction => $_->{transaction},
                    context     => $_->{context},
                    instance    => $_->{instance},
                    event       => $_->{event},
                    signal      => $_->{signal},
                    source      => $_->{source},
                }
            } @{$network->{event_waits} || []}
        ],
        transaction_triggers => [
            map {
                {
                    owner_transaction  => $_->{owner_transaction},
                    context            => $_->{context},
                    instance           => $_->{instance},
                    target_transaction => $_->{target_transaction},
                    signal             => $_->{signal},
                    sink               => $_->{sink},
                }
            } @{$network->{transaction_triggers} || []}
        ],
        data_movements => [
            map {
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
            } @{$network->{data_movements} || []}
        ],
    };
}

sub _actor_network_generated_top_summary($top) {
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

sub _generated_composition_summary($self, $ir) {
    my @spawn_instances = @{$ir->{spawn_instances} || []};
    return undef unless @spawn_instances;

    my $actor_name = $ir->{actor_name};
    my $children = $ir->{children} || {};

    my %spawn_child = map { $_->{child} => 1 } @spawn_instances;
    my $has_non_spawn_activation = grep {
        ($_->{activation_kind} // 'spawn') ne 'spawn'
    } @spawn_instances;
    my $composition_kind = $has_non_spawn_activation
        ? 'activation_generated_top'
        : 'spawn_generated_top';

    return {
        kind       => $composition_kind,
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
        activation_kind    => $spawn->{activation_kind} // 'spawn',
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
                members       => [@{$_->{members} || []}],
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
