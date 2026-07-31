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
use FSM::Support::RegressionCorpus qw(regression_corpus_entries);
use FSM::Test::ProjectDataLocality;

my $repo_root = File::Spec->catdir($FindBin::Bin, '..');
my $tempdir = tempdir(CLEANUP => 1);

my @supported_entries = grep {
    $_->{classification} eq 'supported_smoke'
} regression_corpus_entries();

my @hdl_entries = grep {
    _supports_phase($_, 'hdl_generation')
} @supported_entries;

my @strict_entries = grep {
    $_->{strict_supported}
} @hdl_entries;

ok(@supported_entries, 'regression corpus records supported-smoke entries');
ok(@hdl_entries, 'regression corpus records HDL-generating supported-smoke entries');
ok(@strict_entries, 'regression corpus records strict-supported entries');

subtest 'HDL-generating supported-smoke entries compile through default pipeline' => sub {
    for my $entry (@hdl_entries) {
        _assert_pipeline_acceptance(
            $entry,
            owner => 'default pipeline',
        );
    }
};

subtest 'HDL-generating supported-smoke entries compile through default CLI' => sub {
    for my $entry (@hdl_entries) {
        _assert_cli_acceptance(
            $entry,
            owner => 'default CLI',
            suffix => 'default',
        );
    }
};

subtest 'strict-supported entries compile through strict pipeline' => sub {
    for my $entry (@strict_entries) {
        _assert_pipeline_acceptance(
            $entry,
            strict_mode => 1,
            owner => 'strict pipeline',
        );
    }
};

subtest 'strict-supported entries compile through strict CLI' => sub {
    for my $entry (@strict_entries) {
        _assert_cli_acceptance(
            $entry,
            strict_mode => 1,
            owner => 'strict CLI',
            suffix => 'strict',
        );
    }
};

done_testing();

sub _repo_path {
    my ($relpath) = @_;
    return File::Spec->catfile($repo_root, split m{/}, $relpath);
}

sub _supports_phase {
    my ($entry, $phase) = @_;
    return 1 unless exists $entry->{supported_phases};
    return scalar grep { $_ eq $phase } @{$entry->{supported_phases}};
}

sub _source_search_paths_for_entry {
    my ($entry) = @_;
    return map { _repo_path($_) } @{$entry->{search_path_relpaths} || []};
}

sub _assert_pipeline_acceptance {
    my ($entry, %args) = @_;

    my @search_paths = _source_search_paths_for_entry($entry);
    my %pipeline_args = (
        target_language => 'systemverilog',
        debug_level => 0,
        quiet => 1,
        source_search_paths => \@search_paths,
    );
    $pipeline_args{strict_mode} = 1 if $args{strict_mode};

    my $pipeline = FSM::Pipeline::HDLGenerator->new(%pipeline_args);
    my $result = $pipeline->generate_hdl_from_file(_repo_path($entry->{relpath}));

    is($result->{source_info}{kind}, $entry->{source_kind}, "$entry->{id} keeps source kind through $args{owner}");
    _assert_entry_hdl_shape($entry, $result->{hdl_code}, $args{owner});
    _assert_entry_composition_plan($entry, $result, $args{owner})
        if $entry->{source_kind} eq 'composition';
}

sub _assert_cli_acceptance {
    my ($entry, %args) = @_;

    my $out_name = $entry->{id};
    $out_name =~ s/[^A-Za-z0-9_.-]+/_/g;
    my $out_path = File::Spec->catfile($tempdir, "$out_name.$args{suffix}.sv");

    my @command = ('./bin/fsmgen', '--quiet');
    push @command, '--strict' if $args{strict_mode};
    for my $search_path (_source_search_paths_for_entry($entry)) {
        push @command, '--path', $search_path;
    }
    push @command, '-o', $out_path, _repo_path($entry->{relpath});

    my ($success, $error_message, $full_buf, $stdout_buf, $stderr_buf) = run(
        command => \@command,
    );

    ok($success, "CLI compiles $entry->{id} through $args{owner}");
    ok(-e $out_path, "CLI emits HDL for $entry->{id} through $args{owner}");

    open my $fh, '<', $out_path or die "Cannot open $out_path for read: $!";
    local $/;
    my $hdl = <$fh>;
    close $fh or die "Cannot close $out_path after read: $!";

    _assert_entry_hdl_shape($entry, $hdl, $args{owner});
}

sub _assert_entry_composition_plan {
    my ($entry, $result, $owner) = @_;

    isa_ok($result->{composition_plan}, 'FSM::Composition::Plan', "$entry->{id} $owner composition plan");
    is($result->{composition_plan}->top_name, $entry->{expected_top_name}, "$entry->{id} preserves top name through $owner");
    is($result->{composition_plan}->lane, $entry->{expected_lane}, "$entry->{id} preserves composition lane through $owner");
    is(
        scalar(@{$result->{composition_plan}->instances || []}),
        $entry->{expected_instance_count},
        "$entry->{id} realizes expected child count through $owner",
    );
}

sub _assert_entry_hdl_shape {
    my ($entry, $hdl, $owner) = @_;

    if ($entry->{source_kind} eq 'fsm'
        || $entry->{source_kind} eq 'dt'
        || $entry->{source_kind} eq 'isf'
        || $entry->{source_kind} eq 'ppif') {
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
        fail("$entry->{id} has unsupported supported-smoke source kind '$entry->{source_kind}'");
    }

    for my $pattern (@{$entry->{expected_hdl_patterns} || []}) {
        like($hdl, $pattern, "$entry->{id} keeps an expected HDL shape through $owner");
    }
}
