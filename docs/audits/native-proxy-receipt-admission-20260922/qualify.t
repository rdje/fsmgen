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
my $revision = 'b' x 40;

sub admission {
    return {
        source_revision => $revision,
        execution => 'closed',
        permit => 'unissued',
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
is($forbidden, 0, 'no process or signal attempt');
done_testing;
