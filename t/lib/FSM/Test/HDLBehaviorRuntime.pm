package FSM::Test::HDLBehaviorRuntime;

use strict;
use warnings;

use Cwd qw(abs_path);
use Config ();
use Exporter qw(import);
use File::Basename qw(dirname);
use File::Spec;

use FSM::Test::ProcessSupervisor qw(
    process_failure repository_contained_path repository_root supervise_process
);

our @EXPORT_OK = qw(
    ghdl_behavior_provider run_ghdl_analysis run_ghdl_behavior
    run_storage_identifier_lint
);

my $ROOT = repository_root();
my $SCRATCH = File::Spec->catdir($ROOT, '.artifacts', 'tmp');
my @TOOL_PATH = grep { File::Spec->file_name_is_absolute($_) } File::Spec->path();
my %BOUNDS = (timeout_seconds => 60, capture_limit_bytes => 1_048_576);
my $CONTAINMENT = 'test_runtime_process_group';
my %PROFILE = (
    reset_behavior => ['reset_tb', '100ns'],
    reset_only => ['reset_only_tb', '100ns'],
    internal_role => ['internal_role_tb', '100ns'],
    storage_ownership => ['storage_tb', '300ns'],
    child_storage_reads => ['read_tb', '1000ns'],
    dynamic_count => ['count_tb', '10000ns'],
    unsigned_comparison => ['comparison_tb', '100ns'],
    extract_runtime => ['extract_tb', '100000ns'],
    storage_identifier => [],
);
my %GHDL;
my ($VERILATOR, $VERILATOR_SELECTED);

sub ghdl_behavior_provider {
    my ($profile, @extra) = @_;
    return undef if @extra || !_profile($profile);
    unless (exists $GHDL{$profile}) {
        my $candidate = $profile eq 'storage_identifier'
            ? 'ghdl' : ($ENV{FSMGEN_RESET_GHDL} // 'ghdl');
        $GHDL{$profile} = _executable($candidate);
    }
    return $GHDL{$profile};
}

sub run_ghdl_analysis {
    my ($profile, $directory, $files, @extra) = @_;
    return _failure($profile, 'ghdl', 'expected profile, fixture directory and source array')
        if @extra || !_profile($profile) || ref($files) ne 'ARRAY'
            || !@$files || @$files > 128;
    my ($workspace, $error) = _workspace($directory);
    return _failure($profile, 'ghdl', $error) if defined $error;
    my @sources;
    for my $file (@$files) {
        my ($source, $source_error) = _source($file, $workspace, qr/\.(?:vhd|vhdl)\z/i);
        return _failure($profile, 'ghdl', $source_error) if defined $source_error;
        push @sources, $source;
    }
    my $tool = ghdl_behavior_provider($profile);
    return _unavailable($profile, 'ghdl', 'GHDL provider unavailable') unless defined $tool;
    my @options = ('-a', '--std=08');
    push @options, '--workdir=' . $workspace unless $profile eq 'storage_identifier';
    return _execute($profile, 'ghdl', $workspace, [$tool, @options, @sources]);
}

sub run_ghdl_behavior {
    my ($profile, $directory, @extra) = @_;
    return _failure($profile, 'ghdl', 'expected one runtime profile and fixture directory')
        if @extra || !_profile($profile) || !@{$PROFILE{$profile}};
    my ($workspace, $error) = _workspace($directory);
    return _failure($profile, 'ghdl', $error) if defined $error;
    my $tool = ghdl_behavior_provider($profile);
    return _unavailable($profile, 'ghdl', 'GHDL provider unavailable') unless defined $tool;
    my ($top, $stop) = @{$PROFILE{$profile}};
    return _execute($profile, 'ghdl', $workspace, [
        $tool, '--elab-run', '--std=08', '--workdir=' . $workspace,
        $top, '--assert-level=error', '--stop-time=' . $stop,
    ]);
}

sub run_storage_identifier_lint {
    my ($directory, $file, $objects, @extra) = @_;
    my $profile = 'storage_identifier';
    return _failure($profile, 'verilator_lint', 'expected fixture, source and object directory')
        if @extra;
    my ($workspace, $error) = _workspace($directory);
    return _failure($profile, 'verilator_lint', $error) if defined $error;
    my ($source, $source_error) = _source($file, $workspace, qr/\.(?:sv|v)\z/i);
    return _failure($profile, 'verilator_lint', $source_error) if defined $source_error;
    my ($object_path, $object_error) = repository_contained_path($objects);
    return _failure($profile, 'verilator_lint', 'invalid object directory: ' . $object_error)
        if defined $object_error;
    return _failure($profile, 'verilator_lint', 'object directory must be below the fixture')
        unless _below($object_path, $workspace) && (!-e $object_path || -d $object_path)
            && !_foreign_metadata($object_path);
    unless ($VERILATOR_SELECTED) {
        $VERILATOR = _executable('verilator');
        $VERILATOR_SELECTED = 1;
    }
    return _unavailable($profile, 'verilator_lint', 'Verilator provider unavailable')
        unless defined $VERILATOR;
    return _execute($profile, 'verilator_lint', $workspace, [
        $VERILATOR, '--lint-only', '-Wno-fatal', '--top-module',
        'storage_identifier', '--Mdir', $object_path, $source,
    ], $ROOT);
}

sub _execute {
    my ($profile, $stage, $workspace, $argv, $cwd) = @_;
    my %environment = %ENV;
    delete @environment{qw(BASH_ENV ENV SHELLOPTS BASHOPTS PERL5OPT PERL5LIB)};
    delete @environment{grep { /\ABASH_FUNC_/ } keys %environment};
    $environment{PATH} = join($Config::Config{path_sep}, dirname($argv->[0]), @TOOL_PATH);
    $environment{$_} = $workspace for qw(TMPDIR TMP TEMP);
    return supervise_process(
        schema => 'fsmgen.test.' . $profile . '.v1', stage => $stage,
        bounds => { %BOUNDS }, containment => $CONTAINMENT,
        cwd => defined($cwd) ? $cwd : $workspace,
        environment => \%environment, argv => $argv,
    );
}

sub _profile {
    my ($profile) = @_;
    return defined($profile) && !ref($profile) && exists $PROFILE{$profile};
}

sub _workspace {
    my ($directory) = @_;
    my ($workspace, $error) = repository_contained_path($directory, must_exist => 1);
    return (undef, 'invalid fixture directory: ' . $error) if defined $error;
    return (undef, 'fixture must be below .artifacts/tmp without nested Git metadata')
        unless -d $workspace && _below($workspace, $SCRATCH)
            && !_foreign_metadata($workspace);
    return ($workspace, undef);
}

sub _source {
    my ($file, $workspace, $extension) = @_;
    my ($source, $error) = repository_contained_path($file, must_exist => 1);
    return (undef, 'invalid HDL source: ' . $error) if defined $error;
    return (undef, 'HDL source must be a readable fixture file with the selected extension')
        unless _below($source, $workspace) && -f $source && -r $source
            && $source =~ $extension && !_foreign_metadata($source);
    return ($source, undef);
}

sub _foreign_metadata {
    my ($path) = @_;
    my $cursor = $path;
    while ($cursor ne $ROOT) {
        my $marker = File::Spec->catfile($cursor, '.git');
        return 1 if -e $marker || -l $marker;
        return 1 if -e File::Spec->catfile($cursor, 'HEAD')
            && (-e File::Spec->catfile($cursor, 'objects')
                || -e File::Spec->catfile($cursor, 'refs')
                || -e File::Spec->catfile($cursor, 'packed-refs'));
        $cursor = dirname($cursor);
    }
    return 0;
}

sub _below {
    my ($path, $parent) = @_;
    my $relative = File::Spec->abs2rel($path, $parent);
    return $relative ne File::Spec->curdir()
        && !File::Spec->file_name_is_absolute($relative)
        && !grep { $_ eq File::Spec->updir() } File::Spec->splitdir($relative);
}

sub _executable {
    my ($candidate) = @_;
    return undef unless defined($candidate) && !ref($candidate)
        && length($candidate) && index($candidate, "\0") < 0;
    my @paths = $candidate =~ m{[/\\]}
        ? (File::Spec->rel2abs($candidate, $ROOT))
        : map { File::Spec->catfile($_, $candidate) } @TOOL_PATH;
    for my $path (@paths) {
        next unless -f $path && -x $path;
        my $resolved = abs_path($path);
        return $resolved if defined($resolved) && -f $resolved && -x $resolved;
    }
    return undef;
}

sub _failure {
    my ($profile, $stage, $diagnostic, $status) = @_;
    my $schema = _profile($profile) ? 'fsmgen.test.' . $profile . '.v1'
        : 'fsmgen.test.hdl_behavior_result.v1';
    return process_failure(schema => $schema, stage => $stage,
        bounds => { %BOUNDS }, containment => $CONTAINMENT,
        status => $status // 'invocation_error', diagnostic => $diagnostic);
}

sub _unavailable {
    return _failure(@_, 'tool_unavailable');
}

1;
