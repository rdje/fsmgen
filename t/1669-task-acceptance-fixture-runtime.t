#!/usr/bin/env perl

use strict;
use warnings;

use Cwd qw(abs_path);
use File::Basename qw(dirname);
use File::Path qw(make_path);
use File::Spec;
use FindBin;
use Test::More;
use Time::HiRes qw(sleep);

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');
use lib File::Spec->catdir($FindBin::Bin, 'lib');

use FSM::ProjectDataLocality qw(create_project_tempdir);
use FSM::Test::ProjectDataLocality;
use FSM::Test::ProcessSupervisor qw(
    repository_root
    supervise_process
);
use FSM::Test::TaskAcceptanceFixtureRuntime qw(
    run_fixture_checker
    run_fixture_git
);

my $repo_root = repository_root();
my $perl = abs_path($^X)
    or die "cannot resolve the current Perl interpreter: $!";
my $workspace = create_project_tempdir(
    purpose => 'process-supervisor-tests',
);

subtest 'shared engine keeps one closed success contract' => sub {
    my $program = File::Spec->catfile($workspace, 'success');
    write_executable($program, <<'PROGRAM');
#!/usr/bin/env perl
use strict;
use warnings;
print STDOUT "stdout-ready\n";
print STDERR "stderr-ready\n";
exit 0;
PROGRAM
    my %environment_before = %ENV;
    my $result = supervise_process(
        schema => 'fsmgen.test.process_supervisor_probe.v1',
        stage => 'probe',
        bounds => {
            timeout_seconds => 1,
            capture_limit_bytes => 65_536,
        },
        containment => 'process_supervisor_probe_group',
        cwd => $workspace,
        argv => [$perl, $program],
    );
    is_deeply(\%ENV, \%environment_before, 'caller environment remains exact');
    ok($result->{ok}, 'supervised argv succeeds once');
    is($result->{schema}, 'fsmgen.test.process_supervisor_probe.v1', 'caller policy owns the result schema');
    is($result->{stage}, 'probe', 'caller policy owns the stage');
    is($result->{stdout}, "stdout-ready\n", 'stdout remains separate');
    is($result->{stderr}, "stderr-ready\n", 'stderr remains separate');
    is($result->{timeout_seconds}, 1, 'selected wall is explicit');
    is($result->{capture_limit_bytes}, 65_536, 'selected capture ceiling is explicit');
    is($result->{cleanup}{containment}, 'process_supervisor_probe_group', 'caller policy owns the containment label');
    ok($result->{cleanup}{leader_reaped}, 'leader is reaped');
    ok($result->{cleanup}{group_gone}, 'process group is gone');
};

subtest 'shared engine kills a TERM-resistant process tree at its wall' => sub {
    my $program = File::Spec->catfile($workspace, 'timeout');
    write_executable($program, <<'PROGRAM');
#!/usr/bin/env perl
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
$| = 1;
print STDOUT "descendant=$child\n";
sleep 60;
exit 0;
PROGRAM
    my $result = supervise_process(
        schema => 'fsmgen.test.process_supervisor_probe.v1',
        stage => 'probe',
        bounds => {
            timeout_seconds => 1,
            capture_limit_bytes => 65_536,
        },
        containment => 'process_supervisor_probe_group',
        cwd => $workspace,
        argv => [$perl, $program],
    );
    is($result->{status}, 'timed_out', 'first deadline remains failed');
    ok($result->{timed_out}, 'timeout evidence is explicit');
    ok($result->{cleanup}{term_sent}, 'TERM reaches the complete process group');
    ok($result->{cleanup}{kill_sent}, 'TERM resistance escalates to KILL');
    ok($result->{cleanup}{leader_reaped}, 'timed-out leader is reaped');
    ok($result->{cleanup}{group_gone}, 'timed-out group is proved gone');
    my ($descendant) = $result->{stdout} =~ /descendant=([0-9]+)/;
    ok(defined($descendant), 'hostile fixture reports its descendant');
    if (defined $descendant) {
        my $alive = 1;
        for (1 .. 100) {
            $alive = kill(0, $descendant) ? 1 : 0;
            last unless $alive;
            sleep(0.02);
        }
        ok(!$alive, 'hostile descendant leaves no process residue');
    }
};

subtest 'task-acceptance adapter seals path, command, interpreter, and bounds' => sub {
    my $fixture = create_project_tempdir(
        purpose => 'task-acceptance-tests',
    );
    my $path_trap = File::Spec->catdir($workspace, 'path-trap');
    make_path($path_trap);
    write_executable(File::Spec->catfile($path_trap, 'git'), "#!/bin/sh\nexit 97\n");
    write_executable(File::Spec->catfile($path_trap, 'bash'), "#!/bin/sh\nexit 98\n");
    local $ENV{PATH} = join(':', $path_trap, $ENV{PATH});
    my %environment_before = %ENV;
    my $git = run_fixture_git($fixture, ['init', '-q']);
    is_deeply(\%ENV, \%environment_before, 'fixture Git leaves the environment exact');
    ok($git->{ok}, 'load-time canonical Git ignores later PATH replacement');
    is($git->{schema}, 'fsmgen.test.task_acceptance_fixture_result.v1', 'fixture result schema is exact');
    is($git->{stage}, 'fixture_git', 'fixture Git stage is exact');
    is($git->{timeout_seconds}, 10, 'fixture Git wall cannot be widened');
    is($git->{capture_limit_bytes}, 1_048_576, 'fixture Git capture cannot be widened');
    is($git->{cleanup}{containment}, 'task_acceptance_fixture_process_group', 'fixture containment is exact');

    my $inadmissible = run_fixture_git($fixture, ['status']);
    is($inadmissible->{status}, 'invocation_error', 'unregistered Git subcommand fails closed');
    ok(!$inadmissible->{cleanup}{leader_started}, 'rejected Git command starts no process');
    my $global = run_fixture_git(
        $fixture, ['config', '--global', 'user.name', 'unsafe'],
    );
    is($global->{status}, 'invocation_error', 'global Git configuration fails closed');
    ok(!$global->{cleanup}{leader_started}, 'rejected global configuration starts no process');
    my $outside = run_fixture_git($repo_root, ['init', '-q']);
    is($outside->{status}, 'invocation_error', 'non-fixture repository fails closed');
    ok(!$outside->{cleanup}{leader_started}, 'rejected repository starts no process');

    my $checker = File::Spec->catfile(
        $fixture, 'scripts', 'check_task_acceptance.sh',
    );
    write_executable($checker, <<'CHECKER');
#!/usr/bin/env bash
set -u
values=()
for value in "${values[@]}"; do
  printf '%s\n' "${value}"
done
printf 'modern-bash-ready\n'
CHECKER
    my $checked = run_fixture_checker($fixture);
    ok($checked->{ok}, 'load-time canonical Bash ignores later PATH replacement and env handoff');
    is($checked->{stdout}, "modern-bash-ready\n", 'checker output is exact');
    is($checked->{stage}, 'task_acceptance_checker', 'checker stage is exact');
    is($checked->{timeout_seconds}, 10, 'checker wall cannot be widened');
    is($checked->{capture_limit_bytes}, 4_194_304, 'checker capture cannot be widened');

    write_executable($checker, "#!/usr/bin/env bash\nexit 7\n");
    my $failed = run_fixture_checker($fixture);
    is($failed->{status}, 'nonzero_exit', 'checker nonzero remains failed');
    is($failed->{exit_code}, 7, 'checker exit code is exact');
    ok($failed->{cleanup}{group_gone}, 'failed checker group is gone');
};

subtest 'policy adapters exclusively own low-level test supervision' => sub {
    my $t1545 = slurp(File::Spec->catfile(
        $repo_root, 't', '1545-task-acceptance-doctrine.t',
    ));
    unlike($t1545, qr/IPC::Cmd|run\s*\(\s*command\s*=>/, 't1545 has no direct IPC launch');
    like($t1545, qr/use FSM::Test::TaskAcceptanceFixtureRuntime qw\(/, 't1545 imports its sealed adapter');
    like($t1545, qr/\brun_fixture_git\s*\(/, 'fixture Git is adapter-owned');
    like($t1545, qr/\brun_fixture_checker\s*\(/, 'fixture checker is adapter-owned');

    my @owner;
    for my $path (glob File::Spec->catfile(
            $repo_root, qw(t lib FSM Test *.pm),
        )) {
        next if $path =~ /ProcessSupervisor\.pm\z/;
        my $source = slurp($path);
        push @owner, File::Spec->abs2rel($path, $repo_root)
            if $source =~ /\bsupervise_process\s*\(/;
    }
    is_deeply(
        [sort @owner],
        [qw(
            t/lib/FSM/Test/TaskAcceptanceFixtureRuntime.pm
            t/lib/FSM/Test/VerilatorRuntime.pm
        )],
        'only sealed policy adapters call the low-level supervisor',
    );

    my @direct_test;
    for my $path (glob File::Spec->catfile($repo_root, 't', '*.t')) {
        my $source = slurp($path);
        push @direct_test, File::Spec->abs2rel($path, $repo_root)
            if $source =~ /\bsupervise_process\s*\(/;
    }
    is_deeply(
        [sort @direct_test],
        ['t/1669-task-acceptance-fixture-runtime.t'],
        'only the hostile-process oracle bypasses a sealed policy adapter',
    );
};

done_testing();

sub write_executable {
    my ($path, $content) = @_;
    make_path(dirname($path));
    open my $fh, '>:raw', $path or die "cannot write $path: $!";
    print {$fh} $content or die "cannot populate $path: $!";
    close $fh or die "cannot close $path: $!";
    chmod 0755, $path or die "cannot make $path executable: $!";
}

sub slurp {
    my ($path) = @_;
    open my $fh, '<:raw', $path or die "cannot read $path: $!";
    local $/;
    my $source = <$fh>;
    close $fh or die "cannot close $path: $!";
    return $source;
}
