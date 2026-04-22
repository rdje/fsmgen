#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use File::Spec;
use FindBin;
use IPC::Cmd qw(run);
use JSON::PP qw(decode_json);

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::Support::CapabilityManifest qw(build_capability_manifest);
use FSM::Support::SupportAccountingSection qw(build_support_accounting_section);

my $repo_root = File::Spec->rel2abs(File::Spec->catdir($FindBin::Bin, '..'));
my $expected_section = build_support_accounting_section();

my @manifest_views = (
    {
        label => 'in-process capability manifest',
        section => build_capability_manifest()->{support_accounting},
    },
    {
        label => 'CLI capability manifest',
        section => run_capability_manifest('--capability-manifest')->{support_accounting},
    },
    {
        label => 'CLI alias capability manifest',
        section => run_capability_manifest('--emit-capability-manifest')->{support_accounting},
    },
);

subtest 'support-accounting section keeps exact dedicated-builder parity' => sub {
    for my $view (@manifest_views) {
        is_deeply(
            $view->{section},
            $expected_section,
            "$view->{label} keeps support_accounting as an exact dedicated-builder projection",
        );
    }
};

subtest 'published support-accounting ids and paths stay safe, unique, and present on disk' => sub {
    for my $view (@manifest_views) {
        my $section = $view->{section};
        my $label = $view->{label};
        my $catalog_entries = $section->{catalog_entries};

        ok(ref($catalog_entries) eq 'ARRAY', "$label keeps catalog_entries as an array");
        is($section->{entry_count}, scalar(@{$catalog_entries || []}), "$label keeps entry_count aligned with catalog_entries");

        my %catalog_ids;
        for my $entry (@{$catalog_entries || []}) {
            my $id = $entry->{id};
            ok(defined $id && !ref($id) && length $id, "$label keeps catalog entry ids non-empty");
            ok(!$catalog_ids{$id}++, "$label keeps catalog entry id $id unique");

            assert_relative_repo_file(
                $entry->{relpath},
                "$label keeps catalog entry $id relpath safe and present",
            );

            my %seen_search_paths;
            for my $search_path (@{$entry->{search_path_relpaths} || []}) {
                ok(!$seen_search_paths{$search_path}++, "$label keeps catalog entry $id search path $search_path unique");
                assert_relative_repo_directory(
                    $search_path,
                    "$label keeps catalog entry $id search path safe and present",
                );
            }
        }

        assert_id_list_matches_catalog(
            $section->{supported_smoke_ids},
            \%catalog_ids,
            "$label keeps supported_smoke_ids unique and catalog-backed",
        );
        assert_id_list_matches_catalog(
            $section->{strict_supported_ids},
            \%catalog_ids,
            "$label keeps strict_supported_ids unique and catalog-backed",
        );
        assert_id_list_matches_catalog(
            $section->{expected_failure_ids},
            \%catalog_ids,
            "$label keeps expected_failure_ids unique and catalog-backed",
        );
    }
};

done_testing();

sub run_capability_manifest {
    my ($mode) = @_;
    my ($success, $error_message, $full_buf, $stdout_buf, $stderr_buf) = run(
        command => ['./bin/fsmgen', $mode],
    );

    ok($success, "$mode succeeds");
    is(join('', @{$stderr_buf || []}), '', "$mode keeps stderr clean");

    return decode_json(join('', @{$stdout_buf || []}));
}

sub assert_id_list_matches_catalog {
    my ($ids, $catalog_ids, $label) = @_;

    ok(ref($ids) eq 'ARRAY', "$label: id list stays an array");

    my %seen;
    for my $id (@{$ids || []}) {
        ok(!$seen{$id}++, "$label: id $id stays unique");
        ok($catalog_ids->{$id}, "$label: id $id exists in catalog_entries");
    }
}

sub assert_relative_repo_file {
    my ($path, $label) = @_;

    ok(defined $path && !ref($path) && length $path, "$label: path stays non-empty");
    ok($path !~ m{\A/}, "$label: path stays relative");
    ok(index($path, '..') == -1, "$label: path stays free of parent traversal");

    my $abs_path = File::Spec->catfile($repo_root, split m{/}, $path);
    ok(-f $abs_path, "$label: path exists on disk as a file");
}

sub assert_relative_repo_directory {
    my ($path, $label) = @_;

    ok(defined $path && !ref($path) && length $path, "$label: path stays non-empty");
    ok($path !~ m{\A/}, "$label: path stays relative");
    ok(index($path, '..') == -1, "$label: path stays free of parent traversal");

    my $abs_path = File::Spec->catdir($repo_root, split m{/}, $path);
    ok(-d $abs_path, "$label: path exists on disk as a directory");
}
