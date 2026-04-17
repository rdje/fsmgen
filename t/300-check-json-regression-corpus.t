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

sub strict_args_for_entry {
    my ($entry) = @_;
    return $strict_rejection_coverages{$entry->{coverage}} ? ('--strict') : ();
}

sub safe_filename_for_entry {
    my ($entry) = @_;
    my $name = $entry->{id};
    $name =~ s/[^A-Za-z0-9_.-]+/_/g;
    return "$name.sv";
}

subtest 'check JSON classifies every expected-failure corpus entry' => sub {
    my @expected_failures =
        grep { $_->{classification} eq 'expected_failure' } regression_corpus_entries();

    ok(@expected_failures, 'corpus has expected-failure entries for check JSON coverage');

    for my $entry (@expected_failures) {
        my $path = repo_path($entry->{relpath});
        my $out_path = File::Spec->catfile($tempdir, safe_filename_for_entry($entry));
        my ($success, $error_message, $full_buf, $stdout_buf, $stderr_buf) = run(
            command => [
                './bin/fsmgen',
                strict_args_for_entry($entry),
                '--check-json',
                cli_path_args_for_entry($entry),
                '-o',
                $out_path,
                $path,
            ],
        );

        ok(!$success, "check JSON rejects expected failure $entry->{id}");
        is(join('', @{$stderr_buf || []}), '', "check JSON keeps stderr clean for $entry->{id}");
        ok(!-e $out_path, "check JSON emits no HDL for $entry->{id}");

        my $stdout = join('', @{$stdout_buf || []});
        my $decoded = eval { decode_json($stdout) };
        ok($decoded, "check JSON emits decodable JSON for $entry->{id}")
            or do {
                diag($stdout);
                next;
            };

        ok(!$decoded->{success}, "check JSON marks $entry->{id} as failure");
        is($decoded->{check_schema_version}, 1, "check JSON keeps schema version for $entry->{id}");
        is($decoded->{command}{mode}, 'check', "check JSON records check mode for $entry->{id}");
        ok($decoded->{command}{json}, "check JSON records JSON mode for $entry->{id}");
        is(
            $decoded->{command}{strict_mode} ? 1 : 0,
            $strict_rejection_coverages{$entry->{coverage}} ? 1 : 0,
            "check JSON records strict-mode state for $entry->{id}",
        );
        is($decoded->{source}{resolved_path}, File::Spec->rel2abs($path),
            "check JSON records resolved source path for $entry->{id}");
        ok(!$decoded->{generated_output}{emitted}, "check JSON records no HDL emission for $entry->{id}");
        is(scalar(@{$decoded->{diagnostics}}), 1, "check JSON emits one diagnostic for $entry->{id}");

        my $diagnostic = $decoded->{diagnostics}[0];
        my $metadata = diagnostic_code_metadata($entry->{diagnostic_code});
        is($diagnostic->{code}, $entry->{diagnostic_code},
            "check JSON emits expected stable code for $entry->{id}");
        is($diagnostic->{severity}, $metadata->{severity},
            "check JSON emits severity metadata for $entry->{id}");
        is($diagnostic->{stability}, $metadata->{stability},
            "check JSON emits stability metadata for $entry->{id}");
        is($diagnostic->{family}, $metadata->{family},
            "check JSON emits diagnostic-code family for $entry->{id}");
        is($diagnostic->{summary}, $metadata->{summary},
            "check JSON emits diagnostic summary for $entry->{id}");
        like($diagnostic->{message}, $entry->{expected_error_pattern},
            "check JSON diagnostic message matches corpus boundary for $entry->{id}");

        is($diagnostic->{matched_corpus_entry_id}, $entry->{id},
            "check JSON records matched corpus entry for $entry->{id}");
        is($diagnostic->{coverage}, $entry->{coverage},
            "check JSON records matched coverage for $entry->{id}");
        is($diagnostic->{classification}, $entry->{classification},
            "check JSON records matched classification for $entry->{id}");

        my $support = $diagnostic->{support_accounting};
        ok($support->{matched}, "check JSON support-accounting object is matched for $entry->{id}");
        is($support->{entry_id}, $entry->{id},
            "support-accounting object records entry id for $entry->{id}");
        is($support->{family}, $entry->{family},
            "support-accounting object records corpus family for $entry->{id}");
        is($support->{coverage}, $entry->{coverage},
            "support-accounting object records coverage for $entry->{id}");
        is($support->{classification}, $entry->{classification},
            "support-accounting object records classification for $entry->{id}");
        is($support->{diagnostic_code}, $entry->{diagnostic_code},
            "support-accounting object records diagnostic code for $entry->{id}");

        my $has_hint = $entry->{expected_hint_pattern} ? 1 : 0;
        is($diagnostic->{migration_hint_available} ? 1 : 0, $has_hint,
            "check JSON records migration-hint availability for $entry->{id}");
        is($support->{migration_hint_available} ? 1 : 0, $has_hint,
            "support-accounting object records migration-hint availability for $entry->{id}");
        like($diagnostic->{message}, $entry->{expected_hint_pattern},
            "check JSON diagnostic message keeps migration hint for $entry->{id}")
            if $has_hint;
    }
};

done_testing();
