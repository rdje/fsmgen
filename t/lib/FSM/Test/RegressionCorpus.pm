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
        id => 'contract.language_contract_bad_size_entry',
        relpath => 't/corpus/language_contract_bad_size_entry.fsm',
        family => 'language_contract_fixture',
        classification => 'expected_failure',
        coverage => 'language_contract_rejection_pipeline_cli',
        source_kind => 'fsm',
        expected_error_pattern => qr/Malformed '\+size' entry/,
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

    return \%copy;
}

1;
