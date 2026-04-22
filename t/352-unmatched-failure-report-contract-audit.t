#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use File::Spec;
use FindBin;

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::Support::CheckDiagnostics qw(
    build_check_failure_report
);
use FSM::Support::NormalizedSemanticReport qw(
    build_normalized_semantic_failure_report
);
use FSM::Support::CheckDiagnosticsContract qw(
    build_check_diagnostics_contract
    check_json_failure_diagnostic_keys
    check_json_failure_diagnostic_support_accounting_keys
    check_json_matched_failure_diagnostic_keys
    check_json_matched_failure_support_accounting_keys
    check_json_public_top_level_keys
);
use FSM::Support::NormalizedSemanticReportContract qw(
    build_normalized_semantic_report_contract
    normalized_semantic_failure_diagnostic_keys
    normalized_semantic_failure_diagnostic_support_accounting_keys
    normalized_semantic_matched_failure_diagnostic_keys
    normalized_semantic_matched_failure_diagnostic_support_accounting_keys
    normalized_semantic_matched_failure_support_accounting_keys
    normalized_semantic_public_top_level_keys
    normalized_semantic_support_accounting_keys
);

my $repo_root = File::Spec->catdir($FindBin::Bin, '..');
my $source_path = File::Spec->catfile($repo_root, 'fsm', 'apb_requester.fsm');
my $ad_hoc_message = 'Ad hoc unmatched failure for public contract audit';

subtest 'check failure builder keeps the bounded unmatched-failure shape' => sub {
    my $contract = build_check_diagnostics_contract();
    my $report = build_check_failure_report(
        input => 'ad_hoc_unmatched_failure',
        source_file => $source_path,
        target_language => 'systemverilog',
        strict_mode => 1,
        message => $ad_hoc_message,
    );

    assert_keys_present(
        $report,
        check_json_public_top_level_keys(),
        'unmatched check failure keeps bounded top-level keys',
    );
    ok(!$report->{success}, 'unmatched check failure keeps success false');
    ok(!exists $report->{support_accounting}, 'unmatched check failure omits success-only report-level support accounting');
    is(scalar(@{$report->{diagnostics} || []}), 1, 'unmatched check failure keeps one diagnostic');

    my $diagnostic = $report->{diagnostics}[0];
    assert_keys_present(
        $diagnostic,
        check_json_failure_diagnostic_keys(),
        'unmatched check failure diagnostic keeps bounded public keys',
    );
    assert_keys_present(
        $diagnostic->{support_accounting},
        check_json_failure_diagnostic_support_accounting_keys(),
        'unmatched check failure diagnostic support_accounting keeps bounded common keys',
    );

    ok($contract->{unclassified_failures_use_null_code}, 'check contract advertises null-code unmatched failures');
    ok(exists $diagnostic->{code}, 'unmatched check failure diagnostic still keeps the code key');
    ok(!defined $diagnostic->{code}, 'unmatched check failure diagnostic keeps code as null/undef');
    is($diagnostic->{stability}, 'unclassified', 'unmatched check failure diagnostic keeps unclassified stability');
    is($diagnostic->{family}, 'unclassified', 'unmatched check failure diagnostic keeps unclassified family');
    is($diagnostic->{summary}, 'Unclassified FSMGen failure.', 'unmatched check failure diagnostic keeps fallback summary');
    ok(!$diagnostic->{migration_hint_available}, 'unmatched check failure diagnostic keeps migration_hint_available false');
    ok(!$diagnostic->{support_accounting}{matched}, 'unmatched check failure support_accounting keeps matched false');

    for my $key (@{check_json_matched_failure_diagnostic_keys() || []}) {
        ok(!exists $diagnostic->{$key}, "unmatched check failure omits matched-only diagnostic key $key");
    }
    for my $key (@{check_json_matched_failure_support_accounting_keys() || []}) {
        ok(!exists $diagnostic->{support_accounting}{$key}, "unmatched check failure omits matched-only support_accounting key $key");
    }
};

subtest 'normalized semantic failure builder keeps the bounded unmatched-failure shape' => sub {
    my $contract = build_normalized_semantic_report_contract();
    my $report = build_normalized_semantic_failure_report(
        input => 'ad_hoc_unmatched_failure',
        source_file => $source_path,
        target_language => 'systemverilog',
        strict_mode => 1,
        message => $ad_hoc_message,
    );

    assert_keys_present(
        $report,
        normalized_semantic_public_top_level_keys(),
        'unmatched semantic failure keeps bounded top-level keys',
    );
    ok(!$report->{success}, 'unmatched semantic failure keeps success false');
    ok($contract->{failure_omits_semantic_payload}, 'semantic contract advertises omitted semantic payload on failure');
    ok(!exists $report->{semantic}, 'unmatched semantic failure omits semantic payload');
    assert_keys_present(
        $report->{support_accounting},
        normalized_semantic_support_accounting_keys(),
        'unmatched semantic failure top-level support_accounting keeps bounded common keys',
    );
    ok(!$report->{support_accounting}{matched}, 'unmatched semantic failure top-level support_accounting keeps matched false');
    is(scalar(@{$report->{diagnostics} || []}), 1, 'unmatched semantic failure keeps one diagnostic');

    my $diagnostic = $report->{diagnostics}[0];
    assert_keys_present(
        $diagnostic,
        normalized_semantic_failure_diagnostic_keys(),
        'unmatched semantic failure diagnostic keeps bounded public keys',
    );
    assert_keys_present(
        $diagnostic->{support_accounting},
        normalized_semantic_failure_diagnostic_support_accounting_keys(),
        'unmatched semantic failure diagnostic support_accounting keeps bounded common keys',
    );

    ok(exists $diagnostic->{code}, 'unmatched semantic failure diagnostic still keeps the code key');
    ok(!defined $diagnostic->{code}, 'unmatched semantic failure diagnostic keeps code as null/undef');
    is($diagnostic->{stability}, 'unclassified', 'unmatched semantic failure diagnostic keeps unclassified stability');
    is($diagnostic->{family}, 'unclassified', 'unmatched semantic failure diagnostic keeps unclassified family');
    is($diagnostic->{summary}, 'Unclassified FSMGen failure.', 'unmatched semantic failure diagnostic keeps fallback summary');
    ok(!$diagnostic->{migration_hint_available}, 'unmatched semantic failure diagnostic keeps migration_hint_available false');
    ok(!$diagnostic->{support_accounting}{matched}, 'unmatched semantic failure diagnostic support_accounting keeps matched false');

    for my $key (@{normalized_semantic_matched_failure_support_accounting_keys() || []}) {
        ok(!exists $report->{support_accounting}{$key}, "unmatched semantic failure omits matched-only top-level support_accounting key $key");
    }
    for my $key (@{normalized_semantic_matched_failure_diagnostic_keys() || []}) {
        ok(!exists $diagnostic->{$key}, "unmatched semantic failure omits matched-only diagnostic key $key");
    }
    for my $key (@{normalized_semantic_matched_failure_diagnostic_support_accounting_keys() || []}) {
        ok(!exists $diagnostic->{support_accounting}{$key}, "unmatched semantic failure omits matched-only diagnostic support_accounting key $key");
    }
};

done_testing();

sub assert_keys_present {
    my ($payload, $keys, $label) = @_;
    ok(ref($payload) eq 'HASH', "$label: payload is a hash");
    return unless ref($payload) eq 'HASH';

    for my $key (@{$keys || []}) {
        ok(exists $payload->{$key}, "$label: keeps key $key");
    }
}
