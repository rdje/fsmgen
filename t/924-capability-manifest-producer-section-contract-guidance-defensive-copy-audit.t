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

subtest 'manifest producer section contract guidance list rebuilds cleanly after caller mutation' => sub {
    my $first = build_capability_manifest();
    my $mutated = $first->{'producer'}{section_contract};
    mutate_structure($mutated->{'guidance'});

    my $second = build_capability_manifest();
    my $contract = $second->{'producer'}{section_contract};
    my $expected = build_producer_contract();
    is_deeply($contract->{'guidance'}, $expected->{'guidance'}, 'fresh manifest producer contract rebuilds clean guidance');
};
done_testing();

sub mutate_structure {
    my ($value) = @_;
    return unless ref($value);
    if (ref($value) eq 'ARRAY') { push @{$value}, $sentinel; mutate_structure($_) for @{$value}; return; }
    if (ref($value) eq 'HASH') { $value->{$sentinel} = $sentinel; mutate_structure($_) for values %{$value}; return; }
}
