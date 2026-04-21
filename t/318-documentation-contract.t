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
use FSM::Support::DocumentationContract qw(
    build_documentation_contract
    documentation_contract_source
    documentation_path_list_keys
    documentation_public_top_level_keys
);

my $manifest = build_capability_manifest();

subtest 'contract exposes the bounded documentation section' => sub {
    my $contract = build_documentation_contract();

    is($contract->{schema_version}, 1, 'contract exposes schema version');
    is($contract->{status}, 'bounded_public', 'contract marks documentation as bounded public');
    is(
        $contract->{contract_source},
        documentation_contract_source(),
        'contract records its own owner',
    );
    is(
        $contract->{report_source},
        'FSM::Support::CapabilityManifest',
        'contract records the manifest builder owner',
    );
    is_deeply(
        $contract->{public_top_level_presence_keys},
        documentation_public_top_level_keys(),
        'contract publishes the bounded documentation top-level keys',
    );
    is_deeply(
        $contract->{path_list_keys},
        documentation_path_list_keys(),
        'contract publishes the bounded documentation path-list keys',
    );
    ok($contract->{path_contract}{repo_relative_paths}, 'contract says documentation paths are repo-relative');
    ok($contract->{path_contract}{tracked_markdown_files}, 'contract says documentation paths are markdown files');
    ok(!$contract->{path_contract}{exact_path_lists_frozen}, 'contract keeps exact documentation path lists widenable');
};

subtest 'in-process capability manifest documentation section conforms to the bounded contract' => sub {
    my $documentation = $manifest->{documentation};

    assert_keys_present(
        $documentation,
        documentation_public_top_level_keys(),
        'documentation section keeps bounded top-level keys',
    );
    is(
        $documentation->{section_contract}{contract_source},
        documentation_contract_source(),
        'documentation section advertises the section contract owner',
    );
    assert_documentation_paths(
        $documentation,
        documentation_path_list_keys(),
        'documentation section keeps valid tracked markdown path lists',
    );
};

subtest 'CLI capability manifest keeps the bounded documentation contract' => sub {
    my ($success, $error_message, $full_buf, $stdout_buf, $stderr_buf) = run(
        command => ['./bin/fsmgen', '--capability-manifest'],
    );

    ok($success, 'capability manifest CLI succeeds');
    is(join('', @{$stderr_buf || []}), '', 'capability manifest CLI keeps stderr clean');

    my $decoded = eval { decode_json(join('', @{$stdout_buf || []})) };
    ok($decoded, 'capability manifest CLI emits decodable JSON');

    my $documentation = $decoded->{documentation};
    assert_keys_present(
        $documentation,
        documentation_public_top_level_keys(),
        'CLI documentation section keeps bounded top-level keys',
    );
    is(
        $documentation->{section_contract}{contract_source},
        documentation_contract_source(),
        'CLI documentation section advertises the section contract owner',
    );
    assert_documentation_paths(
        $documentation,
        documentation_path_list_keys(),
        'CLI documentation section keeps valid tracked markdown path lists',
    );
};

done_testing();

sub assert_keys_present {
    my ($payload, $keys, $label) = @_;
    for my $key (@{$keys || []}) {
        ok(exists $payload->{$key}, "$label: keeps key $key");
    }
}

sub assert_documentation_paths {
    my ($payload, $keys, $label) = @_;
    for my $key (@{$keys || []}) {
        my $paths = $payload->{$key};
        ok(ref($paths) eq 'ARRAY', "$label: $key stays an array");
        for my $path (@{$paths || []}) {
            ok(defined $path && !ref($path) && length $path, "$label: $key keeps non-empty path entries");
            like($path, qr/\.md\z/, "$label: $key path $path stays markdown");
            ok(-f File::Spec->catfile($FindBin::Bin, '..', $path), "$label: $key path $path exists in the repo");
        }
    }
}
