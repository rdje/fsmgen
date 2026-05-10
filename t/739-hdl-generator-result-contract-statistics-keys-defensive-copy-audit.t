#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use File::Spec;
use FindBin;

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::Support::HDLGeneratorResultContract qw(
    build_hdl_generator_result_contract
    hdl_generator_result_statistics_optional_composition_keys
    hdl_generator_result_statistics_summary_keys
);

my $sentinel = '__mutated_by_t739__';

subtest 'HDLGenerator result statistics key lists rebuild cleanly after caller mutation' => sub {
    my $first = build_hdl_generator_result_contract();
    push @{$first->{statistics_summary_presence_keys}}, $sentinel;
    $first->{statistics_optional_composition_keys}[0] = $sentinel;

    my $second = build_hdl_generator_result_contract();
    ok(!contains_sentinel($second->{statistics_summary_presence_keys}), 'fresh statistics summary key list is not polluted');
    ok(!contains_sentinel($second->{statistics_optional_composition_keys}), 'fresh statistics optional key list is not polluted');
    is_deeply(
        $second->{statistics_summary_presence_keys},
        hdl_generator_result_statistics_summary_keys(),
        'fresh contract embeds canonical statistics summary keys',
    );
    is_deeply(
        $second->{statistics_optional_composition_keys},
        hdl_generator_result_statistics_optional_composition_keys(),
        'fresh contract embeds canonical statistics optional composition keys',
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
