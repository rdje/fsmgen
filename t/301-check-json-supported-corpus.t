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

use FSM::Support::RegressionCorpus qw(regression_corpus_entries);

my $repo_root = File::Spec->catdir($FindBin::Bin, '..');
my $tempdir = tempdir(CLEANUP => 1);

my @supported_entries = grep {
    $_->{classification} eq 'supported_smoke'
} regression_corpus_entries();

my @strict_entries = grep {
    $_->{strict_supported}
} @supported_entries;

ok(@supported_entries, 'corpus has supported-smoke entries for check JSON coverage');
ok(@strict_entries, 'corpus has strict-supported entries for strict check JSON coverage');

subtest 'check JSON accepts every supported-smoke corpus entry in default mode' => sub {
    for my $entry (@supported_entries) {
        assert_check_json_acceptance(
            $entry,
            owner => 'default check JSON',
            suffix => 'default',
        );
    }
};

subtest 'check JSON accepts every strict-supported corpus entry in strict mode' => sub {
    for my $entry (@strict_entries) {
        assert_check_json_acceptance(
            $entry,
            strict_mode => 1,
            owner => 'strict check JSON',
            suffix => 'strict',
        );
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

sub safe_filename_for_entry {
    my ($entry, $suffix) = @_;
    my $name = $entry->{id};
    $name =~ s/[^A-Za-z0-9_.-]+/_/g;
    return "$name.$suffix.sv";
}

sub assert_check_json_acceptance {
    my ($entry, %args) = @_;

    my $path = repo_path($entry->{relpath});
    my $out_path = File::Spec->catfile(
        $tempdir,
        safe_filename_for_entry($entry, $args{suffix} || 'check'),
    );
    my @command = ('./bin/fsmgen');
    push @command, '--strict' if $args{strict_mode};
    push @command, '--check-json', cli_path_args_for_entry($entry), '-o', $out_path, $path;

    my ($success, $error_message, $full_buf, $stdout_buf, $stderr_buf) = run(
        command => \@command,
    );

    ok($success, "$entry->{id} succeeds through $args{owner}");
    is(join('', @{$stderr_buf || []}), '', "$entry->{id} keeps stderr clean through $args{owner}");
    ok(!-e $out_path, "$entry->{id} emits no HDL through $args{owner}");

    my $stdout = join('', @{$stdout_buf || []});
    my $decoded = eval { decode_json($stdout) };
    ok($decoded, "$entry->{id} emits decodable success JSON through $args{owner}")
        or do {
            diag($stdout);
            return;
        };

    is($decoded->{check_schema_version}, 1, "$entry->{id} keeps check JSON schema version");
    ok($decoded->{success}, "$entry->{id} reports success true through $args{owner}");
    is($decoded->{command}{mode}, 'check', "$entry->{id} records check mode");
    ok($decoded->{command}{json}, "$entry->{id} records JSON mode");
    is(
        $decoded->{command}{strict_mode} ? 1 : 0,
        $args{strict_mode} ? 1 : 0,
        "$entry->{id} records strict-mode state through $args{owner}",
    );
    is($decoded->{source}{resolved_path}, File::Spec->rel2abs($path),
        "$entry->{id} records resolved source path through $args{owner}");
    is(scalar(@{$decoded->{diagnostics}}), 0, "$entry->{id} has no diagnostics through $args{owner}");
    ok($decoded->{support_accounting}{matched}, "$entry->{id} records matched support accounting");
    is($decoded->{support_accounting}{entry_id}, $entry->{id},
        "$entry->{id} records support-accounting entry id");
    is($decoded->{support_accounting}{family}, $entry->{family},
        "$entry->{id} records support-accounting family");
    is($decoded->{support_accounting}{coverage}, $entry->{coverage},
        "$entry->{id} records support-accounting coverage");
    is($decoded->{support_accounting}{classification}, $entry->{classification},
        "$entry->{id} records support-accounting classification");
    is($decoded->{support_accounting}{source_kind}, $entry->{source_kind},
        "$entry->{id} records support-accounting source kind");
    is($decoded->{support_accounting}{strict_supported} ? 1 : 0, $entry->{strict_supported} ? 1 : 0,
        "$entry->{id} records strict-supported support-accounting marker");
    ok(!$decoded->{generated_output}{emitted}, "$entry->{id} records no HDL emission");

    my $expected_module = $entry->{source_kind} eq 'composition'
        ? $entry->{expected_top_name}
        : $entry->{expected_module_name};
    is($decoded->{result}{module_name}, $expected_module,
        "$entry->{id} records checked module/top name through $args{owner}");

    if (defined $entry->{expected_check_composition_child_count}) {
        is(
            $decoded->{result}{composition_child_count},
            $entry->{expected_check_composition_child_count},
            "$entry->{id} records expected aggregate child count through $args{owner}",
        );
    }
    elsif ($entry->{source_kind} eq 'composition') {
        is(
            $decoded->{result}{composition_child_count},
            $entry->{expected_instance_count},
            "$entry->{id} records composition child count through $args{owner}",
        );
    }
}
