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

subtest 'adapter parses the bounded AXI AR address-channel driver PPIF shape' => sub {
    ok(-f sample_ar_driver_ppif_path(), 'tracked runnable AXI AR driver PPIF sample exists');

    my $result = FSM::Adapter::IAL2::PPIF->new()->parse_file(sample_ar_driver_ppif_path());

    is($result->{layer}, 'IAL2', 'AXI AR driver adapter result stays IAL2');
    is($result->{kind}, 'protocol_intent.axi_ar_driver', 'adapter returns the AXI AR driver kind');
    is($result->{mode}, 'driver', 'AXI AR driver mode is explicit');
    is($result->{report}{schema}, 'fsmgen.ial2.protocol_intent.axi_ar_driver.v1', 'AXI AR driver report schema is selected');
    is($result->{report}{source_object}{id}, 'axi-ar-driver', 'AXI AR driver source object id is preserved');
    is($result->{report}{source_object}{intent_name}, 'axi_ar_driver', 'AXI AR driver source intent name is preserved');
    is($result->{report}{target_protocol}{profile}, 'axi4', 'AXI AR driver report carries the axi4 profile');
    is($result->{report}{target_protocol}{object}, 'axi-ar-driver', 'AXI AR driver report carries the axi-ar-driver object');
    is($result->{report}{target_protocol}{role}, 'manager-to-subordinate', 'AXI AR driver report carries the manager-to-subordinate role');
    is(scalar(@{$result->{report}{source_object}{anchors}}), 9, 'AXI AR driver preserves all nine source anchors');

    my $isf = $result->{generated_ial1}{text};
    is($result->{generated_ial1}{name}, 'axi_ar_driver.isf', 'AXI AR driver exposes generated IAL1 artifact');
    like($isf, qr/\A\(actor axi_ar_driver\b/, 'generated AR driver IAL1 is .isf text');
    like($isf, qr/\(input ar_cmd_valid\)/, 'generated AR driver IAL1 declares the command trigger');
    like($isf, qr/\(input cmd_araddr \(width 32\)\)/, 'generated AR driver IAL1 declares the command address input');
    like($isf, qr/\(input arready\)/, 'generated AR driver IAL1 declares ARREADY');
    like($isf, qr/\(output arvalid\)/, 'generated AR driver IAL1 drives ARVALID');
    like($isf, qr/\(output araddr \(width 32\)\)/, 'generated AR driver IAL1 drives ARADDR');
    like($isf, qr/\(output arid \(width 4\)\)/, 'generated AR driver IAL1 drives ARID');
    like($isf, qr/\(priority accept_ar over launch_ar\)/, 'generated AR driver IAL1 gives acceptance priority over launch');
    like($isf, qr/\(rule launch_ar launch_ar_start\b/, 'generated AR driver IAL1 has the launch handoff rule');
    like($isf, qr/\(rule accept_ar \(& arvalid arready\)/, 'generated AR driver IAL1 clears on the accepted-transfer predicate');
    like($isf, qr/\(set arvalid 1\)/, 'generated AR driver IAL1 launches ARVALID high');
    like($isf, qr/\(set arvalid 0\)/, 'generated AR driver IAL1 clears ARVALID on acceptance');
    like($isf, qr/\(on ar_cmd_valid/, 'generated AR driver IAL1 triggers on the command');
    like($isf, qr/\(sample cmd_araddr as addr_q\)/, 'generated AR driver IAL1 samples the command address');
    like($isf, qr/\(drive\s+\(launch_ar_start 1\)\)/, 'generated AR driver IAL1 emits the one-state launch handoff');
    like($isf, qr/\(while active_q\s+\(wait 1\)\)/, 'generated AR driver IAL1 waits on latched transfer activity');
    unlike($isf, qr/\(drive deassert_ar\b/, 'generated AR driver IAL1 has no late post-READY deassert drive');
    unlike($isf, qr/\(while \(! arready\)/, 'generated AR driver IAL1 does not depend on resampling READY for control completion');
    like($isf, qr/\(complete ar_done\)/, 'generated AR driver IAL1 pulses ar_done on completion');

    my $ial1_schedule = $result->{generated_ial1_schedule_report};
    is($ial1_schedule->{state_count}, 6, 'corrected AR driver IAL1 schedule has six states');
    is($ial1_schedule->{port_count}, 15, 'corrected AR driver IAL1 schedule has fifteen interface ports');
    is_deeply($ial1_schedule->{compile_issues}, [], 'corrected AR driver IAL1 schedule has no compile issues');
    is_deeply(
        $ial1_schedule->{transactions}[0]{states},
        [qw(
            ar_issue_idle_0
            ar_issue_drive_1
            ar_issue_while_entry_2
            ar_issue_wait_3
            ar_issue_while_check_4
            ar_issue_done_5
        )],
        'corrected AR driver schedule exposes the six exact transaction states',
    );
    is_deeply(
        [map { [$_->{name}, $_->{assignments}] } @{$ial1_schedule->{dt_blocks}}],
        [['launch_ar', 8], ['accept_ar', 3]],
        'AR launch and acceptance rules expose the exact assignment counts',
    );
    is_deeply(
        [
            sort map {
                join(':', $_->{winner}, $_->{loser}, $_->{target})
            } @{$ial1_schedule->{priority_resolutions} || []}
        ],
        [
            'accept_ar:launch_ar:active_q',
            'accept_ar:launch_ar:ar_busy',
            'accept_ar:launch_ar:arvalid',
        ],
        'corrected AR driver schedule resolves the three shared rule targets in favor of acceptance',
    );

    is_deeply(
        sorted([keys %{$result->{generated_ial0}{files}}]),
        ['axi_ar_driver.fsm'],
        'AXI AR driver adapter exposes generated IAL0 .fsm file map',
    );
    my $fsm = $result->{generated_ial0}{files}{'axi_ar_driver.fsm'};
    like($fsm, qr/\(\?fsm:axi_ar_driver\b/, 'generated AR driver IAL0 names the driver FSM');
    like($fsm, qr/\barvalid\b/, 'generated AR driver IAL0 carries ARVALID');
    like($fsm, qr/\barready\b/, 'generated AR driver IAL0 carries ARREADY');
    like($fsm, qr/\baraddr\b/, 'generated AR driver IAL0 carries ARADDR');
    like($fsm, qr/\(-launch_ar <launch_ar_start/, 'generated AR driver IAL0 contains the launch rule DT');
    like($fsm, qr/\(-accept_ar <\(& arvalid arready\)/, 'generated AR driver IAL0 contains the acceptance-edge clear DT');
    like($fsm, qr/\(ar_issue_while_entry_2\s+\(\?active_q/s, 'generated AR driver IAL0 waits on latched active_q');

    is($result->{report}{bindings}{command}{address}{name}, 'cmd_araddr', 'report captures command address binding');
    is($result->{report}{bindings}{command}{address}{width}, 32, 'report captures command address width');
    is($result->{report}{bindings}{channel}{valid}, 'arvalid', 'report captures channel valid binding');
    is($result->{report}{generated_artifacts}{hdl_entry}{entry_artifact}, 'axi_ar_driver.fsm', 'report selects generated driver .fsm as HDL entry');
    is($result->{report}{layering}{direct_ial2_to_ial0}, 0, 'AXI AR driver lowering goes through generated IAL1 before IAL0');
    my %request_scope = %{$result->{report}{request_scope}};
    my $includes_read_response = delete $request_scope{includes_read_response};
    is_deeply(
        \%request_scope,
        {
            address_width => 32,
            id_width => 4,
            length_width => 8,
            size_width => 3,
            burst_width => 2,
            done_event => 'ar_request_accepted',
        },
        'report records the exact AR request scope and done event',
    );
    ok(!$includes_read_response, 'report makes read-response exclusion machine-readable');

    my %residue = map { $_->{id} => 1 } @{$result->{report}{unsupported_residue}};
    for my $id (qw(
        axi_ar_driver_id_width_fixed
        axi_ar_driver_attributes_deferred
        axi_ar_driver_request_legality_deferred
        axi_ar_driver_r_channel_deferred
        axi_ar_driver_request_only_completion
        axi_ar_driver_capacity_core_integration_deferred
        axi_ar_driver_outstanding_deferred
        axi_ar_driver_transaction_interface_deferred
        axi_ar_driver_profile_alias_deferred
        axi_ar_driver_verification_output_deferred
        axi_ar_driver_backend_variants_deferred
    )) {
        ok($residue{$id}, "report keeps $id residue explicit");
    }
};

subtest 'malformed AXI AR driver PPIF sources fail closed' => sub {
    my @cases = (
        [
            'non-AXI profile',
            sub {
                my $source = sample_ar_driver_ppif();
                $source =~ s/\(profile axi4\)/(profile ahb)/;
                return $source;
            },
            qr/profile 'ahb' does not match \(axi-ar-driver \.\.\.\)/,
        ],
        [
            'non-AXI4 family member',
            sub {
                my $source = sample_ar_driver_ppif();
                $source =~ s/\(profile axi4\)/(profile axi5)/;
                return $source;
            },
            qr/profile must be axi4 in this slice/,
        ],
        [
            'wrong role',
            sub {
                my $source = sample_ar_driver_ppif();
                $source =~ s/\(role manager-to-subordinate\)/(role subordinate-to-manager)/;
                return $source;
            },
            qr/role must be manager-to-subordinate/,
        ],
        [
            'missing channel block',
            sub {
                my $source = sample_ar_driver_ppif();
                $source =~ s/\n    \(channel\n.*?\(done ar_done\)\)\)/)/s;
                return $source;
            },
            qr/missing required \(channel \.\.\.\) clause/,
        ],
        [
            'missing reset block',
            sub {
                my $source = sample_ar_driver_ppif();
                $source =~ s/\n    \(reset \([^\n]+\)\)//;
                return $source;
            },
            qr/missing required \(reset \.\.\.\) clause/,
        ],
        [
            'unsupported address width',
            sub {
                my $source = sample_ar_driver_ppif();
                $source =~ s/\(address cmd_araddr width 32\)/(address cmd_araddr width 16)/;
                return $source;
            },
            qr/command\.address\.width must be 32 in this slice/,
        ],
        [
            'duplicate public signal',
            sub {
                my $source = sample_ar_driver_ppif();
                $source =~ s/\(done ar_done\)/(done arvalid)/;
                return $source;
            },
            qr/duplicates interface\/internal signal 'arvalid'/,
        ],
        [
            'invalid command identifier',
            sub {
                my $source = sample_ar_driver_ppif();
                $source =~ s/\(start ar_cmd_valid\)/(start 9bad)/;
                return $source;
            },
            qr/field 'command\.start' must be an ISF identifier/,
        ],
        [
            'unsupported object clause',
            sub {
                my $source = sample_ar_driver_ppif();
                $source =~ s/\n    \(channel/\n    (queue depth 1)\n    (channel/;
                return $source;
            },
            qr/unsupported clause '\(queue \.\.\.\)'/,
        ],
        [
            'malformed source anchor',
            sub {
                my $source = sample_ar_driver_ppif();
                $source =~ s/ \(page 279\)//;
                return $source;
            },
            qr/\(anchor \.\.\.\) requires \(page \.\.\.\)/,
        ],
        [
            'duplicate AR object',
            sub {
                return append_intent_object(
                    sample_ar_driver_ppif(),
                    minimal_address_driver_object('axi-ar-driver', 'duplicate_ar', 'dup_ar'),
                );
            },
            qr/supports exactly one \(axi-ar-driver \.\.\.\) object/,
        ],
        [
            'mixed AR and AW objects',
            sub {
                return append_intent_object(
                    sample_ar_driver_ppif(),
                    minimal_address_driver_object('axi-aw-driver', 'mixed_aw', 'mix_aw'),
                );
            },
            qr/cannot mix \(axi-ar-driver \.\.\.\) with other intent objects/,
        ],
        [
            'profile alias',
            sub { return sample_ar_driver_ppif(); },
            qr/\(axi-ar-driver \.\.\.\) remains unsupported/,
            'axi-ar-driver.axi',
        ],
    );

    for my $field (
        [address => 'cmd_araddr', 32, 16], [id => 'cmd_arid', 4, 3],
        [length => 'cmd_arlen', 8, 7], [size => 'cmd_arsize', 3, 2],
        [burst => 'cmd_arburst', 2, 1], [address => 'araddr', 32, 16],
        [id => 'arid', 4, 3], [length => 'arlen', 8, 7],
        [size => 'arsize', 3, 2], [burst => 'arburst', 2, 1],
    ) {
        my ($name, $signal, $expected, $bad) = @$field;
        my $side = $signal =~ /^cmd_/ ? 'command' : 'channel';
        push @cases, [
            "$side $name width",
            sub {
                my $source = sample_ar_driver_ppif();
                $source =~ s/\($name \Q$signal\E width $expected\)/($name $signal width $bad)/;
                return $source;
            },
            qr/\Q$side.$name.width must be $expected in this slice\E/,
        ];
    }

    for my $case (@cases) {
        my ($label, $build_source, $pattern, $source_label) = @$case;
        my $ok = eval {
            FSM::Adapter::IAL2::PPIF->new()->parse_source($build_source->(), $source_label // "$label.ppif");
            1;
        };
        ok(!$ok, "$label is rejected");
        like($@, $pattern, "$label diagnostic is targeted");
    }
};

subtest 'CLI checks, semantic export, schedule report, outdir, and verify-hdl use the public AR driver path' => sub {
    my $check = run_json_command('./bin/fsmgen', '--quiet', '--strict', '--check', '--json', sample_ar_driver_ppif_path());
    ok($check->{success}, 'strict check JSON succeeds for AXI AR driver PPIF');
    is($check->{result}{module_name}, 'axi_ar_driver', 'check JSON reports generated module name');
    is($check->{support_accounting}{entry_id}, 'intent.ppif_axi_ar_driver', 'check JSON matches AXI AR driver support accounting');
    is($check->{support_accounting}{source_kind}, 'ppif', 'check JSON reports PPIF source kind');

    my $semantic = run_json_command('./bin/fsmgen', '--quiet', '--strict', '--emit-semantic-json', sample_ar_driver_ppif_path());
    ok($semantic->{success}, 'strict semantic JSON succeeds for AXI AR driver PPIF');
    is($semantic->{generation_result_snapshot}{summary}{module_name}, 'axi_ar_driver', 'semantic JSON reports generated module name');
    is($semantic->{generation_result_snapshot}{summary}{source_root_kind}, 'fsm', 'semantic JSON reports generated FSM source root');
    is($semantic->{support_accounting}{entry_id}, 'intent.ppif_axi_ar_driver', 'semantic JSON matches AXI AR driver support accounting');

    my $schedule = run_json_command('./bin/fsmgen', '--quiet', '--emit-schedule-json', sample_ar_driver_ppif_path());
    is($schedule->{schema}, 'fsmgen.ial2.protocol_intent.axi_ar_driver.v1', 'schedule/report JSON exposes the AXI AR driver schema');
    is($schedule->{generated_artifacts}{ial1}{name}, 'axi_ar_driver.isf', 'schedule/report JSON exposes generated IAL1 artifact');
    is_deeply($schedule->{generated_artifacts}{ial0}{files}, ['axi_ar_driver.fsm'], 'schedule/report JSON exposes generated IAL0 artifact');

    my $tempdir = tempdir(CLEANUP => 1);
    my $outdir = File::Spec->catdir($tempdir, 'out');
    my $hdl = File::Spec->catfile($tempdir, 'axi_ar_driver.sv');
    my ($success, undef, undef, undef, $stderr) = run(
        command => ['./bin/fsmgen', '--quiet', '--outdir', $outdir, '--output', $hdl, sample_ar_driver_ppif_path()],
    );
    ok($success, 'AXI AR driver PPIF emits HDL and review artifacts through --outdir');
    is(join('', @{$stderr || []}), '', 'outdir generation keeps stderr clean');
    ok(-f File::Spec->catfile($outdir, 'axi_ar_driver.isf'), 'outdir contains generated AR driver IAL1 artifact');
    ok(-f File::Spec->catfile($outdir, 'axi_ar_driver.fsm'), 'outdir contains generated AR driver IAL0 artifact');
    ok(-f $hdl, 'outdir command emits selected HDL output');
    like(slurp($hdl), qr/\bmodule\s+axi_ar_driver\b/, 'generated HDL contains the AXI AR driver module');

    my ($verify_ok, undef, undef, $verify_stdout, undef) = run(
        command => ['./bin/fsmgen', '--verify-hdl', sample_ar_driver_ppif_path()],
    );
    ok($verify_ok, 'AXI AR driver PPIF passes --verify-hdl external validation');
    like(join('', @{$verify_stdout || []}), qr/verilator_lint: PASS/, 'AXI AR driver HDL passes verilator lint');
    like(join('', @{$verify_stdout || []}), qr/yosys_synthesis: PASS/, 'AXI AR driver HDL passes Yosys synthesis');
};

subtest 'generated HDL accepts exactly one AR transfer per accepted command' => sub {
    my $tempdir = tempdir(CLEANUP => 1);
    my $hdl = File::Spec->catfile($tempdir, 'axi_ar_driver.sv');
    my $testbench = File::Spec->catfile($tempdir, 'axi_ar_driver_cardinality_tb.sv');
    my $obj_dir = File::Spec->catdir($tempdir, 'obj_cardinality');

    my ($generate_ok, undef, undef, undef, $generate_stderr) = run(
        command => [
            './bin/fsmgen', '--quiet', '--strict', '--output', $hdl,
            sample_ar_driver_ppif_path(),
        ],
    );
    ok($generate_ok, 'public AXI AR driver source emits HDL for cardinality simulation');
    is(join('', @{$generate_stderr || []}), '', 'cardinality HDL generation keeps stderr clean');

    write_file($testbench, <<'SV');
module axi_ar_driver_cardinality_tb;
  logic clk = 0;
  logic rst_n = 0;
  logic ar_cmd_valid = 0;
  logic [31:0] cmd_araddr = 0;
  logic [3:0] cmd_arid = 0;
  logic [7:0] cmd_arlen = 0;
  logic [2:0] cmd_arsize = 0;
  logic [1:0] cmd_arburst = 0;
  logic arready = 0;
  wire arvalid;
  wire [31:0] araddr;
  wire [3:0] arid;
  wire [7:0] arlen;
  wire [2:0] arsize;
  wire [1:0] arburst;
  wire ar_busy;
  wire ar_done;
  integer handshakes = 0;
  integer done_pulses = 0;
  integer wait_cycles = 0;
  logic previous_done = 0;
  logic [48:0] expected_payload = 0;

  axi_ar_driver dut (.*);
  always #5 clk = ~clk;

  always @(posedge clk) begin
    if (rst_n && arvalid && arready) begin
      if ({araddr, arid, arlen, arsize, arburst} !== expected_payload)
        $fatal(1, "accepted AR payload differs from admitted command");
      handshakes <= handshakes + 1;
    end
    if (rst_n && ar_done)
      done_pulses <= done_pulses + 1;
    if (rst_n && ar_done && previous_done)
      $fatal(1, "ar_done remained high for more than one cycle");
    previous_done <= rst_n && ar_done;
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
      cmd_araddr = addr;
      cmd_arid = id;
      cmd_arlen = len;
      cmd_arsize = size;
      cmd_arburst = burst;
      expected_payload = {addr, id, len, size, burst};
      ar_cmd_valid = 1;
      @(negedge clk);
      ar_cmd_valid = 0;
    end
  endtask

  initial begin
    repeat (2) @(negedge clk);
    if (arvalid || ar_busy || ar_done)
      $fatal(1, "idle reset did not hold outputs/status low");
    rst_n = 1;
    repeat (2) @(negedge clk);

    arready = 1;
    pulse_command(32'h1020_3040, 4'h3, 8'h07, 3'h2, 2'h1);
    repeat (12) @(negedge clk);
    if (handshakes != 1 || done_pulses != 1)
      $fatal(1, "continuous-ready expected one transfer/done, got %0d/%0d", handshakes, done_pulses);
    if (arvalid || ar_busy)
      $fatal(1, "continuous-ready did not return valid/busy low");

    arready = 0;
    pulse_command(32'h5566_7788, 4'hA, 8'h11, 3'h4, 2'h2);
    wait_cycles = 0;
    while (!arvalid && wait_cycles < 8) begin
      @(negedge clk);
      wait_cycles = wait_cycles + 1;
    end
    if (!arvalid)
      $fatal(1, "stalled command never raised ARVALID");

    repeat (4) begin
      @(negedge clk);
      if (!arvalid || !ar_busy)
        $fatal(1, "stalled case dropped valid/busy");
      if ({araddr, arid, arlen, arsize, arburst} !==
          {32'h5566_7788, 4'hA, 8'h11, 3'h4, 2'h2})
        $fatal(1, "stalled case changed AR payload");
      cmd_araddr = cmd_araddr + 32'h1111;
      cmd_arid = cmd_arid + 1'b1;
      cmd_arlen = cmd_arlen + 1'b1;
      cmd_arsize = cmd_arsize + 1'b1;
      cmd_arburst = cmd_arburst + 1'b1;
    end

    ar_cmd_valid = 1;
    @(negedge clk);
    ar_cmd_valid = 0;

    arready = 1;
    @(negedge clk);
    arready = 0;
    repeat (12) @(negedge clk);
    if (handshakes != 2 || done_pulses != 2)
      $fatal(1, "one-cycle-ready expected second transfer/done, totals %0d/%0d", handshakes, done_pulses);
    if (arvalid || ar_busy)
      $fatal(1, "one-cycle-ready did not return valid/busy low");

    arready = 0;
    pulse_command(32'hCAFE_1000, 4'h6, 8'h22, 3'h1, 2'h3);
    wait_cycles = 0;
    while (!arvalid && wait_cycles < 8) begin
      @(negedge clk);
      wait_cycles = wait_cycles + 1;
    end
    if (!arvalid || !ar_busy)
      $fatal(1, "reset-cancel command never became active");
    rst_n = 0;
    repeat (2) @(negedge clk);
    if (arvalid || ar_busy || ar_done)
      $fatal(1, "active reset did not cancel valid/busy/done");
    rst_n = 1;
    repeat (8) @(negedge clk);
    if (handshakes != 2 || done_pulses != 2)
      $fatal(1, "reset-canceled request produced a transfer or late done");

    arready = 0;
    pulse_command(32'hABCD_0040, 4'hC, 8'h03, 3'h2, 2'h1);
    wait_cycles = 0;
    while (!arvalid && wait_cycles < 8) begin
      @(negedge clk);
      wait_cycles = wait_cycles + 1;
    end
    arready = 1;
    @(negedge clk);
    arready = 0;
    repeat (12) @(negedge clk);
    if (handshakes != 3 || done_pulses != 3)
      $fatal(1, "post-reset request totals expected 3/3, got %0d/%0d", handshakes, done_pulses);
    if (arvalid || ar_busy || ar_done)
      $fatal(1, "post-reset request did not finish idle");

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
            '-j', '1', '--top-module', 'axi_ar_driver_cardinality_tb',
            '--Mdir', $obj_dir, $hdl, $testbench,
        ],
    );
    ok($compile_ok, 'Verilator builds the generated AR cardinality harness')
        or diag(join('', @{$compile_stdout || []}), join('', @{$compile_stderr || []}));

    return unless $compile_ok;

    my $binary = File::Spec->catfile($obj_dir, 'Vaxi_ar_driver_cardinality_tb');
    ok(-x $binary, 'Verilator cardinality harness binary exists');
    my ($run_ok, undef, undef, $run_stdout, $run_stderr) = run(command => [$binary]);
    ok($run_ok, 'generated AR driver cardinality simulation passes')
        or diag(join('', @{$run_stdout || []}), join('', @{$run_stderr || []}));
    like(
        join('', @{$run_stdout || []}),
        qr/PASS handshakes=3 done_pulses=3/,
        'continuous-ready, stalled, and post-reset requests each accept and complete exactly once',
    );
};

done_testing();

sub sample_ar_driver_ppif_path {
    return File::Spec->catfile($FindBin::Bin, '..', 'ppif', 'axi_ar_driver.ppif');
}

sub sample_ar_driver_ppif {
    return slurp(sample_ar_driver_ppif_path());
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

sub append_intent_object {
    my ($source, $object) = @_;
    $source =~ s/\)\s*\z// or die 'sample PPIF root is not closed';
    return "$source\n  $object)\n";
}

sub minimal_address_driver_object {
    my ($head, $name, $prefix) = @_;
    return "($head $name\n"
        . "    (role manager-to-subordinate)\n"
        . "    (clock ${prefix}_clk)\n"
        . "    (reset (${prefix}_rst_n active_low async))\n"
        . "    (command\n"
        . "      (start ${prefix}_cmd_valid)\n"
        . "      (address ${prefix}_cmd_addr width 32)\n"
        . "      (id ${prefix}_cmd_id width 4)\n"
        . "      (length ${prefix}_cmd_len width 8)\n"
        . "      (size ${prefix}_cmd_size width 3)\n"
        . "      (burst ${prefix}_cmd_burst width 2)\n"
        . "      (ready ${prefix}_ready))\n"
        . "    (channel\n"
        . "      (valid ${prefix}_valid)\n"
        . "      (address ${prefix}_addr width 32)\n"
        . "      (id ${prefix}_id width 4)\n"
        . "      (length ${prefix}_len width 8)\n"
        . "      (size ${prefix}_size width 3)\n"
        . "      (burst ${prefix}_burst width 2)\n"
        . "      (busy ${prefix}_busy)\n"
        . "      (done ${prefix}_done)))\n";
}
