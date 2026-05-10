#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use File::Spec;
use FindBin;

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::Support::CapabilityManifest qw(build_capability_manifest);
use FSM::Support::HDLGeneratorResultContract qw(
    build_hdl_generator_result_contract
);

my $sentinel = '__manifest_hdl_result_mutation__';

subtest 'manifest-embedded HDLGenerator semantic-layer scalar key lists rebuild cleanly after caller mutation' => sub {
    my $first = build_capability_manifest();
    my $mutated = $first->{embedding}{hdl_generator_result};

    mutate_structure($mutated->{'intent_hir_presence_keys'});
    mutate_structure($mutated->{'intent_hir_optional_composition_keys'});
    mutate_structure($mutated->{'lowered_rtl_ir_presence_keys'});
    mutate_structure($mutated->{'lowered_rtl_ir_optional_composition_keys'});
    mutate_structure($mutated->{'structural_rtl_ir_presence_keys'});


    my $second = build_capability_manifest();
    my $contract = $second->{embedding}{hdl_generator_result};
    my $expected = build_hdl_generator_result_contract();

    is_deeply($contract->{'intent_hir_presence_keys'}, $expected->{'intent_hir_presence_keys'}, 'fresh manifest result contract rebuilds clean intent_hir_presence_keys');
    is_deeply($contract->{'intent_hir_optional_composition_keys'}, $expected->{'intent_hir_optional_composition_keys'}, 'fresh manifest result contract rebuilds clean intent_hir_optional_composition_keys');
    is_deeply($contract->{'lowered_rtl_ir_presence_keys'}, $expected->{'lowered_rtl_ir_presence_keys'}, 'fresh manifest result contract rebuilds clean lowered_rtl_ir_presence_keys');
    is_deeply($contract->{'lowered_rtl_ir_optional_composition_keys'}, $expected->{'lowered_rtl_ir_optional_composition_keys'}, 'fresh manifest result contract rebuilds clean lowered_rtl_ir_optional_composition_keys');
    is_deeply($contract->{'structural_rtl_ir_presence_keys'}, $expected->{'structural_rtl_ir_presence_keys'}, 'fresh manifest result contract rebuilds clean structural_rtl_ir_presence_keys');

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
