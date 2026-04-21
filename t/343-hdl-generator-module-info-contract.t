#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use File::Spec;
use FindBin;

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::Support::HDLGeneratorModuleInfoContract qw(
    build_hdl_generator_module_info_contract
    hdl_generator_module_info_contract_source
    hdl_generator_module_info_identity_keys
    hdl_generator_module_info_optional_composition_summary_keys
    hdl_generator_module_info_stable_subsurfaces
    hdl_generator_module_info_summary_keys
);

subtest 'contract exposes the bounded HDLGenerator module_info object' => sub {
    my $contract = build_hdl_generator_module_info_contract();

    is($contract->{schema_version}, 1, 'contract exposes schema version');
    is($contract->{status}, 'bounded_public', 'contract marks the nested module_info object as bounded public');
    is(
        $contract->{contract_source},
        hdl_generator_module_info_contract_source(),
        'contract records its own owner',
    );
    is($contract->{object_name}, 'module_info', 'contract records the nested object name');
    is(
        $contract->{parent_object_name},
        'HDLGeneratorResult.module_info',
        'contract records the nested parent path',
    );
    is_deeply(
        $contract->{report_sources},
        [
            qw(
                FSM::Pipeline::HDLGenerator
            ),
        ],
        'contract records the in-process producer that reuses the nested module_info object',
    );
    ok(
        !$contract->{full_hash_stable},
        'contract does not claim the whole module_info hash is stable',
    );
    ok(
        !$contract->{json_safe_as_whole},
        'contract does not claim the whole module_info hash is JSON-safe',
    );
    is_deeply(
        $contract->{identity_presence_keys},
        hdl_generator_module_info_identity_keys(),
        'contract publishes the bounded module_info identity keys',
    );
    is_deeply(
        $contract->{summary_presence_keys},
        hdl_generator_module_info_summary_keys(),
        'contract publishes the bounded module_info summary keys',
    );
    is_deeply(
        $contract->{optional_composition_summary_keys},
        hdl_generator_module_info_optional_composition_summary_keys(),
        'contract publishes the bounded composition-only module_info summary keys',
    );
    is_deeply(
        $contract->{stable_subsurfaces},
        hdl_generator_module_info_stable_subsurfaces(),
        'contract publishes the bounded stable module_info subsurfaces',
    );
};

done_testing();
