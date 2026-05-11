package FSM::Scheduler::ISF::Emitter::FSM;

use v5.20;
use strict;
use warnings;
use feature qw(signatures postderef);
no warnings 'experimental::signatures';
use FSM::Debug;

# Emits .fsm source text from LoweringIR.
# Pure emitter — no logic, just walks the IR and produces strings.

sub new($class, %args) { bless {}, $class }

sub emit($self, $ir) {
    fsm_trace_enter('Emitter::FSM emit', 2);

    $self->{outputs} = { map { $_->{name} => 1 } grep { $_->{direction} eq 'output' } @{$ir->{ports}} };

    my @lines;

    push @lines, $self->_emit_header($ir);
    push @lines, '';
    push @lines, $self->_emit_system($ir);
    push @lines, '';
    push @lines, $self->_emit_size($ir);
    push @lines, '';
    push @lines, $self->_emit_states($ir, $self->{outputs});
    push @lines, $self->_emit_dt_blocks($ir, $self->{outputs});
    push @lines, ')';

    my $out = join("\n", @lines) . "\n";
    fsm_trace_exit('Emitter::FSM emit', 2);
    return $out;
}

sub _emit_header($self, $ir) {
    return "(?fsm:$ir->{actor_name}";
}

sub _emit_system($self, $ir) {
    my @l;
    push @l, '  (+system';
    push @l, "    (clock $ir->{clock})";
    my $r = $ir->{reset};
    if ($r && $r->{kind} eq 'async' && ($r->{polarity} // '') eq 'active_low') {
        push @l, "    (areset $r->{name})";
    } elsif ($r && $r->{kind} eq 'async') {
        push @l, "    (areset $r->{name})";
    } elsif ($r) {
        push @l, "    (sreset $r->{name})";
    }
    push @l, '  )';
    return join("\n", @l);
}

sub _emit_size($self, $ir) {
    my @l;
    push @l, '  (+size';
    for my $p (@{$ir->{ports}}) {
        push @l, "    ($p->{name} $p->{width})";
    }
    my $ctrs = $ir->{counters} || {};
    for my $name (sort keys %$ctrs) {
        push @l, "    ($name $ctrs->{$name})";
    }
    push @l, '  )';
    return join("\n", @l);
}

sub _emit_states($self, $ir, $outputs) {
    my @lines;
    for my $s (@{$ir->{states}}) {
        push @lines, "  ($s->{name}";
        push @lines, $self->_emit_assignments($s);
        push @lines, $self->_emit_transitions($s);
        push @lines, '  )';
        push @lines, '';
    }
    return @lines;
}

sub _emit_assignments($self, $state) {
    my @lines;
    my $kind = $state->{kind};

    # Watchdog decrement
    if ($kind eq 'await' && $state->{watchdog}) {
        push @lines, "    (-- $state->{watchdog}{name})";
    }

    for my $a (@{$state->{assignments}}) {
        my $guard_str = '';
        if ($a->{guard}) {
            my $g = $a->{guard};
            if ($g->{port} && !$g->{op}) {
                $guard_str = " <$g->{port}";
            } elsif ($g->{signal} && $g->{op}) {
                my $v = $g->{value};
                $guard_str = " <$g->{signal}" . ($g->{op} eq '<' ? "<$v" : "=$v");
            }
        }
        my $op = $a->{op};
        if ($op eq '=') {
            my $port_suffix = $self->{outputs}{$a->{lhs}} ? '>' : '';
            push @lines, "    (= ($a->{lhs}$port_suffix $a->{rhs})$guard_str)";
        } elsif ($op eq '<-') {
            push @lines, "    (<- ($a->{lhs} $a->{rhs})$guard_str)";
        } elsif ($op eq '<=') {
            push @lines, "    (<= ($a->{lhs} $a->{rhs})$guard_str)";
        } elsif ($op eq '--') {
            push @lines, "    (-- $a->{lhs})";
        } else {
            push @lines, "    ($op ($a->{lhs} $a->{rhs})$guard_str)";
        }
    }
    return @lines;
}

sub _emit_transitions($self, $state) {
    my @lines;
    my $txs = $state->{transitions};

    if ($state->{kind} eq 'repeat_check') {
        # Decision tree: (=0 -> exit), (!=0 -> loop)
        push @lines, "    (?$state->{counter}";
        for my $t (@$txs) {
            my $c = $t->{condition};
            if ($c->{op} eq '!=') {
                push @lines, "      (=1 (-> $t->{target}))";
            } else {
                push @lines, "      (=0 (-> $t->{target}))";
            }
        }
        push @lines, '    )';
        return @lines;
    }

    if ($state->{kind} eq 'await') {
        # Await has both guard transition and watchdog timeout
        my %seen;
        for my $t (@$txs) {
            my $c = $t->{condition};
            if ($c->{port} && !$c->{op}) {
                # Guard transition: (<port (-> target))
                push @lines, "    (<$c->{port}";
                push @lines, "      (-> $t->{target})";
                push @lines, '    )';
            } elsif ($c->{signal}) {
                # Watchdog: (?wd (=0 (-> timeout)))
                push @lines, "    (?$c->{signal}";
                push @lines, "      (=0 (-> $t->{target}))";
                push @lines, '    )';
            }
        }
        return @lines;
    }

    # Sync transitions: await_all / await_any
    if ($state->{kind} eq 'sync_all') {
        my @ports = @{$state->{done_ports}};
        my $target = $txs->[0]{target};
        # Nested guards: (<p0 (<p1 (<p2 (-> target))))
        for my $p (reverse @ports) {
            push @lines, "    (<$p";
        }
        push @lines, "      (-> $target)";
        push @lines, '    )' x scalar(@ports);
        return @lines;
    }
    if ($state->{kind} eq 'sync_any') {
        my $target = $txs->[0]{target};
        my @ports = @{$state->{done_ports}};
        # Single guard with OR expression if supported, else just first port
        push @lines, "    (<$ports[0]";
        push @lines, "      (-> $target)";
        push @lines, '    )';
        return @lines;
    }

    # Simple transitions
    for my $t (@$txs) {
        if ($t->{condition} && $t->{condition}{port}) {
            push @lines, "    (<$t->{condition}{port}";
            push @lines, "      (-> $t->{target})";
            push @lines, '    )';
        } elsif ($t->{condition} && $t->{condition}{expr}) {
            push @lines, "    (-> $t->{target} <$t->{condition}{expr})";
        } elsif ($t->{condition} && $t->{condition}{signal}) {
            my $c = $t->{condition};
            push @lines, "    (?$c->{signal}";
            push @lines, "      (=$c->{value} (-> $t->{target}))";
            push @lines, '    )';
        } else {
            push @lines, "    (-> $t->{target})";
        }
    }
    return @lines;
}

sub _emit_dt_blocks($self, $ir, $outputs) {
    my @lines;
    for my $dt (@{$ir->{dt_blocks}}) {
        push @lines, "  (-$dt->{name}";
        for my $a (@{$dt->{assignments}}) {
            my $guard = $a->{guard} ? " <$a->{guard}{port}" : '';
            my $op = $a->{op};
            if ($op eq '=') {
                my $port_suffix = $self->{outputs}{$a->{lhs}} ? '>' : '';
                push @lines, "    (= ($a->{lhs}$port_suffix $a->{rhs})$guard)";
            } elsif ($op eq '<-') {
                push @lines, "    (<- ($a->{lhs} $a->{rhs})$guard)";
            } elsif ($op eq '<=') {
                push @lines, "    (<= ($a->{lhs} $a->{rhs})$guard)";
            } else {
                push @lines, "    ($a->{lhs} = $a->{rhs})$guard";
            }
        }
        push @lines, '  )';
        push @lines, '';
    }
    return @lines;
}

1;
