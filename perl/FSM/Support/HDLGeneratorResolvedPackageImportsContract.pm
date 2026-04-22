package FSM::Support::HDLGeneratorResolvedPackageImportsContract;

use strict;
use warnings;

use Exporter 'import';
use JSON::PP ();

our @EXPORT_OK = qw(
    build_hdl_generator_resolved_package_imports_contract
    hdl_generator_resolved_package_imports_contract_source
    hdl_generator_resolved_package_imports_fallback_surface_map
    hdl_generator_resolved_package_imports_raw_value_class
    hdl_generator_resolved_package_imports_summary_surface
);

sub hdl_generator_resolved_package_imports_contract_source {
    return 'FSM::Support::HDLGeneratorResolvedPackageImportsContract';
}

sub build_hdl_generator_resolved_package_imports_contract {
    return {
        schema_version => 1,
        status => 'bounded_public',
        contract_source => hdl_generator_resolved_package_imports_contract_source(),
        object_name => 'resolved_package_imports',
        parent_object_name => 'HDLGeneratorResult.resolved_package_imports',
        report_sources => [
            qw(
                FSM::Pipeline::HDLGenerator
            ),
        ],
        entrypoints => {
            in_process => [
                'FSM::Pipeline::HDLGenerator->new(...)->generate_hdl_from_file($path)->{resolved_package_imports}',
            ],
        },
        shell_only => JSON::PP::true,
        raw_value_shape => 'HASH',
        raw_value_class => hdl_generator_resolved_package_imports_raw_value_class(),
        summary_surface => hdl_generator_resolved_package_imports_summary_surface(),
        fallback_surface_map => hdl_generator_resolved_package_imports_fallback_surface_map(),
        full_hash_stable => JSON::PP::false,
        json_safe_as_whole => JSON::PP::false,
        guidance => [
            q{Treat this contract as the bounded shell-only `resolved_package_imports` branch reused by in-process `HDLGenerator` results.},
            'The branch remains a hash of raw FSM::Package::Spec objects kept for in-process compatibility rather than a JSON-safe public interchange payload.',
            'Use source_info.package_import_count and source_info.package_import_names for stable package-import inspection instead of traversing the raw package-spec values as public API.',
            'Use the grouped fallback_surface_map to discover the bounded source_info package-import fallback surfaces without collecting those paths separately.',
        ],
    };
}

sub hdl_generator_resolved_package_imports_raw_value_class {
    return 'FSM::Package::Spec';
}

sub hdl_generator_resolved_package_imports_summary_surface {
    return [
        'source_info.package_import_count',
        'source_info.package_import_names',
    ];
}

sub hdl_generator_resolved_package_imports_fallback_surface_map {
    return {
        source_info_package_import_summary => hdl_generator_resolved_package_imports_summary_surface(),
    };
}

1;
