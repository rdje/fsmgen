#!/usr/bin/env perl

use strict;
use warnings;

use Digest::SHA qw(sha256_hex);
use File::Path qw(make_path remove_tree);
use File::Spec;
use FindBin;
use JSON::PP ();
use POSIX ();
use Test::More;

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::VIAL::ArchitectureScaleBalancedPortableMeasurement;
use FSM::VIAL::ArchitectureScaleBalancedPortableMeasurementMatrix;

my $class =
    'FSM::VIAL::ArchitectureScaleBalancedPortableMeasurementMatrix';
my $adapter =
    'FSM::VIAL::ArchitectureScaleBalancedPortableMeasurement';
my $repo_root = File::Spec->catdir($FindBin::Bin, '..');
my $json = JSON::PP->new->canonical(1)->utf8(1);

subtest 'producer authority closes one balanced structural profile' => sub {
    my $inventory = $class->inventory;
    my $authority = $adapter->member_authority;
    is(scalar(@$inventory), 1,
        'publisher derives exactly one profile from producer authority');
    my $profile = $inventory->[0];
    is_deeply([sort keys %$profile], [sort @{$class->profile_keys}],
        'inventory member has one closed schema');
    is_deeply(
        [@{$profile}{qw(family backend_profile level mode)}],
        [@{$authority}{qw(family backend_profile level)},
            'gate_measurement'],
        'inventory preserves the sole producer-owned coordinates');
    like($profile->{profile_id},
        qr/\Abalanced-portable-profile-[0-9a-f]{64}\z/,
        'profile identity is a safe digest of owned coordinates');
    is_deeply([sort @{$class->matrix_keys}], [sort qw(
        schema schema_version matrix_identity family profile_count
        common_identity profiles dominance outcome diagnostics
        explicit_nonclaims
    )], 'family manifest is closed');

    my $limits = $class->publication_limits;
    is($limits->{provisional_publication_bytes}, 67_108_864,
        'publication begins below the conservative 64-MiB envelope');
    is($limits->{measured_records}, 3,
        'publication contract retains all three gate records');
    is($limits->{maximum_publication_bytes},
        $limits->{provisional_publication_bytes},
        'canonical publication cannot escape its storage envelope');
    cmp_ok($limits->{maximum_worker_result_bytes}, '<',
        $limits->{maximum_publication_bytes},
        'compact IPC cannot accidentally carry the raw report');

    my $second = $class->inventory;
    $inventory->[0]{backend_profile} = 'forged';
    isnt($second->[0]{backend_profile}, 'forged',
        'inventory callers receive defensive values');
    like(dies(sub {
        FSM::VIAL::ArchitectureScaleBalancedPortableMeasurementMatrix::inventory(
            'borrowed');
    }), qr/requires the exact class invocant/,
        'borrowed class invocants fail closed');
};

subtest 'capture and validation reject caller evidence before work' => sub {
    local $ENV{FSMGEN_RAM_GUARD_ACTIVE};
    local $ENV{FSMGEN_RAM_GUARD_EFFECTIVE_HOST_MAX_PCT};
    local $ENV{FSMGEN_RAM_GUARD_EFFECTIVE_PROCESS_MAX_RSS_MB};

    like(dies(sub {
        $class->capture_all({repository_root => $repo_root});
    }), qr/active repository RAM guard/,
        'capture cannot run outside the real guard');
    like(dies(sub {
        $class->capture_family({
            repository_root => $repo_root,
            family => 'borrowed_family',
        });
    }), qr/unknown key 'family'/,
        'caller-selected families cannot enter capture');
    like(dies(sub {
        $class->capture_all({
            repository_root => $repo_root,
            reports => [],
        });
    }), qr/unknown key 'reports'/,
        'caller-created report collections cannot enter capture');
    like(dies(sub {
        $class->validate_complete_publication({
            repository_root => $repo_root,
            publication => {},
        });
    }), qr/unknown key 'publication'/,
        'caller-created publications cannot bypass immutable reload');
};

subtest 'profile isolation and atomic publication fail closed' => sub {
    my $profile_id = 'synthetic-balanced-portable-worker-v1';
    my $parent_pid = $$;
    my $run_isolated = $class->can('_run_isolated_profile_worker');
    my $publish_json = $class->can('_publish_json');
    my $isolated = $run_isolated->({
        profile_id => $profile_id,
        worker => sub {
            my $allocation = 'x' x 4_194_304;
            return {allocated_bytes => length($allocation), pid => $$};
        },
        validate_payload => sub {
            my ($payload) = @_;
            die "synthetic payload changed\n"
                unless ref($payload) eq 'HASH'
                    && $payload->{allocated_bytes} == 4_194_304
                    && $payload->{pid} =~ /\A[1-9][0-9]*\z/;
        },
    });
    is($isolated->{allocated_bytes}, 4_194_304,
        'representative allocator state stays inside one child');
    isnt($isolated->{pid}, $parent_pid,
        'profile work does not inflate the coordinator');
    like(dies(sub {
        $run_isolated->({
            profile_id => $profile_id,
            worker => sub { die "synthetic worker exception\n" },
            validate_payload => sub { },
        });
    }), qr/failed: synthetic worker exception/,
        'worker exceptions cross one bounded envelope');
    like(dies(sub {
        $run_isolated->({
            profile_id => $profile_id,
            worker => sub { POSIX::_exit(23) },
            validate_payload => sub { },
        });
    }), qr/returned no result with exit status 23/,
        'abrupt child exit fails closed');
    like(dies(sub {
        $run_isolated->({
            profile_id => $profile_id,
            worker => sub { kill 9, $$; return {} },
            validate_payload => sub { },
        });
    }), qr/terminated by signal 9/,
        'signalled child fails with its exact signal');
    like(dies(sub {
        $run_isolated->({
            profile_id => $profile_id,
            worker => sub { return 'x' x 65_537 },
            validate_payload => sub { },
        });
    }), qr/result exceeded the bounded envelope/,
        'oversized child result cannot cross compact IPC');

    my $fixture_root = repo_path(
        ".artifacts/tmp/t1682-publication-collision-$$",
    );
    remove_tree($fixture_root) if -e $fixture_root;
    make_path(File::Spec->catdir($fixture_root, '.git'));
    my @root_stat = stat($fixture_root);
    my $first = $publish_json->({
        repository_root => $fixture_root,
        root_device => $root_stat[0],
        profile_id => $profile_id,
        filename => 'measurement-publication.json',
        value => {generation => 1},
    });
    is($first->{status}, 'published',
        'first synthetic publication is immutable');
    like(dies(sub {
        $publish_json->({
            repository_root => $fixture_root,
            root_device => $root_stat[0],
            profile_id => $profile_id,
            filename => 'measurement-publication.json',
            value => {generation => 2},
        });
    }), qr/publication collision/,
        'different bytes cannot overwrite publication');

    my $recovery_id = 'synthetic-recoverable-publication-v1';
    my $recovery_value = {generation => 3};
    my $recovery_bytes = $json->encode($recovery_value) . "\n";
    my $recovery_digest = sha256_hex($recovery_bytes);
    my $recovery_stage = File::Spec->catdir(
        $fixture_root, split(m{/}, join('/',
            '.artifacts/tmp/vial-scale',
            'balanced-portable-matrix-publication',
            "$recovery_id-$recovery_digest",
        )),
    );
    make_path($recovery_stage);
    my $recovery_file = File::Spec->catfile(
        $recovery_stage, 'measurement-publication.json',
    );
    open my $recovery_fh, '>:raw', $recovery_file
        or die "cannot create recovery fixture: $!\n";
    print {$recovery_fh} $recovery_bytes;
    close $recovery_fh or die "cannot close recovery fixture: $!\n";
    my $recovered = $publish_json->({
        repository_root => $fixture_root,
        root_device => $root_stat[0],
        profile_id => $recovery_id,
        filename => 'measurement-publication.json',
        value => $recovery_value,
    });
    is($recovered->{status}, 'recovered',
        'byte-exact crash staging recovers atomically');
    ok(!-e $recovery_stage, 'recovery consumes exact staging');

    my $ambiguous_id = 'synthetic-ambiguous-publication-v1';
    my $ambiguous_value = {generation => 4};
    my $ambiguous_digest = sha256_hex(
        $json->encode($ambiguous_value) . "\n",
    );
    my $ambiguous_stage = File::Spec->catdir(
        $fixture_root, split(m{/}, join('/',
            '.artifacts/tmp/vial-scale',
            'balanced-portable-matrix-publication',
            "$ambiguous_id-$ambiguous_digest",
        )),
    );
    make_path($ambiguous_stage);
    open my $ambiguous_fh, '>:raw',
        File::Spec->catfile($ambiguous_stage, 'unexpected.json')
        or die "cannot create ambiguous fixture: $!\n";
    print {$ambiguous_fh} "{}\n";
    close $ambiguous_fh or die "cannot close ambiguous fixture: $!\n";
    like(dies(sub {
        $publish_json->({
            repository_root => $fixture_root,
            root_device => $root_stat[0],
            profile_id => $ambiguous_id,
            filename => 'measurement-publication.json',
            value => $ambiguous_value,
        });
    }), qr/staging is not recoverable/,
        'ambiguous staging is preserved and rejected');
    remove_tree($fixture_root);
    ok(!-e $fixture_root, 'synthetic fixtures leave no residue');
};

subtest 'aggregate manifests reject semantic drift' => sub {
    my $family_manifest = $class->can('_family_manifest');
    my $complete_manifest = $class->can('_complete_manifest');
    my $validate_family = $class->can('_validate_family_manifest_shape');
    my $profile = $class->inventory->[0];
    my $entry = synthetic_entry($profile);

    my $mixed = clone($entry);
    $mixed->{_common_identity}{host_profile}{identity} = 'other-host';
    my $extra = clone($entry);
    like(dies(sub { $family_manifest->([$mixed, $extra]) }),
        qr/profile count changed/,
        'aggregate construction rejects an invented second profile');

    my $family = $family_manifest->([$entry]);
    is($family->{profile_count}, 1,
        'family manifest accepts exactly one owned role');
    is($family->{dominance}{validation_records}, 1,
        'family derives one correctness authority');
    is($family->{dominance}{raw_measurement_records}, 3,
        'family retains all three raw measurements');
    is($family->{dominance}{execution_inapplicable_profiles}, 1,
        'family retains the external-execution boundary');
    my $complete = $complete_manifest->($family);
    is($complete->{total_profile_count}, 1,
        'complete manifest binds the exact family census');

    my $sample_forgery = clone($family);
    $sample_forgery->{profiles}[0]{measured_samples} = 2;
    like(dies(sub { $validate_family->($sample_forgery) }),
        qr/sample counts are invalid/,
        'aggregate rejects incomplete raw sampling');
    my $duplicate = clone($family);
    $duplicate->{profiles}[0]{measurement_identities}[1] =
        $duplicate->{profiles}[0]{measurement_identities}[0];
    like(dies(sub { $validate_family->($duplicate) }),
        qr/repeated a measurement identity/,
        'aggregate rejects duplicated raw evidence');
    my $execution = clone($family);
    $execution->{profiles}[0]{execution_applicable} = JSON::PP::true;
    $execution->{profiles}[0]{execution_reason} = undef;
    like(dies(sub { $validate_family->($execution) }),
        qr/applicability changed/,
        'aggregate rejects forged external execution');
};

subtest 'runner exposes only the immutable balanced inventory' => sub {
    my $runner = repo_path(
        'scripts/run_vial_balanced_portable_measurement_matrix.pl',
    );
    open my $inventory_fh, '-|', $runner, '--inventory'
        or die "cannot start balanced matrix inventory: $!\n";
    local $/;
    my $inventory_json = <$inventory_fh>;
    ok(close($inventory_fh),
        'fresh runner inventory exits without a guard');
    my $inventory = eval { $json->decode($inventory_json) };
    is($@, '', 'fresh runner inventory returns valid JSON');
    is($json->encode($inventory), $json->encode($class->inventory),
        'runner cannot select or reorder the owned profile');
};

subtest 'guarded capture seals and freshly reloads balanced evidence' => sub {
    plan skip_all =>
        'set FSMGEN_VIAL_SCALE_BALANCED_PORTABLE_MATRIX_EXACT=1 under the RAM guard'
        unless $ENV{FSMGEN_VIAL_SCALE_BALANCED_PORTABLE_MATRIX_EXACT};
    is($ENV{FSMGEN_RAM_GUARD_ACTIVE}, 1,
        'complete matrix executes below the repository guard');

    my $complete = $class->capture_all({repository_root => $repo_root});
    is($complete->{schema},
        'fsmgen.vial_architecture_scale_balanced_portable_complete_matrix.v1',
        'complete publication has one versioned schema');
    is($complete->{outcome}, 'accepted',
        'complete publication seals only accepted evidence');
    is($complete->{total_profile_count}, 1,
        'complete publication retains the sole owned profile');

    my $revalidated = $class->validate_complete_publication({
        repository_root => $repo_root,
    });
    is($json->encode($revalidated), $json->encode($complete),
        'same-process reload independently validates exact bytes');
    my $family = $class->validate_family_publication({
        repository_root => $repo_root,
    });
    is($family->{profile_count}, 1,
        'family publication reloads the exact owned partition');
    is($family->{dominance}{raw_measurement_records}, 3,
        'family retains three unexcluded raw samples');
    is($family->{dominance}{cleaned_records}, 4,
        'validation and all raw samples cleaned exactly');

    my @root_stat = stat($repo_root);
    my $load_profile = $class->can('_load_report_publication');
    my ($publication_set) = $load_profile->(
        $repo_root, $root_stat[0], $class->inventory->[0],
    );
    my $report = $publication_set->{report};
    is($report->{outcome}, 'accepted',
        'raw publication retains the accepted adapter report');
    is(scalar(@{$report->{measurement_records}}), 3,
        'raw publication retains every measurement record');
    is_deeply($report->{sample_exclusions}, [],
        'raw publication discards no measurement record');
    ok(!$report->{execution_applicability}{applicable},
        'raw publication cannot invent external execution');
    is_deeply(
        [@{$report->{canonical_emission}{artifact_oracle}}{qw(
            mapped_binding_count mapped_operation_count artifact_count
            source_artifact_count source_bytes source_map_entries
        )}],
        [2_048, 1_024, 8, 3, 503_279, 3_605],
        'raw publication retains exact structural evidence');

    my $runner = repo_path(
        'scripts/run_vial_balanced_portable_measurement_matrix.pl',
    );
    open my $fresh, '-|', $runner, '--validate'
        or die "cannot start fresh balanced reload: $!\n";
    local $/;
    my $fresh_json = <$fresh>;
    ok(close($fresh), 'fresh-process reload exits successfully');
    my $fresh_complete = eval { $json->decode($fresh_json) };
    is($@, '', 'fresh-process reload returns valid JSON');
    is($json->encode($fresh_complete), $json->encode($complete),
        'fresh process returns the exact complete identity');
    ok(!-e repo_path(
            '.artifacts/tmp/vial-scale/balanced-portable-matrix-publication',
        ), 'complete publication leaves no matrix staging');
};

done_testing;

sub synthetic_entry {
    my ($profile) = @_;
    return {
        %$profile,
        primary_axis => 'interaction_profile',
        report_identity => 'synthetic-report',
        workload_identity => 'synthetic-workload',
        authority_identity => 'synthetic-authority',
        composition_identity => 'synthetic-composition',
        emission_identity => 'synthetic-emission',
        controller_applicable => JSON::PP::true,
        measurement_applicable => JSON::PP::true,
        execution_applicable => JSON::PP::false,
        execution_reason =>
            'no_qualified_private_revision_2_runtime_route',
        validation_identity => 'synthetic-validation',
        measurement_identities => [qw(
            synthetic-measurement-1 synthetic-measurement-2
            synthetic-measurement-3
        )],
        measured_samples => 3,
        excluded_measurement_identities => [],
        excluded_samples => 0,
        cleanup_records => 4,
        cleanup_removed => JSON::PP::true,
        residue_count => 0,
        binding_count => 2_048,
        operation_count => 1_024,
        emission_artifact_count => 8,
        source_artifact_count => 3,
        source_bytes => 503_279,
        source_map_entries => 3_605,
        outcome => 'accepted',
        diagnostics => [],
        artifact_relative_path => join('/',
            '.artifacts/qualification/vial-scale/v1',
            $profile->{profile_id}, 'measurement-publication.json',
        ),
        artifact_sha256 => 'b' x 64,
        artifact_bytes => 1_000_000,
        _common_identity => {
            git_revision => 'a' x 40,
            dirty_state => JSON::PP::false,
            host_profile => {identity => 'synthetic-host'},
            tool_profile => {identity => 'synthetic-internal-tool'},
            resource_guard => {active => JSON::PP::true},
        },
    };
}

sub repo_path {
    my ($relative) = @_;
    return File::Spec->catfile($repo_root, split m{/}, $relative);
}

sub dies {
    my ($code) = @_;
    my $ok = eval { $code->(); 1 };
    return $ok ? '' : "$@";
}

sub clone {
    my ($value) = @_;
    return $json->decode($json->encode($value));
}
