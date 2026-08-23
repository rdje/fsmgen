#!/usr/bin/env perl

use strict;
use warnings;

use File::Path qw(make_path remove_tree);
use File::Spec;
use FindBin;
use JSON::PP ();
use POSIX ();
use Test::More;

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::VIAL::ArchitectureScaleExecutionCheckingMeasurementMatrix;

my $class =
    'FSM::VIAL::ArchitectureScaleExecutionCheckingMeasurementMatrix';
my $repo_root = File::Spec->catdir($FindBin::Bin, '..');
my $json = JSON::PP->new->canonical(1)->utf8(1);

subtest 'closed inventory owns every reachable execution and checking profile' => sub {
    my $inventory = $class->inventory;
    is(scalar(@$inventory), 72,
        'four levels across eighteen producer-owned axes produce 72 profiles');
    my %family;
    my %profile_id;
    for my $profile (@$inventory) {
        is_deeply([sort keys %$profile],
            [sort @{$class->profile_keys}],
            'each inventory member has one closed schema');
        ok(!$profile_id{$profile->{profile_id}}++,
            'every publication profile ID is unique');
        $family{$profile->{family}}++;
        like($profile->{profile_id},
            qr/\A[a-z][a-z0-9_.-]*\z/,
            'profile ID is safe for repository-local publication');
        is($profile->{mode},
            $profile->{level} eq 'gate_candidate_v1' ? 'gate_measurement'
                : $profile->{level} eq 'qualification_candidate_v1'
                    ? 'qualification_measurement' : 'validation',
            'profile mode exactly matches the sealed adapter contract');
    }
    is_deeply(\%family, {
        execution_graph_v1 => 40,
        checking_state_v1 => 32,
    }, 'inventory preserves the exact ten/eight-axis producer partition');
    is_deeply([sort @{$class->matrix_keys}], [sort qw(
        schema schema_version matrix_identity family profile_count
        common_identity profiles dominance outcome diagnostics
        explicit_nonclaims
    )], 'family matrix manifest is closed');

    my $second = $class->inventory;
    $inventory->[0]{family} = 'forged';
    isnt($second->[0]{family}, 'forged',
        'inventory callers receive defensive values');
};

subtest 'capture and publication boundaries fail closed before work' => sub {
    local $ENV{FSMGEN_RAM_GUARD_ACTIVE};
    local $ENV{FSMGEN_RAM_GUARD_EFFECTIVE_HOST_MAX_PCT};
    local $ENV{FSMGEN_RAM_GUARD_EFFECTIVE_PROCESS_MAX_RSS_MB};

    like(dies(sub {
        $class->capture_family({
            repository_root => $repo_root,
            family => 'execution_graph_v1',
        });
    }), qr/active repository RAM guard/,
        'family capture cannot run outside the real guard');
    like(dies(sub {
        $class->capture_family({
            repository_root => $repo_root,
            family => 'semantic_catalog_v1',
        });
    }), qr/family is not selected/,
        'earlier-owned families cannot enter the matrix');
    like(dies(sub {
        $class->capture_all({
            repository_root => $repo_root,
            reports => [],
        });
    }), qr/unknown key 'reports'/,
        'caller-created report collections cannot enter capture');
    like(dies(sub {
        $class->validate_family_publication({
            repository_root => $repo_root,
            family => 'unknown',
        });
    }), qr/family is not selected/,
        'publication validation rejects unknown ownership');
};

subtest 'profile isolation is bounded, process-owned, and fail closed' => sub {
    my $profile_id = 'synthetic-profile-worker-v1';
    my $parent_pid = $$;
    my $run_isolated = $class->can('_run_isolated_profile_worker');
    my $decode_envelope = $class->can('_decode_profile_worker_envelope');
    my $publish_json = $class->can('_publish_json');
    my $validate_small_payload = sub {
        my ($payload) = @_;
        die "synthetic worker payload must be one closed hash\n"
            unless ref($payload) eq 'HASH'
                && join(',', sort keys %$payload) eq 'allocated_bytes,pid';
        die "synthetic worker payload allocation is invalid\n"
            unless $payload->{allocated_bytes} == 67_108_864;
        die "synthetic worker payload PID is invalid\n"
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
                worker => sub { return 'x' x 1_048_577 },
                validate_payload => sub { },
            });
    }), qr/failed: isolated profile worker result exceeded the bounded envelope/,
        'an oversized result becomes one bounded deterministic failure');

    my $canonical_envelope = $json->encode({
        schema => 'fsmgen.vial_architecture_scale_profile_worker.v1',
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
        ".artifacts/tmp/t1660-profile-publication-collision-$$",
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
    remove_tree($fixture_root);
    ok(!-e $fixture_root,
        'synthetic collision fixture leaves no repository-local residue');
};

subtest 'guarded capture seals every raw report and authoritative outcome' => sub {
    plan skip_all =>
        'set FSMGEN_VIAL_SCALE_EXECUTION_CHECKING_MATRIX_EXACT=1 under the RAM guard'
        unless $ENV{FSMGEN_VIAL_SCALE_EXECUTION_CHECKING_MATRIX_EXACT};
    is($ENV{FSMGEN_RAM_GUARD_ACTIVE}, 1,
        'complete matrix executes below the repository guard');

    my $complete = $class->capture_all({
        repository_root => $repo_root,
    });
    is($complete->{schema},
        'fsmgen.vial_architecture_scale_execution_checking_complete_matrix.v1',
        'complete publication has one versioned schema');
    is($complete->{outcome}, 'accepted',
        'complete matrix is sealed only after every profile accepts');
    is($complete->{total_profile_count}, 72,
        'complete matrix retains all 72 owned profile-set identities');
    is(scalar(@{$complete->{family_manifests}}), 2,
        'complete matrix retains both family manifests');

    my $revalidated = $class->validate_complete_publication({
        repository_root => $repo_root,
    });
    is($json->encode($revalidated), $json->encode($complete),
        'complete publication independently reloads and revalidates');

    my @profiles;
    for my $family (qw(execution_graph_v1 checking_state_v1)) {
        my $manifest = $class->validate_family_publication({
            repository_root => $repo_root,
            family => $family,
        });
        is($manifest->{outcome}, 'accepted',
            "$family manifest is complete and accepted");
        push @profiles, @{$manifest->{profiles}};
    }
    is(scalar(@profiles), 72,
        'family publications independently recover the full matrix');

    my ($measured, $source_free) = (0, 0);
    my %authority_status;
    for my $profile (@profiles) {
        $authority_status{$profile->{authority_status}}++;
        if ($profile->{mode} eq 'validation') {
            is($profile->{measured_samples}, 0,
                'boundary profile retains correctness without timing');
        }
        elsif ($profile->{measurement_applicable}) {
            my $expected = $profile->{mode} eq 'gate_measurement' ? 3 : 5;
            is($profile->{measured_samples}, $expected,
                'applicable profile retains every required raw sample');
        }
        else {
            is($profile->{measured_samples}, 0,
                'authoritative non-applicability is never timed');
        }
        if (!$profile->{controller_applicable}) {
            ok(!defined($profile->{workload_identity}),
                'source-free profile invents no workload identity');
            ok(!defined($profile->{validation_identity}),
                'source-free profile invents no controller identity');
            $source_free++;
        }
        is($profile->{excluded_samples}, 0,
            'accepted matrix discards no raw sample');
        $measured += $profile->{measured_samples};
    }
    cmp_ok($measured, '>', 0,
        'matrix contains real raw gate and qualification measurements');
    cmp_ok($source_free, '>', 0,
        'matrix preserves source-free outcomes without borrowed identities');
    cmp_ok($authority_status{expected_rejection} // 0, '>', 0,
        'matrix preserves authoritative expected rejections');
    cmp_ok($authority_status{preflight_dominated} // 0, '>', 0,
        'matrix preserves preflight-dominated outcomes');
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
