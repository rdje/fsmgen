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

subtest 'manifest semantic-exports contract advertisement flags and guidance rebuilds cleanly after caller mutation' => sub {
    my $first = build_capability_manifest();
    my $mutated = $first->{'semantic_exports'}{'section_contract'};
    $mutated->{'normalized_semantic_json_contract_advertised'} = $mutated->{'normalized_semantic_json_contract_advertised'} ? 0 : 1;
    $mutated->{'full_semantic_exports_section_stable'} = $mutated->{'full_semantic_exports_section_stable'} ? 0 : 1;
    mutate_structure($mutated->{'guidance'});

    my $second = build_capability_manifest();
    my $contract = $second->{'semantic_exports'}{'section_contract'};
    my $expected = build_semantic_exports_contract();
    is($contract->{'normalized_semantic_json_contract_advertised'} ? 1 : 0, $expected->{'normalized_semantic_json_contract_advertised'} ? 1 : 0, 'fresh manifest semantic-exports contract rebuilds clean normalized_semantic_json_contract_advertised');
    is($contract->{'full_semantic_exports_section_stable'} ? 1 : 0, $expected->{'full_semantic_exports_section_stable'} ? 1 : 0, 'fresh manifest semantic-exports contract rebuilds clean full_semantic_exports_section_stable');
    is_deeply($contract->{'guidance'}, $expected->{'guidance'}, 'fresh manifest semantic-exports contract rebuilds clean guidance');
};
done_testing();

sub mutate_structure {
    my ($value) = @_;
    return unless ref($value);
    if (ref($value) eq 'ARRAY') { push @{$value}, $sentinel; mutate_structure($_) for @{$value}; return; }
    if (ref($value) eq 'HASH') { $value->{$sentinel} = $sentinel; mutate_structure($_) for values %{$value}; return; }
}
