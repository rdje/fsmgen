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

subtest 'adapter report and flat three-child composition preserve the selected contract' => sub {
    ok(-f sample_path(), 'tracked runnable AXI fixed-four write-request composition source exists');
    my $result = FSM::Adapter::IAL2::PPIF->new()->parse_file(sample_path());
    my $report = $result->{report};

    is($result->{layer}, 'IAL2', 'composition result stays at the IAL2 boundary');
    is($result->{kind}, 'protocol_intent.axi_write_burst4_request_composition', 'composition kind is exact');
    is($result->{mode}, 'write-burst4-request-composition', 'composition mode is exact');
    is($report->{schema}, 'fsmgen.ial2.protocol_intent.axi_write_burst4_request_composition.v1', 'report schema is exact');
    is($report->{source_object}{id}, 'axi-write-burst4-request-composition', 'source object identity is preserved');
    is($report->{source_object}{intent_name}, 'axi_write_burst4_request_composition', 'root intent name is preserved');
    is_deeply(
        [map { [$_->{section}, $_->{page}] } @{$report->{source_object}{anchors}}],
        [
            ['A3.2.1', 'A3-40'], ['A2.3', '29'], ['A2.3.1', '30'],
            ['A2.3.2.1', '31'], ['A3.1', '42'], ['A3.1.1', '43'],
            ['A3.1.2', '44'], ['A3.1.4', '46'], ['A3.2.1', '53'],
            ['A3.2.1.1', '54'], ['B1.1.2', '277'],
        ],
        'eleven selected source anchors remain ordered and exact',
    );
    is_deeply(
        $report->{target_protocol},
        { profile => 'axi4', object => 'axi-write-burst4-request-composition', role => 'manager-to-subordinate' },
        'target protocol identity is exact',
    );
    is($report->{bindings}{command}{address}{width}, 32, 'admitted address width is pinned');
    is($report->{bindings}{command}{id}{width}, 4, 'admitted ID width is pinned');
    for my $index (0 .. 3) {
        is($report->{bindings}{command}{"data$index"}{width}, 32, "command data$index width is pinned");
        is($report->{bindings}{command}{"strobe$index"}{width}, 4, "command strobe$index width is pinned");
    }
    is($report->{bindings}{status}{beat_done}, 'write_beat_done', 'beat event binding is direct and exact');
    is_deeply($report->{bindings}{status}{beat_index}, { name => 'write_beat_index', width => 2 }, 'beat index binding is exact');
    is($report->{bindings}{status}{done}, 'write_done', 'request completion binding is exact');
    is_deeply(
        $report->{fixed_four_request_policy},
        {
            address_width => 32, address_alignment_bytes => 4, address_span_bytes => 16,
            four_kib_contained => JSON::PP::true, id_width => 4, data_width => 32,
            strobe_width => 4, all_zero_strobe_allowed => JSON::PP::true,
            awlen => 3, awsize => 2, awburst => 1, awburst_name => 'INCR',
            beat_count => 4, beat_index_width => 2, last_sequence => [0, 0, 0, 1],
            payload_authoring => 'explicit_four_tuple_fields',
            payload_capture => 'atomic_on_idle_command',
            beat_event => 'direct_w_child_accepted_transfer',
            request_completion => 'both_aw_and_final_w_accepted',
        },
        'fixed-four request policy is complete and exact',
    );
    is_deeply(
        $report->{coordinator},
        {
            actor_name => 'axi_write_burst4_request_coordinator',
            admission_policy => 'idle_level_sampled', queue_depth => 0,
            payload_capture => 'atomic_on_admission',
            alignment_guard => 'four_byte_aligned_and_16_byte_span_within_4kib',
            alignment_assertion => 'admissible_idle_attempt_implies_fixed_four_boundary_legal',
            child_start_policy => 'one_registered_pulse_each',
            completion_history => 'remember_aw_done_and_w_done_independently',
            completion_policy => 'one_pulse_after_aw_and_final_w_accept',
            beat_status_policy => 'direct_from_unchanged_w_burst4_child',
            response_completion => JSON::PP::false,
        },
        'coordinator policy is exact',
    );
    is_deeply(
        [map { [$_->{role}, $_->{instance_name}] } @{$report->{children}}],
        [['aw-driver', 'aw_driver'], ['w-driver', 'w_driver'], ['coordinator', 'coordinator']],
        'three generated children are flat, ordered, and named',
    );
    is($report->{generated_schedules}{count}, 3, 'three child schedule reports are exposed');
    is_deeply([map { $_->{report}{compile_issues} } @{$report->{generated_schedules}{items}}], [[], [], []], 'all schedules are lowering-clean');

    my ($coordinator_item) = grep { $_->{object_name} eq 'axi_write_burst4_request_coordinator' } @{$result->{generated_ial1}{items}};
    my $coordinator_isf = $coordinator_item->{text};
    like($coordinator_isf, qr/\(rule admit\s+\(& \(! active_q\) \(! aw_busy_i\) \(! w_busy_i\) write_cmd_valid/s, 'admission requires aggregate and both children idle');
    like($coordinator_isf, qr/\(! cmd_awaddr\[0\]\) \(! cmd_awaddr\[1\]\).*\(! \(& cmd_awaddr\[11\].*cmd_awaddr\[3\]\)\).*\(! \(& cmd_awaddr\[11\].*cmd_awaddr\[2\]\)\)/s, 'renderer-safe aligned 16-byte 4-KiB predicate is generated');
    like($coordinator_isf, qr/fixed-four AXI INCR write request must be four-byte aligned and remain within 4 KiB/, 'coordinator carries the selected admission assertion');
    my ($schedule) = grep { $_->{object_name} eq 'axi_write_burst4_request_coordinator' } @{$report->{generated_schedules}{items}};
    is($schedule->{report}{port_count}, 29, 'coordinator has twenty-nine ports');
    is($schedule->{report}{state_count}, 0, 'coordinator remains rule-only');
    is_deeply(
        [map { [$_->{name}, $_->{assignments}] } @{$schedule->{report}{dt_blocks}}],
        [['admit', 16], ['clear_child_starts', 2], ['latch_aw', 1], ['latch_w', 1], ['finish_join', 5], ['clear_done', 1]],
        'six coordinator rule DTs retain exact assignment counts',
    );
    is_deeply(
        [map { [$_->{winner}, $_->{loser}, $_->{target}] } @{$schedule->{report}{priority_resolutions}}],
        [
            ['admit', 'clear_child_starts', 'aw_cmd_valid_i'],
            ['finish_join', 'latch_aw', 'aw_seen_q'],
            ['admit', 'clear_child_starts', 'w_cmd_valid_i'],
            ['finish_join', 'latch_w', 'w_seen_q'],
            ['finish_join', 'clear_done', 'write_done'],
        ],
        'five realized coordinator priorities are exact',
    );
    is_deeply(
        $report->{generated_artifacts}{ial0}{files},
        [qw(axi_aw_driver.fsm axi_w_burst4_driver.fsm axi_write_burst4_request_composition.fsm axi_write_burst4_request_coordinator.fsm)],
        'three leaf FSMs plus one selected top are exact',
    );
    is(scalar(@{$report->{enforced_static_rules}}), 15, 'fifteen enforced static rules are exposed');
    is_deeply(
        [map { $_->{id} } @{$report->{unsupported_residue}}],
        [qw(
            axi_write_burst4_request_composition_b_response_full_transaction_deferred
            axi_write_burst4_request_composition_dynamic_burst_deferred
            axi_write_burst4_request_composition_narrow_unaligned_wrap_attributes_deferred
            axi_write_burst4_request_composition_packed_streaming_payload_deferred
            axi_write_burst4_request_composition_capacity_core_integration_deferred
            axi_write_burst4_request_composition_outstanding_queueing_deferred
            axi_write_burst4_request_composition_id_allocation_ordering_demux_deferred
            axi_write_burst4_request_composition_malformed_subordinate_recovery_deferred
            axi_write_burst4_request_composition_response_aggregation_output_banks_deferred
            axi_write_burst4_request_composition_transaction_interface_deferred
            axi_write_burst4_request_composition_profile_alias_deferred
            axi_write_burst4_request_composition_verification_output_deferred
            axi_write_burst4_request_composition_backend_variants_deferred
            axi_write_burst4_request_composition_other_protocols_unchanged
        )],
        'fourteen unsupported residue ids are ordered and exact',
    );

    my $top = $result->{generated_ial0}{files}{'axi_write_burst4_request_composition.fsm'};
    like($top, qr/\A\(\?top:axi_write_burst4_request_composition\b/, 'generated IAL0 entry is a structural top');
    like($top, qr/\(\?fsmc:aw_driver axi_aw_driver\)/, 'top directly instantiates unchanged AW');
    like($top, qr/\(\?fsmc:w_driver axi_w_burst4_driver\)/, 'top directly instantiates unchanged W-burst4');
    like($top, qr/\(\?fsmc:coordinator axi_write_burst4_request_coordinator\)/, 'top directly instantiates the join coordinator');
    like($top, qr/\(=8'd3 aw_driver\.cmd_awlen\)/, 'top fixes AWLEN to three');
    like($top, qr/\(=3'd2 aw_driver\.cmd_awsize\)/, 'top fixes AWSIZE to two');
    like($top, qr/\(=2'b01 aw_driver\.cmd_awburst\)/, 'top fixes AWBURST to INCR');
    like($top, qr/=write_beat_done>/, 'top exposes the unchanged W child beat event');
    like($top, qr/=write_beat_index>2/, 'top exposes the unchanged W child beat index');
};

subtest 'malformed and expanded write-request contracts fail closed' => sub {
    my @cases = (
        ['wrong root', sub { replace_once(sample_text(), '(protocol-platform-intent', '(wrong-root') }, qr/must start with \(protocol-platform-intent/, 'bad-root.ppif'],
        ['wrong profile family', sub { replace_once(sample_text(), '(profile axi4)', '(profile ahb)') }, qr/profile 'ahb' does not match \(axi-write-burst4-request-composition/, 'bad-profile.ppif'],
        ['non-AXI4 profile', sub { replace_once(sample_text(), '(profile axi4)', '(profile axi3)') }, qr/profile must be axi4 in this slice/, 'axi3.ppif'],
        ['wrong role', sub { replace_once(sample_text(), '(role manager-to-subordinate)', '(role subordinate-to-manager)') }, qr/role must be manager-to-subordinate/, 'bad-role.ppif'],
        ['synchronous reset', sub { replace_once(sample_text(), '(rst_n active_low async)', '(rst_n active_low sync)') }, qr/reset must be asynchronous active-low/, 'sync-reset.ppif'],
        ['active-high reset', sub { replace_once(sample_text(), '(rst_n active_low async)', '(rst_n active_high async)') }, qr/reset must be asynchronous active-low/, 'active-high.ppif'],
        ['duplicate command', sub { replace_once(sample_text(), "    (aw-channel\n", duplicate_command_clause() . "    (aw-channel\n") }, qr/duplicate \(command \.\.\.\) clause/, 'duplicate-command.ppif'],
        ['unknown clause', sub { replace_once(sample_text(), "    (status\n", "    (unknown value)\n    (status\n") }, qr/unsupported clause '\(unknown \.\.\.\)'/, 'unknown.ppif'],
        ['missing status', sub { without_status_clause() }, qr/missing required \(status \.\.\.\) clause/, 'missing-status.ppif'],
        ['missing W last', sub { my $s = sample_text(); $s =~ s/\n      \(last wlast\)// or die; $s }, qr/w-channel \.\.\.\) is missing required \(last \.\.\.\) clause/, 'missing-last.ppif'],
        ['missing beat event', sub { my $s = sample_text(); $s =~ s/\n      \(beat-done write_beat_done\)// or die; $s }, qr/status \.\.\.\) is missing required \(beat-done \.\.\.\) clause/, 'missing-beat.ppif'],
        ['dynamic metadata', sub { replace_once(sample_text(), '(strobe3 cmd_wstrb3 width 4))', "(strobe3 cmd_wstrb3 width 4)\n      (length cmd_awlen width 8))") }, qr/command \.\.\.\) has unsupported clause '\(length \.\.\.\)'/, 'dynamic.ppif'],
        ['nested child', sub { replace_once(sample_text(), "    (status\n", "    (axi-w-burst4-driver nested)\n    (status\n") }, qr/unsupported clause '\(axi-w-burst4-driver \.\.\.\)'/, 'nested.ppif'],
        ['mixed standalone AW', sub { append_root_clause(sample_text(), standalone_aw_clause()) }, qr/cannot mix \(axi-write-burst4-request-composition \.\.\.\) with other intent objects/, 'mixed.ppif'],
        ['multiple aggregate objects', sub { append_root_clause(sample_text(), second_composition_clause()) }, qr/supports exactly one \(axi-write-burst4-request-composition \.\.\.\) object/, 'duplicate-object.ppif'],
        ['duplicate public binding', sub { replace_once(sample_text(), '(done write_done)', '(done write_busy)') }, qr/duplicates signal 'write_busy'/, 'duplicate-signal.ppif'],
        ['generated collision', sub { replace_once(sample_text(), '(axi-write-burst4-request-composition axi_write_burst4_request_composition', '(axi-write-burst4-request-composition axi_aw_driver') }, qr/generated duplicate \.fsm artifact 'axi_aw_driver\.fsm'/, 'collision.ppif'],
        ['profile alias rejection', sub { sample_text() }, qr/\(axi-write-burst4-request-composition \.\.\.\) remains unsupported for the first profile-alias implementation/, 'composition.axi'],
    );

    my @width_cases = (
        ['command.address', '(address cmd_awaddr width 32)', '(address cmd_awaddr width 16)', qr/command\.address\.width must be 32/],
        ['command.id', '(id cmd_awid width 4)', '(id cmd_awid width 3)', qr/command\.id\.width must be 4/],
        (map { ["command.data$_", "(data$_ cmd_wdata$_ width 32)", "(data$_ cmd_wdata$_ width 16)", qr/command\.data$_\.width must be 32/] } 0 .. 3),
        (map { ["command.strobe$_", "(strobe$_ cmd_wstrb$_ width 4)", "(strobe$_ cmd_wstrb$_ width 2)", qr/command\.strobe$_\.width must be 4/] } 0 .. 3),
        ['aw.address', '(address awaddr width 32)', '(address awaddr width 16)', qr/aw_channel\.address\.width must be 32/],
        ['aw.id', '(id awid width 4)', '(id awid width 3)', qr/aw_channel\.id\.width must be 4/],
        ['aw.length', '(length awlen width 8)', '(length awlen width 7)', qr/aw_channel\.length\.width must be 8/],
        ['aw.size', '(size awsize width 3)', '(size awsize width 2)', qr/aw_channel\.size\.width must be 3/],
        ['aw.burst', '(burst awburst width 2)', '(burst awburst width 3)', qr/aw_channel\.burst\.width must be 2/],
        ['w.data', '(data wdata width 32)', '(data wdata width 16)', qr/w_channel\.data\.width must be 32/],
        ['w.strobe', '(strobe wstrb width 4)', '(strobe wstrb width 2)', qr/w_channel\.strobe\.width must be 4/],
        ['status.beat_index', '(beat-index write_beat_index width 2)', '(beat-index write_beat_index width 3)', qr/status\.beat_index\.width must be 2/],
    );
    for my $case (@width_cases) {
        my ($label, $from, $to, $pattern) = @$case;
        push @cases, ["wrong $label width", sub { replace_once(sample_text(), $from, $to) }, $pattern, "$label.ppif"];
    }
    for my $case (@cases) {
        my ($label, $builder, $pattern, $source_label) = @$case;
        my $accepted = eval { FSM::Adapter::IAL2::PPIF->new()->parse_source($builder->(), $source_label); 1 };
        ok(!$accepted, "$label is rejected");
        like($@, $pattern, "$label diagnostic is targeted");
    }
};

subtest 'CLI support accounting and external HDL use the public write-request path' => sub {
    my $check = run_json_command('./bin/fsmgen', '--quiet', '--strict', '--check', '--json', sample_path());
    ok($check->{success}, 'strict check JSON succeeds');
    is($check->{result}{module_name}, 'axi_write_burst4_request_composition', 'check JSON reports the top module');
    is($check->{result}{composition_child_count}, 3, 'check JSON reports three children');
    is($check->{result}{signal_count}, 29, 'check JSON reports twenty-nine public signals');
    is($check->{support_accounting}{entry_id}, 'intent.ppif_axi_write_burst4_request_composition', 'check JSON matches support accounting');

    my $schedule = run_json_command('./bin/fsmgen', '--quiet', '--emit-schedule-json', sample_path());
    is($schedule->{schema}, 'fsmgen.ial2.protocol_intent.axi_write_burst4_request_composition.v1', 'schedule JSON exposes aggregate schema');
    is($schedule->{generated_schedules}{count}, 3, 'schedule JSON exposes all three schedules');

    my $semantic = run_json_command('./bin/fsmgen', '--quiet', '--strict', '--emit-semantic-json', sample_path());
    ok($semantic->{success}, 'strict semantic JSON succeeds');
    is($semantic->{generation_result_snapshot}{summary}{source_root_kind}, 'top', 'semantic JSON identifies a top root');
    is($semantic->{semantic}{composition}{lane}, 'C4', 'semantic JSON identifies C4');
    is($semantic->{semantic}{module}{composition_net_count}, 66, 'semantic JSON reports sixty-six nets');
    is(scalar(@{$semantic->{semantic}{composition}{plan_snapshot}{links}}), 46, 'semantic JSON reports forty-six declared links');
    is($semantic->{semantic}{module}{composition_resolved_link_count}, 52, 'semantic JSON reports fifty-two resolved links');
    is($semantic->{support_accounting}{entry_id}, 'intent.ppif_axi_write_burst4_request_composition', 'semantic JSON matches support accounting');

    my $tempdir = tempdir(CLEANUP => 1);
    my $outdir = File::Spec->catdir($tempdir, 'out');
    my $hdl = File::Spec->catfile($tempdir, 'axi_write_burst4_request_composition.sv');
    my ($emit_ok, undef, undef, undef, $emit_stderr) = run(command => ['./bin/fsmgen', '--quiet', '--strict', '--outdir', $outdir, '--output', $hdl, sample_path()]);
    ok($emit_ok, 'public source emits HDL and review artifacts through --outdir');
    is(join('', @{$emit_stderr || []}), '', 'outdir generation keeps stderr clean');
    for my $artifact (qw(axi_aw_driver.isf axi_w_burst4_driver.isf axi_write_burst4_request_coordinator.isf axi_aw_driver.fsm axi_w_burst4_driver.fsm axi_write_burst4_request_coordinator.fsm axi_write_burst4_request_composition.fsm)) {
        ok(-f File::Spec->catfile($outdir, $artifact), "outdir contains $artifact");
    }
    like(slurp($hdl), qr/\bmodule\s+axi_write_burst4_request_composition\b/, 'generated HDL contains the structural top');
    like(slurp($hdl), qr/fixed-four AXI INCR write request must be four-byte aligned and remain within 4 KiB/, 'generated HDL retains the admission assertion');

    my ($verify_ok, undef, undef, $verify_stdout, $verify_stderr) = run(command => ['./bin/fsmgen', '--verify-hdl', '--output', File::Spec->catfile($tempdir, 'verify.sv'), sample_path()]);
    ok($verify_ok, 'composition passes external HDL verification') or diag(join('', @{$verify_stdout || []}), join('', @{$verify_stderr || []}));
    my $verify_text = join('', @{$verify_stdout || []});
    like($verify_text, qr/verilator_lint: PASS/, 'generated HDL passes Verilator lint');
    like($verify_text, qr/yosys_synthesis: PASS/, 'generated HDL passes Yosys synthesis');
};

subtest 'generated structural top joins AW and four W beats under both assertion modes' => sub {
    my $tempdir = tempdir(CLEANUP => 1);
    my $hdl = File::Spec->catfile($tempdir, 'axi_write_burst4_request_composition.sv');
    my $testbench = File::Spec->catfile($tempdir, 'axi_write_burst4_request_composition_tb.sv');
    my ($generate_ok, undef, undef, undef, $generate_stderr) = run(command => ['./bin/fsmgen', '--quiet', '--strict', '--output', $hdl, sample_path()]);
    ok($generate_ok, 'public source emits structural HDL for simulation');
    is(join('', @{$generate_stderr || []}), '', 'behavior HDL generation keeps stderr clean');
    write_file($testbench, behavior_testbench());

    for my $case (
        ['assertions disabled', ['--no-assert'], []],
        ['assertions enabled', ['--assert'], ['-DASSERTIONS_ON']],
    ) {
        my ($label, $assert_args, $define_args) = @$case;
        my $obj_dir = File::Spec->catdir($tempdir, $label =~ /enabled/ ? 'obj_assert' : 'obj_no_assert');
        my ($compile_ok, undef, undef, $compile_stdout, $compile_stderr) = run(command => [
            'verilator', '--binary', '--timing', @$assert_args, '-Wno-fatal', '-j', '1', @$define_args,
            '--top-module', 'axi_write_burst4_request_composition_tb', '--Mdir', $obj_dir, $hdl, $testbench,
        ]);
        ok($compile_ok, "Verilator builds the generated harness with $label") or diag(join('', @{$compile_stdout || []}), join('', @{$compile_stderr || []}));
        next unless $compile_ok;
        my $binary = File::Spec->catfile($obj_dir, 'Vaxi_write_burst4_request_composition_tb');
        ok(-x $binary, "$label simulation binary exists");
        my ($run_ok, undef, undef, $run_stdout, $run_stderr) = run(command => [$binary]);
        ok($run_ok, "generated structural-top behavior passes with $label") or diag(join('', @{$run_stdout || []}), join('', @{$run_stderr || []}));
        like(join('', @{$run_stdout || []}), qr/PASS aw=5 w=18 beat=18 done=4 illegal=2 busy_ignored=1 reset_abort=1/, "$label preserves legality, independent completion, reset, recovery, and exact cardinality");
    }
};

done_testing();

sub sample_path { File::Spec->catfile($FindBin::Bin, '..', 'ppif', 'axi_write_burst4_request_composition.ppif') }
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

sub without_status_clause {
    my $source = sample_text();
    my $start = index($source, "\n    (status\n");
    die "failed to locate status clause\n" if $start < 0;
    substr($source, $start) = "\n  ))\n";
    return $source;
}

sub duplicate_command_clause {
    return <<'PPIF';
    (command
      (start duplicate_start)
      (address duplicate_address width 32)
      (id duplicate_id width 4))
PPIF
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

sub second_composition_clause {
    my $source = sample_text();
    my $start = index($source, '  (axi-write-burst4-request-composition');
    die "failed to locate aggregate object\n" if $start < 0;
    my $object = substr($source, $start);
    $object =~ s/\)\s*\z// or die "failed to remove root close\n";
    $object =~ s/axi_write_burst4_request_composition/axi_write_burst4_request_composition_2/g;
    $object =~ s/\b(clk|rst_n|write_cmd_valid|cmd_awaddr|cmd_awid|cmd_wdata0|cmd_wdata1|cmd_wdata2|cmd_wdata3|cmd_wstrb0|cmd_wstrb1|cmd_wstrb2|cmd_wstrb3|awready|awvalid|awaddr|awid|awlen|awsize|awburst|wready|wvalid|wdata|wstrb|wlast|write_busy|write_beat_done|write_done|write_beat_index)\b/${1}_2/g;
    return $object;
}

sub run_json_command {
    my (@command) = @_;
    my ($success, undef, undef, $stdout, $stderr) = run(command => \@command);
    ok($success, "command succeeds: @command") or diag(join('', @{$stdout || []}), join('', @{$stderr || []}));
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
    return slurp(File::Spec->catfile($FindBin::Bin, 'data', 'axi_write_burst4_request_composition_tb.svt'));
}
