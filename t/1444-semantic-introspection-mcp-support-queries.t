#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use Cwd qw(abs_path);
use File::Spec;
use FindBin;
use JSON::PP qw(decode_json);

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::Support::SemanticIntrospectionMCPAdapter;
use FSM::Support::SemanticIntrospectionContract qw(
    semantic_introspection_mcp_tool_names
    semantic_introspection_query_family_names
);

my $repo_root = abs_path(File::Spec->catdir($FindBin::Bin, '..'));
my $adapter = FSM::Support::SemanticIntrospectionMCPAdapter->new(
    repo_root => $repo_root,
    workspace_root => $repo_root,
);

subtest 'manifest contract advertises support-summary query and tool families' => sub {
    my %families = map { $_ => 1 } @{semantic_introspection_query_family_names()};
    ok($families{support_summary}, 'support_summary query family is advertised');

    my %tools = map { $_ => 1 } @{semantic_introspection_mcp_tool_names()};
    ok($tools{fsmgen_support_summary}, 'support-summary MCP tool is advertised');

    my $listed = $adapter->list_tools()->{tools};
    my %listed_tool = map { $_->{name} => $_ } @{$listed};
    ok($listed_tool{fsmgen_support_summary}, 'adapter lists support-summary tool');
    ok(!$listed_tool{fsmgen_write_generation}, 'adapter still does not list write/generation tool');
};

subtest 'support-summary tool returns bounded support-accounting aggregates and samples' => sub {
    my $payload = decode_tool_json($adapter->call_tool('fsmgen_support_summary', {
        limit_examples => 3,
    }));

    is($payload->{query_kind}, 'support_summary', 'support summary records query kind');
    ok($payload->{entry_count} > 0, 'support summary reports catalog entry count');
    ok($payload->{classifications}, 'support summary includes classification buckets');
    ok($payload->{coverage_buckets}, 'support summary includes coverage buckets');
    ok($payload->{families}, 'support summary includes family buckets');
    ok($payload->{source_kinds}, 'support summary includes source-kind buckets');
    ok($payload->{id_counts}{strict_supported_ids} > 0, 'support summary includes strict-supported id count');
    is(scalar @{$payload->{sample_catalog_entries}}, 3, 'support summary honors sample limit');

    for my $entry (@{$payload->{sample_catalog_entries}}) {
        ok($entry->{id}, 'sample entry has id');
        ok($entry->{relpath}, 'sample entry has repo-relative path');
        ok(!exists $entry->{expected_hdl_pattern_count}, 'sample entry omits nonessential catalog internals');
    }
};

subtest 'example discovery includes bounded support summary without catalog dump by default' => sub {
    my $payload = decode_tool_json($adapter->call_tool('fsmgen_find_examples', {
        query => 'composition',
        limit => 2,
    }));

    is($payload->{query}, 'composition', 'example query is preserved');
    is($payload->{returned_count}, 2, 'example result reports returned count');
    is(scalar @{$payload->{catalog_entries}}, 2, 'example result honors requested limit');
    is($payload->{support_summary}{query_kind}, 'support_summary', 'example result includes support summary');
    is(scalar @{$payload->{support_summary}{sample_catalog_entries}}, 0, 'embedded support summary does not dump samples');
};

subtest 'diagnostic explanation links stable codes to support-accounting examples' => sub {
    my $payload = decode_tool_json($adapter->call_tool('fsmgen_explain_diagnostic', {
        code => 'FSMGEN_COMPOSITION_CHILD_ITEM_LIST_SHAPE',
        limit_examples => 5,
    }));

    is($payload->{code}, 'FSMGEN_COMPOSITION_CHILD_ITEM_LIST_SHAPE', 'diagnostic code is preserved');
    ok($payload->{diagnostic}, 'diagnostic metadata is returned');
    ok(@{$payload->{support_examples}} >= 1, 'diagnostic returns matching support examples');
    for my $entry (@{$payload->{support_examples}}) {
        is($entry->{diagnostic_code}, 'FSMGEN_COMPOSITION_CHILD_ITEM_LIST_SHAPE', 'support example matches requested diagnostic code');
        ok($entry->{relpath}, 'support example has repo-relative path');
    }
};

done_testing();

sub decode_tool_json {
    my ($response) = @_;
    return decode_json($response->{content}[0]{text});
}
