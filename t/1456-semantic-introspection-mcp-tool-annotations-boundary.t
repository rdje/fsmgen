#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use Cwd qw(abs_path);
use File::Spec;
use FindBin;
use JSON::PP;

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::Support::SemanticIntrospectionMCPAdapter;

my $repo_root = abs_path(File::Spec->catdir($FindBin::Bin, '..'));
my $adapter = FSM::Support::SemanticIntrospectionMCPAdapter->new(
    repo_root => $repo_root,
    workspace_root => $repo_root,
);

subtest 'read-only tools advertise closed-world safety annotations' => sub {
    my $tools = $adapter->list_tools()->{tools};

    ok(@{$tools}, 'tool list is non-empty');
    for my $tool (@{$tools}) {
        my $annotations = $tool->{annotations};
        ok($annotations, "$tool->{name} has tool annotations");
        is_deeply(
            [sort keys %{$annotations}],
            [qw(openWorldHint readOnlyHint)],
            "$tool->{name} keeps annotation surface narrow",
        );
        ok($annotations->{readOnlyHint}, "$tool->{name} is annotated read-only");
        ok(!$annotations->{openWorldHint}, "$tool->{name} is annotated closed-world");
        ok(
            !exists $annotations->{destructiveHint},
            "$tool->{name} does not set write-only destructive hint",
        );
        ok(
            !exists $annotations->{idempotentHint},
            "$tool->{name} does not set write-only idempotent hint",
        );
    }
};

subtest 'annotations do not widen call result authority' => sub {
    my $result = $adapter->call_tool(
        'fsmgen_capability_query',
        { section => 'semantic_introspection' },
    );
    my $payload = $result->{structuredContent};

    ok(!$payload->{payload}{write_generation_tools_enabled}, 'write tools remain disabled');
    ok($payload->{payload}{read_only_default}, 'semantic-introspection contract remains read-only by default');
    ok(!$result->{isError}, 'annotated tool still returns a successful read-only result');
};

done_testing();
