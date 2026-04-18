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
use FSM::Support::EmbeddingContract qw(
    build_embedding_contract
    embedding_nested_contract_keys
    embedding_public_top_level_keys
);

my $manifest = build_capability_manifest();

subtest 'contract exposes the bounded embedding section' => sub {
    my $contract = build_embedding_contract();

    is($contract->{schema_version}, 1, 'contract exposes schema version');
    is($contract->{status}, 'bounded_public', 'contract marks embedding as bounded public');
    is(
        $contract->{contract_source},
        'FSM::Support::EmbeddingContract',
        'contract records its own owner',
    );
    is(
        $contract->{report_source},
        'FSM::Support::CapabilityManifest',
        'contract records the manifest builder owner',
    );
    is_deeply(
        $contract->{public_top_level_presence_keys},
        embedding_public_top_level_keys(),
        'contract publishes the bounded embedding top-level keys',
    );
    is_deeply(
        $contract->{nested_contract_keys},
        embedding_nested_contract_keys(),
        'contract publishes the bounded embedding nested-contract keys',
    );
    is_deeply(
        $contract->{nested_contract_source_map},
        {
            composition_report => 'FSM::Support::CompositionReportContract',
            hdl_generator_result => 'FSM::Support::HDLGeneratorResultContract',
            typed_extensions => 'FSM::Support::ExtensionContract',
        },
        'contract publishes the bounded embedding nested-contract ownership map',
    );
    ok($contract->{nested_contracts_advertised}, 'contract says nested embedding contracts are advertised');
    ok(!$contract->{full_embedding_section_stable}, 'contract keeps broader embedding stabilization separate');
};

subtest 'in-process capability manifest embedding section conforms to the bounded contract' => sub {
    my $embedding = $manifest->{embedding};
    my $contract = build_embedding_contract();

    assert_keys_present(
        $embedding,
        embedding_public_top_level_keys(),
        'embedding section keeps bounded top-level keys',
    );
    is(
        $embedding->{section_contract}{contract_source},
        'FSM::Support::EmbeddingContract',
        'embedding section advertises the section contract owner',
    );
    assert_nested_contract_sources(
        $embedding,
        $contract->{nested_contract_source_map},
        'embedding section keeps bounded nested contract owners',
    );
};

subtest 'CLI capability manifest keeps the bounded embedding contract' => sub {
    my ($success, $error_message, $full_buf, $stdout_buf, $stderr_buf) = run(
        command => ['./bin/fsmgen', '--capability-manifest'],
    );

    ok($success, 'capability manifest CLI succeeds');
    is(join('', @{$stderr_buf || []}), '', 'capability manifest CLI keeps stderr clean');

    my $decoded = eval { decode_json(join('', @{$stdout_buf || []})) };
    ok($decoded, 'capability manifest CLI emits decodable JSON');

    my $embedding = $decoded->{embedding};
    my $contract = build_embedding_contract();
    assert_keys_present(
        $embedding,
        embedding_public_top_level_keys(),
        'CLI embedding section keeps bounded top-level keys',
    );
    is(
        $embedding->{section_contract}{contract_source},
        'FSM::Support::EmbeddingContract',
        'CLI embedding section advertises the section contract owner',
    );
    assert_nested_contract_sources(
        $embedding,
        $contract->{nested_contract_source_map},
        'CLI embedding section keeps bounded nested contract owners',
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
