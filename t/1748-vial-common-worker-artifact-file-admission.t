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
use Test::More;

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::VIAL::ArchitectureScaleMeasurement;

my $class = 'FSM::VIAL::ArchitectureScaleMeasurement';
my $validate = $class->can('_validated_worker_artifacts')
    or die "common worker-artifact validator is unavailable\n";
my $repo_root = File::Spec->rel2abs(
    File::Spec->catdir($FindBin::Bin, '..'),
);
my $fixture_root = File::Spec->catdir(
    $repo_root, '.artifacts', 'tmp',
    "vial-common-worker-artifact-file-admission-$$",
);
my $maximum_bytes = 67_108_864;

die "worker-artifact fixture root already exists\n"
    if -e $fixture_root || -l $fixture_root;
make_path($fixture_root, {mode => 0700});
chmod 0700, $fixture_root
    or die "cannot seal worker-artifact fixture root: $!\n";

END {
    remove_tree($fixture_root)
        if defined($fixture_root) && -d($fixture_root) && !-l($fixture_root);
}

subtest 'exact regular-file controls are admitted through the common reader' => sub {
    for my $mode (0600, 0640, 0644) {
        my ($stage, $path, $relative) = fresh_stage(sprintf('mode-%04o', $mode));
        my $content = "common worker artifact mode " . sprintf('%04o', $mode) . "\n";
        write_file($path, $content, $mode);
        my $records = $validate->($stage, 'emit', [artifact(
            $relative, $content,
        )]);
        is(scalar(@$records), 1,
            sprintf('mode %04o control returns one artifact', $mode));
        is($records->[0]{sha256}, sha256_hex($content),
            sprintf('mode %04o control retains exact bytes', $mode));
    }

    my ($stage, $path, $relative) = fresh_stage('exact-cap');
    sparse_file($path, $maximum_bytes, 0600);
    my $records = $validate->($stage, 'emit', [{
        relative_path => $relative,
        kind => 'focused_worker_artifact',
        bytes => $maximum_bytes,
        lines => 0,
        sha256 => zero_digest($maximum_bytes),
    }]);
    is($records->[0]{bytes}, $maximum_bytes,
        'the existing 64-MiB runtime artifact ceiling is admitted exactly');
};

subtest 'file byte and mode authority precede content validation' => sub {
    my ($mode_stage, $mode_path, $mode_relative) = fresh_stage('ambient-mode');
    my $mode_content = "ambient writable worker artifact\n";
    write_file($mode_path, $mode_content, 0666);
    like(capture_error(sub {
        $validate->($mode_stage, 'emit', [artifact(
            $mode_relative, $mode_content,
        )]);
    }), qr/worker artifact 'outputs\/emit\/artifact\.bin' mode is not admitted/,
        'ambient group/world-writable mode is rejected before content use');

    my ($large_stage, $large_path, $large_relative) = fresh_stage('over-cap');
    sparse_file($large_path, $maximum_bytes + 1, 0600);
    like(capture_error(sub {
        $validate->($large_stage, 'emit', [{
            relative_path => $large_relative,
            kind => 'focused_worker_artifact',
            bytes => $maximum_bytes + 1,
            lines => 0,
            sha256 => '0' x 64,
        }]);
    }), qr/worker artifact 'outputs\/emit\/artifact\.bin' exceeds the 67108864-byte ceiling/,
        'cap+1 is rejected from file metadata before an unbounded read');
};

subtest 'path, link, owner-volume, and opened-file authority fail closed' => sub {
    my $target = File::Spec->catfile($fixture_root, 'leaf-target.bin');
    my $target_content = "leaf symlink target\n";
    write_file($target, $target_content, 0600);
    my ($leaf_stage, $leaf_path, $leaf_relative) = fresh_stage('leaf-symlink');
    symlink File::Spec->abs2rel($target, dirname($leaf_path)), $leaf_path
        or die "cannot create leaf symlink fixture: $!\n";
    like(capture_error(sub {
        $validate->($leaf_stage, 'emit', [artifact(
            $leaf_relative, $target_content,
        )]);
    }), qr/worker artifact 'outputs\/emit\/artifact\.bin' must not be a symlink/,
        'leaf symlink is rejected explicitly');

    my $hard_source = File::Spec->catfile($fixture_root, 'hard-source.bin');
    my $hard_content = "hard-linked worker artifact\n";
    write_file($hard_source, $hard_content, 0600);
    my ($hard_stage, $hard_path, $hard_relative) = fresh_stage('hard-link');
    link $hard_source, $hard_path
        or die "cannot create hard-link fixture: $!\n";
    like(capture_error(sub {
        $validate->($hard_stage, 'emit', [artifact(
            $hard_relative, $hard_content,
        )]);
    }), qr/worker artifact 'outputs\/emit\/artifact\.bin' must have one link/,
        'multiply linked artifact is rejected before content use');

    my $parent_target = File::Spec->catdir($fixture_root, 'parent-target');
    make_path($parent_target, {mode => 0700});
    my $parent_content = "parent symlink target\n";
    write_file(
        File::Spec->catfile($parent_target, 'artifact.bin'),
        $parent_content, 0600,
    );
    my ($parent_stage, undef, $parent_relative) = fresh_stage(
        'parent-symlink', 'jump/artifact.bin', 0,
    );
    my $parent_link = File::Spec->catfile(
        $parent_stage, qw(outputs emit jump),
    );
    symlink File::Spec->abs2rel($parent_target, dirname($parent_link)),
        $parent_link
        or die "cannot create parent symlink fixture: $!\n";
    like(capture_error(sub {
        $validate->($parent_stage, 'emit', [artifact(
            $parent_relative, $parent_content,
        )]);
    }), qr/worker artifact 'outputs\/emit\/jump\/artifact\.bin' traverses a symlink/,
        'parent symlink is rejected before the target is opened');

    my ($device_stage, $device_path, $device_relative) = fresh_stage(
        'foreign-device',
    );
    my $device_content = "same-volume control bytes\n";
    write_file($device_path, $device_content, 0600);
    my @stage_stat = stat($device_stage);
    my $device_error;
    {
        no warnings qw(redefine once);
        local *FSM::VIAL::ArchitectureScaleMeasurement::_worker_artifact_repository_device
            = sub { return $stage_stat[0] + 1 };
        $device_error = capture_error(sub {
            $validate->($device_stage, 'emit', [artifact(
                $device_relative, $device_content,
            )]);
        });
    }
    like($device_error,
        qr/worker artifact 'outputs\/emit\/artifact\.bin' crossed repository volume/,
        'repository-device authority is checked before content use');
};

subtest 'repository-local fixture cleanup is exact' => sub {
    remove_tree($fixture_root);
    ok(!-e($fixture_root) && !-l($fixture_root),
        'worker-artifact admission fixture leaves no residue');
};

done_testing();

sub fresh_stage {
    my ($name, $suffix, $create_parent) = @_;
    $suffix //= 'artifact.bin';
    $create_parent = 1 unless defined $create_parent;
    my $stage = File::Spec->catdir($fixture_root, $name);
    my $output = File::Spec->catdir($stage, qw(outputs emit));
    make_path($output, {mode => 0700});
    chmod 0700, $stage, File::Spec->catdir($stage, 'outputs'), $output;
    my $path = File::Spec->catfile($output, split m{/}, $suffix);
    if ($create_parent) {
        my $parent = dirname($path);
        make_path($parent, {mode => 0700});
        chmod 0700, $parent;
    }
    return ($stage, $path, "outputs/emit/$suffix");
}

sub artifact {
    my ($relative, $content) = @_;
    return {
        relative_path => $relative,
        kind => 'focused_worker_artifact',
        bytes => bytes::length($content),
        lines => scalar(() = $content =~ /\n/g),
        sha256 => sha256_hex($content),
    };
}

sub write_file {
    my ($path, $content, $mode) = @_;
    sysopen my $fh, $path, O_WRONLY | O_CREAT | O_EXCL | O_NOFOLLOW, $mode
        or die "cannot create worker-artifact fixture '$path': $!\n";
    binmode $fh
        or die "cannot set worker-artifact fixture byte mode: $!\n";
    print {$fh} $content
        or die "cannot write worker-artifact fixture '$path': $!\n";
    close $fh
        or die "cannot close worker-artifact fixture '$path': $!\n";
    chmod $mode, $path
        or die "cannot seal worker-artifact fixture '$path': $!\n";
}

sub sparse_file {
    my ($path, $bytes, $mode) = @_;
    sysopen my $fh, $path, O_WRONLY | O_CREAT | O_EXCL | O_NOFOLLOW, $mode
        or die "cannot create sparse worker-artifact fixture '$path': $!\n";
    seek($fh, $bytes - 1, 0)
        or die "cannot size sparse worker-artifact fixture '$path': $!\n";
    print {$fh} "\0"
        or die "cannot terminate sparse worker-artifact fixture '$path': $!\n";
    close $fh
        or die "cannot close sparse worker-artifact fixture '$path': $!\n";
    chmod $mode, $path
        or die "cannot seal sparse worker-artifact fixture '$path': $!\n";
}

sub zero_digest {
    my ($bytes) = @_;
    my $digest = Digest::SHA->new(256);
    my $chunk = "\0" x 1_048_576;
    while ($bytes >= bytes::length($chunk)) {
        $digest->add($chunk);
        $bytes -= bytes::length($chunk);
    }
    $digest->add(substr($chunk, 0, $bytes)) if $bytes;
    return $digest->hexdigest;
}

sub capture_error {
    my ($code) = @_;
    my $ok = eval { $code->(); 1 };
    return $ok ? '' : $@;
}
