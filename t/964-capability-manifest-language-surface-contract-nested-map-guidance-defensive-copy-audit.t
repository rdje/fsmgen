#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use File::Spec;
use FindBin;
use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');
use FSM::Support::CapabilityManifest qw(build_capability_manifest);
use FSM::Support::LanguageSurfaceContract qw(build_language_surface_contract);
my $sentinel = '__manifest_section_contract_mutation__';

subtest 'manifest language-surface contract nested map flags and guidance rebuilds cleanly after caller mutation' => sub {
    my $first = build_capability_manifest();
    my $mutated = $first->{'language_surface'}{'surface_contract'};
    $mutated->{'full_language_surface_stable'} = $mutated->{'full_language_surface_stable'} ? 0 : 1;
    mutate_structure($mutated->{'nested_presence_key_map'});
    mutate_structure($mutated->{'guidance'});

    my $second = build_capability_manifest();
    my $contract = $second->{'language_surface'}{'surface_contract'};
    my $expected = build_language_surface_contract();
    is($contract->{'full_language_surface_stable'} ? 1 : 0, $expected->{'full_language_surface_stable'} ? 1 : 0, 'fresh manifest language-surface contract rebuilds clean full_language_surface_stable');
    is_deeply($contract->{'nested_presence_key_map'}, $expected->{'nested_presence_key_map'}, 'fresh manifest language-surface contract rebuilds clean nested_presence_key_map');
    is_deeply($contract->{'guidance'}, $expected->{'guidance'}, 'fresh manifest language-surface contract rebuilds clean guidance');
};
done_testing();

sub mutate_structure {
    my ($value) = @_;
    return unless ref($value);
    if (ref($value) eq 'ARRAY') { push @{$value}, $sentinel; mutate_structure($_) for @{$value}; return; }
    if (ref($value) eq 'HASH') { $value->{$sentinel} = $sentinel; mutate_structure($_) for values %{$value}; return; }
}
