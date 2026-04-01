#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use File::Spec;
use File::Temp qw(tempdir);
use IPC::Cmd qw(run);
use FindBin;

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');
use lib File::Spec->catdir($FindBin::Bin, 'lib');

use FSM::Pipeline::HDLGenerator;
use FSM::Test::RegressionCorpus qw(regression_corpus_entries);

my $repo_root = File::Spec->catdir($FindBin::Bin, '..');
my $tempdir = tempdir(CLEANUP => 1);

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

subtest 'legacy-out-of-scope entries stay compatibility-covered in default mode' => sub {
    for my $entry (grep { $_->{classification} eq 'legacy_out_of_scope' } regression_corpus_entries()) {
        my $path = repo_path($entry->{relpath});
        my @search_paths = source_search_paths_for_entry($entry);
        my $pipeline = FSM::Pipeline::HDLGenerator->new(
            target_language => 'systemverilog',
            debug_level => 0,
            quiet => 1,
            source_search_paths => \@search_paths,
        );
        my $result = $pipeline->generate_hdl_from_file($path);

        is($result->{source_info}{kind}, $entry->{source_kind}, "$entry->{id} keeps the expected source kind");
        if ($entry->{source_kind} eq 'fsm') {
            like(
                $result->{hdl_code},
                qr/\bmodule\s+\Q$entry->{expected_module_name}\E\b/s,
                "$entry->{id} still generates HDL in default compatibility mode",
            );
        }
        elsif ($entry->{source_kind} eq 'composition') {
            is($result->{composition_plan}->top_name, $entry->{expected_top_name}, "$entry->{id} keeps the expected composition top name");
            is($result->{composition_plan}->lane, $entry->{expected_lane}, "$entry->{id} keeps the expected composition lane");
            is(scalar(@{$result->{composition_plan}->instances || []}), $entry->{expected_instance_count}, "$entry->{id} keeps the expected realized child count");
            for my $child_module (@{$entry->{expected_child_modules}}) {
                like($result->{hdl_code}, qr/\bmodule\s+\Q$child_module\E\b/s, "$entry->{id} generated HDL includes child module $child_module");
            }
            like($result->{hdl_code}, qr/\bmodule\s+\Q$entry->{expected_top_name}\E\b/s, "$entry->{id} generated HDL includes top module $entry->{expected_top_name}");
        }
        else {
            fail("$entry->{id} uses an unsupported source kind '$entry->{source_kind}' in legacy-out-of-scope coverage");
        }

        my $out_path = File::Spec->catfile($tempdir, "$entry->{id}.sv");
        my ($success, $error_message, $full_buf, $stdout_buf, $stderr_buf) = run(
            command => ['./bin/fsmgen', '--quiet', cli_path_args_for_entry($entry), '-o', $out_path, $path],
        );

        ok($success, "CLI still compiles $entry->{id} in default mode");
        ok(-e $out_path, "CLI emits HDL for $entry->{id} in default mode");
    }
};

subtest 'expected-failure entries reject through the classified strict support-tier boundaries' => sub {
    for my $entry (
        grep {
            $_->{coverage} eq 'strict_root_rejection_pipeline_cli'
                || $_->{coverage} eq 'strict_section_rejection_pipeline_cli'
                || $_->{coverage} eq 'strict_child_root_rejection_pipeline_cli'
        } regression_corpus_entries()
    ) {
        my $path = repo_path($entry->{relpath});
        my @search_paths = source_search_paths_for_entry($entry);
        my $pipeline = FSM::Pipeline::HDLGenerator->new(
            target_language => 'systemverilog',
            debug_level => 0,
            quiet => 1,
            strict_mode => 1,
            source_search_paths => \@search_paths,
        );

        my $pipeline_error = eval {
            $pipeline->generate_hdl_from_file($path);
            undef;
        };
        $pipeline_error = $@ if !$pipeline_error;

        ok($pipeline_error, "strict pipeline rejects $entry->{id}");
        like($pipeline_error, $entry->{expected_error_pattern}, "strict pipeline keeps the expected boundary text for $entry->{id}");
        if ($entry->{expected_hint_pattern}) {
            like($pipeline_error, $entry->{expected_hint_pattern}, "strict pipeline keeps the expected migration hint for $entry->{id}");
        }

        my $out_path = File::Spec->catfile($tempdir, "$entry->{id}.sv");
        my ($success, $error_message, $full_buf, $stdout_buf, $stderr_buf) = run(
            command => ['./bin/fsmgen', '--strict', '--quiet', cli_path_args_for_entry($entry), '-o', $out_path, $path],
        );

        ok(!$success, "CLI strict mode rejects $entry->{id}");
        ok(!-e $out_path, "CLI strict mode does not emit HDL for $entry->{id}");

        my $combined_output = join(
            '',
            @{ $stdout_buf || [] },
            @{ $stderr_buf || [] },
            ($error_message || ''),
        );

        like($combined_output, $entry->{expected_error_pattern}, "CLI strict mode keeps the expected boundary text for $entry->{id}");
        if ($entry->{expected_hint_pattern}) {
            like($combined_output, $entry->{expected_hint_pattern}, "CLI strict mode keeps the expected migration hint for $entry->{id}");
        }
    }
};

subtest 'language-contract expected-failure entries reject through the normal pipeline boundary' => sub {
    my $pipeline = FSM::Pipeline::HDLGenerator->new(
        target_language => 'systemverilog',
        debug_level => 0,
        quiet => 1,
    );

    for my $entry (grep { $_->{coverage} eq 'language_contract_rejection_pipeline_cli' } regression_corpus_entries()) {
        my $path = File::Spec->catfile($repo_root, split m{/}, $entry->{relpath});

        my $pipeline_error = eval {
            $pipeline->generate_hdl_from_file($path);
            undef;
        };
        $pipeline_error = $@ if !$pipeline_error;

        ok($pipeline_error, "pipeline rejects $entry->{id}");
        like($pipeline_error, $entry->{expected_error_pattern}, "pipeline keeps the expected boundary text for $entry->{id}");

        my $out_path = File::Spec->catfile($tempdir, "$entry->{id}.sv");
        my ($success, $error_message, $full_buf, $stdout_buf, $stderr_buf) = run(
            command => ['./bin/fsmgen', '--quiet', '-o', $out_path, $path],
        );

        ok(!$success, "CLI rejects $entry->{id}");
        ok(!-e $out_path, "CLI does not emit HDL for $entry->{id}");

        my $combined_output = join(
            '',
            @{ $stdout_buf || [] },
            @{ $stderr_buf || [] },
            ($error_message || ''),
        );

        like($combined_output, qr/Source file:\s+'[^']+'/s, "CLI keeps source-file context for $entry->{id}");
        like($combined_output, $entry->{expected_error_pattern}, "CLI keeps the expected boundary text for $entry->{id}");
    }
};

subtest 'composition-contract expected-failure entries reject through the normal pipeline boundary' => sub {
    for my $entry (grep { $_->{coverage} eq 'composition_contract_rejection_pipeline_cli' } regression_corpus_entries()) {
        my $path = File::Spec->catfile($repo_root, split m{/}, $entry->{relpath});
        my @search_paths = source_search_paths_for_entry($entry);
        my $pipeline = FSM::Pipeline::HDLGenerator->new(
            target_language => 'systemverilog',
            debug_level => 0,
            quiet => 1,
            source_search_paths => \@search_paths,
        );

        my $pipeline_error = eval {
            $pipeline->generate_hdl_from_file($path);
            undef;
        };
        $pipeline_error = $@ if !$pipeline_error;

        ok($pipeline_error, "pipeline rejects $entry->{id}");
        like($pipeline_error, $entry->{expected_error_pattern}, "pipeline keeps the expected composition-contract boundary text for $entry->{id}");

        my $out_path = File::Spec->catfile($tempdir, "$entry->{id}.sv");
        my ($success, $error_message, $full_buf, $stdout_buf, $stderr_buf) = run(
            command => ['./bin/fsmgen', '--quiet', cli_path_args_for_entry($entry), '-o', $out_path, $path],
        );

        ok(!$success, "CLI rejects $entry->{id}");
        ok(!-e $out_path, "CLI does not emit HDL for $entry->{id}");

        my $combined_output = join(
            '',
            @{ $stdout_buf || [] },
            @{ $stderr_buf || [] },
            ($error_message || ''),
        );

        like($combined_output, $entry->{expected_error_pattern}, "CLI keeps the expected composition-contract boundary text for $entry->{id}");
    }
};

done_testing();
