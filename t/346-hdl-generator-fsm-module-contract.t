#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use File::Spec;
use FindBin;

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::Support::HDLGeneratorFSMModuleContract qw(
    build_hdl_generator_fsm_module_contract
    hdl_generator_fsm_module_contract_source
    hdl_generator_fsm_module_fallback_surface_map
    hdl_generator_fsm_module_raw_value_class_when_defined
    hdl_generator_fsm_module_summary_surfaces
);

subtest 'contract exposes the bounded HDLGenerator fsm_module branch' => sub {
    my $contract = build_hdl_generator_fsm_module_contract();

    is($contract->{schema_version}, 1, 'contract exposes schema version');
    is($contract->{status}, 'bounded_public', 'contract marks the nested fsm_module branch as bounded public');
    is(
        $contract->{contract_source},
        hdl_generator_fsm_module_contract_source(),
        'contract records its own owner',
    );
    is($contract->{object_name}, 'fsm_module', 'contract records the nested object name');
    is(
        $contract->{parent_object_name},
        'HDLGeneratorResult.fsm_module',
        'contract records the nested parent path',
    );
    is_deeply(
        $contract->{report_sources},
        [
            qw(
                FSM::Pipeline::HDLGenerator
            ),
        ],
        'contract records the in-process producer that reuses the nested fsm_module branch',
    );
    ok(
        $contract->{shell_only},
        'contract records fsm_module as shell-only',
    );
    ok(
        $contract->{value_may_be_undef},
        'contract records that fsm_module may be undef',
    );
    is(
        $contract->{raw_value_class_when_defined},
        hdl_generator_fsm_module_raw_value_class_when_defined(),
        'contract records the raw fsm_module value class when defined',
    );
    ok(
        !$contract->{full_hash_stable},
        'contract does not claim the whole fsm_module branch is stable',
    );
    ok(
        !$contract->{json_safe_as_whole},
        'contract does not claim the whole fsm_module branch is JSON-safe',
    );
    is_deeply(
        $contract->{summary_surfaces},
        hdl_generator_fsm_module_summary_surfaces(),
        'contract publishes the bounded semantic summary surfaces for fsm_module consumers',
    );
    is_deeply(
        $contract->{fallback_surface_map},
        hdl_generator_fsm_module_fallback_surface_map(),
        'contract publishes the grouped fallback-surface families for fsm_module consumers',
    );
};

done_testing();
