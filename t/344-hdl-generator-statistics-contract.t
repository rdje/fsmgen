#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use File::Spec;
use FindBin;

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::Support::HDLGeneratorStatisticsContract qw(
    build_hdl_generator_statistics_contract
    hdl_generator_statistics_contract_source
    hdl_generator_statistics_optional_composition_keys
    hdl_generator_statistics_stable_subsurfaces
    hdl_generator_statistics_summary_keys
);

subtest 'contract exposes the bounded HDLGenerator statistics object' => sub {
    my $contract = build_hdl_generator_statistics_contract();

    is($contract->{schema_version}, 1, 'contract exposes schema version');
    is($contract->{status}, 'bounded_public', 'contract marks the nested statistics object as bounded public');
    is(
        $contract->{contract_source},
        hdl_generator_statistics_contract_source(),
        'contract records its own owner',
    );
    is($contract->{object_name}, 'statistics', 'contract records the nested object name');
    is(
        $contract->{parent_object_name},
        'HDLGeneratorResult.statistics',
        'contract records the nested parent path',
    );
    is_deeply(
        $contract->{report_sources},
        [
            qw(
                FSM::Pipeline::HDLGenerator
            ),
        ],
        'contract records the in-process producer that reuses the nested statistics object',
    );
    ok(
        !$contract->{full_hash_stable},
        'contract does not claim the whole statistics hash is stable',
    );
    ok(
        !$contract->{json_safe_as_whole},
        'contract does not claim the whole statistics hash is JSON-safe',
    );
    is_deeply(
        $contract->{summary_presence_keys},
        hdl_generator_statistics_summary_keys(),
        'contract publishes the bounded statistics summary keys',
    );
    is_deeply(
        $contract->{optional_composition_summary_keys},
        hdl_generator_statistics_optional_composition_keys(),
        'contract publishes the bounded composition-only statistics summary keys',
    );
    is_deeply(
        $contract->{stable_subsurfaces},
        hdl_generator_statistics_stable_subsurfaces(),
        'contract publishes the bounded stable statistics subsurfaces',
    );
};

done_testing();
