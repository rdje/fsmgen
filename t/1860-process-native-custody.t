#!/usr/bin/env perl
use strict;
use warnings;
use Errno qw(ECHILD EINTR);
use IO::Select;
use POSIX qw(SIG_BLOCK SIG_SETMASK SIGUSR1 SIGUSR2 SIGSTOP SIGTERM WNOHANG WUNTRACED WIFSTOPPED WSTOPSIG _exit);
use Scalar::Util qw(refaddr weaken);
use Time::HiRes qw(CLOCK_MONOTONIC clock_gettime sleep);
use Test::More;
use lib 'perl', 't/lib';
use FSM::Test::ProjectDataLocality;
use FSM::Support::ProcessSupervisor::ReservedJob ();

my $creator = $$;
my (@jobs, @pipes, @witnesses, %births);
my ($job, $clock, $wait_signal, $mask_failed, $mask_fault, $before_mask, $lost_e);
my ($forks, $e_writes, $pipe_calls, $pair_advances) = (0, 0, 0, 0);
my @waits;
sub now { clock_gettime(CLOCK_MONOTONIC) }
sub error_from { my ($f) = @_; local $@; eval { $f->(); 1 }; return $@ }
sub live { grep { defined($_) && defined(fileno($_)) } @_ }
sub reset_hooks { $clock = $wait_signal = $mask_failed = $mask_fault = $before_mask = $lost_e = undef }
sub mask_state {
    my $old=POSIX::SigSet->new;
    defined POSIX::sigprocmask(SIG_BLOCK,POSIX::SigSet->new,$old) or die 'cannot read custody mask';
    return [$old->ismember(SIGUSR1)?1:0,$old->ismember(SIGUSR2)?1:0];
}
sub snapshot {
    return {type => 'SPAWN', started_ns => sprintf('%.0f', now()*1e9), schema => 'native.custody',
        stage => 'probe', containment => 'fixture-group', cwd => '.', umask => 0027,
        timeout_seconds => 20, capture_limit_bytes => 256,
        argv => [$^X, '-e', 'syswrite STDOUT,"PARENT"; kill "STOP",$$; exit $ARGV[0]', $_[0] // '0'],
        environment => []};
}
sub record {
    my $s = snapshot($_[0]);
    my $j = FSM::Support::ProcessSupervisor::ReservedJob::prepare_record(
        snapshot => $s, deadline => $s->{started_ns}/1e9 + 20, close_handles => []);
    push @jobs, $j; return $j;
}
sub drive {
    my ($j, $phase) = @_; my $end = now() + 5;
    while (now() < $end) {
        return if $j->observation->{phase} eq $phase;
        die "native custody finished before $phase" if $j->observation->{phase} eq 'finished';
        $j->advance; sleep(0.001);
    }
    die "native custody observer expired before $phase";
}
sub ready {
    die 'prior custody resources survive' if live(@pipes, @witnesses) || grep { !$_ } values %births;
    reset_hooks(); @pipes = (); @witnesses = (); @waits = ();
    ($forks, $e_writes, $pipe_calls, $pair_advances) = (0, 0, 0, 0);
    $job = record($_[0]); $job->allocate; $job->start; drive($job, 'ready'); return $job;
}
sub executing {
    my $j = ready($_[0]); $j->release;
    my $end = now() + 3;
    while (now() < $end) {
        $j->advance;
        if ($j->{state}{stdout} eq 'PARENT') {
            my $pid=$j->observation->{command}{command_pid};
            while (now()<$end) {
                my $n=CORE::waitpid($pid,WNOHANG|WUNTRACED); my $status=${^CHILD_ERROR_NATIVE};
                if ($n==$pid) {
                    die 'parent exited before its actual stop' unless WIFSTOPPED($status) && WSTOPSIG($status)==SIGSTOP;
                    return $j;
                }
                die 'cannot observe original parent stop' if $n==-1 && $! != EINTR;
                sleep(0.001);
            }
        }
        sleep(0.001);
    }
    die 'actual parent did not publish its ready output';
}
sub witness {
    my ($handle) = @_;
    open my $fh, '<&', $handle or die 'cannot retain native custody witness';
    push @witnesses, $fh; return $fh;
}
sub observe_eof {
    my ($fh) = @_;
    ok(IO::Select->new($fh)->can_read(3), 'original pipe becomes readable after actual child loss');
    is(sysread($fh, my $part, 32), 0, 'actual native EOF precedes any exact wait');
}
sub finish {
    my ($j, $cancel) = @_; reset_hooks();
    $j->cancel('fixture bounded cleanup', now()+4) if $cancel;
    drive($j, 'finished'); my $s = $j->finished_job;
    ok($s->{resources_closed}, 'original native resources close');
    ok($s->{cleanup}{leader_reaped} && $s->{cleanup}{group_gone} && $s->{reservation_reaped},
        'command, group and reservation closure facts settle');
    ok(!live(@pipes), 'independent weak pipe inventory closes');
    ok(!grep(!$_, values %births), 'all actual children have their consumed exact wait');
    for my $pid (keys %births) {
        my $w = CORE::waitpid($pid, WNOHANG); my $errno = 0+$!;
        is($w, -1, 'independent exact wait finds no child'); is($errno, ECHILD, 'native wait is already consumed');
    }
    CORE::close($_) for live(@witnesses);
    return $s->{result};
}
my $rc = 'FSM::Support::ProcessSupervisor::Reservation';
my $pc = 'FSM::Support::ProcessSupervisor::GatedPair';
my $pipe = $rc->can('_pipe'); my $rfork = $rc->can('_fork'); my $cfork = $pc->can('_fork');
my $rwait = $rc->can('_wait'); my $cwait = $pc->can('_wait'); my $write = $pc->can('_write');
my $advance = $pc->can('advance'); my $native_now = $rc->can('_now'); my $mask = $rc->can('_mask');
my $fork = sub { my ($f) = @_; ++$forks; my $pid=$f->(); $births{$pid}=0 if defined($pid) && $pid>0; return $pid };
my $wait = sub {
    my ($f, $pid) = @_;
    die 'custody wait lacks an original positive child' unless $pid>0 && exists $births{$pid};
    push @waits, $pid; my $n=$f->($pid); my $status=$?;
    $births{$pid}=1 if $n==$pid;
    if ($wait_signal && $job && $pid==$job->observation->{command}{command_pid}) {
        $wait_signal=0; CORE::kill('USR2',$$)==1 or die 'cannot queue custody wait signal';
    }
    $?=$status; return $n;
};
no warnings 'redefine';
local *FSM::Support::ProcessSupervisor::Reservation::_pipe = sub {
    ++$pipe_calls; my $ok=$pipe->(@_);
    if ($ok) { push @pipes,${$_[0]},${$_[1]}; weaken($pipes[-1]); weaken($pipes[-2]); }
    return $ok;
};
local *FSM::Support::ProcessSupervisor::Reservation::_fork = sub { $fork->($rfork) };
local *FSM::Support::ProcessSupervisor::GatedPair::_fork = sub { $fork->($cfork) };
local *FSM::Support::ProcessSupervisor::Reservation::_wait = sub { $wait->($rwait,@_) };
local *FSM::Support::ProcessSupervisor::GatedPair::_wait = sub { $wait->($cwait,@_) };
local *FSM::Support::ProcessSupervisor::Reservation::_now = sub { $clock // $native_now->() };
local *FSM::Support::ProcessSupervisor::GatedPair::advance = sub { ++$pair_advances; return $advance->(@_) };
local *FSM::Support::ProcessSupervisor::GatedPair::_write = sub {
    my $is_e=$$==$creator && $_[1] eq 'E'; ++$e_writes if $is_e;
    my $n=$write->(@_);
    die "lost actual custody E return\n" if $is_e && $lost_e;
    return $n;
};
local *FSM::Support::ProcessSupervisor::Reservation::_mask = sub {
    if ($mask_fault) {
        if ($_[0]==SIG_SETMASK && !$_[1]->ismember(SIGUSR2)) { $mask_failed=1; return undef; }
        return undef if $mask_failed && $_[0]==SIG_BLOCK;
    }
    if ($before_mask && $_[0]==SIG_BLOCK) { my $f=$before_mask; $before_mask=undef; $f->() }
    return $mask->(@_);
};
use warnings 'redefine';
END {
    local $?;
    if ($$==$creator) {
        alarm 0; reset_hooks();
        for my $pid (grep { !$births{$_} } keys %births) {
            my $n=CORE::waitpid($pid,WNOHANG);
            if ($n==$pid || ($n==-1 && $! == ECHILD)) { $births{$pid}=1; next; }
            CORE::kill('KILL',$pid); my $end=now()+2;
            while (now()<$end) {
                $n=CORE::waitpid($pid,WNOHANG);
                if ($n==$pid || ($n==-1 && $! == ECHILD)) { $births{$pid}=1;last; }
                sleep(0.001);
            }
        }
        CORE::close($_) for live(@pipes,@witnesses);
        print STDERR (!live(@pipes,@witnesses) && !grep(!$_,values %births)
            ? "native-end-census: closed\n" : "native-end-census: INCOMPLETE\n");
    }
}
my $original_mask=POSIX::SigSet->new;
defined POSIX::sigprocmask(SIG_SETMASK,POSIX::SigSet->new(SIGUSR1),$original_mask) or die 'cannot select custody mask';
local $SIG{ALRM}=sub { die "native custody fixture deadline\n" }; alarm 90;
local $SIG{USR2}=sub { die "unexpected custody signal\n" };

subtest 'fresh inspection preserves ordinary completed-command classification' => sub {
    for my $code (0,23,'signal') {
        my $signaled=$code eq 'signal';
        my $j=executing($signaled ? 0 : $code); my $fh=witness($j->{received}{stdout});
        is(CORE::kill('TERM',$j->observation->{command}{command_pid}),1,'original stopped child receives a pending terminal signal') if $signaled;
        is(CORE::kill('CONT',$j->observation->{command}{command_pid}),1,'original positive child resumes actual bounded completion');
        observe_eof($fh);
        my ($live,$error)=(1,''); my $end=now()+3;
        while (now()<$end && $live && !$error) {
            $error=error_from(sub { $live=$j->check_custody }); sleep(0.001) if $live && !$error;
        }
        is($error,'','known completed command is a liveness result, not an inspection host error');
        is($live,0,'original exact terminal wait refuses parent liveness');
        ok(!$j->observation->{first_failure},'inspection leaves native outcome classification to capture');
        is($j->observation->{command}{released},1,'confirmed execution truth remains retained');
        my $result=finish($j,0);
        is($result->{status},$signaled ? 'signaled' : $code ? 'nonzero_exit' : 'success','original completed-command status is preserved');
        is($result->{exit_code},$signaled ? undef : $code,'original exact exit code is preserved');
        is($result->{signal},$signaled ? SIGTERM : 0,'original exact terminal signal is preserved');
    }
};

subtest 'ready and queued custody inspection does not execute or launch' => sub {
    my $j=ready();
    for my $queued (0,1) {
        $j->release if $queued;
        my @before=($forks,$pipe_calls,$pair_advances,$e_writes);
        my $wait_count=@waits;
        is($j->check_custody,1,'original live native custody is current');
        is_deeply([$forks,$pipe_calls,$pair_advances,$e_writes],\@before,'inspection neither allocates, forks, advances Pair nor writes E');
        ok(@waits>$wait_count,'inspection polls the original positive command');
        is($j->observation->{phase},$queued?'releasing':'ready','inspection preserves queued versus ready state');
        is_deeply(mask_state(),[1,0],'inspection restores original creator signals');
    }
    finish($j,1); is($e_writes,0,'queued inspection never executes the command');
};

subtest 'executing custody remains live without consuming capture or native truth' => sub {
    my $j=executing(); my @before=($forks,$pipe_calls,$pair_advances,$e_writes);
    is($j->check_custody,1,'actually executing stopped parent remains an owned live command');
    is_deeply([$forks,$pipe_calls,$pair_advances,$e_writes],\@before,'inspection performs no launch, capture advancement or execution write');
    is($j->observation->{command}{released},1,'original confirmed execution stays true');
    is($j->{state}{stdout},'PARENT','already captured bytes stay unchanged');
    is(CORE::kill('CONT',$j->observation->{command}{command_pid}),1,'original command resumes');
    my $r=finish($j,0); is($r->{status},'success','live inspection does not alter successful execution');
    is($j->check_custody,0,'finished original wrapper reports no live custody');
};

subtest 'actual command and reservation loss refuse before any queued E' => sub {
    for my $role ('command','reservation') {
        my $j=ready();$j->release;my $pair=$j->{pair};
        my $pid=$role eq 'command'?$pair->observation->{command_pid}:$pair->reservation->observation->{pid};
        my $fh=witness($role eq 'command'?$j->{received}{stdout}:$pair->reservation->{read});
        is(CORE::kill('KILL',$pid),1,"actual original $role child is killed");observe_eof($fh);
        my $error=error_from(sub { $j->check_custody });
        like($error,qr/(?:command custody|reservation identity)/,'fresh inspection refuses actual native loss');
        is($e_writes,0,'native loss inspection writes no E');
        if ($role eq 'command') {
            ok($j->observation->{command}{command_reaped},'inspection publishes its exact terminal command wait');
        } else {
            ok(!$pair->reservation->observation->{reaped},'dead reservation identity stays unharvested before group cleanup');
        }
        my $first=$j->observation->{first_failure};
        finish($j,0);is_deeply($j->observation->{first_failure},$first,'bounded cleanup preserves original inspection failure');
    }
};

subtest 'original identities and fixed walls bound inspection' => sub {
    my $j=ready(); my $copy=bless {%$j},ref($j);
    like(error_from(sub { $copy->check_custody }),qr/copied job/,'copied wrapper cannot inspect as original');
    my $foreign=record();
    { local $j->{pair}=$foreign->{pair};
      like(error_from(sub { $j->check_custody }),qr/original pair/,'different original Pair cannot supply custody'); }
    { local $j->{pair}{reservation}=bless {%{$j->{pair}{reservation}}},ref($j->{pair}{reservation});
      like(error_from(sub { $j->check_custody }),qr/reservation identity/,'copied reservation cannot supply custody'); }
    finish($j,0);
    $j=ready();
    my $before=@waits;
    { local $j->{pair}{command_pid}=$$;
      like(error_from(sub { $j->check_custody }),qr/command custody/,'substituted positive identity refuses before native wait'); }
    is(scalar(@waits),$before,'wrong identity is never passed to a native wait');finish($j,0);
    $j=ready();$j->release;
    { local $j->{state}{deadline}=$j->{state}{deadline}+1;
      like(error_from(sub { $j->check_custody }),qr/original invocation wall/,'wrapper cannot replace original wall'); }
    $clock=$j->{state}{deadline};is($j->check_custody,0,'exact original deadline has no live custody');
    is($e_writes,0,'expired inspection does not advance queued E');finish($j,1);
    my $unready=record();like(error_from(sub { $unready->check_custody }),qr/live published job/,'resource-free unready wrapper refuses');
};

subtest 'terminal wait publication precedes creator interruption' => sub {
    my $j=ready();$j->release;my $fh=witness($j->{received}{stdout});
    is(CORE::kill('KILL',$j->observation->{command}{command_pid}),1,'original gated command is actually killed');observe_eof($fh);
    my $seen=0;$wait_signal=1;
    local $SIG{USR2}=sub {
        ++$seen;
        ok($j->observation->{command}{command_reaped},'creator sees the original terminal wait publication');
        like($j->observation->{first_failure}{diagnostic},qr/command custody/,'original custody failure precedes signal restoration');
        die "later custody handler interruption\n";
    };
    like(error_from(sub { $j->check_custody }),qr/(?:command custody|later custody handler interruption)/,'creator interrupts after native failure publication');
    is($seen,1,'exact creator signal is delivered');is($e_writes,0,'lost inspection return cannot execute E');finish($j,0);
};

subtest 'creator changes at mask boundaries revoke a positive inspection' => sub {
    for my $cut ('before','cancel','pair-cancel','throw') {
        my $j=ready();$j->release;
        $before_mask=sub { $j->cancel('earlier original cancellation',now()+4) } if $cut eq 'before';
        $wait_signal=1 unless $cut eq 'before';
        local $SIG{USR2}=sub {
            if ($cut eq 'cancel') { $j->cancel('original handler cancellation',now()+4); }
            elsif ($cut eq 'pair-cancel') { $j->{pair}->cancel; }
            else { die "original custody creator interruption\n"; }
        };
        my $live;
        my $error=error_from(sub { $live=$j->check_custody });
        if ($cut eq 'throw') {
            like($error,qr/original custody creator interruption/,'actual creator interruption escapes inspection');
            like($j->observation->{first_failure}{diagnostic},qr/original custody creator interruption/,'first creator failure survives return');
        } else {
            is($error,'','original creator cancellation is observed without replacing its cause');
            is($live,0,"$cut cannot leave a stale positive inspection");
        }
        is($e_writes,0,'creator interruption inspection executes no E');finish($j,0);
    }
};

subtest 'failed mask restoration cannot leave queued execution authority' => sub {
    my $j=ready();$j->release;$mask_fault=1;
    like(error_from(sub { $j->check_custody }),qr/(?:mask|signal)/,'mask restoration failure is explicit');
    ok($j->observation->{first_failure},'inspection refusal is retained despite failed remasking');
    is_deeply(mask_state(),[1,1],'fixture proves the deliberately failed restoration state');
    reset_hooks();defined POSIX::sigprocmask(SIG_SETMASK,POSIX::SigSet->new(SIGUSR1)) or die 'cannot repair custody fixture mask';
    finish($j,0);is($e_writes,0,'mask failure never advances the queued E');
};

subtest 'inherited inspection cannot operate original native children' => sub {
    my $j=ready();my $pid=CORE::fork();die 'cannot fork inherited custody observer' unless defined $pid;
    if (!$pid) { _exit(error_from(sub { $j->check_custody }) =~ /inherited job/ ? 0 : 1); }
    $births{$pid}=0;my ($waited,$status,$end)=(0,undef,now()+3);
    while (now()<$end) {
        $waited=CORE::waitpid($pid,WNOHANG);$status=$?;last if $waited==$pid;sleep(0.001);
    }
    $births{$pid}=1 if $waited==$pid;
    is($waited,$pid,'observer has its original exact positive wait');is($status,0,'inherited inspection refuses');
    is($j->check_custody,1,'original creator still owns live native custody');finish($j,1);
};

subtest 'inspection cannot erase or replay an uncertain native E' => sub {
    my $j=ready();$j->release;$lost_e=1;
    like(error_from(sub { $j->advance }),qr/lost actual custody E return/,'actual native E loses its return');
    my $before=$j->observation->{command};
    is($before->{release_uncertain},1,'native owner retains the lost-return ambiguity');
    is($j->check_custody,0,'uncertain failed execution has no fresh parent custody');
    is_deeply($j->observation->{command},$before,'inspection preserves all original native execution truth');
    finish($j,0);is($e_writes,1,'uncertain E is never replayed');
};

alarm 0;
defined POSIX::sigprocmask(SIG_SETMASK,$original_mask) or die 'cannot restore custody mask';
done_testing;
