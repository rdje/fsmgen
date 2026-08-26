package FSM::Test::VerilatorRuntime;

use strict;
use warnings;

use Exporter qw(import);
use File::Basename qw(basename);

use FSM::Test::ProcessSupervisor qw(
    process_failure
    repository_contained_path
    repository_root
    supervise_process
    validate_argument_vector
);

our @EXPORT_OK = qw(
    darwin_verilator_runtime_qualified
    darwin_verilator_runtime_skip_reason
    run_verilator_version
    run_verilator_compile
    run_generated_binary
);

my $SCHEMA = 'fsmgen.test.verilator_runtime_result.v1';
my $CONTAINMENT = 'test_runtime_process_group';
my $DARWIN_GUARD = 'FSMGEN_DARWIN_VERILATOR_TEST_RUNTIME';
my %STAGE = (
    version => {timeout_seconds => 10, capture_limit_bytes => 65_536},
    compile => {timeout_seconds => 120, capture_limit_bytes => 8_388_608},
    runtime => {timeout_seconds => 30, capture_limit_bytes => 67_108_864},
);
my $REPO_ROOT = repository_root();

sub darwin_verilator_runtime_qualified {
    return 1 unless $^O eq 'darwin';
    return defined($ENV{$DARWIN_GUARD})
        && $ENV{$DARWIN_GUARD} eq '1';
}

sub darwin_verilator_runtime_skip_reason {
    return undef if darwin_verilator_runtime_qualified();
    return "set $DARWIN_GUARD=1 to qualify legacy Verilator test runtime on Darwin";
}

sub run_verilator_version {
    return _run_stage('version', ['verilator', '--version']);
}

sub run_verilator_compile {
    return _run_stage('compile', @_);
}

sub run_generated_binary {
    return _run_stage('runtime', @_);
}

sub _run_stage {
    my ($stage, @arguments) = @_;
    my $bounds = $STAGE{$stage};
    return _failure(
        $stage, $bounds, 'qualification_required',
        darwin_verilator_runtime_skip_reason(),
    ) unless darwin_verilator_runtime_qualified();
    return _failure(
        $stage, $bounds, 'invocation_error',
        "$stage stage expects one argument-vector reference",
    ) unless @arguments == 1 && ref($arguments[0]) eq 'ARRAY';
    my $argv = $arguments[0];
    my $argument_error = validate_argument_vector($argv);
    return _failure(
        $stage, $bounds, 'invocation_error', $argument_error,
    ) if defined $argument_error;
    my $stage_error = $stage eq 'version'
        ? _validate_version_command($argv)
        : $stage eq 'compile'
            ? _validate_compile_command($argv)
            : _validate_runtime_command($argv);
    return _failure(
        $stage, $bounds, 'invocation_error', $stage_error,
    ) if defined $stage_error;
    return supervise_process(
        schema => $SCHEMA,
        stage => $stage,
        bounds => $bounds,
        containment => $CONTAINMENT,
        cwd => $REPO_ROOT,
        argv => $argv,
    );
}

sub _validate_version_command {
    my ($argv) = @_;
    return 'version stage command is sealed'
        unless @$argv == 2
            && $argv->[0] eq 'verilator'
            && $argv->[1] eq '--version';
    return undef;
}

sub _validate_compile_command {
    my ($argv) = @_;
    return 'compile stage executable must be named verilator'
        unless basename($argv->[0]) eq 'verilator';
    my @binary = grep { $argv->[$_] eq '--binary' } 0 .. $#$argv;
    return 'compile stage requires exactly one --binary option'
        unless @binary == 1;
    my @mdir = grep { $argv->[$_] eq '--Mdir' } 0 .. $#$argv;
    return 'compile stage requires exactly one --Mdir path'
        unless @mdir == 1 && $mdir[0] < $#$argv;
    my ($absolute, $path_error) = repository_contained_path(
        $argv->[$mdir[0] + 1], must_exist => 0,
    );
    return "compile object directory is invalid: $path_error"
        if defined $path_error;
    return undef;
}

sub _validate_runtime_command {
    my ($argv) = @_;
    my ($absolute, $path_error) = repository_contained_path(
        $argv->[0], must_exist => 1,
    );
    return "runtime executable is invalid: $path_error"
        if defined $path_error;
    my @metadata = lstat($absolute);
    return 'runtime executable cannot be inspected' unless @metadata;
    return 'runtime executable must not be a symlink' if -l _;
    return 'runtime executable must be a regular executable file'
        unless -f _ && -x _;
    return undef;
}

sub _failure {
    my ($stage, $bounds, $status, $diagnostic) = @_;
    return process_failure(
        schema => $SCHEMA,
        stage => $stage,
        bounds => $bounds,
        containment => $CONTAINMENT,
        status => $status,
        diagnostic => $diagnostic,
    );
}

1;
