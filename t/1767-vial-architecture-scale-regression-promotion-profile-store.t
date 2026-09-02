#!/usr/bin/env perl

use strict;
use warnings;

use bytes ();
use Digest::SHA qw(sha256_hex);
use Fcntl qw(O_CREAT O_EXCL O_NOFOLLOW O_WRONLY);
use File::Basename qw(dirname);
use File::Copy qw(copy);
use File::Path qw(make_path remove_tree);
use File::Spec;
use FindBin;
use JSON::PP ();
use Test::More;

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::VIAL::ArchitectureScaleMeasurement;
use FSM::VIAL::ArchitectureScaleRegressionPromotionProfileStore;

my $class =
    'FSM::VIAL::ArchitectureScaleRegressionPromotionProfileStore';
my $repo_root = File::Spec->rel2abs(
    File::Spec->catdir($FindBin::Bin, '..'),
);
my $fixture_base = File::Spec->catdir(
    $repo_root, '.artifacts', 'tmp',
    "vial-regression-promotion-profile-store-$$",
);
my $closure_rel = join '/', qw(
    .artifacts qualification vial-scale v1 calibration-closure-v1
    calibration-closure.json
);
my $manifest_rel = join '/', qw(
    .artifacts qualification vial-scale v1 calibration-closure-v1
    closure-manifest.json
);
my $source_closure = File::Spec->catfile(
    $repo_root, split m{/}, $closure_rel,
);
my $source_manifest = File::Spec->catfile(
    $repo_root, split m{/}, $manifest_rel,
);
my $json = JSON::PP->new->canonical(1)->utf8(1);
my $maximum_bytes = 67_108_864;
my $fixture_sequence = 0;
my $plan_stub_active = 0;

die "profile-store fixture root already exists\n"
    if -e $fixture_base || -l $fixture_base;
make_path($fixture_base, {mode => 0700});

local $ENV{FSMGEN_RAM_GUARD_ACTIVE} = 1;
local $ENV{FSMGEN_RAM_GUARD_EFFECTIVE_HOST_MAX_PCT} = 88;
local $ENV{FSMGEN_RAM_GUARD_EFFECTIVE_PROCESS_MAX_RSS_MB} = 4096;

END {
    remove_tree($fixture_base)
        if defined($fixture_base) && -d($fixture_base) && !-l($fixture_base);
}

subtest 'public storage inherits current-plan guard authentication' => sub {
    my $repo = fresh_repository('guard-inheritance');
    local $ENV{FSMGEN_RAM_GUARD_ACTIVE};
    local $ENV{FSMGEN_RAM_GUARD_EFFECTIVE_HOST_MAX_PCT};
    local $ENV{FSMGEN_RAM_GUARD_EFFECTIVE_PROCESS_MAX_RSS_MB};
    like(dies(sub {
        $class->load({repository_root => $repo, ordinal => 1});
    }), qr/requires the active repository RAM guard/,
        'public load reaches the authenticated current-plan authority');
};

my $sealed_test_plan = derive_sealed_test_plan();
{
    no warnings 'redefine';
    *FSM::VIAL::ArchitectureScaleRegressionPromotionCapturePlan::derive =
        sub { return clone($sealed_test_plan) };
}
$plan_stub_active = 1;

subtest 'store exposes closed caller-sealed contracts and conservative ceilings' => sub {
    is_deeply([sort @{$class->publication_keys}], [sort qw(
        schema schema_version publication_identity plan_identity
        policy_identity publication_id publication_schema profile report
    )], 'publication envelope has one closed schema');
    is_deeply([sort @{$class->artifact_keys}], [sort qw(
        schema schema_version status ordinal selection_key
        artifact_relative_path artifact_sha256 artifact_bytes
        same_volume atomic
    )], 'artifact metadata has one closed schema');
    is_deeply([sort @{$class->load_result_keys}], [qw(artifact publication)],
        'load returns only publication bytes plus artifact metadata');
    is_deeply($class->publication_limits, {
        publication_revision => 'regression_promotion_profile_store_v1',
        report_filename => 'measurement-report.json',
        maximum_publication_bytes => $maximum_bytes,
        maximum_ipc_bytes => 65_536,
        maximum_error_bytes => 4_096,
        maximum_same_profile_recovery_entries => 1,
    }, 'storage, future IPC, and error envelopes are explicit');

    like(dies(sub {
        FSM::VIAL::ArchitectureScaleRegressionPromotionProfileStore::publish(
            'borrowed', {},
        );
    }), qr/requires the exact class invocant/,
        'borrowed class invocants fail closed');
    for my $injected (
        '/absolute/report.json', '../escape/report.json',
        '.artifacts/qualification/vial-scale/v1/report.json',
        '.artifacts/qualification/vial-scale/v2/unknown/report.json',
    ) {
        like(dies(sub {
            $class->publish({
                repository_root => fresh_repository('closed-path'),
                ordinal => 1,
                report => synthetic_report('closed-path'),
                publication_relative_path => $injected,
            });
        }), qr/unknown key 'publication_relative_path'/,
            "caller path injection '$injected' is rejected");
    }
    my $repo = fresh_repository('closed-request');
    like(dies(sub {
        $class->publish({repository_root => $repo, ordinal => '1',
            report => synthetic_report('string-ordinal')});
    }), qr/profile ordinal is invalid/,
        'a JSON string cannot masquerade as numeric ordinal one');
    like(dies(sub {
        $class->publish({repository_root => $repo, ordinal => 12,
            report => synthetic_report('unknown-ordinal')});
    }), qr/profile ordinal is unknown/,
        'an unknown dispatch ordinal is rejected');
    like(dies(sub {
        $class->publish({repository_root => $repo, ordinal => 1,
            report => []});
    }), qr/report must be one JSON object/,
        'non-object reports are rejected before storage');
};

subtest 'public publication is canonical, atomic, reloadable, and producer-free' => sub {
    my $repo = fresh_repository('published');
    no warnings 'redefine';
    local *FSM::VIAL::ArchitectureScaleMeasurement::measure =
        sub { die "measurement controller executed\n" };
    local *FSM::VIAL::ArchitectureScaleSemanticBridgeMeasurement::measure_profile =
        sub { die "semantic producer executed\n" };
    local *FSM::VIAL::ArchitectureScaleExecutionCheckingMeasurement::measure_profile =
        sub { die "execution producer executed\n" };
    local *FSM::VIAL::ArchitectureScaleBackendEmissionMeasurement::measure_profile =
        sub { die "backend producer executed\n" };
    local *FSM::VIAL::ArchitectureScalePortableRuntimeMeasurement::measure_profile =
        sub { die "portable runtime producer executed\n" };
    local *FSM::VIAL::ArchitectureScalePortableVHDLRuntimeMeasurement::measure_profile =
        sub { die "portable VHDL producer executed\n" };
    local *FSM::VIAL::ArchitectureScaleOSVVMRuntimeMeasurement::measure_profile =
        sub { die "OSVVM producer executed\n" };
    local *FSM::VIAL::ArchitectureScaleBalancedPortableMeasurement::measure_member =
        sub { die "balanced producer executed\n" };
    my $report = synthetic_report('published');
    my $artifact = $class->publish({
        repository_root => $repo, ordinal => 1, report => $report,
    });
    is($artifact->{status}, 'published',
        'a complete synthetic report publishes once');
    is($artifact->{artifact_relative_path},
        expected_artifact_relative($repo, 1),
        'the plan alone selects the v2 artifact coordinate');
    ok($artifact->{same_volume} && $artifact->{atomic},
        'metadata records the same-volume atomic transaction');

    my $absolute = repo_path($repo, $artifact->{artifact_relative_path});
    my $encoded = read_raw($absolute);
    like($encoded, qr/\n\z/, 'artifact is newline terminated');
    is($json->encode($json->decode($encoded)) . "\n", $encoded,
        'artifact bytes are canonical JSON');
    my @stat = lstat($absolute);
    my @root_stat = stat($repo);
    is($stat[0], $root_stat[0], 'artifact stays on the repository volume');
    is($stat[3], 1, 'artifact has exactly one filesystem link');
    is($artifact->{artifact_sha256}, sha256_hex($encoded),
        'metadata authenticates the exact artifact bytes');

    my $loaded = $class->load({repository_root => $repo, ordinal => 1});
    is_deeply([sort keys %$loaded], [qw(artifact publication)],
        'reload result remains closed');
    is_deeply($loaded->{publication}{report}, $report,
        'reload returns the exact synthetic report');
    is($loaded->{artifact}{status}, 'loaded',
        'reload is distinguished from publication');
    my $unchanged = $class->publish({
        repository_root => $repo, ordinal => 1, report => $report,
    });
    is($unchanged->{status}, 'unchanged',
        'identical bytes are admitted without rewriting');
    ok(!same_profile_staging_paths($repo, 1),
        'successful publication leaves no same-profile staging residue');
};

subtest 'an exact sole interrupted stage recovers by directory rename' => sub {
    my $repo = fresh_repository('recovery');
    my ($plan, $entry, $publication, $encoded, $stage_rel) =
        prepared_publication($repo, 1, synthetic_report('recovery'));
    my $stage = repo_path($repo, $stage_rel);
    make_path($stage, {mode => 0700});
    write_raw(File::Spec->catfile($stage, 'measurement-report.json'), $encoded);
    my $artifact = $class->publish({
        repository_root => $repo,
        ordinal => 1,
        report => synthetic_report('recovery'),
    });
    is($artifact->{status}, 'recovered',
        'the exact sole stage is recovered');
    ok(!-e($stage) && !-l($stage),
        'the staged directory identity moved to its final coordinate');
    is_deeply($class->load({repository_root => $repo, ordinal => 1})
        ->{publication}, $publication,
        'recovered bytes reload through the current plan');
};

subtest 'ambiguous and inexact recovery state fails closed in place' => sub {
    my $repo = fresh_repository('ambiguous');
    my (undef, undef, undef, $encoded, $stage_rel) =
        prepared_publication($repo, 1, synthetic_report('ambiguous'));
    my $stage = repo_path($repo, $stage_rel);
    make_path($stage, {mode => 0700});
    write_raw(File::Spec->catfile($stage, 'measurement-report.json'), $encoded);
    my $other = $stage . '-other';
    make_path($other, {mode => 0700});
    write_raw(File::Spec->catfile($other, 'measurement-report.json'), $encoded);
    like(dies(sub {
        $class->publish({repository_root => $repo, ordinal => 1,
            report => synthetic_report('ambiguous')});
    }), qr/recovery state is ambiguous/,
        'multiple same-profile stages reject before recovery');
    ok(-d($stage) && -d($other),
        'ambiguous state is left intact for diagnosis');

    my $inexact_repo = fresh_repository('inexact');
    my (undef, undef, undef, undef, $inexact_rel) =
        prepared_publication($inexact_repo, 1, synthetic_report('inexact'));
    my $inexact = repo_path($inexact_repo, $inexact_rel);
    make_path($inexact, {mode => 0700});
    write_raw(File::Spec->catfile($inexact, 'measurement-report.json'),
        "{}\n");
    like(dies(sub {
        $class->publish({repository_root => $inexact_repo, ordinal => 1,
            report => synthetic_report('inexact')});
    }), qr/staging is not recoverable/,
        'inexact sole stage rejects without byte substitution');
    ok(-d($inexact), 'inexact recovery state remains available for diagnosis');
};

subtest 'collisions and post-publication staging residue reject' => sub {
    my $repo = fresh_repository('collision');
    $class->publish({repository_root => $repo, ordinal => 1,
        report => synthetic_report('first')});
    like(dies(sub {
        $class->publish({repository_root => $repo, ordinal => 1,
            report => synthetic_report('second')});
    }), qr/publication collision/,
        'different canonical bytes cannot replace a published profile');

    my (undef, undef, undef, $encoded, $stage_rel) =
        prepared_publication($repo, 1, synthetic_report('first'));
    my $stage = repo_path($repo, $stage_rel);
    make_path($stage, {mode => 0700});
    write_raw(File::Spec->catfile($stage, 'measurement-report.json'), $encoded);
    like(dies(sub {
        $class->load({repository_root => $repo, ordinal => 1});
    }), qr/retained staging residue/,
        'published target plus matching stage cannot be loaded as complete');
    like(dies(sub {
        $class->publish({repository_root => $repo, ordinal => 1,
            report => synthetic_report('first')});
    }), qr/retained staging residue/,
        'published target plus matching stage is never treated as unchanged');
};

subtest 'artifact census, symlink, and hard-link mutations reject' => sub {
    my $extra_repo = published_repository('extra-entry');
    my $extra_artifact = expected_artifact_absolute($extra_repo, 1);
    write_raw(File::Spec->catfile(dirname($extra_artifact), 'extra.json'), "{}\n");
    like(dies(sub {
        $class->load({repository_root => $extra_repo, ordinal => 1});
    }), qr/publication census changed/,
        'an extra target entry rejects the complete directory');

    my $symlink_repo = published_repository('symlink');
    my $symlink_artifact = expected_artifact_absolute($symlink_repo, 1);
    my $symlink_target = File::Spec->catfile($symlink_repo, 'target.json');
    write_raw($symlink_target, "{}\n");
    unlink($symlink_artifact) or die "cannot replace symlink fixture: $!\n";
    symlink(File::Spec->abs2rel($symlink_target, dirname($symlink_artifact)),
        $symlink_artifact) or die "cannot create symlink fixture: $!\n";
    like(dies(sub {
        $class->load({repository_root => $symlink_repo, ordinal => 1});
    }), qr/publication artifact is invalid/,
        'a symlink cannot substitute for the publication artifact');

    my $hard_repo = published_repository('hard-link');
    my $hard_artifact = expected_artifact_absolute($hard_repo, 1);
    my $hard_alias = File::Spec->catfile($hard_repo, 'hard-alias.json');
    link($hard_artifact, $hard_alias)
        or die "cannot create publication hard-link fixture: $!\n";
    like(dies(sub {
        $class->load({repository_root => $hard_repo, ordinal => 1});
    }), qr/publication artifact is hard-linked/,
        'a multiply linked publication rejects before content use');

    my $stage_symlink_repo = fresh_repository('stage-symlink');
    my (undef, undef, undef, $stage_symlink_bytes, $stage_symlink_rel) =
        prepared_publication($stage_symlink_repo, 1,
            synthetic_report('stage-symlink'));
    my $stage_symlink = repo_path($stage_symlink_repo, $stage_symlink_rel);
    my $stage_target = File::Spec->catdir($stage_symlink_repo, 'stage-target');
    make_path(dirname($stage_symlink), $stage_target, {mode => 0700});
    write_raw(File::Spec->catfile($stage_target, 'measurement-report.json'),
        $stage_symlink_bytes);
    symlink(File::Spec->abs2rel($stage_target, dirname($stage_symlink)),
        $stage_symlink) or die "cannot create staging symlink fixture: $!\n";
    like(dies(sub {
        $class->publish({repository_root => $stage_symlink_repo, ordinal => 1,
            report => synthetic_report('stage-symlink')});
    }), qr/(?:destination component|publication root) is not a real directory/,
        'a symlink cannot substitute for an interrupted stage');

    my $stage_hard_repo = fresh_repository('stage-hard-link');
    my (undef, undef, undef, $stage_hard_bytes, $stage_hard_rel) =
        prepared_publication($stage_hard_repo, 1,
            synthetic_report('stage-hard-link'));
    my $stage_hard = repo_path($stage_hard_repo, $stage_hard_rel);
    make_path($stage_hard, {mode => 0700});
    my $stage_hard_file = File::Spec->catfile(
        $stage_hard, 'measurement-report.json',
    );
    write_raw($stage_hard_file, $stage_hard_bytes);
    link($stage_hard_file,
        File::Spec->catfile($stage_hard_repo, 'stage-hard-alias.json'))
        or die "cannot create staging hard-link fixture: $!\n";
    like(dies(sub {
        $class->publish({repository_root => $stage_hard_repo, ordinal => 1,
            report => synthetic_report('stage-hard-link')});
    }), qr/publication artifact is hard-linked/,
        'a hard-linked interrupted stage rejects before recovery');

    my $stage_extra_repo = fresh_repository('stage-extra');
    my (undef, undef, undef, $stage_extra_bytes, $stage_extra_rel) =
        prepared_publication($stage_extra_repo, 1,
            synthetic_report('stage-extra'));
    my $stage_extra = repo_path($stage_extra_repo, $stage_extra_rel);
    make_path($stage_extra, {mode => 0700});
    write_raw(File::Spec->catfile($stage_extra, 'measurement-report.json'),
        $stage_extra_bytes);
    write_raw(File::Spec->catfile($stage_extra, 'extra.json'), "{}\n");
    like(dies(sub {
        $class->publish({repository_root => $stage_extra_repo, ordinal => 1,
            report => synthetic_report('stage-extra')});
    }), qr/publication census changed/,
        'an extra staged entry rejects before recovery');
};

subtest 'malformed, noncanonical, and oversized bytes reject before admission' => sub {
    my $malformed_repo = published_repository('malformed');
    replace_artifact($malformed_repo, 1, "{not-json}\n");
    like(dies(sub {
        $class->load({repository_root => $malformed_repo, ordinal => 1});
    }), qr/publication JSON is invalid/,
        'malformed JSON rejects');

    my $noncanonical_repo = published_repository('noncanonical');
    my $loaded = $class->load({repository_root => $noncanonical_repo, ordinal => 1});
    my $noncanonical = JSON::PP->new->utf8(1)->pretty(1)
        ->encode($loaded->{publication});
    replace_artifact($noncanonical_repo, 1, $noncanonical);
    like(dies(sub {
        $class->load({repository_root => $noncanonical_repo, ordinal => 1});
    }), qr/publication JSON is not canonical/,
        'valid but noncanonical JSON rejects');

    my $oversized_repo = published_repository('oversized');
    my $oversized = expected_artifact_absolute($oversized_repo, 1);
    unlink($oversized) or die "cannot replace oversized fixture: $!\n";
    sysopen(my $fh, $oversized,
        O_WRONLY | O_CREAT | O_EXCL | O_NOFOLLOW, 0600)
        or die "cannot create oversized fixture: $!\n";
    truncate($fh, $maximum_bytes + 1)
        or die "cannot size oversized fixture: $!\n";
    close $fh or die "cannot close oversized fixture: $!\n";
    like(dies(sub {
        $class->load({repository_root => $oversized_repo, ordinal => 1});
    }), qr/actual=67108865 bytes, maximum=67108864 bytes/,
        'cap plus one rejects from metadata before an unbounded read');
};

subtest 'dispatch paths and filesystem identity remain independently sealed' => sub {
    my $repo = fresh_repository('path-seal');
    my ($plan, $entry) = current_entry($repo, 1);
    my $target = $class->can('_target_directory');
    my (undef, $device) = repository_identity($repo);
    for my $mutated (
        '/absolute/measurement-report.json',
        '../escape/measurement-report.json',
        '.artifacts/qualification/vial-scale/v1/measurement-report.json',
        '.artifacts/qualification/vial-scale/v2/unknown/measurement-report.json',
    ) {
        my $copy = clone($entry);
        $copy->{publication_relative_path} = $mutated;
        like(dies(sub {
            $target->({repository_root => $repo, root_device => $device,
                plan => $plan, entry => $copy});
        }), qr/report coordinate is invalid/,
            "sealed coordinate rejects '$mutated'");
    }

    my $published = published_repository('foreign-device');
    my $root_helper = $class->can('_repository_root');
    my $foreign_error;
    {
        no warnings 'redefine';
        local *FSM::VIAL::ArchitectureScaleRegressionPromotionProfileStore::_repository_root =
            sub {
                my ($root, $device) = $root_helper->(@_);
                return ($root, $device + 1);
            };
        $foreign_error = dies(sub {
            $class->load({repository_root => $published, ordinal => 1});
        });
    }
    like($foreign_error, qr/crossed repository volume/,
        'repository-device authority rejects foreign filesystem identity');
};

subtest 'repository-local fixture cleanup is exact' => sub {
    remove_tree($fixture_base);
    ok(!-e($fixture_base) && !-l($fixture_base),
        'all synthetic publications and sparse probes leave no residue');
};

done_testing;

sub fresh_repository {
    my ($name) = @_;
    my $repo = File::Spec->catdir(
        $fixture_base, sprintf('%02d-%s', ++$fixture_sequence, $name),
    );
    make_path(File::Spec->catdir($repo, '.git'), {mode => 0700});
    if (!$plan_stub_active) {
        my $closure = repo_path($repo, $closure_rel);
        make_path(dirname($closure), {mode => 0700});
        copy($source_closure, $closure)
            or die "cannot copy calibration closure into fixture: $!\n";
        my $manifest = repo_path($repo, $manifest_rel);
        copy($source_manifest, $manifest)
            or die "cannot copy closure manifest into fixture: $!\n";
        chmod 0600, $closure
            or die "cannot seal fixture calibration closure: $!\n";
        chmod 0600, $manifest
            or die "cannot seal fixture closure manifest: $!\n";
    }
    return $repo;
}

sub derive_sealed_test_plan {
    my $closure = $json->decode(read_raw($source_closure));
    my $policy =
        'FSM::VIAL::ArchitectureScaleRegressionPromotionPolicy'
        ->can('_derive_from_report')->($closure);
    return 'FSM::VIAL::ArchitectureScaleRegressionPromotionCapturePlan'
        ->can('_derive_from_policy')->($policy);
}

sub published_repository {
    my ($name) = @_;
    my $repo = fresh_repository($name);
    $class->publish({repository_root => $repo, ordinal => 1,
        report => synthetic_report($name)});
    return $repo;
}

sub synthetic_report {
    my ($identity) = @_;
    return {
        schema => 'fsmgen.vial_architecture_scale_synthetic_profile.v1',
        schema_version => 1,
        identity => $identity,
        outcome => 'accepted',
        records => [
            {run_class => 'validation', run_ordinal => 0},
            map {
                {run_class => 'gate_measurement', run_ordinal => $_}
            } 1 .. 3
        ],
    };
}

sub prepared_publication {
    my ($repo, $ordinal, $report) = @_;
    my ($plan, $entry) = current_entry($repo, $ordinal);
    my $value = $class->can('_publication_value')->($plan, $entry, $report);
    my $encoded = $json->encode($value) . "\n";
    my ($stage_rel) = $class->can('_staging_directory')->({
        repository_root => $repo,
        root_device => (stat($repo))[0],
        plan => $plan,
        entry => $entry,
    }, sha256_hex($encoded));
    return ($plan, $entry, $value, $encoded, $stage_rel);
}

sub current_entry {
    my ($repo, $ordinal) = @_;
    return $class->can('_current_entry')->($repo, $ordinal);
}

sub expected_artifact_relative {
    my ($repo, $ordinal) = @_;
    my (undef, $entry) = current_entry($repo, $ordinal);
    return $entry->{publication_relative_path};
}

sub expected_artifact_absolute {
    my ($repo, $ordinal) = @_;
    return repo_path($repo, expected_artifact_relative($repo, $ordinal));
}

sub same_profile_staging_paths {
    my ($repo, $ordinal) = @_;
    my (undef, $entry) = current_entry($repo, $ordinal);
    my $token = sprintf('%02d-%s', $ordinal,
        sha256_hex($entry->{selection_key}));
    my $base = repo_path($repo,
        '.artifacts/tmp/vial-scale/regression-promotion-profile-publication/v1');
    return () unless -d $base;
    opendir my $dh, $base or die "cannot inspect test staging base: $!\n";
    my @paths = grep { /^\Q$token\E-/ } readdir $dh;
    closedir $dh or die "cannot close test staging base: $!\n";
    return @paths;
}

sub replace_artifact {
    my ($repo, $ordinal, $content) = @_;
    my $path = expected_artifact_absolute($repo, $ordinal);
    unlink($path) or die "cannot replace publication fixture: $!\n";
    write_raw($path, $content);
}

sub repository_identity {
    my ($repo) = @_;
    my @stat = stat($repo);
    return ($repo, $stat[0]);
}

sub repo_path {
    my ($root, $relative) = @_;
    return File::Spec->catfile($root, split m{/}, $relative);
}

sub write_raw {
    my ($path, $content) = @_;
    sysopen(my $fh, $path,
        O_WRONLY | O_CREAT | O_EXCL | O_NOFOLLOW, 0600)
        or die "cannot create fixture '$path': $!\n";
    binmode($fh, ':raw') or die "cannot set fixture byte mode: $!\n";
    print {$fh} $content or die "cannot write fixture '$path': $!\n";
    close $fh or die "cannot close fixture '$path': $!\n";
}

sub read_raw {
    my ($path) = @_;
    open my $fh, '<:raw', $path or die "cannot read fixture '$path': $!\n";
    local $/;
    my $content = <$fh>;
    close $fh or die "cannot close fixture '$path': $!\n";
    return $content;
}

sub clone {
    my ($value) = @_;
    return $json->decode($json->encode($value));
}

sub dies {
    my ($code) = @_;
    my $error;
    eval { $code->(); 1 } or $error = $@;
    return defined($error) ? $error : '';
}
