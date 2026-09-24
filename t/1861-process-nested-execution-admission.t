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
my (@owners,@clients,@pipes,@witnesses,%births,%selected);
my ($owner,$mode,$admission_cut,$clock,$write_limit,$inspect_interrupt,$mask_fault,$custody_cut);
my ($attempts,$writes,$forks,$pipe_calls,$checks)=(0,0,0,0,0);
my @effects;
sub now { clock_gettime(CLOCK_MONOTONIC) }
sub ns { sprintf('%.0f',$_[0]*1e9) }
sub error_from { my ($f)=@_;local $@;eval { $f->();1 };return $@ }
sub live { grep { defined($_) && defined(fileno($_)) } @_ }
sub census { [sort glob(repository_root().'/.artifacts/tmp/process-coordinator/*')] }
my $initial=census();
sub reset_hooks { $mode='';$admission_cut=$clock=$write_limit=$inspect_interrupt=$mask_fault=$custody_cut=undef }
sub mask_state {
    my $old=POSIX::SigSet->new;
    defined POSIX::sigprocmask(SIG_BLOCK,POSIX::SigSet->new,$old) or die 'cannot read nested mask';
    return [$old->ismember(SIGUSR1)?1:0,$old->ismember(SIGUSR2)?1:0];
}
sub snapshot {
    return {type=>'SPAWN',started_ns=>ns(now()),schema=>'nested.admission',stage=>'probe',
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
    die 'previous nested resources survive' if live(@pipes,@witnesses) || grep { !$_ } values %births;
    reset_hooks();@pipes=();@witnesses=();@effects=();($attempts,$writes,$forks,$pipe_calls,$checks)=(0,0,0,0,0);
    $owner=FSM::Support::ProcessSupervisor::Coordinator::prepare(snapshot=>snapshot());push @owners,$owner;
    $owner->open_run;$owner->prepare_job($owner->root);$owner->start_job($owner->root);drive($owner->root,'ready');
    return $owner;
}
sub request {
    my ($parent,$partial)=@_;$parent//=1;my $snapshot=snapshot();
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
    $write_limit=5 if $partial;
    until_service(sub { my $p=$owner->peer_observation($ticket)->{publication}{write};return 1 if $partial ? $p->{confirmed_bytes}==5 : $p->{published};return; });
    $write_limit=undef;
    my $id=$owner->job_observation($grant)->{admission}{id};
    is(read_bytes($client,$partial?5:10),substr(raw(4,pack('N',$id)),0,$partial?5:10),'literal socket bytes match actual ACCEPT publication');
    return ($ticket,$client,$grant);
}
sub queue_check {
    my ($ticket)=@_;my $peer=$owner->{peers}{$ticket};my $grant=$peer->{job_grant};
    my $native=$owner->{jobs}{$peer->{job_id}}{native};my $deadline=$owner->job_observation($grant)->{admission}{deadline_ns};
    # This fixture installs the private final check directly. The explicit
    # aggregate request-release API and effect reporting are later slices.
    $peer->{release_requested}=1;
    $native->release(sub { $owner->_before_request_execution($peer,$native,$deadline,@_) });
    return ($peer,$native,$deadline);
}
sub witness {
    my ($fh)=@_;open my $copy,'<&',$fh or die 'cannot retain exact nested witness';push @witnesses,$copy;return $copy;
}
sub killed_parent {
    my ($role)=@_;my $native=$owner->{jobs}{1}{native};my $pair=$native->{pair};
    my $pid=$role eq 'command'?$pair->observation->{command_pid}:$pair->reservation->observation->{pid};
    my $fh=witness($role eq 'command'?$native->{received}{stdout}:$pair->reservation->{read});
    is(CORE::kill('KILL',$pid),1,'actual original parent child receives the exact signal');
    ok(IO::Select->new($fh)->can_read(2),'original pipe independently witnesses parent loss');
    is(sysread($fh,my $part,32),0,'parent EOF precedes native wait inspection');
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
    CORE::close($_) for live(@witnesses);$_->close for @clients;@clients=();
    is_deeply(census(),$initial,'independent endpoint inventory returns to its original membership');
}
my $rc='FSM::Support::ProcessSupervisor::Reservation';my $pc='FSM::Support::ProcessSupervisor::GatedPair';
my $sc='FSM::Support::ProcessSupervisor::Service';my $nc='FSM::Support::ProcessSupervisor::Coordinator';
my $pipe=$rc->can('_pipe');my $rfork=$rc->can('_fork');my $cfork=$pc->can('_fork');
my $rwait=$rc->can('_wait');my $cwait=$pc->can('_wait');my $write=$pc->can('_write');
my $service_admission=$sc->can('execution_admission');my $socket_write=FSM::Support::ProcessSupervisor::Connection->can('_write_once');
my $custody=FSM::Support::ProcessSupervisor::ReservedJob->can('check_custody');
my $mask=$rc->can('_mask');my $socket_read=FSM::Support::ProcessSupervisor::Connection->can('_read_once');
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
local *FSM::Support::ProcessSupervisor::Connection::_write_once=sub {
    my @a=@_;$a[2]=$write_limit if defined($write_limit) && $a[2]>$write_limit;return $socket_write->(@a);
};
local *FSM::Support::ProcessSupervisor::Service::execution_admission=sub {
    ++$checks;
    if ($mode eq 'failed-remask') { $mask_fault=1;die "original Service admission failure\n"; }
    my $v=$service_admission->(@_);
    if ($admission_cut) { my $f=$admission_cut;$admission_cut=undef;$f->(@_); }
    return $v;
};
local *FSM::Support::ProcessSupervisor::Connection::_read_once=sub {
    if ($inspect_interrupt) { $inspect_interrupt=0;$!=EINTR;return undef; }
    return $socket_read->(@_);
};
local *FSM::Support::ProcessSupervisor::ReservedJob::check_custody=sub {
    my $v=$custody->(@_);$custody_cut->(@_) if $custody_cut;return $v;
};
local *FSM::Support::ProcessSupervisor::Reservation::_mask=sub {
    return undef if $mask_fault;
    return $mask->(@_);
};
local *FSM::Support::ProcessSupervisor::GatedPair::_write=sub {
    return $write->(@_) unless $$==$creator && $_[1] eq 'E';
    ++$attempts;my $gate=$_[0];my ($peer)=grep {
        $_->{release_requested} && $_->{job_id}>1 && $owner->{jobs}{$_->{job_id}}{native}{pair}{gate}
            && refaddr($owner->{jobs}{$_->{job_id}}{native}{pair}{gate})==refaddr($gate)
    } values %{$owner->{peers}};
    push @effects,[$peer && defined($peer->{execution_grant})?1:0,$peer && defined($peer->{execution_grant_identity})?1:0,mask_state()];
    if ($mode eq 'EAGAIN' || $mode eq 'EINTR') { $!=$mode eq 'EAGAIN'?EAGAIN:EINTR;return undef; }
    my $n=$write->(@_);++$writes if defined($n) && $n==1;
    die "lost nested native E return\n" if $mode eq 'lost-E';
    return $n;
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
        CORE::close($_) for live(@pipes,@witnesses);eval { $_->close } for @clients;eval { $_->{run}->close } for @owners;
        print STDERR (!live(@pipes,@witnesses) && !grep(!$_,values %births) && join("\0",@{census()}) eq join("\0",@$initial)
            ? "native-end-census: closed\n":"native-end-census: INCOMPLETE\n");
    }
}
my $saved_mask=POSIX::SigSet->new;
defined POSIX::sigprocmask(SIG_SETMASK,POSIX::SigSet->new(SIGUSR1),$saved_mask) or die 'cannot select nested creator mask';
local $SIG{USR2}=sub { die "unexpected nested creator signal\n" };
local $SIG{ALRM}=sub { die "nested admission fixture deadline\n" };alarm 90;

subtest 'fresh original grant is retained before each actual nested E attempt' => sub {
    ready_owner();my ($ticket,$client,$grant)=request();my ($peer,$native)=queue_check($ticket);
    $owner->release_root($owner->root);
    my @before=($forks,$pipe_calls);my ($identity,$issued);
    for my $fault ('EAGAIN','EINTR','') {
        $mode=$fault;my $error=error_from(sub { $owner->advance_job($grant) });
        is($error,'','fresh original final admission permits a bounded attempt');
        ok($peer->{execution_grant},'original Service grant remains in its peer');
        $identity//=refaddr($peer->{execution_grant});$issued//=$peer->{execution_grant}{issued_ns};
        is(refaddr($peer->{execution_grant}),$identity,'transient retry retains the original grant identity');
        is($peer->{execution_grant}{issued_ns},$issued,'retry cannot renew the grant issue clock');
    }
    is($checks,3,'each native attempt performs fresh Service admission');is($attempts,3,'native retries remain bounded');is($writes,1,'only one actual native E is confirmed');
    is_deeply(\@effects,[[1,1,[1,1]],[1,1,[1,1]],[1,1,[1,1]]],'actual E observes retained original grant identity under masking');
    is_deeply([$forks,$pipe_calls],\@before,'final checks neither fork nor allocate');
    is($owner->job_observation($owner->root)->{native}{phase},'releasing','parent inspection never advances its queued execution');
    drive($grant,'finished');my $result=$native->finished_job->{result};
    is($result->{status},'success','actual nested command finishes successfully');
    is($result->{stdout},join('',map { bytes($_) } 'CHILD','',"arg\n\xff","env\n\xff",$owner->{jobs}{2}{bound_context}),'actual nested bytes retain the original bound context and binary invocation');
    ok($owner->{service}->execution_observation($ticket)->{report},'aggregate advancement reports the actual confirmed native effect');finish();
};

subtest 'partial ACCEPT and pending input never borrow copied publication authority' => sub {
    for my $kind ('publication','input') {
        ready_owner();my ($ticket,$client,$grant)=request(1,$kind eq 'publication');my ($peer)=queue_check($ticket);
        send_raw($client,substr(raw(7,pack('N',2)),0,1)) if $kind eq 'input';
        is(error_from(sub { $owner->advance_job($grant) }),'','incomplete original transport defers without host failure');
        is($attempts,0,"$kind grants no E attempt");ok(!$peer->{execution_grant},'deferral fabricates no positive grant');
        is($owner->job_observation($grant)->{native}{phase},'releasing','original queued native E stays deferred');finish();
    }
};

subtest 'original parent native loss is checked before and after Service admission' => sub {
    for my $cut ('before','after') {
        for my $role ('command','reservation') {
            ready_owner();my ($ticket,$client,$grant)=request();my ($peer)=queue_check($ticket);
            if ($cut eq 'before') { killed_parent($role); } else { $admission_cut=sub { killed_parent($role) }; }
            like(error_from(sub { $owner->advance_job($grant) }),qr/(?:custody|reservation identity)/,"$cut $role loss refuses original child execution");
            is($writes,0,'parent loss writes no E');ok($peer->{request_failure},'original peer retains failure before cleanup');finish();
        }
    }
};

subtest 'deferred input is checked afresh and completed control revokes retries' => sub {
    ready_owner();my ($ticket,$client,$grant)=request();my ($peer)=queue_check($ticket);
    $inspect_interrupt=1;
    is(error_from(sub { $owner->advance_job($grant) }),'','actual selected EINTR defers inspection');
    is($attempts,0,'interrupted input grants no native attempt');ok(!$peer->{execution_grant},'input deferral has no grant');
    $mode='EAGAIN';$owner->advance_job($grant);is($attempts,1,'fresh quiet input admits the next transient attempt');
    my $identity=refaddr($peer->{execution_grant});send_raw($client,raw(7,pack('N',2)));$mode='';
    my $error='';
    for (1..6) { $error=error_from(sub { $owner->advance_job($grant) });last if $error; }
    ok(length($error),'complete literal cancellation refuses retained execution');
    is($attempts,1,'partial and completed cancellation allow no later E attempt');
    is(refaddr($peer->{execution_grant}),$identity,'historical grant custody survives cancellation');finish();
    ready_owner();($ticket,$client,$grant)=request();queue_check($ticket);$client->close;
    ok(length(error_from(sub { $owner->advance_job($grant) })),'actual socket EOF revokes final admission');
    is($writes,0,'closed peer executes no E');finish();
};

subtest 'post-Service authority and fixed walls cannot authorize stale E' => sub {
    for my $cut (qw(phase parent-failure child-failure ledger parent-wall child-context bound-context expired)) {
        ready_owner();my ($ticket,$client,$grant)=request();my ($peer)=queue_check($ticket);
        $admission_cut=sub {
            if ($cut eq 'phase') { $owner->{phase}='failed'; }
            elsif ($cut eq 'parent-failure') { $owner->{jobs}{1}{failure}='earlier parent failure'; }
            elsif ($cut eq 'child-failure') { $owner->{jobs}{2}{failure}='earlier child failure'; }
            elsif ($cut eq 'ledger') { $owner->{ledger}->cancel($grant); }
            elsif ($cut eq 'parent-wall') { $owner->{ledger}{jobs}{1}{deadline_ns}+=1; }
            elsif ($cut eq 'child-context') { $owner->{service}->revoke_parent(2); }
            elsif ($cut eq 'bound-context') { $owner->{jobs}{2}{bound_context}.='changed'; }
            else { $clock=$peer->{request}{admission_deadline_ns}; }
        };
        ok(length(error_from(sub { $owner->advance_job($grant) })),"$cut is freshly refused after Service admission");
        is($writes,0,"$cut performs no native E write");
        ok($peer->{execution_grant},'positive historical Service grant survives final refusal');
        ok($peer->{request_failure},'original peer retains the refusing cause');finish();
    }
};

subtest 'copied callbacks and lost or substituted original grants refuse' => sub {
    ready_owner();my ($ticket,$client,$grant)=request();my ($peer,$native,$deadline)=queue_check($ticket);
    my $copy=bless {%$owner},ref($owner);
    like(error_from(sub { $copy->_before_request_execution($peer,$native,$deadline,$native->{pair}) }),qr/copied coordinator/,'copied aggregate callback refuses');
    like(error_from(sub { $owner->_before_request_execution({%$peer},$native,$deadline,$native->{pair}) }),qr/original retained callback owners/,'copied peer callback refuses');
    like(error_from(sub { $owner->_before_request_execution($peer,$native,$deadline,bless({%{$native->{pair}}},ref($native->{pair}))) }),qr/original retained callback owners/,'copied Pair callback refuses');
    is($writes,0,'copied callbacks perform no E');finish();
    for my $cut (qw(lost copied foreign prefilled)) {
        ready_owner();($ticket,$client,$grant)=request();($peer,$native)=queue_check($ticket);
        my $foreign;
        if ($cut eq 'foreign') {
            my ($other_ticket,undef,$other_grant)=request();
            ok($owner->{service}->execution_admission($other_ticket,$owner->job_observation($other_grant)->{admission}{id},\$foreign),'different original peer obtains its own Service grant');
        }
        if ($cut ne 'prefilled') { $mode='EAGAIN';$owner->advance_job($grant);$mode=''; }
        if ($cut eq 'lost') { delete $peer->{execution_grant}; }
        elsif ($cut eq 'copied') { $peer->{execution_grant}=bless {%{$peer->{execution_grant}}},ref($peer->{execution_grant}); }
        elsif ($cut eq 'foreign') { $peer->{execution_grant}=$foreign;$peer->{execution_grant_identity}=refaddr($foreign); }
        else { $peer->{execution_grant}={}; }
        like(error_from(sub { $owner->advance_job($grant) }),qr/(?:Service grant|different original request|outside original admission)/,"$cut cannot replace original grant custody");
        is($writes,0,'invalid retained grant writes no E');finish();
    }
};

subtest 'creator interruption observes original grant and first cause before return' => sub {
    for my $cut ('refusal','confirmed') {
        ready_owner();my ($ticket,$client,$grant)=request();my ($peer,$native)=queue_check($ticket);my $seen=0;
        local $SIG{USR2}=sub {
            ++$seen;ok($peer->{execution_grant},'creator sees the retained original grant');
            if ($cut eq 'refusal') {
                like($peer->{request_failure},qr/original grant return failure/,'original peer failure precedes creator signal restoration');
                is($writes,0,'failed grant return never reaches native E');
            } else {
                is($native->observation->{command}{released},1,'creator sees confirmed original native E');
                is($peer->{execution_grant_identity},refaddr($peer->{execution_grant}),'original grant identity precedes native E');
            }
            die "later nested creator interruption\n";
        };
        $admission_cut=sub {
            ok($peer->{execution_grant},'Service publishes directly into original peer before return');
            is_deeply(mask_state(),[1,1],'grant publication remains inside native E masking');
            CORE::kill('USR2',$$)==1 or die 'cannot queue nested creator signal';
            die "original grant return failure\n" if $cut eq 'refusal';
        };
        like(error_from(sub { $owner->advance_job($grant) }),qr/(?:original grant return failure|later nested creator interruption)/,'actual creator boundary preserves an original error');
        is($seen,1,'the exact pending creator signal is delivered');
        is_deeply(mask_state(),[1,0],'original creator mask is restored');
        my $truth=$native->observation->{command}{released};finish();
        is($native->observation->{command}{released},$truth,'cleanup preserves confirmed native truth');
    }
};

subtest 'failed remasking cannot erase the original admission refusal' => sub {
    ready_owner();my ($ticket,$client,$grant)=request();my ($peer)=queue_check($ticket);$mode='failed-remask';
    like(error_from(sub { $owner->advance_job($grant) }),qr/original Service admission failure/,'original Service refusal survives subsequent mask failure');
    like($peer->{request_failure},qr/original Service admission failure/,'first peer refusal needs no successful cleanup mask');
    is_deeply(mask_state(),[1,1],'fixture observes the deliberately unrestored actual mask');
    reset_hooks();defined POSIX::sigprocmask(SIG_SETMASK,POSIX::SigSet->new(SIGUSR1)) or die 'cannot repair selected nested mask';
    finish();is($writes,0,'repaired cleanup never replays refused E');
};

subtest 'lost actual E return retains its original grant without reporting confirmation' => sub {
    ready_owner();my ($ticket,$client,$grant)=request();my ($peer,$native)=queue_check($ticket);$mode='lost-E';
    like(error_from(sub { $owner->advance_job($grant) }),qr/lost nested native E return/,'actual syscall return loss is explicit');
    my $view=$native->observation->{command};
    is($view->{release_uncertain},1,'original Pair retains execution ambiguity');is($view->{released},0,'uncertain E fabricates no confirmation');
    ok($peer->{execution_grant},'original pre-effect grant survives ambiguous native return');
    ok(!$owner->{service}->execution_observation($ticket)->{report},'uncertain return fabricates no Service report');
    finish();is($attempts,1,'lost actual E is never replayed');
};

subtest 'late parent inspection cannot lose retained Service grant or live peer' => sub {
    for my $cut ('lost','copied','retired','reported') {
        ready_owner();my ($ticket,$client,$grant)=request();my ($peer)=queue_check($ticket);my $visits=0;
        $custody_cut=sub {
            return unless ++$visits==2;
            if ($cut eq 'lost') { delete $peer->{execution_grant}; }
            elsif ($cut eq 'copied') { $peer->{execution_grant}=bless {%{$peer->{execution_grant}}},ref($peer->{execution_grant}); }
            elsif ($cut eq 'retired') { $owner->{service}->retire($ticket); }
            else { $owner->{service}->record_execution($peer->{execution_grant}); } # hostile trusted-caller report
        };
        ok(length(error_from(sub { $owner->advance_job($grant) })),"$cut at final parent return revokes execution");
        is($writes,0,"$cut after earlier grant validation writes no E");finish();
    }
};

subtest 'an actually completed parent refuses E without changing its own result' => sub {
    ready_owner();$owner->release_root($owner->root);drive($owner->root,'finished');
    my $parent=$owner->{jobs}{1}{native};is($parent->finished_job->{result}{status},'success','actual parent has its original completed result');
    my ($ticket,$client,$grant)=request();queue_check($ticket);my $before=$attempts;
    like(error_from(sub { $owner->advance_job($grant) }),qr/original parent native custody/,'completed original parent grants no final native authority');
    is($attempts,$before,'completed-parent inspection adds no E attempt');
    is($parent->finished_job->{result}{status},'success','nested refusal leaves parent classification unchanged');finish();
    is($parent->finished_job->{result}{status},'success','aggregate cleanup preserves the original parent result');
};

subtest 'a nested submitting parent retains its own queued E while its child executes' => sub {
    ready_owner();my ($parent_ticket,undef,$parent_grant)=request();queue_check($parent_ticket);
    my ($ticket,$client,$grant)=request(2);my ($peer,$native)=queue_check($ticket);
    $owner->advance_job($grant);
    is($writes,1,'only the selected grandchild receives actual E');
    is_deeply($effects[-1],[1,1,[1,1]],'the exact native gate observes its own retained Service grant');
    is($owner->job_observation($parent_grant)->{native}{phase},'releasing','nested parent inspection leaves its own queued E untouched');
    is($owner->job_observation($grant)->{admission}{parent},2,'selected execution retains its original non-root parent');
    drive($grant,'finished');
    is($native->finished_job->{result}{stdout},join('',map { bytes($_) } 'CHILD','',"arg\n\xff","env\n\xff",$owner->{jobs}{3}{bound_context}),'actual grandchild receives its own original context bytes');
    finish();
};

alarm 0;
defined POSIX::sigprocmask(SIG_SETMASK,$saved_mask) or die 'cannot restore nested creator mask';
done_testing;
