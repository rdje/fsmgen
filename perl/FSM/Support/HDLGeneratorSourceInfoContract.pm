package FSM::Support::HDLGeneratorSourceInfoContract;

use strict;
use warnings;

use Exporter 'import';
use JSON::PP ();

our @EXPORT_OK = qw(
    build_hdl_generator_source_info_contract
    hdl_generator_source_info_identity_keys
    hdl_generator_source_info_stable_subsurfaces
    hdl_generator_source_info_summary_keys
);

sub build_hdl_generator_source_info_contract {
    return {
        schema_version => 1,
        status => 'bounded_public',
        contract_source => 'FSM::Support::HDLGeneratorSourceInfoContract',
        object_name => 'source_info',
        parent_object_name => 'HDLGeneratorResult.source_info',
        report_sources => [
            qw(
                FSM::Pipeline::HDLGenerator
            ),
        ],
        entrypoints => {
            in_process => [
                'FSM::Pipeline::HDLGenerator->new(...)->generate_hdl_from_file($path)->{source_info}',
            ],
        },
        identity_presence_keys => hdl_generator_source_info_identity_keys(),
        summary_presence_keys => hdl_generator_source_info_summary_keys(),
        stable_subsurfaces => hdl_generator_source_info_stable_subsurfaces(),
        full_hash_stable => JSON::PP::false,
        json_safe_as_whole => JSON::PP::false,
        guidance => [
            q{Treat this contract as the bounded nested `source_info` object reused by in-process `HDLGenerator` results.},
            'The bounded public promise covers the current source identity keys plus the package-import summary keys.',
            'The wider source_info hash remains compatibility-heavy on composition roots, so callers should target the advertised stable subsurfaces instead of treating the whole hash as public API.',
        ],
    };
}

sub hdl_generator_source_info_identity_keys {
    return [qw(
        header
        kind
    )];
}

sub hdl_generator_source_info_summary_keys {
    return [qw(
        package_import_count
        package_import_names
    )];
}

sub hdl_generator_source_info_stable_subsurfaces {
    return [
        qw(
            source_info.header
            source_info.kind
            source_info.package_import_count
            source_info.package_import_names
        ),
    ];
}

1;
