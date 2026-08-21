#!/usr/bin/env perl

use strict;
use warnings;

use File::Spec;
use FindBin;
use Test::More;

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::Support::VIALNativeUVMEmissionContract qw(
    build_vial_native_uvm_emission_contract
);
use FSM::Support::VIALVHDLEmissionContract qw(
    build_vial_vhdl_emission_contract
);
use FSM::VIAL::ArchitectureScaleWorkload;
use FSM::VIAL::BackendEmissionAuthority qw(
    assert_backend_emission_profile_authorities
    backend_emission_profile_authorities
);

my $catalog = FSM::VIAL::ArchitectureScaleWorkload->catalog;

subtest 'backend-emission catalog carries exact profile-local authorities' => sub {
    is_deeply(
        $catalog->{backend_profiles}{sv_portable_verilator}{structural_authority},
        {
            generated_source_artifacts => 3,
            total_artifacts => 8,
            generated_source_bytes => 16_777_216,
            source_map_entries => 1_000_000,
        },
        'portable SystemVerilog names its complete artifact and source limits',
    );
    is_deeply(
        $catalog->{backend_profiles}{vhdl_portable_ghdl}{structural_authority},
        {
            generated_source_artifacts => 6,
            total_artifacts => 17,
            generated_source_bytes => 16_777_216,
            reference_source_map_entries => 59,
            static_validation_checks => 20,
        },
        'portable VHDL names its complete structural authority',
    );
    is_deeply(
        $catalog->{backend_profiles}{vhdl_osvvm_qualified}{structural_authority},
        {
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
        'OSVVM separates its portable foundation, wrapper adapter, and provider',
    );
    is_deeply(
        $catalog->{backend_profiles}{'sv_uvm_emit.accellera_2020_3_1'}{structural_authority},
        {
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
        'native UVM names its enforced caps and exact selected matrix',
    );
};

subtest 'support contracts project the same OSVVM and native-UVM authorities' => sub {
    my $vhdl = build_vial_vhdl_emission_contract()->{limits};
    is_deeply(
        {map { $_ => $vhdl->{$_} } qw(
            osvvm_portable_foundation_source_artifacts
            osvvm_wrapper_adapter_source_artifacts
            osvvm_total_source_artifacts
            osvvm_total_artifacts
            osvvm_portable_foundation_source_bytes
            osvvm_wrapper_adapter_source_bytes
            osvvm_wrapper_adapter_source_map_entries
            osvvm_source_map_entries
            osvvm_static_validation_checks
            osvvm_portable_foundation_static_validation_checks
        )},
        {
            osvvm_portable_foundation_source_artifacts => 6,
            osvvm_wrapper_adapter_source_artifacts => 1,
            osvvm_total_source_artifacts => 7,
            osvvm_total_artifacts => 16,
            osvvm_portable_foundation_source_bytes => 16_777_216,
            osvvm_wrapper_adapter_source_bytes => 4_351,
            osvvm_wrapper_adapter_source_map_entries => 7,
            osvvm_source_map_entries => 66,
            osvvm_static_validation_checks => 12,
            osvvm_portable_foundation_static_validation_checks => 20,
        },
        'VHDL discovery publishes the repaired OSVVM authority without ambiguity',
    );

    my $uvm = build_vial_native_uvm_emission_contract()->{limits};
    is_deeply(
        {map { $_ => $uvm->{$_} } qw(
            generated_source_artifacts generated_source_bytes total_artifacts
            source_map_entries selected_operation_count selected_source_map_entries
            selected_static_validation_checks selected_mapping_matrix_entries
        )},
        {
            generated_source_artifacts => 10,
            generated_source_bytes => 16_777_216,
            total_artifacts => 16,
            source_map_entries => 1_000_000,
            selected_operation_count => 21,
            selected_source_map_entries => 75,
            selected_static_validation_checks => 14,
            selected_mapping_matrix_entries => 25,
        },
        'native-UVM discovery publishes the selected matrix beside enforced caps',
    );
};

subtest 'authority source rejects unknown, missing, and contradictory fields' => sub {
    my $first = backend_emission_profile_authorities();
    ok(assert_backend_emission_profile_authorities($first),
        'the canonical closed authority set validates');

    $first->{vhdl_osvvm_qualified}{reference_source_map_entries} = 13;
    dies_like(
        sub { assert_backend_emission_profile_authorities($first) },
        qr{vhdl_osvvm_qualified/reference_source_map_entries.*contradicts the selected value},
        'the obsolete thirteen-entry OSVVM map view fails closed',
    );
    is(backend_emission_profile_authorities()
            ->{vhdl_osvvm_qualified}{reference_source_map_entries},
        66, 'a rejected caller mutation cannot alter canonical authority');

    my $unknown = backend_emission_profile_authorities();
    $unknown->{'sv_uvm_emit.accellera_2020_3_1'}{unbounded_maps} = 1;
    dies_like(
        sub { assert_backend_emission_profile_authorities($unknown) },
        qr{sv_uvm_emit\.accellera_2020_3_1.*unknown field 'unbounded_maps'},
        'an unknown native-UVM authority field fails closed',
    );

    my $missing = backend_emission_profile_authorities();
    delete $missing->{vhdl_osvvm_qualified}{portable_foundation_source_bytes};
    dies_like(
        sub { assert_backend_emission_profile_authorities($missing) },
        qr{vhdl_osvvm_qualified.*missing field 'portable_foundation_source_bytes'},
        'a missing portable-foundation byte authority fails closed',
    );
};

done_testing;

sub dies_like {
    my ($code, $pattern, $label) = @_;
    my $ok = eval {
        $code->();
        1;
    };
    ok(!$ok, "$label dies");
    like($@, $pattern, "$label has the selected diagnostic");
}
