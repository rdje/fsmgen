use strict;
use warnings;
no warnings 'once';
use Test::More;
use JSON::PP ();
use Scalar::Util qw(refaddr);
use Errno qw(EIO);
use lib 'perl', 't/lib', 'docs/audits/native-group-witness-20260927',
    'docs/audits/native-group-witness-20260927/failure-only',
    'docs/audits/task-acceptance-index-observer-20261017',
    'docs/audits/task-acceptance-index-prospective-20261018';
use IndexObserver;

# No native supervisor, Git fixture or original test executes here. The actual
# prospective wrapper is exercised around an inert caller that records cleanup
# and receipt ordering independently of the wrapper's stop predicate.
my $installed = 0;
no warnings 'redefine';
local *IndexObserver::install = sub { ++$installed };
require ProspectiveIndexObserver;

is($IndexObserver::WORK, '.artifacts/task-acceptance-index-prospective-20261018', 'fresh fixed namespace');
my $admission = IndexObserver::admission('control_healthy');
ok(IndexObserver::validate($admission, 'control_healthy'), 'complete old and new source closure passes');
for my $mutation (qw(changed missing selector)) {
    my $bad = JSON::PP->new->decode(IndexObserver::encode($admission));
    my $path = 'docs/audits/task-acceptance-index-prospective-20261018/run.py';
    $bad->{sha256}{$path} = '0' x 64 if $mutation eq 'changed';
    delete $bad->{sha256}{$path} if $mutation eq 'missing';
    $bad->{selector} = 'control_unselected' if $mutation eq 'selector';
    eval { IndexObserver::validate($bad, 'control_healthy') };
    like($@, qr/closed observer admission or source identity changed/, "$mutation refuses before observation");
}

for my $mode (qw(success checker_refusal intentional_session unexpected_native unsettled)) {
    subtest $mode => sub {
        my (@order, $stages);
        $stages = 0;
        my $stage = {stage => 'index_checker', ok => 1, exit_code => 0,
            signal => 0, timed_out => 0, output_limited => 0, exec_error => undef,
            cleanup => {leader_reaped => 1, group_gone => 1, surviving_descendants => 0}};
        $stage->{exit_code} = 1 if $mode eq 'checker_refusal';
        if ($mode =~ /session|native/) {
            $stage->{ok} = 0;
            $stage->{exit_code} = 126;
            $stage->{exec_error} = 'pid=17 operation=setpgid result=undef errno=1 fixed diagnostic';
        }
        $stage->{cleanup}{group_gone} = 0 if $mode eq 'unsettled';
        my $case = {checker => $stage, cleanup => {retired => $mode eq 'unsettled' ? 0 : 1}};
        my $before = IndexObserver::encode($case);
        local $INC{'Control.pm'} = 'docs/audits/task-acceptance-index-observer-20261017/Control.pm';
        local $Control::kind = $mode eq 'intentional_session' ? 'session' : 'ordinary';
        local *FSM::Test::TaskAcceptanceIndexRuntime::supervise_process = sub {
            ++$stages;
            push @order, 'native';
            $! = EIO;
            return $stage;
        };
        local *FSM::Test::TaskAcceptanceIndexRuntime::run_index_case = sub {
            my $result = FSM::Test::TaskAcceptanceIndexRuntime::supervise_process();
            is(refaddr($result), refaddr($stage), 'native result reference is unchanged');
            is(0 + $!, EIO, 'native errno is unchanged');
            push @order, 'cleanup', 'retained';
            $! = EIO;
            return $case;
        };
        my $observer = bless {stages => 0}, 'IndexObserver';
        $observer->install();
        my $returned;
        eval {
            $returned = FSM::Test::TaskAcceptanceIndexRuntime::run_index_case('sealed_case');
            push @order, 'later_case';
            1;
        };
        my $error = $@;
        if ($mode eq 'unexpected_native' || $mode eq 'unsettled') {
            like($error, qr/stopped after retained case result/, 'unexpected native truth aborts after case cleanup');
            is_deeply(\@order, [qw(native cleanup retained)], 'no later case precedes complete result retention');
            eval { FSM::Test::TaskAcceptanceIndexRuntime::supervise_process() };
            like($@, qr/refuses later native stage/, 'subsequent stage refuses before native caller');
            is($stages, 1, 'exactly one inert native caller invocation');
        }
        else {
            is($error, '', 'ordinary or intentional result is returned');
            is(refaddr($returned), refaddr($case), 'case result reference is unchanged');
            is(0 + $!, EIO, 'case errno is unchanged');
            is_deeply(\@order, [qw(native cleanup retained later_case)], 'permitted control can continue');
        }
        is(IndexObserver::encode($case), $before, 'all native and case result fields are unchanged');
        my @bailouts;
        local *Test::More::BAIL_OUT = sub { push @bailouts, @_ };
        ProspectiveIndexObserver::stop_harness($observer);
        is(scalar(@bailouts), ($mode eq 'unexpected_native' || $mode eq 'unsettled') ? 1 : 0,
            'only unexpected failure signals TAP bailout after receipt retention');
    };
}
is($installed, 5, 'original installer called once for each inert observer');
done_testing();
