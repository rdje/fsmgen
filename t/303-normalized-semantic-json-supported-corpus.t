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

ok(@supported_entries, 'corpus has supported-smoke entries for semantic JSON coverage');
ok(@strict_entries, 'corpus has strict-supported entries for strict semantic JSON coverage');

subtest 'semantic JSON accepts every supported-smoke corpus entry in default mode' => sub {
    for my $entry (@supported_entries) {
        assert_semantic_json_acceptance(
            $entry,
            owner => 'default semantic JSON',
            suffix => 'default',
        );
    }
};

subtest 'semantic JSON accepts every strict-supported corpus entry in strict mode' => sub {
    for my $entry (@strict_entries) {
        assert_semantic_json_acceptance(
            $entry,
            strict_mode => 1,
            owner => 'strict semantic JSON',
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
    return "$name.$suffix.semantic.sv";
}

sub assert_semantic_json_acceptance {
    my ($entry, %args) = @_;

    my $path = repo_path($entry->{relpath});
    my $out_path = File::Spec->catfile(
        $tempdir,
        safe_filename_for_entry($entry, $args{suffix} || 'semantic'),
    );
    my @command = ('./bin/fsmgen');
    push @command, '--strict' if $args{strict_mode};
    push @command, '--emit-semantic-json', cli_path_args_for_entry($entry), '-o', $out_path, $path;

    my ($success, $error_message, $full_buf, $stdout_buf, $stderr_buf) = run(
        command => \@command,
    );

    ok($success, "$entry->{id} succeeds through $args{owner}");
    is(join('', @{$stderr_buf || []}), '', "$entry->{id} keeps stderr clean through $args{owner}");
    ok(!-e $out_path, "$entry->{id} emits no HDL through $args{owner}");

    my $stdout = join('', @{$stdout_buf || []});
    my $decoded = eval { decode_json($stdout) };
    ok($decoded, "$entry->{id} emits decodable semantic JSON through $args{owner}")
        or do {
            diag($error_message || 'semantic JSON command failed without an IPC error message');
            diag(join('', @{$stderr_buf || []}));
            diag($stdout);
            return;
        };

    my $expected_module = expected_module_for_entry($entry);
    my $expected_root_kind = expected_root_kind_for_entry($entry);

    is($decoded->{normalized_semantic_schema_version}, 1,
        "$entry->{id} keeps semantic JSON schema version");
    ok($decoded->{success}, "$entry->{id} reports success true through $args{owner}");
    is($decoded->{command}{mode}, 'semantic_export', "$entry->{id} records semantic export mode");
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
    ok(!exists $decoded->{hdl_code}, "$entry->{id} does not expose generated HDL text");
    ok(!exists $decoded->{raw_ast}, "$entry->{id} does not expose private raw AST");

    my $semantic = $decoded->{semantic};
    is(ref($semantic), 'HASH', "$entry->{id} exposes a semantic payload");
    is($semantic->{module}{name}, $expected_module,
        "$entry->{id} records semantic module/top name through $args{owner}");
    is($semantic->{module}{source_root_kind}, $expected_root_kind,
        "$entry->{id} records semantic root kind through $args{owner}");
    is(ref($semantic->{signal_analysis}), 'HASH',
        "$entry->{id} exposes sanitized signal analysis through $args{owner}");

    my $forward_ir = $semantic->{forward_ir} || {};
    is($forward_ir->{intent_hir}{module_name}, $expected_module,
        "$entry->{id} exposes intent HIR module/top name through $args{owner}");
    is($forward_ir->{intent_hir}{source_root_kind}, $expected_root_kind,
        "$entry->{id} exposes intent HIR root kind through $args{owner}");
    is($forward_ir->{structural_rtl_ir}{module_name}, $expected_module,
        "$entry->{id} exposes structural RTL IR module/top name through $args{owner}");
    is(ref($forward_ir->{lowered_rtl_ir}), 'HASH',
        "$entry->{id} exposes sanitized lowered RTL IR through $args{owner}");

    if ($entry->{source_kind} eq 'composition') {
        ok($semantic->{composition}, "$entry->{id} exposes composition metadata through $args{owner}");
        is(
            $semantic->{composition}{child_count},
            $entry->{expected_instance_count},
            "$entry->{id} records composition child count through $args{owner}",
        );
        assert_expected_child_modules($entry, $semantic->{composition}{children});
    }
    else {
        ok(!exists $semantic->{composition},
            "$entry->{id} omits composition metadata for direct roots through $args{owner}");
    }
}

sub expected_module_for_entry {
    my ($entry) = @_;
    return $entry->{source_kind} eq 'composition'
        ? $entry->{expected_top_name}
        : $entry->{expected_module_name};
}

sub expected_root_kind_for_entry {
    my ($entry) = @_;
    return $entry->{source_kind} eq 'composition'
        ? 'top'
        : $entry->{source_kind};
}

sub assert_expected_child_modules {
    my ($entry, $children) = @_;
    return unless ref($entry->{expected_child_modules}) eq 'ARRAY';

    my %seen_modules = map {
        $_->{module_name} => 1
    } grep {
        ref($_) eq 'HASH' && defined $_->{module_name}
    } @{ $children || [] };

    for my $module_name (@{$entry->{expected_child_modules}}) {
        ok($seen_modules{$module_name}, "$entry->{id} exposes child module $module_name in semantic JSON");
    }
}
