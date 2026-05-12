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
        compile_issues => [],
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
                kind  => $a->{op} eq '<=' ? 'register' :
                         $a->{op} eq '<-' ? 'register' : 'counter',
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

sub _transaction_summary($self, $ir) {
    my @txs;
    my %tx_states;

    # Group states by transaction prefix
    for my $s (@{$ir->{states}}) {
        my ($tx_name) = ($s->{name} =~ /^(\w+?)_(?:idle|drive|await|done|repeat|sample|max_chk|timeout)_/);
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

1;
