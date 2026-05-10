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

subtest 'manifest-embedded composition report public summary and collection key families rebuilds cleanly after caller mutation' => sub {
    my $first = build_capability_manifest();
    my $mutated = $first->{embedding}{composition_report};
    mutate_structure($mutated->{'public_top_level_keys'});
    mutate_structure($mutated->{'summary_keys'});
    mutate_structure($mutated->{'collection_keys'});

    my $second = build_capability_manifest();
    my $contract = $second->{embedding}{composition_report};
    my $expected = build_composition_report_contract();
    is_deeply($contract->{'public_top_level_keys'}, $expected->{'public_top_level_keys'}, 'fresh manifest composition report rebuilds clean public_top_level_keys');
    is_deeply($contract->{'summary_keys'}, $expected->{'summary_keys'}, 'fresh manifest composition report rebuilds clean summary_keys');
    is_deeply($contract->{'collection_keys'}, $expected->{'collection_keys'}, 'fresh manifest composition report rebuilds clean collection_keys');
};
done_testing();

sub mutate_structure {
    my ($value) = @_;
    return unless ref($value);
    if (ref($value) eq 'ARRAY') { push @{$value}, $sentinel; mutate_structure($_) for @{$value}; return; }
    if (ref($value) eq 'HASH') { $value->{$sentinel} = $sentinel; mutate_structure($_) for values %{$value}; return; }
}
