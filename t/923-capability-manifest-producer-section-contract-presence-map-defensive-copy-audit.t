#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use File::Spec;
use FindBin;
use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');
use FSM::Support::CapabilityManifest qw(build_capability_manifest);
use FSM::Support::ProducerContract qw(build_producer_contract);
my $sentinel = '__manifest_section_contract_mutation__';

subtest 'manifest producer section contract presence key family map rebuilds cleanly after caller mutation' => sub {
    my $first = build_capability_manifest();
    my $mutated = $first->{'producer'}{section_contract};
    mutate_structure($mutated->{'presence_key_family_map'});
    mutate_structure($mutated->{'identity_contract'});

    my $second = build_capability_manifest();
    my $contract = $second->{'producer'}{section_contract};
    my $expected = build_producer_contract();
    is_deeply($contract->{'presence_key_family_map'}, $expected->{'presence_key_family_map'}, 'fresh manifest producer contract rebuilds clean presence_key_family_map');
    is_deeply($contract->{'identity_contract'}, $expected->{'identity_contract'}, 'fresh manifest producer contract rebuilds clean identity_contract');
};
done_testing();

sub mutate_structure {
    my ($value) = @_;
    return unless ref($value);
    if (ref($value) eq 'ARRAY') { push @{$value}, $sentinel; mutate_structure($_) for @{$value}; return; }
    if (ref($value) eq 'HASH') { $value->{$sentinel} = $sentinel; mutate_structure($_) for values %{$value}; return; }
}
