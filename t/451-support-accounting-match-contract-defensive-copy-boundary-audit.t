#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use File::Spec;
use FindBin;

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::Support::SupportAccountingMatchContract qw(
    build_support_accounting_match_contract
    support_accounting_match_common_keys
    support_accounting_match_failure_keys
    support_accounting_match_presence_key_family_map
    support_accounting_match_success_keys
);

my $sentinel = '__mutated_by_t451__';

subtest 'support accounting match contract builder returns fresh nested structures' => sub {
    my $first = build_support_accounting_match_contract();
    mutate_structure($first);

    my $second = build_support_accounting_match_contract();
    ok(!contains_sentinel($second), 'fresh support accounting match contract is not affected by prior caller mutation');
    is_deeply(
        $second->{common_presence_keys},
        support_accounting_match_common_keys(),
        'fresh contract common presence keys match helper',
    );
    is_deeply(
        $second->{matched_success_presence_keys},
        support_accounting_match_success_keys(),
        'fresh contract matched-success presence keys match helper',
    );
    is_deeply(
        $second->{matched_failure_presence_keys},
        support_accounting_match_failure_keys(),
        'fresh contract matched-failure presence keys match helper',
    );
    is_deeply(
        $second->{presence_key_family_map},
        support_accounting_match_presence_key_family_map(),
        'fresh contract presence family map matches helper',
    );
};

subtest 'support accounting match helper builders return fresh nested structures' => sub {
    for my $case (
        {
            label => 'common_keys',
            build => \&support_accounting_match_common_keys,
        },
        {
            label => 'success_keys',
            build => \&support_accounting_match_success_keys,
        },
        {
            label => 'failure_keys',
            build => \&support_accounting_match_failure_keys,
        },
        {
            label => 'presence_key_family_map',
            build => \&support_accounting_match_presence_key_family_map,
        },
    ) {
        my $first = $case->{build}->();
        mutate_structure($first);

        my $second = $case->{build}->();
        ok(!contains_sentinel($second), "$case->{label} returns fresh nested structures");
    }
};

subtest 'fresh support accounting match grouped map stays aligned with helper families' => sub {
    my $family_map = support_accounting_match_presence_key_family_map();

    is_deeply($family_map->{common_presence_keys}, support_accounting_match_common_keys(), 'common family entry matches helper');
    is_deeply(
        $family_map->{matched_success_presence_keys},
        support_accounting_match_success_keys(),
        'matched-success family entry matches helper',
    );
    is_deeply(
        $family_map->{matched_failure_presence_keys},
        support_accounting_match_failure_keys(),
        'matched-failure family entry matches helper',
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
