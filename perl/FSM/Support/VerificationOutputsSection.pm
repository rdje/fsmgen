package FSM::Support::VerificationOutputsSection;

use strict;
use warnings;

use Exporter 'import';
use JSON::PP ();

use FSM::Support::VerificationOutputsContract qw(build_verification_outputs_contract);

our @EXPORT_OK = qw(build_verification_outputs_section);

sub build_verification_outputs_section {
    my $contract = build_verification_outputs_contract();

    return {
        %{$contract},
        targets => [
            {
                id => 'uvm_passive_monitor_skeleton',
                cli_target => 'uvm-passive-monitor',
                source_suffixes => ['.isf'],
                requires_verification_observations => JSON::PP::true,
                artifact_language => 'systemverilog',
                uvm_version => '1.2',
                artifact_relpath_pattern => 'uvm/<actor>_observation_uvm_pkg.sv',
                manifest_relpath => 'verification-output-manifest.json',
                status => 'shipped_bounded_public',
            },
            {
                id => 'vhdl_observation_package_skeleton',
                cli_target => 'vhdl-observation-package',
                source_suffixes => ['.isf'],
                requires_verification_observations => JSON::PP::true,
                artifact_language => 'vhdl',
                artifact_relpath_pattern => 'vhdl/<actor>_observation_vhdl_pkg.vhd',
                manifest_relpath => 'verification-output-manifest.json',
                status => 'shipped_bounded_public',
            },
        ],
        artifact_manifest => {
            schema_version => 1,
            manifest_relpath => 'verification-output-manifest.json',
            public_top_level_presence_keys => $contract->{artifact_manifest_keys},
            artifact_entry_keys => $contract->{artifact_entry_keys},
            observation_entry_keys => $contract->{observation_entry_keys},
            signal_entry_keys => $contract->{signal_entry_keys},
            source_keys => $contract->{source_keys},
            validation_keys => $contract->{validation_keys},
        },
        validation => {
            claimed_uvm_compile_support => JSON::PP::false,
            uvm_compile_validator => 'none',
            claimed_vhdl_compile_support => JSON::PP::false,
            vhdl_syntax_validator => 'none',
            claimed_psl_support => JSON::PP::false,
            psl_validator => 'none',
            validation_scope => 'artifact_shape_and_inert_behavior',
        },
        section_contract => $contract,
    };
}

1;
