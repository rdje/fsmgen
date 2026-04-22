#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use File::Spec;
use FindBin;

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::Support::CheckDiagnostics qw(
    build_check_failure_report
    build_check_success_report
);
use FSM::Support::NormalizedSemanticReport qw(
    build_normalized_semantic_failure_report
    build_normalized_semantic_success_report
);
use FSM::Support::RegressionCorpus qw(regression_corpus_entries);
use FSM::Support::CheckFailureDiagnosticContract qw(
    check_failure_diagnostic_matched_presence_keys
    check_failure_diagnostic_presence_keys
    check_failure_diagnostic_support_accounting_matched_presence_keys
    check_failure_diagnostic_support_accounting_presence_keys
);
use FSM::Support::CheckResultContract qw(
    check_result_presence_keys
);
use FSM::Support::ReportCommandContract qw(
    report_command_presence_keys
);
use FSM::Support::ReportGeneratedOutputContract qw(
    report_generated_output_presence_keys
);
use FSM::Support::ReportProducerContract qw(
    normalized_semantic_report_producer_extra_keys
    report_producer_common_keys
);
use FSM::Support::ReportSourceContract qw(
    report_source_presence_keys
);
use FSM::Support::SupportAccountingMatchContract qw(
    support_accounting_match_common_keys
    support_accounting_match_failure_keys
    support_accounting_match_success_keys
);

my $supported_entry = supported_success_entry();
my $supported_path = repo_relpath($supported_entry->{relpath});
my $module_name = $supported_entry->{expected_module_name} || 'shared_report_runtime_audit';
my $failure_entry = strict_legacy_root_failure_entry();
my $failure_path = repo_relpath($failure_entry->{relpath});
my $failure_message = "Strict mode rejects the legacy '+fsm' root family";

subtest 'check success report keeps the bounded shared leaf contracts at runtime' => sub {
    my $report = build_check_success_report(
        input => $supported_entry->{id},
        source_file => $supported_path,
        target_language => 'systemverilog',
        strict_mode => 1,
        module_info => {
            module_name => $module_name,
            state_count => 3,
            signal_count => 7,
            composition_child_count => 0,
        },
    );

    assert_keys_present($report->{producer}, report_producer_common_keys(), 'check success producer keeps common contract keys');
    assert_keys_present($report->{command}, report_command_presence_keys(), 'check success command keeps contract keys');
    assert_keys_present($report->{source}, report_source_presence_keys(), 'check success source keeps contract keys');
    assert_keys_present($report->{generated_output}, report_generated_output_presence_keys(), 'check success generated_output keeps contract keys');
    assert_keys_present($report->{result}, check_result_presence_keys(), 'check success result keeps contract keys');
    assert_keys_present($report->{support_accounting}, support_accounting_match_common_keys(), 'check success support_accounting keeps common contract keys');
    assert_keys_present($report->{support_accounting}, support_accounting_match_success_keys(), 'check success support_accounting keeps matched-success contract keys');
};

subtest 'normalized semantic success report keeps the bounded shared leaf contracts at runtime' => sub {
    my $report = build_normalized_semantic_success_report(
        input => $supported_entry->{id},
        source_file => $supported_path,
        target_language => 'systemverilog',
        strict_mode => 1,
        module_info => {
            module_name => $module_name,
            source_root_kind => 'fsm',
            state_count => 3,
            regular_state_count => 3,
            regular_state_names => [qw(IDLE BUSY DONE)],
            standalone_dt_count => 0,
            standalone_dt_names => [],
            signal_count => 7,
            signal_names => [qw(clk reset req ack done state bus)],
            parameter_count => 0,
            parameter_names => [],
            requires_implicit_system_ports => 1,
        },
        result => {},
    );

    assert_keys_present($report->{producer}, report_producer_common_keys(), 'semantic success producer keeps common contract keys');
    assert_keys_present($report->{producer}, normalized_semantic_report_producer_extra_keys(), 'semantic success producer keeps semantic extra keys');
    assert_keys_present($report->{command}, report_command_presence_keys(), 'semantic success command keeps contract keys');
    assert_keys_present($report->{source}, report_source_presence_keys(), 'semantic success source keeps contract keys');
    assert_keys_present($report->{generated_output}, report_generated_output_presence_keys(), 'semantic success generated_output keeps contract keys');
    assert_keys_present($report->{support_accounting}, support_accounting_match_common_keys(), 'semantic success support_accounting keeps common contract keys');
    assert_keys_present($report->{support_accounting}, support_accounting_match_success_keys(), 'semantic success support_accounting keeps matched-success contract keys');
};

subtest 'check failure report keeps the bounded shared failure leaf contracts at runtime' => sub {
    my $report = build_check_failure_report(
        input => $failure_entry->{id},
        source_file => $failure_path,
        target_language => 'systemverilog',
        strict_mode => 1,
        message => $failure_message,
    );

    my $diagnostic = $report->{diagnostics}[0];
    ok($diagnostic, 'check failure report carries one diagnostic');

    assert_keys_present($report->{producer}, report_producer_common_keys(), 'check failure producer keeps common contract keys');
    assert_keys_present($report->{command}, report_command_presence_keys(), 'check failure command keeps contract keys');
    assert_keys_present($report->{source}, report_source_presence_keys(), 'check failure source keeps contract keys');
    assert_keys_present($report->{generated_output}, report_generated_output_presence_keys(), 'check failure generated_output keeps contract keys');
    assert_keys_present($diagnostic, check_failure_diagnostic_presence_keys(), 'check failure diagnostic keeps public contract keys');
    assert_keys_present($diagnostic, check_failure_diagnostic_matched_presence_keys(), 'check failure diagnostic keeps matched-only contract keys');
    assert_keys_present($diagnostic->{support_accounting}, check_failure_diagnostic_support_accounting_presence_keys(), 'check failure diagnostic support_accounting keeps common contract keys');
    assert_keys_present($diagnostic->{support_accounting}, check_failure_diagnostic_support_accounting_matched_presence_keys(), 'check failure diagnostic support_accounting keeps matched-failure contract keys');
};

subtest 'normalized semantic failure report keeps the bounded shared failure leaf contracts at runtime' => sub {
    my $report = build_normalized_semantic_failure_report(
        input => $failure_entry->{id},
        source_file => $failure_path,
        target_language => 'systemverilog',
        strict_mode => 1,
        message => $failure_message,
    );

    my $diagnostic = $report->{diagnostics}[0];
    ok($diagnostic, 'semantic failure report carries one diagnostic');

    assert_keys_present($report->{producer}, report_producer_common_keys(), 'semantic failure producer keeps common contract keys');
    assert_keys_present($report->{producer}, normalized_semantic_report_producer_extra_keys(), 'semantic failure producer keeps semantic extra keys');
    assert_keys_present($report->{command}, report_command_presence_keys(), 'semantic failure command keeps contract keys');
    assert_keys_present($report->{source}, report_source_presence_keys(), 'semantic failure source keeps contract keys');
    assert_keys_present($report->{generated_output}, report_generated_output_presence_keys(), 'semantic failure generated_output keeps contract keys');
    assert_keys_present($report->{support_accounting}, support_accounting_match_common_keys(), 'semantic failure top-level support_accounting keeps common contract keys');
    assert_keys_present($report->{support_accounting}, support_accounting_match_failure_keys(), 'semantic failure top-level support_accounting keeps matched-failure contract keys');
    assert_keys_present($diagnostic, check_failure_diagnostic_presence_keys(), 'semantic failure diagnostic keeps public contract keys');
    assert_keys_present($diagnostic, check_failure_diagnostic_matched_presence_keys(), 'semantic failure diagnostic keeps matched-only contract keys');
    assert_keys_present($diagnostic->{support_accounting}, check_failure_diagnostic_support_accounting_presence_keys(), 'semantic failure diagnostic support_accounting keeps common contract keys');
    assert_keys_present($diagnostic->{support_accounting}, check_failure_diagnostic_support_accounting_matched_presence_keys(), 'semantic failure diagnostic support_accounting keeps matched-failure contract keys');
};

done_testing();

sub supported_success_entry {
    my ($entry) = grep {
        ($_->{classification} || '') eq 'supported_smoke'
            && ($_->{source_kind} || '') eq 'fsm'
    } regression_corpus_entries();
    die 'No supported_smoke fsm regression entry found for runtime audit'
        unless $entry;
    return $entry;
}

sub strict_legacy_root_failure_entry {
    my ($entry) = grep {
        ($_->{diagnostic_code} || '') eq 'FSMGEN_STRICT_LEGACY_FSM_ROOT'
    } regression_corpus_entries();
    die 'No FSMGEN_STRICT_LEGACY_FSM_ROOT regression entry found for runtime audit'
        unless $entry;
    return $entry;
}

sub repo_relpath {
    my ($relpath) = @_;
    return File::Spec->catfile($FindBin::Bin, '..', split('/', $relpath));
}

sub assert_keys_present {
    my ($payload, $keys, $label) = @_;
    ok(ref($payload) eq 'HASH', "$label: payload is a hash");
    return unless ref($payload) eq 'HASH';

    for my $key (@{$keys || []}) {
        ok(exists $payload->{$key}, "$label: keeps key $key");
    }
}
