#!/usr/bin/env perl

use v5.20;
use strict;
use warnings;
use feature qw(signatures);
no warnings 'experimental::signatures';

use bytes ();
use Digest::SHA qw(sha256_hex);
use Fcntl qw(O_CREAT O_EXCL O_NOFOLLOW O_WRONLY);
use File::Basename qw(dirname);
use File::Path qw(make_path remove_tree);
use File::Spec;
use FindBin;
use JSON::PP ();
use Test::More;

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::VIAL::ArchitectureScaleRegressionPromotionQualification;
use FSM::VIAL::ArchitectureScaleRegressionPromotionQualificationStore;

my $class =
    'FSM::VIAL::ArchitectureScaleRegressionPromotionQualificationStore';
my $qualification_class =
    'FSM::VIAL::ArchitectureScaleRegressionPromotionQualification';
my $repo_root = File::Spec->rel2abs(
    File::Spec->catdir($FindBin::Bin, '..'),
);
my $fixture_base = File::Spec->catdir(
    $repo_root, '.artifacts', 'tmp',
    "vial-regression-promotion-qualification-store-$$",
);
my $json = JSON::PP->new->canonical(1)->utf8(1);
my $fixture_sequence = 0;
my $publisher_revision = 'a' x 40;
my $maximum_report_bytes = 1_048_576;
my $maximum_manifest_bytes = 65_536;

die "qualification-store fixture root already exists\n"
    if -e $fixture_base || -l $fixture_base;
make_path($fixture_base, {mode => 0700});

END {
    remove_tree($fixture_base)
        if defined($fixture_base) && -d($fixture_base) && !-l($fixture_base);
}

my $current_qualification = qualification_fixture();
my ($derivations, $validations) = (0, 0);
{
    no warnings 'redefine';
    *FSM::VIAL::ArchitectureScaleRegressionPromotionQualification::derive =
        sub {
            $derivations++;
            return clone($current_qualification);
        };
    *FSM::VIAL::ArchitectureScaleRegressionPromotionQualification::_validate_qualification_report =
        sub {
            $validations++;
            my ($value) = @_;
            die "synthetic qualification schema changed\n"
                unless ref($value) eq 'HASH'
                    && ($value->{schema} // '') eq
                        'fsmgen.vial_architecture_scale_regression_promotion_qualification.v1';
            return 1;
        };
    *FSM::VIAL::ArchitectureScaleRegressionPromotionQualificationStore::_require_clean_revision =
        sub { return $publisher_revision };
    *FSM::VIAL::ArchitectureScaleRegressionPromotionQualificationStore::_require_unchanged_clean_revision =
        sub { return 1 };
}

local $ENV{FSMGEN_RAM_GUARD_ACTIVE} = 1;
local $ENV{FSMGEN_RAM_GUARD_EFFECTIVE_HOST_MAX_PCT} = 88;
local $ENV{FSMGEN_RAM_GUARD_EFFECTIVE_PROCESS_MAX_RSS_MB} = 4096;

subtest 'public store is caller-sealed and explicitly bounded' => sub {
    is_deeply([sort @{$class->report_keys}], [sort qw(
        schema schema_version publication_report_identity publisher_revision
        qualification publication_contract outcome diagnostics
        explicit_nonclaims
    )], 'publication report has one closed schema');
    is_deeply([sort @{$class->manifest_keys}], [sort qw(
        schema schema_version publication_identity publication_report_identity
        qualification_identity publisher_revision source_evidence
        formula_authority profile_bindings publication_contract
        report_artifact summary outcome explicit_nonclaims
    )], 'manifest has one closed schema');
    is_deeply([sort @{$class->profile_binding_keys}], [sort qw(
        ordinal selection_key profile_qualification_identity
        source_report_identity workload_identity evidence_revision
        environment_identity correctness_projection_identity
        performance_applicability_identity qualified_budget provider_status
    )], 'profile publication bindings have one closed schema');
    is_deeply([sort @{$class->artifact_keys}], [sort qw(
        schema schema_version status publication_relative_path
        report_artifact manifest_artifact file_set_sha256 same_volume atomic
    )], 'artifact metadata has one closed schema');
    is_deeply($class->load_result_keys,
        [qw(report manifest artifact)],
        'load returns only the two publications and artifact metadata');
    is_deeply($class->publication_limits, {
        publication_revision =>
            'regression_promotion_budget_qualification_store_v1',
        report_filename =>
            'regression-promotion-budget-qualification.json',
        manifest_filename => 'qualification-manifest.json',
        maximum_report_bytes => $maximum_report_bytes,
        maximum_manifest_bytes => $maximum_manifest_bytes,
        maximum_recovery_entries => 1,
        profile_count => 11,
        validation_records => 11,
        raw_measurement_records => 33,
        controller_invocations => 44,
    }, 'storage and qualification envelopes are explicit');
    is($class->publication_contract->{enforcement_state}, 'not_activated',
        'publication does not activate a performance gate');

    like(dies(sub { $class->publish({}) }), qr/is missing 'repository_root'/,
        'repository root is mandatory');
    like(dies(sub {
        $class->publish({repository_root => '.', budgets => []});
    }), qr/unknown key 'budgets'/, 'caller budgets reject');
    like(dies(sub {
        $class->load({repository_root => '.', publication_relative_path => 'x'});
    }), qr/unknown key 'publication_relative_path'/,
        'caller paths reject');
    like(dies(sub {
        FSM::VIAL::ArchitectureScaleRegressionPromotionQualificationStore::load(
            'borrowed', {},
        );
    }), qr/requires the exact class invocant/, 'borrowed invocants reject');
};

subtest 'synthetic qualification publishes atomically and reloads exactly' => sub {
    my $repo = fresh_repository('published');
    my ($before_derive, $before_validate) = ($derivations, $validations);
    no warnings 'redefine';
    local *FSM::VIAL::ArchitectureScaleMeasurement::measure =
        sub { die "measurement controller executed\n" };

    my $artifact = $class->publish({repository_root => $repo});
    is($artifact->{status}, 'published', 'first complete set publishes');
    is($artifact->{publication_relative_path}, publication_relative(),
        'store alone selects the non-colliding v2 coordinate');
    ok($artifact->{same_volume} && $artifact->{atomic},
        'metadata records same-volume atomic publication');
    is($derivations - $before_derive, 1,
        'publish derives the sealed qualification internally once');
    cmp_ok($validations - $before_validate, '>=', 1,
        'publish invokes the qualification validator internally');

    my $directory = repo_path($repo, publication_relative());
    is_deeply([directory_entries($directory)], [qw(
        qualification-manifest.json
        regression-promotion-budget-qualification.json
    )], 'publication contains exactly the report and manifest');
    for my $filename (qw(
        regression-promotion-budget-qualification.json
        qualification-manifest.json
    )) {
        my $path = File::Spec->catfile($directory, $filename);
        my $encoded = read_raw($path);
        like($encoded, qr/\n\z/, "$filename is newline terminated");
        is(canonical($json->decode($encoded)) . "\n", $encoded,
            "$filename is canonical JSON");
        my @stat = lstat($path);
        is($stat[0], (stat($repo))[0],
            "$filename stays on the repository volume");
        is($stat[3], 1, "$filename has exactly one link");
    }

    my $loaded = $class->load({repository_root => $repo});
    is_deeply($loaded->{report}{qualification}, $current_qualification,
        'load exactly rederives and returns the source qualification');
    is($loaded->{manifest}{qualification_identity},
        $current_qualification->{qualification_identity},
        'manifest binds the complete qualification identity');
    is($loaded->{artifact}{status}, 'loaded',
        'reload is distinguished from publication');
    my $unchanged = $class->publish({repository_root => $repo});
    is($unchanged->{status}, 'unchanged',
        'an exact existing publication remains immutable');
    ok(!staging_paths($repo), 'success leaves no staging residue');
};

subtest 'qualification drift, malformed bytes, aliases, and residue reject' => sub {
    my $drift_repo = published_repository('drift');
    my $saved = clone($current_qualification);
    $current_qualification->{profiles}[0]{qualified_budget}{wall_time_ns}++;
    $current_qualification->{qualification_identity} = content_identity(
        $current_qualification, 'qualification_identity',
        'regression-promotion-qualification/',
    );
    like(dies(sub { $class->load({repository_root => $drift_repo}) }),
        qr/current qualification changed/,
        'a changed freshly derived qualification cannot reuse the publication');
    $current_qualification = $saved;

    my $malformed_repo = published_repository('malformed');
    replace_publication_file($malformed_repo,
        'regression-promotion-budget-qualification.json', "{\n");
    like(dies(sub { $class->load({repository_root => $malformed_repo}) }),
        qr/report JSON is invalid/, 'malformed report bytes reject');

    my $noncanonical_repo = published_repository('noncanonical');
    my $manifest_path = publication_file(
        $noncanonical_repo, 'qualification-manifest.json');
    my $manifest = $json->decode(read_raw($manifest_path));
    replace_file($manifest_path,
        JSON::PP->new->utf8(1)->pretty(1)->encode($manifest));
    like(dies(sub { $class->load({repository_root => $noncanonical_repo}) }),
        qr/manifest JSON is not canonical/, 'noncanonical manifest rejects');

    my $oversized_repo = published_repository('oversized');
    replace_publication_file($oversized_repo,
        'regression-promotion-budget-qualification.json',
        'x' x ($maximum_report_bytes + 1));
    like(dies(sub { $class->load({repository_root => $oversized_repo}) }),
        qr/report exceeds its bounded ceiling/, 'cap-plus-one report rejects');

    my $manifest_oversized_repo = published_repository('manifest-oversized');
    replace_publication_file($manifest_oversized_repo,
        'qualification-manifest.json',
        'x' x ($maximum_manifest_bytes + 1));
    like(dies(sub {
        $class->load({repository_root => $manifest_oversized_repo});
    }), qr/manifest exceeds its bounded ceiling/,
        'cap-plus-one manifest rejects');

    my $extra_repo = published_repository('extra');
    write_raw(publication_file($extra_repo, 'extra.json'), "{}\n");
    like(dies(sub { $class->load({repository_root => $extra_repo}) }),
        qr/publication census changed/, 'an extra publication entry rejects');

    my $symlink_repo = published_repository('symlink');
    my $report_path = publication_file(
        $symlink_repo, 'regression-promotion-budget-qualification.json');
    my $target = repo_path(
        $symlink_repo, '.artifacts/tmp/qualification-symlink-target.json');
    write_raw($target, read_raw($report_path));
    unlink($report_path) or die "cannot replace report with symlink: $!\n";
    symlink($target, $report_path)
        or die "cannot create report symlink: $!\n";
    like(dies(sub { $class->load({repository_root => $symlink_repo}) }),
        qr/report artifact is invalid/, 'a symlink cannot replace the report');

    my $hard_repo = published_repository('hard-link');
    my $hard_path = publication_file(
        $hard_repo, 'regression-promotion-budget-qualification.json');
    my $hard_alias = repo_path(
        $hard_repo, '.artifacts/tmp/qualification-hard-link-alias.json');
    make_path(dirname($hard_alias), {mode => 0700});
    link($hard_path, $hard_alias)
        or die "cannot create report hard link: $!\n";
    like(dies(sub { $class->load({repository_root => $hard_repo}) }),
        qr/report artifact is hard-linked/,
        'a multiply linked report rejects');

    my $residue_repo = published_repository('residue');
    make_path(repo_path($residue_repo,
        staging_base() . '/qualification-' . ('0' x 64)), {mode => 0700});
    like(dies(sub { $class->load({repository_root => $residue_repo}) }),
        qr/retained staging residue/, 'reload rejects staging residue');
};

subtest 'exact recovery succeeds while ambiguity and collision reject' => sub {
    my $repo = fresh_repository('recovery');
    my ($report, $manifest, $report_bytes, $manifest_bytes) =
        $class->can('_publication_value')->({
            qualification => clone($current_qualification),
            publisher_revision => $publisher_revision,
        });
    my $digest = file_set_digest($report_bytes, $manifest_bytes);
    my ($stage_rel) = $class->can('_staging_directory')->({
        repository_root => $repo,
        root_device => (stat($repo))[0],
    }, $digest);
    my $stage = repo_path($repo, $stage_rel);
    make_path($stage, {mode => 0700});
    write_raw(File::Spec->catfile(
        $stage, 'regression-promotion-budget-qualification.json'),
        $report_bytes);
    write_raw(File::Spec->catfile(
        $stage, 'qualification-manifest.json'), $manifest_bytes);
    is($class->publish({repository_root => $repo})->{status}, 'recovered',
        'the exact sole interrupted stage recovers by directory rename');
    ok(!-e($stage) && !-l($stage), 'recovery moves the exact stage identity');

    my $ambiguous_repo = fresh_repository('ambiguous');
    my $base = repo_path($ambiguous_repo, staging_base());
    make_path(File::Spec->catdir($base, 'qualification-' . ('1' x 64)),
        {mode => 0700});
    make_path(File::Spec->catdir($base, 'qualification-' . ('2' x 64)),
        {mode => 0700});
    like(dies(sub { $class->publish({repository_root => $ambiguous_repo}) }),
        qr/recovery state is ambiguous/,
        'multiple interrupted stages reject before publication');

    my $malformed_repo = fresh_repository('malformed-recovery');
    my $malformed_stage = repo_path(
        $malformed_repo, staging_base() . '/qualification-' . $digest,
    );
    make_path($malformed_stage, {mode => 0700});
    write_raw(File::Spec->catfile(
        $malformed_stage,
        'regression-promotion-budget-qualification.json'), "{}\n");
    write_raw(File::Spec->catfile(
        $malformed_stage, 'qualification-manifest.json'), $manifest_bytes);
    like(dies(sub { $class->publish({repository_root => $malformed_repo}) }),
        qr/staging is not recoverable/,
        'a malformed sole stage cannot be recovered');

    my $collision_repo = published_repository('collision');
    my (undef, undef, $different_report, $different_manifest) =
        $class->can('_publication_value')->({
            qualification => clone($current_qualification),
            publisher_revision => 'b' x 40,
        });
    like(dies(sub {
        $class->can('_publish')->({
            repository_root => $collision_repo,
            root_device => (stat($collision_repo))[0],
            qualification => clone($current_qualification),
            report_bytes => $different_report,
            manifest_bytes => $different_manifest,
        });
    }), qr/publication collision/,
        'different bytes cannot overwrite the fixed publication');
};

subtest 'partial failure cleans owned state and late mutation rejects' => sub {
    my $cleanup_repo = fresh_repository('partial-cleanup');
    my $write = $class->can('_write_synced_file');
    {
        no warnings 'redefine';
        my $calls = 0;
        local *FSM::VIAL::ArchitectureScaleRegressionPromotionQualificationStore::_write_synced_file =
            sub {
                die "injected second-file failure\n" if ++$calls == 2;
                return $write->(@_);
            };
        like(dies(sub { $class->publish({repository_root => $cleanup_repo}) }),
            qr/injected second-file failure/,
            'a failure after the first staged file propagates');
    }
    ok(!-e(repo_path($cleanup_repo, publication_relative()))
            && !staging_paths($cleanup_repo),
        'partial internal failure removes only its owned stage and target');

    my $late_repo = published_repository('late-entry');
    my $read = $class->can('_read_exact_file');
    {
        no warnings 'redefine';
        my $calls = 0;
        local *FSM::VIAL::ArchitectureScaleRegressionPromotionQualificationStore::_read_exact_file =
            sub {
                my @result = $read->(@_);
                if (++$calls == 2) {
                    write_raw(File::Spec->catfile(
                        dirname($_[0]), 'late-entry.json'), "{}\n");
                }
                return @result;
            };
        like(dies(sub { $class->load({repository_root => $late_repo}) }),
            qr/publication census changed/,
            'a directory entry added after the opening census rejects');
    }
};

remove_tree($fixture_base);
ok(!-e($fixture_base) && !-l($fixture_base),
    'all synthetic publication fixtures are removed');

done_testing;

sub qualification_fixture() {
    my @profiles = map {
        my $ordinal = $_;
        {
            ordinal => $ordinal,
            selection_key => "fixture|profile|$ordinal",
            profile_qualification_identity =>
                'regression-promotion-profile-qualification/'
                . sha256_hex("profile-$ordinal"),
            source_report_identity =>
                'fixture-report/' . sha256_hex("report-$ordinal"),
            workload_identity =>
                'workload/' . sha256_hex("workload-$ordinal"),
            evidence_revision => '1' x 40,
            environment_identity =>
                'regression-promotion-environment/'
                . sha256_hex("environment-$ordinal"),
            correctness_projection_identity =>
                'regression-promotion-correctness/'
                . sha256_hex("correctness-$ordinal"),
            correctness_projection => {
                schema => 'fixture.correctness.v1',
                schema_version => 1,
                ordinal => $ordinal,
            },
            performance_applicability_identity =>
                'regression-promotion-profile-applicability/'
                . sha256_hex("applicability-$ordinal"),
            validation_identity =>
                'measurement/' . sha256_hex("validation-$ordinal"),
            raw_measurement_identities => [map {
                'measurement/' . sha256_hex("raw-$ordinal-$_")
            } 1 .. 3],
            accepted_run_totals => [],
            aggregate_statistics => {},
            qualified_budget => {
                status => 'qualified_unpublished',
                formula_authority => 'decision-0056',
                wall_time_ns => 2_000_000_000 + $ordinal,
                cpu_time_ns => 2_000_000_000 + $ordinal,
                peak_tree_rss_bytes => 268_435_456,
            },
            provider_status => {
                kind => 'not_applicable',
                logical_name => undef,
                provider_identity => undef,
            },
            outcome => 'accepted',
        }
    } 1 .. 11;
    my $value = {
        schema =>
            'fsmgen.vial_architecture_scale_regression_promotion_qualification.v1',
        schema_version => 1,
        qualification_identity => undef,
        source_evidence => {
            corpus_identity => 'regression-promotion-corpus/' . ('2' x 64),
            publication_identity =>
                'regression-promotion-corpus-publication/' . ('3' x 64),
            file_set_sha256 => '4' x 64,
            plan_identity =>
                'regression-promotion-capture-plan/' . ('5' x 64),
            policy_identity =>
                'regression-promotion-policy/' . ('6' x 64),
            publication_id => 'regression-promotion-corpus-v1',
            publication_schema =>
                'fsmgen.vial_architecture_scale_regression_promotion_corpus.v1',
            capture_revision => '1' x 40,
            dirty_state => JSON::PP::false,
        },
        formula => {
            authority => 'decision-0056',
            status => 'qualified_unpublished',
        },
        performance_applicability => {
            applicability_identity =>
                'regression-promotion-performance-applicability/' . ('7' x 64),
        },
        summary => {
            profile_count => 11,
            validation_records => 11,
            raw_measurement_records => 33,
            controller_invocations => 44,
            sample_exclusions => 0,
            qualified_profiles => 11,
        },
        profiles => \@profiles,
        outcome => 'accepted_qualified_unpublished',
        diagnostics => [],
        explicit_nonclaims => ['qualification_publication'],
    };
    $value->{qualification_identity} = content_identity(
        $value, 'qualification_identity',
        'regression-promotion-qualification/',
    );
    return $value;
}

sub content_identity($value, $key, $prefix) {
    my $copy = clone($value);
    $copy->{$key} = undef;
    return $prefix . sha256_hex(canonical($copy));
}

sub published_repository($name) {
    my $repo = fresh_repository($name);
    $class->publish({repository_root => $repo});
    return $repo;
}

sub fresh_repository($name) {
    my $repo = File::Spec->catdir(
        $fixture_base, sprintf('%02d-%s', ++$fixture_sequence, $name),
    );
    make_path(File::Spec->catdir($repo, '.git'), {mode => 0700});
    return $repo;
}

sub publication_relative() {
    return join '/', qw(
        .artifacts qualification vial-scale v2
        regression-promotion-budget-qualification-v1 current
    );
}

sub staging_base() {
    return join '/', qw(
        .artifacts tmp vial-scale
        regression-promotion-budget-qualification-publication v1
    );
}

sub publication_file($repo, $filename) {
    return File::Spec->catfile(
        repo_path($repo, publication_relative()), $filename,
    );
}

sub replace_publication_file($repo, $filename, $bytes) {
    replace_file(publication_file($repo, $filename), $bytes);
}

sub staging_paths($repo) {
    my $base = repo_path($repo, staging_base());
    return () unless -d $base;
    opendir my $dh, $base or die "cannot inspect staging: $!\n";
    my @paths = grep { /^qualification-/ } readdir $dh;
    closedir $dh or die "cannot close staging: $!\n";
    return @paths;
}

sub directory_entries($path) {
    opendir my $dh, $path or die "cannot inspect '$path': $!\n";
    my @entries = sort grep { $_ ne '.' && $_ ne '..' } readdir $dh;
    closedir $dh or die "cannot close '$path': $!\n";
    return @entries;
}

sub file_set_digest($report, $manifest) {
    return sha256_hex(join "\0",
        bytes::length($report), $report,
        bytes::length($manifest), $manifest,
    );
}

sub replace_file($path, $bytes) {
    unlink($path) or die "cannot replace '$path': $!\n";
    write_raw($path, $bytes);
}

sub write_raw($path, $bytes) {
    make_path(dirname($path), {mode => 0700}) unless -d dirname($path);
    sysopen(my $fh, $path,
        O_WRONLY | O_CREAT | O_EXCL | O_NOFOLLOW, 0600)
        or die "cannot create '$path': $!\n";
    binmode($fh, ':raw') or die "cannot set '$path' byte mode: $!\n";
    print {$fh} $bytes or die "cannot write '$path': $!\n";
    close $fh or die "cannot close '$path': $!\n";
}

sub read_raw($path) {
    open my $fh, '<:raw', $path or die "cannot read '$path': $!\n";
    local $/;
    my $bytes = <$fh>;
    close $fh or die "cannot close '$path': $!\n";
    return $bytes;
}

sub repo_path($root, $relative) {
    return File::Spec->catfile($root, split m{/}, $relative);
}

sub canonical($value) {
    return $json->encode($value);
}

sub clone($value) {
    return $json->decode($json->encode($value));
}

sub dies($code) {
    my $ok = eval { $code->(); 1 };
    return '' if $ok;
    return $@;
}
