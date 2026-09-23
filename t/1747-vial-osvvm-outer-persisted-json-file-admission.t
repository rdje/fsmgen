#!/usr/bin/env perl

use strict;
use warnings;

use bytes ();
use Cwd qw(abs_path);
use File::Path qw(make_path remove_tree);
use File::Spec;
use JSON::PP ();
use Test::More;

use lib 'perl';
use lib 't/lib';

use FSM::Test::OSVVMRuntimePersistedRequest qw(
    exact_inputs provider_cache_present provider_cache_skip
);
use FSM::VIAL::ArchitectureScaleOSVVMRuntimeMeasurement;

my $JSON = JSON::PP->new->canonical(1);
my $REQUEST_MAX_BYTES = 64 * 1_024;
my $HANDLE_MAX_BYTES = 4 * 1_024;
my $repo_root = abs_path('.');
my @root_stat = stat($repo_root);
my $stage_rel = ".artifacts/tmp/tests/vial-osvvm-outer-json-admission-$$";
my $stage_abs = File::Spec->catdir(
    $repo_root, split(m{/}, $stage_rel),
);
my $owned_root = $stage_abs;
my $context = {
    repository_root => $repo_root,
    staging_identity => $stage_rel,
    staging_root => $stage_abs,
};

END {
    remove_tree($owned_root)
        if defined($owned_root) && -d $owned_root && !-l $owned_root;
}

my $provider_present = provider_cache_present();
my (undef, undef, $envelope) = $provider_present ? exact_inputs() : ();
my $request_content = $JSON->encode($envelope) . "\n";
my $handle_content = $JSON->encode({
    schema => 'focused.osvvm.outer.handle.v1',
    schema_version => 1,
    identity => 'handle/' . ('1' x 64),
}) . "\n";

subtest 'outer lifecycle request file is admitted before decode' => sub {
    plan skip_all => provider_cache_skip() unless $provider_present;
    my $path = request_path();
    make_path(File::Spec->catdir($stage_abs, 'outputs', 'emit'));
    cmp_ok(bytes::length($request_content), '<=', $REQUEST_MAX_BYTES,
        'selected request control fits the 64-KiB admission ceiling');
    write_bytes($path, $request_content, 0600);
    ok(read_request(), 'canonical same-volume 0600 request admits');

    chmod 0644, $path
        or die "cannot change focused request mode: $!\n";
    rejects_request('content-correct request with foreign mode rejects');

    my $oversized = $JSON->encode({
        padding => 'x' x $REQUEST_MAX_BYTES,
    }) . "\n";
    write_bytes($path, $oversized, 0600);
    cmp_ok(-s $path, '>', $REQUEST_MAX_BYTES,
        'request byte-excess control is larger than 64 KiB');
    rejects_request('canonical request over 64 KiB rejects before decode');

    my $target = File::Spec->catfile($stage_abs, 'request-control.json');
    write_bytes($target, $request_content, 0600);
    unlink $path or die "cannot replace focused request with symlink: $!\n";
    symlink '../../request-control.json', $path
        or die "cannot create focused request symlink: $!\n";
    rejects_request('request leaf symlink rejects');

    unlink $path or die "cannot remove focused request symlink: $!\n";
    write_bytes($path, $request_content, 0600);
    {
        no warnings 'redefine';
        local *FSM::VIAL::ArchitectureScaleOSVVMRuntimeMeasurement::_repository_device =
            sub { return $root_stat[0] + 1 };
        rejects_request('request on a foreign simulated device rejects');
    }

    unlink $path or die "cannot replace focused request with hard link: $!\n";
    link $target, $path
        or die "cannot create focused request hard link: $!\n";
    rejects_request('multiply linked request file rejects');

    unlink $path or die "cannot remove focused request hard link: $!\n";
    my $parent_target = File::Spec->catdir($stage_abs, 'request-parent');
    make_path($parent_target);
    write_bytes(
        File::Spec->catfile($parent_target, 'lifecycle-request.json'),
        $request_content, 0600,
    );
    rmdir File::Spec->catdir($stage_abs, 'outputs', 'emit')
        or die "cannot replace focused request parent: $!\n";
    symlink '../request-parent',
        File::Spec->catdir($stage_abs, 'outputs', 'emit')
        or die "cannot create focused request parent symlink: $!\n";
    rejects_request('request parent symlink rejects');
    unlink File::Spec->catdir($stage_abs, 'outputs', 'emit')
        or die "cannot remove focused request parent symlink: $!\n";
    unlink File::Spec->catfile($parent_target, 'lifecycle-request.json')
        or die "cannot remove focused request parent target: $!\n";
    rmdir $parent_target
        or die "cannot remove focused request parent directory: $!\n";
    make_path(File::Spec->catdir($stage_abs, 'outputs', 'emit'));

    write_bytes($path, $request_content, 0600);
    unlink $path or die "cannot replace focused request with directory: $!\n";
    mkdir $path or die "cannot create focused request directory: $!\n";
    rejects_request('non-regular request path rejects');
    rmdir $path or die "cannot remove focused request directory: $!\n";
};

subtest 'outer predecessor handle file is admitted before resume' => sub {
    my $path = handle_path();
    make_path(File::Spec->catdir($stage_abs, 'outputs', 'emit'));
    cmp_ok(bytes::length($handle_content), '<=', $HANDLE_MAX_BYTES,
        'selected handle control fits the 4-KiB admission ceiling');
    write_bytes($path, $handle_content, 0600);
    ok(read_handle(), 'canonical same-volume 0600 handle admits');

    chmod 0644, $path
        or die "cannot change focused handle mode: $!\n";
    rejects_handle('content-correct handle with foreign mode rejects');

    my $oversized = $JSON->encode({
        padding => 'x' x $HANDLE_MAX_BYTES,
    }) . "\n";
    write_bytes($path, $oversized, 0600);
    cmp_ok(-s $path, '>', $HANDLE_MAX_BYTES,
        'handle byte-excess control is larger than 4 KiB');
    rejects_handle('canonical handle over 4 KiB rejects before decode');

    my $target = File::Spec->catfile($stage_abs, 'handle-control.json');
    write_bytes($target, $handle_content, 0600);
    unlink $path or die "cannot replace focused handle with symlink: $!\n";
    symlink '../../handle-control.json', $path
        or die "cannot create focused handle symlink: $!\n";
    rejects_handle('handle leaf symlink rejects');

    unlink $path or die "cannot remove focused handle symlink: $!\n";
    write_bytes($path, $handle_content, 0600);
    {
        no warnings 'redefine';
        local *FSM::VIAL::ArchitectureScaleOSVVMRuntimeMeasurement::_repository_device =
            sub { return $root_stat[0] + 1 };
        rejects_handle('handle on a foreign simulated device rejects');
    }

    unlink $path or die "cannot replace focused handle with hard link: $!\n";
    link $target, $path
        or die "cannot create focused handle hard link: $!\n";
    rejects_handle('multiply linked handle file rejects');

    unlink $path or die "cannot remove focused handle hard link: $!\n";
    write_bytes($path, $handle_content, 0600);
    unlink $path or die "cannot replace focused handle with directory: $!\n";
    mkdir $path or die "cannot create focused handle directory: $!\n";
    rejects_handle('non-regular handle path rejects');
    rmdir $path or die "cannot remove focused handle directory: $!\n";
};

subtest 'outer JSON writer normalizes exact private modes' => sub {
    plan skip_all => provider_cache_skip() unless $provider_present;
    my $root = File::Spec->catdir($stage_abs, 'writer');
    my $old_umask = umask 0000;
    my $result = eval {
        FSM::VIAL::ArchitectureScaleOSVVMRuntimeMeasurement::_materialize_payload(
            {output_root => $root, output_identity => 'outputs/focused'},
            {
                status => 'focused', oracle_id => 'focused', evidence => {},
                semantic_counts => {},
                artifacts => [
                    {
                        suffix => 'lifecycle-request.json',
                        kind => 'osvvm_runtime_lifecycle_request',
                        content => $request_content,
                    },
                    {
                        suffix => 'lifecycle-handle.json',
                        kind => 'osvvm_runtime_lifecycle_handle',
                        content => $handle_content,
                    },
                ],
            },
        );
    };
    my $error = $@;
    umask $old_umask;
    die $error unless defined $result;
    is(file_mode(File::Spec->catfile($root, 'lifecycle-request.json')),
        '0600', 'request writer is independent of ambient umask');
    is(file_mode(File::Spec->catfile($root, 'lifecycle-handle.json')),
        '0600', 'handle writer is independent of ambient umask');
};

remove_tree($owned_root);
$owned_root = undef;
ok(!-e $stage_abs && !-l $stage_abs,
    'focused same-volume outer JSON tree is removed exactly');

done_testing();

sub request_path {
    return File::Spec->catfile(
        $stage_abs, 'outputs', 'emit', 'lifecycle-request.json',
    );
}

sub handle_path {
    return File::Spec->catfile(
        $stage_abs, 'outputs', 'emit', 'lifecycle-handle.json',
    );
}

sub read_request {
    return eval {
        FSM::VIAL::ArchitectureScaleOSVVMRuntimeMeasurement::_read_request_envelope(
            $context,
        );
        1;
    } ? 1 : 0;
}

sub read_handle {
    return eval {
        FSM::VIAL::ArchitectureScaleOSVVMRuntimeMeasurement::_read_predecessor_handle(
            $context, 'compile_analyze',
        );
        1;
    } ? 1 : 0;
}

sub rejects_request {
    my ($label) = @_;
    ok(!read_request(), $label);
}

sub rejects_handle {
    my ($label) = @_;
    ok(!read_handle(), $label);
}

sub write_bytes {
    my ($path, $content, $mode) = @_;
    unlink $path if -f $path || -l $path;
    open my $fh, '>:raw', $path
        or die "cannot create focused outer JSON file: $!\n";
    print {$fh} $content
        or die "cannot write focused outer JSON file: $!\n";
    close $fh or die "cannot close focused outer JSON file: $!\n";
    chmod $mode, $path
        or die "cannot seal focused outer JSON mode: $!\n";
}

sub file_mode {
    my ($path) = @_;
    my @stat = stat($path);
    return @stat ? sprintf('%04o', $stat[2] & 07777) : 'absent';
}
