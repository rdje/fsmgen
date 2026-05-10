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

subtest 'manifest semantic-exports contract entrypoint metadata rebuilds cleanly after caller mutation' => sub {
    my $first = build_capability_manifest();
    my $mutated = $first->{'semantic_exports'}{'section_contract'};
    mutate_structure($mutated->{'entrypoints'});

    my $second = build_capability_manifest();
    my $contract = $second->{'semantic_exports'}{'section_contract'};
    my $expected = build_semantic_exports_contract();
    is_deeply($contract->{'entrypoints'}, $expected->{'entrypoints'}, 'fresh manifest semantic-exports contract rebuilds clean entrypoints');
};
done_testing();

sub mutate_structure {
    my ($value) = @_;
    return unless ref($value);
    if (ref($value) eq 'ARRAY') { push @{$value}, $sentinel; mutate_structure($_) for @{$value}; return; }
    if (ref($value) eq 'HASH') { $value->{$sentinel} = $sentinel; mutate_structure($_) for values %{$value}; return; }
}
