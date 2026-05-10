#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use File::Spec;
use FindBin;

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::Support::CompositionReportContract qw(
    composition_report_json_fragment_path
);
use FSM::Support::HDLGeneratorResultContract qw(
    build_hdl_generator_result_contract
);

my $sentinel = '__mutated_by_t762__';

subtest 'HDLGenerator result composition_report shell fallback rebuilds cleanly after caller mutation' => sub {
    my $first = build_hdl_generator_result_contract();
    $first->{composition_report_json_fragment_path} = $sentinel;
    mutate_structure($first->{shell_only_fallback_surface_map}{composition_report});
    mutate_structure($first->{shell_only_fallback_surface_family_map}{composition_report});

    my $second = build_hdl_generator_result_contract();
    is($second->{composition_report_json_fragment_path}, composition_report_json_fragment_path(), 'fresh JSON fragment path remains canonical');
    ok(!contains_sentinel($second->{shell_only_fallback_surface_map}{composition_report}), 'fresh grouped composition_report fallback surface is not polluted');
    ok(!contains_sentinel($second->{shell_only_fallback_surface_family_map}{composition_report}), 'fresh grouped composition_report fallback family is not polluted');
    is_deeply($second->{shell_only_fallback_surface_map}{composition_report}, [composition_report_json_fragment_path()], 'fresh grouped surface points at canonical path');
    is_deeply($second->{shell_only_fallback_surface_family_map}{composition_report}{sanitized_json_fragment}, [composition_report_json_fragment_path()], 'fresh grouped family points at canonical path');
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
