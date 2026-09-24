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
    return {type=>'SPAWN',started_ns=>ns(now()),schema=>'nested.effect',stage=>'probe',
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
local $SIG{ALRM}=sub { die "nested effect fixture deadline\n" };alarm 90;

# Advance the original wrapper directly to qualify reporting independently
# from the aggregate advancement/lifetime integration exercised by T1863.
sub released_request {
    ready_owner();my ($ticket,$client,$grant)=request();my ($peer,$native)=queue_check($ticket);
    $native->advance;
    is($native->observation->{command}{released},1,'original Pair confirms actual E');
    is($writes,1,'independent native syscall observer confirms E');
    return ($ticket,$client,$grant,$peer,$native);
}

subtest 'no effect and transient writes cannot fabricate confirmation' => sub {
    ready_owner();my ($ticket,$client,$grant)=request();my $peer=$owner->{peers}{$ticket};
    is($owner->_record_request_execution($peer),0,'ready child has no effect to report');
    my (undef,$native)=queue_check($ticket);
    my $copy=$owner->job_observation($grant);$copy->{native}{command}{released}=1;
    is($owner->_record_request_execution($peer),0,'copied native confirmation grants no report');
    for my $fault ('EAGAIN','EINTR') {
        $mode=$fault;$native->advance;
        is($owner->_record_request_execution($peer),0,'returned transient attempt remains unconfirmed');
        ok(!$owner->peer_observation($ticket)->{execution},'transient attempt freezes no effect observation');
    }
    is($report_calls,0,'no Service report without confirmed E');is($writes,0,'transient attempts execute no E');
    $mode='';$native->advance;
    is($owner->_record_request_execution($peer),1,'fresh confirmed E reports after transient attempts');
    is($report_calls,1,'confirmed retry issues its original report once');finish();
};

subtest 'confirmed effect and first report retain original identities and clocks' => sub {
    my ($ticket,$client,$grant,$peer,$native)=released_request();
    my @before=($forks,$pipe_calls,$attempts);my $issued=$peer->{execution_grant}{issued_ns};
    is($owner->_record_request_execution($peer),1,'confirmed E publishes its original Service report');
    my $view=$owner->peer_observation($ticket)->{execution};
    is_deeply([@{$view->{native}}{qw(state job parent deadline_ns)}],['confirmed',2,1,$peer->{request}{deadline_ns}],'native observation names exact original request owners and wall');
    is($view->{report}{admission_issued_ns},$issued,'report retains pre-effect admission time');
    is($view->{report}{deadline_ns},$peer->{request}{deadline_ns},'report retains original execution deadline');
    is_deeply($view->{report},$owner->{service}->execution_observation($ticket)->{report},'retained aggregate report matches original Service');
    my $saved={native=>{%{$view->{native}}},report=>{%{$view->{report}}}};
    $view->{native}{state}='invented';$view->{report}{deadline_ns}='0';
    my $service_copy=$owner->{service}->execution_observation($ticket);$service_copy->{report}{reported_ns}='0';
    is($owner->_record_request_execution($peer),1,'repeat observation retains original confirmed report');
    is_deeply($owner->peer_observation($ticket)->{execution},$saved,'public copies cannot mutate retained history');
    is($report_calls,1,'repeat publication does not reissue a report');
    is_deeply([$forks,$pipe_calls,$attempts],\@before,'reporting neither allocates nor advances native E');
    drive($grant,'finished');is($native->finished_job->{result}{status},'success','actual nested command completes successfully');
    is($native->finished_job->{result}{stdout},join('',map { bytes($_) } 'CHILD','',"arg\n\xff","env\n\xff",$owner->{jobs}{2}{bound_context}),'confirmed effect preserves actual invocation output');
    is($owner->_record_request_execution($peer),1,'native retirement cannot erase confirmed effect');finish();
};

subtest 'delayed reports preserve admission history after its wall or closure' => sub {
    for my $cut ('admission-wall','closed','execution-wall') {
        my ($ticket,$client,$grant,$peer,$native)=released_request();
        my $admission=$peer->{request}{admission_deadline_ns};
        if ($cut eq 'closed') { $owner->{service}->retire($ticket); }
        else { $clock=$cut eq 'admission-wall'?$admission:$peer->{request}{deadline_ns}; }
        is($owner->_record_request_execution($peer),1,"$cut retains actual prior effect");
        my $view=$owner->{service}->execution_observation($ticket);
        is($view->{admission_deadline_ns},$admission,'report never renews original admission wall');
        is($view->{active_deadline_ns},$peer->{request}{deadline_ns},'Service uses frozen execution wall');
        is($view->{report}{admission_issued_ns},$peer->{execution_grant}{issued_ns},'delayed report keeps original grant clock');
        is($owner->{service}->ticket_observation($ticket)->{state},$cut eq 'admission-wall'?'bound':'closed','report never reopens closed or expired Service lifetime');
        finish();
    }
};

subtest 'uncertain actual E is observed without reporting or replaying it' => sub {
    ready_owner();my ($ticket,$client,$grant)=request();my ($peer,$native)=queue_check($ticket);$mode='lost-E';
    like(error_from(sub { $native->advance }),qr/lost nested native E return/,'actual E return loss remains explicit');
    is($writes,1,'selected syscall actually wrote E before losing its return');
    for (1..2) { is($owner->_record_request_execution($peer),0,'uncertain effect never reports confirmation'); }
    my $view=$owner->peer_observation($ticket)->{execution};
    is($view->{native}{state},'uncertain','aggregate retains original native uncertainty');
    ok(!$view->{report},'uncertainty fabricates no retained report');
    ok(!$owner->{service}->execution_observation($ticket)->{report},'uncertainty fabricates no Service report');
    is($report_calls,0,'uncertain effect never calls Service report');is($attempts,1,'observing uncertainty cannot replay E');finish();
};

subtest 'copies and substituted owners cannot report an original native effect' => sub {
    my ($ticket,$client,$grant,$peer,$native)=released_request();
    like(error_from(sub { (bless {%$owner},ref($owner))->_record_request_execution($peer) }),qr/copied coordinator/,'copied aggregate refuses effect reporting');
    like(error_from(sub { $owner->_record_request_execution({%$peer}) }),qr/original retained request/,'copied peer refuses effect reporting');
    for my $cut ('request','job','native','pair','service','grant') {
        my ($container,$key)= $cut eq 'request'?($peer,'request'):$cut eq 'job'?($peer,'job_grant'):
            $cut eq 'native'?($owner->{jobs}{2},'native'):$cut eq 'pair'?($native,'pair'):
            $cut eq 'service'?($owner,'service'):($peer,'execution_grant');
        my $original=$container->{$key};my $copy={%$original};bless $copy,ref($original) unless ref($original) eq 'HASH';
        $container->{$key}=$copy;
        ok(length(error_from(sub { $owner->_record_request_execution($peer) })),"substituted $cut refuses reporting");
        $container->{$key}=$original;
    }
    is($report_calls,0,'substituted authorities report nothing');finish();
};

subtest 'inherited aggregate cannot publish the creator effect' => sub {
    my ($ticket,$client,$grant,$peer,$native)=released_request();
    my $pid=CORE::fork();die 'cannot fork inherited owner observer' unless defined $pid;
    if (!$pid) {
        my $error=error_from(sub { $owner->_record_request_execution($peer) });
        _exit($error=~/inherited coordinator/?0:29);
    }
    my ($n,$end)=(0,now()+2);
    while (now()<$end) { $n=CORE::waitpid($pid,WNOHANG);last if $n==$pid;sleep(0.001); }
    if ($n!=$pid) { CORE::kill('KILL',$pid);CORE::waitpid($pid,0);die 'inherited observer exceeded deadline'; }
    is($?,0,'inherited owner refuses before reporting');is($report_calls,0,'creator Service remains unreported');finish();
};

subtest 'lost Service return retains its original report before creator interruption' => sub {
    my ($ticket,$client,$grant,$peer,$native)=released_request();my $seen=0;
    local $SIG{USR2}=sub {
        ++$seen;
        ok($peer->{execution}{report},'creator interruption sees retained original Service report');
        like($peer->{request_failure},qr/original report return lost/,'original first report failure precedes creator signal');
        die "later report creator interruption\n";
    };
    $report_cut=sub { CORE::kill('USR2',$$)==1 or die 'cannot queue report signal';die "original report return lost\n"; };
    like(error_from(sub { $owner->_record_request_execution($peer) }),qr/(?:original report return lost|later report creator interruption)/,'interrupted report keeps original error truth');
    is($seen,1,'actual pending creator signal is delivered');
    is_deeply(mask_state(),[1,0],'original mask restores after interrupted report');
    my $first=$peer->{request_failure};my $report={%{$peer->{execution}{report}}};$report_cut=undef;
    is($owner->_record_request_execution($peer),1,'retained report can be observed after interruption');
    is_deeply($peer->{execution}{report},$report,'repeat keeps exact original report');
    is($peer->{request_failure},$first,'repeat preserves the first request failure');is($report_calls,1,'lost report return never reissues original report');finish();
};

subtest 'report history survives failed restoration and unavailable cleanup masks' => sub {
    my ($ticket,$client,$grant,$peer,$native)=released_request();
    $report_cut=sub { $mask_fault=1;die "original report mask-cut failure\n"; };
    like(error_from(sub { $owner->_record_request_execution($peer) }),qr/original report mask-cut failure/,'first report failure survives failed remask');
    ok($peer->{execution}{report},'original report retained without needing a new mask');
    like($peer->{request_failure},qr/original report mask-cut failure/,'pure peer cause publication survives cleanup mask failure');
    is_deeply(mask_state(),[1,1],'fixture observes actual failed mask restoration');
    reset_hooks();defined POSIX::sigprocmask(SIG_SETMASK,POSIX::SigSet->new(SIGUSR1)) or die 'cannot restore effect mask';
    finish();is($writes,1,'failed remask cannot replay native E');
};

subtest 'pre-report refusal retains native truth without fabricating report history' => sub {
    my ($ticket,$client,$grant,$peer,$native)=released_request();
    { no warnings 'redefine';
    local *FSM::Support::ProcessSupervisor::Service::record_execution=sub { die "original report entry refusal\n" };
    like(error_from(sub { $owner->_record_request_execution($peer) }),qr/original report entry refusal/,'selected entry refusal propagates');
    is($peer->{execution}{native}{state},'confirmed','actual confirmed effect precedes failed report entry');
    ok(!$peer->{execution}{report},'entry refusal fabricates no report');
    ok(!$owner->{service}->execution_observation($ticket)->{report},'original Service still has no report');
    like($peer->{request_failure},qr/original report entry refusal/,'first report refusal remains retained');
    }
    finish();
};

subtest 'lost foreign and consumed grants cannot publish confirmed effects' => sub {
    for my $cut ('lost','foreign','consumed') {
        my ($ticket,$client,$grant,$peer,$native)=released_request();my $original=$peer->{execution_grant};
        if ($cut eq 'lost') { delete $peer->{execution_grant}; }
        elsif ($cut eq 'foreign') {
            my ($other_ticket,undef,$other_job)=request();my $other;
            ok($owner->{service}->execution_admission($other_ticket,$owner->job_observation($other_job)->{admission}{id},\$other),'different original peer retains its own grant');
            $peer->{execution_grant}=$other;$peer->{execution_grant_identity}=refaddr($other);
        }
        else { $owner->{service}->retire($ticket);$owner->_consume_closed_peers; }
        my $before_reports=$report_calls;
        like(error_from(sub { $owner->_record_request_execution($peer) }),qr/(?:original Service grant|different original request|original peer admission)/,"$cut authority refuses reporting");
        is($report_calls,$before_reports,'invalid original grant cannot report');
        $peer->{execution_grant}=$original;$peer->{execution_grant_identity}=refaddr($original);
        finish();
    }
};

subtest 'post-report return cuts preserve captured original report and revalidate custody' => sub {
    for my $cut ('throw','substitute') {
        my ($ticket,$client,$grant,$peer,$native)=released_request();my $original=$peer->{execution_grant};my $seen=0;
        local $SIG{USR2}=sub {
            ++$seen;ok($peer->{execution}{report},'successful report is retained before creator signal');
            if ($cut eq 'throw') { die "creator interrupted successful report\n"; }
            $peer->{execution_grant}=bless {%$original},ref($original);
        };
        $report_cut=sub { CORE::kill('USR2',$$)==1 or die 'cannot queue successful report signal'; };
        like(error_from(sub { $owner->_record_request_execution($peer) }),qr/(?:creator interrupted successful report|original Service grant)/,"$cut after report cannot return stale success");
        is($seen,1,'successful report delivers actual pending signal');
        ok($peer->{request_failure},'post-report refusal remains on original peer');
        is_deeply($peer->{execution}{report},$owner->{service}->execution_observation($ticket)->{report},'captured original report survives creator return cut');
        $peer->{execution_grant}=$original;$report_cut=undef;finish();
    }
};

subtest 'lost report return reads captured original Service after live field substitution' => sub {
    my ($ticket,$client,$grant,$peer,$native)=released_request();my $service=$owner->{service};
    $report_cut=sub { $owner->{service}=bless {%$service},ref($service);die "original report Service return lost\n"; };
    like(error_from(sub { $owner->_record_request_execution($peer) }),qr/original report Service return lost/,'substituted live field cannot erase original report failure');
    is_deeply($peer->{execution}{report},$service->execution_observation($ticket)->{report},'failure recovery reads captured original Service');
    like($peer->{request_failure},qr/original report Service return lost/,'pure original peer cause survives unavailable owner cleanup');
    $owner->{service}=$service;finish();
};

alarm 0;
defined POSIX::sigprocmask(SIG_SETMASK,$saved_mask) or die 'cannot restore effect creator mask';
done_testing;
