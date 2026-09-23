#!/usr/bin/env perl
use strict;
use warnings;
our $forbidden = 0;
BEGIN {
    *CORE::GLOBAL::fork = sub { ++$forbidden; die 'forbidden fork'; };
    *CORE::GLOBAL::system = sub { ++$forbidden; die 'forbidden system'; };
    *CORE::GLOBAL::exec = sub { ++$forbidden; die 'forbidden exec'; };
    *CORE::GLOBAL::kill = sub { ++$forbidden; die 'forbidden signal'; };
}
use FindBin;
use lib $FindBin::Bin;
use Test::More;
use Admission;

my $admit = \&NativeProxyReceiptAdmission::admitted;
my $execute = \&NativeProxyReceiptAdmission::execution_allowed;
my $issue = \&NativeProxyReceiptAdmission::issue_permit;
my $consume = \&NativeProxyReceiptAdmission::consume_permit;
my $revision = 'b' x 40;

sub admission {
    return {
        source_revision => $revision,
        execution => 'closed',
        permit => 'unissued',
        sealed_return => NativeProxyReceiptAdmission::sealed_return_name(),
        roles => NativeProxyReceiptAdmission::required_roles(),
        private_fields => NativeProxyReceiptAdmission::required_private_fields(),
        replay_original => 0,
        replay_proxy => 0,
        live_collector => 0,
    };
}

my $good = admission();
ok($admit->($good), 'closed admission matches the current public stages');
ok(!$execute->($good), 'admitted plan still refuses execution');
is(NativeProxyReceiptAdmission::required_private_fields()->[0], 'pid', 'private pid is required');
is(NativeProxyReceiptAdmission::required_private_fields()->[6], 'cleanup_identity', 'private cleanup identity is required');

my @rejected;
sub reject {
    my ($name, $value) = @_;
    push @rejected, $name;
    ok(!$admit->($value), $name);
    ok(!$execute->($value), "$name also refuses execution");
}
my $short = admission(); $short->{source_revision} = 'abc';
reject('short source revision', $short);
my $open = admission(); $open->{execution} = 'open';
reject('open execution', $open);
my $issued = admission(); $issued->{permit} = 'issued';
reject('issued permit', $issued);
my $missing = admission(); pop @{$missing->{roles}};
reject('missing inner role', $missing);
my $swapped = admission(); @{$swapped->{roles}} = @{$swapped->{roles}}[1, 0, 2];
reject('swapped role order', $swapped);
my $changed = admission(); $changed->{roles}[2]{stage} = 'tool_admission';
reject('substituted inner stage', $changed);
my $dropped = admission(); pop @{$dropped->{private_fields}};
reject('dropped cleanup identity', $dropped);
my $replay = admission(); $replay->{replay_original} = 1;
reject('original replay', $replay);
my $proxy = admission(); $proxy->{replay_proxy} = 1;
reject('proxy replay', $proxy);
my $live = admission(); $live->{live_collector} = 1;
reject('live collector', $live);
reject('missing plan', undef);
is(scalar(@rejected), 11, 'every declared rejection remains distinct');

my $unnamed = admission();
delete $unnamed->{sealed_return};
is($issue->($unnamed), undef, 'a plan that omits the sealed return issues nothing');
my $renamed = admission();
$renamed->{sealed_return} = 'FSM::Support::ProcessSupervisor::supervise_process';
is($issue->($renamed), undef, 'a public supervisor name issues nothing');
my $replayed = admission();
$replayed->{replay_original} = 1;
is($issue->($replayed), undef, 'original replay issues nothing');
is($admit->($good), 1, 'issuing nothing leaves the closed plan admitted');

my $token = $issue->($good);
is(ref($token), 'HASH', 'one fresh permit is issued');
is($token->{sealed_return}, NativeProxyReceiptAdmission::sealed_return_name(),
    'the permit names the sealed private return');
is($token->{source_revision}, $revision, 'the permit binds the current source revision');
is($token->{uses_remaining}, 1, 'the fresh permit has one use');
is($issue->($good), undef, 'a second issue is rejected');
my $other_revision = admission();
$other_revision->{source_revision} = 'c' x 40;
ok(!$consume->($other_revision, $token), 'a different source revision cannot consume the permit');
my $replay_consume = admission();
$replay_consume->{replay_proxy} = 1;
ok(!$consume->($replay_consume, $token), 'proxy replay cannot consume the permit');
my $live_consume = admission();
$live_consume->{live_collector} = 1;
ok(!$consume->($live_consume, $token), 'a live collector cannot consume the permit');
ok($consume->($good, $token), 'the matching closed plan consumes the issued permit');
ok(!$consume->($good, $token), 'the same token cannot be consumed again');
is($execute->($good), 0, 'a consumed permit still refuses execution');
is($forbidden, 0, 'no process or signal attempt');
done_testing;
