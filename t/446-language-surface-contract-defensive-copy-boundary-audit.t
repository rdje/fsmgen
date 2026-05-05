#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use File::Spec;
use FindBin;

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::Support::LanguageSurfaceContract qw(
    build_language_surface_contract
    language_surface_assignments_keys
    language_surface_composition_keys
    language_surface_declarations_keys
    language_surface_default_mode_compatibility_keys
    language_surface_expressions_keys
    language_surface_nested_presence_key_map
    language_surface_public_top_level_keys
    language_surface_strict_mode_keys
    language_surface_system_contracts_keys
);

my $sentinel = '__mutated_by_t446__';

subtest 'language surface contract builder returns fresh nested structures' => sub {
    my $first = build_language_surface_contract();
    mutate_structure($first);

    my $second = build_language_surface_contract();
    ok(!contains_sentinel($second), 'fresh language surface contract is not affected by prior caller mutation');
    is_deeply(
        $second->{public_top_level_presence_keys},
        language_surface_public_top_level_keys(),
        'fresh contract top-level presence keys match helper',
    );
    is_deeply(
        $second->{nested_presence_key_map},
        language_surface_nested_presence_key_map(),
        'fresh contract nested presence map matches helper',
    );
};

subtest 'language surface helper builders return fresh nested structures' => sub {
    for my $case (
        {
            label => 'public_top_level_keys',
            build => \&language_surface_public_top_level_keys,
        },
        {
            label => 'strict_mode_keys',
            build => \&language_surface_strict_mode_keys,
        },
        {
            label => 'default_mode_compatibility_keys',
            build => \&language_surface_default_mode_compatibility_keys,
        },
        {
            label => 'assignments_keys',
            build => \&language_surface_assignments_keys,
        },
        {
            label => 'system_contracts_keys',
            build => \&language_surface_system_contracts_keys,
        },
        {
            label => 'expressions_keys',
            build => \&language_surface_expressions_keys,
        },
        {
            label => 'declarations_keys',
            build => \&language_surface_declarations_keys,
        },
        {
            label => 'composition_keys',
            build => \&language_surface_composition_keys,
        },
        {
            label => 'nested_presence_key_map',
            build => \&language_surface_nested_presence_key_map,
        },
    ) {
        my $first = $case->{build}->();
        mutate_structure($first);

        my $second = $case->{build}->();
        ok(!contains_sentinel($second), "$case->{label} returns fresh nested structures");
    }
};

subtest 'fresh language surface nested map stays aligned with helper families' => sub {
    my $nested_map = language_surface_nested_presence_key_map();

    is_deeply($nested_map->{strict_mode}, language_surface_strict_mode_keys(), 'strict-mode nested map entry matches helper');
    is_deeply(
        $nested_map->{default_mode_compatibility},
        language_surface_default_mode_compatibility_keys(),
        'default-mode nested map entry matches helper',
    );
    is_deeply($nested_map->{assignments}, language_surface_assignments_keys(), 'assignments nested map entry matches helper');
    is_deeply($nested_map->{system_contracts}, language_surface_system_contracts_keys(), 'system-contracts nested map entry matches helper');
    is_deeply($nested_map->{expressions}, language_surface_expressions_keys(), 'expressions nested map entry matches helper');
    is_deeply($nested_map->{declarations}, language_surface_declarations_keys(), 'declarations nested map entry matches helper');
    is_deeply($nested_map->{composition}, language_surface_composition_keys(), 'composition nested map entry matches helper');
};

done_testing();

sub mutate_structure {
    my ($value) = @_;
    return unless ref($value);

    if (ref($value) eq 'ARRAY') {
        push @{$value}, $sentinel;
        mutate_structure($_) for @{$value};
        return;
    }

    if (ref($value) eq 'HASH') {
        $value->{$sentinel} = $sentinel;
        mutate_structure($_) for values %{$value};
        return;
    }
}

sub contains_sentinel {
    my ($value) = @_;
    return 1 if defined($value) && !ref($value) && $value eq $sentinel;
    return 0 unless ref($value);

    if (ref($value) eq 'ARRAY') {
        for my $entry (@{$value}) {
            return 1 if contains_sentinel($entry);
        }
        return 0;
    }

    if (ref($value) eq 'HASH') {
        return 1 if exists($value->{$sentinel});
        for my $entry (values %{$value}) {
            return 1 if contains_sentinel($entry);
        }
        return 0;
    }

    return 0;
}
