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
    ok(-f sample_path(), 'tracked runnable AXI full-read transaction composition source exists');
    my $result = FSM::Adapter::IAL2::PPIF->new()->parse_file(sample_path());
    my $report = $result->{report};

    is($result->{layer}, 'IAL2', 'composition result stays at the IAL2 boundary');
    is($result->{kind}, 'protocol_intent.axi_read_transaction_composition', 'composition kind is exact');
    is($result->{mode}, 'read-transaction-composition', 'composition mode is exact');
    is($report->{schema}, 'fsmgen.ial2.protocol_intent.axi_read_transaction_composition.v1', 'report schema is exact');
    is($report->{source_object}{id}, 'axi-read-transaction-composition', 'source object identity is preserved');
    is($report->{source_object}{intent_name}, 'axi_read_transaction_composition', 'root intent name is preserved');
    is_deeply(
        [map { [$_->{section}, $_->{page}] } @{$report->{source_object}{anchors}}],
        [
            ['A2.3', '29'], ['A2.3.1', '30'], ['A2.3.2.2', '32'], ['A2.6', '41'],
            ['A3.1', '42'], ['A3.1.1', '43'], ['A3.1.2', '44'], ['A3.1.4', '46'],
            ['A3.2.2', '55'], ['A3.3.2', '62'], ['A5.1.1', '90'],
            ['B1.2.1', '279'], ['B1.2.2', '281'],
        ],
        'thirteen selected source anchors remain ordered and exact',
    );
    is_deeply(
        $report->{target_protocol},
        { profile => 'axi4', object => 'axi-read-transaction-composition', role => 'manager' },
        'target protocol identity is exact',
    );
    is($report->{bindings}{command}{address}{width}, 32, 'admitted address width is pinned');
    is($report->{bindings}{command}{id}{width}, 4, 'admitted ARID width is pinned');
    is($report->{bindings}{r_channel}{captured_data}{width}, 32, 'captured RDATA width is pinned');
    is($report->{bindings}{status}{request_done}, 'read_request_done', 'request completion binding is distinct');
    is($report->{bindings}{status}{transaction_done}, 'read_transaction_done', 'transaction completion binding is distinct');
    is_deeply(
        $report->{single_beat_policy},
        {
            address_width => 32, address_alignment_bytes => 4, id_width => 4,
            data_width => 32, arlen => 0, arsize => 2, arburst => 1,
            arburst_name => 'INCR', rlast_expected => 1, beat_count => 1,
            request_completion => 'ar_request_accepted',
            response_completion => 'r_beat_accepted_and_captured',
        },
        'fixed single-beat AR R policy is complete and exact',
    );
    is($report->{ar_driver_reuse}{generator}, 'FSM::IAL2::ProtocolIntent::AxiArDriver', 'AR child generator is reused');
    ok($report->{ar_driver_reuse}{behavior_unchanged}, 'AR child behavior remains unchanged');
    is($report->{r_acceptor_reuse}{generator}, 'FSM::IAL2::ProtocolIntent::AxiRBeatAcceptor', 'R child generator is reused');
    ok($report->{r_acceptor_reuse}{behavior_unchanged}, 'R child behavior remains unchanged');
    is($report->{transaction_coordinator}{r_arm_policy}, 'arm_after_request_completion', 'R is armed only after AR completion');
    is($report->{transaction_coordinator}{busy_policy}, 'admission_through_r_response_retirement', 'busy spans the full read transaction');
    is($report->{transaction_coordinator}{mismatch_policy}, 'terminal_completion_with_match_zero_and_assertion', 'RID/RLAST mismatch policy is explicit');
    is($report->{transaction_coordinator}{response_status_policy}, 'raw_rresp_capture_not_success_interpretation', 'RRESP remains raw status');
    is_deeply(
        [map { [$_->{role}, $_->{instance_name}] } @{$report->{children}}],
        [
            ['ar-driver', 'ar_driver'],
            ['r-acceptor', 'r_acceptor'],
            ['transaction-coordinator', 'transaction_coordinator'],
        ],
        'three generated children are flat, ordered, and named',
    );
    is($report->{generated_schedules}{count}, 3, 'three child schedule reports are exposed');
    is_deeply([map { $_->{report}{compile_issues} } @{$report->{generated_schedules}{items}}], [[], [], []], 'all schedules are lowering-clean');

    my ($coordinator_item) = grep { $_->{object_name} eq 'axi_read_transaction_coordinator' } @{$result->{generated_ial1}{items}};
    my $coordinator_isf = $coordinator_item->{text};
    like($coordinator_isf, qr/\(rule arm_response \(& active_q \(! response_armed_q\) ar_done_i \(! r_busy_i\)\)/, 'coordinator gates R arm on AR completion');
    like($coordinator_isf, qr/\(set response_id_match \(== captured_rid_i expected_arid_q\)\)/, 'coordinator compares captured RID to retained ARID');
    like($coordinator_isf, qr/fixed-single-beat AXI read response must assert RLAST/, 'coordinator carries the RLAST assertion');
    my ($schedule) = grep { $_->{object_name} eq 'axi_read_transaction_coordinator' } @{$report->{generated_schedules}{items}};
    is($schedule->{report}{port_count}, 18, 'coordinator has eighteen ports');
    is($schedule->{report}{state_count}, 0, 'coordinator remains rule-only');
    is_deeply(
        [map { [$_->{name}, $_->{assignments}] } @{$schedule->{report}{dt_blocks}}],
        [
            ['admit', 6], ['clear_ar_start', 1], ['arm_response', 3],
            ['clear_r_arm', 1], ['clear_request_done', 1],
            ['finish_response', 6], ['clear_transaction_done', 1],
        ],
        'seven coordinator rule DTs retain exact assignment counts',
    );
    is_deeply(
        [map { [$_->{winner}, $_->{loser}, $_->{target}] } @{$schedule->{report}{priority_resolutions}}],
        [
            ['admit', 'clear_ar_start', 'ar_cmd_valid_i'],
            ['arm_response', 'clear_r_arm', 'r_arm_i'],
            ['arm_response', 'clear_request_done', 'read_request_done'],
            ['finish_response', 'clear_transaction_done', 'read_transaction_done'],
        ],
        'four realized coordinator pulse priorities are exact',
    );
    is_deeply(
        $report->{generated_artifacts}{ial0}{files},
        [qw(axi_ar_driver.fsm axi_r_beat_acceptor.fsm axi_read_transaction_composition.fsm axi_read_transaction_coordinator.fsm)],
        'three leaf FSMs plus one selected top are exact',
    );
    is($report->{generated_artifacts}{hdl_entry}{entry_artifact}, 'axi_read_transaction_composition.fsm', 'structural top artifact is selected');
    is(scalar(@{$report->{enforced_static_rules}}), 12, 'report carries twelve static rules');
    is(scalar(@{$report->{unsupported_residue}}), 13, 'report keeps thirteen bounded deferrals explicit');

    my $top = $result->{generated_ial0}{files}{'axi_read_transaction_composition.fsm'};
    like($top, qr/\A\(\?top:axi_read_transaction_composition\b/, 'generated IAL0 entry is a structural top');
    like($top, qr/\(\?fsmc:ar_driver axi_ar_driver\)/, 'top directly instantiates AR');
    like($top, qr/\(\?fsmc:r_acceptor axi_r_beat_acceptor\)/, 'top directly instantiates R');
    like($top, qr/\(\?fsmc:transaction_coordinator axi_read_transaction_coordinator\)/, 'top directly instantiates coordinator');
    like($top, qr/\(=8'd0 ar_driver\.cmd_arlen\)/, 'top fixes ARLEN');
    like($top, qr/\(r_acceptor\.response_rid transaction_coordinator\.captured_rid_i\)/, 'captured RID fanout is explicit');
    like($top, qr/\(r_acceptor\.response_rlast transaction_coordinator\.captured_rlast_i\)/, 'captured RLAST fanout is explicit');
};

subtest 'malformed and expanded full-read contracts fail closed' => sub {
    my @cases = (
        ['wrong root', sub { replace_once(sample_text(), '(protocol-platform-intent', '(wrong-root') }, qr/must start with \(protocol-platform-intent/, 'bad-root.ppif'],
        ['wrong profile family', sub { replace_once(sample_text(), '(profile axi4)', '(profile ahb)') }, qr/profile 'ahb' does not match \(axi-read-transaction-composition/, 'bad-profile.ppif'],
        ['non-AXI4 profile', sub { replace_once(sample_text(), '(profile axi4)', '(profile axi3)') }, qr/profile must be axi4 in this slice/, 'axi3.ppif'],
        ['wrong role', sub { replace_once(sample_text(), '(role manager)', '(role manager-to-subordinate)') }, qr/role must be manager/, 'bad-role.ppif'],
        ['synchronous reset', sub { replace_once(sample_text(), '(rst_n active_low async)', '(rst_n active_low sync)') }, qr/reset must be asynchronous active-low/, 'sync-reset.ppif'],
        ['active-high reset', sub { replace_once(sample_text(), '(rst_n active_low async)', '(rst_n active_high async)') }, qr/reset must be asynchronous active-low/, 'active-high.ppif'],
        ['duplicate command', sub { replace_once(sample_text(), "    (ar-channel\n", duplicate_command_clause() . "    (ar-channel\n") }, qr/duplicate \(command \.\.\.\) clause/, 'duplicate-command.ppif'],
        ['unknown clause', sub { replace_once(sample_text(), "    (status\n", "    (unknown value)\n    (status\n") }, qr/unsupported clause '\(unknown \.\.\.\)'/, 'unknown.ppif'],
        ['missing R channel', sub { my $s = sample_text(); $s =~ s/\n    \(r-channel\n(?:.*\n){9}      \(captured-last response_rlast\)\)// or die; $s }, qr/missing required \(r-channel \.\.\.\) clause/, 'missing-r.ppif'],
        ['missing transaction done', sub { my $s = sample_text(); $s =~ s/\n      \(transaction-done read_transaction_done\)// or die; $s }, qr/status \.\.\.\) is missing required \(transaction-done \.\.\.\) clause/, 'missing-done.ppif'],
        ['missing captured ID', sub { my $s = sample_text(); $s =~ s/\n      \(captured-id response_rid width 4\)// or die; $s }, qr/r-channel \.\.\.\) is missing required \(captured-id \.\.\.\) clause/, 'missing-rid.ppif'],
        ['missing captured data', sub { my $s = sample_text(); $s =~ s/\n      \(captured-data response_rdata width 32\)// or die; $s }, qr/r-channel \.\.\.\) is missing required \(captured-data \.\.\.\) clause/, 'missing-rdata.ppif'],
        ['missing captured response', sub { my $s = sample_text(); $s =~ s/\n      \(captured-response response_rresp width 2\)// or die; $s }, qr/r-channel \.\.\.\) is missing required \(captured-response \.\.\.\) clause/, 'missing-rresp.ppif'],
        ['missing captured last', sub { my $s = sample_text(); $s =~ s/\n      \(captured-last response_rlast\)// or die; $s }, qr/r-channel \.\.\.\) is missing required \(captured-last \.\.\.\) clause/, 'missing-rlast.ppif'],
        ['missing ID match', sub { my $s = sample_text(); $s =~ s/\n      \(response-id-match response_id_match\)// or die; $s }, qr/status \.\.\.\) is missing required \(response-id-match \.\.\.\) clause/, 'missing-id-match.ppif'],
        ['missing last match', sub { my $s = sample_text(); $s =~ s/\n      \(response-last-match response_last_match\)// or die; $s }, qr/status \.\.\.\) is missing required \(response-last-match \.\.\.\) clause/, 'missing-last-match.ppif'],
        ['dynamic metadata', sub { replace_once(sample_text(), '(id cmd_read_id width 4))', "(id cmd_read_id width 4)\n      (length cmd_arlen width 8))") }, qr/command \.\.\.\) has unsupported clause '\(length \.\.\.\)'/, 'dynamic.ppif'],
        ['nested child', sub { replace_once(sample_text(), "    (status\n", "    (axi-r-beat-acceptor nested)\n    (status\n") }, qr/unsupported clause '\(axi-r-beat-acceptor \.\.\.\)'/, 'nested.ppif'],
        ['mixed standalone AR', sub { append_root_clause(sample_text(), standalone_ar_clause()) }, qr/cannot mix \(axi-read-transaction-composition \.\.\.\) with other intent objects/, 'mixed.ppif'],
        ['multiple aggregate objects', sub { append_root_clause(sample_text(), second_composition_clause()) }, qr/supports exactly one \(axi-read-transaction-composition \.\.\.\) object/, 'duplicate-object.ppif'],
        ['duplicate public binding', sub { replace_once(sample_text(), '(response-id-match response_id_match)', '(response-id-match read_busy)') }, qr/duplicates signal 'read_busy'/, 'duplicate-signal.ppif'],
        ['generated collision', sub { replace_once(sample_text(), '(axi-read-transaction-composition axi_read_transaction_composition', '(axi-read-transaction-composition axi_ar_driver') }, qr/generated duplicate \.fsm artifact 'axi_ar_driver\.fsm'/, 'collision.ppif'],
        ['profile alias rejection', sub { sample_text() }, qr/\(axi-read-transaction-composition \.\.\.\) remains unsupported for the first profile-alias implementation/, 'composition.axi'],
    );

    my @width_cases = (
        ['command.address', '(address cmd_read_addr width 32)', '(address cmd_read_addr width 16)', qr/command\.address\.width must be 32/],
        ['command.id', '(id cmd_read_id width 4)', '(id cmd_read_id width 3)', qr/command\.id\.width must be 4/],
        ['ar.address', '(address araddr width 32)', '(address araddr width 16)', qr/ar_channel\.address\.width must be 32/],
        ['ar.id', '(id arid width 4)', '(id arid width 3)', qr/ar_channel\.id\.width must be 4/],
        ['ar.length', '(length arlen width 8)', '(length arlen width 7)', qr/ar_channel\.length\.width must be 8/],
        ['ar.size', '(size arsize width 3)', '(size arsize width 2)', qr/ar_channel\.size\.width must be 3/],
        ['ar.burst', '(burst arburst width 2)', '(burst arburst width 3)', qr/ar_channel\.burst\.width must be 2/],
        ['r.id', '(id rid width 4)', '(id rid width 3)', qr/r_channel\.id\.width must be 4/],
        ['r.data', '(data rdata width 32)', '(data rdata width 16)', qr/r_channel\.data\.width must be 32/],
        ['r.response', '(response rresp width 2)', '(response rresp width 3)', qr/r_channel\.response\.width must be 2/],
        ['r.captured_id', '(captured-id response_rid width 4)', '(captured-id response_rid width 3)', qr/r_channel\.captured_id\.width must be 4/],
        ['r.captured_data', '(captured-data response_rdata width 32)', '(captured-data response_rdata width 16)', qr/r_channel\.captured_data\.width must be 32/],
        ['r.captured_response', '(captured-response response_rresp width 2)', '(captured-response response_rresp width 3)', qr/r_channel\.captured_response\.width must be 2/],
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

subtest 'CLI support accounting and external HDL use the public full-read path' => sub {
    my $check = run_json_command('./bin/fsmgen', '--quiet', '--strict', '--check', '--json', sample_path());
    ok($check->{success}, 'strict check JSON succeeds');
    is($check->{result}{module_name}, 'axi_read_transaction_composition', 'check JSON reports the top module');
    is($check->{result}{composition_child_count}, 3, 'check JSON reports three children');
    is($check->{result}{signal_count}, 27, 'check JSON reports twenty-seven public signals');
    is($check->{support_accounting}{entry_id}, 'intent.ppif_axi_read_transaction_composition', 'check JSON matches support accounting');

    my $schedule = run_json_command('./bin/fsmgen', '--quiet', '--emit-schedule-json', sample_path());
    is($schedule->{schema}, 'fsmgen.ial2.protocol_intent.axi_read_transaction_composition.v1', 'schedule JSON exposes aggregate schema');
    is($schedule->{generated_schedules}{count}, 3, 'schedule JSON exposes all three schedules');

    my $semantic = run_json_command('./bin/fsmgen', '--quiet', '--strict', '--emit-semantic-json', sample_path());
    ok($semantic->{success}, 'strict semantic JSON succeeds');
    is($semantic->{generation_result_snapshot}{summary}{source_root_kind}, 'top', 'semantic JSON identifies a top root');
    is($semantic->{semantic}{composition}{lane}, 'C4', 'semantic JSON identifies C4');
    is($semantic->{generation_result_snapshot}{summary}{composition_child_count}, 3, 'semantic JSON reports three children');
    is($semantic->{semantic}{module}{composition_net_count}, 41, 'semantic JSON reports forty-one nets');
    is($semantic->{semantic}{module}{composition_resolved_link_count}, 44, 'semantic JSON reports forty-four links');
    is($semantic->{support_accounting}{entry_id}, 'intent.ppif_axi_read_transaction_composition', 'semantic JSON matches support accounting');

    my $tempdir = tempdir(CLEANUP => 1);
    my $outdir = File::Spec->catdir($tempdir, 'out');
    my $hdl = File::Spec->catfile($tempdir, 'axi_read_transaction_composition.sv');
    my ($emit_ok, undef, undef, undef, $emit_stderr) = run(command => ['./bin/fsmgen', '--quiet', '--strict', '--outdir', $outdir, '--output', $hdl, sample_path()]);
    ok($emit_ok, 'public source emits HDL and review artifacts through --outdir');
    is(join('', @{$emit_stderr || []}), '', 'outdir generation keeps stderr clean');
    for my $artifact (qw(axi_ar_driver.isf axi_r_beat_acceptor.isf axi_read_transaction_coordinator.isf axi_ar_driver.fsm axi_r_beat_acceptor.fsm axi_read_transaction_coordinator.fsm axi_read_transaction_composition.fsm)) {
        ok(-f File::Spec->catfile($outdir, $artifact), "outdir contains $artifact");
    }
    like(slurp($hdl), qr/\bmodule\s+axi_read_transaction_composition\b/, 'generated HDL contains the structural top');
    like(slurp($hdl), qr/accepted AXI RID must match admitted ARID/, 'generated HDL retains RID assertion');
    like(slurp($hdl), qr/fixed-single-beat AXI read response must assert RLAST/, 'generated HDL retains RLAST assertion');

    my ($verify_ok, undef, undef, $verify_stdout, $verify_stderr) = run(command => ['./bin/fsmgen', '--verify-hdl', '--output', File::Spec->catfile($tempdir, 'verify.sv'), sample_path()]);
    ok($verify_ok, 'composition passes external HDL verification') or diag(join('', @{$verify_stdout || []}), join('', @{$verify_stderr || []}));
    my $verify_text = join('', @{$verify_stdout || []});
    like($verify_text, qr/verilator_lint: PASS/, 'generated HDL passes Verilator lint');
    like($verify_text, qr/yosys_synthesis: PASS/, 'generated HDL passes Yosys synthesis');
};

subtest 'generated structural top joins AR then retires exact raw R outcomes' => sub {
    my $tempdir = tempdir(CLEANUP => 1);
    my $hdl = File::Spec->catfile($tempdir, 'axi_read_transaction_composition.sv');
    my $testbench = File::Spec->catfile($tempdir, 'axi_read_transaction_composition_tb.sv');
    my $obj_dir = File::Spec->catdir($tempdir, 'obj');
    my ($generate_ok, undef, undef, undef, $generate_stderr) = run(command => ['./bin/fsmgen', '--quiet', '--strict', '--output', $hdl, sample_path()]);
    ok($generate_ok, 'public source emits structural HDL for simulation');
    is(join('', @{$generate_stderr || []}), '', 'behavior HDL generation keeps stderr clean');
    write_file($testbench, behavior_testbench());

    my ($compile_ok, undef, undef, $compile_stdout, $compile_stderr) = run(command => ['verilator', '--binary', '--timing', '--no-assert', '-Wno-fatal', '-j', '1', '--top-module', 'axi_read_transaction_composition_tb', '--Mdir', $obj_dir, $hdl, $testbench]);
    ok($compile_ok, 'Verilator builds the generated structural-top harness with assertions disabled') or diag(join('', @{$compile_stdout || []}), join('', @{$compile_stderr || []}));
    return unless $compile_ok;
    my $binary = File::Spec->catfile($obj_dir, 'Vaxi_read_transaction_composition_tb');
    ok(-x $binary, 'simulation binary exists');
    my ($run_ok, undef, undef, $run_stdout, $run_stderr) = run(command => [$binary]);
    ok($run_ok, 'generated structural-top behavior passes') or diag(join('', @{$run_stdout || []}), join('', @{$run_stderr || []}));
    like(join('', @{$run_stdout || []}), qr/PASS ar=5 r=4 request=5 transaction=4 mismatch_terminal=1 missing_last_terminal=1 reset_abort=2/, 'all timing, capture, terminal-error, reset, and exact-cardinality checks pass');
};

done_testing();

sub sample_path { File::Spec->catfile($FindBin::Bin, '..', 'ppif', 'axi_read_transaction_composition.ppif') }
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

sub duplicate_command_clause {
    return <<'PPIF';
    (command
      (start duplicate_start)
      (address duplicate_address width 32)
      (id duplicate_id width 4))
PPIF
}

sub standalone_ar_clause {
    return <<'PPIF';
  (axi-ar-driver extra_ar
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
    my $start = index($source, '  (axi-read-transaction-composition');
    die "failed to locate aggregate object\n" if $start < 0;
    my $object = substr($source, $start);
    $object =~ s/\)\s*\z// or die "failed to remove root close\n";
    $object =~ s/axi_read_transaction_composition/axi_read_transaction_composition_2/g;
    $object =~ s/\b(clk|rst_n|read_cmd_valid|cmd_read_addr|cmd_read_id|arready|arvalid|araddr|arid|arlen|arsize|arburst|rvalid|rready|rid|rdata|rresp|rlast|response_rid|response_rdata|response_rresp|response_rlast|read_busy|read_request_done|read_transaction_done|response_id_match|response_last_match)\b/${1}_2/g;
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
    return slurp(File::Spec->catfile($FindBin::Bin, 'data', 'axi_read_transaction_composition_tb.svt'));
}
