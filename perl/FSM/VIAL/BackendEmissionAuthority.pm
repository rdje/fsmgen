package FSM::VIAL::BackendEmissionAuthority;

use strict;
use warnings;
use Carp qw(confess);
use Exporter 'import';
use Scalar::Util qw(blessed);

our @EXPORT_OK = qw(
    assert_backend_emission_profile_authorities
    backend_emission_profile_authorities
);

my $AUTHORITIES = {
    sv_portable_verilator => {
        generated_source_artifacts => 3,
        total_artifacts => 8,
        generated_source_bytes => 16_777_216,
        source_map_entries => 1_000_000,
    },
    vhdl_portable_ghdl => {
        generated_source_artifacts => 6,
        total_artifacts => 17,
        generated_source_bytes => 16_777_216,
        reference_source_map_entries => 59,
        static_validation_checks => 20,
    },
    vhdl_osvvm_qualified => {
        portable_foundation_source_artifacts => 6,
        wrapper_adapter_source_artifacts => 1,
        total_source_artifacts => 7,
        total_artifacts => 16,
        portable_foundation_source_bytes => 16_777_216,
        wrapper_adapter_source_bytes => 4_351,
        wrapper_adapter_source_map_entries => 7,
        reference_source_map_entries => 66,
        wrapper_static_validation_checks => 12,
        portable_foundation_static_validation_checks => 20,
        provider_materialization => 'external_exact_osvvm_2026_05',
    },
    'sv_uvm_emit.accellera_2020_3_1' => {
        generated_source_artifacts => 10,
        total_artifacts => 16,
        generated_source_bytes => 16_777_216,
        source_map_entries => 1_000_000,
        selected_operation_count => 21,
        selected_source_map_entries => 75,
        selected_static_validation_checks => 14,
        selected_mapping_matrix_entries => 25,
        execution_status => 'emission_and_static_review_only',
    },
};

sub backend_emission_profile_authorities {
    my $copy = _clone($AUTHORITIES);
    assert_backend_emission_profile_authorities($copy);
    return $copy;
}

sub assert_backend_emission_profile_authorities {
    my ($actual) = @_;
    confess "backend-emission authorities must be one unblessed hash\n"
        unless @_ == 1 && ref($actual) eq 'HASH' && !blessed($actual);
    _assert_exact_keys($actual, [sort keys %$AUTHORITIES], 'backend-emission profile set');
    for my $profile (sort keys %$AUTHORITIES) {
        my $authority = $actual->{$profile};
        confess "backend-emission authority '$profile' must be one unblessed hash\n"
            unless ref($authority) eq 'HASH' && !blessed($authority);
        my $expected = $AUTHORITIES->{$profile};
        _assert_exact_keys(
            $authority,
            [sort keys %$expected],
            "backend-emission authority '$profile'",
        );
        for my $field (sort keys %$expected) {
            confess "backend-emission authority '$profile/$field' must be a scalar\n"
                if !defined($authority->{$field}) || ref($authority->{$field});
            confess "backend-emission authority '$profile/$field' contradicts the selected value\n"
                unless "$authority->{$field}" eq "$expected->{$field}";
        }
    }
    return 1;
}

sub _assert_exact_keys {
    my ($value, $expected, $label) = @_;
    my %expected = map { $_ => 1 } @$expected;
    my @unknown = sort grep { !$expected{$_} } keys %$value;
    my @missing = grep { !exists($value->{$_}) } @$expected;
    confess "$label has unknown field '$unknown[0]'\n" if @unknown;
    confess "$label is missing field '$missing[0]'\n" if @missing;
}

sub _clone {
    my ($value) = @_;
    return undef unless defined $value;
    return {map { $_ => _clone($value->{$_}) } keys %$value}
        if ref($value) eq 'HASH';
    return [map { _clone($_) } @$value] if ref($value) eq 'ARRAY';
    return $value;
}

1;
