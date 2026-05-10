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

subtest 'manifest contract manifest safety flags rebuilds cleanly after caller mutation' => sub {
    my $first = build_capability_manifest();
    my $mutated = $first->{manifest_contract};
    $mutated->{'full_manifest_json_safe'} = $mutated->{'full_manifest_json_safe'} ? 0 : 1;
    $mutated->{'nested_section_contracts_advertised'} = $mutated->{'nested_section_contracts_advertised'} ? 0 : 1;

    my $second = build_capability_manifest();
    my $contract = $second->{manifest_contract};
    my $expected = build_capability_manifest_contract();
    is($contract->{'full_manifest_json_safe'} ? 1 : 0, $expected->{'full_manifest_json_safe'} ? 1 : 0, 'fresh manifest contract rebuilds clean full_manifest_json_safe');
    is($contract->{'nested_section_contracts_advertised'} ? 1 : 0, $expected->{'nested_section_contracts_advertised'} ? 1 : 0, 'fresh manifest contract rebuilds clean nested_section_contracts_advertised');
};
done_testing();

sub mutate_structure {
    my ($value) = @_;
    return unless ref($value);
    if (ref($value) eq 'ARRAY') { push @{$value}, $sentinel; mutate_structure($_) for @{$value}; return; }
    if (ref($value) eq 'HASH') { $value->{$sentinel} = $sentinel; mutate_structure($_) for values %{$value}; return; }
}
