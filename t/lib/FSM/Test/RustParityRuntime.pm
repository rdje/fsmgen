package FSM::Test::RustParityRuntime;

use strict;
use warnings;

use Cwd qw(abs_path);
use Exporter qw(import);
use File::Basename qw(basename dirname);
use File::Path qw(remove_tree);
use File::Spec;
use File::Temp ();
use JSON::PP qw(decode_json);
use FSM::ProjectDataLocality qw(
    configure_project_temp_environment
    ensure_project_artifact_dir
);
use FSM::Test::ProcessSupervisor qw(
    process_failure
    repository_contained_path
    repository_root
    supervise_process
);

our @EXPORT_OK = qw(run_rust_parity);

my $SCHEMA = 'fsmgen.test.rust_parity_result.v1';
my $ROOT = repository_root();
my $PACKAGE = 'fsmgen_portable_api';
my $BINARY = 'fsmgen-portable-api-check-smoke';
my $MANIFEST = File::Spec->catfile($ROOT, qw(rust fsmgen-portable-api Cargo.toml));
my $SOURCE = File::Spec->catfile($ROOT, qw(rust fsmgen-portable-api src bin check_smoke_projection.rs));
my $FIXTURE = File::Spec->catfile($ROOT, qw(t corpus direct_sreset_active_high.fsm));
my @TOOL_PATH = grep { File::Spec->file_name_is_absolute($_) } File::Spec->path();
my $PERL = _resolve_executable($^X);
my $CARGO = _resolve_executable('cargo');
my $RUSTC = _resolve_executable('rustc');
my %RUSTUP_SELECTION = map { $_ => $ENV{$_} } qw(RUSTUP_HOME RUSTUP_TOOLCHAIN);

sub run_rust_parity {
    return _aggregate(_failure('invocation', 'Rust parity accepts no caller options')) if @_;
    return _aggregate(_failure('tool_resolution', 'required Perl or Cargo executable is unavailable'))
        unless defined($PERL) && defined($CARGO);

    # The caller's environment is restored on every return, including failures.
    # Toolchain selection is read-only; cache, build and temporary writes stay local.
    local %ENV = %ENV;
    delete @ENV{grep { /\ACARGO_/ || /\ARUST(?:C|DOC|FLAGS|_ENCODED_)/ } keys %ENV};
    $ENV{PATH} = join(':', @TOOL_PATH);
    for my $key (keys %RUSTUP_SELECTION) {
        if (defined $RUSTUP_SELECTION{$key}) { $ENV{$key} = $RUSTUP_SELECTION{$key}; }
        else { delete $ENV{$key}; }
    }
    my ($workspace, $environment_error);
    eval {
        configure_project_temp_environment(purpose => 'rust-parity');
        $ENV{CARGO_HOME} = ensure_project_artifact_dir('cache', 'cargo');
        my ($parent, $error) = repository_contained_path(
            File::Spec->catdir($ROOT, qw(.artifacts build rust-parity)),
        );
        die "$error\n" if defined $error;
        ensure_project_artifact_dir('build', 'rust-parity');
        $workspace = File::Temp->newdir('fsmgen-XXXXXXXX', DIR => $parent, CLEANUP => 1);
        $ENV{CARGO_TARGET_DIR} = "$workspace";
        1;
    } or $environment_error = $@ || 'cannot configure repository-local Rust workspace';
    return _aggregate(_failure('workspace', $environment_error)) if defined $environment_error;

    my @stages;
    my $result = eval { _run_stages("$workspace", \@stages) };
    if ($@) {
        push @stages, _failure('host', "Rust parity host failure: $@");
        $result = _aggregate(@stages);
    }
    # Remove only this operation's private build directory, after group cleanup.
    # If cleanup is unproved, retain the workspace for diagnosis instead of racing
    # a still-running writer. File::Temp must not erase it on destruction either.
    if (grep { !$_->{cleanup}{group_gone} } @stages) {
        $workspace->unlink_on_destroy(0);
        return $result;
    }
    $workspace->unlink_on_destroy(0);
    my $errors;
    my $removed = eval { remove_tree("$workspace", {error => \$errors}); 1 };
    if (!$removed || @$errors || -e "$workspace" || -l "$workspace") {
        push @stages, _failure('workspace_cleanup', 'cannot remove the owned Rust build workspace', 'cleanup_failed');
        $result = _aggregate(@stages);
    }
    return $result;
}

sub _run_stages {
    my ($target, $stages) = @_;
    my ($cargo, $rustc) = ($CARGO, $RUSTC);
    if (basename($cargo) eq 'rustup') {
        my $resolution = _run('tool_resolution', [$cargo, 'which', 'cargo']);
        push @$stages, $resolution;
        return _aggregate(@$stages) unless $resolution->{ok};
        my $path = $resolution->{stdout};
        $path =~ s/\r?\n\z//;
        $cargo = _absolute_executable($path);
        $rustc = defined($cargo)
            ? _absolute_executable(File::Spec->catfile(dirname($cargo), 'rustc')) : undef;
        return _stop($stages, 'tool_admission', 'rustup did not select a real Cargo and matching rustc')
            unless defined($cargo) && basename($cargo) eq 'cargo'
                && defined($rustc) && basename($rustc) eq 'rustc';
    }
    return _stop($stages, 'tool_admission', 'required direct rustc executable is unavailable')
        unless defined $rustc;
    if (basename($rustc) eq 'rustup') {
        my $resolution = _run('rustc_resolution', [$rustc, 'which', 'rustc']);
        push @$stages, $resolution;
        return _aggregate(@$stages) unless $resolution->{ok};
        my $path = $resolution->{stdout};
        $path =~ s/\r?\n\z//;
        $rustc = _absolute_executable($path);
        return _stop($stages, 'tool_admission', 'rustup did not select a real rustc')
            unless defined($rustc) && basename($rustc) eq 'rustc';
    }
    $ENV{RUSTC} = $rustc;

    my $build = _run('cargo_build', [
        $cargo, 'build', '--offline', '--locked', '--manifest-path',
        File::Spec->catfile($ROOT, qw(rust Cargo.toml)),
        '--package', $PACKAGE, '--bin', $BINARY,
        '--message-format=json-render-diagnostics', '--target-dir', $target,
    ]);
    push @$stages, $build;
    return _aggregate(@$stages) unless $build->{ok};
    my ($program, $error) = _build_executable($build->{stdout}, $target);
    return _stop($stages, 'artifact_admission', $error) if defined $error;

    my $oracle = _run('perl_oracle', [
        $PERL, File::Spec->catfile($ROOT, qw(bin fsmgen)), '--check-json', $FIXTURE,
    ]);
    push @$stages, $oracle;
    return _aggregate(@$stages) unless $oracle->{ok};
    push @$stages, _run('rust_execution', [$program, $FIXTURE]);
    return _aggregate(@$stages);
}

sub _build_executable {
    my ($stdout, $target_root) = @_;
    my @artifacts;
    for my $line (split /\n/, $stdout) {
        next unless length $line;
        my $record = eval { decode_json($line) };
        return (undef, 'Cargo output contains a malformed record')
            unless ref($record) eq 'HASH';
        next unless ($record->{reason} // '') eq 'compiler-artifact';
        next unless ref($record->{target}) eq 'HASH'
            && ($record->{target}{name} // '') eq $BINARY;
        push @artifacts, $record;
    }
    return (undef, 'Cargo must report exactly one matching binary artifact') unless @artifacts == 1;
    my $record = $artifacts[0];
    my $kind = $record->{target}{kind};
    return (undef, 'Cargo artifact target or manifest does not match the parity binary')
        unless ref($kind) eq 'ARRAY' && @$kind == 1 && $kind->[0] eq 'bin'
            && ($record->{manifest_path} // '') eq $MANIFEST
            && ($record->{target}{src_path} // '') eq $SOURCE;

    # Bind package identity to the tracked manifest, without depending on an
    # unrelated workspace artifact or silently accepting another package version.
    open my $fh, '<', $MANIFEST or return (undef, 'cannot read the parity package manifest');
    my $manifest = do { local $/; <$fh> };
    close $fh or return (undef, 'cannot close the parity package manifest');
    my ($section) = $manifest =~ /^\[package\]\s*\n(.*?)(?=^\[|\z)/ms;
    my ($version) = defined($section) ? $section =~ /^version\s*=\s*"([^"]+)"\s*$/m : ();
    return (undef, 'parity package manifest has no literal version') unless defined $version;
    my $package_url = dirname($MANIFEST);
    $package_url =~ s{([^A-Za-z0-9/_.~-])}{sprintf '%%%02X', ord($1)}ge;
    return (undef, 'Cargo artifact package identity does not match the parity package')
        unless ($record->{package_id} // '') =~ /\Apath\+file:\/\/\Q$package_url\E#(?:\Q$PACKAGE\E\@)?\Q$version\E\z/;

    my ($executable, $error) = repository_contained_path($record->{executable}, must_exist => 1);
    return (undef, "Cargo executable is invalid: $error") if defined $error;
    my $relative = File::Spec->abs2rel($executable, $target_root);
    return (undef, 'Cargo executable is outside this operation build directory')
        if File::Spec->file_name_is_absolute($relative) || $relative =~ m{\A\.\.(?:/|\z)};
    return (undef, 'Cargo executable must be a regular executable file') unless -f $executable && -x $executable;
    return ($executable, undef);
}

sub _bounds {
    my ($stage) = @_;
    return {
        timeout_seconds => $stage eq 'cargo_build' ? 120 : 10,
        capture_limit_bytes => $stage eq 'cargo_build' ? 8_388_608 : 1_048_576,
    };
}

sub _run {
    my ($stage, $argv) = @_;
    return supervise_process(
        schema => 'fsmgen.test.rust_parity_stage.v1', stage => $stage,
        bounds => _bounds($stage), containment => 'rust_parity_process_group',
        cwd => $ROOT, argv => $argv,
    );
}

sub _failure {
    my ($stage, $diagnostic, $status) = @_;
    return process_failure(
        schema => 'fsmgen.test.rust_parity_stage.v1', stage => $stage,
        bounds => _bounds($stage), containment => 'rust_parity_process_group',
        status => $status // 'invocation_error', diagnostic => $diagnostic,
    );
}

sub _stop {
    my ($stages, $stage, $diagnostic) = @_;
    push @$stages, _failure($stage, $diagnostic);
    return _aggregate(@$stages);
}

sub _aggregate {
    my (@stages) = @_;
    my ($failure) = grep { !$_->{ok} } @stages;
    return {
        schema => $SCHEMA, schema_version => 1,
        ok => $failure ? 0 : 1,
        status => $failure ? $failure->{status} : 'success',
        failure_stage => $failure ? $failure->{stage} : undef,
        stages => \@stages,
    };
}

sub _resolve_executable {
    my ($name) = @_;
    return _absolute_executable($name) if File::Spec->file_name_is_absolute($name);
    return undef if $name =~ m{/};
    for my $directory (@TOOL_PATH) {
        my $resolved = _absolute_executable(File::Spec->catfile($directory, $name));
        return $resolved if defined $resolved;
    }
    return undef;
}

sub _absolute_executable {
    my ($path) = @_;
    return undef unless defined($path) && !ref($path) && $path !~ /[\x00\r\n]/
        && File::Spec->file_name_is_absolute($path) && -f $path && -x $path;
    my $resolved = abs_path($path);
    return defined($resolved) && -f $resolved && -x $resolved ? $resolved : undef;
}

1;
