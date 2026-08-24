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

use FSM::VIAL::ArchitectureScaleBackendEmission;
use FSM::VIAL::ArchitectureScaleBackendEmissionMeasurementMatrix;

my $class =
    'FSM::VIAL::ArchitectureScaleBackendEmissionMeasurementMatrix';
my $repo_root = File::Spec->catdir($FindBin::Bin, '..');
my $json = JSON::PP->new->canonical(1)->utf8(1);

subtest 'producer-owned inventory closes all backend-emission profiles' => sub {
    my $inventory = $class->inventory;
    my $owned = FSM::VIAL::ArchitectureScaleBackendEmission->owned_shapes;
    is(scalar(@$inventory), 20,
        'four backend profiles across five levels produce 20 profiles');
    is(scalar(@$owned), scalar(@$inventory),
        'matrix cardinality comes directly from producer ownership');
    my (%profile_id, %backend, %level);
    for my $index (0 .. $#$inventory) {
        my $profile = $inventory->[$index];
        is_deeply([sort keys %$profile],
            [sort @{$class->profile_keys}],
            'each inventory member has one closed schema');
        is($profile->{backend_profile}, $owned->[$index]{backend_profile},
            'matrix preserves producer backend order');
        is($profile->{level}, $owned->[$index]{level},
            'matrix preserves producer level order');
        ok(!$profile_id{$profile->{profile_id}}++,
            'every content-addressed profile ID is unique');
        like($profile->{profile_id},
            qr/\Abackend-emission-profile-[0-9a-f]{64}\z/,
            'profile identity is a safe digest of the owned coordinates');
        is($profile->{mode},
            $profile->{level} eq 'gate_candidate_v1' ? 'gate_measurement'
                : $profile->{level} eq 'qualification_candidate_v1'
                    ? 'qualification_measurement' : 'validation',
            'profile mode exactly matches the sealed adapter route');
        $backend{$profile->{backend_profile}}++;
        $level{$profile->{level}}++;
    }
    is_deeply([sort values %backend], [5, 5, 5, 5],
        'every producer backend owns five matrix profiles');
    is_deeply([sort values %level], [4, 4, 4, 4, 4],
        'every producer level owns four matrix profiles');
    is_deeply([sort @{$class->matrix_keys}], [sort qw(
        schema schema_version matrix_identity family profile_count
        common_identity profiles dominance outcome diagnostics
        explicit_nonclaims
    )], 'family manifest is closed');

    my $limits = $class->publication_limits;
    is($limits->{calibrated_canonical_report_bytes}, 334_757,
        'publication bound names its observed calibration input');
    cmp_ok($limits->{maximum_publication_bytes}, '>',
        $limits->{calibrated_canonical_report_bytes},
        'publication bound retains positive measured headroom');
    cmp_ok($limits->{maximum_worker_result_bytes}, '<',
        $limits->{calibrated_canonical_report_bytes},
        'compact child envelope cannot accidentally carry a raw report');

    my $second = $class->inventory;
    $inventory->[0]{backend_profile} = 'forged';
    isnt($second->[0]{backend_profile}, 'forged',
        'inventory callers receive defensive values');
};

subtest 'capture and validation fail closed before profile work' => sub {
    local $ENV{FSMGEN_RAM_GUARD_ACTIVE};
    local $ENV{FSMGEN_RAM_GUARD_EFFECTIVE_HOST_MAX_PCT};
    local $ENV{FSMGEN_RAM_GUARD_EFFECTIVE_PROCESS_MAX_RSS_MB};

    like(dies(sub {
        $class->capture_all({repository_root => $repo_root});
    }), qr/active repository RAM guard/,
        'complete capture cannot run outside the real guard');
    like(dies(sub {
        $class->capture_family({
            repository_root => $repo_root,
            family => 'borrowed_family',
        });
    }), qr/unknown key 'family'/,
        'caller-selected families cannot enter the single owned partition');
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

subtest 'profile isolation and publication are bounded and immutable' => sub {
    my $profile_id = 'synthetic-backend-emission-worker-v1';
    my $parent_pid = $$;
    my $run_isolated = $class->can('_run_isolated_profile_worker');
    my $decode_envelope = $class->can('_decode_profile_worker_envelope');
    my $publish_json = $class->can('_publish_json');
    my $validate_small_payload = sub {
        my ($payload) = @_;
        die "synthetic worker payload must be one closed hash\n"
            unless ref($payload) eq 'HASH'
                && join(',', sort keys %$payload) eq 'allocated_bytes,pid';
        die "synthetic worker allocation changed\n"
            unless $payload->{allocated_bytes} == 67_108_864;
        die "synthetic worker PID is invalid\n"
            unless $payload->{pid} =~ /\A[1-9][0-9]*\z/;
    };
    my $isolated = $run_isolated->({
        profile_id => $profile_id,
        worker => sub {
            my $allocation = 'x' x 67_108_864;
            die "synthetic child allocation changed\n"
                unless length($allocation) == 67_108_864;
            return {
                allocated_bytes => length($allocation),
                pid => $$,
            };
        },
        validate_payload => $validate_small_payload,
    });
    is($isolated->{allocated_bytes}, 67_108_864,
        'large synthetic state exists only for one child lifecycle');
    isnt($isolated->{pid}, $parent_pid,
        'profile work executes outside the long-lived coordinator');

    like(dies(sub {
        $run_isolated->({
            profile_id => $profile_id,
            worker => sub { die "synthetic worker exception\n" },
            validate_payload => sub { },
        });
    }), qr/failed: synthetic worker exception/,
        'child exceptions cross the bounded envelope without ambiguity');
    like(dies(sub {
        $run_isolated->({
            profile_id => $profile_id,
            worker => sub { POSIX::_exit(23) },
            validate_payload => sub { },
        });
    }), qr/returned no result with exit status 23/,
        'an abrupt nonzero child exit fails closed');
    like(dies(sub {
        $run_isolated->({
            profile_id => $profile_id,
            worker => sub { kill 9, $$; return {} },
            validate_payload => sub { },
        });
    }), qr/terminated by signal 9/,
        'a signaled child fails closed with its exact signal');
    like(dies(sub {
        $run_isolated->({
            profile_id => $profile_id,
            worker => sub { return 'not-a-closed-payload' },
            validate_payload => sub {
                die "synthetic worker payload must be one closed hash\n";
            },
        });
    }), qr/payload is invalid: synthetic worker payload must be one closed hash/,
        'a malformed success payload cannot cross the parent boundary');
    like(dies(sub {
        $run_isolated->({
            profile_id => $profile_id,
            worker => sub { return 'x' x 65_537 },
            validate_payload => sub { },
        });
    }), qr/failed: isolated backend-emission profile worker result exceeded the bounded envelope/,
        'an oversized result becomes one bounded deterministic failure');

    my $canonical_envelope = $json->encode({
        schema =>
            'fsmgen.vial_architecture_scale_backend_emission_profile_worker.v1',
        schema_version => 1,
        ok => JSON::PP::true,
        payload => {},
        error => undef,
    });
    my (undef, $canonical_error) =
        $decode_envelope->("$canonical_envelope\n");
    is($canonical_error, 'result is not canonical JSON',
        'noncanonical worker bytes are rejected before payload use');

    my $fixture_root = repo_path(
        ".artifacts/tmp/t1662-profile-publication-collision-$$",
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
        'synthetic publication establishes one immutable identity');
    like(dies(sub {
        $publish_json->({
            repository_root => $fixture_root,
            root_device => $root_stat[0],
            profile_id => $profile_id,
            filename => 'measurement-publication.json',
            value => {generation => 2},
        });
    }), qr/publication collision/,
        'an isolated worker cannot overwrite a conflicting publication');
    like(dies(sub {
        $publish_json->({
            repository_root => $fixture_root,
            root_device => $root_stat[0],
            profile_id => 'synthetic-oversized-publication-v1',
            filename => 'measurement-publication.json',
            value => {payload => 'x' x 524_289},
        });
    }), qr/exceeds its calibrated ceiling/,
        'oversized publication bytes fail before staging begins');

    my $recovery_id = 'synthetic-recoverable-publication-v1';
    my $recovery_value = {generation => 3};
    my $recovery_bytes = $json->encode($recovery_value) . "\n";
    my $recovery_digest = sha256_hex($recovery_bytes);
    my $recovery_stage = File::Spec->catdir(
        $fixture_root, split(m{/}, join('/',
            '.artifacts/tmp/vial-scale',
            'backend-emission-matrix-publication',
            "$recovery_id-$recovery_digest",
        )),
    );
    make_path($recovery_stage);
    my $recovery_file = File::Spec->catfile(
        $recovery_stage, 'measurement-publication.json',
    );
    open my $recovery_fh, '>:raw', $recovery_file
        or die "cannot create synthetic recovery fixture: $!\n";
    print {$recovery_fh} $recovery_bytes;
    close $recovery_fh
        or die "cannot close synthetic recovery fixture: $!\n";
    my $recovered = $publish_json->({
        repository_root => $fixture_root,
        root_device => $root_stat[0],
        profile_id => $recovery_id,
        filename => 'measurement-publication.json',
        value => $recovery_value,
    });
    is($recovered->{status}, 'recovered',
        'byte-exact crash staging recovers atomically');
    ok(!-e $recovery_stage,
        'successful recovery consumes its exact staging directory');

    my $ambiguous_id = 'synthetic-ambiguous-publication-v1';
    my $ambiguous_value = {generation => 4};
    my $ambiguous_digest = sha256_hex(
        $json->encode($ambiguous_value) . "\n",
    );
    my $ambiguous_stage = File::Spec->catdir(
        $fixture_root, split(m{/}, join('/',
            '.artifacts/tmp/vial-scale',
            'backend-emission-matrix-publication',
            "$ambiguous_id-$ambiguous_digest",
        )),
    );
    make_path($ambiguous_stage);
    my $ambiguous_file = File::Spec->catfile(
        $ambiguous_stage, 'unexpected.json',
    );
    open my $ambiguous_fh, '>:raw', $ambiguous_file
        or die "cannot create ambiguous staging fixture: $!\n";
    print {$ambiguous_fh} "{}\n";
    close $ambiguous_fh
        or die "cannot close ambiguous staging fixture: $!\n";
    like(dies(sub {
        $publish_json->({
            repository_root => $fixture_root,
            root_device => $root_stat[0],
            profile_id => $ambiguous_id,
            filename => 'measurement-publication.json',
            value => $ambiguous_value,
        });
    }), qr/staging is not recoverable/,
        'ambiguous crash staging fails closed without deletion');
    ok(-e $ambiguous_file,
        'failed recovery preserves ambiguous evidence for diagnosis');
    remove_tree($fixture_root);
    ok(!-e $fixture_root,
        'synthetic publication fixtures leave no repository-local residue');
};

subtest 'aggregate manifests reject semantic partition drift' => sub {
    my $family_manifest = $class->can('_family_manifest');
    my $complete_manifest = $class->can('_complete_manifest');
    my $validate_family = $class->can('_validate_family_manifest_shape');
    my $inventory = $class->inventory;
    my $common = {
        git_revision => 'a' x 40,
        dirty_state => JSON::PP::false,
        host_profile => {identity => 'synthetic-host'},
        tool_profile => {identity => 'synthetic-tool'},
        resource_guard => {active => JSON::PP::true},
    };
    my @entries;
    for my $profile (@$inventory) {
        my $is_native = $profile->{backend_profile}
            eq 'sv_uvm_emit.accellera_2020_3_1';
        my $is_osvvm = $profile->{backend_profile}
            eq 'vhdl_osvvm_qualified';
        my $preflight = $is_native
            && ($profile->{level} eq 'qualification_candidate_v1'
                || $profile->{level} eq 'limit_v1'
                || $profile->{level} eq 'over_limit_v1');
        my $emitted = !$is_native
            || $profile->{level} eq 'reference_v1';
        my $validation = $profile->{mode} eq 'validation';
        my $applicable = !$validation && $emitted;
        my $samples = !$applicable ? 0
            : $profile->{mode} eq 'gate_measurement' ? 3 : 5;
        push @entries, {
            %$profile,
            observed_outcome => $preflight
                ? 'preflight_dominated_not_constructed'
                : $emitted ? 'accepted_structural_emission'
                    : 'backend_negotiation_rejected',
            artifacts_emitted => $emitted
                ? JSON::PP::true : JSON::PP::false,
            preflight_dominated => $preflight
                ? JSON::PP::true : JSON::PP::false,
            report_identity => 'synthetic-report',
            workload_identity => 'synthetic-workload',
            evaluation_identity => 'synthetic-evaluation',
            validation_identity => 'synthetic-validation',
            controller_applicable => JSON::PP::true,
            measurement_applicable => $applicable
                ? JSON::PP::true : JSON::PP::false,
            measurement_reason => $validation
                ? 'correctness_only_requested'
                : $applicable ? undef : 'authoritative_non_emission',
            measured_samples => $samples,
            excluded_samples => 0,
            provider_applicable => $is_osvvm
                ? JSON::PP::true : JSON::PP::false,
            provider_included => $is_osvvm
                ? JSON::PP::true : JSON::PP::false,
            provider_read_only => $is_osvvm
                ? JSON::PP::true : JSON::PP::false,
            provider_external_tool => JSON::PP::false,
            provider_classification => $is_osvvm
                ? 'sealed_osvvm_2026_05_provider_materialization'
                : 'not_applicable',
            outcome => $validation ? 'accepted_validation'
                : $applicable ? 'accepted' : 'validated_not_measured',
            diagnostics => [],
            artifact_relative_path => join('/',
                '.artifacts/qualification/vial-scale/v1',
                $profile->{profile_id}, 'measurement-publication.json',
            ),
            artifact_sha256 => 'b' x 64,
            artifact_bytes => 400_000,
            _common_identity => $common,
        };
    }
    my $family = $family_manifest->(\@entries);
    is($family->{profile_count}, 20,
        'family manifest accepts the exact producer partition');
    is($family->{dominance}{provider_verification_profiles}, 5,
        'family manifest derives the exact provider partition');
    my $complete = $complete_manifest->($family);
    is($complete->{total_profile_count}, 20,
        'complete manifest binds the accepted family census');

    my $reordered = $json->decode($json->encode($family));
    @{$reordered->{profiles}}[0, 1] =
        @{$reordered->{profiles}}[1, 0];
    like(dies(sub { $validate_family->($reordered) }),
        qr/profile entry (?:profile_id|level) changed/,
        'aggregate validation rejects reordered owned profiles');
    my $provider_forgery = $json->decode($json->encode($family));
    my ($portable) = grep {
        $_->{backend_profile} eq 'sv_portable_verilator'
    } @{$provider_forgery->{profiles}};
    $portable->{provider_included} = JSON::PP::true;
    like(dies(sub { $validate_family->($provider_forgery) }),
        qr/provider classification changed/,
        'aggregate validation rejects borrowed provider evidence');
    my $sample_forgery = $json->decode($json->encode($family));
    my ($gate) = grep {
        $_->{backend_profile} eq 'sv_portable_verilator'
            && $_->{level} eq 'gate_candidate_v1'
    } @{$sample_forgery->{profiles}};
    $gate->{measured_samples} = 2;
    like(dies(sub { $validate_family->($sample_forgery) }),
        qr/sample count changed/,
        'aggregate validation rejects incomplete raw sampling');
};

subtest 'guarded capture seals all structural backend-emission evidence' => sub {
    plan skip_all =>
        'set FSMGEN_VIAL_SCALE_BACKEND_EMISSION_MATRIX_EXACT=1 under the RAM guard'
        unless $ENV{FSMGEN_VIAL_SCALE_BACKEND_EMISSION_MATRIX_EXACT};
    is($ENV{FSMGEN_RAM_GUARD_ACTIVE}, 1,
        'complete matrix executes below the repository guard');

    my $complete = $class->capture_all({repository_root => $repo_root});
    is($complete->{schema},
        'fsmgen.vial_architecture_scale_backend_emission_complete_matrix.v1',
        'complete publication has one versioned schema');
    is($complete->{outcome}, 'accepted',
        'complete matrix seals only after every structural profile accepts');
    is($complete->{total_profile_count}, 20,
        'complete matrix retains all producer-owned profile identities');

    my $revalidated = $class->validate_complete_publication({
        repository_root => $repo_root,
    });
    is($json->encode($revalidated), $json->encode($complete),
        'complete publication independently reloads and revalidates');
    my $family = $class->validate_family_publication({
        repository_root => $repo_root,
    });
    is($family->{profile_count}, 20,
        'family publication independently recovers the full matrix');

    my %recomputed = (
        emitted_profiles => 0,
        authoritative_non_emission_profiles => 0,
        preflight_dominated_profiles => 0,
        validation_profiles => 0,
        measurement_candidate_profiles => 0,
        applicable_measurement_profiles => 0,
        inapplicable_measurement_profiles => 0,
        raw_measurement_records => 0,
        excluded_measurement_records => 0,
        provider_verification_profiles => 0,
    );
    for my $profile (@{$family->{profiles}}) {
        if ($profile->{artifacts_emitted}) {
            $recomputed{emitted_profiles}++;
        }
        else {
            $recomputed{authoritative_non_emission_profiles}++;
        }
        $recomputed{preflight_dominated_profiles}++
            if $profile->{preflight_dominated};
        if ($profile->{mode} eq 'validation') {
            $recomputed{validation_profiles}++;
            is($profile->{measured_samples}, 0,
                'validation profile retains no timing sample');
        }
        else {
            $recomputed{measurement_candidate_profiles}++;
            if ($profile->{measurement_applicable}) {
                $recomputed{applicable_measurement_profiles}++;
                my $expected =
                    $profile->{mode} eq 'gate_measurement' ? 3 : 5;
                is($profile->{measured_samples}, $expected,
                    'applicable profile retains every required raw sample');
            }
            else {
                $recomputed{inapplicable_measurement_profiles}++;
                is($profile->{measured_samples}, 0,
                    'authoritative non-emission is never timed');
            }
        }
        $recomputed{raw_measurement_records} +=
            $profile->{measured_samples};
        $recomputed{excluded_measurement_records} +=
            $profile->{excluded_samples};
        $recomputed{provider_verification_profiles}++
            if $profile->{provider_applicable}
                && $profile->{provider_included}
                && $profile->{provider_read_only}
                && !$profile->{provider_external_tool};
        is($profile->{excluded_samples}, 0,
            'accepted matrix discards no raw sample');
    }
    for my $key (sort keys %recomputed) {
        is($family->{dominance}{$key}, $recomputed{$key},
            "dominance count '$key' is recomputed from sealed profiles");
    }
    is($family->{dominance}{provider_verification_profiles}, 5,
        'all five OSVVM profiles retain read-only provider materialization');
    cmp_ok($family->{dominance}{raw_measurement_records}, '>', 0,
        'matrix retains real raw gate and qualification measurements');
    cmp_ok($family->{dominance}{authoritative_non_emission_profiles}, '>', 0,
        'matrix preserves authoritative backend non-emission');
    cmp_ok($family->{dominance}{preflight_dominated_profiles}, '>', 0,
        'matrix preserves preflight-dominated profiles');
    ok(!-e repo_path('.artifacts/tmp/vial-scale'),
        'complete publication leaves no ephemeral measurement residue');
};

done_testing;

sub repo_path {
    my ($relative) = @_;
    return File::Spec->catfile($repo_root, split m{/}, $relative);
}

sub dies {
    my ($code) = @_;
    my $ok = eval { $code->(); 1 };
    return $ok ? '' : "$@";
}
