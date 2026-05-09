#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use File::Spec;
use FindBin;
use JSON::PP qw(decode_json encode_json);

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::Support::SerializablePlanReportContract qw(
    build_serializable_plan_report_contract
    serializable_plan_report_surface_registry_entry_keys
);

subtest 'serializable plan/report registry entry keys survive JSON round trip' => sub {
    my $decoded = decode_json(encode_json(build_serializable_plan_report_contract()));

    is_deeply(
        $decoded->{surface_registry_entry_keys},
        serializable_plan_report_surface_registry_entry_keys(),
        'decoded contract preserves canonical registry entry key list',
    );
};

subtest 'decoded registry entries match decoded entry key list' => sub {
    my $decoded = decode_json(encode_json(build_serializable_plan_report_contract()));
    my $expected = as_set($decoded->{surface_registry_entry_keys});

    for my $surface (sort keys %{$decoded->{surface_registry}}) {
        is_deeply(
            as_set([keys %{$decoded->{surface_registry}{$surface}}]),
            $expected,
            "$surface decoded registry entry keys match decoded shape",
        );
    }
};

done_testing();

sub as_set {
    my ($values) = @_;
    return {map { $_ => 1 } @{$values || []}};
}
