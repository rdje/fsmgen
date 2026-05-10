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

subtest 'manifest contract tooling section presence keys rebuilds cleanly after caller mutation' => sub {
    my $first = build_capability_manifest();
    my $mutated = $first->{manifest_contract};
    mutate_structure($mutated->{'backend_validation_presence_keys'});
    mutate_structure($mutated->{'embedding_presence_keys'});
    mutate_structure($mutated->{'language_surface_presence_keys'});
    mutate_structure($mutated->{'documentation_presence_keys'});

    my $second = build_capability_manifest();
    my $contract = $second->{manifest_contract};
    my $expected = build_capability_manifest_contract();
    is_deeply($contract->{'backend_validation_presence_keys'}, $expected->{'backend_validation_presence_keys'}, 'fresh manifest contract rebuilds clean backend_validation_presence_keys');
    is_deeply($contract->{'embedding_presence_keys'}, $expected->{'embedding_presence_keys'}, 'fresh manifest contract rebuilds clean embedding_presence_keys');
    is_deeply($contract->{'language_surface_presence_keys'}, $expected->{'language_surface_presence_keys'}, 'fresh manifest contract rebuilds clean language_surface_presence_keys');
    is_deeply($contract->{'documentation_presence_keys'}, $expected->{'documentation_presence_keys'}, 'fresh manifest contract rebuilds clean documentation_presence_keys');
};
done_testing();

sub mutate_structure {
    my ($value) = @_;
    return unless ref($value);
    if (ref($value) eq 'ARRAY') { push @{$value}, $sentinel; mutate_structure($_) for @{$value}; return; }
    if (ref($value) eq 'HASH') { $value->{$sentinel} = $sentinel; mutate_structure($_) for values %{$value}; return; }
}
