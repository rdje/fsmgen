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
use Scalar::Util ();
use Test::More;
use ReceiptAdapter;

my $bound = \&NativeProxyReceiptAdapter::receipts_bound;
my $launch = \&NativeProxyReceiptAdapter::launch_allowed;

sub birth {
    my ($pid) = @_;
    return {pid => $pid, start_sec => 1_700_000_000 + $pid, start_usec => $pid};
}

sub receipt {
    my ($role, $pid, $stage) = @_;
    my $cleanup = {leader_started => 1, leader_reaped => 1, group_gone => 1};
    return {
        role => $role,
        birth => birth($pid),
        group => birth($pid + 1000),
        stage => $stage,
        phase => 'finished',
        leader_reaped => 1,
        cleanup => $cleanup,
        cleanup_identity => Scalar::Util::refaddr($cleanup),
    };
}

my $open = {closed => 0};
my $closed = {closed => 1};
my @good = (
    receipt('compiler', 11, 'compile_proxy'),
    receipt('outer', 12, 'probe'),
    receipt('inner', 13, 'tool_resolution'),
);
ok(!$bound->([map { {%$_} } @good], $open), 'open frontier rejects settled ownership');
ok($bound->([map { {%$_} } @good], $closed), 'closed frontier accepts complete owner-bound receipts');
ok($launch->($open), 'open frontier still allows a launch decision');
ok(!$launch->($closed), 'closed frontier rejects a later launch');

my @rejected;
sub reject {
    my ($name, $receipts, $frontier) = @_;
    push @rejected, $name;
    ok(!$bound->($receipts, $frontier), $name);
}

my $missing = [map { {%$_} } @good];
pop @$missing;
reject('missing inner stage', $missing, $closed);
my $extra = [map { {%$_} } @good, receipt('inner', 14, 'extra')];
reject('extra stage', $extra, $closed);
my $swapped = [map { {%$_} } @good[1, 0, 2]];
reject('substituted role order', $swapped, $closed);
my $stale = [map { {%$_} } @good];
$stale->[1]{phase} = 'capture';
reject('unfinished capture', $stale, $closed);
my $copied = [map { {%$_} } @good];
$copied->[0]{cleanup} = {%{$copied->[0]{cleanup}}};
reject('copied cleanup hash is not private state', $copied, $closed);
my $unreaped = [map { {%$_} } @good];
$unreaped->[0]{cleanup}{leader_reaped} = 0;
reject('unreaped leader', $unreaped, $closed);
my $same = [map { {%$_} } @good];
$same->[2]{birth} = {%{$same->[0]{birth}}};
reject('reused birth', $same, $closed);
my $aliased = [map { {%$_} } @good];
$aliased->[0]{group} = {%{$aliased->[0]{birth}}};
reject('group aliases leader birth', $aliased, $closed);
my $array = [map { {%$_} } @good];
$array->[0]{cleanup_array} = [{leader_started => 1, leader_reaped => 1, group_gone => 1}];
reject('supplied cleanup array grants no authority', $array, $closed);
ok(!$bound->([map { {%$_} } @good], {closed => 2}), 'non-boolean frontier rejects');
ok(!$launch->({closed => 'yes'}), 'non-boolean launch decision rejects');
is($forbidden, 0, 'no process or signal attempt');
is(scalar(@rejected), 9, 'every declared rejection remains distinct');
done_testing;
