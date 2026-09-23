#!/usr/bin/env perl
use strict;
use warnings;
use Errno qw(EAGAIN ECHILD);
use POSIX qw(SIG_BLOCK SIG_UNBLOCK SIG_SETMASK SIGUSR1 SIGUSR2 SIGSTOP WNOHANG WUNTRACED WIFSTOPPED WSTOPSIG _exit);
use Scalar::Util qw(refaddr);
use Time::HiRes qw(sleep);
use Test::More;
use lib 'perl', 't/lib';
use FSM::Test::ProjectDataLocality;
use FSM::ProjectDataLocality qw(repository_root);
use FSM::Support::ProcessSupervisor::Coordinator ();

my $creator = $$;
my $class = 'FSM::Support::ProcessSupervisor::Coordinator';
my $reservation = 'FSM::Support::ProcessSupervisor::Reservation';
my $pair = 'FSM::Support::ProcessSupervisor::GatedPair';
my $admission = 'FSM::Support::ProcessSupervisor::Admission';
my (@owners, @pipes, @foreign, @retired, %births, %waits, $owner, $current, $role);
my %endpoints;
my ($signal_role, $refuse_role, $refusal, $fail_role, $clock_ns, $signal_reserve, $signal_pipe, $check_mask);
my ($checks, $forks, $pipe_calls) = (0, 0, 0);
my $native_now = $reservation->can('_now');
my $now_ns = $admission->can('_now_ns');
sub now { $native_now->() }
sub error_from { my ($code) = @_; local $@; eval { $code->(); 1 }; return $@ }
sub live { grep { defined(fileno($_)) } @_ }
sub census { [sort glob(repository_root() . '/.artifacts/tmp/process-coordinator/*')] }
sub snapshot {
    return FSM::Support::ProcessSupervisor::Wire::snapshot_request({
        argv => [$^X, '-e', 'syswrite STDOUT,"FORBIDDEN"'], cwd => '.',
        schema => 'private.coordinator.lifecycle.v1', stage => 'probe', containment => 'fixture-group',
        bounds => {timeout_seconds => 30, capture_limit_bytes => 64},
    }, $now_ns->());
}
sub create {
    my $o = FSM::Support::ProcessSupervisor::Coordinator::prepare(snapshot => snapshot());
    push @owners, $o; $o->open_run; $owner = $o;
    my $path = repository_root() . '/' . $o->{run}{directory};
    $endpoints{refaddr($o)} = [map { [$_, [lstat($_)]] } ("$path/s", $path)];
    return $o;
}
sub drive {
    my ($grant, $phase) = @_;
    my $end = now() + 5;
    while (now() < $end) {
        my $o = $owner->job_observation($grant);
        return if $o->{native}{phase} eq $phase;
        if ($o->{native}{phase} eq 'finished') {
            my $pid = $o->{native}{command}{command_pid} // $o->{native}{reservation}{pid};
            my $raw = defined($pid) && exists($waits{$pid}) ? $waits{$pid} : 'unobserved';
            die 'native lifecycle finished before expected state: ' . ($o->{failure} // '')
                . "; independent wait=$raw\n";
        }
        $owner->advance_job($grant); sleep(0.001);
    }
    die 'coordinator lifecycle observer wall expired';
}
sub ready {
    my ($grant) = @_;
    $current = $grant; $owner->prepare_job($grant); $owner->start_job($grant); drive($grant, 'ready');
    is($owner->job_observation($grant)->{admission}{phase}, 'active', 'actual ready handoff activates the original grant');
}
sub child {
    my ($parent) = @_;
    return $owner->reserve_job(parent => $parent, snapshot => snapshot());
}
sub close_owner {
    my ($o) = @_;
    my $end = now() + 5;
    my $result;
    while (now() < $end) {
        $result = $o->close;
        last if $result->{ok} || !$result->{pending};
        sleep(0.001);
    }
    ok($result->{ok}, 'bounded close settles original native resources and endpoint');
    is($o->observation->{usage}{jobs}, 0, 'whole-run close consumes retained outcome slots');
    is($o->observation->{usage}{charged_children}, 0, 'exact closure releases child credit');
    is($o->observation->{usage}{charged_descriptors}, 0, 'exact closure releases descriptor credit');
    ok(!live(@pipes), 'independent native pipe inventory is closed before rescue');
    ok(!grep(!$_, values %births), 'every observed direct wait is consumed before rescue');
    is_deeply($o->close, $result, 'completed whole-run close is idempotent');
}
sub reset_observers {
    die 'previous actual child remains unconsumed' if grep { !$_ } values %births;
    die 'previous actual pipe remains open' if live(@pipes);
    @pipes = (); @retired = (); @foreign = ();
    $signal_role = $refuse_role = $refusal = $fail_role = $clock_ns = undef;
    $signal_reserve = $signal_pipe = $check_mask = 0;
}
sub rescue {
    for my $pid (keys %births) {
        next if $births{$pid};
        my $w = CORE::waitpid($pid, WNOHANG);
        if ($w == $pid || ($w == -1 && $! == ECHILD)) { $births{$pid} = 1; next; }
        die 'independent fixture lost exact child ownership' unless $w == 0;
        CORE::kill('KILL', $pid);
        my $end = now() + 2;
        while (now() < $end) {
            $w = CORE::waitpid($pid, WNOHANG);
            if ($w == $pid) { $births{$pid} = 1; last; }
            die 'independent fixture lost exact rescue wait' if $w == -1;
            sleep(0.001);
        }
        die 'independent fixture rescue wall expired' unless $births{$pid};
    }
}
END {
    local $?;
    if ($$ == $creator) {
        alarm 0;
        my $needed = grep { !$_ } values %births;
        rescue(); diag('independent lifecycle fixture rescued direct children') if $needed;
        close $_ for live(@pipes);
        # A broken owner never earns completion from this exact fixture-only
        # endpoint teardown. Preserve its failed ledger for the test verdict.
        for my $o (@owners) {
            next if $o->{phase} eq 'closed' || !$o->{run};
            my $closed = $o->{run}->close;
            unless ($closed->{ok}) {
                my $entries = $endpoints{refaddr($o)} or die 'fixture lacks original endpoint identities';
                for my $entry (@$entries) {
                    my ($path, $original) = @$entry; my @actual = lstat($path);
                    next unless @actual;
                    die 'original fixture endpoint identity changed' unless @$original
                        && $actual[0] == $original->[0] && $actual[1] == $original->[1]
                        && $actual[2] == $original->[2] && $actual[4] == $original->[4];
                    if (-d _) { rmdir($path) or die 'cannot remove exact empty fixture directory'; }
                    else { unlink($path) == 1 or die 'cannot remove exact original fixture socket'; }
                }
                die 'independent original endpoint rescue left residue'
                    if grep { lstat($_->[0]) } @$entries;
                die 'independent original endpoint rescue left handles' if @{$o->{run}->handles};
                diag('independent identity-checked endpoint teardown preserved the failed owner verdict');
            }
        }
    }
}

my $rfork = $reservation->can('_fork'); my $cfork = $pair->can('_fork');
my $rwait = $reservation->can('_wait'); my $cwait = $pair->can('_wait');
my $pipe = $reservation->can('_pipe'); my $byte = $reservation->can('_child_byte');
my $command_child = $pair->can('_child'); my $fork_check = $class->can('_before_job_fork');
my $reserve = $admission->can('reserve_job'); my $retire = $admission->can('retire');
my $native_cancel = FSM::Support::ProcessSupervisor::ReservedJob->can('cancel');
my $fork = sub {
    my ($which, $native) = @_;
    die 'native fork lacks the latest original grant check' unless defined($role) && $role eq $which;
    $role = undef;
    if (defined($fail_role) && $fail_role eq $which) { $! = EAGAIN; return undef; }
    my $pid = $native->();
    if (defined($pid) && $pid > 0) {
        $births{$pid} = 0; ++$forks;
        CORE::kill('USR1', $$) == 1 or die 'cannot queue actual creator interruption'
            if defined($signal_role) && $signal_role eq $which;
    }
    return $pid;
};
my $wait = sub {
    my ($native, $pid) = @_;
    die 'native owner waited for an unobserved child' unless exists $births{$pid};
    my $w = $native->($pid);
    if ($w == $pid) { $waits{$pid} = $?; $births{$pid} = 1; }
    return $w;
};
no warnings 'redefine';
local *FSM::Support::ProcessSupervisor::Admission::_now_ns = sub { $clock_ns // $now_ns->() };
local *FSM::Support::ProcessSupervisor::Coordinator::_now_ns = sub { $clock_ns // $now_ns->() };
local *FSM::Support::ProcessSupervisor::Reservation::_now = sub { defined($clock_ns) ? $clock_ns / 1e9 : now() };
local *FSM::Support::ProcessSupervisor::Reservation::_pipe = sub {
    ++$pipe_calls;
    my $ok = $pipe->(@_); push @pipes, ${$_[0]}, ${$_[1]} if $ok;
    CORE::kill('USR1', $$) == 1 or die 'cannot queue pipe publication interruption' if $signal_pipe;
    return $ok;
};
local *FSM::Support::ProcessSupervisor::Reservation::_fork = sub { $fork->('reservation', $rfork) };
local *FSM::Support::ProcessSupervisor::GatedPair::_fork = sub { $fork->('command', $cfork) };
local *FSM::Support::ProcessSupervisor::Reservation::_wait = sub { $wait->($rwait, @_) };
local *FSM::Support::ProcessSupervisor::GatedPair::_wait = sub { $wait->($cwait, @_) };
local *FSM::Support::ProcessSupervisor::Reservation::_child_byte = sub {
    _exit(91) if live(@foreign);
    return $byte->(@_);
};
local *FSM::Support::ProcessSupervisor::GatedPair::_child = sub {
    if ($check_mask) {
        _exit(92) unless $_[0]{exec_mask}->ismember(SIGUSR1)
            && !$_[0]{exec_mask}->ismember(SIGUSR2) && $_[0]{dispositions}{USR2} eq 'IGNORE';
    }
    return $command_child->(@_);
};
local *FSM::Support::ProcessSupervisor::Coordinator::_before_job_fork = sub {
    my ($self, $grant, $which) = @_;
    ++$checks;
    if (defined($refuse_role) && $refuse_role eq $which) {
        $self->cancel_job($grant, 'fixture cancels before native fork') if $refusal eq 'cancel';
        $clock_ns = $self->job_observation($grant)->{admission}{deadline_ns} if $refusal eq 'expire';
    }
    my $inventory = $fork_check->(@_);
    my $view = $self->job_observation($grant)->{admission};
    die 'fork lacks conservative child credit' unless $view->{phase} eq 'starting' && $view->{reserved_children} == 2;
    my $id = $view->{id};
    # This independent inventory is retained in each real child. The child-side
    # acknowledgment observer fails if any other job/run handle stays open.
    @foreign = (@{$self->{run}->handles}, map {
        $_ == $id || !$self->{jobs}{$_}{native} ? () : @{$self->{jobs}{$_}{native}->handles}
    } keys %{$self->{jobs}});
    is_deeply([sort map { refaddr($_) } @$inventory], [sort map { refaddr($_) } @foreign],
        'native hook returns the exact current foreign ownership');
    $role = $which;
    return $inventory;
};
local *FSM::Support::ProcessSupervisor::Admission::reserve_job = sub {
    my $g = $reserve->(@_);
    CORE::kill('USR1', $$) == 1 or die 'cannot queue reserve publication interruption' if $signal_reserve;
    return $g;
};
local *FSM::Support::ProcessSupervisor::Admission::retire = sub {
    push @retired, $_[0]->describe($_[1])->{id}; return $retire->(@_);
};
local *FSM::Support::ProcessSupervisor::ReservedJob::cancel = sub {
    my ($native) = @_;
    for my $g (@{$owner->grants}) {
        my $v = $owner->job_observation($g);
        next unless $owner->{jobs}{$v->{admission}{id}}{native}
            && refaddr($owner->{jobs}{$v->{admission}{id}}{native}) == refaddr($native);
        die 'native cancellation precedes ledger revocation' if $v->{admission}{accepting};
    }
    return $native_cancel->(@_);
};
local *FSM::Support::ProcessSupervisor::ReservedJob::release = sub { die 'coordinator must not release exec' };
use warnings 'redefine';
local $SIG{ALRM} = sub { die "coordinator lifecycle fixture deadline\n" };
alarm 60;

subtest 'root and nested real handoffs retain original grants and fresh inventories' => sub {
    reset_observers(); my $before = census(); create(); my $root = $owner->root;
    local $SIG{USR2} = 'IGNORE'; my $old = POSIX::SigSet->new;
    defined POSIX::sigprocmask(SIG_UNBLOCK, POSIX::SigSet->new(SIGUSR2), $old) or die 'cannot select original mask';
    defined POSIX::sigprocmask(SIG_BLOCK, POSIX::SigSet->new(SIGUSR1)) or die 'cannot select original blocked signal';
    $check_mask = 1; ready($root);
    my $request = snapshot(); my $nested = $owner->reserve_job(parent => $root, snapshot => $request);
    $request->{argv}[2] = 'changed caller snapshot';
    is($owner->{jobs}{2}{snapshot}{argv}[2], 'syswrite STDOUT,"FORBIDDEN"', 'retained nested snapshot is detached from its caller');
    my $other = child($root);
    $current = $nested; $owner->prepare_job($nested); $owner->start_job($nested);
    $owner->prepare_job($other); # later foreign descriptors must reach command child
    drive($nested, 'ready');
    my $grandchild = child($nested); ready($grandchild);
    defined POSIX::sigprocmask(SIG_SETMASK, $old) or die 'cannot restore original mask'; $check_mask = 0;
    is($owner->observation->{usage}{children}, 6, 'three ready pairs account for six actual retained children');
    is($owner->observation->{usage}{reserved_children}, 2, 'unstarted sibling keeps its future child credit');
    my @witness;
    for my $g ($root, $nested, $grandchild) {
        my $id = $owner->job_observation($g)->{admission}{id};
        open my $fh, '<&', $owner->{jobs}{$id}{native}{received}{stdout} or die 'cannot retain native execution witness';
        push @witness, $fh;
    }
    $owner->cancel_job($nested, 'cancel selected subtree');
    ok($owner->job_observation($root)->{admission}{accepting}, 'nested cancellation preserves root admission');
    ok($owner->job_observation($other)->{admission}{accepting}, 'nested cancellation preserves unrelated sibling');
    ok(!$owner->job_observation($grandchild)->{admission}{accepting}, 'descendant is revoked with its parent');
    my $wall = $owner->job_observation($nested)->{cleanup_deadline};
    is($owner->job_observation($grandchild)->{cleanup_deadline}, $wall, 'affected subtree shares exactly one remaining wall');
    $owner->cancel_job($root, 'close root subtree');
    is($owner->job_observation($root)->{native}{cleanup_deadline}, $wall, 'ancestor cancellation inherits already-running shorter cleanup');
    close_owner($owner);
    is_deeply(\@retired, [4, 3, 2, 1], 'descendant outcomes retire before their original parent');
    for my $fh (@witness) { is(sysread($fh, my $bytes, 32), 0, 'independent native EOF proves no exec output'); close $fh; }
    is_deeply(census(), $before, 'exact original endpoint census is restored');
};

subtest 'copied grants and aggregate capacity refuse before native effects' => sub {
    reset_observers(); create(); my $root = $owner->root; ready($root);
    my $copy = bless {}, ref($root); my $before = [$pipe_calls, $forks];
    like(error_from(sub { child($copy) }), qr/foreign, copied or retired/, 'copied parent has no admission authority');
    like(error_from(sub { $owner->start_job($copy) }), qr/foreign, copied or retired/, 'copied start grant has no authority');
    like(error_from(sub { $owner->_before_job_fork($copy, 'command') }), qr/foreign, copied or retired/, 'fork boundary independently rejects a copied original grant');
    my @nested = map { child($root) } 1 .. 7;
    is($owner->observation->{usage}{jobs}, 8, 'inclusive retained job capacity is admitted');
    like(error_from(sub { child($root) }), qr/job capacity exhausted/, 'first excess retained job rejects');
    is_deeply([$pipe_calls, $forks], $before, 'pure refusals and reservations allocate no native resources');
    $owner->cancel_job($nested[0], 'cancel unused nested slot');
    like(error_from(sub { child($root) }), qr/job capacity exhausted/, 'cancelled result keeps its logical slot until consumed');
    close_owner($owner);
    reset_observers(); create(); ready($owner->root);
    my $used = $owner->observation->{usage}{charged_descriptors};
    $owner->{ledger}->reserve_descriptors(128 - $used - 16);
    my $g = child($owner->root);
    is($owner->observation->{usage}{charged_descriptors}, 128, 'nested peak reserves the exact aggregate descriptor boundary');
    $before = [$pipe_calls, $forks];
    like(error_from(sub { child($owner->root) }), qr/descriptor capacity exhausted/, 'next nested peak rejects descriptor excess');
    is_deeply([$pipe_calls, $forks], $before, 'descriptor refusal occurs before native effects');
    ready($g); close_owner($owner);
};

subtest 'cancellation expiry and native failures retain each partial start' => sub {
    for my $which (qw(reservation command)) {
        for my $mode (qw(cancel expire fork)) {
            reset_observers(); create(); ready($owner->root); my $g = child($owner->root);
            $current = $g; $owner->prepare_job($g); my $before = $forks;
            if ($mode eq 'fork') { $fail_role = $which; }
            else { $refuse_role = $which; $refusal = $mode; }
            my $error = error_from(sub { $owner->start_job($g); drive($g, 'ready'); });
            $clock_ns = undef; $refuse_role = $fail_role = undef;
            like($error, qr/admission revoked|deadline expired|cannot fork|finished before expected/,
                "$mode refuses $which before actual child creation");
            is($forks - $before, $which eq 'reservation' ? 0 : 1, 'only admitted earlier direct child exists');
            is($owner->job_observation($g)->{admission}{phase}, 'closing', 'failed nested start revokes its original grant');
            is($owner->job_observation($g)->{admission}{reserved_children}, 2, 'partial start conservatively retains both child slots');
            is($owner->observation->{phase}, 'open', 'nested failure does not poison root context');
            $owner->context;
            close_owner($owner);
        }
    }
};

subtest 'pending native fork interruption exposes retained identity before cleanup' => sub {
    for my $which (qw(reservation command)) {
        reset_observers(); create(); ready($owner->root); my $g = child($owner->root);
        $current = $g; $owner->prepare_job($g); $signal_role = $which;
        my ($published, $credit);
        local $SIG{USR1} = sub {
            my $v = $owner->job_observation($g);
            $published = $which eq 'reservation' ? $v->{native}{reservation}{pid} : $v->{native}{command}{command_pid};
            $credit = $v->{admission}{reserved_children}; die "interrupted original $which return\n";
        };
        my $old = POSIX::SigSet->new;
        defined POSIX::sigprocmask(SIG_UNBLOCK, POSIX::SigSet->new(SIGUSR1), $old) or die 'cannot select interruption mask';
        my $error = error_from(sub { $owner->start_job($g); drive($g, 'ready'); });
        defined POSIX::sigprocmask(SIG_SETMASK, $old) or die 'cannot restore interruption mask';
        $signal_role = undef;
        like($error, qr/interrupted original/, 'actual pending creator interruption propagates');
        ok($published && exists($births{$published}), 'handler sees exact native identity before return interruption');
        is($credit, 2, 'handler sees conservative credit for both potential children');
        like($owner->job_observation($g)->{failure}, qr/interrupted original/, 'first creator failure remains retained');
        close_owner($owner);
    }
};

subtest 'pending nested publication retains detached requests and failed preparation' => sub {
    for my $mode (qw(reserve prepare)) {
        reset_observers(); create(); ready($owner->root); my $g;
        $g = child($owner->root) if $mode eq 'prepare';
        my ($seen, $phase);
        local $SIG{USR1} = sub {
            my $grants = $owner->grants; $seen = $grants->[-1];
            $phase = $owner->job_observation($seen)->{admission}{phase};
            die "interrupted nested $mode publication\n";
        };
        my $old = POSIX::SigSet->new;
        defined POSIX::sigprocmask(SIG_UNBLOCK, POSIX::SigSet->new(SIGUSR1), $old) or die 'cannot select publication mask';
        $signal_reserve = $mode eq 'reserve'; $signal_pipe = $mode eq 'prepare';
        my $error = error_from(sub { $mode eq 'reserve' ? child($owner->root) : $owner->prepare_job($g) });
        defined POSIX::sigprocmask(SIG_SETMASK, $old) or die 'cannot restore publication mask';
        $signal_reserve = $signal_pipe = 0;
        like($error, qr/interrupted nested/, 'real pending signal interrupts nested publication return');
        is($phase, $mode eq 'reserve' ? 'reserved' : 'prepared', 'handler observes completed original publication');
        is($owner->job_observation($seen)->{admission}{id}, 2, 'unreturned original grant remains reachable');
        is($owner->job_observation($seen)->{admission}{phase}, 'closing', 'interrupted return revokes the original nested grant');
        is($owner->observation->{phase}, 'open', 'interrupted nested return preserves root admission');
        close_owner($owner);
    }
};

subtest 'bounded close retains charges while a real stopped descendant remains' => sub {
    local $SIG{TERM} = 'IGNORE';
    reset_observers(); create(); my $root = $owner->root; ready($root);
    my $g = child($root); ready($g);
    my $native = $owner->{jobs}{2}{native};
    my $pid = $native->observation->{command}{command_pid};
    die 'stop lacks an independently recorded child' unless exists($births{$pid}) && !$births{$pid};
    CORE::kill('STOP', $pid) == 1 or die 'cannot stop the exact owned child';
    my ($stopped, $end) = (0, now() + 2);
    while (now() < $end) {
        my $w = CORE::waitpid($pid, WNOHANG | WUNTRACED);
        my $status = ${^CHILD_ERROR_NATIVE};
        if ($w == $pid) {
            die 'stop observer unexpectedly consumed an exit' unless WIFSTOPPED($status) && WSTOPSIG($status) == SIGSTOP;
            $stopped = 1; last;
        }
        die 'stop observer lost exact child ownership' if $w == -1;
        sleep(0.001);
    }
    ok($stopped, 'independent native wait observes the actual stopped command');
    my $usage = $owner->observation->{usage};
    my $began = now(); my $result = $owner->close;
    ok(now() - $began < 0.5, 'one close step does not wait for the stopped child grace');
    ok(!$result->{ok} && $result->{pending}, 'unfinished native cleanup reports pending');
    is_deeply($owner->observation->{usage}, $usage, 'pending closure releases neither resource nor outcome credit');
    is(scalar @{$owner->{run}->handles}, 2, 'endpoint remains retained while native cleanup is pending');
    my $short = now() + 0.8;
    $native->cancel('earlier retained native cleanup', $short);
    my $first = $native->observation->{first_failure};
    $owner->cancel_job($root, 'ancestor must respect native remaining wall');
    is($owner->job_observation($root)->{native}{cleanup_deadline}, $short,
        'native earlier wall propagates to the already-running ancestor cleanup');
    close_owner($owner);
    is($waits{$pid} & 127, 9, 'exact independently observed wait proves stopped child KILL');
    cmp_ok(now(), '<', $short, 'exact waits and endpoint closure complete within the clipped wall');
    is_deeply($native->observation->{first_failure}, $first, 'shared-wall clipping preserves native first failure');
};

subtest 'settled descendant clocks do not expire later live cleanup' => sub {
    reset_observers(); create(); my $root = $owner->root; ready($root);
    my $g = child($root); ready($g);
    $owner->cancel_job($g, 'finish nested outcome before root'); drive($g, 'finished');
    my $native = $owner->{jobs}{2}{native};
    ok($native->finished_job->{resources_closed}, 'descendant native cleanup is actually settled');
    is($owner->observation->{usage}{jobs}, 2, 'settled descendant retains its logical result slot');
    my $spent = $native->observation->{cleanup_deadline};
    # Only the parent's decision clock is advanced; real waited identities and
    # descriptors stay unchanged. This falsifies expired-clock reuse without
    # creating a fake native process or waiting out an otherwise idle grace.
    $clock_ns = sprintf('%.0f', ($spent + 0.1) * 1e9);
    $owner->cancel_job($root, 'later root cancellation');
    cmp_ok($owner->job_observation($root)->{native}{cleanup_deadline}, '>', $spent,
        'already consumed descendant wall cannot expire the remaining live parent');
    close_owner($owner); $clock_ns = undef;
};

done_testing;
