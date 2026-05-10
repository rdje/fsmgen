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

subtest 'manifest-embedded serializable plan reports public report key metadata rebuilds cleanly after caller mutation' => sub {
    my $first = build_capability_manifest();
    my $mutated = $first->{embedding}{serializable_plan_reports};
    $mutated->{'composition_report_json_fragment_path'} = $sentinel;
    mutate_structure($mutated->{'normalized_semantic_report_public_top_level_keys'});
    mutate_structure($mutated->{'composition_report_public_top_level_keys'});

    my $second = build_capability_manifest();
    my $contract = $second->{embedding}{serializable_plan_reports};
    my $expected = build_serializable_plan_report_contract();
    is($contract->{'composition_report_json_fragment_path'}, $expected->{'composition_report_json_fragment_path'}, 'fresh manifest serializable plan report contract rebuilds clean composition_report_json_fragment_path');
    is_deeply($contract->{'normalized_semantic_report_public_top_level_keys'}, $expected->{'normalized_semantic_report_public_top_level_keys'}, 'fresh manifest serializable plan report contract rebuilds clean normalized_semantic_report_public_top_level_keys');
    is_deeply($contract->{'composition_report_public_top_level_keys'}, $expected->{'composition_report_public_top_level_keys'}, 'fresh manifest serializable plan report contract rebuilds clean composition_report_public_top_level_keys');
};
done_testing();

sub mutate_structure {
    my ($value) = @_;
    return unless ref($value);
    if (ref($value) eq 'ARRAY') { push @{$value}, $sentinel; mutate_structure($_) for @{$value}; return; }
    if (ref($value) eq 'HASH') { $value->{$sentinel} = $sentinel; mutate_structure($_) for values %{$value}; return; }
}
