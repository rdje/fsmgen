#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use File::Spec;
use FindBin;

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::Support::SemanticExportsContract qw(
    build_semantic_exports_contract
    semantic_exports_nested_contract_keys
    semantic_exports_nested_presence_key_map
    semantic_exports_public_top_level_keys
);

my $sentinel = '__mutated_by_t447__';

subtest 'semantic exports contract builder returns fresh nested structures' => sub {
    my $first = build_semantic_exports_contract();
    mutate_structure($first);

    my $second = build_semantic_exports_contract();
    ok(!contains_sentinel($second), 'fresh semantic exports contract is not affected by prior caller mutation');
    is_deeply(
        $second->{public_top_level_presence_keys},
        semantic_exports_public_top_level_keys(),
        'fresh contract top-level presence keys match helper',
    );
    is_deeply(
        $second->{nested_contract_keys},
        semantic_exports_nested_contract_keys(),
        'fresh contract nested contract keys match helper',
    );
    is_deeply(
        $second->{nested_presence_key_map},
        semantic_exports_nested_presence_key_map(),
        'fresh contract nested presence map matches helper',
    );
};

subtest 'semantic exports helper builders return fresh nested structures' => sub {
    for my $case (
        {
            label => 'public_top_level_keys',
            build => \&semantic_exports_public_top_level_keys,
        },
        {
            label => 'nested_contract_keys',
            build => \&semantic_exports_nested_contract_keys,
        },
        {
            label => 'nested_presence_key_map',
            build => \&semantic_exports_nested_presence_key_map,
        },
    ) {
        my $first = $case->{build}->();
        mutate_structure($first);

        my $second = $case->{build}->();
        ok(!contains_sentinel($second), "$case->{label} returns fresh nested structures");
    }
};

subtest 'fresh semantic exports maps stay aligned with helper families' => sub {
    my $contract = build_semantic_exports_contract();

    is_deeply(
        [sort keys %{$contract->{nested_presence_key_map}}],
        sorted(semantic_exports_nested_contract_keys()),
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
