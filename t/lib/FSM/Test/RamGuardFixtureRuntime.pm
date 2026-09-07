package FSM::Test::RamGuardFixtureRuntime;

use strict;
use warnings;

use Cwd qw(abs_path);
use Exporter qw(import);
use File::Spec;
use FSM::ProjectDataLocality qw(configure_project_temp_environment);
use FSM::Test::ProcessSupervisor qw(
    process_failure
    repository_contained_path
    repository_root
    supervise_process
);

our @EXPORT_OK = qw(prepare_ram_guard_fixture run_ram_guard_fixture);

my $ROOT = repository_root();
my $PARENT = File::Spec->catdir($ROOT, qw(.artifacts tmp ram-guard-tests));
my @TOOL_PATH = grep { File::Spec->file_name_is_absolute($_) } File::Spec->path();
my $BASH = _resolve_bash();
my $PERL = abs_path($^X);
my $SCHEMA = 'fsmgen.test.ram_guard_fixture_result.v1';
my $STAGE = 'ram_guard_fixture';
my $CONTAINMENT = 'ram_guard_fixture_process_group';
my %BOUNDS = (timeout_seconds => 10, capture_limit_bytes => 1_048_576);
my $INPUT_LIMIT = 65_536;
my %TOOL = (
    uname => <<'UNAME',
set -eu
[ "$#" -eq 1 ] && [ "$1" = "-s" ] || exit 1
printf '%s\n' Darwin
UNAME
    sysctl => <<'SYSCTL',
set -eu
if [ "$#" -ne 2 ] || [ "$1" != "-n" ] || [ "$2" != "hw.memsize" ]; then
    exit 1
fi
printf '%s\n' "${FSMGEN_TEST_TOTAL_BYTES:?}"
SYSCTL
    vm_stat => <<'VMSTAT',
set -eu
while IFS= read -r line || [ -n "$line" ]; do
    printf '%s\n' "$line"
done < "${FSMGEN_TEST_VM_STAT_FILE:?}"
VMSTAT
);
my %PROGRAM = (
    healthy => 'print qq(healthy-child-ok\n)',
    pressured => '$| = 1; print qq(pressured-child-started\n); sleep 30',
    marker => 'open my $fh, q(>), $ARGV[0] or die $!; print {$fh} qq(started\n)',
);

sub prepare_ram_guard_fixture {
    die "RAM-guard fixture preparation expects one workspace\n" unless @_ == 1;
    my ($workspace, $error) = _workspace($_[0]);
    die "RAM-guard fixture preparation: $error\n" if defined $error;
    die "RAM-guard fixture requires a canonical Bash shebang interpreter\n"
        unless defined($BASH) && $BASH !~ /[\s\x00]/;
    my $bin = File::Spec->catdir($workspace, 'fake-bin');
    die "RAM-guard fixture tools already exist\n" if -e $bin || -l $bin;
    mkdir $bin or die "cannot create RAM-guard fixture tools: $!\n";
    for my $name (sort keys %TOOL) {
        my $path = File::Spec->catfile($bin, $name);
        open my $fh, '>', $path or die "cannot write fixture $name: $!\n";
        print {$fh} "#!$BASH\n", $TOOL{$name}
            or die "cannot write fixture $name: $!\n";
        close $fh or die "cannot close fixture $name: $!\n";
        chmod 0755, $path or die "cannot make fixture $name executable: $!\n";
    }
    return $workspace;
}

sub run_ram_guard_fixture {
    return _failure('RAM-guard fixture expects workspace, sample basename and scenario')
        unless @_ == 3;
    my ($requested, $sample, $scenario) = @_;
    my ($workspace, $error) = _workspace($requested);
    return _failure($error) if defined $error;
    return _failure('RAM-guard fixture sample must be a safe basename')
        unless defined($sample) && !ref($sample)
            && $sample =~ /\A[A-Za-z0-9][A-Za-z0-9_.-]*\z/;
    return _failure('RAM-guard fixture scenario is not admitted')
        unless defined($scenario) && !ref($scenario) && exists $PROGRAM{$scenario};
    return _failure('required canonical Bash or Perl executable is unavailable')
        unless defined($BASH) && -f $BASH && -x $BASH
            && defined($PERL) && -f $PERL && -x $PERL;

    my ($input, $input_error) = _regular_file(
        File::Spec->catfile($workspace, $sample),
    );
    return _failure("RAM-guard fixture sample: $input_error") if defined $input_error;
    return _failure('RAM-guard fixture sample exceeds its fixed input ceiling')
        if -s $input > $INPUT_LIMIT;
    my $bin = File::Spec->catdir($workspace, 'fake-bin');
    for my $name (sort keys %TOOL) {
        my ($tool, $tool_error) = _regular_file(File::Spec->catfile($bin, $name));
        return _failure("RAM-guard fixture $name: $tool_error") if defined $tool_error;
        return _failure("RAM-guard fixture $name is not executable") unless -x $tool;
    }
    opendir my $directory, $bin or return _failure('RAM-guard fixture tools cannot be inspected');
    my @unexpected = grep { $_ ne '.' && $_ ne '..' && !exists $TOOL{$_} } readdir $directory;
    closedir $directory or return _failure('RAM-guard fixture tools inspection did not close');
    return _failure('RAM-guard fixture fake-bin contains an unadmitted tool') if @unexpected;

    my ($guard, $guard_error) = _regular_file(
        File::Spec->catfile($ROOT, qw(scripts run_with_ram_guard.sh)),
    );
    return _failure("RAM-guard fixture launcher: $guard_error") if defined $guard_error;
    my @child = ($PERL, '-e', $PROGRAM{$scenario});
    if ($scenario eq 'marker') {
        my $marker = File::Spec->catfile($workspace, "$sample-child-marker");
        return _failure('RAM-guard fixture marker already exists') if -e $marker || -l $marker;
        push @child, $marker;
    }

    local %ENV = %ENV;
    delete @ENV{grep { /\ABASH_FUNC_/ } keys %ENV};
    delete @ENV{qw(BASH_ENV ENV SHELLOPTS BASHOPTS CDPATH GLOBIGNORE)};
    $ENV{PATH} = join(':', $bin, @TOOL_PATH);
    $ENV{FSMGEN_TEST_TOTAL_BYTES} = 4_096_000;
    $ENV{FSMGEN_TEST_VM_STAT_FILE} = $input;
    my $configured = eval {
        configure_project_temp_environment(purpose => 'ram-guard-tests');
        1;
    };
    return _failure('cannot configure repository-local RAM-guard fixture environment')
        unless $configured;
    return supervise_process(
        schema => $SCHEMA, stage => $STAGE, bounds => \%BOUNDS,
        containment => $CONTAINMENT, cwd => $ROOT,
        argv => [$BASH, $guard,
            '--host-max-pct', '88', '--process-max-rss-mb', '4096',
            '--poll-seconds', '0.02', '--grace-seconds', '0', '--', @child],
    );
}

sub _workspace {
    my ($path) = @_;
    my ($absolute, $error) = repository_contained_path($path, must_exist => 1);
    return (undef, "RAM-guard fixture workspace: $error") if defined $error;
    return (undef, 'RAM-guard fixture workspace must be a directory') unless -d $absolute;
    my $relative = File::Spec->abs2rel($absolute, $PARENT);
    return (undef, 'RAM-guard fixture workspace is outside its sealed parent')
        unless $relative =~ /\Afsmgen-[A-Za-z0-9_-]+\z/;
    return ($absolute, undef);
}

sub _regular_file {
    my ($path) = @_;
    my ($absolute, $error) = repository_contained_path($path, must_exist => 1);
    return (undef, $error) if defined $error;
    return (undef, 'expected a readable regular file') unless -f $absolute && -r $absolute;
    return ($absolute, undef);
}

sub _resolve_bash {
    for my $directory (@TOOL_PATH) {
        my $candidate = File::Spec->catfile($directory, 'bash');
        next unless -f $candidate && -x $candidate;
        my $absolute = abs_path($candidate);
        return $absolute if defined($absolute) && -f $absolute && -x $absolute;
    }
    return undef;
}

sub _failure {
    my ($diagnostic) = @_;
    return process_failure(
        schema => $SCHEMA, stage => $STAGE, bounds => \%BOUNDS,
        containment => $CONTAINMENT, status => 'invocation_error',
        diagnostic => $diagnostic,
    );
}

1;
