package FSM::Support::HIALVIALBridgeContract;

use strict;
use warnings;

use Exporter 'import';
use JSON::PP ();

our @EXPORT_OK = qw(
    build_hial_vial_bridge_contract
    hial_vial_bridge_contract_keys
    hial_vial_bridge_contract_source
);

sub hial_vial_bridge_contract_source {
    return 'FSM::Support::HIALVIALBridgeContract';
}

sub hial_vial_bridge_contract_keys {
    return [qw(
        schema_version
        status
        contract_source
        implementation_entrypoints
        manifest_schema
        profile
        canonical_review_routes
        capabilities
        limits
        fixture
        writes_files
        public_embedding_api
        explicit_nonclaims
        guidance
    )];
}

sub build_hial_vial_bridge_contract {
    return {
        schema_version => 1,
        status => 'shipped_private_in_process',
        contract_source => hial_vial_bridge_contract_source(),
        implementation_entrypoints => [
            'FSM::HIAL::VIALBridge::Builder->build_ial0({...})',
            'FSM::HIAL::VIALBridge::Builder->build_ial1({...})',
            'FSM::HIAL::VIALBridge::Builder->build_ial2_via_ial1({...})',
            'FSM::HIAL::VIALBridge::Report->build($manifest)',
        ],
        manifest_schema => 'fsmgen.hial_vial_bridge_manifest.v1',
        profile => 'core_single_unit_v1',
        canonical_review_routes => [
            'IAL0 authored .fsm',
            'IAL1 authored .isf -> generated .fsm',
            'IAL2 authored .ppif -> generated and reparsed .isf -> generated .fsm',
        ],
        capabilities => [qw(
            hial_vial.bridge_manifest.v1
            hial_vial.bridge_observation.passive_monitor
            hial_vial.bridge_probe.equivalent_adapter_required
            hial_vial.bridge_profile.core_single_unit_v1
            hial_vial.bridge_protocol.ahb_subordinate_v1
            hial_vial.bridge_qualification.architecture_scale_v1
            hial_vial.bridge_source.ial0
            hial_vial.bridge_source.ial1
            hial_vial.bridge_source.ial2_via_generated_ial1
        )],
        limits => {
            sources => 3,
            review_artifacts => 3,
            units => 1,
            domains => 1,
            configurations => 4096,
            types => 4096,
            endpoints => 4096,
            transactions => 256,
            events => 2048,
            protocols => 16,
            observations => 256,
            probes => 256,
            backend_bindings => 16384,
            unsupported_residue => 4096,
            source_map => 65536,
            serialized_manifest_bytes => 16_777_216,
        },
        fixture => 'ppif/ahb_lite_subordinate.ppif',
        writes_files => JSON::PP::false,
        public_embedding_api => JSON::PP::false,
        explicit_nonclaims => [qw(
            vial_binding
            execution_plan
            verification_artifact_generation
            compile
            simulation
            result
            parity
            uvm
            vhdl_methodology
            mixed_language
            scale
        )],
        guidance => [
            'Consume this contract only for capability discovery; the bridge producer remains a private in-process compiler seam.',
            'Use logical bridge IDs and compiler-proved facts, never backend names or target-language casts, as semantic authority.',
            'Do not infer a public VIAL API, execution plan, backend, runtime, or parity result from bridge availability.',
        ],
    };
}

1;
