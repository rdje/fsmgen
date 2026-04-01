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

subtest 'legacy-out-of-scope entries stay compatibility-covered in default mode' => sub {
    my $pipeline = FSM::Pipeline::HDLGenerator->new(
        target_language => 'systemverilog',
        debug_level => 0,
        quiet => 1,
    );

    for my $entry (grep { $_->{classification} eq 'legacy_out_of_scope' } regression_corpus_entries()) {
        my $path = File::Spec->catfile($repo_root, split m{/}, $entry->{relpath});
        my $result = $pipeline->generate_hdl_from_file($path);

        is($result->{source_info}{kind}, $entry->{source_kind}, "$entry->{id} keeps the expected source kind");
        like(
            $result->{hdl_code},
            qr/\bmodule\s+\Q$entry->{expected_module_name}\E\b/s,
            "$entry->{id} still generates HDL in default compatibility mode",
        );

        my $out_path = File::Spec->catfile($tempdir, "$entry->{id}.sv");
        my ($success, $error_message, $full_buf, $stdout_buf, $stderr_buf) = run(
            command => ['./bin/fsmgen', '--quiet', '-o', $out_path, $path],
        );

        ok($success, "CLI still compiles $entry->{id} in default mode");
        ok(-e $out_path, "CLI emits HDL for $entry->{id} in default mode");
    }
};

subtest 'expected-failure entries reject through the classified strict boundary' => sub {
    my $pipeline = FSM::Pipeline::HDLGenerator->new(
        target_language => 'systemverilog',
        debug_level => 0,
        quiet => 1,
        strict_mode => 1,
    );

    for my $entry (grep { $_->{classification} eq 'expected_failure' } regression_corpus_entries()) {
        my $path = File::Spec->catfile($repo_root, split m{/}, $entry->{relpath});

        my $pipeline_error = eval {
            $pipeline->generate_hdl_from_file($path);
            undef;
        };
        $pipeline_error = $@ if !$pipeline_error;

        ok($pipeline_error, "strict pipeline rejects $entry->{id}");
        like($pipeline_error, $entry->{expected_error_pattern}, "strict pipeline keeps the expected boundary text for $entry->{id}");
        like($pipeline_error, $entry->{expected_hint_pattern}, "strict pipeline keeps the expected migration hint for $entry->{id}");

        my $out_path = File::Spec->catfile($tempdir, "$entry->{id}.sv");
        my ($success, $error_message, $full_buf, $stdout_buf, $stderr_buf) = run(
            command => ['./bin/fsmgen', '--strict', '--quiet', '-o', $out_path, $path],
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
        like($combined_output, $entry->{expected_hint_pattern}, "CLI strict mode keeps the expected migration hint for $entry->{id}");
    }
};

done_testing();
