#!/usr/bin/env perl
use strict;
use warnings;
use Errno qw(EAGAIN EINTR ECHILD);
use POSIX qw(SIG_BLOCK SIG_SETMASK SIGUSR1 SIGUSR2 WNOHANG _exit);
use Scalar::Util qw(refaddr weaken);
use Time::HiRes qw(CLOCK_MONOTONIC clock_gettime sleep);
use Test::More;
use lib 'perl', 't/lib';
use FSM::Test::ProjectDataLocality;
use FSM::Support::ProcessSupervisor::ReservedJob ();

my $creator=$$;
my (@jobs,@pipes,%births,@queue_masks,@write_masks);
my ($job,$mode,$queue_cut,$before_mask,$clock,$mask_failed);
my ($attempts,$writes)=(0,0);
sub now { clock_gettime(CLOCK_MONOTONIC) }
sub error_from { my ($code)=@_; local $@; eval { $code->(); 1 }; return $@ }
sub live { grep { defined($_) && defined(fileno($_)) } @_ }
sub mask_state {
    my $old=POSIX::SigSet->new;
    defined POSIX::sigprocmask(SIG_BLOCK,POSIX::SigSet->new,$old) or die 'cannot read wrapper mask';
    return [$old->ismember(SIGUSR1)?1:0,$old->ismember(SIGUSR2)?1:0];
}
sub snapshot {
    return {type=>'SPAWN',started_ns=>sprintf('%.0f',now()*1e9),
        schema=>'reserved.execution.admission',stage=>'probe',containment=>'fixture-group',
        cwd=>'.',umask=>0027,timeout_seconds=>20,capture_limit_bytes=>4096,
        argv=>[$^X,'-MPOSIX','-e','my $s=POSIX::SigSet->new; POSIX::sigprocmask(POSIX::SIG_BLOCK(),POSIX::SigSet->new,$s); syswrite STDOUT, join(":", "EXECUTED", $s->ismember(POSIX::SIGUSR1())?1:0, $s->ismember(POSIX::SIGUSR2())?1:0)."|A\0\xff";'],
        environment=>[]};
}
my $pair_class='FSM::Support::ProcessSupervisor::GatedPair';
my $reservation_class='FSM::Support::ProcessSupervisor::Reservation';
my $pipe=$reservation_class->can('_pipe');
my $cfork=$pair_class->can('_fork'); my $rfork=$reservation_class->can('_fork');
my $cwait=$pair_class->can('_wait'); my $rwait=$reservation_class->can('_wait');
my $write=$pair_class->can('_write'); my $release=$pair_class->can('release');
my $native_clock=$pair_class->can('_now'); my $mask=$reservation_class->can('_mask');
my $fork=sub { my ($f)=@_; my $pid=$f->(); $births{$pid}=0 if defined($pid) && $pid>0; return $pid };
my $wait=sub {
    my ($f,$pid)=@_; die 'non-positive wrapper wait' unless $pid>0;
    my $n=$f->($pid); my $status=$?; $births{$pid}=1 if $n==$pid; $?=$status; return $n;
};
no warnings 'redefine';
local *FSM::Support::ProcessSupervisor::Reservation::_pipe=sub {
    my $ok=$pipe->(@_);
    if ($ok) { push @pipes,${$_[0]},${$_[1]}; weaken($pipes[-1]); weaken($pipes[-2]); }
    return $ok;
};
local *FSM::Support::ProcessSupervisor::GatedPair::_fork=sub { $fork->($cfork) };
local *FSM::Support::ProcessSupervisor::Reservation::_fork=sub { $fork->($rfork) };
local *FSM::Support::ProcessSupervisor::GatedPair::_wait=sub { $wait->($cwait,@_) };
local *FSM::Support::ProcessSupervisor::Reservation::_wait=sub { $wait->($rwait,@_) };
local *FSM::Support::ProcessSupervisor::GatedPair::_now=sub { $clock // $native_clock->() };
local *FSM::Support::ProcessSupervisor::GatedPair::_write=sub {
    return $write->(@_) unless $$==$creator && $_[1] eq 'E';
    ++$attempts; push @write_masks,mask_state();
    if ($mode eq 'EAGAIN' || $mode eq 'EINTR') { $!=$mode eq 'EAGAIN'?EAGAIN:EINTR; return undef; }
    my $n=$write->(@_); ++$writes if defined($n) && $n==1;
    die "lost original E return\n" if $mode eq 'lost-E';
    kill('USR2',$$)==1 or die 'cannot queue E signal' if $mode eq 'E-signal';
    return $n;
};
local *FSM::Support::ProcessSupervisor::GatedPair::release=sub {
    push @queue_masks,mask_state();
    kill('USR2',$$)==1 or die 'cannot queue refusal signal' if $queue_cut eq 'refusal';
    my $v=$release->(@_);
    die "lost original queue return\n" if $queue_cut eq 'lost-return';
    kill('USR2',$$)==1 or die 'cannot queue wrapper signal' if $queue_cut eq 'signal';
    return $v;
};
local *FSM::Support::ProcessSupervisor::Reservation::_mask=sub {
    if ($mode eq 'outer-mask-failure') {
        if ($_[0]==SIG_SETMASK && !$_[1]->ismember(SIGUSR2)) { $mask_failed=1;return undef; }
        return undef if $mask_failed && $_[0]==SIG_BLOCK;
    }
    if ($before_mask && $_[0]==SIG_BLOCK) { my $f=$before_mask; $before_mask=undef; $f->() }
    return $mask->(@_);
};
use warnings 'redefine';
sub reset_hooks { $mode=$queue_cut=''; $clock=$before_mask=$mask_failed=undef; }
sub make_record {
    my $s=snapshot();
    my $j=FSM::Support::ProcessSupervisor::ReservedJob::prepare_record(
        snapshot=>$s,deadline=>$s->{started_ns}/1e9+20,close_handles=>[]);
    push @jobs,$j; return $j;
}
sub drive {
    my ($j,$phase)=@_; my $end=now()+6;
    while (now()<$end) {
        return $j->observation if $j->observation->{phase} eq $phase;
        die "wrapper finished before $phase" if $j->observation->{phase} eq 'finished';
        $j->advance; sleep(0.001);
    }
    die "wrapper observer expired before $phase";
}
sub ready {
    die 'prior wrapper pipes survive' if live(@pipes);
    die 'prior wrapper children survive' if grep { !$_ } values %births;
    reset_hooks(); @pipes=(); @queue_masks=(); @write_masks=(); $attempts=$writes=0;
    $job=make_record(); $job->allocate; $job->start; drive($job,'ready');
    return $job;
}
sub finish {
    my ($cancel)=@_; reset_hooks();
    $job->cancel('fixture cleanup',now()+4) if $cancel;
    drive($job,'finished'); my $state=$job->finished_job;
    ok($state->{resources_closed},'original wrapper closes all owned resources');
    ok($state->{cleanup}{leader_reaped} && $state->{cleanup}{group_gone} && $state->{reservation_reaped},'distinct actual command/group/reservation closure facts hold');
    for my $pid ($state->{pid},$state->{group_identity}{pid}) {
        my $w=CORE::waitpid($pid,WNOHANG);my $errno=0+$!;
        is($w,-1,'independent exact wait finds no retained child');is($errno,ECHILD,'exact native wait was consumed');
    }
    ok(!grep(!$_,values %births),'fork/wait census contains no live direct child');
    ok(!live(@pipes),'independent weak pipe inventory is closed');
    ok(!exists($job->{pair}{release_check}),'final pair retains no callback cycle');
    return $state->{result};
}
END {
    local $?;
    if ($$==$creator) {
        alarm 0; reset_hooks();
        for my $pid (grep { !$births{$_} } keys %births) {
            my $n=CORE::waitpid($pid,WNOHANG);
            if ($n==$pid || ($n==-1 && $! == ECHILD)) { $births{$pid}=1;next; }
            CORE::kill('KILL',$pid);my $end=now()+2;
            while (now()<$end) {
                $n=CORE::waitpid($pid,WNOHANG);
                if ($n==$pid || ($n==-1 && $! == ECHILD)) { $births{$pid}=1;last; }
                sleep(0.001);
            }
        }
        CORE::close($_) for live(@pipes);
        if (grep(!$_,values %births) || live(@pipes)) {
            print STDERR "native-end-census: INCOMPLETE\n";
        }
        else { print STDERR "native-end-census: closed\n"; }
    }
}
local $SIG{ALRM}=sub { die "reserved execution fixture deadline\n" };alarm 90;
my $original_mask=POSIX::SigSet->new;
defined POSIX::sigprocmask(SIG_SETMASK,POSIX::SigSet->new(SIGUSR1),$original_mask) or die 'cannot select wrapper mask';
local $SIG{USR2}=sub { die "unexpected wrapper signal\n" };
reset_hooks();

subtest 'resource-free original wrapper refuses shallow copies and foreign pairs' => sub {
    my $j=make_record();my $copy=bless {%$j},ref($j);my $other=make_record();
    for my $method (qw(allocate start release advance observation handles finished_job receipt_basis)) {
        like(error_from(sub { $copy->$method }),qr/copied job/,"copied wrapper cannot use $method");
    }
    like(error_from(sub { $copy->cancel('copied',now()+4) }),qr/copied job/,'copied wrapper cannot cancel original pair');
    { local $j->{pair}=$other->{pair};
      like(error_from(sub { $j->observation }),qr/lost original pair/,'original wrapper refuses substituted original foreign pair'); }
    is($j->observation->{phase},'unallocated','original wrapper identity remains usable');
    is(scalar(keys %births),0,'resource-free identity tests launch no child');
    is(scalar(live(@pipes)),0,'resource-free identity tests create no pipe');
};

subtest 'retained callback gates each native attempt and preserves execution bytes and mask' => sub {
    ready();my ($calls,$allow)=(0,0);my $wall=$job->{state}{deadline};
    like(error_from(sub { $job->release(1) }),qr/ready published job/,'malformed release check leaves original job ready');
    is($job->observation->{phase},'ready','bad callback creates no pending release');
    $job->release(sub {
        is(refaddr($_[0]),refaddr($job->{pair}),'forwarded check receives the original Pair');
        is_deeply(mask_state(),[1,1],'retained execution check remains creator-masked');
        ++$calls;return $allow;
    });
    is($calls,0,'queueing wrapper release performs no execution check');
    is_deeply($queue_masks[0],[1,1],'wrapper queues the original Pair under masking');
    is($job->observation->{phase},'releasing','wrapper retains pending release phase');
    $job->advance;is($attempts,0,'deferred wrapper callback emits no E');
    $allow=1;
    for my $transient ('EAGAIN','EINTR') { $mode=$transient;$job->advance;is($writes,0,"$transient confirms no byte"); }
    is($calls,3,'each retry rechecks original owner admission');
    is($job->{state}{deadline},$wall,'deferral and retries cannot renew wrapper deadline');
    $mode='';my $result=finish(0);
    is($calls,4,'successful native attempt also requires a fresh check');
    is($writes,1,'only one native E byte is confirmed');
    is($result->{status},'success','actual bounded command succeeds');
    is($result->{stdout},"EXECUTED:1:0|A\0\xff",'actual binary output and original exec mask survive wrapper forwarding');
    is_deeply(mask_state(),[1,0],'creator mask is restored after execution');
};

subtest 'callback cancellation and failures cannot turn an admitted answer into E' => sub {
    for my $cut ('cancel','throw','malformed','wall','phase','first-failure') {
        ready();$job->release(sub {
            if ($cut eq 'cancel') { $job->cancel('callback revoked original job',now()+4);return 1; }
            die "original callback failure\n" if $cut eq 'throw';
            if ($cut eq 'wall') { $job->{state}{deadline}+=1;return 1; }
            if ($cut eq 'phase') { $job->{state}{phase}='ready';return 1; }
            if ($cut eq 'first-failure') { $job->_latch('host_error','callback original failure');return 1; }
            return {};
        });
        my $error=error_from(sub { $job->advance });
        like($error,$cut eq 'throw'?qr/original callback failure/:$cut eq 'malformed'?qr/boolean/:qr/releas|admission/,"$cut refuses original native release");
        is($attempts,0,"$cut performs no native E attempt");
        my $result=finish(0);is($result->{stdout},'',"$cut has no execution output");
        ok(!$job->observation->{command}{released},"$cut preserves unreleased native truth");
    }
};

subtest 'pre-existing wrapper failure prevents invoking a retained caller check' => sub {
    ready();my $calls=0;$job->release(sub {++$calls;1});
    $job->_latch('host_error','prior wrapper failure');
    like(error_from(sub {$job->advance}),qr/execution admission/,'prior wrapper refusal prevents final release');
    is($calls,0,'invalid wrapper never invokes caller admission');
    is($attempts,0,'prior wrapper failure performs no E attempt');
    my $result=finish(0);is($result->{diagnostic},'prior wrapper failure','first wrapper failure survives native refusal');
};

subtest 'queue interruptions retain wrapper phase and revoke pending execution' => sub {
    for my $cut ('signal','lost-return','refusal','handler-cancel','before-mask') {
        ready();my ($seen,$failure);
        local $SIG{USR2}=sub {
            $seen=$job->observation;$failure=$seen->{first_failure};
            if ($cut eq 'handler-cancel') { $job->cancel('handler cancelled original job',now()+4);return; }
            die "original wrapper interruption\n";
        };
        $queue_cut=$cut eq 'handler-cancel'?'signal':$cut;
        $clock=$job->{pair}{deadline} if $cut eq 'refusal';
        $before_mask=sub { $job->cancel('pre-mask original cancellation',now()+4) } if $cut eq 'before-mask';
        my $error=error_from(sub { $job->release(sub { 1 }) });
        if ($cut eq 'handler-cancel') {
            is($error,'','handler cancellation can return normally');
            is($job->observation->{phase},'cleanup','release return never overwrites newer handler cleanup');
        }
        else {
            like($error,$cut eq 'lost-return'?qr/lost original queue return/:$cut eq 'before-mask'?qr/ready published job/:qr/original wrapper interruption/,"$cut preserves original queue error");
        }
        if ($cut eq 'signal' || $cut eq 'handler-cancel') {
            is($seen->{phase},'releasing','creator handler sees published wrapper phase');
            is($seen->{command}{phase},'release_pending','handler sees retained original pending E');
        }
        if ($cut eq 'refusal') {
            like($failure->{diagnostic},qr/invocation wall/,'queue refusal latches original failure before signals resume');
            is($seen->{command}{phase},'failed','queue refusal revokes original Pair before handler');
            is_deeply($job->observation->{first_failure},$failure,'outer interruption preserves the first inner queue failure');
        }
        if ($cut eq 'signal' || $cut eq 'lost-return' || $cut eq 'refusal') {
            ok(!exists($job->{pair}{outgoing}),'interrupted queue retains no pending E');
            ok(!exists($job->{pair}{release_check}),'interrupted queue retains no execution callback');
        }
        reset_hooks();is_deeply(mask_state(),[1,0],"$cut preserves creator mask");
        my $result=finish(0);
        is($attempts,0,"$cut has no later native E attempt");
        is($result->{stdout},'',"$cut produces no execution witness");
    }
};

subtest 'failed signal-mask restoration cannot leave E eligible when masking is unavailable' => sub {
    ready();$mode='outer-mask-failure';
    like(error_from(sub {$job->release(sub {1})}),qr/fatal preparation signal-mask restoration failure/,'original outer restoration failure is retained');
    my $view=$job->observation;
    like($view->{first_failure}{diagnostic},qr/fatal preparation signal-mask restoration failure/,'mask failure still latches original wrapper refusal');
    ok(!exists($job->{pair}{outgoing}),'mask failure revokes pending E without needing another successful mask');
    ok(!exists($job->{pair}{release_check}),'mask failure clears retained execution check');
    reset_hooks();
    defined POSIX::sigprocmask(SIG_SETMASK,POSIX::SigSet->new(SIGUSR1)) or die 'cannot recover fixture caller mask';
    $job->advance;is($attempts,0,'restoration failure has no later native E attempt');
    finish(0);
};

subtest 'interrupted actual E retains confirmed or uncertain original native truth' => sub {
    for my $cut ('E-signal','lost-E') {
        ready();my $seen;
        local $SIG{USR2}=sub { $seen=$job->observation;die "actual E wrapper interruption\n" };
        $job->release(sub {1});$mode=$cut;
        like(error_from(sub {$job->advance}),$cut eq 'E-signal'?qr/actual E wrapper interruption/:qr/lost original E return/,"$cut preserves native interruption");
        my $native=$job->observation->{command};
        is($writes,1,'independent syscall confirms one actual E byte');
        is($native->{released},$cut eq 'E-signal'?1:0,'confirmed-release flag respects whether native return was retained');
        is($native->{release_uncertain},$cut eq 'lost-E'?1:0,'lost return remains explicit uncertainty');
        ok($seen->{command}{released},'real creator signal observes confirmed original E') if $cut eq 'E-signal';
        finish(0);is($attempts,1,'interrupted original effect is never retried');
    }
};

subtest 'inherited wrappers refuse access and no-callback release remains supported' => sub {
    ready();my @inherited=@{$job->handles};my $pid=CORE::fork();die 'cannot fork wrapper ownership observer' unless defined $pid;
    if (!$pid) {
        my $a=error_from(sub {$job->release});my $b=error_from(sub {$job->observation});
        CORE::close($_) for live(@inherited);_exit($a=~/inherited job/ && $b=~/inherited job/?0:93);
    }
    $births{$pid}=0;my ($status,$end)=(undef,now()+2);
    while(now()<$end){my $w=CORE::waitpid($pid,WNOHANG);if($w==$pid){$status=$?;$births{$pid}=1;last}die 'wrapper exact ownership wait failed' if $w<0;sleep(0.001)}
    is($status,0,'exact inherited observer cannot use original creator wrapper');
    $job->release;my $result=finish(0);
    is($result->{stdout},"EXECUTED:1:0|A\0\xff",'existing no-callback release executes the original bounded command');
};

defined POSIX::sigprocmask(SIG_SETMASK,$original_mask) or die 'cannot restore wrapper mask';
alarm 0;done_testing();
