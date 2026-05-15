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
    if (@{$ir->{constants} || []}) {
        push @lines, $self->_emit_constants($ir);
        push @lines, '';
    }
    if (@{$ir->{params} || []}) {
        push @lines, $self->_emit_params($ir);
        push @lines, '';
    }
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

sub _emit_constants($self, $ir) {
    my @l;
    push @l, '  (+constants';
    for my $constant (@{$ir->{constants} || []}) {
        push @l, "    ($constant->{name} " . _format_param_value($constant->{value}) . ")";
    }
    push @l, '  )';
    return join("\n", @l);
}

sub _emit_params($self, $ir) {
    my @l;
    push @l, '  (+params';
    for my $param (@{$ir->{params} || []}) {
        push @l, "    ($param->{name} " . _format_param_value($param->{value}) . ")";
    }
    push @l, '  )';
    return join("\n", @l);
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
    for my $storage (@{$ir->{declared_storage} || []}) {
        for my $signal (@{$storage->{signals} || []}) {
            my $name = $signal->{name};
            next if $declared{$name};
            $declared{$name} = 1;
            push @l, "    ($name $signal->{width})";
        }
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
        my $guard_str = _format_guard_suffix($a->{guard});
        my $op = $a->{op};
        my $lhs = $self->_lhs_token($a->{lhs});
        if ($op eq '=') {
            push @lines, "    (= ($lhs $a->{rhs})$guard_str)";
        } elsif ($op eq '<-') {
            push @lines, "    (<- ($lhs $a->{rhs})$guard_str)";
        } elsif ($op eq '<=') {
            push @lines, "    (<= ($lhs $a->{rhs})$guard_str)";
        } elsif ($op eq '--') {
            push @lines, "    (-- $a->{lhs})";
        } else {
            push @lines, "    ($op ($lhs $a->{rhs})$guard_str)";
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
        my @counter_transitions = grep {
            $_->{condition}
                && $_->{condition}{signal}
                && $_->{condition}{signal} eq $state->{counter}
        } @$txs;
        my @other_transitions = grep {
            !($_->{condition}
                && $_->{condition}{signal}
                && $_->{condition}{signal} eq $state->{counter})
        } @$txs;

        if (@counter_transitions) {
            push @lines, "    (?$state->{counter}";
        }
        for my $t (@counter_transitions) {
            my $c = $t->{condition};
            if ($c->{op} eq '!=') {
                push @lines, "      (=1 (-> $t->{target}))";
            } else {
                push @lines, "      (=0 (-> $t->{target}))";
            }
        }
        push @lines, '    )' if @counter_transitions;
        for my $t (@other_transitions) {
            push @lines, $self->_emit_simple_transition($t);
        }
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
            } elsif ($c->{expr}) {
                push @lines, $self->_emit_simple_transition($t);
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
        return map { $self->_emit_simple_transition($_) } @$txs
            if grep { $_->{condition} } @$txs;

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
        return map { $self->_emit_simple_transition($_) } @$txs
            if grep { $_->{condition} } @$txs;

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
        return map { $self->_emit_simple_transition($_) } @$txs
            if grep { $_->{condition} } @$txs;

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

    if ($state->{kind} eq 'loop_while' || $state->{kind} eq 'loop_until') {
        my $cond = $state->{condition};
        my $cond_str = !ref($cond) ? $cond : _format_expr($cond);
        push @lines, "    (?$cond_str";
        for my $t (@$txs) {
            my $branch = $t->{condition}{loop_branch};
            push @lines, "      (=$branch (-> $t->{target}))" if defined $branch;
        }
        push @lines, '    )';
        return @lines;
    }

    # Simple transitions
    for my $t (@$txs) {
        push @lines, $self->_emit_simple_transition($t);
    }
    return @lines;
}

sub _emit_simple_transition($self, $transition) {
    my @lines;
    if ($transition->{condition} && $transition->{condition}{port}) {
        push @lines, "    (<$transition->{condition}{port}";
        push @lines, "      (-> $transition->{target})";
        push @lines, '    )';
    } elsif ($transition->{condition} && $transition->{condition}{expr}) {
        push @lines, "    (-> $transition->{target} <$transition->{condition}{expr})";
    } elsif ($transition->{condition} && $transition->{condition}{signal}) {
        my $c = $transition->{condition};
        my $op = $c->{op} // '=';
        $op = '=' if $op eq '==';
        push @lines, "    (?$c->{signal}";
        push @lines, "      ($op$c->{value} (-> $transition->{target}))";
        push @lines, '    )';
    } else {
        push @lines, "    (-> $transition->{target})";
    }
    return @lines;
}

sub _emit_dt_blocks($self, $ir, $outputs) {
    my @lines;
    for my $dt (@{$ir->{dt_blocks}}) {
        push @lines, "  (-$dt->{name}" . _format_guard_suffix($dt->{dte_guard});
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
    my $guard = !$options{no_guard} ? _format_guard_suffix($assignment->{guard}) : '';
    my $op = $assignment->{op};
    my $lhs = $self->_lhs_token($assignment->{lhs});

    if ($op eq '=') {
        return "$padding(= ($lhs $assignment->{rhs})$guard)";
    } elsif ($op eq '<-') {
        return "$padding(<- ($lhs $assignment->{rhs})$guard)";
    } elsif ($op eq '<=') {
        return "$padding(<= ($lhs $assignment->{rhs})$guard)";
    } elsif ($op =~ /^<[0-9]+$/) {
        return "$padding($op ($lhs $assignment->{rhs})$guard)";
    }

    return "$padding($lhs = $assignment->{rhs})$guard";
}

sub _lhs_token($self, $name) {
    return $self->{outputs}{$name} ? "$name>" : $name;
}

sub _rule_guard_key {
    my ($guard) = @_;
    return '' unless $guard && ref($guard) eq 'HASH';
    return '' if defined($guard->{port}) && $guard->{port} eq '1';
    return $guard->{port} // '';
}

sub _format_guard_suffix {
    my ($guard) = @_;
    return '' unless $guard && ref($guard) eq 'HASH';
    return '' if defined($guard->{port}) && $guard->{port} eq '1';
    return " <$guard->{port}" if $guard->{port} && !$guard->{op};
    if ($guard->{signal} && $guard->{op}) {
        my $value = $guard->{value};
        my $operator = $guard->{op} eq '=' ? '=' : $guard->{op};
        return " <$guard->{signal}$operator$value";
    }
    return " <$guard->{expr}" if $guard->{expr};
    return '';
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

sub _format_param_value {
    my ($value) = @_;
    return $value unless ref($value) eq 'ARRAY';
    return '(' . join(' ', map { _format_param_value($_) } @$value) . ')';
}

sub _is_default_selector {
    my ($value) = @_;
    return defined($value)
        && !ref($value)
        && ($value eq 'default' || $value eq '_');
}

1;
