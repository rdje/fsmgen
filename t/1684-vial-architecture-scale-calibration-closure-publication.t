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

use FSM::VIAL::ArchitectureScaleCalibrationClosurePublication;

my $class =
    'FSM::VIAL::ArchitectureScaleCalibrationClosurePublication';
my $repo_root = File::Spec->catdir($FindBin::Bin, '..');
my $json = JSON::PP->new->canonical(1)->utf8(1);

subtest 'publisher exposes one caller-closed immutable contract' => sub {
    is_deeply([sort @{$class->manifest_keys}], [sort qw(
        schema schema_version publication_identity closure_identity
        publisher_revision report_artifact summary candidate_formula outcome
        diagnostics explicit_nonclaims
    )], 'publication manifest has one closed schema');
    my $limits = $class->publication_limits;
    is($limits->{maximum_report_bytes}, 2_097_152,
        'sealed closure report stays below the two-MiB storage envelope');
    is($limits->{maximum_manifest_bytes}, 65_536,
        'compact manifest stays below the 64-KiB envelope');
    is($limits->{maximum_worker_result_bytes}, 65_536,
        'isolated worker cannot return the full closure through IPC');
    cmp_ok($limits->{maximum_worker_result_bytes}, '<',
        $limits->{maximum_report_bytes},
        'worker result remains smaller than the full report');

    my $nonclaims = $class->explicit_nonclaims;
    ok((grep { $_ eq 'promoted_performance_budget' } @$nonclaims),
        'publication does not promote candidate evidence');
    ok((grep { $_ eq 'cap_implementation' } @$nonclaims),
        'publication does not implement architecture caps');

    like(dies(sub {
        FSM::VIAL::ArchitectureScaleCalibrationClosurePublication::manifest_keys(
            'borrowed');
    }), qr/requires the exact class invocant/,
        'borrowed class invocants fail closed');

    local $ENV{FSMGEN_RAM_GUARD_ACTIVE};
    local $ENV{FSMGEN_RAM_GUARD_EFFECTIVE_HOST_MAX_PCT};
    local $ENV{FSMGEN_RAM_GUARD_EFFECTIVE_PROCESS_MAX_RSS_MB};
    like(dies(sub {
        $class->capture_all({repository_root => $repo_root});
    }), qr/active repository RAM guard/,
        'capture cannot run outside the repository guard');
    like(dies(sub {
        $class->capture_all({
            repository_root => $repo_root,
            report => {},
        });
    }), qr/unknown key 'report'/,
        'callers cannot inject a derived report');
    like(dies(sub {
        $class->validate_complete_publication({
            repository_root => $repo_root,
            publication => {},
        });
    }), qr/unknown key 'publication'/,
        'callers cannot inject publication evidence into reload');
};

subtest 'isolation rejects exceptions, signals, and oversized IPC' => sub {
    my $run = $class->can('_run_isolated_worker');
    ok(defined($run), 'publisher exposes its private isolation primitive');
    my $parent_pid = $$;
    my $result = $run->({
        operation => 'synthetic-allocation',
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
    is($result->{allocated_bytes}, 4_194_304,
        'representative closure state stays inside one child');
    isnt($result->{pid}, $parent_pid,
        'coordinator does not retain the child allocation');
    like(dies(sub {
        $run->({
            operation => 'synthetic-exception',
            worker => sub { die "synthetic worker exception\n" },
            validate_payload => sub { },
        });
    }), qr/failed: synthetic worker exception/,
        'worker exceptions cross one bounded failure envelope');
    like(dies(sub {
        $run->({
            operation => 'synthetic-exit',
            worker => sub { POSIX::_exit(23) },
            validate_payload => sub { },
        });
    }), qr/returned no result with exit status 23/,
        'abrupt child exit fails closed');
    like(dies(sub {
        $run->({
            operation => 'synthetic-signal',
            worker => sub { kill 9, $$; return {} },
            validate_payload => sub { },
        });
    }), qr/terminated by signal 9/,
        'signalled child reports the exact signal');
    like(dies(sub {
        $run->({
            operation => 'synthetic-oversize',
            worker => sub { return 'x' x 65_537 },
            validate_payload => sub { },
        });
    }), qr/result exceeded the bounded envelope/,
        'full or oversized state cannot cross compact IPC');
};

subtest 'two-file atomic publication rejects collision and ambiguity' => sub {
    my $publish = $class->can('_publish_file_set');
    my $digest = $class->can('_file_set_digest');
    my $fixture_root = repo_path(
        ".artifacts/tmp/t1684-publication-fixture-$$",
    );
    remove_tree($fixture_root) if -e $fixture_root || -l $fixture_root;
    make_path(File::Spec->catdir($fixture_root, '.git'));
    my @root_stat = stat($fixture_root);

    my $first_report = $json->encode({generation => 1}) . "\n";
    my $first_manifest = $json->encode({manifest => 1}) . "\n";
    my $first = $publish->({
        repository_root => $fixture_root,
        root_device => $root_stat[0],
        publication_id => 'synthetic-calibration-closure-v1',
        report_bytes => $first_report,
        manifest_bytes => $first_manifest,
    });
    is($first->{status}, 'published',
        'first two-file publication is atomically visible');
    like(dies(sub {
        $publish->({
            repository_root => $fixture_root,
            root_device => $root_stat[0],
            publication_id => 'synthetic-calibration-closure-v1',
            report_bytes => $json->encode({generation => 2}) . "\n",
            manifest_bytes => $first_manifest,
        });
    }), qr/publication collision/,
        'different bytes cannot overwrite an immutable directory');

    my $recovery_id = 'synthetic-calibration-recovery-v1';
    my $recovery_report = $json->encode({generation => 3}) . "\n";
    my $recovery_manifest = $json->encode({manifest => 3}) . "\n";
    my $recovery_digest = $digest->(
        $recovery_report, $recovery_manifest,
    );
    my $recovery_stage = File::Spec->catdir(
        $fixture_root, split(m{/}, join('/',
            '.artifacts/tmp/vial-scale',
            'calibration-closure-publication',
            "$recovery_id-$recovery_digest",
        )),
    );
    make_path($recovery_stage);
    write_bytes(File::Spec->catfile(
        $recovery_stage, 'calibration-closure.json',
    ), $recovery_report);
    write_bytes(File::Spec->catfile(
        $recovery_stage, 'closure-manifest.json',
    ), $recovery_manifest);
    my $recovered = $publish->({
        repository_root => $fixture_root,
        root_device => $root_stat[0],
        publication_id => $recovery_id,
        report_bytes => $recovery_report,
        manifest_bytes => $recovery_manifest,
    });
    is($recovered->{status}, 'recovered',
        'byte-exact two-file crash staging recovers atomically');
    ok(!-e $recovery_stage, 'recovery consumes exact staging');

    my $ambiguous_id = 'synthetic-calibration-ambiguous-v1';
    my $ambiguous_report = $json->encode({generation => 4}) . "\n";
    my $ambiguous_manifest = $json->encode({manifest => 4}) . "\n";
    my $ambiguous_digest = $digest->(
        $ambiguous_report, $ambiguous_manifest,
    );
    my $ambiguous_stage = File::Spec->catdir(
        $fixture_root, split(m{/}, join('/',
            '.artifacts/tmp/vial-scale',
            'calibration-closure-publication',
            "$ambiguous_id-$ambiguous_digest",
        )),
    );
    make_path($ambiguous_stage);
    write_bytes(File::Spec->catfile(
        $ambiguous_stage, 'calibration-closure.json',
    ), $ambiguous_report);
    write_bytes(File::Spec->catfile(
        $ambiguous_stage, 'unexpected.json',
    ), $ambiguous_manifest);
    like(dies(sub {
        $publish->({
            repository_root => $fixture_root,
            root_device => $root_stat[0],
            publication_id => $ambiguous_id,
            report_bytes => $ambiguous_report,
            manifest_bytes => $ambiguous_manifest,
        });
    }), qr/staging is not recoverable/,
        'partial or ambiguous staging is preserved and rejected');

    my $symlink_id = 'synthetic-calibration-symlink-v1';
    my $target = File::Spec->catdir(
        $fixture_root, split(m{/}, join('/',
            '.artifacts/qualification/vial-scale/v1', $symlink_id,
        )),
    );
    make_path(File::Spec->catdir($fixture_root,
        '.artifacts', 'qualification', 'vial-scale', 'v1'));
    symlink($fixture_root, $target)
        or die "cannot create publication symlink fixture: $!\n";
    like(dies(sub {
        $publish->({
            repository_root => $fixture_root,
            root_device => $root_stat[0],
            publication_id => $symlink_id,
            report_bytes => $first_report,
            manifest_bytes => $first_manifest,
        });
    }), qr/destination traverses a symlink/,
        'symlinked publication destination fails closed');

    like(dies(sub {
        $publish->({
            repository_root => $fixture_root,
            root_device => $root_stat[0],
            publication_id => 'synthetic-calibration-oversized-v1',
            report_bytes => 'x' x 2_097_153,
            manifest_bytes => $first_manifest,
        });
    }), qr/report exceeds its storage envelope/,
        'oversized report is rejected before staging');

    remove_tree($fixture_root);
    ok(!-e $fixture_root && !-l $fixture_root,
        'synthetic publication fixture leaves no residue');
};

subtest 'manifest identity rejects report or summary drift' => sub {
    my $build = $class->can('_publication_manifest');
    my $validate = $class->can('_validate_manifest_shape');
    my $report = synthetic_report();
    my $manifest = $build->($report, 'a' x 40);
    $validate->($manifest);
    like($manifest->{publication_identity},
        qr/\Acalibration-closure-publication\/[0-9a-f]{64}\z/,
        'manifest has one content identity');
    is($manifest->{report_artifact}{sha256},
        sha256_hex($json->encode($report) . "\n"),
        'manifest independently binds exact report bytes');

    for my $case (
        ['artifact digest', sub { $_[0]{report_artifact}{sha256} = 'b' x 64 }],
        ['closure identity', sub { $_[0]{closure_identity} = 'calibration-closure/' . ('c' x 64) }],
        ['summary', sub { $_[0]{summary}{profile_count}++ }],
        ['candidate formula', sub { $_[0]{candidate_formula}{status} = 'promoted' }],
        ['nonclaim', sub { pop @{$_[0]{explicit_nonclaims}} }],
    ) {
        my ($name, $mutate) = @$case;
        my $copy = clone($manifest);
        $mutate->($copy);
        like(dies(sub { $validate->($copy) }),
            qr/publication identity changed|summary changed|candidate formula changed|nonclaims changed/,
            "$name drift fails closed");
    }
};

subtest 'fresh runner exposes only fixed limits before capture' => sub {
    my $runner = repo_path(
        'scripts/run_vial_calibration_closure_publication.pl',
    );
    open my $limits_fh, '-|', $^X, $runner, '--limits'
        or die "cannot start calibration publication runner: $!\n";
    local $/;
    my $limits_json = <$limits_fh>;
    ok(close($limits_fh), 'fresh limits runner exits without a guard');
    my $limits = eval { $json->decode($limits_json) };
    is($@, '', 'fresh limits runner returns valid JSON');
    is($json->encode($limits), $json->encode($class->publication_limits),
        'runner cannot select a publication or inject a report');
};

subtest 'guarded capture atomically seals and freshly reloads closure' => sub {
    plan skip_all =>
        'set FSMGEN_VIAL_SCALE_CALIBRATION_PUBLICATION_EXACT=1 under the RAM guard'
        unless $ENV{FSMGEN_VIAL_SCALE_CALIBRATION_PUBLICATION_EXACT};
    is($ENV{FSMGEN_RAM_GUARD_ACTIVE}, 1,
        'closure publication executes below the repository guard');

    my $manifest = $class->capture_all({repository_root => $repo_root});
    is($manifest->{schema},
        'fsmgen.vial_architecture_scale_calibration_closure_publication.v1',
        'publication has one versioned manifest schema');
    is($manifest->{summary}{authority_count}, 7,
        'publication retains all seven source authorities');
    is($manifest->{summary}{family_count}, 9,
        'publication retains all nine measured families');
    is($manifest->{summary}{profile_count}, 216,
        'publication retains all 216 derived profiles');
    is($manifest->{summary}{raw_measurement_records}, 356,
        'publication retains every raw measurement identity');
    is($manifest->{summary}{excluded_measurement_records}, 0,
        'publication retains the exact zero-exclusion result');
    cmp_ok($manifest->{report_artifact}{bytes}, '<=', 2_097_152,
        'canonical report fits its immutable storage envelope');

    my $loaded = $class->validate_complete_publication({
        repository_root => $repo_root,
    });
    is($json->encode($loaded), $json->encode($manifest),
        'same-process reload returns the exact manifest identity');
    my $load = $class->can('_load_publication');
    my @root_stat = stat($repo_root);
    my ($report, $reloaded) = $load->($repo_root, $root_stat[0]);
    is($report->{closure_identity}, $manifest->{closure_identity},
        'full report reload agrees with the compact manifest');
    is($json->encode($reloaded), $json->encode($manifest),
        'full report and manifest form one immutable file set');

    my $runner = repo_path(
        'scripts/run_vial_calibration_closure_publication.pl',
    );
    open my $fresh, '-|', $^X, $runner, '--validate'
        or die "cannot start fresh calibration reload: $!\n";
    local $/;
    my $fresh_json = <$fresh>;
    ok(close($fresh), 'fresh-process reload exits successfully');
    my $fresh_manifest = eval { $json->decode($fresh_json) };
    is($@, '', 'fresh-process reload returns valid JSON');
    is($json->encode($fresh_manifest), $json->encode($manifest),
        'fresh process returns the exact closure publication identity');
    ok(!-e repo_path(
            '.artifacts/tmp/vial-scale/calibration-closure-publication',
        ), 'complete publication leaves no staging residue');
};

done_testing;

sub synthetic_report {
    my $nonclaims = $class->explicit_nonclaims;
    return {
        closure_identity => 'calibration-closure/' . ('d' x 64),
        summary => {
            authority_count => 7,
            family_count => 9,
            profile_count => 216,
            raw_measurement_records => 356,
            excluded_measurement_records => 0,
            candidate_profiles => 92,
            noncandidate_profiles => 124,
        },
        candidate_formula => {
            authority => 'decision-0056',
            status => 'candidate_only',
            wall_time_ns => {
                floor => 2_000_000_000,
                multiplier_numerator => 3,
                multiplier_denominator => 2,
                rounding_quantum => 1_000_000,
            },
            cpu_time_ns => {
                floor => 2_000_000_000,
                multiplier_numerator => 3,
                multiplier_denominator => 2,
                rounding_quantum => 1_000_000,
            },
            peak_tree_rss_bytes => {
                floor => 268_435_456,
                multiplier_numerator => 5,
                multiplier_denominator => 4,
                rounding_quantum => 16_777_216,
            },
        },
        outcome => 'accepted',
        diagnostics => [],
        explicit_nonclaims => $nonclaims,
    };
}

sub write_bytes {
    my ($path, $bytes) = @_;
    open my $fh, '>:raw', $path
        or die "cannot create synthetic publication file: $!\n";
    print {$fh} $bytes;
    close $fh or die "cannot close synthetic publication file: $!\n";
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
