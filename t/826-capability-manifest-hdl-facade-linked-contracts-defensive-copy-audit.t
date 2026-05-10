#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use File::Spec;
use FindBin;
use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');
use FSM::Support::CapabilityManifest qw(build_capability_manifest);
use FSM::Support::HDLGeneratorFacadeContract qw(build_hdl_generator_facade_contract);
my $sentinel = '__manifest_hdl_facade_mutation__';

subtest 'manifest-embedded HDLGenerator facade linked contract and guidance metadata rebuild cleanly after caller mutation' => sub {
    my $first = build_capability_manifest();
    my $mutated = $first->{embedding}{hdl_generator_facade};
    $mutated->{'result_contract_source'} = $sentinel;
    $mutated->{'direct_extension_contract_source'} = $sentinel;
    $mutated->{'debug_runtime_contract_source'} = $sentinel;
    $mutated->{'object_injection_arg_policy'} = $sentinel;
    $mutated->{'stateful_reuse_supported'} = $mutated->{'stateful_reuse_supported'} ? 0 : 1;
    $mutated->{'result_surface_json_safe_as_a_whole'} = $mutated->{'result_surface_json_safe_as_a_whole'} ? 0 : 1;
    $mutated->{'object_injection_args_public'} = $mutated->{'object_injection_args_public'} ? 0 : 1;
    mutate_structure($mutated->{'guidance'});

    my $second = build_capability_manifest();
    my $contract = $second->{embedding}{hdl_generator_facade};
    my $expected = build_hdl_generator_facade_contract();
    is($contract->{'result_contract_source'}, $expected->{'result_contract_source'}, 'fresh manifest facade rebuilds clean result_contract_source');
    is($contract->{'direct_extension_contract_source'}, $expected->{'direct_extension_contract_source'}, 'fresh manifest facade rebuilds clean direct_extension_contract_source');
    is($contract->{'debug_runtime_contract_source'}, $expected->{'debug_runtime_contract_source'}, 'fresh manifest facade rebuilds clean debug_runtime_contract_source');
    is($contract->{'object_injection_arg_policy'}, $expected->{'object_injection_arg_policy'}, 'fresh manifest facade rebuilds clean object_injection_arg_policy');
    is($contract->{'stateful_reuse_supported'} ? 1 : 0, $expected->{'stateful_reuse_supported'} ? 1 : 0, 'fresh manifest facade rebuilds clean stateful_reuse_supported');
    is($contract->{'result_surface_json_safe_as_a_whole'} ? 1 : 0, $expected->{'result_surface_json_safe_as_a_whole'} ? 1 : 0, 'fresh manifest facade rebuilds clean result_surface_json_safe_as_a_whole');
    is($contract->{'object_injection_args_public'} ? 1 : 0, $expected->{'object_injection_args_public'} ? 1 : 0, 'fresh manifest facade rebuilds clean object_injection_args_public');
    is_deeply($contract->{'guidance'}, $expected->{'guidance'}, 'fresh manifest facade rebuilds clean guidance');
};
done_testing();

sub mutate_structure {
    my ($value) = @_;
    return unless ref($value);
    if (ref($value) eq 'ARRAY') { push @{$value}, $sentinel; mutate_structure($_) for @{$value}; return; }
    if (ref($value) eq 'HASH') { $value->{$sentinel} = $sentinel; mutate_structure($_) for values %{$value}; return; }
}
