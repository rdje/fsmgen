package FSM::Adapter::ISF;

use v5.20;
use strict;
use warnings;
use Carp qw(confess);
use Scalar::Util qw(blessed);
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
    _validate_constructor_receiver($class);
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

sub _validate_constructor_receiver($class) {
    confess "FSM::Adapter::ISF->new must be called with the FSM::Adapter::ISF class invocant\n"
        unless defined($class) && !ref($class) && $class eq 'FSM::Adapter::ISF';
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
    _validate_object_receiver($self, 'parse_file');
    my ($isf_path) = _validate_scalar_args('parse_file', 1, @args);
    _validate_parse_file_path($isf_path);
    fsm_trace_enter("ISF parse_file: $isf_path", 2);
    fsm_debug("Parsing .isf file: $isf_path", 3);
    my $result = $self->{parser}->parse_file($isf_path);
    fsm_trace_exit("ISF parse_file completed for $isf_path", 2);
    return $result;
}

sub parse_source($self, @args) {
    _validate_object_receiver($self, 'parse_source');
    my ($source_text, $source_label) = _validate_scalar_args('parse_source', 2, @args);
    fsm_trace_enter("ISF parse_source: $source_label", 2);
    my $result = $self->{parser}->parse_source($source_text, $source_label);
    fsm_trace_exit("ISF parse_source completed for $source_label", 2);
    return $result;
}

sub _validate_object_receiver($self, $method) {
    confess "FSM::Adapter::ISF->$method must be called on an FSM::Adapter::ISF object\n"
        unless blessed($self) && $self->isa('FSM::Adapter::ISF');
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

sub _validate_parse_file_path($isf_path) {
    confess "FSM::Adapter::ISF->parse_file argument 1 must name a readable .isf file\n"
        unless $isf_path =~ /\.isf\z/i && -f $isf_path && -r $isf_path;
}

1;

__END__

=encoding utf8

=head1 NAME

FSM::Adapter::ISF - Parse IAL1 source through the bounded ISF facade

=head1 SYNOPSIS

    use FSM::Adapter::ISF;
    my $parser = FSM::Adapter::ISF->new(debug => 0);
    my $actor = $parser->parse_file('isf/i2c_master.isf');
    print $actor->{actor_name}, "\n";

Run examples from the repository root with C<perl -Iperl>.

=head1 METHODS

=head2 new(debug =E<gt> 0)

Constructs a parser facade. Call on the exact class name. The constructor takes
an even option/value list; C<debug> is the only option and defaults to zero.
Unknown options are rejected. Returns an C<FSM::Adapter::ISF> object.

=head2 parse_file($path)

Takes exactly one defined scalar naming a readable C<.isf> file, with a
case-insensitive extension. Reads and parses that source and resolves its
declared library/actor references. Returns the scheduler-consumable actor hash,
including C<actor_name>, C<interface> and C<transactions>. Repository-relative
paths are recommended.

=head2 parse_source($text, $source_label)

Takes exactly two defined scalar arguments: source text and its origin label.
Returns the same actor shape as C<parse_file>. The label identifies diagnostics
and provides origin context for library resolution; it is not a substitute for
supplying imported sources. Source text must contain one entry actor. Parsing
success alone does not establish that every construct can be scheduled or
generated for a particular backend.

=head1 ERRORS AND EFFECTS

Invalid receiver/argument shape, unreadable files and parse/resolution failures
throw Perl exceptions. Use C<eval> at an application boundary. Parsing can read
referenced library sources and emit configured debug traces. It does not emit
HDL or run a simulation.

=head1 CONTRACT AND STABILITY

This is the Perl parsing binding described in the manual's Extensions and
Embedding chapter and the ISF interface contracts. The returned actor is an
in-process scheduler input, not a frozen JSON interchange format. Do not depend
on underscore-prefixed metadata. Use normalized reports for external consumers.
Scheduling is provided by L<FSM::Scheduler::ISF>.

=cut
