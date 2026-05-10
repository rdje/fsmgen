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
);

my $sentinel = '__mutated_by_t741__';

subtest 'HDLGenerator result top-level key families rebuild cleanly after caller mutation' => sub {
    my $first = build_hdl_generator_result_contract();
    push @{$first->{public_top_level_presence_keys}}, $sentinel;
    $first->{direct_root_top_level_keys}[0] = $sentinel;
    push @{$first->{composition_root_top_level_keys}}, $sentinel;

    my $second = build_hdl_generator_result_contract();
    for my $field (qw(public_top_level_presence_keys direct_root_top_level_keys composition_root_top_level_keys)) {
        ok(!contains_sentinel($second->{$field}), "fresh $field list is not polluted");
    }
    is_deeply(
        unique_sorted([
            @{$second->{public_top_level_presence_keys}},
            @{$second->{direct_root_top_level_keys}},
            @{$second->{composition_root_top_level_keys}},
        ]),
        hdl_generator_result_known_top_level_keys(),
        'fresh top-level key families still feed the known-key helper',
    );
};

done_testing();

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

sub unique_sorted {
    my ($values) = @_;
    my %seen;
    return [sort grep { !$seen{$_}++ } @{$values || []}];
}
