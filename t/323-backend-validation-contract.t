#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use File::Spec;
use FindBin;
use IPC::Cmd qw(run);
use JSON::PP qw(decode_json);

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::Support::BackendValidationContract qw(
    backend_validation_contract_source
    backend_validation_nested_contract_keys
    backend_validation_public_top_level_keys
    build_backend_validation_contract
);
use FSM::Support::CapabilityManifest qw(build_capability_manifest);
use FSM::Support::HDLExternalValidationContract qw(
    hdl_external_validation_contract_source
);

my $manifest = build_capability_manifest();

subtest 'contract exposes the bounded backend-validation section' => sub {
    my $contract = build_backend_validation_contract();

    is($contract->{schema_version}, 1, 'contract exposes schema version');
    is($contract->{status}, 'bounded_public', 'contract marks backend_validation as bounded public');
    is(
        $contract->{contract_source},
        backend_validation_contract_source(),
        'contract records its own owner',
    );
    is(
        $contract->{report_source},
        'FSM::Support::CapabilityManifest',
        'contract records the manifest builder owner',
    );
    is_deeply(
        $contract->{public_top_level_presence_keys},
        backend_validation_public_top_level_keys(),
        'contract publishes the bounded backend-validation top-level keys',
    );
    is_deeply(
        $contract->{nested_contract_keys},
        backend_validation_nested_contract_keys(),
        'contract publishes the bounded backend-validation nested-contract keys',
    );
    is_deeply(
        $contract->{nested_contract_source_map},
        {
            systemverilog_external => hdl_external_validation_contract_source(),
        },
        'contract publishes the bounded backend-validation nested-contract ownership map',
    );
    ok(
        $contract->{systemverilog_external_contract_advertised},
        'contract says the external SystemVerilog validation contract is advertised',
    );
    ok(
        !$contract->{full_backend_validation_section_stable},
        'contract keeps broader backend-validation stabilization separate',
    );
};

subtest 'in-process capability manifest backend-validation section conforms to the bounded contract' => sub {
    my $backend_validation = $manifest->{backend_validation};
    my $contract = build_backend_validation_contract();

    assert_keys_present(
        $backend_validation,
        backend_validation_public_top_level_keys(),
        'backend-validation section keeps bounded top-level keys',
    );
    is(
        $backend_validation->{section_contract}{contract_source},
        backend_validation_contract_source(),
        'backend-validation section advertises the section contract owner',
    );
    assert_nested_contract_sources(
        $backend_validation,
        $contract->{nested_contract_source_map},
        'backend-validation section keeps bounded nested contract owners',
    );
};

subtest 'CLI capability manifest keeps the bounded backend-validation contract' => sub {
    my ($success, $error_message, $full_buf, $stdout_buf, $stderr_buf) = run(
        command => ['./bin/fsmgen', '--capability-manifest'],
    );

    ok($success, 'capability manifest CLI succeeds');
    is(join('', @{$stderr_buf || []}), '', 'capability manifest CLI keeps stderr clean');

    my $decoded = eval { decode_json(join('', @{$stdout_buf || []})) };
    ok($decoded, 'capability manifest CLI emits decodable JSON');

    my $backend_validation = $decoded->{backend_validation};
    my $contract = build_backend_validation_contract();
    assert_keys_present(
        $backend_validation,
        backend_validation_public_top_level_keys(),
        'CLI backend-validation section keeps bounded top-level keys',
    );
    is(
        $backend_validation->{section_contract}{contract_source},
        backend_validation_contract_source(),
        'CLI backend-validation section advertises the section contract owner',
    );
    assert_nested_contract_sources(
        $backend_validation,
        $contract->{nested_contract_source_map},
        'CLI backend-validation section keeps bounded nested contract owners',
    );
};

done_testing();

sub assert_keys_present {
    my ($payload, $keys, $label) = @_;
    for my $key (@{$keys || []}) {
        ok(exists $payload->{$key}, "$label: keeps key $key");
    }
}

sub assert_nested_contract_sources {
    my ($payload, $expected_map, $label) = @_;
    for my $key (sort keys %{$expected_map || {}}) {
        is(
            $payload->{$key}{contract_source},
            $expected_map->{$key},
            "$label: $key keeps advertised contract owner",
        );
    }
}
