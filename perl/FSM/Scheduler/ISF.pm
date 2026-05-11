package FSM::Scheduler::ISF;

use v5.20;
use strict;
use warnings;
use feature qw(signatures postderef);
no warnings 'experimental::signatures';

use FSM::Debug;
use FSM::Scheduler::ISF::LoweringIR;
use FSM::Scheduler::ISF::Emitter::FSM;

sub new($class, %args) {
    my $debug = $args{debug} // 0;
    fsm_trace_enter('Initialize ISF scheduler', 2);

    my $self = bless {
        debug    => $debug,
        ir       => FSM::Scheduler::ISF::LoweringIR->new(debug => $debug),
        emitter  => FSM::Scheduler::ISF::Emitter::FSM->new,
    }, $class;

    fsm_trace_exit('ISF scheduler initialized', 2);
    return $self;
}

sub lower($self, $actor) {
    fsm_trace_enter("Scheduler lower: $actor->{actor_name}", 2);

    my $ir  = $self->{ir}->build_module($actor);
    my $fsm = $self->{emitter}->emit($ir);

    fsm_trace_exit("Scheduler lower completed", 2);
    return $fsm;
}

1;
