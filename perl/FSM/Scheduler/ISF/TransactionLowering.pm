package FSM::Scheduler::ISF::TransactionLowering;

use v5.20;
use strict;
use warnings;
use Carp qw(confess);
use feature qw(signatures postderef);
no warnings 'experimental::signatures';

use FSM::Debug;
use POSIX qw(log);

# Lowers ISF transaction clauses into .fsm state decision-tree blocks.
#
# Two-phase approach:
#   1. Collect all state bodies (assignments, conditions, samples)
#   2. Link states with transitions knowing the full state list

sub new($class, %args) {
    return bless { debug => ($args{debug} // 0) }, $class;
}

sub lower_transaction($self, $tx, $actor) {
    fsm_trace_enter("TransactionLowering: $tx->{name}", 3);

    my $tx_name    = $tx->{name};
    my $handshakes = $actor->{handshakes};
    my $watchdog   = $actor->{watchdog};
    my @state_specs;            # { name, kind, body, ... }
    my @pending_samples;
    my @inferred_counters;      # counter names inferred from (repeat ...)
    my $has_await;              # tracks if transaction has any (await ...)
    my $wd_counter;             # watchdog counter name
    my $latency;                # { min, max } from (latency (min N) (max M))
    my $idx = 0;

    for my $clause (@{$tx->{clauses}}) {
        next unless ref($clause) eq 'ARRAY';
        my $kind = $clause->[0];

        if ($kind eq 'on') {
            my $spec = $self->_on_clause($clause, $tx_name, $handshakes, $idx++);
            push @state_specs, $spec if $spec;
        }
        elsif ($kind eq 'drive') {
            my $samples = [splice @pending_samples];
            push @state_specs, $self->_drive_clause($clause, $tx_name, $samples, $idx++);
        }
        elsif ($kind eq 'await') {
            $has_await = 1;
            $wd_counter = "${tx_name}_wd";
            push @state_specs, $self->_await_clause($clause, $tx_name, $idx++, $watchdog);
        }
        elsif ($kind eq 'sample') {
            push @pending_samples, $clause;
        }
        elsif ($kind eq 'complete') {
            push @state_specs, $self->_complete_clause($clause, $tx_name, $idx++);
        }
        elsif ($kind eq 'repeat') {
            my ($repeat_states, $counter) =
                $self->_repeat_clause($clause, $tx_name, \$idx, \@pending_samples, $watchdog);
            push @state_specs, @$repeat_states;
            push @inferred_counters, $counter;
        }
        elsif ($kind eq 'latency') {
            $latency = $self->_parse_latency($clause);
            fsm_debug("Transaction '$tx_name': latency min=$latency->{min} max=$latency->{max}", 3);
        }
        elsif ($kind eq 'do' || $kind eq 'spawn' || $kind eq 'await_all' || $kind eq 'await_any') {
            push @state_specs, $self->_placeholder_clause($clause, $tx_name, $idx++);
        }
    }

    # Flush pending samples as a standalone state
    if (@pending_samples) {
        push @state_specs, $self->_sample_state($tx_name, \@pending_samples, $idx++);
    }

    # Phase 2: link states with transitions — deferred until after all modifications
    # (watchdog, latency) are done

    fsm_trace_exit("TransactionLowering: $tx_name produced " . scalar(@state_specs) . " states", 3);

    my %counters;
    for my $c (@inferred_counters) { $counters{$c} = 8; }

    # Watchdog counter
    if ($has_await && $wd_counter) {
        my $limit = $watchdog // 65536;
        my $wd_bits = int(log($limit) / log(2)) + 1;
        $counters{$wd_counter} = $wd_bits;

        # Reset watchdog in entry (idle) state
        if (@state_specs && $state_specs[0]{kind} eq 'entry') {
            unshift @{$state_specs[0]{body}}, "    (<= ($wd_counter (- $limit 1)))";
        }

        # Timeout state
        my $timeout_name = "${tx_name}_timeout";
        push @state_specs, {
            name => $timeout_name,
            kind => 'terminal',
            body => ["    (= (done> 1))", "    (= (last_error> 1))"],
        };
    }

    # Latency constraint lowering
    my @extra_dts;
    if ($latency) {
        my $cc_name = "${tx_name}_cc";
        my $inc_name = "${tx_name}_inc";
        my $err_name = "${tx_name}_lerr";
        my $max = $latency->{max} // 256;
        my $min = $latency->{min} // 1;
        my $cc_bits = int(log($max) / log(2)) + 1;

        $counters{$cc_name}  = $cc_bits;
        $counters{$inc_name} = 1;
        $counters{$err_name} = 1;

        # Reset counter in entry state
        if (@state_specs && $state_specs[0]{kind} eq 'entry') {
            unshift @{$state_specs[0]{body}}, "    (<- ($cc_name 0))";
        }

        # Inject inc=1 into every active state (drive, await, repeat_init, repeat_check)
        for my $spec (@state_specs) {
            next if $spec->{kind} eq 'entry' || $spec->{kind} eq 'terminal';
            next if $spec->{name} =~ /_timeout\$/;
            unshift @{$spec->{body}}, "    (= ($inc_name 1))";
        }

        # Latency check in terminal/done state: min violation
        my ($done_state) = grep {
            $_->{kind} eq 'terminal' && $_->{name} !~ /_timeout\$/
        } @state_specs;
        if ($done_state) {
            push @{$done_state->{body}}, "    (?$cc_name";
            push @{$done_state->{body}}, "      (<$min (= ($err_name 1)))";
            push @{$done_state->{body}}, '    )';
        }

        # Max check via watchdog — already handled if (await) exists.
        # If no await but latency max specified, add a max-check state.
        if (!$has_await && $max) {
            my $max_check = "${tx_name}_max_chk";
            push @state_specs, {
                name => $max_check,
                kind => 'sequential',
                body => [
                    "    (?$cc_name",
                    "      (=$max (-> ${tx_name}_timeout))",
                    '    )',
                ],
            };

            my $timeout_name = "${tx_name}_timeout";
            push @state_specs, {
                name => $timeout_name,
                kind => 'terminal',
                body => [
                    "    (= ($err_name 1))",
                    "    (= (done> 1))",
                    "    (= (last_error> 1))",
                ],
            };
        }


        # Combinational DT for cycle counter increment
        push @extra_dts, "  (-${tx_name}_cc_inc";
        push @extra_dts, "    (<- ($cc_name (+ $cc_name 1)) <$inc_name)";
        push @extra_dts, '  )';
        push @extra_dts, '';
    }

    # Relink states after all modifications

    $self->_link_states(\@state_specs, $tx_name);

    return { states => \@state_specs, counters => \%counters, extra_dts => \@extra_dts };
}

# --- Phase 1: Collect state bodies ---

sub _state_name($tx_name, $kind, $idx) {
    return "${tx_name}_${kind}_$idx";
}

sub _on_clause($self, $clause, $tx_name, $handshakes, $idx) {
    my $hs_name    = $clause->[1];
    my $hs         = $handshakes->{$hs_name}
        or confess "Transaction '$tx_name': handshake '$hs_name' not declared\n";
    my $valid_port = $hs->{valid};
    my $name       = _state_name($tx_name, 'idle', $idx);
    my @samples;

    for my $i (2 .. $#$clause) {
        my $sub = $clause->[$i];
        next unless ref($sub) eq 'ARRAY' && $sub->[0] eq 'sample';
        my ($kw, $port, $as_kw, $as_name) = @$sub;
        push @samples, "    (<= ($as_name $port))";
    }

    return {
        name      => $name,
        kind      => 'entry',
        body      => [],
        samples   => \@samples,
        cond_port => $valid_port,
    };
}

sub _drive_clause($self, $clause, $tx_name, $samples, $idx) {
    my $name = _state_name($tx_name, 'drive', $idx);
    my @body;

    # Emit samples from preceding (sample ...) clauses
    for my $s (@$samples) {
        my ($kw, $port, $as_kw, $as_name) = @$s;
        push @body, "    (<= ($as_name $port))";
    }

    # Drive assignments
    for my $i (2 .. $#$clause) {
        my $assign = $clause->[$i];
        next unless ref($assign) eq 'ARRAY' && $assign->[0] eq 'assign';
        my ($kw, $port, $value) = @$assign;
        push @body, "    (= ($port> $value))";
    }

    return { name => $name, kind => 'sequential', body => \@body };
}

sub _await_clause($self, $clause, $tx_name, $idx, $watchdog) {
    my $port     = $clause->[1];
    my $name     = _state_name($tx_name, 'await', $idx);
    my $wd_name  = "${tx_name}_wd";
    my $wd_limit = $watchdog // 65536;

    return {
        name      => $name,
        kind      => 'await',
        body      => [],
        cond_port => $port,
        wd_name   => $wd_name,
        wd_limit  => $wd_limit,
    };
}

sub _complete_clause($self, $clause, $tx_name, $idx) {
    my $port = $clause->[1];
    my $name = _state_name($tx_name, 'done', $idx);

    return {
        name => $name,
        kind => 'terminal',
        body => ["    (= ($port> 1))"],
    };
}

sub _sample_state($self, $tx_name, $samples, $idx) {
    my $name = _state_name($tx_name, 'sample', $idx);
    my @body;
    for my $s (@$samples) {
        my ($kw, $port, $as_kw, $as_name) = @$s;
        push @body, "    (<= ($as_name $port))";
    }
    return { name => $name, kind => 'sequential', body => \@body };
}

sub _placeholder_clause($self, $clause, $tx_name, $idx) {
    my $kind = $clause->[0];
    my $name = _state_name($tx_name, $kind, $idx);
    return {
        name => $name,
        kind => 'sequential',
        body => ["    ;; ($kind ...) \x{2014} lowering deferred"],
    };
}

sub _repeat_clause($self, $clause, $tx_name, $idx_ref, $pending, $watchdog) {
    # (repeat count_expr body...)
    # Produces: counter_init, body_states, counter_check (loop back)
    my $count_expr = $clause->[1];
    my $counter_name = "${tx_name}_cnt";
    my @states;

    # Init state: load counter
    my $init_name = _state_name($tx_name, 'repeat_init', $$idx_ref++);
    push @states, {
        name => $init_name,
        kind => 'sequential',
        body => ["    (<= ($counter_name $count_expr))"],
    };

    # Body states: process clauses inside repeat as inline states
    my @body_clauses = @{$clause}[2 .. $#$clause];
    my @local_pending;

    for my $bc (@body_clauses) {
        next unless ref($bc) eq 'ARRAY';
        my $bk = $bc->[0];

        if ($bk eq 'await') {
            push @states, $self->_await_clause($bc, $tx_name, $$idx_ref++, $watchdog);
        }
        elsif ($bk eq 'sample') {
            push @local_pending, $bc;
        }
        elsif ($bk eq 'drive') {
            my $samples = [splice @local_pending];
            push @states, $self->_drive_clause($bc, $tx_name, $samples, $$idx_ref++);
        }
    }

    # Flush any pending samples inside the repeat
    if (@local_pending) {
        push @states, $self->_sample_state($tx_name, \@local_pending, $$idx_ref++);
    }

    # Check state: decrement counter, loop back or exit
    my $check_name = _state_name($tx_name, 'repeat_check', $$idx_ref++);
    my $first_body_name = $states[0]{name};

    push @states, {
        name => $check_name,
        kind => 'repeat_check',
        counter => $counter_name,
        body => [
            "    (<- ($counter_name (- $counter_name 1)))",
        ],
        loop_target => $first_body_name,
    };

    return (\@states, $counter_name);
}

# --- Phase 2: Link states with transitions ---

sub _link_states($self, $state_specs, $tx_name) {
    return unless @$state_specs;

    my $entry_state = $state_specs->[0]->{name};

    for my $i (0 .. $#$state_specs) {
        my $spec   = $state_specs->[$i];
        my $kind   = $spec->{kind};
        my $next   = ($i < $#$state_specs) ? $state_specs->[$i+1]{name} : undef;

        if ($kind eq 'entry') {
            # Samples inside condition, transition to first real state when condition true
            push @{$spec->{body}}, "    (<$spec->{cond_port}";
            push @{$spec->{body}}, @{$spec->{samples}} if $spec->{samples};
            push @{$spec->{body}}, "      (-> $next)" if $next;
            push @{$spec->{body}}, '    )';
        }
        elsif ($kind eq 'terminal') {
            # Return to entry (idle) state after completion
            push @{$spec->{body}}, "    (-> $entry_state)";
        }
        elsif ($kind eq 'repeat_check') {
            my $ctr = $spec->{counter};
            push @{$spec->{body}}, "    (?$ctr";
            push @{$spec->{body}}, "      (=0 (-> $next))" if $next;
            push @{$spec->{body}}, "      (=1 (-> $spec->{loop_target}))" if $spec->{loop_target};
            push @{$spec->{body}}, '    )';
        }
        elsif ($kind eq 'await') {
            my $wd = $spec->{wd_name};
            # Decrement watchdog, check port, check timeout at zero
            push @{$spec->{body}}, "    (-- $wd)";
            push @{$spec->{body}}, "    (<$spec->{cond_port}";
            push @{$spec->{body}}, "      (-> $next)" if $next;
            push @{$spec->{body}}, '    )';
            push @{$spec->{body}}, "    (?$wd";
            push @{$spec->{body}}, "      (=0 (-> ${tx_name}_timeout))";
            push @{$spec->{body}}, '    )';
        }
        elsif ($kind eq 'sequential' && $next) {
            push @{$spec->{body}}, "    (-> $next)";
        }
        # terminal: no transition needed
    }
}

sub _parse_latency($self, $clause) {
    my %result;
    for my $i (1 .. $#$clause) {
        my $item = $clause->[$i];
        next unless ref($item) eq 'ARRAY' && @$item >= 2;
        my $key = $item->[0];
        my $val = $item->[1];
        $result{$key} = $val if $key eq 'min' || $key eq 'max';
    }
    return \%result;
}

1;
