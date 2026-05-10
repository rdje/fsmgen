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

my $sentinel = '__mutated_by_t743__';

subtest 'HDLGenerator result guidance rebuilds cleanly after caller mutation' => sub {
    my $first = build_hdl_generator_result_contract();
    $first->{guidance}[0] = $sentinel;
    push @{$first->{guidance}}, $sentinel;

    my $second = build_hdl_generator_result_contract();
    ok(!contains_sentinel($second->{guidance}), 'fresh guidance list is not polluted');
    ok(@{$second->{guidance} || []} > 0, 'fresh guidance list remains non-empty');
    is(
        scalar(@{$second->{guidance}}),
        scalar(keys %{as_set($second->{guidance})}),
        'fresh guidance list remains unique',
    );
    ok(
        contains_matching_guidance($second->{guidance}, qr/Do not treat the entire HDLGenerator result hash as a stable JSON document/),
        'fresh guidance still warns against whole-result JSON stability',
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

sub as_set {
    my ($values) = @_;
    return {map { $_ => 1 } @{$values || []}};
}

sub contains_matching_guidance {
    my ($values, $pattern) = @_;
    for my $value (@{$values || []}) {
        return 1 if defined($value) && !ref($value) && $value =~ $pattern;
    }
    return 0;
}
