#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use File::Spec;
use FindBin;
use IPC::Cmd qw(run);
use JSON::PP qw(decode_json);

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::Support::CapabilityManifest qw(build_capability_manifest);
use FSM::Support::CheckDiagnosticsContract qw(
    check_diagnostics_contract_source
    check_json_public_top_level_keys
);
use FSM::Support::DiagnosticsContract qw(
    build_diagnostics_contract
    diagnostics_contract_source
    diagnostics_list_keys
    diagnostics_nested_contract_keys
    diagnostics_nested_presence_key_map
    diagnostics_public_top_level_keys
    diagnostics_scalar_string_keys
);
use FSM::Support::DiagnosticCodeRegistryContract qw(
    diagnostic_code_registry_contract_source
    diagnostic_code_registry_entry_keys
    diagnostic_code_registry_family_values
    diagnostic_code_registry_public_keys
);

my $manifest = build_capability_manifest();

subtest 'contract exposes the bounded diagnostics section' => sub {
    my $contract = build_diagnostics_contract();

    is($contract->{schema_version}, 1, 'contract exposes schema version');
    is($contract->{status}, 'bounded_public', 'contract marks diagnostics as bounded public');
    is(
        $contract->{contract_source},
        diagnostics_contract_source(),
        'contract records its own owner',
    );
    is(
        $contract->{report_source},
        'FSM::Support::CapabilityManifest',
        'contract records the manifest builder owner',
    );
    is_deeply(
        $contract->{public_top_level_presence_keys},
        diagnostics_public_top_level_keys(),
        'contract publishes the bounded diagnostics top-level keys',
    );
    is_deeply(
        $contract->{scalar_string_keys},
        diagnostics_scalar_string_keys(),
        'contract publishes the bounded diagnostics scalar-string keys',
    );
    is_deeply(
        $contract->{list_keys},
        diagnostics_list_keys(),
        'contract publishes the bounded diagnostics list keys',
    );
    is_deeply(
        $contract->{nested_contract_keys},
        diagnostics_nested_contract_keys(),
        'contract publishes the bounded diagnostics nested-contract keys',
    );
    is_deeply(
        $contract->{nested_contract_source_map},
        {
            stable_code_registry => diagnostic_code_registry_contract_source(),
            check_json => check_diagnostics_contract_source(),
        },
        'contract publishes the bounded diagnostics nested-contract ownership map',
    );
    is_deeply(
        $contract->{nested_presence_key_map},
        diagnostics_nested_presence_key_map(),
        'contract publishes the bounded diagnostics nested key-family map',
    );
    is_deeply(
        $contract->{stable_code_entry_presence_keys},
        diagnostic_code_registry_entry_keys(),
        'contract reuses the bounded stable-code entry keys',
    );
    is_deeply(
        $contract->{stable_code_family_values},
        diagnostic_code_registry_family_values(),
        'contract reuses the bounded stable-code family values',
    );
    ok($contract->{stable_code_registry_contract_advertised}, 'contract says stable-code registry contract is advertised');
    ok($contract->{check_json_contract_advertised}, 'contract says check-json contract is advertised');
    ok(!$contract->{full_diagnostics_section_stable}, 'contract keeps broader diagnostics stabilization separate');
};

subtest 'in-process capability manifest diagnostics section conforms to the bounded contract' => sub {
    my $diagnostics = $manifest->{diagnostics};
    my $contract = build_diagnostics_contract();

    assert_keys_present(
        $diagnostics,
        diagnostics_public_top_level_keys(),
        'diagnostics section keeps bounded top-level keys',
    );
    is(
        $diagnostics->{section_contract}{contract_source},
        diagnostics_contract_source(),
        'diagnostics section advertises the section contract owner',
    );
    assert_scalar_string_keys(
        $diagnostics,
        diagnostics_scalar_string_keys(),
        'diagnostics section keeps bounded scalar-string keys',
    );
    assert_stable_code_entries(
        $diagnostics->{stable_codes},
        'diagnostics section keeps bounded stable-code entries',
    );
    is_deeply(
        $diagnostics->{section_contract}{nested_contract_source_map},
        $contract->{nested_contract_source_map},
        'diagnostics section keeps bounded nested contract owners',
    );
    is_deeply(
        $diagnostics->{section_contract}{nested_presence_key_map},
        $contract->{nested_presence_key_map},
        'diagnostics section keeps bounded nested key families',
    );
    assert_nested_contract_sources($diagnostics, $contract->{nested_contract_source_map}, 'diagnostics section');
};

subtest 'CLI capability manifest keeps the bounded diagnostics contract' => sub {
    my ($success, $error_message, $full_buf, $stdout_buf, $stderr_buf) = run(
        command => ['./bin/fsmgen', '--capability-manifest'],
    );

    ok($success, 'capability manifest CLI succeeds');
    is(join('', @{$stderr_buf || []}), '', 'capability manifest CLI keeps stderr clean');

    my $decoded = eval { decode_json(join('', @{$stdout_buf || []})) };
    ok($decoded, 'capability manifest CLI emits decodable JSON');

    my $diagnostics = $decoded->{diagnostics};
    my $contract = build_diagnostics_contract();
    assert_keys_present(
        $diagnostics,
        diagnostics_public_top_level_keys(),
        'CLI diagnostics section keeps bounded top-level keys',
    );
    is(
        $diagnostics->{section_contract}{contract_source},
        diagnostics_contract_source(),
        'CLI diagnostics section advertises the section contract owner',
    );
    assert_scalar_string_keys(
        $diagnostics,
        diagnostics_scalar_string_keys(),
        'CLI diagnostics section keeps bounded scalar-string keys',
    );
    assert_stable_code_entries(
        $diagnostics->{stable_codes},
        'CLI diagnostics section keeps bounded stable-code entries',
    );
    is_deeply(
        $diagnostics->{section_contract}{nested_contract_source_map},
        $contract->{nested_contract_source_map},
        'CLI diagnostics section keeps bounded nested contract owners',
    );
    is_deeply(
        $diagnostics->{section_contract}{nested_presence_key_map},
        $contract->{nested_presence_key_map},
        'CLI diagnostics section keeps bounded nested key families',
    );
    assert_nested_contract_sources($diagnostics, $contract->{nested_contract_source_map}, 'CLI diagnostics section');
};

done_testing();

sub assert_keys_present {
    my ($payload, $keys, $label) = @_;
    for my $key (@{$keys || []}) {
        ok(exists $payload->{$key}, "$label: keeps key $key");
    }
}

sub assert_scalar_string_keys {
    my ($payload, $keys, $label) = @_;
    for my $key (@{$keys || []}) {
        ok(defined $payload->{$key} && !ref($payload->{$key}) && length $payload->{$key}, "$label: $key stays a non-empty scalar string");
    }
}

sub assert_stable_code_entries {
    my ($entries, $label) = @_;
    ok(ref($entries) eq 'ARRAY', "$label: stable_codes stays an array");
    ok(@{$entries || []}, "$label: stable_codes stays non-empty");

    for my $entry (@{$entries || []}) {
        assert_keys_present(
            $entry,
            diagnostic_code_registry_entry_keys(),
            "$label: stable-code entry $entry->{code}",
        );
        like(
            $entry->{code} || '',
            qr/\AFSMGEN_[A-Z0-9_]+\z/,
            "$label: stable-code entry $entry->{code} keeps public code shape",
        );
        assert_value_in_list(
            $entry->{family},
            diagnostic_code_registry_family_values(),
            "$label: stable-code entry $entry->{code} keeps bounded family",
        );
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

sub assert_value_in_list {
    my ($value, $allowed, $label) = @_;
    my %allowed = map { $_ => 1 } @{$allowed || []};
    ok($allowed{$value}, $label);
}
