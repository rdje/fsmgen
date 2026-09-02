#!/usr/bin/env perl

use strict;
use warnings;

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

use FSM::VIAL::ArchitectureScaleRegressionPromotionCapturePlan;
use FSM::VIAL::ArchitectureScaleRegressionPromotionCorpusStore;
use FSM::VIAL::ArchitectureScaleRegressionPromotionProfileStore;

my $class = 'FSM::VIAL::ArchitectureScaleRegressionPromotionCorpusStore';
my $profile_store =
    'FSM::VIAL::ArchitectureScaleRegressionPromotionProfileStore';
my $repo_root = File::Spec->rel2abs(
    File::Spec->catdir($FindBin::Bin, '..'),
);
my $fixture_base = File::Spec->catdir(
    $repo_root, '.artifacts', 'tmp',
    "vial-regression-promotion-corpus-store-$$",
);
my $closure_path = repo_path($repo_root, join '/', qw(
    .artifacts qualification vial-scale v1 calibration-closure-v1
    calibration-closure.json
));
my $json = JSON::PP->new->canonical(1)->utf8(1);
my $fixture_sequence = 0;
my $revision = '1' x 40;
my $maximum_report_bytes = 1_048_576;
my $maximum_manifest_bytes = 65_536;

die "corpus-store fixture root already exists\n"
    if -e $fixture_base || -l $fixture_base;
make_path($fixture_base, {mode => 0700});

local $ENV{FSMGEN_RAM_GUARD_ACTIVE} = 1;
local $ENV{FSMGEN_RAM_GUARD_EFFECTIVE_HOST_MAX_PCT} = 88;
local $ENV{FSMGEN_RAM_GUARD_EFFECTIVE_PROCESS_MAX_RSS_MB} = 4096;

END {
    remove_tree($fixture_base)
        if defined($fixture_base) && -d($fixture_base) && !-l($fixture_base);
}

my $sealed_plan = derive_sealed_test_plan();
{
    no warnings 'redefine';
    *FSM::VIAL::ArchitectureScaleRegressionPromotionCapturePlan::derive =
        sub { return clone($sealed_plan) };
}

subtest 'public store is caller-sealed and explicitly bounded' => sub {
    is_deeply([sort @{$class->report_keys}], [sort qw(
        schema schema_version corpus_identity plan_identity policy_identity
        publication_id publication_schema common_identity summary profiles
        explicit_nonclaims
    )], 'complete report has one closed schema');
    is_deeply([sort @{$class->manifest_keys}], [sort qw(
        schema schema_version publication_identity corpus_identity
        plan_identity policy_identity publication_id report_artifact summary
        outcome explicit_nonclaims
    )], 'compact manifest has one closed schema');
    is_deeply([sort @{$class->artifact_keys}], [sort qw(
        schema schema_version status publication_relative_path
        report_artifact manifest_artifact file_set_sha256 same_volume atomic
    )], 'publication metadata has one closed schema');
    is_deeply([sort @{$class->load_result_keys}],
        [qw(artifact manifest report)],
        'reload returns only the two publications and metadata');
    is_deeply($class->publication_limits, {
        publication_revision => 'regression_promotion_corpus_store_v1',
        report_filename => 'regression-promotion-corpus.json',
        manifest_filename => 'corpus-manifest.json',
        maximum_report_bytes => $maximum_report_bytes,
        maximum_manifest_bytes => $maximum_manifest_bytes,
        maximum_recovery_entries => 1,
        profile_count => 11,
        validation_records => 11,
        raw_measurement_records => 33,
        controller_invocations => 44,
    }, 'storage and complete-corpus envelopes are explicit');

    like(dies(sub {
        FSM::VIAL::ArchitectureScaleRegressionPromotionCorpusStore::load(
            'borrowed', {},
        );
    }), qr/requires the exact class invocant/,
        'borrowed invocants reject');
    my $repo = fresh_repository('closed-request');
    like(dies(sub {
        $class->load({repository_root => $repo, ordinal => 1});
    }), qr/unknown key 'ordinal'/,
        'caller coordinates cannot replace the sealed complete path');
    like(dies(sub {
        $class->publish({repository_root => $repo, profiles => [],
            publication_relative_path => '/foreign'});
    }), qr/unknown key 'publication_relative_path'/,
        'caller publication paths reject');
    like(dies(sub {
        $class->publish({repository_root => $repo, profiles => {}});
    }), qr/profiles must be one array/,
        'profile input must be an ordered array');
};

subtest 'complete synthetic metadata publishes atomically without execution' => sub {
    my ($repo, $profiles) = prepared_repository('published');
    no warnings 'redefine';
    local *FSM::VIAL::ArchitectureScaleMeasurement::measure =
        sub { die "measurement controller executed\n" };
    local *FSM::VIAL::ArchitectureScaleRegressionPromotionProfileCapture::capture =
        sub { die "profile capture executed\n" };
    local *FSM::VIAL::ArchitectureScaleRegressionPromotionProfileCapture::resume =
        sub { die "profile resume executed\n" };

    my $artifact = $class->publish({
        repository_root => $repo, profiles => $profiles,
    });
    is($artifact->{status}, 'published',
        'the complete synthetic set publishes once');
    is($artifact->{publication_relative_path}, complete_relative(),
        'the plan alone selects the complete v2 coordinate');
    ok($artifact->{same_volume} && $artifact->{atomic},
        'metadata records same-volume atomic publication');

    my $directory = repo_path($repo, complete_relative());
    is_deeply([directory_entries($directory)],
        [qw(corpus-manifest.json regression-promotion-corpus.json)],
        'the complete publication has exactly two files');
    for my $filename (qw(
        regression-promotion-corpus.json corpus-manifest.json
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
    is($loaded->{report}{summary}{profile_count}, 11,
        'reload admits all eleven profiles');
    is($loaded->{report}{summary}{validation_records}, 11,
        'reload admits eleven validations');
    is($loaded->{report}{summary}{raw_measurement_records}, 33,
        'reload admits 33 raw measurements');
    is($loaded->{report}{summary}{sample_exclusions}, 0,
        'reload admits zero exclusions');
    is($loaded->{manifest}{corpus_identity},
        $loaded->{report}{corpus_identity},
        'manifest binds the exact report identity');
    is($loaded->{artifact}{status}, 'loaded',
        'reload is distinguished from publication');
    my $resumed = clone($profiles);
    $_->{artifact}{status} = 'loaded' for @$resumed;
    my $unchanged = $class->publish({
        repository_root => $repo, profiles => $resumed,
    });
    is($unchanged->{status}, 'unchanged',
        'transient profile status cannot change complete bytes');
    ok(!corpus_staging_paths($repo),
        'success leaves no complete-publication staging residue');
};

subtest 'an exact sole interrupted stage recovers and ambiguity rejects' => sub {
    my ($repo, $profiles) = prepared_repository('recovery');
    my ($report, $manifest, $report_bytes, $manifest_bytes) =
        prepared_publication($repo, $profiles);
    my $digest = file_set_digest($report_bytes, $manifest_bytes);
    my ($stage_rel) = $class->can('_staging_directory')->({
        repository_root => $repo,
        root_device => (stat($repo))[0],
    }, $digest);
    my $stage = repo_path($repo, $stage_rel);
    make_path($stage, {mode => 0700});
    write_raw(File::Spec->catfile(
        $stage, 'regression-promotion-corpus.json'), $report_bytes);
    write_raw(File::Spec->catfile(
        $stage, 'corpus-manifest.json'), $manifest_bytes);
    my $artifact = $class->publish({
        repository_root => $repo, profiles => $profiles,
    });
    is($artifact->{status}, 'recovered',
        'the exact sole staged file set recovers by directory rename');
    ok(!-e($stage) && !-l($stage),
        'recovery moves the exact staged directory identity');
    is_deeply($class->load({repository_root => $repo})->{report}, $report,
        'recovered report reloads exactly');
    is_deeply($class->load({repository_root => $repo})->{manifest}, $manifest,
        'recovered manifest reloads exactly');

    my ($ambiguous_repo, $ambiguous_profiles) =
        prepared_repository('ambiguous');
    my (undef, undef, $amb_report_bytes, $amb_manifest_bytes) =
        prepared_publication($ambiguous_repo, $ambiguous_profiles);
    my $base = repo_path($ambiguous_repo, staging_base());
    for my $suffix (qw(first second)) {
        my $path = File::Spec->catdir($base, "corpus-$suffix");
        make_path($path, {mode => 0700});
        write_raw(File::Spec->catfile(
            $path, 'regression-promotion-corpus.json'), $amb_report_bytes);
        write_raw(File::Spec->catfile(
            $path, 'corpus-manifest.json'), $amb_manifest_bytes);
    }
    like(dies(sub {
        $class->publish({repository_root => $ambiguous_repo,
            profiles => $ambiguous_profiles});
    }), qr/recovery state is ambiguous/,
        'multiple complete stages reject before publication');
};

subtest 'profile order, counts, identities, and references fail closed' => sub {
    my ($repo, $profiles) = prepared_repository('admission');
    my @controls = (
        ['missing', sub { pop @{$_[0]} }, qr/requires exactly 11 profiles/],
        ['reordered', sub { @{$_[0]}[0, 1] = @{$_[0]}[1, 0] },
            qr/profile order changed/],
        ['duplicate', sub { $_[0][1] = clone($_[0][0]) },
            qr/profile order changed/],
        ['string ordinal', sub { $_[0][0]{ordinal} = '1' },
            qr/profile order changed/],
        ['foreign plan', sub { $_[0][0]{plan_identity} = 'foreign' },
            qr/profile plan binding changed/],
        ['mixed revision', sub {
            $_[0][1]{common_identity}{git_revision} = '2' x 40
        }, qr/profile common identity changed/],
        ['mixed host', sub {
            $_[0][1]{common_identity}{host_profile}{system} = 'foreign'
        }, qr/profile common identity changed/],
        ['mixed guard', sub {
            $_[0][1]{common_identity}{resource_guard}{active} = JSON::PP::false
        }, qr/(?:profile common identity changed|resource guard is inactive)/],
        ['provider', sub {
            $_[0][0]{provider_status}{kind} = 'foreign'
        }, qr/profile provider status changed/],
        ['validation count', sub {
            $_[0][0]{applicability_status}{validation_records} = 2
        }, qr/profile applicability changed/],
        ['string raw count', sub {
            $_[0][0]{applicability_status}{raw_measurement_records} = '3'
        }, qr/profile applicability changed/],
        ['exclusion', sub {
            $_[0][0]{applicability_status}{sample_exclusions} = 1
        }, qr/profile applicability changed/],
        ['artifact digest', sub {
            $_[0][0]{artifact}{artifact_sha256} = '0' x 64
        }, qr/profile artifact metadata changed/],
        ['historical path', sub {
            $_[0][0]{artifact}{artifact_relative_path} =~ s{/v2/}{/v1/}
        }, qr/profile artifact coordinate changed/],
    );
    for my $control (@controls) {
        my ($name, $mutate, $expected) = @$control;
        my $copy = clone($profiles);
        $mutate->($copy);
        like(dies(sub {
            $class->publish({repository_root => $repo, profiles => $copy});
        }), $expected, "$name input rejects");
    }

    my $mutated = clone($profiles);
    my $profile_path = repo_path(
        $repo, $mutated->[0]{artifact}{artifact_relative_path},
    );
    replace_file($profile_path, "{}\n");
    like(dies(sub {
        $class->publish({repository_root => $repo, profiles => $mutated});
    }), qr/profile publication (?:JSON|schema|plan|dispatch|is missing)/,
        'profile bytes mutated after admission cannot feed the complete seal');
};

subtest 'published file-set mutations and unsafe aliases reject' => sub {
    my ($malformed_repo, $malformed_profiles) =
        published_repository('malformed');
    replace_complete_file($malformed_repo,
        'regression-promotion-corpus.json', "{\n");
    like(dies(sub { $class->load({repository_root => $malformed_repo}) }),
        qr/report JSON is invalid/,
        'malformed report bytes reject');

    my ($newline_repo) = published_repository('newline');
    my $newline_path = complete_file(
        $newline_repo, 'regression-promotion-corpus.json');
    my $without_newline = read_raw($newline_path);
    $without_newline =~ s/\n\z//;
    replace_file($newline_path, $without_newline);
    like(dies(sub { $class->load({repository_root => $newline_repo}) }),
        qr/report is not newline-terminated/,
        'missing report newline rejects');

    my ($noncanonical_repo) = published_repository('noncanonical');
    my $noncanonical_path = complete_file(
        $noncanonical_repo, 'corpus-manifest.json');
    my $decoded = $json->decode(read_raw($noncanonical_path));
    replace_file($noncanonical_path,
        JSON::PP->new->utf8(1)->pretty(1)->encode($decoded));
    like(dies(sub { $class->load({repository_root => $noncanonical_repo}) }),
        qr/manifest JSON is not canonical/,
        'noncanonical manifest rejects');

    my ($oversized_repo) = published_repository('oversized');
    replace_complete_file($oversized_repo,
        'regression-promotion-corpus.json',
        'x' x ($maximum_report_bytes + 1));
    like(dies(sub { $class->load({repository_root => $oversized_repo}) }),
        qr/report exceeds its bounded ceiling/,
        'cap-plus-one existing report bytes reject');

    my ($manifest_oversized_repo) =
        published_repository('manifest-oversized');
    replace_complete_file($manifest_oversized_repo,
        'corpus-manifest.json', 'x' x ($maximum_manifest_bytes + 1));
    like(dies(sub {
        $class->load({repository_root => $manifest_oversized_repo})
    }), qr/manifest exceeds its bounded ceiling/,
        'cap-plus-one existing manifest bytes reject');

    my ($extra_repo) = published_repository('extra');
    write_raw(complete_file($extra_repo, 'extra.json'), "{}\n");
    like(dies(sub { $class->load({repository_root => $extra_repo}) }),
        qr/publication census changed/,
        'an extra complete-publication entry rejects');

    my ($symlink_repo) = published_repository('symlink');
    my $symlink_path = complete_file(
        $symlink_repo, 'regression-promotion-corpus.json');
    my $symlink_bytes = read_raw($symlink_path);
    my $symlink_target = repo_path(
        $symlink_repo, '.artifacts/tmp/corpus-symlink-target.json');
    write_raw($symlink_target, $symlink_bytes);
    unlink($symlink_path) or die "cannot replace report with symlink: $!\n";
    symlink($symlink_target, $symlink_path)
        or die "cannot create report symlink: $!\n";
    like(dies(sub { $class->load({repository_root => $symlink_repo}) }),
        qr/report artifact is invalid/,
        'a symlink cannot substitute for the report');

    my ($hard_repo) = published_repository('hard-link');
    my $hard_path = complete_file(
        $hard_repo, 'regression-promotion-corpus.json');
    my $hard_alias = repo_path(
        $hard_repo, '.artifacts/tmp/corpus-hard-link-alias.json');
    make_path(dirname($hard_alias), {mode => 0700});
    link($hard_path, $hard_alias)
        or die "cannot create report hard link: $!\n";
    like(dies(sub { $class->load({repository_root => $hard_repo}) }),
        qr/report artifact is hard-linked/,
        'a multiply linked report rejects');

    my ($reordered_repo) = published_repository('rehashed-reorder');
    rewrite_complete_publication($reordered_repo, sub {
        @{$_[0]{profiles}}[0, 1] = @{$_[0]{profiles}}[1, 0];
    });
    like(dies(sub { $class->load({repository_root => $reordered_repo}) }),
        qr/profile order changed/,
        'a rehashed reordered complete report rejects semantically');

    my ($typed_repo) = published_repository('rehashed-type');
    rewrite_complete_publication($typed_repo, sub {
        $_[0]{schema_version} = '1';
    });
    like(dies(sub { $class->load({repository_root => $typed_repo}) }),
        qr/report schema is invalid/,
        'a rehashed JSON string cannot masquerade as schema version one');
};

subtest 'partial internal failure cleans and late directory mutation rejects' => sub {
    my ($cleanup_repo, $cleanup_profiles) =
        prepared_repository('partial-cleanup');
    my $write = $class->can('_write_synced_file');
    {
        no warnings 'redefine';
        my $calls = 0;
        local *FSM::VIAL::ArchitectureScaleRegressionPromotionCorpusStore::_write_synced_file =
            sub {
                die "injected second-file failure\n" if ++$calls == 2;
                return $write->(@_);
            };
        like(dies(sub {
            $class->publish({repository_root => $cleanup_repo,
                profiles => $cleanup_profiles});
        }), qr/injected second-file failure/,
            'a failure after the first staged file propagates');
    }
    ok(!-e(repo_path($cleanup_repo, complete_relative()))
            && !corpus_staging_paths($cleanup_repo),
        'partial internal failure removes the exact owned stage and target');

    my ($late_repo) = published_repository('late-entry');
    my $read = $class->can('_read_exact_file');
    {
        no warnings 'redefine';
        my $calls = 0;
        local *FSM::VIAL::ArchitectureScaleRegressionPromotionCorpusStore::_read_exact_file =
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

subtest 'collisions and retained staging residue reject' => sub {
    my ($repo, $profiles) = published_repository('collision');
    my $first_path = repo_path(
        $repo, $profiles->[0]{artifact}{artifact_relative_path},
    );
    my $profile_publication = $json->decode(read_raw($first_path));
    $profile_publication->{report}{report_identity} =
        'synthetic-report/' . ('f' x 64);
    $profile_publication->{publication_identity} = undef;
    $profile_publication->{publication_identity} =
        'regression-promotion-profile-publication/'
        . sha256_hex(canonical($profile_publication));
    replace_file($first_path, canonical($profile_publication) . "\n");
    my $changed = clone($profiles);
    $changed->[0]{report_identity} =
        $profile_publication->{report}{report_identity};
    $changed->[0]{artifact}{artifact_sha256} =
        sha256_hex(read_raw($first_path));
    $changed->[0]{artifact}{artifact_bytes} = -s $first_path;
    like(dies(sub { $class->load({repository_root => $repo}) }),
        qr/profile artifact metadata changed/,
        'a profile mutated after sealing invalidates complete reload');
    like(dies(sub {
        $class->publish({repository_root => $repo, profiles => $changed});
    }), qr/publication collision/,
        'different complete bytes cannot overwrite an existing seal');

    my ($residue_repo, $residue_profiles) =
        published_repository('residue');
    my $residue = File::Spec->catdir(
        repo_path($residue_repo, staging_base()), 'corpus-residue',
    );
    make_path($residue, {mode => 0700});
    like(dies(sub {
        $class->load({repository_root => $residue_repo});
    }), qr/retained staging residue/,
        'complete reload rejects staging residue');
    like(dies(sub {
        $class->publish({repository_root => $residue_repo,
            profiles => $residue_profiles});
    }), qr/(?:retained staging residue|recovery state is ambiguous)/,
        'complete republish rejects unrelated staging residue');
};

remove_tree($fixture_base);
ok(!grep { -e $_ || -l $_ } corpus_fixture_paths(),
    'all complete-publication fixtures are removed at process exit');

done_testing;

sub derive_sealed_test_plan {
    my $closure = $json->decode(read_raw($closure_path));
    my $policy =
        'FSM::VIAL::ArchitectureScaleRegressionPromotionPolicy'
        ->can('_derive_from_report')->($closure);
    return 'FSM::VIAL::ArchitectureScaleRegressionPromotionCapturePlan'
        ->can('_derive_from_policy')->($policy);
}

sub prepared_repository {
    my ($name) = @_;
    my $repo = fresh_repository($name);
    my $profiles = [map { profile_result($repo, $_) } 1 .. 11];
    return ($repo, $profiles);
}

sub published_repository {
    my ($name) = @_;
    my ($repo, $profiles) = prepared_repository($name);
    $class->publish({repository_root => $repo, profiles => $profiles});
    return ($repo, $profiles);
}

sub profile_result {
    my ($repo, $ordinal) = @_;
    my $entry = plan_entry($ordinal);
    my $report_identity = 'synthetic-report/' . sha256_hex(
        join('/', $ordinal, $revision),
    );
    my $artifact = $profile_store->publish({
        repository_root => $repo,
        ordinal => $ordinal,
        report => {
            schema => 'fsmgen.vial_architecture_scale_synthetic_profile.v1',
            schema_version => 1,
            report_identity => $report_identity,
            outcome => 'accepted',
        },
    });
    my $tool = $entry->{provider_requirement}{kind} eq 'exact_tool_profile'
        ? {
            logical_name => $entry->{provider_requirement}{logical_name},
            provider_identity =>
                $entry->{provider_requirement}{provider_identity},
            external_verification_tool => JSON::PP::true,
        }
        : {
            logical_name => 'fsmgen',
            provider_identity => 'repository_owned',
            external_verification_tool => JSON::PP::false,
        };
    return {
        schema =>
            'fsmgen.vial_architecture_scale_regression_promotion_profile_capture.v1',
        schema_version => 1,
        plan_identity => $sealed_plan->{plan_identity},
        policy_identity => $sealed_plan->{policy_identity},
        ordinal => $ordinal,
        selection_key => $entry->{selection_key},
        report_identity => $report_identity,
        common_identity => {
            git_revision => $revision,
            dirty_state => JSON::PP::false,
            host_profile => {
                system => 'fixture', architecture => 'synthetic',
            },
            tool_profile => $tool,
            resource_guard => {
                active => JSON::PP::true,
                host_max_percent => 88,
                single_descendant_max_mib => 4096,
            },
        },
        provider_status => clone($entry->{provider_requirement}),
        applicability_status => {
            required => JSON::PP::true,
            predicate => $entry->{applicability_requirement}{predicate},
            controller_applicable => JSON::PP::true,
            measurement_applicable => JSON::PP::true,
            validation_records => 1,
            raw_measurement_records => 3,
            sample_exclusions => 0,
            outcome => 'accepted',
        },
        artifact => $artifact,
    };
}

sub prepared_publication {
    my ($repo, $profiles) = @_;
    return $class->can('_publication_value')->({
        repository_root => $repo,
        root_device => (stat($repo))[0],
        plan => clone($sealed_plan),
        profiles => clone($profiles),
    });
}

sub fresh_repository {
    my ($name) = @_;
    my $repo = File::Spec->catdir(
        $fixture_base, sprintf('%02d-%s', ++$fixture_sequence, $name),
    );
    make_path(File::Spec->catdir($repo, '.git'), {mode => 0700});
    return $repo;
}

sub plan_entry {
    my ($ordinal) = @_;
    return clone($sealed_plan->{entries}[$ordinal - 1]);
}

sub complete_relative {
    return join '/', qw(
        .artifacts qualification vial-scale v2
        regression-promotion-corpus-v1 complete
    );
}

sub staging_base {
    return join '/', qw(
        .artifacts tmp vial-scale
        regression-promotion-corpus-publication v1
    );
}

sub complete_file {
    my ($repo, $filename) = @_;
    return File::Spec->catfile(
        repo_path($repo, complete_relative()), $filename,
    );
}

sub replace_complete_file {
    my ($repo, $filename, $bytes) = @_;
    replace_file(complete_file($repo, $filename), $bytes);
}

sub rewrite_complete_publication {
    my ($repo, $mutate) = @_;
    my $report_path = complete_file(
        $repo, 'regression-promotion-corpus.json');
    my $manifest_path = complete_file($repo, 'corpus-manifest.json');
    my $report = $json->decode(read_raw($report_path));
    $mutate->($report);
    $report->{corpus_identity} = undef;
    $report->{corpus_identity} = 'regression-promotion-corpus/'
        . sha256_hex(canonical($report));
    my $report_bytes = canonical($report) . "\n";
    my $manifest = $json->decode(read_raw($manifest_path));
    $manifest->{corpus_identity} = $report->{corpus_identity};
    $manifest->{report_artifact}{sha256} = sha256_hex($report_bytes);
    $manifest->{report_artifact}{bytes} = bytes::length($report_bytes);
    $manifest->{publication_identity} = undef;
    $manifest->{publication_identity} =
        'regression-promotion-corpus-publication/'
        . sha256_hex(canonical($manifest));
    replace_file($report_path, $report_bytes);
    replace_file($manifest_path, canonical($manifest) . "\n");
}

sub corpus_staging_paths {
    my ($repo) = @_;
    my $base = repo_path($repo, staging_base());
    return () unless -d $base;
    opendir my $dh, $base or die "cannot inspect corpus staging: $!\n";
    my @paths = grep { /^corpus-/ } readdir $dh;
    closedir $dh or die "cannot close corpus staging: $!\n";
    return @paths;
}

sub directory_entries {
    my ($path) = @_;
    opendir my $dh, $path or die "cannot inspect '$path': $!\n";
    my @entries = sort grep { $_ ne '.' && $_ ne '..' } readdir $dh;
    closedir $dh or die "cannot close '$path': $!\n";
    return @entries;
}

sub file_set_digest {
    my ($report, $manifest) = @_;
    return sha256_hex(join "\0",
        bytes::length($report), $report,
        bytes::length($manifest), $manifest,
    );
}

sub replace_file {
    my ($path, $bytes) = @_;
    unlink($path) or die "cannot replace '$path': $!\n";
    write_raw($path, $bytes);
}

sub write_raw {
    my ($path, $bytes) = @_;
    make_path(dirname($path), {mode => 0700}) unless -d dirname($path);
    sysopen(my $fh, $path,
        O_WRONLY | O_CREAT | O_EXCL | O_NOFOLLOW, 0600)
        or die "cannot create '$path': $!\n";
    binmode($fh, ':raw') or die "cannot set '$path' byte mode: $!\n";
    print {$fh} $bytes or die "cannot write '$path': $!\n";
    close $fh or die "cannot close '$path': $!\n";
}

sub read_raw {
    my ($path) = @_;
    open my $fh, '<:raw', $path or die "cannot read '$path': $!\n";
    local $/;
    my $bytes = <$fh>;
    close $fh or die "cannot close '$path': $!\n";
    return $bytes;
}

sub repo_path {
    my ($root, $relative) = @_;
    return File::Spec->catfile($root, split m{/}, $relative);
}

sub canonical {
    my ($value) = @_;
    return $json->encode($value);
}

sub clone {
    my ($value) = @_;
    return $json->decode($json->encode($value));
}

sub dies {
    my ($code) = @_;
    my $ok = eval { $code->(); 1 };
    return '' if $ok;
    return $@;
}

sub corpus_fixture_paths {
    return ($fixture_base);
}
