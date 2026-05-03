#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use File::Spec;
use FindBin;

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::Support::DebugRuntimeContract qw(
    debug_runtime_contract_source
);
use FSM::Support::ExtensionContract qw(
    extension_contract_source
);
use FSM::Support::HDLGeneratorFacadeContract qw(
    build_hdl_generator_facade_contract
    hdl_generator_facade_compatibility_constructor_option_names
    hdl_generator_facade_constructor_option_family_map
    hdl_generator_facade_contract_source
    hdl_generator_facade_core_constructor_option_names
    hdl_generator_facade_direct_extension_option_names
    hdl_generator_facade_method_names
    hdl_generator_facade_public_constructor_option_names
    hdl_generator_facade_public_top_level_keys
);
use FSM::Support::HDLGeneratorResultContract qw(
    hdl_generator_result_contract_source
);

subtest 'contract exposes the bounded HDLGenerator facade seam' => sub {
    my $contract = build_hdl_generator_facade_contract();

    is($contract->{schema_version}, 1, 'contract exposes schema version');
    is($contract->{status}, 'bounded_public', 'contract marks the facade seam as bounded public');
    is(
        $contract->{contract_source},
        hdl_generator_facade_contract_source(),
        'contract records its own owner',
    );
    is_deeply(
        $contract->{implementation_owners},
        [
            'FSM::Pipeline::HDLGenerator',
            'FSM::Pipeline::SourceGenerationOrchestrator',
        ],
        'contract records the current facade implementation owners',
    );
    is_deeply(
        $contract->{public_top_level_presence_keys},
        hdl_generator_facade_public_top_level_keys(),
        'contract publishes the bounded facade top-level keys',
    );
    is_deeply(
        [sort @{$contract->{public_top_level_presence_keys}}],
        [sort keys %{$contract}],
        'contract top-level presence list covers every emitted facade contract key',
    );
    is_deeply(
        $contract->{entrypoints},
        {
            manifest => './bin/fsmgen --capability-manifest -> embedding.hdl_generator_facade',
            in_process => [
                'FSM::Pipeline::HDLGenerator->new(%args)',
                'FSM::Pipeline::HDLGenerator->generate_hdl_from_file($path)',
            ],
        },
        'contract publishes the current manifest and in-process entrypoints',
    );
    is_deeply(
        $contract->{method_names},
        hdl_generator_facade_method_names(),
        'contract publishes the bounded facade method family',
    );
    is_deeply(
        $contract->{public_constructor_option_names},
        hdl_generator_facade_public_constructor_option_names(),
        'contract publishes the bounded public constructor-option family',
    );
    is_deeply(
        $contract->{core_constructor_option_names},
        hdl_generator_facade_core_constructor_option_names(),
        'contract publishes the bounded core constructor-option family',
    );
    is_deeply(
        $contract->{compatibility_constructor_option_names},
        hdl_generator_facade_compatibility_constructor_option_names(),
        'contract publishes the bounded compatibility constructor-option family',
    );
    is_deeply(
        $contract->{direct_extension_option_names},
        hdl_generator_facade_direct_extension_option_names(),
        'contract publishes the bounded direct-extension constructor-option family',
    );
    is_deeply(
        $contract->{constructor_option_family_map},
        hdl_generator_facade_constructor_option_family_map(),
        'contract publishes the grouped constructor-option family map',
    );
    is(
        $contract->{default_target_language},
        'systemverilog',
        'contract records the bounded default target language',
    );
    is(
        $contract->{generation_argument_shape},
        'scalar filesystem path to a .fsm source root',
        'contract records the bounded generation argument shape',
    );
    is(
        $contract->{generation_argument_list_shape},
        'exactly one source-path argument after object invocant',
        'contract records the bounded generation argument-list shape',
    );
    is(
        $contract->{constructor_receiver_shape},
        'scalar FSM::Pipeline::HDLGenerator class name',
        'contract records the bounded constructor receiver shape',
    );
    is(
        $contract->{constructor_argument_list_shape},
        'even-length list of scalar non-empty option-name/value pairs after class invocant',
        'contract records the bounded constructor argument-list shape',
    );
    is(
        $contract->{constructor_unknown_option_policy},
        'reject unsupported constructor option names before debug-state setup',
        'contract records the bounded constructor unknown-option policy',
    );
    is(
        $contract->{generation_receiver_shape},
        'blessed FSM::Pipeline::HDLGenerator object',
        'contract records the bounded generation receiver shape',
    );
    is(
        $contract->{generation_receiver_instance_shape},
        'exact hash-backed FSM::Pipeline::HDLGenerator instance constructed by new(...) with required facade state',
        'contract records the bounded generation receiver instance shape',
    );
    is(
        $contract->{result_contract_source},
        hdl_generator_result_contract_source(),
        'contract points to the bounded result contract owner',
    );
    is(
        $contract->{direct_extension_contract_source},
        extension_contract_source(),
        'contract points to the bounded typed-extension contract owner',
    );
    is(
        $contract->{debug_runtime_contract_source},
        debug_runtime_contract_source(),
        'contract points to the bounded debug-runtime contract owner',
    );
    ok($contract->{stateful_reuse_supported}, 'contract says the facade supports stateful reuse');
    ok(
        !$contract->{result_surface_json_safe_as_a_whole},
        'contract does not claim the whole raw result surface is JSON-safe',
    );
    ok(
        !$contract->{object_injection_args_public},
        'contract does not claim the current owner-injection constructor args are public',
    );
    is(
        $contract->{object_injection_arg_policy},
        'non-public owner-injection values fail closed when present and must be blessed objects providing required owner methods',
        'contract records the bounded non-public owner-injection value policy',
    );
};

done_testing();
