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

use FSM::VIAL::ArchitectureScalePortableRuntimeMeasurement;
use FSM::VIAL::ArchitectureScalePortableRuntimeMeasurementMatrix;

my $class =
    'FSM::VIAL::ArchitectureScalePortableRuntimeMeasurementMatrix';
my $repo_root = File::Spec->catdir($FindBin::Bin, '..');
my $json = JSON::PP->new->canonical(1)->utf8(1);

subtest 'producer-owned inventory closes all portable-runtime profiles' => sub {
    my $inventory = $class->inventory;
    my $owned = FSM::VIAL::ArchitectureScalePortableRuntimeMeasurement->owned_shapes;
    is(scalar(@$inventory), 5,
        'one portable runtime profile across five levels is complete');
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
            qr/\Aportable-runtime-profile-[0-9a-f]{64}\z/,
            'profile identity is a safe digest of the owned coordinates');
        is($profile->{mode},
            $profile->{level} eq 'gate_candidate_v1' ? 'gate_measurement'
                : $profile->{level} eq 'qualification_candidate_v1'
                    ? 'qualification_measurement'
                    : $profile->{level} =~ /limit/ ? 'preflight'
                    : 'validation',
            'profile mode exactly matches the sealed adapter route');
        $backend{$profile->{backend_profile}}++;
        $level{$profile->{level}}++;
    }
    is_deeply([sort values %backend], [5],
        'the selected producer backend owns all five profiles');
    is_deeply([sort values %level], [1, 1, 1, 1, 1],
        'every producer level occurs exactly once');
    is_deeply([sort @{$class->matrix_keys}], [sort qw(
        schema schema_version matrix_identity family profile_count
        common_identity profiles dominance outcome diagnostics
        explicit_nonclaims
    )], 'family manifest is closed');

    my $limits = $class->publication_limits;
    is($limits->{reference_calibration_bytes}, 74_735,
        'publication bound names its guarded reference calibration');
    is($limits->{gate_calibration_publication_bytes}, 848_468,
        'bound names the exact accepted three-sample gate publication');
    is($limits->{gate_calibration_measurement_records}, 3,
        'bound derives from the exact gate repetition count');
    is($limits->{gate_calibration_trace_records}, 10_000,
        'bound derives from the exact gate workload count');
    is($limits->{qualification_measurement_records}, 5,
        'bound scales to the selected qualification repetition count');
    is($limits->{qualification_trace_records}, 15_000,
        'bound scales to the selected qualification workload count');
    is($limits->{qualification_projection_bytes}, 2_121_170,
        'bound conservatively scales the complete gate publication twice');
    cmp_ok($limits->{maximum_publication_bytes}, '>',
        $limits->{qualification_projection_bytes},
        'publication bound retains positive projected headroom');
    cmp_ok($limits->{maximum_worker_result_bytes}, '<',
        $limits->{reference_calibration_bytes},
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
    my $profile_id = 'synthetic-portable-runtime-worker-v1';
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
    }), qr/failed: isolated portable-runtime profile worker result exceeded the bounded envelope/,
        'an oversized result becomes one bounded deterministic failure');

    my $canonical_envelope = $json->encode({
        schema =>
            'fsmgen.vial_architecture_scale_runtime_stream_profile_worker.v1',
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
        ".artifacts/tmp/t1670-profile-publication-collision-$$",
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
            value => {
                payload => 'x' x
                    ($class->publication_limits
                        ->{maximum_publication_bytes} + 1),
            },
        });
    }), qr/exceeds its calibrated ceiling \(actual=\d+ bytes, maximum=4194304 bytes\)/,
        'oversized publication bytes fail before staging begins');

    my $recovery_id = 'synthetic-recoverable-publication-v1';
    my $recovery_value = {generation => 3};
    my $recovery_bytes = $json->encode($recovery_value) . "\n";
    my $recovery_digest = sha256_hex($recovery_bytes);
    my $recovery_stage = File::Spec->catdir(
        $fixture_root, split(m{/}, join('/',
            '.artifacts/tmp/vial-scale',
            'portable-runtime-matrix-publication',
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
            'portable-runtime-matrix-publication',
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

subtest 'tool-free profiles inherit but cannot forge capture identity' => sub {
    my $derive = $class->can('_report_common_identity');
    my $report = FSM::VIAL::ArchitectureScalePortableRuntimeMeasurement
        ->validate_profile({
            repository_root => $repo_root,
            level => 'limit_v1',
        });
    my $common = {
        git_revision => 'a' x 40,
        dirty_state => JSON::PP::false,
        host_profile => {identity => 'synthetic-host'},
        tool_profile =>
            FSM::VIAL::ArchitectureScalePortableRuntimeMeasurement
                ->tool_profile,
        resource_guard => {active => JSON::PP::true},
    };
    like(dies(sub { $derive->($report) }),
        qr/no inherited capture identity/,
        'preflight report cannot originate a host/revision/guard identity');
    is_deeply($derive->($report, $common), $common,
        'preflight report inherits the already sealed executable identity');
    my $forged = $json->decode($json->encode($common));
    $forged->{tool_profile}{build} = 'forged';
    like(dies(sub { $derive->($report, $forged) }),
        qr/preflight tool identity changed/,
        'preflight report cannot inherit a mismatched tool identity');
};

subtest 'real adapter dispatch keeps both preflight profiles tool-free' => sub {
    local $ENV{FSMGEN_RAM_GUARD_ACTIVE};
    local $ENV{FSMGEN_RAM_GUARD_EFFECTIVE_HOST_MAX_PCT};
    local $ENV{FSMGEN_RAM_GUARD_EFFECTIVE_PROCESS_MAX_RSS_MB};
    my $dispatch = $class->can('_produce_profile_report');
    my $inventory = $class->inventory;

    for my $level (qw(limit_v1 over_limit_v1)) {
        my ($profile) = grep { $_->{level} eq $level } @$inventory;
        my $report = $dispatch->($profile, {
            repository_root => $repo_root,
            level => $level,
        });
        FSM::VIAL::ArchitectureScalePortableRuntimeMeasurement
            ->validate_report({
                repository_root => $repo_root,
                report => $report,
            });
        is($report->{level}, $level,
            "$level dispatch preserves the producer-owned level");
        is($report->{mode}, 'preflight',
            "$level dispatch selects the real validation/preflight route");
        is($report->{outcome}, 'preflight_dominated',
            "$level remains an honest preflight-dominated outcome");
        ok(!$report->{controller_applicability}{applicable},
            "$level does not execute the common controller");
        ok(!$report->{measurement_applicability}{applicable},
            "$level does not become measurement-applicable");
        ok(!defined($report->{validation_record}),
            "$level retains no runtime validation record");
        is(scalar(@{$report->{measurement_records}}), 0,
            "$level retains no measured repetition");
        is($report->{cleanup}{records_total}, 0,
            "$level creates no lifecycle cleanup record");
        is(scalar(@{$report->{cleanup}{residue}}), 0,
            "$level leaves no runtime residue");
    }

    my $unrouted = {%{$inventory->[0]}, mode => 'unrouted'};
    like(dies(sub {
        $dispatch->($unrouted, {
            repository_root => $repo_root,
            level => $unrouted->{level},
        });
    }), qr/profile mode has no producer route/,
        'an unhandled matrix mode fails closed before producer execution');
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
    my %records = (
        reference_v1 => 274,
        gate_candidate_v1 => 10_000,
        qualification_candidate_v1 => 15_000,
        limit_v1 => 8_000_002,
        over_limit_v1 => 8_000_003,
    );
    my @entries;
    for my $profile (@$inventory) {
        my $preflight = $profile->{mode} eq 'preflight';
        my $validation = $profile->{mode} eq 'validation';
        my $applicable = !$validation && !$preflight;
        my $samples = !$applicable ? 0
            : $profile->{mode} eq 'gate_measurement' ? 3 : 5;
        my @measurement_ids = map { "synthetic-measurement-$_" }
            1 .. $samples;
        push @entries, {
            %$profile,
            preflight_dominated => $preflight
                ? JSON::PP::true : JSON::PP::false,
            report_identity => 'synthetic-report',
            workload_identity => 'synthetic-workload',
            materialization_identity => 'synthetic-materialization',
            requested_trace_records => $records{$profile->{level}},
            controller_applicable => $preflight
                ? JSON::PP::false : JSON::PP::true,
            measurement_applicable => $applicable
                ? JSON::PP::true : JSON::PP::false,
            measurement_reason => $preflight ? 'preflight_dominated'
                : $validation
                ? 'correctness_only_requested'
                : undef,
            validation_identity => $preflight
                ? undef : 'synthetic-validation',
            validation_trace_records => $preflight
                ? undef : $records{$profile->{level}},
            validation_artifact_count => $preflight ? 0 : 12,
            measurement_identities => \@measurement_ids,
            measured_samples => $samples,
            excluded_measurement_identities => [],
            excluded_samples => 0,
            cleanup_records => $preflight ? 0 : 1 + $samples,
            cleanup_removed => JSON::PP::true,
            residue_count => 0,
            outcome => $preflight ? 'preflight_dominated'
                : $validation ? 'accepted_validation' : 'accepted',
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
    my @mixed = map { $json->decode($json->encode($_)) } @entries;
    $mixed[-1]{_common_identity}{host_profile}{identity} = 'other-host';
    like(dies(sub { $family_manifest->(\@mixed) }),
        qr/mixed common identities/,
        'aggregate construction rejects mixed revision/host/tool/guard sets');
    my $family = $family_manifest->(\@entries);
    is($family->{profile_count}, 5,
        'family manifest accepts the exact producer partition');
    is($family->{dominance}{raw_measurement_records}, 8,
        'family manifest derives all eight selected measured repetitions');
    my $complete = $complete_manifest->($family);
    is($complete->{total_profile_count}, 5,
        'complete manifest binds the accepted family census');

    my $reordered = $json->decode($json->encode($family));
    @{$reordered->{profiles}}[0, 1] =
        @{$reordered->{profiles}}[1, 0];
    like(dies(sub { $validate_family->($reordered) }),
        qr/profile entry (?:profile_id|level) changed/,
        'aggregate validation rejects reordered owned profiles');
    my $sample_forgery = $json->decode($json->encode($family));
    my ($gate) = grep {
        $_->{backend_profile} eq 'sv_portable_verilator'
            && $_->{level} eq 'gate_candidate_v1'
    } @{$sample_forgery->{profiles}};
    $gate->{measured_samples} = 2;
    like(dies(sub { $validate_family->($sample_forgery) }),
        qr/sample counts are invalid/,
        'aggregate validation rejects incomplete raw sampling');
    my $identity_forgery = $json->decode($json->encode($family));
    my ($qualification) = grep {
        $_->{level} eq 'qualification_candidate_v1'
    } @{$identity_forgery->{profiles}};
    $qualification->{measurement_identities}[1] =
        $qualification->{measurement_identities}[0];
    like(dies(sub { $validate_family->($identity_forgery) }),
        qr/repeated a measurement identity/,
        'aggregate validation rejects duplicated raw evidence');
    my $preflight_forgery = $json->decode($json->encode($family));
    my ($limit) = grep { $_->{level} eq 'limit_v1' }
        @{$preflight_forgery->{profiles}};
    $limit->{controller_applicable} = JSON::PP::true;
    like(dies(sub { $validate_family->($preflight_forgery) }),
        qr/preflight entry executed the controller/,
        'aggregate validation rejects forged preflight execution');
};

subtest 'guarded capture seals all portable runtime evidence' => sub {
    plan skip_all =>
        'set FSMGEN_VIAL_PORTABLE_RUNTIME_MATRIX_EXACT=1 under the RAM guard'
        unless $ENV{FSMGEN_VIAL_PORTABLE_RUNTIME_MATRIX_EXACT};
    is($ENV{FSMGEN_RAM_GUARD_ACTIVE}, 1,
        'complete matrix executes below the repository guard');

    my $complete = $class->capture_all({repository_root => $repo_root});
    is($complete->{schema},
        'fsmgen.vial_architecture_scale_portable_runtime_complete_matrix.v1',
        'complete publication has one versioned schema');
    is($complete->{outcome}, 'accepted',
        'complete matrix seals only after every runtime profile accepts');
    is($complete->{total_profile_count}, 5,
        'complete matrix retains all producer-owned profile identities');

    my $revalidated = $class->validate_complete_publication({
        repository_root => $repo_root,
    });
    is($json->encode($revalidated), $json->encode($complete),
        'complete publication independently reloads and revalidates');
    my $family = $class->validate_family_publication({
        repository_root => $repo_root,
    });
    is($family->{profile_count}, 5,
        'family publication independently recovers the full matrix');

    my %recomputed = (
        preflight_dominated_profiles => 0,
        controller_applicable_profiles => 0,
        controller_inapplicable_profiles => 0,
        validation_route_profiles => 0,
        measured_route_profiles => 0,
        measurement_applicable_profiles => 0,
        measurement_inapplicable_profiles => 0,
        validation_records => 0,
        raw_measurement_records => 0,
        excluded_measurement_records => 0,
        cleaned_records => 0,
        residue_records => 0,
    );
    for my $profile (@{$family->{profiles}}) {
        $recomputed{preflight_dominated_profiles}++
            if $profile->{preflight_dominated};
        $recomputed{controller_applicable_profiles}++
            if $profile->{controller_applicable};
        $recomputed{controller_inapplicable_profiles}++
            unless $profile->{controller_applicable};
        if ($profile->{mode} eq 'validation'
                || $profile->{mode} eq 'preflight') {
            $recomputed{validation_route_profiles}++;
            is($profile->{measured_samples}, 0,
                'validation/preflight route retains no measured repetition');
        }
        else {
            $recomputed{measured_route_profiles}++;
            my $expected =
                $profile->{mode} eq 'gate_measurement' ? 3 : 5;
            is($profile->{measured_samples}, $expected,
                'measured route retains every selected raw repetition');
        }
        $recomputed{measurement_applicable_profiles}++
            if $profile->{measurement_applicable};
        $recomputed{measurement_inapplicable_profiles}++
            unless $profile->{measurement_applicable};
        $recomputed{validation_records}++
            if defined($profile->{validation_identity});
        $recomputed{raw_measurement_records} +=
            $profile->{measured_samples};
        $recomputed{excluded_measurement_records} +=
            $profile->{excluded_samples};
        $recomputed{cleaned_records} += $profile->{cleanup_records};
        $recomputed{residue_records} += $profile->{residue_count};
        is($profile->{excluded_samples}, 0,
            'accepted matrix discards no raw sample');
    }
    for my $key (sort keys %recomputed) {
        is($family->{dominance}{$key}, $recomputed{$key},
            "dominance count '$key' is recomputed from sealed profiles");
    }
    is($family->{dominance}{raw_measurement_records}, 8,
        'matrix retains all eight gate and qualification repetitions');
    is($family->{dominance}{preflight_dominated_profiles}, 2,
        'matrix preserves both tool-free preflight profiles');
    is($family->{dominance}{cleaned_records}, 11,
        'all three validations and eight repetitions clean exactly');

    my $runner = repo_path(
        'scripts/run_vial_portable_runtime_measurement_matrix.pl',
    );
    open my $fresh, '-|', $runner, '--validate'
        or die "cannot start fresh matrix reload: $!\n";
    local $/;
    my $fresh_json = <$fresh>;
    ok(close($fresh), 'fresh-process complete reload exits successfully');
    my $fresh_complete = eval { $json->decode($fresh_json) };
    is($@, '', 'fresh-process complete reload returns valid JSON');
    is($json->encode($fresh_complete), $json->encode($complete),
        'fresh-process reload returns the exact complete identity');

    ok(!-e repo_path(
            '.artifacts/tmp/vial-scale/portable-runtime-matrix-publication',
        ),
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
