#!/usr/bin/env perl
use strict;
use warnings;
use Cwd qw(abs_path);
use FindBin;
use IPC::Cmd ();
use JSON::PP qw(decode_json encode_json);
use Test::More;
use lib "$FindBin::Bin/../perl";
use FSM::ProjectDataLocality qw(create_project_tempdir);
use FSM::Support::CapabilityManifest qw(build_capability_manifest);
use FSM::Support::SemanticIntrospectionMCPAdapter;
use FSM::VIAL::Tool qw(check_vial_source_file vial_tool_capabilities vial_tool_capabilities_v2);

my $root = abs_path("$FindBin::Bin/..");
my $workspace = create_project_tempdir(purpose => 'mcp-vial-query');
my $manifest = build_capability_manifest();
my $runner_calls = 0;
sub adapter {
    return FSM::Support::SemanticIntrospectionMCPAdapter->new(
        repo_root => $root, workspace_root => $_[0], manifest_builder => sub { $manifest },
        runner => sub { ++$runner_calls; die 'VIAL must not use hardware runner'; });
}
my $repo_adapter = adapter($root);
my $local = adapter($workspace);
sub request {
    my ($adapter, $method, $params) = @_;
    return $adapter->handle_jsonrpc_request({jsonrpc => '2.0', id => 1, method => $method, params => $params});
}
sub checked_tool {
    my ($adapter, $kind, $args, $expected) = @_;
    my $response = request($adapter, 'tools/call', {name => $kind eq 'check' ? 'fsmgen_check' : 'fsmgen_semantic_introspect', arguments => $args});
    ok(!$response->{error}, "$kind VIAL query returns an MCP result") or return;
    my $result = $response->{result};
    is_deeply(decode_json($result->{content}[0]{text}), $result->{structuredContent}, 'text and structured content agree');
    my $payload = $result->{structuredContent};
    is_deeply($payload->{report}, $expected, 'complete native VIAL report is preserved, including semantic paths');
    is($payload->{query_kind}, $kind, 'requested query kind remains explicit');
    is($result->{isError} ? 1 : 0, $expected->{success} ? 0 : 1, 'tool failure flag follows native public result');
    is($payload->{adapter_provenance}{api_entrypoint}, 'FSM::VIAL::Tool::check_vial_source_file', 'provenance names actual public producer');
    ok(!defined($payload->{adapter_provenance}{command_shape}), 'provenance does not invent hardware argv');
    is_deeply($payload->{report}{artifacts}, [], 'MCP check publishes no artifact');
    unlike(encode_json($payload), qr/\Q$root\E|\Q$workspace\E/, 'result contains no machine-local workspace root');
    return $payload;
}
sub write_source {
    my ($name, $text) = @_;
    open my $fh, '>:raw', "$workspace/$name" or die $!;
    print {$fh} $text; close $fh or die $!;
}
sub read_source {
    open my $fh, '<:raw', $_[0] or die $!;
    local $/; my $text = <$fh>; close $fh or die $!; return $text;
}

subtest 'VIAL capability and catalog discovery preserve native contracts' => sub {
    for my $version (1, 2) {
        my $expected = $version == 1 ? vial_tool_capabilities() : vial_tool_capabilities_v2();
        my $response = request($repo_adapter, 'tools/call', {name => 'fsmgen_capability_query', arguments => {section => "vial_tooling_v$version"}});
        ok(!$response->{error}, "v$version capabilities are queryable");
        is_deeply($response->{result}{structuredContent}{payload}, $expected, 'capability tool preserves native versioned record');
        $response = request($repo_adapter, 'resources/read', {uri => "fsmgen://vial/$version/capabilities"});
        ok(!$response->{error}, "v$version capability resource exists");
        is_deeply(decode_json($response->{result}{contents}[0]{text}), $expected, 'resource preserves complete native capability record') if $response->{result};
    }
    my @catalog = grep { ($_->{relpath} // '') =~ /\.vial\z/ } @{$manifest->{support_accounting}{catalog_entries}};
    my $discovery = $repo_adapter->call_tool('fsmgen_discover_sources', {file_kind => 'vial', limit => 100})->{structuredContent};
    ok(@catalog, 'native catalog contains VIAL sources');
    is($discovery->{matched_count}, scalar(@catalog), 'VIAL discovery derives full native catalog count');
    my @visible = @catalog; splice @visible, 100 if @visible > 100;
    is_deeply([map { [$_->{source_id}, $_->{support}{id}] } @{$discovery->{sources}}], [map { [$_->{relpath}, $_->{id}] } @visible], 'bounded discovery keeps catalog identities and order');
    is_deeply($manifest->{semantic_introspection}{source_query_kinds}{vial}, [qw(check semantic)], 'native applicability excludes scheduling');
    my $tools = $repo_adapter->list_tools()->{tools};
    for my $tool (grep { $_->{name} =~ /\Afsmgen_(?:check|semantic_introspect)\z/ } @$tools) {
        is_deeply($tool->{inputSchema}{properties}{language_version}{enum}, [1, 2], 'tool declares explicit version choices');
    }
};

subtest 'actual native v1 v2 and lifecycle results match MCP tools and resources' => sub {
    for my $case ([1, 'vial/ahb_subordinate_base_output_arbitration.vial'],
                  [2, 'vial/ahb_subordinate_base_output_arbitration_v2.vial'],
                  [2, 'vial/ahb_subordinate_base_output_arbitration_lifecycle_v2.vial']) {
        my ($version, $source) = @$case;
        my ($ok, $error, $all, $stdout) = IPC::Cmd::run(command => ["$root/bin/fsmgen", 'vial', 'check', '--json', '--language-version', $version, $source]);
        ok($ok, "$source native query succeeds");
        my $expected = decode_json(join('', @{$stdout || []}));
        for my $kind (qw(check semantic)) {
            checked_tool($repo_adapter, $kind, {source_id => $source, language_version => $version}, $expected);
            my $uri = "fsmgen://vial/$version/source/$source/$kind";
            my $response = request($repo_adapter, 'resources/read', {uri => $uri});
            ok(!$response->{error}, 'versioned source resource succeeds');
            is_deeply(decode_json($response->{result}{contents}[0]{text})->{report}, $expected, 'resource preserves full native result') if $response->{result};
            if ($version == 1) {
                $response = request($repo_adapter, 'resources/read', {uri => "fsmgen://source/$source/$kind"});
                ok(!$response->{error}, 'unversioned VIAL resource defaults to v1');
                is_deeply(decode_json($response->{result}{contents}[0]{text})->{report}, $expected, 'default result is native v1') if $response->{result};
            }
        }
    }
    my $v2 = 'vial/ahb_subordinate_base_output_arbitration_lifecycle_v2.vial';
    my $default = check_vial_source_file({workspace_root => $root, source_id => $v2});
    ok(!$default->{success}, 'native default does not infer v2 from the filename');
    checked_tool($repo_adapter, 'semantic', {source_id => $v2}, $default);
    my $encoded = $v2; $encoded =~ s{/}{%2F}g;
    my $response = request($repo_adapter, 'resources/read', {uri => "fsmgen://vial/2/source/$encoded/check"});
    ok(!$response->{error}, 'versioned resource accepts percent-encoded source separators');
    is_deeply(decode_json($response->{result}{contents}[0]{text})->{report},
        check_vial_source_file({workspace_root => $root, source_id => $v2, language_version => 2}),
        'encoded resource retains the same full public result') if $response->{result};
};

subtest 'imported invalid and unsafe inputs preserve public refusal and path authority' => sub {
    for my $version (1, 2) {
        my $source = read_source("$root/vial/ahb_subordinate_base_output_arbitration" . ($version == 2 ? '_v2' : '') . '.vial');
        my $import = $source; $import =~ s/package ahb_subordinate_base_output_arbitration/package imported/ or die 'package marker absent';
        $source =~ s/\(imports\)/(imports (import shared "part.vial"))/ or die 'imports marker absent';
        write_source('root.vial', $source); write_source('part.vial', $import);
        my $expected = check_vial_source_file({workspace_root => $workspace, source_id => 'root.vial', language_version => $version});
        ok($expected->{success}, 'independent filesystem facade accepts imported source');
        checked_tool($local, 'semantic', {source_path => "$workspace/root.vial", language_version => $version}, $expected);
        is(read_source("$workspace/root.vial"), $source, 'root source is unchanged');
        is(read_source("$workspace/part.vial"), $import, 'imported source is unchanged');
        write_source('invalid.vial', '(');
        write_source('oversize.vial', ' ' x (vial_tool_capabilities()->{limits}{source_bytes} + 1));
        for my $id (qw(invalid.vial oversize.vial missing.vial linked.vial)) {
            if ($id eq 'linked.vial' && !-l "$workspace/$id") { symlink "$workspace/root.vial", "$workspace/$id" or die $!; }
            $expected = check_vial_source_file({workspace_root => $workspace, source_id => $id, language_version => $version});
            ok(!$expected->{success}, 'native input is refused');
            checked_tool($local, 'check', {source_id => $id, language_version => $version}, $expected);
        }
    }
    symlink $workspace, "$workspace/aliased" or die $!;
    for my $id ('aliased/root.vial', '../outside.vial') {
        my $expected = check_vial_source_file({workspace_root => $workspace, source_id => $id, language_version => 2});
        ok(!$expected->{success}, 'public facade rejects directory symlink or workspace escape');
        checked_tool($local, 'semantic', {source_id => $id, language_version => 2}, $expected);
    }
    my $linked_import = read_source("$workspace/root.vial");
    $linked_import =~ s/"part.vial"/"linked.vial"/ or die 'import marker absent';
    write_source('root.vial', $linked_import);
    my $expected = check_vial_source_file({workspace_root => $workspace, source_id => 'root.vial', language_version => 2});
    ok(!$expected->{success}, 'symlink import is unavailable to the public source catalog');
    checked_tool($local, 'semantic', {source_id => 'root.vial', language_version => 2}, $expected);
    opendir my $dir, $workspace or die $!;
    is_deeply([sort grep { $_ ne '.' && $_ ne '..' } readdir $dir], [sort qw(root.vial part.vial invalid.vial oversize.vial linked.vial aliased)], 'MCP creates no workspace artifact');
    closedir $dir or die $!;
};

subtest 'version selection is closed and never widens query authority' => sub {
    for my $args ({source_id => 'vial/x.vial', language_version => 3},
                  {source_id => 'vial/x.vial', language_version => JSON::PP::true},
                  {source_id => 'vial/x.vial', language_version => undef},
                  {source_id => 'fsm/ahb_lite_subordinate.fsm', language_version => 1},
                  {source_id => 'vial/x.vial', action => 'run'}, {source_id => []}) {
        my $response = request($repo_adapter, 'tools/call', {name => 'fsmgen_check', arguments => $args});
        is($response->{error}{code}, -32602, 'invalid selector/shape/action is invalid params before producer execution');
    }
    for my $uri ('fsmgen://vial/3/capabilities', 'fsmgen://vial/0/source/x.vial/check',
                 'fsmgen://vial/2/source/fsm/ahb_lite_subordinate.fsm/check') {
        my $response = request($repo_adapter, 'resources/read', {uri => $uri});
        is($response->{error}{code}, -32602, 'versioned resource rejects invalid version or source kind');
    }
    my $response = request($repo_adapter, 'tools/call', {name => 'fsmgen_schedule_preview', arguments => {source_id => 'vial/ahb_subordinate_base_output_arbitration.vial'}});
    is($response->{error}{code}, -32602, 'VIAL schedule fails before any producer');
    is($runner_calls, 0, 'no VIAL request invoked the hardware runner');
};

done_testing();
