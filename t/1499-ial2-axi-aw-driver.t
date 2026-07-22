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

subtest 'adapter parses the bounded AXI AW address-channel driver PPIF shape' => sub {
    ok(-f sample_aw_driver_ppif_path(), 'tracked runnable AXI AW driver PPIF sample exists');

    my $result = FSM::Adapter::IAL2::PPIF->new()->parse_file(sample_aw_driver_ppif_path());

    is($result->{layer}, 'IAL2', 'AXI AW driver adapter result stays IAL2');
    is($result->{kind}, 'protocol_intent.axi_aw_driver', 'adapter returns the AXI AW driver kind');
    is($result->{mode}, 'driver', 'AXI AW driver mode is explicit');
    is($result->{report}{schema}, 'fsmgen.ial2.protocol_intent.axi_aw_driver.v1', 'AXI AW driver report schema is selected');
    is($result->{report}{source_object}{id}, 'axi-aw-driver', 'AXI AW driver source object id is preserved');
    is($result->{report}{source_object}{intent_name}, 'axi_aw_driver', 'AXI AW driver source intent name is preserved');
    is($result->{report}{target_protocol}{profile}, 'axi4', 'AXI AW driver report carries the axi4 profile');
    is($result->{report}{target_protocol}{object}, 'axi-aw-driver', 'AXI AW driver report carries the axi-aw-driver object');
    is($result->{report}{target_protocol}{role}, 'manager-to-subordinate', 'AXI AW driver report carries the manager-to-subordinate role');

    my $isf = $result->{generated_ial1}{text};
    is($result->{generated_ial1}{name}, 'axi_aw_driver.isf', 'AXI AW driver exposes generated IAL1 artifact');
    like($isf, qr/\A\(actor axi_aw_driver\b/, 'generated AW driver IAL1 is .isf text');
    like($isf, qr/\(input aw_cmd_valid\)/, 'generated AW driver IAL1 declares the command trigger');
    like($isf, qr/\(input cmd_awaddr \(width 32\)\)/, 'generated AW driver IAL1 declares the command address input');
    like($isf, qr/\(input awready\)/, 'generated AW driver IAL1 declares AWREADY');
    like($isf, qr/\(output awvalid\)/, 'generated AW driver IAL1 drives AWVALID');
    like($isf, qr/\(output awaddr \(width 32\)\)/, 'generated AW driver IAL1 drives AWADDR');
    like($isf, qr/\(output awid \(width 4\)\)/, 'generated AW driver IAL1 drives AWID');
    like($isf, qr/\(priority accept_aw over launch_aw\)/, 'generated AW driver IAL1 gives acceptance priority over launch');
    like($isf, qr/\(rule launch_aw launch_aw_start\b/, 'generated AW driver IAL1 has the launch handoff rule');
    like($isf, qr/\(rule accept_aw \(& awvalid awready\)/, 'generated AW driver IAL1 clears on the accepted-transfer predicate');
    like($isf, qr/\(set awvalid 1\)/, 'generated AW driver IAL1 launches AWVALID high');
    like($isf, qr/\(set awvalid 0\)/, 'generated AW driver IAL1 clears AWVALID on acceptance');
    like($isf, qr/\(on aw_cmd_valid/, 'generated AW driver IAL1 triggers on the command');
    like($isf, qr/\(sample cmd_awaddr as addr_q\)/, 'generated AW driver IAL1 samples the command address');
    like($isf, qr/\(drive\s+\(launch_aw_start 1\)\)/, 'generated AW driver IAL1 emits the one-state launch handoff');
    like($isf, qr/\(while active_q\s+\(wait 1\)\)/, 'generated AW driver IAL1 waits on latched transfer activity');
    unlike($isf, qr/\(drive deassert_aw\b/, 'generated AW driver IAL1 has no late post-READY deassert drive');
    unlike($isf, qr/\(while \(! awready\)/, 'generated AW driver IAL1 does not depend on resampling READY for control completion');
    like($isf, qr/\(complete aw_done\)/, 'generated AW driver IAL1 pulses aw_done on completion');

    my $ial1_schedule = $result->{generated_ial1_schedule_report};
    is($ial1_schedule->{state_count}, 6, 'corrected AW driver IAL1 schedule has six states');
    is_deeply($ial1_schedule->{compile_issues}, [], 'corrected AW driver IAL1 schedule has no compile issues');
    is_deeply(
        [
            sort map {
                join(':', $_->{winner}, $_->{loser}, $_->{target})
            } @{$ial1_schedule->{priority_resolutions} || []}
        ],
        [
            'accept_aw:launch_aw:active_q',
            'accept_aw:launch_aw:aw_busy',
            'accept_aw:launch_aw:awvalid',
        ],
        'corrected AW driver schedule resolves the three shared rule targets in favor of acceptance',
    );

    is_deeply(
        sorted([keys %{$result->{generated_ial0}{files}}]),
        ['axi_aw_driver.fsm'],
        'AXI AW driver adapter exposes generated IAL0 .fsm file map',
    );
    my $fsm = $result->{generated_ial0}{files}{'axi_aw_driver.fsm'};
    like($fsm, qr/\(\?fsm:axi_aw_driver\b/, 'generated AW driver IAL0 names the driver FSM');
    like($fsm, qr/\bawvalid\b/, 'generated AW driver IAL0 carries AWVALID');
    like($fsm, qr/\bawready\b/, 'generated AW driver IAL0 carries AWREADY');
    like($fsm, qr/\bawaddr\b/, 'generated AW driver IAL0 carries AWADDR');
    like($fsm, qr/\(-launch_aw <launch_aw_start/, 'generated AW driver IAL0 contains the launch rule DT');
    like($fsm, qr/\(-accept_aw <\(& awvalid awready\)/, 'generated AW driver IAL0 contains the acceptance-edge clear DT');
    like($fsm, qr/\(aw_issue_while_entry_2\s+\(\?active_q/s, 'generated AW driver IAL0 waits on latched active_q');

    is($result->{report}{bindings}{command}{address}{name}, 'cmd_awaddr', 'report captures command address binding');
    is($result->{report}{bindings}{command}{address}{width}, 32, 'report captures command address width');
    is($result->{report}{bindings}{channel}{valid}, 'awvalid', 'report captures channel valid binding');
    is($result->{report}{generated_artifacts}{hdl_entry}{entry_artifact}, 'axi_aw_driver.fsm', 'report selects generated driver .fsm as HDL entry');
    is($result->{report}{layering}{direct_ial2_to_ial0}, 0, 'AXI AW driver lowering goes through generated IAL1 before IAL0');

    my %residue = map { $_->{id} => 1 } @{$result->{report}{unsupported_residue}};
    ok($residue{axi_aw_driver_w_channel_deferred}, 'report keeps W write-data drive residue explicit');
    ok($residue{axi_aw_driver_ar_channel_deferred}, 'report keeps AR read-address drive residue explicit');
    ok($residue{axi_aw_driver_id_width_fixed}, 'report keeps the pinned AWID width residue explicit');
    ok($residue{axi_aw_driver_profile_alias_deferred}, 'report keeps the .axi profile-alias residue explicit');
};

subtest 'malformed AXI AW driver PPIF sources fail closed' => sub {
    my @cases = (
        [
            'non-AXI profile',
            sub {
                my $source = sample_aw_driver_ppif();
                $source =~ s/\(profile axi4\)/(profile ahb)/;
                return $source;
            },
            qr/profile 'ahb' does not match \(axi-aw-driver \.\.\.\)/,
        ],
        [
            'missing channel block',
            sub {
                my $source = sample_aw_driver_ppif();
                $source =~ s/\n    \(channel\n.*?\(done aw_done\)\)\)/)/s;
                return $source;
            },
            qr/missing required \(channel \.\.\.\) clause/,
        ],
        [
            'unsupported address width',
            sub {
                my $source = sample_aw_driver_ppif();
                $source =~ s/\(address cmd_awaddr width 32\)/(address cmd_awaddr width 16)/;
                return $source;
            },
            qr/command\.address\.width must be 32 in this slice/,
        ],
    );

    for my $case (@cases) {
        my ($label, $build_source, $pattern) = @$case;
        my $ok = eval {
            FSM::Adapter::IAL2::PPIF->new()->parse_source($build_source->(), "$label.ppif");
            1;
        };
        ok(!$ok, "$label is rejected");
        like($@, $pattern, "$label diagnostic is targeted");
    }
};

subtest 'CLI checks, semantic export, schedule report, outdir, and verify-hdl use the public AW driver path' => sub {
    my $check = run_json_command('./bin/fsmgen', '--quiet', '--strict', '--check', '--json', sample_aw_driver_ppif_path());
    ok($check->{success}, 'strict check JSON succeeds for AXI AW driver PPIF');
    is($check->{result}{module_name}, 'axi_aw_driver', 'check JSON reports generated module name');
    is($check->{support_accounting}{entry_id}, 'intent.ppif_axi_aw_driver', 'check JSON matches AXI AW driver support accounting');
    is($check->{support_accounting}{source_kind}, 'ppif', 'check JSON reports PPIF source kind');

    my $semantic = run_json_command('./bin/fsmgen', '--quiet', '--strict', '--emit-semantic-json', sample_aw_driver_ppif_path());
    ok($semantic->{success}, 'strict semantic JSON succeeds for AXI AW driver PPIF');
    is($semantic->{generation_result_snapshot}{summary}{module_name}, 'axi_aw_driver', 'semantic JSON reports generated module name');
    is($semantic->{generation_result_snapshot}{summary}{source_root_kind}, 'fsm', 'semantic JSON reports generated FSM source root');
    is($semantic->{support_accounting}{entry_id}, 'intent.ppif_axi_aw_driver', 'semantic JSON matches AXI AW driver support accounting');

    my $schedule = run_json_command('./bin/fsmgen', '--quiet', '--emit-schedule-json', sample_aw_driver_ppif_path());
    is($schedule->{schema}, 'fsmgen.ial2.protocol_intent.axi_aw_driver.v1', 'schedule/report JSON exposes the AXI AW driver schema');
    is($schedule->{generated_artifacts}{ial1}{name}, 'axi_aw_driver.isf', 'schedule/report JSON exposes generated IAL1 artifact');
    is_deeply($schedule->{generated_artifacts}{ial0}{files}, ['axi_aw_driver.fsm'], 'schedule/report JSON exposes generated IAL0 artifact');

    my $tempdir = tempdir(CLEANUP => 1);
    my $outdir = File::Spec->catdir($tempdir, 'out');
    my $hdl = File::Spec->catfile($tempdir, 'axi_aw_driver.sv');
    my ($success, undef, undef, undef, $stderr) = run(
        command => ['./bin/fsmgen', '--quiet', '--outdir', $outdir, '--output', $hdl, sample_aw_driver_ppif_path()],
    );
    ok($success, 'AXI AW driver PPIF emits HDL and review artifacts through --outdir');
    is(join('', @{$stderr || []}), '', 'outdir generation keeps stderr clean');
    ok(-f File::Spec->catfile($outdir, 'axi_aw_driver.isf'), 'outdir contains generated AW driver IAL1 artifact');
    ok(-f File::Spec->catfile($outdir, 'axi_aw_driver.fsm'), 'outdir contains generated AW driver IAL0 artifact');
    ok(-f $hdl, 'outdir command emits selected HDL output');
    like(slurp($hdl), qr/\bmodule\s+axi_aw_driver\b/, 'generated HDL contains the AXI AW driver module');

    my ($verify_ok, undef, undef, $verify_stdout, undef) = run(
        command => ['./bin/fsmgen', '--verify-hdl', sample_aw_driver_ppif_path()],
    );
    ok($verify_ok, 'AXI AW driver PPIF passes --verify-hdl external validation');
    like(join('', @{$verify_stdout || []}), qr/verilator_lint: PASS/, 'AXI AW driver HDL passes verilator lint');
};

subtest 'generated HDL accepts exactly one AW transfer per accepted command' => sub {
    my $tempdir = tempdir(CLEANUP => 1);
    my $hdl = File::Spec->catfile($tempdir, 'axi_aw_driver.sv');
    my $testbench = File::Spec->catfile($tempdir, 'axi_aw_driver_cardinality_tb.sv');
    my $obj_dir = File::Spec->catdir($tempdir, 'obj_cardinality');

    my ($generate_ok, undef, undef, undef, $generate_stderr) = run(
        command => [
            './bin/fsmgen', '--quiet', '--strict', '--output', $hdl,
            sample_aw_driver_ppif_path(),
        ],
    );
    ok($generate_ok, 'public AXI AW driver source emits HDL for cardinality simulation');
    is(join('', @{$generate_stderr || []}), '', 'cardinality HDL generation keeps stderr clean');

    write_file($testbench, <<'SV');
module axi_aw_driver_cardinality_tb;
  logic clk = 0;
  logic rst_n = 0;
  logic aw_cmd_valid = 0;
  logic [31:0] cmd_awaddr = 0;
  logic [3:0] cmd_awid = 0;
  logic [7:0] cmd_awlen = 0;
  logic [2:0] cmd_awsize = 0;
  logic [1:0] cmd_awburst = 0;
  logic awready = 0;
  wire awvalid;
  wire [31:0] awaddr;
  wire [3:0] awid;
  wire [7:0] awlen;
  wire [2:0] awsize;
  wire [1:0] awburst;
  wire aw_busy;
  wire aw_done;
  integer handshakes = 0;
  integer done_pulses = 0;
  integer wait_cycles = 0;

  axi_aw_driver dut (.*);
  always #5 clk = ~clk;

  always @(posedge clk) begin
    if (rst_n && awvalid && awready)
      handshakes <= handshakes + 1;
    if (rst_n && aw_done)
      done_pulses <= done_pulses + 1;
  end

  task automatic pulse_command(
    input logic [31:0] addr,
    input logic [3:0] id,
    input logic [7:0] len,
    input logic [2:0] size,
    input logic [1:0] burst
  );
    begin
      @(negedge clk);
      cmd_awaddr = addr;
      cmd_awid = id;
      cmd_awlen = len;
      cmd_awsize = size;
      cmd_awburst = burst;
      aw_cmd_valid = 1;
      @(negedge clk);
      aw_cmd_valid = 0;
    end
  endtask

  initial begin
    repeat (2) @(negedge clk);
    rst_n = 1;
    repeat (2) @(negedge clk);

    awready = 1;
    pulse_command(32'h1020_3040, 4'h3, 8'h07, 3'h2, 2'h1);
    repeat (12) @(negedge clk);
    if (handshakes != 1 || done_pulses != 1)
      $fatal(1, "continuous-ready expected one transfer/done, got %0d/%0d", handshakes, done_pulses);
    if (awvalid || aw_busy)
      $fatal(1, "continuous-ready did not return valid/busy low");

    awready = 0;
    pulse_command(32'h5566_7788, 4'hA, 8'h11, 3'h4, 2'h2);
    wait_cycles = 0;
    while (!awvalid && wait_cycles < 8) begin
      @(negedge clk);
      wait_cycles = wait_cycles + 1;
    end
    if (!awvalid)
      $fatal(1, "stalled command never raised AWVALID");

    repeat (4) begin
      @(negedge clk);
      if (!awvalid || !aw_busy)
        $fatal(1, "stalled case dropped valid/busy");
      if ({awaddr, awid, awlen, awsize, awburst} !==
          {32'h5566_7788, 4'hA, 8'h11, 3'h4, 2'h2})
        $fatal(1, "stalled case changed AW payload");
    end

    awready = 1;
    @(negedge clk);
    awready = 0;
    repeat (12) @(negedge clk);
    if (handshakes != 2 || done_pulses != 2)
      $fatal(1, "one-cycle-ready expected second transfer/done, totals %0d/%0d", handshakes, done_pulses);
    if (awvalid || aw_busy)
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
            '-j', '1', '--top-module', 'axi_aw_driver_cardinality_tb',
            '--Mdir', $obj_dir, $hdl, $testbench,
        ],
    );
    ok($compile_ok, 'Verilator builds the generated AW cardinality harness')
        or diag(join('', @{$compile_stdout || []}), join('', @{$compile_stderr || []}));

    return unless $compile_ok;

    my $binary = File::Spec->catfile($obj_dir, 'Vaxi_aw_driver_cardinality_tb');
    ok(-x $binary, 'Verilator cardinality harness binary exists');
    my ($run_ok, undef, undef, $run_stdout, $run_stderr) = run(command => [$binary]);
    ok($run_ok, 'generated AW driver cardinality simulation passes')
        or diag(join('', @{$run_stdout || []}), join('', @{$run_stderr || []}));
    like(
        join('', @{$run_stdout || []}),
        qr/PASS handshakes=2 done_pulses=2/,
        'continuous-ready and one-cycle-ready commands each accept exactly once and complete once',
    );
};

done_testing();

sub sample_aw_driver_ppif_path {
    return File::Spec->catfile($FindBin::Bin, '..', 'ppif', 'axi_aw_driver.ppif');
}

sub sample_aw_driver_ppif {
    return slurp(sample_aw_driver_ppif_path());
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
            return {};
        };
    return $decoded;
}

sub slurp {
    my ($path) = @_;
    open my $fh, '<', $path or die "Cannot read $path: $!";
    local $/;
    return <$fh>;
}

sub write_file {
    my ($path, $text) = @_;
    open my $fh, '>', $path or die "Cannot write $path: $!";
    print {$fh} $text;
    close $fh or die "Cannot close $path: $!";
}

sub sorted {
    my ($values) = @_;
    return [sort @$values];
}
