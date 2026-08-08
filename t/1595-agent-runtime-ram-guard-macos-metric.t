#!/usr/bin/env perl

use strict;
use warnings;

use File::Spec;
use FindBin;
use IPC::Open3 qw(open3);
use Symbol qw(gensym);
use Test::More;

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::ProjectDataLocality qw(
    configure_project_temp_environment
    create_project_tempdir
    repository_root
);

my $repo_root = repository_root();
configure_project_temp_environment(purpose => 'tests');
my $workspace = create_project_tempdir(purpose => 'tests');
my $fake_bin = File::Spec->catdir($workspace, 'fake-bin');
mkdir $fake_bin or die "cannot create $fake_bin: $!";

my $guard = File::Spec->catfile(
    $repo_root, 'scripts', 'run_with_ram_guard.sh');
my $sysctl = File::Spec->catfile($fake_bin, 'sysctl');
my $uname = File::Spec->catfile($fake_bin, 'uname');
my $vm_stat = File::Spec->catfile($fake_bin, 'vm_stat');

write_executable($uname, <<'UNAME');
#!/usr/bin/env bash
set -eu
[ "$#" -eq 1 ] && [ "$1" = "-s" ] || exit 1
printf '%s\n' Darwin
UNAME

write_executable($sysctl, <<'SYSCTL');
#!/usr/bin/env bash
set -eu
if [ "$#" -ne 2 ] || [ "$1" != "-n" ] || [ "$2" != "hw.memsize" ]; then
    exit 1
fi
printf '%s\n' "${FSMGEN_TEST_TOTAL_BYTES:?}"
SYSCTL

write_executable($vm_stat, <<'VMSTAT');
#!/usr/bin/env bash
set -eu
while IFS= read -r line || [ -n "$line" ]; do
    printf '%s\n' "$line"
done < "${FSMGEN_TEST_VM_STAT_FILE:?}"
VMSTAT

my $healthy = write_vm_stat('healthy.vm_stat', <<'HEALTHY');
Mach Virtual Memory Statistics: (page size of 4096 bytes)
Pages free:                               400.
Pages active:                             400.
Pages inactive:                           300.
Pages speculative:                         20.
Pages wired down:                         100.
Pages purgeable:                           20.
File-backed pages:                        300.
Pages occupied by compressor:              50.
HEALTHY

my $pressured = write_vm_stat('pressured.vm_stat', <<'PRESSURED');
Mach Virtual Memory Statistics: (page size of 4096 bytes)
Pages free:                                20.
Pages active:                             500.
Pages inactive:                           250.
Pages speculative:                         20.
Pages wired down:                         150.
Pages purgeable:                           10.
File-backed pages:                         50.
Pages occupied by compressor:             100.
PRESSURED

my $incomplete = write_vm_stat('incomplete.vm_stat', <<'INCOMPLETE');
Mach Virtual Memory Statistics: (page size of 4096 bytes)
Pages free:                               400.
Pages active:                             400.
Pages inactive:                           300.
Pages speculative:                         20.
Pages wired down:                         100.
Pages purgeable:                           20.
Pages occupied by compressor:              50.
INCOMPLETE

my $invalid = write_vm_stat('invalid.vm_stat', <<'INVALID');
Mach Virtual Memory Statistics: (page size of 4096 bytes)
Pages free:                               400.
Pages active:                             not-a-counter.
Pages inactive:                           300.
Pages speculative:                         20.
Pages wired down:                         100.
Pages purgeable:                           20.
File-backed pages:                        300.
Pages occupied by compressor:              50.
INVALID

subtest 'healthy reclaimable-file-cache sample does not trip' => sub {
    my ($exit, $stdout, $stderr) = run_guard(
        vm_stat_file => $healthy,
        command => [$^X, '-e', 'print qq(healthy-child-ok\n)'],
    );

    is($exit, 0, 'guard preserves the healthy child exit status');
    is($stdout, "healthy-child-ok\n", 'healthy child runs to completion');
    like($stderr, qr/host 55[.]0%; host cutoff 88%/,
        'Stats-compatible fixture reports 55.0% occupied capacity');
    unlike($stderr, qr/reached cutoff/, 'healthy fixture never trips the guard');
};

subtest 'forced high occupied-capacity sample trips at the unchanged cutoff' => sub {
    my ($exit, $stdout, $stderr) = run_guard(
        vm_stat_file => $pressured,
        command => [$^X, '-e', '$| = 1; print qq(pressured-child-started\n); sleep 30'],
    );

    is($exit, 137, 'guard returns its documented trip status');
    is($stdout, "pressured-child-started\n", 'pressured child starts before monitoring trips');
    like($stderr, qr/host 96[.]0%; host cutoff 88%/,
        'Stats-compatible fixture reports 96.0% occupied capacity');
    like($stderr, qr/host memory 96[.]0% reached cutoff 88%/,
        'unchanged host cutoff terminates the pressured child');
};

subtest 'incomplete and invalid macOS samples fail closed before child launch' => sub {
    for my $case (
        ['missing required counter', $incomplete],
        ['invalid required counter', $invalid],
    ) {
        my ($label, $fixture) = @$case;
        my $marker = File::Spec->catfile(
            $workspace, $label =~ s/ /-/gr . '-child-marker');
        my ($exit, $stdout, $stderr) = run_guard(
            vm_stat_file => $fixture,
            command => [$^X, '-e', 'open my $fh, q(>), $ARGV[0] or die $!; print {$fh} qq(started\n)', $marker],
        );

        is($exit, 2, "$label is an inspection failure");
        is($stdout, '', "$label emits no child output");
        like($stderr, qr/host memory inspection is unavailable/,
            "$label identifies the unavailable safety reading");
        ok(!-e $marker, "$label never launches the child");
    }
};

subtest 'unrelated safety contracts remain present' => sub {
    my $source = slurp($guard);
    like($source,
        qr/^process_max_rss_mb="\$\{FSMGEN_RAM_GUARD_PROCESS_MAX_RSS_MB:-4096\}"$/m,
        'descendant-RSS default remains 4096 MiB');
    like($source, qr/^\s*\/\^MemAvailable:\/ \{ available = \$2 \}$/m,
        'Linux host-capacity branch still uses MemAvailable');
    unlike($source, qr/command -v memory_pressure/,
        'incomplete memory_pressure counters are not used as a capacity fallback');
};

done_testing();

sub run_guard {
    my (%args) = @_;
    local %ENV = %ENV;
    $ENV{PATH} = $fake_bin . ':' . $ENV{PATH};
    $ENV{FSMGEN_TEST_TOTAL_BYTES} = 4_096_000;
    $ENV{FSMGEN_TEST_VM_STAT_FILE} = $args{vm_stat_file};

    my @command = (
        $guard,
        '--host-max-pct', '88',
        '--process-max-rss-mb', '4096',
        '--poll-seconds', '0.02',
        '--grace-seconds', '0',
        '--',
        @{$args{command}},
    );

    my $stderr_fh = gensym();
    my $pid = open3(my $stdin_fh, my $stdout_fh, $stderr_fh, @command);
    close $stdin_fh;
    local $/;
    my $stdout = <$stdout_fh> // '';
    my $stderr = <$stderr_fh> // '';
    waitpid($pid, 0);
    return ($? >> 8, $stdout, $stderr);
}

sub write_vm_stat {
    my ($name, $contents) = @_;
    my $path = File::Spec->catfile($workspace, $name);
    write_file($path, $contents);
    return $path;
}

sub write_executable {
    my ($path, $contents) = @_;
    write_file($path, $contents);
    chmod 0755, $path or die "cannot chmod $path: $!";
}

sub write_file {
    my ($path, $contents) = @_;
    open my $fh, '>', $path or die "cannot write $path: $!";
    print {$fh} $contents;
    close $fh or die "cannot close $path: $!";
}

sub slurp {
    my ($path) = @_;
    open my $fh, '<', $path or die "cannot read $path: $!";
    local $/;
    my $contents = <$fh>;
    close $fh or die "cannot close $path: $!";
    return $contents;
}
