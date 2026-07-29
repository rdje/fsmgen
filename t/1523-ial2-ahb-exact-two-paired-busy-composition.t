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

use FSM::Support::SemanticIntrospectionMCPAdapter;

my $repo_root = abs_path(File::Spec->catdir($FindBin::Bin, '..'));

subtest 'adapter composes exact-two requester BUSY insertion with subordinate BUSY parking' => sub {
    ok(-f sample_path(), 'tracked exact-two paired BUSY aggregate PPIF sample exists');
    my $source = slurp(sample_path());
    like($source, qr/\(ahb-requester amba_requester_busy_insert_two\b/, 'sample selects the exact-two BUSY-inserting requester');
    like($source, qr/\(busy-before-beat 2\)/, 'sample inserts BUSY before beat index two');
    like($source, qr/\(busy-beats 2\)/, 'sample selects two qualified BUSY events');
    like($source, qr/\(parked-transfer busy\)/, 'sample selects subordinate BUSY parking');

    my $report = run_json_command('./bin/fsmgen', '--quiet', '--emit-schedule-json', sample_path());
    is($report->{schema}, 'fsmgen.ial2.protocol_intent.ahb_interconnect.v1', 'adapter returns the AHB interconnect report schema');
    is(
        $report->{source_object}{id},
        'fsmgen-ahb-interconnect-requester-busy-insert-two-byte-lane-hburst-seq-busy-park',
        'exact-two paired source object id is selected',
    );
    is(
        $report->{source_object}{intent_name},
        'ahb_interconnect_requester_busy_insert_two_byte_lane_hburst_seq_busy_park',
        'exact-two paired source intent name is selected',
    );
    is($report->{composition}{child_instance_count}, 3, 'paired aggregate child count is preserved');
    is($report->{composition}{response_mux}{data_phase_owner}{mode}, 'one_hot_accepted_subordinate', 'paired fabric retains the accepted subordinate as data-phase response owner');
    is($report->{composition}{response_mux}{data_phase_owner}{same_edge_replacement}, 'completion_with_accepted_active_address_replaces_owner', 'paired fabric reports completion-edge owner replacement');

    is_deeply(
        [sort @{$report->{generated_artifacts}{ial0}{files}}],
        [qw(ahb_interconnect.fsm ahb_lite_subordinate_byte_lane_hburst_seq.fsm ahb_tb.fsm amba_requester_busy_insert_two.fsm)],
        'exact-two paired source exposes requester, subordinate, fabric, and top IAL0 artifacts',
    );
    is_deeply(
        [sort map { $_->{name} } @{$report->{generated_artifacts}{ial1}{items}}],
        [qw(ahb_interconnect.isf ahb_lite_subordinate_byte_lane_hburst_seq.isf amba_requester_busy_insert_two.isf)],
        'exact-two paired source exposes the exact generated IAL1 artifacts',
    );
    is($report->{generated_artifacts}{hdl_entry}{module}, 'ahb_tb', 'paired source selects the aggregate HDL module');

    my $requester = $report->{children}[0];
    is($requester->{object_name}, 'amba_requester_busy_insert_two', 'requester child selects the exact-two BUSY-inserting object');
    is($requester->{transfer}{busy}, "2'b01", 'requester child report keeps HTRANS BUSY');
    is($requester->{transfer}{busy_before_beat}, 2, 'requester child report keeps the insertion index');
    is($requester->{busy_insertion}{generated_behavior}, 1, 'requester child exposes generated BUSY behavior');
    is($requester->{busy_insertion}{htrans_busy_encoding}, "2'b01", 'requester child exposes the BUSY encoding');
    is($requester->{busy_insertion}{before_beat}, 2, 'requester child exposes the BUSY insertion index');
    is($requester->{transfer}{busy_beats}, 2, 'requester child transfer keeps exact-two cardinality');
    is($requester->{busy_insertion}{beats}, 2, 'requester child exposes numeric exact-two cardinality');
    my %requester_residue = map { $_->{id} => $_->{detail} } @{$requester->{unsupported_residue}};
    like($requester_residue{ahb_requester_busy_insert_support}, qr/exact-two qualified requester HTRANS BUSY events/, 'requester child keeps exact-two BUSY-insertion residue');

    my $subordinate = $report->{children}[2];
    is($subordinate->{transfer}{seq_policy}{mode}, 'hburst_in_word_progressive', 'subordinate child keeps HBURST SEQ progression');
    is_deeply($subordinate->{transfer}{seq_policy}{parks_on}, [qw(busy)], 'subordinate child parks BUSY');
    is_deeply($subordinate->{transfer}{seq_policy}{clears_on}, [qw(reset idle error new_nonseq final_beat)], 'subordinate child does not clear SEQ state on BUSY');
    is_deeply(
        $report->{composition}{seq_policy_propagation}{subordinates}[0]{seq_policy}{parks_on},
        [qw(busy)],
        'aggregate propagation exposes subordinate BUSY parking',
    );
    ok(!exists $report->{composition}{busy_flow}, 'paired proof does not duplicate child facts in a top busy-flow summary');
};

subtest 'base-requester aggregate reports remain structurally unchanged' => sub {
    my $base = run_json_command('./bin/fsmgen', '--quiet', '--emit-schedule-json', base_path());
    ok(!exists $base->{children}[0]{busy_insertion}, 'base requester child has no optional busy_insertion block');
    ok(!exists $base->{children}[0]{transfer}{busy}, 'base requester child has no BUSY encoding');
    ok(!exists $base->{children}[0]{transfer}{busy_before_beat}, 'base requester child has no BUSY insertion index');
};

subtest 'CLI, semantic, MCP, and review surfaces agree on the exact-two paired aggregate' => sub {
    my $check = run_json_command('./bin/fsmgen', '--quiet', '--strict', '--check', '--json', sample_path());
    ok($check->{success}, 'strict check succeeds for the exact-two paired BUSY source');
    is($check->{result}{module_name}, 'ahb_tb', 'check JSON reports the aggregate module');
    is($check->{result}{composition_child_count}, 3, 'check JSON reports the aggregate child count');
    is($check->{support_accounting}{entry_id}, support_id(), 'check JSON matches support accounting');
    is($check->{support_accounting}{coverage}, coverage_key(), 'check JSON reports paired BUSY coverage');

    my $semantic = run_json_command('./bin/fsmgen', '--quiet', '--strict', '--emit-semantic-json', sample_path());
    is($semantic->{generation_result_snapshot}{summary}{module_name}, 'ahb_tb', 'semantic JSON reports the aggregate module');
    is($semantic->{generation_result_snapshot}{summary}{source_root_kind}, 'top', 'semantic JSON reports the composition top');
    is($semantic->{support_accounting}{entry_id}, support_id(), 'semantic JSON matches support accounting');
    is($semantic->{support_accounting}{source_kind}, 'ppif', 'semantic JSON reports the generic source kind');

    my $adapter = FSM::Support::SemanticIntrospectionMCPAdapter->new(
        repo_root => $repo_root,
        workspace_root => $repo_root,
    );
    my $mcp = decode_json(
        $adapter->call_tool(
            'fsmgen_semantic_introspect',
            { source_path => sample_relpath() },
        )->{content}[0]{text},
    );
    is($mcp->{query_kind}, 'semantic', 'MCP dispatches through bounded semantic query');
    is($mcp->{source_id}, sample_relpath(), 'MCP keeps repo-relative exact-two paired identity');
    ok($mcp->{adapter_provenance}{read_only}, 'MCP provenance remains read-only');
    ok(!$mcp->{adapter_provenance}{shell_access}, 'MCP provenance keeps shell access disabled');
    is($mcp->{report}{generation_result_snapshot}{summary}{module_name}, 'ahb_tb', 'MCP semantic report exposes the aggregate module');
    is($mcp->{report}{generation_result_snapshot}{summary}{source_root_kind}, 'top', 'MCP semantic report exposes the composition root');
    is($mcp->{report}{support_accounting}{entry_id}, support_id(), 'MCP semantic report matches support accounting');
    is($mcp->{report}{support_accounting}{source_kind}, 'ppif', 'MCP semantic report keeps generic source kind');

    my $tempdir = tempdir(CLEANUP => 1);
    my $outdir = File::Spec->catdir($tempdir, 'out');
    my $hdl = File::Spec->catfile($tempdir, 'ahb_tb.sv');
    my ($generate_ok, undef, undef, $generate_stdout, $generate_stderr) = run(
        command => ['./bin/fsmgen', '--quiet', '--strict', '--outdir', $outdir, '--output', $hdl, sample_path()],
    );
    ok($generate_ok, 'exact-two paired BUSY source emits HDL and review artifacts')
        or diag(join('', @{$generate_stdout || []}), join('', @{$generate_stderr || []}));
    for my $artifact (qw(
        amba_requester_busy_insert_two.isf
        ahb_lite_subordinate_byte_lane_hburst_seq.isf
        ahb_interconnect.isf
        amba_requester_busy_insert_two.fsm
        ahb_lite_subordinate_byte_lane_hburst_seq.fsm
        ahb_interconnect.fsm
        ahb_tb.fsm
    )) {
        ok(-f File::Spec->catfile($outdir, $artifact), "outdir contains generated $artifact");
    }
    my $requester_isf = slurp(File::Spec->catfile($outdir, 'amba_requester_busy_insert_two.isf'));
    my $subordinate_isf = slurp(File::Spec->catfile($outdir, 'ahb_lite_subordinate_byte_lane_hburst_seq.isf'));
    my $interconnect_fsm = slurp(File::Spec->catfile($outdir, 'ahb_interconnect.fsm'));
    like($requester_isf, qr/\(var ahb_busy_remaining_q \(width 2\) \(reset 0\)\)/, 'exact-two paired requester keeps its actor-owned counter');
    like($subordinate_isf, qr/\(rule ahb_phase_capture \(& \(! ahb_phase_pending_q\)/, 'paired subordinate captures each ready active transfer once');
    like($subordinate_isf, qr/\(rule ahb_phase_hold ahb_phase_pending_q/, 'paired subordinate holds one accepted next phase');
    unlike($subordinate_isf, qr/\(transaction ahb_seq_idle_clear\b/, 'paired subordinate uses no competing idle-clear transaction');
    like($interconnect_fsm, qr/\(ahb_data_owner_0_q 1 \(reset 0\)\)/, 'paired fabric declares one reset-clean data-phase owner bit');
    like($interconnect_fsm, qr/\(<ahb_data_owner_0_q\s+\(= \(HREADY> HREADYOUT_REGS\)\).*?\(<HRESP_REGS/s, 'paired fabric muxes ready and response from the retained subordinate owner');
    like(slurp($hdl), qr/\bmodule\s+ahb_tb\b/, 'generated HDL contains the aggregate module');

    my ($verify_ok, undef, undef, $verify_stdout, $verify_stderr) = run(
        command => ['./bin/fsmgen', '--quiet', '--strict', '--verify-hdl', sample_path()],
    );
    ok($verify_ok, 'public verify-hdl accepts the exact-two paired BUSY source')
        or diag(join('', @{$verify_stdout || []}), join('', @{$verify_stderr || []}));
};

subtest 'generated HDL pairs two qualified requester BUSY events with subordinate parking' => sub {
    my $tempdir = tempdir(CLEANUP => 1);
    my $hdl = File::Spec->catfile($tempdir, 'ahb_tb.sv');
    my $objdir = File::Spec->catdir($tempdir, 'obj');
    my ($generate_ok, undef, undef, $generate_stdout, $generate_stderr) = run(
        command => ['./bin/fsmgen', '--quiet', '--strict', '--output', $hdl, sample_path()],
    );
    ok($generate_ok, 'public exact-two paired BUSY source emits generated HDL')
        or diag(join('', @{$generate_stdout || []}), join('', @{$generate_stderr || []}));
    return unless $generate_ok;

    my ($compile_ok, undef, undef, $compile_stdout, $compile_stderr) = run(
        command => [
            'verilator', '--binary', '--timing', '-Wno-fatal',
            '-j', '1', '--top-module', 'ahb_exact_two_paired_busy_composition_tb',
            '--Mdir', $objdir, $hdl, testbench_path(),
        ],
    );
    ok($compile_ok, 'Verilator builds the assertion-enabled exact-two paired BUSY composition harness')
        or diag(join('', @{$compile_stdout || []}), join('', @{$compile_stderr || []}));
    return unless $compile_ok;

    my $binary = File::Spec->catfile($objdir, 'Vahb_exact_two_paired_busy_composition_tb');
    my ($run_ok, undef, undef, $run_stdout, $run_stderr) = run(command => [$binary]);
    ok($run_ok, 'generated-HDL exact-two paired BUSY composition passes with assertions enabled')
        or diag(join('', @{$run_stdout || []}), join('', @{$run_stderr || []}));
    like(
        join('', @{$run_stdout || []}),
        qr/PASS transfers=5 beats=4 busy=1 qualified_busy=2 resumed_seq=1 storage=44332211/,
        'runtime observes two qualified paired BUSY events, one resumed SEQ, parking, and four byte writes',
    );
};

done_testing();

sub sample_path {
    return File::Spec->catfile(
        $repo_root,
        'ppif',
        'ahb_interconnect_requester_busy_insert_two_byte_lane_hburst_seq_busy_park.ppif',
    );
}

sub sample_relpath {
    return 'ppif/ahb_interconnect_requester_busy_insert_two_byte_lane_hburst_seq_busy_park.ppif';
}

sub base_path {
    return File::Spec->catfile($FindBin::Bin, '..', 'ppif', 'ahb_interconnect_byte_lane_hburst_seq_busy_park.ppif');
}

sub testbench_path {
    return File::Spec->catfile($FindBin::Bin, 'data', 'ahb_exact_two_paired_busy_composition_tb.svt');
}

sub support_id {
    return 'intent.ppif_ahb_interconnect_requester_busy_insert_two_byte_lane_hburst_seq_busy_park';
}

sub coverage_key {
    return 'ial2_ppif_ahb_interconnect_requester_busy_insert_two_byte_lane_hburst_seq_busy_park_pipeline_cli';
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

sub slurp {
    my ($path) = @_;
    open my $fh, '<', $path or die "open $path: $!";
    local $/;
    return <$fh>;
}
