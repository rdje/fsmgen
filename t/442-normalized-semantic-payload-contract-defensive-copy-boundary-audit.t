#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use File::Spec;
use FindBin;

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::Support::NormalizedSemanticPayloadContract qw(
    build_normalized_semantic_payload_contract
    normalized_semantic_payload_composition_keys
    normalized_semantic_payload_explicit_system_contract_keys
    normalized_semantic_payload_forward_ir_intent_hir_keys
    normalized_semantic_payload_forward_ir_intent_hir_optional_composition_keys
    normalized_semantic_payload_forward_ir_keys
    normalized_semantic_payload_forward_ir_lowered_rtl_ir_keys
    normalized_semantic_payload_forward_ir_lowered_rtl_ir_optional_composition_keys
    normalized_semantic_payload_forward_ir_lowered_rtl_ir_output_drive_family_entry_keys
    normalized_semantic_payload_forward_ir_lowered_rtl_ir_output_drive_rhs_enable_family_entry_keys
    normalized_semantic_payload_forward_ir_lowered_rtl_ir_selector_conflict_multi_value_assertion_keys
    normalized_semantic_payload_forward_ir_lowered_rtl_ir_selector_conflict_rhs_enable_family_entry_keys
    normalized_semantic_payload_forward_ir_lowered_rtl_ir_selector_conflict_same_value_assertion_keys
    normalized_semantic_payload_forward_ir_lowered_rtl_ir_selector_conflict_target_entry_keys
    normalized_semantic_payload_forward_ir_structural_rtl_ir_declared_link_entry_keys
    normalized_semantic_payload_forward_ir_structural_rtl_ir_instance_entry_keys
    normalized_semantic_payload_forward_ir_structural_rtl_ir_instance_interface_port_entry_keys
    normalized_semantic_payload_forward_ir_structural_rtl_ir_instance_parameter_override_entry_keys
    normalized_semantic_payload_forward_ir_structural_rtl_ir_instance_parameter_override_raw_value_extension_keys
    normalized_semantic_payload_forward_ir_structural_rtl_ir_instance_parameter_override_value_metadata_extension_keys
    normalized_semantic_payload_forward_ir_structural_rtl_ir_instance_port_binding_entry_keys
    normalized_semantic_payload_forward_ir_structural_rtl_ir_instance_port_binding_typed_extension_keys
    normalized_semantic_payload_forward_ir_nested_contract_source_map
    normalized_semantic_payload_forward_ir_nested_presence_key_map
    normalized_semantic_payload_forward_ir_structural_rtl_ir_net_entry_keys
    normalized_semantic_payload_forward_ir_structural_rtl_ir_port_composition_extension_keys
    normalized_semantic_payload_forward_ir_structural_rtl_ir_port_entry_keys
    normalized_semantic_payload_forward_ir_structural_rtl_ir_resolved_link_entry_keys
    normalized_semantic_payload_forward_ir_structural_rtl_ir_keys
    normalized_semantic_payload_nested_presence_key_map
    normalized_semantic_payload_optional_child_presence_keys
    normalized_semantic_payload_presence_key_family_map
    normalized_semantic_payload_presence_keys
    normalized_semantic_payload_signal_analysis_entry_keys
    normalized_semantic_payload_signal_analysis_keys
    normalized_semantic_payload_symbol_contract_keys
    normalized_semantic_payload_system_contract_keys
);

my $sentinel = '__mutated_by_t442__';

subtest 'normalized semantic payload contract builder returns fresh nested structures' => sub {
    my $first = build_normalized_semantic_payload_contract();
    mutate_structure($first);

    my $second = build_normalized_semantic_payload_contract();
    ok(!contains_sentinel($second), 'fresh normalized semantic payload contract is not affected by prior caller mutation');
    is_deeply(
        $second->{nested_presence_key_map},
        normalized_semantic_payload_nested_presence_key_map(),
        'fresh contract nested presence map matches its helper',
    );
    is_deeply(
        $second->{presence_key_family_map},
        normalized_semantic_payload_presence_key_family_map(),
        'fresh contract presence family map matches its helper',
    );
    is_deeply(
        $second->{forward_ir_nested_contract_source_map},
        normalized_semantic_payload_forward_ir_nested_contract_source_map(),
        'fresh contract forward-IR nested contract-source map matches its helper',
    );
    is_deeply(
        $second->{forward_ir_nested_presence_key_map},
        normalized_semantic_payload_forward_ir_nested_presence_key_map(),
        'fresh contract forward-IR nested presence map matches its helper',
    );
};

subtest 'normalized semantic payload helper builders return fresh nested structures' => sub {
    for my $case (
        {
            label => 'presence_keys',
            build => \&normalized_semantic_payload_presence_keys,
        },
        {
            label => 'nested_presence_key_map',
            build => \&normalized_semantic_payload_nested_presence_key_map,
        },
        {
            label => 'presence_key_family_map',
            build => \&normalized_semantic_payload_presence_key_family_map,
        },
        {
            label => 'optional_child_presence_keys',
            build => \&normalized_semantic_payload_optional_child_presence_keys,
        },
        {
            label => 'forward_ir_nested_contract_source_map',
            build => \&normalized_semantic_payload_forward_ir_nested_contract_source_map,
        },
        {
            label => 'forward_ir_nested_presence_key_map',
            build => \&normalized_semantic_payload_forward_ir_nested_presence_key_map,
        },
        {
            label => 'forward_ir_keys',
            build => \&normalized_semantic_payload_forward_ir_keys,
        },
        {
            label => 'forward_ir_intent_hir_keys',
            build => \&normalized_semantic_payload_forward_ir_intent_hir_keys,
        },
        {
            label => 'forward_ir_intent_hir_optional_composition_keys',
            build => \&normalized_semantic_payload_forward_ir_intent_hir_optional_composition_keys,
        },
        {
            label => 'forward_ir_lowered_rtl_ir_keys',
            build => \&normalized_semantic_payload_forward_ir_lowered_rtl_ir_keys,
        },
        {
            label => 'forward_ir_lowered_rtl_ir_optional_composition_keys',
            build => \&normalized_semantic_payload_forward_ir_lowered_rtl_ir_optional_composition_keys,
        },
        {
            label => 'forward_ir_lowered_rtl_ir_output_drive_family_entry_keys',
            build => \&normalized_semantic_payload_forward_ir_lowered_rtl_ir_output_drive_family_entry_keys,
        },
        {
            label => 'forward_ir_lowered_rtl_ir_output_drive_rhs_enable_family_entry_keys',
            build => \&normalized_semantic_payload_forward_ir_lowered_rtl_ir_output_drive_rhs_enable_family_entry_keys,
        },
        {
            label => 'forward_ir_lowered_rtl_ir_selector_conflict_target_entry_keys',
            build => \&normalized_semantic_payload_forward_ir_lowered_rtl_ir_selector_conflict_target_entry_keys,
        },
        {
            label => 'forward_ir_lowered_rtl_ir_selector_conflict_rhs_enable_family_entry_keys',
            build => \&normalized_semantic_payload_forward_ir_lowered_rtl_ir_selector_conflict_rhs_enable_family_entry_keys,
        },
        {
            label => 'forward_ir_lowered_rtl_ir_selector_conflict_multi_value_assertion_keys',
            build => \&normalized_semantic_payload_forward_ir_lowered_rtl_ir_selector_conflict_multi_value_assertion_keys,
        },
        {
            label => 'forward_ir_lowered_rtl_ir_selector_conflict_same_value_assertion_keys',
            build => \&normalized_semantic_payload_forward_ir_lowered_rtl_ir_selector_conflict_same_value_assertion_keys,
        },
        {
            label => 'forward_ir_structural_rtl_ir_keys',
            build => \&normalized_semantic_payload_forward_ir_structural_rtl_ir_keys,
        },
        {
            label => 'forward_ir_structural_rtl_ir_port_entry_keys',
            build => \&normalized_semantic_payload_forward_ir_structural_rtl_ir_port_entry_keys,
        },
        {
            label => 'forward_ir_structural_rtl_ir_port_composition_extension_keys',
            build => \&normalized_semantic_payload_forward_ir_structural_rtl_ir_port_composition_extension_keys,
        },
        {
            label => 'forward_ir_structural_rtl_ir_net_entry_keys',
            build => \&normalized_semantic_payload_forward_ir_structural_rtl_ir_net_entry_keys,
        },
        {
            label => 'forward_ir_structural_rtl_ir_declared_link_entry_keys',
            build => \&normalized_semantic_payload_forward_ir_structural_rtl_ir_declared_link_entry_keys,
        },
        {
            label => 'forward_ir_structural_rtl_ir_resolved_link_entry_keys',
            build => \&normalized_semantic_payload_forward_ir_structural_rtl_ir_resolved_link_entry_keys,
        },
        {
            label => 'forward_ir_structural_rtl_ir_instance_entry_keys',
            build => \&normalized_semantic_payload_forward_ir_structural_rtl_ir_instance_entry_keys,
        },
        {
            label => 'forward_ir_structural_rtl_ir_instance_interface_port_entry_keys',
            build => \&normalized_semantic_payload_forward_ir_structural_rtl_ir_instance_interface_port_entry_keys,
        },
        {
            label => 'forward_ir_structural_rtl_ir_instance_parameter_override_entry_keys',
            build => \&normalized_semantic_payload_forward_ir_structural_rtl_ir_instance_parameter_override_entry_keys,
        },
        {
            label => 'forward_ir_structural_rtl_ir_instance_parameter_override_raw_value_extension_keys',
            build => \&normalized_semantic_payload_forward_ir_structural_rtl_ir_instance_parameter_override_raw_value_extension_keys,
        },
        {
            label => 'forward_ir_structural_rtl_ir_instance_parameter_override_value_metadata_extension_keys',
            build => \&normalized_semantic_payload_forward_ir_structural_rtl_ir_instance_parameter_override_value_metadata_extension_keys,
        },
        {
            label => 'forward_ir_structural_rtl_ir_instance_port_binding_entry_keys',
            build => \&normalized_semantic_payload_forward_ir_structural_rtl_ir_instance_port_binding_entry_keys,
        },
        {
            label => 'forward_ir_structural_rtl_ir_instance_port_binding_typed_extension_keys',
            build => \&normalized_semantic_payload_forward_ir_structural_rtl_ir_instance_port_binding_typed_extension_keys,
        },
        {
            label => 'explicit_system_contract_keys',
            build => \&normalized_semantic_payload_explicit_system_contract_keys,
        },
        {
            label => 'signal_analysis_keys',
            build => \&normalized_semantic_payload_signal_analysis_keys,
        },
        {
            label => 'signal_analysis_entry_keys',
            build => \&normalized_semantic_payload_signal_analysis_entry_keys,
        },
        {
            label => 'system_contract_keys',
            build => \&normalized_semantic_payload_system_contract_keys,
        },
        {
            label => 'symbol_contract_keys',
            build => \&normalized_semantic_payload_symbol_contract_keys,
        },
        {
            label => 'composition_keys',
            build => \&normalized_semantic_payload_composition_keys,
        },
    ) {
        my $first = $case->{build}->();
        mutate_structure($first);

        my $second = $case->{build}->();
        ok(!contains_sentinel($second), "$case->{label} returns fresh nested structures");
    }
};

subtest 'fresh normalized semantic grouped maps stay aligned with helper families' => sub {
    my $nested_map = normalized_semantic_payload_nested_presence_key_map();
    is_deeply($nested_map->{module}, build_normalized_semantic_payload_contract()->{module_presence_keys}, 'module nested map entry matches contract helper value');
    is_deeply($nested_map->{explicit_system_contract}, normalized_semantic_payload_explicit_system_contract_keys(), 'explicit-system nested map entry matches helper');
    is_deeply($nested_map->{signal_analysis}, normalized_semantic_payload_signal_analysis_keys(), 'signal-analysis nested map entry matches helper');
    is_deeply($nested_map->{system_contract}, normalized_semantic_payload_system_contract_keys(), 'system-contract nested map entry matches helper');
    is_deeply($nested_map->{forward_ir}, normalized_semantic_payload_forward_ir_keys(), 'forward-IR nested map entry matches helper');
    is_deeply($nested_map->{symbol_contract}, normalized_semantic_payload_symbol_contract_keys(), 'symbol-contract nested map entry matches helper');
    is_deeply($nested_map->{composition}, normalized_semantic_payload_composition_keys(), 'composition nested map entry matches helper');

    my $family_map = normalized_semantic_payload_presence_key_family_map();
    is_deeply($family_map->{public_presence_keys}, normalized_semantic_payload_presence_keys(), 'public presence family entry matches helper');
    is_deeply($family_map->{optional_child_presence_keys}, normalized_semantic_payload_optional_child_presence_keys(), 'optional child family entry matches helper');
    is_deeply($family_map->{signal_analysis_entry_presence_keys}, normalized_semantic_payload_signal_analysis_entry_keys(), 'signal-analysis entry family entry matches helper');
    is_deeply(
        $family_map->{forward_ir_intent_hir_optional_composition_keys},
        normalized_semantic_payload_forward_ir_intent_hir_optional_composition_keys(),
        'intent-HIR optional composition family entry matches helper',
    );
    is_deeply(
        $family_map->{forward_ir_lowered_rtl_ir_optional_composition_keys},
        normalized_semantic_payload_forward_ir_lowered_rtl_ir_optional_composition_keys(),
        'lowered-RTL optional composition family entry matches helper',
    );
    is_deeply(
        $family_map->{forward_ir_lowered_rtl_ir_output_drive_family_entry_keys},
        normalized_semantic_payload_forward_ir_lowered_rtl_ir_output_drive_family_entry_keys(),
        'lowered-RTL output-drive family entry family matches helper',
    );
    is_deeply(
        $family_map->{forward_ir_lowered_rtl_ir_output_drive_rhs_enable_family_entry_keys},
        normalized_semantic_payload_forward_ir_lowered_rtl_ir_output_drive_rhs_enable_family_entry_keys(),
        'lowered-RTL output-drive rhs-enable-family entry family matches helper',
    );
    is_deeply(
        $family_map->{forward_ir_lowered_rtl_ir_selector_conflict_target_entry_keys},
        normalized_semantic_payload_forward_ir_lowered_rtl_ir_selector_conflict_target_entry_keys(),
        'lowered-RTL selector-conflict target entry family matches helper',
    );
    is_deeply(
        $family_map->{forward_ir_lowered_rtl_ir_selector_conflict_rhs_enable_family_entry_keys},
        normalized_semantic_payload_forward_ir_lowered_rtl_ir_selector_conflict_rhs_enable_family_entry_keys(),
        'lowered-RTL selector-conflict rhs-enable-family entry family matches helper',
    );
    is_deeply(
        $family_map->{forward_ir_lowered_rtl_ir_selector_conflict_multi_value_assertion_keys},
        normalized_semantic_payload_forward_ir_lowered_rtl_ir_selector_conflict_multi_value_assertion_keys(),
        'lowered-RTL selector-conflict multi-value assertion family matches helper',
    );
    is_deeply(
        $family_map->{forward_ir_lowered_rtl_ir_selector_conflict_same_value_assertion_keys},
        normalized_semantic_payload_forward_ir_lowered_rtl_ir_selector_conflict_same_value_assertion_keys(),
        'lowered-RTL selector-conflict same-value assertion family matches helper',
    );
    is_deeply(
        $family_map->{forward_ir_structural_rtl_ir_port_entry_keys},
        normalized_semantic_payload_forward_ir_structural_rtl_ir_port_entry_keys(),
        'structural-RTL port entry family matches helper',
    );
    is_deeply(
        $family_map->{forward_ir_structural_rtl_ir_port_composition_extension_keys},
        normalized_semantic_payload_forward_ir_structural_rtl_ir_port_composition_extension_keys(),
        'structural-RTL port composition extension family matches helper',
    );
    is_deeply(
        $family_map->{forward_ir_structural_rtl_ir_net_entry_keys},
        normalized_semantic_payload_forward_ir_structural_rtl_ir_net_entry_keys(),
        'structural-RTL net entry family matches helper',
    );
    is_deeply(
        $family_map->{forward_ir_structural_rtl_ir_declared_link_entry_keys},
        normalized_semantic_payload_forward_ir_structural_rtl_ir_declared_link_entry_keys(),
        'structural-RTL declared-link entry family matches helper',
    );
    is_deeply(
        $family_map->{forward_ir_structural_rtl_ir_resolved_link_entry_keys},
        normalized_semantic_payload_forward_ir_structural_rtl_ir_resolved_link_entry_keys(),
        'structural-RTL resolved-link entry family matches helper',
    );
    is_deeply(
        $family_map->{forward_ir_structural_rtl_ir_instance_entry_keys},
        normalized_semantic_payload_forward_ir_structural_rtl_ir_instance_entry_keys(),
        'structural-RTL instance shallow entry family matches helper',
    );
    is_deeply(
        $family_map->{forward_ir_structural_rtl_ir_instance_interface_port_entry_keys},
        normalized_semantic_payload_forward_ir_structural_rtl_ir_instance_interface_port_entry_keys(),
        'structural-RTL instance interface-port entry family matches helper',
    );
    is_deeply(
        $family_map->{forward_ir_structural_rtl_ir_instance_parameter_override_entry_keys},
        normalized_semantic_payload_forward_ir_structural_rtl_ir_instance_parameter_override_entry_keys(),
        'structural-RTL instance parameter-override core entry family matches helper',
    );
    is_deeply(
        $family_map->{forward_ir_structural_rtl_ir_instance_parameter_override_raw_value_extension_keys},
        normalized_semantic_payload_forward_ir_structural_rtl_ir_instance_parameter_override_raw_value_extension_keys(),
        'structural-RTL instance parameter-override raw-value extension family matches helper',
    );
    is_deeply(
        $family_map->{forward_ir_structural_rtl_ir_instance_parameter_override_value_metadata_extension_keys},
        normalized_semantic_payload_forward_ir_structural_rtl_ir_instance_parameter_override_value_metadata_extension_keys(),
        'structural-RTL instance parameter-override value-metadata extension family matches helper',
    );
    is_deeply(
        $family_map->{forward_ir_structural_rtl_ir_instance_port_binding_entry_keys},
        normalized_semantic_payload_forward_ir_structural_rtl_ir_instance_port_binding_entry_keys(),
        'structural-RTL instance port-binding core entry family matches helper',
    );
    is_deeply(
        $family_map->{forward_ir_structural_rtl_ir_instance_port_binding_typed_extension_keys},
        normalized_semantic_payload_forward_ir_structural_rtl_ir_instance_port_binding_typed_extension_keys(),
        'structural-RTL instance port-binding typed extension family matches helper',
    );

    my $forward_ir_map = normalized_semantic_payload_forward_ir_nested_presence_key_map();
    is_deeply($forward_ir_map->{intent_hir}, normalized_semantic_payload_forward_ir_intent_hir_keys(), 'forward-IR intent-HIR map entry matches helper');
    is_deeply($forward_ir_map->{lowered_rtl_ir}, normalized_semantic_payload_forward_ir_lowered_rtl_ir_keys(), 'forward-IR lowered-RTL map entry matches helper');
    is_deeply($forward_ir_map->{structural_rtl_ir}, normalized_semantic_payload_forward_ir_structural_rtl_ir_keys(), 'forward-IR structural-RTL map entry matches helper');
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
        for my $entry (@{$value}) {
            return 1 if contains_sentinel($entry);
        }
        return 0;
    }

    if (ref($value) eq 'HASH') {
        return 1 if exists($value->{$sentinel});
        for my $entry (values %{$value}) {
            return 1 if contains_sentinel($entry);
        }
        return 0;
    }

    return 0;
}
