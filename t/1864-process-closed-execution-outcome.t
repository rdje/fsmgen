#!/usr/bin/env perl
use strict;
use warnings;
use Errno qw(EAGAIN EINTR ECHILD);
use IO::Select;
use Math::BigInt;
use POSIX qw(SIG_BLOCK SIG_SETMASK SIGUSR1 SIGUSR2 WNOHANG _exit);
use Scalar::Util qw(refaddr weaken);
use Time::HiRes qw(CLOCK_MONOTONIC clock_gettime sleep);
use Test::More;
use lib 'perl', 't/lib';
use FSM::Test::ProjectDataLocality;
use FSM::ProjectDataLocality qw(repository_root);
use FSM::Support::ProcessSupervisor::Coordinator ();

my $creator=$$;
my (@owners,@clients,@pipes,%births,%selected);
my ($owner,$mode,$clock,$mask_fault,$report_cut,$report_calls);
my ($attempts,$writes,$forks,$pipe_calls)=(0,0,0,0);
sub now { clock_gettime(CLOCK_MONOTONIC) }
sub ns { sprintf('%.0f',$_[0]*1e9) }
sub error_from { my ($f)=@_;local $@;eval { $f->();1 };return $@ }
sub live { grep { defined($_) && defined(fileno($_)) } @_ }
sub census { [sort glob(repository_root().'/.artifacts/tmp/process-coordinator/*')] }
my $initial=census();
sub reset_hooks { $mode='';$clock=$mask_fault=$report_cut=undef;$report_calls=0 }
sub mask_state {
    my $old=POSIX::SigSet->new;
    defined POSIX::sigprocmask(SIG_BLOCK,POSIX::SigSet->new,$old) or die 'cannot read nested mask';
    return [$old->ismember(SIGUSR1)?1:0,$old->ismember(SIGUSR2)?1:0];
}
sub snapshot {
    return {type=>'SPAWN',started_ns=>ns(now()),schema=>'nested.outcome',stage=>'probe',
        containment=>'fixture-group',cwd=>'.',umask=>0027,timeout_seconds=>30,capture_limit_bytes=>4096,
        argv=>[$^X,'-e','syswrite STDOUT,join("",map { pack("N",length($_)).$_ } "CHILD",@ARGV,$ENV{A},$ENV{FSMGEN_PROCESS_COORDINATOR_CONTEXT});','',"arg\n\xff"],
        environment=>[['A',"env\n\xff"],['FSMGEN_PROCESS_COORDINATOR_CONTEXT','obsolete']]};
}
sub bytes { pack('N',length($_[0])).$_[0] }
sub raw { pack('NCC',length($_[1])+2,1,$_[0]).$_[1] }
sub literal {
    my ($s)=@_;my ($hi,$lo)=Math::BigInt->new($s->{started_ns})->bdiv(4_294_967_296);
    return raw(3,pack('NN',$hi->numify,$lo->numify).join('',map { bytes($s->{$_}) } qw(schema stage containment cwd))
        .pack('NNNN',$s->{timeout_seconds},$s->{capture_limit_bytes},$s->{umask},scalar @{$s->{argv}})
        .join('',map { bytes($_) } @{$s->{argv}}).pack('N',scalar @{$s->{environment}})
        .join('',map { bytes($_->[0]).bytes($_->[1]) } @{$s->{environment}}));
}
sub send_raw {
    my ($client,$data)=@_;my $end=now()+2;
    while (length($data) && now()<$end) {
        my $n=syswrite($client->handle,$data);
        if (defined($n) && $n>0) { substr($data,0,$n,'');next; }
        die 'literal nested write failed' unless !defined($n) && ($! == EAGAIN || $! == EINTR);
        sleep(0.001);
    }
    die 'literal nested write expired' if length $data;
}
sub read_bytes {
    my ($client,$count)=@_;my ($data,$end)=('',now()+2);
    while (length($data)<$count && now()<$end) {
        my $n=sysread($client->handle,my $part,$count-length($data));
        if (defined($n) && $n>0) { $data.=$part;next; }
        last if defined($n) && !$n;
        die 'literal nested read failed' unless $! == EAGAIN || $! == EINTR;
        sleep(0.001);
    }
    return $data;
}
sub until_service {
    my ($f)=@_;my $end=now()+2;
    while (now()<$end) { $owner->advance_service;my $v=$f->();return $v if defined $v;sleep(0.001); }
    die 'original nested Service observer expired';
}
sub drive {
    my ($grant,$phase)=@_;my $end=now()+4;
    while (now()<$end) {
        my $v=$owner->job_observation($grant);
        return $v if $v->{native}{phase} eq $phase;
        die "nested native finished before $phase" if $v->{native}{phase} eq 'finished';
        $owner->advance_job($grant);sleep(0.001);
    }
    die "original nested native observer expired before $phase";
}
sub ready_owner {
    die 'previous nested resources survive' if live(@pipes) || grep { !$_ } values %births;
    reset_hooks();@pipes=();($attempts,$writes,$forks,$pipe_calls)=(0,0,0,0);
    $owner=FSM::Support::ProcessSupervisor::Coordinator::prepare(snapshot=>snapshot());push @owners,$owner;
    $owner->open_run;$owner->prepare_job($owner->root);$owner->start_job($owner->root);drive($owner->root,'ready');
    return $owner;
}
sub request {
    my ($parent)=@_;$parent//=1;my $snapshot=snapshot();
    my $context=$owner->{service}->parent_context($parent);
    my $client=FSM::Support::ProcessSupervisor::Endpoint::connect_context($context);push @clients,$client;
    until_service(sub { IO::Select->new($client->handle)->can_write(0) && $client->connection_ready ? 1:undef });
    my @p=split /:/,$context;
    send_raw($client,raw(1,pack('H*',$p[2]).pack('N',$p[3]).pack('H*',$p[4])));
    until_service(sub { IO::Select->new($client->handle)->can_read(0) ? 1:undef });
    is(read_bytes($client,26),raw(2,pack('H*',$p[2]).pack('N',$p[3])),'literal socket READY names the original parent');
    send_raw($client,literal($snapshot));
    my $ticket=until_service(sub {
        for my $id (@{$owner->peer_tickets}) {
            return $id if $owner->peer_observation($id)->{transport}{state} eq 'request' && !$selected{refaddr($owner)}{$id};
        }
        return;
    });
    $selected{refaddr($owner)}{$ticket}=1;
    my $grant=$owner->admit_request($ticket);$owner->start_request($ticket);my $end=now()+2;
    while (now()<$end) { last if $owner->advance_request($ticket)->{publication};sleep(0.001); }
    die 'nested ACCEPT was never queued' unless $owner->peer_observation($ticket)->{publication};
    until_service(sub { my $p=$owner->peer_observation($ticket)->{publication}{write};return 1 if $p->{published};return; });
    my $id=$owner->job_observation($grant)->{admission}{id};
    is(read_bytes($client,10),raw(4,pack('N',$id)),'literal socket bytes match actual ACCEPT publication');
    return ($ticket,$client,$grant);
}
sub queue_check {
    my ($ticket)=@_;my $peer=$owner->{peers}{$ticket};my $grant=$peer->{job_grant};
    my $native=$owner->{jobs}{$peer->{job_id}}{native};my $deadline=$owner->job_observation($grant)->{admission}{deadline_ns};
    # This fixture installs the private final check directly. The explicit
    # aggregate request-release API remains a later slice.
    $peer->{release_requested}=1;
    $native->release(sub { $owner->_before_request_execution($peer,$native,$deadline,@_) });
    return ($peer,$native,$deadline);
}
sub finish {
    reset_hooks();my ($closed,$end)=(undef,now()+5);
    while (now()<$end) { $closed=$owner->close;last unless $closed->{pending};sleep(0.001); }
    ok($closed && $closed->{ok},'original aggregate cleanup completes');
    is($owner->observation->{usage}{charged_descriptors},0,'original descriptor credit retires');
    is($owner->observation->{usage}{charged_children},0,'original child credit retires');
    ok(!live(@pipes),'independent weak native pipe inventory closes');
    ok(!grep(!$_,values %births),'every original positive child wait is consumed');
    for my $pid (keys %births) {
        my $n=CORE::waitpid($pid,WNOHANG);my $errno=0+$!;
        is($n,-1,'independent exact wait finds no child');is($errno,ECHILD,'original wait remains consumed');
    }
    $_->close for @clients;@clients=();
    is_deeply(census(),$initial,'independent endpoint inventory returns to its original membership');
}
my $rc='FSM::Support::ProcessSupervisor::Reservation';my $pc='FSM::Support::ProcessSupervisor::GatedPair';
my $sc='FSM::Support::ProcessSupervisor::Service';my $nc='FSM::Support::ProcessSupervisor::Coordinator';
my $pipe=$rc->can('_pipe');my $rfork=$rc->can('_fork');my $cfork=$pc->can('_fork');
my $rwait=$rc->can('_wait');my $cwait=$pc->can('_wait');my $write=$pc->can('_write');
my $record_execution=$sc->can('record_execution');
my $mask=$rc->can('_mask');
my $nclock=$nc->can('_now_ns');my $sclock=$sc->can('_now_ns');
my $fork=sub {
    my ($f)=@_;++$forks;my $pid=$f->();
    if (defined($pid) && !$pid) { $_->discard_inherited for @clients; }
    $births{$pid}=0 if defined($pid) && $pid>0;return $pid;
};
my $wait=sub {
    my ($f,$pid)=@_;die 'nested wait lacks its original positive child' unless $pid>0 && exists $births{$pid};
    my $n=$f->($pid);my $status=$?;$births{$pid}=1 if $n==$pid;$?=$status;return $n;
};
no warnings 'redefine';
local *FSM::Support::ProcessSupervisor::Reservation::_pipe=sub {
    ++$pipe_calls;my $ok=$pipe->(@_);if ($ok) { push @pipes,${$_[0]},${$_[1]};weaken($pipes[-1]);weaken($pipes[-2]); }return $ok;
};
local *FSM::Support::ProcessSupervisor::Reservation::_fork=sub { $fork->($rfork) };
local *FSM::Support::ProcessSupervisor::GatedPair::_fork=sub { $fork->($cfork) };
local *FSM::Support::ProcessSupervisor::Reservation::_wait=sub { $wait->($rwait,@_) };
local *FSM::Support::ProcessSupervisor::GatedPair::_wait=sub { $wait->($cwait,@_) };
local *FSM::Support::ProcessSupervisor::Coordinator::_now_ns=sub { $clock//$nclock->() };
local *FSM::Support::ProcessSupervisor::Service::_now_ns=sub { $clock//$sclock->() };
local *FSM::Support::ProcessSupervisor::Reservation::_mask=sub {
    return undef if $mask_fault;
    return $mask->(@_);
};
local *FSM::Support::ProcessSupervisor::GatedPair::_write=sub {
    return $write->(@_) unless $$==$creator && $_[1] eq 'E';
    ++$attempts;
    if ($mode eq 'EAGAIN' || $mode eq 'EINTR') { $!=$mode eq 'EAGAIN'?EAGAIN:EINTR;return undef; }
    my $n=$write->(@_);++$writes if defined($n) && $n==1;
    die "lost nested native E return\n" if $mode eq 'lost-E';
    return $n;
};
local *FSM::Support::ProcessSupervisor::Service::record_execution=sub {
    ++$report_calls;
    my $peer=$owner->{peers}{$_[1]{ticket}};
    is($peer->{execution}{native}{state},'confirmed','original native observation precedes the Service report call');
    is_deeply(mask_state(),[1,1],'effect observation and report remain under the creator mask');
    my $v=$record_execution->(@_);
    $report_cut->(@_) if $report_cut;
    return $v;
};
use warnings 'redefine';
END {
    local $?;
    if ($$==$creator) {
        alarm 0;reset_hooks();eval { $_->close } for @owners;
        for my $pid (grep { !$births{$_} } keys %births) {
            my $n=CORE::waitpid($pid,WNOHANG);
            if ($n==$pid || ($n==-1 && $! == ECHILD)) { $births{$pid}=1;next; }
            CORE::kill('KILL',$pid);my $end=now()+2;
            while (now()<$end) { $n=CORE::waitpid($pid,WNOHANG);if ($n==$pid || ($n==-1 && $! == ECHILD)) { $births{$pid}=1;last; }sleep(0.001); }
        }
        CORE::close($_) for live(@pipes);eval { $_->close } for @clients;eval { $_->{run}->close } for @owners;
        print STDERR (!live(@pipes) && !grep(!$_,values %births) && join("\0",@{census()}) eq join("\0",@$initial)
            ? "native-end-census: closed\n":"native-end-census: INCOMPLETE\n");
    }
}
my $saved_mask=POSIX::SigSet->new;
defined POSIX::sigprocmask(SIG_SETMASK,POSIX::SigSet->new(SIGUSR1),$saved_mask) or die 'cannot select nested creator mask';
local $SIG{USR2}=sub { die "unexpected nested creator signal\n" };
local $SIG{ALRM}=sub { die "nested outcome fixture deadline\n" };alarm 90;

my ($before_take,$after_take);
my (%expected,$takes);
my $take=$sc->can('take_closed');
no warnings 'redefine';
local *FSM::Support::ProcessSupervisor::Service::take_closed=sub {
    my ($service)=@_;++$takes;
    # Read the original Service while it still owns every ticket. The aggregate
    # must already retain every complete outcome before the first destructive call.
    for my $ticket (@{$service->tickets}) {
        my $transport=$service->ticket_observation($ticket);
        my $execution=$service->execution_observation($ticket);
        my $outcome={ticket=>$ticket,parent=>$transport->{parent},%{$transport->{failure}},
            resources_closed=>$transport->{resources_closed}};
        $outcome->{job}=$transport->{job} if exists $transport->{job};
        $outcome->{execution}=$execution if $execution && $execution->{report};
        $expected{$ticket}//=$outcome;
        is_deeply($owner->peer_observation($ticket)->{outcome},$expected{$ticket},
            'complete original metadata precedes destructive Service consumption');
    }
    is_deeply(mask_state(),[1,1],'whole-run consumption retains the creator signal mask');
    $before_take->() if $before_take;
    my $outcome=$take->(@_);
    $after_take->($outcome) if $after_take;
    return $outcome;
};
use warnings 'redefine';
sub setup {
    %expected=();$takes=0;$before_take=$after_take=undef;
    ready_owner();return request();
}
sub execute {
    my ($ticket,$grant,$direct)=@_;my ($peer,$native)=queue_check($ticket);
    $direct ? $native->advance : $owner->advance_job($grant);
    is($native->observation->{command}{released},1,'original Pair confirms actual E');
    is($writes,1,'independent syscall witness confirms one E');
    return ($peer,$native);
}
sub close_until_error {
    my ($label)=@_;$label//='selected';
    my $end=now()+5;
    while (now()<$end) {
        my $result;my $error=error_from(sub { $result=$owner->close });
        return $error if length $error;
        die "$label consumption cut never ran" unless $result->{pending};
        sleep(0.001);
    }
    die 'selected consumption cut expired';
}
sub retained {
    my ($ticket)=@_;
    is_deeply($owner->peer_observation($ticket)->{outcome},$expected{$ticket},
        'complete original outcome survives Service retirement');
}

subtest 'actual command outcome retains original job, clocks and complete execution history' => sub {
    my ($ticket,$client,$grant)=setup();my ($peer,$native)=execute($ticket,$grant);
    my $reported={%{$peer->{execution}{report}}};my $issued=$peer->{execution_grant}{issued_ns};
    my $deadline=$peer->{request}{deadline_ns};my $admission=$peer->{request}{admission_deadline_ns};
    drive($grant,'finished');
    is($native->finished_job->{result}{stdout},join('',map { bytes($_) } 'CHILD','',"arg\n\xff","env\n\xff",$owner->{jobs}{2}{bound_context}),
        'actual command output preserves binary invocation and original context');
    finish();retained($ticket);
    my $outcome=$owner->peer_observation($ticket)->{outcome};
    is($outcome->{job},2,'closed outcome keeps the original child job');
    is_deeply($outcome->{execution}{report},$reported,'first report survives complete native and transport cleanup');
    is($outcome->{execution}{report}{admission_issued_ns},$issued,'original grant issue time survives');
    is($outcome->{execution}{deadline_ns},$deadline,'fixed execution deadline survives');
    is($outcome->{execution}{admission_deadline_ns},$admission,'historical admission deadline survives');
    is($outcome->{execution}{active_deadline_ns},$deadline,'reported execution wall survives');
    is_deeply($outcome->{execution}{failure},{map { $_=>$outcome->{$_} } qw(status diagnostic)},'full execution view retains original closure cause');
    for my $field (qw(report latest admitted failure)) {
        my $copy=$owner->peer_observation($ticket)->{outcome};
        $copy->{execution}{$field}{forged}='mutable public copy';
        delete $copy->{execution}{$field}{(sort keys %{$copy->{execution}{$field}})[0]};
        retained($ticket);
    }
    $outcome->{execution}{job}=999;$outcome->{job}=999;retained($ticket);
    like(error_from(sub { $record_execution->($owner->{service},$peer->{execution_grant}) }),qr/lost original peer admission/,'original consumed grant is spent');
    is($takes,1,'one original peer has one consumption');$owner->close;is($takes,1,'idempotent close never consumes again');
};

subtest 'unreported bound jobs retain association without fabricating execution confirmation' => sub {
    for my $kind ('ready','transient','uncertain') {
        my ($ticket,$client,$grant)=setup();my $peer=$owner->{peers}{$ticket};
        if ($kind ne 'ready') {
            queue_check($ticket);$mode=$kind eq 'transient'?'EAGAIN':'lost-E';
            my $error=error_from(sub { $owner->advance_job($grant) });
            like($error,qr/lost nested native E return/,'actual written E has an uncertain return') if $kind eq 'uncertain';
        }
        finish();retained($ticket);my $outcome=$owner->peer_observation($ticket)->{outcome};
        is($outcome->{job},2,"$kind preserves original bound job");
        ok(!exists $outcome->{execution},"$kind creates no Service report metadata");
        if ($kind eq 'uncertain') {
            is($peer->{execution}{native}{state},'uncertain','separate original effect history keeps uncertainty');
            like($peer->{request_failure},qr/lost nested native E return/,'original native return failure survives outcome consumption');
        }
    }
};

subtest 'delayed effects preserve original cancellation and EOF metadata' => sub {
    for my $cut ('cancel','eof') {
        my ($ticket,$client,$grant)=setup();my ($peer)=execute($ticket,$grant,1);
        if ($cut eq 'cancel') { send_raw($client,raw(7,pack('N',2))); } else { $client->close; }
        $clock=$peer->{request}{admission_deadline_ns};
        until_service(sub { $peer->{transport}{state} eq 'closed'?1:undef });
        my $failure={%{$peer->{transport}{failure}}};
        is($failure->{status},$cut eq 'cancel'?'cancelled':'peer_closed','original transport cause is observed before aggregate close');
        finish();retained($ticket);
        is_deeply($expected{$ticket}{execution}{failure},$failure,'consumed execution view keeps the first transport cause');
        is($expected{$ticket}{execution}{latest}{state},'admitted','original positive check survives closed-peer reporting');
    }
};


subtest 'a later refused check cannot replace original admission or delayed report history' => sub {
    my ($ticket,$client,$grant)=setup();my ($peer)=execute($ticket,$grant,1);
    my $admitted=$owner->{service}->execution_observation($ticket)->{admitted};
    my $issued=$peer->{execution_grant}{issued_ns};
    $clock=$peer->{request}{admission_deadline_ns};
    is($owner->{service}->execution_admission($ticket,2),0,'original unreported admission wall refuses a fresh check');
    is($owner->{service}->execution_observation($ticket)->{latest}{state},'refused','latest actual Service check differs from admitted history');
    finish();retained($ticket);my $execution=$owner->peer_observation($ticket)->{outcome}{execution};
    is_deeply($execution->{admitted},$admitted,'last original positive check survives a later refusal');
    is($execution->{latest}{state},'refused','complete outcome retains the distinct latest refusal');
    is($execution->{report}{admission_issued_ns},$issued,'delayed report retains the original grant issue time');
    is($execution->{failure}{status},'timed_out','delayed report preserves actual original expiry');
};

subtest 'consumption entry and return failures retain full metadata before retry' => sub {
    for my $cut ('entry','return') {
        my ($ticket,$client,$grant)=setup();execute($ticket,$grant);
        my $failure=sub { die "selected closed-outcome $cut loss\n" };
        $cut eq 'entry' ? ($before_take=$failure) : ($after_take=$failure);
        like(close_until_error(),qr/selected closed-outcome $cut loss/,'selected original exception propagates');
        retained($ticket);
        is(scalar @{$owner->{service}->tickets},$cut eq 'entry'?1:0,'native Service record reflects the actual destructive boundary');
        ok($owner->observation->{usage}{charged_descriptors}>0,'interrupted close keeps original resource credit');
        $before_take=$after_take=undef;finish();retained($ticket);
        like($owner->observation->{failure},qr/selected closed-outcome $cut loss/,'successful cleanup cannot replace the original close failure');
    }
};

subtest 'creator signal after consumption sees complete retained history' => sub {
    my ($ticket,$client,$grant)=setup();execute($ticket,$grant);my ($seen,$view)=(0);
    local $SIG{USR2}=sub {
        ++$seen;$view=$owner->peer_observation($ticket);
        is_deeply($owner->{service}->tickets,[],'pending handler sees actual Service consumption');
        is($owner->observation->{phase},'closed','pending handler sees complete aggregate retirement');
        die "selected closed-outcome creator signal\n";
    };
    $after_take=sub { CORE::kill('USR2',$$)==1 or die 'cannot queue outcome creator signal' };
    like(close_until_error(),qr/selected closed-outcome creator signal/,'creator interruption follows masked complete close');
    is($seen,1,'one real creator signal is delivered');is_deeply($view->{outcome},$expected{$ticket},'signal handler sees complete original execution metadata');
    is_deeply(mask_state(),[1,0],'original creator mask is restored');
    $after_take=undef;finish();retained($ticket);
};

subtest 'all returned fields must agree with the original retained outcome' => sub {
    my @changes=(
        ['job',sub { $_[0]{job}=999 }],
        ['missing job',sub { delete $_[0]{job} }],
        ['missing execution',sub { delete $_[0]{execution} }],
        ['execution job',sub { $_[0]{execution}{job}=999 }],
        ['report time',sub { $_[0]{execution}{report}{reported_ns}='1' }],
        ['admission time',sub { $_[0]{execution}{admitted}{checked_ns}='1' }],
        ['latest state',sub { $_[0]{execution}{latest}{state}='pending' }],
        ['failure',sub { $_[0]{execution}{failure}{diagnostic}='later forged cause' }],
        ['extra root key',sub { $_[0]{extra}=undef }],
        ['extra nested key',sub { $_[0]{execution}{latest}{extra}=undef }],
        ['undefined parent',sub { $_[0]{parent}=undef }],
        ['wrong reference type',sub { $_[0]{execution}{report}=[] }],
    );
    for my $change (@changes) {
        my ($ticket,$client,$grant)=setup();execute($ticket,$grant);$after_take=$change->[1];
        like(close_until_error($change->[0]),qr/closed outcome disagrees with its original retained observation/,"$change->[0] mismatch refuses after actual consumption");
        is_deeply($owner->{service}->tickets,[],'mismatch occurs after actual original record retirement');
        retained($ticket);$after_take=undef;finish();retained($ticket);
        like($owner->observation->{failure},qr/closed outcome disagrees/,'retry keeps original mismatch cause');
    }
};

subtest 'all peers are retained before a lost first consumption return' => sub {
    my ($first,$client,$grant)=setup();execute($first,$grant);
    my ($second)=request();my ($first_call,$consumed)=(1);
    $after_take=sub { $consumed=$_[0]{ticket};die "selected first peer return loss\n" if $first_call-- };
    like(close_until_error(),qr/selected first peer return loss/,'one original peer is consumed before interruption');
    retained($first);retained($second);
    is($expected{$first}{job},2,'first peer retains its executed job');
    is($expected{$second}{job},3,'second peer retains its distinct unexecuted job');
    ok($expected{$first}{execution} && !exists $expected{$second}{execution},'execution histories remain associated with their original peers');
    is_deeply($owner->{service}->tickets,[grep { $_ != $consumed } ($first,$second)],'only the original unconsumed Service record remains');
    $after_take=undef;finish();retained($first);retained($second);is($takes,2,'retry consumes only the remaining original peer');
};

subtest 'unbound peer outcomes preserve absent job and present undefined parent' => sub {
    for my $altered (0,1) {
        %expected=();$takes=0;$before_take=$after_take=undef;ready_owner();
        my $client=FSM::Support::ProcessSupervisor::Endpoint::connect_context($owner->context);push @clients,$client;
        until_service(sub { @{$owner->peer_tickets} ? 1:undef });my ($ticket)=@{$owner->peer_tickets};
        if ($altered) {
            $after_take=sub { delete $_[0]{parent};$_[0]{replacement}=undef };
            like(close_until_error(),qr/closed outcome disagrees with its original retained observation/,
                'an absent undefined key cannot be replaced by another undefined key');
            $after_take=undef;
        }
        finish();retained($ticket);my $outcome=$owner->peer_observation($ticket)->{outcome};
        ok(exists($outcome->{parent}) && !defined($outcome->{parent}),'unauthenticated parent is present and undefined');
        ok(!exists($outcome->{job}) && !exists($outcome->{execution}),'unbound peer fabricates no job or execution history');
        is($writes,0,'unbound outcome executes no E');
    }
};

alarm 0;
defined POSIX::sigprocmask(SIG_SETMASK,$saved_mask) or die 'cannot restore outcome creator mask';
done_testing;
