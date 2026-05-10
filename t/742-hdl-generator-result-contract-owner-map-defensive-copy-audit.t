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

my $sentinel = '__mutated_by_t742__';

subtest 'HDLGenerator result nested_contract_source_map rebuilds cleanly after caller mutation' => sub {
    my $first = build_hdl_generator_result_contract();
    $first->{nested_contract_source_map}{source_info} = $sentinel;
    $first->{nested_contract_source_map}{$sentinel} = $sentinel;

    my $second = build_hdl_generator_result_contract();
    ok(
        !contains_sentinel($second->{nested_contract_source_map}),
        'fresh result contract nested_contract_source_map is not polluted',
    );
    for my $branch (qw(source_info module_info statistics fsm_module raw_ast resolved_package_imports composition_spec composition_plan composition_report intent_hir lowered_rtl_ir structural_rtl_ir)) {
        ok(
            exists $second->{nested_contract_source_map}{$branch},
            "fresh owner map still advertises $branch",
        );
        like(
            $second->{nested_contract_source_map}{$branch},
            qr/^FSM::Support::/,
            "$branch owner remains a support contract source",
        );
    }
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
