#!/usr/bin/env perl
use strict;
use warnings;

our ($FORKS, $WAITS, $SIGNALS) = (0, 0, 0);
our $REVIEW_ONLY = 0;
BEGIN {
    *CORE::GLOBAL::fork = sub {
        ++$FORKS; die 'review attempted fork' if $REVIEW_ONLY; CORE::fork();
    };
    *CORE::GLOBAL::waitpid = sub {
        ++$WAITS; die 'review attempted wait' if $REVIEW_ONLY; CORE::waitpid($_[0], $_[1]);
    };
    *CORE::GLOBAL::kill = sub {
        ++$SIGNALS; die 'review attempted signal' if $REVIEW_ONLY; CORE::kill($_[0], @_[1 .. $#_]);
    };
}
use IO::Select;
use POSIX qw(WNOHANG);
use Scalar::Util qw(refaddr);
use Time::HiRes qw(CLOCK_MONOTONIC clock_gettime sleep);
use Test::More;
use lib 'perl', 't/lib', 'docs/audits/native-proxy-receipt-adapter-20260922';
use FSM::Test::ProjectDataLocality;
use FSM::Support::ProcessSupervisor::ReservedReceipt ();
use ReceiptAdapter;

my $bound = \&FSM::Support::ProcessSupervisor::ReservedReceipt::receipt_bound;
my $owner = $$;
my @native;
sub now { clock_gettime(CLOCK_MONOTONIC) }
sub review {
    my @before = ($FORKS, $WAITS, $SIGNALS);
    local $REVIEW_ONLY = 1;
    my $result = $bound->(@_);
    is_deeply([$FORKS, $WAITS, $SIGNALS], \@before, 'review performs no process operation');
    return $result;
}

# Pure structural models. Their numeric identities are never passed to an OS
# operation. Only the separate real control below supplies native evidence.
sub model {
    my ($stage, $command_status, $reservation_status) = @_;
    $stage //= 'probe'; $command_status //= 0; $reservation_status //= 0;
    my $r = bless {owner_pid => $$, phase => 'finished', pid => 80002,
        birth_sec => 1_700_000_000, birth_usec => 0, group_ready => 1,
        moved => 1, retired => 1, reaped => 1, wait_status => $reservation_status},
        'FSM::Support::ProcessSupervisor::Reservation';
    my $p = bless {owner_pid => $$, phase => 'retired', command_pid => 80001,
        birth_sec => 1_700_000_001, birth_usec => 0, command_reaped => 1,
        command_status => $command_status, command_authority => 0,
        joined => 1, released => 1, retired => 1, reservation => $r},
        'FSM::Support::ProcessSupervisor::GatedPair';
    my $closure = bless {owner_pid => $$, pair => $p, phase => 'finished',
        complete => 1, group_gone => 1, term_sent => 0, kill_sent => 0,
        surviving_descendants => 0}, 'FSM::Support::ProcessSupervisor::GroupClosure';
    my $cleanup = FSM::Support::ProcessSupervisor::_new_cleanup(1, 'fixture-group');
    $cleanup->{leader_reaped} = $cleanup->{group_gone} = 1;
    my $s = {phase => 'finished', stage => $stage, cleanup => $cleanup,
        pid => $p->{command_pid}, birth_sec => $p->{birth_sec}, birth_usec => 0,
        leader_reaped => 1, group_identity => {
            pid => $r->{pid}, start_sec => $r->{birth_sec}, start_usec => 0},
        streams => {}, select => IO::Select->new};
    $s->{receipt_observation} = FSM::Support::ProcessSupervisor::_receipt_observation($s);
    my $job = bless {owner_pid => $$, pair => $p, closure => $closure,
        state => $s, received => {}, original_receipt => $s->{receipt_observation},
        original_cleanup => $cleanup, original_stage => $stage,
        original_containment => 'fixture-group'}, 'FSM::Support::ProcessSupervisor::ReservedJob';
    return ($job, $s->{receipt_observation});
}

subtest 'closed creator-bound stage models preserve zero microseconds and failed waits' => sub {
    for my $stage ([compile_proxy => 'compiler'], [probe => 'outer'], [tool_resolution => 'inner']) {
        for my $wait ([0, 0], [23 << 8, 0], [15, 9]) {
            my ($job, $receipt) = model($stage->[0], @$wait);
            ok(review($job, $receipt, $stage->[1], {closed => 1}), 'exact settled ownership can bind independently of exit success');
            ok(!NativeProxyReceiptAdapter::receipt_bound($receipt, $stage->[1], {closed => 1}),
                'historical own-group contract remains distinct');
        }
    }
};

subtest 'copied and replaced carriers cannot create owner-bound authority' => sub {
    my ($job, $receipt) = model();
    ok(!review($job, {%$receipt}, 'outer', {closed => 1}), 'even a shallow receipt copy is not the retained original');
    my $copy = {%$receipt, cleanup => {%{$receipt->{cleanup}}}};
    $copy->{cleanup_identity} = refaddr($copy->{cleanup});
    $job->{state}{receipt_observation} = $copy;
    $job->{state}{cleanup} = $copy->{cleanup};
    ok(!review($job, $copy, 'outer', {closed => 1}), 'coordinated returned-record replacement cannot replace creator-held ownership');
    ok(review($job, $receipt, 'outer', {closed => 1}), 'the original retained receipt remains independently bound');
    my ($foreign) = model();
    ok(!review($foreign, $receipt, 'outer', {closed => 1}), 'equal-valued identities from another owner cannot bind this receipt');
    for my $args (
        [$job, $receipt, 'outer', {closed => 0}],
        [$job, $receipt, 'inner', {closed => 1}],
        [$job, $receipt, [], {closed => 1}],
        [$job->{state}, $receipt, 'outer', {closed => 1}],
        [$job, $receipt, 'outer'],
        [$job, $receipt, 'outer', {closed => 1}, 'extra'],
    ) { ok(!review(@$args), 'invalid review boundary rejects'); }
};

subtest 'independent owner observations reject altered receipt and closure facts' => sub {
    my @cuts = (
        ['inherited creator', sub { $_[0]{owner_pid}++ }],
        ['unfinished job', sub { $_[0]{state}{phase} = 'capture' }],
        ['wrong schema', sub { $_[1]{schema} = 'other' }],
        ['wrong role', sub { $_[1]{role} = 'inner' }],
        ['changed stage in both carriers', sub { $_[0]{state}{stage} = $_[1]{stage} = 'tool_resolution' }],
        ['unfinished receipt', sub { $_[1]{phase} = 'capture' }],
        ['changed command birth', sub { $_[1]{birth}{start_usec}++ }],
        ['changed reservation birth', sub { $_[1]{group}{start_sec}++ }],
        ['aliased group', sub { $_[1]{group} = {%{$_[1]{birth}}} }],
        ['same numeric PID', sub { $_[0]{pair}{reservation}{pid} = $_[1]{group}{pid} = $_[1]{birth}{pid} }],
        ['extra identity field', sub { $_[1]{group}{extra} = 1 }],
        ['copied cleanup with updated address', sub { $_[1]{cleanup} = {%{$_[1]{cleanup}}}; $_[1]{cleanup_identity} = refaddr($_[1]{cleanup}) }],
        ['malformed address', sub { $_[1]{cleanup_identity} .= 'junk' }],
        ['unreaped receipt', sub { $_[1]{leader_reaped} = 0 }],
        ['unknown command wait', sub { $_[0]{pair}{command_status} = undef }],
        ['unreaped command', sub { $_[0]{pair}{command_reaped} = 0 }],
        ['live command authority', sub { $_[0]{pair}{command_authority} = 1 }],
        ['unretired command', sub { $_[0]{pair}{retired} = 0 }],
        ['unreaped reservation', sub { $_[0]{pair}{reservation}{reaped} = 0 }],
        ['unknown reservation wait', sub { $_[0]{pair}{reservation}{wait_status} = undef }],
        ['invalid reservation wait', sub { $_[0]{pair}{reservation}{wait_status} = 65536 }],
        ['unretired reservation', sub { $_[0]{pair}{reservation}{retired} = 0 }],
        ['missing departure', sub { $_[0]{pair}{reservation}{moved} = 0 }],
        ['missing group acknowledgment', sub { $_[0]{pair}{reservation}{group_ready} = 0 }],
        ['unfinished reservation', sub { $_[0]{pair}{reservation}{phase} = 'retiring' }],
        ['unfinished closure', sub { $_[0]{closure}{phase} = 'retiring' }],
        ['incomplete closure', sub { $_[0]{closure}{complete} = 0 }],
        ['unproved absence', sub { $_[0]{closure}{group_gone} = 0 }],
        ['retained closure failure', sub { $_[0]{closure}{failure} = 'uncertain group' }],
        ['false cleanup', sub { $_[1]{cleanup}{group_gone} = 0 }],
        ['wrong containment', sub { $_[1]{cleanup}{containment} = 'another' }],
        ['obsolete receipt array', sub { $_[1]{cleanup_array} = [] }],
        ['unclosed capture', sub { $_[0]{received}{stdout} = 'modeled retained handle' }],
    );
    for my $cut (@cuts) {
        my ($job, $receipt) = model();
        ok(review($job, $receipt, 'outer', {closed => 1}), "$cut->[0] control starts bound");
        $cut->[1]->($job, $receipt);
        ok(!review($job, $receipt, 'outer', {closed => 1}), "$cut->[0] rejects");
    }
};

END {
    local $?;
    if ($$ == $owner) {
        alarm 0;
        for my $job (@native) {
            my $p = $job->{pair};
            for my $entry ([$p->{command_pid}, $p->{command_authority}],
                [$p->reservation->{pid}, $p->reservation->{positive_authority}]) {
                next unless $entry->[0] && $entry->[1];
                kill 'KILL', $entry->[0];
                my $end = now() + 2;
                while (now() < $end) {
                    my $w = waitpid($entry->[0], WNOHANG);
                    last if $w == $entry->[0] || $w == -1;
                    sleep(0.001);
                }
            }
        }
    }
}
local $SIG{ALRM} = sub { die "reserved receipt test deadline\n" };
alarm 20;
subtest 'one real failed command can retain a bound settled receipt' => sub {
    my $snapshot = FSM::Support::ProcessSupervisor::Wire::snapshot_request({
        argv => [$^X, '-e', 'exit 23'], cwd => '.', schema => 'private.receipt.fixture.v1',
        stage => 'probe', containment => 'fixture-group',
        bounds => {timeout_seconds => 5, capture_limit_bytes => 64},
    }, sprintf('%.0f', now() * 1e9));
    my $job = FSM::Support::ProcessSupervisor::ReservedJob::prepare(
        snapshot => $snapshot, deadline => $snapshot->{started_ns} / 1e9 + 5, close_handles => []);
    push @native, $job;
    ok(!review($job, {}, 'outer', {closed => 1}), 'prepared ownership cannot bind a receipt');
    $job->start;
    my $end = now() + 8;
    while (now() < $end) {
        my $phase = $job->observation->{phase};
        last if $phase eq 'finished';
        $job->release if $phase eq 'ready';
        $job->advance;
        sleep(0.001);
    }
    my $state = $job->finished_job;
    is($state->{result}{exit_code}, 23, 'actual native wait reports the original nonzero exit');
    ok(!$state->{result}{ok} && $state->{resources_closed}, 'failed command and settled ownership remain distinct');
    ok(review($job, $state->{receipt_observation}, 'outer', {closed => 1}), 'real creator-held receipt binds after exact closure');
    ok(!review($job, $state->{result}, 'outer', {closed => 1}), 'public result is never an ownership receipt');
};
alarm 0;
done_testing();
