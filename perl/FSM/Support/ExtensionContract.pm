package FSM::Support::ExtensionContract;

use strict;
use warnings;

use Exporter 'import';
use JSON::PP ();

our @EXPORT_OK = qw(
    build_extension_contract
    extension_contract_context_accessors
    extension_contract_hook_names
);

sub build_extension_contract {
    return {
        schema_version => 1,
        status => 'bounded_public',
        contract_source => 'FSM::Support::ExtensionContract',
        implementation_owners => [
            'FSM::Extension::Context',
            'FSM::Extension::Registry',
            'FSM::Extension::Loader',
            'FSM::Pipeline::HDLGenerator',
        ],
        tested_by => [
            't/26-extension-mechanism.t',
            't/27-extension-loading.t',
            't/28-extension-config-loading.t',
            't/252-extension-diagnostic-context.t',
            't/253-extension-loader-diagnostic-context.t',
            't/306-extension-contract.t',
        ],
        entrypoints => {
            programmatic_objects => 'FSM::Pipeline::HDLGenerator->new(extensions => [ $object, ... ])',
            programmatic_modules => 'FSM::Pipeline::HDLGenerator->new(extension_modules => [ "Module::Name", ... ])',
            programmatic_config_files => 'FSM::Pipeline::HDLGenerator->new(extension_config_files => [ "extensions.fsmext", ... ])',
            cli_modules => './bin/fsmgen --extension-module Module::Name path/to/file.fsm',
            cli_config_files => './bin/fsmgen --extension-config extensions.fsmext path/to/file.fsm',
        },
        extension_object_contract => {
            must_be_blessed_object => JSON::PP::true,
            constructor_for_module_loading => 'new()',
            config_line_shape => 'module Module::Name',
            legacy_plg_discovery => JSON::PP::false,
            automatic_directory_discovery => JSON::PP::false,
            autoload_hook_dispatch => JSON::PP::false,
        },
        hook_names => extension_contract_hook_names(),
        context_accessors => extension_contract_context_accessors(),
        hooks => {
            after_parse_source => {
                timing => 'after parse/classification and before source lowering or HDL generation',
                context_accessors => [
                    qw(stage pipeline source_path target_language source_info raw_ast)
                ],
                raw_ast_available => JSON::PP::true,
                result_available => JSON::PP::false,
                intended_use => [
                    'source-frontier inspection',
                    'early validation',
                    'telemetry',
                ],
            },
            after_generate_result => {
                timing => 'after generation result assembly and before the caller receives the result',
                context_accessors => [
                    qw(stage pipeline source_path target_language source_info result)
                ],
                raw_ast_available => JSON::PP::false,
                result_available => JSON::PP::true,
                result_mutation_allowed => JSON::PP::true,
                intended_use => [
                    'result inspection',
                    'metadata augmentation',
                    'reporting',
                    'telemetry',
                ],
            },
        },
        supported_source_kinds => [
            qw(fsm composition)
        ],
        stable_context_accessor_names => JSON::PP::true,
        hook_set_closed_for_schema_version => JSON::PP::true,
        full_extension_api_frozen => JSON::PP::false,
        guidance => [
            'Treat the listed hook names and context accessor names as the bounded public extension contract.',
            'Do not rely on legacy .plg discovery, AUTOLOAD dispatch, or implicit hook discovery.',
            'Use after_generate_result for returned-result augmentation; use normalized semantic JSON for sanitized interchange.',
            'New hook families should be added only when their pipeline seam is stable enough to regression-lock.',
        ],
    };
}

sub extension_contract_hook_names {
    return [
        qw(after_parse_source after_generate_result)
    ];
}

sub extension_contract_context_accessors {
    return [
        qw(stage pipeline source_path target_language source_info raw_ast result)
    ];
}

1;
