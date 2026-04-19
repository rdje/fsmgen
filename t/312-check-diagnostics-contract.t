#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use File::Spec;
use File::Temp qw(tempdir);
use FindBin;
use IPC::Cmd qw(run);
use JSON::PP qw(decode_json);

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::Support::CheckFailureDiagnosticContract qw(
    check_failure_diagnostic_matched_presence_keys
    check_failure_diagnostic_optional_artifact_keys
    check_failure_diagnostic_presence_keys
    check_failure_diagnostic_support_accounting_matched_presence_keys
    check_failure_diagnostic_support_accounting_presence_keys
);
use FSM::Support::CheckDiagnosticsContract qw(
    build_check_diagnostics_contract
    check_json_failure_diagnostic_keys
    check_json_failure_diagnostic_support_accounting_keys
    check_json_matched_failure_diagnostic_keys
    check_json_matched_failure_support_accounting_keys
    check_json_matched_success_support_accounting_keys
    check_json_public_top_level_keys
    check_json_success_only_top_level_keys
    check_json_success_result_keys
    check_json_success_support_accounting_keys
);
use FSM::Support::CheckResultContract qw(check_result_presence_keys);
use FSM::Support::ReportCommandContract qw(report_command_presence_keys);
use FSM::Support::ReportGeneratedOutputContract qw(report_generated_output_presence_keys);
use FSM::Support::ReportProducerContract qw(report_producer_common_keys);
use FSM::Support::ReportSourceContract qw(report_source_presence_keys);
use FSM::Support::SupportAccountingMatchContract qw(
    support_accounting_match_common_keys
    support_accounting_match_failure_keys
    support_accounting_match_success_keys
);

my $repo_root = File::Spec->catdir($FindBin::Bin, '..');
my $tempdir = tempdir(CLEANUP => 1);

subtest 'contract exposes the bounded check JSON surface' => sub {
    my $contract = build_check_diagnostics_contract();

    is($contract->{schema_version}, 1, 'contract exposes schema version');
    is($contract->{status}, 'bounded_public', 'contract marks check JSON as bounded public');
    is(
        $contract->{contract_source},
        'FSM::Support::CheckDiagnosticsContract',
        'contract records its own owner',
    );
    is(
        $contract->{report_source},
        'FSM::Support::CheckDiagnostics',
        'contract records the check JSON report owner',
    );
    ok($contract->{emits_stable_codes}, 'contract says check JSON emits stable codes');
    ok(!$contract->{emits_hdl}, 'contract says check JSON emits no HDL');
    ok($contract->{emits_support_accounting_object}, 'contract says check JSON emits support accounting');
    ok(
        $contract->{emits_failure_diagnostic_support_accounting_object},
        'contract says failed diagnostics carry support accounting',
    );
    is(
        $contract->{command_contract_source},
        'FSM::Support::ReportCommandContract',
        'contract records the shared command nested-object owner',
    );
    is(
        $contract->{result_contract_source},
        'FSM::Support::CheckResultContract',
        'contract records the success result nested-object owner',
    );
    is(
        $contract->{failure_diagnostic_contract_source},
        'FSM::Support::CheckFailureDiagnosticContract',
        'contract records the failure diagnostic nested-object owner',
    );
    is(
        $contract->{generated_output_contract_source},
        'FSM::Support::ReportGeneratedOutputContract',
        'contract records the shared generated_output nested-object owner',
    );
    is(
        $contract->{producer_contract_source},
        'FSM::Support::ReportProducerContract',
        'contract records the shared producer nested-object owner',
    );
    is(
        $contract->{source_contract_source},
        'FSM::Support::ReportSourceContract',
        'contract records the shared source nested-object owner',
    );
    is(
        $contract->{support_accounting_contract_source},
        'FSM::Support::SupportAccountingMatchContract',
        'contract records the shared support-accounting nested-object owner',
    );
    ok($contract->{full_report_json_safe}, 'contract says the emitted report is JSON-safe');
    ok(
        !$contract->{full_diagnostic_schema_stable},
        'contract keeps broader failure-diagnostic stabilization out of the bounded promise',
    );

    is_deeply(
        $contract->{public_top_level_presence_keys},
        check_json_public_top_level_keys(),
        'contract publishes the bounded top-level key list',
    );
    is_deeply(
        $contract->{success_only_top_level_keys},
        check_json_success_only_top_level_keys(),
        'contract publishes the success-only top-level key list',
    );
    is_deeply(
        $contract->{success_result_presence_keys},
        check_result_presence_keys(),
        'contract publishes the bounded success-result key list',
    );
    is_deeply(
        $contract->{command_presence_keys},
        report_command_presence_keys(),
        'contract publishes the bounded command-object key list',
    );
    is_deeply(
        $contract->{generated_output_presence_keys},
        report_generated_output_presence_keys(),
        'contract publishes the bounded generated_output-object key list',
    );
    is_deeply(
        $contract->{producer_presence_keys},
        report_producer_common_keys(),
        'contract publishes the bounded producer-object key list',
    );
    is_deeply(
        $contract->{source_presence_keys},
        report_source_presence_keys(),
        'contract publishes the bounded source-object key list',
    );
    is_deeply(
        $contract->{success_support_accounting_presence_keys},
        support_accounting_match_common_keys(),
        'contract publishes the common success support-accounting keys',
    );
    is_deeply(
        $contract->{matched_success_support_accounting_presence_keys},
        support_accounting_match_success_keys(),
        'contract publishes the matched success support-accounting keys',
    );
    is_deeply(
        $contract->{failure_diagnostic_presence_keys},
        check_failure_diagnostic_presence_keys(),
        'contract publishes the bounded failure-diagnostic key list',
    );
    is_deeply(
        $contract->{matched_failure_diagnostic_presence_keys},
        check_failure_diagnostic_matched_presence_keys(),
        'contract publishes the matched failure-diagnostic key list',
    );
    is_deeply(
        $contract->{failure_diagnostic_optional_artifact_keys},
        check_failure_diagnostic_optional_artifact_keys(),
        'contract publishes the optional failure-diagnostic artifact key list',
    );
    is_deeply(
        $contract->{failure_diagnostic_support_accounting_presence_keys},
        check_failure_diagnostic_support_accounting_presence_keys(),
        'contract publishes the common failure support-accounting keys',
    );
    is_deeply(
        $contract->{matched_failure_diagnostic_support_accounting_presence_keys},
        check_failure_diagnostic_support_accounting_matched_presence_keys(),
        'contract publishes the matched failure support-accounting keys',
    );
};

my $ok_path = File::Spec->catfile($tempdir, 'check_contract_ok.fsm');
my $bad_path = File::Spec->catfile($tempdir, 'check_contract_bad.fsm');
my $ok_out_path = File::Spec->catfile($tempdir, 'check_contract_ok.sv');
my $bad_out_path = File::Spec->catfile($tempdir, 'check_contract_bad.sv');

write_file(
    $ok_path,
    <<'FSM'
(?fsm:check_contract_ok
  (+system
    (clock clk)
    (sreset reset)
  )

  (+size
    (COND 1)
    (SRC 8)
    (OUT 8)
  )

  (idle
    (<COND
      (= (OUT SRC))
    )
  )
)
FSM
);

write_file(
    $bad_path,
    <<'FSM'
(?fsm:check_contract_bad
  (+system
    (clock clk)
    (sreset reset)
  )

  (+size
    (SRC 8)
    (OUT 8)
  )

  (idle
    (OUT = SRC)
  )
)
FSM
);

subtest 'successful direct check JSON conforms to the bounded contract' => sub {
    my $decoded = run_check_json(
        ['./bin/fsmgen', '--strict', '--check-json', '-o', $ok_out_path, $ok_path],
        'strict check JSON succeeds for direct sample',
    );

    assert_keys_present(
        $decoded,
        check_json_public_top_level_keys(),
        'direct success report keeps bounded top-level keys',
    );
    assert_keys_present(
        $decoded->{command},
        report_command_presence_keys(),
        'direct success report keeps bounded command-object keys',
    );
    assert_keys_present(
        $decoded->{generated_output},
        report_generated_output_presence_keys(),
        'direct success report keeps bounded generated_output-object keys',
    );
    assert_keys_present(
        $decoded->{producer},
        report_producer_common_keys(),
        'direct success report keeps bounded producer-object keys',
    );
    assert_keys_present(
        $decoded->{source},
        report_source_presence_keys(),
        'direct success report keeps bounded source-object keys',
    );
    assert_keys_present(
        $decoded,
        check_json_success_only_top_level_keys(),
        'direct success report keeps success-only top-level keys',
    );
    assert_keys_present(
        $decoded->{result},
        check_result_presence_keys(),
        'direct success report keeps bounded success-result keys',
    );
    assert_keys_present(
        $decoded->{support_accounting},
        check_json_success_support_accounting_keys(),
        'direct success report keeps common success support-accounting keys',
    );

    ok(!$decoded->{support_accounting}{matched}, 'direct ad hoc success stays unmatched');
    ok(!$decoded->{generated_output}{emitted}, 'direct success still records no HDL emission');
};

subtest 'successful corpus-backed composition check JSON conforms to the matched support-accounting branch' => sub {
    my $composition_path = File::Spec->catfile($repo_root, 'fsm', 'apb_tb.fsm');
    my $composition_out_path = File::Spec->catfile($tempdir, 'check_contract_apb_tb.sv');

    my $decoded = run_check_json(
        ['./bin/fsmgen', '--strict', '--check-json', '-o', $composition_out_path, $composition_path],
        'strict check JSON succeeds for composition sample',
    );

    assert_keys_present(
        $decoded,
        check_json_public_top_level_keys(),
        'composition success report keeps bounded top-level keys',
    );
    assert_keys_present(
        $decoded->{command},
        report_command_presence_keys(),
        'composition success report keeps bounded command-object keys',
    );
    assert_keys_present(
        $decoded->{generated_output},
        report_generated_output_presence_keys(),
        'composition success report keeps bounded generated_output-object keys',
    );
    assert_keys_present(
        $decoded->{producer},
        report_producer_common_keys(),
        'composition success report keeps bounded producer-object keys',
    );
    assert_keys_present(
        $decoded->{source},
        report_source_presence_keys(),
        'composition success report keeps bounded source-object keys',
    );
    assert_keys_present(
        $decoded,
        check_json_success_only_top_level_keys(),
        'composition success report keeps success-only top-level keys',
    );
    assert_keys_present(
        $decoded->{result},
        check_result_presence_keys(),
        'composition success report keeps bounded success-result keys',
    );
    assert_keys_present(
        $decoded->{support_accounting},
        check_json_success_support_accounting_keys(),
        'composition success report keeps common success support-accounting keys',
    );
    assert_keys_present(
        $decoded->{support_accounting},
        check_json_matched_success_support_accounting_keys(),
        'composition success report keeps matched success support-accounting keys',
    );

    ok($decoded->{support_accounting}{matched}, 'composition success records a matched corpus entry');
};

subtest 'failed check JSON conforms to the bounded contract' => sub {
    my $decoded = run_failed_check_json(
        ['./bin/fsmgen', '--strict', '--check-json', '-o', $bad_out_path, $bad_path],
        'strict check JSON fails for rejected source',
    );

    assert_keys_present(
        $decoded,
        check_json_public_top_level_keys(),
        'failed report keeps bounded top-level keys',
    );
    assert_keys_present(
        $decoded->{command},
        report_command_presence_keys(),
        'failed report keeps bounded command-object keys',
    );
    assert_keys_present(
        $decoded->{generated_output},
        report_generated_output_presence_keys(),
        'failed report keeps bounded generated_output-object keys',
    );
    assert_keys_present(
        $decoded->{producer},
        report_producer_common_keys(),
        'failed report keeps bounded producer-object keys',
    );
    assert_keys_present(
        $decoded->{source},
        report_source_presence_keys(),
        'failed report keeps bounded source-object keys',
    );
    ok(!exists $decoded->{support_accounting}, 'failed report omits success-only report-level support accounting');
    ok(!exists $decoded->{result}, 'failed report omits success-only result summary');
    is(scalar(@{$decoded->{diagnostics} || []}), 1, 'failed report emits one diagnostic');

    my $diagnostic = $decoded->{diagnostics}[0];
    assert_keys_present(
        $diagnostic,
        check_json_failure_diagnostic_keys(),
        'failed report keeps bounded failure-diagnostic keys',
    );
    assert_keys_present(
        $diagnostic,
        check_json_matched_failure_diagnostic_keys(),
        'matched failure keeps bounded matched-diagnostic keys',
    );
    assert_keys_present(
        $diagnostic->{support_accounting},
        check_json_failure_diagnostic_support_accounting_keys(),
        'failed report keeps common failure support-accounting keys',
    );
    assert_keys_present(
        $diagnostic->{support_accounting},
        check_json_matched_failure_support_accounting_keys(),
        'matched failure keeps bounded matched failure support-accounting keys',
    );

    ok(!$decoded->{generated_output}{emitted}, 'failed report still records no HDL emission');
};

done_testing();

sub run_check_json {
    my ($command, $label) = @_;
    my ($success, $error_message, $full_buf, $stdout_buf, $stderr_buf) = run(
        command => $command,
    );

    ok($success, $label);
    is(join('', @{$stderr_buf || []}), '', "$label keeps stderr clean");

    my $decoded = eval { decode_json(join('', @{$stdout_buf || []})) };
    ok($decoded, "$label emits decodable JSON");
    return $decoded;
}

sub run_failed_check_json {
    my ($command, $label) = @_;
    my ($success, $error_message, $full_buf, $stdout_buf, $stderr_buf) = run(
        command => $command,
    );

    ok(!$success, $label);
    is(join('', @{$stderr_buf || []}), '', "$label keeps stderr clean");

    my $decoded = eval { decode_json(join('', @{$stdout_buf || []})) };
    ok($decoded, "$label emits decodable JSON");
    return $decoded;
}

sub assert_keys_present {
    my ($payload, $keys, $label) = @_;
    for my $key (@{$keys || []}) {
        ok(exists $payload->{$key}, "$label: keeps key $key");
    }
}

sub write_file {
    my ($path, $content) = @_;
    open my $fh, '>', $path or die "Cannot open $path for write: $!";
    print {$fh} $content or die "Cannot write $path: $!";
    close $fh or die "Cannot close $path: $!";
}
