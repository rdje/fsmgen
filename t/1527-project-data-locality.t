#!/usr/bin/env perl
use strict;
use warnings;

use Test::More;
use Cwd qw(abs_path getcwd);
use File::Spec;
use File::Temp qw(tempdir);
use FindBin;
use IPC::Cmd qw(run);

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::ProjectDataLocality qw(
    create_project_tempdir
    create_project_tempfile
    ensure_project_artifact_dir
    project_output_path
    repository_root
);

my $repo_root = abs_path(File::Spec->catdir($FindBin::Bin, '..'));

is(repository_root(), $repo_root, 'runtime derives the repository root from tracked module location');

for my $name (qw(TMPDIR TMP TEMP)) {
    ok(defined($ENV{$name}) && length($ENV{$name}), "$name is established by the standard prove harness");
    assert_inside_repository($ENV{$name}, "$name stays inside the repository");
}

my $artifact_dir = ensure_project_artifact_dir('tmp', 'locality-test');
assert_inside_repository($artifact_dir, 'typed artifact directory stays inside the repository');
is((stat($artifact_dir))[0], (stat($repo_root))[0], 'typed artifact directory uses the repository filesystem device');

my ($temp_fh, $temp_file) = create_project_tempfile(
    purpose => 'locality-test',
    suffix => '.fsm',
);
print {$temp_fh} "?fsm:locality_temp\n";
close $temp_fh;
ok(-f $temp_file, 'project tempfile is created');
assert_inside_repository($temp_file, 'project tempfile stays inside the repository');

my $temp_dir = create_project_tempdir(purpose => 'locality-test');
ok(-d $temp_dir, 'project tempdir is created');
assert_inside_repository($temp_dir, 'project tempdir stays inside the repository');

my $accepted = in_directory($repo_root, sub {
    return project_output_path(
        File::Spec->catfile('.artifacts', 'locality-test', 'accepted.sv'),
        label => 'test output',
    );
});
assert_inside_repository($accepted, 'repository-relative output is accepted');

my $outside = File::Spec->catfile($repo_root, File::Spec->updir(), "fsmgen-locality-outside-$$.sv");
my $outside_error = capture_exception(sub {
    project_output_path($outside, label => 'test output');
});
like($outside_error, qr/must resolve inside the FSMGen repository/, 'parent escape is rejected before output');
ok(!-e $outside, 'rejected parent escape creates no output');

my $symlink_root = tempdir('symlink-XXXXXXXX', DIR => $artifact_dir, CLEANUP => 1);
my $escape_link = File::Spec->catfile($symlink_root, 'escape');
if (symlink(File::Spec->rootdir(), $escape_link)) {
    my $symlink_error = capture_exception(sub {
        project_output_path(
            File::Spec->catfile($escape_link, 'fsmgen-locality-outside.sv'),
            label => 'test symlink output',
        );
    });
    like($symlink_error, qr/must resolve inside the FSMGen repository/, 'symlink escape is rejected before output');
} else {
    diag("symlink creation unavailable: $!");
    pass('symlink escape check skipped because symlink creation is unavailable');
}

my ($mktemp_ok, undef, undef, $mktemp_stdout, $mktemp_stderr) = run(
    command => [File::Spec->catfile($repo_root, 'scripts', 'project_mktemp.sh')],
);
ok($mktemp_ok, 'repository-local mktemp wrapper succeeds')
    or diag(join('', @{$mktemp_stderr || []}));
my $wrapper_path = join('', @{$mktemp_stdout || []});
chomp $wrapper_path;
ok(-f $wrapper_path, 'repository-local mktemp wrapper creates a file');
assert_inside_repository($wrapper_path, 'repository-local mktemp wrapper stays inside the repository');
unlink $wrapper_path or die "cannot remove focused-test temporary file '$wrapper_path': $!";

done_testing();

sub assert_inside_repository {
    my ($path, $label) = @_;
    my $absolute = File::Spec->rel2abs($path);
    my $relative = File::Spec->abs2rel($absolute, $repo_root);
    ok(
        $relative ne File::Spec->updir()
            && $relative !~ m{\A\.\.(?:[\\/]|\z)}
            && !File::Spec->file_name_is_absolute($relative),
        $label,
    );
}

sub capture_exception {
    my ($callback) = @_;
    local $@;
    eval { $callback->(); 1 };
    return $@;
}

sub in_directory {
    my ($dir, $callback) = @_;
    my $original = getcwd();
    chdir $dir or die "cannot chdir to $dir: $!";
    my ($result, $error);
    {
        local $@;
        $result = eval { $callback->() };
        $error = $@;
    }
    chdir $original or die "cannot restore cwd to $original: $!";
    die $error if length($error);
    return $result;
}
