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
my ($write_size, $inspect_hook, $publication_hook, $before_mask);
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
        . bytes('execution.admission.schema') . bytes('probe') . bytes('fixture-group') . bytes('.')
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
local *FSM::Support::ProcessSupervisor::Service::_now_ns = sub { $clock_ns // $native_clock->() };
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
        alarm 0; $clock_ns=$inspect_hook=$publication_hook=$before_mask=undef;
        for my $pid (grep { !$children{$_} } keys %children) {
            my $w=CORE::waitpid($pid,WNOHANG); next if $w==$pid || $w==-1;
            CORE::kill('KILL',$pid); my $end=now()+2;
            while (now()<$end) { last if CORE::waitpid($pid,WNOHANG)==$pid; sleep(0.001); }
        }
        eval { $_->close } for @services; eval { $_->close } for @clients;
    }
}
local $SIG{ALRM}=sub { die "Service execution admission fixture deadline\n" }; alarm 60;
sub bind_request {
    my ($s,$job,$context)=@_; $job//=2;
    my ($ticket,$c)=request($s,$context); my $packet;
    ok($s->transfer_request($ticket,\$packet),'original request enters the retained owner slot');
    $s->register_parent($job,$packet->{deadline_ns});
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
    my ($s,$job,$context)=@_; my @v=bind_request($s,$job,$context); complete($s,$v[0],$v[1],$job); return @v;
}
sub reset_hooks { $clock_ns=$inspect_hook=$publication_hook=$before_mask=$write_size=undef; }
sub inspect_only {
    my ($s,$ticket,$job)=@_; $job//=2;
    my ($w,$a,$n)=($writes,$accepts,scalar @inspections);
    my $ok=$s->execution_admission($ticket,$job);
    is($writes,$w,'execution admission writes no output');
    is($accepts,$a,'execution admission accepts no unrelated connection');
    ok(@inspections-$n<=1,'execution admission inspects at most its original peer once');
    return $ok;
}

subtest 'only complete original publication and fresh quiet input admit the matching peer' => sub {
    my $s=service(); my ($ticket,$c,$packet)=bind_request($s);
    ok(!defined($s->execution_observation($ticket)),'no execution history exists before inspection');
    is(inspect_only($s,$ticket),0,'queued ACCEPT grants no execution admission');
    is($s->execution_observation($ticket)->{latest}{reason},'publication','queued publication is an explicit deferral');
    $write_size=5; $s->advance; my $prefix=read_exact($c,5);
    is(inspect_only($s,$ticket),0,'partial ACCEPT still grants no admission');
    is($s->accept_publication($ticket)->{write}{confirmed_bytes},5,'inspection preserves original confirmed prefix');
    $write_size=undef; $s->advance;
    is($prefix.read_exact($c,5),raw(4,pack('N',2)),'independent client reconstructs exact original publication');
    is(inspect_only($s,$ticket),1,'complete original publication with fresh quiet input is admitted');
    my $v=$s->execution_observation($ticket);
    is_deeply([@{$v}{qw(ticket parent job deadline_ns admission_deadline_ns)}],
        [$ticket,1,2,$packet->{deadline_ns},$packet->{admission_deadline_ns}],'copied execution check preserves original association and both walls');
    is($v->{latest}{state},'admitted','latest check is retained');
    is($v->{admitted}{state},'admitted','last positive check is separately retained');
    $v->{latest}{state}=$v->{admitted}{state}='changed'; $v->{deadline_ns}='1';
    is($s->execution_observation($ticket)->{admitted}{state},'admitted','copied positive check cannot mutate original history');
    is($s->execution_observation($ticket)->{latest}{state},'admitted','copied latest check cannot mutate original history');
    is($s->ticket_observation($ticket)->{wall_ns},$packet->{admission_deadline_ns},'positive transport check extends no lifetime');
    finish($s); peer_eof($c);
};

subtest 'selected inspection neither reads another peer nor consumes a waiting connection' => sub {
    my $s=service(); my ($ticket,$c)=ready_request($s);
    my ($other,$other_client)=request($s);
    send_raw($other_client,raw(7,pack('N',99)));
    my $waiting=FSM::Support::ProcessSupervisor::Endpoint::connect_context($s->context); push @clients,$waiting;
    my $end=now()+2;
    while (now()<$end && !$waiting->connection_ready) { sleep(0.001); }
    my $before=$s->counts->{connections}; my $start=@reads;
    is(inspect_only($s,$ticket),1,'selected original peer remains admissible');
    is($s->counts->{connections},$before,'waiting backlog remains untouched');
    is_deeply([@reads[$start..$#reads]],[refaddr($s->{records}{$ticket}{handle})],'only matching original socket was read');
    is($s->ticket_observation($other)->{state},'request','other retained request does not advance');
    finish($s); peer_eof($c); peer_eof($other_client); $waiting->close;
};

subtest 'partial and decoded control always defeats a prior positive check' => sub {
    for my $kind ('CANCEL','foreign-CANCEL','ACK','SPAWN') {
        my $s=service(); my ($ticket,$c)=ready_request($s);
        is(inspect_only($s,$ticket),1,'original quiet check succeeds before new control');
        my $previous=$s->execution_observation($ticket)->{admitted};
        my $raw=$kind eq 'SPAWN' ? spawn_frame(ns(now()),20)
            : raw($kind eq 'ACK'?9:7,pack('N',$kind eq 'foreign-CANCEL'?3:2));
        send_raw($c,substr($raw,0,1));
        is(inspect_only($s,$ticket),0,"$kind fragment revokes current admission");
        is($s->execution_observation($ticket)->{latest}{reason},'input','buffered control explicitly defers');
        is(inspect_only($s,$ticket),0,'later empty kernel read cannot bypass retained fragment');
        is_deeply($s->execution_observation($ticket)->{admitted},$previous,'deferral keeps historical positive check without reusing it');
        send_raw($c,substr($raw,1));
        for (1..16) {
            last unless $s->ticket_observation($ticket)->{state} eq 'bound';
            is(inspect_only($s,$ticket),0,'every further control read refuses execution');
        }
        is($s->ticket_observation($ticket)->{state},'closed','complete control closes the original bound peer');
        is($s->execution_observation($ticket)->{failure}{status},$kind eq 'CANCEL'?'cancelled':'protocol_error',"$kind retains exact failure class");
        ok($s->accept_publication($ticket)->{write}{published},'original complete publication remains historical');
        peer_eof($c); finish($s);
    }
};

subtest 'EOF interrupted reads and original failures are never quiet admission' => sub {
    for my $cut ('EOF','EINTR','throw','clean-close') {
        my $s=service(); my ($ticket,$c)=ready_request($s);
        if ($cut eq 'EOF') { shutdown($c->handle,1) or die 'cannot half-close execution client'; }
        if ($cut eq 'EINTR') {
            no warnings 'redefine';
            local *FSM::Support::ProcessSupervisor::Connection::_read_once=sub { $! = Errno::EINTR(); return undef };
            is(inspect_only($s,$ticket),0,'interrupted original read cannot authorize E');
            is($s->execution_observation($ticket)->{latest}{reason},'input','interrupted inspection stays pending');
        }
        else {
            $inspect_hook=sub { die "original transport inspection failure\n" } if $cut eq 'throw';
            $inspect_hook=sub { $_[0]->close } if $cut eq 'clean-close';
            if ($cut eq 'throw') {
                like(error_from(sub { $s->execution_admission($ticket,2) }),qr/original transport inspection failure/,'inspection exception survives Service cleanup');
            }
            else { is(inspect_only($s,$ticket),0,"$cut refuses execution"); }
            reset_hooks();
            is($s->ticket_observation($ticket)->{state},'closed',"$cut closes original peer");
            my $f=$s->execution_observation($ticket)->{failure}; $f->{diagnostic}='changed';
            isnt($s->execution_observation($ticket)->{failure}{diagnostic},'changed','copied failure is detached');
        }
        finish($s); peer_eof($c);
    }
};

subtest 'fixed walls and authority are rechecked around native inspection and publication' => sub {
    for my $cut ('before-wall','after-input-wall','after-publication-wall','revoke-parent','revoke-job','endpoint') {
        my $s=service(); my ($ticket,$c)=ready_request($s); my $wall=$s->ticket_observation($ticket)->{wall_ns};
        $clock_ns=$wall if $cut eq 'before-wall';
        $inspect_hook=sub { $clock_ns=$wall } if $cut eq 'after-input-wall';
        $publication_hook=sub { $clock_ns=$wall } if $cut eq 'after-publication-wall';
        $inspect_hook=sub { $s->revoke_parent($cut eq 'revoke-parent'?1:2) } if $cut =~ /^revoke/;
        $inspect_hook=sub { $s->{run}->close } if $cut eq 'endpoint';
        my $start=@inspections;
        is(inspect_only($s,$ticket),0,"$cut prevents E admission");
        reset_hooks();
        is(@inspections-$start,$cut eq 'before-wall'?0:1,"$cut has bounded original inspection");
        is($s->ticket_observation($ticket)->{state},'closed',"$cut retains peer closure");
        like($s->execution_observation($ticket)->{failure}{diagnostic},$cut =~ /wall/?qr/deadline expired/:$cut =~ /revoke/?qr/authority is no longer live/:qr/endpoint is no longer ready/,"$cut preserves original cause");
        peer_eof($c); finish($s);
    }
    my $s=service(); my ($ticket,$c,$packet)=ready_request($s);
    is(inspect_only($s,$ticket),1,'quiet transport admission precedes expiry');
    $clock_ns=$packet->{admission_deadline_ns}; $s->advance; $clock_ns=undef;
    is($s->ticket_observation($ticket)->{state},'closed','positive transport check alone never extends the admission wall');
    is($s->execution_observation($ticket)->{admitted}{state},'admitted','closure preserves past check, not current authority');
    peer_eof($c); finish($s);
};

subtest 'missing or foreign original publication cannot authorize the gate' => sub {
    for my $cut ('missing','foreign') {
        my $s=service(); my ($ticket,$c)=ready_request($s);
        no warnings 'redefine';
        local *FSM::Support::ProcessSupervisor::Connection::accept_publication=sub {
            return undef if $cut eq 'missing'; my $v=$publication->(@_); $v->{job}=3; return $v;
        };
        is(inspect_only($s,$ticket),0,"$cut original publication refuses");
        like($s->ticket_observation($ticket)->{failure}{diagnostic},qr/lost original ACCEPT/,'publication failure is retained');
        peer_eof($c); finish($s);
    }
};

subtest 'native pending signals see retained checks and cannot leave stale return authority' => sub {
    my $old=POSIX::SigSet->new;
    defined POSIX::sigprocmask(SIG_SETMASK,POSIX::SigSet->new(SIGUSR2),$old) or die 'cannot select execution mask';
    for my $cut ('admitted','pending','close-on-return','before-mask') {
        my $s=service(); my ($ticket,$c)=ready_request($s); my $seen;
        send_raw($c,substr(raw(7,pack('N',2)),0,1)) if $cut eq 'pending';
        local $SIG{USR1}=sub {
            if ($cut eq 'before-mask') { $s->retire($ticket); return; }
            $seen=$s->execution_observation($ticket);
            if ($cut eq 'close-on-return') { $s->retire($ticket); return; }
            die "original execution admission interruption\n";
        };
        if ($cut eq 'before-mask') { $before_mask=sub { kill('USR1',$$)==1 or die 'cannot signal pre-mask'; }; }
        else { $inspect_hook=sub { kill('USR1',$$)==1 or die 'cannot queue execution signal' }; }
        if ($cut eq 'admitted' || $cut eq 'pending') {
            like(error_from(sub { $s->execution_admission($ticket,2) }),qr/original execution admission interruption/,"$cut preserves real creator interruption");
            is($seen->{latest}{state},$cut,'handler sees retained check before unmask');
            is($s->ticket_observation($ticket)->{state},'closed','interrupted Service return closes original peer');
        }
        else { is(inspect_only($s,$ticket),0,"$cut never returns stale permission"); }
        is($s->execution_observation($ticket)->{admitted}{state},'admitted','return-time closure keeps the earlier positive check historical') if $cut eq 'close-on-return';
        reset_hooks(); is_deeply(mask_state(),[0,1],"$cut restores creator mask");
        peer_eof($c); finish($s);
    }
    defined POSIX::sigprocmask(SIG_SETMASK,$old) or die 'cannot restore execution mask';
};

subtest 'new APIs reject copied foreign and inherited authority without native effects' => sub {
    my $s=service(); my ($ticket,$c)=ready_request($s); my $copy=bless {%$s},ref($s); my $start=@inspections;
    like(error_from(sub { $copy->execution_admission($ticket,2) }),qr/copied service/,'copied Service cannot check original input');
    like(error_from(sub { $copy->execution_observation($ticket) }),qr/copied service/,'copied Service cannot recover original history');
    like(error_from(sub { $s->execution_admission($ticket,3) }),qr/matching bound job/,'foreign job cannot use original peer');
    like(error_from(sub { $s->execution_admission(999,2) }),qr/unknown connection/,'unknown ticket cannot inspect original peer');
    like(error_from(sub { $s->execution_admission($ticket) }),qr/execution ticket and job/,'incomplete arguments are refused');
    is(scalar(@inspections),$start,'invalid authority triggers no inspection');
    my $pid=fork(); die 'cannot fork execution ownership observer' unless defined $pid;
    if (!$pid) {
        my $a=error_from(sub { $s->execution_admission($ticket,2) });
        my $b=error_from(sub { $s->execution_observation($ticket) });
        $_->discard_inherited for @services; $_->discard_inherited for @clients;
        _exit($a =~ /inherited service/ && $b =~ /inherited service/ ? 0:93);
    }
    $children{$pid}=0; my ($status,$end)=(undef,now()+2);
    while (now()<$end) {
        my $w=CORE::waitpid($pid,WNOHANG);
        if ($w==$pid) { $status=$?; $children{$pid}=1; last; }
        die 'execution ownership exact wait failed' if $w<0; sleep(0.001);
    }
    is($status,0,'exact inherited observer refuses original Service authority');
    is(inspect_only($s,$ticket),1,'original creator remains independently admissible');
    finish($s); peer_eof($c);
    is_deeply(census(),$initial,'independent endpoint census is unchanged');
};

alarm 0;
done_testing();
