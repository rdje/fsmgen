#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use File::Spec;
use FindBin;

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::Support::HDLGeneratorCompositionSpecContract qw(
    hdl_generator_composition_spec_fallback_surface_map
    hdl_generator_composition_spec_summary_surfaces
);
use FSM::Support::HDLGeneratorResultContract qw(
    build_hdl_generator_result_contract
);

my $sentinel = '__mutated_by_t760__';

subtest 'HDLGenerator result composition_spec shell surfaces rebuild cleanly after caller mutation' => sub {
    my $first = build_hdl_generator_result_contract();
    mutate_structure($first->{composition_spec_summary_surfaces});
    mutate_structure($first->{composition_spec_fallback_surface_map});

    my $second = build_hdl_generator_result_contract();
    ok(!contains_sentinel($second->{composition_spec_summary_surfaces}), 'fresh composition_spec summary surfaces are not polluted');
    ok(!contains_sentinel($second->{composition_spec_fallback_surface_map}), 'fresh composition_spec fallback map is not polluted');
    is_deeply($second->{composition_spec_summary_surfaces}, hdl_generator_composition_spec_summary_surfaces(), 'fresh summary surfaces remain canonical');
    is_deeply($second->{composition_spec_fallback_surface_map}, hdl_generator_composition_spec_fallback_surface_map(), 'fresh fallback map remains canonical');
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
