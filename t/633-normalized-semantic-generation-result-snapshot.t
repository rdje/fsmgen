#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use File::Spec;
use FindBin;
use IPC::Cmd qw(run);
use JSON::PP qw(decode_json encode_json);

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::Support::SerializableGenerationResultSnapshot qw(
    serializable_generation_result_snapshot_contract_source
    serializable_generation_result_snapshot_public_top_level_keys
);

my $repo_root = File::Spec->catdir($FindBin::Bin, '..');

subtest 'direct semantic JSON embeds a generation result snapshot' => sub {
    my $decoded = semantic_json(File::Spec->catfile($repo_root, 'fsm', 'apb_requester.fsm'));
    my $snapshot = $decoded->{generation_result_snapshot};

    assert_snapshot_shell($snapshot);
    is($snapshot->{summary}{module_name}, 'apb_requester', 'direct snapshot records module name');
    is($snapshot->{summary}{source_root_kind}, 'fsm', 'direct snapshot records root kind');
    ok($snapshot->{semantic_layer_presence}{intent_hir}, 'direct snapshot records semantic layer presence');
    ok(!$snapshot->{raw_shell_presence}{composition_plan}{present}, 'direct snapshot records absent composition plan shell');
    ok(length(encode_json($snapshot)), 'direct embedded snapshot encodes as JSON');
};

subtest 'composition semantic JSON embeds a generation result snapshot' => sub {
    my $decoded = semantic_json(File::Spec->catfile($repo_root, 'fsm', 'apb_tb.fsm'));
    my $snapshot = $decoded->{generation_result_snapshot};

    assert_snapshot_shell($snapshot);
    is($snapshot->{summary}{module_name}, 'apb_tb', 'composition snapshot records module name');
    is($snapshot->{summary}{source_root_kind}, 'top', 'composition snapshot records root kind');
    is($snapshot->{summary}{composition_child_count}, 2, 'composition snapshot records child count');
    ok($snapshot->{raw_shell_presence}{composition_plan}{present}, 'composition snapshot records composition plan shell presence');
    is($snapshot->{raw_shell_presence}{composition_plan}{value_ref}, 'FSM::Composition::Plan', 'composition snapshot records raw plan class metadata');
    ok(length(encode_json($snapshot)), 'composition embedded snapshot encodes as JSON');
};

done_testing();

sub semantic_json {
    my ($path) = @_;
    my ($success, $error_message, $full_buf, $stdout_buf, $stderr_buf) = run(
        command => ['./bin/fsmgen', '--strict', '--emit-semantic-json', $path],
    );

    ok($success, "semantic JSON succeeds for $path");
    is(join('', @{$stderr_buf || []}), '', "semantic JSON keeps stderr clean for $path");

    my $decoded = decode_json(join('', @{$stdout_buf || []}));
    ok($decoded->{success}, "semantic JSON reports success for $path");
    return $decoded;
}

sub assert_snapshot_shell {
    my ($snapshot) = @_;
    ok($snapshot, 'semantic report includes generation_result_snapshot');
    for my $key (@{serializable_generation_result_snapshot_public_top_level_keys()}) {
        ok(exists $snapshot->{$key}, "generation_result_snapshot keeps key $key");
    }
    is(
        $snapshot->{contract_source},
        serializable_generation_result_snapshot_contract_source(),
        'generation_result_snapshot records contract owner',
    );
    ok($snapshot->{present}, 'generation_result_snapshot records result presence');
}
