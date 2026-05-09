#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use File::Spec;
use FindBin;
use IPC::Cmd qw(run);
use JSON::PP qw(decode_json encode_json);

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::Support::SerializableCompositionPlanSnapshot qw(
    serializable_composition_plan_snapshot_contract_source
    serializable_composition_plan_snapshot_public_top_level_keys
);

my $repo_root = File::Spec->catdir($FindBin::Bin, '..');

subtest 'semantic JSON embeds a serializable composition plan snapshot' => sub {
    my $composition_path = File::Spec->catfile($repo_root, 'fsm', 'apb_tb.fsm');
    my ($success, $error_message, $full_buf, $stdout_buf, $stderr_buf) = run(
        command => ['./bin/fsmgen', '--strict', '--emit-semantic-json', $composition_path],
    );

    ok($success, 'semantic JSON succeeds for the composition fixture');
    is(join('', @{$stderr_buf || []}), '', 'semantic JSON keeps stderr clean');

    my $decoded = decode_json(join('', @{$stdout_buf || []}));
    ok($decoded->{success}, 'semantic report marks success');

    my $snapshot = $decoded->{semantic}{composition}{plan_snapshot};
    ok($snapshot, 'semantic composition includes plan_snapshot');
    for my $key (@{serializable_composition_plan_snapshot_public_top_level_keys()}) {
        ok(exists $snapshot->{$key}, "plan_snapshot keeps key $key");
    }
    is($snapshot->{contract_source}, serializable_composition_plan_snapshot_contract_source(), 'plan_snapshot records contract owner');
    ok($snapshot->{present}, 'plan_snapshot records raw plan presence');
    is($snapshot->{lane}, 'C4', 'plan_snapshot records lane');
    is($snapshot->{top_name}, 'apb_tb', 'plan_snapshot records top name');
    is($snapshot->{summary}{instance_count}, 2, 'plan_snapshot records instance count');
    is_deeply(
        [map { $_->{instance_name} } @{$snapshot->{instances}}],
        [qw(requester completer)],
        'plan_snapshot records child instances',
    );
    ok(length(encode_json($snapshot)), 'embedded plan_snapshot encodes as JSON');
};

done_testing();
