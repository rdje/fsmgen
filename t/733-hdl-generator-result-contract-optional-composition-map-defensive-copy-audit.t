#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use File::Spec;
use FindBin;

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::Support::HDLGeneratorResultContract qw(
    build_hdl_generator_result_contract
    hdl_generator_result_optional_composition_key_family_map
);

my $sentinel = '__mutated_by_t733__';

subtest 'HDLGenerator result optional_composition_key_family_map rebuilds cleanly after caller mutation' => sub {
    my $first = build_hdl_generator_result_contract();
    mutate_structure($first->{optional_composition_key_family_map});

    my $second = build_hdl_generator_result_contract();
    ok(
        !contains_sentinel($second->{optional_composition_key_family_map}),
        'fresh result contract optional_composition_key_family_map is not polluted',
    );
    is_deeply(
        $second->{optional_composition_key_family_map},
        hdl_generator_result_optional_composition_key_family_map(),
        'fresh result contract embeds canonical optional_composition_key_family_map',
    );
};

subtest 'optional_composition_key_family_map helper returns fresh nested structures' => sub {
    my $first = hdl_generator_result_optional_composition_key_family_map();
    mutate_structure($first);

    my $second = hdl_generator_result_optional_composition_key_family_map();
    ok(!contains_sentinel($second), 'fresh helper map is not polluted');
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
        return 1 if grep { contains_sentinel($_) } @{$value};
        return 0;
    }

    if (ref($value) eq 'HASH') {
        return 1 if exists($value->{$sentinel});
        return 1 if grep { contains_sentinel($_) } values %{$value};
        return 0;
    }

    return 0;
}
