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

my $sentinel = '__mutated_by_t744__';

subtest 'HDLGenerator result tested_by provenance rebuilds cleanly after caller mutation' => sub {
    my $first = build_hdl_generator_result_contract();
    $first->{tested_by}[0] = $sentinel;
    push @{$first->{tested_by}}, $sentinel;

    my $second = build_hdl_generator_result_contract();
    ok(!contains_sentinel($second->{tested_by}), 'fresh tested_by list is not polluted');
    ok(
        contains_scalar($second->{tested_by}, 't/305-hdl-generator-result-contract.t'),
        'fresh tested_by still includes the primary contract test',
    );
    ok(
        contains_scalar($second->{tested_by}, 't/438-hdl-generator-result-contract-defensive-copy-boundary-audit.t'),
        'fresh tested_by still includes the defensive-copy boundary audit',
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

sub contains_scalar {
    my ($values, $wanted) = @_;
    return 0 unless ref($values) eq 'ARRAY';
    return scalar grep { defined($_) && !ref($_) && $_ eq $wanted } @{$values};
}
