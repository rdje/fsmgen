package FSM::VIAL::Backend::VHDLResultSchema;

use v5.20;
use strict;
use warnings;
use Carp qw(confess);
use feature qw(signatures);
no warnings 'experimental::signatures';

my $PARITY_SCHEMA = 'fsmgen.vial_vhdl_portable_outcomes.v1';
my $PARITY_SCHEMA_VERSION = 1;
my @PARITY_PROJECTION_KEYS = qw(outcomes plan_id schema schema_version);
my @PARITY_OUTCOME_KEYS = qw(
    bus_accepts final_read_data_bits final_ready final_response
    nonzero_read_data_cycles ready_low_cycles response_error_cycles
    scenario_id status storage_bits
);

sub parity_schema($class) {
    _exact_class($class, 'parity_schema');
    return $PARITY_SCHEMA;
}

sub parity_schema_version($class) {
    _exact_class($class, 'parity_schema_version');
    return $PARITY_SCHEMA_VERSION;
}

sub parity_projection_keys($class) {
    _exact_class($class, 'parity_projection_keys');
    return [@PARITY_PROJECTION_KEYS];
}

sub parity_outcome_keys($class) {
    _exact_class($class, 'parity_outcome_keys');
    return [@PARITY_OUTCOME_KEYS];
}

sub _exact_class($class, $method) {
    confess __PACKAGE__ . "->$method requires the exact class invocant\n"
        unless defined($class) && !ref($class) && $class eq __PACKAGE__;
    return;
}

1;
