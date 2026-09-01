#!/usr/bin/env perl

use strict;
use warnings;

use bytes ();
use Fcntl qw(O_CREAT O_EXCL O_NOFOLLOW O_WRONLY);
use File::Path qw(make_path remove_tree);
use File::Spec;
use FindBin;
use Test::More;

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::VIAL::ArchitectureScaleMeasurement;

my $class = 'FSM::VIAL::ArchitectureScaleMeasurement';
my $tree_files = $class->can('_tree_files')
    or die "common worker-output census is unavailable\n";
my $validate_stat = $class->can('_validate_census_entry_stat')
    or die "common worker-output census metadata validator is unavailable\n";
my $validate_worker = $class->can('_validated_worker_artifacts')
    or die "common worker-artifact validator is unavailable\n";
my $validate_terminal = $class->can('_validate_owned_artifact_census')
    or die "terminal worker-output census validator is unavailable\n";
my $repo_root = File::Spec->rel2abs(
    File::Spec->catdir($FindBin::Bin, '..'),
);
my $fixture_root = File::Spec->catdir(
    $repo_root, '.artifacts', 'tmp',
    "vial-common-worker-output-census-admission-$$",
);
my %limit = (
    files => 1_024,
    directories => 1_024,
    depth => 64,
    path_bytes => 262_144,
);

die "worker-output census fixture root already exists\n"
    if -e $fixture_root || -l $fixture_root;
make_path($fixture_root, {mode => 0700});
chmod 0700, $fixture_root
    or die "cannot seal worker-output census fixture root: $!\n";

END {
    remove_tree($fixture_root)
        if defined($fixture_root) && -d($fixture_root) && !-l($fixture_root);
}

my $file_root = File::Spec->catdir($fixture_root, 'files');
make_path($file_root, {mode => 0700});
for my $index (0 .. $limit{files} - 1) {
    touch_file(File::Spec->catfile(
        $file_root, sprintf('f%04d', $index),
    ));
}

my $directory_root = File::Spec->catdir($fixture_root, 'directories');
make_path($directory_root, {mode => 0700});
for my $index (0 .. $limit{directories} - 1) {
    mkdir File::Spec->catdir($directory_root, sprintf('d%04d', $index)), 0700
        or die "cannot create directory-count fixture: $!\n";
}

my $depth_root = File::Spec->catdir($fixture_root, 'depth');
make_path($depth_root, {mode => 0700});
my $deepest = $depth_root;
for (1 .. $limit{depth}) {
    $deepest = File::Spec->catdir($deepest, 'd');
    mkdir $deepest, 0700 or die "cannot create depth fixture: $!\n";
}

my $path_root = File::Spec->catdir($fixture_root, 'path-bytes');
my $path_directory = File::Spec->catdir($path_root, 'd');
make_path($path_directory, {mode => 0700});
for my $index (0 .. $limit{files} - 2) {
    my $name = sprintf('%04x', $index) . ('x' x 250);
    touch_file(File::Spec->catfile($path_directory, $name));
}
my $short_name = 's' x 253;
my $short_path = File::Spec->catfile($path_directory, $short_name);
touch_file($short_path);

subtest 'all four production boundaries are admitted exactly' => sub {
    my @files = $tree_files->($file_root);
    is(scalar(@files), $limit{files},
        'the exact worker-output file-count ceiling is admitted');

    my @directory_files = $tree_files->($directory_root);
    is_deeply(\@directory_files, [],
        'the exact empty-directory-count ceiling is admitted');

    my @depth_files = $tree_files->($depth_root);
    is_deeply(\@depth_files, [],
        'the exact worker-output path-depth ceiling is admitted');

    my @path_files = $tree_files->($path_root);
    is(scalar(@path_files), $limit{files},
        'the exact aggregate relative-path-byte ceiling is admitted');
    is(census_path_bytes($path_root), $limit{path_bytes},
        'the exact path-byte fixture independently totals 262144 bytes');
};

subtest 'each first excess rejects independently during census' => sub {
    touch_file(File::Spec->catfile($file_root, 'f1024'));
    like(capture_error(sub { $tree_files->($file_root) }),
        qr/measurement staging exceeds the 1024-file census ceiling/,
        'file-count ceiling plus one rejects');

    mkdir File::Spec->catdir($directory_root, 'd1024'), 0700
        or die "cannot create directory-count excess fixture: $!\n";
    like(capture_error(sub { $tree_files->($directory_root) }),
        qr/measurement staging exceeds the 1024-directory census ceiling/,
        'directory-count ceiling plus one rejects');

    my $too_deep = File::Spec->catdir($deepest, 'd');
    mkdir $too_deep, 0700 or die "cannot create depth excess fixture: $!\n";
    like(capture_error(sub { $tree_files->($depth_root) }),
        qr/measurement staging exceeds the 64-component census depth ceiling/,
        'path-depth ceiling plus one rejects');

    my $long_name = 's' x 254;
    my $long_path = File::Spec->catfile($path_directory, $long_name);
    rename $short_path, $long_path
        or die "cannot create path-byte excess fixture: $!\n";
    is(census_path_bytes($path_root), $limit{path_bytes} + 1,
        'the path-byte excess fixture independently totals 262145 bytes');
    like(capture_error(sub { $tree_files->($path_root) }),
        qr/measurement staging exceeds the 262144-byte relative-path census ceiling/,
        'aggregate relative-path-byte ceiling plus one rejects');
};

subtest 'repository device, owner, and shared admission are authoritative' => sub {
    my @stat = stat($file_root);
    like(capture_error(sub { $tree_files->($file_root, $stat[0] + 1) }),
        qr/measurement staging crossed repository volume/,
        'a simulated foreign repository device rejects before admission');

    my @foreign_owner = @stat;
    $foreign_owner[4]++;
    like(capture_error(sub {
        $validate_stat->(\@foreign_owner, {repository_device => $stat[0]});
    }), qr/measurement staging owner changed/,
        'a simulated foreign entry owner rejects before admission');

    my $symlink_root = File::Spec->catdir($fixture_root, 'symlink-entry');
    make_path($symlink_root, {mode => 0700});
    touch_file(File::Spec->catfile($symlink_root, 'target'));
    symlink 'target', File::Spec->catfile($symlink_root, 'alias')
        or die "cannot create census symlink fixture: $!\n";
    like(capture_error(sub { $tree_files->($symlink_root, $stat[0]) }),
        qr/measurement staging contains a symlink or special file/,
        'a symlinked entry rejects before census admission');

    my $shared_root = File::Spec->catdir($fixture_root, 'shared-admission');
    make_path(
        File::Spec->catdir($shared_root, qw(outputs emit)),
        {mode => 0700},
    );
    {
        no warnings qw(redefine once);
        local *FSM::VIAL::ArchitectureScaleMeasurement::_tree_files =
            sub { die "bounded census integration sentinel\n" };
        like(capture_error(sub {
            $validate_worker->($shared_root, 'emit', [], $stat[0]);
        }), qr/bounded census integration sentinel/,
            'per-stage worker-result admission uses the common census');
        like(capture_error(sub {
            $validate_terminal->($shared_root, [], $stat[0]);
        }), qr/bounded census integration sentinel/,
            'terminal artifact admission uses the same common census');
    }
};

subtest 'repository-local fixture cleanup is exact' => sub {
    remove_tree($fixture_root);
    ok(!-e($fixture_root) && !-l($fixture_root),
        'worker-output census fixture leaves no residue');
};

done_testing();

sub touch_file {
    my ($path) = @_;
    sysopen my $fh, $path, O_WRONLY | O_CREAT | O_EXCL | O_NOFOLLOW, 0600
        or die "cannot create worker-output census fixture '$path': $!\n";
    close $fh
        or die "cannot close worker-output census fixture '$path': $!\n";
}

sub census_path_bytes {
    my ($root) = @_;
    my $bytes = 0;
    my @pending = (['', $root]);
    while (@pending) {
        my ($relative, $path) = @{pop @pending};
        opendir my $dh, $path
            or die "cannot inventory path-byte fixture '$path': $!\n";
        my @entries = grep { $_ ne '.' && $_ ne '..' } readdir $dh;
        closedir $dh
            or die "cannot close path-byte fixture '$path': $!\n";
        for my $name (@entries) {
            my $entry_relative = length($relative)
                ? "$relative/$name" : $name;
            my $entry = File::Spec->catfile($path, $name);
            $bytes += bytes::length($entry_relative);
            push @pending, [$entry_relative, $entry] if -d $entry && !-l $entry;
        }
    }
    return $bytes;
}

sub capture_error {
    my ($code) = @_;
    my $ok = eval { $code->(); 1 };
    return $ok ? '' : $@;
}
