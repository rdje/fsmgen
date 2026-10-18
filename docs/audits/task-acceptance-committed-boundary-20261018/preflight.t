use strict;
use warnings;
use Test::More;
use JSON::PP ();
use Scalar::Util qw(refaddr);
use lib 'perl', 't/lib', 'docs/audits/native-group-witness-20260927',
    'docs/audits/native-group-witness-20260927/failure-only',
    'docs/audits/task-acceptance-index-observer-20261017',
    'docs/audits/task-acceptance-index-prospective-20261018',
    'docs/audits/task-acceptance-committed-boundary-20261018';
use ProspectiveIndexObserver;

my @methods = qw(IndexObserver::new IndexObserver::install IndexObserver::retain
    IndexObserver::capture_gaps IndexObserver::finish IndexObserver::normalize
    IndexObserver::save IndexObserver::read_bytes IndexObserver::encode
    IndexObserver::validate IndexObserver::admission
    ProspectiveIndexObserver::unexpected ProspectiveIndexObserver::stop_harness
    FailureWitness::wrap FailureWitness::_query_context FailureWitness::_write
    FSM::Support::ProcessSupervisor::setpgid
    FSM::Test::TaskAcceptanceIndexRuntime::supervise_process
    FSM::Test::TaskAcceptanceIndexRuntime::run_index_case);
sub identities {
    no strict 'refs';
    return {map { die "undefined method $_\n" unless defined &{$_}; $_ => refaddr(\&{$_}) } @methods};
}
my $before = identities();
my %base = map { $_ => 1 } IndexObserver::paths();
require BoundaryIndexObserver;
is_deeply(identities(), $before, 'every native capture/result/cleanup/stop method is unchanged');
is($IndexObserver::WORK, '.artifacts/task-acceptance-committed-boundary-20261018', 'fresh fixed workspace');
my $target = 't/2072-task-acceptance-box-boundaries.t';
my $admission = IndexObserver::admission($target);
ok(IndexObserver::validate($admission, $target), 'complete closed admission validates without native execution');
is_deeply($admission->{expected}, [9, 90, 9], 'explicit original programme population');
my @added = sort grep { !$base{$_} } IndexObserver::paths();
is_deeply(\@added, [sort($target, map { 'docs/audits/task-acceptance-committed-boundary-20261018/' . $_ }
    qw(BoundaryIndexObserver.pm run.py verify.py preflight.t preflight.py contract.json))], 'only declared data/programme sources are added');
for my $outside ('control_healthy', 't/2068-task-acceptance-index-runtime.t', '../other.t') {
    eval { IndexObserver::selection($outside) };
    like($@, qr/outside committed boundary scope/, 'outside selector refuses before observation');
}
for my $kind (qw(source missing population target)) {
    my $bad = JSON::PP->new->decode(IndexObserver::encode($admission));
    my $path = 'docs/audits/task-acceptance-committed-boundary-20261018/run.py';
    $bad->{sha256}{$path} = '0' x 64 if $kind eq 'source';
    delete $bad->{sha256}{$path} if $kind eq 'missing';
    $bad->{expected}[1] = 89 if $kind eq 'population';
    $bad->{target} = '../other.t' if $kind eq 'target';
    eval { IndexObserver::validate($bad, $target) };
    like($@, qr/closed observer admission or source identity changed/, "$kind substitution refuses");
}
done_testing();
