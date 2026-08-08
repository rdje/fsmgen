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
my $worker_surface = $ENV{FSMGEN_T296_WORKER_SURFACE};
my %worker_batch_size = (
    pipeline => 1,
    cli => 4,
);

my @supported_entries = grep {
    $_->{classification} eq 'supported_smoke'
} regression_corpus_entries();

my @hdl_entries = grep {
    _supports_phase($_, 'hdl_generation')
} @supported_entries;

my @pipeline_hdl_entries = grep {
    _supports_public_pipeline($_)
} @hdl_entries;

my @cli_only_hdl_entries = grep {
    !_supports_public_pipeline($_)
} @hdl_entries;

my @strict_entries = grep {
    $_->{strict_supported}
} @hdl_entries;

my @strict_pipeline_entries = grep {
    $_->{strict_supported}
} @pipeline_hdl_entries;

if (defined $worker_surface) {
    _run_worker_acceptance();
    done_testing();
}
else {
    ok(@supported_entries, 'regression corpus records supported-smoke entries');
    ok(@hdl_entries, 'regression corpus records HDL-generating supported-smoke entries');
    ok(@pipeline_hdl_entries, 'regression corpus records public-pipeline HDL entries');
    ok(@cli_only_hdl_entries, 'regression corpus records CLI-only HDL entries');
    ok(@strict_entries, 'regression corpus records strict-supported entries');
    is(
        scalar(@pipeline_hdl_entries) + scalar(@cli_only_hdl_entries),
        scalar(@hdl_entries),
        'public-pipeline and CLI-only cohorts partition every HDL entry',
    );

    subtest 'public-pipeline HDL entries compile through default pipeline' => sub {
        _assert_batched_acceptance(
            entries => \@pipeline_hdl_entries,
            surface => 'pipeline',
            owner => 'default pipeline',
        );
    };

    subtest 'HDL-generating supported-smoke entries compile through default CLI' => sub {
        _assert_batched_acceptance(
            entries => \@hdl_entries,
            surface => 'cli',
            owner => 'default CLI',
        );
    };

    subtest 'public-pipeline strict-supported entries compile through strict pipeline' => sub {
        _assert_batched_acceptance(
            entries => \@strict_pipeline_entries,
            surface => 'pipeline',
            strict_mode => 1,
            owner => 'strict pipeline',
        );
    };

    subtest 'strict-supported entries compile through strict CLI' => sub {
        _assert_batched_acceptance(
            entries => \@strict_entries,
            surface => 'cli',
            strict_mode => 1,
            owner => 'strict CLI',
        );
    };

    done_testing();
}

sub _repo_path {
    my ($relpath) = @_;
    return File::Spec->catfile($repo_root, split m{/}, $relpath);
}

sub _supports_phase {
    my ($entry, $phase) = @_;
    return 1 unless exists $entry->{supported_phases};
    return scalar grep { $_ eq $phase } @{$entry->{supported_phases}};
}

sub _supports_public_pipeline {
    my ($entry) = @_;
    return 1 if $entry->{relpath} =~ /\.(?:fsm|isf|ppif)\z/i;
    return 0
        if $entry->{source_kind} eq 'ial2_profile_alias'
        && $entry->{relpath} =~ /\.(?:ahb|apb|axi)\z/i;
    die "HDL-generating entry '$entry->{id}' has no public-pipeline or profile-alias source contract";
}

sub _assert_batched_acceptance {
    my (%args) = @_;
    my $entries = $args{entries};
    my $batch_size = $worker_batch_size{$args{surface}};

    for (my $start = 0; $start < @{$entries}; $start += $batch_size) {
        my $count = @{$entries} - $start;
        $count = $batch_size if $count > $batch_size;
        my $first = $start + 1;
        my $last = $start + $count;

        local $ENV{FSMGEN_T296_WORKER_SURFACE} = $args{surface};
        local $ENV{FSMGEN_T296_WORKER_STRICT} = $args{strict_mode} ? 1 : 0;
        local $ENV{FSMGEN_T296_WORKER_START} = $start;
        local $ENV{FSMGEN_T296_WORKER_COUNT} = $count;
        local $ENV{FSMGEN_T296_WORKER_OWNER} = $args{owner};

        my ($success, $error_message, $full_buf) = run(
            command => [$^X, $0],
        );

        ok(
            $success,
            "$args{owner} entries $first-$last pass in an isolated worker",
        );
        if (!$success) {
            diag($error_message) if defined $error_message && length $error_message;
            diag(join '', @{$full_buf || []});
        }
    }
}

sub _run_worker_acceptance {
    my $surface = $worker_surface;
    my $strict_mode = $ENV{FSMGEN_T296_WORKER_STRICT};
    my $start = $ENV{FSMGEN_T296_WORKER_START};
    my $count = $ENV{FSMGEN_T296_WORKER_COUNT};
    my $owner = $ENV{FSMGEN_T296_WORKER_OWNER};

    die "Invalid t296 worker surface '$surface'"
        unless $surface eq 'pipeline' || $surface eq 'cli';
    die 'Invalid t296 worker strict-mode selector'
        unless defined $strict_mode && $strict_mode =~ /\A[01]\z/;
    die 'Invalid t296 worker start offset'
        unless defined $start && $start =~ /\A\d+\z/;
    die 'Invalid t296 worker entry count'
        unless defined $count && $count =~ /\A\d+\z/ && $count > 0;
    die 'Missing t296 worker owner label'
        unless defined $owner && length $owner;

    my @entries = $surface eq 'pipeline'
        ? @pipeline_hdl_entries
        : @hdl_entries;
    @entries = grep { $_->{strict_supported} } @entries if $strict_mode;
    die "t296 worker slice $start+$count exceeds cohort size " . scalar(@entries)
        if $start + $count > @entries;

    my $last = $start + $count - 1;
    for my $entry (@entries[$start .. $last]) {
        if ($surface eq 'pipeline') {
            _assert_pipeline_acceptance(
                $entry,
                strict_mode => $strict_mode,
                owner => $owner,
            );
        }
        else {
            _assert_cli_acceptance(
                $entry,
                strict_mode => $strict_mode,
                owner => $owner,
                suffix => $strict_mode ? 'strict' : 'default',
            );
        }
    }
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
    my $expected_module_name = _expected_pipeline_module_name($entry);
    _assert_entry_hdl_shape(
        $entry,
        $result->{hdl_code},
        $args{owner},
        $expected_module_name,
    );
    if ($entry->{source_kind} eq 'ppif') {
        is(
            $result->{source_info}{generated_hdl_entry_artifact},
            _expected_pipeline_entry_artifact($entry, $expected_module_name),
            "$entry->{id} preserves the cataloged generated entry artifact through $args{owner}",
        );
    }
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

    _assert_entry_hdl_shape(
        $entry,
        $hdl,
        $args{owner},
        $entry->{expected_module_name},
    );
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
    my ($entry, $hdl, $owner, $expected_module_name) = @_;

    if ($entry->{source_kind} eq 'fsm'
        || $entry->{source_kind} eq 'dt'
        || $entry->{source_kind} eq 'isf'
        || $entry->{source_kind} eq 'ppif'
        || $entry->{source_kind} eq 'ial2_profile_alias') {
        like(
            $hdl,
            qr/\bmodule\s+\Q$expected_module_name\E\b/s,
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

sub _expected_pipeline_module_name {
    my ($entry) = @_;
    return $entry->{expected_pipeline_module_name}
        // $entry->{expected_module_name};
}

sub _expected_pipeline_entry_artifact {
    my ($entry, $expected_module_name) = @_;
    return $entry->{expected_pipeline_entry_artifact}
        // "$expected_module_name.fsm";
}
