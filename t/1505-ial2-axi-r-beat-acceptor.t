#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use File::Spec;
use File::Temp qw(tempdir);
use FindBin;
use IPC::Cmd qw(run);
use JSON::PP qw(decode_json);

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::Adapter::IAL2::PPIF;

subtest 'adapter exposes the exact bounded AXI R-beat acceptor contract and artifacts' => sub {
    ok(-f sample_r_acceptor_ppif_path(), 'tracked runnable AXI R-beat acceptor PPIF sample exists');

    my $result = FSM::Adapter::IAL2::PPIF->new()->parse_file(sample_r_acceptor_ppif_path());
    is($result->{layer}, 'IAL2', 'AXI R-beat acceptor result stays IAL2');
    is($result->{kind}, 'protocol_intent.axi_r_beat_acceptor', 'adapter selects the R-beat result kind');
    is($result->{mode}, 'acceptor', 'adapter selects acceptor mode');

    my $report = $result->{report};
    is($report->{schema}, 'fsmgen.ial2.protocol_intent.axi_r_beat_acceptor.v1', 'report schema is exact');
    is_deeply(
        $report->{source_object},
        {
            id => 'axi-r-beat-acceptor',
            intent_name => 'axi_r_beat_acceptor',
            anchors => [
                map {
                    +{ document => 'IHI0022_L_2025-08', section => $_->[0], page => $_->[1] }
                } (
                    ['A2.3', '29'], ['A2.3.1', '30'], ['A2.3.2.2', '32'],
                    ['A2.6', '41'], ['A3.2.2', '55'], ['A3.3.2', '62'],
                    ['A5.1.1', '90'], ['B1.2.2', '281'],
                )
            ],
        },
        'report preserves the selected object, intent, and eight Issue L anchors',
    );
    is_deeply(
        $report->{target_protocol},
        {
            profile => 'axi4',
            object => 'axi-r-beat-acceptor',
            role => 'subordinate-to-manager',
        },
        'report fixes the AXI4 manager-side receiver direction',
    );
    is($report->{acceptor}{actor_name}, 'axi_r_beat_acceptor', 'report names the generated actor');
    is_deeply(
        $report->{bindings}{command},
        { arm => 'r_accept_cmd_valid' },
        'report preserves the arm binding',
    );
    is_deeply(
        $report->{bindings}{channel},
        {
            valid => 'rvalid', ready => 'rready',
            id => { name => 'rid', width => 4 },
            data => { name => 'rdata', width => 32 },
            response => { name => 'rresp', width => 2 },
            last => 'rlast',
            captured_id => { name => 'response_rid', width => 4 },
            captured_data => { name => 'response_rdata', width => 32 },
            captured_response => { name => 'response_rresp', width => 2 },
            captured_last => 'response_rlast',
            busy => 'r_busy', done => 'r_beat_done',
        },
        'report preserves all twelve R-channel bindings and fixed widths',
    );

    my %bounded = %{$report->{bounded_beat}};
    my $includes_read_completion = delete $bounded{includes_read_completion};
    my $back_to_back_supported = delete $bounded{back_to_back_supported};
    is_deeply(
        \%bounded,
        {
            arming_policy => 'explicit_one_beat',
            ready_policy => 'assert_after_arm_without_waiting_for_valid',
            accept_condition => 'rvalid && rready',
            id_width => 4,
            data_width => 32,
            response_width => 2,
            last_width => 1,
            capture_policy => 'on_accept_and_hold_until_next_accept',
            done_event => 'r_beat_accepted',
            done_policy => 'one_pulse_per_accepted_arm_after_transaction_retirement',
        },
        'bounded-beat report fixes the selected arm, ready, capture, width, and done policies',
    );
    ok(!$includes_read_completion, 'beat acceptance does not claim read completion');
    ok(!$back_to_back_supported, 'same-cycle rearm and back-to-back acceptance remain unsupported');

    is_deeply(
        $report->{enforced_static_rules},
        [
            'profile must be axi4 and the object must be axi-r-beat-acceptor',
            'role must be subordinate-to-manager',
            'one explicit arm owns one R beat acceptance',
            'RREADY is manager-driven and asserts after arm without waiting for RVALID',
            'R ID width and captured ID width are 4',
            'R data width and captured data width are 32',
            'R response width and captured response width are 2',
            'RLAST and captured RLAST are scalar and captured raw',
            'capture occurs only on RVALID && RREADY and is held until the next accepted beat',
            'busy and ready clear on acceptance and beat-done is one later pulse',
            'beat-done does not imply RLAST, response success, ID match, length satisfaction, or read completion',
            'all bindings and reserved internal names are distinct',
            'direct IAL2-to-IAL0 lowering is forbidden',
        ],
        'report exposes the thirteen exact enforced rules',
    );
    is_deeply(
        [map { $_->{id} } @{$report->{unsupported_residue}}],
        [qw(
            axi_r_beat_acceptor_ar_coordination_deferred
            axi_r_beat_acceptor_repeated_multi_beat_deferred
            axi_r_beat_acceptor_arlen_rlast_validation_deferred
            axi_r_beat_acceptor_read_completion_deferred
            axi_r_beat_acceptor_id_match_deferred
            axi_r_beat_acceptor_response_interpretation_deferred
            axi_r_beat_acceptor_capacity_core_integration_deferred
            axi_r_beat_acceptor_outstanding_back_to_back_deferred
            axi_r_beat_acceptor_widths_fixed
            axi_r_beat_acceptor_extended_response_signals_deferred
            axi_r_beat_acceptor_subordinate_stall_assertions_deferred
            axi_r_beat_acceptor_transaction_interface_deferred
            axi_r_beat_acceptor_profile_alias_deferred
            axi_r_beat_acceptor_verification_output_deferred
            axi_r_beat_acceptor_backend_variants_deferred
        )],
        'report preserves the fifteen ordered residue identifiers',
    );

    my $isf = $result->{generated_ial1}{text};
    is($result->{generated_ial1}{name}, 'axi_r_beat_acceptor.isf', 'generated IAL1 name is exact');
    like($isf, qr/\A\(actor axi_r_beat_acceptor\b/, 'generated IAL1 names the R actor');
    like($isf, qr/\(input rid \(width 4\)\)/, 'generated IAL1 declares RID');
    like($isf, qr/\(input rdata \(width 32\)\)/, 'generated IAL1 declares RDATA');
    like($isf, qr/\(input rresp \(width 2\)\)/, 'generated IAL1 declares RRESP');
    like($isf, qr/\(input rlast\)/, 'generated IAL1 declares RLAST');
    like($isf, qr/\(priority accept_r over arm_r\)/, 'acceptance has priority over arm');
    like($isf, qr/\(rule arm_r arm_r_start\b/, 'generated IAL1 has the arm rule');
    like($isf, qr/\(rule accept_r \(& active_q rvalid rready\)/, 'generated IAL1 captures on the physical handshake');
    like($isf, qr/\(set response_rid rid\)/, 'generated IAL1 captures RID raw');
    like($isf, qr/\(set response_rdata rdata\)/, 'generated IAL1 captures RDATA raw');
    like($isf, qr/\(set response_rresp rresp\)/, 'generated IAL1 captures RRESP raw');
    like($isf, qr/\(set response_rlast rlast\)/, 'generated IAL1 captures RLAST raw');
    like($isf, qr/\(while active_q\s+\(wait 1\)\)/, 'generated transaction waits on latched ownership');
    like($isf, qr/\(complete r_beat_done\)/, 'generated transaction emits the beat-done pulse');

    is_deeply(
        [sort keys %{$result->{generated_ial0}{files}}],
        ['axi_r_beat_acceptor.fsm'],
        'adapter exposes one generated IAL0 FSM artifact',
    );
    my $fsm = $result->{generated_ial0}{files}{'axi_r_beat_acceptor.fsm'};
    like($fsm, qr/\(\?fsm:axi_r_beat_acceptor\b/, 'IAL0 artifact names the R acceptor FSM');
    like($fsm, qr/\(-accept_r <\(& active_q rvalid rready\)/, 'IAL0 preserves the accept predicate');
    like($fsm, qr/\(<- \(response_rdata> rdata\)\)/, 'IAL0 preserves RDATA capture');

    my $schedule = $result->{generated_ial1_schedule_report};
    is($schedule->{port_count}, 13, 'schedule has thirteen interface ports');
    is($schedule->{state_count}, 6, 'schedule has six transaction states');
    is_deeply($schedule->{compile_issues}, [], 'schedule is lowering-clean');
    is($schedule->{transactions}[0]{name}, 'r_receive', 'schedule names the R receive transaction');
    is_deeply(
        $schedule->{transactions}[0]{states},
        [qw(r_receive_idle_0 r_receive_drive_1 r_receive_while_entry_2 r_receive_wait_3 r_receive_while_check_4 r_receive_done_5)],
        'schedule exposes the exact six-state transaction',
    );
    is_deeply(
        [map { [$_->{name}, $_->{assignments}] } @{$schedule->{dt_blocks}}],
        [['arm_r', 3], ['accept_r', 7]],
        'arm and accept rules retain the exact assignment counts',
    );
    is_deeply(
        [sort map { join(':', $_->{winner}, $_->{loser}, $_->{target}) } @{$schedule->{priority_resolutions}}],
        [
            'accept_r:arm_r:active_q',
            'accept_r:arm_r:r_busy',
            'accept_r:arm_r:rready',
        ],
        'schedule resolves all three shared targets in favor of acceptance',
    );
};

subtest 'malformed and out-of-scope AXI R-beat sources fail closed' => sub {
    my @cases = (
        ['non-AXI profile', sub { mutate('(profile axi4)', '(profile ahb)') }, qr/profile 'ahb' does not match \(axi-r-beat-acceptor \.\.\.\)/, 'bad-profile.ppif'],
        ['wrong AXI family member', sub { mutate('(profile axi4)', '(profile axi5)') }, qr/profile must be axi4 in this slice/, 'bad-family.ppif'],
        ['wrong role', sub { mutate('(role subordinate-to-manager)', '(role manager-to-subordinate)') }, qr/role must be subordinate-to-manager/, 'bad-role.ppif'],
        ['ID width', sub { mutate('(id rid width 4)', '(id rid width 3)') }, qr/channel\.id\.width must be 4 in this slice/, 'bad-id.ppif'],
        ['captured ID width', sub { mutate('(captured-id response_rid width 4)', '(captured-id response_rid width 3)') }, qr/channel\.captured_id\.width must be 4 in this slice/, 'bad-captured-id.ppif'],
        ['data width', sub { mutate('(data rdata width 32)', '(data rdata width 16)') }, qr/channel\.data\.width must be 32 in this slice/, 'bad-data.ppif'],
        ['captured data width', sub { mutate('(captured-data response_rdata width 32)', '(captured-data response_rdata width 16)') }, qr/channel\.captured_data\.width must be 32 in this slice/, 'bad-captured-data.ppif'],
        ['response width', sub { mutate('(response rresp width 2)', '(response rresp width 3)') }, qr/channel\.response\.width must be 2 in this slice/, 'bad-response.ppif'],
        ['captured response width', sub { mutate('(captured-response response_rresp width 2)', '(captured-response response_rresp width 3)') }, qr/channel\.captured_response\.width must be 2 in this slice/, 'bad-captured-response.ppif'],
        ['malformed reset', sub { mutate('(reset (rst_n active_low async))', '(reset (rst_n sideways async))') }, qr/reset attribute 'sideways' must be active_low, active_high, async, or sync/, 'bad-reset.ppif'],
        ['duplicate object', sub { append_object(sample_r_acceptor_ppif(), second_r_acceptor_clause()) }, qr/supports exactly one \(axi-r-beat-acceptor \.\.\.\) object/, 'duplicate-object.ppif'],
        ['mixed object', sub { append_object(sample_r_acceptor_ppif(), w_driver_clause()) }, qr/cannot mix \(axi-r-beat-acceptor \.\.\.\) with other intent objects/, 'mixed-object.ppif'],
        ['duplicate arm binding', sub { mutate('(arm r_accept_cmd_valid)', "(arm r_accept_cmd_valid)\n      (arm r_accept_cmd_valid_2)") }, qr/has duplicate \(arm \.\.\.\) clause/, 'duplicate-arm.ppif'],
        ['unknown channel binding', sub { mutate('(done r_beat_done)', "(done r_beat_done)\n      (user ruser)") }, qr/has unsupported clause '\(user \.\.\.\)'/, 'unknown-channel.ppif'],
        ['missing last binding', sub { mutate("      (last rlast)\n", '') }, qr/is missing required \(last \.\.\.\) clause/, 'missing-last.ppif'],
        ['duplicate public signal', sub { mutate('(done r_beat_done)', '(done rready)') }, qr/duplicates signal 'rready'/, 'duplicate-signal.ppif'],
        ['reserved internal signal', sub { mutate('(done r_beat_done)', '(done active_q)') }, qr/duplicates signal 'active_q'/, 'reserved-signal.ppif'],
        ['profile alias', sub { sample_r_acceptor_ppif() }, qr/\(axi-r-beat-acceptor \.\.\.\) remains unsupported/, 'r-acceptor.axi'],
    );

    for my $case (@cases) {
        my ($label, $build_source, $pattern, $source_label) = @$case;
        my $ok = eval {
            FSM::Adapter::IAL2::PPIF->new()->parse_source($build_source->(), $source_label);
            1;
        };
        ok(!$ok, "$label is rejected");
        like($@, $pattern, "$label diagnostic is targeted");
    }
};

subtest 'CLI check, semantic export, schedule export, outdir, and external HDL verification use the public source' => sub {
    my $check = run_json_command('./bin/fsmgen', '--quiet', '--strict', '--check', '--json', sample_r_acceptor_ppif_path());
    ok($check->{success}, 'strict check JSON succeeds');
    is($check->{result}{module_name}, 'axi_r_beat_acceptor', 'check JSON reports the module');
    is($check->{support_accounting}{entry_id}, 'intent.ppif_axi_r_beat_acceptor', 'check JSON matches the support entry');
    ok($check->{support_accounting}{matched}, 'check JSON marks support accounting matched');

    my $semantic = run_json_command('./bin/fsmgen', '--quiet', '--strict', '--emit-semantic-json', sample_r_acceptor_ppif_path());
    ok($semantic->{success}, 'strict semantic JSON succeeds');
    is($semantic->{generation_result_snapshot}{summary}{module_name}, 'axi_r_beat_acceptor', 'semantic JSON reports the module');
    is($semantic->{generation_result_snapshot}{summary}{source_root_kind}, 'fsm', 'semantic JSON reports generated FSM input');

    my $schedule = run_json_command('./bin/fsmgen', '--quiet', '--emit-schedule-json', sample_r_acceptor_ppif_path());
    is($schedule->{schema}, 'fsmgen.ial2.protocol_intent.axi_r_beat_acceptor.v1', 'schedule export exposes the R schema');
    is($schedule->{generated_artifacts}{ial1}{name}, 'axi_r_beat_acceptor.isf', 'schedule export exposes IAL1');
    is_deeply($schedule->{generated_artifacts}{ial0}{files}, ['axi_r_beat_acceptor.fsm'], 'schedule export exposes IAL0');

    my $tempdir = tempdir(CLEANUP => 1);
    my $outdir = File::Spec->catdir($tempdir, 'out');
    my $hdl = File::Spec->catfile($tempdir, 'axi_r_beat_acceptor.sv');
    my ($generate_ok, undef, undef, undef, $generate_stderr) = run(
        command => ['./bin/fsmgen', '--quiet', '--strict', '--outdir', $outdir, '--output', $hdl, sample_r_acceptor_ppif_path()],
    );
    ok($generate_ok, 'public source emits HDL and review artifacts');
    is(join('', @{$generate_stderr || []}), '', 'outdir generation keeps stderr clean');
    ok(-f File::Spec->catfile($outdir, 'axi_r_beat_acceptor.isf'), 'outdir contains IAL1');
    ok(-f File::Spec->catfile($outdir, 'axi_r_beat_acceptor.fsm'), 'outdir contains IAL0');
    like(slurp($hdl), qr/\bmodule\s+axi_r_beat_acceptor\b/, 'HDL contains the selected module');

    my ($verify_ok, undef, undef, $verify_stdout, $verify_stderr) = run(
        command => ['./bin/fsmgen', '--verify-hdl', sample_r_acceptor_ppif_path()],
    );
    ok($verify_ok, 'public source passes external HDL verification')
        or diag(join('', @{$verify_stdout || []}), join('', @{$verify_stderr || []}));
    like(join('', @{$verify_stdout || []}), qr/verilator_lint: PASS/, 'generated HDL passes Verilator lint');
    like(join('', @{$verify_stdout || []}), qr/yosys_synthesis: PASS/, 'generated HDL passes Yosys synthesis');
};

subtest 'generated HDL accepts and captures exactly one R beat per arm across reset and timing cases' => sub {
    my $tempdir = tempdir(CLEANUP => 1);
    my $hdl = File::Spec->catfile($tempdir, 'axi_r_beat_acceptor.sv');
    my $testbench = File::Spec->catfile($tempdir, 'axi_r_beat_acceptor_cardinality_tb.sv');
    my $obj_dir = File::Spec->catdir($tempdir, 'obj_cardinality');

    my ($generate_ok, undef, undef, undef, $generate_stderr) = run(
        command => ['./bin/fsmgen', '--quiet', '--strict', '--output', $hdl, sample_r_acceptor_ppif_path()],
    );
    ok($generate_ok, 'public source emits simulation HDL');
    is(join('', @{$generate_stderr || []}), '', 'simulation HDL generation keeps stderr clean');

    write_file($testbench, <<'SV');
module axi_r_beat_acceptor_cardinality_tb;
  logic clk = 0;
  logic rst_n = 0;
  logic r_accept_cmd_valid = 0;
  logic rvalid = 0;
  logic [3:0] rid = 0;
  logic [31:0] rdata = 0;
  logic [1:0] rresp = 0;
  logic rlast = 0;
  wire rready;
  wire [3:0] response_rid;
  wire [31:0] response_rdata;
  wire [1:0] response_rresp;
  wire response_rlast;
  wire r_busy;
  wire r_beat_done;
  integer handshakes = 0;
  integer done_pulses = 0;
  integer wait_cycles = 0;
  logic previous_done = 0;

  axi_r_beat_acceptor dut (.*);
  always #5 clk = ~clk;

  always @(posedge clk) begin
    if (rst_n && rvalid && rready)
      handshakes <= handshakes + 1;
    if (rst_n && r_beat_done)
      done_pulses <= done_pulses + 1;
    if (rst_n && r_beat_done && previous_done)
      $fatal(1, "r_beat_done remained high for more than one cycle");
    previous_done <= rst_n && r_beat_done;
  end

  task automatic pulse_arm;
    begin
      @(negedge clk);
      r_accept_cmd_valid = 1;
      @(negedge clk);
      r_accept_cmd_valid = 0;
    end
  endtask

  task automatic wait_for_ready;
    begin
      wait_cycles = 0;
      while (!rready && wait_cycles < 10) begin
        @(negedge clk);
        wait_cycles = wait_cycles + 1;
      end
      if (!rready)
        $fatal(1, "armed receiver never raised RREADY");
    end
  endtask

  initial begin
    repeat (2) @(negedge clk);
    if (rready || r_busy || r_beat_done || response_rid || response_rdata || response_rresp || response_rlast)
      $fatal(1, "idle reset did not hold outputs and status low");
    rst_n = 1;
    repeat (2) @(negedge clk);

    // Unarmed RVALID cannot transfer.
    {rid, rdata, rresp, rlast} = {4'h3, 32'h1234_5678, 2'b10, 1'b0};
    rvalid = 1;
    repeat (3) @(negedge clk);
    if (handshakes != 0 || rready || r_busy)
      $fatal(1, "unarmed beat was accepted or receiver was active");

    // Already-high and then held-high RVALID accepts exactly once. Mutating the
    // unowned bus after acceptance must not alter the captured beat.
    pulse_arm();
    wait_for_ready();
    repeat (12) @(negedge clk);
    if (handshakes != 1 || done_pulses != 1)
      $fatal(1, "held-valid arm expected 1/1, got %0d/%0d", handshakes, done_pulses);
    if ({response_rid, response_rdata, response_rresp, response_rlast} !==
        {4'h3, 32'h1234_5678, 2'b10, 1'b0})
      $fatal(1, "first captured beat mismatch");
    {rid, rdata, rresp, rlast} = {4'he, 32'hfeed_face, 2'b01, 1'b1};
    repeat (4) @(negedge clk);
    if (handshakes != 1 ||
        {response_rid, response_rdata, response_rresp, response_rlast} !==
        {4'h3, 32'h1234_5678, 2'b10, 1'b0})
      $fatal(1, "held unarmed input repeated or mutated the capture");
    rvalid = 0;

    // Arm before valid, remain eager for at least four cycles, and ignore a
    // second arm pulse while the first ownership window is busy.
    pulse_arm();
    wait_for_ready();
    repeat (4) begin
      @(negedge clk);
      if (!rready || !r_busy)
        $fatal(1, "armed receiver dropped ready/busy before RVALID");
    end
    pulse_arm();
    {rid, rdata, rresp, rlast} = {4'h9, 32'hcafe_f00d, 2'b11, 1'b1};
    rvalid = 1;
    @(negedge clk);
    rvalid = 0;
    repeat (12) @(negedge clk);
    if (handshakes != 2 || done_pulses != 2)
      $fatal(1, "busy rearm/delayed beat expected totals 2/2, got %0d/%0d", handshakes, done_pulses);
    if ({response_rid, response_rdata, response_rresp, response_rlast} !==
        {4'h9, 32'hcafe_f00d, 2'b11, 1'b1})
      $fatal(1, "second captured beat mismatch");

    // Active reset cancels an armed ownership window without a transfer or a
    // late done pulse.
    pulse_arm();
    wait_for_ready();
    rst_n = 0;
    repeat (2) @(negedge clk);
    if (rready || r_busy || r_beat_done)
      $fatal(1, "active reset did not cancel ready/busy/done");
    rst_n = 1;
    repeat (8) @(negedge clk);
    if (handshakes != 2 || done_pulses != 2)
      $fatal(1, "reset-canceled arm produced a transfer or late done");

    // A one-cycle post-reset RVALID pulse is accepted and captured once.
    pulse_arm();
    wait_for_ready();
    {rid, rdata, rresp, rlast} = {4'h5, 32'h0bad_c0de, 2'b00, 1'b1};
    rvalid = 1;
    @(negedge clk);
    rvalid = 0;
    repeat (12) @(negedge clk);
    if (handshakes != 3 || done_pulses != 3)
      $fatal(1, "post-reset beat expected totals 3/3, got %0d/%0d", handshakes, done_pulses);
    if ({response_rid, response_rdata, response_rresp, response_rlast} !==
        {4'h5, 32'h0bad_c0de, 2'b00, 1'b1})
      $fatal(1, "post-reset captured beat mismatch");
    if (rready || r_busy || r_beat_done)
      $fatal(1, "post-reset beat did not finish idle");

    $display("PASS handshakes=%0d done_pulses=%0d rid=%0h rdata=%0h rresp=%0h rlast=%0h",
      handshakes, done_pulses, response_rid, response_rdata, response_rresp, response_rlast);
    $finish;
  end

  initial begin
    #9000;
    $fatal(1, "R-beat acceptor simulation timed out");
  end
endmodule
SV

    my ($compile_ok, undef, undef, $compile_stdout, $compile_stderr) = run(
        command => [
            'verilator', '--binary', '--timing', '--assert', '-Wno-fatal',
            '-j', '1', '--top-module', 'axi_r_beat_acceptor_cardinality_tb',
            '--Mdir', $obj_dir, $hdl, $testbench,
        ],
    );
    ok($compile_ok, 'Verilator builds the generated R-beat harness')
        or diag(join('', @{$compile_stdout || []}), join('', @{$compile_stderr || []}));
    return unless $compile_ok;

    my $binary = File::Spec->catfile($obj_dir, 'Vaxi_r_beat_acceptor_cardinality_tb');
    ok(-x $binary, 'R-beat harness binary exists');
    my ($run_ok, undef, undef, $run_stdout, $run_stderr) = run(command => [$binary]);
    ok($run_ok, 'generated R-beat acceptor simulation passes')
        or diag(join('', @{$run_stdout || []}), join('', @{$run_stderr || []}));
    like(
        join('', @{$run_stdout || []}),
        qr/PASS handshakes=3 done_pulses=3 rid=5 rdata=badc0de rresp=0 rlast=1/,
        'unarmed, held-high, delayed, busy-arm, reset, and one-cycle-valid cases retain exact cardinality and capture',
    );
};

done_testing();

sub sample_r_acceptor_ppif_path {
    return File::Spec->catfile($FindBin::Bin, '..', 'ppif', 'axi_r_beat_acceptor.ppif');
}

sub sample_r_acceptor_ppif {
    return slurp(sample_r_acceptor_ppif_path());
}

sub mutate {
    my ($from, $to) = @_;
    my $source = sample_r_acceptor_ppif();
    index($source, $from) >= 0 or die "mutation source text not found: $from";
    $source =~ s/\Q$from\E/$to/;
    return $source;
}

sub append_object {
    my ($source, $object) = @_;
    $source =~ s/\)\s*\z// or die 'sample PPIF root is not closed';
    return "$source\n  $object)\n";
}

sub second_r_acceptor_clause {
    return <<'PPIF';
(axi-r-beat-acceptor axi_r_beat_acceptor_2
    (role subordinate-to-manager)
    (clock clk2)
    (reset (rst2_n active_low async))
    (command (arm r2_accept_cmd_valid))
    (channel
      (valid rvalid2) (ready rready2)
      (id rid2 width 4) (data rdata2 width 32)
      (response rresp2 width 2) (last rlast2)
      (captured-id response_rid2 width 4)
      (captured-data response_rdata2 width 32)
      (captured-response response_rresp2 width 2)
      (captured-last response_rlast2)
      (busy r_busy2) (done r_beat_done2)))
PPIF
}

sub w_driver_clause {
    return <<'PPIF';
(axi-w-driver mixed_w
    (role manager-to-subordinate)
    (clock wclk)
    (reset (wrst_n active_low async))
    (command
      (start w_cmd_valid) (data cmd_wdata width 32)
      (strobe cmd_wstrb width 4) (ready wready))
    (channel
      (valid wvalid) (data wdata width 32) (strobe wstrb width 4)
      (last wlast) (busy w_busy) (done w_done)))
PPIF
}

sub run_json_command {
    my (@command) = @_;
    my ($success, undef, undef, $stdout, $stderr) = run(command => \@command);
    ok($success, "command succeeds: @command")
        or diag(join('', @{$stdout || []}), join('', @{$stderr || []}));
    return decode_json(join('', @{$stdout || []}));
}

sub slurp {
    my ($path) = @_;
    open my $fh, '<', $path or die "cannot read $path: $!";
    local $/;
    my $text = <$fh>;
    close $fh or die "cannot close $path: $!";
    return $text;
}

sub write_file {
    my ($path, $text) = @_;
    open my $fh, '>', $path or die "cannot write $path: $!";
    print {$fh} $text;
    close $fh or die "cannot close $path: $!";
}
