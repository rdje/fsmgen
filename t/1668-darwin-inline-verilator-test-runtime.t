#!/usr/bin/env perl

use strict;
use warnings;

use Cwd qw(abs_path);
use File::Basename qw(dirname);
use File::Path qw(make_path);
use File::Spec;
use File::Temp qw(tempdir);
use FindBin;
use JSON::PP qw(decode_json);
use Test::More;
use Time::HiRes qw(sleep);

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');
use lib File::Spec->catdir($FindBin::Bin, 'lib');

use FSM::Test::ProjectDataLocality;
use FSM::Test::VerilatorRuntime qw(
    darwin_verilator_runtime_qualified
    darwin_verilator_runtime_skip_reason
    run_generated_binary
    run_verilator_compile
    run_verilator_version
);

my $repo_root = abs_path(File::Spec->catdir($FindBin::Bin, '..'));
my $perl = abs_path($^X)
    or die "cannot resolve the current Perl interpreter: $!";
my $workspace = tempdir(CLEANUP => 1);

subtest 'Darwin qualification fails closed before invocation inspection' => sub {
    if ($^O ne 'darwin') {
        ok(
            darwin_verilator_runtime_qualified(),
            'non-Darwin execution needs no platform opt-in',
        );
        is(
            darwin_verilator_runtime_skip_reason(), undef,
            'non-Darwin execution has no skip reason',
        );
        return;
    }
    local $ENV{FSMGEN_DARWIN_VERILATOR_TEST_RUNTIME};
    delete $ENV{FSMGEN_DARWIN_VERILATOR_TEST_RUNTIME};
    ok(
        !darwin_verilator_runtime_qualified(),
        'unqualified Darwin execution is rejected',
    );
    like(
        darwin_verilator_runtime_skip_reason(),
        qr/FSMGEN_DARWIN_VERILATOR_TEST_RUNTIME=1/,
        'Darwin skip reason names the exact opt-in',
    );
    my $guarded = run_generated_binary(
        [File::Spec->catfile($workspace, 'missing-runtime')],
    );
    is(
        $guarded->{status}, 'qualification_required',
        'qualification precedes path lookup and process creation',
    );
    ok(
        !$guarded->{cleanup}{leader_started},
        'guard rejection starts no process',
    );
};

subtest 'closed runtime result separates streams and preserves the environment' => sub {
    local $ENV{FSMGEN_DARWIN_VERILATOR_TEST_RUNTIME} = '1';
    my $program = File::Spec->catfile($workspace, 'success-runtime');
    write_executable($program, perl_program(<<'PROGRAM'));
use strict;
use warnings;
print STDOUT "stdout-ready\n";
print STDERR "stderr-ready\n";
exit 0;
PROGRAM
    my %environment_before = %ENV;
    my $result = run_generated_binary([$program]);
    is_deeply(\%ENV, \%environment_before, 'helper leaves caller environment exact');
    ok($result->{ok}, 'repository-local executable succeeds once');
    is($result->{status}, 'success', 'success status is exact');
    is($result->{stdout}, "stdout-ready\n", 'stdout is captured separately');
    is($result->{stderr}, "stderr-ready\n", 'stderr is captured separately');
    is($result->{stdout_bytes}, 13, 'stdout byte count is exact');
    is($result->{stderr_bytes}, 13, 'stderr byte count is exact');
    is($result->{timeout_seconds}, 30, 'runtime deadline cannot be widened');
    is(
        $result->{capture_limit_bytes}, 67_108_864,
        'runtime aggregate capture limit cannot be widened',
    );
    ok($result->{cleanup}{leader_reaped}, 'successful leader is reaped');
    ok($result->{cleanup}{group_gone}, 'successful process group is gone');
    is_deeply(
        [sort keys %$result],
        [sort qw(
            schema schema_version stage ok status diagnostic stdout stderr
            stdout_bytes stderr_bytes exit_code signal timed_out
            output_limited exec_failed exec_error timeout_seconds
            capture_limit_bytes started_monotonic_ns
            exec_handoff_monotonic_ns first_output_monotonic_ns
            finished_monotonic_ns spawn_to_exec_ns execution_ns
            exec_to_first_output_ns first_output_to_exit_ns cleanup
        )],
        'runtime result has one closed top-level schema',
    );
    is_deeply(
        [sort keys %{$result->{cleanup}}],
        [sort qw(
            containment leader_started term_sent kill_sent leader_reaped
            group_gone surviving_descendants
        )],
        'cleanup evidence has one closed key set',
    );
    cmp_ok(
        $result->{started_monotonic_ns}, '<=',
        $result->{exec_handoff_monotonic_ns},
        'spawn precedes successful exec handoff',
    );
    cmp_ok(
        $result->{exec_handoff_monotonic_ns}, '<=',
        $result->{first_output_monotonic_ns},
        'exec handoff precedes first output',
    );
    cmp_ok(
        $result->{first_output_monotonic_ns}, '<=',
        $result->{finished_monotonic_ns},
        'first output precedes process completion',
    );
};

subtest 'invalid, exec, nonzero, and signal outcomes remain failed' => sub {
    local $ENV{FSMGEN_DARWIN_VERILATOR_TEST_RUNTIME} = '1';
    my $invalid_compile = run_verilator_compile([
        'verilator', '--binary', '--binary', '--Mdir', $workspace,
    ]);
    is(
        $invalid_compile->{status}, 'invocation_error',
        'duplicate binary mode fails before process creation',
    );
    ok(
        !$invalid_compile->{cleanup}{leader_started},
        'invalid compile starts no process',
    );

    my $target = File::Spec->catfile($workspace, 'symlink-target');
    write_executable($target, perl_program("exit 0;\n"));
    my $link = File::Spec->catfile($workspace, 'symlink-runtime');
    symlink($target, $link) or die "cannot create runtime symlink: $!";
    my $symlink_result = run_generated_binary([$link]);
    is(
        $symlink_result->{status}, 'invocation_error',
        'symlink runtime is rejected before process creation',
    );

    my $bad_exec = File::Spec->catfile($workspace, 'bad-exec-runtime');
    write_executable($bad_exec, "#!/fsmgen/no-such-interpreter\n");
    my $exec_result = run_generated_binary([$bad_exec]);
    is($exec_result->{status}, 'exec_error', 'exec failure stays failed');
    ok($exec_result->{exec_failed}, 'exec failure is explicit');
    like($exec_result->{exec_error}, qr/^exec failed:/, 'exec diagnostic is stable');
    ok($exec_result->{cleanup}{group_gone}, 'exec-failure group is gone');

    my $nonzero = File::Spec->catfile($workspace, 'nonzero-runtime');
    write_executable($nonzero, perl_program("exit 7;\n"));
    my $nonzero_result = run_generated_binary([$nonzero]);
    is($nonzero_result->{status}, 'nonzero_exit', 'nonzero exit stays failed');
    is($nonzero_result->{exit_code}, 7, 'nonzero exit code is exact');
    ok($nonzero_result->{cleanup}{group_gone}, 'nonzero process group is gone');

    my $signal = File::Spec->catfile($workspace, 'signal-runtime');
    write_executable($signal, perl_program("kill q{KILL}, \$\$;\n"));
    my $signal_result = run_generated_binary([$signal]);
    is($signal_result->{status}, 'signaled', 'signal exit stays failed');
    is($signal_result->{signal}, 9, 'terminating signal is exact');
    ok($signal_result->{cleanup}{group_gone}, 'signaled process group is gone');

    my $orphaning = File::Spec->catfile($workspace, 'orphaning-runtime');
    write_executable($orphaning, perl_program(<<'PROGRAM'));
use strict;
use warnings;
my $child = fork();
die "fork failed: $!" unless defined $child;
if ($child == 0) {
    sleep 60;
    exit 0;
}
print STDOUT "descendant=$child\n";
exit 0;
PROGRAM
    my $orphaning_result = run_generated_binary([$orphaning]);
    is(
        $orphaning_result->{status}, 'surviving_descendants',
        'leader success cannot promote a surviving descendant',
    );
    ok(
        !$orphaning_result->{timed_out},
        'surviving descendant is detected before the runtime deadline',
    );
    ok(
        $orphaning_result->{cleanup}{surviving_descendants},
        'surviving-descendant evidence is explicit',
    );
    ok(
        $orphaning_result->{cleanup}{term_sent},
        'surviving descendant triggers whole-group termination',
    );
    ok(
        $orphaning_result->{cleanup}{group_gone},
        'surviving-descendant group is gone before return',
    );
};

subtest 'capture overflow terminates once at the sealed version limit' => sub {
    local $ENV{FSMGEN_DARWIN_VERILATOR_TEST_RUNTIME} = '1';
    my $fake_bin = File::Spec->catdir($workspace, 'overflow-bin');
    make_path($fake_bin);
    my $verilator = File::Spec->catfile($fake_bin, 'verilator');
    write_executable($verilator, perl_program(<<'PROGRAM'));
use strict;
use warnings;
print STDOUT 'x' x 70000;
exit 0;
PROGRAM
    local $ENV{PATH} = $fake_bin . ':' . ($ENV{PATH} // '');
    my $result = run_verilator_version();
    is($result->{status}, 'output_limited', 'capture overflow stays failed');
    ok($result->{output_limited}, 'capture-limit flag is explicit');
    is(
        $result->{stdout_bytes} + $result->{stderr_bytes}, 65_536,
        'aggregate capture stops at the exact sealed limit',
    );
    ok($result->{cleanup}{group_gone}, 'overflow process group is gone');
};

subtest 'deadline kills a TERM-resistant descendant and proves zero group residue' => sub {
    local $ENV{FSMGEN_DARWIN_VERILATOR_TEST_RUNTIME} = '1';
    my $fake_bin = File::Spec->catdir($workspace, 'timeout-bin');
    make_path($fake_bin);
    my $verilator = File::Spec->catfile($fake_bin, 'verilator');
    write_executable($verilator, perl_program(<<'PROGRAM'));
use strict;
use warnings;
$SIG{TERM} = 'IGNORE';
my $child = fork();
die "fork failed: $!" unless defined $child;
if ($child == 0) {
    $SIG{TERM} = 'IGNORE';
    sleep 60;
    exit 0;
}
print STDOUT "descendant=$child\n";
$| = 1;
sleep 60;
exit 0;
PROGRAM
    local $ENV{PATH} = $fake_bin . ':' . ($ENV{PATH} // '');
    my $result = run_verilator_version();
    is($result->{status}, 'timed_out', 'fixed version deadline stays failed');
    ok($result->{timed_out}, 'timeout flag is explicit');
    is($result->{timeout_seconds}, 10, 'version deadline is the sealed value');
    ok($result->{cleanup}{term_sent}, 'timeout sends TERM to the process group');
    ok($result->{cleanup}{kill_sent}, 'TERM-resistant group escalates to KILL');
    ok($result->{cleanup}{leader_reaped}, 'timeout leader is reaped');
    ok($result->{cleanup}{group_gone}, 'timeout process group is gone');
    my ($descendant) = $result->{stdout} =~ /descendant=([0-9]+)/;
    ok(defined($descendant), 'timeout fixture reports the descendant identity');
    if (defined $descendant) {
        my $alive = 1;
        for (1 .. 100) {
            $alive = kill(0, $descendant) ? 1 : 0;
            last unless $alive;
            sleep(0.02);
        }
        ok(!$alive, 'TERM-resistant descendant leaves no process residue');
    }
};

subtest 'tracked legacy launch census is completely helper-owned' => sub {
    my $watcher_source = slurp(__FILE__);
    my $env_perl_shebangs = () =
        $watcher_source =~ /^#!\/usr\/bin\/env perl$/mg;
    is(
        $env_perl_shebangs, 1,
        'only the prove-invoked watcher entrypoint retains an env shebang',
    );
    like(
        $watcher_source, qr/return "#!\$perl\\n\$body";/,
        'generated hostile fixtures use the canonical running interpreter',
    );
    my $manifest_path = File::Spec->catfile(
        $repo_root,
        qw(t data darwin_inline_verilator_runtime_manifest.json),
    );
    my $manifest = decode_json(slurp($manifest_path));
    is_deeply(
        [sort keys %$manifest],
        [sort qw(schema schema_version compile_calls runtime_calls files)],
        'tracked census manifest has one closed schema',
    );
    is(
        $manifest->{schema},
        'fsmgen.test.darwin_inline_verilator_runtime_manifest.v1',
        'tracked census manifest schema is exact',
    );
    is($manifest->{schema_version}, 1, 'tracked census schema version is exact');
    is($manifest->{compile_calls}, 37, 'tracked compile-call census is exact');
    is($manifest->{runtime_calls}, 37, 'tracked runtime-call census is exact');
    my @expected = @{$manifest->{files}};
    is(scalar @expected, 34, 'tracked census names exactly 34 affected files');
    is_deeply(
        \@expected,
        [sort @expected],
        'tracked census file paths are sorted',
    );
    my %expected_once = map { $_ => 1 } @expected;
    is(
        scalar(keys %expected_once),
        scalar(@expected),
        'tracked census file paths are unique',
    );
    my (%literal_compile, %helper_compile, %helper_runtime);
    my (@direct_binary_ipc, @direct_system_launch);
    for my $path (glob File::Spec->catfile($repo_root, 't', '*.t')) {
        next if basename_only($path) eq '1668-darwin-inline-verilator-test-runtime.t';
        my $relative = File::Spec->abs2rel($path, $repo_root);
        $relative =~ s{\\}{/}g;
        my $source = slurp($path);
        my $literal_count = () =
            $source =~ /['"]verilator['"]\s*,\s*['"]--binary['"]/g;
        $literal_compile{$relative} = $literal_count if $literal_count;
        my $compile_count = () =
            $source =~ /\brun_verilator_compile\s*\(/g;
        $helper_compile{$relative} = $compile_count if $compile_count;
        my $runtime_count = () =
            $source =~ /\brun_generated_binary\s*\(/g;
        $helper_runtime{$relative} = $runtime_count if $runtime_count;
        push @direct_binary_ipc, $relative
            if $source =~ /command\s*=>\s*\[\s*\$binary(?:\s*,|\s*\])/;
        push @direct_system_launch, $relative
            if $source =~ /\bsystem\s*\([^\n]*(?:verilator|["']V[A-Za-z0-9_])/;
    }
    is_deeply(
        \@direct_binary_ipc, [],
        'no tracked test directly launches a generated binary through IPC',
    );
    is_deeply(
        \@direct_system_launch, [],
        'no tracked test directly system-launches Verilator output',
    );
    is_deeply(
        [sort keys %literal_compile], [sort @expected],
        'literal Verilator compile file set remains the exact audited set',
    );
    is_deeply(
        [sort keys %helper_compile], [sort @expected],
        'every audited compile file is helper-owned',
    );
    is_deeply(
        [sort keys %helper_runtime], [sort @expected],
        'every audited runtime file is helper-owned',
    );
    is(
        sum(values %literal_compile), $manifest->{compile_calls},
        'audited Verilator binary compile callsites match the manifest',
    );
    is(
        sum(values %helper_compile), $manifest->{compile_calls},
        'all manifest compile callsites use the bounded helper',
    );
    is(
        sum(values %helper_runtime), $manifest->{runtime_calls},
        'all manifest generated-runtime callsites use the bounded helper',
    );
    for my $relative (@expected) {
        my $source = slurp(File::Spec->catfile(
            $repo_root, split m{/}, $relative,
        ));
        like(
            $source, qr/use FSM::Test::ProjectDataLocality;/,
            "$relative activates project-local test storage",
        );
        like(
            $source, qr/use FSM::Test::VerilatorRuntime qw\(/,
            "$relative imports the bounded runtime helper",
        );
        like(
            $source,
            qr/plan skip_all => darwin_verilator_runtime_skip_reason\(\)\s+unless darwin_verilator_runtime_qualified\(\);/,
            "$relative applies the Darwin guard before runtime work",
        );
    }
};

done_testing();

sub write_executable {
    my ($path, $content) = @_;
    open my $fh, '>:raw', $path or die "cannot write $path: $!";
    print {$fh} $content or die "cannot populate $path: $!";
    close $fh or die "cannot close $path: $!";
    chmod 0755, $path or die "cannot make $path executable: $!";
}

sub perl_program {
    my ($body) = @_;
    return "#!$perl\n$body";
}

sub slurp {
    my ($path) = @_;
    open my $fh, '<:raw', $path or die "cannot read $path: $!";
    local $/;
    my $source = <$fh>;
    close $fh or die "cannot close $path: $!";
    return $source;
}

sub basename_only {
    my ($path) = @_;
    return (File::Spec->splitpath($path))[2];
}

sub sum {
    my $total = 0;
    $total += $_ for @_;
    return $total;
}
