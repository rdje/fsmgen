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

subtest 'manifest producer section contract public key families rebuilds cleanly after caller mutation' => sub {
    my $first = build_capability_manifest();
    my $mutated = $first->{'producer'}{section_contract};
    mutate_structure($mutated->{'public_top_level_presence_keys'});
    mutate_structure($mutated->{'scalar_string_keys'});
    mutate_structure($mutated->{'boolean_keys'});

    my $second = build_capability_manifest();
    my $contract = $second->{'producer'}{section_contract};
    my $expected = build_producer_contract();
    is_deeply($contract->{'public_top_level_presence_keys'}, $expected->{'public_top_level_presence_keys'}, 'fresh manifest producer contract rebuilds clean public_top_level_presence_keys');
    is_deeply($contract->{'scalar_string_keys'}, $expected->{'scalar_string_keys'}, 'fresh manifest producer contract rebuilds clean scalar_string_keys');
    is_deeply($contract->{'boolean_keys'}, $expected->{'boolean_keys'}, 'fresh manifest producer contract rebuilds clean boolean_keys');
};
done_testing();

sub mutate_structure {
    my ($value) = @_;
    return unless ref($value);
    if (ref($value) eq 'ARRAY') { push @{$value}, $sentinel; mutate_structure($_) for @{$value}; return; }
    if (ref($value) eq 'HASH') { $value->{$sentinel} = $sentinel; mutate_structure($_) for values %{$value}; return; }
}
