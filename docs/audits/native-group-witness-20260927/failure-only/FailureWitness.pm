package FailureWitness;
use strict;
use warnings;
use Fcntl qw(F_GETFL O_APPEND S_ISREG);
use JSON::PP ();
use Time::HiRes qw(clock_gettime CLOCK_MONOTONIC);
use GroupWitness ();

sub new {
    my ($class, $sink, $label) = @_;
    die "invalid failure witness label\n"
        unless defined($label) && $label =~ /\A[a-z_]{1,64}\z/;
    my @state = stat($sink);
    my $flags = fcntl($sink, F_GETFL, 0);
    die "failure witness needs an append-only regular capture\n"
        unless @state && S_ISREG($state[2]) && defined($flags) && ($flags & O_APPEND);
    return bless {sink => $sink, label => $label, sequence => 0,
                  capture_error => undef}, $class;
}

sub _query_context { return GroupWitness::context(0) }

sub _write {
    my ($self, $record) = @_;
    my $data = JSON::PP->new->canonical->encode($record) . "\n";
    my @state = stat($self->{sink});
    die "failure witness capture envelope exceeded\n"
        unless @state && length($data) <= 4096 && $state[7] + length($data) <= 1_048_576;
    my $size = syswrite($self->{sink}, $data);
    die "failure witness write failed\n" unless defined($size) && $size == length($data);
}

sub wrap {
    my ($self, $original) = @_;
    die "failure witness requires the original call\n" unless ref($original) eq 'CODE';
    return sub {
        my @arguments = @_;
        my $result = $original->(@arguments);
        my $native_errno = 0 + $!;
        # Match the supervisor's return-value admission rule. A successful
        # call may retain stale errno. Parent race closure is passed through.
        if (@arguments == 2 && $arguments[0] == 0 && $arguments[1] == 0
                && !(defined($result) && $result == 0)) {
            my $observed = int(clock_gettime(CLOCK_MONOTONIC) * 1_000_000_000);
            my $context = eval { $self->_query_context() };
            my $context_error = $@ || undef;
            my $record = {
                event => 'child_setpgid_failure', label => $self->{label}, pid => $$,
                sequence => ++$self->{sequence}, arguments => \@arguments,
                result => $result, errno => $native_errno,
                observed_monotonic_ns => $observed,
                context_completed_monotonic_ns => int(clock_gettime(CLOCK_MONOTONIC) * 1_000_000_000),
                context => $context, context_error => $context_error,
            };
            eval { $self->_write($record); 1 } or do {
                $self->{capture_error} //= $@ || 'unknown failure witness write error';
                warn $self->{capture_error};
            };
        }
        $! = $native_errno;
        return $result;
    };
}

sub capture_error { return $_[0]{capture_error} }
1;
