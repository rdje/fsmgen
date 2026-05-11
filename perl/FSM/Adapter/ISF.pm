package FSM::Adapter::ISF;

use v5.20;
use strict;
use warnings;
use Carp qw(confess);
use feature qw(signatures postderef);
no warnings 'experimental::signatures';

use FSM::Adapter::ISF::Parser;

# ISF Adapter — facade for .isf intent scheduling format parsing
#
# Parses .isf source files into a typed AST that the scheduler consumes.
# Uses Lispish::multi for the raw parse, then validates and classifies
# the AST structure.

sub new($class, %args) {
    my $debug = $args{debug} // 0;

    my $parser = FSM::Adapter::ISF::Parser->new(debug => $debug);

    return bless {
        parser => $parser,
        debug  => $debug,
    }, $class;
}

sub parse_file($self, $isf_path) {
    return $self->{parser}->parse_file($isf_path);
}

sub parse_source($self, $source_text, $source_label) {
    return $self->{parser}->parse_source($source_text, $source_label);
}

1;
