#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use JSON::PP ();
use Storable qw(dclone);
use Digest::SHA qw(sha256_hex);
use Encode qw(decode FB_CROAK);
use FindBin;
use lib "$FindBin::Bin/../perl";
use FSM::Support::SemanticIntrospectionMCPAdapter;

my $json = JSON::PP->new->canonical->ascii->allow_nonref;
my $code = 'FSMGEN_COUNTERFACTUAL_LIMIT_FIXTURE';
my @entries = map { +{
    id => sprintf('counterfactual_%03d', $_),
    relpath => sprintf('counterfactual/catalog_%03d.fsm', $_),
    family => 'counterfactual_fixture', classification => 'counterfactual_fixture',
    coverage => 'counterfactual_fixture', source_kind => 'fsm',
    strict_supported => $_ % 2 ? JSON::PP::true : JSON::PP::false,
    diagnostic_code => $code,
    ($_ % 3 == 0 ? (expected_module_name => "counterfactual_module_$_") : ()),
} } 1 .. 121;
# This is a deliberately invented catalog, not actual support evidence. Its
# population distinguishes defaults, zero, the cap and unbounded example limits.
my $fixture = {
    documentation => {fixture => 'counterfactual_catalog'},
    diagnostics => {stable_codes => [{code => $code, meaning => 'counterfactual limit fixture'}],
        stable_code_registry => {fixture => 'counterfactual_registry'}},
    support_accounting => {
        source => 'counterfactual_catalog', entry_count => 121,
        classifications => {counterfactual_fixture => 121},
        coverage_buckets => {counterfactual_fixture => 121},
        families => {counterfactual_fixture => 121}, source_kinds => {fsm => 121},
        supported_smoke_ids => [], strict_supported_ids => [], expected_failure_ids => [],
        catalog_entries => \@entries,
    },
};
my $adapter = FSM::Support::SemanticIntrospectionMCPAdapter->new(
    repo_root => '.', workspace_root => '.', manifest_builder => sub {$fixture});
my $fixture_before = $json->encode($fixture);
my $fixture_copy_before = $json->encode(dclone($fixture));
my @tools = (
    ['fsmgen_explain_diagnostic', 'limit_examples'],
    ['fsmgen_support_summary', 'limit_examples'],
    ['fsmgen_discover_sources', 'limit'],
    ['fsmgen_find_examples', 'limit'],
);
# Explicit policy rows, reviewed before the implementation change. Positive
# example limits have no numeric cap; other positive samples cap at 100.
my @limits = (
    ['omitted', 10, 10, 25, 25], ['-1', 10, 10, 25, 25],
    ['0', 10, 0, 0, 25], ['0.0', 10, 0, 0, 25],
    ['1', 1, 1, 1, 1], ['1.0', 1, 1, 1, 1], ['1e0', 1, 1, 1, 1],
    ['10', 10, 10, 10, 10], ['25', 25, 25, 25, 25],
    ['100', 100, 100, 100, 100], ['101', 100, 100, 100, 101],
    ['121', 100, 100, 100, 121], ['122', 100, 100, 100, 122],
    ['1e30', 100, 100, 100, $json->decode('1e30')],
    ['1e300', 100, 100, 100, $json->decode('1e300')],
    map {[$_, undef, undef, undef, undef]} ('1.5', 'true', 'false', 'null', '"1"', '[]', '{}'),
);
my @compact = map { my $entry = $_; +{map {$_ => $entry->{$_}}
    qw(id relpath family classification coverage source_kind strict_supported diagnostic_code)} } @entries;
my $summary = {
    query_kind => 'support_summary', source => 'counterfactual_catalog', entry_count => 121,
    (map {$_ => $fixture->{support_accounting}{$_}} qw(classifications coverage_buckets families source_kinds)),
    id_counts => {supported_smoke_ids => 0, strict_supported_ids => 0, expected_failure_ids => 0},
    sample_catalog_entries => [],
};
my @sources = map { my $entry = $_; +{
    source_id => $entry->{relpath}, source_path => $entry->{relpath}, relpath => $entry->{relpath},
    file_kind => 'fsm', source_kind => 'fsm', available_query_kinds => ['check', 'semantic'],
    support => {map {$_ => $entry->{$_}} grep {exists $entry->{$_}}
        qw(id family classification coverage strict_supported diagnostic_code expected_module_name)},
} } @entries;
my (@cases, $input);
for my $tool_index (0 .. $#tools) {
    my ($name, $field) = @{$tools[$tool_index]};
    subtest "$name exact limit policy and complete records" => sub {
        for my $row (@limits) {
            my ($literal, $limit) = ($row->[0], $row->[$tool_index + 1]);
            my $arguments = $name eq 'fsmgen_explain_diagnostic' ? {code => $code} : {};
            $arguments->{$field} = '__LIMIT_LITERAL__' unless $literal eq 'omitted';
            my $raw = $json->encode({jsonrpc => '2.0', id => scalar(@cases),
                method => 'tools/call', params => {name => $name, arguments => $arguments}});
            $raw =~ s/"__LIMIT_LITERAL__"/$literal/ unless $literal eq 'omitted';
            $input .= "$raw\n";
            my $request = $json->decode($raw);
            my $before = $json->encode($request);
            my $copy_before = $json->encode(dclone($request));
            my $response = $adapter->handle_jsonrpc_request($request);
            is($json->encode($request), $before, "$literal caller unchanged");
            is($json->encode(dclone($request)), $copy_before, "$literal later caller copy unchanged");
            push @cases, {request_utf8 => $raw, input_literal => $literal, response => $response};
            if (!defined $limit) {
                is($response->{error}{code}, -32602, "$literal is the wrong JSON kind");
                next;
            }
            my $count = $limit > 121 ? 121 : $limit;
            my @sample = $count ? @compact[0 .. $count - 1] : ();
            my $wanted;
            if ($name eq 'fsmgen_explain_diagnostic') {
                $wanted = {code => $code, diagnostic => $fixture->{diagnostics}{stable_codes}[0],
                    registry_contract => $fixture->{diagnostics}{stable_code_registry}, support_examples => \@sample};
            } elsif ($name eq 'fsmgen_support_summary') {
                $wanted = {%$summary, sample_catalog_entries => \@sample};
            } elsif ($name eq 'fsmgen_discover_sources') {
                my @selected = $count ? @sources[0 .. $count - 1] : ();
                $wanted = {query_kind => 'source_discovery', source => 'counterfactual_catalog',
                    query => '', limit => $limit, filters => {file_kind => '', source_kind => '', classification => ''},
                    path_policy => {discovery_authority => 'manifest_support_catalog_only',
                        recursive_workspace_traversal => JSON::PP::false, hidden_paths => 'excluded',
                        source_identity => 'repo_or_workspace_relative', machine_local_absolute_paths => 'not_returned'},
                    total_catalog_count => 121, matched_count => 121, returned_count => $count, sources => \@selected};
            } else {
                my @selected = $count ? @entries[0 .. $count - 1] : ();
                $wanted = {documentation => $fixture->{documentation}, query => '', limit => $limit,
                    support_summary => $summary, returned_count => $count, catalog_entries => \@selected};
            }
            my $result = $response->{result} || {};
            is($json->encode($result->{structuredContent}), $json->encode($wanted),
                "$literal complete ordered records and JSON kinds");
            is($json->encode($json->decode($result->{content}[0]{text} // 'null')), $json->encode($wanted),
                "$literal complete text payload");
            is($json->encode($result->{isError}), 'false', "$literal metadata query succeeds");
        }
    };
}
subtest 'newline dispatcher conserves the complete API results' => sub {
    open my $in, '<', \$input or die $!;
    my $wire = '';
    open my $out, '>', \$wire or die $!;
    $adapter->run_stdio(in => $in, out => $out);
    close $in or die $!;
    close $out or die $!;
    my @replies = map {$json->decode($_)} split /\n/, $wire;
    is(scalar(@replies), scalar(@cases), 'one complete response per request');
    for my $index (0 .. $#cases) {
        my ($api, $stdio) = ($cases[$index]{response}, $replies[$index]);
        is($stdio->{id}, $api->{id}, 'request identity preserved');
        if (exists $api->{result}) {
            is($json->encode($stdio), $json->encode($api), 'complete typed success parity');
        } else {
            is($stdio->{error}{code}, $api->{error}{code}, 'same invalid-kind refusal class');
        }
    }
    is($json->encode($fixture), $fixture_before, 'counterfactual manifest unchanged');
    is($json->encode(dclone($fixture)), $fixture_copy_before, 'counterfactual manifest later copy unchanged');
    if ($ENV{FSMGEN_MCP_LIMIT_DETAILS}) {
        my (%hashes, %source);
        for my $path ('t/2103-mcp-metadata-integer-limits.t',
                      'perl/FSM/Support/SemanticIntrospectionMCPAdapter.pm',
                      'perl/FSM/Support/SemanticIntrospectionContract.pm') {
            open my $fh, '<:raw', $path or die "$path: $!";
            local $/;
            my $bytes = <$fh>;
            close $fh or die "$path: $!";
            $hashes{$path} = sha256_hex($bytes);
            $source{$path} = decode('UTF-8', $bytes, FB_CROAK);
        }
        note('MCP_LIMIT_EVIDENCE ' . $json->encode({fixture_kind => 'counterfactual_catalog',
            fixture => $fixture, cases => \@cases, sent_utf8 => $input, received_utf8 => $wire,
            source_sha256 => \%hashes, source_capsules => \%source,
            perl => "$^V", json_pp => $JSON::PP::VERSION, storable => $Storable::VERSION}));
    }
};
done_testing();
