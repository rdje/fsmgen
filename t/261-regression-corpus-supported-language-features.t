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

sub _repo_path {
    my ($relpath) = @_;
    return File::Spec->catfile($repo_root, split m{/}, $relpath);
}

sub _source_search_paths_for_entry {
    my ($entry) = @_;
    return map { _repo_path($_) } @{$entry->{search_path_relpaths} || []};
}

sub _assert_entry_hdl_shape {
    my ($entry, $hdl, $owner) = @_;

    if ($entry->{source_kind} eq 'fsm' || $entry->{source_kind} eq 'dt') {
        like(
            $hdl,
            qr/\bmodule\s+\Q$entry->{expected_module_name}\E\b/s,
            "$entry->{id} generates module $entry->{expected_module_name} through $owner",
        );
    }
    elsif ($entry->{source_kind} eq 'composition') {
        like(
            $hdl,
            qr/\bmodule\s+\Q$entry->{expected_top_name}\E\b/s,
            "$entry->{id} generates top module $entry->{expected_top_name} through $owner",
        );
        for my $child_module (@{$entry->{expected_child_modules} || []}) {
            like(
                $hdl,
                qr/\bmodule\s+\Q$child_module\E\b/s,
                "$entry->{id} generates child module $child_module through $owner",
            );
        }
    }
    else {
        fail("$entry->{id} has unsupported language-feature source kind '$entry->{source_kind}'");
    }

    for my $pattern (@{$entry->{expected_hdl_patterns} || []}) {
        like($hdl, $pattern, "$entry->{id} keeps one expected $owner HDL shape");
    }
}

sub _assert_entry_plan_shape {
    my ($entry, $result, $owner) = @_;
    return if $entry->{source_kind} ne 'composition';

    isa_ok($result->{composition_plan}, 'FSM::Composition::Plan', "$entry->{id} records a composition plan through $owner");
    is($result->{composition_plan}->top_name, $entry->{expected_top_name}, "$entry->{id} preserves top name through $owner");
    is($result->{composition_plan}->lane, $entry->{expected_lane}, "$entry->{id} preserves composition lane through $owner");
    is(
        scalar(@{$result->{composition_plan}->instances || []}),
        $entry->{expected_instance_count},
        "$entry->{id} realizes expected child count through $owner",
    );
}

subtest 'supported language-feature corpus entries keep their semantic HDL shape through pipeline and CLI' => sub {
    for my $entry (
        grep {
            $_->{family} eq 'language_feature_fixture'
                && $_->{classification} eq 'supported_smoke'
        } regression_corpus_entries()
    ) {
        my $pipeline = FSM::Pipeline::HDLGenerator->new(
            target_language => 'systemverilog',
            debug_level => 0,
            quiet => 1,
            source_search_paths => [_source_search_paths_for_entry($entry)],
        );
        my $path = _repo_path($entry->{relpath});
        my $result = $pipeline->generate_hdl_from_file($path);

        is($result->{source_info}{kind}, $entry->{source_kind}, "$entry->{id} keeps the expected source kind");
        _assert_entry_plan_shape($entry, $result, 'the pipeline');
        _assert_entry_hdl_shape($entry, $result->{hdl_code}, 'the pipeline');

        my $out_path = File::Spec->catfile($tempdir, "$entry->{id}.sv");
        my @command = ('./bin/fsmgen', '--quiet');
        for my $search_path (_source_search_paths_for_entry($entry)) {
            push @command, '--path', $search_path;
        }
        push @command, '-o', $out_path, $path;
        my ($success, $error_message, $full_buf, $stdout_buf, $stderr_buf) = run(
            command => \@command,
        );

        ok($success, "CLI compiles $entry->{id}");
        ok(-e $out_path, "CLI emits HDL for $entry->{id}");

        open my $fh, '<', $out_path or die "Cannot open $out_path for read: $!";
        local $/;
        my $hdl = <$fh>;
        close $fh or die "Cannot close $out_path after read: $!";

        _assert_entry_hdl_shape($entry, $hdl, 'the CLI');
    }
};

subtest 'strict-supported language-feature corpus entries compile through strict pipeline and CLI' => sub {
    my @strict_entries = grep {
        $_->{family} eq 'language_feature_fixture'
            && $_->{classification} eq 'supported_smoke'
            && $_->{strict_supported}
    } regression_corpus_entries();

    ok(@strict_entries, 'corpus records at least one positive strict-mode supported feature');

    for my $entry (@strict_entries) {
        my $pipeline = FSM::Pipeline::HDLGenerator->new(
            target_language => 'systemverilog',
            debug_level => 0,
            quiet => 1,
            strict_mode => 1,
            source_search_paths => [_source_search_paths_for_entry($entry)],
        );
        my $path = _repo_path($entry->{relpath});
        my $result = $pipeline->generate_hdl_from_file($path);

        is($result->{source_info}{kind}, $entry->{source_kind}, "$entry->{id} keeps the expected source kind in strict mode");
        _assert_entry_plan_shape($entry, $result, 'the strict pipeline');
        _assert_entry_hdl_shape($entry, $result->{hdl_code}, 'the strict pipeline');

        my $out_path = File::Spec->catfile($tempdir, "$entry->{id}.strict.sv");
        my @command = ('./bin/fsmgen', '--strict', '--quiet');
        for my $search_path (_source_search_paths_for_entry($entry)) {
            push @command, '--path', $search_path;
        }
        push @command, '-o', $out_path, $path;
        my ($success, $error_message, $full_buf, $stdout_buf, $stderr_buf) = run(
            command => \@command,
        );

        ok($success, "CLI strict mode compiles $entry->{id}");
        ok(-e $out_path, "CLI strict mode emits HDL for $entry->{id}");

        open my $fh, '<', $out_path or die "Cannot open $out_path for read: $!";
        local $/;
        my $hdl = <$fh>;
        close $fh or die "Cannot close $out_path after read: $!";

        _assert_entry_hdl_shape($entry, $hdl, 'the strict CLI');
    }
};

done_testing();
