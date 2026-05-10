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

subtest 'manifest-embedded embedding section contract nested contract source map rebuilds cleanly after caller mutation' => sub {
    my $first = build_capability_manifest();
    my $mutated = $first->{embedding}{section_contract};
    mutate_structure($mutated->{'nested_contract_source_map'});

    my $second = build_capability_manifest();
    my $contract = $second->{embedding}{section_contract};
    my $expected = build_embedding_contract();
    is_deeply($contract->{'nested_contract_source_map'}, $expected->{'nested_contract_source_map'}, 'fresh manifest embedding contract rebuilds clean nested_contract_source_map');
};
done_testing();

sub mutate_structure {
    my ($value) = @_;
    return unless ref($value);
    if (ref($value) eq 'ARRAY') { push @{$value}, $sentinel; mutate_structure($_) for @{$value}; return; }
    if (ref($value) eq 'HASH') { $value->{$sentinel} = $sentinel; mutate_structure($_) for values %{$value}; return; }
}
