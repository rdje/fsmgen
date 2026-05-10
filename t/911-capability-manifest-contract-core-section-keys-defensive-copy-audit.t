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

subtest 'manifest contract core section presence keys rebuilds cleanly after caller mutation' => sub {
    my $first = build_capability_manifest();
    my $mutated = $first->{manifest_contract};
    mutate_structure($mutated->{'producer_presence_keys'});
    mutate_structure($mutated->{'support_accounting_presence_keys'});
    mutate_structure($mutated->{'diagnostics_presence_keys'});
    mutate_structure($mutated->{'semantic_exports_presence_keys'});

    my $second = build_capability_manifest();
    my $contract = $second->{manifest_contract};
    my $expected = build_capability_manifest_contract();
    is_deeply($contract->{'producer_presence_keys'}, $expected->{'producer_presence_keys'}, 'fresh manifest contract rebuilds clean producer_presence_keys');
    is_deeply($contract->{'support_accounting_presence_keys'}, $expected->{'support_accounting_presence_keys'}, 'fresh manifest contract rebuilds clean support_accounting_presence_keys');
    is_deeply($contract->{'diagnostics_presence_keys'}, $expected->{'diagnostics_presence_keys'}, 'fresh manifest contract rebuilds clean diagnostics_presence_keys');
    is_deeply($contract->{'semantic_exports_presence_keys'}, $expected->{'semantic_exports_presence_keys'}, 'fresh manifest contract rebuilds clean semantic_exports_presence_keys');
};
done_testing();

sub mutate_structure {
    my ($value) = @_;
    return unless ref($value);
    if (ref($value) eq 'ARRAY') { push @{$value}, $sentinel; mutate_structure($_) for @{$value}; return; }
    if (ref($value) eq 'HASH') { $value->{$sentinel} = $sentinel; mutate_structure($_) for values %{$value}; return; }
}
