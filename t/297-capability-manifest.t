#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use File::Spec;
use FindBin;
use IPC::Cmd qw(run);
use JSON::PP qw(decode_json);

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::Support::CapabilityManifest qw(build_capability_manifest);
use FSM::Support::DiagnosticCodes qw(diagnostic_code_ids);
use FSM::Support::RegressionCorpus qw(regression_corpus_entries);

my @entries = regression_corpus_entries();
my @diagnostic_codes = diagnostic_code_ids();
my $manifest = build_capability_manifest();

subtest 'module manifest is generated from support accounting' => sub {
    is($manifest->{manifest_schema_version}, 1, 'manifest exposes its schema version');
    is($manifest->{producer}{name}, 'FSMGen', 'manifest identifies FSMGen as producer');
    like($manifest->{producer}{version}, qr/\A\d+\.\d+-dev\z/, 'manifest exposes a producer version string');
    like($manifest->{producer}{git_commit}, qr/\A(?:unknown|[0-9a-f]{7,12})\z/, 'manifest exposes a bounded producer commit identity');
    is($manifest->{support_accounting}{source}, 'FSM::Support::RegressionCorpus', 'manifest records the corpus owner');
    is($manifest->{support_accounting}{entry_count}, scalar(@entries), 'manifest entry count follows the corpus');

    is(
        scalar(@{$manifest->{support_accounting}{catalog_entries}}),
        scalar(@entries),
        'manifest exposes one sanitized catalog entry per corpus entry',
    );

    is(
        $manifest->{support_accounting}{classifications}{supported_smoke},
        scalar(grep { $_->{classification} eq 'supported_smoke' } @entries),
        'manifest supported-smoke count follows the corpus',
    );
    is(
        $manifest->{support_accounting}{classifications}{expected_failure},
        scalar(grep { $_->{classification} eq 'expected_failure' } @entries),
        'manifest expected-failure count follows the corpus',
    );
    is(
        scalar(@{$manifest->{support_accounting}{strict_supported_ids}}),
        scalar(grep { $_->{strict_supported} } @entries),
        'manifest strict-supported ids follow the corpus',
    );

    my ($strict_infix_entry) = grep { $_->{id} eq 'legacy.infix_assignment.strict_rejection' }
        @{$manifest->{support_accounting}{catalog_entries}};
    is(
        $strict_infix_entry->{diagnostic_code},
        'FSMGEN_STRICT_INFIX_ASSIGNMENT',
        'manifest exposes stable diagnostic codes on expected-failure catalog entries',
    );
};

subtest 'manifest exposes the stable diagnostic-code registry' => sub {
    is(
        $manifest->{diagnostics}{registry_source},
        'FSM::Support::DiagnosticCodes',
        'manifest records the production diagnostic-code owner',
    );
    is(
        scalar(@{$manifest->{diagnostics}{stable_codes}}),
        scalar(@diagnostic_codes),
        'manifest stable diagnostic-code count follows the registry',
    );

    my %stable_codes = map { $_->{code} => $_ } @{$manifest->{diagnostics}{stable_codes}};
    ok($stable_codes{FSMGEN_STRICT_INFIX_ASSIGNMENT}, 'manifest includes the strict infix-assignment diagnostic code');
    is(
        $stable_codes{FSMGEN_STRICT_INFIX_ASSIGNMENT}{severity},
        'error',
        'manifest diagnostic-code entries carry severity metadata',
    );
    is(
        $stable_codes{FSMGEN_STRICT_INFIX_ASSIGNMENT}{stability},
        'stable',
        'manifest diagnostic-code entries carry stability metadata',
    );
    is($manifest->{diagnostics}{check_json}{schema_version}, 1, 'manifest records check JSON schema version');
    is($manifest->{diagnostics}{check_json}{status}, 'bounded_public', 'manifest marks check JSON as bounded public');
    ok($manifest->{diagnostics}{check_json}{emits_stable_codes}, 'manifest says check JSON emits stable codes');
    ok(!$manifest->{diagnostics}{check_json}{emits_hdl}, 'manifest says check JSON does not emit HDL');
    ok(
        $manifest->{diagnostics}{check_json}{emits_support_accounting_object},
        'manifest says check JSON emits a support-accounting object',
    );
    ok(
        $manifest->{diagnostics}{check_json}{expected_failure_corpus_covered},
        'manifest says check JSON is covered across expected-failure corpus entries',
    );
    is(
        $manifest->{diagnostics}{check_json}{classifier_match_policy},
        'most_specific_expected_error_pattern',
        'manifest records the check JSON classifier match policy',
    );
    is(
        $manifest->{diagnostics}{check_json}{report_source},
        'FSM::Support::CheckDiagnostics',
        'manifest records the check JSON report owner',
    );
};

subtest 'manifest captures the first downstream tool contract surface' => sub {
    ok($manifest->{language_surface}{strict_mode}{intended_for_generated_fsm}, 'strict mode is marked as the generated-FSM target');
    ok(!$manifest->{language_surface}{strict_mode}{compatibility_syntax_is_canonical}, 'compatibility syntax is not canonical');

    my %direct_roots = map { $_ => 1 } @{$manifest->{language_surface}{strict_mode}{canonical_direct_roots}};
    ok($direct_roots{'?fsm'}, 'manifest names ?fsm as a canonical direct root');
    ok($direct_roots{'?dt'}, 'manifest names ?dt as a canonical direct root');

    my %blocked = map { $_ => 1 } @{$manifest->{language_surface}{intentionally_blocked_or_not_yet_public}};
    ok($blocked{'full check-only JSON diagnostic schema stabilization'}, 'manifest keeps full JSON diagnostic API stabilization blocked');
    ok($blocked{'full normalized semantic JSON export'}, 'manifest tells downstream tools that normalized JSON export is not stable yet');
};

subtest 'CLI emits the same valid JSON manifest without an input file' => sub {
    my ($success, $error_message, $full_buf, $stdout_buf, $stderr_buf) = run(
        command => ['./bin/fsmgen', '--capability-manifest'],
    );

    ok($success, 'CLI capability manifest command succeeds without an input source');
    is(join('', @{$stderr_buf || []}), '', 'CLI capability manifest command does not print stderr');

    my $decoded = decode_json(join('', @{$stdout_buf || []}));
    is($decoded->{manifest_schema_version}, 1, 'CLI manifest JSON decodes with schema version');
    is($decoded->{support_accounting}{entry_count}, scalar(@entries), 'CLI manifest JSON uses corpus entry count');
    is($decoded->{support_accounting}{source}, 'FSM::Support::RegressionCorpus', 'CLI manifest JSON records the corpus owner');

    my ($alias_success, $alias_error, $alias_full, $alias_stdout, $alias_stderr) = run(
        command => ['./bin/fsmgen', '--emit-capability-manifest'],
    );
    ok($alias_success, 'CLI manifest alias succeeds without an input source');
    my $alias_decoded = decode_json(join('', @{$alias_stdout || []}));
    is($alias_decoded->{manifest_schema_version}, 1, 'CLI manifest alias emits valid manifest JSON');
};

done_testing();
