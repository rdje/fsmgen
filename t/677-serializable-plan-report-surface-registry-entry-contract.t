#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use File::Spec;
use FindBin;

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::Support::SerializablePlanReportContract qw(
    build_serializable_plan_report_contract
    serializable_plan_report_surface_registry
    serializable_plan_report_surface_registry_entry_keys
);

subtest 'surface registry entry keys are explicit and embedded' => sub {
    is_deeply(
        serializable_plan_report_surface_registry_entry_keys(),
        [qw(contract_source primary_report_paths)],
        'entry key helper exposes the stable registry entry shape',
    );
    is_deeply(
        build_serializable_plan_report_contract()->{surface_registry_entry_keys},
        serializable_plan_report_surface_registry_entry_keys(),
        'parent contract embeds the entry key list',
    );
};

subtest 'surface registry entries match the advertised entry key list' => sub {
    my $registry = serializable_plan_report_surface_registry();
    my $expected = as_set(serializable_plan_report_surface_registry_entry_keys());

    for my $surface (sort keys %{$registry}) {
        is_deeply(
            as_set([keys %{$registry->{$surface}}]),
            $expected,
            "$surface registry entry keys match advertised shape",
        );
    }
};

done_testing();

sub as_set {
    my ($values) = @_;
    return {map { $_ => 1 } @{$values || []}};
}
