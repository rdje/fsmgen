package FSM::Scheduler::ISF::LoweringIR;

use v5.20;
use strict;
use warnings;
use feature qw(signatures postderef);
no warnings 'experimental::signatures';

# Structured Intermediate Representation for lowered .isf actors.
# No strings — typed objects consumed by emitters.

# === IR node types ===
#
# Module:
#   { actor_name, clock, reset, watchdog, ports => [...], states => [...],
#     dt_blocks => [...], counters => {...}, extra_dts => [...] }
#
# Port:
#   { name, direction => 'input'|'output', width }
#
# State:
#   { name, kind => 'entry'|'sequential'|'await'|'terminal'|'repeat_check',
#     assignments => [{ lhs, rhs, op => '='|'<-'|'<='|'<-='|'--' },
#     guard => { port, negated },     # for entry states
#     samples => [{ port, as_name }], # for entry/sequential
#     transitions => [{ target, condition => undef|{port, negated}|{signal, op, value} }],
#     loop_target,                    # for repeat_check
#     counter,                        # for repeat_check
#     watchdog => { name, limit },    # for await
#   }
#
# DTBlock:
#   { name, kind => 'rule'|'latency_counter',
#     assignments => [{ lhs, rhs, op, guard => { port, negated } }],
#   }
#
# Counter:
#   { name, width }

sub new($class, %args) {
    return bless { debug => ($args{debug} // 0) }, $class;
}

sub build_module($self, $actor) {
    my $name     = $actor->{actor_name};
    my $watchdog = $actor->{watchdog};
    my $iface    = $actor->{interface};
    my @ports;
    my @states;
    my @dt_blocks;
    my %counters;

    # Build ports from interface
    for my $p (@{$iface->{inputs}}) {
        push @ports, { name => $p->{name}, direction => 'input', width => $p->{width} // 1 };
    }
    for my $p (@{$iface->{outputs}}) {
        push @ports, { name => $p->{name}, direction => 'output', width => $p->{width} // 1 };
    }

    # Build states from transactions
    my $tx_idx = 0;
    for my $tx (@{$actor->{transactions}}) {
        my ($tx_states, $tx_counters, $tx_dts, $do_children) =
            $self->_build_transaction($tx, $actor, $tx_idx++);
        push @states, @$tx_states;
        while (my ($k, $v) = each %$tx_counters) { $counters{$k} = $v; }
        push @dt_blocks, @$tx_dts;
        for my $child (@$do_children) {
            $counters{"${child}_start"} = 1;
            $counters{"${child}_done"}  = 1;
        }
    }

    # Build DT blocks from rules
    push @dt_blocks, $self->_build_rules($actor);

    # Post-process: wire do-children start/done handshake
    $self->_wire_do_children(\@states, \%counters, $actor);

    return {
        actor_name => $name,
        clock      => $actor->{clock},
        reset      => $actor->{reset},
        watchdog   => $watchdog,
        ports      => \@ports,
        states     => \@states,
        dt_blocks  => \@dt_blocks,
        counters   => \%counters,
    };
}

# --- Transaction → IR states ---

sub _build_transaction($self, $tx, $actor, $tx_idx) {
    my $tx_name    = $tx->{name};
    my $handshakes = $actor->{handshakes};
    my $watchdog   = $actor->{watchdog};
    my @states;
    my %counters;
    my @dts;
    my @pending_samples;
    my $state_idx     = 0;
    my $has_await     = 0;
    my $wd_counter;
    my $latency;
    my @do_children;           # child tx names from (do ...)

    for my $clause (@{$tx->{clauses}}) {
        next unless ref($clause) eq 'ARRAY';
        my $kind = $clause->[0];

        if ($kind eq 'on') {
            push @states, $self->_ir_on($clause, $tx_name, $handshakes, $state_idx++);
        }
        elsif ($kind eq 'drive') {
            push @states, $self->_ir_drive($clause, $tx_name, [splice @pending_samples], $state_idx++);
        }
        elsif ($kind eq 'await') {
            $has_await = 1;
            $wd_counter = "${tx_name}_wd";
            push @states, $self->_ir_await($clause, $tx_name, $state_idx++, $watchdog);
        }
        elsif ($kind eq 'sample') {
            push @pending_samples, $clause;
        }
        elsif ($kind eq 'complete') {
            push @states, $self->_ir_complete($clause, $tx_name, $state_idx++);
        }
        elsif ($kind eq 'repeat') {
            my ($rs, $rc) = $self->_ir_repeat($clause, $tx_name, \$state_idx, \@pending_samples, $watchdog);
            push @states, @$rs;
            $counters{$rc} = 8;
        }
        elsif ($kind eq 'latency') {
            $latency = $self->_parse_latency($clause);
        }
        elsif ($kind eq 'do') {
            my $child = $clause->[1];
            push @do_children, $child;
            push @states, $self->_ir_do($clause, $tx_name, $state_idx++);
        }
        elsif ($kind eq 'spawn' || $kind eq 'await_all' || $kind eq 'await_any') {
            push @states, $self->_ir_placeholder($clause, $tx_name, $state_idx++);
        }
    }

    if (@pending_samples) {
        push @states, $self->_ir_sample_state($tx_name, \@pending_samples, $state_idx++);
    }

    # Watchdog
    if ($has_await && $wd_counter) {
        my $limit = $watchdog // 65536;
        my $wd_bits = int(log($limit) / log(2)) + 1;
        $counters{$wd_counter} = $wd_bits;
        $self->_inject_watchdog(\@states, $tx_name, $wd_counter, $limit);
    }

    # Latency
    if ($latency) {
        my ($cc, $inc, $err, $cc_dt) = $self->_inject_latency(\@states, $tx_name, $latency, $has_await);
        $counters{$cc}  = int(log($latency->{max} // 256) / log(2)) + 1;
        $counters{$inc} = 1;
        $counters{$err} = 1;
        push @dts, $cc_dt;
    }

    # Link transitions
    $self->_link_state_transitions(\@states, $tx_name);

    return (\@states, \%counters, \@dts, \@do_children);
}

# --- Individual clause → IR ---

sub _ir_on($self, $clause, $tx_name, $handshakes, $idx) {
    my $hs_name = $clause->[1];
    my $hs = $handshakes->{$hs_name};
    my @samples;
    for my $i (2 .. $#$clause) {
        my $sub = $clause->[$i];
        next unless ref($sub) eq 'ARRAY' && $sub->[0] eq 'sample';
        push @samples, { port => $sub->[1], as_name => $sub->[3] };
    }
    return {
        name    => "${tx_name}_idle_$idx",
        kind    => 'entry',
        guard   => { port => $hs->{valid} },
        samples => \@samples,
        assignments => [],
        transitions => [],
    };
}

sub _ir_drive($self, $clause, $tx_name, $samples, $idx) {
    my @assignments;
    for my $s (@$samples) {
        # $s is a raw (sample port as name) clause
        push @assignments, { lhs => $s->[3], rhs => $s->[1], op => '<=' };
    }
    for my $i (2 .. $#$clause) {
        my $a = $clause->[$i];
        next unless ref($a) eq 'ARRAY' && $a->[0] eq 'assign';
        push @assignments, { lhs => $a->[1], rhs => $a->[2], op => '=' };
    }
    return {
        name        => "${tx_name}_drive_$idx",
        kind        => 'sequential',
        assignments => \@assignments,
        transitions => [],
    };
}

sub _ir_await($self, $clause, $tx_name, $idx, $watchdog) {
    return {
        name        => "${tx_name}_await_$idx",
        kind        => 'await',
        assignments => [],
        transitions => [],
        guard       => { port => $clause->[1] },
        watchdog    => { name => "${tx_name}_wd", limit => $watchdog // 65536 },
    };
}

sub _ir_complete($self, $clause, $tx_name, $idx) {
    return {
        name        => "${tx_name}_done_$idx",
        kind        => 'terminal',
        assignments => [{ lhs => $clause->[1], rhs => 1, op => '=' }],
        transitions => [],
    };
}

sub _ir_sample_state($self, $tx_name, $samples, $idx) {
    my @assignments;
    for my $s (@$samples) {
        push @assignments, { lhs => $s->[3], rhs => $s->[1], op => '<=' };
    }
    return {
        name        => "${tx_name}_sample_$idx",
        kind        => 'sequential',
        assignments => \@assignments,
        transitions => [],
    };
}

sub _ir_placeholder($self, $clause, $tx_name, $idx) {
    return {
        name        => "${tx_name}_$clause->[0]_$idx",
        kind        => 'sequential',
        assignments => [],
        transitions => [],
    };
}

sub _ir_do($self, $clause, $tx_name, $idx) {
    my $child  = $clause->[1];
    my $start  = "${child}_start";
    my $done   = "${child}_done";

    return {
        name        => "${tx_name}_do_$idx",
        kind        => 'await',
        assignments => [{ lhs => $start, rhs => 1, op => '=' }],
        transitions => [],
        guard       => { port => $done },
    };
}

sub _ir_repeat($self, $clause, $tx_name, $idx_ref, $pending, $watchdog) {
    my $counter = "${tx_name}_cnt";
    my @states;
    my @local_pending;

    # Init state
    push @states, {
        name        => "${tx_name}_repeat_init_" . $$idx_ref++,
        kind        => 'sequential',
        assignments => [{ lhs => $counter, rhs => $clause->[1], op => '<=' }],
        transitions => [],
    };

    # Body
    for my $bc (@{$clause}[2 .. $#$clause]) {
        next unless ref($bc) eq 'ARRAY';
        my $bk = $bc->[0];
        if ($bk eq 'drive') {
            push @states, $self->_ir_drive($bc, $tx_name, [splice @local_pending], $$idx_ref++);
        }
        elsif ($bk eq 'await') {
            push @states, $self->_ir_await($bc, $tx_name, $$idx_ref++, $watchdog);
        }
        elsif ($bk eq 'sample') {
            push @local_pending, $bc;
        }
    }
    if (@local_pending) {
        push @states, $self->_ir_sample_state($tx_name, \@local_pending, $$idx_ref++);
    }

    # Check state
    my $first_body = $states[0]{name};
    push @states, {
        name        => "${tx_name}_repeat_check_" . $$idx_ref++,
        kind        => 'repeat_check',
        assignments => [{ lhs => $counter, rhs => "(- $counter 1)", op => '<-' }],
        transitions => [],
        loop_target => $first_body,
        counter     => $counter,
    };

    return (\@states, $counter);
}

# --- Post-processing ---

sub _link_state_transitions($self, $states, $tx_name) {
    return unless @$states;
    my $entry = $states->[0]{name};
    for my $i (0 .. $#$states) {
        my $s   = $states->[$i];
        my $next = ($i < $#$states) ? $states->[$i+1]{name} : undef;

        if ($s->{kind} eq 'entry' && $next) {
            push @{$s->{transitions}}, { target => $next, condition => $s->{guard} };
        }
        elsif ($s->{kind} eq 'await' && $next) {
            push @{$s->{transitions}}, { target => $next, condition => $s->{guard} };
            push @{$s->{transitions}}, { target => "${tx_name}_timeout", condition => { signal => $s->{watchdog}{name}, op => '=', value => 0 } };
        }
        elsif ($s->{kind} eq 'repeat_check') {
            push @{$s->{transitions}}, { target => $s->{loop_target}, condition => { signal => $s->{counter}, op => '!=', value => 0 } };
            push @{$s->{transitions}}, { target => $next, condition => { signal => $s->{counter}, op => '=', value => 0 } } if $next;
        }
        elsif ($s->{kind} eq 'sequential' && $next) {
            push @{$s->{transitions}}, { target => $next };
        }
        elsif ($s->{kind} eq 'terminal') {
            push @{$s->{transitions}}, { target => $entry };
        }
    }
}

sub _inject_watchdog($self, $states, $tx_name, $wd_name, $limit) {
    my $entry = $states->[0];
    unshift @{$entry->{assignments}}, { lhs => $wd_name, rhs => "(- $limit 1)", op => '<=' };

    push @$states, {
        name        => "${tx_name}_timeout",
        kind        => 'terminal',
        assignments => [
            { lhs => 'done', rhs => 1, op => '=' },
            { lhs => 'last_error', rhs => 1, op => '=' },
        ],
        transitions => [],
    };
}

sub _inject_latency($self, $states, $tx_name, $latency, $has_await) {
    my $cc  = "${tx_name}_cc";
    my $inc = "${tx_name}_inc";
    my $err = "${tx_name}_lerr";
    my $min = $latency->{min} // 1;
    my $max = $latency->{max} // 256;

    # Counter reset in entry
    unshift @{$states->[0]{assignments}}, { lhs => $cc, rhs => 0, op => '<-' };

    # inc=1 in all active states
    for my $s (@$states) {
        next if $s->{kind} eq 'entry' || $s->{kind} eq 'terminal' || $s->{name} =~ /_timeout$/;
        unshift @{$s->{assignments}}, { lhs => $inc, rhs => 1, op => '=' };
    }

    # Min check in non-timeout terminal
    my ($done) = grep { $_->{kind} eq 'terminal' && $_->{name} !~ /_timeout$/ } @$states;
    if ($done) {
        push @{$done->{assignments}},
            { lhs => $err, rhs => 1, op => '=', guard => { signal => $cc, op => '<', value => $min } };
    }

    # Max check if no await
    if (!$has_await && $max) {
        my $max_chk = "${tx_name}_max_chk";
        push @$states, {
            name        => $max_chk,
            kind        => 'sequential',
            assignments => [],
            transitions => [{ target => "${tx_name}_timeout",
                              condition => { signal => $cc, op => '=', value => $max } }],
        };
        push @$states, {
            name        => "${tx_name}_timeout",
            kind        => 'terminal',
            assignments => [
                { lhs => $err, rhs => 1, op => '=' },
                { lhs => 'done', rhs => 1, op => '=' },
                { lhs => 'last_error', rhs => 1, op => '=' },
            ],
            transitions => [],
        };
    }

    # Comb DT for cycle counter
    my $dt = {
        name => "${tx_name}_cc_inc",
        kind => 'latency_counter',
        assignments => [{ lhs => $cc, rhs => "(+ $cc 1)", op => '<-', guard => { port => $inc } }],
    };

    return ($cc, $inc, $err, $dt);
}

# --- Rules → IR ---

sub _build_rules($self, $actor) {
    my @dts;
    for my $rule (@{$actor->{rules} || []}) {
        my $name    = $rule->{name};
        my $cond    = $self->_rule_condition($rule->{when});
        my @assignments;

        for my $action (@{$rule->{actions}}) {
            next unless ref($action) eq 'ARRAY';
            my $ak = $action->[0];
            if ($ak eq 'assign') {
                my ($kw, $port, $value) = @$action;
                push @assignments, { lhs => $port, rhs => $value, op => '=', guard => $cond };
            }
            elsif ($ak eq 'assert' || $ak eq 'pulse') {
                push @assignments, { lhs => $action->[1], rhs => 1, op => '=', guard => $cond };
            }
            elsif ($ak eq 'trigger') {
                push @assignments, { lhs => "$action->[1]_start", rhs => 1, op => '=', guard => $cond };
            }
        }

        push @dts, { name => $name, kind => 'rule', assignments => \@assignments };
    }
    return @dts;
}

sub _rule_condition($self, $when) {
    return { port => '1' } unless $when && ref($when) eq 'ARRAY' && @$when >= 2;
    return { port => $when->[1] };
}

sub _parse_latency($self, $clause) {
    my %r;
    for my $i (1 .. $#$clause) {
        my $item = $clause->[$i];
        next unless ref($item) eq 'ARRAY' && @$item >= 2;
        $r{$item->[0]} = $item->[1] if $item->[0] eq 'min' || $item->[0] eq 'max';
    }
    return \%r;
}

sub _wire_do_children($self, $states, $counters, $actor) {
    # Collect child names that have their own transactions in this actor
    my %child_tx = map { $_->{name} => $_ } @{$actor->{transactions}};

    # Find do-children referenced by parent transactions
    my %needs_handshake;
    for my $tx (@{$actor->{transactions}}) {
        for my $clause (@{$tx->{clauses}}) {
            next unless ref($clause) eq 'ARRAY' && $clause->[0] eq 'do';
            my $child = $clause->[1];
            $needs_handshake{$child} = 1 if $child_tx{$child};
        }
    }

    # For each child that needs handshake, modify its entry and done states
    for my $child (keys %needs_handshake) {
        my $start = "${child}_start";
        my $done  = "${child}_done";

        # Find child's entry state and change its guard to watch start
        my ($entry) = grep { $_->{name} =~ /^${child}_idle_/ } @$states;
        if ($entry) {
            $entry->{guard} = { port => $start };
            # Rebuild transitions for the new guard
            $entry->{transitions} = [];
            my ($next) = grep { $_->{name} =~ /^${child}_drive_/ } @$states;
            push @{$entry->{transitions}}, { target => $next->{name}, condition => $entry->{guard} }
                if $next;
        }

        # Find child's terminal state and add done pulse
        my ($terminal) = grep { $_->{name} =~ /^${child}_(?:done|complete)_/ && $_->{kind} eq 'terminal' } @$states;
        if ($terminal) {
            unshift @{$terminal->{assignments}}, { lhs => $done, rhs => 1, op => '=' };
        }
    }
}

1;
