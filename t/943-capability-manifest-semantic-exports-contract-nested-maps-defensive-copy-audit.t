#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use File::Spec;
use FindBin;
use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');
use FSM::Support::CapabilityManifest qw(build_capability_manifest);
use FSM::Support::SemanticExportsContract qw(build_semantic_exports_contract);
my $sentinel = '__manifest_section_contract_mutation__';

subtest 'manifest semantic-exports contract nested source and presence maps rebuilds cleanly after caller mutation' => sub {
    my $first = build_capability_manifest();
    my $mutated = $first->{'semantic_exports'}{'section_contract'};
    mutate_structure($mutated->{'nested_contract_source_map'});
    mutate_structure($mutated->{'nested_presence_key_map'});

    my $second = build_capability_manifest();
    my $contract = $second->{'semantic_exports'}{'section_contract'};
    my $expected = build_semantic_exports_contract();
    is_deeply($contract->{'nested_contract_source_map'}, $expected->{'nested_contract_source_map'}, 'fresh manifest semantic-exports contract rebuilds clean nested_contract_source_map');
    is_deeply($contract->{'nested_presence_key_map'}, $expected->{'nested_presence_key_map'}, 'fresh manifest semantic-exports contract rebuilds clean nested_presence_key_map');
};
done_testing();

sub mutate_structure {
    my ($value) = @_;
    return unless ref($value);
    if (ref($value) eq 'ARRAY') { push @{$value}, $sentinel; mutate_structure($_) for @{$value}; return; }
    if (ref($value) eq 'HASH') { $value->{$sentinel} = $sentinel; mutate_structure($_) for values %{$value}; return; }
}
