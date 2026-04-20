#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use File::Spec;
use FindBin;

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::Support::HDLGeneratorRawASTContract qw(
    build_hdl_generator_raw_ast_contract
    hdl_generator_raw_ast_summary_surfaces
    hdl_generator_raw_ast_value_shape
);

subtest 'contract exposes the bounded HDLGenerator raw_ast branch' => sub {
    my $contract = build_hdl_generator_raw_ast_contract();

    is($contract->{schema_version}, 1, 'contract exposes schema version');
    is($contract->{status}, 'bounded_public', 'contract marks the nested raw_ast branch as bounded public');
    is(
        $contract->{contract_source},
        'FSM::Support::HDLGeneratorRawASTContract',
        'contract records its own owner',
    );
    is($contract->{object_name}, 'raw_ast', 'contract records the nested object name');
    is(
        $contract->{parent_object_name},
        'HDLGeneratorResult.raw_ast',
        'contract records the nested parent path',
    );
    is_deeply(
        $contract->{report_sources},
        [
            qw(
                FSM::Pipeline::HDLGenerator
            ),
        ],
        'contract records the in-process producer that reuses the nested raw_ast branch',
    );
    ok(
        $contract->{shell_only},
        'contract records raw_ast as shell-only',
    );
    is(
        $contract->{raw_value_shape},
        hdl_generator_raw_ast_value_shape(),
        'contract records the raw_ast value shape',
    );
    ok(
        !$contract->{full_hash_stable},
        'contract does not claim the whole raw_ast branch is stable',
    );
    ok(
        !$contract->{json_safe_as_whole},
        'contract does not claim the whole raw_ast branch is JSON-safe',
    );
    is_deeply(
        $contract->{summary_surfaces},
        hdl_generator_raw_ast_summary_surfaces(),
        'contract publishes the bounded semantic summary surfaces for raw_ast consumers',
    );
};

done_testing();
