#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use Scalar::Util qw(refaddr);
use FindBin;
use lib "$FindBin::Bin/../perl", "$FindBin::Bin/lib";
use FSM::Test::ProjectDataLocality;
use FSM::Support::ProcessSupervisor::Admission ();

# Model-only test. No fabricated numeric process identity reaches a syscall.
my $class = 'FSM::Support::ProcessSupervisor::Admission';
my $now = '100000000000';
no warnings 'redefine';
local *FSM::Support::ProcessSupervisor::Admission::_now_ns = sub { $now };
local *FSM::Support::ProcessSupervisor::GatedPair::prepare = sub { die 'native preparation forbidden' };
local *FSM::Support::ProcessSupervisor::GatedPair::start = sub { die 'native start forbidden' };
sub ledger { return FSM::Support::ProcessSupervisor::Admission::prepare(
    started_ns => '99000000000', timeout_seconds => 20) }
sub rejects {
    my ($code, $pattern, $label) = @_;
    my $ok = eval { $code->(); 1 };
    ok(!$ok && $@ =~ $pattern, $label) or diag($@ || 'unexpected acceptance');
}
sub active {
    my ($ledger, $grant) = @_;
    $ledger->begin_prepare($grant);
    $ledger->prepared($grant, 15);
    $ledger->begin_start($grant);
    $ledger->activate($grant, 7);
}
sub nested {
    my ($ledger, $parent, %extra) = @_;
    return $ledger->reserve_job(parent => $parent, started_ns => $now,
        timeout_seconds => 30, %extra);
}
sub settle {
    my ($ledger, $grant) = @_;
    $ledger->cancel($grant);
    $ledger->release_resources($grant, children => 0, descriptors => 0);
    $ledger->finish($grant);
}

subtest 'original timing and retained one-use transitions' => sub {
    my $l = ledger(); my $r = $l->root;
    is_deeply($l->describe($r), {id => 1, parent => 0, depth => 1,
        started_ns => '99000000000', timeout_seconds => '20', deadline_ns => '119000000000',
        phase => 'reserved', accepting => 1, children => 0, descriptors => 0,
        reserved_children => 2, reserved_descriptors => 16}, 'root retains literal original timing and peak charges');
    is_deeply($l->usage, {jobs => 1, children => 0, descriptors => 0,
        reserved_children => 2, reserved_descriptors => 16,
        charged_children => 2, charged_descriptors => 16}, 'unallocated capacity is distinct from actual effects');
    rejects(sub { nested($l, $r) }, qr/parent is not active/, 'unstarted parent cannot admit');
    rejects(sub { $l->begin_start($r) }, qr/expected prepared/, 'fork cannot precede preparation');
    $l->begin_prepare($r);
    rejects(sub { $l->begin_prepare($r) }, qr/expected reserved/, 'preparation is single-use');
    $l->prepared($r, 15);
    is($l->usage->{reserved_descriptors}, 0, 'prepared effects replace their reservation');
    is($l->usage->{descriptors}, 15, 'actual prepared descriptors remain charged');
    rejects(sub { $l->prepared($r, 15) }, qr/expected preparing/, 'cannot replay preparation completion');
    rejects(sub { $l->release_resources($r, children => 0, descriptors => 0) }, qr/only after launch/, 'future forks keep their full child reservation');
    $l->begin_start($r);
    rejects(sub { $l->begin_start($r) }, qr/expected prepared/, 'start grant is single-use');
    $l->activate($r, 7);
    is_deeply($l->usage, {jobs => 1, children => 2, descriptors => 7,
        reserved_children => 0, reserved_descriptors => 0,
        charged_children => 2, charged_descriptors => 7}, 'ready effects have no outstanding allocation credit');
    my $c = nested($l, $r);
    is_deeply([@{$l->describe($c)}{qw(id parent depth started_ns deadline_ns)}],
        [2, 1, 2, '100000000000', '119000000000'], 'nested deadline clips to original ancestor');
    active($l, $c);
    my $g = nested($l, $c, timeout_seconds => 2);
    is($l->describe($g)->{deadline_ns}, '102000000000', 'shorter child wall is never extended');
    $l->describe($g)->{deadline_ns} = '999999999999';
    is($l->describe($g)->{deadline_ns}, '102000000000', 'projection mutation grants no renewed wall');
    $now = '102000000000';
    rejects(sub { $l->begin_prepare($g) }, qr/deadline expired/, 'inclusive expiry prevents allocation');
    $now = '100000000000';
};

subtest 'deadline validation and expiry after retained preparation' => sub {
    for my $case (
        ['100000000001', 20, qr/future/], ['99000000000', 1, qr/expired/],
        ['099000000000', 20, qr/noncanonical/], ['99000000000', 0, qr/positive/],
    ) {
        rejects(sub { FSM::Support::ProcessSupervisor::Admission::prepare(
            started_ns => $case->[0], timeout_seconds => $case->[1]) }, $case->[2], 'invalid original invocation rejects');
    }
    my $l = ledger(); my $r = $l->root;
    $l->begin_prepare($r); $now = '119000000000';
    $l->prepared($r, 15);
    rejects(sub { $l->begin_start($r) }, qr/expired/, 'effects can be recorded after expiry but cannot start');
    is($l->usage->{charged_descriptors}, 15, 'expiry does not erase retained effects');
    settle($l, $r); $l->retire($r);
    $now = '100000000000';
    $l = ledger(); $r = $l->root; active($l, $r);
    rejects(sub { nested($l, $r, started_ns => '98000000000') }, qr/precedes its parent/, 'child cannot predate logical parent');
    my $c = nested($l, $r, timeout_seconds => 1);
    $l->begin_prepare($c); $l->prepared($c, 15); $l->begin_start($c);
    $now = '101000000000';
    rejects(sub { $l->activate($c, 7) }, qr/expired/, 'handoff cannot activate an expired grant');
    $l->cancel($c);
    is($l->usage->{reserved_children}, 2, 'interrupted start retains possible child effects until owner reconciles');
    settle($l, $c); $l->retire($c);
    $now = '119000000000';
    rejects(sub { nested($l, $r) }, qr/expired/, 'expired ancestor cannot admit a fresh child');
    $now = '18446744073709551615';
    rejects(sub { FSM::Support::ProcessSupervisor::Admission::prepare(
        started_ns => $now, timeout_seconds => 1) }, qr/exceeds wire range/, 'u64 deadline cannot overflow');
    $now = '100000000000';
};

subtest 'grant identity, creator custody and monotonic retirement' => sub {
    my $l = ledger(); my $r = $l->root; my $other = ledger();
    rejects(sub { $other->describe($r) }, qr/foreign, copied/, 'job grant belongs to one ledger');
    my $copy = bless {%$r}, ref($r);
    rejects(sub { $l->begin_prepare($copy) }, qr/foreign, copied/, 'copied grant cannot allocate');
    rejects(sub { $l->describe(1) }, qr/invalid job grant/, 'wire identity alone grants no authority');
    my $clone = bless {%$l}, ref($l);
    rejects(sub { $clone->root }, qr/copied ledger/, 'copied owner cannot share authority');
    { local $l->{owner_pid} = $$ + 1;
      rejects(sub { $l->root }, qr/inherited ledger/, 'inherited-owner model rejects before native operations'); }
    active($l, $r);
    my $a = nested($l, $r); active($l, $a);
    my $b = nested($l, $a); my $sibling = nested($l, $r);
    $l->cancel($a);
    is($l->describe($b)->{phase}, 'closing', 'cancellation revokes entire retained subtree');
    is($l->describe($sibling)->{phase}, 'reserved', 'unrelated branch retains its state');
    rejects(sub { $l->begin_prepare($b) }, qr/revoked/, 'cancel after record before allocation forbids preparation');
    rejects(sub { nested($l, $a) }, qr/revoked/, 'cancelled parent cannot admit');
    rejects(sub { $l->finish($a) }, qr/resources remain/, 'finish cannot forget resources');
    $l->release_resources($a, children => 0, descriptors => 0);
    rejects(sub { $l->release_resources($a, children => 1, descriptors => 0) }, qr/out of range|noncanonical/, 'released child capacity cannot be reclaimed');
    rejects(sub { $l->finish($a) }, qr/descendant outcome/, 'parent waits for retained descendant outcome');
    settle($l, $b);
    rejects(sub { $l->finish($a) }, qr/descendant outcome/, 'closed child still owns delivery slot');
    is($l->usage->{jobs}, 4, 'result pending still consumes job capacity');
    $l->retire($b); $l->finish($a); $l->retire($a);
    rejects(sub { $l->describe($b) }, qr/retired job grant/, 'retired job grant is stale');
    my $later = nested($l, $r);
    is($l->describe($later)->{id}, 5, 'retirement never recycles a wire identity');
    is_deeply([map { $l->describe($_)->{id} } @{$l->grants}], [1, 4, 5], 'owner can recover every still-retained grant');
    $l->cancel($r);
    settle($l, $_), $l->retire($_) for ($later, $sibling);
    settle($l, $r); $l->retire($r);
    is($l->usage->{jobs}, 0, 'child-first delivery retirement empties the ledger');
    rejects(sub { $l->reserve_descriptors(1) }, qr/root is retired/, 'retired run cannot reacquire resources');
};

subtest 'independent inclusive capacity census and closed outcome pressure' => sub {
    my $l = ledger(); my @jobs = ($l->root); active($l, $jobs[0]);
    for (2 .. 8) { push @jobs, nested($l, $jobs[-1]); active($l, $jobs[-1]); }
    is_deeply([@{$l->usage}{qw(jobs children charged_children descriptors)}],
        [8, 16, 16, 56], 'eight retained pairs independently account for sixteen children');
    is($l->describe($jobs[-1])->{depth}, 8, 'inclusive logical depth is eight');
    rejects(sub { nested($l, $jobs[-1]) }, qr/depth exhausted/, 'ninth logical level rejects');
    rejects(sub { nested($l, $jobs[0]) }, qr/job capacity exhausted/, 'ninth job rejects even at shallow depth');
    settle($l, $jobs[-1]);
    is($l->usage->{children}, 14, 'exact declared closure releases its two child charges');
    rejects(sub { nested($l, $jobs[0]) }, qr/job capacity exhausted/, 'zero-resource outcome does not reopen job slot');
    $l->retire(pop @jobs);
    my $next = nested($l, $jobs[0]);
    is($l->describe($next)->{id}, 9, 'settled delivery reopens capacity with a fresh identity');

    my $d = ledger(); my $r = $d->root;
    my $external = $d->reserve_descriptors(112);
    is($d->usage->{charged_descriptors}, 128, 'root peak plus external reservations reaches inclusive descriptor bound');
    rejects(sub { $d->reserve_descriptors(1) }, qr/capacity exhausted/, 'one excess descriptor rejects before allocation');
    is(refaddr($d->descriptor_grants->[0]), refaddr($external), 'lost-return descriptor reservation is recoverable');
    my $forged = bless {}, ref($external);
    rejects(sub { $d->release_descriptors($forged, 0) }, qr/foreign, copied/, 'copied descriptor grant rejects');
    rejects(sub { $l->release_descriptors($external, 0) }, qr/foreign, copied/, 'descriptor grant cannot move to another owner');
    $d->descriptors_prepared($external, 111);
    is_deeply([@{$d->usage}{qw(descriptors reserved_descriptors charged_descriptors)}],
        [111, 16, 127], 'external effects are separate from job preparation credit');
    rejects(sub { $d->descriptors_prepared($external, 111) }, qr/already prepared/, 'external preparation cannot replay');
    rejects(sub { $d->release_descriptors($external, 112) }, qr/out of range/, 'external usage cannot grow without fresh credit');
    active($d, $r);
    rejects(sub { nested($d, $r) }, qr/descriptor capacity/, 'job admission includes external actual descriptors');
    $d->release_descriptors($external, 0);
    rejects(sub { $d->release_descriptors($external, 0) }, qr/retired descriptor/, 'released descriptor grant is stale');
    rejects(sub { $d->reserve_descriptors(0) }, qr/positive/, 'empty descriptor grant rejects');
    rejects(sub { $d->reserve_descriptors(129) }, qr/out of range/, 'single reservation beyond the bound rejects');
    my $cleanup = $d->reserve_descriptors(2);
    settle($d, $r);
    rejects(sub { $d->retire($r) }, qr/run descriptor/, 'run cannot retire while endpoint resources are charged');
    my $scratch = $d->reserve_descriptors(1);
    $d->release_descriptors($scratch, 0); $d->release_descriptors($cleanup, 0); $d->retire($r);
    is($d->usage->{charged_descriptors}, 0, 'bounded cleanup credit also retires exactly');
};

subtest 'identity exhaustion is final even after retirement' => sub {
    my $l = ledger(); my $r = $l->root; active($l, $r);
    $l->{next_id} = 4_294_967_295; # model seam; never a native PID or PGID
    my $last = nested($l, $r);
    is($l->describe($last)->{id}, 4_294_967_295, 'last u32 identity is usable');
    settle($l, $last); $l->retire($last);
    rejects(sub { nested($l, $r) }, qr/identity exhausted/, 'u32 exhaustion never wraps or reuses');
    is($l->usage->{jobs}, 1, 'exhaustion publishes no partial record or resource charge');
};

done_testing;
