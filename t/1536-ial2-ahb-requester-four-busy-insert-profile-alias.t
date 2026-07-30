#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use Cwd qw(abs_path);
use File::Spec;
use FindBin;
use IPC::Cmd qw(run);
use JSON::PP qw(decode_json);

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::Adapter::IAL2::PPIF;
use FSM::ProjectDataLocality qw(configure_project_temp_environment create_project_tempdir);
use FSM::Support::SemanticIntrospectionMCPAdapter;

my $repo_root = abs_path(File::Spec->catdir($FindBin::Bin, '..'));
configure_project_temp_environment(purpose => 'tests');

subtest 'exact-four requester .ahb alias mirrors generic source, lowering, and report' => sub {
    ok(-f alias_path(), 'tracked exact-four requester .ahb alias exists');
    is(slurp(alias_path()), slurp(ppif_path()), '.ahb source is byte-identical to generic .ppif source');

    my $alias = FSM::Adapter::IAL2::PPIF->new()->parse_file(alias_path());
    my $ppif = FSM::Adapter::IAL2::PPIF->new()->parse_file(ppif_path());

    is($alias->{layer}, 'IAL2', 'alias remains an IAL2 source');
    is($alias->{kind}, 'protocol_intent.ahb_requester', 'alias keeps AHB requester kind');
    is($alias->{mode}, 'requester', 'alias keeps requester mode');
    is($alias->{generated_ial1}{name}, 'amba_requester_busy_insert_four.isf', 'alias exposes exact-four IAL1 artifact');
    is($alias->{generated_ial1}{text}, $ppif->{generated_ial1}{text}, 'alias and generic source generate identical IAL1');
    is_deeply($alias->{generated_ial0}{files}, $ppif->{generated_ial0}{files}, 'alias and generic source generate identical IAL0 files');
    is_deeply(
        $alias->{generated_ial0}{files},
        {'amba_requester_busy_insert_four.fsm' => $ppif->{generated_ial0}{files}{'amba_requester_busy_insert_four.fsm'}},
        'alias keeps exact-four IAL0 artifact text',
    );

    is($alias->{report}{schema}, 'fsmgen.ial2.protocol_intent.ahb_requester.v1', 'alias keeps requester report schema');
    is($alias->{report}{source_object}{id}, 'fsmgen-ahb-requester-busy-insert-four', 'alias preserves source object');
    is($alias->{report}{source_object}{intent_name}, 'ahb_requester_busy_insert_four', 'alias preserves intent name');
    is($alias->{report}{busy_insertion}{generated_behavior}, 1, 'alias preserves generated BUSY behavior marker');
    is($alias->{report}{busy_insertion}{htrans_busy_encoding}, "2'b01", 'alias exposes BUSY encoding');
    is($alias->{report}{busy_insertion}{before_beat}, 2, 'alias exposes insertion index');
    is($alias->{report}{busy_insertion}{beats}, 4, 'alias keeps numeric exact-four event count');
    is($alias->{report}{layering}{direct_ial2_to_ial0}, 0, 'alias still lowers through IAL1');

    my %alias_residue = map { $_->{id} => $_->{detail} } @{$alias->{report}{unsupported_residue}};
    my %ppif_residue = map { $_->{id} => $_->{detail} } @{$ppif->{report}{unsupported_residue}};
    ok(!exists $alias_residue{ahb_profile_alias_deferred}, 'alias removes source-surface profile-alias residue');
    ok($ppif_residue{ahb_profile_alias_deferred}, 'generic source keeps alias-deferred residue');
    is(
        $alias_residue{ahb_requester_busy_insert_support},
        $ppif_residue{ahb_requester_busy_insert_support},
        'alias and generic source keep identical exact-four BUSY support residue',
    );
    like($alias->{generated_ial1}{text}, qr/\(var ahb_busy_remaining_q \(width 3\) \(reset 0\)\)/, 'alias keeps exact-four width-three actor counter');
};

subtest 'check, semantic JSON, and read-only MCP expose alias support identity' => sub {
    my $check = run_json_command('./bin/fsmgen', '--quiet', '--strict', '--check', '--json', alias_path());
    ok($check->{success}, 'strict alias check succeeds');
    is($check->{source}{resolved_path}, File::Spec->rel2abs(alias_path()), 'check JSON reports alias source path');
    is($check->{result}{module_name}, 'amba_requester_busy_insert_four', 'check JSON reports exact-four module');
    is($check->{support_accounting}{entry_id}, 'intent.ahb_profile_alias_requester_busy_insert_four', 'check JSON reports alias support identity');
    is($check->{support_accounting}{coverage}, 'ial2_ahb_profile_alias_requester_busy_insert_four_pipeline_cli', 'check JSON reports alias coverage');
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
            { source_path => 'ppif/ahb_requester_busy_insert_four.ahb' },
        )->{content}[0]{text},
    );
    is($mcp->{query_kind}, 'semantic', 'MCP dispatches through bounded semantic query');
    is($mcp->{source_id}, 'ppif/ahb_requester_busy_insert_four.ahb', 'MCP keeps repo-relative alias identity');
    ok($mcp->{adapter_provenance}{read_only}, 'MCP provenance remains read-only');
    ok(!$mcp->{adapter_provenance}{shell_access}, 'MCP provenance keeps shell access disabled');
    assert_semantic_payload($mcp->{report}, 'MCP semantic report');
};

subtest 'schedule, review artifacts, HDL, and verifier preserve exact-four identity' => sub {
    my $schedule = run_json_command('./bin/fsmgen', '--quiet', '--emit-schedule-json', alias_path());
    is($schedule->{schema}, 'fsmgen.ial2.protocol_intent.ahb_requester.v1', 'schedule JSON keeps requester schema');
    is($schedule->{busy_insertion}{before_beat}, 2, 'schedule JSON keeps insertion index');
    is($schedule->{busy_insertion}{beats}, 4, 'schedule JSON keeps numeric exact-four count');
    is($schedule->{generated_artifacts}{ial1}{name}, 'amba_requester_busy_insert_four.isf', 'schedule JSON names IAL1 artifact');
    is_deeply($schedule->{generated_artifacts}{ial0}{files}, ['amba_requester_busy_insert_four.fsm'], 'schedule JSON names IAL0 artifact');
    my %residue = map { $_->{id} => $_->{detail} } @{$schedule->{unsupported_residue}};
    ok(!exists $residue{ahb_profile_alias_deferred}, 'schedule JSON removes alias-deferred residue');
    ok($residue{ahb_requester_busy_insert_support}, 'schedule JSON keeps exact-four support residue');

    my $tempdir = create_project_tempdir(purpose => 'tests');
    my $outdir = File::Spec->catdir($tempdir, 'out');
    my $hdl = File::Spec->catfile($tempdir, 'amba_requester_busy_insert_four.sv');
    run_command_ok(
        ['./bin/fsmgen', '--quiet', '--strict', '--outdir', $outdir, '--output', $hdl, alias_path()],
        'alias emits HDL and review artifacts',
    );
    ok(-f File::Spec->catfile($outdir, 'amba_requester_busy_insert_four.isf'), 'outdir contains exact-four IAL1 artifact');
    ok(-f File::Spec->catfile($outdir, 'amba_requester_busy_insert_four.fsm'), 'outdir contains exact-four IAL0 artifact');
    ok(-f $hdl, 'outdir command emits HDL');
    like(slurp(File::Spec->catfile($outdir, 'amba_requester_busy_insert_four.isf')), qr/ahb_busy_remaining_q/, 'generated IAL1 keeps exact-four counter');
    like(slurp($hdl), qr/\bmodule\s+amba_requester_busy_insert_four\b/, 'generated HDL keeps exact-four module');
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
    is($generic->{support_accounting}{entry_id}, 'intent.ppif_ahb_requester_busy_insert_four', 'generic exact-four source keeps PPIF support identity');
    is($generic->{support_accounting}{source_kind}, 'ppif', 'generic exact-four source keeps PPIF source kind');

    my $exact_three = run_json_command('./bin/fsmgen', '--quiet', '--strict', '--check', '--json', exact_three_alias_path());
    is($exact_three->{support_accounting}{entry_id}, 'intent.ahb_profile_alias_requester_busy_insert_three', 'exact-three alias keeps support identity');
    my $exact_two = run_json_command('./bin/fsmgen', '--quiet', '--strict', '--check', '--json', exact_two_alias_path());
    is($exact_two->{support_accounting}{entry_id}, 'intent.ahb_profile_alias_requester_busy_insert_two', 'exact-two alias keeps support identity');
    my $exact_one = run_json_command('./bin/fsmgen', '--quiet', '--strict', '--check', '--json', exact_one_alias_path());
    is($exact_one->{support_accounting}{entry_id}, 'intent.ahb_profile_alias_requester_busy_insert', 'exact-one alias keeps support identity');
    my $base = FSM::Adapter::IAL2::PPIF->new()->parse_file(base_alias_path());
    ok(!exists($base->{report}{busy_insertion}), 'base requester alias remains BUSY-insertion free');

    for my $relative_path (preserved_paired_paths()) {
        ok(-f File::Spec->catfile($repo_root, split m{/}, $relative_path), "$relative_path remains tracked");
    }
};

done_testing();

sub assert_semantic_payload {
    my ($semantic, $label) = @_;
    ok($semantic->{success}, "$label succeeds");
    is($semantic->{generation_result_snapshot}{summary}{module_name}, 'amba_requester_busy_insert_four', "$label reports exact-four module");
    is($semantic->{semantic}{module}{source_root_kind}, 'fsm', "$label reports generated FSM root");
    is($semantic->{support_accounting}{entry_id}, 'intent.ahb_profile_alias_requester_busy_insert_four', "$label reports alias support identity");
    is($semantic->{support_accounting}{source_kind}, 'ial2_profile_alias', "$label reports profile-alias source kind");
}

sub ppif_path {
    return File::Spec->catfile($FindBin::Bin, '..', 'ppif', 'ahb_requester_busy_insert_four.ppif');
}

sub alias_path {
    return File::Spec->catfile($FindBin::Bin, '..', 'ppif', 'ahb_requester_busy_insert_four.ahb');
}

sub exact_three_alias_path {
    return File::Spec->catfile($FindBin::Bin, '..', 'ppif', 'ahb_requester_busy_insert_three.ahb');
}

sub exact_two_alias_path {
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

sub preserved_paired_paths {
    return qw(
        ppif/ahb_interconnect_requester_busy_insert_byte_lane_hburst_seq_busy_park.ppif
        ppif/ahb_interconnect_requester_busy_insert_byte_lane_hburst_seq_busy_park.ahb
        ppif/ahb_interconnect_requester_busy_insert_two_byte_lane_hburst_seq_busy_park.ppif
        ppif/ahb_interconnect_requester_busy_insert_two_byte_lane_hburst_seq_busy_park.ahb
        ppif/ahb_interconnect_requester_busy_insert_three_byte_lane_hburst_seq_busy_park.ppif
        ppif/ahb_interconnect_requester_busy_insert_three_byte_lane_hburst_seq_busy_park.ahb
        ppif/ahb_interconnect_requester_busy_insert_two_subordinate_byte_lane_hburst_seq_busy_park.ppif
        ppif/ahb_interconnect_requester_busy_insert_two_subordinate_byte_lane_hburst_seq_busy_park.ahb
        ppif/ahb_interconnect_two_subordinate_requester_busy_insert_two_byte_lane_hburst_seq_busy_park.ppif
        ppif/ahb_interconnect_two_subordinate_requester_busy_insert_two_byte_lane_hburst_seq_busy_park.ahb
        ppif/ahb_interconnect_two_subordinate_requester_busy_insert_three_byte_lane_hburst_seq_busy_park.ppif
        ppif/ahb_interconnect_two_subordinate_requester_busy_insert_three_byte_lane_hburst_seq_busy_park.ahb
    );
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
