package FSM::Support::HDLGeneratorFacadeContract;

use strict;
use warnings;

use Exporter 'import';
use JSON::PP ();

use FSM::Support::DebugRuntimeContract qw(
    debug_runtime_contract_source
    debug_runtime_numeric_trace_level_range
);
use FSM::Support::ExtensionContract qw(
    extension_contract_source
);
use FSM::Support::HDLGeneratorResultContract qw(
    hdl_generator_result_contract_source
);

our @EXPORT_OK = qw(
    build_hdl_generator_facade_contract
    hdl_generator_facade_constructor_option_family_map
    hdl_generator_facade_constructor_option_shape_map
    hdl_generator_facade_contract_source
    hdl_generator_facade_compatibility_constructor_option_names
    hdl_generator_facade_core_constructor_option_names
    hdl_generator_facade_debug_level_numeric_range
    hdl_generator_facade_direct_extension_option_names
    hdl_generator_facade_method_names
    hdl_generator_facade_public_constructor_option_names
    hdl_generator_facade_public_top_level_keys
    hdl_generator_facade_target_language_names
);

sub hdl_generator_facade_contract_source {
    return 'FSM::Support::HDLGeneratorFacadeContract';
}

sub build_hdl_generator_facade_contract {
    return {
        schema_version => 1,
        status => 'bounded_public',
        contract_source => hdl_generator_facade_contract_source(),
        implementation_owners => [
            'FSM::Pipeline::HDLGenerator',
            'FSM::Pipeline::SourceGenerationOrchestrator',
        ],
        entrypoints => {
            manifest => './bin/fsmgen --capability-manifest -> embedding.hdl_generator_facade',
            in_process => [
                'FSM::Pipeline::HDLGenerator->new(%args)',
                'FSM::Pipeline::HDLGenerator->generate_hdl_from_file($path)',
            ],
        },
        public_top_level_presence_keys => hdl_generator_facade_public_top_level_keys(),
        method_names => hdl_generator_facade_method_names(),
        public_constructor_option_names => hdl_generator_facade_public_constructor_option_names(),
        core_constructor_option_names => hdl_generator_facade_core_constructor_option_names(),
        compatibility_constructor_option_names => hdl_generator_facade_compatibility_constructor_option_names(),
        direct_extension_option_names => hdl_generator_facade_direct_extension_option_names(),
        constructor_option_family_map => hdl_generator_facade_constructor_option_family_map(),
        constructor_option_shape_map => hdl_generator_facade_constructor_option_shape_map(),
        constructor_argument_list_shape => 'even-length list of scalar non-empty option-name/value pairs after class invocant',
        constructor_unknown_option_policy => 'reject unsupported constructor option names before debug-state setup',
        debug_level_numeric_range => hdl_generator_facade_debug_level_numeric_range(),
        default_target_language => 'systemverilog',
        target_language_names => hdl_generator_facade_target_language_names(),
        constructor_receiver_shape => 'scalar FSM::Pipeline::HDLGenerator class name',
        generation_receiver_shape => 'blessed FSM::Pipeline::HDLGenerator object',
        generation_receiver_instance_shape => 'exact hash-backed FSM::Pipeline::HDLGenerator instance constructed by new(...) with required facade state',
        generation_argument_list_shape => 'exactly one source-path argument after object invocant',
        generation_argument_shape => 'scalar filesystem path to a .fsm source root',
        result_contract_source => hdl_generator_result_contract_source(),
        direct_extension_contract_source => extension_contract_source(),
        debug_runtime_contract_source => debug_runtime_contract_source(),
        stateful_reuse_supported => JSON::PP::true,
        result_surface_json_safe_as_a_whole => JSON::PP::false,
        object_injection_args_public => JSON::PP::false,
        object_injection_arg_policy => 'non-public owner-injection values fail closed when present and must be blessed objects providing required owner methods',
        guidance => [
            'Treat this contract as the bounded public in-process facade around FSM::Pipeline::HDLGenerator constructor and generate_hdl_from_file(...) entrypoints.',
            'Use the grouped constructor_option_family_map to discover the bounded public constructor option families without scraping POD or freezing every currently accepted owner-injection argument.',
            'Use constructor_receiver_shape, constructor_argument_list_shape, and constructor_option_shape_map for the bounded shape contract of the public constructor boundary.',
            'Constructor arguments after the class invocant are validated as option/value pairs with scalar non-empty option names before Perl hash coercion can reinterpret malformed input.',
            'Unsupported constructor option names are rejected before facade debug-state setup rather than being silently ignored.',
            'Owner-injection constructor options remain non-public; if internal callers supply them, malformed values are rejected before facade state is constructed or lower-level owner methods are invoked.',
            'Use debug_level_numeric_range for the accepted facade constructor debug_level range.',
            'Use target_language_names for the accepted lower-case target-language tokens at the facade constructor boundary.',
            'Use generation_receiver_shape, generation_argument_list_shape, and generation_argument_shape for the bounded generate_hdl_from_file(...) method boundary.',
            'Generation receivers must be exact hash-backed FSM::Pipeline::HDLGenerator facade instances constructed by new(...) with the required internal facade state, not subclasses or manually blessed stand-ins.',
            'Generation arguments after the object invocant are validated as exactly one source-path argument before Perl signature or lower-level source-opening diagnostics can reinterpret malformed calls.',
            'Follow result_contract_source for the returned compatibility-heavy result hash, direct_extension_contract_source for typed extension loading and hook semantics, and debug_runtime_contract_source for the explicit process-global debug save/restore seam.',
            'The current bounded constructor surface covers the core runtime generation options, compatibility presentation state such as quiet, plus direct extension-object injection and supports stateful pipeline reuse across multiple generation calls.',
            'The quiet option is accepted by the in-process facade for constructor/API compatibility, but CLI presentation output remains owned by bin/fsmgen rather than by generate_hdl_from_file(...).',
            'Widen this facade contract only when additional constructor or method seams are explicitly documented and regression-backed.',
        ],
    };
}

sub hdl_generator_facade_public_top_level_keys {
    return [
        qw(
            schema_version
            status
            contract_source
            implementation_owners
            entrypoints
            public_top_level_presence_keys
            method_names
            public_constructor_option_names
            core_constructor_option_names
            compatibility_constructor_option_names
            direct_extension_option_names
            constructor_option_family_map
            constructor_option_shape_map
            constructor_argument_list_shape
            constructor_unknown_option_policy
            debug_level_numeric_range
            default_target_language
            target_language_names
            constructor_receiver_shape
            generation_receiver_shape
            generation_receiver_instance_shape
            generation_argument_list_shape
            generation_argument_shape
            result_contract_source
            direct_extension_contract_source
            debug_runtime_contract_source
            stateful_reuse_supported
            result_surface_json_safe_as_a_whole
            object_injection_args_public
            object_injection_arg_policy
            guidance
        ),
    ];
}

sub hdl_generator_facade_method_names {
    return [
        qw(
            new
            generate_hdl_from_file
        ),
    ];
}

sub hdl_generator_facade_core_constructor_option_names {
    return [
        qw(
            debug_level
            target_language
            strict_mode
            source_search_paths
        ),
    ];
}

sub hdl_generator_facade_compatibility_constructor_option_names {
    return [
        qw(
            quiet
        ),
    ];
}

sub hdl_generator_facade_direct_extension_option_names {
    return [
        qw(
            extensions
        ),
    ];
}

sub hdl_generator_facade_public_constructor_option_names {
    return [
        qw(
            debug_level
            target_language
            quiet
            strict_mode
            source_search_paths
            extensions
        ),
    ];
}

sub hdl_generator_facade_target_language_names {
    return [
        qw(
            systemverilog
            sv
            verilog
            v
            vhdl
        ),
    ];
}
sub hdl_generator_facade_constructor_option_family_map {
    return {
        core_constructor_option_names => hdl_generator_facade_core_constructor_option_names(),
        compatibility_constructor_option_names => hdl_generator_facade_compatibility_constructor_option_names(),
        direct_extension_option_names => hdl_generator_facade_direct_extension_option_names(),
    };
}
sub hdl_generator_facade_constructor_option_shape_map {
    return {
        debug_level => 'integer in debug_level_numeric_range',
        target_language => 'one of target_language_names',
        quiet => 'boolean scalar 0 or 1',
        strict_mode => 'boolean scalar 0 or 1',
        source_search_paths => 'array reference of scalar non-empty filesystem search roots',
        extensions => 'array reference of blessed typed-extension objects',
    };
}
sub hdl_generator_facade_debug_level_numeric_range {
    return debug_runtime_numeric_trace_level_range();
}

1;
