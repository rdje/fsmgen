#!/usr/bin/env perl

use strict;
use warnings;
use File::Spec;
use FindBin;
use JSON::PP ();
use Test::More;

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::VIAL::Backend::VHDLOSVVMGHDLQualification;

my $repo_root = File::Spec->catdir($FindBin::Bin, '..');
my $ghdl_provider_root = FSM::VIAL::Backend::VHDLOSVVMGHDLQualification
    ->default_ghdl_provider_root;
my $osvvm_dependency_root = FSM::VIAL::Backend::VHDLOSVVMGHDLQualification
    ->default_osvvm_dependency_root;
my $provider_binary = repo_path("$ghdl_provider_root/bin/ghdl");
my $provider_source = repo_path($osvvm_dependency_root);
my $checked_report = repo_path(
    'vial/qualification/vhdl_osvvm_ghdl/osvvm-2026.05-ghdl-6.0.0-qualification.json');

subtest 'checked qualification report closes the exact combined profile' => sub {
    plan skip_all => 'checked combined qualification report has not been generated yet'
        unless -f $checked_report;
    my $report = JSON::PP->new->decode(slurp_raw($checked_report));
    is_deeply([sort keys %$report],
        [sort @{FSM::VIAL::Backend::VHDLOSVVMGHDLQualification->report_keys}],
        'qualification report is closed');
    is($report->{schema}, 'fsmgen.vial_vhdl_osvvm_ghdl_qualification.v1',
        'qualification schema is exact');
    is($report->{status}, 'qualified', 'combined profile is qualified');
    is($report->{backend_profile}, 'vhdl_osvvm_qualified',
        'backend profile is exact');
    is($report->{tool_profile}{qualified_version}, '6.0.0',
        'tool version is exact');
    is($report->{tool_profile}{backend}, 'llvm_jit',
        'only the qualified GHDL backend is selected');
    is($report->{provider_profile}{version}, '2026.05',
        'provider version is exact');
    is($report->{provider_profile}{root_commit},
        '2f7c391051dfb11890fa4bdbda9918d1db492250',
        'provider root commit is exact');
    is($report->{provider_profile}{repository_count}, 14,
        'complete recursive provider graph is recorded');
    is($report->{provider_profile}{recursive_gitlink_count}, 13,
        'all recursive gitlinks are recorded');
    is($report->{provider_compilation}{osvvm_analyzed_source_count}, 44,
        'OSVVM core compile order is complete');
    is($report->{provider_compilation}{common_analyzed_source_count}, 17,
        'OSVVM Common compile order is complete');
    is($report->{provider_compilation}{total_analyzed_source_count}, 61,
        'all selected provider sources were analyzed');
    is(scalar(@{$report->{commands}{provider_analyze}}), 61,
        'every provider analysis command is closed in the report');
    is($report->{execution}{adapter_analysis}, 'passed',
        'generated provider adapter analyzed');
    is($report->{execution}{generated_fixture_analysis}, 'passed',
        'generated fixture analyzed');
    is($report->{execution}{fixture_elaboration}, 'passed',
        'generated fixture elaborated');
    is($report->{execution}{fixture_execution}, 'passed',
        'generated fixture executed');
    is($report->{trace}{status}, 'closed_validated',
        'portable trace is closed and validated');
    is($report->{trace}{record_count}, 42,
        'portable trace retains its exact record count');
    is($report->{result}{status}, 'pass',
        'normalized semantic result passed');
    ok($report->{deterministic_rerun}{fixture_stdout_identical},
        'fixture rerun is byte-identical');
    ok($report->{deterministic_rerun}{provider_stdout_identical},
        'provider-probe rerun is byte-identical');
    ok($report->{deterministic_rerun}{provider_reports_identical},
        'supplementary provider reports rerun byte-identically');
    ok($report->{portable_result_parity}{equivalent},
        'applicable portable-result paths are equivalent');
    is(scalar(@{$report->{portable_result_parity}{compared_paths}}), 19,
        'portable parity compares the exact bounded path set');
    is($report->{supplementary_provider_reports}{report_count}, 4,
        'all four supplementary OSVVM reports are recorded');
    is($report->{supplementary_provider_reports}{alert_status},
        'passed_three_affirmations_zero_errors',
        'OSVVM alert report is exact');
    is($report->{supplementary_provider_reports}{coverage_status},
        'passed_one_of_four_bins_25_percent',
        'OSVVM coverage report is exact');
    is($report->{supplementary_provider_reports}{scoreboard_status},
        'passed_one_checked_item_zero_errors',
        'OSVVM scoreboard report is exact');
    is($report->{capability_support}{product_support},
        'qualified_private_fixture_profile_not_public_api',
        'support truth remains bounded and private');
    ok($report->{cleanup}{removed} && $report->{cleanup}{same_volume}
        && $report->{cleanup}{provider_tree_clean},
        'same-volume staging is removed and the provider stays clean');
};

subtest 'installed exact tuple reproduces the checked qualification' => sub {
    plan skip_all => 'exact repository-local provider/tool tuple is absent'
        unless -x $provider_binary && -d $provider_source && -f $checked_report;
    my $result = FSM::VIAL::Backend::VHDLOSVVMGHDLQualification->qualify({
        repo_root => $repo_root,
        ghdl_provider_root => $ghdl_provider_root,
        osvvm_dependency_root => $osvvm_dependency_root,
    });
    ok($result->{ok}, 'exact combined qualification succeeds')
        or diag(JSON::PP->new->canonical->encode($result->{diagnostics}));
    is($result->{status}, 'qualified', 'live status is qualified');
    is($result->{content}, slurp_raw($checked_report),
        'live exact rerun reproduces the checked report byte for byte');
    ok(!-e repo_path($result->{cleanup}{staging_identity}),
        'live qualification leaves no staging residue');
};

subtest 'invocation and provider identities fail closed' => sub {
    my $unknown = FSM::VIAL::Backend::VHDLOSVVMGHDLQualification->qualify({
        repo_root => $repo_root,
        ghdl_provider_root => $ghdl_provider_root,
        osvvm_dependency_root => $osvvm_dependency_root,
        extra => 1,
    });
    ok(!$unknown->{ok}, 'unknown invocation key fails');
    is($unknown->{diagnostics}[0]{code},
        'VIAL_OSVVM_GHDL_QUALIFICATION_INVOCATION_ERROR',
        'unknown-key diagnostic is exact');

    my $wrong_ghdl = FSM::VIAL::Backend::VHDLOSVVMGHDLQualification->qualify({
        repo_root => $repo_root,
        ghdl_provider_root => '.artifacts/cache/providers/ghdl/6.0.0/other',
        osvvm_dependency_root => $osvvm_dependency_root,
    });
    ok(!$wrong_ghdl->{ok}, 'different GHDL root fails');
    is($wrong_ghdl->{diagnostics}[0]{code},
        'VIAL_OSVVM_GHDL_QUALIFICATION_PATH_ERROR',
        'GHDL-root diagnostic is exact');

    my $wrong_osvvm = FSM::VIAL::Backend::VHDLOSVVMGHDLQualification->qualify({
        repo_root => $repo_root,
        ghdl_provider_root => $ghdl_provider_root,
        osvvm_dependency_root => '.artifacts/cache/providers/osvvm/other/source',
    });
    ok(!$wrong_osvvm->{ok}, 'different OSVVM root fails');
    is($wrong_osvvm->{diagnostics}[0]{code},
        'VIAL_OSVVM_GHDL_QUALIFICATION_PATH_ERROR',
        'OSVVM-root diagnostic is exact');
};

done_testing();

sub repo_path {
    return File::Spec->catfile($repo_root, split m{/}, $_[0]);
}

sub slurp_raw {
    open my $fh, '<:raw', $_[0] or die "cannot read $_[0]: $!";
    local $/;
    my $text = <$fh>;
    close $fh;
    return $text;
}

exit 0;
