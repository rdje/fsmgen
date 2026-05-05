#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use File::Spec;
use FindBin;

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::Support::ProducerContract qw(
    build_producer_contract
    producer_boolean_keys
    producer_presence_key_family_map
    producer_public_top_level_keys
    producer_scalar_string_keys
);

my $sentinel = '__mutated_by_t449__';

subtest 'producer contract builder returns fresh nested structures' => sub {
    my $first = build_producer_contract();
    mutate_structure($first);

    my $second = build_producer_contract();
    ok(!contains_sentinel($second), 'fresh producer contract is not affected by prior caller mutation');
    is_deeply(
        $second->{public_top_level_presence_keys},
        producer_public_top_level_keys(),
        'fresh contract top-level presence keys match helper',
    );
    is_deeply(
        $second->{scalar_string_keys},
        producer_scalar_string_keys(),
        'fresh contract scalar-string keys match helper',
    );
    is_deeply(
        $second->{boolean_keys},
        producer_boolean_keys(),
        'fresh contract boolean keys match helper',
    );
    is_deeply(
        $second->{presence_key_family_map},
        producer_presence_key_family_map(),
        'fresh contract presence family map matches helper',
    );
};

subtest 'producer helper builders return fresh nested structures' => sub {
    for my $case (
        {
            label => 'public_top_level_keys',
            build => \&producer_public_top_level_keys,
        },
        {
            label => 'scalar_string_keys',
            build => \&producer_scalar_string_keys,
        },
        {
            label => 'boolean_keys',
            build => \&producer_boolean_keys,
        },
        {
            label => 'presence_key_family_map',
            build => \&producer_presence_key_family_map,
        },
    ) {
        my $first = $case->{build}->();
        mutate_structure($first);

        my $second = $case->{build}->();
        ok(!contains_sentinel($second), "$case->{label} returns fresh nested structures");
    }
};

subtest 'fresh producer grouped map stays aligned with helper families' => sub {
    my $family_map = producer_presence_key_family_map();

    is_deeply(
        $family_map->{scalar_string_keys},
        producer_scalar_string_keys(),
        'scalar-string family entry matches helper',
    );
    is_deeply(
        $family_map->{boolean_keys},
        producer_boolean_keys(),
        'boolean family entry matches helper',
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
