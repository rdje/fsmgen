package FSM::Test::RegressionCorpus;

use strict;
use warnings;

use Exporter 'import';

our @EXPORT_OK = qw(regression_corpus_entries protocol_fixture_entries);

my @REGRESSION_CORPUS = (
    {
        id => 'protocol.apb_requester',
        relpath => 'fsm/apb_requester.fsm',
        family => 'protocol_fixture',
        classification => 'supported_smoke',
        coverage => 'direct_root_pipeline_cli',
        source_kind => 'fsm',
        expected_module_name => 'apb_requester',
    },
    {
        id => 'protocol.apb_completer',
        relpath => 'fsm/apb_completer.fsm',
        family => 'protocol_fixture',
        classification => 'supported_smoke',
        coverage => 'direct_root_pipeline_cli',
        source_kind => 'fsm',
        expected_module_name => 'apb_completer',
    },
    {
        id => 'protocol.amba_requester',
        relpath => 'fsm/amba_requester.fsm',
        family => 'protocol_fixture',
        classification => 'supported_smoke',
        coverage => 'direct_root_pipeline_cli',
        source_kind => 'fsm',
        expected_module_name => 'amba_requester',
    },
    {
        id => 'protocol.apb_tb',
        relpath => 'fsm/apb_tb.fsm',
        family => 'protocol_fixture',
        classification => 'supported_smoke',
        coverage => 'composition_top_pipeline_cli',
        source_kind => 'composition',
        expected_top_name => 'apb_tb',
        expected_lane => 'C4',
        expected_instance_count => 2,
        expected_child_modules => ['apb_requester', 'apb_completer'],
    },
    {
        id => 'feature.partial_lhs_with_size',
        relpath => 't/corpus/partial_lhs_with_size.fsm',
        family => 'language_feature_fixture',
        classification => 'supported_smoke',
        coverage => 'direct_root_pipeline_cli',
        source_kind => 'fsm',
        expected_module_name => 'partial_lhs_with_size',
        expected_hdl_patterns => [
            qr/\bOUT\s*=\s*\{HI,\s*MID,\s*LO\};/s,
            qr/\bROD_next\s*=\s*\{HI,\s*MID,\s*LO\};/s,
            qr/\bRID\s*=\s*\{HI,\s*MID,\s*LO\};/s,
            qr/\boutput\s+reg\s+\[3:0\]\s+next_ROD\b/s,
            qr/\boutput\s+reg\s+\[3:0\]\s+RID_r\b/s,
        ],
    },
    {
        id => 'feature.partial_lhs_inferred_width',
        relpath => 't/corpus/partial_lhs_inferred_width.fsm',
        family => 'language_feature_fixture',
        classification => 'supported_smoke',
        coverage => 'direct_root_pipeline_cli',
        source_kind => 'fsm',
        expected_module_name => 'partial_lhs_inferred_width',
        expected_hdl_patterns => [
            qr/\breg\s+\[3:0\]\s+OUT;/s,
            qr/\boutput\s+reg\s+\[3:0\]\s+next_ROD\b/s,
            qr/\boutput\s+reg\s+\[3:0\]\s+RID_r\b/s,
            qr/\breg\s+\[4:0\]\s+IDXOUT;/s,
            qr/\boutput\s+reg\s+\[4:0\]\s+next_IDXRO\b/s,
            qr/\boutput\s+reg\s+\[4:0\]\s+IDXRI_r\b/s,
        ],
    },
    {
        id => 'legacy.mipicsi2_txccore_ulp.default_compat',
        relpath => 'fsm/mipicsi2_txccore_ulp.fsm',
        family => 'legacy_fixture',
        classification => 'legacy_out_of_scope',
        coverage => 'legacy_root_default_pipeline_cli',
        source_kind => 'fsm',
        expected_module_name => 'mipicsi2_txccore_ulp',
    },
    {
        id => 'legacy.mipicsi2_txccore_ulp.strict_rejection',
        relpath => 'fsm/mipicsi2_txccore_ulp.fsm',
        family => 'legacy_fixture',
        classification => 'expected_failure',
        coverage => 'strict_root_rejection_pipeline_cli',
        source_kind => 'fsm',
        expected_error_pattern => qr/Strict mode rejects the legacy '\+fsm' root family/,
        expected_hint_pattern => qr/\?fsm:module_name/,
    },
    {
        id => 'legacy.empty_size_noop.default_compat',
        relpath => 't/corpus/legacy_empty_size_noop.fsm',
        family => 'legacy_fixture',
        classification => 'legacy_out_of_scope',
        coverage => 'legacy_section_default_pipeline_cli',
        source_kind => 'fsm',
        expected_module_name => 'legacy_empty_size_noop',
    },
    {
        id => 'legacy.empty_size_noop.strict_rejection',
        relpath => 't/corpus/legacy_empty_size_noop.fsm',
        family => 'legacy_fixture',
        classification => 'expected_failure',
        coverage => 'strict_section_rejection_pipeline_cli',
        source_kind => 'fsm',
        expected_error_pattern => qr/Strict mode rejects the legacy empty '\(\+size\)' section/,
        expected_hint_pattern => qr/replace it with explicit '\(\+size \(signal width\) \.\.\.\)' entries/,
    },
    {
        id => 'legacy.fsm_child_root.default_compat',
        relpath => 't/corpus/legacy_fsm_child_root_top.fsm',
        family => 'legacy_fixture',
        classification => 'legacy_out_of_scope',
        coverage => 'legacy_child_root_default_pipeline_cli',
        source_kind => 'composition',
        search_path_relpaths => ['t/corpus'],
        expected_top_name => 'legacy_fsm_child_root_top',
        expected_lane => 'C1',
        expected_instance_count => 1,
        expected_child_modules => ['legacy_fsm_child_root_src'],
    },
    {
        id => 'legacy.fsm_child_root.strict_rejection',
        relpath => 't/corpus/legacy_fsm_child_root_top.fsm',
        family => 'legacy_fixture',
        classification => 'expected_failure',
        coverage => 'strict_child_root_rejection_pipeline_cli',
        source_kind => 'composition',
        search_path_relpaths => ['t/corpus'],
        expected_error_pattern => qr/Generated child source:\s+'\?fsmc' 'legacy_fsm_child_root_src'.*Strict mode rejects the legacy '\+fsm' root family as the root of '\?fsmc' source 'legacy_fsm_child_root_src'/s,
        expected_hint_pattern => qr/\?fsm:source_name/,
    },
    {
        id => 'legacy.dt_child_root.default_compat',
        relpath => 't/corpus/legacy_dt_child_root_top.fsm',
        family => 'legacy_fixture',
        classification => 'legacy_out_of_scope',
        coverage => 'legacy_child_root_default_pipeline_cli',
        source_kind => 'composition',
        search_path_relpaths => ['t/corpus'],
        expected_top_name => 'legacy_dt_child_root_top',
        expected_lane => 'C1',
        expected_instance_count => 1,
        expected_child_modules => ['legacy_dt_child_root_src'],
    },
    {
        id => 'legacy.dt_child_root.strict_rejection',
        relpath => 't/corpus/legacy_dt_child_root_top.fsm',
        family => 'legacy_fixture',
        classification => 'expected_failure',
        coverage => 'strict_child_root_rejection_pipeline_cli',
        source_kind => 'composition',
        search_path_relpaths => ['t/corpus'],
        expected_error_pattern => qr/Generated child source:\s+'\?dtc' 'legacy_dt_child_root_src'.*Strict mode rejects '\?module:legacy_dt_child_root_src' as the root of '\?dtc' source 'legacy_dt_child_root_src'/s,
        expected_hint_pattern => qr/\?dt:source_name/,
    },
    {
        id => 'contract.language_contract_bad_size_entry',
        relpath => 't/corpus/language_contract_bad_size_entry.fsm',
        family => 'language_contract_fixture',
        classification => 'expected_failure',
        coverage => 'language_contract_rejection_pipeline_cli',
        source_kind => 'fsm',
        expected_error_pattern => qr/Malformed '\+size' entry/,
    },
    {
        id => 'contract.missing_rtl_metadata_sidecar',
        relpath => 't/corpus/missing_rtl_metadata_top.fsm',
        family => 'composition_contract_fixture',
        classification => 'expected_failure',
        coverage => 'composition_contract_rejection_pipeline_cli',
        source_kind => 'composition',
        expected_error_pattern => qr/Expected RTL metadata file:\s+'uart_tx\.rtlif'.*RTL child module:\s+'\?rtl' 'uart_tx'.*no declared interface metadata file 'uart_tx\.rtlif' was found/s,
    },
    {
        id => 'contract.missing_fsm_child_source',
        relpath => 't/corpus/missing_fsm_child_source_top.fsm',
        family => 'composition_contract_fixture',
        classification => 'expected_failure',
        coverage => 'composition_contract_rejection_pipeline_cli',
        source_kind => 'composition',
        expected_error_pattern => qr/Expected child source file:\s+'missing_src\.fsm'.*Generated child source:\s+'\?fsmc' 'missing_src'.*child-source resolution is blocked because no active child FSM source was found either embedded in the same file or in an external '\.fsm' file/s,
    },
    {
        id => 'contract.missing_dt_child_source',
        relpath => 't/corpus/missing_dt_child_source_top.fsm',
        family => 'composition_contract_fixture',
        classification => 'expected_failure',
        coverage => 'composition_contract_rejection_pipeline_cli',
        source_kind => 'composition',
        expected_error_pattern => qr/Expected child source file:\s+'missing_dt_src\.fsm'.*Generated child source:\s+'\?dtc' 'missing_dt_src'.*child-source resolution is blocked because no active standalone-DT child source was found either embedded in the same file or in an external '\.fsm' file/s,
    },
);

sub regression_corpus_entries {
    return map { _copy_entry($_) } @REGRESSION_CORPUS;
}

sub protocol_fixture_entries {
    return map { _copy_entry($_) } grep { $_->{family} eq 'protocol_fixture' } @REGRESSION_CORPUS;
}

sub _copy_entry {
    my ($entry) = @_;

    my %copy = %{$entry};
    if (ref $copy{expected_child_modules} eq 'ARRAY') {
        $copy{expected_child_modules} = [@{$copy{expected_child_modules}}];
    }
    if (ref $copy{expected_hdl_patterns} eq 'ARRAY') {
        $copy{expected_hdl_patterns} = [@{$copy{expected_hdl_patterns}}];
    }
    if (ref $copy{search_path_relpaths} eq 'ARRAY') {
        $copy{search_path_relpaths} = [@{$copy{search_path_relpaths}}];
    }

    return \%copy;
}

1;
