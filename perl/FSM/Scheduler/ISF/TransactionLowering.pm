package FSM::Scheduler::ISF::TransactionLowering;

use v5.20;
use strict;
use warnings;
use Carp qw(confess);
use feature qw(signatures postderef);
no warnings 'experimental::signatures';

use FSM::Debug;

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
    my @state_specs;            # { name, kind, body_lines, samples }
    my @pending_samples;
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
            push @state_specs, $self->_await_clause($clause, $tx_name, $idx++);
        }
        elsif ($kind eq 'sample') {
            push @pending_samples, $clause;
        }
        elsif ($kind eq 'complete') {
            push @state_specs, $self->_complete_clause($clause, $tx_name, $idx++);
        }
        elsif ($kind eq 'latency') {
            fsm_debug("Transaction '$tx_name': latency constraint recorded", 3);
        }
        elsif ($kind eq 'do' || $kind eq 'spawn' || $kind eq 'await_all' || $kind eq 'await_any') {
            push @state_specs, $self->_placeholder_clause($clause, $tx_name, $idx++);
        }
    }

    # Flush pending samples as a standalone state
    if (@pending_samples) {
        push @state_specs, $self->_sample_state($tx_name, \@pending_samples, $idx++);
    }

    # Phase 2: link states with transitions
    $self->_link_states(\@state_specs, $tx_name);

    fsm_trace_exit("TransactionLowering: $tx_name produced " . scalar(@state_specs) . " states", 3);
    return \@state_specs;
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

sub _await_clause($self, $clause, $tx_name, $idx) {
    my $port = $clause->[1];
    my $name = _state_name($tx_name, 'await', $idx);

    return {
        name      => $name,
        kind      => 'await',
        body      => [],
        cond_port => $port,
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
        body => ["    ;; ($kind ...) — lowering deferred"],
    };
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
        elsif ($kind eq 'await') {
            my $cond = $spec->{cond_port};
            push @{$spec->{body}}, "    (<$cond";
            push @{$spec->{body}}, "      (-> $next)" if $next;
            push @{$spec->{body}}, "    )";
        }
        elsif ($kind eq 'sequential' && $next) {
            push @{$spec->{body}}, "    (-> $next)";
        }
        # terminal: no transition needed
    }
}

1;
