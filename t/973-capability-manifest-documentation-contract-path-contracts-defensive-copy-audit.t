#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use File::Spec;
use FindBin;
use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');
use FSM::Support::CapabilityManifest qw(build_capability_manifest);
use FSM::Support::DocumentationContract qw(build_documentation_contract);
my $sentinel = '__manifest_section_contract_mutation__';

subtest 'manifest documentation contract path contract maps rebuilds cleanly after caller mutation' => sub {
    my $first = build_capability_manifest();
    my $mutated = $first->{'documentation'}{'section_contract'};
    mutate_structure($mutated->{'path_contract'});
    mutate_structure($mutated->{'path_list_contract_map'});

    my $second = build_capability_manifest();
    my $contract = $second->{'documentation'}{'section_contract'};
    my $expected = build_documentation_contract();
    is_deeply($contract->{'path_contract'}, $expected->{'path_contract'}, 'fresh manifest documentation contract rebuilds clean path_contract');
    is_deeply($contract->{'path_list_contract_map'}, $expected->{'path_list_contract_map'}, 'fresh manifest documentation contract rebuilds clean path_list_contract_map');
};
done_testing();

sub mutate_structure {
    my ($value) = @_;
    return unless ref($value);
    if (ref($value) eq 'ARRAY') { push @{$value}, $sentinel; mutate_structure($_) for @{$value}; return; }
    if (ref($value) eq 'HASH') { $value->{$sentinel} = $sentinel; mutate_structure($_) for values %{$value}; return; }
}
