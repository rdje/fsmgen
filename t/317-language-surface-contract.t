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
use FSM::Support::LanguageSurfaceContract qw(
    build_language_surface_contract
    language_surface_assignments_keys
    language_surface_composition_keys
    language_surface_declarations_keys
    language_surface_default_mode_compatibility_keys
    language_surface_expressions_keys
    language_surface_public_top_level_keys
    language_surface_strict_mode_keys
    language_surface_system_contracts_keys
);

my $manifest = build_capability_manifest();

subtest 'contract exposes the bounded language-surface section' => sub {
    my $contract = build_language_surface_contract();

    is($contract->{schema_version}, 1, 'contract exposes schema version');
    is($contract->{status}, 'bounded_public', 'contract marks language surface as bounded public');
    is(
        $contract->{contract_source},
        'FSM::Support::LanguageSurfaceContract',
        'contract records its own owner',
    );
    is(
        $contract->{report_source},
        'FSM::Support::CapabilityManifest',
        'contract records the manifest builder owner',
    );
    ok(!$contract->{full_language_surface_stable}, 'contract keeps broader language-surface stabilization separate');

    is_deeply(
        $contract->{public_top_level_presence_keys},
        language_surface_public_top_level_keys(),
        'contract publishes the bounded language-surface top-level keys',
    );
    is_deeply(
        $contract->{strict_mode_presence_keys},
        language_surface_strict_mode_keys(),
        'contract publishes the bounded strict-mode keys',
    );
    is_deeply(
        $contract->{default_mode_compatibility_presence_keys},
        language_surface_default_mode_compatibility_keys(),
        'contract publishes the bounded default-mode keys',
    );
    is_deeply(
        $contract->{assignments_presence_keys},
        language_surface_assignments_keys(),
        'contract publishes the bounded assignments keys',
    );
    is_deeply(
        $contract->{system_contracts_presence_keys},
        language_surface_system_contracts_keys(),
        'contract publishes the bounded system-contract keys',
    );
    is_deeply(
        $contract->{expressions_presence_keys},
        language_surface_expressions_keys(),
        'contract publishes the bounded expressions keys',
    );
    is_deeply(
        $contract->{declarations_presence_keys},
        language_surface_declarations_keys(),
        'contract publishes the bounded declarations keys',
    );
    is_deeply(
        $contract->{composition_presence_keys},
        language_surface_composition_keys(),
        'contract publishes the bounded composition keys',
    );
};

subtest 'in-process capability manifest language surface conforms to the bounded contract' => sub {
    my $surface = $manifest->{language_surface};

    assert_keys_present(
        $surface,
        language_surface_public_top_level_keys(),
        'language-surface section keeps bounded top-level keys',
    );
    is(
        $surface->{surface_contract}{contract_source},
        'FSM::Support::LanguageSurfaceContract',
        'language-surface section advertises the section contract owner',
    );
    assert_keys_present(
        $surface->{strict_mode},
        language_surface_strict_mode_keys(),
        'strict-mode section keeps bounded keys',
    );
    assert_keys_present(
        $surface->{default_mode_compatibility},
        language_surface_default_mode_compatibility_keys(),
        'default-mode section keeps bounded keys',
    );
    assert_keys_present(
        $surface->{assignments},
        language_surface_assignments_keys(),
        'assignments section keeps bounded keys',
    );
    assert_keys_present(
        $surface->{system_contracts},
        language_surface_system_contracts_keys(),
        'system-contracts section keeps bounded keys',
    );
    assert_keys_present(
        $surface->{expressions},
        language_surface_expressions_keys(),
        'expressions section keeps bounded keys',
    );
    assert_keys_present(
        $surface->{declarations},
        language_surface_declarations_keys(),
        'declarations section keeps bounded keys',
    );
    assert_keys_present(
        $surface->{composition},
        language_surface_composition_keys(),
        'composition section keeps bounded keys',
    );
};

subtest 'CLI capability manifest keeps the bounded language-surface contract' => sub {
    my ($success, $error_message, $full_buf, $stdout_buf, $stderr_buf) = run(
        command => ['./bin/fsmgen', '--capability-manifest'],
    );

    ok($success, 'capability manifest CLI succeeds');
    is(join('', @{$stderr_buf || []}), '', 'capability manifest CLI keeps stderr clean');

    my $decoded = eval { decode_json(join('', @{$stdout_buf || []})) };
    ok($decoded, 'capability manifest CLI emits decodable JSON');

    my $surface = $decoded->{language_surface};
    assert_keys_present(
        $surface,
        language_surface_public_top_level_keys(),
        'CLI language-surface section keeps bounded top-level keys',
    );
    is(
        $surface->{surface_contract}{contract_source},
        'FSM::Support::LanguageSurfaceContract',
        'CLI language-surface section advertises the section contract owner',
    );
    assert_keys_present(
        $surface->{expressions},
        language_surface_expressions_keys(),
        'CLI expressions section keeps bounded keys',
    );
};

done_testing();

sub assert_keys_present {
    my ($payload, $keys, $label) = @_;
    for my $key (@{$keys || []}) {
        ok(exists $payload->{$key}, "$label: keeps key $key");
    }
}
