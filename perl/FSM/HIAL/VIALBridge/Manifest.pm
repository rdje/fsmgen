package FSM::HIAL::VIALBridge::Manifest;

use v5.20;
use strict;
use warnings;
use Carp qw(confess);
use JSON::PP ();
use Scalar::Util qw(blessed);
use feature qw(signatures postderef);
no warnings 'experimental::signatures';

my @TOP_LEVEL_KEYS = qw(
    schema schema_version profile manifest_id producer entry_source_id sources
    review_route review_artifacts units configurations types endpoints domains
    transactions events protocols observations probes backend_bindings
    required_capabilities unsupported_residue source_map diagnostics
);
my %TOP_LEVEL_KEY = map { $_ => 1 } @TOP_LEVEL_KEYS;

sub _from_builder($class, @args) {
    my $caller = caller;
    confess "$class->_from_builder expects a manifest hash and builder token\n"
        unless @args == 2 && ref($args[0]) eq 'HASH'
            && defined($args[1]) && !ref($args[1])
            && $args[1] eq 'FSM::HIAL::VIALBridge::Builder'
            && $caller eq 'FSM::HIAL::VIALBridge::Builder';
    my ($data) = @args;
    my @unknown = sort grep { !$TOP_LEVEL_KEY{$_} } keys %$data;
    my @missing = grep { !exists $data->{$_} } @TOP_LEVEL_KEYS;
    confess 'HIAL/VIAL bridge manifest has unknown top-level key(s): '
        . join(', ', @unknown) . "\n" if @unknown;
    confess 'HIAL/VIAL bridge manifest is missing top-level key(s): '
        . join(', ', @missing) . "\n" if @missing;
    return bless { data => _clone_json_value($data) }, $class;
}

sub top_level_keys($class) {
    confess "$class->top_level_keys must be called with the manifest class invocant\n"
        unless defined($class) && !ref($class) && $class eq __PACKAGE__;
    return [@TOP_LEVEL_KEYS];
}

sub as_hashref($self) {
    _validate_object($self, 'as_hashref');
    return _clone_json_value($self->{data});
}

sub get($self, @args) {
    _validate_object($self, 'get');
    confess __PACKAGE__ . "->get expects exactly one scalar top-level key\n"
        unless @args == 1 && defined($args[0]) && !ref($args[0]);
    my $key = $args[0];
    confess __PACKAGE__ . "->get unknown top-level key '$key'\n"
        unless $TOP_LEVEL_KEY{$key};
    return _clone_json_value($self->{data}{$key});
}

sub schema($self) { _scalar_accessor($self, 'schema') }
sub schema_version($self) { _scalar_accessor($self, 'schema_version') }
sub profile($self) { _scalar_accessor($self, 'profile') }
sub manifest_id($self) { _scalar_accessor($self, 'manifest_id') }

sub _scalar_accessor($self, $key) {
    _validate_object($self, $key);
    return $self->{data}{$key};
}

sub _validate_object($self, $method) {
    confess __PACKAGE__ . "->$method must be called on a manifest object\n"
        unless blessed($self) && $self->isa(__PACKAGE__);
}

sub _clone_json_value($value) {
    return undef unless defined $value;
    if (blessed($value) && $value->isa('JSON::PP::Boolean')) {
        return $value ? JSON::PP::true : JSON::PP::false;
    }
    if (ref($value) eq 'HASH') {
        return { map { $_ => _clone_json_value($value->{$_}) } sort keys %$value };
    }
    if (ref($value) eq 'ARRAY') {
        return [map { _clone_json_value($_) } @$value];
    }
    confess 'HIAL/VIAL bridge manifest contains a non-JSON reference of class '
        . (blessed($value) || ref($value)) . "\n" if ref($value);
    return $value;
}

1;
