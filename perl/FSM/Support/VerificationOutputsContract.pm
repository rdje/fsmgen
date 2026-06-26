package FSM::Support::VerificationOutputsContract;

use strict;
use warnings;

use Exporter 'import';
use JSON::PP ();

our @EXPORT_OK = qw(
    build_verification_outputs_contract
    verification_outputs_artifact_entry_keys
    verification_outputs_artifact_manifest_keys
    verification_outputs_contract_source
    verification_outputs_observation_entry_keys
    verification_outputs_presence_key_family_map
    verification_outputs_public_top_level_keys
    verification_outputs_signal_entry_keys
    verification_outputs_source_keys
    verification_outputs_target_entry_keys
    verification_outputs_validation_keys
);

sub verification_outputs_contract_source {
    return 'FSM::Support::VerificationOutputsContract';
}

sub build_verification_outputs_contract {
    return {
        schema_version => 1,
        status => 'bounded_public',
        contract_source => verification_outputs_contract_source(),
        report_source => 'FSM::Support::CapabilityManifest',
        entrypoints => {
            cli => './bin/fsmgen --capability-manifest',
            in_process => [
                'FSM::Support::CapabilityManifest::build_capability_manifest()->{verification_outputs}',
                'FSM::Support::VerificationOutputsSection::build_verification_outputs_section()',
            ],
        },
        public_top_level_presence_keys => verification_outputs_public_top_level_keys(),
        target_entry_keys => verification_outputs_target_entry_keys(),
        artifact_manifest_keys => verification_outputs_artifact_manifest_keys(),
        artifact_entry_keys => verification_outputs_artifact_entry_keys(),
        observation_entry_keys => verification_outputs_observation_entry_keys(),
        signal_entry_keys => verification_outputs_signal_entry_keys(),
        source_keys => verification_outputs_source_keys(),
        validation_keys => verification_outputs_validation_keys(),
        presence_key_family_map => verification_outputs_presence_key_family_map(),
        json_safe_when_embedded_in_public_manifest => JSON::PP::true,
        guidance => [
            'Treat this section as the bounded public discovery surface for generated verification-output targets.',
            'Generated verification artifact manifests use the advertised manifest, artifact, observation, signal, source, and validation key families.',
            'The first targets are inert observation skeleton artifacts and do not claim UVM, VHDL compile, VHDL syntax, or PSL validation support.',
            'Widen this section only with task-tree-owned implementation and regression coverage for the new verification-output target or manifest field.',
        ],
    };
}

sub verification_outputs_public_top_level_keys {
    return [
        qw(
            schema_version
            status
            contract_source
            report_source
            entrypoints
            public_top_level_presence_keys
            target_entry_keys
            artifact_manifest_keys
            artifact_entry_keys
            observation_entry_keys
            signal_entry_keys
            source_keys
            validation_keys
            presence_key_family_map
            targets
            artifact_manifest
            validation
            section_contract
        ),
    ];
}

sub verification_outputs_target_entry_keys {
    return [
        qw(
            id
            cli_target
            source_suffixes
            requires_verification_observations
            artifact_language
            uvm_version
            artifact_relpath_pattern
            manifest_relpath
            status
        ),
    ];
}

sub verification_outputs_artifact_manifest_keys {
    return [
        qw(
            schema_version
            mode
            target
            source
            actor
            artifacts
            validation
        ),
    ];
}

sub verification_outputs_artifact_entry_keys {
    return [
        qw(
            kind
            language
            uvm_version
            relpath
            package_name
            observations
        ),
    ];
}

sub verification_outputs_observation_entry_keys {
    return [
        qw(
            name
            role
            constant_prefix
            snapshot_class
            monitor_class
            signals
        ),
    ];
}

sub verification_outputs_signal_entry_keys {
    return [
        qw(
            name
            direction
            width
        ),
    ];
}

sub verification_outputs_source_keys {
    return [
        qw(
            resolved_path
            source_kind
        ),
    ];
}

sub verification_outputs_validation_keys {
    return [
        qw(
            claimed_uvm_compile_support
            uvm_compile_validator
            claimed_vhdl_compile_support
            vhdl_syntax_validator
            claimed_psl_support
            psl_validator
            artifact_shape_checked
            inert_behavior_checked
        ),
    ];
}

sub verification_outputs_presence_key_family_map {
    return {
        target_entry_keys => verification_outputs_target_entry_keys(),
        artifact_manifest_keys => verification_outputs_artifact_manifest_keys(),
        artifact_entry_keys => verification_outputs_artifact_entry_keys(),
        observation_entry_keys => verification_outputs_observation_entry_keys(),
        signal_entry_keys => verification_outputs_signal_entry_keys(),
        source_keys => verification_outputs_source_keys(),
        validation_keys => verification_outputs_validation_keys(),
    };
}

1;
