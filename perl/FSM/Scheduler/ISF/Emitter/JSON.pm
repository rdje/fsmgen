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
        dt_blocks      => $self->_dt_summary($ir),
        generated_composition => $self->_generated_composition_summary($ir),
        compatible_fanin_groups => $self->_compatible_fanin_group_summary($ir),
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

    for my $s (@{$ir->{states}}) {
        for my $a (@{$s->{assignments}}) {
            next if $seen{$a->{lhs}}++;
            next if $a->{op} eq '=';  # combinational
            if (_is_scheduler_counter_name($a->{lhs}) && exists $counter_widths{$a->{lhs}}) {
                push @storage, {
                    name  => $a->{lhs},
                    kind  => 'counter',
                    width => $counter_widths{$a->{lhs}},
                };
                next;
            }
            push @storage, {
                name  => $a->{lhs},
                kind  => _is_clocked_register_op($a->{op}) ? 'register' : 'counter',
            };
        }
    }

    for my $name (sort keys %counter_widths) {
        next if $seen{$name}++;
        push @storage, { name => $name, kind => 'counter', width => $counter_widths{$name} };
    }

    return \@storage;
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
        my ($tx_name) = ($s->{name} =~ /^(\w+?)_(?:idle|drive|await|done|repeat|sample|max_chk|when|switch|update|shift|asm|extract|do|spawn|phase)_/);
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
            sort keys %$children
        ],
        instances => [
            map { $self->_generated_composition_instance_summary($_, $children->{$_->{child}}) }
            @spawn_instances
        ],
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
