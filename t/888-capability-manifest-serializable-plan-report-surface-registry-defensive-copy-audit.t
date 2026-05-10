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

subtest 'manifest-embedded serializable plan reports surface registry rebuilds cleanly after caller mutation' => sub {
    my $first = build_capability_manifest();
    my $mutated = $first->{embedding}{serializable_plan_reports};
    mutate_structure($mutated->{'surface_registry'});

    my $second = build_capability_manifest();
    my $contract = $second->{embedding}{serializable_plan_reports};
    my $expected = build_serializable_plan_report_contract();
    is_deeply($contract->{'surface_registry'}, $expected->{'surface_registry'}, 'fresh manifest serializable plan report contract rebuilds clean surface_registry');
};
done_testing();

sub mutate_structure {
    my ($value) = @_;
    return unless ref($value);
    if (ref($value) eq 'ARRAY') { push @{$value}, $sentinel; mutate_structure($_) for @{$value}; return; }
    if (ref($value) eq 'HASH') { $value->{$sentinel} = $sentinel; mutate_structure($_) for values %{$value}; return; }
}
