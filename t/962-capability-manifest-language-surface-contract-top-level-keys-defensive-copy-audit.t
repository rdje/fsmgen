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

subtest 'manifest language-surface contract top-level and mode key lists rebuilds cleanly after caller mutation' => sub {
    my $first = build_capability_manifest();
    my $mutated = $first->{'language_surface'}{'surface_contract'};
    mutate_structure($mutated->{'public_top_level_presence_keys'});
    mutate_structure($mutated->{'strict_mode_presence_keys'});
    mutate_structure($mutated->{'file_surfaces_presence_keys'});
    mutate_structure($mutated->{'file_surface_entry_presence_keys'});
    mutate_structure($mutated->{'default_mode_compatibility_presence_keys'});

    my $second = build_capability_manifest();
    my $contract = $second->{'language_surface'}{'surface_contract'};
    my $expected = build_language_surface_contract();
    is_deeply($contract->{'public_top_level_presence_keys'}, $expected->{'public_top_level_presence_keys'}, 'fresh manifest language-surface contract rebuilds clean public_top_level_presence_keys');
    is_deeply($contract->{'strict_mode_presence_keys'}, $expected->{'strict_mode_presence_keys'}, 'fresh manifest language-surface contract rebuilds clean strict_mode_presence_keys');
    is_deeply($contract->{'file_surfaces_presence_keys'}, $expected->{'file_surfaces_presence_keys'}, 'fresh manifest language-surface contract rebuilds clean file_surfaces_presence_keys');
    is_deeply($contract->{'file_surface_entry_presence_keys'}, $expected->{'file_surface_entry_presence_keys'}, 'fresh manifest language-surface contract rebuilds clean file_surface_entry_presence_keys');
    is_deeply($contract->{'default_mode_compatibility_presence_keys'}, $expected->{'default_mode_compatibility_presence_keys'}, 'fresh manifest language-surface contract rebuilds clean default_mode_compatibility_presence_keys');
};
done_testing();

sub mutate_structure {
    my ($value) = @_;
    return unless ref($value);
    if (ref($value) eq 'ARRAY') { push @{$value}, $sentinel; mutate_structure($_) for @{$value}; return; }
    if (ref($value) eq 'HASH') { $value->{$sentinel} = $sentinel; mutate_structure($_) for values %{$value}; return; }
}
