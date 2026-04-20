#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use File::Spec;
use FindBin;

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::Support::HDLGeneratorSourceInfoContract qw(
    build_hdl_generator_source_info_contract
    hdl_generator_source_info_identity_keys
    hdl_generator_source_info_stable_subsurfaces
    hdl_generator_source_info_summary_keys
);

subtest 'contract exposes the bounded HDLGenerator source_info object' => sub {
    my $contract = build_hdl_generator_source_info_contract();

    is($contract->{schema_version}, 1, 'contract exposes schema version');
    is($contract->{status}, 'bounded_public', 'contract marks the nested source_info object as bounded public');
    is(
        $contract->{contract_source},
        'FSM::Support::HDLGeneratorSourceInfoContract',
        'contract records its own owner',
    );
    is($contract->{object_name}, 'source_info', 'contract records the nested object name');
    is(
        $contract->{parent_object_name},
        'HDLGeneratorResult.source_info',
        'contract records the nested parent path',
    );
    is_deeply(
        $contract->{report_sources},
        [
            qw(
                FSM::Pipeline::HDLGenerator
            ),
        ],
        'contract records the in-process producer that reuses the nested source_info object',
    );
    ok(
        !$contract->{full_hash_stable},
        'contract does not claim the whole source_info hash is stable',
    );
    ok(
        !$contract->{json_safe_as_whole},
        'contract does not claim the whole source_info hash is JSON-safe',
    );
    is_deeply(
        $contract->{identity_presence_keys},
        hdl_generator_source_info_identity_keys(),
        'contract publishes the bounded source_info identity keys',
    );
    is_deeply(
        $contract->{summary_presence_keys},
        hdl_generator_source_info_summary_keys(),
        'contract publishes the bounded source_info summary keys',
    );
    is_deeply(
        $contract->{stable_subsurfaces},
        hdl_generator_source_info_stable_subsurfaces(),
        'contract publishes the bounded stable source_info subsurfaces',
    );
};

done_testing();
