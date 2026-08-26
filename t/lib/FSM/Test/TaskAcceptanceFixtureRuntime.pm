package FSM::Test::TaskAcceptanceFixtureRuntime;

use strict;
use warnings;

use Cwd qw(abs_path);
use Exporter qw(import);
use File::Spec;

use FSM::Test::ProcessSupervisor qw(
    process_failure
    repository_contained_path
    repository_root
    supervise_process
    validate_argument_vector
);

our @EXPORT_OK = qw(
    run_fixture_checker
    run_fixture_git
);

my $SCHEMA = 'fsmgen.test.task_acceptance_fixture_result.v1';
my $CONTAINMENT = 'task_acceptance_fixture_process_group';
my $BASH = _resolve_path_executable('bash');
my $GIT = _resolve_path_executable('git');
my %STAGE = (
    fixture_git => {
        timeout_seconds => 10,
        capture_limit_bytes => 1_048_576,
    },
    task_acceptance_checker => {
        timeout_seconds => 10,
        capture_limit_bytes => 4_194_304,
    },
);
my $REPO_ROOT = repository_root();
my $FIXTURE_PARENT = File::Spec->catdir(
    $REPO_ROOT, '.artifacts', 'tmp', 'task-acceptance-tests',
);

sub run_fixture_git {
    my ($repo, @arguments) = @_;
    my $stage = 'fixture_git';
    my ($fixture, $fixture_error) = _fixture_repo($repo);
    return _failure($stage, $fixture_error) if defined $fixture_error;
    return _failure(
        $stage,
        'required external git executable cannot be resolved to an absolute executable',
    ) unless defined $GIT;
    return _failure(
        $stage, 'fixture Git expects one argument-vector reference',
    ) unless @arguments == 1 && ref($arguments[0]) eq 'ARRAY';
    my $git_arguments = $arguments[0];
    my $argument_error = validate_argument_vector($git_arguments);
    return _failure($stage, $argument_error) if defined $argument_error;
    my $git_error = _validate_git_arguments($git_arguments);
    return _failure($stage, $git_error) if defined $git_error;

    return supervise_process(
        schema => $SCHEMA,
        stage => $stage,
        bounds => $STAGE{$stage},
        containment => $CONTAINMENT,
        cwd => $fixture,
        argv => [$GIT, '-C', $fixture, @$git_arguments],
    );
}

sub _validate_git_arguments {
    my ($arguments) = @_;
    return undef
        if @$arguments == 2
            && $arguments->[0] eq 'init'
            && $arguments->[1] eq '-q';
    return undef
        if @$arguments == 3
            && $arguments->[0] eq 'config'
            && (($arguments->[1] eq 'user.email'
                    && $arguments->[2] eq 'fixture@example.invalid')
                || ($arguments->[1] eq 'user.name'
                    && $arguments->[2] eq 'Fixture'));
    return undef
        if @$arguments == 4
            && $arguments->[0] eq 'commit'
            && $arguments->[1] eq '-q'
            && $arguments->[2] eq '-m'
            && $arguments->[3] eq 'fixture baseline';
    return undef
        if @$arguments == 2
            && $arguments->[0] eq 'add'
            && $arguments->[1] eq '.';
    if (@$arguments >= 3
            && $arguments->[0] eq 'add'
            && $arguments->[1] eq '--') {
        for my $path (@$arguments[2 .. $#$arguments]) {
            return 'fixture Git add path must be repository-relative'
                if File::Spec->file_name_is_absolute($path);
            my @component = split m{[\\/]}, $path, -1;
            return 'fixture Git add path contains an unsafe component'
                if grep { $_ eq '' || $_ eq '.' || $_ eq '..' } @component;
        }
        return undef;
    }
    return 'fixture Git argument shape is not admitted';
}

sub run_fixture_checker {
    my ($repo, @extra) = @_;
    my $stage = 'task_acceptance_checker';
    return _failure($stage, 'fixture checker accepts only one repository path')
        if @extra;
    my ($fixture, $fixture_error) = _fixture_repo($repo);
    return _failure($stage, $fixture_error) if defined $fixture_error;
    return _failure(
        $stage,
        'required external bash interpreter cannot be resolved to an absolute executable',
    ) unless defined $BASH;

    my $checker = File::Spec->catfile(
        $fixture, 'scripts', 'check_task_acceptance.sh',
    );
    my ($absolute, $checker_error) = repository_contained_path(
        $checker, must_exist => 1,
    );
    return _failure(
        $stage, "fixture checker path is invalid: $checker_error",
    ) if defined $checker_error;
    my @metadata = lstat($absolute);
    return _failure($stage, 'fixture checker cannot be inspected')
        unless @metadata;
    return _failure($stage, 'fixture checker must not be a symlink') if -l _;
    return _failure(
        $stage, 'fixture checker must be a readable regular file',
    ) unless -f _ && -r _;

    return supervise_process(
        schema => $SCHEMA,
        stage => $stage,
        bounds => $STAGE{$stage},
        containment => $CONTAINMENT,
        cwd => $fixture,
        argv => [$BASH, $absolute],
    );
}

sub _fixture_repo {
    my ($repo) = @_;
    my ($absolute, $path_error) = repository_contained_path(
        $repo, must_exist => 1,
    );
    return (undef, "fixture repository path is invalid: $path_error")
        if defined $path_error;
    return (undef, 'fixture repository must be a directory')
        unless -d $absolute;
    my $relative = File::Spec->abs2rel($absolute, $FIXTURE_PARENT);
    $relative =~ s{\\}{/}g;
    return (undef, 'fixture repository is outside the sealed task-acceptance workspace')
        unless $relative =~ /\Afsmgen-[A-Za-z0-9_-]+\z/;
    return ($absolute, undef);
}

sub _resolve_path_executable {
    my ($name) = @_;
    for my $directory (File::Spec->path()) {
        next unless defined($directory) && length($directory);
        next unless File::Spec->file_name_is_absolute($directory);
        my $candidate = File::Spec->catfile($directory, $name);
        next unless -f $candidate && -x $candidate;
        my $resolved = abs_path($candidate);
        return $resolved
            if defined($resolved) && File::Spec->file_name_is_absolute($resolved)
                && -f $resolved && -x $resolved;
    }
    return undef;
}

sub _failure {
    my ($stage, $diagnostic) = @_;
    return process_failure(
        schema => $SCHEMA,
        stage => $stage,
        bounds => $STAGE{$stage},
        containment => $CONTAINMENT,
        status => 'invocation_error',
        diagnostic => $diagnostic,
    );
}

1;
