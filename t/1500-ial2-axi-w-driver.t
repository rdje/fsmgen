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

subtest 'adapter parses the bounded AXI W write-data-channel driver PPIF shape' => sub {
    ok(-f sample_w_driver_ppif_path(), 'tracked runnable AXI W driver PPIF sample exists');

    my $result = FSM::Adapter::IAL2::PPIF->new()->parse_file(sample_w_driver_ppif_path());

    is($result->{layer}, 'IAL2', 'AXI W driver adapter result stays IAL2');
    is($result->{kind}, 'protocol_intent.axi_w_driver', 'adapter returns the AXI W driver kind');
    is($result->{mode}, 'driver', 'AXI W driver mode is explicit');
    is($result->{report}{schema}, 'fsmgen.ial2.protocol_intent.axi_w_driver.v1', 'AXI W driver report schema is selected');
    is($result->{report}{source_object}{id}, 'axi-w-driver', 'AXI W driver source object id is preserved');
    is($result->{report}{source_object}{intent_name}, 'axi_w_driver', 'AXI W driver source intent name is preserved');
    is_deeply(
        [map { [$_->{section}, $_->{page}] } @{$result->{report}{source_object}{anchors}}],
        [
            ['A2.3', '29'],
            ['A2.3.1', '30'],
            ['A2.3.2.1', '31'],
            ['A3.2.1', '53'],
            ['A3.2.1.1', '54'],
        ],
        'AXI W driver carries the five selected Valid-Ready/write-data source anchors',
    );
    is($result->{report}{target_protocol}{profile}, 'axi4', 'AXI W driver report carries the axi4 profile');
    is($result->{report}{target_protocol}{object}, 'axi-w-driver', 'AXI W driver report carries the axi-w-driver object');
    is($result->{report}{target_protocol}{role}, 'manager-to-subordinate', 'AXI W driver report carries the manager-to-subordinate role');

    my $isf = $result->{generated_ial1}{text};
    is($result->{generated_ial1}{name}, 'axi_w_driver.isf', 'AXI W driver exposes generated IAL1 artifact');
    like($isf, qr/\A\(actor axi_w_driver\b/, 'generated W driver IAL1 is .isf text');
    like($isf, qr/\(input w_cmd_valid\)/, 'generated W driver IAL1 declares the command trigger');
    like($isf, qr/\(input cmd_wdata \(width 32\)\)/, 'generated W driver IAL1 declares the command data input');
    like($isf, qr/\(input cmd_wstrb \(width 4\)\)/, 'generated W driver IAL1 declares the command strobe input');
    like($isf, qr/\(input wready\)/, 'generated W driver IAL1 declares WREADY');
    like($isf, qr/\(output wvalid\)/, 'generated W driver IAL1 drives WVALID');
    like($isf, qr/\(output wdata \(width 32\)\)/, 'generated W driver IAL1 drives WDATA');
    like($isf, qr/\(output wstrb \(width 4\)\)/, 'generated W driver IAL1 drives WSTRB');
    like($isf, qr/\(output wlast\)/, 'generated W driver IAL1 drives WLAST');
    like($isf, qr/\(priority accept_w over launch_w\)/, 'generated W driver IAL1 gives acceptance priority over launch');
    like($isf, qr/\(rule launch_w launch_w_start\b/, 'generated W driver IAL1 has the launch handoff rule');
    like($isf, qr/\(rule accept_w \(& wvalid wready\)/, 'generated W driver IAL1 clears on the accepted-transfer predicate');
    like($isf, qr/\(set wvalid 1\)/, 'generated W driver IAL1 launches WVALID high');
    like($isf, qr/\(set wlast 1\)/, 'generated W driver IAL1 fixes WLAST high for the one beat');
    like($isf, qr/\(set wvalid 0\)/, 'generated W driver IAL1 clears WVALID on acceptance');
    like($isf, qr/\(sample cmd_wdata as data_q\)/, 'generated W driver IAL1 samples command data');
    like($isf, qr/\(sample cmd_wstrb as strb_q\)/, 'generated W driver IAL1 samples command strobes');
    like($isf, qr/\(drive\s+\(launch_w_start 1\)\)/, 'generated W driver IAL1 emits the one-state launch handoff');
    like($isf, qr/\(while active_q\s+\(wait 1\)\)/, 'generated W driver IAL1 waits on latched transfer activity');
    like($isf, qr/\(complete w_done\)/, 'generated W driver IAL1 pulses w_done on completion');

    my $schedule = $result->{generated_ial1_schedule_report};
    is($schedule->{state_count}, 6, 'W driver IAL1 schedule has six states');
    is_deeply($schedule->{compile_issues}, [], 'W driver IAL1 schedule has no compile issues');
    is_deeply(
        [
            sort map {
                join(':', $_->{winner}, $_->{loser}, $_->{target})
            } @{$schedule->{priority_resolutions} || []}
        ],
        [
            'accept_w:launch_w:active_q',
            'accept_w:launch_w:w_busy',
            'accept_w:launch_w:wvalid',
        ],
        'W driver schedule resolves the three shared rule targets in favor of acceptance',
    );

    is_deeply(
        sorted([keys %{$result->{generated_ial0}{files}}]),
        ['axi_w_driver.fsm'],
        'AXI W driver adapter exposes generated IAL0 .fsm file map',
    );
    my $fsm = $result->{generated_ial0}{files}{'axi_w_driver.fsm'};
    like($fsm, qr/\(\?fsm:axi_w_driver\b/, 'generated W driver IAL0 names the driver FSM');
    like($fsm, qr/\bwvalid\b/, 'generated W driver IAL0 carries WVALID');
    like($fsm, qr/\bwready\b/, 'generated W driver IAL0 carries WREADY');
    like($fsm, qr/\bwlast\b/, 'generated W driver IAL0 carries WLAST');
    like($fsm, qr/\(-launch_w <launch_w_start/, 'generated W driver IAL0 contains the launch rule DT');
    like($fsm, qr/\(-accept_w <\(& wvalid wready\)/, 'generated W driver IAL0 contains the acceptance-edge clear DT');

    is($result->{report}{bindings}{command}{data}{name}, 'cmd_wdata', 'report captures command data binding');
    is($result->{report}{bindings}{command}{strobe}{width}, 4, 'report captures command strobe width');
    is($result->{report}{bindings}{channel}{last}, 'wlast', 'report captures WLAST binding');
    is($result->{report}{single_beat}{data_width}, 32, 'report pins single-beat data width');
    is($result->{report}{single_beat}{strobe_width}, 4, 'report pins single-beat strobe width');
    is($result->{report}{single_beat}{last_value}, 1, 'report pins WLAST high');
    ok($result->{report}{single_beat}{all_zero_strobe_allowed}, 'report records legal all-zero WSTRB');
    is($result->{report}{generated_artifacts}{hdl_entry}{entry_artifact}, 'axi_w_driver.fsm', 'report selects generated W driver .fsm as HDL entry');
    is($result->{report}{layering}{direct_ial2_to_ial0}, 0, 'AXI W driver lowering goes through generated IAL1 before IAL0');

    my %residue = map { $_->{id} => 1 } @{$result->{report}{unsupported_residue}};
    for my $id (qw(
        axi_w_driver_aw_coordination_deferred
        axi_w_driver_b_response_completion_deferred
        axi_w_driver_multi_beat_deferred
        axi_w_driver_outstanding_transactions_deferred
        axi_w_driver_burst_address_coupling_deferred
        axi_w_driver_ar_r_channels_deferred
        axi_w_driver_capacity_core_integration_deferred
        axi_w_driver_transaction_interface_deferred
        axi_w_driver_profile_alias_deferred
        axi_w_driver_verification_output_deferred
        axi_w_driver_backend_variants_deferred
    )) {
        ok($residue{$id}, "report keeps $id explicit");
    }
};

subtest 'malformed AXI W driver PPIF sources fail closed' => sub {
    my @cases = (
        [
            'non-AXI profile',
            sub {
                my $source = sample_w_driver_ppif();
                $source =~ s/\(profile axi4\)/(profile ahb)/;
                return $source;
            },
            qr/profile 'ahb' does not match \(axi-w-driver \.\.\.\)/,
            'bad-profile.ppif',
        ],
        [
            'non-AXI4 family member',
            sub {
                my $source = sample_w_driver_ppif();
                $source =~ s/\(profile axi4\)/(profile axi3)/;
                return $source;
            },
            qr/profile must be axi4 in this slice/,
            'axi3.ppif',
        ],
        [
            'wrong role',
            sub {
                my $source = sample_w_driver_ppif();
                $source =~ s/\(role manager-to-subordinate\)/(role subordinate-to-manager)/;
                return $source;
            },
            qr/role must be manager-to-subordinate/,
            'bad-role.ppif',
        ],
        [
            'missing channel block',
            sub {
                my $source = sample_w_driver_ppif();
                $source =~ s/\n    \(channel\n.*?\(done w_done\)\)\)/)/s;
                return $source;
            },
            qr/missing required \(channel \.\.\.\) clause/,
            'missing-channel.ppif',
        ],
        [
            'unsupported data width',
            sub {
                my $source = sample_w_driver_ppif();
                $source =~ s/\(data cmd_wdata width 32\)/(data cmd_wdata width 16)/;
                return $source;
            },
            qr/command\.data\.width must be 32 in this slice/,
            'bad-data-width.ppif',
        ],
        [
            'unsupported strobe width',
            sub {
                my $source = sample_w_driver_ppif();
                $source =~ s/\(strobe cmd_wstrb width 4\)/(strobe cmd_wstrb width 2)/;
                return $source;
            },
            qr/command\.strobe\.width must be 4 in this slice/,
            'bad-strobe-width.ppif',
        ],
        [
            'duplicate signal binding',
            sub {
                my $source = sample_w_driver_ppif();
                $source =~ s/\(last wlast\)/(last wvalid)/;
                return $source;
            },
            qr/duplicates signal 'wvalid'/,
            'duplicate-signal.ppif',
        ],
        [
            'duplicate W driver object',
            sub {
                return insert_before_root_close(sample_w_driver_ppif(), second_w_driver_clause());
            },
            qr/supports exactly one \(axi-w-driver \.\.\.\) object/,
            'duplicate-object.ppif',
        ],
        [
            'mixed W and AW driver objects',
            sub {
                return insert_before_root_close(sample_w_driver_ppif(), aw_driver_clause());
            },
            qr/cannot mix \(axi-w-driver \.\.\.\) with other intent objects/,
            'mixed-object.ppif',
        ],
        [
            'W driver profile alias',
            sub { return sample_w_driver_ppif() },
            qr/\(axi-w-driver \.\.\.\) remains unsupported for the first profile-alias implementation/,
            'w-driver.axi',
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

subtest 'CLI checks, semantic export, schedule report, outdir, and verify-hdl use the public W driver path' => sub {
    my $check = run_json_command('./bin/fsmgen', '--quiet', '--strict', '--check', '--json', sample_w_driver_ppif_path());
    ok($check->{success}, 'strict check JSON succeeds for AXI W driver PPIF');
    is($check->{result}{module_name}, 'axi_w_driver', 'check JSON reports generated module name');
    is($check->{support_accounting}{entry_id}, 'intent.ppif_axi_w_driver', 'check JSON matches AXI W driver support accounting');
    is($check->{support_accounting}{source_kind}, 'ppif', 'check JSON reports PPIF source kind');

    my $semantic = run_json_command('./bin/fsmgen', '--quiet', '--strict', '--emit-semantic-json', sample_w_driver_ppif_path());
    ok($semantic->{success}, 'strict semantic JSON succeeds for AXI W driver PPIF');
    is($semantic->{generation_result_snapshot}{summary}{module_name}, 'axi_w_driver', 'semantic JSON reports generated module name');
    is($semantic->{generation_result_snapshot}{summary}{source_root_kind}, 'fsm', 'semantic JSON reports generated FSM source root');
    is($semantic->{support_accounting}{entry_id}, 'intent.ppif_axi_w_driver', 'semantic JSON matches AXI W driver support accounting');

    my $schedule = run_json_command('./bin/fsmgen', '--quiet', '--emit-schedule-json', sample_w_driver_ppif_path());
    is($schedule->{schema}, 'fsmgen.ial2.protocol_intent.axi_w_driver.v1', 'schedule/report JSON exposes the AXI W driver schema');
    is($schedule->{generated_artifacts}{ial1}{name}, 'axi_w_driver.isf', 'schedule/report JSON exposes generated IAL1 artifact');
    is_deeply($schedule->{generated_artifacts}{ial0}{files}, ['axi_w_driver.fsm'], 'schedule/report JSON exposes generated IAL0 artifact');

    my $tempdir = tempdir(CLEANUP => 1);
    my $outdir = File::Spec->catdir($tempdir, 'out');
    my $hdl = File::Spec->catfile($tempdir, 'axi_w_driver.sv');
    my ($success, undef, undef, undef, $stderr) = run(
        command => ['./bin/fsmgen', '--quiet', '--outdir', $outdir, '--output', $hdl, sample_w_driver_ppif_path()],
    );
    ok($success, 'AXI W driver PPIF emits HDL and review artifacts through --outdir');
    is(join('', @{$stderr || []}), '', 'outdir generation keeps stderr clean');
    ok(-f File::Spec->catfile($outdir, 'axi_w_driver.isf'), 'outdir contains generated W driver IAL1 artifact');
    ok(-f File::Spec->catfile($outdir, 'axi_w_driver.fsm'), 'outdir contains generated W driver IAL0 artifact');
    ok(-f $hdl, 'outdir command emits selected HDL output');
    like(slurp($hdl), qr/\bmodule\s+axi_w_driver\b/, 'generated HDL contains the AXI W driver module');

    my ($verify_ok, undef, undef, $verify_stdout, undef) = run(
        command => ['./bin/fsmgen', '--verify-hdl', sample_w_driver_ppif_path()],
    );
    ok($verify_ok, 'AXI W driver PPIF passes --verify-hdl external validation');
    like(join('', @{$verify_stdout || []}), qr/verilator_lint: PASS/, 'AXI W driver HDL passes verilator lint');
    like(join('', @{$verify_stdout || []}), qr/yosys_synthesis: PASS/, 'AXI W driver HDL passes Yosys synthesis');
};

subtest 'generated HDL accepts exactly one W transfer per accepted command' => sub {
    my $tempdir = tempdir(CLEANUP => 1);
    my $hdl = File::Spec->catfile($tempdir, 'axi_w_driver.sv');
    my $testbench = File::Spec->catfile($tempdir, 'axi_w_driver_cardinality_tb.sv');
    my $obj_dir = File::Spec->catdir($tempdir, 'obj_cardinality');

    my ($generate_ok, undef, undef, undef, $generate_stderr) = run(
        command => [
            './bin/fsmgen', '--quiet', '--strict', '--output', $hdl,
            sample_w_driver_ppif_path(),
        ],
    );
    ok($generate_ok, 'public AXI W driver source emits HDL for cardinality simulation');
    is(join('', @{$generate_stderr || []}), '', 'cardinality HDL generation keeps stderr clean');

    write_file($testbench, <<'SV');
module axi_w_driver_cardinality_tb;
  logic clk = 0;
  logic rst_n = 0;
  logic w_cmd_valid = 0;
  logic [31:0] cmd_wdata = 0;
  logic [3:0] cmd_wstrb = 0;
  logic wready = 0;
  wire wvalid;
  wire [31:0] wdata;
  wire [3:0] wstrb;
  wire wlast;
  wire w_busy;
  wire w_done;
  integer handshakes = 0;
  integer done_pulses = 0;
  integer wait_cycles = 0;

  axi_w_driver dut (.*);
  always #5 clk = ~clk;

  always @(posedge clk) begin
    if (rst_n && wvalid && !wlast)
      $fatal(1, "WLAST must be high on every valid beat");
    if (rst_n && wvalid && wready)
      handshakes <= handshakes + 1;
    if (rst_n && w_done)
      done_pulses <= done_pulses + 1;
  end

  task automatic pulse_command(
    input logic [31:0] data,
    input logic [3:0] strb
  );
    begin
      @(negedge clk);
      cmd_wdata = data;
      cmd_wstrb = strb;
      w_cmd_valid = 1;
      @(negedge clk);
      w_cmd_valid = 0;
    end
  endtask

  initial begin
    repeat (2) @(negedge clk);
    rst_n = 1;
    repeat (2) @(negedge clk);

    wready = 1;
    pulse_command(32'h1020_3040, 4'b0000);
    repeat (12) @(negedge clk);
    if (handshakes != 1 || done_pulses != 1)
      $fatal(1, "continuous-ready zero-strobe expected one transfer/done, got %0d/%0d", handshakes, done_pulses);
    if (wvalid || w_busy)
      $fatal(1, "continuous-ready did not return valid/busy low");

    wready = 0;
    pulse_command(32'h5566_7788, 4'b1010);
    wait_cycles = 0;
    while (!wvalid && wait_cycles < 8) begin
      @(negedge clk);
      wait_cycles = wait_cycles + 1;
    end
    if (!wvalid)
      $fatal(1, "stalled command never raised WVALID");

    repeat (4) begin
      @(negedge clk);
      if (!wvalid || !w_busy || !wlast)
        $fatal(1, "stalled case dropped valid/busy/last");
      if ({wdata, wstrb} !== {32'h5566_7788, 4'b1010})
        $fatal(1, "stalled case changed W payload");
    end

    wready = 1;
    @(negedge clk);
    wready = 0;
    repeat (12) @(negedge clk);
    if (handshakes != 2 || done_pulses != 2)
      $fatal(1, "one-cycle-ready expected second transfer/done, totals %0d/%0d", handshakes, done_pulses);
    if (wvalid || w_busy)
      $fatal(1, "one-cycle-ready did not return valid/busy low");

    $display("PASS handshakes=%0d done_pulses=%0d", handshakes, done_pulses);
    $finish;
  end

  initial begin
    #5000;
    $fatal(1, "cardinality simulation timed out");
  end
endmodule
SV

    my ($compile_ok, undef, undef, $compile_stdout, $compile_stderr) = run(
        command => [
            'verilator', '--binary', '--timing', '--assert', '-Wno-fatal',
            '-j', '1', '--top-module', 'axi_w_driver_cardinality_tb',
            '--Mdir', $obj_dir, $hdl, $testbench,
        ],
    );
    ok($compile_ok, 'Verilator builds the generated W cardinality harness')
        or diag(join('', @{$compile_stdout || []}), join('', @{$compile_stderr || []}));

    return unless $compile_ok;

    my $binary = File::Spec->catfile($obj_dir, 'Vaxi_w_driver_cardinality_tb');
    ok(-x $binary, 'Verilator W cardinality harness binary exists');
    my ($run_ok, undef, undef, $run_stdout, $run_stderr) = run(command => [$binary]);
    ok($run_ok, 'generated W driver cardinality simulation passes')
        or diag(join('', @{$run_stdout || []}), join('', @{$run_stderr || []}));
    like(
        join('', @{$run_stdout || []}),
        qr/PASS handshakes=2 done_pulses=2/,
        'continuous-ready zero-strobe and stalled one-cycle-ready commands each accept and complete exactly once',
    );
};

done_testing();

sub sample_w_driver_ppif_path {
    return File::Spec->catfile($FindBin::Bin, '..', 'ppif', 'axi_w_driver.ppif');
}

sub sample_w_driver_ppif {
    return slurp(sample_w_driver_ppif_path());
}

sub insert_before_root_close {
    my ($source, $clause) = @_;
    $source =~ s/\)\s*\z/$clause\n)\n/
        or die "failed to append PPIF object clause\n";
    return $source;
}

sub second_w_driver_clause {
    return <<'PPIF';
  (axi-w-driver axi_w_driver_2
    (role manager-to-subordinate)
    (clock clk2)
    (reset (rst2_n active_low async))
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

sub aw_driver_clause {
    return <<'PPIF';
  (axi-aw-driver axi_aw_driver_2
    (role manager-to-subordinate)
    (clock awclk)
    (reset (awreset_n active_low async))
    (command
      (start aw2_cmd_valid)
      (address cmd_awaddr2 width 32)
      (id cmd_awid2 width 4)
      (length cmd_awlen2 width 8)
      (size cmd_awsize2 width 3)
      (burst cmd_awburst2 width 2)
      (ready awready2))
    (channel
      (valid awvalid2)
      (address awaddr2 width 32)
      (id awid2 width 4)
      (length awlen2 width 8)
      (size awsize2 width 3)
      (burst awburst2 width 2)
      (busy aw_busy2)
      (done aw_done2)))
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
