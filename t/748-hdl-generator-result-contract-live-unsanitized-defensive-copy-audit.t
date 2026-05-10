#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use File::Spec;
use FindBin;

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::Support::HDLGeneratorResultContract qw(
    build_hdl_generator_result_contract
);

my $sentinel = '__mutated_by_t748__';

subtest 'HDLGenerator result live_or_unsanitized_keys rebuild cleanly after caller mutation' => sub {
    my $first = build_hdl_generator_result_contract();
    $first->{live_or_unsanitized_keys}[0] = $sentinel;
    push @{$first->{live_or_unsanitized_keys}}, $sentinel;

    my $second = build_hdl_generator_result_contract();
    ok(!contains_sentinel($second->{live_or_unsanitized_keys}), 'fresh live_or_unsanitized_keys list is not polluted');
    ok(contains_scalar($second->{live_or_unsanitized_keys}, 'fsm_module'), 'fresh list still marks fsm_module');
    ok(contains_scalar($second->{live_or_unsanitized_keys}, 'composition_report'), 'fresh list still marks composition_report');
    ok(!contains_scalar($second->{live_or_unsanitized_keys}, 'hdl_code'), 'fresh list does not mark hdl_code');
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

sub contains_scalar {
    my ($values, $wanted) = @_;
    return 0 unless ref($values) eq 'ARRAY';
    return scalar grep { defined($_) && !ref($_) && $_ eq $wanted } @{$values};
}
