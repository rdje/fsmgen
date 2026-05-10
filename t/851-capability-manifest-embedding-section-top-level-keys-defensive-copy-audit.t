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

subtest 'manifest-embedded embedding section contract top-level and nested contract keys rebuilds cleanly after caller mutation' => sub {
    my $first = build_capability_manifest();
    my $mutated = $first->{embedding}{section_contract};
    mutate_structure($mutated->{'public_top_level_presence_keys'});
    mutate_structure($mutated->{'nested_contract_keys'});

    my $second = build_capability_manifest();
    my $contract = $second->{embedding}{section_contract};
    my $expected = build_embedding_contract();
    is_deeply($contract->{'public_top_level_presence_keys'}, $expected->{'public_top_level_presence_keys'}, 'fresh manifest embedding contract rebuilds clean public_top_level_presence_keys');
    is_deeply($contract->{'nested_contract_keys'}, $expected->{'nested_contract_keys'}, 'fresh manifest embedding contract rebuilds clean nested_contract_keys');
};
done_testing();

sub mutate_structure {
    my ($value) = @_;
    return unless ref($value);
    if (ref($value) eq 'ARRAY') { push @{$value}, $sentinel; mutate_structure($_) for @{$value}; return; }
    if (ref($value) eq 'HASH') { $value->{$sentinel} = $sentinel; mutate_structure($_) for values %{$value}; return; }
}
