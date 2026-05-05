#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use File::Spec;
use FindBin;

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::Support::SupportAccountingContract qw(
    build_support_accounting_contract
    support_accounting_bucket_keys
    support_accounting_catalog_entry_optional_keys
    support_accounting_catalog_entry_required_keys
    support_accounting_id_list_keys
    support_accounting_presence_key_family_map
    support_accounting_public_top_level_keys
);

my $sentinel = '__mutated_by_t450__';

subtest 'support accounting contract builder returns fresh nested structures' => sub {
    my $first = build_support_accounting_contract();
    mutate_structure($first);

    my $second = build_support_accounting_contract();
    ok(!contains_sentinel($second), 'fresh support accounting contract is not affected by prior caller mutation');
    is_deeply(
        $second->{public_top_level_presence_keys},
        support_accounting_public_top_level_keys(),
        'fresh contract top-level presence keys match helper',
    );
    is_deeply(
        $second->{presence_key_family_map},
        support_accounting_presence_key_family_map(),
        'fresh contract presence family map matches helper',
    );
};

subtest 'support accounting helper builders return fresh nested structures' => sub {
    for my $case (
        {
            label => 'public_top_level_keys',
            build => \&support_accounting_public_top_level_keys,
        },
        {
            label => 'bucket_keys',
            build => \&support_accounting_bucket_keys,
        },
        {
            label => 'id_list_keys',
            build => \&support_accounting_id_list_keys,
        },
        {
            label => 'catalog_entry_required_keys',
            build => \&support_accounting_catalog_entry_required_keys,
        },
        {
            label => 'catalog_entry_optional_keys',
            build => \&support_accounting_catalog_entry_optional_keys,
        },
        {
            label => 'presence_key_family_map',
            build => \&support_accounting_presence_key_family_map,
        },
    ) {
        my $first = $case->{build}->();
        mutate_structure($first);

        my $second = $case->{build}->();
        ok(!contains_sentinel($second), "$case->{label} returns fresh nested structures");
    }
};

subtest 'fresh support accounting grouped map stays aligned with helper families' => sub {
    my $family_map = support_accounting_presence_key_family_map();

    is_deeply($family_map->{bucket_presence_keys}, support_accounting_bucket_keys(), 'bucket family entry matches helper');
    is_deeply($family_map->{id_list_presence_keys}, support_accounting_id_list_keys(), 'id-list family entry matches helper');
    is_deeply(
        $family_map->{catalog_entry_required_keys},
        support_accounting_catalog_entry_required_keys(),
        'catalog required family entry matches helper',
    );
    is_deeply(
        $family_map->{catalog_entry_optional_keys},
        support_accounting_catalog_entry_optional_keys(),
        'catalog optional family entry matches helper',
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
