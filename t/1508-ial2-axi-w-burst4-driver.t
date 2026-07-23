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

subtest 'adapter report and schedule expose the exact fixed-four W driver' => sub {
    ok(-f sample_path(), 'tracked runnable AXI W burst4 driver sample exists');
    my $result = FSM::Adapter::IAL2::PPIF->new()->parse_file(sample_path());

    is($result->{layer}, 'IAL2', 'result stays at the IAL2 generation boundary');
    is($result->{kind}, 'protocol_intent.axi_w_burst4_driver', 'result kind is exact');
    is($result->{mode}, 'burst4-driver', 'result mode is exact');
    is($result->{report}{schema}, 'fsmgen.ial2.protocol_intent.axi_w_burst4_driver.v1', 'report schema is exact');
    is($result->{report}{source_object}{id}, 'axi-w-burst4-driver', 'source object is exact');
    is($result->{report}{source_object}{intent_name}, 'axi_w_burst4_driver', 'intent name is retained');
    is_deeply(
        [map { [$_->{section}, $_->{page}] } @{$result->{report}{source_object}{anchors}}],
        [
            ['A2.3', '29'],
            ['A2.3.1', '30'],
            ['A2.3.2.1', '31'],
            ['A3.1.2', '44'],
            ['A3.2.1', '53'],
            ['A3.2.1.1', '54'],
            ['B1.1.2', '277'],
        ],
        'all seven selected Issue L anchors are ordered and retained',
    );
    is_deeply(
        $result->{report}{target_protocol},
        {
            profile => 'axi4',
            object  => 'axi-w-burst4-driver',
            role    => 'manager-to-subordinate',
        },
        'target profile/object/role are exact',
    );

    my $isf = $result->{generated_ial1}{text};
    is($result->{generated_ial1}{name}, 'axi_w_burst4_driver.isf', 'generated IAL1 name is exact');
    like($isf, qr/\A\(actor axi_w_burst4_driver\b/, 'generated IAL1 actor name is exact');
    for my $index (0 .. 3) {
        like($isf, qr/\(input cmd_wdata$index \(width 32\)\)/, "data$index input is exact");
        like($isf, qr/\(input cmd_wstrb$index \(width 4\)\)/, "strobe$index input is exact");
    }
    for my $output (qw(wvalid wlast w_busy w_beat_done w_done)) {
        like($isf, qr/\(output \Q$output\E\)/, "$output output is exact");
    }
    like($isf, qr/\(output wdata \(width 32\)\)/, 'WDATA output width is exact');
    like($isf, qr/\(output wstrb \(width 4\)\)/, 'WSTRB output width is exact');
    like($isf, qr/\(output w_beat_index \(width 2\)\)/, 'beat index output width is exact');
    unlike($isf, qr/\bdata0_q\b|\bstrb0_q\b/, 'beat zero uses driven storage without dead private copies');
    like($isf, qr/\(rule admit \(& \(! active_q\) w_cmd_valid\)/, 'admission is idle-only');
    like($isf, qr/\(set wdata cmd_wdata0\)/, 'admission captures beat zero directly into WDATA');
    like($isf, qr/\(set data3_q cmd_wdata3\)/, 'admission captures the final private tuple');
    like($isf, qr/\(rule accept_beat2 .*?\(set wlast 1\)/s, 'beat two acceptance presents final WLAST high');
    like($isf, qr/\(rule accept_final .*?\(set wvalid 0\).*?\(set w_done 1\)/s, 'final acceptance retires valid and pulses done');
    like($isf, qr/WLAST must be high only on fixed-four beat index 3/, 'WLAST assertion is retained');

    my $schedule = $result->{generated_ial1_schedule_report};
    is($schedule->{port_count}, 18, 'schedule has eighteen ports');
    is($schedule->{inputs}, 10, 'schedule has ten inputs');
    is($schedule->{outputs}, 8, 'schedule has eight outputs');
    is($schedule->{state_count}, 0, 'schedule has zero procedural states');
    is_deeply($schedule->{compile_issues}, [], 'schedule has no compile issues');
    is_deeply(
        [map { [$_->{name}, $_->{assignments}] } @{$schedule->{dt_blocks}}],
        [
            ['admit', 13],
            ['accept_beat0', 6],
            ['accept_beat1', 6],
            ['accept_beat2', 6],
            ['accept_final', 6],
            ['clear_beat_done', 1],
            ['clear_done', 1],
        ],
        'seven decision-tree assignment counts are exact',
    );
    is_deeply(
        [sort map { $_->{name} } @{$schedule->{inferred_storage}}],
        [qw(beat_index_q can_accept data1_q data2_q data3_q strb1_q strb2_q strb3_q)],
        'schedule exposes seven declared stores plus assertion can-accept state',
    );
    is_deeply(
        [map { join(':', $_->{winner}, $_->{loser}, $_->{target}) } @{$schedule->{priority_resolutions}}],
        [
            'accept_beat0:clear_beat_done:w_beat_done',
            'accept_beat1:clear_beat_done:w_beat_done',
            'accept_beat2:clear_beat_done:w_beat_done',
            'accept_final:clear_beat_done:w_beat_done',
            'accept_final:clear_done:w_done',
        ],
        'five event-clear priority resolutions are exact',
    );

    is_deeply(
        [sort keys %{$result->{generated_ial0}{files}}],
        ['axi_w_burst4_driver.fsm'],
        'result exposes one generated IAL0 FSM',
    );
    like($result->{generated_ial0}{files}{'axi_w_burst4_driver.fsm'}, qr/\(\?fsm:axi_w_burst4_driver\b/, 'generated IAL0 FSM name is exact');

    my $policy = $result->{report}{fixed_burst_policy};
    is_deeply($policy->{last_sequence}, [0, 0, 0, 1], 'report fixes WLAST sequence');
    is($policy->{payload_authoring}, 'explicit_four_tuple_fields', 'report fixes explicit payload authoring');
    is($policy->{beat_zero_storage}, 'driven_wdata_wstrb_registers', 'report fixes beat-zero storage');
    is($policy->{beat_count}, 4, 'report fixes four transfers');
    is($policy->{beat_index_width}, 2, 'report fixes two-bit index');
    ok($policy->{all_zero_strobe_allowed}, 'report preserves all-zero strobe legality');
    is($result->{report}{driver_policy}{beat_event}, 'level_high_each_accepted_cycle_with_index', 'report fixes adjacent event semantics');
    is($result->{report}{generated_artifacts}{hdl_entry}{entry_artifact}, 'axi_w_burst4_driver.fsm', 'report selects the FSM as HDL entry');
    is($result->{report}{layering}{direct_ial2_to_ial0}, 0, 'lowering remains IAL2 through generated IAL1');
    is_deeply($result->{report}{enforced_static_rules}, enforced_rules(), 'all thirteen enforced strings are exact and ordered');
    is_deeply(
        [map { $_->{id} } @{$result->{report}{unsupported_residue}}],
        residue_ids(),
        'all thirteen residue ids are exact and ordered',
    );

    my $rebound = FSM::Adapter::IAL2::PPIF->new()->parse_source(
        replace_once(
            replace_once(sample_text(), '(beat-done w_beat_done)', '(beat-done burst_beat_event)'),
            '(done w_done)',
            '(done burst_complete)',
        ),
        'rebound-events.ppif',
    );
    is_deeply(
        [map { $_->{target} } @{$rebound->{report}{generated_ial1_schedule}{priority_resolutions}}],
        [qw(burst_beat_event burst_beat_event burst_beat_event burst_beat_event burst_complete)],
        'report priority targets honor legal event-output rebinding',
    );
};

subtest 'malformed and expanded AXI W burst4 contracts fail closed' => sub {
    my @cases = (
        ['non-AXI profile', '(profile axi4)', '(profile ahb)', qr/profile 'ahb' does not match \(axi-w-burst4-driver \.\.\.\)/, 'bad-profile.ppif'],
        ['non-AXI4 family', '(profile axi4)', '(profile axi3)', qr/profile must be axi4 in this slice/, 'axi3.ppif'],
        ['wrong role', '(role manager-to-subordinate)', '(role subordinate-to-manager)', qr/role must be manager-to-subordinate/, 'bad-role.ppif'],
        ['sync reset', '(reset (rst_n active_low async))', '(reset (rst_n active_low sync))', qr/reset must be asynchronous active-low/, 'sync-reset.ppif'],
        ['missing data3', "      (data3 cmd_wdata3 width 32)\n", '', qr/missing required \(data3 \.\.\.\) clause/, 'missing-data3.ppif'],
        ['packed payload', '(data0 cmd_wdata0 width 32)', '(data-bank cmd_wdata_bank width 128)', qr/unsupported clause '\(data-bank \.\.\.\)'/, 'packed.ppif'],
        ['fifth tuple', '(data3 cmd_wdata3 width 32)', "(data3 cmd_wdata3 width 32)\n      (data4 cmd_wdata4 width 32)", qr/unsupported clause '\(data4 \.\.\.\)'/, 'fifth.ppif'],
        ['duplicate private name', '(valid wvalid)', '(valid active_q)', qr/duplicates signal 'active_q'/, 'private-name.ppif'],
    );
    for my $index (0 .. 3) {
        push @cases,
            ["data$index width", "(data$index cmd_wdata$index width 32)", "(data$index cmd_wdata$index width 16)", qr/command\.data$index\.width must be 32/, "data$index.ppif"],
            ["strobe$index width", "(strobe$index cmd_wstrb$index width 4)", "(strobe$index cmd_wstrb$index width 2)", qr/command\.strobe$index\.width must be 4/, "strobe$index.ppif"];
    }
    push @cases,
        ['driven data width', '(data wdata width 32)', '(data wdata width 16)', qr/channel\.data\.width must be 32/, 'wdata.ppif'],
        ['driven strobe width', '(strobe wstrb width 4)', '(strobe wstrb width 2)', qr/channel\.strobe\.width must be 4/, 'wstrb.ppif'],
        ['beat index width', '(beat-index w_beat_index width 2)', '(beat-index w_beat_index width 3)', qr/channel\.beat_index\.width must be 2/, 'index.ppif'];

    for my $case (@cases) {
        my ($label, $from, $to, $pattern, $source_label) = @$case;
        my $accepted = eval {
            FSM::Adapter::IAL2::PPIF->new()->parse_source(
                replace_once(sample_text(), $from, $to),
                $source_label,
            );
            1;
        };
        ok(!$accepted, "$label is rejected");
        like($@, $pattern, "$label diagnostic is targeted");
    }

    my @structural_cases = (
        [
            'duplicate driver object',
            sub { append_root_clause(sample_text(), second_driver_clause()) },
            qr/supports exactly one \(axi-w-burst4-driver \.\.\.\) object/,
            'duplicate.ppif',
        ],
        [
            'mixed burst4 and single W drivers',
            sub { append_root_clause(sample_text(), single_w_driver_clause()) },
            qr/cannot mix \(axi-w-burst4-driver \.\.\.\) with other intent objects/,
            'mixed.ppif',
        ],
        [
            'profile alias',
            sub { sample_text() },
            qr/\(axi-w-burst4-driver \.\.\.\) remains unsupported for the first profile-alias implementation/,
            'burst4.axi',
        ],
    );
    for my $case (@structural_cases) {
        my ($label, $builder, $pattern, $source_label) = @$case;
        my $accepted = eval {
            FSM::Adapter::IAL2::PPIF->new()->parse_source($builder->(), $source_label);
            1;
        };
        ok(!$accepted, "$label is rejected");
        like($@, $pattern, "$label diagnostic is targeted");
    }
};

subtest 'public CLI, support, artifacts, Verilator, and Yosys use the burst4 path' => sub {
    my $check = run_json_command('./bin/fsmgen', '--quiet', '--strict', '--check', '--json', sample_path());
    ok($check->{success}, 'strict check JSON succeeds');
    is($check->{result}{module_name}, 'axi_w_burst4_driver', 'check reports exact module');
    is($check->{result}{signal_count}, 30, 'check reports thirty signals');
    is($check->{result}{state_count}, 0, 'check reports zero states');
    is($check->{support_accounting}{entry_id}, 'intent.ppif_axi_w_burst4_driver', 'check matches support accounting');

    my $schedule = run_json_command('./bin/fsmgen', '--quiet', '--emit-schedule-json', sample_path());
    is($schedule->{schema}, 'fsmgen.ial2.protocol_intent.axi_w_burst4_driver.v1', 'schedule JSON exposes schema');
    is($schedule->{generated_ial1_schedule}{port_count}, 18, 'schedule JSON exposes port count');
    is($schedule->{generated_ial1_schedule}{state_count}, 0, 'schedule JSON exposes zero-state shape');
    is_deeply($schedule->{generated_artifacts}{ial0}{files}, ['axi_w_burst4_driver.fsm'], 'schedule JSON exposes one FSM');

    my $semantic = run_json_command('./bin/fsmgen', '--quiet', '--strict', '--emit-semantic-json', sample_path());
    ok($semantic->{success}, 'strict semantic JSON succeeds');
    is($semantic->{generation_result_snapshot}{summary}{module_name}, 'axi_w_burst4_driver', 'semantic JSON reports module');
    is($semantic->{generation_result_snapshot}{summary}{source_root_kind}, 'fsm', 'semantic JSON reports FSM root');
    is($semantic->{support_accounting}{entry_id}, 'intent.ppif_axi_w_burst4_driver', 'semantic JSON matches support');

    my $tempdir = tempdir(CLEANUP => 1);
    my $outdir = File::Spec->catdir($tempdir, 'out');
    my $hdl = File::Spec->catfile($tempdir, 'axi_w_burst4_driver.sv');
    my ($emit_ok, undef, undef, undef, $emit_stderr) = run(
        command => ['./bin/fsmgen', '--quiet', '--strict', '--outdir', $outdir, '--output', $hdl, sample_path()],
    );
    ok($emit_ok, 'public source emits HDL and review artifacts');
    is(join('', @{$emit_stderr || []}), '', 'outdir generation keeps stderr clean');
    ok(-f File::Spec->catfile($outdir, 'axi_w_burst4_driver.isf'), 'outdir contains ISF');
    ok(-f File::Spec->catfile($outdir, 'axi_w_burst4_driver.fsm'), 'outdir contains FSM');
    like(slurp($hdl), qr/\bmodule\s+axi_w_burst4_driver\b/, 'generated HDL contains driver module');
    like(slurp($hdl), qr/WLAST must be high only on fixed-four beat index 3/, 'generated HDL retains WLAST assertion');

    my ($verify_ok, undef, undef, $verify_stdout, $verify_stderr) = run(
        command => ['./bin/fsmgen', '--verify-hdl', '--output', File::Spec->catfile($tempdir, 'verify.sv'), sample_path()],
    );
    ok($verify_ok, 'public source passes external HDL verification')
        or diag(join('', @{$verify_stdout || []}), join('', @{$verify_stderr || []}));
    my $verify_text = join('', @{$verify_stdout || []});
    like($verify_text, qr/verilator_lint: PASS/, 'Verilator lint passes');
    like($verify_text, qr/yosys_synthesis: PASS/, 'Yosys synthesis passes');
};

subtest 'generated HDL presents exact tuples, events, WLAST, reset, and cardinality' => sub {
    my $tempdir = tempdir(CLEANUP => 1);
    my $hdl = File::Spec->catfile($tempdir, 'axi_w_burst4_driver.sv');
    my $testbench = File::Spec->catfile($tempdir, 'axi_w_burst4_driver_tb.sv');
    my $obj_dir = File::Spec->catdir($tempdir, 'obj');
    my ($generate_ok, undef, undef, undef, $generate_stderr) = run(
        command => ['./bin/fsmgen', '--quiet', '--strict', '--output', $hdl, sample_path()],
    );
    ok($generate_ok, 'public source emits HDL for simulation');
    is(join('', @{$generate_stderr || []}), '', 'behavior generation keeps stderr clean');
    write_file($testbench, behavior_testbench());

    my ($compile_ok, undef, undef, $compile_stdout, $compile_stderr) = run(
        command => [
            'verilator', '--binary', '--timing', '--no-assert', '-Wno-fatal',
            '-j', '1', '--top-module', 'axi_w_burst4_driver_tb',
            '--Mdir', $obj_dir, $hdl, $testbench,
        ],
    );
    ok($compile_ok, 'Verilator builds the assertion-disabled generated-HDL harness')
        or diag(join('', @{$compile_stdout || []}), join('', @{$compile_stderr || []}));
    return unless $compile_ok;

    my $binary = File::Spec->catfile($obj_dir, 'Vaxi_w_burst4_driver_tb');
    ok(-x $binary, 'simulation binary exists');
    my ($run_ok, undef, undef, $run_stdout, $run_stderr) = run(command => [$binary]);
    ok($run_ok, 'generated-HDL behavior passes')
        or diag(join('', @{$run_stdout || []}), join('', @{$run_stderr || []}));
    like(
        join('', @{$run_stdout || []}),
        qr/PASS handshakes=14 beat=14 done=3 busy_ignored=1 reset_abort=1/,
        'exact completed/reset-aborted burst cardinality passes',
    );
};

done_testing();

sub sample_path { File::Spec->catfile($FindBin::Bin, '..', 'ppif', 'axi_w_burst4_driver.ppif') }
sub sample_text { slurp(sample_path()) }

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

sub second_driver_clause {
    my $source = sample_text();
    my $start = index($source, '  (axi-w-burst4-driver');
    die "failed to locate burst4 object\n" if $start < 0;
    my $object = substr($source, $start);
    $object =~ s/\)\s*\z// or die "failed to remove root close\n";
    $object =~ s/axi_w_burst4_driver/axi_w_burst4_driver_2/g;
    $object =~ s/\b(clk|rst_n|w_cmd_valid|cmd_wdata[0-3]|cmd_wstrb[0-3]|wready|wvalid|wdata|wstrb|wlast|w_busy|w_beat_done|w_done|w_beat_index)\b/${1}_2/g;
    return $object;
}

sub single_w_driver_clause {
    return <<'PPIF';
  (axi-w-driver extra_w_driver
    (role manager-to-subordinate)
    (clock extra_clk)
    (reset (extra_rst_n active_low async))
    (command
      (start extra_start)
      (data extra_cmd_data width 32)
      (strobe extra_cmd_strobe width 4)
      (ready extra_ready))
    (channel
      (valid extra_valid)
      (data extra_data width 32)
      (strobe extra_strobe width 4)
      (last extra_last)
      (busy extra_busy)
      (done extra_done)))
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

sub behavior_testbench {
    return slurp(File::Spec->catfile($FindBin::Bin, 'data', 'axi_w_burst4_driver_tb.svt'));
}

sub enforced_rules {
    return [
        'profile must be axi4, object must be axi-w-burst4-driver, and role must be manager-to-subordinate',
        'clock and reset are shared with one asynchronous active-low generated actor',
        'one idle command atomically captures four explicit data width 32 and strobe width 4 tuples',
        'WVALID asserts independently of WREADY and remains high through all four presented beats',
        'WDATA, WSTRB, WLAST, and the current beat index remain stable during every WREADY-low stall',
        'WLAST is low on beat indices 0 through 2 and high only on beat index 3',
        'exactly four WVALID and WREADY acceptances retire one admitted command',
        'all-zero and partial WSTRB values are legal on every beat',
        'beat done and beat index identify every accepted tuple including consecutive WREADY-high transfers',
        'final done coincides with accepted beat index 3 and clears busy and WVALID',
        'a one-cycle command while busy is ignored and no command queue is provided',
        'asynchronous reset aborts without fabricated beat or final events and recovery restarts at beat index 0',
        'lowering is IAL2 through one generated IAL1 actor into one generated IAL0 FSM, never direct IAL2-to-IAL0',
    ];
}

sub residue_ids {
    return [qw(
        axi_w_burst4_driver_aw_coordination_deferred
        axi_w_burst4_driver_b_response_completion_deferred
        axi_w_burst4_driver_address_attribute_coupling_deferred
        axi_w_burst4_driver_dynamic_general_bursts_deferred
        axi_w_burst4_driver_narrow_unaligned_wrap_deferred
        axi_w_burst4_driver_streaming_packed_payload_deferred
        axi_w_burst4_driver_capacity_core_integration_deferred
        axi_w_burst4_driver_outstanding_queueing_deferred
        axi_w_burst4_driver_transaction_interface_deferred
        axi_w_burst4_driver_profile_alias_deferred
        axi_w_burst4_driver_verification_output_deferred
        axi_w_burst4_driver_backend_variants_deferred
        axi_w_burst4_driver_other_protocols_unchanged
    )];
}
