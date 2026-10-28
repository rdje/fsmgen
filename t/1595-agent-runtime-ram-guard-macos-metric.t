#!/usr/bin/env perl

use strict;
use warnings;

use File::Spec;
use FindBin;
use File::Basename qw(basename);
use JSON::PP ();
use Test::More;

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');
use lib File::Spec->catdir($FindBin::Bin, 'lib');

use FSM::Test::RamGuardFixtureRuntime qw(
    prepare_ram_guard_fixture
    run_ram_guard_fixture
);

use FSM::ProjectDataLocality qw(
    configure_project_temp_environment
    create_project_tempdir
    repository_root
);

my $repo_root = repository_root();
configure_project_temp_environment(purpose => 'ram-guard-tests');
my $workspace = create_project_tempdir(purpose => 'ram-guard-tests');
prepare_ram_guard_fixture($workspace);

my $guard = File::Spec->catfile(
    $repo_root, 'scripts', 'run_with_ram_guard.sh');
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
        scenario => 'healthy',
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
        scenario => 'pressured',
    );

    is($exit, 137, 'guard returns its documented trip status');
    is($stdout, '', 'over-limit preflight starts no command');
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
            $workspace, basename($fixture) . '-child-marker');
        my ($exit, $stdout, $stderr) = run_guard(
            vm_stat_file => $fixture,
            scenario => 'marker',
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
    like($source, qr/^export FSMGEN_RAM_GUARD_ACTIVE=1$/m,
        'guarded children receive one explicit active-enforcement marker');
    like($source,
        qr/^export FSMGEN_RAM_GUARD_EFFECTIVE_HOST_MAX_PCT="\$host_max_pct"$/m,
        'guarded children receive the exact effective host threshold');
    like($source,
        qr/^export FSMGEN_RAM_GUARD_EFFECTIVE_PROCESS_MAX_RSS_MB="\$process_max_rss_mb"$/m,
        'guarded children receive the exact effective descendant threshold');
};

done_testing();

sub run_guard {
    my (%args) = @_;
    my $result = run_ram_guard_fixture(
        $workspace, basename($args{vm_stat_file}), $args{scenario},
    );
    my $completed = $result->{status} eq 'success' || $result->{status} eq 'nonzero_exit';
    ok($completed, 'fixture finishes with an actual guard exit status');
    my $clean = $result->{cleanup}{leader_reaped} && $result->{cleanup}{group_gone};
    ok($clean, 'fixture leader and process group are cleaned up');
    diag(JSON::PP->new->canonical->encode($result)) unless $completed && $clean;
    return ($result->{exit_code}, $result->{stdout}, $result->{stderr});
}

sub write_vm_stat {
    my ($name, $contents) = @_;
    my $path = File::Spec->catfile($workspace, $name);
    write_file($path, $contents);
    return $path;
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
