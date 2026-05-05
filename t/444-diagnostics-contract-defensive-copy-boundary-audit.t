#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use File::Spec;
use FindBin;

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::Support::DiagnosticsContract qw(
    build_diagnostics_contract
    diagnostics_list_keys
    diagnostics_nested_contract_keys
    diagnostics_nested_presence_key_map
    diagnostics_presence_key_family_map
    diagnostics_public_top_level_keys
    diagnostics_scalar_string_keys
);

my $sentinel = '__mutated_by_t444__';

subtest 'diagnostics contract builder returns fresh nested structures' => sub {
    my $first = build_diagnostics_contract();
    mutate_structure($first);

    my $second = build_diagnostics_contract();
    ok(!contains_sentinel($second), 'fresh diagnostics contract is not affected by prior caller mutation');
    is_deeply(
        $second->{nested_presence_key_map},
        diagnostics_nested_presence_key_map(),
        'fresh contract nested presence map matches its helper',
    );
    is_deeply(
        $second->{presence_key_family_map},
        diagnostics_presence_key_family_map(),
        'fresh contract presence family map matches its helper',
    );
};

subtest 'diagnostics helper builders return fresh nested structures' => sub {
    for my $case (
        {
            label => 'public_top_level_keys',
            build => \&diagnostics_public_top_level_keys,
        },
        {
            label => 'scalar_string_keys',
            build => \&diagnostics_scalar_string_keys,
        },
        {
            label => 'list_keys',
            build => \&diagnostics_list_keys,
        },
        {
            label => 'nested_contract_keys',
            build => \&diagnostics_nested_contract_keys,
        },
        {
            label => 'nested_presence_key_map',
            build => \&diagnostics_nested_presence_key_map,
        },
        {
            label => 'presence_key_family_map',
            build => \&diagnostics_presence_key_family_map,
        },
    ) {
        my $first = $case->{build}->();
        mutate_structure($first);

        my $second = $case->{build}->();
        ok(!contains_sentinel($second), "$case->{label} returns fresh nested structures");
    }
};

subtest 'fresh diagnostics grouped maps stay aligned with helper families' => sub {
    my $presence_map = diagnostics_presence_key_family_map();

    is_deeply(
        $presence_map->{scalar_string_keys},
        diagnostics_scalar_string_keys(),
        'scalar-string family entry matches helper',
    );
    is_deeply(
        $presence_map->{list_keys},
        diagnostics_list_keys(),
        'list family entry matches helper',
    );

    my $contract = build_diagnostics_contract();
    is_deeply(
        $contract->{nested_contract_keys},
        diagnostics_nested_contract_keys(),
        'contract nested contract keys match helper',
    );
    is_deeply(
        [sort keys %{$contract->{nested_presence_key_map}}],
        sorted(diagnostics_nested_contract_keys()),
        'nested presence map keys match nested contract keys',
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
