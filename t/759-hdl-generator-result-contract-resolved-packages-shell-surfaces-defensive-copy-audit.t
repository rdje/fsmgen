#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use File::Spec;
use FindBin;

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::Support::HDLGeneratorResolvedPackageImportsContract qw(
    hdl_generator_resolved_package_imports_fallback_surface_map
    hdl_generator_resolved_package_imports_summary_surface
);
use FSM::Support::HDLGeneratorResultContract qw(
    build_hdl_generator_result_contract
);

my $sentinel = '__mutated_by_t759__';

subtest 'HDLGenerator result resolved_package_imports shell surfaces rebuild cleanly after caller mutation' => sub {
    my $first = build_hdl_generator_result_contract();
    mutate_structure($first->{resolved_package_imports_summary_surface});
    mutate_structure($first->{resolved_package_imports_fallback_surface_map});

    my $second = build_hdl_generator_result_contract();
    ok(!contains_sentinel($second->{resolved_package_imports_summary_surface}), 'fresh package summary surface is not polluted');
    ok(!contains_sentinel($second->{resolved_package_imports_fallback_surface_map}), 'fresh package fallback map is not polluted');
    is_deeply($second->{resolved_package_imports_summary_surface}, hdl_generator_resolved_package_imports_summary_surface(), 'fresh summary surface remains canonical');
    is_deeply($second->{resolved_package_imports_fallback_surface_map}, hdl_generator_resolved_package_imports_fallback_surface_map(), 'fresh fallback map remains canonical');
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
