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

subtest 'adapter report and generated composition preserve the selected contract' => sub {
    ok(-f sample_path(), 'tracked runnable AXI write-request composition source exists');
    my $result = FSM::Adapter::IAL2::PPIF->new()->parse_file(sample_path());
    my $report = $result->{report};

    is($result->{layer}, 'IAL2', 'composition result stays at the IAL2 boundary');
    is($result->{kind}, 'protocol_intent.axi_write_request_composition', 'composition kind is exact');
    is($result->{mode}, 'write-request-composition', 'composition mode is exact');
    is($report->{schema}, 'fsmgen.ial2.protocol_intent.axi_write_request_composition.v1', 'report schema is exact');
    is($report->{source_object}{id}, 'axi-write-request-composition', 'source object identity is preserved');
    is($report->{source_object}{intent_name}, 'axi_write_request_composition', 'root intent name is preserved');
    is_deeply(
        [map { [$_->{section}, $_->{page}] } @{$report->{source_object}{anchors}}],
        [
            ['A3.2.1', 'A3-40'],
            ['A2.3', '29'],
            ['A2.3.1', '30'],
            ['A2.3.2.1', '31'],
            ['A3.2.1', '53'],
            ['A3.2.1.1', '54'],
        ],
        'six selected source anchors remain ordered and exact',
    );
    is_deeply(
        $report->{target_protocol},
        {
            profile => 'axi4',
            object  => 'axi-write-request-composition',
            role    => 'manager-to-subordinate',
        },
        'target protocol identity is exact',
    );
    is($report->{bindings}{command}{address}{name}, 'cmd_awaddr', 'aggregate address binding is preserved');
    is($report->{bindings}{command}{id}{width}, 4, 'aggregate ID width is pinned');
    is($report->{bindings}{command}{data}{width}, 32, 'aggregate data width is pinned');
    is($report->{bindings}{command}{strobe}{width}, 4, 'aggregate strobe width is pinned');
    is($report->{bindings}{aw_channel}{ready}, 'awready', 'AWREADY binding is preserved');
    is($report->{bindings}{w_channel}{last}, 'wlast', 'WLAST binding is preserved');
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
        },
        'fixed single-beat policy is complete and exact',
    );
    is($report->{coordinator}{payload_capture}, 'atomic_on_admission', 'coordinator atomically captures payload');
    is($report->{coordinator}{completion_history}, 'remember_aw_done_and_w_done_independently', 'coordinator remembers independent child completion');
    is($report->{coordinator}{completion_policy}, 'one_pulse_after_both_request_channels_accept', 'aggregate completion policy is request-only');
    ok(!$report->{coordinator}{response_completion}, 'aggregate completion does not claim B response completion');
    is_deeply(
        [map { [$_->{role}, $_->{instance_name}] } @{$report->{children}}],
        [
            ['aw-driver', 'aw_driver'],
            ['w-driver', 'w_driver'],
            ['coordinator', 'coordinator'],
        ],
        'three generated children are ordered and named',
    );
    is($report->{generated_schedules}{count}, 3, 'three child schedule reports are exposed');
    is_deeply(
        [map { $_->{report}{compile_issues} } @{$report->{generated_schedules}{items}}],
        [[], [], []],
        'all child schedules are lowering-clean',
    );
    my ($coordinator_item) = grep {
        $_->{object_name} eq 'axi_write_request_coordinator'
    } @{$result->{generated_ial1}{items}};
    my $coordinator_isf = $coordinator_item->{text};
    like($coordinator_isf, qr/\(input aw_busy\).*\(input aw_done\).*\(input w_busy\).*\(input w_done\)/s, 'coordinator consumes every child busy/done status');
    like($coordinator_isf, qr/\(rule launch_join \(& \(! active_q\) \(! aw_busy\) \(! w_busy\) write_cmd_valid \(! cmd_awaddr\[0\]\) \(! cmd_awaddr\[1\]\)\)/, 'coordinator launch requires aggregate and both children idle plus alignment');
    like($coordinator_isf, qr/\(rule finish_join \(& active_q \(\| aw_seen_q aw_done\) \(\| w_seen_q w_done\)\)/, 'coordinator joins current or remembered independent child completion');
    my ($coordinator_schedule) = grep {
        $_->{object_name} eq 'axi_write_request_coordinator'
    } @{$report->{generated_schedules}{items}};
    is($coordinator_schedule->{report}{state_count}, 0, 'coordinator remains rule-only');
    is_deeply($coordinator_schedule->{report}{transactions}, [], 'coordinator schedules no procedural transactions');
    is_deeply(
        [map { [$_->{name}, $_->{assignments}] } @{$coordinator_schedule->{report}{dt_blocks}}],
        [
            ['launch_join', 10],
            ['clear_child_starts', 2],
            ['latch_aw', 1],
            ['latch_w', 1],
            ['finish_join', 5],
            ['clear_done', 1],
        ],
        'six coordinator rule DTs retain exact assignment counts',
    );
    is_deeply(
        [map { [$_->{winner}, $_->{loser}, $_->{target}] } @{$coordinator_schedule->{report}{priority_resolutions}}],
        [
            ['launch_join', 'clear_child_starts', 'aw_cmd_valid'],
            ['finish_join', 'latch_aw', 'aw_seen_q'],
            ['launch_join', 'clear_child_starts', 'w_cmd_valid'],
            ['finish_join', 'latch_w', 'w_seen_q'],
            ['finish_join', 'clear_done', 'write_done'],
        ],
        'five coordinator priority resolutions are exact',
    );
    is_deeply(
        $report->{generated_artifacts}{ial1}{items},
        [
            { object_name => 'axi_aw_driver', role => 'aw-driver', instance_name => 'aw_driver', format => 'isf', name => 'axi_aw_driver.isf' },
            { object_name => 'axi_w_driver', role => 'w-driver', instance_name => 'w_driver', format => 'isf', name => 'axi_w_driver.isf' },
            { object_name => 'axi_write_request_coordinator', role => 'coordinator', instance_name => 'coordinator', format => 'isf', name => 'axi_write_request_coordinator.isf' },
        ],
        'ordered IAL1 review artifacts are exact',
    );
    is_deeply(
        $report->{generated_artifacts}{ial0}{files},
        [qw(
            axi_aw_driver.fsm
            axi_w_driver.fsm
            axi_write_request_composition.fsm
            axi_write_request_coordinator.fsm
        )],
        'four generated IAL0 artifacts are exact',
    );
    is($report->{generated_artifacts}{hdl_entry}{kind}, 'generated_composition_top', 'structural composition is the selected HDL entry');
    is($report->{generated_artifacts}{hdl_entry}{entry_artifact}, 'axi_write_request_composition.fsm', 'structural top artifact is selected');
    is(scalar(@{$report->{enforced_static_rules}}), 11, 'report carries eleven static rules');
    is_deeply(
        [map { $_->{id} } @{$report->{unsupported_residue}}],
        [qw(
            axi_write_request_composition_b_response_completion_deferred
            axi_write_request_composition_capacity_core_integration_deferred
            axi_write_request_composition_multi_beat_w_deferred
            axi_write_request_composition_dynamic_aw_metadata_deferred
            axi_write_request_composition_narrow_unaligned_transfers_deferred
            axi_write_request_composition_outstanding_queueing_deferred
            axi_write_request_composition_back_to_back_admission_deferred
            axi_write_request_composition_id_width_fixed
            axi_write_request_composition_extended_axi_attributes_deferred
            axi_write_request_composition_ar_r_channels_deferred
            axi_write_request_composition_transaction_interface_deferred
            axi_write_request_composition_profile_alias_deferred
            axi_write_request_composition_verification_output_deferred
            axi_write_request_composition_backend_variants_deferred
        )],
        'fourteen composition residue ids stay explicit and ordered',
    );

    my $top = $result->{generated_ial0}{files}{'axi_write_request_composition.fsm'};
    like($top, qr/\A\(\?top:axi_write_request_composition\b/, 'generated IAL0 entry is a structural top');
    like($top, qr/\(\?fsmc:aw_driver axi_aw_driver\)/, 'top instantiates unchanged AW driver');
    like($top, qr/\(\?fsmc:w_driver axi_w_driver\)/, 'top instantiates unchanged W driver');
    like($top, qr/\(\?fsmc:coordinator axi_write_request_coordinator\)/, 'top instantiates generated coordinator');
    like($top, qr/\(=8'd0 aw_driver\.cmd_awlen\)/, 'top fixes AWLEN to zero');
    like($top, qr/\(=3'd2 aw_driver\.cmd_awsize\)/, 'top fixes AWSIZE to two');
    like($top, qr/\(=2'b01 aw_driver\.cmd_awburst\)/, 'top fixes AWBURST to INCR');
    like($top, qr/\(aw_driver\.aw_done coordinator\.aw_done\)/, 'top links AW completion into coordinator');
    like($top, qr/\(w_driver\.w_done coordinator\.w_done\)/, 'top links W completion into coordinator');
};

subtest 'malformed and expanded composition contracts fail closed' => sub {
    my @cases = (
        ['wrong root', sub { replace_once(sample_text(), '(protocol-platform-intent', '(wrong-root') }, qr/must start with \(protocol-platform-intent/, 'bad-root.ppif'],
        ['wrong profile family', sub { replace_once(sample_text(), '(profile axi4)', '(profile ahb)') }, qr/profile 'ahb' does not match \(axi-write-request-composition/, 'bad-profile.ppif'],
        ['non-AXI4 profile', sub { replace_once(sample_text(), '(profile axi4)', '(profile axi3)') }, qr/profile must be axi4 in this slice/, 'axi3.ppif'],
        ['wrong role', sub { replace_once(sample_text(), '(role manager-to-subordinate)', '(role subordinate-to-manager)') }, qr/role must be manager-to-subordinate/, 'bad-role.ppif'],
        ['synchronous reset', sub { replace_once(sample_text(), '(rst_n active_low async)', '(rst_n active_low sync)') }, qr/reset must be asynchronous active-low/, 'sync-reset.ppif'],
        ['active-high reset', sub { replace_once(sample_text(), '(rst_n active_low async)', '(rst_n active_high async)') }, qr/reset must be asynchronous active-low/, 'active-high.ppif'],
        ['duplicate command block', sub { replace_once(sample_text(), "    (aw-channel\n", duplicate_command_clause() . "    (aw-channel\n") }, qr/duplicate \(command \.\.\.\) clause/, 'duplicate-command.ppif'],
        ['unknown object clause', sub { replace_once(sample_text(), "    (status\n", "    (unknown value)\n    (status\n") }, qr/unsupported clause '\(unknown \.\.\.\)'/, 'unknown.ppif'],
        ['missing status block', sub { my $s = sample_text(); $s =~ s/\n    \(status\n      \(busy write_busy\)\n      \(done write_done\)\)// or die; return $s }, qr/missing required \(status \.\.\.\) clause/, 'missing-status.ppif'],
        ['missing W last binding', sub { my $s = sample_text(); $s =~ s/\n      \(last wlast\)// or die; return $s }, qr/w-channel \.\.\.\) is missing required \(last \.\.\.\) clause/, 'missing-last.ppif'],
        ['dynamic AW metadata', sub { replace_once(sample_text(), '      (strobe cmd_wstrb width 4))', "      (strobe cmd_wstrb width 4)\n      (length cmd_awlen width 8))") }, qr/command \.\.\.\) has unsupported clause '\(length \.\.\.\)'/, 'dynamic-metadata.ppif'],
        ['nested child object', sub { replace_once(sample_text(), "    (status\n", "    (axi-aw-driver nested)\n    (status\n") }, qr/unsupported clause '\(axi-aw-driver \.\.\.\)'/, 'nested-child.ppif'],
        ['mixed standalone child', sub { append_root_clause(sample_text(), standalone_aw_clause()) }, qr/cannot mix \(axi-write-request-composition \.\.\.\) with other intent objects/, 'mixed-child.ppif'],
        ['multiple aggregate objects', sub { append_root_clause(sample_text(), second_composition_clause()) }, qr/supports exactly one \(axi-write-request-composition \.\.\.\) object/, 'duplicate-object.ppif'],
        ['duplicate public binding', sub { replace_once(sample_text(), '(done write_done)', '(done write_busy)') }, qr/duplicates signal 'write_busy'/, 'duplicate-signal.ppif'],
        ['generated artifact collision', sub { replace_once(sample_text(), '(axi-write-request-composition axi_write_request_composition', '(axi-write-request-composition axi_aw_driver') }, qr/duplicate \.fsm artifact 'axi_aw_driver\.fsm'/, 'artifact-collision.ppif'],
        ['profile alias rejection', sub { sample_text() }, qr/\(axi-write-request-composition \.\.\.\) remains unsupported for the first profile-alias implementation/, 'composition.axi'],
    );

    my @width_cases = (
        ['command.address', '(address cmd_awaddr width 32)', '(address cmd_awaddr width 16)', qr/command\.address\.width must be 32/],
        ['command.id', '(id cmd_awid width 4)', '(id cmd_awid width 3)', qr/command\.id\.width must be 4/],
        ['command.data', '(data cmd_wdata width 32)', '(data cmd_wdata width 16)', qr/command\.data\.width must be 32/],
        ['command.strobe', '(strobe cmd_wstrb width 4)', '(strobe cmd_wstrb width 2)', qr/command\.strobe\.width must be 4/],
        ['aw_channel.address', '(address awaddr width 32)', '(address awaddr width 16)', qr/aw_channel\.address\.width must be 32/],
        ['aw_channel.id', '(id awid width 4)', '(id awid width 3)', qr/aw_channel\.id\.width must be 4/],
        ['aw_channel.length', '(length awlen width 8)', '(length awlen width 7)', qr/aw_channel\.length\.width must be 8/],
        ['aw_channel.size', '(size awsize width 3)', '(size awsize width 2)', qr/aw_channel\.size\.width must be 3/],
        ['aw_channel.burst', '(burst awburst width 2)', '(burst awburst width 3)', qr/aw_channel\.burst\.width must be 2/],
        ['w_channel.data', '(data wdata width 32)', '(data wdata width 16)', qr/w_channel\.data\.width must be 32/],
        ['w_channel.strobe', '(strobe wstrb width 4)', '(strobe wstrb width 2)', qr/w_channel\.strobe\.width must be 4/],
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

subtest 'CLI support accounting and external HDL use the public composition path' => sub {
    my $check = run_json_command('./bin/fsmgen', '--quiet', '--strict', '--check', '--json', sample_path());
    ok($check->{success}, 'strict check JSON succeeds');
    is($check->{result}{module_name}, 'axi_write_request_composition', 'check JSON reports the structural top module');
    is($check->{result}{composition_child_count}, 3, 'check JSON reports three structural children');
    is($check->{support_accounting}{entry_id}, 'intent.ppif_axi_write_request_composition', 'check JSON matches support accounting');

    my $schedule = run_json_command('./bin/fsmgen', '--quiet', '--emit-schedule-json', sample_path());
    is($schedule->{schema}, 'fsmgen.ial2.protocol_intent.axi_write_request_composition.v1', 'schedule JSON exposes aggregate schema');
    is($schedule->{generated_schedules}{count}, 3, 'schedule JSON exposes all three child schedules');

    my $semantic = run_json_command('./bin/fsmgen', '--quiet', '--strict', '--emit-semantic-json', sample_path());
    ok($semantic->{success}, 'strict semantic JSON succeeds');
    is($semantic->{generation_result_snapshot}{summary}{source_root_kind}, 'top', 'semantic JSON identifies a structural top root');
    is($semantic->{semantic}{composition}{lane}, 'C4', 'semantic JSON identifies the C4 lane');
    is($semantic->{generation_result_snapshot}{summary}{composition_child_count}, 3, 'semantic JSON reports three children');
    is($semantic->{support_accounting}{entry_id}, 'intent.ppif_axi_write_request_composition', 'semantic JSON matches support accounting');

    my $tempdir = tempdir(CLEANUP => 1);
    my $outdir = File::Spec->catdir($tempdir, 'out');
    my $hdl = File::Spec->catfile($tempdir, 'axi_write_request_composition.sv');
    my ($emit_ok, undef, undef, undef, $emit_stderr) = run(
        command => ['./bin/fsmgen', '--quiet', '--strict', '--outdir', $outdir, '--output', $hdl, sample_path()],
    );
    ok($emit_ok, 'public source emits HDL and review artifacts through --outdir');
    is(join('', @{$emit_stderr || []}), '', 'outdir generation keeps stderr clean');
    for my $artifact (qw(
        axi_aw_driver.isf
        axi_w_driver.isf
        axi_write_request_coordinator.isf
        axi_aw_driver.fsm
        axi_w_driver.fsm
        axi_write_request_coordinator.fsm
        axi_write_request_composition.fsm
    )) {
        ok(-f File::Spec->catfile($outdir, $artifact), "outdir contains $artifact");
    }
    like(slurp($hdl), qr/\bmodule\s+axi_write_request_composition\b/, 'generated HDL contains the structural top');

    my ($verify_ok, undef, undef, $verify_stdout, $verify_stderr) = run(
        command => ['./bin/fsmgen', '--verify-hdl', '--output', File::Spec->catfile($tempdir, 'verify.sv'), sample_path()],
    );
    ok($verify_ok, 'composition passes external HDL verification')
        or diag(join('', @{$verify_stdout || []}), join('', @{$verify_stderr || []}));
    my $verify_text = join('', @{$verify_stdout || []});
    like($verify_text, qr/verilator_lint: PASS/, 'generated structural HDL passes Verilator lint');
    like($verify_text, qr/yosys_synthesis: PASS/, 'generated structural HDL passes Yosys synthesis');
};

subtest 'generated structural top preserves atomic payload and independent AW W completion' => sub {
    my $tempdir = tempdir(CLEANUP => 1);
    my $hdl = File::Spec->catfile($tempdir, 'axi_write_request_composition.sv');
    my $testbench = File::Spec->catfile($tempdir, 'axi_write_request_composition_tb.sv');
    my $obj_dir = File::Spec->catdir($tempdir, 'obj');

    my ($generate_ok, undef, undef, undef, $generate_stderr) = run(
        command => ['./bin/fsmgen', '--quiet', '--strict', '--output', $hdl, sample_path()],
    );
    ok($generate_ok, 'public composition source emits structural HDL for simulation');
    is(join('', @{$generate_stderr || []}), '', 'behavior HDL generation keeps stderr clean');
    like(
        slurp($hdl),
        qr/assert property \(@\(posedge clk\) disable iff \(!rst_n\) \(\(!\(active_q\) & write_cmd_valid\) \|-> \(!\(cmd_awaddr\[0\]\) & !\(cmd_awaddr\[1\]\)\)\)\)/,
        'emitted coordinator assertion is the exact aligned idle-admission implication',
    );

    write_file($testbench, <<'SV');
module axi_write_request_composition_tb;
  logic clk = 0;
  logic rst_n = 0;
  logic write_cmd_valid = 0;
  logic [31:0] cmd_awaddr = 0;
  logic [3:0] cmd_awid = 0;
  logic [31:0] cmd_wdata = 0;
  logic [3:0] cmd_wstrb = 0;
  logic awready = 0;
  logic wready = 0;
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
  wire write_busy;
  wire write_done;
  integer aw_handshakes = 0;
  integer w_handshakes = 0;
  integer done_pulses = 0;
  integer cycles = 0;

  axi_write_request_composition dut (.*);
  always #5 clk = ~clk;

  always @(posedge clk) begin
    if (rst_n) begin
      if (awvalid && {awlen, awsize, awburst} !== {8'd0, 3'd2, 2'd1})
        $fatal(1, "fixed AW metadata mismatch");
      if (wvalid && !wlast)
        $fatal(1, "WLAST was not high on the single beat");
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
      if (write_done)
        done_pulses <= done_pulses + 1;
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

  task automatic wait_for_counts(input integer aw_count, input integer w_count, input integer done_count);
    begin
      cycles = 0;
      while ((aw_handshakes < aw_count || w_handshakes < w_count || done_pulses < done_count) && cycles < 120) begin
        @(negedge clk);
        cycles = cycles + 1;
      end
      if (aw_handshakes != aw_count || w_handshakes != w_count || done_pulses != done_count)
        $fatal(1, "count wait failed: AW=%0d W=%0d done=%0d", aw_handshakes, w_handshakes, done_pulses);
    end
  endtask

  initial begin
    repeat (2) @(negedge clk);
    rst_n = 1;
    repeat (2) @(negedge clk);

    // Assertions are intentionally disabled for this run: misalignment is both
    // asserted in emitted HDL and guarded from launching any physical request.
    awready = 1;
    wready = 1;
    pulse_command(32'h00001003, 4'hf, 32'hdeadbeef, 4'hf);
    repeat (12) @(negedge clk);
    if (awvalid || wvalid || write_busy || write_done || aw_handshakes || w_handshakes || done_pulses)
      $fatal(1, "misaligned command launched request activity");

    // Simultaneous-ready, zero-strobe command. Mutating the aggregate inputs
    // immediately after admission must not change either child payload.
    pulse_command(32'h00001000, 4'h1, 32'h11112222, 4'h0);
    cmd_awaddr = 32'hffff0000;
    cmd_awid = 4'he;
    cmd_wdata = 32'haaaaaaaa;
    cmd_wstrb = 4'hf;
    wait_for_counts(1, 1, 1);
    repeat (6) @(negedge clk);
    if (aw_handshakes != 1 || w_handshakes != 1 || done_pulses != 1)
      $fatal(1, "held READY caused duplicate command 1 transfer");

    // AW first; W remains stalled and stable for four cycles. A command pulse
    // while busy must be ignored rather than queued.
    awready = 1;
    wready = 0;
    pulse_command(32'h00002000, 4'h2, 32'h33334444, 4'ha);
    cycles = 0;
    while ((!wvalid || aw_handshakes < 2) && cycles < 80) begin
      @(negedge clk);
      cycles = cycles + 1;
    end
    if (!wvalid || aw_handshakes != 2)
      $fatal(1, "command 2 did not reach AW-first stalled-W state");
    repeat (4) begin
      @(negedge clk);
      if (!wvalid || {wdata, wstrb, wlast} !== {32'h33334444, 4'ha, 1'b1})
        $fatal(1, "stalled W payload changed");
    end
    pulse_command(32'h0000f000, 4'hf, 32'hffffffff, 4'hf);
    if (!write_busy)
      $fatal(1, "aggregate busy dropped during ignored command");
    wready = 1;
    wait_for_counts(2, 2, 2);

    // W first; AW remains stalled and stable for four cycles.
    awready = 0;
    wready = 1;
    pulse_command(32'h00003000, 4'h3, 32'h55556666, 4'h5);
    cycles = 0;
    while ((!awvalid || w_handshakes < 3) && cycles < 80) begin
      @(negedge clk);
      cycles = cycles + 1;
    end
    if (!awvalid || w_handshakes != 3)
      $fatal(1, "command 3 did not reach W-first stalled-AW state");
    repeat (4) begin
      @(negedge clk);
      if (!awvalid || {awaddr, awid, awlen, awsize, awburst} !== {32'h00003000, 4'h3, 8'd0, 3'd2, 2'd1})
        $fatal(1, "stalled AW payload changed");
    end
    awready = 1;
    wait_for_counts(3, 3, 3);
    repeat (8) @(negedge clk);

    if (aw_handshakes != 3 || w_handshakes != 3 || done_pulses != 3)
      $fatal(1, "final transfer cardinality mismatch");
    if (awvalid || wvalid || write_busy || write_done)
      $fatal(1, "composition did not return fully idle");

    $display("PASS aw_handshakes=%0d w_handshakes=%0d done_pulses=%0d", aw_handshakes, w_handshakes, done_pulses);
    $finish;
  end

  initial begin
    #20000;
    $fatal(1, "AXI write-request composition simulation timed out");
  end
endmodule
SV

    my ($compile_ok, undef, undef, $compile_stdout, $compile_stderr) = run(
        command => [
            'verilator', '--binary', '--timing', '--no-assert', '-Wno-fatal', '-j', '1',
            '--top-module', 'axi_write_request_composition_tb',
            '--Mdir', $obj_dir, $hdl, $testbench,
        ],
    );
    ok($compile_ok, 'Verilator builds the generated structural-top harness with assertions disabled')
        or diag(join('', @{$compile_stdout || []}), join('', @{$compile_stderr || []}));
    return unless $compile_ok;

    my $binary = File::Spec->catfile($obj_dir, 'Vaxi_write_request_composition_tb');
    ok(-x $binary, 'structural-top simulation binary exists');
    my ($run_ok, undef, undef, $run_stdout, $run_stderr) = run(command => [$binary]);
    ok($run_ok, 'generated structural-top behavior passes')
        or diag(join('', @{$run_stdout || []}), join('', @{$run_stderr || []}));
    like(
        join('', @{$run_stdout || []}),
        qr/PASS aw_handshakes=3 w_handshakes=3 done_pulses=3/,
        'misalignment, atomic capture, simultaneous, AW-first, W-first, busy-ignore, stability, and cardinality checks all pass',
    );
};

done_testing();

sub sample_path {
    return File::Spec->catfile($FindBin::Bin, '..', 'ppif', 'axi_write_request_composition.ppif');
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
    my $start = index($source, '  (axi-write-request-composition');
    die "failed to locate aggregate object\n" if $start < 0;
    my $object = substr($source, $start);
    $object =~ s/\)\s*\z// or die "failed to remove root close\n";
    $object =~ s/axi_write_request_composition/axi_write_request_composition_2/g;
    $object =~ s/\b(clk|rst_n|write_cmd_valid|cmd_awaddr|cmd_awid|cmd_wdata|cmd_wstrb|awready|awvalid|awaddr|awid|awlen|awsize|awburst|wready|wvalid|wdata|wstrb|wlast|write_busy|write_done)\b/${1}_2/g;
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
