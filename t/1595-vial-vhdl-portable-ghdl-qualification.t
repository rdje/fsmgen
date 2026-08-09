#!/usr/bin/env perl

use strict;
use warnings;
use File::Spec;
use FindBin;
use JSON::PP ();
use Test::More;

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::VIAL::Backend::VHDLPortableGHDLQualification;

my $repo_root = File::Spec->catdir($FindBin::Bin, '..');
my $provider_root = FSM::VIAL::Backend::VHDLPortableGHDLQualification
    ->default_provider_root;
my $provider_binary = repo_path("$provider_root/bin/ghdl");
my $checked_report = repo_path(
    'vial/qualification/vhdl_portable_ghdl/ghdl-6.0.0-qualification.json');

subtest 'checked qualification report is closed and records the exact profile' => sub {
    plan skip_all => 'checked qualification report has not been generated yet'
        unless -f $checked_report;
    my $report = JSON::PP->new->decode(slurp_raw($checked_report));
    is_deeply([sort keys %$report],
        [sort @{FSM::VIAL::Backend::VHDLPortableGHDLQualification->report_keys}],
        'qualification report is closed');
    is($report->{schema}, 'fsmgen.vial_vhdl_portable_ghdl_qualification.v1',
        'qualification schema is exact');
    is($report->{status}, 'qualified', 'checked report is qualified');
    is($report->{tool_profile}{qualified_version}, '6.0.0',
        'tool version is exact');
    is($report->{tool_profile}{backend}, 'llvm_jit',
        'only the working external-name-capable LLVM-JIT backend is selected');
    is($report->{provider}{archive_sha256},
        'c21312d5a0cc5833e6d8690d8c4343e67f4fc32f070c07343816cd11a31c7769',
        'official release archive digest is exact');
    is($report->{execution}{analysis}, 'passed', 'analysis passed');
    is($report->{execution}{fixture_elaboration}, 'passed',
        'fixture elaboration passed');
    is($report->{execution}{fixture_execution}, 'passed',
        'fixture execution passed');
    is($report->{trace}{status}, 'closed_validated', 'trace is closed and validated');
    is($report->{result}{status}, 'pass', 'normalized result passed');
    ok($report->{deterministic_rerun}{fixture_stdout_identical},
        'fixture rerun is byte-identical');
    ok($report->{deterministic_rerun}{four_state_stdout_identical},
        'four-state rerun is byte-identical');
    ok($report->{portable_sv_parity}{equivalent},
        'applicable portable-SystemVerilog outcomes are equivalent');
    ok($report->{cleanup}{removed} && $report->{cleanup}{same_volume},
        'repository-local qualification staging was removed on the same volume');
};

subtest 'installed exact provider reproduces the checked qualification' => sub {
    plan skip_all => 'exact repository-local GHDL 6.0.0 LLVM-JIT provider is absent'
        unless -x $provider_binary && -f $checked_report;
    my $result = FSM::VIAL::Backend::VHDLPortableGHDLQualification->qualify({
        repo_root => $repo_root,
        provider_root => $provider_root,
    });
    ok($result->{ok}, 'exact provider qualification succeeds')
        or diag(JSON::PP->new->canonical->encode($result->{diagnostics}));
    is($result->{status}, 'qualified', 'live status is qualified');
    is($result->{content}, slurp_raw($checked_report),
        'live exact rerun reproduces the checked report byte for byte');
    ok(!-e repo_path($result->{cleanup}{staging_identity}),
        'live qualification leaves no staging residue');
};

subtest 'invocation and provider identity fail closed' => sub {
    my $unknown = FSM::VIAL::Backend::VHDLPortableGHDLQualification->qualify({
        repo_root => $repo_root,
        provider_root => $provider_root,
        extra => 1,
    });
    ok(!$unknown->{ok}, 'unknown invocation key fails');
    is($unknown->{diagnostics}[0]{code},
        'VIAL_VHDL_QUALIFICATION_INVOCATION_ERROR',
        'unknown-key diagnostic is exact');
    my $wrong = FSM::VIAL::Backend::VHDLPortableGHDLQualification->qualify({
        repo_root => $repo_root,
        provider_root => '.artifacts/cache/providers/ghdl/6.0.0/other',
    });
    ok(!$wrong->{ok}, 'different provider root fails');
    is($wrong->{diagnostics}[0]{code},
        'VIAL_VHDL_QUALIFICATION_PATH_ERROR',
        'provider-root diagnostic is exact');
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
