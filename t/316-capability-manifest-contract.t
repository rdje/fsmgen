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
use FSM::Support::CapabilityManifestContract qw(
    build_capability_manifest_contract
    capability_manifest_contract_source
    capability_manifest_backend_validation_keys
    capability_manifest_diagnostics_keys
    capability_manifest_documentation_keys
    capability_manifest_embedding_keys
    capability_manifest_language_surface_keys
    capability_manifest_producer_keys
    capability_manifest_public_top_level_keys
    capability_manifest_semantic_exports_keys
    capability_manifest_support_accounting_keys
);

my $manifest = build_capability_manifest();

subtest 'contract exposes the bounded capability-manifest shell' => sub {
    my $contract = build_capability_manifest_contract();

    is($contract->{schema_version}, 1, 'contract exposes schema version');
    is($contract->{status}, 'bounded_public', 'contract marks the capability-manifest shell as bounded public');
    is(
        $contract->{contract_source},
        capability_manifest_contract_source(),
        'contract records its own owner',
    );
    is(
        $contract->{report_source},
        'FSM::Support::CapabilityManifest',
        'contract records the manifest builder owner',
    );
    ok($contract->{full_manifest_json_safe}, 'contract says the manifest is JSON-safe');
    ok($contract->{nested_section_contracts_advertised}, 'contract says nested public sections advertise dedicated contracts');

    is_deeply(
        $contract->{public_top_level_presence_keys},
        capability_manifest_public_top_level_keys(),
        'contract publishes the bounded top-level manifest keys',
    );
    is_deeply(
        $contract->{producer_presence_keys},
        capability_manifest_producer_keys(),
        'contract publishes the bounded producer keys',
    );
    is_deeply(
        $contract->{support_accounting_presence_keys},
        capability_manifest_support_accounting_keys(),
        'contract publishes the bounded support-accounting section keys',
    );
    is_deeply(
        $contract->{diagnostics_presence_keys},
        capability_manifest_diagnostics_keys(),
        'contract publishes the bounded diagnostics section keys',
    );
    is_deeply(
        $contract->{semantic_exports_presence_keys},
        capability_manifest_semantic_exports_keys(),
        'contract publishes the bounded semantic-exports section keys',
    );
    is_deeply(
        $contract->{backend_validation_presence_keys},
        capability_manifest_backend_validation_keys(),
        'contract publishes the bounded backend-validation section keys',
    );
    is_deeply(
        $contract->{embedding_presence_keys},
        capability_manifest_embedding_keys(),
        'contract publishes the bounded embedding section keys',
    );
    is_deeply(
        $contract->{language_surface_presence_keys},
        capability_manifest_language_surface_keys(),
        'contract publishes the bounded language-surface section keys',
    );
    is_deeply(
        $contract->{documentation_presence_keys},
        capability_manifest_documentation_keys(),
        'contract publishes the bounded documentation section keys',
    );
};

subtest 'in-process capability manifest conforms to the bounded shell contract' => sub {
    assert_keys_present(
        $manifest,
        capability_manifest_public_top_level_keys(),
        'capability manifest keeps bounded top-level keys',
    );
    is(
        $manifest->{manifest_contract}{contract_source},
        capability_manifest_contract_source(),
        'capability manifest advertises the top-level manifest contract owner',
    );
    assert_keys_present(
        $manifest->{producer},
        capability_manifest_producer_keys(),
        'producer section keeps bounded keys',
    );
    assert_keys_present(
        $manifest->{support_accounting},
        capability_manifest_support_accounting_keys(),
        'support-accounting section keeps bounded keys',
    );
    assert_keys_present(
        $manifest->{diagnostics},
        capability_manifest_diagnostics_keys(),
        'diagnostics section keeps bounded keys',
    );
    assert_keys_present(
        $manifest->{semantic_exports},
        capability_manifest_semantic_exports_keys(),
        'semantic-exports section keeps bounded keys',
    );
    assert_keys_present(
        $manifest->{backend_validation},
        capability_manifest_backend_validation_keys(),
        'backend-validation section keeps bounded keys',
    );
    assert_keys_present(
        $manifest->{embedding},
        capability_manifest_embedding_keys(),
        'embedding section keeps bounded keys',
    );
    assert_keys_present(
        $manifest->{language_surface},
        capability_manifest_language_surface_keys(),
        'language-surface section keeps bounded keys',
    );
    assert_keys_present(
        $manifest->{documentation},
        capability_manifest_documentation_keys(),
        'documentation section keeps bounded keys',
    );
};

subtest 'CLI capability manifest keeps the bounded shell contract' => sub {
    my ($success, $error_message, $full_buf, $stdout_buf, $stderr_buf) = run(
        command => ['./bin/fsmgen', '--capability-manifest'],
    );

    ok($success, 'capability manifest CLI succeeds');
    is(join('', @{$stderr_buf || []}), '', 'capability manifest CLI keeps stderr clean');

    my $decoded = eval { decode_json(join('', @{$stdout_buf || []})) };
    ok($decoded, 'capability manifest CLI emits decodable JSON');

    assert_keys_present(
        $decoded,
        capability_manifest_public_top_level_keys(),
        'CLI capability manifest keeps bounded top-level keys',
    );
    is(
        $decoded->{manifest_contract}{contract_source},
        capability_manifest_contract_source(),
        'CLI capability manifest advertises the top-level manifest contract owner',
    );
    assert_keys_present(
        $decoded->{producer},
        capability_manifest_producer_keys(),
        'CLI producer section keeps bounded keys',
    );
    assert_keys_present(
        $decoded->{support_accounting},
        capability_manifest_support_accounting_keys(),
        'CLI support-accounting section keeps bounded keys',
    );
    assert_keys_present(
        $decoded->{documentation},
        capability_manifest_documentation_keys(),
        'CLI documentation section keeps bounded keys',
    );
};

done_testing();

sub assert_keys_present {
    my ($payload, $keys, $label) = @_;
    for my $key (@{$keys || []}) {
        ok(exists $payload->{$key}, "$label: keeps key $key");
    }
}
