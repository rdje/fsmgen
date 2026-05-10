#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use File::Spec;
use FindBin;
use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');
use FSM::Support::CapabilityManifest qw(build_capability_manifest);
use FSM::Support::CompositionReportContract qw(build_composition_report_contract);
my $sentinel = '__manifest_composition_report_mutation__';

subtest 'manifest-embedded composition report map and ordered key families rebuilds cleanly after caller mutation' => sub {
    my $first = build_capability_manifest();
    my $mutated = $first->{embedding}{composition_report};
    mutate_structure($mutated->{'count_map_keys'});
    mutate_structure($mutated->{'example_map_keys'});
    mutate_structure($mutated->{'ordered_list_keys'});
    mutate_structure($mutated->{'presence_key_family_map'});

    my $second = build_capability_manifest();
    my $contract = $second->{embedding}{composition_report};
    my $expected = build_composition_report_contract();
    is_deeply($contract->{'count_map_keys'}, $expected->{'count_map_keys'}, 'fresh manifest composition report rebuilds clean count_map_keys');
    is_deeply($contract->{'example_map_keys'}, $expected->{'example_map_keys'}, 'fresh manifest composition report rebuilds clean example_map_keys');
    is_deeply($contract->{'ordered_list_keys'}, $expected->{'ordered_list_keys'}, 'fresh manifest composition report rebuilds clean ordered_list_keys');
    is_deeply($contract->{'presence_key_family_map'}, $expected->{'presence_key_family_map'}, 'fresh manifest composition report rebuilds clean presence_key_family_map');
};
done_testing();

sub mutate_structure {
    my ($value) = @_;
    return unless ref($value);
    if (ref($value) eq 'ARRAY') { push @{$value}, $sentinel; mutate_structure($_) for @{$value}; return; }
    if (ref($value) eq 'HASH') { $value->{$sentinel} = $sentinel; mutate_structure($_) for values %{$value}; return; }
}
