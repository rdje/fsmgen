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
use FSM::Composition::Plan;
use FSM::Test::RegressionCorpus qw(regression_corpus_entries);

my $repo_root = File::Spec->catdir($FindBin::Bin, '..');
my $tempdir = tempdir(CLEANUP => 1);

my @strict_entries = grep {
    $_->{classification} eq 'supported_smoke'
        && $_->{strict_supported}
} regression_corpus_entries();

ok(@strict_entries, 'regression corpus records strict-supported entries');

subtest 'strict-supported entries compile through strict pipeline' => sub {
    my $pipeline = FSM::Pipeline::HDLGenerator->new(
        target_language => 'systemverilog',
        debug_level => 0,
        quiet => 1,
        strict_mode => 1,
    );

    for my $entry (@strict_entries) {
        my $path = _repo_path($entry->{relpath});
        my $result = $pipeline->generate_hdl_from_file($path);

        is($result->{source_info}{kind}, $entry->{source_kind}, "$entry->{id} keeps source kind in strict pipeline");
        _assert_entry_hdl_shape($entry, $result->{hdl_code}, 'strict pipeline');

        if ($entry->{source_kind} eq 'composition') {
            isa_ok($result->{composition_plan}, 'FSM::Composition::Plan', "$entry->{id} strict composition plan");
            is($result->{composition_plan}->top_name, $entry->{expected_top_name}, "$entry->{id} preserves top name in strict pipeline");
            is($result->{composition_plan}->lane, $entry->{expected_lane}, "$entry->{id} preserves composition lane in strict pipeline");
            is(
                scalar(@{$result->{composition_plan}->instances || []}),
                $entry->{expected_instance_count},
                "$entry->{id} realizes expected child count in strict pipeline",
            );
        }
    }
};

subtest 'strict-supported entries compile through strict CLI' => sub {
    for my $entry (@strict_entries) {
        my $path = _repo_path($entry->{relpath});
        my $out_name = $entry->{id};
        $out_name =~ s/[^A-Za-z0-9_.-]+/_/g;
        my $out_path = File::Spec->catfile($tempdir, "$out_name.strict.sv");

        my @command = ('./bin/fsmgen', '--strict', '--quiet');
        for my $search_relpath (@{$entry->{search_path_relpaths} || []}) {
            push @command, '--path', _repo_path($search_relpath);
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

        _assert_entry_hdl_shape($entry, $hdl, 'strict CLI');
    }
};

done_testing();

sub _repo_path {
    my ($relpath) = @_;
    return File::Spec->catfile($repo_root, split m{/}, $relpath);
}

sub _assert_entry_hdl_shape {
    my ($entry, $hdl, $owner) = @_;

    if ($entry->{source_kind} eq 'fsm') {
        like(
            $hdl,
            qr/\bmodule\s+\Q$entry->{expected_module_name}\E\b/s,
            "$entry->{id} emits expected module through $owner",
        );
    }
    elsif ($entry->{source_kind} eq 'composition') {
        like(
            $hdl,
            qr/\bmodule\s+\Q$entry->{expected_top_name}\E\b/s,
            "$entry->{id} emits expected top module through $owner",
        );
        for my $child_module (@{$entry->{expected_child_modules} || []}) {
            like(
                $hdl,
                qr/\bmodule\s+\Q$child_module\E\b/s,
                "$entry->{id} emits expected child module $child_module through $owner",
            );
        }
    }
    else {
        fail("$entry->{id} has unsupported strict-supported source kind '$entry->{source_kind}'");
    }

    for my $pattern (@{$entry->{expected_hdl_patterns} || []}) {
        like($hdl, $pattern, "$entry->{id} keeps an expected HDL shape through $owner");
    }
}
