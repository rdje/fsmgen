#!/usr/bin/env perl
use strict;
use warnings;
use utf8;
use Test::More;
use JSON::PP ();
use Storable qw(dclone);
use FindBin;
use lib "$FindBin::Bin/../perl";
use FSM::Support::SemanticIntrospectionMCPAdapter;

my $json = JSON::PP->new->canonical->allow_nonref;
my $adapter = FSM::Support::SemanticIntrospectionMCPAdapter->new(
    repo_root => '.', workspace_root => '.',
);
my $code = 'FSMGEN_COMPOSITION_CHILD_ITEM_LIST_SHAPE';
my %base = (
    fsmgen_capability_query => {section => 'semantic_introspection'},
    fsmgen_discover_sources => {query => 'axi', limit => 1},
    fsmgen_find_examples => {query => 'axi', limit => 1},
    fsmgen_explain_diagnostic => {code => $code, limit_examples => 1},
    fsmgen_support_summary => {limit_examples => 1},
);
my %fields = (
    fsmgen_capability_query => {section => 'string'},
    fsmgen_discover_sources => {map {$_ => 'string'} qw(query file_kind source_kind classification)},
    fsmgen_find_examples => {query => 'string', limit => 'integer'},
    fsmgen_explain_diagnostic => {code => 'string', limit_examples => 'integer'},
    fsmgen_support_summary => {limit_examples => 'integer'},
);
$fields{fsmgen_discover_sources}{limit} = 'integer';

sub exercise {
    my ($request, $wanted, $label, $client) = @_;
    $client ||= $adapter;
    # Decode anew before the first validation read. Ordinary JSON parity alone
    # cannot establish that a later Storable copy keeps the caller's kinds.
    $request = $json->decode($json->encode($request));
    my $before = $json->encode($request);
    my $clone_before = $json->encode(dclone($request));
    my $response = $client->handle_jsonrpc_request($request);
    is($json->encode($request), $before, "$label preserves caller values");
    is($json->encode(dclone($request)), $clone_before, "$label preserves later caller copies");
    if (defined $wanted) {
        is($response->{error}{code}, $wanted, "$label error class");
        ok(!exists $response->{result}, "$label has no result");
        unlike($response->{error}{message}, qr/(?:ARRAY|HASH|Boolean)\(0x[0-9a-f]+\)/i,
            "$label does not stringify a reference");
    } else {
        ok(exists $response->{result}, "$label succeeds");
        my $result = $response->{result};
        is($json->encode($json->decode($result->{content}[0]{text})),
            $json->encode($result->{structuredContent}), "$label complete text/structured parity");
        is($json->encode($result->{isError}), 'false', "$label metadata is successful");
    }
    return $response;
}

sub call_request {
    my ($name, $arguments) = @_;
    return {jsonrpc => '2.0', id => 1, method => 'tools/call',
        params => {name => $name, arguments => $arguments}};
}

subtest 'every published metadata field rejects other JSON kinds' => sub {
    my %tools = map {$_->{name} => $_} @{$adapter->list_tools->{tools}};
    for my $name (sort keys %fields) {
        my $schema = $tools{$name}{inputSchema};
        is_deeply({map {$_ => $schema->{properties}{$_}{type}} keys %{$schema->{properties}}},
            $fields{$name}, "$name explicit reviewed field population");
        for my $field (sort keys %{$fields{$name}}) {
            my @invalid = $fields{$name}{$field} eq 'string'
                ? ('null', 'false', 'true', '0', '1', '1.5', '[]', '{}')
                : ('null', 'false', 'true', '1.5', '"1"', '""', '"é"', '[]', '{}');
            for my $literal (@invalid) {
                my %arguments = (%{$base{$name}}, $field => $json->decode($literal));
                exercise(call_request($name, \%arguments), -32602, "$name $field=$literal");
            }
        }
        exercise(call_request($name, {%{$base{$name}}, unpublished_argument => 1}),
            -32602, "$name unknown field");
        exercise(call_request($name, $base{$name}), undef, "$name valid baseline");
    }
    exercise(call_request('fsmgen_explain_diagnostic', {}), -32602, 'required code missing');
    exercise(call_request('fsmgen_explain_diagnostic', {code => 'UNKNOWN_DIAGNOSTIC_FIXTURE'}),
        -32000, 'unknown string code keeps semantic refusal');
};

subtest 'tools call requires object params, a string name and optional object arguments' => sub {
    my @bad = ('null', 'false', 'true', '0', '1', '1.5', '[]', '""', '"1"', '"é"');
    for my $tool (@{$adapter->list_tools->{tools}}) {
        my $name = $tool->{name};
        for my $literal (@bad) {
            exercise(call_request($name, $json->decode($literal)), -32602,
                "$name arguments=$literal");
        }
    }
    for my $literal (@bad, '{}') {
        my $request = {jsonrpc => '2.0', id => 1, method => 'tools/call',
            params => $json->decode($literal)};
        exercise($request, -32602, "params=$literal");
    }
    exercise({jsonrpc => '2.0', id => 1, method => 'tools/call'}, -32602, 'params absent');
    for my $literal ('null', 'false', 'true', '0', '1', '1.5', '[]', '{}') {
        exercise(call_request($json->decode($literal), {}), -32602, "name=$literal");
    }
    exercise(call_request('fsmgen_unpublished_tool', {}), -32000,
        'unknown string tool keeps lookup refusal');
};

subtest 'integral numbers, defaults and internal resource aliases remain usable' => sub {
    for my $name (sort keys %fields) {
        for my $field (sort keys %{$fields{$name}}) {
            next unless $fields{$name}{$field} eq 'integer';
            for my $literal ('0', '1.0', '1e0', '-1', '1e30') {
                my %arguments = (%{$base{$name}}, $field => $json->decode($literal));
                exercise(call_request($name, \%arguments), undef, "$name $field=$literal");
            }
        }
        next if $name eq 'fsmgen_explain_diagnostic';
        my $request = call_request($name, {});
        delete $request->{params}{arguments};
        $request->{params}{_meta} = {progressToken => 'unused-extension'};
        my $omitted = exercise($request, undef, "$name arguments absent with metadata");
        is($json->encode($adapter->call_tool($name, undef)), $json->encode($omitted->{result}),
            "$name embedded undef retains optional default");
    }
    for my $pair (['fsmgen_find_examples', 'fsmgen://examples'],
                  ['fsmgen_discover_sources', 'fsmgen://sources']) {
        my ($tool, $uri) = @$pair;
        is($json->encode($adapter->call_tool($tool, {})->{structuredContent}),
            $json->encode($json->decode($adapter->read_resource($uri)->{contents}[0]{text})),
            "$tool and resource preserve complete default payload");
    }
    is($json->encode($adapter->call_tool('fsmgen_capability_query', {section => 'examples'})->{structuredContent}),
        $json->encode($adapter->call_tool('fsmgen_find_examples', {})->{structuredContent}),
        'capability examples alias is not subjected to another tool argument schema');
};

{
    package Local::ChangedMetadataSchema;
    our @ISA = ('FSM::Support::SemanticIntrospectionMCPAdapter');
    sub list_tools {
        my ($self) = @_;
        my $result = $self->SUPER::list_tools();
        my ($tool) = grep {$_->{name} eq 'fsmgen_support_summary'} @{$result->{tools}};
        $self->{change_schema}->($tool->{inputSchema});
        return $result;
    }
}
subtest 'unimplemented advertised constraints fail closed instead of being ignored' => sub {
    my @changes = (
        ['root constraint', sub {$_[0]{minProperties} = 1}],
        ['property constraint', sub {$_[0]{properties}{limit_examples}{minimum} = 2}],
        ['property type', sub {$_[0]{properties}{limit_examples}{type} = 'boolean'}],
        ['closed fields', sub {$_[0]{additionalProperties} = JSON::PP::true}],
        ['required declaration', sub {$_[0]{required} = ['undeclared_argument']}],
    );
    for my $change (@changes) {
        my $client = Local::ChangedMetadataSchema->new(repo_root => '.', workspace_root => '.');
        $client->{change_schema} = $change->[1];
        my $response = exercise(call_request('fsmgen_support_summary', {limit_examples => 1}),
            -32000, $change->[0], $client);
        like($response->{error}{message}, qr/Unsupported metadata input schema/,
            "$change->[0] names the unsupported producer contract");
    }
};

done_testing();
