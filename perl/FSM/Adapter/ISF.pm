package FSM::Adapter::ISF;

use v5.20;
use strict;
use warnings;
use Carp qw(confess);
use feature qw(signatures postderef);
no warnings 'experimental::signatures';

use FSM::Adapter::ISF::Parser;
use FSM::Debug;

# ISF Adapter — facade for .isf intent scheduling format parsing
#
# Parses .isf source files into a typed AST that the scheduler consumes.
# Uses Lispish::multi for the raw parse, then validates and classifies
# the AST structure.

sub new($class, %args) {
    my $debug = $args{debug} // 0;

    fsm_trace_enter('Initialize ISF adapter facade', 2);

    my $parser = FSM::Adapter::ISF::Parser->new(debug => $debug);

    my $self = bless {
        parser => $parser,
        debug  => $debug,
    }, $class;

    fsm_trace_exit('ISF adapter facade initialized', 2);
    return $self;
}

sub parse_file($self, $isf_path) {
    fsm_trace_enter("ISF parse_file: $isf_path", 2);
    fsm_debug("Parsing .isf file: $isf_path", 3);
    my $result = $self->{parser}->parse_file($isf_path);
    fsm_trace_exit("ISF parse_file completed for $isf_path", 2);
    return $result;
}

sub parse_source($self, $source_text, $source_label) {
    fsm_trace_enter("ISF parse_source: $source_label", 2);
    my $result = $self->{parser}->parse_source($source_text, $source_label);
    fsm_trace_exit("ISF parse_source completed for $source_label", 2);
    return $result;
}

1;
