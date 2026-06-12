#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use File::Spec;
use FindBin;

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::Support::NormalizedSemanticStructuralRTLIRContract qw(
    build_normalized_semantic_structural_rtl_ir_contract
    normalized_semantic_structural_rtl_ir_assignment_record_entry_keys
    normalized_semantic_structural_rtl_ir_assignment_record_lhs_entry_keys
    normalized_semantic_structural_rtl_ir_assignment_record_provenance_entry_keys
    normalized_semantic_structural_rtl_ir_assignment_record_rhs_entry_keys
    normalized_semantic_structural_rtl_ir_auxiliary_assignment_entry_value_kinds
    normalized_semantic_structural_rtl_ir_auxiliary_assignment_entry_value_meaning
    normalized_semantic_structural_rtl_ir_collection_presence_keys
    normalized_semantic_structural_rtl_ir_contract_source
    normalized_semantic_structural_rtl_ir_declared_link_entry_keys
    normalized_semantic_structural_rtl_ir_instance_entry_keys
    normalized_semantic_structural_rtl_ir_instance_interface_port_entry_keys
    normalized_semantic_structural_rtl_ir_instance_parameter_override_entry_keys
    normalized_semantic_structural_rtl_ir_instance_parameter_override_raw_value_extension_keys
    normalized_semantic_structural_rtl_ir_instance_parameter_override_value_metadata_extension_keys
    normalized_semantic_structural_rtl_ir_instance_port_binding_entry_keys
    normalized_semantic_structural_rtl_ir_instance_port_binding_typed_extension_keys
    normalized_semantic_structural_rtl_ir_link_entry_keys
    normalized_semantic_structural_rtl_ir_net_entry_keys
    normalized_semantic_structural_rtl_ir_net_source_entry_keys
    normalized_semantic_structural_rtl_ir_net_target_entry_keys
    normalized_semantic_structural_rtl_ir_presence_key_family_map
    normalized_semantic_structural_rtl_ir_presence_keys
    normalized_semantic_structural_rtl_ir_port_composition_extension_keys
    normalized_semantic_structural_rtl_ir_port_entry_keys
    normalized_semantic_structural_rtl_ir_resolved_link_entry_keys
    normalized_semantic_structural_rtl_ir_summary_presence_keys
);

subtest 'contract exposes the bounded normalized semantic structural-rtl-ir object' => sub {
    my $contract = build_normalized_semantic_structural_rtl_ir_contract();

    is($contract->{schema_version}, 1, 'contract exposes schema version');
    is($contract->{status}, 'bounded_public', 'contract marks the nested structural-rtl-ir object as bounded public');
    is(
        $contract->{contract_source},
        normalized_semantic_structural_rtl_ir_contract_source(),
        'contract records its own owner',
    );
    is($contract->{object_name}, 'structural_rtl_ir', 'contract records the nested object name');
    is($contract->{parent_object_name}, 'semantic.forward_ir.structural_rtl_ir', 'contract records the nested parent path');
    ok(
        $contract->{json_safe_when_embedded_in_public_reports},
        'contract says the nested structural-rtl-ir object is JSON-safe when embedded in public reports',
    );
    is_deeply(
        $contract->{public_presence_keys},
        normalized_semantic_structural_rtl_ir_presence_keys(),
        'contract publishes the bounded structural-rtl-ir key list',
    );
    is_deeply(
        $contract->{summary_presence_keys},
        normalized_semantic_structural_rtl_ir_summary_presence_keys(),
        'contract publishes the bounded structural-rtl-ir summary key family',
    );
    is_deeply(
        $contract->{collection_presence_keys},
        normalized_semantic_structural_rtl_ir_collection_presence_keys(),
        'contract publishes the bounded structural-rtl-ir collection key family',
    );
    is_deeply(
        $contract->{auxiliary_assignment_entry_value_kinds},
        normalized_semantic_structural_rtl_ir_auxiliary_assignment_entry_value_kinds(),
        'contract publishes the bounded structural-rtl-ir auxiliary-assignment entry value-kind family',
    );
    is_deeply(
        normalized_semantic_structural_rtl_ir_auxiliary_assignment_entry_value_kinds(),
        [qw(scalar_string)],
        'structural-rtl-ir auxiliary-assignment entry value kinds stay exact and ordered',
    );
    is(
        $contract->{auxiliary_assignment_entry_value_meaning},
        normalized_semantic_structural_rtl_ir_auxiliary_assignment_entry_value_meaning(),
        'contract publishes the bounded structural-rtl-ir auxiliary-assignment entry value meaning',
    );
    is_deeply(
        $contract->{assignment_record_entry_keys},
        normalized_semantic_structural_rtl_ir_assignment_record_entry_keys(),
        'contract publishes the bounded structural-rtl-ir assignment-record entry key family',
    );
    is_deeply(
        normalized_semantic_structural_rtl_ir_assignment_record_entry_keys(),
        [qw(kind lhs provenance rendered rhs)],
        'structural-rtl-ir assignment-record entry keys stay exact and ordered',
    );
    is_deeply(
        $contract->{assignment_record_lhs_entry_keys},
        normalized_semantic_structural_rtl_ir_assignment_record_lhs_entry_keys(),
        'contract publishes the bounded structural-rtl-ir assignment-record lhs entry key family',
    );
    is_deeply(
        normalized_semantic_structural_rtl_ir_assignment_record_lhs_entry_keys(),
        [qw(kind name)],
        'structural-rtl-ir assignment-record lhs entry keys stay exact and ordered',
    );
    is_deeply(
        $contract->{assignment_record_rhs_entry_keys},
        normalized_semantic_structural_rtl_ir_assignment_record_rhs_entry_keys(),
        'contract publishes the bounded structural-rtl-ir assignment-record rhs entry key family',
    );
    is_deeply(
        normalized_semantic_structural_rtl_ir_assignment_record_rhs_entry_keys(),
        [qw(ast kind language text)],
        'structural-rtl-ir assignment-record rhs entry keys stay exact and ordered',
    );
    is_deeply(
        $contract->{assignment_record_provenance_entry_keys},
        normalized_semantic_structural_rtl_ir_assignment_record_provenance_entry_keys(),
        'contract publishes the bounded structural-rtl-ir assignment-record provenance key family',
    );
    is_deeply(
        normalized_semantic_structural_rtl_ir_assignment_record_provenance_entry_keys(),
        [qw(clean_dt_name dt_name dte_gate_signal family lhs_signal rhs_value role state_name)],
        'structural-rtl-ir assignment-record provenance keys stay exact and ordered',
    );
    is_deeply(
        $contract->{port_entry_keys},
        normalized_semantic_structural_rtl_ir_port_entry_keys(),
        'contract publishes the bounded structural-rtl-ir port entry key family',
    );
    is_deeply(
        normalized_semantic_structural_rtl_ir_port_entry_keys(),
        [qw(direction name signed type width)],
        'structural-rtl-ir port entry keys stay exact and ordered',
    );
    is_deeply(
        $contract->{port_composition_extension_keys},
        normalized_semantic_structural_rtl_ir_port_composition_extension_keys(),
        'contract publishes the bounded structural-rtl-ir port composition extension key family',
    );
    is_deeply(
        normalized_semantic_structural_rtl_ir_port_composition_extension_keys(),
        [qw(binding_mode origin_kind)],
        'structural-rtl-ir port composition extension keys stay exact and ordered',
    );
    is_deeply(
        $contract->{net_entry_keys},
        normalized_semantic_structural_rtl_ir_net_entry_keys(),
        'contract publishes the bounded structural-rtl-ir net entry key family',
    );
    is_deeply(
        normalized_semantic_structural_rtl_ir_net_entry_keys(),
        [qw(name source targets width)],
        'structural-rtl-ir net entry keys stay exact and ordered',
    );
    is_deeply(
        $contract->{net_source_entry_keys},
        normalized_semantic_structural_rtl_ir_net_source_entry_keys(),
        'contract publishes the bounded structural-rtl-ir net source entry key family',
    );
    is_deeply(
        normalized_semantic_structural_rtl_ir_net_source_entry_keys(),
        [qw(assignment_kind assignment_lhs family kind role)],
        'structural-rtl-ir net source entry keys stay exact and ordered',
    );
    is_deeply(
        $contract->{net_target_entry_keys},
        normalized_semantic_structural_rtl_ir_net_target_entry_keys(),
        'contract publishes the bounded structural-rtl-ir net target entry key family',
    );
    is_deeply(
        normalized_semantic_structural_rtl_ir_net_target_entry_keys(),
        [qw(assignment_kind assignment_lhs family kind role)],
        'structural-rtl-ir net target entry keys stay exact and ordered',
    );
    is_deeply(
        normalized_semantic_structural_rtl_ir_link_entry_keys(),
        [qw(origin_kind raw_token source target)],
        'structural-rtl-ir shared link entry keys stay exact and ordered',
    );
    is_deeply(
        $contract->{declared_link_entry_keys},
        normalized_semantic_structural_rtl_ir_declared_link_entry_keys(),
        'contract publishes the bounded structural-rtl-ir declared-link entry key family',
    );
    is_deeply(
        normalized_semantic_structural_rtl_ir_declared_link_entry_keys(),
        normalized_semantic_structural_rtl_ir_link_entry_keys(),
        'structural-rtl-ir declared-link entry keys reuse the shared link entry shape',
    );
    is_deeply(
        $contract->{resolved_link_entry_keys},
        normalized_semantic_structural_rtl_ir_resolved_link_entry_keys(),
        'contract publishes the bounded structural-rtl-ir resolved-link entry key family',
    );
    is_deeply(
        normalized_semantic_structural_rtl_ir_resolved_link_entry_keys(),
        normalized_semantic_structural_rtl_ir_link_entry_keys(),
        'structural-rtl-ir resolved-link entry keys reuse the shared link entry shape',
    );
    is_deeply(
        $contract->{instance_entry_keys},
        normalized_semantic_structural_rtl_ir_instance_entry_keys(),
        'contract publishes the bounded structural-rtl-ir instance shallow entry key family',
    );
    is_deeply(
        normalized_semantic_structural_rtl_ir_instance_entry_keys(),
        [qw(instance_name interface_ports kind module_name parameter_overrides port_bindings source_name)],
        'structural-rtl-ir instance shallow entry keys stay exact and ordered',
    );
    is_deeply(
        $contract->{instance_interface_port_entry_keys},
        normalized_semantic_structural_rtl_ir_instance_interface_port_entry_keys(),
        'contract publishes the bounded structural-rtl-ir instance interface-port entry key family',
    );
    is_deeply(
        normalized_semantic_structural_rtl_ir_instance_interface_port_entry_keys(),
        normalized_semantic_structural_rtl_ir_port_entry_keys(),
        'structural-rtl-ir instance interface-port keys reuse the structural port core shape',
    );
    is_deeply(
        $contract->{instance_parameter_override_entry_keys},
        normalized_semantic_structural_rtl_ir_instance_parameter_override_entry_keys(),
        'contract publishes the bounded structural-rtl-ir instance parameter-override core entry key family',
    );
    is_deeply(
        normalized_semantic_structural_rtl_ir_instance_parameter_override_entry_keys(),
        [qw(name origin_kind raw_value_ast value_kind value_payload value_text)],
        'structural-rtl-ir instance parameter-override core entry keys stay exact and ordered',
    );
    is_deeply(
        $contract->{instance_parameter_override_raw_value_extension_keys},
        normalized_semantic_structural_rtl_ir_instance_parameter_override_raw_value_extension_keys(),
        'contract publishes the bounded structural-rtl-ir instance parameter-override raw-value extension key family',
    );
    is_deeply(
        normalized_semantic_structural_rtl_ir_instance_parameter_override_raw_value_extension_keys(),
        [qw(raw_value)],
        'structural-rtl-ir instance parameter-override raw-value extension keys stay exact and ordered',
    );
    is_deeply(
        $contract->{instance_parameter_override_value_metadata_extension_keys},
        normalized_semantic_structural_rtl_ir_instance_parameter_override_value_metadata_extension_keys(),
        'contract publishes the bounded structural-rtl-ir instance parameter-override value-metadata extension key family',
    );
    is_deeply(
        normalized_semantic_structural_rtl_ir_instance_parameter_override_value_metadata_extension_keys(),
        [qw(declaration_default_value_kind declaration_default_value_width value_type_spec value_width)],
        'structural-rtl-ir instance parameter-override value-metadata extension keys stay exact and ordered',
    );
    is_deeply(
        $contract->{instance_port_binding_entry_keys},
        normalized_semantic_structural_rtl_ir_instance_port_binding_entry_keys(),
        'contract publishes the bounded structural-rtl-ir instance port-binding core entry key family',
    );
    is_deeply(
        normalized_semantic_structural_rtl_ir_instance_port_binding_entry_keys(),
        [qw(connection_expr port_name signal_name)],
        'structural-rtl-ir instance port-binding core entry keys stay exact and ordered',
    );
    is_deeply(
        $contract->{instance_port_binding_typed_extension_keys},
        normalized_semantic_structural_rtl_ir_instance_port_binding_typed_extension_keys(),
        'contract publishes the bounded structural-rtl-ir instance port-binding typed extension key family',
    );
    is_deeply(
        normalized_semantic_structural_rtl_ir_instance_port_binding_typed_extension_keys(),
        [qw(connection_type_spec)],
        'structural-rtl-ir instance port-binding typed extension keys stay exact and ordered',
    );
    is_deeply(
        $contract->{presence_key_family_map},
        normalized_semantic_structural_rtl_ir_presence_key_family_map(),
        'contract publishes the grouped structural-rtl-ir key-family map',
    );
    is_deeply(
        $contract->{presence_key_family_map}{port_entry_keys},
        normalized_semantic_structural_rtl_ir_port_entry_keys(),
        'grouped structural-rtl-ir family map publishes port entry keys',
    );
    is_deeply(
        $contract->{presence_key_family_map}{port_composition_extension_keys},
        normalized_semantic_structural_rtl_ir_port_composition_extension_keys(),
        'grouped structural-rtl-ir family map publishes port composition extension keys',
    );
    is_deeply(
        $contract->{presence_key_family_map}{net_entry_keys},
        normalized_semantic_structural_rtl_ir_net_entry_keys(),
        'grouped structural-rtl-ir family map publishes net entry keys',
    );
    is_deeply(
        $contract->{presence_key_family_map}{net_source_entry_keys},
        normalized_semantic_structural_rtl_ir_net_source_entry_keys(),
        'grouped structural-rtl-ir family map publishes net source entry keys',
    );
    is_deeply(
        $contract->{presence_key_family_map}{net_target_entry_keys},
        normalized_semantic_structural_rtl_ir_net_target_entry_keys(),
        'grouped structural-rtl-ir family map publishes net target entry keys',
    );
    is_deeply(
        $contract->{presence_key_family_map}{declared_link_entry_keys},
        normalized_semantic_structural_rtl_ir_declared_link_entry_keys(),
        'grouped structural-rtl-ir family map publishes declared-link entry keys',
    );
    is_deeply(
        $contract->{presence_key_family_map}{resolved_link_entry_keys},
        normalized_semantic_structural_rtl_ir_resolved_link_entry_keys(),
        'grouped structural-rtl-ir family map publishes resolved-link entry keys',
    );
    is_deeply(
        $contract->{presence_key_family_map}{instance_entry_keys},
        normalized_semantic_structural_rtl_ir_instance_entry_keys(),
        'grouped structural-rtl-ir family map publishes instance shallow entry keys',
    );
    is_deeply(
        $contract->{presence_key_family_map}{instance_interface_port_entry_keys},
        normalized_semantic_structural_rtl_ir_instance_interface_port_entry_keys(),
        'grouped structural-rtl-ir family map publishes instance interface-port entry keys',
    );
    is_deeply(
        $contract->{presence_key_family_map}{instance_parameter_override_entry_keys},
        normalized_semantic_structural_rtl_ir_instance_parameter_override_entry_keys(),
        'grouped structural-rtl-ir family map publishes instance parameter-override core entry keys',
    );
    is_deeply(
        $contract->{presence_key_family_map}{instance_parameter_override_raw_value_extension_keys},
        normalized_semantic_structural_rtl_ir_instance_parameter_override_raw_value_extension_keys(),
        'grouped structural-rtl-ir family map publishes instance parameter-override raw-value extension keys',
    );
    is_deeply(
        $contract->{presence_key_family_map}{instance_parameter_override_value_metadata_extension_keys},
        normalized_semantic_structural_rtl_ir_instance_parameter_override_value_metadata_extension_keys(),
        'grouped structural-rtl-ir family map publishes instance parameter-override value-metadata extension keys',
    );
    is_deeply(
        $contract->{presence_key_family_map}{instance_port_binding_entry_keys},
        normalized_semantic_structural_rtl_ir_instance_port_binding_entry_keys(),
        'grouped structural-rtl-ir family map publishes instance port-binding core entry keys',
    );
    is_deeply(
        $contract->{presence_key_family_map}{instance_port_binding_typed_extension_keys},
        normalized_semantic_structural_rtl_ir_instance_port_binding_typed_extension_keys(),
        'grouped structural-rtl-ir family map publishes instance port-binding typed extension keys',
    );
    is_deeply(
        $contract->{presence_key_family_map}{auxiliary_assignment_entry_value_kinds},
        normalized_semantic_structural_rtl_ir_auxiliary_assignment_entry_value_kinds(),
        'grouped structural-rtl-ir family map publishes auxiliary-assignment entry value kinds',
    );
    is_deeply(
        $contract->{presence_key_family_map}{assignment_record_entry_keys},
        normalized_semantic_structural_rtl_ir_assignment_record_entry_keys(),
        'grouped structural-rtl-ir family map publishes assignment-record entry keys',
    );
    is_deeply(
        $contract->{presence_key_family_map}{assignment_record_lhs_entry_keys},
        normalized_semantic_structural_rtl_ir_assignment_record_lhs_entry_keys(),
        'grouped structural-rtl-ir family map publishes assignment-record lhs entry keys',
    );
    is_deeply(
        $contract->{presence_key_family_map}{assignment_record_rhs_entry_keys},
        normalized_semantic_structural_rtl_ir_assignment_record_rhs_entry_keys(),
        'grouped structural-rtl-ir family map publishes assignment-record rhs entry keys',
    );
    is_deeply(
        $contract->{presence_key_family_map}{assignment_record_provenance_entry_keys},
        normalized_semantic_structural_rtl_ir_assignment_record_provenance_entry_keys(),
        'grouped structural-rtl-ir family map publishes assignment-record provenance keys',
    );
};

done_testing();
