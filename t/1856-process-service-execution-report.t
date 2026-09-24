#!/usr/bin/env perl
use strict;
use warnings;
use Errno qw(EAGAIN ECHILD);
use IO::Select;
use Math::BigInt;
use POSIX qw(SIG_BLOCK SIG_UNBLOCK SIG_SETMASK SIGUSR1 SIGUSR2 WNOHANG _exit);
use Scalar::Util qw(refaddr);
use Time::HiRes qw(CLOCK_MONOTONIC clock_gettime sleep);
use Test::More;
use lib 'perl', 't/lib';
use FSM::Test::ProjectDataLocality;
use FSM::ProjectDataLocality qw(repository_root);
use FSM::Support::ProcessSupervisor::Service ();

my $creator = $$;
my (@services, @clients, %children, %selected_requests);
my $clock_ns;
my ($write_size, $inspect_hook, $publication_hook, $before_mask, $clock_hook);
my (@reads, @inspections); my $accepts=0;
my $writes = 0;
sub now { clock_gettime(CLOCK_MONOTONIC) }
sub ns { sprintf('%.0f', $_[0] * 1_000_000_000) }
sub error_from { my ($code) = @_; local $@; eval { $code->(); 1 }; return $@ }
sub census { [sort glob(repository_root() . '/.artifacts/tmp/process-coordinator/*')] }
my $initial = census();
sub raw { pack('NCC', length($_[1]) + 2, 1, $_[0]) . $_[1] }
sub bytes { pack('N', length($_[0])) . $_[0] }
sub spawn_frame {
    my ($started, $timeout) = @_;
    my ($hi, $lo) = Math::BigInt->new($started)->bdiv(4_294_967_296);
    return raw(3, pack('NN', $hi->numify, $lo->numify)
        . bytes('execution.report.schema') . bytes('probe') . bytes('fixture-group') . bytes('.')
        . pack('NNNN', $timeout, 64, 18, 3)
        . bytes('never-executed') . bytes('') . bytes("high\xff\n")
        . pack('N', 2) . bytes('A') . bytes('') . bytes('B') . bytes("space and\nnewline"));
}
sub until_value {
    my ($s, $read) = @_; my $end = now() + 2;
    while (now() < $end) {
        $s->advance; my $value = $read->(); return $value if defined $value;
        sleep(0.001);
    }
    die 'Service publication observer expired';
}
sub send_raw {
    my ($c, $raw) = @_; my $end = now() + 2;
    while (length $raw && now() < $end) {
        my $n = syswrite($c->handle, $raw, length $raw);
        if (defined($n) && $n > 0) { substr($raw, 0, $n, ''); next; }
        die 'Service publication raw write failed' unless !defined($n) && $! == EAGAIN;
        sleep(0.001);
    }
    die 'Service publication raw write observer expired' if length $raw;
}
sub service {
    my ($root_deadline) = @_;
    my $run = FSM::Support::ProcessSupervisor::Endpoint::create_run();
    my $s = FSM::Support::ProcessSupervisor::Service::new_service($run, $root_deadline // ns(now() + 25));
    push @services, $s; return $s;
}
sub request {
    my ($s, $context, $started, $timeout) = @_;
    $context //= $s->context; $started //= $clock_ns // ns(now()); $timeout //= 20;
    my $c = FSM::Support::ProcessSupervisor::Endpoint::connect_context($context);
    push @clients, $c;
    until_value($s, sub { IO::Select->new($c->handle)->can_write(0) && $c->connection_ready ? 1 : undef });
    my @v = split /:/, $context;
    send_raw($c, raw(1, pack('H*', $v[2]) . pack('N', $v[3]) . pack('H*', $v[4])));
    my $ready = '';
    until_value($s, sub {
        my $n = sysread($c->handle, my $part, 26 - length $ready);
        $ready .= $part if defined($n) && $n > 0;
        return length($ready) == 26 ? 1 : undef;
    });
    is($ready, raw(2, pack('H*', $v[2]) . pack('N', $v[3])), 'independent client receives literal authenticated READY');
    send_raw($c, spawn_frame($started, $timeout));
    my $ticket = until_value($s, sub {
        for my $id (@{$s->tickets}) {
            return $id if $s->ticket_observation($id)->{state} eq 'request'
                && !$selected_requests{refaddr($s)}{$id};
        }
        return;
    });
    $selected_requests{refaddr($s)}{$ticket} = 1;
    return ($ticket, $c, $started);
}
sub peer_eof {
    my ($c) = @_;
    ok(IO::Select->new($c->handle)->can_read(1), 'native peer is readable after server retirement');
    is(sysread($c->handle, my $part, 1), 0, 'native peer observes empty EOF');
    ok($c->close->{ok}, 'original client closes its retained descriptor');
}
sub finish {
    my ($s) = @_; my $path = repository_root() . '/' . $s->{run}{directory};
    ok($s->close->{ok}, 'original service reports complete closure');
    ok(!-e $path, 'independent exact endpoint is absent');
}
sub mask_state {
    my $old = POSIX::SigSet->new;
    defined POSIX::sigprocmask(SIG_BLOCK, POSIX::SigSet->new, $old) or die 'cannot read transfer mask';
    return [$old->ismember(SIGUSR1) ? 1 : 0, $old->ismember(SIGUSR2) ? 1 : 0];
}
my $native_clock = FSM::Support::ProcessSupervisor::Service->can('_now_ns');
my $write = FSM::Support::ProcessSupervisor::Connection->can('_write_once');
my $read = FSM::Support::ProcessSupervisor::Connection->can('_read_once');
my $inspect = FSM::Support::ProcessSupervisor::Connection->can('inspect_input');
my $publication = FSM::Support::ProcessSupervisor::Connection->can('accept_publication');
my $accept = FSM::Support::ProcessSupervisor::Service->can('_accept_once');
my $mask = FSM::Support::ProcessSupervisor::Reservation->can('_mask');
no warnings 'redefine';
local *FSM::Support::ProcessSupervisor::Service::_now_ns = sub { $clock_hook->() if $clock_hook; return $clock_ns // $native_clock->() };
local *FSM::Support::ProcessSupervisor::Service::_accept_once = sub { ++$accepts; return $accept->(@_) };
local *FSM::Support::ProcessSupervisor::Connection::_read_once = sub { push @reads, refaddr($_[0]); return $read->(@_) };
local *FSM::Support::ProcessSupervisor::Connection::_write_once = sub {
    ++$writes; return $write->($_[0],$_[1],defined($write_size) && $write_size<$_[2] ? $write_size:$_[2]);
};
local *FSM::Support::ProcessSupervisor::Connection::inspect_input = sub {
    push @inspections, refaddr($_[0]); my $v=$inspect->(@_); $inspect_hook->($_[0]) if $inspect_hook; return $v;
};
local *FSM::Support::ProcessSupervisor::Connection::accept_publication = sub {
    my $v=$publication->(@_); $publication_hook->($v) if $publication_hook; return $v;
};
local *FSM::Support::ProcessSupervisor::Reservation::_mask = sub {
    if ($before_mask && $_[0]==SIG_BLOCK) { my $f=$before_mask; $before_mask=undef; $f->(); }
    return $mask->(@_);
};
use warnings 'redefine';
END {
    local $?;
    if ($$==$creator) {
        alarm 0; $clock_ns=$inspect_hook=$publication_hook=$before_mask=$clock_hook=undef;
        for my $pid (grep { !$children{$_} } keys %children) {
            my $w=CORE::waitpid($pid,WNOHANG); next if $w==$pid || $w==-1;
            CORE::kill('KILL',$pid); my $end=now()+2;
            while (now()<$end) { last if CORE::waitpid($pid,WNOHANG)==$pid; sleep(0.001); }
        }
        eval { $_->close } for @services; eval { $_->close } for @clients;
    }
}
local $SIG{ALRM}=sub { die "Service execution report fixture deadline\n" }; alarm 60;
sub bind_request {
    my ($s,$job,$context,$deadline)=@_; $job//=2;
    my ($ticket,$c)=request($s,$context); my $packet;
    ok($s->transfer_request($ticket,\$packet),'original request enters the retained owner slot');
    $s->register_parent($job,$deadline // $packet->{deadline_ns});
    ok($s->queue_accept($ticket,$job),'original matching job queues ACCEPT');
    return ($ticket,$c,$packet);
}
sub read_exact {
    my ($c,$size)=@_; my ($raw,$end)=('',now()+2);
    while (length($raw)<$size && now()<$end) {
        my $n=sysread($c->handle,my $part,$size-length($raw));
        if (defined($n) && $n>0) { $raw.=$part; next; }
        die 'execution peer read failed' unless !defined($n) && $! == EAGAIN; sleep(0.001);
    }
    die 'execution peer exact read expired' unless length($raw)==$size; return $raw;
}
sub complete {
    my ($s,$ticket,$c,$job)=@_; $job//=2;
    until_value($s,sub { $s->accept_publication($ticket)->{write}{published} ? 1:undef });
    is(read_exact($c,10),raw(4,pack('N',$job)),'literal complete ACCEPT names the matching job');
}
sub ready_request {
    my ($s,$job,$context,$deadline)=@_; my @v=bind_request($s,$job,$context,$deadline); complete($s,$v[0],$v[1],$job); return @v;
}
sub reset_hooks { $clock_ns=$inspect_hook=$publication_hook=$before_mask=$clock_hook=$write_size=undef; }
# These tests supply the trusted report only. Actual native E proof belongs to
# T1853 and the aggregate integration; a Service grant alone proves no execution.
sub admit {
    my ($s,$ticket,$job)=@_; $job//=2; my $grant;
    is($s->execution_admission($ticket,$job,\$grant),1,'fresh admission publishes one original grant');
    isa_ok($grant,'FSM::Support::ProcessSupervisor::Service::ExecutionAdmission');
    return $grant;
}
sub no_report {
    my ($s,$ticket)=@_;
    ok(!defined($s->execution_observation($ticket)->{report}),'transport admission alone records no native effect report');
}

subtest 'original admission slot is published only on a fresh positive check' => sub {
    my $s=service(); my ($ticket,$c)=bind_request($s); my $slot;
    for my $bad (undef, {}, [], \2) {
        like(error_from(sub { $s->execution_admission($ticket,2,$bad) }),qr/empty untied scalar slot/,'invalid or populated grant slot is rejected');
    }
    { package NoGrantFetch; sub TIESCALAR { bless {},shift } sub FETCH { die 'tied grant FETCH must never run' } sub STORE { die 'tied grant STORE must never run' } }
    tie my $tied,'NoGrantFetch';
    like(error_from(sub { $s->execution_admission($ticket,2,\$tied) }),qr/empty untied scalar slot/,'tied grant slot is rejected without callback'); untie $tied;
    is($s->execution_admission($ticket,2,\$slot),0,'unpublished ACCEPT defers grant issuance');
    ok(!defined($slot),'deferred admission leaves the retained slot empty'); no_report($s,$ticket);
    complete($s,$ticket,$c); my $grant=admit($s,$ticket); my $issued=$grant->{issued_ns};
    $clock_ns=Math::BigInt->new($issued)->badd(1)->bstr;
    my $again=admit($s,$ticket);
    is(refaddr($again),refaddr($grant),'retry returns the same original grant');
    is($again->{issued_ns},$issued,'retry does not renew original grant issue time');
    is($s->execution_admission($ticket,2),1,'existing boolean-only check remains supported');
    no_report($s,$ticket);
    send_raw($c,substr(raw(7,pack('N',2)),0,1)); my $pending;
    is($s->execution_admission($ticket,2,\$pending),0,'new partial input defers the next native attempt');
    ok(!defined($pending),'historical grant is never published as new pending permission');
    no_report($s,$ticket);
    reset_hooks(); finish($s); peer_eof($c);
};

subtest 'a trusted report selects the original clipped execution wall without renewal' => sub {
    my $s=service(); my $clip=ns(now()+8); my ($ticket,$c,$packet)=ready_request($s,2,undef,$clip);
    my $grant=admit($s,$ticket); my $before=$s->execution_observation($ticket);
    is($before->{active_deadline_ns},$packet->{admission_deadline_ns},'admission grant alone keeps the original short wall');
    my $reported=Math::BigInt->new($packet->{admission_deadline_ns})->badd(1)->bstr; $clock_ns=$reported;
    is($s->record_execution($grant),1,'delayed trusted report can follow the admission wall');
    my $view=$s->execution_observation($ticket); my $report={%{$view->{report}}};
    is_deeply($report,{reported_ns=>$reported,admission_issued_ns=>$grant->{issued_ns},deadline_ns=>$clip},'report uses reporting time and original clipped deadline');
    is($view->{deadline_ns},$packet->{deadline_ns},'original request deadline remains historical');
    is($view->{admission_deadline_ns},$packet->{admission_deadline_ns},'original admission deadline remains historical');
    is($view->{active_deadline_ns},$clip,'report selects the already clipped execution deadline');
    is($s->ticket_observation($ticket)->{wall_ns},$packet->{admission_deadline_ns},'ticket view keeps original admission wall');
    is($s->ticket_observation($ticket)->{active_deadline_ns},$clip,'ticket view exposes the selected active wall');
    cmp_ok($s->poll_delay,'>',0,'polling no longer busy-spins on the spent admission wall');
    $s->advance; is($s->ticket_observation($ticket)->{state},'bound','reported execution survives admission expiry in ordinary advancement');
    ok($s->{records}{$ticket}{io}->queue({type=>'STDOUT_END',job=>2,offset=>0}),'fixture queues valid bounded transport output');
    $s->advance(sub { 0 },sub { 1 });
    is(read_exact($c,18),raw(11,pack('NNN',2,0,0)),'bound transport writes use the execution lifetime after report');
    $clock_ns=Math::BigInt->new($reported)->badd(1)->bstr;
    is($s->record_execution($grant),1,'repeated trusted report is idempotent');
    is_deeply($s->execution_observation($ticket)->{report},$report,'repeat preserves the first report time and original wall');
    like(error_from(sub { $s->execution_admission($ticket,2) }),qr/already consumed/,'reported execution cannot request another gate admission');
    $view->{report}{reported_ns}='1'; $view->{latest}{state}='forged'; $view->{admitted}{state}='forged';
    is_deeply($s->execution_observation($ticket)->{report},$report,'mutating a copied report cannot alter retained history');
    $clock_ns=Math::BigInt->new($clip)->bsub(1)->bstr; $s->advance;
    is($s->ticket_observation($ticket)->{state},'bound','original clipped boundary remains live immediately before expiry');
    $clock_ns=$clip; $s->advance;
    is($s->ticket_observation($ticket)->{state},'closed','original clipped boundary closes exactly at expiry');
    is($s->ticket_observation($ticket)->{failure}{status},'timed_out','execution expiry retains timeout outcome');
    reset_hooks(); peer_eof($c); finish($s);
};

subtest 'a first report at execution expiry retains history while closing transport' => sub {
    my $s=service(); my $clip=ns(now()+8); my ($ticket,$c)=ready_request($s,2,undef,$clip);
    my $grant=admit($s,$ticket); $clock_ns=$clip;
    is($s->record_execution($grant),1,'expired lifetime still accepts the historical trusted report');
    is($s->ticket_observation($ticket)->{state},'closed','first report at expiry cannot revive execution lifetime');
    is($s->execution_observation($ticket)->{report}{deadline_ns},$clip,'expired report keeps original clipped deadline');
    is($s->execution_observation($ticket)->{failure}{status},'timed_out','first report performs fresh original lifetime validation');
    reset_hooks(); peer_eof($c); finish($s);
};

subtest 'copies numeric observations and foreign owners cannot report an effect' => sub {
    my $s=service(); my ($ticket,$c)=ready_request($s); my $grant=admit($s,$ticket);
    my $copy=bless {%$grant},ref($grant); my $service_copy=bless {%$s},ref($s);
    for my $bad ($copy,2,$s->execution_observation($ticket),undef) {
        like(error_from(sub { $s->record_execution($bad) }),qr/original admission grant/,'copied or numeric history cannot act as report handle');
    }
    like(error_from(sub { $service_copy->record_execution($grant) }),qr/copied service/,'copied Service cannot report on original peer');
    like(error_from(sub { $s->record_execution }),qr/one original execution admission grant/,'missing report handle is rejected');
    like(error_from(sub { $s->record_execution($grant,1) }),qr/one original execution admission grant/,'extra report arguments are rejected');
    my $foreign=service();
    like(error_from(sub { $foreign->record_execution($grant) }),qr/original admission grant/,'foreign Service cannot borrow original grant'); finish($foreign);
    my $record=$s->{records}{$ticket};
    { local $s->{records}{$ticket}={%$record};
      like(error_from(sub { $s->record_execution($grant) }),qr/lost original peer admission/,'replacement peer cannot borrow the original grant'); }
    { local $record->{execution_grant}=$copy;
      like(error_from(sub { $s->record_execution($grant) }),qr/lost original peer admission/,'replaced retained grant cannot report'); }
    no_report($s,$ticket);
    my $pid=fork(); die 'cannot fork report ownership observer' unless defined $pid;
    if (!$pid) {
        my $error=error_from(sub { $s->record_execution($grant) });
        $_->discard_inherited for @services; $_->discard_inherited for @clients;
        _exit($error =~ /inherited service/ ? 0:93);
    }
    $children{$pid}=0; my ($status,$end)=(undef,now()+2);
    while (now()<$end) {
        my $w=CORE::waitpid($pid,WNOHANG);
        if ($w==$pid) { $status=$?; $children{$pid}=1; last; }
        die 'report ownership exact wait failed' if $w<0; sleep(0.001);
    }
    is($status,0,'exact inherited observer cannot report creator execution');
    is($s->record_execution($grant),1,'original retained grant remains reportable');
    finish($s); peer_eof($c);
};

subtest 'closed peers retain reports and first failures without reopening' => sub {
    for my $cut ('retire','eof','admission-expiry','authority') {
        my $s=service(); my ($ticket,$c,$packet)=ready_request($s); my $grant=admit($s,$ticket);
        if ($cut eq 'retire') { $s->retire($ticket); }
        elsif ($cut eq 'eof') { $c->close; $s->advance; }
        elsif ($cut eq 'authority') { $s->revoke_parent(2); }
        else { $clock_ns=$packet->{admission_deadline_ns}; $s->advance; }
        my $failure=$s->ticket_observation($ticket)->{failure};
        is($s->ticket_observation($ticket)->{state},'closed',"$cut closes before the delayed report");
        is($s->record_execution($grant),1,"$cut retains delayed trusted report");
        my $view=$s->execution_observation($ticket);
        is($s->ticket_observation($ticket)->{state},'closed','historical report never reopens the peer');
        is($s->ticket_observation($ticket)->{handles},0,'historical report opens no native handle');
        is_deeply($view->{failure},$failure,'report preserves original first failure');
        my $retained=$s->{records}{$ticket}; my $outcome=$s->take_closed;
        is_deeply($outcome->{execution},$view,'consumed outcome carries the complete detached execution report');
        $outcome->{execution}{report}{reported_ns}='1';
        isnt($view->{report}{reported_ns},'1','consumed report does not alias an earlier observation');
        isnt($retained->{execution_report}{reported_ns},'1','consumed report does not alias the original retained record');
        ok(!defined($s->take_closed),'closed outcome is consumed once');
        like(error_from(sub { $s->record_execution($grant) }),qr/lost original peer admission/,'spent peer grant cannot report after outcome consumption');
        reset_hooks(); peer_eof($c) unless $cut eq 'eof'; finish($s);
    }
};

subtest 'post-report parent job root and endpoint authority remain authoritative' => sub {
    for my $cut ('parent','job','root','endpoint','parent-expiry','job-expiry','root-expiry') {
        my $s=service(); my $context=$s->register_parent(2,ns(now()+15));
        my ($ticket,$c,$packet)=ready_request($s,3,$context); my $grant=admit($s,$ticket,3);
        $s->record_execution($grant); my $report=$s->execution_observation($ticket)->{report};
        if ($cut eq 'parent') { $s->revoke_parent(2); }
        elsif ($cut eq 'job') { $s->revoke_parent(3); }
        elsif ($cut eq 'root') { $s->revoke_parent(1); }
        elsif ($cut eq 'endpoint') { $s->{run}->close; }
        else {
            my $wall=$cut eq 'parent-expiry' ? $s->parent_observation(2)->{deadline_ns}
                : $cut eq 'job-expiry' ? $s->parent_observation(3)->{deadline_ns} : $s->{deadline}->bstr;
            $clock_ns=$wall;
        }
        if ($cut eq 'endpoint') {
            like(error_from(sub { $s->advance }),qr/endpoint handle is closed/,'closed original endpoint retains its native refusal');
        }
        else { $s->advance; }
        is($s->ticket_observation($ticket)->{state},'closed',"$cut stops reported transport even without a queued write");
        $s->record_execution($grant);
        is_deeply($s->execution_observation($ticket)->{report},$report,'later authority loss preserves first report');
        reset_hooks(); peer_eof($c); finish($s);
    }
};

subtest 'post-report literal cancellation protocol errors EOF and framing wall still close' => sub {
    for my $cut ('cancel','foreign','ack','repeated','eof','partial-wall') {
        my $s=service(); my ($ticket,$c,$packet)=ready_request($s); my $grant=admit($s,$ticket); $s->record_execution($grant);
        my $report=$s->execution_observation($ticket)->{report};
        $clock_ns=Math::BigInt->new($packet->{admission_deadline_ns})->badd(1)->bstr;
        if ($cut eq 'eof') { $c->close; }
        else {
            my $frame=$cut eq 'ack' ? raw(9,pack('N',2)) : $cut eq 'repeated' ? spawn_frame(ns(now()),20)
                : raw(7,pack('N',$cut eq 'foreign' ? 3:2));
            send_raw($c,$cut eq 'partial-wall' ? substr($frame,0,1):$frame);
        }
        $s->advance;
        if ($cut eq 'partial-wall') {
            is($s->ticket_observation($ticket)->{state},'bound','partial control remains bounded pending input');
            my $io=$s->{records}{$ticket}{io}; my $wall=$io->{frame_started}+2;
            no warnings 'redefine'; local *FSM::Support::ProcessSupervisor::Connection::_now=sub { $wall };
            $s->advance;
        }
        else { for (1..4) { last if $s->ticket_observation($ticket)->{state} eq 'closed'; $s->advance; } }
        is($s->ticket_observation($ticket)->{state},'closed',"$cut closes reported transport");
        my $expected=$cut eq 'cancel' ? 'cancelled' : $cut eq 'eof' ? 'peer_closed' : $cut eq 'partial-wall' ? 'framing_timeout' : 'protocol_error';
        is($s->ticket_observation($ticket)->{failure}{status},$expected,'first protocol/EOF/frame failure is retained');
        is_deeply($s->execution_observation($ticket)->{report},$report,'transport failure preserves report history');
        reset_hooks(); peer_eof($c) unless $cut eq 'eof'; finish($s);
    }
};

subtest 'real pending creator signals see the original grant and report before return' => sub {
    my $old=POSIX::SigSet->new;
    defined POSIX::sigprocmask(SIG_SETMASK,POSIX::SigSet->new(SIGUSR2),$old) or die 'cannot select report mask';
    for my $cut ('admission','report','report-close') {
        my $s=service(); my ($ticket,$c)=ready_request($s); my ($grant,$seen,$seen_grant);
        $grant=admit($s,$ticket) unless $cut eq 'admission';
        local $SIG{USR1}=sub {
            $seen_grant=$grant; $seen=$s->execution_observation($ticket);
            if ($cut eq 'report-close') { $s->retire($ticket); return; }
            die "original execution report interruption\n";
        };
        my $queue=sub { kill('USR1',$$)==1 or die 'cannot queue report signal' };
        if ($cut eq 'admission') { $inspect_hook=$queue; }
        else { $clock_hook=sub { $clock_hook=undef; $queue->() }; }
        my $error=error_from(sub {
            $cut eq 'admission' ? $s->execution_admission($ticket,2,\$grant) : $s->record_execution($grant);
        });
        if ($cut eq 'report-close') { is($error,'','nonthrowing handler preserves successful reporting'); }
        else { like($error,qr/original execution report interruption/,'original pending signal exception survives'); }
        ok(defined($seen_grant) && refaddr($seen_grant)==refaddr($grant),'handler sees original retained grant before return');
        if ($cut eq 'admission') { ok(!defined($seen->{report}),'admission interruption alone cannot fabricate a report'); }
        else { ok(defined($seen->{report}),'handler sees complete report before creator signals resume'); }
        is($s->ticket_observation($ticket)->{state},'closed','interrupted or handler-closed peer stays closed');
        reset_hooks(); is_deeply(mask_state(),[0,1],'original creator mask is restored');
        is($s->record_execution($grant),1,'original retained handle permits idempotent reconciliation after interruption');
        is_deeply($s->execution_observation($ticket)->{report},$seen->{report},'interrupted report keeps first timestamp') unless $cut eq 'admission';
        peer_eof($c); finish($s);
    }
    defined POSIX::sigprocmask(SIG_SETMASK,$old) or die 'cannot restore report mask';
};

subtest 'pre-mask mutations never overwrite newer custody or reopen a peer' => sub {
    my $s=service(); my ($ticket,$c)=ready_request($s); my $slot;
    $before_mask=sub { $slot='occupied'; };
    like(error_from(sub { $s->execution_admission($ticket,2,\$slot) }),qr/empty untied scalar slot/,'pre-mask slot publication is respected');
    is($slot,'occupied','newer destination is never overwritten');
    my $grant=admit($s,$ticket); $before_mask=sub { $s->retire($ticket); };
    is($s->record_execution($grant),1,'pre-mask closure still permits historical report');
    is($s->ticket_observation($ticket)->{state},'closed','report does not reopen handler-closed peer');
    reset_hooks(); peer_eof($c); finish($s);
    $s=service(); ($ticket,$c)=ready_request($s); $grant=admit($s,$ticket);
    $before_mask=sub { $s->retire($ticket); $s->take_closed; };
    like(error_from(sub { $s->record_execution($grant) }),qr/lost original peer admission/,'pre-mask outcome consumption invalidates the original report handle');
    is_deeply($s->tickets,[],'report creates no replacement consumed peer');
    reset_hooks(); peer_eof($c); finish($s);
    is_deeply(census(),$initial,'independent endpoint census is unchanged');
};

alarm 0;
done_testing();
