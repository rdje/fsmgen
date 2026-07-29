package FSM::ProjectDataLocality;

use v5.20;
use strict;
use warnings;

use Cwd qw(abs_path);
use Exporter qw(import);
use File::Basename qw(basename dirname);
use File::Path qw(make_path);
use File::Spec;
use File::Temp qw(tempdir tempfile);

our @EXPORT_OK = qw(
    configure_project_temp_environment
    create_project_tempdir
    create_project_tempfile
    ensure_project_artifact_dir
    ensure_project_output_directory
    project_output_path
    repository_root
);

my $REPOSITORY_ROOT = _discover_repository_root();

sub repository_root {
    return $REPOSITORY_ROOT;
}

sub ensure_project_artifact_dir {
    my (@parts) = @_;
    _validate_relative_components(@parts);

    my $path = File::Spec->catdir($REPOSITORY_ROOT, '.artifacts', @parts);
    _assert_repository_containment($path, 'project artifact directory');

    eval { make_path($path); 1 }
        or die "Cannot create project artifact directory '$path': $@";

    _assert_repository_containment($path, 'project artifact directory');
    my $resolved = abs_path($path)
        or die "Cannot resolve project artifact directory '$path': $!";
    return $resolved;
}

sub project_output_path {
    my ($path, %args) = @_;
    my $label = $args{label} // 'project output path';

    die "$label is required\n" unless defined($path) && length($path);
    die "$label contains a NUL byte\n" if index($path, "\0") >= 0;

    my $absolute = File::Spec->rel2abs($path);
    return _assert_repository_containment($absolute, $label);
}

sub ensure_project_output_directory {
    my ($path, %args) = @_;
    my $label = $args{label} // 'project output directory';
    my $resolved = project_output_path($path, label => $label);

    eval { make_path($resolved); 1 }
        or die "Cannot create $label '$resolved': $@";

    return _assert_repository_containment($resolved, $label);
}

sub create_project_tempfile {
    my (%args) = @_;
    my $purpose = delete($args{purpose}) // 'runtime';
    my $suffix = delete($args{suffix}) // '';
    die "Unknown create_project_tempfile argument: $_\n" for sort keys %args;

    _validate_relative_components($purpose);
    my $dir = ensure_project_artifact_dir('tmp', $purpose);
    return tempfile(
        'fsmgen-XXXXXXXX',
        DIR => $dir,
        SUFFIX => $suffix,
        UNLINK => 1,
    );
}

sub create_project_tempdir {
    my (%args) = @_;
    my $purpose = delete($args{purpose}) // 'runtime';
    die "Unknown create_project_tempdir argument: $_\n" for sort keys %args;

    _validate_relative_components($purpose);
    my $dir = ensure_project_artifact_dir('tmp', $purpose);
    return tempdir(
        'fsmgen-XXXXXXXX',
        DIR => $dir,
        CLEANUP => 1,
    );
}

sub configure_project_temp_environment {
    my (%args) = @_;
    my $purpose = delete($args{purpose}) // 'runtime';
    die "Unknown configure_project_temp_environment argument: $_\n" for sort keys %args;

    _validate_relative_components($purpose);
    my $dir = ensure_project_artifact_dir('tmp', $purpose);
    $ENV{TMPDIR} = $dir;
    $ENV{TMP} = $dir;
    $ENV{TEMP} = $dir;
    $ENV{FSMGEN_REPO_ROOT} = $REPOSITORY_ROOT;
    $ENV{FSMGEN_TMP_ROOT} = ensure_project_artifact_dir('tmp');
    return $dir;
}

sub _discover_repository_root {
    my $module_path = abs_path(__FILE__)
        or die "Cannot resolve FSM::ProjectDataLocality module path: $!";
    my $root = dirname(dirname(dirname($module_path)));
    $root = abs_path($root)
        or die "Cannot resolve FSMGen repository root from '$module_path': $!";

    for my $required ('README.md', File::Spec->catfile('bin', 'fsmgen'), 'perl') {
        my $path = File::Spec->catfile($root, $required);
        die "Resolved FSMGen repository root '$root' is missing '$required'\n"
            unless -e $path;
    }

    return $root;
}

sub _assert_repository_containment {
    my ($path, $label) = @_;
    my ($resolved, $existing_ancestor) = _resolve_with_existing_ancestor($path, $label);
    my $relative = File::Spec->abs2rel($resolved, $REPOSITORY_ROOT);

    if (
        File::Spec->file_name_is_absolute($relative)
        || $relative eq File::Spec->updir()
        || $relative =~ m{\A\.\.(?:[\\/]|\z)}
    ) {
        die "$label must resolve inside the FSMGen repository: '$path' resolves to '$resolved'\n";
    }

    my @root_stat = stat($REPOSITORY_ROOT);
    my @ancestor_stat = stat($existing_ancestor);
    die "Cannot inspect filesystem device for $label '$path'\n"
        unless @root_stat && @ancestor_stat;
    die "$label must stay on the repository filesystem volume: '$path'\n"
        unless $root_stat[0] == $ancestor_stat[0];

    return $resolved;
}

sub _resolve_with_existing_ancestor {
    my ($path, $label) = @_;
    my $probe = File::Spec->rel2abs($path);
    my @tail;

    while (!-e $probe && !-l $probe) {
        my $parent = dirname($probe);
        die "Cannot find an existing ancestor for $label '$path'\n"
            if $parent eq $probe;
        unshift @tail, basename($probe);
        $probe = $parent;
    }

    my $resolved_ancestor = abs_path($probe)
        or die "Cannot resolve existing ancestor '$probe' for $label '$path': $!";
    my $resolved = $resolved_ancestor;
    for my $component (@tail) {
        next if $component eq File::Spec->curdir();
        if ($component eq File::Spec->updir()) {
            $resolved = dirname($resolved);
            next;
        }

        $resolved = File::Spec->catfile($resolved, $component);
        if (-e $resolved || -l $resolved) {
            $resolved = abs_path($resolved)
                or die "Cannot resolve path component '$resolved' for $label '$path': $!";
        }
    }

    return ($resolved, $resolved_ancestor);
}

sub _validate_relative_components {
    for my $part (@_) {
        die "Project artifact path component is required\n"
            unless defined($part) && length($part);
        die "Unsafe project artifact path component '$part'\n"
            unless $part =~ /\A[A-Za-z0-9][A-Za-z0-9._-]*\z/;
    }
}

1;
