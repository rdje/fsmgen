#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use Cwd qw(abs_path);
use File::Path qw(make_path);
use File::Spec;
use File::Temp qw(tempdir);
use FindBin;
use IPC::Cmd qw(run);
use JSON::PP qw(decode_json);

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::Adapter::IAL2::PPIF;
use FSM::ProjectDataLocality qw(configure_project_temp_environment);
use FSM::Support::SemanticIntrospectionMCPAdapter;

my $repo_root = abs_path(File::Spec->catdir($FindBin::Bin, '..'));
configure_project_temp_environment(purpose => 'tests');

subtest 'exact-four paired .ahb alias mirrors generic source and lowering' => sub {
    ok(-f alias_path(), 'tracked exact-four paired .ahb alias exists');
    is(slurp(alias_path()), slurp(ppif_path()), '.ahb source is byte-identical to generic .ppif source');

    my $alias = FSM::Adapter::IAL2::PPIF->new()->parse_file(alias_path());
    my $ppif = FSM::Adapter::IAL2::PPIF->new()->parse_file(ppif_path());

    is($alias->{layer}, 'IAL2', 'alias remains an IAL2 source');
    is($alias->{kind}, 'protocol_intent.ahb_interconnect', 'alias keeps AHB interconnect kind');
    is($alias->{mode}, 'requester-subordinate-interconnect', 'alias keeps requester-subordinate interconnect mode');
    is_deeply($alias->{generated_ial1}, $ppif->{generated_ial1}, 'alias and generic source generate identical IAL1 artifacts');
    is_deeply($alias->{generated_ial0}, $ppif->{generated_ial0}, 'alias and generic source generate identical IAL0 artifacts');

    is($alias->{report}{schema}, 'fsmgen.ial2.protocol_intent.ahb_interconnect.v1', 'alias keeps aggregate report schema');
    is($alias->{report}{source_object}{id}, 'fsmgen-ahb-interconnect-requester-busy-insert-four-byte-lane-hburst-seq-busy-park', 'alias preserves source object');
    is($alias->{report}{source_object}{intent_name}, 'ahb_interconnect_requester_busy_insert_four_byte_lane_hburst_seq_busy_park', 'alias preserves intent name');
    is($alias->{report}{composition}{child_instance_count}, 3, 'alias preserves the three-child aggregate');
    is($alias->{report}{children}[0]{busy_insertion}{before_beat}, 2, 'alias preserves BUSY insertion index');
    is($alias->{report}{children}[0]{busy_insertion}{beats}, 4, 'alias preserves numeric exact-four cardinality');
    is_deeply($alias->{report}{children}[2]{transfer}{seq_policy}{parks_on}, [qw(busy)], 'alias preserves subordinate BUSY parking');
    is_deeply($alias->{report}{composition}{seq_policy_propagation}{subordinates}[0]{seq_policy}{parks_on}, [qw(busy)], 'alias preserves propagated BUSY parking');
    is($alias->{report}{composition}{response_mux}{data_phase_owner}{mode}, 'one_hot_accepted_subordinate', 'alias preserves one-hot response ownership');
    ok(!exists $alias->{report}{composition}{busy_flow}, 'alias adds no duplicate top BUSY summary');

    for my $residue_id (qw(
        ahb_profile_alias_deferred
        ahb_aggregate_profile_alias_deferred
        ahb_subordinate_profile_alias_deferred
    )) {
        ok(!residue_id_occurs($alias->{report}, $residue_id), "alias removes $residue_id");
        ok(residue_id_occurs($ppif->{report}, $residue_id), "generic source keeps $residue_id");
    }
    ok(!detail_pattern_occurs($alias->{report}, qr/\.ahb alias exposure/), 'alias removes alias-exposure wording');
};

subtest 'check, schedule, semantic JSON, and read-only MCP expose alias identity' => sub {
    my $check = run_json_command('./bin/fsmgen', '--quiet', '--strict', '--check', '--json', alias_path());
    ok($check->{success}, 'strict alias check succeeds');
    is($check->{result}{module_name}, 'ahb_tb', 'check JSON reports aggregate module');
    is($check->{result}{composition_child_count}, 3, 'check JSON reports child count');
    is($check->{result}{signal_count}, 28, 'check JSON reports stable signal count');
    is($check->{support_accounting}{entry_id}, support_id(), 'check JSON reports alias support id');
    is($check->{support_accounting}{coverage}, coverage_key(), 'check JSON reports alias coverage');
    is($check->{support_accounting}{source_kind}, 'ial2_profile_alias', 'check JSON reports profile-alias source kind');

    my $schedule = run_json_command('./bin/fsmgen', '--quiet', '--emit-schedule-json', alias_path());
    is($schedule->{schema}, 'fsmgen.ial2.protocol_intent.ahb_interconnect.v1', 'schedule JSON keeps aggregate schema');
    is($schedule->{source_object}{id}, 'fsmgen-ahb-interconnect-requester-busy-insert-four-byte-lane-hburst-seq-busy-park', 'schedule JSON keeps source object');
    is($schedule->{source_object}{intent_name}, 'ahb_interconnect_requester_busy_insert_four_byte_lane_hburst_seq_busy_park', 'schedule JSON keeps intent name');
    is($schedule->{composition}{child_instance_count}, 3, 'schedule JSON keeps child count');
    is_deeply(
        [sort map { $_->{name} } @{$schedule->{generated_artifacts}{ial1}{items}}],
        [qw(ahb_interconnect.isf ahb_lite_subordinate_byte_lane_hburst_seq.isf amba_requester_busy_insert_four.isf)],
        'schedule JSON keeps exact IAL1 artifacts',
    );
    is_deeply(
        [sort @{$schedule->{generated_artifacts}{ial0}{files}}],
        [qw(ahb_interconnect.fsm ahb_lite_subordinate_byte_lane_hburst_seq.fsm ahb_tb.fsm amba_requester_busy_insert_four.fsm)],
        'schedule JSON keeps exact IAL0 artifacts',
    );
    is($schedule->{children}[0]{busy_insertion}{before_beat}, 2, 'schedule JSON keeps insertion index');
    is($schedule->{children}[0]{busy_insertion}{beats}, 4, 'schedule JSON keeps numeric exact-four count');
    is_deeply($schedule->{children}[2]{transfer}{seq_policy}{parks_on}, [qw(busy)], 'schedule JSON keeps subordinate parking');
    is_deeply($schedule->{composition}{seq_policy_propagation}{subordinates}[0]{seq_policy}{parks_on}, [qw(busy)], 'schedule JSON keeps propagated parking');
    is($schedule->{composition}{response_mux}{data_phase_owner}{mode}, 'one_hot_accepted_subordinate', 'schedule JSON keeps response ownership');
    ok(!exists $schedule->{composition}{busy_flow}, 'schedule JSON adds no duplicate top BUSY summary');

    my $semantic = run_json_command('./bin/fsmgen', '--quiet', '--strict', '--emit-semantic-json', alias_path());
    assert_semantic_payload($semantic, 'semantic JSON');

    my $adapter = FSM::Support::SemanticIntrospectionMCPAdapter->new(
        repo_root => $repo_root,
        workspace_root => $repo_root,
    );
    my $mcp = decode_json(
        $adapter->call_tool(
            'fsmgen_semantic_introspect',
            { source_path => alias_relpath() },
        )->{content}[0]{text},
    );
    is($mcp->{query_kind}, 'semantic', 'MCP dispatches through bounded semantic query');
    is($mcp->{source_id}, alias_relpath(), 'MCP keeps repo-relative alias identity');
    ok($mcp->{adapter_provenance}{read_only}, 'MCP provenance remains read-only');
    ok(!$mcp->{adapter_provenance}{shell_access}, 'MCP provenance keeps shell access disabled');
    assert_semantic_payload($mcp->{report}, 'MCP semantic report');
};

subtest 'review artifacts, HDL, and verifier preserve exact-four paired identity' => sub {
    my $tempdir = project_tempdir();
    my $outdir = File::Spec->catdir($tempdir, 'out');
    my $hdl = File::Spec->catfile($tempdir, 'ahb_tb.sv');
    run_command_ok(
        ['./bin/fsmgen', '--quiet', '--strict', '--outdir', $outdir, '--output', $hdl, alias_path()],
        'alias emits repository-local HDL and review artifacts',
    );
    for my $artifact (qw(
        amba_requester_busy_insert_four.isf
        ahb_lite_subordinate_byte_lane_hburst_seq.isf
        ahb_interconnect.isf
        amba_requester_busy_insert_four.fsm
        ahb_lite_subordinate_byte_lane_hburst_seq.fsm
        ahb_interconnect.fsm
        ahb_tb.fsm
    )) {
        ok(-f File::Spec->catfile($outdir, $artifact), "outdir contains $artifact");
    }
    like(slurp(File::Spec->catfile($outdir, 'amba_requester_busy_insert_four.isf')), qr/\(var ahb_busy_remaining_q \(width 3\) \(reset 0\)\)/, 'requester IAL1 keeps the width-three exact-four counter');
    like(slurp(File::Spec->catfile($outdir, 'ahb_lite_subordinate_byte_lane_hburst_seq.isf')), qr/ahb_phase_pending_q/, 'subordinate IAL1 keeps accepted-phase storage');
    like(slurp(File::Spec->catfile($outdir, 'ahb_interconnect.fsm')), qr/\(ahb_data_owner_0_q 1 \(reset 0\)\)/, 'fabric IAL0 keeps response ownership state');
    like(slurp($hdl), qr/\bmodule\s+ahb_tb\b/, 'generated HDL keeps aggregate module');
    run_command_ok(
        ['./bin/fsmgen', '--quiet', '--strict', '--verify-hdl', alias_path()],
        'alias passes generated HDL verification',
    );
};

subtest 'profile boundaries and existing aggregate identities remain stable' => sub {
    my $source = slurp(alias_path());
    my $mismatch = $source;
    $mismatch =~ s/\(profile ahb\)/(profile apb)/;
    my $mismatch_ok = eval {
        FSM::Adapter::IAL2::PPIF->new()->parse_source($mismatch, 'reserved-mismatch.ahb');
        1;
    };
    ok(!$mismatch_ok, '.ahb with non-AHB profile is rejected');
    like($@, qr/profile 'apb' does not match \(ahb-interconnect \.\.\.\); expected ahb/, 'profile mismatch diagnostic remains targeted');

    my $wrong_object = slurp(valid_ready_path());
    $wrong_object =~ s/\(profile valid-ready\)/(profile ahb)/;
    my $wrong_object_ok = eval {
        FSM::Adapter::IAL2::PPIF->new()->parse_source($wrong_object, 'reserved-wrong-object.ahb');
        1;
    };
    ok(!$wrong_object_ok, '.ahb with a non-AHB behavior object is rejected');
    like($@, qr/profile ahb requires exactly one .*\(ahb-requester \.\.\.\) object/s, 'wrong-object diagnostic names selected AHB shapes');

    my $generic = run_json_command('./bin/fsmgen', '--quiet', '--strict', '--check', '--json', ppif_path());
    is($generic->{support_accounting}{entry_id}, 'intent.ppif_ahb_interconnect_requester_busy_insert_four_byte_lane_hburst_seq_busy_park', 'generic exact-four source keeps PPIF support identity');
    is($generic->{support_accounting}{source_kind}, 'ppif', 'generic exact-four source keeps PPIF source kind');

    my $exact_three = run_json_command('./bin/fsmgen', '--quiet', '--strict', '--check', '--json', exact_three_alias_path());
    is($exact_three->{support_accounting}{entry_id}, 'intent.ahb_profile_alias_interconnect_requester_busy_insert_three_byte_lane_hburst_seq_busy_park', 'exact-three paired alias keeps support identity');
    my $requester = run_json_command('./bin/fsmgen', '--quiet', '--strict', '--check', '--json', requester_alias_path());
    is($requester->{support_accounting}{entry_id}, 'intent.ahb_profile_alias_requester_busy_insert_four', 'standalone exact-four requester alias keeps support identity');
};

done_testing();

sub assert_semantic_payload {
    my ($semantic, $label) = @_;
    ok($semantic->{success}, "$label succeeds");
    is($semantic->{generation_result_snapshot}{summary}{module_name}, 'ahb_tb', "$label reports aggregate module");
    is($semantic->{generation_result_snapshot}{summary}{source_root_kind}, 'top', "$label reports composition root");
    is($semantic->{generation_result_snapshot}{summary}{composition_child_count}, 3, "$label reports child count");
    is($semantic->{support_accounting}{entry_id}, support_id(), "$label reports alias support identity");
    is($semantic->{support_accounting}{source_kind}, 'ial2_profile_alias', "$label reports profile-alias source kind");
}

sub ppif_path {
    return File::Spec->catfile($repo_root, split m{/}, ppif_relpath());
}

sub alias_path {
    return File::Spec->catfile($repo_root, split m{/}, alias_relpath());
}

sub ppif_relpath {
    return 'ppif/ahb_interconnect_requester_busy_insert_four_byte_lane_hburst_seq_busy_park.ppif';
}

sub alias_relpath {
    return 'ppif/ahb_interconnect_requester_busy_insert_four_byte_lane_hburst_seq_busy_park.ahb';
}

sub exact_three_alias_path {
    return File::Spec->catfile($repo_root, 'ppif', 'ahb_interconnect_requester_busy_insert_three_byte_lane_hburst_seq_busy_park.ahb');
}

sub requester_alias_path {
    return File::Spec->catfile($repo_root, 'ppif', 'ahb_requester_busy_insert_four.ahb');
}

sub valid_ready_path {
    return File::Spec->catfile($repo_root, 'ppif', 'valid_ready_handshake.ppif');
}

sub support_id {
    return 'intent.ahb_profile_alias_interconnect_requester_busy_insert_four_byte_lane_hburst_seq_busy_park';
}

sub coverage_key {
    return 'ial2_ahb_profile_alias_interconnect_requester_busy_insert_four_byte_lane_hburst_seq_busy_park_pipeline_cli';
}

sub project_tempdir {
    my $temp_root = File::Spec->catdir($repo_root, '.artifacts', 'tmp', 'tests');
    make_path($temp_root);
    return tempdir('t1538-XXXXXX', DIR => $temp_root, CLEANUP => 1);
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
        };
    return $decoded || {};
}

sub run_command_ok {
    my ($command, $label) = @_;
    my ($success, undef, undef, $stdout, $stderr) = run(command => $command);
    ok($success, $label)
        or diag(join('', @{$stdout || []}), join('', @{$stderr || []}));
    is(join('', @{$stderr || []}), '', "$label keeps stderr clean") if $success;
}

sub residue_id_occurs {
    my ($node, $id) = @_;
    return 0 unless ref($node);
    if (ref($node) eq 'ARRAY') {
        return scalar grep { residue_id_occurs($_, $id) } @{$node};
    }
    return 0 unless ref($node) eq 'HASH';
    return 1 if exists($node->{id}) && ($node->{id} // '') eq $id;
    return scalar grep { residue_id_occurs($node->{$_}, $id) } keys %{$node};
}

sub detail_pattern_occurs {
    my ($node, $pattern) = @_;
    return 0 unless ref($node);
    if (ref($node) eq 'ARRAY') {
        return scalar grep { detail_pattern_occurs($_, $pattern) } @{$node};
    }
    return 0 unless ref($node) eq 'HASH';
    return 1 if exists($node->{detail}) && ($node->{detail} // '') =~ $pattern;
    return scalar grep { detail_pattern_occurs($node->{$_}, $pattern) } keys %{$node};
}

sub slurp {
    my ($path) = @_;
    open my $fh, '<', $path or die "open $path: $!";
    local $/;
    return <$fh>;
}
