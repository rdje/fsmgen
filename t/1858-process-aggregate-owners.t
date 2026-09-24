#!/usr/bin/env perl
use strict;
use warnings;
use Errno qw(ECHILD EINTR);
use POSIX qw(SIG_BLOCK SIG_SETMASK SIGUSR1 SIGUSR2 WNOHANG);
use Scalar::Util qw(refaddr weaken);
use Time::HiRes qw(CLOCK_MONOTONIC clock_gettime sleep);
use Test::More;
use lib 'perl', 't/lib';
use FSM::Test::ProjectDataLocality;
use FSM::ProjectDataLocality qw(repository_root);
use FSM::Support::ProcessSupervisor::Coordinator ();

my $creator = $$;
my (@owners, @pipes, @witnesses, %births);
my ($pipe_calls, $fork_calls, $token_checks) = (0, 0, 0);
my ($binding_cut, $allocation_cut, $run_cut);
sub now { clock_gettime(CLOCK_MONOTONIC) }
sub error_from { my ($code) = @_; local $@; eval { $code->(); 1 }; return $@ }
sub live { grep { defined($_) && defined(fileno($_)) } @_ }
sub census { [sort glob(repository_root() . '/.artifacts/tmp/process-coordinator/*')] }
my $initial = census();
my $original_mask = POSIX::SigSet->new;
defined POSIX::sigprocmask(SIG_SETMASK, POSIX::SigSet->new(SIGUSR1), $original_mask)
    or die 'cannot select creator interruption mask';
sub snapshot {
    return {type => 'SPAWN', started_ns => sprintf('%.0f', now() * 1e9),
        schema => 'aggregate.owners', stage => 'probe', containment => 'fixture-group',
        cwd => '.', umask => 0027, timeout_seconds => 30, capture_limit_bytes => 64,
        argv => [$^X, '-e', 'syswrite STDOUT,"FORBIDDEN"'], environment => []};
}
sub prepare {
    my $o = FSM::Support::ProcessSupervisor::Coordinator::prepare(snapshot => snapshot());
    push @owners, $o; return $o;
}
sub open_owner { my $o = prepare(); $o->open_run; return $o }
sub ready {
    my ($o, $g) = @_;
    $o->prepare_job($g); $o->start_job($g);
    my $end = now() + 3;
    while (now() < $end) {
        my $v = $o->advance_job($g);
        if ($v->{native}{phase} eq 'ready') {
            my $id = $v->{admission}{id};
            open my $fh, '<&', $o->{jobs}{$id}{native}{received}{stdout}
                or die 'cannot retain independent execution witness';
            push @witnesses, $fh;
            return;
        }
        die 'owner fixture lost readiness' if $v->{admission}{phase} eq 'closing';
        sleep(0.001);
    }
    die 'owner fixture readiness expired';
}
sub finish {
    my ($o) = @_;
    $binding_cut = $allocation_cut = $run_cut = undef;
    my ($closed, $end) = (undef, now() + 5);
    while (now() < $end) { $closed = $o->close; last unless $closed->{pending}; sleep(0.001); }
    ok($closed && $closed->{ok}, 'original aggregate cleanup completes');
    is($o->observation->{usage}{charged_descriptors}, 0, 'descriptor credit retires after closure');
    is($o->observation->{usage}{charged_children}, 0, 'child credit retires after closure');
}
sub settled {
    ok(!live(@pipes), 'independent weak pipe inventory is closed');
    ok(!grep(!$_, values %births), 'every actual native child has its consumed exact wait');
    for my $pid (keys %births) {
        my $w = CORE::waitpid($pid, WNOHANG); my $errno = 0 + $!;
        is($w, -1, 'independent exact wait finds no child');
        is($errno, ECHILD, 'native wait is already consumed');
    }
    for my $fh (live(@witnesses)) {
        is(sysread($fh, my $part, 32), 0, 'independent stdout EOF contains no command output');
        CORE::close($fh);
    }
    is_deeply(census(), $initial, 'endpoint census returns to its original inventory');
}
sub no_effect {
    my ($code, $pattern, $label) = @_;
    my @before = ($pipe_calls, $fork_calls, $token_checks);
    like(error_from($code), $pattern, $label);
    is_deeply([$pipe_calls, $fork_calls, $token_checks], \@before, 'refusal adds no pipe, fork or token admission');
}
my $coordinator = 'FSM::Support::ProcessSupervisor::Coordinator';
my $reservation = 'FSM::Support::ProcessSupervisor::Reservation';
my $pair = 'FSM::Support::ProcessSupervisor::GatedPair';
my $pipe = $reservation->can('_pipe');
my $rfork = $reservation->can('_fork'); my $cfork = $pair->can('_fork');
my $rwait = $reservation->can('_wait'); my $cwait = $pair->can('_wait');
my $bind = FSM::Support::ProcessSupervisor::Wire->can('snapshot_with_context');
my $allocation = $coordinator->can('_before_job_allocation');
my $run_allocation = $coordinator->can('_before_run_allocation');
my $token = $coordinator->can('_before_context_allocation');
my $fork = sub {
    my ($f) = @_; ++$fork_calls;
    my $pid = $f->(); $births{$pid} = 0 if defined($pid) && $pid > 0; return $pid;
};
my $wait = sub {
    my ($f, $pid) = @_;
    die 'wait lacks an original observed child' unless $pid > 0 && exists $births{$pid};
    my $n = $f->($pid); my $status = $?;
    $births{$pid} = 1 if $n == $pid; $? = $status; return $n;
};
no warnings 'redefine';
local *FSM::Support::ProcessSupervisor::Reservation::_pipe = sub {
    ++$pipe_calls; my $ok = $pipe->(@_);
    if ($ok) { push @pipes, ${$_[0]}, ${$_[1]}; weaken($pipes[-1]); weaken($pipes[-2]); }
    return $ok;
};
local *FSM::Support::ProcessSupervisor::Reservation::_fork = sub { $fork->($rfork) };
local *FSM::Support::ProcessSupervisor::GatedPair::_fork = sub { $fork->($cfork) };
local *FSM::Support::ProcessSupervisor::Reservation::_wait = sub { $wait->($rwait, @_) };
local *FSM::Support::ProcessSupervisor::GatedPair::_wait = sub { $wait->($cwait, @_) };
local *FSM::Support::ProcessSupervisor::Coordinator::_before_context_allocation = sub {
    ++$token_checks;
    if ($_[5] eq 'entropy_open') {
        my ($o, $g, $s, $id, $kind, $operation) = @_;
        local $o->{jobs}{$id} = {%{$o->{jobs}{$id}}};
        no_effect(sub { $token->($o, $g, $s, $id, $kind, $operation) }, qr/original.*job/,
            'nested job identity precedes token source opening');
    }
    return $token->(@_);
};
local *FSM::Support::ProcessSupervisor::Coordinator::_before_run_allocation = sub {
    $run_cut->(@_) if $run_cut; return $run_allocation->(@_);
};
local *FSM::Support::ProcessSupervisor::Coordinator::_before_job_allocation = sub {
    $allocation_cut->(@_) if $allocation_cut; return $allocation->(@_);
};
local *FSM::Support::ProcessSupervisor::Wire::snapshot_with_context = sub {
    my $s = $bind->(@_); $binding_cut->() if $binding_cut; return $s;
};
use warnings 'redefine';
END {
    local $?;
    if ($$ == $creator) {
        alarm 0; $binding_cut = $allocation_cut = $run_cut = undef;
        eval { $_->close } for @owners;
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
local $SIG{ALRM} = sub { die "aggregate owner fixture deadline\n" }; alarm 60;

subtest 'original transport owners cannot be substituted or lost' => sub {
    my $o = open_owner(); my $other = open_owner(); my $g = $o->root;
    my $original = $o->context;
    for my $field (qw(run service)) {
        for my $replacement ($other->{$field}, bless({%{$o->{$field}}}, ref($o->{$field})), undef) {
            local $o->{$field} = $replacement;
            no_effect(sub { $o->context }, qr/original.*(?:endpoint|Service)/, "$field substitution refuses context");
            no_effect(sub { $o->prepare_job($g) }, qr/original.*(?:endpoint|Service)/, "$field substitution refuses native preparation");
        }
    }
    { local $o->{service}{run} = $other->{run};
      no_effect(sub { $o->context }, qr/original.*endpoint/, 'Service cannot borrow a different original endpoint'); }
    my $same = FSM::Support::ProcessSupervisor::Service::new_shared_service(
        $o->{run}, $o->job_observation($g)->{admission}{deadline_ns});
    is($same->parent_context(1), $original, 'different original Service can expose identical root bytes');
    { local $o->{service} = $same;
      no_effect(sub { $o->context }, qr/original.*Service/, 'equal context bytes do not replace original Service'); }
    $same->close;
    is($o->context, $original, 'restored original association retains original bytes');
    finish($other); finish($o); settled();
};

subtest 'original job entries and bound context values remain required' => sub {
    my $o = open_owner(); my $g = $o->root; my $entry = $o->{jobs}{1};
    for my $replacement ({%$entry}, undef) {
        local $o->{jobs}{1} = $replacement;
        no_effect(sub { $o->job_observation($g) }, qr/original.*(?:job|owner)/, 'copied or lost entry refuses observation');
        no_effect(sub { $o->prepare_job($g) }, qr/original.*(?:job|owner)/, 'copied or lost entry refuses preparation');
    }
    { local $o->{jobs}{1}; delete $o->{jobs}{1};
      no_effect(sub { $o->handles }, qr/original.*job/, 'lost original entry cannot disappear from handle inventory'); }
    { local $o->{jobs}{999} = {};
      no_effect(sub { $o->handles }, qr/original.*job/, 'unadmitted entry cannot enter handle inventory'); }
    { local $entry->{bound_context};
      no_effect(sub { $o->context }, qr/original.*context/, 'lost bound context refuses lookup'); }
    for my $context ($o->{run}->context_for(2, 'ab' x 16), undef) {
        local $o->{service}{parents}{1}{context} = $context;
        no_effect(sub { $o->context }, qr/original.*context/, 'changed context value cannot replace bound snapshot authority');
    }
    ready($o, $g);
    my $nested = $o->reserve_job(parent => $g, snapshot => snapshot());
    { local $o->{jobs}{2} = {%{$o->{jobs}{2}}};
      no_effect(sub { $o->job_observation($nested) }, qr/original.*job/, 'nested entry identity is retained before native preparation'); }
    { local $o->{service}{parents}{2}{context} = $o->context;
      no_effect(sub { $o->prepare_job($nested) }, qr/original.*context/, 'nested context cannot be replaced by root bytes'); }
    finish($o); settled();
};

subtest 'ownership and context publication precede actual creator interruptions' => sub {
    my $o = prepare(); my $seen_run = 0;
    $run_cut = sub {
        my ($owner, @args) = @_;
        return if $seen_run++ || $args[0] ne 'create';
        local $owner->{run} = bless {%{$owner->{run}}}, ref($owner->{run});
        no_effect(sub { $run_allocation->($owner, @args) }, qr/original.*endpoint/,
            'endpoint identity precedes first native run allocation');
    };
    my $seen = 0;
    local $SIG{USR2} = sub {
        ++$seen;
        is($o->context, $o->{jobs}{1}{bound_context}, 'creator handler sees completed original context binding');
        { local $o->{service} = bless {%{$o->{service}}}, ref($o->{service});
          like(error_from(sub { $o->context }), qr/original.*Service/, 'Service identity already retained at creator return cut'); }
        die "original association creator interruption\n";
    };
    $binding_cut = sub { CORE::kill('USR2', $$) == 1 or die 'cannot queue owner signal' };
    like(error_from(sub { $o->open_run }), qr/original association creator interruption/, 'real creator handler interrupts completed binding return');
    is($seen, 1, 'creator interruption is delivered exactly once');
    like($o->observation->{failure}, qr/original association creator interruption/, 'original first failure is retained');
    $binding_cut = $run_cut = undef;
    finish($o); settled();
};

subtest 'native association is original before pipes and through later readiness' => sub {
    my $o = open_owner(); my $g = $o->root;
    my $s = snapshot();
    my $foreign = FSM::Support::ProcessSupervisor::ReservedJob::prepare_record(
        snapshot => $s, deadline => $s->{started_ns}/1e9 + 30, close_handles => []);
    my $checked = 0;
    $allocation_cut = sub {
        my ($owner, $grant) = @_;
        return if $checked++;
        local $owner->{jobs}{1}{native} = $foreign;
        no_effect(sub { $allocation->($owner, $grant) }, qr/original.*native/, 'original native binding precedes first pipe');
    };
    ready($o, $g); $allocation_cut = undef;
    my $native = $o->{jobs}{1}{native};
    for my $replacement ($foreign, bless({%$native}, ref($native)), undef) {
        local $o->{jobs}{1}{native} = $replacement;
        no_effect(sub { $o->job_observation($g) }, qr/original.*native/, 'native substitution refuses observation');
        no_effect(sub { $o->advance_job($g) }, qr/original.*native/, 'native substitution refuses advancement');
        no_effect(sub { $o->handles }, qr/original.*native/, 'native substitution refuses descriptor inventory');
    }
    is($o->job_observation($g)->{native}{phase}, 'ready', 'restored native remains gated and ready');
    finish($o); settled();
};

alarm 0;
defined POSIX::sigprocmask(SIG_SETMASK, $original_mask) or die 'cannot restore creator mask';
done_testing;
