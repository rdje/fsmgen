#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use File::Spec;
use FindBin;

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::Support::SerializablePlanReportContract qw(
    build_serializable_plan_report_contract
    serializable_plan_report_public_top_level_keys
);

subtest 'serializable plan/report contract public key list matches emitted keys' => sub {
    my $contract = build_serializable_plan_report_contract();
    my $expected = as_set(serializable_plan_report_public_top_level_keys());
    my $actual = as_set([keys %{$contract}]);

    is_deeply($actual, $expected, 'emitted contract keys match advertised public top-level keys');
};

done_testing();

sub as_set {
    my ($values) = @_;
    return {map { $_ => 1 } @{$values || []}};
}
