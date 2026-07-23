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

subtest 'adapter parses the bounded AXI B write-response acceptor PPIF shape' => sub {
    ok(-f sample_b_acceptor_ppif_path(), 'tracked runnable AXI B acceptor PPIF sample exists');

    my $result = FSM::Adapter::IAL2::PPIF->new()->parse_file(sample_b_acceptor_ppif_path());

    is($result->{layer}, 'IAL2', 'AXI B acceptor adapter result stays IAL2');
    is($result->{kind}, 'protocol_intent.axi_b_response_acceptor', 'adapter returns the AXI B acceptor kind');
    is($result->{mode}, 'acceptor', 'AXI B acceptor mode is explicit');
    is($result->{report}{schema}, 'fsmgen.ial2.protocol_intent.axi_b_response_acceptor.v1', 'AXI B acceptor report schema is selected');
    is($result->{report}{source_object}{id}, 'axi-b-response-acceptor', 'AXI B acceptor source object id is preserved');
    is($result->{report}{source_object}{intent_name}, 'axi_b_response_acceptor', 'AXI B acceptor source intent name is preserved');
    is_deeply(
        [map { [$_->{section}, $_->{page}] } @{$result->{report}{source_object}{anchors}}],
        [
            ['A2.3', '29'],
            ['A2.3.1', '30'],
            ['A2.3.2.1', '31'],
            ['A3.3', '61'],
            ['A3.3.1', '61'],
            ['B1.1.3', '278'],
        ],
        'AXI B acceptor carries the six selected transport/dependency/response/signal anchors',
    );
    is($result->{report}{target_protocol}{profile}, 'axi4', 'AXI B acceptor report carries the axi4 profile');
    is($result->{report}{target_protocol}{object}, 'axi-b-response-acceptor', 'AXI B acceptor report carries the selected object');
    is($result->{report}{target_protocol}{role}, 'subordinate-to-manager', 'AXI B acceptor report carries the receiver direction');
    is($result->{report}{acceptor}{actor_name}, 'axi_b_response_acceptor', 'report names the generated acceptor actor');

    my $isf = $result->{generated_ial1}{text};
    is($result->{generated_ial1}{name}, 'axi_b_response_acceptor.isf', 'AXI B acceptor exposes generated IAL1 artifact');
    like($isf, qr/\A\(actor axi_b_response_acceptor\b/, 'generated B acceptor IAL1 is .isf text');
    like($isf, qr/\(input b_accept_cmd_valid\)/, 'generated B acceptor IAL1 declares the arm input');
    like($isf, qr/\(input bvalid\)/, 'generated B acceptor IAL1 declares BVALID input');
    like($isf, qr/\(input bid \(width 4\)\)/, 'generated B acceptor IAL1 declares four-bit BID input');
    like($isf, qr/\(input bresp \(width 2\)\)/, 'generated B acceptor IAL1 declares two-bit BRESP input');
    like($isf, qr/\(output bready\)/, 'generated B acceptor IAL1 drives BREADY');
    like($isf, qr/\(output response_bid \(width 4\)\)/, 'generated B acceptor IAL1 exposes captured BID');
    like($isf, qr/\(output response_bresp \(width 2\)\)/, 'generated B acceptor IAL1 exposes captured BRESP');
    like($isf, qr/\(priority accept_b over arm_b\)/, 'generated B acceptor gives acceptance priority over arm');
    like($isf, qr/\(rule arm_b arm_b_start\b/, 'generated B acceptor has the arm handoff rule');
    like($isf, qr/\(rule accept_b \(& active_q bvalid bready\)/, 'generated B acceptor captures on the active response handshake');
    like($isf, qr/\(set response_bid bid\)/, 'generated B acceptor captures BID');
    like($isf, qr/\(set response_bresp bresp\)/, 'generated B acceptor captures BRESP');
    like($isf, qr/\(set bready 1\)/, 'generated B acceptor raises BREADY after arm');
    like($isf, qr/\(set bready 0\)/, 'generated B acceptor clears BREADY on acceptance');
    like($isf, qr/\(while active_q\s+\(wait 1\)\)/, 'generated B acceptor waits on latched receive activity');
    like($isf, qr/\(complete b_done\)/, 'generated B acceptor emits the later done pulse');

    my $schedule = $result->{generated_ial1_schedule_report};
    is($schedule->{state_count}, 6, 'B acceptor IAL1 schedule has six states');
    is_deeply($schedule->{compile_issues}, [], 'B acceptor IAL1 schedule has no compile issues');
    is_deeply(
        [
            sort map {
                join(':', $_->{winner}, $_->{loser}, $_->{target})
            } @{$schedule->{priority_resolutions} || []}
        ],
        [
            'accept_b:arm_b:active_q',
            'accept_b:arm_b:b_busy',
            'accept_b:arm_b:bready',
        ],
        'B acceptor schedule resolves the three shared rule targets in favor of acceptance',
    );

    is_deeply(
        sorted([keys %{$result->{generated_ial0}{files}}]),
        ['axi_b_response_acceptor.fsm'],
        'AXI B acceptor adapter exposes generated IAL0 .fsm file map',
    );
    my $fsm = $result->{generated_ial0}{files}{'axi_b_response_acceptor.fsm'};
    like($fsm, qr/\(\?fsm:axi_b_response_acceptor\b/, 'generated B acceptor IAL0 names the acceptor FSM');
    like($fsm, qr/\(-arm_b <arm_b_start/, 'generated B acceptor IAL0 contains the arm rule DT');
    like($fsm, qr/\(-accept_b <\(& active_q bvalid bready\)/, 'generated B acceptor IAL0 contains the acceptance/capture DT');
    like($fsm, qr/\(<- \(response_bid> bid\)\)/, 'generated B acceptor IAL0 carries captured BID assignment');
    like($fsm, qr/\(<- \(response_bresp> bresp\)\)/, 'generated B acceptor IAL0 carries captured BRESP assignment');

    is($result->{report}{bindings}{command}{arm}, 'b_accept_cmd_valid', 'report captures arm binding');
    is($result->{report}{bindings}{channel}{id}{width}, 4, 'report pins bus BID width');
    is($result->{report}{bindings}{channel}{captured_id}{name}, 'response_bid', 'report captures response BID output binding');
    is($result->{report}{bindings}{channel}{captured_response}{width}, 2, 'report pins captured BRESP width');
    my $bounded = $result->{report}{bounded_response};
    is($bounded->{arming_policy}, 'explicit_one_response', 'report selects explicit one-response arming');
    is($bounded->{ready_policy}, 'assert_after_arm_without_waiting_for_valid', 'report selects eager post-arm BREADY');
    is($bounded->{accept_condition}, 'bvalid && bready', 'report exposes physical response accept condition');
    is($bounded->{id_width}, 4, 'report pins response ID width');
    is($bounded->{response_width}, 2, 'report pins response status width');
    is($bounded->{capture_policy}, 'on_accept_and_hold_until_next_accept', 'report fixes captured response stability');
    is($bounded->{done_policy}, 'one_pulse_per_accepted_arm_after_transaction_retirement', 'report distinguishes the later done pulse');
    ok(!$bounded->{back_to_back_supported}, 'report keeps back-to-back acceptance unsupported');
    is($result->{report}{generated_artifacts}{hdl_entry}{kind}, 'generated_acceptor_fsm', 'report selects the acceptor HDL entry kind');
    is($result->{report}{generated_artifacts}{hdl_entry}{entry_artifact}, 'axi_b_response_acceptor.fsm', 'report selects generated B acceptor .fsm as HDL entry');
    is($result->{report}{layering}{direct_ial2_to_ial0}, 0, 'AXI B acceptor lowering goes through generated IAL1 before IAL0');

    is_deeply(
        [map { $_->{id} } @{$result->{report}{unsupported_residue}}],
        [qw(
            axi_b_response_acceptor_aw_w_coordination_deferred
            axi_b_response_acceptor_capacity_core_integration_deferred
            axi_b_response_acceptor_outstanding_back_to_back_deferred
            axi_b_response_acceptor_id_width_fixed
            axi_b_response_acceptor_response_width_variants_deferred
            axi_b_response_acceptor_extended_response_signals_deferred
            axi_b_response_acceptor_status_interpretation_deferred
            axi_b_response_acceptor_subordinate_stall_assertions_deferred
            axi_b_response_acceptor_burst_coupling_deferred
            axi_b_response_acceptor_ar_r_channels_deferred
            axi_b_response_acceptor_transaction_interface_deferred
            axi_b_response_acceptor_profile_alias_deferred
            axi_b_response_acceptor_verification_output_deferred
            axi_b_response_acceptor_backend_variants_deferred
        )],
        'B acceptor report keeps the selected ordered residue explicit',
    );
};

subtest 'malformed AXI B response acceptor PPIF sources fail closed' => sub {
    my @cases = (
        [
            'non-AXI profile',
            sub {
                my $source = sample_b_acceptor_ppif();
                $source =~ s/\(profile axi4\)/(profile ahb)/;
                return $source;
            },
            qr/profile 'ahb' does not match \(axi-b-response-acceptor \.\.\.\)/,
            'bad-profile.ppif',
        ],
        [
            'non-AXI4 family member',
            sub {
                my $source = sample_b_acceptor_ppif();
                $source =~ s/\(profile axi4\)/(profile axi3)/;
                return $source;
            },
            qr/profile must be axi4 in this slice/,
            'axi3.ppif',
        ],
        [
            'wrong role',
            sub {
                my $source = sample_b_acceptor_ppif();
                $source =~ s/\(role subordinate-to-manager\)/(role manager-to-subordinate)/;
                return $source;
            },
            qr/role must be subordinate-to-manager/,
            'bad-role.ppif',
        ],
        [
            'missing channel block',
            sub {
                my $source = sample_b_acceptor_ppif();
                $source =~ s/\n    \(channel\n.*?\(done b_done\)\)\)/)/s;
                return $source;
            },
            qr/missing required \(channel \.\.\.\) clause/,
            'missing-channel.ppif',
        ],
        [
            'unsupported bus ID width',
            sub {
                my $source = sample_b_acceptor_ppif();
                $source =~ s/\(id bid width 4\)/(id bid width 3)/;
                return $source;
            },
            qr/channel\.id\.width must be 4 in this slice/,
            'bad-id-width.ppif',
        ],
        [
            'unsupported captured ID width',
            sub {
                my $source = sample_b_acceptor_ppif();
                $source =~ s/\(captured-id response_bid width 4\)/(captured-id response_bid width 3)/;
                return $source;
            },
            qr/channel\.captured_id\.width must be 4 in this slice/,
            'bad-captured-id-width.ppif',
        ],
        [
            'unsupported bus response width',
            sub {
                my $source = sample_b_acceptor_ppif();
                $source =~ s/\(response bresp width 2\)/(response bresp width 3)/;
                return $source;
            },
            qr/channel\.response\.width must be 2 in this slice/,
            'bad-response-width.ppif',
        ],
        [
            'unsupported captured response width',
            sub {
                my $source = sample_b_acceptor_ppif();
                $source =~ s/\(captured-response response_bresp width 2\)/(captured-response response_bresp width 3)/;
                return $source;
            },
            qr/channel\.captured_response\.width must be 2 in this slice/,
            'bad-captured-response-width.ppif',
        ],
        [
            'duplicate command clause binding',
            sub {
                my $source = sample_b_acceptor_ppif();
                $source =~ s/\(arm b_accept_cmd_valid\)/(arm b_accept_cmd_valid)\n      (arm b_accept_cmd_valid_2)/;
                return $source;
            },
            qr/has duplicate \(arm \.\.\.\) clause/,
            'duplicate-arm.ppif',
        ],
        [
            'duplicate signal binding',
            sub {
                my $source = sample_b_acceptor_ppif();
                $source =~ s/\(done b_done\)/(done bready)/;
                return $source;
            },
            qr/duplicates signal 'bready'/,
            'duplicate-signal.ppif',
        ],
        [
            'duplicate B acceptor object',
            sub {
                return insert_before_root_close(sample_b_acceptor_ppif(), second_b_acceptor_clause());
            },
            qr/supports exactly one \(axi-b-response-acceptor \.\.\.\) object/,
            'duplicate-object.ppif',
        ],
        [
            'mixed B acceptor and W driver objects',
            sub {
                return insert_before_root_close(sample_b_acceptor_ppif(), w_driver_clause());
            },
            qr/cannot mix \(axi-b-response-acceptor \.\.\.\) with other intent objects/,
            'mixed-object.ppif',
        ],
        [
            'B acceptor profile alias',
            sub { return sample_b_acceptor_ppif() },
            qr/\(axi-b-response-acceptor \.\.\.\) remains unsupported for the first profile-alias implementation/,
            'b-acceptor.axi',
        ],
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

subtest 'CLI checks, semantic export, schedule report, outdir, and verify-hdl use the public B acceptor path' => sub {
    my $check = run_json_command('./bin/fsmgen', '--quiet', '--strict', '--check', '--json', sample_b_acceptor_ppif_path());
    ok($check->{success}, 'strict check JSON succeeds for AXI B acceptor PPIF');
    is($check->{result}{module_name}, 'axi_b_response_acceptor', 'check JSON reports generated module name');
    is($check->{support_accounting}{entry_id}, 'intent.ppif_axi_b_response_acceptor', 'check JSON matches AXI B acceptor support accounting');
    is($check->{support_accounting}{source_kind}, 'ppif', 'check JSON reports PPIF source kind');

    my $semantic = run_json_command('./bin/fsmgen', '--quiet', '--strict', '--emit-semantic-json', sample_b_acceptor_ppif_path());
    ok($semantic->{success}, 'strict semantic JSON succeeds for AXI B acceptor PPIF');
    is($semantic->{generation_result_snapshot}{summary}{module_name}, 'axi_b_response_acceptor', 'semantic JSON reports generated module name');
    is($semantic->{generation_result_snapshot}{summary}{source_root_kind}, 'fsm', 'semantic JSON reports generated FSM source root');
    is($semantic->{support_accounting}{entry_id}, 'intent.ppif_axi_b_response_acceptor', 'semantic JSON matches AXI B acceptor support accounting');

    my $schedule = run_json_command('./bin/fsmgen', '--quiet', '--emit-schedule-json', sample_b_acceptor_ppif_path());
    is($schedule->{schema}, 'fsmgen.ial2.protocol_intent.axi_b_response_acceptor.v1', 'schedule/report JSON exposes the AXI B acceptor schema');
    is($schedule->{generated_artifacts}{ial1}{name}, 'axi_b_response_acceptor.isf', 'schedule/report JSON exposes generated IAL1 artifact');
    is_deeply($schedule->{generated_artifacts}{ial0}{files}, ['axi_b_response_acceptor.fsm'], 'schedule/report JSON exposes generated IAL0 artifact');

    my $tempdir = tempdir(CLEANUP => 1);
    my $outdir = File::Spec->catdir($tempdir, 'out');
    my $hdl = File::Spec->catfile($tempdir, 'axi_b_response_acceptor.sv');
    my ($success, undef, undef, undef, $stderr) = run(
        command => ['./bin/fsmgen', '--quiet', '--outdir', $outdir, '--output', $hdl, sample_b_acceptor_ppif_path()],
    );
    ok($success, 'AXI B acceptor PPIF emits HDL and review artifacts through --outdir');
    is(join('', @{$stderr || []}), '', 'outdir generation keeps stderr clean');
    ok(-f File::Spec->catfile($outdir, 'axi_b_response_acceptor.isf'), 'outdir contains generated B acceptor IAL1 artifact');
    ok(-f File::Spec->catfile($outdir, 'axi_b_response_acceptor.fsm'), 'outdir contains generated B acceptor IAL0 artifact');
    ok(-f $hdl, 'outdir command emits selected HDL output');
    like(slurp($hdl), qr/\bmodule\s+axi_b_response_acceptor\b/, 'generated HDL contains the AXI B acceptor module');

    my ($verify_ok, undef, undef, $verify_stdout, undef) = run(
        command => ['./bin/fsmgen', '--verify-hdl', sample_b_acceptor_ppif_path()],
    );
    ok($verify_ok, 'AXI B acceptor PPIF passes --verify-hdl external validation');
    like(join('', @{$verify_stdout || []}), qr/verilator_lint: PASS/, 'AXI B acceptor HDL passes verilator lint');
    like(join('', @{$verify_stdout || []}), qr/yosys_synthesis: PASS/, 'AXI B acceptor HDL passes Yosys synthesis');
};

subtest 'generated HDL accepts and captures exactly one B response per arm' => sub {
    my $tempdir = tempdir(CLEANUP => 1);
    my $hdl = File::Spec->catfile($tempdir, 'axi_b_response_acceptor.sv');
    my $testbench = File::Spec->catfile($tempdir, 'axi_b_response_acceptor_cardinality_tb.sv');
    my $obj_dir = File::Spec->catdir($tempdir, 'obj_cardinality');

    my ($generate_ok, undef, undef, undef, $generate_stderr) = run(
        command => [
            './bin/fsmgen', '--quiet', '--strict', '--output', $hdl,
            sample_b_acceptor_ppif_path(),
        ],
    );
    ok($generate_ok, 'public AXI B acceptor source emits HDL for cardinality simulation');
    is(join('', @{$generate_stderr || []}), '', 'cardinality HDL generation keeps stderr clean');

    write_file($testbench, <<'SV');
module axi_b_response_acceptor_cardinality_tb;
  logic clk = 0;
  logic rst_n = 0;
  logic b_accept_cmd_valid = 0;
  logic bvalid = 0;
  logic [3:0] bid = 0;
  logic [1:0] bresp = 0;
  wire bready;
  wire [3:0] response_bid;
  wire [1:0] response_bresp;
  wire b_busy;
  wire b_done;
  integer handshakes = 0;
  integer done_pulses = 0;
  integer wait_cycles = 0;

  axi_b_response_acceptor dut (.*);
  always #5 clk = ~clk;

  always @(posedge clk) begin
    if (rst_n && bvalid && bready)
      handshakes <= handshakes + 1;
    if (rst_n && b_done)
      done_pulses <= done_pulses + 1;
  end

  task automatic pulse_arm;
    begin
      @(negedge clk);
      b_accept_cmd_valid = 1;
      @(negedge clk);
      b_accept_cmd_valid = 0;
    end
  endtask

  task automatic wait_for_ready;
    begin
      wait_cycles = 0;
      while (!bready && wait_cycles < 10) begin
        @(negedge clk);
        wait_cycles = wait_cycles + 1;
      end
      if (!bready)
        $fatal(1, "armed receiver never raised BREADY");
    end
  endtask

  initial begin
    repeat (2) @(negedge clk);
    rst_n = 1;
    repeat (2) @(negedge clk);

    // BVALID is unowned before arm and must not transfer.
    bid = 4'h3;
    bresp = 2'b10;
    bvalid = 1;
    repeat (3) @(negedge clk);
    if (handshakes != 0 || bready || b_busy)
      $fatal(1, "unarmed response was accepted or receiver was active");

    // Already-high BVALID is accepted once; held-high BVALID cannot repeat.
    pulse_arm();
    wait_for_ready();
    repeat (12) @(negedge clk);
    if (handshakes != 1 || done_pulses != 1)
      $fatal(1, "held-valid arm expected one response/done, got %0d/%0d", handshakes, done_pulses);
    if ({response_bid, response_bresp} !== {4'h3, 2'b10})
      $fatal(1, "first response capture mismatch");
    if (bready || b_busy)
      $fatal(1, "first response did not return ready/busy low");

    bid = 4'he;
    bresp = 2'b01;
    repeat (4) @(negedge clk);
    if (handshakes != 1 || {response_bid, response_bresp} !== {4'h3, 2'b10})
      $fatal(1, "unarmed held-valid input changed cardinality or captured payload");
    bvalid = 0;

    // Arm first, then hold READY/busy for four cycles before BVALID arrives.
    pulse_arm();
    wait_for_ready();
    repeat (4) begin
      @(negedge clk);
      if (!bready || !b_busy)
        $fatal(1, "armed receiver dropped ready/busy before BVALID");
    end
    bid = 4'h9;
    bresp = 2'b11;
    bvalid = 1;
    @(negedge clk);
    bvalid = 0;
    repeat (12) @(negedge clk);

    if (handshakes != 2 || done_pulses != 2)
      $fatal(1, "two arms expected two responses/done, got %0d/%0d", handshakes, done_pulses);
    if ({response_bid, response_bresp} !== {4'h9, 2'b11})
      $fatal(1, "second response capture mismatch");
    if (bready || b_busy)
      $fatal(1, "second response did not return ready/busy low");

    $display("PASS handshakes=%0d done_pulses=%0d bid=%0h bresp=%0h", handshakes, done_pulses, response_bid, response_bresp);
    $finish;
  end

  initial begin
    #6000;
    $fatal(1, "B acceptor cardinality simulation timed out");
  end
endmodule
SV

    my ($compile_ok, undef, undef, $compile_stdout, $compile_stderr) = run(
        command => [
            'verilator', '--binary', '--timing', '--assert', '-Wno-fatal',
            '-j', '1', '--top-module', 'axi_b_response_acceptor_cardinality_tb',
            '--Mdir', $obj_dir, $hdl, $testbench,
        ],
    );
    ok($compile_ok, 'Verilator builds the generated B acceptor cardinality harness')
        or diag(join('', @{$compile_stdout || []}), join('', @{$compile_stderr || []}));

    return unless $compile_ok;

    my $binary = File::Spec->catfile($obj_dir, 'Vaxi_b_response_acceptor_cardinality_tb');
    ok(-x $binary, 'Verilator B acceptor cardinality harness binary exists');
    my ($run_ok, undef, undef, $run_stdout, $run_stderr) = run(command => [$binary]);
    ok($run_ok, 'generated B acceptor cardinality/capture simulation passes')
        or diag(join('', @{$run_stdout || []}), join('', @{$run_stderr || []}));
    like(
        join('', @{$run_stdout || []}),
        qr/PASS handshakes=2 done_pulses=2 bid=9 bresp=3/,
        'already-high held response and four-cycle delayed response each accept, capture, and complete exactly once',
    );
};

done_testing();

sub sample_b_acceptor_ppif_path {
    return File::Spec->catfile($FindBin::Bin, '..', 'ppif', 'axi_b_response_acceptor.ppif');
}

sub sample_b_acceptor_ppif {
    return slurp(sample_b_acceptor_ppif_path());
}

sub insert_before_root_close {
    my ($source, $clause) = @_;
    $source =~ s/\)\s*\z/$clause\n)\n/
        or die "failed to append PPIF object clause\n";
    return $source;
}

sub second_b_acceptor_clause {
    return <<'PPIF';
  (axi-b-response-acceptor axi_b_response_acceptor_2
    (role subordinate-to-manager)
    (clock clk2)
    (reset (rst2_n active_low async))
    (command
      (arm b2_accept_cmd_valid))
    (channel
      (valid bvalid2)
      (ready bready2)
      (id bid2 width 4)
      (response bresp2 width 2)
      (captured-id response_bid2 width 4)
      (captured-response response_bresp2 width 2)
      (busy b_busy2)
      (done b_done2)))
PPIF
}

sub w_driver_clause {
    return <<'PPIF';
  (axi-w-driver axi_w_driver_2
    (role manager-to-subordinate)
    (clock wclk)
    (reset (wreset_n active_low async))
    (command
      (start w2_cmd_valid)
      (data cmd_wdata2 width 32)
      (strobe cmd_wstrb2 width 4)
      (ready wready2))
    (channel
      (valid wvalid2)
      (data wdata2 width 32)
      (strobe wstrb2 width 4)
      (last wlast2)
      (busy w_busy2)
      (done w_done2)))
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

sub sorted {
    my ($values) = @_;
    return [sort @$values];
}
