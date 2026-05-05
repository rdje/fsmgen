#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use File::Spec;
use FindBin;

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::Support::DocumentationContract qw(
    build_documentation_contract
    documentation_path_contract
    documentation_path_list_contract_map
    documentation_path_list_keys
    documentation_public_top_level_keys
);

my $sentinel = '__mutated_by_t448__';

subtest 'documentation contract builder returns fresh nested structures' => sub {
    my $first = build_documentation_contract();
    mutate_structure($first);

    my $second = build_documentation_contract();
    ok(!contains_sentinel($second), 'fresh documentation contract is not affected by prior caller mutation');
    is_deeply(
        $second->{public_top_level_presence_keys},
        documentation_public_top_level_keys(),
        'fresh contract top-level presence keys match helper',
    );
    is_deeply(
        $second->{path_list_keys},
        documentation_path_list_keys(),
        'fresh contract path-list keys match helper',
    );
    is_deeply(
        $second->{path_contract},
        documentation_path_contract(),
        'fresh contract path contract matches helper',
    );
    is_deeply(
        $second->{path_list_contract_map},
        documentation_path_list_contract_map(),
        'fresh contract path-list contract map matches helper',
    );
};

subtest 'documentation helper builders return fresh nested structures' => sub {
    for my $case (
        {
            label => 'public_top_level_keys',
            build => \&documentation_public_top_level_keys,
        },
        {
            label => 'path_list_keys',
            build => \&documentation_path_list_keys,
        },
        {
            label => 'path_contract',
            build => \&documentation_path_contract,
        },
        {
            label => 'path_list_contract_map',
            build => \&documentation_path_list_contract_map,
        },
    ) {
        my $first = $case->{build}->();
        mutate_structure($first);

        my $second = $case->{build}->();
        ok(!contains_sentinel($second), "$case->{label} returns fresh nested structures");
    }
};

subtest 'documentation path-list contract entries are independent structures' => sub {
    my $map = documentation_path_list_contract_map();

    mutate_structure($map->{human_contract});
    ok(
        !contains_sentinel($map->{downstream_alignment}),
        'mutating human_contract path contract does not mutate downstream_alignment path contract',
    );

    $map = build_documentation_contract()->{path_list_contract_map};
    mutate_structure($map->{downstream_alignment});
    ok(
        !contains_sentinel($map->{human_contract}),
        'mutating emitted downstream_alignment path contract does not mutate emitted human_contract path contract',
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
