package FSM::IR::SourceHIR;

=head1 NAME

FSM::IR::SourceHIR - Private immutable source-facing semantic intent

=head1 DESCRIPTION

Represents the private source-facing HIR boundary above IAL2 and IAL1.
Version 1 models one protocol-neutral valid-ready intent; version 2 adds one
closed concrete-control actor subset. Construction is owned by
C<FSM::IR::SourceHIRBuilder>.

=cut

use v5.20;
use strict;
use warnings;
use Carp qw(confess);
use Scalar::Util qw(blessed);
use feature qw(signatures);
no warnings 'experimental::signatures';

sub _new_validated ($class, $normalized) {
    confess "FSM::IR::SourceHIR->_new_validated must be called with the FSM::IR::SourceHIR class invocant\n"
        unless defined($class) && !ref($class) && $class eq __PACKAGE__;
    confess "FSM::IR::SourceHIR->_new_validated expects exactly one validated hash reference\n"
        unless ref($normalized) eq 'HASH';

    return bless _clone($normalized), $class;
}

sub schema_version ($self) { _validate_object($self, 'schema_version'); return $self->{schema_version} }
sub root_kind ($self) { _validate_object($self, 'root_kind'); return $self->{root_kind} }
sub intent_name ($self) {
    _validate_object($self, 'intent_name');
    _require_root_kind($self, 'intent_name', 'protocol_platform_intent');
    return $self->{intent_name};
}

sub profile ($self) {
    _validate_object($self, 'profile');
    _require_root_kind($self, 'profile', 'protocol_platform_intent');
    return $self->{profile};
}

sub source_object ($self) {
    _validate_object($self, 'source_object');
    _require_root_kind($self, 'source_object', 'protocol_platform_intent');
    return _clone($self->{source_object});
}

sub valid_ready_channel ($self) {
    _validate_object($self, 'valid_ready_channel');
    _require_root_kind($self, 'valid_ready_channel', 'protocol_platform_intent');
    return _clone($self->{valid_ready_channel});
}

sub control_actor ($self) {
    _validate_object($self, 'control_actor');
    _require_root_kind($self, 'control_actor', 'concrete_control');
    return _clone($self->{actor});
}

sub provenance ($self) {
    _validate_object($self, 'provenance');
    return _clone($self->{provenance});
}

sub source_location_for ($self, $semantic_path) {
    _validate_object($self, 'source_location_for');
    confess "FSM::IR::SourceHIR->source_location_for expects one JSON-Pointer-style semantic path\n"
        unless defined($semantic_path) && !ref($semantic_path) && $semantic_path =~ m{\A/};

    my $provenance = $self->{provenance};
    my $spans = $provenance->{spans};
    my $candidate = $semantic_path;

    while (!exists $spans->{$candidate}) {
        last if $candidate eq '/';
        $candidate =~ s{/[^/]+\z}{};
        $candidate = '/' if $candidate eq '';
    }

    my $span = $spans->{$candidate} // $spans->{'/'};
    return {
        source_name => $provenance->{source_name},
        %{_clone($span)},
    };
}

sub as_hashref ($self) {
    _validate_object($self, 'as_hashref');
    return _clone({%$self});
}

sub _validate_object ($self, $method) {
    confess "FSM::IR::SourceHIR->$method must be called on an FSM::IR::SourceHIR object\n"
        unless blessed($self) && $self->isa(__PACKAGE__);
}

sub _require_root_kind ($self, $method, $expected) {
    my $actual = $self->{root_kind} // '<missing>';
    confess "FSM::IR::SourceHIR->$method is unavailable for root_kind '$actual'\n"
        unless $actual eq $expected;
}

sub _clone ($value) {
    return undef unless defined $value;

    if (ref($value) eq 'HASH') {
        return {map { $_ => _clone($value->{$_}) } sort keys %$value};
    }

    if (ref($value) eq 'ARRAY') {
        return [map { _clone($_) } @$value];
    }

    return $value;
}

1;

__END__

=head1 PRIVATE METHODS

=head2 _new_validated

Constructs the immutable object from a builder-validated normalized hash.

=head1 READ-ONLY METHODS

=head2 schema_version

=head2 root_kind

=head2 intent_name

=head2 profile

Return scalar root facts.

=head2 source_object

=head2 valid_ready_channel

=head2 control_actor

=head2 provenance

Return defensive clones of root-appropriate structured SourceHIR branches.

=head2 source_location_for

Resolves exact, nearest-ancestor, then root provenance for one semantic path.

=head2 as_hashref

Returns a defensive clone of the complete private SourceHIR object.

=cut
