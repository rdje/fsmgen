package FSM::Scheduler::ISF::ModuleEmitter;

use v5.20;
use strict;
use warnings;
use Carp qw(confess);
use feature qw(signatures postderef);
no warnings 'experimental::signatures';

use FSM::Debug;

# Emits the .fsm module header, system declaration, and port declarations
# from a parsed ISF actor AST.

sub new($class, %args) {
    return bless { debug => ($args{debug} // 0) }, $class;
}

sub emit_header($self, $actor) {
    fsm_trace_enter('ModuleEmitter emit_header', 3);
    my $name = $actor->{actor_name};
    fsm_trace_exit('ModuleEmitter emit_header', 3);
    return "(?fsm:$name";
}

sub emit_system($self, $actor) {
    fsm_trace_enter('ModuleEmitter emit_system', 3);
    my @lines;
    push @lines, '  (+system';

    # Clock
    my $clock = $actor->{clock};
    confess "emit_system: actor missing clock\n" unless $clock;
    push @lines, "    (clock $clock)";

    # Reset — map ISF reset to .fsm form
    if (my $reset = $actor->{reset}) {
        my $name  = $reset->{name};
        my $kind  = $reset->{kind}  // 'sync';
        my $polar = $reset->{polarity} // 'active_high';

        if ($kind eq 'async' && $polar eq 'active_low') {
            push @lines, "    (areset $name)";
        } elsif ($kind eq 'async') {
            push @lines, "    (areset $name)";
        } else {
            push @lines, "    (sreset $name)";
        }
    }

    push @lines, '  )';
    fsm_trace_exit('ModuleEmitter emit_system', 3);
    return join("\n", @lines);
}

sub emit_ports($self, $actor) {
    fsm_trace_enter('ModuleEmitter emit_ports', 3);
    my @lines;
    push @lines, '  (+size';

    my $iface = $actor->{interface};

    # Inputs
    for my $port (@{$iface->{inputs}}) {
        my $name  = $port->{name};
        my $width = $port->{width} // 1;
        push @lines, "    ($name $width)";
    }

    # Outputs
    for my $port (@{$iface->{outputs}}) {
        my $name  = $port->{name};
        my $width = $port->{width} // 1;
        push @lines, "    ($name $width)";
    }

    push @lines, '  )';
    fsm_trace_exit('ModuleEmitter emit_ports', 3);
    return join("\n", @lines);
}

1;
