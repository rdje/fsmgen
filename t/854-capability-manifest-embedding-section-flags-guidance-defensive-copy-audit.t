#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use File::Spec;
use FindBin;
use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');
use FSM::Support::CapabilityManifest qw(build_capability_manifest);
use FSM::Support::EmbeddingContract qw(build_embedding_contract);
my $sentinel = '__manifest_embedding_contract_mutation__';

subtest 'manifest-embedded embedding section contract flags and guidance rebuilds cleanly after caller mutation' => sub {
    my $first = build_capability_manifest();
    my $mutated = $first->{embedding}{section_contract};
    $mutated->{'nested_contracts_advertised'} = $mutated->{'nested_contracts_advertised'} ? 0 : 1;
    $mutated->{'full_embedding_section_stable'} = $mutated->{'full_embedding_section_stable'} ? 0 : 1;
    mutate_structure($mutated->{'guidance'});

    my $second = build_capability_manifest();
    my $contract = $second->{embedding}{section_contract};
    my $expected = build_embedding_contract();
    is($contract->{'nested_contracts_advertised'} ? 1 : 0, $expected->{'nested_contracts_advertised'} ? 1 : 0, 'fresh manifest embedding contract rebuilds clean nested_contracts_advertised');
    is($contract->{'full_embedding_section_stable'} ? 1 : 0, $expected->{'full_embedding_section_stable'} ? 1 : 0, 'fresh manifest embedding contract rebuilds clean full_embedding_section_stable');
    is_deeply($contract->{'guidance'}, $expected->{'guidance'}, 'fresh manifest embedding contract rebuilds clean guidance');
};
done_testing();

sub mutate_structure {
    my ($value) = @_;
    return unless ref($value);
    if (ref($value) eq 'ARRAY') { push @{$value}, $sentinel; mutate_structure($_) for @{$value}; return; }
    if (ref($value) eq 'HASH') { $value->{$sentinel} = $sentinel; mutate_structure($_) for values %{$value}; return; }
}
