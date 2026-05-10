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

subtest 'manifest-embedded serializable plan reports embedded child contracts rebuilds cleanly after caller mutation' => sub {
    my $first = build_capability_manifest();
    my $mutated = $first->{embedding}{serializable_plan_reports};
    mutate_structure($mutated->{'composition_plan_snapshot_contract'});
    mutate_structure($mutated->{'generation_result_snapshot_contract'});
    mutate_structure($mutated->{'diagnostic_summary_contract'});

    my $second = build_capability_manifest();
    my $contract = $second->{embedding}{serializable_plan_reports};
    my $expected = build_serializable_plan_report_contract();
    is_deeply($contract->{'composition_plan_snapshot_contract'}, $expected->{'composition_plan_snapshot_contract'}, 'fresh manifest serializable plan report contract rebuilds clean composition_plan_snapshot_contract');
    is_deeply($contract->{'generation_result_snapshot_contract'}, $expected->{'generation_result_snapshot_contract'}, 'fresh manifest serializable plan report contract rebuilds clean generation_result_snapshot_contract');
    is_deeply($contract->{'diagnostic_summary_contract'}, $expected->{'diagnostic_summary_contract'}, 'fresh manifest serializable plan report contract rebuilds clean diagnostic_summary_contract');
};
done_testing();

sub mutate_structure {
    my ($value) = @_;
    return unless ref($value);
    if (ref($value) eq 'ARRAY') { push @{$value}, $sentinel; mutate_structure($_) for @{$value}; return; }
    if (ref($value) eq 'HASH') { $value->{$sentinel} = $sentinel; mutate_structure($_) for values %{$value}; return; }
}
