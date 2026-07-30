#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use Cwd qw(abs_path);
use File::Spec;
use FindBin;
use IPC::Cmd qw(run);
use JSON::PP qw(decode_json);

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::Adapter::ISF;
use FSM::Pipeline::HDLGenerator;
use FSM::ProjectDataLocality qw(configure_project_temp_environment create_project_tempdir);
use FSM::Scheduler::ISF;
use FSM::Scheduler::ISF::LoweringIR;

my $repo_root = abs_path(File::Spec->catdir($FindBin::Bin, '..'));
configure_project_temp_environment(purpose => 'tests');
my $workspace = create_project_tempdir(purpose => 'tests');

subtest 'direct transaction assignment priority remains mechanically exclusive' => sub {
    my $path = data_path('isf_rule_transaction_direct_priority_control.isf');
    my $source = slurp($path);
    my $actor = FSM::Adapter::ISF->new()->parse_source($source, $path);
    my $schedule = decode_json(FSM::Scheduler::ISF->new()->report($actor));

    is_deeply(
        $schedule->{priority_resolutions},
        [{
            target => 'out',
            winner => 'force_out',
            winner_kind => 'rule',
            loser => 'main',
            loser_kind => 'transaction',
        }],
        'schedule reports direct rule-over-transaction suppression',
    );
    is_deeply($schedule->{compile_issues}, [], 'direct priority control has no compile issue');

    my $ir = FSM::Scheduler::ISF::LoweringIR->new()->build_module($actor);
    my $transaction_out = find_provenance(
        $ir,
        target => 'out',
        owner => 'main',
        owner_kind => 'transaction',
    );
    is_deeply(
        $transaction_out->{priority_suppressed_by},
        ['force_out'],
        'direct transaction assignment records its higher-priority suppressor',
    );
    is_deeply(
        $transaction_out->{activation}{assignment_guard},
        { expr => '(! override_req)' },
        'direct transaction assignment is guarded by the inverse rule condition',
    );

    my $hdl = generate_hdl('direct_priority_control', $source, $path);
    like(
        $hdl,
        qr/assign main_update_1_out_0_en = main_update_1_en & not_override_req;/,
        'direct generated selector enable includes the priority guard',
    );
    run_runtime(
        module => 'direct_priority_control',
        hdl => $hdl,
        testbench => data_path('isf_rule_transaction_direct_priority_control_tb.svt'),
        top => 'direct_priority_control_tb',
        expect_success => 1,
        expected_output => qr/PASS direct rule\/transaction priority out=1/,
    );
};

subtest 'unique transaction caller receives target-local rule-over-drive priority' => sub {
    my $path = data_path('isf_rule_transaction_named_drive_priority_probe.isf');
    my $source = slurp($path);
    my $check = run_json_command('./bin/fsmgen', '--quiet', '--strict', '--check', '--json', $path);
    ok($check->{success}, 'strict public check accepts the resolved named-drive overlap');
    is($check->{diagnostic_summary}{diagnostic_count}, 0, 'strict public check exposes no diagnostic for the resolved overlap');

    my $actor = FSM::Adapter::ISF->new()->parse_source($source, $path);
    my $schedule = decode_json(FSM::Scheduler::ISF->new()->report($actor));
    is_deeply(
        $schedule->{priority_resolutions},
        [{
            target => 'out',
            winner => 'force_out',
            winner_kind => 'rule',
            loser => 'main',
            loser_kind => 'transaction',
        }],
        'schedule reports the logical rule-over-transaction resolution',
    );
    is_deeply($schedule->{compile_issues}, [], 'resolved named-drive overlap has no compile issue');

    my $ir = FSM::Scheduler::ISF::LoweringIR->new()->build_module($actor);
    my ($drive_dt) = grep { ($_->{kind} // '') eq 'drive' && $_->{name} eq 'drive_zero' }
        @{$ir->{dt_blocks}};
    is_deeply($drive_dt->{local_transaction_callers}, ['main'], 'drive DT records its one sorted local caller');
    is_deeply($drive_dt->{generated_call_sources}, [], 'drive DT records no generated call source');
    my $drive_start = find_provenance(
        $ir,
        target => 'drive_zero_start',
        owner => 'main',
        source_kind => 'drive_call_start',
    );
    is($drive_start->{owner_kind}, 'transaction', 'drive-call request retains transaction provenance');
    my $drive_out = find_provenance(
        $ir,
        target => 'out',
        owner => 'drive_zero',
        source_kind => 'drive_body',
    );
    is($drive_out->{owner_kind}, 'drive', 'drive body changes provenance owner kind to drive');
    is_deeply($drive_out->{invoking_transactions}, ['main'], 'drive output retains private invoking transaction metadata');
    is_deeply($drive_out->{priority_suppressed_by}, ['force_out'], 'conflicting drive output records its higher-priority rule');
    is_deeply(
        $drive_out->{activation}{assignment_guard},
        { expr => '(& drive_zero_start (! override_req))' },
        'conflicting drive output combines its request with inverse rule activation',
    );
    my $drive_side = find_provenance(
        $ir,
        target => 'side',
        owner => 'drive_zero',
        source_kind => 'drive_body',
    );
    is_deeply($drive_side->{invoking_transactions}, ['main'], 'non-conflicting drive output retains the same caller metadata');
    is_deeply($drive_side->{priority_suppressed_by}, [], 'non-conflicting drive output is not priority-masked');
    is_deeply(
        $drive_side->{activation}{assignment_guard},
        { port => 'drive_zero_start' },
        'non-conflicting drive output keeps the original request guard',
    );

    my $hdl = generate_hdl('named_drive_priority_probe', $source, $path, 'systemverilog');
    like(
        $hdl,
        qr/assign intermediate_and_drive_zero_start_not_override_req_1 = drive_zero_start & !override_req;/,
        'generated HDL materializes the target-local inverse rule guard',
    );
    like(
        $hdl,
        qr/assign drive_zero_out_0_en = drive_zero_en & intermediate_and_drive_zero_start_not_override_req_1;/,
        'conflicting named-drive selector enable uses the priority guard',
    );
    like(
        $hdl,
        qr/assign drive_zero_side_1_en = drive_zero_en & \(\|drive_zero_start\);/,
        'non-conflicting named-drive selector remains request-only',
    );
    like(
        $hdl,
        qr/assert \(\$onehot0\(\{out_0_en, out_1_en\}\)\) else \$error\("selector multi-value conflict: out"\);/,
        'generated multi-value selector assertion remains authoritative',
    );

    my $semantic = run_json_command('./bin/fsmgen', '--quiet', '--strict', '--emit-semantic-json', $path);
    my ($out_family) = grep { $_->{signal_name} eq 'out' }
        @{$semantic->{semantic}{forward_ir}{lowered_rtl_ir}{output_drive_families}};
    is_deeply($out_family->{driver_blocks}, ['-drive_zero', '-force_out'], 'semantic output family exposes both drive blocks');
    is_deeply($out_family->{rhs_values}, ['0', '1'], 'semantic output family exposes both values');
    my ($side_family) = grep { $_->{signal_name} eq 'side' }
        @{$semantic->{semantic}{forward_ir}{lowered_rtl_ir}{output_drive_families}};
    is_deeply($side_family->{driver_blocks}, ['-drive_zero'], 'semantic non-conflicting output retains its drive block');
    is_deeply($side_family->{rhs_values}, ['1'], 'semantic non-conflicting output retains its value');

    run_runtime(
        module => 'named_drive_priority_probe',
        hdl => $hdl,
        testbench => data_path('isf_rule_transaction_named_drive_priority_probe_tb.svt'),
        top => 'named_drive_priority_probe_tb',
        expect_success => 1,
        expected_output => qr/PASS named-drive rule priority out=1 side=1/,
    );
};

subtest 'shared named-drive activation is inventoried and prioritized ambiguity fails closed' => sub {
    my $source = <<'ISF';
(actor named_drive_multi_caller_boundary
  (clock clk)
  (reset reset)
  (interface
    (input main_start)
    (input auxiliary_start)
    (input override_req)
    (output main_done)
    (output auxiliary_done)
    (output out))
  (drive drive_zero
    (out 0))
  (transaction main
    (on main_start)
    (drive drive_zero)
    (complete main_done))
  (transaction auxiliary
    (on auxiliary_start)
    (drive drive_zero)
    (complete auxiliary_done))
  (rule force_out override_req
    (out 1)))
ISF
    my $actor = FSM::Adapter::ISF->new()->parse_source($source, 'named-drive-multi-caller-boundary.isf');
    my $ir = FSM::Scheduler::ISF::LoweringIR->new()->build_module($actor);
    my @callers = sort map { $_->{owner} } grep {
        $_->{target} eq 'drive_zero_start' && $_->{source_kind} eq 'drive_call_start'
    } @{$ir->{assignment_provenance}};
    is_deeply(\@callers, ['auxiliary', 'main'], 'call sites retain two distinct transaction owners');

    my ($drive_dt) = grep { ($_->{kind} // '') eq 'drive' && $_->{name} eq 'drive_zero' }
        @{$ir->{dt_blocks}};
    is_deeply($drive_dt->{local_transaction_callers}, ['auxiliary', 'main'], 'drive DT records sorted distinct local callers');
    is_deeply($drive_dt->{generated_call_sources}, [], 'shared local drive records no generated source');
    my $drive_out = find_provenance(
        $ir,
        target => 'out',
        owner => 'drive_zero',
        source_kind => 'drive_body',
    );
    is_deeply(
        $drive_out->{activation}{assignment_guard},
        { port => 'drive_zero_start' },
        'shared drive body sees only the aggregate request after caller fan-in',
    );
    is_deeply($drive_out->{invoking_transactions}, ['auxiliary', 'main'], 'shared drive provenance retains both callers');

    my $schedule = decode_json(FSM::Scheduler::ISF->new()->report($actor));
    is($schedule->{compile_issues}[0]{code}, 'isf_unproven_rule_drive_overlap', 'unordered shared drive retains the current warning');
    is($schedule->{compile_issues}[0]{proof_status}, 'not_doable', 'unordered shared drive remains explicitly unproved');

    my $prioritized = $source;
    $prioritized =~ s/  \(drive drive_zero/  (priority force_out over main)\n  (drive drive_zero/;
    assert_lower_rejected(
        $prioritized,
        'prioritized shared named drive',
        qr/isf_ambiguous_rule_transaction_drive_priority.*target 'out'.*rule 'force_out'.*drive 'drive_zero'.*ambiguity_class=multiple_local_callers.*local_callers=\[auxiliary, main\].*rule_action, <- 1.*drive_body, <- 0/s,
    );

    my $failure = run_failed_check_json_source($prioritized, 'named-drive-multi-caller-priority.isf');
    ok(!$failure->{success}, 'ambiguous public check marks success false');
    is($failure->{diagnostic_summary}{diagnostic_count}, 1, 'ambiguous public check reports exactly one diagnostic');
    is(scalar(@{$failure->{diagnostics} || []}), 1, 'ambiguous public check carries one diagnostic payload');
    like($failure->{diagnostics}[0]{message}, qr/isf_ambiguous_rule_transaction_drive_priority/, 'public diagnostic carries the stable ambiguity code');
    ok(!$failure->{generated_output}{emitted}, 'ambiguous public check emits no generated output');
};

subtest 'unique transaction-over-rule priority masks only the rule while the drive is active' => sub {
    my $path = data_path('isf_rule_transaction_named_drive_transaction_priority.isf');
    my $source = slurp($path);
    my $actor = FSM::Adapter::ISF->new()->parse_source($source, $path);
    my $schedule = decode_json(FSM::Scheduler::ISF->new()->report($actor));

    is_deeply(
        $schedule->{priority_resolutions},
        [{
            target => 'out',
            winner => 'main',
            winner_kind => 'transaction',
            loser => 'force_out',
            loser_kind => 'rule',
        }],
        'schedule reports the logical transaction-over-rule resolution',
    );
    is_deeply($schedule->{compile_issues}, [], 'reverse-priority named-drive overlap has no compile issue');

    my $ir = FSM::Scheduler::ISF::LoweringIR->new()->build_module($actor);
    my $rule_out = find_provenance(
        $ir,
        target => 'out',
        owner => 'force_out',
        owner_kind => 'rule',
    );
    is_deeply($rule_out->{priority_suppressed_by}, ['main'], 'rule records the higher-priority logical transaction');
    is_deeply(
        $rule_out->{activation}{assignment_guard},
        { expr => '(! drive_zero_start)' },
        'rule receives only the inverse drive-body activation guard',
    );
    my $drive_out = find_provenance(
        $ir,
        target => 'out',
        owner => 'drive_zero',
        owner_kind => 'drive',
    );
    is_deeply($drive_out->{priority_suppressed_by}, [], 'winning drive assignment remains unmasked');

    my $hdl = generate_hdl('named_drive_transaction_priority', $source, $path, 'systemverilog');
    like(
        $hdl,
        qr/assign not_drive_zero_start = \(~\|drive_zero_start\);/,
        'generated HDL materializes inverse drive-body activation',
    );
    like(
        $hdl,
        qr/assign force_out_out_1_en = force_out_en & not_drive_zero_start;/,
        'generated rule selector is masked only while this drive target is active',
    );
    run_runtime(
        module => 'named_drive_transaction_priority',
        hdl => $hdl,
        testbench => data_path('isf_rule_transaction_named_drive_transaction_priority_tb.svt'),
        top => 'named_drive_transaction_priority_tb',
        expect_success => 1,
        expected_output => qr/PASS named-drive transaction priority out=1/,
    );
};

subtest 'unique-caller unordered, cyclic, and same-value boundaries stay exact' => sub {
    my $unordered = <<'ISF';
(actor named_drive_unordered
  (clock clk)
  (interface
    (input start)
    (input override_req)
    (output done)
    (output out))
  (drive drive_zero (out 0))
  (transaction main
    (on start)
    (drive drive_zero)
    (complete done))
  (rule force_out override_req (out 1)))
ISF
    assert_lower_rejected(
        $unordered,
        'unordered unique-caller named drive',
        qr/isf_conflicting_rule_transaction_writes.*target 'out'.*rule 'force_out'.*transaction 'main' \(drive_body, <- 0\)/s,
    );

    my $cyclic = $unordered;
    $cyclic =~ s/  \(drive drive_zero/  (priority force_out over main)\n  (priority main over force_out)\n  (drive drive_zero/;
    assert_lower_rejected(
        $cyclic,
        'cyclic unique-caller named-drive priority',
        qr/isf_priority_cycle_conflict.*target 'out'.*rule 'force_out'.*transaction 'main' \(drive_body, <- 0\)/s,
    );

    my $same_value = $unordered;
    $same_value =~ s/\(rule force_out override_req \(out 1\)\)/\(rule force_out override_req (out 0)\)/;
    my $same_actor = FSM::Adapter::ISF->new()->parse_source($same_value, 'named-drive-same-value.isf');
    my $same_ir = FSM::Scheduler::ISF::LoweringIR->new()->build_module($same_actor);
    is_deeply($same_ir->{conflict_issues}, [], 'same-value unique-caller fan-in remains compatible');
    is_deeply($same_ir->{priority_resolution}{resolutions}, [], 'same-value fan-in requires no priority resolution');
    my ($same_group) = grep {
        ($_->{kind} // '') eq 'same_target_value' && ($_->{target} // '') eq 'out'
    } @{$same_ir->{compatible_fanin_groups}};
    ok($same_group, 'same-value drive/rule fan-in remains explicitly reported');

    my $repeated_call = $unordered;
    $repeated_call =~ s/  \(drive drive_zero/  (priority force_out over main)\n  (drive drive_zero/;
    $repeated_call =~ s/    \(drive drive_zero\)\n    \(complete done\)/    (drive drive_zero)\n    (drive drive_zero)\n    (complete done)/;
    my $repeated_actor = FSM::Adapter::ISF->new()->parse_source($repeated_call, 'named-drive-repeated-call.isf');
    my $repeated_ir = FSM::Scheduler::ISF::LoweringIR->new()->build_module($repeated_actor);
    my ($repeated_dt) = grep { ($_->{kind} // '') eq 'drive' && $_->{name} eq 'drive_zero' }
        @{$repeated_ir->{dt_blocks}};
    is_deeply($repeated_dt->{local_transaction_callers}, ['main'], 'multiple call sites in one transaction remain one distinct caller');
    is(scalar(@{$repeated_ir->{priority_resolution}{resolutions}}), 1, 'repeated same-transaction calls produce one target resolution');
};

subtest 'unused and generated-source drives do not receive synthetic local ownership' => sub {
    my $unused_source = <<'ISF';
(actor unused_named_drive_boundary
  (clock clk)
  (interface
    (input override_req)
    (output out))
  (drive drive_zero (out 0))
  (rule force_out override_req (out 1)))
ISF
    my $unused_actor = FSM::Adapter::ISF->new()->parse_source($unused_source, 'unused-named-drive.isf');
    my $unused_ir = FSM::Scheduler::ISF::LoweringIR->new()->build_module($unused_actor);
    my ($unused_dt) = grep { ($_->{kind} // '') eq 'drive' && $_->{name} eq 'drive_zero' }
        @{$unused_ir->{dt_blocks}};
    is_deeply($unused_dt->{local_transaction_callers}, [], 'unused drive has no synthetic local caller');
    is_deeply($unused_dt->{generated_call_sources}, [], 'unused drive has no generated source descriptor');
    my $unused_out = find_provenance(
        $unused_ir,
        target => 'out',
        owner => 'drive_zero',
        owner_kind => 'drive',
    );
    is_deeply($unused_out->{invoking_transactions}, [], 'unused drive provenance retains an empty caller set');

    my $generated_source = <<'ISF';
(actor generated_named_drive_priority_boundary
  (clock clk)
  (interface
    (input start)
    (input override_req)
    (output done)
    (output out))
  (priority force_out over worker)
  (drive drive_zero (out 0))
  (transaction parent
    (on start)
    (spawn worker as w0)
    (complete done))
  (transaction worker
    (drive drive_zero)
    (complete done))
  (rule force_out override_req (out 1)))
ISF
    assert_lower_rejected(
        $generated_source,
        'prioritized generated-source named drive',
        qr/isf_ambiguous_rule_transaction_drive_priority.*ambiguity_class=generated_sources.*child_transaction=worker.*instance=w0.*candidate_transactions=\[worker\]/s,
    );

    my $mixed_source = <<'ISF';
(actor mixed_named_drive_priority_boundary
  (clock clk)
  (interface
    (input start)
    (input override_req)
    (output done)
    (output out))
  (priority force_out over main)
  (drive drive_zero (out 0))
  (transaction main
    (on start)
    (drive drive_zero)
    (spawn worker as w0)
    (complete done))
  (transaction worker
    (drive drive_zero)
    (complete done))
  (rule force_out override_req (out 1)))
ISF
    assert_lower_rejected(
        $mixed_source,
        'prioritized mixed local/generated named drive',
        qr/isf_ambiguous_rule_transaction_drive_priority.*ambiguity_class=mixed_local_and_generated_sources.*local_callers=\[main\].*child_transaction=worker.*candidate_transactions=\[main, worker\]/s,
    );
};

subtest 'native Verilog qualifies priority and direct VHDL removes scalar reduction tokens' => sub {
    my $path = data_path('isf_rule_transaction_named_drive_priority_probe.isf');
    my $source = slurp($path);
    my $verilog = generate_hdl('named_drive_priority_probe', $source, $path, 'verilog');
    like(
        $verilog,
        qr/assign intermediate_and_drive_zero_start_not_override_req_1 = drive_zero_start & !override_req;/,
        'native Verilog carries the target-local inverse guard',
    );
    unlike($verilog, qr/\$onehot0|\bassert\s*\(/, 'native Verilog does not gain SystemVerilog assertion syntax');
    run_iverilog_runtime(
        module => 'named_drive_priority_probe',
        hdl => $verilog,
        testbench => data_path('isf_rule_transaction_named_drive_priority_tb.vt'),
        top => 'named_drive_priority_probe_tb',
        expected_output => qr/PASS native Verilog named-drive priority out=1 side=1/,
    );

    my $vhdl = generate_hdl('named_drive_priority_probe', $source, $path, 'vhdl');
    like(
        $vhdl,
        qr/drive_zero_side_1_en <= drive_zero_en and \(drive_zero_start\);/,
        'direct VHDL lowers the scalar named-drive reduction by identity',
    );
    unlike($vhdl, qr/\(\s*[~]?[|&^]\s*drive_zero_start/, 'direct VHDL emits no named-drive reduction token');

    my $reverse_path = data_path('isf_rule_transaction_named_drive_transaction_priority.isf');
    my $reverse_source = slurp($reverse_path);
    my $reverse_vhdl = generate_hdl(
        'named_drive_transaction_priority',
        $reverse_source,
        $reverse_path,
        'vhdl',
    );
    like(
        $reverse_vhdl,
        qr/not_drive_zero_start <= \(not drive_zero_start\);/,
        'direct VHDL lowers the complemented scalar named-drive reduction to not',
    );
    unlike($reverse_vhdl, qr/\(\s*[~]?[|&^]\s*drive_zero_start/, 'complemented direct VHDL emits no reduction token');
    note('decision 0023 still requires an authoritative compiler for executable VHDL qualification');
};

done_testing();

sub generate_hdl {
    my ($module, $source, $source_path, $target_language) = @_;
    $target_language ||= 'systemverilog';
    my $actor = FSM::Adapter::ISF->new()->parse_source($source, $source_path);
    my $fsm = FSM::Scheduler::ISF->new()->lower($actor)->{files}{"$module.fsm"};
    my $fsm_path = File::Spec->catfile($workspace, "$module.fsm");
    write_file($fsm_path, $fsm);
    return FSM::Pipeline::HDLGenerator->new(
        target_language => $target_language,
        debug_level => 0,
        quiet => 1,
    )->generate_hdl_from_file($fsm_path)->{hdl_code};
}

sub run_runtime {
    my (%args) = @_;
    my $hdl_path = File::Spec->catfile($workspace, "$args{module}.sv");
    write_file($hdl_path, $args{hdl});
    my $objdir = File::Spec->catdir($workspace, "obj-$args{module}");
    my ($compile_ok, undef, undef, $compile_stdout, $compile_stderr) = run(
        command => [
            'verilator', '--binary', '--timing', '--assert', '-Wno-fatal',
            '-j', '1', '--sv', '--top-module', $args{top}, '--Mdir', $objdir,
            $hdl_path, $args{testbench},
        ],
    );
    my $compile_output = join('', @{$compile_stdout || []}, @{$compile_stderr || []});
    ok($compile_ok, "$args{module} assertion-enabled Verilator build succeeds")
        or diag($compile_output);
    return unless $compile_ok;

    my $binary = File::Spec->catfile($objdir, "V$args{top}");
    my ($run_ok, undef, undef, $run_stdout, $run_stderr) = run(command => [$binary]);
    my $run_output = join('', @{$run_stdout || []}, @{$run_stderr || []});
    is($run_ok ? 1 : 0, $args{expect_success} ? 1 : 0, "$args{module} runtime has the expected success state")
        or diag($run_output);
    like($run_output, $args{expected_output}, "$args{module} runtime exposes the expected outcome");
}

sub run_iverilog_runtime {
    my (%args) = @_;
    my $hdl_path = File::Spec->catfile($workspace, "$args{module}.v");
    my $binary = File::Spec->catfile($workspace, "$args{module}-iverilog");
    write_file($hdl_path, $args{hdl});
    my ($compile_ok, undef, undef, $compile_stdout, $compile_stderr) = run(
        command => [
            'iverilog', '-g2005', '-s', $args{top}, '-o', $binary,
            $hdl_path, $args{testbench},
        ],
    );
    my $compile_output = join('', @{$compile_stdout || []}, @{$compile_stderr || []});
    ok($compile_ok, "$args{module} native Verilog compiles with Icarus")
        or diag($compile_output);
    return unless $compile_ok;

    my ($run_ok, undef, undef, $run_stdout, $run_stderr) = run(command => ['vvp', $binary]);
    my $run_output = join('', @{$run_stdout || []}, @{$run_stderr || []});
    ok($run_ok, "$args{module} native Verilog runtime succeeds") or diag($run_output);
    like($run_output, $args{expected_output}, "$args{module} native Verilog runtime exposes the expected outcome");
}

sub assert_lower_rejected {
    my ($source, $label, $diagnostic_re) = @_;
    my $actor = FSM::Adapter::ISF->new()->parse_source($source, "$label.isf");
    my $ok = eval {
        FSM::Scheduler::ISF::LoweringIR->new()->build_module($actor);
        1;
    };
    my $diagnostic = $@;
    ok(!$ok, "$label is rejected");
    ok(!ref($diagnostic), "$label diagnostic is scalar");
    like($diagnostic, $diagnostic_re, "$label diagnostic is exact");
}

sub run_failed_check_json_source {
    my ($source, $basename) = @_;
    my $path = File::Spec->catfile($workspace, $basename);
    write_file($path, $source);
    my ($success, undef, undef, $stdout, $stderr) = run(
        command => ['./bin/fsmgen', '--quiet', '--strict', '--check', '--json', $path],
    );
    ok(!$success, "$basename fails public check JSON");
    is(join('', @{$stderr || []}), '', "$basename keeps stderr clean");
    my $payload = join('', @{$stdout || []});
    isnt($payload, '', "$basename emits JSON on stdout");
    my $decoded = eval { decode_json($payload) };
    ok(!$@, "$basename emits decodable JSON");
    return $decoded;
}

sub run_json_command {
    my @command = @_;
    my ($ok, undef, undef, $stdout, $stderr) = run(command => \@command);
    my $stderr_text = join('', @{$stderr || []});
    ok($ok, "@command succeeds") or diag($stderr_text);
    is($stderr_text, '', "@command keeps stderr clean");
    my $json = join('', @{$stdout || []});
    return decode_json($json);
}

sub find_provenance {
    my ($ir, %want) = @_;
    RECORD:
    for my $record (@{$ir->{assignment_provenance} || []}) {
        for my $key (sort keys %want) {
            next RECORD unless defined($record->{$key}) && $record->{$key} eq $want{$key};
        }
        return $record;
    }
    return {};
}

sub data_path {
    my ($name) = @_;
    return File::Spec->catfile($FindBin::Bin, 'data', $name);
}

sub slurp {
    my ($path) = @_;
    open my $fh, '<', $path or die "open $path: $!";
    local $/;
    return <$fh>;
}

sub write_file {
    my ($path, $content) = @_;
    open my $fh, '>', $path or die "open $path: $!";
    print {$fh} $content or die "write $path: $!";
    close $fh or die "close $path: $!";
}
