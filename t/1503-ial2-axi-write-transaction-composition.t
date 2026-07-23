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

subtest 'adapter report and flat five-child composition preserve the selected contract' => sub {
    ok(-f sample_path(), 'tracked runnable AXI full-write transaction composition source exists');
    my $result = FSM::Adapter::IAL2::PPIF->new()->parse_file(sample_path());
    my $report = $result->{report};

    is($result->{layer}, 'IAL2', 'composition result stays at the IAL2 boundary');
    is($result->{kind}, 'protocol_intent.axi_write_transaction_composition', 'composition kind is exact');
    is($result->{mode}, 'write-transaction-composition', 'composition mode is exact');
    is($report->{schema}, 'fsmgen.ial2.protocol_intent.axi_write_transaction_composition.v1', 'report schema is exact');
    is($report->{source_object}{id}, 'axi-write-transaction-composition', 'source object identity is preserved');
    is($report->{source_object}{intent_name}, 'axi_write_transaction_composition', 'root intent name is preserved');
    is_deeply(
        [map { [$_->{section}, $_->{page}] } @{$report->{source_object}{anchors}}],
        [
            ['A3.2.1', 'A3-40'],
            ['A2.3', '29'],
            ['A2.3.1', '30'],
            ['A2.3.2.1', '31'],
            ['A3.2.1', '53'],
            ['A3.2.1.1', '54'],
            ['A3.3', '61'],
            ['A3.3.1', '61'],
            ['B1.1.3', '278'],
        ],
        'nine selected source anchors remain ordered and exact',
    );
    is_deeply(
        $report->{target_protocol},
        { profile => 'axi4', object => 'axi-write-transaction-composition', role => 'manager' },
        'target protocol identity is exact',
    );
    is($report->{bindings}{command}{id}{width}, 4, 'admitted AWID width is pinned');
    is($report->{bindings}{b_channel}{captured_response}{width}, 2, 'captured BRESP width is pinned');
    is($report->{bindings}{status}{request_done}, 'write_request_done', 'request completion binding is distinct');
    is($report->{bindings}{status}{transaction_done}, 'write_transaction_done', 'transaction completion binding is distinct');
    is_deeply(
        $report->{single_beat_policy},
        {
            address_width           => 32,
            address_alignment_bytes => 4,
            id_width                => 4,
            data_width              => 32,
            strobe_width            => 4,
            all_zero_strobe_allowed => JSON::PP::true,
            awlen                   => 0,
            awsize                  => 2,
            awburst                 => 1,
            awburst_name            => 'INCR',
            wlast                   => 1,
            beat_count              => 1,
            request_completion      => 'both_aw_and_w_accepted',
            response_completion     => 'b_response_accepted_and_captured',
        },
        'fixed single-beat AW W B policy is complete and exact',
    );
    is($report->{request_composition_reuse}{generator}, 'FSM::IAL2::ProtocolIntent::AxiWriteRequestComposition', 'request composition is the sole AW/W source');
    ok(!$report->{request_composition_reuse}{nested_top_selected}, 'nested request top is not selected');
    is($report->{request_composition_reuse}{omitted_top_artifact}, 'axi_write_request_private.fsm', 'private nested top is omitted');
    is($report->{transaction_coordinator}{b_arm_policy}, 'arm_after_request_completion', 'B is armed only after request completion');
    is($report->{transaction_coordinator}{busy_policy}, 'admission_through_b_response_retirement', 'busy spans the whole write transaction');
    is($report->{transaction_coordinator}{mismatch_policy}, 'terminal_completion_with_match_zero_and_assertion', 'BID mismatch policy is explicit');
    is($report->{transaction_coordinator}{response_status_policy}, 'raw_bresp_capture_not_success_interpretation', 'BRESP remains raw status');
    is_deeply(
        [map { [$_->{role}, $_->{instance_name}] } @{$report->{children}}],
        [
            ['aw-driver', 'aw_driver'],
            ['w-driver', 'w_driver'],
            ['request-coordinator', 'request_coordinator'],
            ['b-acceptor', 'b_acceptor'],
            ['transaction-coordinator', 'transaction_coordinator'],
        ],
        'five generated children are flat, ordered, and named',
    );
    is($report->{generated_schedules}{count}, 5, 'five child schedule reports are exposed');
    is_deeply(
        [map { $_->{report}{compile_issues} } @{$report->{generated_schedules}{items}}],
        [[], [], [], [], []],
        'all child schedules are lowering-clean',
    );

    my ($coordinator_item) = grep {
        $_->{object_name} eq 'axi_write_transaction_coordinator'
    } @{$result->{generated_ial1}{items}};
    my $coordinator_isf = $coordinator_item->{text};
    like($coordinator_isf, qr/\(rule arm_response \(& active_q \(! response_armed_q\) request_done_i \(! b_busy_i\)\)/, 'transaction coordinator gates B arm on request completion');
    like($coordinator_isf, qr/\(set response_id_match \(== captured_bid_i expected_awid_q\)\)/, 'transaction coordinator compares captured BID to retained AWID');
    like($coordinator_isf, qr/accepted AXI BID must match admitted AWID/, 'transaction coordinator carries the mismatch assertion');
    my ($coordinator_schedule) = grep {
        $_->{object_name} eq 'axi_write_transaction_coordinator'
    } @{$report->{generated_schedules}{items}};
    is($coordinator_schedule->{report}{state_count}, 0, 'transaction coordinator remains rule-only');
    is_deeply(
        [map { [$_->{name}, $_->{assignments}] } @{$coordinator_schedule->{report}{dt_blocks}}],
        [
            ['admit', 8],
            ['clear_request_start', 1],
            ['arm_response', 3],
            ['clear_b_arm', 1],
            ['clear_request_done', 1],
            ['finish_response', 5],
            ['clear_transaction_done', 1],
        ],
        'seven transaction-coordinator rule DTs retain exact assignment counts',
    );
    is_deeply(
        [map { [$_->{winner}, $_->{loser}, $_->{target}] } @{$coordinator_schedule->{report}{priority_resolutions}}],
        [
            ['arm_response', 'clear_b_arm', 'b_arm_i'],
            ['admit', 'clear_request_start', 'request_cmd_valid_i'],
            ['arm_response', 'clear_request_done', 'write_request_done'],
            ['finish_response', 'clear_transaction_done', 'write_transaction_done'],
        ],
        'four realized transaction-coordinator pulse priorities are exact',
    );
    is_deeply(
        $report->{generated_artifacts}{ial0}{files},
        [qw(
            axi_aw_driver.fsm
            axi_b_response_acceptor.fsm
            axi_w_driver.fsm
            axi_write_request_coordinator.fsm
            axi_write_transaction_composition.fsm
            axi_write_transaction_coordinator.fsm
        )],
        'five leaf FSMs plus one selected top are exact',
    );
    is($report->{generated_artifacts}{hdl_entry}{entry_artifact}, 'axi_write_transaction_composition.fsm', 'structural top artifact is selected');
    is(scalar(@{$report->{enforced_static_rules}}), 12, 'report carries twelve static rules');
    is(scalar(@{$report->{unsupported_residue}}), 13, 'report keeps thirteen bounded deferrals explicit');

    my $top = $result->{generated_ial0}{files}{'axi_write_transaction_composition.fsm'};
    like($top, qr/\A\(\?top:axi_write_transaction_composition\b/, 'generated IAL0 entry is a structural top');
    like($top, qr/\(\?fsmc:request_coordinator axi_write_request_coordinator\)/, 'top directly instantiates the reused request coordinator leaf');
    like($top, qr/\(\?fsmc:b_acceptor axi_b_response_acceptor\)/, 'top directly instantiates the B acceptor');
    like($top, qr/\(\?fsmc:transaction_coordinator axi_write_transaction_coordinator\)/, 'top directly instantiates the transaction coordinator');
    unlike($top, qr/\?fsmc:\S+ axi_write_request_private/, 'top does not retain a nested request-composition child');
    like($top, qr/\(transaction_coordinator\.b_arm_i b_acceptor\.b_arm_i\)/, 'top links post-request B arm explicitly');
    like($top, qr/\(b_acceptor\.response_bid transaction_coordinator\.captured_bid_i\)/, 'top feeds captured BID to the transaction coordinator');
};

subtest 'malformed and expanded full-write contracts fail closed' => sub {
    my @cases = (
        ['wrong root', sub { replace_once(sample_text(), '(protocol-platform-intent', '(wrong-root') }, qr/must start with \(protocol-platform-intent/, 'bad-root.ppif'],
        ['wrong profile family', sub { replace_once(sample_text(), '(profile axi4)', '(profile ahb)') }, qr/profile 'ahb' does not match \(axi-write-transaction-composition/, 'bad-profile.ppif'],
        ['non-AXI4 profile', sub { replace_once(sample_text(), '(profile axi4)', '(profile axi3)') }, qr/profile must be axi4 in this slice/, 'axi3.ppif'],
        ['wrong role', sub { replace_once(sample_text(), '(role manager)', '(role subordinate-to-manager)') }, qr/role must be manager/, 'bad-role.ppif'],
        ['synchronous reset', sub { replace_once(sample_text(), '(rst_n active_low async)', '(rst_n active_low sync)') }, qr/reset must be asynchronous active-low/, 'sync-reset.ppif'],
        ['active-high reset', sub { replace_once(sample_text(), '(rst_n active_low async)', '(rst_n active_high async)') }, qr/reset must be asynchronous active-low/, 'active-high.ppif'],
        ['duplicate command block', sub { replace_once(sample_text(), "    (aw-channel\n", duplicate_command_clause() . "    (aw-channel\n") }, qr/duplicate \(command \.\.\.\) clause/, 'duplicate-command.ppif'],
        ['unknown object clause', sub { replace_once(sample_text(), "    (status\n", "    (unknown value)\n    (status\n") }, qr/unsupported clause '\(unknown \.\.\.\)'/, 'unknown.ppif'],
        ['missing B channel', sub { my $s = sample_text(); $s =~ s/\n    \(b-channel\n(?:.*\n){5}      \(captured-response response_bresp width 2\)\)// or die; return $s }, qr/missing required \(b-channel \.\.\.\) clause/, 'missing-b.ppif'],
        ['missing transaction done', sub { my $s = sample_text(); $s =~ s/\n      \(transaction-done write_transaction_done\)// or die; return $s }, qr/status \.\.\.\) is missing required \(transaction-done \.\.\.\) clause/, 'missing-done.ppif'],
        ['missing captured BID', sub { my $s = sample_text(); $s =~ s/\n      \(captured-id response_bid width 4\)// or die; return $s }, qr/b-channel \.\.\.\) is missing required \(captured-id \.\.\.\) clause/, 'missing-bid.ppif'],
        ['dynamic AW metadata', sub { replace_once(sample_text(), '      (strobe cmd_wstrb width 4))', "      (strobe cmd_wstrb width 4)\n      (length cmd_awlen width 8))") }, qr/command \.\.\.\) has unsupported clause '\(length \.\.\.\)'/, 'dynamic-metadata.ppif'],
        ['nested child object', sub { replace_once(sample_text(), "    (status\n", "    (axi-b-response-acceptor nested)\n    (status\n") }, qr/unsupported clause '\(axi-b-response-acceptor \.\.\.\)'/, 'nested-child.ppif'],
        ['mixed standalone child', sub { append_root_clause(sample_text(), standalone_aw_clause()) }, qr/cannot mix \(axi-write-transaction-composition \.\.\.\) with other intent objects/, 'mixed-child.ppif'],
        ['multiple aggregate objects', sub { append_root_clause(sample_text(), second_composition_clause()) }, qr/supports exactly one \(axi-write-transaction-composition \.\.\.\) object/, 'duplicate-object.ppif'],
        ['duplicate public binding', sub { replace_once(sample_text(), '(response-id-match response_id_match)', '(response-id-match write_busy)') }, qr/duplicates signal 'write_busy'/, 'duplicate-signal.ppif'],
        ['generated artifact collision', sub { replace_once(sample_text(), '(axi-write-transaction-composition axi_write_transaction_composition', '(axi-write-transaction-composition axi_aw_driver') }, qr/duplicate \.fsm artifact 'axi_aw_driver\.fsm'/, 'artifact-collision.ppif'],
        ['profile alias rejection', sub { sample_text() }, qr/\(axi-write-transaction-composition \.\.\.\) remains unsupported for the first profile-alias implementation/, 'composition.axi'],
    );

    my @width_cases = (
        ['command.address', '(address cmd_awaddr width 32)', '(address cmd_awaddr width 16)', qr/command\.address\.width must be 32/],
        ['command.id', '(id cmd_awid width 4)', '(id cmd_awid width 3)', qr/command\.id\.width must be 4/],
        ['command.data', '(data cmd_wdata width 32)', '(data cmd_wdata width 16)', qr/command\.data\.width must be 32/],
        ['command.strobe', '(strobe cmd_wstrb width 4)', '(strobe cmd_wstrb width 2)', qr/command\.strobe\.width must be 4/],
        ['aw_channel.address', '(address awaddr width 32)', '(address awaddr width 16)', qr/aw_channel\.address\.width must be 32/],
        ['aw_channel.id', '(id awid width 4)', '(id awid width 3)', qr/aw_channel\.id\.width must be 4/],
        ['w_channel.data', '(data wdata width 32)', '(data wdata width 16)', qr/w_channel\.data\.width must be 32/],
        ['b_channel.id', '(id bid width 4)', '(id bid width 3)', qr/b_channel\.id\.width must be 4/],
        ['b_channel.response', '(response bresp width 2)', '(response bresp width 3)', qr/b_channel\.response\.width must be 2/],
        ['b_channel.captured_id', '(captured-id response_bid width 4)', '(captured-id response_bid width 3)', qr/b_channel\.captured_id\.width must be 4/],
        ['b_channel.captured_response', '(captured-response response_bresp width 2)', '(captured-response response_bresp width 3)', qr/b_channel\.captured_response\.width must be 2/],
    );
    for my $case (@width_cases) {
        my ($label, $from, $to, $pattern) = @$case;
        push @cases, ["wrong $label width", sub { replace_once(sample_text(), $from, $to) }, $pattern, "$label.ppif"];
    }

    for my $case (@cases) {
        my ($label, $source_builder, $pattern, $source_label) = @$case;
        my $accepted = eval {
            FSM::Adapter::IAL2::PPIF->new()->parse_source($source_builder->(), $source_label);
            1;
        };
        ok(!$accepted, "$label is rejected");
        like($@, $pattern, "$label diagnostic is targeted");
    }
};

subtest 'CLI support accounting and external HDL use the public full-write path' => sub {
    my $check = run_json_command('./bin/fsmgen', '--quiet', '--strict', '--check', '--json', sample_path());
    ok($check->{success}, 'strict check JSON succeeds');
    is($check->{result}{module_name}, 'axi_write_transaction_composition', 'check JSON reports the structural top module');
    is($check->{result}{composition_child_count}, 5, 'check JSON reports five structural children');
    is($check->{result}{signal_count}, 29, 'check JSON reports twenty-nine public signals');
    is($check->{support_accounting}{entry_id}, 'intent.ppif_axi_write_transaction_composition', 'check JSON matches support accounting');

    my $schedule = run_json_command('./bin/fsmgen', '--quiet', '--emit-schedule-json', sample_path());
    is($schedule->{schema}, 'fsmgen.ial2.protocol_intent.axi_write_transaction_composition.v1', 'schedule JSON exposes aggregate schema');
    is($schedule->{generated_schedules}{count}, 5, 'schedule JSON exposes all five child schedules');

    my $semantic = run_json_command('./bin/fsmgen', '--quiet', '--strict', '--emit-semantic-json', sample_path());
    ok($semantic->{success}, 'strict semantic JSON succeeds');
    is($semantic->{generation_result_snapshot}{summary}{source_root_kind}, 'top', 'semantic JSON identifies a structural top root');
    is($semantic->{semantic}{composition}{lane}, 'C4', 'semantic JSON identifies the C4 lane');
    is($semantic->{generation_result_snapshot}{summary}{composition_child_count}, 5, 'semantic JSON reports five children');
    is($semantic->{support_accounting}{entry_id}, 'intent.ppif_axi_write_transaction_composition', 'semantic JSON matches support accounting');

    my $tempdir = tempdir(CLEANUP => 1);
    my $outdir = File::Spec->catdir($tempdir, 'out');
    my $hdl = File::Spec->catfile($tempdir, 'axi_write_transaction_composition.sv');
    my ($emit_ok, undef, undef, undef, $emit_stderr) = run(
        command => ['./bin/fsmgen', '--quiet', '--strict', '--outdir', $outdir, '--output', $hdl, sample_path()],
    );
    ok($emit_ok, 'public source emits HDL and review artifacts through --outdir');
    is(join('', @{$emit_stderr || []}), '', 'outdir generation keeps stderr clean');
    for my $artifact (qw(
        axi_aw_driver.isf
        axi_w_driver.isf
        axi_write_request_coordinator.isf
        axi_b_response_acceptor.isf
        axi_write_transaction_coordinator.isf
        axi_aw_driver.fsm
        axi_w_driver.fsm
        axi_write_request_coordinator.fsm
        axi_b_response_acceptor.fsm
        axi_write_transaction_coordinator.fsm
        axi_write_transaction_composition.fsm
    )) {
        ok(-f File::Spec->catfile($outdir, $artifact), "outdir contains $artifact");
    }
    ok(!-f File::Spec->catfile($outdir, 'axi_write_request_private.fsm'), 'outdir omits the private nested request top');
    like(slurp($hdl), qr/\bmodule\s+axi_write_transaction_composition\b/, 'generated HDL contains the structural top');

    my ($verify_ok, undef, undef, $verify_stdout, $verify_stderr) = run(
        command => ['./bin/fsmgen', '--verify-hdl', '--output', File::Spec->catfile($tempdir, 'verify.sv'), sample_path()],
    );
    ok($verify_ok, 'composition passes external HDL verification')
        or diag(join('', @{$verify_stdout || []}), join('', @{$verify_stderr || []}));
    my $verify_text = join('', @{$verify_stdout || []});
    like($verify_text, qr/verilator_lint: PASS/, 'generated structural HDL passes Verilator lint');
    like($verify_text, qr/yosys_synthesis: PASS/, 'generated structural HDL passes Yosys synthesis');
};

subtest 'generated structural top joins AW W then retires matched and mismatched B responses' => sub {
    my $tempdir = tempdir(CLEANUP => 1);
    my $hdl = File::Spec->catfile($tempdir, 'axi_write_transaction_composition.sv');
    my $testbench = File::Spec->catfile($tempdir, 'axi_write_transaction_composition_tb.sv');
    my $obj_dir = File::Spec->catdir($tempdir, 'obj');

    my ($generate_ok, undef, undef, undef, $generate_stderr) = run(
        command => ['./bin/fsmgen', '--quiet', '--strict', '--output', $hdl, sample_path()],
    );
    ok($generate_ok, 'public composition source emits structural HDL for simulation');
    is(join('', @{$generate_stderr || []}), '', 'behavior HDL generation keeps stderr clean');
    like(slurp($hdl), qr/accepted AXI BID must match admitted AWID/, 'emitted coordinator HDL retains the BID-match assertion text');

    write_file($testbench, <<'SV');
module axi_write_transaction_composition_tb;
  logic clk = 0;
  logic rst_n = 0;
  logic write_cmd_valid = 0;
  logic [31:0] cmd_awaddr = 0;
  logic [3:0] cmd_awid = 0;
  logic [31:0] cmd_wdata = 0;
  logic [3:0] cmd_wstrb = 0;
  logic awready = 0;
  logic wready = 0;
  logic bvalid = 0;
  logic [3:0] bid = 0;
  logic [1:0] bresp = 0;
  wire awvalid;
  wire [31:0] awaddr;
  wire [3:0] awid;
  wire [7:0] awlen;
  wire [2:0] awsize;
  wire [1:0] awburst;
  wire wvalid;
  wire [31:0] wdata;
  wire [3:0] wstrb;
  wire wlast;
  wire bready;
  wire [3:0] response_bid;
  wire [1:0] response_bresp;
  wire write_busy;
  wire write_request_done;
  wire write_transaction_done;
  wire response_id_match;
  integer aw_handshakes = 0;
  integer w_handshakes = 0;
  integer b_handshakes = 0;
  integer request_pulses = 0;
  integer transaction_pulses = 0;
  integer cycles = 0;

  axi_write_transaction_composition dut (.*);
  always #5 clk = ~clk;

  always @(posedge clk) begin
    if (rst_n) begin
      if (awvalid && {awlen, awsize, awburst} !== {8'd0, 3'd2, 2'd1})
        $fatal(1, "fixed AW metadata mismatch");
      if (wvalid && !wlast)
        $fatal(1, "WLAST was not high on the single beat");
      if (bready && (aw_handshakes <= b_handshakes || w_handshakes <= b_handshakes))
        $fatal(1, "B was armed before both request handshakes");
      if (awvalid && awready) begin
        case (aw_handshakes)
          0: if ({awaddr, awid} !== {32'h00001000, 4'h1}) $fatal(1, "command 1 AW payload mismatch");
          1: if ({awaddr, awid} !== {32'h00002000, 4'h2}) $fatal(1, "command 2 AW payload mismatch");
          2: if ({awaddr, awid} !== {32'h00003000, 4'h3}) $fatal(1, "command 3 AW payload mismatch");
          default: $fatal(1, "unexpected extra AW transfer");
        endcase
        aw_handshakes <= aw_handshakes + 1;
      end
      if (wvalid && wready) begin
        case (w_handshakes)
          0: if ({wdata, wstrb} !== {32'h11112222, 4'h0}) $fatal(1, "command 1 W payload/zero strobe mismatch");
          1: if ({wdata, wstrb} !== {32'h33334444, 4'ha}) $fatal(1, "command 2 W payload mismatch");
          2: if ({wdata, wstrb} !== {32'h55556666, 4'h5}) $fatal(1, "command 3 W payload mismatch");
          default: $fatal(1, "unexpected extra W transfer");
        endcase
        w_handshakes <= w_handshakes + 1;
      end
      if (bvalid && bready)
        b_handshakes <= b_handshakes + 1;
      if (write_request_done)
        request_pulses <= request_pulses + 1;
      if (write_transaction_done)
        transaction_pulses <= transaction_pulses + 1;
    end
  end

  task automatic pulse_command(input [31:0] address, input [3:0] id, input [31:0] data, input [3:0] strobe);
    begin
      @(negedge clk);
      cmd_awaddr = address;
      cmd_awid = id;
      cmd_wdata = data;
      cmd_wstrb = strobe;
      write_cmd_valid = 1;
      @(negedge clk);
      write_cmd_valid = 0;
    end
  endtask

  task automatic wait_for_request(input integer count);
    begin
      cycles = 0;
      while ((request_pulses < count || !bready) && cycles < 120) begin
        @(negedge clk);
        cycles = cycles + 1;
      end
      if (request_pulses != count || !bready)
        $fatal(1, "request/B-arm wait failed: request=%0d bready=%0d", request_pulses, bready);
      if (!write_busy)
        $fatal(1, "aggregate busy dropped before B retirement");
    end
  endtask

  task automatic send_response(input [3:0] response_id, input [1:0] response_code, input integer count, input bit expected_match);
    begin
      @(negedge clk);
      bid = response_id;
      bresp = response_code;
      bvalid = 1;
      @(negedge clk);
      bvalid = 0;
      cycles = 0;
      while (transaction_pulses < count && cycles < 80) begin
        @(negedge clk);
        cycles = cycles + 1;
      end
      if (transaction_pulses != count || b_handshakes != count)
        $fatal(1, "response retirement failed: B=%0d transaction=%0d", b_handshakes, transaction_pulses);
      if ({response_bid, response_bresp} !== {response_id, response_code})
        $fatal(1, "captured B response mismatch");
      if (response_id_match !== expected_match)
        $fatal(1, "response ID match result mismatch");
    end
  endtask

  initial begin
    repeat (2) @(negedge clk);
    rst_n = 1;
    repeat (2) @(negedge clk);

    // Misalignment is asserted in emitted HDL and also guards all physical launch.
    awready = 1;
    wready = 1;
    pulse_command(32'h00001003, 4'hf, 32'hdeadbeef, 4'hf);
    repeat (12) @(negedge clk);
    if (awvalid || wvalid || bready || write_busy || aw_handshakes || w_handshakes || b_handshakes)
      $fatal(1, "misaligned command launched transaction activity");

    // Simultaneous AW/W completion, zero strobe, and BVALID already high
    // before request admission. The B acceptor must still wait for B arm.
    bid = 4'h1;
    bresp = 2'b10;
    bvalid = 1;
    if (bready)
      $fatal(1, "unarmed already-high BVALID was accepted");
    pulse_command(32'h00001000, 4'h1, 32'h11112222, 4'h0);
    cmd_awaddr = 32'hffff0000;
    cmd_awid = 4'he;
    cmd_wdata = 32'haaaaaaaa;
    cmd_wstrb = 4'hf;
    cycles = 0;
    while (b_handshakes < 1 && cycles < 120) begin
      @(negedge clk);
      cycles = cycles + 1;
    end
    if (b_handshakes != 1)
      $fatal(1, "already-high BVALID did not retire after request completion");
    bvalid = 0;
    cycles = 0;
    while (transaction_pulses < 1 && cycles < 80) begin
      @(negedge clk);
      cycles = cycles + 1;
    end
    if (request_pulses != 1 || transaction_pulses != 1)
      $fatal(1, "already-high response completion pulses mismatch");
    if ({response_bid, response_bresp, response_id_match} !== {4'h1, 2'b10, 1'b1})
      $fatal(1, "already-high matched non-OKAY response capture mismatch");

    // AW first while W remains stable under backpressure.
    awready = 1;
    wready = 0;
    pulse_command(32'h00002000, 4'h2, 32'h33334444, 4'ha);
    cycles = 0;
    while ((!wvalid || aw_handshakes < 2) && cycles < 80) begin
      @(negedge clk);
      cycles = cycles + 1;
    end
    if (!wvalid || aw_handshakes != 2 || bready)
      $fatal(1, "command 2 did not reach pre-B AW-first state");
    repeat (4) begin
      @(negedge clk);
      if (!wvalid || {wdata, wstrb, wlast} !== {32'h33334444, 4'ha, 1'b1})
        $fatal(1, "stalled W payload changed");
    end
    wready = 1;
    wait_for_request(2);
    repeat (4) begin
      @(negedge clk);
      if (!bready || !write_busy || write_transaction_done)
        $fatal(1, "delayed BVALID wait did not preserve ready/busy/no-done state");
    end
    pulse_command(32'h0000f000, 4'hf, 32'hffffffff, 4'hf);
    send_response(4'h2, 2'b00, 2, 1'b1);

    // W first while AW remains stable, then terminally complete BID mismatch.
    awready = 0;
    wready = 1;
    pulse_command(32'h00003000, 4'h3, 32'h55556666, 4'h5);
    cycles = 0;
    while ((!awvalid || w_handshakes < 3) && cycles < 80) begin
      @(negedge clk);
      cycles = cycles + 1;
    end
    if (!awvalid || w_handshakes != 3 || bready)
      $fatal(1, "command 3 did not reach pre-B W-first state");
    repeat (4) begin
      @(negedge clk);
      if (!awvalid || {awaddr, awid, awlen, awsize, awburst} !== {32'h00003000, 4'h3, 8'd0, 3'd2, 2'd1})
        $fatal(1, "stalled AW payload changed");
    end
    awready = 1;
    wait_for_request(3);
    send_response(4'h4, 2'b11, 3, 1'b0);
    repeat (8) @(negedge clk);

    if (aw_handshakes != 3 || w_handshakes != 3 || b_handshakes != 3 || request_pulses != 3 || transaction_pulses != 3)
      $fatal(1, "final transaction cardinality mismatch");
    if (awvalid || wvalid || bready || write_busy || write_request_done || write_transaction_done)
      $fatal(1, "composition did not return fully idle");

    $display("PASS aw=%0d w=%0d b=%0d request=%0d transaction=%0d mismatch_terminal=%0d", aw_handshakes, w_handshakes, b_handshakes, request_pulses, transaction_pulses, !response_id_match);
    $finish;
  end

  initial begin
    #30000;
    $fatal(1, "AXI full-write transaction composition simulation timed out");
  end
endmodule
SV

    my ($compile_ok, undef, undef, $compile_stdout, $compile_stderr) = run(
        command => [
            'verilator', '--binary', '--timing', '--no-assert', '-Wno-fatal', '-j', '1',
            '--top-module', 'axi_write_transaction_composition_tb',
            '--Mdir', $obj_dir, $hdl, $testbench,
        ],
    );
    ok($compile_ok, 'Verilator builds the generated structural-top harness with assertions disabled')
        or diag(join('', @{$compile_stdout || []}), join('', @{$compile_stderr || []}));
    return unless $compile_ok;

    my $binary = File::Spec->catfile($obj_dir, 'Vaxi_write_transaction_composition_tb');
    ok(-x $binary, 'structural-top simulation binary exists');
    my ($run_ok, undef, undef, $run_stdout, $run_stderr) = run(command => [$binary]);
    ok($run_ok, 'generated structural-top behavior passes')
        or diag(join('', @{$run_stdout || []}), join('', @{$run_stderr || []}));
    like(
        join('', @{$run_stdout || []}),
        qr/PASS aw=3 w=3 b=3 request=3 transaction=3 mismatch_terminal=1/,
        'alignment, capture, AW/W ordering, already-high/delayed BVALID, B gating, raw response capture, busy, pulses, match, and terminal mismatch checks all pass',
    );
};

done_testing();

sub sample_path {
    return File::Spec->catfile($FindBin::Bin, '..', 'ppif', 'axi_write_transaction_composition.ppif');
}

sub sample_text {
    return slurp(sample_path());
}

sub replace_once {
    my ($source, $from, $to) = @_;
    my $count = ($source =~ s/\Q$from\E/$to/);
    die "failed to replace '$from'\n" unless $count == 1;
    return $source;
}

sub append_root_clause {
    my ($source, $clause) = @_;
    $source =~ s/\)\s*\z/$clause\n)\n/ or die "failed to append root clause\n";
    return $source;
}

sub standalone_aw_clause {
    return <<'PPIF';
  (axi-aw-driver extra_aw
    (role manager-to-subordinate)
    (clock extra_clk)
    (reset (extra_rst_n active_low async))
    (command
      (start extra_start)
      (address extra_cmd_addr width 32)
      (id extra_cmd_id width 4)
      (length extra_cmd_len width 8)
      (size extra_cmd_size width 3)
      (burst extra_cmd_burst width 2)
      (ready extra_ready))
    (channel
      (valid extra_valid)
      (address extra_addr width 32)
      (id extra_id width 4)
      (length extra_len width 8)
      (size extra_size width 3)
      (burst extra_burst width 2)
      (busy extra_busy)
      (done extra_done)))
PPIF
}

sub duplicate_command_clause {
    return <<'PPIF';
    (command
      (start duplicate_start)
      (address duplicate_address width 32)
      (id duplicate_id width 4)
      (data duplicate_data width 32)
      (strobe duplicate_strobe width 4))
PPIF
}

sub second_composition_clause {
    my $source = sample_text();
    my $start = index($source, '  (axi-write-transaction-composition');
    die "failed to locate aggregate object\n" if $start < 0;
    my $object = substr($source, $start);
    $object =~ s/\)\s*\z// or die "failed to remove root close\n";
    $object =~ s/axi_write_transaction_composition/axi_write_transaction_composition_2/g;
    $object =~ s/\b(clk|rst_n|write_cmd_valid|cmd_awaddr|cmd_awid|cmd_wdata|cmd_wstrb|awready|awvalid|awaddr|awid|awlen|awsize|awburst|wready|wvalid|wdata|wstrb|wlast|bvalid|bready|bid|bresp|response_bid|response_bresp|write_busy|write_request_done|write_transaction_done|response_id_match)\b/${1}_2/g;
    return $object;
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
