#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use File::Spec;
use FindBin;

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');
use lib File::Spec->catdir($FindBin::Bin, 'lib');

use FSM::Support::CheckDiagnosticsContract qw(
    build_check_diagnostics_contract
    check_json_failure_diagnostic_keys
    check_json_failure_diagnostic_optional_artifact_keys
    check_json_failure_diagnostic_support_accounting_keys
    check_json_matched_failure_diagnostic_keys
    check_json_matched_failure_support_accounting_keys
    check_json_matched_success_support_accounting_keys
    check_json_nested_presence_key_map
    check_json_presence_key_family_map
    check_json_public_top_level_keys
    check_json_success_only_top_level_keys
    check_json_success_result_keys
    check_json_success_support_accounting_keys
);
use FSM::Test::DefensiveCopyAudit qw(
    contains_sentinel
    mutate_structure
);

my $sentinel = '__mutated_by_t458__';

subtest 'check diagnostics contract builder returns fresh nested structures' => sub {
    my $first = build_check_diagnostics_contract();
    mutate_structure($first, $sentinel);

    my $second = build_check_diagnostics_contract();
    ok(!contains_sentinel($second, $sentinel), 'fresh check diagnostics contract is not affected by prior caller mutation');
    is_deeply(
        $second->{public_top_level_presence_keys},
        check_json_public_top_level_keys(),
        'fresh contract public top-level keys match helper',
    );
    is_deeply(
        $second->{nested_presence_key_map},
        check_json_nested_presence_key_map(),
        'fresh contract nested presence map matches helper',
    );
    is_deeply(
        $second->{presence_key_family_map},
        check_json_presence_key_family_map(),
        'fresh contract presence family map matches helper',
    );
};

subtest 'check diagnostics helper builders return fresh nested structures' => sub {
    for my $case (
        {
            label => 'public_top_level_keys',
            build => \&check_json_public_top_level_keys,
        },
        {
            label => 'nested_presence_key_map',
            build => \&check_json_nested_presence_key_map,
        },
        {
            label => 'presence_key_family_map',
            build => \&check_json_presence_key_family_map,
        },
        {
            label => 'success_only_top_level_keys',
            build => \&check_json_success_only_top_level_keys,
        },
        {
            label => 'success_result_keys',
            build => \&check_json_success_result_keys,
        },
        {
            label => 'success_support_accounting_keys',
            build => \&check_json_success_support_accounting_keys,
        },
        {
            label => 'matched_success_support_accounting_keys',
            build => \&check_json_matched_success_support_accounting_keys,
        },
        {
            label => 'failure_diagnostic_keys',
            build => \&check_json_failure_diagnostic_keys,
        },
        {
            label => 'matched_failure_diagnostic_keys',
            build => \&check_json_matched_failure_diagnostic_keys,
        },
        {
            label => 'failure_diagnostic_optional_artifact_keys',
            build => \&check_json_failure_diagnostic_optional_artifact_keys,
        },
        {
            label => 'failure_diagnostic_support_accounting_keys',
            build => \&check_json_failure_diagnostic_support_accounting_keys,
        },
        {
            label => 'matched_failure_support_accounting_keys',
            build => \&check_json_matched_failure_support_accounting_keys,
        },
    ) {
        my $first = $case->{build}->();
        mutate_structure($first, $sentinel);

        my $second = $case->{build}->();
        ok(!contains_sentinel($second, $sentinel), "$case->{label} returns fresh nested structures");
    }
};

subtest 'fresh check diagnostics grouped maps stay aligned with helper families' => sub {
    my $nested_map = check_json_nested_presence_key_map();
    my $family_map = check_json_presence_key_family_map();

    is_deeply($nested_map->{result}, check_json_success_result_keys(), 'nested result family entry matches helper');
    is_deeply(
        $nested_map->{support_accounting},
        check_json_success_support_accounting_keys(),
        'nested support-accounting family entry matches helper',
    );
    is_deeply(
        $family_map->{success_only_top_level_keys},
        check_json_success_only_top_level_keys(),
        'success-only family entry matches helper',
    );
    is_deeply(
        $family_map->{failure_diagnostic_presence_keys},
        check_json_failure_diagnostic_keys(),
        'failure diagnostic family entry matches helper',
    );
    is_deeply(
        $family_map->{matched_failure_diagnostic_presence_keys},
        check_json_matched_failure_diagnostic_keys(),
        'matched failure diagnostic family entry matches helper',
    );
    is_deeply(
        $family_map->{failure_diagnostic_optional_artifact_keys},
        check_json_failure_diagnostic_optional_artifact_keys(),
        'failure diagnostic optional-artifact family entry matches helper',
    );
};

done_testing();
