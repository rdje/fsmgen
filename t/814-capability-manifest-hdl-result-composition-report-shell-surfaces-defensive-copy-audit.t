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

subtest 'manifest-embedded HDLGenerator `composition_report` shell surfaces rebuild cleanly after caller mutation' => sub {
    my $first = build_capability_manifest();
    my $mutated = $first->{embedding}{hdl_generator_result};

    $mutated->{'composition_report_contract_source'} = $sentinel;
    $mutated->{'composition_report_json_fragment_path'} = $sentinel;
    $mutated->{'composition_report_shell_only'} = $mutated->{'composition_report_shell_only'} ? 0 : 1;
    $mutated->{'composition_report_raw_hash_json_safe'} = $mutated->{'composition_report_raw_hash_json_safe'} ? 0 : 1;
    mutate_structure($mutated->{'shell_only_fallback_surface_map'});
    mutate_structure($mutated->{'shell_only_fallback_surface_family_map'});


    my $second = build_capability_manifest();
    my $contract = $second->{embedding}{hdl_generator_result};
    my $expected = build_hdl_generator_result_contract();

    is($contract->{'composition_report_contract_source'}, $expected->{'composition_report_contract_source'}, 'fresh manifest result contract rebuilds clean composition_report_contract_source');
    is($contract->{'composition_report_json_fragment_path'}, $expected->{'composition_report_json_fragment_path'}, 'fresh manifest result contract rebuilds clean composition_report_json_fragment_path');
    is($contract->{'composition_report_shell_only'} ? 1 : 0, $expected->{'composition_report_shell_only'} ? 1 : 0, 'fresh manifest result contract rebuilds clean composition_report_shell_only');
    is($contract->{'composition_report_raw_hash_json_safe'} ? 1 : 0, $expected->{'composition_report_raw_hash_json_safe'} ? 1 : 0, 'fresh manifest result contract rebuilds clean composition_report_raw_hash_json_safe');
    is_deeply($contract->{'shell_only_fallback_surface_map'}, $expected->{'shell_only_fallback_surface_map'}, 'fresh manifest result contract rebuilds clean shell_only_fallback_surface_map');
    is_deeply($contract->{'shell_only_fallback_surface_family_map'}, $expected->{'shell_only_fallback_surface_family_map'}, 'fresh manifest result contract rebuilds clean shell_only_fallback_surface_family_map');

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
