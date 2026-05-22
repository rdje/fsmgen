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

use FSM::Support::DiagnosticCodes qw(diagnostic_code_metadata);
use FSM::Support::RegressionCorpus qw(regression_corpus_entries);

my $repo_root = File::Spec->catdir($FindBin::Bin, '..');
my $tempdir = tempdir(CLEANUP => 1);

my %strict_rejection_coverages = map { $_ => 1 } qw(
    strict_root_rejection_pipeline_cli
    strict_section_rejection_pipeline_cli
    strict_assignment_rejection_pipeline_cli
    strict_child_root_rejection_pipeline_cli
);

subtest 'semantic JSON classifies every expected-failure corpus entry' => sub {
    my @expected_failures =
        grep { $_->{classification} eq 'expected_failure' } regression_corpus_entries();

    ok(@expected_failures, 'corpus has expected-failure entries for semantic JSON coverage');

    for my $entry (@expected_failures) {
        assert_semantic_json_rejection($entry);
    }
};

done_testing();

sub repo_path {
    my ($relpath) = @_;
    return File::Spec->catfile($repo_root, split m{/}, $relpath);
}

sub source_search_paths_for_entry {
    my ($entry) = @_;
    return map { repo_path($_) } @{ $entry->{search_path_relpaths} || [] };
}

sub cli_path_args_for_entry {
    my ($entry) = @_;
    my @args;
    for my $path (source_search_paths_for_entry($entry)) {
        push @args, '--path', $path;
    }
    return @args;
}

sub cli_language_args_for_entry {
    my ($entry) = @_;
    return $entry->{target_language} ? ('--language', $entry->{target_language}) : ();
}

sub strict_args_for_entry {
    my ($entry) = @_;
    return $strict_rejection_coverages{$entry->{coverage}} ? ('--strict') : ();
}

sub safe_filename_for_entry {
    my ($entry) = @_;
    my $name = $entry->{id};
    $name =~ s/[^A-Za-z0-9_.-]+/_/g;
    return "$name.semantic.sv";
}

sub assert_semantic_json_rejection {
    my ($entry) = @_;

    my $path = repo_path($entry->{relpath});
    my $out_path = File::Spec->catfile($tempdir, safe_filename_for_entry($entry));
    my ($success, $error_message, $full_buf, $stdout_buf, $stderr_buf) = run(
        command => [
            './bin/fsmgen',
            strict_args_for_entry($entry),
            cli_language_args_for_entry($entry),
            '--emit-semantic-json',
            cli_path_args_for_entry($entry),
            '-o',
            $out_path,
            $path,
        ],
    );

    ok(!$success, "semantic JSON rejects expected failure $entry->{id}");
    is(join('', @{$stderr_buf || []}), '', "semantic JSON keeps stderr clean for $entry->{id}");
    ok(!-e $out_path, "semantic JSON emits no HDL for $entry->{id}");

    my $stdout = join('', @{$stdout_buf || []});
    my $decoded = eval { decode_json($stdout) };
    ok($decoded, "semantic JSON emits decodable JSON for $entry->{id}")
        or do {
            diag($error_message || 'semantic JSON command failed without an IPC error message');
            diag(join('', @{$stderr_buf || []}));
            diag($stdout);
            return;
        };

    ok(!$decoded->{success}, "semantic JSON marks $entry->{id} as failure");
    is($decoded->{normalized_semantic_schema_version}, 1,
        "semantic JSON keeps schema version for $entry->{id}");
    is($decoded->{command}{mode}, 'semantic_export',
        "semantic JSON records semantic export mode for $entry->{id}");
    ok($decoded->{command}{json}, "semantic JSON records JSON mode for $entry->{id}");
    is(
        $decoded->{command}{strict_mode} ? 1 : 0,
        $strict_rejection_coverages{$entry->{coverage}} ? 1 : 0,
        "semantic JSON records strict-mode state for $entry->{id}",
    );
    is($decoded->{source}{resolved_path}, File::Spec->rel2abs($path),
        "semantic JSON records resolved source path for $entry->{id}");
    ok(!$decoded->{generated_output}{emitted}, "semantic JSON records no HDL emission for $entry->{id}");
    ok(!exists $decoded->{semantic}, "semantic JSON exposes no partial semantic payload for $entry->{id}");
    ok(!exists $decoded->{hdl_code}, "semantic JSON exposes no generated HDL text for $entry->{id}");
    ok(!exists $decoded->{raw_ast}, "semantic JSON exposes no private raw AST for $entry->{id}");
    is(scalar(@{$decoded->{diagnostics}}), 1, "semantic JSON emits one diagnostic for $entry->{id}");

    my $diagnostic = $decoded->{diagnostics}[0];
    my $metadata = diagnostic_code_metadata($entry->{diagnostic_code});
    is($diagnostic->{code}, $entry->{diagnostic_code},
        "semantic JSON emits expected stable code for $entry->{id}");
    is($diagnostic->{severity}, $metadata->{severity},
        "semantic JSON emits severity metadata for $entry->{id}");
    is($diagnostic->{stability}, $metadata->{stability},
        "semantic JSON emits stability metadata for $entry->{id}");
    is($diagnostic->{family}, $metadata->{family},
        "semantic JSON emits diagnostic-code family for $entry->{id}");
    is($diagnostic->{summary}, $metadata->{summary},
        "semantic JSON emits diagnostic summary for $entry->{id}");
    like($diagnostic->{message}, $entry->{expected_error_pattern},
        "semantic JSON diagnostic message matches corpus boundary for $entry->{id}");

    is($diagnostic->{matched_corpus_entry_id}, $entry->{id},
        "semantic JSON records matched corpus entry for $entry->{id}");
    is($diagnostic->{coverage}, $entry->{coverage},
        "semantic JSON records matched coverage for $entry->{id}");
    is($diagnostic->{classification}, $entry->{classification},
        "semantic JSON records matched classification for $entry->{id}");

    assert_support_accounting($entry, $decoded->{support_accounting}, 'report-level');
    assert_support_accounting($entry, $diagnostic->{support_accounting}, 'diagnostic');

    my $has_hint = $entry->{expected_hint_pattern} ? 1 : 0;
    is($diagnostic->{migration_hint_available} ? 1 : 0, $has_hint,
        "semantic JSON records migration-hint availability for $entry->{id}");
    is($decoded->{support_accounting}{migration_hint_available} ? 1 : 0, $has_hint,
        "semantic JSON report-level support accounting records migration-hint availability for $entry->{id}");
    is($diagnostic->{support_accounting}{migration_hint_available} ? 1 : 0, $has_hint,
        "semantic JSON diagnostic support accounting records migration-hint availability for $entry->{id}");
    like($diagnostic->{message}, $entry->{expected_hint_pattern},
        "semantic JSON diagnostic message keeps migration hint for $entry->{id}")
        if $has_hint;
}

sub assert_support_accounting {
    my ($entry, $support, $scope) = @_;

    ok($support->{matched}, "semantic JSON $scope support-accounting object is matched for $entry->{id}");
    is($support->{entry_id}, $entry->{id},
        "semantic JSON $scope support-accounting records entry id for $entry->{id}");
    is($support->{family}, $entry->{family},
        "semantic JSON $scope support-accounting records corpus family for $entry->{id}");
    is($support->{coverage}, $entry->{coverage},
        "semantic JSON $scope support-accounting records coverage for $entry->{id}");
    is($support->{classification}, $entry->{classification},
        "semantic JSON $scope support-accounting records classification for $entry->{id}");
    is($support->{diagnostic_code}, $entry->{diagnostic_code},
        "semantic JSON $scope support-accounting records diagnostic code for $entry->{id}");
}
