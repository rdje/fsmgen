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

subtest 'manifest-embedded embedding section contract identity metadata rebuilds cleanly after caller mutation' => sub {
    my $first = build_capability_manifest();
    my $mutated = $first->{embedding}{section_contract};
    $mutated->{'status'} = $sentinel;
    $mutated->{'contract_source'} = $sentinel;
    $mutated->{'report_source'} = $sentinel;
    mutate_structure($mutated->{'entrypoints'});

    my $second = build_capability_manifest();
    my $contract = $second->{embedding}{section_contract};
    my $expected = build_embedding_contract();
    is($contract->{'status'}, $expected->{'status'}, 'fresh manifest embedding contract rebuilds clean status');
    is($contract->{'contract_source'}, $expected->{'contract_source'}, 'fresh manifest embedding contract rebuilds clean contract_source');
    is($contract->{'report_source'}, $expected->{'report_source'}, 'fresh manifest embedding contract rebuilds clean report_source');
    is_deeply($contract->{'entrypoints'}, $expected->{'entrypoints'}, 'fresh manifest embedding contract rebuilds clean entrypoints');
    is($contract->{schema_version}, $expected->{schema_version}, 'fresh manifest embedding contract rebuilds clean schema version');
};
done_testing();

sub mutate_structure {
    my ($value) = @_;
    return unless ref($value);
    if (ref($value) eq 'ARRAY') { push @{$value}, $sentinel; mutate_structure($_) for @{$value}; return; }
    if (ref($value) eq 'HASH') { $value->{$sentinel} = $sentinel; mutate_structure($_) for values %{$value}; return; }
}
