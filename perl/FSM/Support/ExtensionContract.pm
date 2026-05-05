package FSM::Support::ExtensionContract;

use strict;
use warnings;

use Exporter 'import';
use JSON::PP ();

our @EXPORT_OK = qw(
    build_extension_contract
    extension_contract_name_family_map
    extension_contract_public_top_level_keys
    extension_contract_source
    extension_contract_context_accessors
    extension_contract_hook_names
    extension_contract_loader_constructor_option_names
    extension_contract_loader_method_names
    extension_contract_registry_constructor_option_names
    extension_contract_registry_method_names
    extension_contract_supported_source_kinds
);

sub extension_contract_source {
    return 'FSM::Support::ExtensionContract';
}

sub build_extension_contract {
    return {
        schema_version => 1,
        status => 'bounded_public',
        contract_source => extension_contract_source(),
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
            't/380-extension-loading-command-boundary-audit.t',
            't/389-hdl-generator-facade-extensions-boundary-audit.t',
            't/391-typed-extension-programmatic-loading-boundary-audit.t',
            't/392-typed-extension-autoload-boundary-audit.t',
            't/393-typed-extension-hook-set-closed-boundary-audit.t',
            't/394-typed-extension-context-accessor-boundary-audit.t',
            't/395-typed-extension-explicit-discovery-boundary-audit.t',
            't/396-typed-extension-constructor-boundary-audit.t',
            't/397-typed-extension-registry-dispatch-boundary-audit.t',
            't/400-typed-extension-config-line-shape-boundary-audit.t',
            't/401-typed-extension-module-name-shape-boundary-audit.t',
            't/402-typed-extension-constructor-list-shape-boundary-audit.t',
            't/411-typed-extension-programmatic-entry-shape-boundary-audit.t',
            't/421-hdl-generator-facade-extension-hook-method-boundary-audit.t',
            't/422-typed-extension-registry-dispatch-context-boundary-audit.t',
            't/423-typed-extension-context-constructor-argument-boundary-audit.t',
            't/424-typed-extension-context-constructor-payload-boundary-audit.t',
            't/425-typed-extension-dt-source-kind-contract-audit.t',
            't/426-typed-extension-registry-constructor-argument-boundary-audit.t',
            't/427-typed-extension-loader-constructor-argument-boundary-audit.t',
            't/428-typed-extension-loader-method-receiver-boundary-audit.t',
            't/429-typed-extension-registry-method-receiver-boundary-audit.t',
            't/430-typed-extension-context-accessor-receiver-boundary-audit.t',
            't/431-typed-extension-loader-method-argument-list-boundary-audit.t',
            't/432-typed-extension-registry-method-argument-list-boundary-audit.t',
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
            must_provide_supported_hook_method => JSON::PP::true,
            supported_hook_method_policy => 'extension objects must provide at least one real supported hook method discoverable by UNIVERSAL::can',
            loader_constructor_receiver_shape => 'scalar FSM::Extension::Loader class name',
            loader_constructor_argument_list_shape => 'no option/value arguments after class invocant',
            loader_constructor_supported_option_names => extension_contract_loader_constructor_option_names(),
            loader_method_receiver_shape => 'exact hash-backed FSM::Extension::Loader object constructed by new(...)',
            loader_method_argument_list_shape => 'exactly one payload argument after the loader invocant',
            loader_method_names => extension_contract_loader_method_names(),
            registry_constructor_receiver_shape => 'scalar FSM::Extension::Registry class name',
            registry_constructor_argument_list_shape => 'even-length list of unique scalar non-empty supported option-name/value pairs after class invocant',
            registry_constructor_supported_option_names => extension_contract_registry_constructor_option_names(),
            registry_method_receiver_shape => 'exact hash-backed FSM::Extension::Registry object constructed by new(...)',
            registry_method_argument_list_shape => 'extensions takes no payload arguments; dispatch_hook takes hook name and context; hook wrapper methods take one context argument after the registry invocant',
            registry_method_names => extension_contract_registry_method_names(),
            registry_dispatch_context_shape => 'FSM::Extension::Context object whose stage matches the dispatched hook name',
            constructor_for_module_loading => 'new()',
            module_name_shape => 'scalar Module::Name value',
            config_file_path_shape => 'scalar non-empty extension config file path',
            config_line_shape => 'module Module::Name',
            legacy_plg_discovery => JSON::PP::false,
            automatic_directory_discovery => JSON::PP::false,
            autoload_hook_dispatch => JSON::PP::false,
        },
        context_contract => {
            constructor_receiver_shape => 'scalar FSM::Extension::Context class name',
            constructor_argument_list_shape => 'even-length list of unique scalar non-empty supported option-name/value pairs after class invocant',
            constructor_supported_option_names => extension_contract_context_accessors(),
            accessor_receiver_shape => 'exact hash-backed FSM::Extension::Context object constructed by new(...)',
            accessor_method_names => extension_contract_context_accessors(),
            constructor_stage_shape => 'supported hook stage name',
            constructor_common_payload_shape => 'blessed pipeline object, scalar non-empty source_path, scalar non-empty target_language, and source_info hash with scalar non-empty kind',
            constructor_stage_payload_shape => 'after_parse_source requires raw_ast ARRAY and no result; after_generate_result requires result HASH and no raw_ast',
        },
        public_top_level_presence_keys => extension_contract_public_top_level_keys(),
        hook_names => extension_contract_hook_names(),
        context_accessors => extension_contract_context_accessors(),
        name_family_map => extension_contract_name_family_map(),
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
        supported_source_kinds => extension_contract_supported_source_kinds(),
        stable_context_accessor_names => JSON::PP::true,
        hook_set_closed_for_schema_version => JSON::PP::true,
        full_extension_api_frozen => JSON::PP::false,
        guidance => [
            'Treat the listed hook names and context accessor names as the bounded public extension contract.',
            'Use the grouped name_family_map to discover the bounded hook-name, context-accessor, and supported-source-kind families without collecting those name lists separately.',
            'Do not rely on legacy .plg discovery, AUTOLOAD dispatch, or implicit hook discovery.',
            'Use after_generate_result for returned-result augmentation; use normalized semantic JSON for sanitized interchange.',
            'New hook families should be added only when their pipeline seam is stable enough to regression-lock.',
        ],
    };
}

sub extension_contract_public_top_level_keys {
    return [
        qw(
            schema_version
            status
            contract_source
            implementation_owners
            tested_by
            entrypoints
            extension_object_contract
            context_contract
            public_top_level_presence_keys
            hook_names
            context_accessors
            name_family_map
            hooks
            supported_source_kinds
            stable_context_accessor_names
            hook_set_closed_for_schema_version
            full_extension_api_frozen
            guidance
        ),
    ];
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

sub extension_contract_loader_constructor_option_names {
    return [];
}

sub extension_contract_loader_method_names {
    return [
        qw(
            load_modules
            module_names_from_config_file
            module_names_from_config_files
        ),
    ];
}

sub extension_contract_registry_constructor_option_names {
    return [
        qw(extensions)
    ];
}

sub extension_contract_registry_method_names {
    return [
        qw(
            extensions
            dispatch_hook
            after_parse_source
            after_generate_result
        ),
    ];
}

sub extension_contract_supported_source_kinds {
    return [
        qw(fsm dt composition)
    ];
}

sub extension_contract_name_family_map {
    return {
        hook_names => extension_contract_hook_names(),
        context_accessors => extension_contract_context_accessors(),
        supported_source_kinds => extension_contract_supported_source_kinds(),
    };
}

1;
