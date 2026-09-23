#!/usr/bin/env perl

use strict;
use warnings;

use Cwd qw(realpath);
use Digest::SHA qw(sha256_hex);
use File::Basename qw(dirname);
use File::Copy qw(copy);
use File::Find qw(find);
use File::Path qw(make_path remove_tree);
use File::Spec;
use FindBin;
use IPC::Open3 qw(open3);
use JSON::PP ();
use POSIX ();
use Symbol qw(gensym);
use Test::More;

my $root = realpath(File::Spec->catdir($FindBin::Bin, '..'))
    // die "cannot resolve repository root\n";
my $fixture = File::Spec->catdir(
    $root, '.artifacts', 'tmp',
    "vial-regression-promotion-current-corpus-mutations-$$",
);
my $active_relative = join '/', qw(
    .artifacts qualification vial-scale v2 regression-promotion-corpus-v1
);
my $script_relative =
    'scripts/verify_vial_regression_promotion_current_corpus.pl';
my $historical_relative = join '/', qw(
    .artifacts qualification vial-scale history
    610ed7869642ee57f9df608204cfbad3a0b187e4
    regression-promotion-report-coordinate-failure-ordinal-5-v1
    profiles
    01-cba98f10c2a7bf1d5f35f2aa79daf240c642fffb2bc5fa15a96a7a4273fbf300
    measurement-report.json
);
my @staging_relatives = (
    join('/', qw(
        .artifacts tmp vial-scale
        regression-promotion-profile-publication v1
    )),
    join('/', qw(
        .artifacts tmp vial-scale
        regression-promotion-corpus-publication v1
    )),
);
my $json = JSON::PP->new->canonical(1)->utf8(1);

my $real_active = repo_path($root, $active_relative);
my $ignored_corpus_present = -d $real_active && !-l $real_active;
my $real_before = $ignored_corpus_present
    ? corpus_census($real_active, 1) : undef;
my $real_content = $ignored_corpus_present
    ? corpus_census($real_active, 0) : undef;

if ($ignored_corpus_present) {
    die "current-corpus mutation fixture root already exists\n"
        if -e $fixture || -l $fixture;
    make_path($fixture, {mode => 0700});
}

END {
    remove_tree($fixture)
        if $ignored_corpus_present
            && defined($fixture) && -d($fixture) && !-l($fixture);
}

if ($ignored_corpus_present) {
    copy_file(
        repo_path($root, $script_relative),
        repo_path($fixture, $script_relative),
    );
    copy_tree($real_active, repo_path($fixture, $active_relative));
}

my $script = repo_path($fixture, $script_relative);
my $active = repo_path($fixture, $active_relative);
my $report = repo_path(
    $active, 'complete/regression-promotion-corpus.json',
);
my $manifest = repo_path($active, 'complete/corpus-manifest.json');
my $profile = $ignored_corpus_present ? first_matching_file(
    $active, qr{/profiles/01-[^/]+/measurement-report[.]json\z},
) : undef;
my $profile_mode = $ignored_corpus_present
    ? ((lstat($profile))[2] & 07777) : undef;
my $historical = repo_path($root, $historical_relative);
my $fixture_baseline = $ignored_corpus_present
    ? corpus_census($active, 0) : undef;

subtest 'copied exact publication is same-volume and authentic' => sub {
    plan skip_all => 'ignored current corpus is absent on a fresh checkout'
        unless $ignored_corpus_present;
    my @root_stat = lstat($root);
    my @fixture_stat = lstat($fixture);
    my @active_stat = lstat($active);
    is($fixture_stat[0], $root_stat[0],
        'fixture resides on the repository device');
    is($active_stat[0], $root_stat[0],
        'copied publication resides on the repository device');
    is($fixture_stat[4], $root_stat[4],
        'fixture retains the repository owner');
    is($active_stat[4], $root_stat[4],
        'copied publication retains the repository owner');
    is_deeply(
        $fixture_baseline, $real_content,
        'initial copy matches every real path/mode/link/owner/device/byte/hash',
    );
    assert_accepts('copied exact publication baseline');
};

subtest 'content and semantic-coordinate mutations fail closed' => sub {
    plan skip_all => 'ignored current corpus is absent on a fresh checkout'
        unless $ignored_corpus_present;
    exercise_json_mutation('complete report content', $report, sub {
        $_[0]{common_identity}{git_revision} = '0' x 40;
    });
    exercise_json_mutation('complete manifest content', $manifest, sub {
        $_[0]{outcome} = 'rejected';
    });
    exercise_json_mutation('profile report record', $profile, sub {
        $_[0]{report}{outcome} = 'rejected';
    });
    exercise_json_mutation('profile ordering', $report, sub {
        @{$_[0]{profiles}}[0, 1] = @{$_[0]{profiles}}[1, 0];
    });
    exercise_json_mutation('corpus identity', $report, sub {
        $_[0]{corpus_identity} = 'regression-promotion-corpus/' . ('0' x 64);
    });
    exercise_json_mutation('provider identity', $report, sub {
        my $provider = $_[0]{profiles}[8]{provider_status}{provider_identity};
        die "provider mutation target is not a nonempty scalar\n"
            if !defined($provider) || ref($provider) || !length($provider);
        $_[0]{profiles}[8]{provider_status}{provider_identity} =
            'x' x length($provider);
    });
    exercise_json_mutation('aggregate count', $report, sub {
        $_[0]{summary}{profile_count} = 10;
    });
    exercise_json_mutation('manifest digest', $manifest, sub {
        $_[0]{report_artifact}{sha256} = '0' x 64;
    });
};

subtest 'canonicality, link, and file-shape mutations fail closed' => sub {
    plan skip_all => 'ignored current corpus is absent on a fresh checkout'
        unless $ignored_corpus_present;
    my $manifest_bytes = read_raw($manifest);
    exercise_mutation(
        'noncanonical manifest bytes',
        sub { write_raw($manifest, $manifest_bytes . ' ') },
        sub { write_raw($manifest, $manifest_bytes) },
    );

    my $profile_bytes = read_raw($profile);
    exercise_mutation(
        'profile symlink',
        sub {
            unlink($profile) or die "cannot remove copied profile for symlink\n";
            symlink($manifest, $profile)
                or die "cannot create copied-profile symlink control: $!\n";
        },
        sub {
            unlink($profile) or die "cannot remove copied-profile symlink\n";
            restore_raw($profile, $profile_bytes, $profile_mode);
        },
    );
    exercise_mutation(
        'profile hard link',
        sub {
            unlink($profile) or die "cannot remove copied profile for hard link\n";
            link($manifest, $profile)
                or die "cannot create copied-profile hard-link control: $!\n";
        },
        sub {
            unlink($profile) or die "cannot remove copied-profile hard link\n";
            restore_raw($profile, $profile_bytes, $profile_mode);
        },
    );
    exercise_mutation(
        'profile special-file node',
        sub {
            unlink($profile) or die "cannot remove copied profile for FIFO\n";
            POSIX::mkfifo($profile, 0600)
                or die "cannot create copied-profile FIFO control: $!\n";
        },
        sub {
            unlink($profile) or die "cannot remove copied-profile FIFO\n";
            restore_raw($profile, $profile_bytes, $profile_mode);
        },
    );
};

subtest 'namespace, staging, and historical mutations fail closed' => sub {
    plan skip_all => 'ignored current corpus is absent on a fresh checkout'
        unless $ignored_corpus_present;
    my $extra = File::Spec->catfile($active, 'foreign.json');
    exercise_mutation(
        'extra namespace path',
        sub { write_raw($extra, "{}\n") },
        sub { unlink($extra) or die "cannot remove extra-path control\n" },
    );

    my $profile_bytes = read_raw($profile);
    exercise_mutation(
        'missing namespace path',
        sub { unlink($profile) or die "cannot remove copied profile\n" },
        sub { restore_raw($profile, $profile_bytes, $profile_mode) },
    );

    for my $index (0 .. $#staging_relatives) {
        my $stage = repo_path($fixture, $staging_relatives[$index]);
        my $residue = File::Spec->catfile($stage, 'residue');
        my $label = $index == 0 ? 'profile staging residue' : 'corpus staging residue';
        exercise_mutation(
            $label,
            sub {
                make_path($stage, {mode => 0700});
                write_raw($residue, "residue\n");
            },
            sub { remove_tree($stage) },
        );
    }

    my $historical_bytes = read_raw($historical);
    exercise_mutation(
        'historical profile substitution',
        sub { write_raw($profile, $historical_bytes) },
        sub { write_raw($profile, $profile_bytes) },
    );
};

subtest 'owner and device enforcement remains explicit' => sub {
    plan skip_all => 'ignored current corpus is absent on a fresh checkout'
        unless $ignored_corpus_present;
    my $source = read_raw($script);
    like(
        $source,
        qr/changed device or owner.*?\$stat\[0\].*?\$device.*?\$stat\[4\].*?\$owner/s,
        'copied verifier directly compares every safe node owner and device',
    );
    note('foreign-owner mutation is intentionally unavailable without privilege');
    note('foreign-device mutation is intentionally unavailable under same-volume policy');
    pass('unsafe owner/device controls are declared unavailable, not fabricated');
};

SKIP: {
    skip 'ignored current corpus is absent on a fresh checkout', 2
        unless $ignored_corpus_present;
    is_deeply(
        corpus_census($real_active, 1), $real_before,
        'all copied controls leave the real namespace byte/file-identical',
    );
    remove_tree($fixture);
    ok(!-e($fixture) && !-l($fixture),
        'repository-local mutation fixture is removed deterministically');
}

done_testing();

sub exercise_json_mutation {
    my ($label, $path, $mutator) = @_;
    my $original = read_raw($path);
    my $value = $json->decode($original);
    $mutator->($value);
    my $mutated = $json->encode($value) . "\n";
    die "$label did not change copied bytes\n" if $mutated eq $original;
    exercise_mutation(
        $label,
        sub { write_raw($path, $mutated) },
        sub { write_raw($path, $original) },
    );
}

sub exercise_mutation {
    my ($label, $mutate, $restore) = @_;
    $mutate->();
    my $rejected = run_verifier();
    isnt($rejected->{exit}, 0, "$label rejects");
    is($rejected->{stdout}, '', "$label emits no result");
    isnt($rejected->{stderr}, '', "$label emits a bounded diagnostic");
    cmp_ok(length($rejected->{stderr}), '<=', 65_536,
        "$label diagnostic stays within the test ceiling");
    $restore->();
    is_deeply(
        corpus_census($active, 0), $fixture_baseline,
        "$label restores the exact copied census",
    );
    assert_accepts("$label restored baseline");
}

sub assert_accepts {
    my ($label) = @_;
    my $result = run_verifier();
    is($result->{exit}, 0, "$label accepts") or diag($result->{stderr});
    isnt($result->{stdout}, '', "$label emits its complete result");
    is($result->{stderr}, '', "$label is diagnostic-free");
}

sub corpus_census {
    my ($base, $include_inode) = @_;
    my @entries;
    find({
        no_chdir => 1,
        wanted => sub {
            my $path = $File::Find::name;
            my @stat = lstat($path);
            die "cannot stat mutation-census path\n" unless @stat;
            my $relative = File::Spec->abs2rel($path, $base);
            $relative = '' if $relative eq '.';
            $relative =~ s{\\}{/}g;
            my $entry = {
                relative_path => $relative,
                device => $stat[0],
                mode => $stat[2],
                links => $stat[3],
                owner => $stat[4],
                bytes => $stat[7],
                type => -l _ ? 'symlink' : -d _ ? 'directory'
                    : -f _ ? 'file' : 'other',
            };
            $entry->{inode} = $stat[1] if $include_inode;
            $entry->{sha256} = sha256_hex(read_raw($path)) if -f _;
            push @entries, $entry;
        },
    }, $base);
    return [sort {
        $a->{relative_path} cmp $b->{relative_path}
    } @entries];
}

sub copy_tree {
    my ($source, $destination) = @_;
    die "mutation fixture source tree is unavailable\n"
        unless -d $source && !-l $source;
    my @directory_modes;
    find({
        no_chdir => 1,
        wanted => sub {
            my $path = $File::Find::name;
            die "mutation fixture source contains a symlink\n" if -l $path;
            my $relative = File::Spec->abs2rel($path, $source);
            my $target = $relative eq '.'
                ? $destination
                : File::Spec->catfile($destination, $relative);
            my @stat = lstat($path);
            die "cannot stat mutation fixture source path\n" unless @stat;
            my $permissions = $stat[2] & 07777;
            if (-d _) {
                make_path($target, {mode => 0700});
                push @directory_modes, [$target, $permissions];
                return;
            }
            die "mutation fixture source contains a non-file\n" unless -f _;
            copy_file($path, $target);
            chmod($permissions, $target) == 1
                or die "cannot preserve mutation fixture file mode\n";
        },
    }, $source);
    for my $entry (sort {
        length($b->[0]) <=> length($a->[0])
    } @directory_modes) {
        chmod($entry->[1], $entry->[0]) == 1
            or die "cannot preserve mutation fixture directory mode\n";
    }
}

sub copy_file {
    my ($source, $destination) = @_;
    make_path(dirname($destination), {mode => 0700});
    copy($source, $destination)
        or die "cannot copy mutation fixture file\n";
}

sub first_matching_file {
    my ($base, $pattern) = @_;
    my @matches;
    find({
        no_chdir => 1,
        wanted => sub {
            my $path = $File::Find::name;
            my $normalized = $path;
            $normalized =~ s{\\}{/}g;
            push @matches, $path if -f _ && $normalized =~ $pattern;
        },
    }, $base);
    die "mutation fixture expected exactly one matching file\n"
        unless @matches == 1;
    return $matches[0];
}

sub run_verifier {
    my $stderr = gensym;
    my $pid = open3(my $stdin, my $stdout, $stderr, $^X, $script);
    close $stdin or die "cannot close verifier input\n";
    local $/;
    my $out = <$stdout> // '';
    my $err = <$stderr> // '';
    close $stdout or die "cannot close verifier output\n";
    close $stderr or die "cannot close verifier diagnostics\n";
    waitpid($pid, 0) == $pid or die "cannot wait for verifier\n";
    return {exit => $? >> 8, stdout => $out, stderr => $err};
}

sub read_raw {
    my ($path) = @_;
    open my $fh, '<:raw', $path or die "cannot read mutation fixture path\n";
    local $/;
    my $bytes = <$fh>;
    close $fh or die "cannot close mutation fixture path\n";
    return $bytes;
}

sub write_raw {
    my ($path, $bytes) = @_;
    open my $fh, '>:raw', $path or die "cannot write mutation fixture path\n";
    print {$fh} $bytes or die "cannot write mutation fixture bytes\n";
    close $fh or die "cannot close mutation fixture path\n";
}

sub restore_raw {
    my ($path, $bytes, $mode) = @_;
    write_raw($path, $bytes);
    chmod($mode, $path) == 1
        or die "cannot restore mutation fixture file mode\n";
}

sub repo_path {
    my ($base, $relative) = @_;
    return File::Spec->catfile($base, split m{/}, $relative);
}
