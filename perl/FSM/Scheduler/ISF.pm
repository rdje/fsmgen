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

# ISF Scheduler — lowers a parsed .isf actor AST into explicit .fsm source.
#
# Pipeline:
#   parsed ISF actor (from FSM::Adapter::ISF)
#     -> ModuleEmitter (header, ports, system)
#     -> TransactionLowering (state machines) [future]
#     -> .fsm source text

sub new($class, %args) {
    my $debug = $args{debug} // 0;
    fsm_trace_enter('Initialize ISF scheduler', 2);

    my $self = bless {
        debug         => $debug,
        module_emitter => FSM::Scheduler::ISF::ModuleEmitter->new(debug => $debug),
        tx_lowering   => FSM::Scheduler::ISF::TransactionLowering->new(debug => $debug),
    }, $class;

    fsm_trace_exit('ISF scheduler initialized', 2);
    return $self;
}

sub lower($self, $actor) {
    fsm_trace_enter("Scheduler lower: $actor->{actor_name}", 2);

    my @lines;

    # Module header
    push @lines, $self->{module_emitter}->emit_header($actor);
    push @lines, '';
    push @lines, $self->{module_emitter}->emit_system($actor);
    push @lines, '';
    push @lines, $self->{module_emitter}->emit_ports($actor);
    push @lines, '';

    # Transaction lowering
    my $tx_lowering = $self->{tx_lowering};
    for my $tx (@{$actor->{transactions}}) {
        my $states = $tx_lowering->lower_transaction($tx, $actor);
        for my $state (@$states) {
            push @lines, "  ($state->{name}";
            push @lines, @{$state->{body}};
            push @lines, '  )';
            push @lines, '';
        }
    }

    push @lines, ')';

    my $fsm_source = join("\n", @lines) . "\n";
    fsm_trace_exit("Scheduler lower completed for $actor->{actor_name}", 2);
    return $fsm_source;
}

1;
