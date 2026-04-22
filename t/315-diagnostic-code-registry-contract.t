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
use FSM::Support::DiagnosticCodeRegistryContract qw(
    build_diagnostic_code_registry_contract
    diagnostic_code_registry_bounded_value_family_map
    diagnostic_code_registry_contract_source
    diagnostic_code_registry_entry_keys
    diagnostic_code_registry_family_values
    diagnostic_code_registry_key_family_map
    diagnostic_code_registry_public_keys
);
use FSM::Support::DiagnosticCodes qw(diagnostic_code_ids);

my $manifest = build_capability_manifest();
my @diagnostic_codes = diagnostic_code_ids();

subtest 'contract exposes the bounded stable-code registry surface' => sub {
    my $contract = build_diagnostic_code_registry_contract();

    is($contract->{schema_version}, 1, 'contract exposes schema version');
    is($contract->{status}, 'bounded_public', 'contract marks the stable-code registry as bounded public');
    is(
        $contract->{contract_source},
        diagnostic_code_registry_contract_source(),
        'contract records its own owner',
    );
    is(
        $contract->{report_source},
        'FSM::Support::DiagnosticCodes',
        'contract records the stable-code registry owner',
    );
    is_deeply(
        $contract->{public_sibling_keys},
        diagnostic_code_registry_public_keys(),
        'contract publishes the bounded stable-code registry sibling keys',
    );
    is_deeply(
        $contract->{entry_presence_keys},
        diagnostic_code_registry_entry_keys(),
        'contract publishes the bounded stable-code entry keys',
    );
    is_deeply(
        $contract->{key_family_map},
        diagnostic_code_registry_key_family_map(),
        'contract publishes the grouped stable-code registry key families',
    );
    is_deeply(
        $contract->{bounded_family_values},
        diagnostic_code_registry_family_values(),
        'contract publishes the bounded diagnostic-code families',
    );
    is_deeply(
        $contract->{bounded_value_family_map},
        diagnostic_code_registry_bounded_value_family_map(),
        'contract publishes the grouped bounded diagnostic-code value families',
    );
    ok(
        $contract->{registry_returns_defensive_copies},
        'contract says registry lookups return defensive copies',
    );
};

subtest 'in-process manifest stable-code registry conforms to the bounded contract' => sub {
    assert_keys_present(
        $manifest->{diagnostics},
        diagnostic_code_registry_public_keys(),
        'diagnostics section keeps bounded stable-code registry sibling keys',
    );
    is(
        scalar(@{$manifest->{diagnostics}{stable_codes} || []}),
        scalar(@diagnostic_codes),
        'stable-code registry count follows diagnostic_code_ids',
    );
    is(
        $manifest->{diagnostics}{stable_code_registry}{contract_source},
        diagnostic_code_registry_contract_source(),
        'manifest advertises the stable-code registry contract owner',
    );
    is_deeply(
        $manifest->{diagnostics}{stable_code_registry}{key_family_map},
        diagnostic_code_registry_key_family_map(),
        'manifest advertises the grouped stable-code registry key families',
    );
    is_deeply(
        $manifest->{diagnostics}{stable_code_registry}{bounded_value_family_map},
        diagnostic_code_registry_bounded_value_family_map(),
        'manifest advertises the grouped bounded diagnostic-code value families',
    );
    ok(@{$manifest->{diagnostics}{stable_codes} || []}, 'manifest exposes stable-code entries');

    for my $entry (@{$manifest->{diagnostics}{stable_codes} || []}) {
        assert_keys_present(
            $entry,
            diagnostic_code_registry_entry_keys(),
            "stable-code entry $entry->{code} keeps bounded entry keys",
        );
        like(
            $entry->{code} || '',
            qr/\AFSMGEN_[A-Z0-9_]+\z/,
            "stable-code entry $entry->{code} keeps the public code shape",
        );
        assert_value_in_list(
            $entry->{family},
            diagnostic_code_registry_family_values(),
            "stable-code entry $entry->{code} keeps a bounded family",
        );
    }
};

subtest 'CLI capability manifest keeps the bounded stable-code registry contract' => sub {
    my ($success, $error_message, $full_buf, $stdout_buf, $stderr_buf) = run(
        command => ['./bin/fsmgen', '--capability-manifest'],
    );

    ok($success, 'capability manifest CLI succeeds');
    is(join('', @{$stderr_buf || []}), '', 'capability manifest CLI keeps stderr clean');

    my $decoded = eval { decode_json(join('', @{$stdout_buf || []})) };
    ok($decoded, 'capability manifest CLI emits decodable JSON');

    assert_keys_present(
        $decoded->{diagnostics},
        diagnostic_code_registry_public_keys(),
        'CLI diagnostics section keeps bounded stable-code registry sibling keys',
    );
    is(
        $decoded->{diagnostics}{stable_code_registry}{contract_source},
        diagnostic_code_registry_contract_source(),
        'CLI diagnostics section advertises the stable-code registry contract owner',
    );
    is_deeply(
        $decoded->{diagnostics}{stable_code_registry}{key_family_map},
        diagnostic_code_registry_key_family_map(),
        'CLI diagnostics section advertises the grouped stable-code registry key families',
    );
    is_deeply(
        $decoded->{diagnostics}{stable_code_registry}{bounded_value_family_map},
        diagnostic_code_registry_bounded_value_family_map(),
        'CLI diagnostics section advertises the grouped bounded diagnostic-code value families',
    );
    is(
        scalar(@{$decoded->{diagnostics}{stable_codes} || []}),
        scalar(@diagnostic_codes),
        'CLI stable-code registry count follows diagnostic_code_ids',
    );
    assert_keys_present(
        $decoded->{diagnostics}{stable_codes}[0],
        diagnostic_code_registry_entry_keys(),
        'CLI stable-code entries keep bounded entry keys',
    );
    assert_value_in_list(
        $decoded->{diagnostics}{stable_codes}[0]{family},
        diagnostic_code_registry_family_values(),
        'CLI stable-code entries keep bounded families',
    );
};

done_testing();

sub assert_keys_present {
    my ($payload, $keys, $label) = @_;
    for my $key (@{$keys || []}) {
        ok(exists $payload->{$key}, "$label: keeps key $key");
    }
}

sub assert_value_in_list {
    my ($value, $allowed, $label) = @_;

    my %allowed = map { $_ => 1 } @{$allowed || []};
    ok($allowed{$value}, $label);
}
