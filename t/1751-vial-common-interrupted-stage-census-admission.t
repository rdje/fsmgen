#!/usr/bin/env perl

use strict;
use warnings;

use Fcntl qw(O_CREAT O_EXCL O_NOFOLLOW O_WRONLY);
use File::Path qw(make_path remove_tree);
use File::Spec;
use FindBin;
use Test::More;

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::VIAL::ArchitectureScaleMeasurement;

my $class = 'FSM::VIAL::ArchitectureScaleMeasurement';
my $validate_recovery = $class->can('_validate_recoverable_stage')
    or die "interrupted-stage validator is unavailable\n";
my $cleanup_residue = $class->can('_cleanup_residue')
    or die "cleanup-residue census is unavailable\n";
my $repo_root = File::Spec->rel2abs(
    File::Spec->catdir($FindBin::Bin, '..'),
);
my $fixture_root = File::Spec->catdir(
    $repo_root, '.artifacts', 'tmp',
    "vial-common-interrupted-stage-census-admission-$$",
);
my $stage_root = File::Spec->catdir($fixture_root, 'stage');

die "interrupted-stage census fixture root already exists\n"
    if -e $fixture_root || -l $fixture_root;
make_path($stage_root, {mode => 0700});
chmod 0700, $fixture_root, $stage_root
    or die "cannot seal interrupted-stage census fixture root: $!\n";
my @root_stat = stat($repo_root);
die "repository device is unavailable\n" unless @root_stat;

END {
    remove_tree($fixture_root)
        if defined($fixture_root) && -d($fixture_root) && !-l($fixture_root);
}

for my $index (0 .. 1_023) {
    touch_file(File::Spec->catfile(
        $stage_root, sprintf('f%04d', $index),
    ));
}

subtest 'the exact common file boundary admits interrupted recovery' => sub {
    is(capture_error(sub {
        $validate_recovery->($stage_root, $root_stat[0]);
    }), '', 'the exact 1024-file orphan is safe to recover');
};

subtest 'the first recovery excess rejects before fresh work' => sub {
    touch_file(File::Spec->catfile($stage_root, 'f1024'));
    like(capture_error(sub {
        $validate_recovery->($stage_root, $root_stat[0]);
    }), qr/measurement staging exceeds the 1024-file census ceiling/,
        'a 1025-file orphan is not traversed as an admissible recovery tree');
    unlink File::Spec->catfile($stage_root, 'f1024')
        or die "cannot restore interrupted-stage boundary fixture: $!\n";
};

subtest 'recovery reuses the common bounded census' => sub {
    no warnings qw(redefine once);
    local *FSM::VIAL::ArchitectureScaleMeasurement::_tree_files =
        sub { die "common interrupted-stage census sentinel\n" };
    like(capture_error(sub {
        $validate_recovery->($stage_root, $root_stat[0]);
    }), qr/common interrupted-stage census sentinel/,
        'recovery cannot bypass the common count/depth/path/device admission');
};

subtest 'cleanup residue retains caller-sealed device authority' => sub {
    my $seen;
    no warnings qw(redefine once);
    local *FSM::VIAL::ArchitectureScaleMeasurement::_tree_files = sub {
        $seen = [@_];
        return ('remaining.txt');
    };
    my $residue = eval {
        $cleanup_residue->(
            $stage_root, 'owned/stage', $root_stat[0],
        );
    };
    my $error = "$@";
    is($error, '', 'cleanup residue accepts caller device authority')
        or diag($error);
    is_deeply($seen, [$stage_root, $root_stat[0]],
        'cleanup residue forwards the exact repository device');
    is_deeply($residue, ['owned/stage/remaining.txt'],
        'device-bound residue retains repository-relative identity');
};

subtest 'repository-local fixture cleanup is exact' => sub {
    remove_tree($fixture_root);
    ok(!-e($fixture_root) && !-l($fixture_root),
        'interrupted-stage census fixture leaves no residue');
};

done_testing();

sub touch_file {
    my ($path) = @_;
    sysopen my $fh, $path,
        O_WRONLY | O_CREAT | O_EXCL | O_NOFOLLOW, 0600
        or die "cannot create interrupted-stage fixture '$path': $!\n";
    close $fh
        or die "cannot close interrupted-stage fixture '$path': $!\n";
}

sub capture_error {
    my ($code) = @_;
    my $ok = eval { $code->(); 1 };
    return $ok ? '' : "$@";
}
