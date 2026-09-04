package FSM::VIAL::ExecutionIR;

use v5.20;
use strict;
use warnings;
use Carp qw(confess);
use JSON::PP ();
use Scalar::Util qw(blessed reftype);
use feature qw(signatures postderef);
no warnings 'experimental::signatures';

use FSM::Support::VIALSemanticFamilyContract qw(
    validate_vial_semantic_family_collection
);

my @TOP_LEVEL_KEYS_V1 = qw(
    schema schema_version profile plan_id semantic_identity bridge_identity
    fixture type_table bindings domains transactions events models scoreboards
    coverage faults randomness scenarios operation_graph capability_ledger
    native_extensions source_map resource_summary diagnostics
);
my @TOP_LEVEL_KEYS_V2 = (@TOP_LEVEL_KEYS_V1, 'semantic_families');
my %TOP_LEVEL_KEY = map { $_ => 1 } @TOP_LEVEL_KEYS_V2;

sub _from_builder($class, @args) {
    my $caller = caller;
    confess "$class->_from_builder expects one validated data hash from ExecutionBuilder\n"
        unless $class eq __PACKAGE__
            && ($caller eq 'FSM::VIAL::ExecutionBuilder'
                || $caller eq 'FSM::VIAL::ExecutionBuilderV2')
            && @args == 1 && ref($args[0]) eq 'HASH' && !blessed($args[0]);
    my ($data) = @args;
    my $version = $data->{schema_version};
    confess "VIALExecutionIR schema_version must be 1 or 2\n"
        unless defined($version) && !ref($version) && $version =~ /\A[12]\z/;
    my @keys = $version == 2 ? @TOP_LEVEL_KEYS_V2 : @TOP_LEVEL_KEYS_V1;
    my %expected = map { $_ => 1 } @keys;
    my @unknown = sort grep { !$expected{$_} } keys %$data;
    my @missing = grep { !exists $data->{$_} } @keys;
    confess 'VIALExecutionIR has unknown top-level key(s): ' . join(', ', @unknown) . "\n"
        if @unknown;
    confess 'VIALExecutionIR is missing top-level key(s): ' . join(', ', @missing) . "\n"
        if @missing;
    my $suffix = $version == 2 ? 'v2' : 'v1';
    confess "VIALExecutionIR schema is invalid\n"
        unless $data->{schema} eq "fsmgen.vial_execution_ir.$suffix";
    confess "VIALExecutionIR profile is invalid\n"
        unless $data->{profile} eq "core_directed_single_clock_execution_$suffix";
    validate_vial_semantic_family_collection(
        'execution', $data->{semantic_families},
    ) if $version == 2;
    confess "VIALExecutionIR plan_id is invalid\n"
        unless $data->{plan_id} =~ /\Aplan\/[0-9a-f]{64}\z/;
    confess "VIALExecutionIR success diagnostics must be empty\n"
        unless ref($data->{diagnostics}) eq 'ARRAY' && !@{$data->{diagnostics}};
    _assert_plain($data, '$');
    return bless {data => _clone($data)}, $class;
}

sub top_level_keys($class) {
    confess "$class->top_level_keys requires the exact class invocant\n"
        unless defined($class) && !ref($class) && $class eq __PACKAGE__;
    return [@TOP_LEVEL_KEYS_V1];
}

sub top_level_keys_v2($class) {
    confess "$class->top_level_keys_v2 requires the exact class invocant\n"
        unless defined($class) && !ref($class) && $class eq __PACKAGE__;
    return [@TOP_LEVEL_KEYS_V2];
}

sub schema($self) { _scalar($self, 'schema') }
sub schema_version($self) { 0 + _scalar($self, 'schema_version') }
sub profile($self) { _scalar($self, 'profile') }
sub plan_id($self) { _scalar($self, 'plan_id') }

sub get($self, @args) {
    _validate_object($self, 'get');
    confess __PACKAGE__ . "->get expects one known scalar top-level key\n"
        unless @args == 1 && defined($args[0]) && !ref($args[0])
            && $TOP_LEVEL_KEY{$args[0]} && exists($self->{data}{$args[0]});
    return _clone($self->{data}{$args[0]});
}

sub as_hashref($self) {
    _validate_object($self, 'as_hashref');
    return _clone($self->{data});
}

sub semantic_identity($self) { $self->get('semantic_identity') }
sub bridge_identity($self) { $self->get('bridge_identity') }
sub fixture($self) { $self->get('fixture') }
sub type_table($self) { $self->get('type_table') }
sub bindings($self) { $self->get('bindings') }
sub domains($self) { $self->get('domains') }
sub transactions($self) { $self->get('transactions') }
sub events($self) { $self->get('events') }
sub models($self) { $self->get('models') }
sub scoreboards($self) { $self->get('scoreboards') }
sub coverage($self) { $self->get('coverage') }
sub faults($self) { $self->get('faults') }
sub randomness($self) { $self->get('randomness') }
sub scenarios($self) { $self->get('scenarios') }
sub operation_graph($self) { $self->get('operation_graph') }
sub capability_ledger($self) { $self->get('capability_ledger') }
sub native_extensions($self) { $self->get('native_extensions') }
sub semantic_families($self) { $self->get('semantic_families') }
sub source_map($self) { $self->get('source_map') }
sub resource_summary($self) { $self->get('resource_summary') }
sub diagnostics($self) { $self->get('diagnostics') }

sub _scalar($self, $key) {
    _validate_object($self, $key);
    return $self->{data}{$key};
}

sub _validate_object($self, $method) {
    confess __PACKAGE__ . "->$method must be called on an exact ExecutionIR object\n"
        unless blessed($self) && ref($self) eq __PACKAGE__;
}

sub _assert_plain($value, $path) {
    return unless ref($value);
    return if blessed($value) && $value->isa('JSON::PP::Boolean');
    confess "VIALExecutionIR contains blessed data at $path\n" if blessed($value);
    my $type = reftype($value) || '';
    if ($type eq 'HASH') {
        _assert_plain($value->{$_}, "$path/$_") for sort keys %$value;
        return;
    }
    if ($type eq 'ARRAY') {
        _assert_plain($value->[$_], "$path/$_") for 0 .. $#$value;
        return;
    }
    confess "VIALExecutionIR contains unsupported reference type '$type' at $path\n";
}

sub _clone($value) {
    return undef unless defined $value;
    return $value ? JSON::PP::true : JSON::PP::false
        if blessed($value) && $value->isa('JSON::PP::Boolean');
    return {map { $_ => _clone($value->{$_}) } sort keys %$value}
        if ref($value) eq 'HASH';
    return [map { _clone($_) } @$value] if ref($value) eq 'ARRAY';
    return $value;
}

1;
