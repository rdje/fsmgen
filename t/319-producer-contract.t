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
use FSM::Support::ProducerContract qw(
    build_producer_contract
    producer_boolean_keys
    producer_contract_source
    producer_presence_key_family_map
    producer_public_top_level_keys
    producer_scalar_string_keys
);

my $manifest = build_capability_manifest();

subtest 'contract exposes the bounded producer section' => sub {
    my $contract = build_producer_contract();

    is($contract->{schema_version}, 1, 'contract exposes schema version');
    is($contract->{status}, 'bounded_public', 'contract marks producer as bounded public');
    is(
        $contract->{contract_source},
        producer_contract_source(),
        'contract records its own owner',
    );
    is(
        $contract->{report_source},
        'FSM::Support::CapabilityManifest',
        'contract records the manifest builder owner',
    );
    is_deeply(
        $contract->{public_top_level_presence_keys},
        producer_public_top_level_keys(),
        'contract publishes the bounded producer top-level keys',
    );
    is_deeply(
        $contract->{scalar_string_keys},
        producer_scalar_string_keys(),
        'contract publishes the bounded producer scalar-string keys',
    );
    is_deeply(
        $contract->{boolean_keys},
        producer_boolean_keys(),
        'contract publishes the bounded producer boolean keys',
    );
    is_deeply(
        $contract->{presence_key_family_map},
        producer_presence_key_family_map(),
        'contract publishes the grouped producer key-family map',
    );
    ok($contract->{identity_contract}{name_is_tool_identity}, 'contract keeps tool-identity name semantics');
    ok(
        $contract->{identity_contract}{git_commit_is_best_effort_short_hash_or_unknown},
        'contract keeps bounded git-commit identity semantics',
    );
    ok(
        $contract->{identity_contract}{source_is_manifest_builder_module},
        'contract keeps bounded source-module identity semantics',
    );
};

subtest 'in-process capability manifest producer section conforms to the bounded contract' => sub {
    my $producer = $manifest->{producer};

    assert_keys_present(
        $producer,
        producer_public_top_level_keys(),
        'producer section keeps bounded top-level keys',
    );
    is(
        $producer->{section_contract}{contract_source},
        producer_contract_source(),
        'producer section advertises the section contract owner',
    );
    is_deeply(
        $producer->{section_contract}{presence_key_family_map},
        producer_presence_key_family_map(),
        'producer section keeps the grouped key-family map',
    );
    assert_scalar_string_keys(
        $producer,
        producer_scalar_string_keys(),
        'producer section keeps bounded scalar-string keys',
    );
    assert_boolean_keys(
        $producer,
        producer_boolean_keys(),
        'producer section keeps bounded boolean keys',
    );
    assert_git_commit_shape(
        $producer->{git_commit},
        'producer section keeps bounded git-commit identity',
    );
};

subtest 'CLI capability manifest keeps the bounded producer contract' => sub {
    my ($success, $error_message, $full_buf, $stdout_buf, $stderr_buf) = run(
        command => ['./bin/fsmgen', '--capability-manifest'],
    );

    ok($success, 'capability manifest CLI succeeds');
    is(join('', @{$stderr_buf || []}), '', 'capability manifest CLI keeps stderr clean');

    my $decoded = eval { decode_json(join('', @{$stdout_buf || []})) };
    ok($decoded, 'capability manifest CLI emits decodable JSON');

    my $producer = $decoded->{producer};
    assert_keys_present(
        $producer,
        producer_public_top_level_keys(),
        'CLI producer section keeps bounded top-level keys',
    );
    is(
        $producer->{section_contract}{contract_source},
        producer_contract_source(),
        'CLI producer section advertises the section contract owner',
    );
    is_deeply(
        $producer->{section_contract}{presence_key_family_map},
        producer_presence_key_family_map(),
        'CLI producer section keeps the grouped key-family map',
    );
    assert_scalar_string_keys(
        $producer,
        producer_scalar_string_keys(),
        'CLI producer section keeps bounded scalar-string keys',
    );
    assert_boolean_keys(
        $producer,
        producer_boolean_keys(),
        'CLI producer section keeps bounded boolean keys',
    );
    assert_git_commit_shape(
        $producer->{git_commit},
        'CLI producer section keeps bounded git-commit identity',
    );
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

sub assert_boolean_keys {
    my ($payload, $keys, $label) = @_;
    for my $key (@{$keys || []}) {
        my $value = $payload->{$key};
        my $class = ref($value);
        my $stringified = defined $value ? "$value" : '';
        ok(
            defined $value
                && (
                    ($class && $class eq 'JSON::PP::Boolean')
                    || (!$class && ($stringified eq '0' || $stringified eq '1'))
                ),
            "$label: $key stays boolean-like",
        );
    }
}

sub assert_git_commit_shape {
    my ($value, $label) = @_;
    like($value, qr/\A(?:unknown|[0-9a-f]{7,12})\z/, $label);
}
