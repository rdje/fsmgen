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

my $repo_root = abs_path(File::Spec->catdir($FindBin::Bin, '..'));
my $adapter = FSM::Support::SemanticIntrospectionMCPAdapter->new(
    repo_root => $repo_root,
    workspace_root => $repo_root,
    runner => sub {
        my ($command) = @_;
        return {
            runner => 'stub',
            argv => [@{$command}],
            ok => JSON::PP::true,
        };
    },
);

subtest 'tool calls return structuredContent plus text JSON compatibility' => sub {
    for my $case (
        ['fsmgen_capability_query', { section => 'semantic_introspection' }, 'section'],
        ['fsmgen_support_summary', { limit_examples => 1 }, 'query_kind'],
        ['fsmgen_check', { source_path => 'ppif/axi_aw_valid_ready.ppif' }, 'adapter_provenance'],
    ) {
        my ($name, $arguments, $required_key) = @{$case};
        my $response = $adapter->call_tool($name, $arguments);
        my $text_payload = decode_json($response->{content}[0]{text});

        is($response->{content}[0]{type}, 'text', "$name keeps text JSON content");
        ok(
            $response->{structuredContent}{$required_key},
            "$name returns structuredContent",
        );
        is_deeply(
            $response->{structuredContent},
            $text_payload,
            "$name structuredContent matches serialized JSON payload",
        );
        ok(!$response->{isError}, "$name remains a successful tool result");
    }
};

subtest 'tool descriptors expose compact public outputSchema envelopes' => sub {
    my $tools = $adapter->list_tools()->{tools};

    for my $tool (@{$tools}) {
        my $schema = $tool->{outputSchema};
        ok($schema, "$tool->{name} has an outputSchema");
        is($schema->{type}, 'object', "$tool->{name} outputSchema is an object");
        ok($schema->{properties}, "$tool->{name} outputSchema names public fields");
    }
};

done_testing();
