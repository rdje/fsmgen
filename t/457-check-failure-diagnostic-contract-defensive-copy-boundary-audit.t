#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use File::Spec;
use FindBin;

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');
use lib File::Spec->catdir($FindBin::Bin, 'lib');

use FSM::Support::CheckFailureDiagnosticContract qw(
    build_check_failure_diagnostic_contract
    check_failure_diagnostic_matched_presence_keys
    check_failure_diagnostic_optional_artifact_keys
    check_failure_diagnostic_presence_key_family_map
    check_failure_diagnostic_presence_keys
    check_failure_diagnostic_support_accounting_matched_presence_keys
    check_failure_diagnostic_support_accounting_presence_keys
);
use FSM::Test::DefensiveCopyAudit qw(
    contains_sentinel
    mutate_structure
);

my $sentinel = '__mutated_by_t457__';

subtest 'check failure diagnostic contract builder returns fresh nested structures' => sub {
    my $first = build_check_failure_diagnostic_contract();
    mutate_structure($first, $sentinel);

    my $second = build_check_failure_diagnostic_contract();
    ok(!contains_sentinel($second, $sentinel), 'fresh check failure diagnostic contract is not affected by prior caller mutation');
    is_deeply(
        $second->{public_presence_keys},
        check_failure_diagnostic_presence_keys(),
        'fresh contract public diagnostic keys match helper',
    );
    is_deeply(
        $second->{matched_presence_keys},
        check_failure_diagnostic_matched_presence_keys(),
        'fresh contract matched diagnostic keys match helper',
    );
    is_deeply(
        $second->{optional_artifact_keys},
        check_failure_diagnostic_optional_artifact_keys(),
        'fresh contract optional artifact keys match helper',
    );
    is_deeply(
        $second->{support_accounting_presence_keys},
        check_failure_diagnostic_support_accounting_presence_keys(),
        'fresh contract support-accounting keys match helper',
    );
    is_deeply(
        $second->{matched_support_accounting_presence_keys},
        check_failure_diagnostic_support_accounting_matched_presence_keys(),
        'fresh contract matched support-accounting keys match helper',
    );
    is_deeply(
        $second->{presence_key_family_map},
        check_failure_diagnostic_presence_key_family_map(),
        'fresh contract presence family map matches helper',
    );
};

subtest 'check failure diagnostic helper builders return fresh nested structures' => sub {
    for my $case (
        {
            label => 'presence_keys',
            build => \&check_failure_diagnostic_presence_keys,
        },
        {
            label => 'matched_presence_keys',
            build => \&check_failure_diagnostic_matched_presence_keys,
        },
        {
            label => 'optional_artifact_keys',
            build => \&check_failure_diagnostic_optional_artifact_keys,
        },
        {
            label => 'support_accounting_presence_keys',
            build => \&check_failure_diagnostic_support_accounting_presence_keys,
        },
        {
            label => 'matched_support_accounting_presence_keys',
            build => \&check_failure_diagnostic_support_accounting_matched_presence_keys,
        },
        {
            label => 'presence_key_family_map',
            build => \&check_failure_diagnostic_presence_key_family_map,
        },
    ) {
        my $first = $case->{build}->();
        mutate_structure($first, $sentinel);

        my $second = $case->{build}->();
        ok(!contains_sentinel($second, $sentinel), "$case->{label} returns fresh nested structures");
    }
};

subtest 'fresh check failure diagnostic grouped map stays aligned with helper families' => sub {
    my $family_map = check_failure_diagnostic_presence_key_family_map();

    is_deeply($family_map->{public_presence_keys}, check_failure_diagnostic_presence_keys(), 'public family entry matches helper');
    is_deeply(
        $family_map->{matched_presence_keys},
        check_failure_diagnostic_matched_presence_keys(),
        'matched family entry matches helper',
    );
    is_deeply(
        $family_map->{optional_artifact_keys},
        check_failure_diagnostic_optional_artifact_keys(),
        'optional artifact family entry matches helper',
    );
    is_deeply(
        $family_map->{support_accounting_presence_keys},
        check_failure_diagnostic_support_accounting_presence_keys(),
        'support-accounting family entry matches helper',
    );
    is_deeply(
        $family_map->{matched_support_accounting_presence_keys},
        check_failure_diagnostic_support_accounting_matched_presence_keys(),
        'matched support-accounting family entry matches helper',
    );
};

done_testing();
