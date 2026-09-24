#!/usr/bin/env perl
use strict;
use warnings;
use Cwd qw(getcwd);
use Errno qw(EAGAIN EINTR ECHILD);
use POSIX qw(SIG_BLOCK SIG_SETMASK SIGUSR1 SIGUSR2 WNOHANG _exit);
use Scalar::Util qw(refaddr weaken);
use Time::HiRes qw(CLOCK_MONOTONIC clock_gettime sleep);
use Test::More;
use lib 'perl', 't/lib';
use FSM::Test::ProjectDataLocality;
use FSM::ProjectDataLocality qw(repository_root);
use FSM::Support::ProcessSupervisor::Coordinator ();

my $creator = $$;
my $key = 'FSMGEN_PROCESS_COORDINATOR_CONTEXT';
my (@owners, @pipes, @witnesses, %births, @checks, @write_masks);
my ($owner, $mode, $queue_cut, $before_mask, $clock, $mask_failed, $context_cut);
my ($attempts, $writes, $deferrals) = (0, 0, 0);
our $in_execution_check;
sub now { clock_gettime(CLOCK_MONOTONIC) }
sub error_from { my ($code) = @_; local $@; eval { $code->(); 1 }; return $@ }
sub live { grep { defined($_) && defined(fileno($_)) } @_ }
sub census { [sort glob(repository_root() . '/.artifacts/tmp/process-coordinator/*')] }
my $initial = census();
sub mask_state {
    my $old = POSIX::SigSet->new;
    defined POSIX::sigprocmask(SIG_BLOCK, POSIX::SigSet->new, $old) or die 'cannot read root mask';
    return [$old->ismember(SIGUSR1) ? 1 : 0, $old->ismember(SIGUSR2) ? 1 : 0];
}
sub snapshot {
    return {type => 'SPAWN', started_ns => sprintf('%.0f', now() * 1e9),
        schema => 'root.execution', stage => 'probe', containment => 'fixture-group', cwd => '.',
        umask => 0027, timeout_seconds => 30, capture_limit_bytes => 4096,
        argv => [$^X, '-MPOSIX', '-MCwd=getcwd', '-e',
            'my $s=POSIX::SigSet->new; POSIX::sigprocmask(POSIX::SIG_BLOCK(),POSIX::SigSet->new,$s); my @v=("ROOT",@ARGV,$ENV{A},$ENV{FSMGEN_PROCESS_COORDINATOR_CONTEXT},$ENV{FSMGEN_PROCESS_COORDINATOR_CONTEXT_OTHER},$ENV{Z},getcwd(),sprintf("%04o",umask),$s->ismember(POSIX::SIGUSR1())?1:0,$s->ismember(POSIX::SIGUSR2())?1:0); my $out=join("",map { pack("N",length($_)).$_ } @v); syswrite STDOUT,$out;',
            '', "space\n\xff"],
        environment => [['A', ''], [$key, 'obsolete'], [$key . '_OTHER', 'keep'], ['Z', "value\n\xff"]]};
}
sub prepare {
    my $s = snapshot();
    my $o = FSM::Support::ProcessSupervisor::Coordinator::prepare(snapshot => $s);
    push @owners, $o; return $o;
}
sub reset_hooks {
    $mode = $queue_cut = $context_cut = '';
    $before_mask = $clock = $mask_failed = undef; $deferrals = 0;
}
sub drive {
    my ($o, $phase, $grant) = @_; $grant //= $o->root; my $end = now() + 5;
    while (now() < $end) {
        my $v = $o->job_observation($grant);
        return $v if $v->{native}{phase} eq $phase;
        die "root finished before $phase" if $v->{native}{phase} eq 'finished';
        $o->advance_job($grant); sleep(0.001);
    }
    die "root observer expired before $phase";
}
sub ready {
    die 'prior root pipes survive' if live(@pipes);
    die 'prior root children survive' if grep { !$_ } values %births;
    reset_hooks(); @pipes = (); @checks = (); @write_masks = (); $attempts = $writes = 0;
    $owner = prepare(); $owner->open_run;
    $owner->prepare_job($owner->root); $owner->start_job($owner->root);
    drive($owner, 'ready');
    open my $witness, '<&', $owner->{jobs}{1}{native}{received}{stdout}
        or die 'cannot retain root execution witness';
    push @witnesses, $witness;
    return $owner;
}
sub expected {
    my ($context) = @_;
    return join('', map { pack('N', length($_)) . $_ }
        'ROOT', '', "space\n\xff", '', $context, 'keep', "value\n\xff", getcwd(), '0027', 1, 0);
}
sub finish {
    my ($o, $no_exec) = @_; reset_hooks();
    my $native = $o->{jobs}{1}{native};
    my ($closed, $end) = (undef, now() + 5);
    while (now() < $end) { $closed = $o->close; last unless $closed->{pending}; sleep(0.001); }
    ok($closed && $closed->{ok}, 'original aggregate cleanup completes');
    is($o->observation->{usage}{charged_descriptors}, 0, 'original descriptor credit retires');
    is($o->observation->{usage}{charged_children}, 0, 'original child credit retires');
    ok(!live(@pipes), 'independent weak pipe inventory closes');
    ok(!grep(!$_, values %births), 'every actual child has its exact consumed wait');
    for my $pid (keys %births) {
        my $w = CORE::waitpid($pid, WNOHANG); my $errno = 0 + $!;
        is($w, -1, 'independent exact wait finds no child'); is($errno, ECHILD, 'exact wait is consumed');
    }
    for my $witness (live(@witnesses)) {
        is(sysread($witness, my $part, 4096), 0, 'independent root stdout reaches EOF without unconsumed bytes');
        CORE::close($witness);
    }
    if ($native) {
        my $s = $native->finished_job;
        ok($s->{resources_closed} && $s->{cleanup}{leader_reaped}
            && $s->{cleanup}{group_gone} && $s->{reservation_reaped}, 'original native closure facts settle');
        is($s->{result}{stdout}, '', 'unreleased command contributes no captured bytes') if $no_exec;
        ok(!exists($native->{pair}{release_check}), 'cleanup drops retained admission callback');
    }
    is_deeply(census(), $initial, 'original endpoint inventory is restored');
}
my $cc = 'FSM::Support::ProcessSupervisor::Coordinator';
my $rc = 'FSM::Support::ProcessSupervisor::Reservation';
my $pc = 'FSM::Support::ProcessSupervisor::GatedPair';
my $pipe = $rc->can('_pipe'); my $rfork = $rc->can('_fork'); my $cfork = $pc->can('_fork');
my $rwait = $rc->can('_wait'); my $cwait = $pc->can('_wait'); my $write = $pc->can('_write');
my $check = $cc->can('_before_root_execution');
my $release = FSM::Support::ProcessSupervisor::ReservedJob->can('release');
my $parent_context = FSM::Support::ProcessSupervisor::Service->can('parent_context');
my $admission_clock = FSM::Support::ProcessSupervisor::Admission->can('_now_ns');
my $mask = $rc->can('_mask');
my $fork = sub { my ($f) = @_; my $pid = $f->(); $births{$pid} = 0 if defined($pid) && $pid > 0; return $pid };
my $wait = sub {
    my ($f, $pid) = @_; die 'root wait lacks original positive child' unless $pid > 0 && exists $births{$pid};
    my $w = $f->($pid); my $status = $?; $births{$pid} = 1 if $w == $pid; $? = $status; return $w;
};
no warnings 'redefine';
local *FSM::Support::ProcessSupervisor::Reservation::_pipe = sub {
    my $ok = $pipe->(@_);
    if ($ok) { push @pipes, ${$_[0]}, ${$_[1]}; weaken($pipes[-1]); weaken($pipes[-2]); }
    return $ok;
};
local *FSM::Support::ProcessSupervisor::Reservation::_fork = sub { $fork->($rfork) };
local *FSM::Support::ProcessSupervisor::GatedPair::_fork = sub { $fork->($cfork) };
local *FSM::Support::ProcessSupervisor::Reservation::_wait = sub { $wait->($rwait, @_) };
local *FSM::Support::ProcessSupervisor::GatedPair::_wait = sub { $wait->($cwait, @_) };
local *FSM::Support::ProcessSupervisor::Admission::_now_ns = sub { $clock // $admission_clock->() };
local *FSM::Support::ProcessSupervisor::Coordinator::_before_root_execution = sub {
    push @checks, [refaddr($_[1]), refaddr($_[2]), refaddr($_[4]), mask_state()];
    local $in_execution_check = 1;
    my $allow = $check->(@_); return 0 if $deferrals && $deferrals-- > 0; return $allow;
};
local *FSM::Support::ProcessSupervisor::Service::parent_context = sub {
    my $context = $parent_context->(@_);
    if ($context_cut && $in_execution_check && $owner && $owner->{jobs}{1}{release_requested}) {
        $context_cut = ''; $owner->{ledger}->cancel($owner->root);
    }
    return $context;
};
local *FSM::Support::ProcessSupervisor::GatedPair::_write = sub {
    return $write->(@_) unless $$ == $creator && $_[1] eq 'E';
    ++$attempts; push @write_masks, mask_state();
    if ($mode eq 'EAGAIN' || $mode eq 'EINTR') { $! = $mode eq 'EAGAIN' ? EAGAIN : EINTR; return undef; }
    my $n = $write->(@_); ++$writes if defined($n) && $n == 1;
    die "lost original root E return\n" if $mode eq 'lost-E';
    CORE::kill('USR2', $$) == 1 or die 'cannot queue root E signal' if $mode eq 'E-signal';
    return $n;
};
local *FSM::Support::ProcessSupervisor::ReservedJob::release = sub {
    my $v = $release->(@_);
    CORE::kill('USR2', $$) == 1 or die 'cannot queue root signal' if $queue_cut;
    die "original root queue failure\n" if $queue_cut eq 'failure';
    return $v;
};
local *FSM::Support::ProcessSupervisor::Reservation::_mask = sub {
    if ($mode eq 'outer-mask-failure') {
        if ($_[0] == SIG_SETMASK && !$_[1]->ismember(SIGUSR2)) { $mask_failed = 1; return undef; }
        return undef if $mask_failed && $_[0] == SIG_BLOCK;
    }
    if ($before_mask && $_[0] == SIG_BLOCK) { my $f = $before_mask; $before_mask = undef; $f->() }
    return $mask->(@_);
};
use warnings 'redefine';
END {
    local $?;
    if ($$ == $creator) {
        alarm 0; reset_hooks(); eval { $_->close } for @owners;
        for my $pid (grep { !$births{$_} } keys %births) {
            my $w = CORE::waitpid($pid, WNOHANG);
            if ($w == $pid || ($w == -1 && $! == ECHILD)) { $births{$pid} = 1; next; }
            CORE::kill('KILL', $pid); my $end = now() + 2;
            while (now() < $end) {
                $w = CORE::waitpid($pid, WNOHANG);
                if ($w == $pid || ($w == -1 && $! == ECHILD)) { $births{$pid} = 1; last; }
                sleep(0.001);
            }
        }
        CORE::close($_) for live(@pipes, @witnesses);
        eval { $_->{run}->close } for grep { $_->{run} } @owners;
        print STDERR (!live(@pipes, @witnesses) && !grep(!$_, values %births)
            && join("\n", @{census()}) eq join("\n", @$initial)
            ? "native-end-census: closed\n" : "native-end-census: INCOMPLETE\n");
    }
}
my $original_mask = POSIX::SigSet->new;
defined POSIX::sigprocmask(SIG_SETMASK, POSIX::SigSet->new(SIGUSR1), $original_mask) or die 'cannot select root exec mask';
local $SIG{ALRM} = sub { die "root execution fixture deadline\n" }; alarm 90;
local $SIG{USR2} = sub { die "unexpected root creator signal\n" };

subtest 'root release is single-use, deferred and preserves actual invocation bytes' => sub {
    my $o = ready(); my $g = $o->root; my $context = $o->context;
    $o->release_root($g);
    is($attempts, 0, 'queuing root release performs no E write');
    is($o->job_observation($g)->{release_requested}, 1, 'original root request is retained');
    like(error_from(sub { $o->release_root($g) }), qr/single-use/, 'repeat cannot queue another release');
    $deferrals = 2; $o->advance_job($g) for 1..2;
    is($attempts, 0, 'fresh false admission defers E');
    for my $transient ('EAGAIN', 'EINTR') {
        $mode = $transient; $o->advance_job($g);
        is($writes, 0, "$transient writes no E");
    }
    $mode = ''; drive($o, 'finished');
    is($writes, 1, 'only one original E is confirmed');
    is($o->{jobs}{1}{native}->finished_job->{result}{stdout}, expected($context),
        'actual command preserves byte arguments, environment, context, cwd, umask and exec signals');
    ok(@checks >= 5 && !grep($_->[0] != refaddr($g) || $_->[1] != refaddr($o->{jobs}{1}{native})
        || $_->[2] != $o->{jobs}{1}{native}{pair_identity} || join('', @{$_->[3]}) ne '11', @checks),
        'every retained callback sees original grant, wrapper, Pair and masked creator signals');
    ok(!grep(join('', @$_) ne '11', @write_masks), 'actual E attempts retain the native transaction mask');
    finish($o, 0);
};

subtest 'copied, foreign, nested and unready authority cannot release root' => sub {
    my $o = ready(); my $g = $o->root; my $other = prepare();
    like(error_from(sub { $other->release_root($other->root) }), qr/original active root/, 'unready original root refuses');
    for my $bad (bless({}, ref($g)), $other->root, $o->job_observation($g)->{admission}) {
        like(error_from(sub { $o->release_root($bad) }), qr/(?:grant|copied|foreign)/, 'non-original root grant refuses');
    }
    my $copy = bless {%$o}, ref($o);
    like(error_from(sub { $copy->release_root($g) }), qr/copied coordinator/, 'copied aggregate refuses');
    my $nested = $o->reserve_job(parent => $g, snapshot => snapshot());
    $o->prepare_job($nested); $o->start_job($nested); drive($o, 'ready', $nested);
    like(error_from(sub { $o->release_root($nested) }), qr/original active root/, 'nested original grant is not root execution authority');
    my $pid = CORE::fork(); die 'cannot fork inherited root observer' unless defined $pid;
    if (!$pid) { _exit(error_from(sub { $o->release_root($g) }) =~ /inherited coordinator/ ? 0 : 1); }
    $births{$pid} = 0; my ($waited, $status, $end) = (0, undef, now() + 3);
    while (now() < $end) {
        $waited = CORE::waitpid($pid, WNOHANG); $status = $?;
        last if $waited == $pid; sleep(0.001);
    }
    $births{$pid} = 1 if $waited == $pid;
    is($waited, $pid, 'inherited observer has its exact positive wait');
    is($status, 0, 'inherited aggregate refuses root release');
    is($attempts, 0, 'invalid authority adds no E attempt');
    $other->close; finish($o, 1);
};

subtest 'every final attempt rechecks original aggregate authority and wall' => sub {
    for my $cut (qw(phase failure revoked context expired wall context-return)) {
        my $o = ready(); my $g = $o->root; $o->release_root($g);
        if ($cut eq 'phase') { $o->{phase} = 'failed'; }
        elsif ($cut eq 'failure') { $o->{jobs}{1}{failure} = 'original root failure'; }
        elsif ($cut eq 'revoked') { $o->{ledger}->cancel($g); }
        elsif ($cut eq 'context') { $o->{service}->revoke_parent(1); }
        elsif ($cut eq 'expired') { $clock = $o->job_observation($g)->{admission}{deadline_ns}; }
        elsif ($cut eq 'wall') { $o->{ledger}{jobs}{1}{deadline_ns} += 1_000_000_000; }
        else { $context_cut = 'cancel'; }
        my $error = error_from(sub { $o->advance_job($g) });
        ok(length($error) || $o->job_observation($g)->{admission}{phase} eq 'closing', "$cut refuses or enters original cleanup");
        is($attempts, 0, "$cut performs no native E attempt");
        finish($o, 1);
    }
};

subtest 'actual command and reservation loss revoke root execution' => sub {
    for my $role ('command', 'reservation') {
        my $o = ready(); my $g = $o->root; $o->release_root($g);
        my $native = $o->{jobs}{1}{native}; my $pair = $native->{pair};
        my $pid = $role eq 'command' ? $pair->observation->{command_pid} : $pair->reservation->observation->{pid};
        is(CORE::kill('KILL', $pid), 1, "$role original positive child is actually killed");
        my $end = now() + 3; my $detected = 0;
        while (now() < $end) {
            if ($role eq 'command') { $pair->poll_command; $detected = $pair->observation->{command_reaped}; }
            else { $pair->reservation->advance; $detected = defined($pair->reservation->observation->{failure}); }
            last if $detected; sleep(0.001);
        }
        ok($detected, 'original native owner detects actual child loss');
        ok(!$pair->reservation->observation->{reaped}, 'reservation identity stays unharvested until group cleanup')
            if $role eq 'reservation';
        error_from(sub { $o->advance_job($g) });
        is($attempts, 0, "$role loss performs no E attempt"); finish($o, 1);
    }
};

subtest 'creator queue interruption retains ownership and the first failure' => sub {
    for my $cut ('signal', 'failure') {
        my $o = ready(); my $g = $o->root; $queue_cut = $cut; my $seen = 0;
        local $SIG{USR2} = sub {
            ++$seen;
            is($o->job_observation($g)->{release_requested}, 1, 'creator sees original request before return');
            like($o->job_observation($g)->{failure}, qr/original root queue failure/, 'inner first failure precedes signal') if $cut eq 'failure';
            die "root creator return interruption\n";
        };
        like(error_from(sub { $o->release_root($g) }), qr/(?:root creator return interruption|original root queue failure)/,
            'actual creator signal interrupts root queuing');
        is($seen, 1, 'one actual creator signal is consumed');
        like($o->job_observation($g)->{failure}, $cut eq 'failure' ? qr/original root queue failure/ : qr/root creator return interruption/,
            'aggregate preserves the first failure');
        is($attempts, 0, 'interrupted queue performs no E attempt'); finish($o, 1);
    }
};

subtest 'pre-mask reentry cannot overwrite an already queued original request' => sub {
    my $o = ready(); my $g = $o->root; my $context = $o->context;
    $before_mask = sub { $o->release_root($g) };
    like(error_from(sub { $o->release_root($g) }), qr/single-use/, 'earlier creator request wins original single-use transition');
    ok(!$o->job_observation($g)->{failure}, 'losing caller does not cancel original queued work');
    drive($o, 'finished'); is($writes, 1, 'original winning request executes once');
    is($o->{jobs}{1}{native}->finished_job->{result}{stdout}, expected($context), 'winning request keeps original execution bytes');
    finish($o, 0);
};

subtest 'mask failure publishes refusal without requiring another mask' => sub {
    my $o = ready(); my $g = $o->root; $mode = 'outer-mask-failure';
    like(error_from(sub { $o->release_root($g) }), qr/(?:mask|signal)/, 'outer restoration failure is returned');
    ok($o->job_observation($g)->{failure}, 'original refusal survives failed remasking');
    is_deeply(mask_state(), [1, 1], 'injected restoration failure leaves the actual creator mask blocked');
    reset_hooks();
    defined POSIX::sigprocmask(SIG_SETMASK, POSIX::SigSet->new(SIGUSR1)) or die 'cannot repair fixture mask after injected failure';
    error_from(sub { $o->advance_job($g) });
    is($attempts, 0, 'failed mask cannot leave executable root E'); finish($o, 1);
};

subtest 'confirmed and uncertain original E truth survive interrupted returns' => sub {
    for my $cut ('E-signal', 'lost-E') {
        my $o = ready(); my $g = $o->root; $o->release_root($g); $mode = $cut;
        local $SIG{USR2} = sub { die "confirmed root E interruption\n" };
        like(error_from(sub { $o->advance_job($g) }), qr/(?:confirmed root E interruption|lost original root E return)/,
            'actual original E return is interrupted');
        my $v = $o->job_observation($g)->{native}{command};
        is($v->{released}, $cut eq 'E-signal' ? 1 : 0, 'confirmed original execution truth is preserved');
        is($v->{release_uncertain}, $cut eq 'lost-E' ? 1 : 0, 'lost syscall return retains native uncertainty');
        is($writes, 1, 'one actual original E byte escaped');
        finish($o, 0); is($attempts, 1, 'interrupted native effect is never replayed');
    }
};

alarm 0;
defined POSIX::sigprocmask(SIG_SETMASK, $original_mask) or die 'cannot restore root exec mask';
done_testing;
