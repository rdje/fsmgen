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

subtest 'manifest-embedded serializable plan reports JSON-safety flags and guidance rebuilds cleanly after caller mutation' => sub {
    my $first = build_capability_manifest();
    my $mutated = $first->{embedding}{serializable_plan_reports};
    $mutated->{'current_serializable_surfaces_json_safe'} = $mutated->{'current_serializable_surfaces_json_safe'} ? 0 : 1;
    $mutated->{'raw_hdl_generator_branches_json_safe'} = $mutated->{'raw_hdl_generator_branches_json_safe'} ? 0 : 1;
    mutate_structure($mutated->{'guidance'});

    my $second = build_capability_manifest();
    my $contract = $second->{embedding}{serializable_plan_reports};
    my $expected = build_serializable_plan_report_contract();
    is($contract->{'current_serializable_surfaces_json_safe'} ? 1 : 0, $expected->{'current_serializable_surfaces_json_safe'} ? 1 : 0, 'fresh manifest serializable plan report contract rebuilds clean current_serializable_surfaces_json_safe');
    is($contract->{'raw_hdl_generator_branches_json_safe'} ? 1 : 0, $expected->{'raw_hdl_generator_branches_json_safe'} ? 1 : 0, 'fresh manifest serializable plan report contract rebuilds clean raw_hdl_generator_branches_json_safe');
    is_deeply($contract->{'guidance'}, $expected->{'guidance'}, 'fresh manifest serializable plan report contract rebuilds clean guidance');
};
done_testing();

sub mutate_structure {
    my ($value) = @_;
    return unless ref($value);
    if (ref($value) eq 'ARRAY') { push @{$value}, $sentinel; mutate_structure($_) for @{$value}; return; }
    if (ref($value) eq 'HASH') { $value->{$sentinel} = $sentinel; mutate_structure($_) for values %{$value}; return; }
}
