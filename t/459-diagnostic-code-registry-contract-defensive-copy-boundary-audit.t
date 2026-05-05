#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use File::Spec;
use FindBin;

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');
use lib File::Spec->catdir($FindBin::Bin, 'lib');

use FSM::Support::DiagnosticCodeRegistryContract qw(
    build_diagnostic_code_registry_contract
    diagnostic_code_registry_bounded_value_family_map
    diagnostic_code_registry_entry_keys
    diagnostic_code_registry_family_values
    diagnostic_code_registry_key_family_map
    diagnostic_code_registry_public_keys
);
use FSM::Test::DefensiveCopyAudit qw(
    contains_sentinel
    mutate_structure
);

my $sentinel = '__mutated_by_t459__';

subtest 'diagnostic code registry contract builder returns fresh nested structures' => sub {
    my $first = build_diagnostic_code_registry_contract();
    mutate_structure($first, $sentinel);

    my $second = build_diagnostic_code_registry_contract();
    ok(!contains_sentinel($second, $sentinel), 'fresh diagnostic code registry contract is not affected by prior caller mutation');
    is_deeply(
        $second->{public_sibling_keys},
        diagnostic_code_registry_public_keys(),
        'fresh contract public sibling keys match helper',
    );
    is_deeply(
        $second->{entry_presence_keys},
        diagnostic_code_registry_entry_keys(),
        'fresh contract entry keys match helper',
    );
    is_deeply(
        $second->{key_family_map},
        diagnostic_code_registry_key_family_map(),
        'fresh contract key family map matches helper',
    );
    is_deeply(
        $second->{bounded_family_values},
        diagnostic_code_registry_family_values(),
        'fresh contract bounded family values match helper',
    );
    is_deeply(
        $second->{bounded_value_family_map},
        diagnostic_code_registry_bounded_value_family_map(),
        'fresh contract bounded value family map matches helper',
    );
};

subtest 'diagnostic code registry helper builders return fresh nested structures' => sub {
    for my $case (
        {
            label => 'public_keys',
            build => \&diagnostic_code_registry_public_keys,
        },
        {
            label => 'entry_keys',
            build => \&diagnostic_code_registry_entry_keys,
        },
        {
            label => 'key_family_map',
            build => \&diagnostic_code_registry_key_family_map,
        },
        {
            label => 'family_values',
            build => \&diagnostic_code_registry_family_values,
        },
        {
            label => 'bounded_value_family_map',
            build => \&diagnostic_code_registry_bounded_value_family_map,
        },
    ) {
        my $first = $case->{build}->();
        mutate_structure($first, $sentinel);

        my $second = $case->{build}->();
        ok(!contains_sentinel($second, $sentinel), "$case->{label} returns fresh nested structures");
    }
};

subtest 'fresh diagnostic code registry grouped maps stay aligned with helper families' => sub {
    my $key_family_map = diagnostic_code_registry_key_family_map();
    my $value_family_map = diagnostic_code_registry_bounded_value_family_map();

    is_deeply(
        $key_family_map->{public_sibling_keys},
        diagnostic_code_registry_public_keys(),
        'public sibling key family entry matches helper',
    );
    is_deeply(
        $key_family_map->{entry_presence_keys},
        diagnostic_code_registry_entry_keys(),
        'entry key family entry matches helper',
    );
    is_deeply(
        $value_family_map->{bounded_family_values},
        diagnostic_code_registry_family_values(),
        'bounded family values entry matches helper',
    );
};

done_testing();
