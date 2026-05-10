#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use File::Spec;
use FindBin;

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::Support::HDLGeneratorResultContract qw(
    build_hdl_generator_result_contract
    hdl_generator_result_intent_hir_keys
    hdl_generator_result_intent_hir_optional_composition_keys
    hdl_generator_result_lowered_rtl_ir_keys
    hdl_generator_result_lowered_rtl_ir_optional_composition_keys
    hdl_generator_result_structural_rtl_ir_keys
);

my $sentinel = '__mutated_by_t740__';

subtest 'HDLGenerator result semantic layer key lists rebuild cleanly after caller mutation' => sub {
    my $first = build_hdl_generator_result_contract();
    push @{$first->{intent_hir_presence_keys}}, $sentinel;
    $first->{intent_hir_optional_composition_keys}[0] = $sentinel;
    push @{$first->{lowered_rtl_ir_presence_keys}}, $sentinel;
    $first->{lowered_rtl_ir_optional_composition_keys}[0] = $sentinel;
    push @{$first->{structural_rtl_ir_presence_keys}}, $sentinel;

    my $second = build_hdl_generator_result_contract();
    ok(!contains_sentinel($second->{intent_hir_presence_keys}), 'fresh intent_hir presence key list is not polluted');
    ok(!contains_sentinel($second->{intent_hir_optional_composition_keys}), 'fresh intent_hir optional key list is not polluted');
    ok(!contains_sentinel($second->{lowered_rtl_ir_presence_keys}), 'fresh lowered_rtl_ir presence key list is not polluted');
    ok(!contains_sentinel($second->{lowered_rtl_ir_optional_composition_keys}), 'fresh lowered_rtl_ir optional key list is not polluted');
    ok(!contains_sentinel($second->{structural_rtl_ir_presence_keys}), 'fresh structural_rtl_ir presence key list is not polluted');
    is_deeply($second->{intent_hir_presence_keys}, hdl_generator_result_intent_hir_keys(), 'fresh contract embeds canonical intent_hir keys');
    is_deeply($second->{intent_hir_optional_composition_keys}, hdl_generator_result_intent_hir_optional_composition_keys(), 'fresh contract embeds canonical intent_hir optional keys');
    is_deeply($second->{lowered_rtl_ir_presence_keys}, hdl_generator_result_lowered_rtl_ir_keys(), 'fresh contract embeds canonical lowered_rtl_ir keys');
    is_deeply($second->{lowered_rtl_ir_optional_composition_keys}, hdl_generator_result_lowered_rtl_ir_optional_composition_keys(), 'fresh contract embeds canonical lowered_rtl_ir optional keys');
    is_deeply($second->{structural_rtl_ir_presence_keys}, hdl_generator_result_structural_rtl_ir_keys(), 'fresh contract embeds canonical structural_rtl_ir keys');
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
