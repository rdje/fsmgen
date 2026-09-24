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
my ($owner,$mode,$clock,$mask_fault,$report_cut,$report_calls,$advance_cut,$report_entry_cut,$e_cut);
my ($attempts,$writes,$forks,$pipe_calls)=(0,0,0,0);
sub now { clock_gettime(CLOCK_MONOTONIC) }
sub ns { sprintf('%.0f',$_[0]*1e9) }
sub error_from { my ($f)=@_;local $@;eval { $f->();1 };return $@ }
sub live { grep { defined($_) && defined(fileno($_)) } @_ }
sub census { [sort glob(repository_root().'/.artifacts/tmp/process-coordinator/*')] }
my $initial=census();
sub reset_hooks { $mode='';$clock=$mask_fault=$report_cut=$advance_cut=$report_entry_cut=$e_cut=undef;$report_calls=0 }
sub mask_state {
    my $old=POSIX::SigSet->new;
    defined POSIX::sigprocmask(SIG_BLOCK,POSIX::SigSet->new,$old) or die 'cannot read nested mask';
    return [$old->ismember(SIGUSR1)?1:0,$old->ismember(SIGUSR2)?1:0];
}
sub snapshot {
    return {type=>'SPAWN',started_ns=>ns(now()),schema=>'nested.lifetime',stage=>'probe',
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
my $service_advance=$sc->can('advance');
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
    $e_cut->() if $e_cut && defined($n) && $n==1;
    die "lost nested native E return\n" if $mode eq 'lost-E';
    return $n;
};
local *FSM::Support::ProcessSupervisor::Service::record_execution=sub {
    ++$report_calls;
    my $peer=$owner->{peers}{$_[1]{ticket}};
    is($peer->{execution}{native}{state},'confirmed','original native observation precedes the Service report call');
    is_deeply(mask_state(),[1,1],'effect observation and report remain under the creator mask');
    $report_entry_cut->(@_) if $report_entry_cut;
    my $v=$record_execution->(@_);
    $report_cut->(@_) if $report_cut;
    return $v;
};
local *FSM::Support::ProcessSupervisor::Service::advance=sub {
    $advance_cut->(@_) if $advance_cut;return $service_advance->(@_);
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
local $SIG{ALRM}=sub { die "nested lifetime fixture deadline\n" };alarm 90;

sub effect_request {
    my ($direct)=@_;ready_owner();my ($ticket,$client,$grant)=request();my ($peer,$native)=queue_check($ticket);
    if ($direct) { $native->advance; } else { $owner->advance_job($grant); }
    is($native->observation->{command}{released},1,'original Pair confirms the actual selected E');
    is($writes,1,'independent write observer confirms actual E');
    return ($ticket,$client,$grant,$peer,$native);
}

subtest 'ordinary native advancement reports before returning' => sub {
    my ($ticket,$client,$grant,$peer,$native)=effect_request();
    ok($peer->{execution}{report},'aggregate advancement retains original report before return');
    is($report_calls,1,'actual effect issues its Service report once');
    my $report={%{$peer->{execution}{report}}};
    $owner->advance_request($ticket);
    is_deeply($peer->{execution}{report},$report,'request advancement preserves first report clocks');
    is($report_calls,1,'later advancement does not reissue original report');
    drive($grant,'finished');
    is($native->finished_job->{result}{stdout},join('',map { bytes($_) } 'CHILD','',"arg\n\xff","env\n\xff",$owner->{jobs}{2}{bound_context}),'integrated native command retains original binary invocation and context');
    finish();
};

subtest 'Service advancement reconciles delayed E before the admission wall is applied' => sub {
    my ($ticket,$client,$grant,$peer,$native)=effect_request(1);
    ok(!$owner->{service}->execution_observation($ticket)->{report},'direct native advancement leaves the report pending');
    my $admission=$peer->{request}{admission_deadline_ns};$clock=$admission;my $seen=0;
    $advance_cut=sub {
        ++$seen;
        ok($peer->{execution}{report},'retained aggregate report precedes Service advancement');
        ok($owner->{service}->execution_observation($ticket)->{report},'original Service report precedes its old admission check');
    };
    is(error_from(sub { $owner->advance_service }),'','delayed confirmed E survives the original admission boundary');
    is($seen,1,'the actual original Service advances once');$advance_cut=undef;
    is($peer->{transport}{state},'bound','confirmed execution keeps its original bound peer');
    is($peer->{transport}{wall_ns},$admission,'historical admission wall remains exact');
    is($peer->{transport}{active_deadline_ns},$peer->{request}{deadline_ns},'active Service wall is original execution deadline');
    is(error_from(sub { $owner->_request_live($peer) }),'','aggregate liveness agrees with original confirmed execution');
    is($attempts,1,'lifetime reconciliation adds no native E attempt');finish();
};

subtest 'request and job liveness reconcile delayed E without renewing a deadline' => sub {
    for my $entry ('request','job') {
        my ($ticket,$client,$grant,$peer,$native)=effect_request(1);
        my $deadline=$peer->{request}{deadline_ns};my $issued=$peer->{execution_grant}{issued_ns};
        $clock=$peer->{request}{admission_deadline_ns};
        is(error_from(sub { $entry eq 'request' ? $owner->advance_request($ticket) : $owner->advance_job($grant) }),'',"$entry advancement reconciles before admission expiry");
        is($peer->{execution}{report}{deadline_ns},$deadline,'liveness preserves original execution wall');
        is($peer->{execution}{report}{admission_issued_ns},$issued,'liveness preserves original admission issue time');
        ok(!$peer->{request_failure},'confirmed execution creates no admission-expiry failure');
        is($attempts,1,'liveness cannot replay selected E');finish();
    }
};

subtest 'unreleased and transient attempts still expire on the admission wall' => sub {
    for my $kind ('ready','transient') {
        ready_owner();my ($ticket,$client,$grant)=request();my $peer=$owner->{peers}{$ticket};
        if ($kind eq 'transient') { queue_check($ticket);$mode='EAGAIN';$owner->advance_job($grant); }
        $clock=$peer->{request}{admission_deadline_ns};
        is(error_from(sub { $owner->advance_service }),'',"$kind expiry closes its peer through ordinary Service advancement");
        is($peer->{transport}{state},'closed','unconfirmed peer keeps the original expiry');
        is($peer->{transport}{failure}{status},'timed_out','original admission expiry remains classified');
        ok(!$peer->{execution},'no confirmed or uncertain effect is fabricated');
        is($report_calls,0,'unconfirmed attempt cannot extend Service lifetime');is($writes,0,'expiry executes no E');finish();
    }
};

subtest 'a Service report or copied observation alone cannot extend aggregate lifetime' => sub {
    ready_owner();my ($ticket,$client,$grant)=request();my ($peer,$native)=queue_check($ticket);
    $mode='EAGAIN';$owner->advance_job($grant);
    # Service is a trusted reporter, not a native proof source. Deliberately
    # submit an unsupported report through its real API to test the aggregate.
    $record_execution->($owner->{service},$peer->{execution_grant});
    my $copy=$owner->peer_observation($ticket);$copy->{execution}={native=>{state=>'confirmed'},report=>{deadline_ns=>$peer->{request}{deadline_ns}}};
    like(error_from(sub { $owner->_request_live($peer) }),qr/lifetime disagrees with original native execution truth/,'unsupported Service history cannot authorize aggregate execution lifetime');
    ok(!$peer->{execution},'copied confirmation does not become original native history');
    is($writes,0,'unsupported report and public copy execute no E');finish();
};

subtest 'actual lost E return retains uncertainty and the original advancement failure' => sub {
    ready_owner();my ($ticket,$client,$grant)=request();my ($peer,$native)=queue_check($ticket);$mode='lost-E';
    like(error_from(sub { $owner->advance_job($grant) }),qr/lost nested native E return/,'original native return failure propagates');
    is($peer->{execution}{native}{state},'uncertain','ordinary advancement reconciles original uncertainty before cleanup');
    ok(!$peer->{execution}{report},'uncertain native effect fabricates no report');
    like($peer->{request_failure},qr/lost nested native E return/,'native failure remains the first request cause');
    is($report_calls,0,'uncertain effect never reports confirmation');
    $clock=$peer->{request}{admission_deadline_ns};
    is(error_from(sub { $owner->advance_service }),'','later Service advancement preserves retained uncertainty');
    is($attempts,1,'uncertain execution is never replayed');is($writes,1,'fixture really wrote E before losing the return');finish();
};

subtest 'delayed confirmation precedes completed cancellation and socket EOF' => sub {
    for my $cut ('cancel','eof') {
        my ($ticket,$client,$grant,$peer,$native)=effect_request(1);
        if ($cut eq 'cancel') { send_raw($client,raw(7,pack('N',2))); } else { $client->close; }
        $clock=$peer->{request}{admission_deadline_ns};
        until_service(sub { $peer->{transport}{state} eq 'closed'?1:undef });
        ok($peer->{execution}{report},"$cut retains actual prior confirmed effect");
        is($peer->{transport}{failure}{status},$cut eq 'cancel'?'cancelled':'peer_closed',"$cut keeps its original transport cause");
        unlike($peer->{request_failure},qr/admission deadline/,'old admission expiry does not replace transport cause');
        is($report_calls,1,'transport closure keeps one original report');finish();
    }
};

subtest 'confirmed execution never renews its original execution deadline' => sub {
    my ($ticket,$client,$grant,$peer,$native)=effect_request(1);
    my $deadline=$peer->{request}{deadline_ns};$clock=$deadline;
    error_from(sub { $owner->advance_service });
    is($peer->{execution}{report}{deadline_ns},$deadline,'expired execution retains its fixed original wall');
    is($owner->{service}->ticket_observation($ticket)->{state},'closed','confirmed E cannot reopen an expired lifetime');
    is($owner->{service}->ticket_observation($ticket)->{failure}{status},'timed_out','execution expiry retains timeout classification');
    ok(length(error_from(sub { $owner->_request_live($peer) })),'expired aggregate liveness refuses');
    is($attempts,1,'expired execution adds no E attempt');finish();
};

subtest 'lost report return during advancement is reconciled once with its first failure' => sub {
    for my $cut ('plain','substituted-Service') {
        ready_owner();my ($ticket,$client,$grant)=request();my ($peer,$native)=queue_check($ticket);my $service=$owner->{service};
        $report_cut=sub {
            $owner->{service}=bless {%$service},ref($service) if $cut eq 'substituted-Service';
            die "integrated original report return lost\n";
        };
        like(error_from(sub { $owner->advance_job($grant) }),qr/integrated original report return lost/,"$cut report return loss propagates from ordinary advancement");
        ok($peer->{execution}{report},'original report survives the lost return');
        like($peer->{request_failure},qr/integrated original report return lost/,'request retains first integrated report failure');
        is($report_calls,1,'advancement does not retry a failed report transaction');
        like($owner->{jobs}{2}{cleanup_error},qr/lost or substituted original Service/,'cleanup custody failure is retained separately') if $cut eq 'substituted-Service';
        $owner->{service}=$service;$report_cut=undef;$owner->advance_service;
        is($report_calls,1,'later reconciliation uses the original retained report');finish();
    }
};

subtest 'closing reconciles confirmed effect before consuming original Service custody' => sub {
    my ($ticket,$client,$grant,$peer,$native)=effect_request(1);my $seen=0;
    my $take=$sc->can('take_closed');
    no warnings 'redefine';
    local *FSM::Support::ProcessSupervisor::Service::take_closed=sub {
        ++$seen;ok($peer->{execution}{report},'closed consumption sees retained original effect report');
        ok($_[0]->execution_observation($ticket)->{report},'closed consumption sees matching original Service report');
        return $take->(@_);
    };
    finish();is($seen,1,'original Service outcome is consumed once');
    ok($owner->peer_observation($ticket)->{execution}{report},'native effect report remains after original Service grant is spent');
    my $before=$report_calls;$owner->close;
    is($report_calls,$before,'repeated closed observation never reuses spent Service grant');
};

subtest 'nested parent admission remains authoritative after its child executes' => sub {
    ready_owner();my ($parent_ticket,undef,$parent_grant)=request();queue_check($parent_ticket);
    my ($ticket,$client,$grant)=request(2);my ($peer,$native)=queue_check($ticket);
    $native->advance;is($writes,1,'only the selected grandchild executes actual E');
    $clock=$peer->{request}{admission_deadline_ns};
    like(error_from(sub { $owner->_request_live($peer) }),qr/admission deadline expired/,'unexecuted ancestor keeps its original admission wall');
    ok($peer->{execution}{report},'grandchild retains its real effect before ancestor liveness refusal');
    is($owner->job_observation($parent_grant)->{native}{command}{released},0,'grandchild reconciliation never advances its parent E');finish();
};

subtest 'creator interruption after confirmed E precedes later report failures' => sub {
    for my $cut ('native-only','report-return','report-entry') {
        ready_owner();my ($ticket,$client,$grant)=request();my ($peer,$native)=queue_check($ticket);my $seen=0;
        local $SIG{USR2}=sub {
            ++$seen;
            is($native->observation->{command}{released},1,'creator interruption observes actual confirmed E');
            is($report_calls,0,'creator interruption precedes aggregate report recovery');
            die "first native creator interruption\n";
        };
        $e_cut=sub { CORE::kill('USR2',$$)==1 or die 'cannot queue native creator interruption'; };
        $report_cut=sub { die "later integrated report return loss\n" } if $cut eq 'report-return';
        $report_entry_cut=sub { die "later integrated report entry refusal\n" } if $cut eq 'report-entry';
        like(error_from(sub { $owner->advance_job($grant) }),qr/first native creator interruption/,"$cut returns the original native cause");
        is($seen,1,'exact pending creator signal was delivered');
        is($peer->{execution}{native}{state},'confirmed','report recovery retains confirmed native truth');
        is(defined($peer->{execution}{report})?1:0,$cut eq 'report-entry'?0:1,'report history matches actual Service publication');
        like($peer->{request_failure},qr/first native creator interruption/,'native cause precedes report recovery on original peer');
        like($owner->job_observation($grant)->{failure},qr/first native creator interruption/,'native cause precedes report recovery on original job');
        is($report_calls,1,'native interruption permits one report recovery attempt');
        is_deeply(mask_state(),[1,0],'original creator mask is restored');finish();
    }
};

subtest 'returned native cancellation keeps its first peer cause before revocation' => sub {
    ready_owner();my ($ticket,$client,$grant)=request();my $peer=$owner->{peers}{$ticket};my $native=$owner->{jobs}{2}{native};
    $native->cancel('first original native cancellation',now()+4);
    is(error_from(sub { $owner->advance_job($grant) }),'','ordinary advancement observes a returned native failure');
    like($peer->{request_failure},qr/first original native cancellation/,'returned native failure precedes peer authority revocation');
    like($owner->job_observation($grant)->{failure},qr/first original native cancellation/,'returned native failure remains on original job');
    is($writes,0,'cancelled native command executes no E');finish();
};

subtest 'retained native failure precedes report recovery at request liveness entry' => sub {
    my ($ticket,$client,$grant,$peer,$native)=effect_request(1);
    $native->cancel('first retained native failure',now()+4);
    $report_entry_cut=sub { die "later retained-effect report entry refusal\n" };
    like(error_from(sub { $owner->advance_job($grant) }),qr/later retained-effect report entry refusal/,'new report refusal remains the call failure');
    like($peer->{request_failure},qr/first retained native failure/,'retained native failure precedes liveness report recovery on original peer');
    like($owner->job_observation($grant)->{failure},qr/first retained native failure/,'retained native failure precedes liveness report recovery on original job');
    is($peer->{execution}{native}{state},'confirmed','earlier confirmed E survives the native and report failures');finish();
};

alarm 0;
defined POSIX::sigprocmask(SIG_SETMASK,$saved_mask) or die 'cannot restore lifetime creator mask';
done_testing;
