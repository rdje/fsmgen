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

subtest 'manifest-embedded composition report identity metadata rebuilds cleanly after caller mutation' => sub {
    my $first = build_capability_manifest();
    my $mutated = $first->{embedding}{composition_report};
    $mutated->{'status'} = $sentinel;
    $mutated->{'contract_source'} = $sentinel;
    $mutated->{'report_builder'} = $sentinel;
    $mutated->{'raw_result_key'} = $sentinel;
    $mutated->{'json_fragment_path'} = $sentinel;

    my $second = build_capability_manifest();
    my $contract = $second->{embedding}{composition_report};
    my $expected = build_composition_report_contract();
    is($contract->{'status'}, $expected->{'status'}, 'fresh manifest composition report rebuilds clean status');
    is($contract->{'contract_source'}, $expected->{'contract_source'}, 'fresh manifest composition report rebuilds clean contract_source');
    is($contract->{'report_builder'}, $expected->{'report_builder'}, 'fresh manifest composition report rebuilds clean report_builder');
    is($contract->{'raw_result_key'}, $expected->{'raw_result_key'}, 'fresh manifest composition report rebuilds clean raw_result_key');
    is($contract->{'json_fragment_path'}, $expected->{'json_fragment_path'}, 'fresh manifest composition report rebuilds clean json_fragment_path');
};
done_testing();

sub mutate_structure {
    my ($value) = @_;
    return unless ref($value);
    if (ref($value) eq 'ARRAY') { push @{$value}, $sentinel; mutate_structure($_) for @{$value}; return; }
    if (ref($value) eq 'HASH') { $value->{$sentinel} = $sentinel; mutate_structure($_) for values %{$value}; return; }
}
