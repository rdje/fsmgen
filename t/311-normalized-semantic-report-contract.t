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

use FSM::Support::NormalizedSemanticReportContract qw(
    build_normalized_semantic_report_contract
    normalized_semantic_composition_keys
    normalized_semantic_forward_ir_keys
    normalized_semantic_matched_failure_support_accounting_keys
    normalized_semantic_matched_success_support_accounting_keys
    normalized_semantic_public_top_level_keys
    normalized_semantic_success_only_top_level_keys
    normalized_semantic_success_semantic_keys
    normalized_semantic_support_accounting_keys
);

my $repo_root = File::Spec->catdir($FindBin::Bin, '..');
my $tempdir = tempdir(CLEANUP => 1);

subtest 'contract exposes the bounded normalized semantic surface' => sub {
    my $contract = build_normalized_semantic_report_contract();

    is($contract->{schema_version}, 1, 'contract exposes schema version');
    is($contract->{status}, 'bounded_public', 'contract marks normalized semantic JSON as bounded public');
    is(
        $contract->{contract_source},
        'FSM::Support::NormalizedSemanticReportContract',
        'contract records its own owner',
    );
    is(
        $contract->{report_source},
        'FSM::Support::NormalizedSemanticReport',
        'contract records the normalized semantic report owner',
    );
    ok(!$contract->{emits_hdl}, 'contract says normalized semantic JSON emits no HDL');
    ok($contract->{emits_support_accounting_object}, 'contract says normalized semantic JSON emits support accounting');
    is(
        $contract->{support_accounting_contract_source},
        'FSM::Support::SupportAccountingMatchContract',
        'contract records the shared support-accounting nested-object owner',
    );
    ok($contract->{failure_omits_semantic_payload}, 'contract says failed reports omit semantic payload');
    ok($contract->{full_report_json_safe}, 'contract says the emitted report is JSON-safe');
    ok(!$contract->{full_export_stable}, 'contract keeps full export stabilization out of the bounded promise');

    is_deeply(
        $contract->{public_top_level_presence_keys},
        normalized_semantic_public_top_level_keys(),
        'contract publishes the bounded top-level key list',
    );
    is_deeply(
        $contract->{success_only_top_level_keys},
        normalized_semantic_success_only_top_level_keys(),
        'contract publishes the success-only top-level key list',
    );
    is_deeply(
        $contract->{support_accounting_presence_keys},
        normalized_semantic_support_accounting_keys(),
        'contract publishes the common support-accounting key list',
    );
    is_deeply(
        $contract->{matched_success_support_accounting_presence_keys},
        normalized_semantic_matched_success_support_accounting_keys(),
        'contract publishes the matched success support-accounting key list',
    );
    is_deeply(
        $contract->{matched_failure_support_accounting_presence_keys},
        normalized_semantic_matched_failure_support_accounting_keys(),
        'contract publishes the matched failure support-accounting key list',
    );
    is_deeply(
        $contract->{success_semantic_presence_keys},
        normalized_semantic_success_semantic_keys(),
        'contract publishes the bounded semantic payload key list',
    );
    is_deeply(
        $contract->{success_forward_ir_presence_keys},
        normalized_semantic_forward_ir_keys(),
        'contract publishes the bounded forward-IR key list',
    );
    is_deeply(
        $contract->{composition_presence_keys},
        normalized_semantic_composition_keys(),
        'contract publishes the bounded composition key list',
    );
};

my $ok_path = File::Spec->catfile($tempdir, 'semantic_contract_ok.fsm');
my $bad_path = File::Spec->catfile($tempdir, 'semantic_contract_bad.fsm');
my $ok_out_path = File::Spec->catfile($tempdir, 'semantic_contract_ok.sv');
my $bad_out_path = File::Spec->catfile($tempdir, 'semantic_contract_bad.sv');

write_file(
    $ok_path,
    <<'FSM'
(?fsm:semantic_contract_ok
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
(?fsm:semantic_contract_bad
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

subtest 'successful direct semantic JSON conforms to the bounded contract' => sub {
    my $decoded = run_semantic_json(
        ['./bin/fsmgen', '--strict', '--emit-semantic-json', '-o', $ok_out_path, $ok_path],
        'strict semantic JSON succeeds for direct sample',
    );

    assert_keys_present(
        $decoded,
        normalized_semantic_public_top_level_keys(),
        'direct success report keeps bounded top-level keys',
    );
    assert_keys_present(
        $decoded->{support_accounting},
        normalized_semantic_support_accounting_keys(),
        'direct success report keeps common support-accounting keys',
    );
    assert_keys_present(
        $decoded,
        normalized_semantic_success_only_top_level_keys(),
        'direct success report keeps success-only top-level keys',
    );
    assert_keys_present(
        $decoded->{semantic},
        normalized_semantic_success_semantic_keys(),
        'direct success semantic payload keeps bounded semantic keys',
    );
    assert_keys_present(
        $decoded->{semantic}{forward_ir},
        normalized_semantic_forward_ir_keys(),
        'direct success semantic payload keeps bounded forward-IR keys',
    );

    ok(!exists $decoded->{semantic}{composition}, 'direct success omits optional composition payload');
    ok(!$decoded->{generated_output}{emitted}, 'direct success still records no HDL emission');
};

subtest 'successful composition semantic JSON conforms to the bounded contract' => sub {
    my $composition_path = File::Spec->catfile($repo_root, 'fsm', 'apb_tb.fsm');
    my $composition_out_path = File::Spec->catfile($tempdir, 'semantic_contract_apb_tb.sv');

    my $decoded = run_semantic_json(
        ['./bin/fsmgen', '--strict', '--emit-semantic-json', '-o', $composition_out_path, $composition_path],
        'strict semantic JSON succeeds for composition sample',
    );

    assert_keys_present(
        $decoded,
        normalized_semantic_public_top_level_keys(),
        'composition success report keeps bounded top-level keys',
    );
    assert_keys_present(
        $decoded->{support_accounting},
        normalized_semantic_support_accounting_keys(),
        'composition success report keeps common support-accounting keys',
    );
    assert_keys_present(
        $decoded->{support_accounting},
        normalized_semantic_matched_success_support_accounting_keys(),
        'composition success report keeps matched support-accounting keys',
    );
    assert_keys_present(
        $decoded->{semantic},
        normalized_semantic_success_semantic_keys(),
        'composition success semantic payload keeps bounded semantic keys',
    );
    assert_keys_present(
        $decoded->{semantic}{composition},
        normalized_semantic_composition_keys(),
        'composition success semantic payload keeps bounded composition keys',
    );
};

subtest 'failed semantic JSON conforms to the bounded contract' => sub {
    my $decoded = run_failed_semantic_json(
        ['./bin/fsmgen', '--strict', '--emit-semantic-json', '-o', $bad_out_path, $bad_path],
        'strict semantic JSON fails for rejected source',
    );

    assert_keys_present(
        $decoded,
        normalized_semantic_public_top_level_keys(),
        'failed report keeps bounded top-level keys',
    );
    assert_keys_present(
        $decoded->{support_accounting},
        normalized_semantic_support_accounting_keys(),
        'failed report keeps common support-accounting keys',
    );
    assert_keys_present(
        $decoded->{support_accounting},
        normalized_semantic_matched_failure_support_accounting_keys(),
        'failed report keeps matched failure support-accounting keys',
    );
    ok(!exists $decoded->{semantic}, 'failed report omits semantic payload');
    ok(!$decoded->{success}, 'failed report keeps success false');
    ok(!$decoded->{generated_output}{emitted}, 'failed report records no HDL emission');
};

done_testing();

sub run_semantic_json {
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

sub run_failed_semantic_json {
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
