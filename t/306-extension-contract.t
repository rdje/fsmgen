#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use File::Spec;
use FindBin;

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::Extension::Context;
use FSM::Extension::Registry;
use FSM::Pipeline::HDLGenerator;
use FSM::Support::ExtensionContract qw(
    build_extension_contract
    extension_contract_context_accessors
    extension_contract_hook_names
    extension_contract_loader_constructor_option_names
    extension_contract_name_family_map
    extension_contract_public_top_level_keys
    extension_contract_registry_constructor_option_names
    extension_contract_source
    extension_contract_supported_source_kinds
);

{
    package Test::ExtensionContractRecorder;

    use strict;
    use warnings;

    sub new {
        return bless {
            parse_records => [],
            result_records => [],
        }, shift;
    }

    sub after_parse_source {
        my ($self, $context) = @_;
        push @{$self->{parse_records}}, _snapshot_context($context);
    }

    sub after_generate_result {
        my ($self, $context) = @_;
        push @{$self->{result_records}}, _snapshot_context($context);
    }

    sub parse_records { return shift->{parse_records} }
    sub result_records { return shift->{result_records} }

    sub _snapshot_context {
        my ($context) = @_;
        return {
            stage => $context->stage,
            pipeline_class => ref($context->pipeline),
            source_path => $context->source_path,
            target_language => $context->target_language,
            source_kind => $context->source_info->{kind},
            raw_ast_ref => ref($context->raw_ast) || '',
            result_ref => ref($context->result) || '',
            result_module_name => (
                ref($context->result) eq 'HASH'
                    ? $context->result->{module_info}{module_name}
                    : undef
            ),
        };
    }
}

my $repo_root = File::Spec->catdir($FindBin::Bin, '..');
my $contract = build_extension_contract();

subtest 'contract declares the bounded typed-extension surface' => sub {
    is($contract->{schema_version}, 1, 'contract exposes schema version');
    is($contract->{status}, 'bounded_public', 'contract marks typed extensions as bounded public');
    is($contract->{contract_source}, extension_contract_source(), 'contract records its owner');
    is_deeply(
        $contract->{public_top_level_presence_keys},
        extension_contract_public_top_level_keys(),
        'contract publishes the bounded typed-extension top-level keys',
    );
    is_deeply(
        [sort @{$contract->{public_top_level_presence_keys}}],
        [sort keys %{$contract}],
        'contract top-level presence list covers every emitted typed-extension contract key',
    );
    is_deeply(
        $contract->{name_family_map},
        extension_contract_name_family_map(),
        'contract publishes the grouped extension name families',
    );
    ok($contract->{extension_object_contract}{must_be_blessed_object}, 'contract requires extension objects');
    ok(
        $contract->{extension_object_contract}{must_provide_supported_hook_method},
        'contract requires extension objects to provide at least one supported hook method',
    );
    is(
        $contract->{extension_object_contract}{supported_hook_method_policy},
        'extension objects must provide at least one real supported hook method discoverable by UNIVERSAL::can',
        'contract records the supported-hook method policy',
    );
    is(
        $contract->{extension_object_contract}{loader_constructor_receiver_shape},
        'scalar FSM::Extension::Loader class name',
        'contract records the direct loader constructor receiver shape',
    );
    is(
        $contract->{extension_object_contract}{loader_constructor_argument_list_shape},
        'no option/value arguments after class invocant',
        'contract records the direct loader constructor argument-list shape',
    );
    is_deeply(
        sorted($contract->{extension_object_contract}{loader_constructor_supported_option_names}),
        sorted(extension_contract_loader_constructor_option_names()),
        'contract records the supported direct loader constructor option names',
    );
    is(
        $contract->{extension_object_contract}{registry_constructor_receiver_shape},
        'scalar FSM::Extension::Registry class name',
        'contract records the direct registry constructor receiver shape',
    );
    is(
        $contract->{extension_object_contract}{registry_constructor_argument_list_shape},
        'even-length list of unique scalar non-empty supported option-name/value pairs after class invocant',
        'contract records the direct registry constructor argument-list shape',
    );
    is_deeply(
        sorted($contract->{extension_object_contract}{registry_constructor_supported_option_names}),
        sorted(extension_contract_registry_constructor_option_names()),
        'contract records the supported direct registry constructor option names',
    );
    is(
        $contract->{extension_object_contract}{registry_dispatch_context_shape},
        'FSM::Extension::Context object whose stage matches the dispatched hook name',
        'contract records the direct registry dispatch context shape',
    );
    is(
        $contract->{context_contract}{constructor_receiver_shape},
        'scalar FSM::Extension::Context class name',
        'contract records the context constructor receiver shape',
    );
    is(
        $contract->{context_contract}{constructor_argument_list_shape},
        'even-length list of unique scalar non-empty supported option-name/value pairs after class invocant',
        'contract records the context constructor argument-list shape',
    );
    is_deeply(
        sorted($contract->{context_contract}{constructor_supported_option_names}),
        sorted(extension_contract_context_accessors()),
        'contract records the supported context constructor option names',
    );
    is(
        $contract->{context_contract}{constructor_stage_shape},
        'supported hook stage name',
        'contract records the context constructor stage shape',
    );
    is(
        $contract->{context_contract}{constructor_common_payload_shape},
        'blessed pipeline object, scalar non-empty source_path, scalar non-empty target_language, and source_info hash with scalar non-empty kind',
        'contract records the context constructor common payload shape',
    );
    is(
        $contract->{context_contract}{constructor_stage_payload_shape},
        'after_parse_source requires raw_ast ARRAY and no result; after_generate_result requires result HASH and no raw_ast',
        'contract records the context constructor stage payload shape',
    );
    is(
        $contract->{extension_object_contract}{constructor_for_module_loading},
        'new()',
        'contract records the module-loading constructor boundary',
    );
    is(
        $contract->{extension_object_contract}{module_name_shape},
        'scalar Module::Name value',
        'contract records the programmatic module-name entry shape',
    );
    is(
        $contract->{extension_object_contract}{config_file_path_shape},
        'scalar non-empty extension config file path',
        'contract records the programmatic config-file path entry shape',
    );
    ok(!$contract->{extension_object_contract}{legacy_plg_discovery}, 'contract keeps legacy .plg discovery out');
    ok(!$contract->{extension_object_contract}{autoload_hook_dispatch}, 'contract keeps AUTOLOAD dispatch out');
    ok(!$contract->{full_extension_api_frozen}, 'contract does not overpromise that all future extension API is frozen');

    my %hooks = map { $_ => 1 } @{$contract->{hook_names}};
    ok($hooks{after_parse_source}, 'contract includes after_parse_source hook');
    ok($hooks{after_generate_result}, 'contract includes after_generate_result hook');

    my %accessors = map { $_ => 1 } @{$contract->{context_accessors}};
    for my $accessor (qw(stage pipeline source_path target_language source_info raw_ast result)) {
        ok($accessors{$accessor}, "contract includes context accessor $accessor");
    }

    is_deeply(
        $contract->{supported_source_kinds},
        extension_contract_supported_source_kinds(),
        'contract publishes the bounded supported source kinds',
    );

    ok($contract->{hooks}{after_parse_source}{raw_ast_available}, 'parse hook advertises raw AST availability');
    ok(!$contract->{hooks}{after_parse_source}{result_available}, 'parse hook does not advertise result availability');
    ok(!$contract->{hooks}{after_generate_result}{raw_ast_available}, 'result hook does not advertise raw AST availability');
    ok($contract->{hooks}{after_generate_result}{result_available}, 'result hook advertises result availability');
    ok($contract->{hooks}{after_generate_result}{result_mutation_allowed}, 'result hook advertises result augmentation');
};

subtest 'declared hooks and context accessors exist on implementation classes' => sub {
    can_ok('FSM::Extension::Registry', @{extension_contract_hook_names()});
    can_ok('FSM::Extension::Context', @{extension_contract_context_accessors()});
};

subtest 'live hook contexts match the advertised contract across source kinds' => sub {
    my $recorder = Test::ExtensionContractRecorder->new();
    my $pipeline = FSM::Pipeline::HDLGenerator->new(
        debug_level => 0,
        target_language => 'systemverilog',
        strict_mode => 1,
        quiet => 1,
        extensions => [$recorder],
    );

    my $direct_result = $pipeline->generate_hdl_from_file(repo_file('fsm/apb_requester.fsm'));
    is($direct_result->{module_info}{module_name}, 'apb_requester', 'direct fixture generated successfully');

    my $composition_result = $pipeline->generate_hdl_from_file(repo_file('fsm/apb_tb.fsm'));
    is($composition_result->{module_info}{module_name}, 'apb_tb', 'composition fixture generated successfully');

    is(scalar(@{$recorder->parse_records}), 2, 'parse hook ran once for each generated source');
    is(scalar(@{$recorder->result_records}), 2, 'result hook ran once for each generated source');

    assert_parse_record($recorder->parse_records->[0], 'fsm', 'fsm/apb_requester.fsm');
    assert_parse_record($recorder->parse_records->[1], 'composition', 'fsm/apb_tb.fsm');

    assert_result_record($recorder->result_records->[0], 'fsm', 'apb_requester');
    assert_result_record($recorder->result_records->[1], 'composition', 'apb_tb');
};

done_testing();

sub repo_file {
    my ($relpath) = @_;
    return File::Spec->catfile($repo_root, split m{/}, $relpath);
}

sub assert_parse_record {
    my ($record, $source_kind, $relpath) = @_;
    is($record->{stage}, 'after_parse_source', "$source_kind parse hook reports stage");
    is($record->{pipeline_class}, 'FSM::Pipeline::HDLGenerator', "$source_kind parse hook reports pipeline class");
    is($record->{target_language}, 'systemverilog', "$source_kind parse hook reports target language");
    is($record->{source_kind}, $source_kind, "$source_kind parse hook reports source kind");
    like($record->{source_path}, qr/\Q$relpath\E\z/, "$source_kind parse hook reports source path");
    is($record->{raw_ast_ref}, 'ARRAY', "$source_kind parse hook receives raw AST");
    is($record->{result_ref}, '', "$source_kind parse hook does not receive result hash");
}

sub assert_result_record {
    my ($record, $source_kind, $module_name) = @_;
    is($record->{stage}, 'after_generate_result', "$source_kind result hook reports stage");
    is($record->{pipeline_class}, 'FSM::Pipeline::HDLGenerator', "$source_kind result hook reports pipeline class");
    is($record->{target_language}, 'systemverilog', "$source_kind result hook reports target language");
    is($record->{source_kind}, $source_kind, "$source_kind result hook reports source kind");
    is($record->{raw_ast_ref}, '', "$source_kind result hook does not receive raw AST");
    is($record->{result_ref}, 'HASH', "$source_kind result hook receives result hash");
    is($record->{result_module_name}, $module_name, "$source_kind result hook receives generated module result");
}

sub sorted {
    my ($values) = @_;
    return [sort @{$values || []}];
}
