package FSM::AllocationTransitionDependencies;

use v5.20;
use strict;
use warnings;
use Hash::Util::FieldHash qw(fieldhash);
use Scalar::Util qw(blessed refaddr);

fieldhash my %DEPENDENCIES;

sub remember {
    my ($class, %args) = @_;
    my $holder = $args{holder};
    return $holder unless ref($holder) eq 'HASH';
    delete $DEPENDENCIES{$holder};
    return $holder if tied(%$holder);
    return $holder unless join(',', sort keys %$holder) eq 'record,state';
    return $holder if tied($holder->{state});
    return $holder unless ref($holder->{record}) eq 'HASH'
        && defined($holder->{state}) && !ref($holder->{state})
        && ref($args{objects}) eq 'ARRAY' && @{$args{objects}};
    my %members;
    for my $object (@{$args{objects}}) {
        return $holder unless blessed($object)
            && UNIVERSAL::isa($object, 'FSM::CoreAST::Signal');
        $members{refaddr($object)} = 1;
    }
    # Keep only detached scalar data. Weak holder keys and numeric identities
    # cannot retain a Core graph or lend validity to a later object lifetime.
    $DEPENDENCIES{$holder} = {
        snapshot => $holder->{state},
        record_identity => refaddr($holder->{record}),
        members => \%members,
    };
    return $holder;
}

sub may_affect {
    my ($class, %args) = @_;
    my $holder = $args{holder};
    return 1 unless ref($holder) eq 'HASH';
    return 1 if tied(%$holder);
    return 1 unless join(',', sort keys %$holder) eq 'record,state';
    return 1 if tied($holder->{state});
    my $known = $DEPENDENCIES{$holder} or return 1;
    return 1 unless ref($holder->{record}) eq 'HASH'
        && refaddr($holder->{record}) == $known->{record_identity}
        && defined($holder->{state}) && !ref($holder->{state})
        && $holder->{state} eq $known->{snapshot};
    my $signal = $args{signal};
    return 1 unless blessed($signal) && UNIVERSAL::isa($signal, 'FSM::CoreAST::Signal');
    # This only excludes a known non-member. A potential member still needs
    # every existing registry, complete capture, revision and transition check.
    return exists($known->{members}{refaddr($signal)}) ? 1 : 0;
}

1;

=head1 NAME

FSM::AllocationTransitionDependencies - private dependency selection for source writes

=head1 DESCRIPTION

Successful allocation-holder constructors record their complete physical Signal
participants without adding fields to Signals or detached holder records.
The weak index stores only scalar identities and the captured snapshot. It does
not retain Core objects or cache currentness, source admission or validation.

An unchanged known snapshot can exclude an unrelated Signal before expensive
source traversal. Potential dependencies still undergo the existing complete
live checks. Unknown, copied, tied or changed snapshots take the ordinary full
validation path. Reusing a physical address can only select extra validation;
the existing lifetime and currentness proofs remain authoritative.

=head1 INTERNAL INTERFACE

C<remember(holder =E<gt> $holder, objects =E<gt> \@signals)> returns the same
holder. Only successful source constructors supply the actual complete capture;
this utility is not a public policy-installation API.

C<may_affect(holder =E<gt> $holder, signal =E<gt> $signal)> conservatively selects
events for the original validation path. A true result proves no validity.

=cut
