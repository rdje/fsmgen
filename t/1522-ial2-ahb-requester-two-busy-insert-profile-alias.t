#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use Cwd qw(abs_path);
use File::Spec;
use File::Temp qw(tempdir);
use FindBin;
use IPC::Cmd qw(run);
use JSON::PP qw(decode_json);

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::Adapter::IAL2::PPIF;
use FSM::Support::SemanticIntrospectionMCPAdapter;

my $repo_root = abs_path(File::Spec->catdir($FindBin::Bin, '..'));

subtest 'exact-two requester .ahb alias mirrors generic source, lowering, and report' => sub {
    ok(-f alias_path(), 'tracked exact-two requester .ahb alias exists');
    is(slurp(alias_path()), slurp(ppif_path()), '.ahb source is byte-identical to generic .ppif source');

    my $alias = FSM::Adapter::IAL2::PPIF->new()->parse_file(alias_path());
    my $ppif = FSM::Adapter::IAL2::PPIF->new()->parse_file(ppif_path());

    is($alias->{layer}, 'IAL2', 'alias remains an IAL2 source');
    is($alias->{kind}, 'protocol_intent.ahb_requester', 'alias keeps AHB requester kind');
    is($alias->{mode}, 'requester', 'alias keeps requester mode');
    is($alias->{generated_ial1}{name}, 'amba_requester_busy_insert_two.isf', 'alias exposes exact-two IAL1 artifact');
    is($alias->{generated_ial1}{text}, $ppif->{generated_ial1}{text}, 'alias and generic source generate identical IAL1');
    is_deeply($alias->{generated_ial0}{files}, $ppif->{generated_ial0}{files}, 'alias and generic source generate identical IAL0 files');
    is_deeply(
        $alias->{generated_ial0}{files},
        {'amba_requester_busy_insert_two.fsm' => $ppif->{generated_ial0}{files}{'amba_requester_busy_insert_two.fsm'}},
        'alias keeps exact-two IAL0 artifact text',
    );

    is($alias->{report}{schema}, 'fsmgen.ial2.protocol_intent.ahb_requester.v1', 'alias keeps requester report schema');
    is($alias->{report}{source_object}{id}, 'fsmgen-ahb-requester-busy-insert-two', 'alias preserves source object');
    is($alias->{report}{source_object}{intent_name}, 'ahb_requester_busy_insert_two', 'alias preserves intent name');
    is($alias->{report}{busy_insertion}{generated_behavior}, 1, 'alias preserves generated BUSY behavior marker');
    is($alias->{report}{busy_insertion}{htrans_busy_encoding}, "2'b01", 'alias exposes BUSY encoding');
    is($alias->{report}{busy_insertion}{before_beat}, 2, 'alias exposes insertion index');
    is($alias->{report}{busy_insertion}{beats}, 2, 'alias keeps numeric exact-two event count');
    is($alias->{report}{layering}{direct_ial2_to_ial0}, 0, 'alias still lowers through IAL1');

    my %alias_residue = map { $_->{id} => $_->{detail} } @{$alias->{report}{unsupported_residue}};
    my %ppif_residue = map { $_->{id} => $_->{detail} } @{$ppif->{report}{unsupported_residue}};
    ok(!exists $alias_residue{ahb_profile_alias_deferred}, 'alias removes source-surface profile-alias residue');
    ok($ppif_residue{ahb_profile_alias_deferred}, 'generic source keeps alias-deferred residue');
    is(
        $alias_residue{ahb_requester_busy_insert_support},
        $ppif_residue{ahb_requester_busy_insert_support},
        'alias and generic source keep identical exact-two BUSY support residue',
    );
    like($alias->{generated_ial1}{text}, qr/\(var ahb_busy_remaining_q \(width 2\) \(reset 0\)\)/, 'alias keeps exact-two actor-owned counter');
};

subtest 'check, semantic JSON, and read-only MCP expose alias support identity' => sub {
    my $check = run_json_command('./bin/fsmgen', '--quiet', '--strict', '--check', '--json', alias_path());
    ok($check->{success}, 'strict alias check succeeds');
    is($check->{source}{resolved_path}, File::Spec->rel2abs(alias_path()), 'check JSON reports alias source path');
    is($check->{result}{module_name}, 'amba_requester_busy_insert_two', 'check JSON reports exact-two module');
    is($check->{support_accounting}{entry_id}, 'intent.ahb_profile_alias_requester_busy_insert_two', 'check JSON reports alias support identity');
    is($check->{support_accounting}{coverage}, 'ial2_ahb_profile_alias_requester_busy_insert_two_pipeline_cli', 'check JSON reports alias coverage');
    is($check->{support_accounting}{source_kind}, 'ial2_profile_alias', 'check JSON records profile-alias source kind');

    my $semantic = run_json_command('./bin/fsmgen', '--quiet', '--strict', '--emit-semantic-json', alias_path());
    assert_semantic_payload($semantic, 'semantic JSON');

    my $adapter = FSM::Support::SemanticIntrospectionMCPAdapter->new(
        repo_root => $repo_root,
        workspace_root => $repo_root,
    );
    my $mcp = decode_json(
        $adapter->call_tool(
            'fsmgen_semantic_introspect',
            { source_path => 'ppif/ahb_requester_busy_insert_two.ahb' },
        )->{content}[0]{text},
    );
    is($mcp->{query_kind}, 'semantic', 'MCP dispatches through bounded semantic query');
    is($mcp->{source_id}, 'ppif/ahb_requester_busy_insert_two.ahb', 'MCP keeps repo-relative alias identity');
    ok($mcp->{adapter_provenance}{read_only}, 'MCP provenance remains read-only');
    ok(!$mcp->{adapter_provenance}{shell_access}, 'MCP provenance keeps shell access disabled');
    assert_semantic_payload($mcp->{report}, 'MCP semantic report');
};

subtest 'schedule, review artifacts, HDL, and verifier preserve exact-two identity' => sub {
    my $schedule = run_json_command('./bin/fsmgen', '--quiet', '--emit-schedule-json', alias_path());
    is($schedule->{schema}, 'fsmgen.ial2.protocol_intent.ahb_requester.v1', 'schedule JSON keeps requester schema');
    is($schedule->{busy_insertion}{before_beat}, 2, 'schedule JSON keeps insertion index');
    is($schedule->{busy_insertion}{beats}, 2, 'schedule JSON keeps numeric exact-two count');
    is($schedule->{generated_artifacts}{ial1}{name}, 'amba_requester_busy_insert_two.isf', 'schedule JSON names IAL1 artifact');
    is_deeply($schedule->{generated_artifacts}{ial0}{files}, ['amba_requester_busy_insert_two.fsm'], 'schedule JSON names IAL0 artifact');
    my %residue = map { $_->{id} => $_->{detail} } @{$schedule->{unsupported_residue}};
    ok(!exists $residue{ahb_profile_alias_deferred}, 'schedule JSON removes alias-deferred residue');
    ok($residue{ahb_requester_busy_insert_support}, 'schedule JSON keeps exact-two support residue');

    my $tempdir = tempdir(CLEANUP => 1);
    my $outdir = File::Spec->catdir($tempdir, 'out');
    my $hdl = File::Spec->catfile($tempdir, 'amba_requester_busy_insert_two.sv');
    run_command_ok(
        ['./bin/fsmgen', '--quiet', '--strict', '--outdir', $outdir, '--output', $hdl, alias_path()],
        'alias emits HDL and review artifacts',
    );
    ok(-f File::Spec->catfile($outdir, 'amba_requester_busy_insert_two.isf'), 'outdir contains exact-two IAL1 artifact');
    ok(-f File::Spec->catfile($outdir, 'amba_requester_busy_insert_two.fsm'), 'outdir contains exact-two IAL0 artifact');
    ok(-f $hdl, 'outdir command emits HDL');
    like(slurp(File::Spec->catfile($outdir, 'amba_requester_busy_insert_two.isf')), qr/ahb_busy_remaining_q/, 'generated IAL1 keeps exact-two counter');
    like(slurp($hdl), qr/\bmodule\s+amba_requester_busy_insert_two\b/, 'generated HDL keeps exact-two module');
    run_command_ok(
        ['./bin/fsmgen', '--quiet', '--strict', '--verify-hdl', alias_path()],
        'alias passes generated HDL verification',
    );
};

subtest 'profile boundaries and existing requester identities remain stable' => sub {
    my $source = slurp(alias_path());
    my $mismatch = $source;
    $mismatch =~ s/\(profile ahb\)/(profile apb)/;
    my $mismatch_ok = eval {
        FSM::Adapter::IAL2::PPIF->new()->parse_source($mismatch, 'reserved-mismatch.ahb');
        1;
    };
    ok(!$mismatch_ok, '.ahb with non-AHB profile is rejected');
    like($@, qr/profile 'apb' does not match \(ahb-requester \.\.\.\); expected ahb/, 'profile mismatch diagnostic remains targeted');

    my $wrong_object = slurp(valid_ready_path());
    $wrong_object =~ s/\(profile valid-ready\)/(profile ahb)/;
    my $wrong_object_ok = eval {
        FSM::Adapter::IAL2::PPIF->new()->parse_source($wrong_object, 'reserved-wrong-object.ahb');
        1;
    };
    ok(!$wrong_object_ok, '.ahb with a non-AHB behavior object is rejected');
    like($@, qr/profile ahb requires exactly one .*\(ahb-requester \.\.\.\) object/s, 'wrong-object diagnostic names selected AHB shapes');

    my $generic = run_json_command('./bin/fsmgen', '--quiet', '--strict', '--check', '--json', ppif_path());
    is($generic->{support_accounting}{entry_id}, 'intent.ppif_ahb_requester_busy_insert_two', 'generic exact-two source keeps PPIF support identity');
    is($generic->{support_accounting}{source_kind}, 'ppif', 'generic exact-two source keeps PPIF source kind');

    my $exact_one = run_json_command('./bin/fsmgen', '--quiet', '--strict', '--check', '--json', exact_one_alias_path());
    is($exact_one->{support_accounting}{entry_id}, 'intent.ahb_profile_alias_requester_busy_insert', 'exact-one alias keeps support identity');
    my $base = FSM::Adapter::IAL2::PPIF->new()->parse_file(base_alias_path());
    ok(!exists($base->{report}{busy_insertion}), 'base requester alias remains BUSY-insertion free');
};

done_testing();

sub assert_semantic_payload {
    my ($semantic, $label) = @_;
    ok($semantic->{success}, "$label succeeds");
    is($semantic->{generation_result_snapshot}{summary}{module_name}, 'amba_requester_busy_insert_two', "$label reports exact-two module");
    is($semantic->{semantic}{module}{source_root_kind}, 'fsm', "$label reports generated FSM root");
    is($semantic->{support_accounting}{entry_id}, 'intent.ahb_profile_alias_requester_busy_insert_two', "$label reports alias support identity");
    is($semantic->{support_accounting}{source_kind}, 'ial2_profile_alias', "$label reports profile-alias source kind");
}

sub ppif_path {
    return File::Spec->catfile($FindBin::Bin, '..', 'ppif', 'ahb_requester_busy_insert_two.ppif');
}

sub alias_path {
    return File::Spec->catfile($FindBin::Bin, '..', 'ppif', 'ahb_requester_busy_insert_two.ahb');
}

sub exact_one_alias_path {
    return File::Spec->catfile($FindBin::Bin, '..', 'ppif', 'ahb_requester_busy_insert.ahb');
}

sub base_alias_path {
    return File::Spec->catfile($FindBin::Bin, '..', 'ppif', 'ahb_requester.ahb');
}

sub valid_ready_path {
    return File::Spec->catfile($FindBin::Bin, '..', 'ppif', 'valid_ready_handshake.ppif');
}

sub run_json_command {
    my @command = @_;
    my ($success, undef, undef, $stdout, $stderr) = run(command => \@command);
    my $json = join('', @{$stdout || []});
    my $decoded = eval { decode_json($json) };
    ok($decoded, join(' ', @command) . ' emits decodable JSON')
        or do {
            diag($json);
            diag(join('', @{$stderr || []}));
            diag('command failed') unless $success;
            return {};
        };
    return $decoded;
}

sub run_command_ok {
    my ($command, $label) = @_;
    my ($success, undef, undef, $stdout, $stderr) = run(command => $command);
    ok($success, $label)
        or diag(join('', @{$stdout || []}), join('', @{$stderr || []}));
    is(join('', @{$stderr || []}), '', "$label keeps stderr clean") if $success;
}

sub slurp {
    my ($path) = @_;
    open my $fh, '<', $path or die "Cannot read $path: $!";
    local $/;
    return <$fh>;
}
