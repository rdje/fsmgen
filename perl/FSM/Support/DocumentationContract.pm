package FSM::Support::DocumentationContract;

use strict;
use warnings;

use Exporter 'import';
use JSON::PP ();

our @EXPORT_OK = qw(
    build_documentation_contract
    documentation_contract_source
    documentation_path_contract
    documentation_path_list_contract_map
    documentation_path_list_keys
    documentation_public_top_level_keys
);

sub documentation_contract_source {
    return 'FSM::Support::DocumentationContract';
}

sub build_documentation_contract {
    return {
        schema_version => 1,
        status => 'bounded_public',
        contract_source => documentation_contract_source(),
        report_source => 'FSM::Support::CapabilityManifest',
        entrypoints => {
            cli => './bin/fsmgen --capability-manifest',
            cli_aliases => [
                './bin/fsmgen --emit-capability-manifest',
            ],
            in_process => [
                'FSM::Support::CapabilityManifest::build_capability_manifest()->{documentation}',
            ],
        },
        public_top_level_presence_keys => documentation_public_top_level_keys(),
        path_list_keys => documentation_path_list_keys(),
        path_contract => documentation_path_contract(),
        path_list_contract_map => documentation_path_list_contract_map(),
        guidance => [
            'Treat the published documentation-section top-level keys and path-list fields as the bounded public manifest-facing contract for schema version 1.',
            'Use the grouped path_list_contract_map to discover the bounded path-list families for human_contract and downstream_alignment without collecting those path-list fields separately.',
            'The manifest promises that these fields carry repo-relative Markdown documentation pointers, but it does not freeze the exact list of files forever.',
            'Widen the section deliberately when new machine-readable documentation groupings are documented and regression-backed.',
        ],
    };
}

sub documentation_public_top_level_keys {
    return [
        qw(
            human_contract
            downstream_alignment
            section_contract
        ),
    ];
}

sub documentation_path_list_keys {
    return [
        qw(
            human_contract
            downstream_alignment
        ),
    ];
}

sub documentation_path_contract {
    return {
        repo_relative_paths => JSON::PP::true,
        tracked_markdown_files => JSON::PP::true,
        exact_path_lists_frozen => JSON::PP::false,
    };
}

sub documentation_path_list_contract_map {
    return {
        human_contract => documentation_path_contract(),
        downstream_alignment => documentation_path_contract(),
    };
}

1;
