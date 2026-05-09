#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use File::Spec;
use FindBin;

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::Support::SerializablePlanReportContract qw(
    build_serializable_plan_report_contract
    serializable_plan_report_nested_contract_source_map
    serializable_plan_report_surface_registry
);

subtest 'surface registry owners match nested contract source map' => sub {
    my $registry = serializable_plan_report_surface_registry();
    my $source_map = serializable_plan_report_nested_contract_source_map();

    is_deeply(as_set([keys %{$registry}]), as_set([keys %{$source_map}]), 'registry and source map cover same surfaces');
    for my $surface (sort keys %{$source_map}) {
        is($registry->{$surface}{contract_source}, $source_map->{$surface}, "$surface owner matches source map");
    }
};

subtest 'parent contract embeds aligned registry and nested source map' => sub {
    my $contract = build_serializable_plan_report_contract();
    for my $surface (sort keys %{$contract->{nested_contract_source_map}}) {
        is(
            $contract->{surface_registry}{$surface}{contract_source},
            $contract->{nested_contract_source_map}{$surface},
            "$surface embedded registry owner matches embedded source map",
        );
    }
};

done_testing();

sub as_set {
    my ($values) = @_;
    return {map { $_ => 1 } @{$values || []}};
}
