#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use File::Spec;
use FindBin;
use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');
use FSM::Support::CapabilityManifest qw(build_capability_manifest);
use FSM::Support::CapabilityManifestContract qw(build_capability_manifest_contract);
my $sentinel = '__manifest_contract_mutation__';

subtest 'manifest contract top-level contract source map rebuilds cleanly after caller mutation' => sub {
    my $first = build_capability_manifest();
    my $mutated = $first->{manifest_contract};
    mutate_structure($mutated->{'top_level_contract_source_map'});

    my $second = build_capability_manifest();
    my $contract = $second->{manifest_contract};
    my $expected = build_capability_manifest_contract();
    is_deeply($contract->{'top_level_contract_source_map'}, $expected->{'top_level_contract_source_map'}, 'fresh manifest contract rebuilds clean top_level_contract_source_map');
};
done_testing();

sub mutate_structure {
    my ($value) = @_;
    return unless ref($value);
    if (ref($value) eq 'ARRAY') { push @{$value}, $sentinel; mutate_structure($_) for @{$value}; return; }
    if (ref($value) eq 'HASH') { $value->{$sentinel} = $sentinel; mutate_structure($_) for values %{$value}; return; }
}
