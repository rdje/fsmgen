#!/usr/bin/env perl
use strict;
use warnings;
use Cwd qw(getcwd);
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
my ($queue_cut,$before_mask,$admission_cut,$write_limit,$inspect_interrupt);
my ($attempts,$writes,$forks,$pipe_calls)=(0,0,0,0);
sub now { clock_gettime(CLOCK_MONOTONIC) }
sub ns { sprintf('%.0f',$_[0]*1e9) }
sub error_from { my ($f)=@_;local $@;eval { $f->();1 };return $@ }
sub live { grep { defined($_) && defined(fileno($_)) } @_ }
sub census { [sort glob(repository_root().'/.artifacts/tmp/process-coordinator/*')] }
my $initial=census();
sub reset_hooks { $mode='';$clock=$mask_fault=$report_cut=undef;$report_calls=0;$queue_cut=$before_mask=$admission_cut=$write_limit=$inspect_interrupt=undef }
sub mask_state {
    my $old=POSIX::SigSet->new;
    defined POSIX::sigprocmask(SIG_BLOCK,POSIX::SigSet->new,$old) or die 'cannot read nested mask';
    return [$old->ismember(SIGUSR1)?1:0,$old->ismember(SIGUSR2)?1:0];
}
sub snapshot {
    return {type=>'SPAWN',started_ns=>ns(now()),schema=>'nested.release',stage=>'probe',
        containment=>'fixture-group',cwd=>'.',umask=>0027,timeout_seconds=>30,capture_limit_bytes=>4096,
        argv=>[$^X,'-MPOSIX','-MCwd=getcwd','-e','my $s=POSIX::SigSet->new;POSIX::sigprocmask(POSIX::SIG_BLOCK(),POSIX::SigSet->new,$s);syswrite STDOUT,join("",map { pack("N",length($_)).$_ } "CHILD",@ARGV,$ENV{A},$ENV{FSMGEN_PROCESS_COORDINATOR_CONTEXT},getcwd(),sprintf("%04o",umask),$s->ismember(POSIX::SIGUSR1())?1:0,$s->ismember(POSIX::SIGUSR2())?1:0);','',"arg\n\xff"],
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
    my ($parent,$complete,$stop)=@_;$parent//=1;$complete//=1;my $snapshot=snapshot();
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
    my $grant=$owner->admit_request($ticket);return ($ticket,$client,$grant) if ($stop//'') eq 'admitted';
    $owner->start_request($ticket);return ($ticket,$client,$grant) if ($stop//'') eq 'started';my $end=now()+2;
    while (now()<$end) { last if $owner->advance_request($ticket)->{publication};sleep(0.001); }
    die 'nested ACCEPT was never queued' unless $owner->peer_observation($ticket)->{publication};
    return ($ticket,$client,$grant) unless $complete;
    until_service(sub { my $p=$owner->peer_observation($ticket)->{publication}{write};return 1 if $p->{published};return; });
    my $id=$owner->job_observation($grant)->{admission}{id};
    is(read_bytes($client,10),raw(4,pack('N',$id)),'literal socket bytes match actual ACCEPT publication');
    return ($ticket,$client,$grant);
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
my $release=FSM::Support::ProcessSupervisor::ReservedJob->can('release');
my $service_admission=$sc->can('execution_admission');
my $socket_write=FSM::Support::ProcessSupervisor::Connection->can('_write_once');
my $socket_read=FSM::Support::ProcessSupervisor::Connection->can('_read_once');
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
    if ($before_mask && $_[0]==SIG_BLOCK) { my $f=$before_mask;$before_mask=undef;$f->(); }
    return undef if $mask_fault;
    return $mask->(@_);
};
local *FSM::Support::ProcessSupervisor::GatedPair::_write=sub {
    return $write->(@_) unless $$==$creator && $_[1] eq 'E';
    ++$attempts;
    if ($mode eq 'EAGAIN' || $mode eq 'EINTR') { $!=$mode eq 'EAGAIN'?EAGAIN:EINTR;return undef; }
    my $n=$write->(@_);++$writes if defined($n) && $n==1;
    CORE::kill('USR2',$$)==1 or die 'cannot queue E creator signal' if $mode eq 'E-signal';
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
local *FSM::Support::ProcessSupervisor::ReservedJob::release=sub {
    for my $peer (values %{$owner->{peers}}) {
        my $native=$owner->{jobs}{$peer->{job_id}}{native};next unless $native && refaddr($native)==refaddr($_[0]);
        ok($peer->{release_requested},'original intent precedes native queue entry');
        is_deeply(mask_state(),[1,1],'request queue retains the creator mask');
    }
    my $v=$release->(@_);$queue_cut->(@_) if $queue_cut;return $v;
};
local *FSM::Support::ProcessSupervisor::Service::execution_admission=sub {
    if ($mode eq 'admission-failed-remask') { $mask_fault=1;die "first release admission refusal\n"; }
    my $v=$service_admission->(@_);
    if ($admission_cut) { my $f=$admission_cut;$admission_cut=undef;$f->(@_); }
    return $v;
};
local *FSM::Support::ProcessSupervisor::Connection::_write_once=sub {
    my @a=@_;$a[2]=$write_limit if defined($write_limit) && $a[2]>$write_limit;return $socket_write->(@a);
};
local *FSM::Support::ProcessSupervisor::Connection::_read_once=sub {
    if ($inspect_interrupt) { $inspect_interrupt=0;$!=EINTR;return undef; }
    return $socket_read->(@_);
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
local $SIG{ALRM}=sub { die "nested release fixture deadline\n" };alarm 90;

sub expected_output {
    my ($id)=@_;
    return join('',map { bytes($_) } 'CHILD','',"arg\n\xff","env\n\xff",$owner->{jobs}{$id}{bound_context},getcwd(),'0027',1,0);
}
sub published {
    my ($ticket,$client,$id)=@_;$write_limit=undef;
    until_service(sub { $owner->peer_observation($ticket)->{publication}{write}{published} ? 1:undef });
    return;
}
sub no_execution {
    is($writes,0,'refused original request executes no E');finish();
    for my $id (grep { $_>1 } keys %{$owner->{jobs}}) {
        my $native=$owner->{jobs}{$id}{native};next unless $native;
        is($native->finished_job->{result}{stdout},'','original command pipe contains no executed output');
    }
}

subtest 'explicit release queues once and ordinary advancement executes the original invocation' => sub {
    ready_owner();my ($ticket,$client,$grant)=request();my $before=[$forks,$pipe_calls,$attempts];
    is($owner->release_request($ticket),1,'complete original ACCEPT queues one request release');
    is_deeply([$forks,$pipe_calls,$attempts],$before,'release queues without another fork, pipe or E');
    ok($owner->peer_observation($ticket)->{request}{release_requested},'public request observation retains release intent');
    ok(!$owner->{peers}{$ticket}{execution_grant},'preflight does not issue the final native-attempt grant');
    like(error_from(sub { $owner->release_request($ticket) }),qr/single-use/,'repeat release cannot overwrite original intent');
    my $copy=$owner->peer_observation($ticket);$copy->{request}{release_requested}=0;
    ok($owner->peer_observation($ticket)->{request}{release_requested},'public copy cannot reset single-use intent');
    $owner->advance_request($ticket);drive($grant,'finished');
    is($writes,1,'one actual original E is confirmed');
    is($owner->{jobs}{2}{native}->finished_job->{result}{stdout},expected_output(2),'actual child preserves binary argv/environment/context, cwd, umask and original exec mask');
    is($owner->{jobs}{1}{native}->observation->{command}{released},0,'child release never executes its submitting parent');
    finish();my $view=$owner->peer_observation($ticket);
    is($view->{execution}{native}{state},'confirmed','original aggregate retains confirmed native effect');
    is_deeply($view->{outcome}{execution}{report},$view->{execution}{report},'whole close retains the matching original execution report');
};

subtest 'unpublished and partial ACCEPT defer without blocking subsequent publication' => sub {
    for my $partial (0,1) {
        ready_owner();my ($ticket,$client,$grant)=request(1,0);my $received='';
        if ($partial) { $write_limit=1;$owner->advance_service;$received=read_bytes($client,1); }
        is($owner->release_request($ticket),0,'incomplete matching ACCEPT defers release');
        ok(!$owner->peer_observation($ticket)->{request}{release_requested},'deferred publication consumes no release intent');
        is($owner->job_observation($grant)->{native}{phase},'ready','deferred wrapper remains ready for ACCEPT write checks');
        is($attempts,0,'incomplete publication attempts no E');
        published($ticket,$client,2);$received.=read_bytes($client,10-length($received));
        is($received,raw(4,pack('N',2)),'original complete ACCEPT finishes after release deferral');
        is($owner->release_request($ticket),1,'same original ticket queues after actual full publication');
        drive($grant,'finished');is($writes,1,'only the completed original publication permits E');finish();
    }
};

subtest 'current partial control and interrupted reads defer without consuming intent' => sub {
    for my $cut ('partial','interrupted') {
        ready_owner();my ($ticket,$client,$grant)=request();
        if ($cut eq 'partial') { send_raw($client,substr(raw(7,pack('N',2)),0,1)); } else { $inspect_interrupt=1; }
        is($owner->release_request($ticket),0,"$cut inspection defers original release");
        ok(!$owner->peer_observation($ticket)->{request}{release_requested},'input deferral preserves an unused intent');
        if ($cut eq 'partial') {
            send_raw($client,substr(raw(7,pack('N',2)),1));
            my ($error,$end)=('',now()+2);
            while (now()<$end) { my $queued;$error=error_from(sub { $queued=$owner->release_request($ticket) });last if length $error;is($queued,0,'bounded partial-control progress remains deferred');sleep(0.001); }
            like($error,qr/(?:cancel|closed|live)/,'completed cancellation refuses original release');no_execution();
        }
        else { is($owner->release_request($ticket),1,'fresh quiet input admits a later original request');drive($grant,'finished');finish(); }
    }
};

subtest 'pre-mask reentry leaves the winning original release intact' => sub {
    ready_owner();my ($ticket,$client,$grant)=request();
    $before_mask=sub { is($owner->release_request($ticket),1,'earlier creator call queues the original release') };
    like(error_from(sub { $owner->release_request($ticket) }),qr/single-use/,'later masked caller observes the winning intent');
    ok(!$owner->peer_observation($ticket)->{request}{failure},'losing caller does not cancel the winner');
    drive($grant,'finished');is($writes,1,'winning request executes exactly once');
    is($owner->{jobs}{2}{native}->finished_job->{result}{stdout},expected_output(2),'winning request preserves original execution bytes');finish();
};

subtest 'foreign copied inherited and unready release inputs cannot acquire intent' => sub {
    ready_owner();my ($ticket,$client,$grant)=request();my $copy=bless {%$owner},ref($owner);
    like(error_from(sub { $copy->release_request($ticket) }),qr/copied coordinator/,'copied aggregate refuses original ticket');
    for my $bad (0,999,$owner->peer_observation($ticket),$grant,undef) {
        ok(length(error_from(sub { $owner->release_request($bad) })),'non-original ticket argument refuses');
    }
    ok(length(error_from(sub { $owner->release_request($ticket,'extra') })),'extra release argument refuses');
    my $foreign=FSM::Support::ProcessSupervisor::Coordinator::prepare(snapshot=>snapshot());push @owners,$foreign;
    like(error_from(sub { $foreign->release_request($ticket) }),qr/unknown retained peer ticket/,'foreign aggregate has no matching original ticket');$foreign->close;
    my $pid=CORE::fork();die 'cannot fork inherited request observer' unless defined $pid;
    if (!$pid) { _exit(error_from(sub { $owner->release_request($ticket) }) =~ /inherited coordinator/?0:1); }
    $births{$pid}=0;my ($n,$status,$end)=(0,undef,now()+3);
    while (now()<$end) { $n=CORE::waitpid($pid,WNOHANG);$status=$?;last if $n==$pid;sleep(0.001); }
    $births{$pid}=1 if $n==$pid;is($n,$pid,'inherited observer has its exact original wait');is($status,0,'inherited aggregate refuses release');
    ok(!$owner->peer_observation($ticket)->{request}{release_requested},'invalid callers publish no original intent');no_execution();
    for my $stage ('admitted','started') {
        ready_owner();my ($unready,$c,$g)=request(1,0,$stage);
        like(error_from(sub { $owner->release_request($unready) }),qr/active ready job/,"actual $stage job refuses before native readiness");no_execution();
    }
};

subtest 'preflight rechecks original authority after the Service admission return' => sub {
    for my $cut ('cancel','expiry','failure','context','packet') {
        ready_owner();my ($ticket,$client,$grant)=request();my $peer=$owner->{peers}{$ticket};my $packet=$peer->{request};
        $admission_cut=sub {
            if ($cut eq 'cancel') { $owner->{service}->retire($ticket); }
            elsif ($cut eq 'expiry') { $clock=$packet->{admission_deadline_ns}; }
            elsif ($cut eq 'failure') { $owner->{jobs}{2}{failure}='original release boundary failure'; }
            elsif ($cut eq 'context') { $owner->{service}->revoke_parent(2); }
            else { $peer->{request}={%$packet}; }
        };
        ok(length(error_from(sub { $owner->release_request($ticket) })),"$cut at admission return refuses before queue");
        ok(!$peer->{release_requested},'changed authority cannot publish release intent');
        $peer->{request}=$packet;no_execution();
    }
};

subtest 'creator queue interruption retains intent and the first original cause' => sub {
    for my $cut ('signal','failure') {
        ready_owner();my ($ticket,$client,$grant)=request();my $seen=0;
        $queue_cut=sub {
            CORE::kill('USR2',$$)==1 or die 'cannot queue release creator signal';
            die "first original request queue failure\n" if $cut eq 'failure';
        };
        local $SIG{USR2}=sub {
            ++$seen;ok($owner->peer_observation($ticket)->{request}{release_requested},'handler sees original intent before return');
            like($owner->job_observation($grant)->{failure},qr/first original request queue failure/,'first queue failure precedes signal restoration') if $cut eq 'failure';
            die "later request creator interruption\n";
        };
        like(error_from(sub { $owner->release_request($ticket) }),qr/(?:first original request queue failure|later request creator interruption)/,'creator signal interrupts queue return');
        is($seen,1,'one actual queued creator signal is consumed');
        like($owner->peer_observation($ticket)->{request}{failure},$cut eq 'failure'?qr/first original request queue failure/:qr/later request creator interruption/,'request retains first original cause');
        unlike($owner->peer_observation($ticket)->{request}{failure},qr/later request creator interruption/,'later creator error cannot join the original first cause') if $cut eq 'failure';
        is_deeply(mask_state(),[1,0],'original creator mask is restored');no_execution();
    }
};


subtest 'lost native queue returns preserve refusal despite substituted cleanup custody' => sub {
    ready_owner();my ($ticket,$client,$grant)=request();my $service=$owner->{service};
    my $entry=$owner->{jobs}{2};my $peer=$owner->{peers}{$ticket};
    $queue_cut=sub { $owner->{service}=bless {%$service},ref($service);die "first original queue return loss\n" };
    like(error_from(sub { $owner->release_request($ticket) }),qr/first original queue return loss/,'original queue return failure is preserved');
    like($entry->{failure},qr/first original queue return loss/,'original job cause precedes failed cleanup custody');
    like($peer->{request_failure},qr/first original queue return loss/,'original peer cause precedes failed cleanup custody');
    like($peer->{cleanup_error},qr/lost or substituted original Service/,'cleanup custody refusal is retained separately');
    $owner->{service}=$service;reset_hooks();error_from(sub { $owner->advance_job($grant) });no_execution();
};

subtest 'failed signal restoration or remasking cannot leave executable intent' => sub {
    for my $cut ('queue','admission') {
        ready_owner();my ($ticket,$client,$grant)=request();
        if ($cut eq 'queue') { $queue_cut=sub { $mask_fault=1 }; } else { $mode='admission-failed-remask'; }
        like(error_from(sub { $owner->release_request($ticket) }),qr/(?:mask|signal|first release admission refusal)/,'fatal mask failure propagates');
        ok($owner->peer_observation($ticket)->{request}{failure},'original request refusal survives failed remasking');
        ok($owner->job_observation($grant)->{failure},'original job refusal survives failed remasking');
        is_deeply(mask_state(),[1,1],'injected failed restoration leaves actual mask blocked');reset_hooks();
        defined POSIX::sigprocmask(SIG_SETMASK,POSIX::SigSet->new(SIGUSR1)) or die 'cannot repair fixture mask';
        error_from(sub { $owner->advance_job($grant) });no_execution();
    }
};

subtest 'each later E attempt checks fresh input and original lifetime' => sub {
    for my $cut ('cancel','eof','expiry','transient') {
        ready_owner();my ($ticket,$client,$grant)=request();is($owner->release_request($ticket),1,'original request queues before later boundary');
        if ($cut eq 'cancel') { send_raw($client,raw(7,pack('N',2))); }
        elsif ($cut eq 'eof') { $client->close; }
        elsif ($cut eq 'expiry') { $clock=$owner->{peers}{$ticket}{request}{admission_deadline_ns}; }
        else { $mode='EAGAIN';$owner->advance_job($grant);is($attempts,1,'first actual attempt returns a native transient');$mode='';send_raw($client,raw(7,pack('N',2))); }
        error_from(sub { $owner->advance_job($grant) });no_execution();
    }
};


subtest 'nested release leaves parent E queued and refuses actual parent loss' => sub {
    for my $lost (0,1) {
        ready_owner();my ($ticket,$client,$grant)=request();$owner->release_root($owner->root);
        is($owner->release_request($ticket),1,'original nested release can queue under an unexecuted parent intent');
        if ($lost) {
            my $parent=$owner->{jobs}{1}{native};my $pid=$parent->observation->{command}{command_pid};
            open my $witness,'<&',$parent->{received}{stdout} or die 'cannot retain parent-loss witness';
            is(CORE::kill('KILL',$pid),1,'actual original parent command receives its exact signal');
            ok(IO::Select->new($witness)->can_read(2),'independent parent pipe witnesses native loss');
            is(sysread($witness,my $part,32),0,'actual parent EOF precedes nested final admission');CORE::close($witness);
            error_from(sub { $owner->advance_job($grant) });no_execution();
        }
        else {
            drive($grant,'finished');is($writes,1,'only the selected child writes actual E');
            is($owner->{jobs}{1}{native}->observation->{command}{released},0,'fresh parent custody checks never advance queued parent E');finish();
        }
    }
};

subtest 'confirmed and uncertain E survive interrupted advancement after public release' => sub {
    for my $cut ('E-signal','lost-E') {
        ready_owner();my ($ticket,$client,$grant)=request();$owner->release_request($ticket);$mode=$cut;
        local $SIG{USR2}=sub { die "first confirmed request E interruption\n" };
        like(error_from(sub { $owner->advance_job($grant) }),qr/(?:first confirmed request E interruption|lost nested native E return)/,'actual original E return is interrupted');
        my $view=$owner->peer_observation($ticket);
        is($view->{execution}{native}{state},$cut eq 'E-signal'?'confirmed':'uncertain','original effect truth survives interrupted advancement');
        is(defined($view->{execution}{report})?1:0,$cut eq 'E-signal'?1:0,'only confirmed E receives a Service report');
        is($writes,1,'one actual original E escaped');finish();is($attempts,1,'interrupted E is never replayed');
    }
};

alarm 0;
defined POSIX::sigprocmask(SIG_SETMASK,$saved_mask) or die 'cannot restore request release creator mask';
done_testing;
