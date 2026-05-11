package FSM::Scheduler::ISF;

use v5.20;
use strict;
use warnings;
use Carp qw(confess);
use feature qw(signatures postderef);
no warnings 'experimental::signatures';

use FSM::Debug;
use FSM::Scheduler::ISF::ModuleEmitter;
use FSM::Scheduler::ISF::TransactionLowering;
use FSM::Scheduler::ISF::RuleLowering;

sub new($class, %args) {
    my $debug = $args{debug} // 0;
    fsm_trace_enter('Initialize ISF scheduler', 2);

    my $self = bless {
        debug          => $debug,
        module_emitter => FSM::Scheduler::ISF::ModuleEmitter->new(debug => $debug),
        tx_lowering    => FSM::Scheduler::ISF::TransactionLowering->new(debug => $debug),
        rule_lowering  => FSM::Scheduler::ISF::RuleLowering->new(debug => $debug),
    }, $class;

    fsm_trace_exit('ISF scheduler initialized', 2);
    return $self;
}

sub lower($self, $actor) {
    fsm_trace_enter("Scheduler lower: $actor->{actor_name}", 2);

    my @lines;

    # Module header and system
    push @lines, $self->{module_emitter}->emit_header($actor);
    push @lines, '';
    push @lines, $self->{module_emitter}->emit_system($actor);
    push @lines, '';

    # Transaction lowering — collect states and infer counters
    my $tx_lowering = $self->{tx_lowering};
    my %all_counters;
    my @all_states;
    my @extra_dts;

    for my $tx (@{$actor->{transactions}}) {
        my $result = $tx_lowering->lower_transaction($tx, $actor);
        push @all_states, @{$result->{states}};
        my $counters = $result->{counters};
        while (my ($name, $width) = each %$counters) {
            $all_counters{$name} = $width;
        }
        push @extra_dts, @{$result->{extra_dts}} if $result->{extra_dts};
    }

    # Emit ports with inferred counters
    push @lines, $self->{module_emitter}->emit_ports($actor, \%all_counters);
    push @lines, '';

    # Emit states
    for my $state (@all_states) {
        push @lines, "  ($state->{name}";
        push @lines, @{$state->{body}};
        push @lines, '  )';
        push @lines, '';
    }

    # Emit rules as combinational DT blocks
    my $rule_blocks = $self->{rule_lowering}->lower_rules($actor);
    push @lines, @$rule_blocks;

    # Emit extra DTs from transaction lowering (latency cycle counters)
    push @lines, @extra_dts;

    push @lines, ')';

    my $fsm_source = join("\n", @lines) . "\n";
    fsm_trace_exit("Scheduler lower completed for $actor->{actor_name}", 2);
    return $fsm_source;
}

1;
