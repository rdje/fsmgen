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
    my %declared;
    for my $p (@{$ir->{ports}}) {
        $declared{$p->{name}} = 1;
        push @l, "    ($p->{name} $p->{width})";
    }
    my $ctrs = $ir->{counters} || {};
    for my $name (sort keys %$ctrs) {
        next if $declared{$name};
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
    if ($state->{fields}) {
        for my $f (@{$state->{fields}}) {
            push @lines, "    (<= ($f (slice $state->{word} $f HIGH $f LOW)))";
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
                # Watchdog: zero test and nonzero decrement both read current Q.
                push @lines, "    (?$c->{signal}";
                push @lines, "      (=0 (-> $t->{target}))";
                push @lines, "      (>0 (-- $c->{signal}))";
                push @lines, '    )';
            }
        }
        return @lines;
    }

    # Sync transitions: await_all / await_any
    if ($state->{kind} eq 'sync_all') {
        my @ports = @{$state->{done_ports}};
        my $target = $txs->[0]{target};
        if (!@ports) {
            push @lines, "    (-> $target)";
        } elsif (@ports == 1) {
            push @lines, "    (-> $target <$ports[0])";
        } else {
            push @lines, "    (-> $target <(& " . join(' ', @ports) . '))';
        }
        return @lines;
    }
    if ($state->{kind} eq 'sync_any') {
        my $target = $txs->[0]{target};
        my @ports = @{$state->{done_ports}};
        for my $p (@ports) {
            push @lines, "    (<$p";
            push @lines, "      (-> $target)";
            push @lines, '    )';
        }
        push @lines, "    (-> $target)" unless @ports;
        return @lines;
    }

    # Switch transition: (?signal (=val (-> body)) ...)
    if ($state->{kind} eq 'switch') {
        push @lines, "    (?$state->{signal}";
        for my $br (@{$state->{branches}}) {
            my $selector = _is_default_selector($br->{value}) ? 'default' : "=$br->{value}";
            push @lines, "      ($selector (-> $br->{body_start}))";
        }
        for my $t (@$txs) {
            push @lines, "      (default (-> $t->{target}))" if !$t->{condition};
        }
        push @lines, '    )';
        return @lines;
    }

    # Branch transition: ?condition (=1 -> body) (=0 -> skip)
    if ($state->{kind} eq 'branch') {
        my $cond = $state->{condition};
        my $cond_str = !ref($cond) ? $cond : _format_expr($cond);
        push @lines, "    (?$cond_str";
        push @lines, "      (=1 (-> $state->{true_target}))" if $state->{true_target};
        # =0: skip to next top-level state
        for my $t (@$txs) {
            push @lines, "      (=0 (-> $t->{target}))" if !$t->{condition};
        }
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
        push @lines,
            $dt->{kind} eq 'rule'
                ? $self->_emit_rule_dt_assignments($dt)
                : $self->_emit_plain_dt_assignments($dt);
        push @lines, '  )';
        push @lines, '';
    }
    return @lines;
}

sub _emit_plain_dt_assignments($self, $dt) {
    return map { $self->_format_dt_assignment($_, 4) } @{$dt->{assignments}};
}

sub _emit_rule_dt_assignments($self, $dt) {
    my @lines;
    my @guard_order;
    my %by_guard;

    for my $assignment (@{$dt->{assignments}}) {
        my $guard_key = _rule_guard_key($assignment->{guard});
        push @guard_order, $guard_key unless exists $by_guard{$guard_key};
        push @{$by_guard{$guard_key}}, $assignment;
    }

    for my $guard_key (@guard_order) {
        my $assignments = $by_guard{$guard_key};
        if ($guard_key eq '') {
            push @lines, map { $self->_format_dt_assignment($_, 4) } @$assignments;
            next;
        }

        push @lines, "    (<$guard_key";
        push @lines, map { $self->_format_dt_assignment($_, 6, no_guard => 1) } @$assignments;
        push @lines, '    )';
    }

    return @lines;
}

sub _format_dt_assignment($self, $assignment, $indent, %options) {
    my $padding = ' ' x $indent;
    my $guard = !$options{no_guard} && $assignment->{guard} ? " <$assignment->{guard}{port}" : '';
    my $op = $assignment->{op};

    if ($op eq '=') {
        my $port_suffix = $self->{outputs}{$assignment->{lhs}} ? '>' : '';
        return "$padding(= ($assignment->{lhs}$port_suffix $assignment->{rhs})$guard)";
    } elsif ($op eq '<-') {
        return "$padding(<- ($assignment->{lhs} $assignment->{rhs})$guard)";
    } elsif ($op eq '<=') {
        return "$padding(<= ($assignment->{lhs} $assignment->{rhs})$guard)";
    } elsif ($op =~ /^<[0-9]+$/) {
        return "$padding($op ($assignment->{lhs} $assignment->{rhs})$guard)";
    }

    return "$padding($assignment->{lhs} = $assignment->{rhs})$guard";
}

sub _rule_guard_key {
    my ($guard) = @_;
    return '' unless $guard && ref($guard) eq 'HASH';
    return '' if defined($guard->{port}) && $guard->{port} eq '1';
    return $guard->{port} // '';
}

sub _format_expr {
    my ($e) = @_;
    return $e unless ref($e) eq 'ARRAY';
    my $op = $e->[0];
    my @args;
    for my $i (1 .. $#$e) {
        my $a = $e->[$i];
        push @args, ref($a) ? _format_expr($a) : $a;
    }
    return "($op " . join(' ', @args) . ')';
}

sub _is_default_selector {
    my ($value) = @_;
    return defined($value)
        && !ref($value)
        && ($value eq 'default' || $value eq '_');
}

1;
