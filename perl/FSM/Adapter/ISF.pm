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

sub new($class, @constructor_args) {
    my %args = _validate_constructor_args($class, @constructor_args);
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

sub parse_file($self, @args) {
    my ($isf_path) = _validate_scalar_args('parse_file', 1, @args);
    fsm_trace_enter("ISF parse_file: $isf_path", 2);
    fsm_debug("Parsing .isf file: $isf_path", 3);
    my $result = $self->{parser}->parse_file($isf_path);
    fsm_trace_exit("ISF parse_file completed for $isf_path", 2);
    return $result;
}

sub parse_source($self, @args) {
    my ($source_text, $source_label) = _validate_scalar_args('parse_source', 2, @args);
    fsm_trace_enter("ISF parse_source: $source_label", 2);
    my $result = $self->{parser}->parse_source($source_text, $source_label);
    fsm_trace_exit("ISF parse_source completed for $source_label", 2);
    return $result;
}

sub _validate_scalar_args($method, $expected, @args) {
    confess "FSM::Adapter::ISF->$method expects exactly $expected scalar argument(s)\n"
        unless @args == $expected;

    for my $index (0 .. $#args) {
        my $arg = $args[$index];
        confess "FSM::Adapter::ISF->$method argument " . ($index + 1) . " must be a defined scalar\n"
            if !defined($arg) || ref($arg);
    }

    return @args;
}

1;
