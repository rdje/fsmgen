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

use FSM::Support::CheckDiagnosticsContract qw(
    check_json_failure_diagnostic_keys
    check_json_failure_diagnostic_support_accounting_keys
    check_json_matched_failure_diagnostic_keys
    check_json_matched_failure_support_accounting_keys
    check_json_matched_success_support_accounting_keys
    check_json_nested_presence_key_map
    check_json_public_top_level_keys
    check_json_success_only_top_level_keys
    check_json_success_support_accounting_keys
);
use FSM::Support::NormalizedSemanticReportContract qw(
    normalized_semantic_failure_diagnostic_keys
    normalized_semantic_failure_diagnostic_support_accounting_keys
    normalized_semantic_matched_failure_diagnostic_keys
    normalized_semantic_matched_failure_diagnostic_support_accounting_keys
    normalized_semantic_matched_failure_support_accounting_keys
    normalized_semantic_matched_success_support_accounting_keys
    normalized_semantic_nested_presence_key_map
    normalized_semantic_public_top_level_keys
    normalized_semantic_success_only_top_level_keys
    normalized_semantic_success_semantic_keys
    normalized_semantic_support_accounting_keys
);
use FSM::Support::ReportProducerContract qw(
    normalized_semantic_report_producer_extra_keys
    report_producer_common_keys
);

my $repo_root = File::Spec->catdir($FindBin::Bin, '..');
my $tempdir = tempdir(CLEANUP => 1);

my $bad_path = File::Spec->catfile($tempdir, 'bad_infix_report_shell.fsm');
write_file(
    $bad_path,
    <<'FSM'
(?fsm:bad_infix_report_shell
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

subtest 'check JSON success shell keeps bounded contract families at runtime' => sub {
    my $decoded = run_json_command('--check-json', repo_file('fsm/apb_requester.fsm'));

    ok($decoded->{success}, 'check JSON success report marks success true');
    is_deeply(
        unknown_top_level_keys(
            $decoded,
            [
                @{check_json_public_top_level_keys() || []},
                @{check_json_success_only_top_level_keys() || []},
            ],
        ),
        [],
        'check JSON success report keeps only declared top-level shell keys',
    );

    assert_keys_present(
        $decoded,
        check_json_public_top_level_keys(),
        'check JSON success report keeps public top-level keys',
    );
    assert_keys_present(
        $decoded,
        check_json_success_only_top_level_keys(),
        'check JSON success report keeps success-only top-level keys',
    );

    my $nested = check_json_nested_presence_key_map();
    assert_keys_present(
        $decoded->{command},
        $nested->{command},
        'check JSON success command keeps bounded nested keys',
    );
    assert_keys_present(
        $decoded->{generated_output},
        $nested->{generated_output},
        'check JSON success generated_output keeps bounded nested keys',
    );
    assert_keys_present(
        $decoded->{producer},
        $nested->{producer},
        'check JSON success producer keeps bounded nested keys',
    );
    assert_keys_present(
        $decoded->{source},
        $nested->{source},
        'check JSON success source keeps bounded nested keys',
    );
    assert_keys_present(
        $decoded->{result},
        $nested->{result},
        'check JSON success result keeps bounded nested keys',
    );
    assert_keys_present(
        $decoded->{support_accounting},
        check_json_success_support_accounting_keys(),
        'check JSON success support_accounting keeps common bounded keys',
    );
    assert_keys_present(
        $decoded->{support_accounting},
        check_json_matched_success_support_accounting_keys(),
        'check JSON success support_accounting keeps matched bounded keys',
    );
    ok($decoded->{support_accounting}{matched}, 'check JSON success support_accounting is matched');
    is(scalar(@{$decoded->{diagnostics} || []}), 0, 'check JSON success report keeps diagnostics empty');
};

subtest 'check JSON matched failure shell keeps bounded contract families at runtime' => sub {
    my $decoded = run_json_command('--check-json', $bad_path, expect_failure => 1);

    ok(!$decoded->{success}, 'check JSON failure report marks success false');
    is_deeply(
        unknown_top_level_keys($decoded, check_json_public_top_level_keys()),
        [],
        'check JSON failure report keeps only declared public top-level shell keys',
    );

    assert_keys_present(
        $decoded,
        check_json_public_top_level_keys(),
        'check JSON failure report keeps public top-level keys',
    );
    assert_keys_absent(
        $decoded,
        check_json_success_only_top_level_keys(),
        'check JSON failure report omits success-only top-level keys',
    );
    ok(!exists $decoded->{support_accounting}, 'check JSON failure report keeps support accounting inside diagnostics only');
    is(scalar(@{$decoded->{diagnostics} || []}), 1, 'check JSON failure report keeps one diagnostic');

    my $diagnostic = $decoded->{diagnostics}[0];
    assert_keys_present(
        $diagnostic,
        check_json_failure_diagnostic_keys(),
        'check JSON failure diagnostic keeps bounded keys',
    );
    assert_keys_present(
        $diagnostic,
        check_json_matched_failure_diagnostic_keys(),
        'check JSON failure diagnostic keeps matched bounded keys',
    );
    assert_keys_present(
        $diagnostic->{support_accounting},
        check_json_failure_diagnostic_support_accounting_keys(),
        'check JSON failure diagnostic support_accounting keeps common bounded keys',
    );
    assert_keys_present(
        $diagnostic->{support_accounting},
        check_json_matched_failure_support_accounting_keys(),
        'check JSON failure diagnostic support_accounting keeps matched bounded keys',
    );
    ok($diagnostic->{support_accounting}{matched}, 'check JSON failure diagnostic support_accounting is matched');
};

subtest 'normalized semantic success shell keeps bounded contract families at runtime' => sub {
    my $decoded = run_json_command('--emit-semantic-json', repo_file('fsm/apb_requester.fsm'));

    ok($decoded->{success}, 'normalized semantic success report marks success true');
    is_deeply(
        unknown_top_level_keys(
            $decoded,
            [
                @{normalized_semantic_public_top_level_keys() || []},
                @{normalized_semantic_success_only_top_level_keys() || []},
            ],
        ),
        [],
        'normalized semantic success report keeps only declared top-level shell keys',
    );

    assert_keys_present(
        $decoded,
        normalized_semantic_public_top_level_keys(),
        'normalized semantic success report keeps public top-level keys',
    );
    assert_keys_present(
        $decoded,
        normalized_semantic_success_only_top_level_keys(),
        'normalized semantic success report keeps success-only top-level keys',
    );

    my $nested = normalized_semantic_nested_presence_key_map();
    assert_keys_present(
        $decoded->{command},
        $nested->{command},
        'normalized semantic success command keeps bounded nested keys',
    );
    assert_keys_present(
        $decoded->{generated_output},
        $nested->{generated_output},
        'normalized semantic success generated_output keeps bounded nested keys',
    );
    assert_keys_present(
        $decoded->{producer},
        report_producer_common_keys(),
        'normalized semantic success producer keeps common bounded keys',
    );
    assert_keys_present(
        $decoded->{producer},
        normalized_semantic_report_producer_extra_keys(),
        'normalized semantic success producer keeps semantic extra bounded keys',
    );
    assert_keys_present(
        $decoded->{source},
        $nested->{source},
        'normalized semantic success source keeps bounded nested keys',
    );
    assert_keys_present(
        $decoded->{support_accounting},
        normalized_semantic_support_accounting_keys(),
        'normalized semantic success support_accounting keeps common bounded keys',
    );
    assert_keys_present(
        $decoded->{support_accounting},
        normalized_semantic_matched_success_support_accounting_keys(),
        'normalized semantic success support_accounting keeps matched bounded keys',
    );
    assert_keys_present(
        $decoded->{semantic},
        normalized_semantic_success_semantic_keys(),
        'normalized semantic success semantic payload keeps bounded shell keys',
    );
    ok($decoded->{support_accounting}{matched}, 'normalized semantic success support_accounting is matched');
    is(scalar(@{$decoded->{diagnostics} || []}), 0, 'normalized semantic success report keeps diagnostics empty');
};

subtest 'normalized semantic matched failure shell keeps bounded contract families at runtime' => sub {
    my $decoded = run_json_command('--emit-semantic-json', $bad_path, expect_failure => 1);

    ok(!$decoded->{success}, 'normalized semantic failure report marks success false');
    is_deeply(
        unknown_top_level_keys($decoded, normalized_semantic_public_top_level_keys()),
        [],
        'normalized semantic failure report keeps only declared public top-level shell keys',
    );

    assert_keys_present(
        $decoded,
        normalized_semantic_public_top_level_keys(),
        'normalized semantic failure report keeps public top-level keys',
    );
    assert_keys_absent(
        $decoded,
        normalized_semantic_success_only_top_level_keys(),
        'normalized semantic failure report omits success-only top-level keys',
    );
    assert_keys_present(
        $decoded->{producer},
        report_producer_common_keys(),
        'normalized semantic failure producer keeps common bounded keys',
    );
    assert_keys_present(
        $decoded->{producer},
        normalized_semantic_report_producer_extra_keys(),
        'normalized semantic failure producer keeps semantic extra bounded keys',
    );
    assert_keys_present(
        $decoded->{support_accounting},
        normalized_semantic_support_accounting_keys(),
        'normalized semantic failure support_accounting keeps common bounded keys',
    );
    assert_keys_present(
        $decoded->{support_accounting},
        normalized_semantic_matched_failure_support_accounting_keys(),
        'normalized semantic failure support_accounting keeps matched bounded keys',
    );
    ok($decoded->{support_accounting}{matched}, 'normalized semantic failure support_accounting is matched');
    ok(!exists $decoded->{semantic}, 'normalized semantic failure report omits semantic payload');
    is(scalar(@{$decoded->{diagnostics} || []}), 1, 'normalized semantic failure report keeps one diagnostic');

    my $diagnostic = $decoded->{diagnostics}[0];
    assert_keys_present(
        $diagnostic,
        normalized_semantic_failure_diagnostic_keys(),
        'normalized semantic failure diagnostic keeps bounded keys',
    );
    assert_keys_present(
        $diagnostic,
        normalized_semantic_matched_failure_diagnostic_keys(),
        'normalized semantic failure diagnostic keeps matched bounded keys',
    );
    assert_keys_present(
        $diagnostic->{support_accounting},
        normalized_semantic_failure_diagnostic_support_accounting_keys(),
        'normalized semantic failure diagnostic support_accounting keeps common bounded keys',
    );
    assert_keys_present(
        $diagnostic->{support_accounting},
        normalized_semantic_matched_failure_diagnostic_support_accounting_keys(),
        'normalized semantic failure diagnostic support_accounting keeps matched bounded keys',
    );
    ok($diagnostic->{support_accounting}{matched}, 'normalized semantic failure diagnostic support_accounting is matched');
};

done_testing();

sub run_json_command {
    my ($mode, $path, %opts) = @_;
    my ($success, $error_message, $full_buf, $stdout_buf, $stderr_buf) = run(
        command => ['./bin/fsmgen', '--strict', $mode, $path],
    );

    if ($opts{expect_failure}) {
        ok(!$success, "$mode fails for $path as expected");
    } else {
        ok($success, "$mode succeeds for $path");
    }
    is(join('', @{$stderr_buf || []}), '', "$mode keeps stderr clean for $path");

    return decode_json(join('', @{$stdout_buf || []}));
}

sub repo_file {
    my ($relpath) = @_;
    return File::Spec->catfile($repo_root, split m{/}, $relpath);
}

sub write_file {
    my ($path, $contents) = @_;
    open my $fh, '>', $path or die "Cannot open $path for write: $!";
    print {$fh} $contents;
    close $fh or die "Cannot close $path: $!";
}

sub assert_keys_present {
    my ($payload, $keys, $label) = @_;
    ok(ref($payload) eq 'HASH', "$label: payload is a hash");
    return unless ref($payload) eq 'HASH';

    for my $key (@{$keys || []}) {
        ok(exists $payload->{$key}, "$label keeps key $key");
    }
}

sub assert_keys_absent {
    my ($payload, $keys, $label) = @_;
    ok(ref($payload) eq 'HASH', "$label: payload is a hash");
    return unless ref($payload) eq 'HASH';

    for my $key (@{$keys || []}) {
        ok(!exists $payload->{$key}, "$label omits key $key");
    }
}

sub unknown_top_level_keys {
    my ($payload, $known_keys) = @_;
    my %known = map { $_ => 1 } @{$known_keys || []};
    return [grep { !$known{$_} } sort keys %{$payload || {}}];
}
