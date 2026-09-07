#!/usr/bin/env perl

use strict;
use warnings;
use Cwd qw(abs_path);
use File::Spec;
use FindBin;
use Test::More;
use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');
use lib File::Spec->catdir($FindBin::Bin, 'lib');
use FSM::ProjectDataLocality qw(create_project_tempdir repository_root);
use FSM::Test::ProjectDataLocality;
use FSM::Test::ProcessSupervisor qw(process_failure);
use FSM::Test::RamGuardFixtureRuntime qw(prepare_ram_guard_fixture run_ram_guard_fixture);

my $root = repository_root();
my $perl = abs_path($^X) or die "cannot resolve current Perl: $!";
my $workspace = create_project_tempdir(purpose => 'ram-guard-tests');
prepare_ram_guard_fixture($workspace);
my $sample = 'healthy.vm_stat';
my $input = File::Spec->catfile($workspace, $sample);
my $vm_stat = File::Spec->catfile($workspace, 'fake-bin', 'vm_stat');
my $vm_source = slurp($vm_stat);
my $healthy = <<'SAMPLE';
Mach Virtual Memory Statistics: (page size of 4096 bytes)
Pages active: 400.
Pages inactive: 300.
Pages speculative: 20.
Pages wired down: 100.
Pages purgeable: 20.
File-backed pages: 300.
Pages occupied by compressor: 50.
SAMPLE
write_file($input, $healthy);

subtest 'fixture policy survives caller environment mutation' => sub {
    my $injection = File::Spec->catfile($workspace, 'startup-injection');
    my $marker = File::Spec->catfile($workspace, 'startup-ran');
    write_file($injection, 'printf injected > ' . shell_quote($marker) . "\n");
    local $ENV{PATH} = $workspace;
    local $ENV{BASH_ENV} = $injection;
    local $ENV{ENV} = $injection;
    local $ENV{FSMGEN_TEST_TOTAL_BYTES} = 1;
    local $ENV{FSMGEN_TEST_VM_STAT_FILE} = $injection;
    local $ENV{FSMGEN_RAM_GUARD_HOST_MAX_PCT} = 1;
    local $ENV{FSMGEN_RAM_GUARD_PROCESS_MAX_RSS_MB} = 1;
    my %before = %ENV;
    my $result = run_ram_guard_fixture($workspace, $sample, 'healthy');
    ok($result->{ok}, 'selected tools and fixed options survive caller overrides') or diag explain $result;
    is($result->{stdout}, "healthy-child-ok\n", 'exact admitted child runs');
    like($result->{stderr}, qr/host 55[.]0%; host cutoff 88%; descendant RSS cutoff 4096 MiB/,
        'fixture metric and effective limits remain exact');
    is($result->{schema}, 'fsmgen.test.ram_guard_fixture_result.v1', 'result schema is explicit');
    is($result->{stage}, 'ram_guard_fixture', 'result stage is fixed');
    is($result->{timeout_seconds}, 10, 'fixture wall is sealed');
    is($result->{capture_limit_bytes}, 1_048_576, 'capture ceiling is sealed');
    is($result->{cleanup}{containment}, 'ram_guard_fixture_process_group', 'containment claim is one group');
    ok($result->{cleanup}{leader_reaped} && $result->{cleanup}{group_gone}, 'actual owned group is gone');
    ok(!-e $marker, 'Bash startup injection never runs');
    is_deeply(\%ENV, \%before, 'caller environment is restored');
};

subtest 'command, input, tool and workspace escapes reject before launch' => sub {
    my $foreign = create_project_tempdir(purpose => 'tests');
    my $alias = File::Spec->catdir($workspace, 'alias');
    symlink $workspace, $alias or die $!;
    my @rejected = (
        [], [$workspace], [$workspace, $sample, 'healthy', timeout_seconds => 999],
        [$workspace, '../healthy.vm_stat', 'healthy'], [$workspace, $input, 'healthy'],
        [$workspace, {}, 'healthy'], [$workspace, $sample, {}],
        [$workspace, $sample, 'arbitrary-command'], [$foreign, $sample, 'healthy'],
        [$alias, $sample, 'healthy'], [$workspace, 'fake-bin', 'healthy'],
    );
    for my $arguments (@rejected) {
        my $result = run_ram_guard_fixture(@$arguments);
        is($result->{status}, 'invocation_error', 'invalid invocation rejects');
        ok(!$result->{cleanup}{leader_started}, 'rejection starts no process');
        is($result->{timeout_seconds}, 10, 'rejection cannot change the wall');
    }
    my $sample_link = File::Spec->catfile($workspace, 'sample-link');
    symlink $input, $sample_link or die $!;
    is(run_ram_guard_fixture($workspace, 'sample-link', 'healthy')->{status},
        'invocation_error', 'sample symlink rejects');
    my $oversized = File::Spec->catfile($workspace, 'oversized');
    write_file($oversized, 'x' x 65_537);
    is(run_ram_guard_fixture($workspace, 'oversized', 'healthy')->{status},
        'invocation_error', 'input boundary plus one rejects');
    my $decoy = File::Spec->catfile($workspace, 'fake-bin', 'ps');
    write_file($decoy, "#!/bin/sh\nexit 0\n");
    is(run_ram_guard_fixture($workspace, $sample, 'healthy')->{status},
        'invocation_error', 'extra fake tool cannot intercept process inspection');
    unlink $decoy or die $!;
    rename $vm_stat, "$vm_stat.saved" or die $!;
    symlink "$vm_stat.saved", $vm_stat or die $!;
    is(run_ram_guard_fixture($workspace, $sample, 'healthy')->{status},
        'invocation_error', 'fake tool symlink rejects');
    unlink $vm_stat or die $!;
    rename "$vm_stat.saved", $vm_stat or die $!;
};

subtest 'input boundary and complete engine failure record remain exact' => sub {
    write_file(File::Spec->catfile($workspace, 'boundary'), 'x' x 65_536);
    my $record = process_failure(
        schema => 'fsmgen.test.ram_guard_fixture_result.v1', stage => 'ram_guard_fixture',
        containment => 'ram_guard_fixture_process_group',
        bounds => {timeout_seconds => 10, capture_limit_bytes => 1_048_576},
        status => 'signaled', diagnostic => 'injected complete engine record',
    );
    $record->{signal} = 15;
    $record->{cleanup}{group_gone} = 0;
    $record->{cleanup}{leader_started} = 1;
    $record->{cleanup}{leader_reaped} = 1;
    my $calls = 0;
    {
        no warnings 'redefine';
        local *FSM::Test::RamGuardFixtureRuntime::supervise_process = sub {
            my %args = @_;
            $calls++;
            is_deeply($args{bounds}, {timeout_seconds => 10, capture_limit_bytes => 1_048_576},
                'admitted input still uses exact bounds');
            is($args{argv}[1], File::Spec->catfile($root, 'scripts', 'run_with_ram_guard.sh'),
                'only the repository guard can be selected');
            return $record;
        };
        is_deeply(run_ram_guard_fixture($workspace, 'boundary', 'healthy'), $record,
            'adapter returns the complete result without projecting exit or cleanup');
    }
    is($calls, 1, 'input boundary admits one invocation with no retry');
};

subtest 'stderr before stdout makes observed progress through concurrent capture' => sub {
    my $progress = File::Spec->catfile($workspace, 'stream-progress');
    my $body = progress_prefix($progress) . <<'PROGRAM';
print STDERR 'x' x 262_144 or die $!;
open my $after, '>>', $progress or die $!;
print {$after} "drained\n" or die $!;
close $after or die $!;
print STDOUT "stdout-after-stderr\n";
PROGRAM
    my $result = run_engine_probe('streams', $body);
    ok($result->{ok}, 'stderr-first producer completes through the actual shared capture') or diag explain $result;
    is(slurp($progress), "entered\ndrained\n", 'independent file proves producer main and completed writes');
    is($result->{stderr}, 'x' x 262_144, 'the complete admitted stderr burst is captured');
    is($result->{stdout}, "stdout-after-stderr\n", 'later stdout remains separate');
    ok($result->{cleanup}{leader_reaped} && $result->{cleanup}{group_gone}, 'stream control has no surviving group');
};

subtest 'actual engine signal and capture failures survive the adapter boundary' => sub {
    my $signaled = run_engine_probe('signal', '$|=1; print "signal-body-entered\n"; kill q(TERM), $$; die q(signal did not terminate);');
    is($signaled->{status}, 'signaled', 'signal is not projected into exit success') or diag explain $signaled;
    is($signaled->{signal}, 15, 'actual native signal remains exact');
    ok(!defined($signaled->{exit_code}), 'signal has no fabricated exit code');
    is($signaled->{stdout}, "signal-body-entered\n", 'signal producer entered its body');
    ok($signaled->{cleanup}{leader_reaped} && $signaled->{cleanup}{group_gone}, 'signal cleans the group');
    my $overflow = run_engine_probe('overflow', "print STDERR 'x' x 1_048_577;");
    is($overflow->{status}, 'output_limited', 'capture failure is not projected into exit success') or diag explain $overflow;
    ok($overflow->{output_limited}, 'capture limit flag is retained');
    ok($overflow->{cleanup}{leader_reaped} && $overflow->{cleanup}{group_gone}, 'overflow cleans the group');
};

subtest 'a TERM-resistant inspection body has a bounded failed startup and cleanup' => sub {
    my ($shebang) = split /\n/, $vm_source, 2;
    my $progress = File::Spec->catfile($workspace, 'startup-progress');
    write_file($vm_stat, "$shebang\ntrap '' TERM\n"
        . 'printf "entered\\n" > ' . shell_quote($progress) . "\nwhile :; do sleep 1; done\n");
    my $timeout = run_ram_guard_fixture($workspace, $sample, 'healthy');
    is($timeout->{status}, 'timed_out', 'actual guard inspection deadline stays failed') or diag explain $timeout;
    ok(-f $progress, 'inspection producer independently records main entry');
    is(slurp($progress), "entered\n", 'the actual timeout control entered its fixture body') if -f $progress;
    ok($timeout->{cleanup}{term_sent} && $timeout->{cleanup}{kill_sent}, 'TERM-resistant fixture requires bounded KILL');
    ok($timeout->{cleanup}{leader_reaped} && $timeout->{cleanup}{group_gone}, 'deadline cleans the complete owned group');
    write_file($vm_stat, $vm_source);
};

done_testing();

sub write_file {
    my ($path, $contents) = @_;
    open my $fh, '>', $path or die "cannot write $path: $!";
    print {$fh} $contents or die "cannot write $path: $!";
    close $fh or die "cannot close $path: $!";
}

sub slurp {
    my ($path) = @_;
    open my $fh, '<', $path or die "cannot read $path: $!";
    my $contents = do { local $/; <$fh> };
    close $fh or die "cannot close $path: $!";
    return $contents;
}

sub shell_quote {
    my ($text) = @_;
    $text =~ s/'/'"'"'/g;
    return "'$text'";
}

sub progress_prefix {
    my ($progress) = @_;
    return "my \$progress = pack('H*', '" . unpack('H*', $progress) . "');\n"
        . 'open my $marker, q(>), $progress or die $!; print {$marker} "entered\n" or die $!; close $marker or die $!;' . "\n";
}

sub run_engine_probe {
    my ($name, $body) = @_;
    my $program = File::Spec->catfile($workspace, "engine-$name");
    write_file($program, "#!$perl\nuse strict; use warnings;\n$body\n");
    my $engine = FSM::Test::RamGuardFixtureRuntime->can('supervise_process');
    # Test-private mechanism injection: retain the admitted schema, fixed limits,
    # environment and result path, substituting only this owned hostile producer.
    # Public command rejection is qualified separately above; no test runner API
    # is added to the adapter and no production command changes.
    no warnings 'redefine';
    local *FSM::Test::RamGuardFixtureRuntime::supervise_process = sub {
        my %args = @_;
        is_deeply($args{bounds}, {timeout_seconds => 10, capture_limit_bytes => 1_048_576},
            "$name uses the actual adapter's fixed policy");
        $args{argv} = [$perl, $program];
        return $engine->(%args);
    };
    return run_ram_guard_fixture($workspace, $sample, 'healthy');
}
