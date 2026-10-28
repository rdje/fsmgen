use strict;
use warnings;
use Cwd qw(abs_path);
use File::Spec;
use Test::More;
use lib 'perl', 't/lib';
use FSM::ProjectDataLocality qw(create_project_tempdir repository_root);
use FSM::Test::ProjectDataLocality;
use FSM::Test::ProcessSupervisor qw(supervise_process);
use FSM::Test::RamGuardFixtureRuntime qw(prepare_ram_guard_fixture);

my $root = repository_root();
my $perl = abs_path($^X);
my $bash = executable('bash');
my $ps = executable('ps');
my $guard = "$root/scripts/run_with_ram_guard.sh";
my @tools = File::Spec->path();

sub run_case {
    my ($mode, $launcher) = @_;
    my $work = create_project_tempdir(purpose => 'ram-guard-tests');
    prepare_ram_guard_fixture($work);
    write_file("$work/healthy", sample(400, 300, 20, 100, 20, 300, 50));
    write_file("$work/high", sample(500, 250, 20, 150, 10, 50, 100));
    write_file("$work/fake-bin/vm_stat", "#!$perl\n" . <<'VM');
use strict; use warnings;
my $w = $ENV{FSMGEN_CONTAINMENT_WORK};
my $high = $ENV{FSMGEN_CONTAINMENT_MODE} eq 'preflight'
    || (-e "$w/child-ready" && $ENV{FSMGEN_CONTAINMENT_MODE} eq 'late-fork')
    || (-e "$w/ready" && $ENV{FSMGEN_CONTAINMENT_MODE} eq 'term-fork');
open my $f, '<', "$w/" . ($high ? 'high' : 'healthy') or die $!;
print while <$f>;
VM
    write_file("$work/fake-bin/ps", "#!$perl\n" . <<'PS');
use strict; use warnings; use Time::HiRes qw(sleep);
my $w = $ENV{FSMGEN_CONTAINMENT_WORK};
my $mode = $ENV{FSMGEN_CONTAINMENT_MODE};
if ($mode eq 'orphan-rss' && @ARGV == 4 && $ARGV[0] eq '-o' && $ARGV[1] eq 'rss='
        && -f "$w/child-ready") {
    open my $f, '<', "$w/child-ready" or die $!; my $pid = <$f>; close $f;
    if (0 + $pid == $ARGV[3]) { print "4194304\n"; exit 0 }
}
open my $real, '-|', $ENV{FSMGEN_REAL_PS}, @ARGV or die $!;
my $rows = do { local $/; <$real> }; close $real or exit 1;
# Freeze the actual census, then force the payload to fork before that census
# is returned. Both PPID and group implementations see the identical stale view.
if ($ARGV[0] eq '-axo' && -f "$w/ready" && !-e "$w/injected"
        && $mode =~ /\A(?:late-fork|monitor-TERM|monitor-KILL)\z/) {
    open my $once, '>', "$w/injected" or die $!; close $once;
    if ($mode eq 'late-fork') {
        open my $f, '<', "$w/ready" or die $!; my $pid = <$f>; close $f;
        kill 'USR1', 0 + $pid or die $!;
        for (1..200) { last if -e "$w/child-ready"; sleep 0.01 }
        die 'child did not enter' unless -e "$w/child-ready";
    } else {
        open my $f, '<', "$w/monitor" or die $!; my $pid = <$f>; close $f;
        kill substr($mode, 8), 0 + $pid or die $!;
    }
}
print $rows;
PS
    chmod 0755, "$work/fake-bin/ps", "$work/fake-bin/vm_stat" or die $!;
    write_file("$work/payload.pl", <<'PAYLOAD');
use strict; use warnings; use Time::HiRes qw(sleep);
my $w = $ENV{FSMGEN_CONTAINMENT_WORK};
my $mode = $ENV{FSMGEN_CONTAINMENT_MODE};
sub mark { open my $f, '>', "$w/$_[0]" or die $!; print {$f} "$$\n"; close $f or die $! }
sub child {
    $SIG{TERM} = 'IGNORE';
    # The failure control must not hold capture pipes open or run indefinitely.
    close STDIN; close STDOUT; close STDERR;
    mark('child-ready');
    sleep($mode eq 'parent-exit' ? 0.3 : 2);
    mark('child-finished');
    exit 0;
}
if ($mode eq 'parent-exit' || $mode eq 'orphan-rss') {
    my $pid = fork(); die $! unless defined $pid;
    if (!$pid) { require POSIX; POSIX::setpgid(0, 0) == 0 or die $!; child(); }
    exit 17;
}
$SIG{USR1} = sub { my $pid = fork(); die $! unless defined $pid; child() unless $pid; };
$SIG{TERM} = sub {
    if ($mode eq 'term-fork') {
        my $pid = fork(); die $! unless defined $pid;
        if (!$pid) { require POSIX; POSIX::setpgid(0, 0) == 0 or die $!; child(); }
        for (1..100) { last if -e "$w/child-ready"; sleep 0.001 }
    }
    exit 0;
};
mark('ready');
sleep 0.01 for 1..500;
PAYLOAD
    local %ENV = %ENV;
    delete @ENV{grep { /\ABASH_FUNC_/ } keys %ENV};
    delete @ENV{qw(BASH_ENV ENV SHELLOPTS BASHOPTS CDPATH GLOBIGNORE)};
    $ENV{PATH} = join(':', "$work/fake-bin", @tools);
    $ENV{FSMGEN_TEST_TOTAL_BYTES} = 4_096_000;
    $ENV{FSMGEN_CONTAINMENT_WORK} = $work;
    $ENV{FSMGEN_CONTAINMENT_MODE} = $mode;
    $ENV{FSMGEN_REAL_PS} = $ps;
    my $result = supervise_process(
        schema => 'fsmgen.test.ram_containment.v1', stage => 'guard_containment',
        containment => 'fixture_outer_group', cwd => $root,
        bounds => { timeout_seconds => 10, capture_limit_bytes => 1_048_576 },
        argv => [$bash, '-c', 'printf "%s\n" "$$" > "$1/monitor"; shift; exec "$@"',
            'containment-monitor', $work, $bash, $launcher // $guard,
            '--poll-seconds', '0.02', '--grace-seconds', '0.05', '--', $perl, "$work/payload.pl"],
    );
    return ($result, $work);
}

subtest 'late fork after a frozen census is killed with its owned group' => sub {
    my ($r, $w) = run_case('late-fork');
    is($r->{exit_code}, 137, 'actual host cutoff remains exit 137') or diag explain $r;
    ok(-f "$w/injected" && -f "$w/child-ready", 'child actually forks after the frozen census');
    ok(!live_child($w), 'TERM-resistant late child is gone at guard return');
    ok(!-e "$w/child-finished", 'child cannot complete after the cutoff');
    like($r->{stderr}, qr/terminating owned session/, 'actual group cleanup executes');
};

subtest 'a TERM handler cannot orphan a newly forked nested group' => sub {
    my ($r, $w) = run_case('term-fork');
    is($r->{exit_code}, 137, 'cutoff remains a failed run') or diag explain $r;
    ok(-f "$w/child-ready", 'TERM handler actually creates the late nested group');
    ok(!live_child($w), 'freeze-and-rescan reaches the new TERM-resistant member');
    ok(!-e "$w/child-finished", 'late child cannot finish unmonitored');
};

subtest 'early command exit retains status and monitors remaining children' => sub {
    my ($r, $w) = run_case('parent-exit');
    is($r->{exit_code}, 17, 'exact original command exit is preserved') or diag explain $r;
    ok(-f "$w/child-finished", 'guard waits for the actual orphaned child');
    ok(!live_child($w), 'no active child remains at guard return');
};

subtest 'orphaned nested process groups remain under the unchanged RSS cutoff' => sub {
    my ($r, $w) = run_case('orphan-rss');
    is($r->{exit_code}, 137, 'actual orphan RSS inspection trips at the existing cutoff') or diag explain $r;
    ok(-f "$w/child-ready", 'nested-group child actually enters');
    like($r->{stderr}, qr/RSS 4096[.]0 MiB reached cutoff 4096 MiB/, 'independent RSS fixture selects the actual orphan PID');
    ok(!live_child($w), 'TERM-resistant orphan in its own group is gone');
};

subtest 'monitor cancellation and untrappable monitor loss clean their groups' => sub {
    for my $signal (qw(TERM KILL)) {
        my ($r, $w) = run_case("monitor-$signal");
        ok(-f "$w/injected" && -f "$w/ready", "$signal control enters the actual payload");
        if ($signal eq 'TERM') {
            is($r->{exit_code}, 143, 'trapped cancellation preserves its shell status');
        } else {
            is($r->{signal}, 9, 'hard monitor loss remains a signal');
        }
        # The private leader detects parent loss on its next bounded poll.
        for (1..100) { last unless live_pid_file("$w/ready"); select undef, undef, undef, 0.01 }
        ok(!live_pid_file("$w/ready"), "$signal leaves no active payload");
        ok($r->{cleanup}{leader_reaped} && $r->{cleanup}{group_gone}, 'unrelated outer supervisor survives and cleans its own group');
    }
};

subtest 'high startup refuses before any payload is launched' => sub {
    my ($r, $w) = run_case('preflight');
    is($r->{exit_code}, 137, 'unchanged high sample refuses with trip status');
    ok(!-e "$w/ready", 'payload never starts');
    like($r->{stderr}, qr/before command launch/, 'preflight refusal is explicit');
};

done_testing();

sub live_child { return live_pid_file("$_[0]/child-ready") }
sub live_pid_file {
    my ($file) = @_;
    return 0 unless -f $file;
    open my $f, '<', $file or die $!; my $pid = <$f>; close $f;
    chomp $pid; die 'invalid owned PID' unless $pid =~ /\A[1-9][0-9]*\z/;
    open my $p, '-|', $ps, '-o', 'stat=', '-p', $pid or die $!;
    my $state = do { local $/; <$p> }; close $p;
    return defined($state) && $state =~ /\S/ && $state !~ /\A\s*Z/;
}
sub write_file {
    my ($path, $bytes) = @_;
    open my $f, '>', $path or die $!; print {$f} $bytes or die $!; close $f or die $!;
}
sub sample {
    my @n = @_;
    my @keys = ('Pages active', 'Pages inactive', 'Pages speculative', 'Pages wired down',
        'Pages purgeable', 'File-backed pages', 'Pages occupied by compressor');
    return "Mach Virtual Memory Statistics: (page size of 4096 bytes)\n"
        . join('', map { "$keys[$_]: $n[$_].\n" } 0..$#keys);
}
sub executable {
    my ($name) = @_;
    for my $dir (File::Spec->path()) {
        my $p = "$dir/$name"; return abs_path($p) if -f $p && -x $p;
    }
    die "$name unavailable";
}
