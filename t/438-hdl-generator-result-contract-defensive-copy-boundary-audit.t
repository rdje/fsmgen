#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use File::Spec;
use FindBin;

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::Support::HDLGeneratorResultContract qw(
    build_hdl_generator_result_contract
    hdl_generator_result_known_top_level_keys
    hdl_generator_result_optional_composition_key_family_map
    hdl_generator_result_semantic_layer_presence_key_family_map
    hdl_generator_result_shell_only_fallback_surface_family_map
    hdl_generator_result_shell_only_fallback_surface_map
    hdl_generator_result_stable_subsurface_map
);

my $sentinel = '__mutated_by_t438__';
my $audit_test = 't/438-hdl-generator-result-contract-defensive-copy-boundary-audit.t';

subtest 'HDLGenerator result contract builder returns fresh nested structures' => sub {
    my $first = build_hdl_generator_result_contract();
    mutate_structure($first);

    my $second = build_hdl_generator_result_contract();
    ok(!contains_sentinel($second), 'fresh HDLGenerator result contract is not affected by prior caller mutation');
    ok(contains_scalar($second->{tested_by}, $audit_test), 'contract provenance lists this defensive-copy audit');
    is_deeply(
        unique_sorted(hdl_generator_result_known_top_level_keys()),
        unique_sorted([
            @{$second->{public_top_level_presence_keys}},
            @{$second->{direct_root_top_level_keys}},
            @{$second->{composition_root_top_level_keys}},
        ]),
        'fresh contract still feeds the known top-level key helper after prior mutation',
    );
};

subtest 'HDLGenerator result grouped helper maps return fresh nested structures' => sub {
    for my $case (
        {
            label => 'stable_subsurface_map',
            build => \&hdl_generator_result_stable_subsurface_map,
        },
        {
            label => 'optional_composition_key_family_map',
            build => \&hdl_generator_result_optional_composition_key_family_map,
        },
        {
            label => 'semantic_layer_presence_key_family_map',
            build => \&hdl_generator_result_semantic_layer_presence_key_family_map,
        },
        {
            label => 'shell_only_fallback_surface_map',
            build => \&hdl_generator_result_shell_only_fallback_surface_map,
        },
        {
            label => 'shell_only_fallback_surface_family_map',
            build => \&hdl_generator_result_shell_only_fallback_surface_family_map,
        },
    ) {
        my $first = $case->{build}->();
        mutate_structure($first);

        my $second = $case->{build}->();
        ok(!contains_sentinel($second), "$case->{label} returns fresh nested structures");
    }
};

subtest 'fresh contract grouped maps match their helper builders' => sub {
    my $contract = build_hdl_generator_result_contract();

    is_deeply(
        $contract->{stable_subsurface_map},
        hdl_generator_result_stable_subsurface_map(),
        'fresh contract stable_subsurface_map matches its helper',
    );
    is_deeply(
        $contract->{optional_composition_key_family_map},
        hdl_generator_result_optional_composition_key_family_map(),
        'fresh contract optional_composition_key_family_map matches its helper',
    );
    is_deeply(
        $contract->{semantic_layer_presence_key_family_map},
        hdl_generator_result_semantic_layer_presence_key_family_map(),
        'fresh contract semantic_layer_presence_key_family_map matches its helper',
    );
    is_deeply(
        $contract->{shell_only_fallback_surface_map},
        hdl_generator_result_shell_only_fallback_surface_map(),
        'fresh contract shell_only_fallback_surface_map matches its helper',
    );
    is_deeply(
        $contract->{shell_only_fallback_surface_family_map},
        hdl_generator_result_shell_only_fallback_surface_family_map(),
        'fresh contract shell_only_fallback_surface_family_map matches its helper',
    );
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

sub contains_scalar {
    my ($values, $wanted) = @_;
    return 0 unless ref($values) eq 'ARRAY';

    for my $value (@{$values}) {
        return 1 if defined($value) && !ref($value) && $value eq $wanted;
    }

    return 0;
}

sub sorted {
    my ($values) = @_;
    return [sort @{$values || []}];
}

sub unique_sorted {
    my ($values) = @_;
    my %seen;
    return [sort grep { !$seen{$_}++ } @{$values || []}];
}
