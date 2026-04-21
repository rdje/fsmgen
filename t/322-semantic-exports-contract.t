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
use FSM::Support::NormalizedSemanticReportContract qw(
    normalized_semantic_report_contract_source
);
use FSM::Support::SemanticExportsContract qw(
    build_semantic_exports_contract
    semantic_exports_contract_source
    semantic_exports_nested_contract_keys
    semantic_exports_public_top_level_keys
);

my $manifest = build_capability_manifest();

subtest 'contract exposes the bounded semantic-exports section' => sub {
    my $contract = build_semantic_exports_contract();

    is($contract->{schema_version}, 1, 'contract exposes schema version');
    is($contract->{status}, 'bounded_public', 'contract marks semantic_exports as bounded public');
    is(
        $contract->{contract_source},
        semantic_exports_contract_source(),
        'contract records its own owner',
    );
    is(
        $contract->{report_source},
        'FSM::Support::CapabilityManifest',
        'contract records the manifest builder owner',
    );
    is_deeply(
        $contract->{public_top_level_presence_keys},
        semantic_exports_public_top_level_keys(),
        'contract publishes the bounded semantic-exports top-level keys',
    );
    is_deeply(
        $contract->{nested_contract_keys},
        semantic_exports_nested_contract_keys(),
        'contract publishes the bounded semantic-exports nested-contract keys',
    );
    is_deeply(
        $contract->{nested_contract_source_map},
        {
            normalized_semantic_json => normalized_semantic_report_contract_source(),
        },
        'contract publishes the bounded semantic-exports nested-contract ownership map',
    );
    ok(
        $contract->{normalized_semantic_json_contract_advertised},
        'contract says the normalized semantic JSON contract is advertised',
    );
    ok(
        !$contract->{full_semantic_exports_section_stable},
        'contract keeps broader semantic-exports stabilization separate',
    );
};

subtest 'in-process capability manifest semantic-exports section conforms to the bounded contract' => sub {
    my $semantic_exports = $manifest->{semantic_exports};
    my $contract = build_semantic_exports_contract();

    assert_keys_present(
        $semantic_exports,
        semantic_exports_public_top_level_keys(),
        'semantic-exports section keeps bounded top-level keys',
    );
    is(
        $semantic_exports->{section_contract}{contract_source},
        semantic_exports_contract_source(),
        'semantic-exports section advertises the section contract owner',
    );
    assert_nested_contract_sources(
        $semantic_exports,
        $contract->{nested_contract_source_map},
        'semantic-exports section keeps bounded nested contract owners',
    );
};

subtest 'CLI capability manifest keeps the bounded semantic-exports contract' => sub {
    my ($success, $error_message, $full_buf, $stdout_buf, $stderr_buf) = run(
        command => ['./bin/fsmgen', '--capability-manifest'],
    );

    ok($success, 'capability manifest CLI succeeds');
    is(join('', @{$stderr_buf || []}), '', 'capability manifest CLI keeps stderr clean');

    my $decoded = eval { decode_json(join('', @{$stdout_buf || []})) };
    ok($decoded, 'capability manifest CLI emits decodable JSON');

    my $semantic_exports = $decoded->{semantic_exports};
    my $contract = build_semantic_exports_contract();
    assert_keys_present(
        $semantic_exports,
        semantic_exports_public_top_level_keys(),
        'CLI semantic-exports section keeps bounded top-level keys',
    );
    is(
        $semantic_exports->{section_contract}{contract_source},
        semantic_exports_contract_source(),
        'CLI semantic-exports section advertises the section contract owner',
    );
    assert_nested_contract_sources(
        $semantic_exports,
        $contract->{nested_contract_source_map},
        'CLI semantic-exports section keeps bounded nested contract owners',
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
