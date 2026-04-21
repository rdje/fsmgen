#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use File::Spec;
use FindBin;

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::Support::HDLGeneratorResolvedPackageImportsContract qw(
    build_hdl_generator_resolved_package_imports_contract
    hdl_generator_resolved_package_imports_contract_source
    hdl_generator_resolved_package_imports_raw_value_class
    hdl_generator_resolved_package_imports_summary_surface
);

subtest 'contract exposes the bounded HDLGenerator resolved_package_imports branch' => sub {
    my $contract = build_hdl_generator_resolved_package_imports_contract();

    is($contract->{schema_version}, 1, 'contract exposes schema version');
    is($contract->{status}, 'bounded_public', 'contract marks the nested resolved_package_imports branch as bounded public');
    is(
        $contract->{contract_source},
        hdl_generator_resolved_package_imports_contract_source(),
        'contract records its own owner',
    );
    is($contract->{object_name}, 'resolved_package_imports', 'contract records the nested object name');
    is(
        $contract->{parent_object_name},
        'HDLGeneratorResult.resolved_package_imports',
        'contract records the nested parent path',
    );
    is_deeply(
        $contract->{report_sources},
        [
            qw(
                FSM::Pipeline::HDLGenerator
            ),
        ],
        'contract records the in-process producer that reuses the nested resolved_package_imports branch',
    );
    ok(
        $contract->{shell_only},
        'contract records resolved_package_imports as shell-only',
    );
    is($contract->{raw_value_shape}, 'HASH', 'contract records the raw resolved_package_imports value shape');
    is(
        $contract->{raw_value_class},
        hdl_generator_resolved_package_imports_raw_value_class(),
        'contract records the raw resolved_package_imports value class',
    );
    ok(
        !$contract->{full_hash_stable},
        'contract does not claim the whole resolved_package_imports hash is stable',
    );
    ok(
        !$contract->{json_safe_as_whole},
        'contract does not claim the whole resolved_package_imports hash is JSON-safe',
    );
    is_deeply(
        $contract->{summary_surface},
        hdl_generator_resolved_package_imports_summary_surface(),
        'contract publishes the bounded summary surface for package-import inspection',
    );
};

done_testing();
