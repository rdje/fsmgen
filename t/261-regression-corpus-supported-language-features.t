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
use FSM::Support::RegressionCorpus qw(regression_corpus_entries);

my $repo_root = File::Spec->catdir($FindBin::Bin, '..');
my $tempdir = tempdir(CLEANUP => 1);

subtest 'supported language-feature corpus entries keep their semantic HDL shape through pipeline and CLI' => sub {
    my $pipeline = FSM::Pipeline::HDLGenerator->new(
        target_language => 'systemverilog',
        debug_level => 0,
        quiet => 1,
    );

    for my $entry (
        grep {
            $_->{family} eq 'language_feature_fixture'
                && $_->{classification} eq 'supported_smoke'
                && $_->{coverage} eq 'direct_root_pipeline_cli'
        } regression_corpus_entries()
    ) {
        my $path = File::Spec->catfile($repo_root, split m{/}, $entry->{relpath});
        my $result = $pipeline->generate_hdl_from_file($path);

        is($result->{source_info}{kind}, $entry->{source_kind}, "$entry->{id} keeps the expected source kind");
        like(
            $result->{hdl_code},
            qr/\bmodule\s+\Q$entry->{expected_module_name}\E\b/s,
            "$entry->{id} generates module $entry->{expected_module_name} through the pipeline",
        );
        for my $pattern (@{$entry->{expected_hdl_patterns} || []}) {
            like($result->{hdl_code}, $pattern, "$entry->{id} keeps one expected pipeline HDL shape");
        }

        my $out_path = File::Spec->catfile($tempdir, "$entry->{id}.sv");
        my ($success, $error_message, $full_buf, $stdout_buf, $stderr_buf) = run(
            command => ['./bin/fsmgen', '--quiet', '-o', $out_path, $path],
        );

        ok($success, "CLI compiles $entry->{id}");
        ok(-e $out_path, "CLI emits HDL for $entry->{id}");

        open my $fh, '<', $out_path or die "Cannot open $out_path for read: $!";
        local $/;
        my $hdl = <$fh>;
        close $fh or die "Cannot close $out_path after read: $!";

        like($hdl, qr/\bmodule\s+\Q$entry->{expected_module_name}\E\b/s, "$entry->{id} generates module $entry->{expected_module_name} through the CLI");
        for my $pattern (@{$entry->{expected_hdl_patterns} || []}) {
            like($hdl, $pattern, "$entry->{id} keeps one expected CLI HDL shape");
        }
    }
};

subtest 'strict-supported language-feature corpus entries compile through strict pipeline and CLI' => sub {
    my $pipeline = FSM::Pipeline::HDLGenerator->new(
        target_language => 'systemverilog',
        debug_level => 0,
        quiet => 1,
        strict_mode => 1,
    );

    my @strict_entries = grep {
        $_->{family} eq 'language_feature_fixture'
            && $_->{classification} eq 'supported_smoke'
            && $_->{coverage} eq 'direct_root_pipeline_cli'
            && $_->{strict_supported}
    } regression_corpus_entries();

    ok(@strict_entries, 'corpus records at least one positive strict-mode supported feature');

    for my $entry (@strict_entries) {
        my $path = File::Spec->catfile($repo_root, split m{/}, $entry->{relpath});
        my $result = $pipeline->generate_hdl_from_file($path);

        is($result->{source_info}{kind}, $entry->{source_kind}, "$entry->{id} keeps the expected source kind in strict mode");
        like(
            $result->{hdl_code},
            qr/\bmodule\s+\Q$entry->{expected_module_name}\E\b/s,
            "$entry->{id} generates module $entry->{expected_module_name} through the strict pipeline",
        );
        for my $pattern (@{$entry->{expected_hdl_patterns} || []}) {
            like($result->{hdl_code}, $pattern, "$entry->{id} keeps one expected strict pipeline HDL shape");
        }

        my $out_path = File::Spec->catfile($tempdir, "$entry->{id}.strict.sv");
        my ($success, $error_message, $full_buf, $stdout_buf, $stderr_buf) = run(
            command => ['./bin/fsmgen', '--strict', '--quiet', '-o', $out_path, $path],
        );

        ok($success, "CLI strict mode compiles $entry->{id}");
        ok(-e $out_path, "CLI strict mode emits HDL for $entry->{id}");

        open my $fh, '<', $out_path or die "Cannot open $out_path for read: $!";
        local $/;
        my $hdl = <$fh>;
        close $fh or die "Cannot close $out_path after read: $!";

        like($hdl, qr/\bmodule\s+\Q$entry->{expected_module_name}\E\b/s, "$entry->{id} generates module $entry->{expected_module_name} through the strict CLI");
        for my $pattern (@{$entry->{expected_hdl_patterns} || []}) {
            like($hdl, $pattern, "$entry->{id} keeps one expected strict CLI HDL shape");
        }
    }
};

done_testing();
