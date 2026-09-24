#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use Cwd qw(abs_path);
use FindBin;
use JSON::PP qw(decode_json encode_json);
use IPC::Cmd ();
use lib "$FindBin::Bin/../perl";
use FSM::Support::CapabilityManifest qw(build_capability_manifest);
use FSM::Support::SemanticIntrospectionContract qw(build_semantic_introspection_contract);
use FSM::Support::SemanticIntrospectionSection qw(build_semantic_introspection_section);
use FSM::Support::SemanticIntrospectionMCPAdapter;

my $root = abs_path("$FindBin::Bin/..");
my $manifest = build_capability_manifest();
my $adapter = FSM::Support::SemanticIntrospectionMCPAdapter->new(
    repo_root => $root, workspace_root => $root, manifest_builder => sub { $manifest },
);
my $expected = { fsm => [qw(check semantic)], vial => [qw(check semantic inspection)],
    map { $_ => [qw(check semantic schedule)] } qw(isf ppif axi apb ahb) };

subtest 'public query applicability covers current shipped suffixes' => sub {
    my $contract = build_semantic_introspection_contract();
    my $section = build_semantic_introspection_section();
    is_deeply($contract->{source_query_kinds}, $expected, 'native contract declares exact source/query applicability');
    is_deeply($section->{source_query_kinds}, $expected, 'native section exposes applicability');
    is_deeply($manifest->{semantic_introspection}{source_query_kinds}, $expected, 'manifest exposes the same map');
    ok(grep { $_ eq 'source_query_kinds' } @{$contract->{public_top_level_presence_keys}}, 'public presence keys include applicability');
    my @shipped = sort map { s/^\.//r }
        @{$manifest->{language_surface}{file_surfaces}{shipped_suffixes}};
    is_deeply([sort keys %{$contract->{source_query_kinds} || {}}], \@shipped,
        'new shipped suffixes cannot be silently omitted');
    my $accessor = FSM::Support::SemanticIntrospectionContract->can('semantic_introspection_source_query_kinds');
    ok($accessor, 'native applicability accessor is public');
    if ($accessor) {
        my $first = $accessor->();
        push @{$first->{ppif}}, 'mutated'; delete $first->{axi};
        is_deeply($accessor->(), $expected, 'fresh map survives caller mutation');
        is_deeply($first->{apb}, $expected->{apb}, 'aliases do not share mutable arrays');
    }
};

subtest 'every protocol-alias catalog record is discoverable with original support identity' => sub {
    for my $kind (qw(axi apb ahb)) {
        my @catalog = grep { ($_->{relpath} // '') =~ /\.\Q$kind\E\z/i }
            @{$manifest->{support_accounting}{catalog_entries}};
        ok(@catalog, "$kind native catalog has coverage");
        my $response = $adapter->call_tool('fsmgen_discover_sources', { file_kind => uc($kind), limit => 100 });
        my $payload = $response->{structuredContent};
        is_deeply(decode_json($response->{content}[0]{text}), $payload, "$kind text/structured discovery agrees");
        is($payload->{matched_count}, scalar(@catalog), "$kind derives full matching count from native catalog");
        is_deeply([map { [$_->{source_id}, $_->{support}{id}] } @{$payload->{sources}}],
                  [map { [$_->{relpath}, $_->{id}] } @catalog], "$kind retains complete catalog order and identity");
        for my $entry (@{$payload->{sources}}) {
            is($entry->{file_kind}, $kind, 'alias file kind is explicit');
            is_deeply($entry->{available_query_kinds}, [qw(check semantic schedule)], 'alias advertises all PPIF query kinds');
        }
        my $limited = $adapter->call_tool('fsmgen_discover_sources', {file_kind => $kind, limit => 1})->{structuredContent};
        is($limited->{returned_count}, 1, "$kind respects bounded result limit");
        is($limited->{matched_count}, scalar(@catalog), "$kind keeps full count under limit");
    }
};

subtest 'alias discovery keeps path exclusions and catalog filters' => sub {
    my @entries = map { { id => $_->[0], relpath => $_->[1], source_kind => 'protocol', classification => 'fixture' } } (
        ['public', 'inputs/port.APB'], ['hidden', '.secret/port.apb'], ['escape', '../port.ahb'],
        ['absolute', '/private/port.axi'], ['unknown', 'inputs/port.chi'], ['vial', 'inputs/case.vial'],
    );
    my $local = FSM::Support::SemanticIntrospectionMCPAdapter->new(
        repo_root => $root, workspace_root => $root,
        manifest_builder => sub { { support_accounting => { catalog_entries => \@entries } } },
    );
    my $resource = $local->read_resource('fsmgen://sources');
    my $payload = decode_json($resource->{contents}[0]{text});
    is_deeply([map { $_->{source_id} } @{$payload->{sources}}], ['inputs/port.APB', 'inputs/case.vial'], 'resource admits supported alias and VIAL source families');
    my $filtered = $local->call_tool('fsmgen_discover_sources', {
        file_kind => 'apb', query => 'PORT', source_kind => 'protocol', classification => 'fixture', limit => 1,
    })->{structuredContent};
    is($filtered->{returned_count}, 1, 'case-insensitive identity query combines with support filters');
    my $none = $local->call_tool('fsmgen_discover_sources', {file_kind => 'apb', classification => 'other'})->{structuredContent};
    is($none->{returned_count}, 0, 'support filter rejects a nonmatching record');
};

sub relative_report {
    my ($value) = @_;
    return { map { $_ => relative_report($value->{$_}) } keys %$value } if ref($value) eq 'HASH';
    return [map { relative_report($_) } @$value] if ref($value) eq 'ARRAY';
    return $value if !defined($value) || ref($value);
    $value =~ s{\Q$root/\E}{}g;
    return $value;
}

subtest 'advertised aliases have real native and MCP query parity' => sub {
    for my $source (qw(ppif/axi_aw_valid_ready.axi ppif/apb_requester_transfer.apb ppif/ahb_lite_subordinate.ahb)) {
        for my $query (
            ['check', 'fsmgen_check', '--strict', '--check', '--json'],
            ['semantic', 'fsmgen_semantic_introspect', '--strict', '--emit-semantic-json'],
            ['schedule', 'fsmgen_schedule_preview', '--emit-schedule-json'],
        ) {
            my ($kind, $tool, @flags) = @$query;
            my ($ok, $error, $all, $stdout) = IPC::Cmd::run(command => ["$root/bin/fsmgen", @flags, "$root/$source"]);
            ok($ok, "$source $kind native query succeeds");
            my $native = decode_json(join('', @{$stdout || []}));
            my $response = $adapter->handle_jsonrpc_request({jsonrpc => '2.0', id => 1,
                method => 'tools/call', params => {name => $tool, arguments => {source_id => $source}}});
            ok(!exists($response->{error}) && !$response->{result}{isError}, "$source $kind MCP query succeeds");
            my $payload = $response->{result}{structuredContent};
            is($payload->{query_kind}, $kind, 'query identity is accurate');
            is_deeply($payload->{report}, relative_report($native), "$source $kind preserves the complete native report");
            unlike(encode_json($payload), qr/\Q$root\E/, 'machine-local repository root is absent');
        }
    }
};

done_testing();
