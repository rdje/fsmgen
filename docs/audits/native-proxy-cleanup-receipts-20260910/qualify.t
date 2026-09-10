#!/usr/bin/env perl
use strict;
use warnings;
our $forbidden = 0;
BEGIN {
    *CORE::GLOBAL::fork = sub { ++$forbidden; die 'forbidden fork'; };
    *CORE::GLOBAL::system = sub { ++$forbidden; die 'forbidden system'; };
    *CORE::GLOBAL::exec = sub { ++$forbidden; die 'forbidden exec'; };
}
use FindBin;
use lib "$FindBin::Bin/../../../perl", $FindBin::Bin;
use JSON::PP ();
use Test::More;
use FSM::ProjectDataLocality qw(ensure_project_artifact_dir);
use CleanupReceipts;

my $json = JSON::PP->new->canonical->ascii;
open my $input, '<:raw', "$FindBin::Bin/plan.json" or die "plan: $!";
my $plan = $json->decode(do { local $/; <$input> });
close $input or die "close plan: $!";
my $log = ensure_project_artifact_dir(qw(logs native-proxy-cleanup-receipts-20260910));
my $review = \&NativeProxyCleanupReceipts::cleanup_receipts_settled;
my (@cases, %mutants);
my $result = {schema => 'fsmgen.inactive_cleanup_receipt_qualification.v1',
              success => JSON::PP::false, cases => \@cases, mutants => \%mutants};

sub save_result {
    $result->{forbidden_process_attempts} = $forbidden;
    open my $output, '>:raw', "$log/qualification.json" or die "result: $!";
    print {$output} $json->pretty->encode($result) or die "write result: $!";
    close $output or die "close result: $!";
}

save_result();
for my $case (@{$plan->{cases}}) {
    my $before = $json->encode($case->{arguments});
    my $actual = $review->(@{$case->{arguments}});
    my $unchanged = $before eq $json->encode($case->{arguments}) ? 1 : 0;
    push @cases, {name => $case->{name}, actual => $actual, input_unchanged => $unchanged};
    save_result();
    ok($actual == $case->{expected} && $unchanged, $case->{name})
        or BAIL_OUT('first unexpected receipt result retained');
}

my $settled = \&NativeProxyCleanupReceipts::_settled_owner;
my %by_name = map { $_->{name} => $_ } @{$plan->{cases}};
no warnings 'redefine';
for my $control (
    ['omitted compiler', 'compiler: flags 110', sub {
        return 1 if $_[0]{stage} eq 'compile_proxy'; return $settled->(@_);
    }],
    ['omitted outer', 'outer: flags 110', sub {
        return 1 if $_[0]{stage} eq 'probe'; return $settled->(@_);
    }],
    ['omitted later inner', 'inner-last: flags 110', sub {
        return 1 if $_[0]{stage} eq 'tool_admission'; return $settled->(@_);
    }],
    ['omitted leader reap', 'inner-first: flags 101', sub {
        return $_[0]{cleanup}{group_gone} ? 1 : 0;
    }],
) {
    my ($name, $case_name, $replacement) = @$control;
    local *NativeProxyCleanupReceipts::_settled_owner = $replacement;
    my $case = $by_name{$case_name};
    my $before = $json->encode($case->{arguments});
    my $actual = $review->(@{$case->{arguments}});
    my $unchanged = $before eq $json->encode($case->{arguments}) ? 1 : 0;
    $mutants{$name} = {case_name => $case_name, actual => $actual,
                      expected => $case->{expected}, input_unchanged => $unchanged};
    save_result();
    ok($actual == 1 && !$case->{expected} && $unchanged, "$name defeats the independent case")
        or BAIL_OUT('first unexpected mutant result retained');
}
is($forbidden, 0, 'no process attempt');
$result->{success} = Test::More->builder->is_passing ? JSON::PP::true : JSON::PP::false;
save_result();
done_testing;
