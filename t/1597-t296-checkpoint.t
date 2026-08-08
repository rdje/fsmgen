#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use File::Path qw(make_path);
use File::Spec;
use File::Temp qw(tempdir);
use FindBin;
use JSON::PP ();

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');
use lib File::Spec->catdir($FindBin::Bin, 'lib');

use FSM::Test::ProjectDataLocality;
use FSM::Test::T296Checkpoint;

my $test_root = tempdir(CLEANUP => 1);
my $relative_path = '.artifacts/t296/focused-checkpoint.json';
my $fingerprint = 'a' x 40;
my $contract_version = 'focused-v1';

my $checkpoint = FSM::Test::T296Checkpoint->new(
    repo_root => $test_root,
    relative_path => $relative_path,
    fingerprint => $fingerprint,
    contract_version => $contract_version,
);

is($checkpoint->completed_count(), 0, 'new checkpoint starts with no completed batches');
ok(
    !$checkpoint->is_complete(
        surface => 'pipeline', strict_mode => 0, start => 0, count => 1,
    ),
    'new checkpoint does not invent batch completion',
);
ok(
    $checkpoint->mark_complete(
        surface => 'pipeline', strict_mode => 0, start => 0, count => 1,
    ),
    'first completed batch is persisted',
);
ok(-f $checkpoint->path(), 'checkpoint is written below the supplied repository root');
ok(
    !$checkpoint->mark_complete(
        surface => 'pipeline', strict_mode => 0, start => 0, count => 1,
    ),
    'persisting an already-complete batch is idempotent',
);

my $reloaded = FSM::Test::T296Checkpoint->new(
    repo_root => $test_root,
    relative_path => $relative_path,
    fingerprint => $fingerprint,
    contract_version => $contract_version,
);
ok(
    $reloaded->is_complete(
        surface => 'pipeline', strict_mode => 0, start => 0, count => 1,
    ),
    'matching revision and contract reload completed batch evidence',
);
is($reloaded->completed_count(), 1, 'reloaded checkpoint keeps the exact completion set');

opendir my $dir_fh, File::Spec->catdir($test_root, '.artifacts', 't296')
    or die "Cannot inspect focused checkpoint directory: $!";
my @temporary_files = grep { /\.tmp-/ } readdir $dir_fh;
closedir $dir_fh or die "Cannot close focused checkpoint directory: $!";
is_deeply(\@temporary_files, [], 'atomic replacement leaves no temporary checkpoint residue');

my $revision_error = _capture_error(sub {
    FSM::Test::T296Checkpoint->new(
        repo_root => $test_root,
        relative_path => $relative_path,
        fingerprint => ('b' x 40),
        contract_version => $contract_version,
    );
});
like($revision_error, qr/different repository revision/, 'revision mismatch fails closed');

my $contract_error = _capture_error(sub {
    FSM::Test::T296Checkpoint->new(
        repo_root => $test_root,
        relative_path => $relative_path,
        fingerprint => $fingerprint,
        contract_version => 'focused-v2',
    );
});
like($contract_error, qr/different test contract/, 'test-contract mismatch fails closed');

for my $unsafe_path (
    '/off-volume/t296.json',
    '.artifacts/t296/../escape.json',
    '.artifacts/other/checkpoint.json',
) {
    my $error = _capture_error(sub {
        FSM::Test::T296Checkpoint->new(
            repo_root => $test_root,
            relative_path => $unsafe_path,
            fingerprint => $fingerprint,
            contract_version => $contract_version,
        );
    });
    like($error, qr/must match \.artifacts\/t296/, "unsafe path '$unsafe_path' fails closed");
}

_write_checkpoint_state(
    $checkpoint->path(),
    {
        schema_version => 1,
        fingerprint => $fingerprint,
        contract_version => $contract_version,
        completed => {'pipeline:default:not-a-number:1' => 1},
    },
);
my $batch_error = _capture_error(sub {
    FSM::Test::T296Checkpoint->new(
        repo_root => $test_root,
        relative_path => $relative_path,
        fingerprint => $fingerprint,
        contract_version => $contract_version,
    );
});
like($batch_error, qr/Invalid t296 checkpoint batch key/, 'malformed batch state fails closed');

open my $malformed_fh, '>:raw', $checkpoint->path()
    or die "Cannot write malformed focused checkpoint: $!";
print {$malformed_fh} "{not-json\n";
close $malformed_fh or die "Cannot close malformed focused checkpoint: $!";
my $json_error = _capture_error(sub {
    FSM::Test::T296Checkpoint->new(
        repo_root => $test_root,
        relative_path => $relative_path,
        fingerprint => $fingerprint,
        contract_version => $contract_version,
    );
});
like($json_error, qr/Malformed t296 checkpoint/, 'malformed JSON fails closed');

SKIP: {
    my $symlink_root = tempdir(CLEANUP => 1);
    my $symlink_target = tempdir(CLEANUP => 1);
    my $artifact_link = File::Spec->catdir($symlink_root, '.artifacts');
    skip 'symbolic links are unavailable', 1
        unless symlink $symlink_target, $artifact_link;
    my $symlink_error = _capture_error(sub {
        FSM::Test::T296Checkpoint->new(
            repo_root => $symlink_root,
            relative_path => $relative_path,
            fingerprint => $fingerprint,
            contract_version => $contract_version,
        );
    });
    like($symlink_error, qr/artifact root must not be a symlink/, 'symlink escape fails closed');
}

SKIP: {
    my $symlink_checkpoint = FSM::Test::T296Checkpoint->new(
        repo_root => $test_root,
        relative_path => '.artifacts/t296/symlinked-checkpoint.json',
        fingerprint => $fingerprint,
        contract_version => $contract_version,
    );
    my $target_path = File::Spec->catfile($test_root, 'symlink-target.json');
    open my $target_fh, '>:raw', $target_path
        or die "Cannot create focused symlink target: $!";
    print {$target_fh} "{}\n";
    close $target_fh or die "Cannot close focused symlink target: $!";
    skip 'symbolic links are unavailable', 1
        unless symlink $target_path, $symlink_checkpoint->path();
    my $clear_error = _capture_error(sub { $symlink_checkpoint->clear() });
    like($clear_error, qr/Refusing to clear symlinked/, 'checkpoint removal rejects a replaced symlink');
    unlink $symlink_checkpoint->path()
        or die "Cannot remove focused checkpoint symlink: $!";
}

$checkpoint->clear();
ok(!-e $checkpoint->path(), 'completed checkpoint is removed exactly');

done_testing();

sub _capture_error {
    my ($code) = @_;
    my $ok = eval { $code->(); 1 };
    return '' if $ok;
    return $@;
}

sub _write_checkpoint_state {
    my ($path, $state) = @_;
    open my $fh, '>:raw', $path or die "Cannot write focused checkpoint state: $!";
    print {$fh} JSON::PP->new->canonical->encode($state), "\n";
    close $fh or die "Cannot close focused checkpoint state: $!";
}
