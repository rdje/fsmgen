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
    runner => sub {
        my ($command) = @_;
        return {
            runner => 'stub',
            argv => [@{$command}],
            ok => JSON::PP::true,
        };
    },
);

subtest 'resources and templates do not advertise common annotations yet' => sub {
    for my $resource (@{$adapter->list_resources()->{resources}}) {
        ok(!exists $resource->{annotations}, "$resource->{uri} has no resource annotations");
    }

    for my $template (@{$adapter->list_resource_templates()->{resourceTemplates}}) {
        ok(!exists $template->{annotations}, "$template->{uriTemplate} has no template annotations");
    }
};

subtest 'resource read content blocks do not carry audience or timestamp annotations' => sub {
    for my $resource (@{$adapter->list_resources()->{resources}}) {
        my $read = $adapter->read_resource($resource->{uri});
        for my $content (@{$read->{contents}}) {
            ok(!exists $content->{annotations}, "$resource->{uri} content has no annotations");
            ok(!exists $content->{lastModified}, "$resource->{uri} content has no lastModified shortcut");
        }
    }
};

subtest 'tool result content remains plain text JSON without resource links' => sub {
    for my $case (
        ['fsmgen_capability_query', { section => 'semantic_introspection' }],
        ['fsmgen_check', { source_path => 'ppif/axi_aw_valid_ready.ppif' }],
        ['fsmgen_semantic_introspect', { source_path => 'ppif/axi_aw_valid_ready.ppif' }],
        ['fsmgen_schedule_preview', { source_path => 'ppif/axi_aw_valid_ready.ppif' }],
        ['fsmgen_find_examples', { query => 'composition', limit => 1 }],
        ['fsmgen_explain_diagnostic', { code => 'FSMGEN_COMPOSITION_CHILD_ITEM_LIST_SHAPE' }],
        ['fsmgen_support_summary', { limit_examples => 1 }],
    ) {
        my ($name, $arguments) = @{$case};
        my $response = $adapter->call_tool($name, $arguments);
        ok($response->{structuredContent}, "$name still carries structuredContent");

        for my $content (@{$response->{content}}) {
            is($content->{type}, 'text', "$name content remains text JSON");
            ok(!exists $content->{annotations}, "$name text content has no annotations");
            isnt($content->{type}, 'resource_link', "$name does not return resource links");
        }
    }
};

done_testing();
