package FSM::Scheduler::ISF;

use v5.20;
use strict;
use warnings;
use Carp qw(confess);
use feature qw(signatures postderef);
no warnings 'experimental::signatures';

use FSM::Debug;
use FSM::Scheduler::ISF::LoweringIR;
use FSM::Scheduler::ISF::Emitter::FSM;
use FSM::Scheduler::ISF::Emitter::JSON;

sub new($class, @constructor_args) {
    my %args = _validate_constructor_args($class, @constructor_args);
    my $debug = $args{debug} // 0;
    fsm_trace_enter('Initialize ISF scheduler', 2);

    my $self = bless {
        debug       => $debug,
        ir          => FSM::Scheduler::ISF::LoweringIR->new(debug => $debug),
        fsm_emitter => FSM::Scheduler::ISF::Emitter::FSM->new,
        json_emitter=> FSM::Scheduler::ISF::Emitter::JSON->new,
    }, $class;

    fsm_trace_exit('ISF scheduler initialized', 2);
    return $self;
}

sub _validate_constructor_args($class, @args) {
    confess "$class->new expects an even-length option/value list\n"
        if @args % 2;

    my %options = @args;
    my %allowed = map { $_ => 1 } qw(debug);
    for my $name (sort keys %options) {
        confess "$class->new unsupported option '$name'; supported option: debug\n"
            unless $allowed{$name};
    }

    return %options;
}

sub lower($self, @args) {
    my ($actor) = _validate_actor_arg('lower', @args);
    fsm_trace_enter("Scheduler lower: $actor->{actor_name}", 2);

    my $ir     = $self->{ir}->build_module($actor);
    my %files;

    # Emit parent
    $files{"$ir->{actor_name}.fsm"} = $self->{fsm_emitter}->emit($ir);

    # Emit children
    my $children = $ir->{children} || {};
    while (my ($cname, $cir) = each %$children) {
        $files{"$cname.fsm"} = $self->{fsm_emitter}->emit($cir);
    }

    fsm_trace_exit("Scheduler lower completed", 2);
    return { files => \%files };
}

sub report($self, @args) {
    my ($actor) = _validate_actor_arg('report', @args);
    fsm_trace_enter("Scheduler report: $actor->{actor_name}", 2);

    my $ir   = $self->{ir}->build_module($actor);
    my $json = $self->{json_emitter}->emit($ir);

    fsm_trace_exit("Scheduler report completed", 2);
    return $json;
}

sub _validate_actor_arg($method, @args) {
    confess "FSM::Scheduler::ISF->$method expects exactly one scheduler-consumable actor hash reference\n"
        unless @args == 1;

    my $actor = $args[0];
    confess "FSM::Scheduler::ISF->$method argument 1 must be a scheduler-consumable actor hash reference\n"
        unless ref($actor) eq 'HASH';
    confess "FSM::Scheduler::ISF->$method actor must include scalar actor_name\n"
        unless defined($actor->{actor_name}) && !ref($actor->{actor_name});
    confess "FSM::Scheduler::ISF->$method actor must include transactions array\n"
        unless ref($actor->{transactions}) eq 'ARRAY';
    confess "FSM::Scheduler::ISF->$method actor must include interface hash\n"
        unless ref($actor->{interface}) eq 'HASH';

    return ($actor);
}

1;
