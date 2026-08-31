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
my @PARITY_COUNTER_KEYS = qw(
    bus_accepts nonzero_read_data_cycles ready_low_cycles
    response_error_cycles
);
my @PARITY_SCALAR_KEYS = qw(final_ready final_response);
my %PARITY_SCALAR_CATALOG_BINDINGS = (
    final_ready => 'endpoint/HREADYOUT',
    final_response => 'endpoint/HRESP',
);
my %PARITY_BIT_CATALOG_BINDINGS = (
    final_read_data_bits => 'endpoint/HRDATA',
    storage_bits => 'probe/reg_data_q',
);
my $RUNTIME_RESULT_CONTRACT = {
    schema => 'fsmgen.verification_result_manifest.v1',
    schema_version => 1,
    execution_profile => 'core_directed_single_clock_execution_v1',
    backend_profile => {
        capabilities => [
            'vial.backend.vhdl_portable_ghdl.v1',
            'vial.backend.vhdl_portable_ghdl.result_manifest_projection.v1',
        ],
        id => 'vhdl_portable_ghdl',
        methodology => 'plain_vhdl_no_provider',
        target_language => 'VHDL',
        tool_name => undef,
        tool_version => undef,
        uvm_revision => undef,
        vhdl_standard => 'IEEE 1076-2008',
    },
    capability_evidence => {
        native_only => [],
        required => [],
        satisfied => ['portable_checking_projection'],
        unsatisfied => [],
    },
    backend_evidence => {
        analysis_status => 'not_run',
        elaboration_status => 'not_run',
        runtime_status => 'projection_only',
    },
    collection_keys => [qw(
        random_decisions events drives samples transactions expectations
        models scoreboards coverage faults fibers native_extensions
        diagnostics exclusions
    )],
    empty_collection_keys => [qw(
        events drives samples transactions expectations models fibers
        native_extensions exclusions
    )],
    metric_keys => [qw(
        coverage_not_stalled coverage_stalled diagnostic_records
        fault_applications scoreboard_comparisons scoreboard_mismatches
    )],
    coverage_record_keys => [qw(bins coverpoint_id)],
    coverage_bin_keys => [qw(not_stalled stalled)],
    coverage_coverpoint_id => 'coverpoint/stall_seen',
    fault_record_keys => [qw(applications fault_id kind)],
    fault_id => 'fault/unsupported_size',
    fault_kind => 'substitution',
    scoreboard_record_keys => [qw(capacity comparisons mismatches)],
    scoreboard_capacity => 4,
    diagnostic_record_keys => [qw(code logical_time outcome severity)],
    diagnostic_time_keys => [qw(cycle local_index phase_rank static_rank)],
};

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

sub parity_counter_keys($class) {
    _exact_class($class, 'parity_counter_keys');
    return [@PARITY_COUNTER_KEYS];
}

sub parity_scalar_keys($class) {
    _exact_class($class, 'parity_scalar_keys');
    return [@PARITY_SCALAR_KEYS];
}

sub parity_scalar_catalog_bindings($class) {
    _exact_class($class, 'parity_scalar_catalog_bindings');
    return {%PARITY_SCALAR_CATALOG_BINDINGS};
}

sub parity_bit_catalog_bindings($class) {
    _exact_class($class, 'parity_bit_catalog_bindings');
    return {%PARITY_BIT_CATALOG_BINDINGS};
}

sub runtime_result_contract($class) {
    _exact_class($class, 'runtime_result_contract');
    return _clone_contract($RUNTIME_RESULT_CONTRACT);
}

sub _clone_contract($value) {
    return $value unless ref($value);
    return [map { _clone_contract($_) } @$value] if ref($value) eq 'ARRAY';
    return {map { $_ => _clone_contract($value->{$_}) } keys %$value}
        if ref($value) eq 'HASH';
    confess __PACKAGE__ . " runtime-result contract is not plain data\n";
}

sub _exact_class($class, $method) {
    confess __PACKAGE__ . "->$method requires the exact class invocant\n"
        unless defined($class) && !ref($class) && $class eq __PACKAGE__;
    return;
}

1;
