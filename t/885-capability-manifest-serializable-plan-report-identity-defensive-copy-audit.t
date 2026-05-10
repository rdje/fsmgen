#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use File::Spec;
use FindBin;
use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');
use FSM::Support::CapabilityManifest qw(build_capability_manifest);
use FSM::Support::SerializablePlanReportContract qw(build_serializable_plan_report_contract);
my $sentinel = '__manifest_serializable_plan_report_mutation__';

subtest 'manifest-embedded serializable plan reports identity metadata rebuilds cleanly after caller mutation' => sub {
    my $first = build_capability_manifest();
    my $mutated = $first->{embedding}{serializable_plan_reports};
    $mutated->{'status'} = $sentinel;
    $mutated->{'contract_source'} = $sentinel;
    $mutated->{'purpose'} = $sentinel;

    my $second = build_capability_manifest();
    my $contract = $second->{embedding}{serializable_plan_reports};
    my $expected = build_serializable_plan_report_contract();
    is($contract->{'status'}, $expected->{'status'}, 'fresh manifest serializable plan report contract rebuilds clean status');
    is($contract->{'contract_source'}, $expected->{'contract_source'}, 'fresh manifest serializable plan report contract rebuilds clean contract_source');
    is($contract->{'purpose'}, $expected->{'purpose'}, 'fresh manifest serializable plan report contract rebuilds clean purpose');
    is($contract->{schema_version}, $expected->{schema_version}, 'fresh manifest serializable plan report contract rebuilds clean schema_version');
};
done_testing();

sub mutate_structure {
    my ($value) = @_;
    return unless ref($value);
    if (ref($value) eq 'ARRAY') { push @{$value}, $sentinel; mutate_structure($_) for @{$value}; return; }
    if (ref($value) eq 'HASH') { $value->{$sentinel} = $sentinel; mutate_structure($_) for values %{$value}; return; }
}
