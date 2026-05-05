#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use File::Spec;
use FindBin;

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');
use lib File::Spec->catdir($FindBin::Bin, 'lib');

use FSM::Support::CheckResultContract qw(
    build_check_result_contract
    check_result_identity_keys
    check_result_presence_key_family_map
    check_result_presence_keys
    check_result_summary_keys
);
use FSM::Test::DefensiveCopyAudit qw(
    contains_sentinel
    mutate_structure
);

my $sentinel = '__mutated_by_t456__';

subtest 'check result contract builder returns fresh nested structures' => sub {
    my $first = build_check_result_contract();
    mutate_structure($first, $sentinel);

    my $second = build_check_result_contract();
    ok(!contains_sentinel($second, $sentinel), 'fresh check result contract is not affected by prior caller mutation');
    is_deeply(
        $second->{public_presence_keys},
        check_result_presence_keys(),
        'fresh contract public result keys match helper',
    );
    is_deeply($second->{identity_keys}, check_result_identity_keys(), 'fresh contract identity keys match helper');
    is_deeply($second->{summary_keys}, check_result_summary_keys(), 'fresh contract summary keys match helper');
    is_deeply(
        $second->{presence_key_family_map},
        check_result_presence_key_family_map(),
        'fresh contract presence family map matches helper',
    );
};

subtest 'check result helper builders return fresh nested structures' => sub {
    for my $case (
        {
            label => 'presence_keys',
            build => \&check_result_presence_keys,
        },
        {
            label => 'identity_keys',
            build => \&check_result_identity_keys,
        },
        {
            label => 'summary_keys',
            build => \&check_result_summary_keys,
        },
        {
            label => 'presence_key_family_map',
            build => \&check_result_presence_key_family_map,
        },
    ) {
        my $first = $case->{build}->();
        mutate_structure($first, $sentinel);

        my $second = $case->{build}->();
        ok(!contains_sentinel($second, $sentinel), "$case->{label} returns fresh nested structures");
    }
};

subtest 'fresh check result grouped map stays aligned with helper families' => sub {
    my $family_map = check_result_presence_key_family_map();

    is_deeply($family_map->{identity_keys}, check_result_identity_keys(), 'identity family entry matches helper');
    is_deeply($family_map->{summary_keys}, check_result_summary_keys(), 'summary family entry matches helper');
};

done_testing();
