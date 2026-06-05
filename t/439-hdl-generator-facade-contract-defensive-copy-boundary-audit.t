#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use File::Spec;
use FindBin;

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::Support::HDLGeneratorFacadeContract qw(
    build_hdl_generator_facade_contract
    hdl_generator_facade_compatibility_constructor_option_names
    hdl_generator_facade_constructor_option_family_map
    hdl_generator_facade_constructor_option_shape_map
    hdl_generator_facade_core_constructor_option_names
    hdl_generator_facade_debug_level_numeric_range
    hdl_generator_facade_default_generation_mode
    hdl_generator_facade_direct_extension_option_names
    hdl_generator_facade_generation_mode_names
    hdl_generator_facade_method_names
    hdl_generator_facade_public_constructor_option_names
    hdl_generator_facade_public_top_level_keys
    hdl_generator_facade_structured_nonflattened_generation_status
    hdl_generator_facade_target_language_names
);

my $sentinel = '__mutated_by_t439__';

subtest 'HDLGenerator facade contract builder returns fresh nested structures' => sub {
    my $first = build_hdl_generator_facade_contract();
    mutate_structure($first);

    my $second = build_hdl_generator_facade_contract();
    ok(!contains_sentinel($second), 'fresh HDLGenerator facade contract is not affected by prior caller mutation');
    is_deeply(
        sorted($second->{public_top_level_presence_keys}),
        sorted([keys %{$second}]),
        'fresh contract top-level presence list still covers every emitted facade contract key',
    );
    is_deeply(
        $second->{constructor_option_family_map},
        hdl_generator_facade_constructor_option_family_map(),
        'fresh contract grouped constructor-option family map matches its helper',
    );
    is_deeply(
        $second->{constructor_option_shape_map},
        hdl_generator_facade_constructor_option_shape_map(),
        'fresh contract constructor-option shape map matches its helper',
    );
    is_deeply(
        $second->{debug_level_numeric_range},
        hdl_generator_facade_debug_level_numeric_range(),
        'fresh contract debug-level range matches its helper',
    );
    is(
        $second->{default_generation_mode},
        hdl_generator_facade_default_generation_mode(),
        'fresh contract default generation mode matches its helper',
    );
    is_deeply(
        $second->{generation_mode_names},
        hdl_generator_facade_generation_mode_names(),
        'fresh contract generation-mode family matches its helper',
    );
    is(
        $second->{structured_nonflattened_generation_status},
        hdl_generator_facade_structured_nonflattened_generation_status(),
        'fresh contract structured non-flattened status matches its helper',
    );
};

subtest 'HDLGenerator facade helper builders return fresh nested structures' => sub {
    for my $case (
        {
            label => 'public_top_level_keys',
            build => \&hdl_generator_facade_public_top_level_keys,
        },
        {
            label => 'method_names',
            build => \&hdl_generator_facade_method_names,
        },
        {
            label => 'public_constructor_option_names',
            build => \&hdl_generator_facade_public_constructor_option_names,
        },
        {
            label => 'core_constructor_option_names',
            build => \&hdl_generator_facade_core_constructor_option_names,
        },
        {
            label => 'compatibility_constructor_option_names',
            build => \&hdl_generator_facade_compatibility_constructor_option_names,
        },
        {
            label => 'direct_extension_option_names',
            build => \&hdl_generator_facade_direct_extension_option_names,
        },
        {
            label => 'target_language_names',
            build => \&hdl_generator_facade_target_language_names,
        },
        {
            label => 'generation_mode_names',
            build => \&hdl_generator_facade_generation_mode_names,
        },
        {
            label => 'constructor_option_family_map',
            build => \&hdl_generator_facade_constructor_option_family_map,
        },
        {
            label => 'constructor_option_shape_map',
            build => \&hdl_generator_facade_constructor_option_shape_map,
        },
        {
            label => 'debug_level_numeric_range',
            build => \&hdl_generator_facade_debug_level_numeric_range,
        },
    ) {
        my $first = $case->{build}->();
        mutate_structure($first);

        my $second = $case->{build}->();
        ok(!contains_sentinel($second), "$case->{label} returns fresh nested structures");
    }
};

subtest 'fresh grouped facade maps stay aligned with helper families' => sub {
    my $family_map = hdl_generator_facade_constructor_option_family_map();

    is_deeply(
        $family_map->{core_constructor_option_names},
        hdl_generator_facade_core_constructor_option_names(),
        'core constructor option family map entry matches helper',
    );
    is_deeply(
        $family_map->{compatibility_constructor_option_names},
        hdl_generator_facade_compatibility_constructor_option_names(),
        'compatibility constructor option family map entry matches helper',
    );
    is_deeply(
        $family_map->{direct_extension_option_names},
        hdl_generator_facade_direct_extension_option_names(),
        'direct extension option family map entry matches helper',
    );
    is_deeply(
        unique_sorted([
            @{$family_map->{core_constructor_option_names}},
            @{$family_map->{compatibility_constructor_option_names}},
            @{$family_map->{direct_extension_option_names}},
        ]),
        unique_sorted(hdl_generator_facade_public_constructor_option_names()),
        'grouped facade option families cover the public constructor option helper',
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

sub sorted {
    my ($values) = @_;
    return [sort @{$values || []}];
}

sub unique_sorted {
    my ($values) = @_;
    my %seen;
    return [sort grep { !$seen{$_}++ } @{$values || []}];
}
