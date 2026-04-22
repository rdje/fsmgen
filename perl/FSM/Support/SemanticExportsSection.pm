package FSM::Support::SemanticExportsSection;

use strict;
use warnings;

use Exporter 'import';
use JSON::PP ();

use FSM::Support::NormalizedSemanticReportContract qw(
    build_normalized_semantic_report_contract
);
use FSM::Support::SemanticExportsContract qw(build_semantic_exports_contract);

our @EXPORT_OK = qw(
    build_semantic_exports_section
);

sub build_semantic_exports_section {
    return {
        normalized_semantic_json => {
            %{build_normalized_semantic_report_contract()},
            success_match_policy => 'resolved_source_path_to_non_failure_corpus_entry',
            supported_smoke_corpus_covered => JSON::PP::true,
            strict_supported_corpus_covered => JSON::PP::true,
            expected_failure_corpus_covered => JSON::PP::true,
        },
        section_contract => build_semantic_exports_contract(),
    };
}

1;
