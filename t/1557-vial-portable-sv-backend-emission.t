#!/usr/bin/env perl

use strict;
use warnings;

use bytes ();
use Digest::SHA qw(sha256_hex);
use File::Spec;
use FindBin;
use JSON::PP ();
use Scalar::Util qw(blessed);
use Test::More;

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::Support::CapabilityManifest qw(build_capability_manifest);
use FSM::Support::VIALExecutionContract qw(
    build_vial_execution_contract
    vial_execution_contract_keys
);
use FSM::VIAL::Backend::SVPortableVerilator;
use FSM::VIAL::Backend::TraceValidator;
use FSM::VIAL::Parser;
use FSM::VIAL::PlanBuilder;

my $json = JSON::PP->new->canonical(1);
my $vial_id = 'vial/ahb_subordinate_base_output_arbitration.vial';
my $hial_id = 'ppif/ahb_lite_subordinate.ppif';
my $built = build_plan();

ok($built->{ok}, 'checked VIAL/HIAL fixture reaches private backend inputs');
diag($json->encode($built->{diagnostics})) unless $built->{ok};

subtest 'planning exposes exact private compiler inputs without changing public projections' => sub {
    is_deeply(
        [sort keys %$built],
        [sort qw(
            ok bridge_manifest bridge_report execution_ir backend_inputs plan
            review_artifacts diagnostics
        )],
        'private PlanBuilder result has one closed backend handoff',
    );
    isa_ok($built->{execution_ir}, 'FSM::VIAL::ExecutionIR');
    isa_ok($built->{bridge_manifest}, 'FSM::HIAL::VIALBridge::Manifest');
    is_deeply(
        [sort keys %{$built->{backend_inputs}}],
        [qw(dut_systemverilog dut_vhdl)],
        'backend inputs carry both generated HIAL language families privately',
    );
    is(scalar(@{$built->{backend_inputs}{dut_systemverilog}}), 1, 'one bound unit supplies one DUT source');
    my $dut = $built->{backend_inputs}{dut_systemverilog}[0];
    is($dut->{module_name}, 'ahb_lite_subordinate', 'DUT module identity is exact');
    is($dut->{artifact_name}, 'ahb_lite_subordinate.sv', 'DUT artifact name is deterministic');
    is($dut->{byte_length}, bytes::length($dut->{text}), 'DUT byte count covers exact emitted text');
    is($dut->{content_sha256}, sha256_hex($dut->{text}), 'DUT hash covers exact emitted text');
    like($dut->{text}, qr{// Date: omitted by deterministic VIAL backend}, 'nondeterministic generator date is normalized');
    unlike($dut->{text}, qr{// Date: \d}, 'normalized DUT contains no generated wall-clock date');
    is(scalar(@{$built->{backend_inputs}{dut_vhdl}}), 1,
        'one bound unit supplies one VHDL DUT source');
    my $vhdl_dut = $built->{backend_inputs}{dut_vhdl}[0];
    is($vhdl_dut->{entity_name}, 'ahb_lite_subordinate', 'VHDL DUT entity identity is exact');
    is($vhdl_dut->{artifact_name}, 'ahb_lite_subordinate.vhd',
        'VHDL DUT artifact name is deterministic');
    is($vhdl_dut->{byte_length}, bytes::length($vhdl_dut->{text}),
        'VHDL DUT byte count covers exact emitted text');
    is($vhdl_dut->{content_sha256}, sha256_hex($vhdl_dut->{text}),
        'VHDL DUT hash covers exact emitted text');
    like($vhdl_dut->{text}, qr/entity ahb_lite_subordinate is/,
        'VHDL DUT bytes declare the bridge-bound entity');
};

subtest 'private emitter produces a deterministic closed portable-SystemVerilog graph' => sub {
    my $first = emit_backend();
    ok($first->{ok}, 'backend emission succeeds');
    diag($json->encode($first->{diagnostics})) unless $first->{ok};
    is_deeply(
        [sort keys %$first],
        [sort @{FSM::VIAL::Backend::SVPortableVerilator->result_keys}],
        'backend result is closed',
    );
    is($first->{status}, 'emitted', 'emitter reports only the emission gate');
    is($first->{backend_profile}, 'sv_portable_verilator', 'backend profile is exact');
    like($first->{generated_top}, qr{\A[A-Za-z_][A-Za-z0-9_]*\z}, 'generated top is a legal stable identifier');
    is_deeply($first->{negotiation}{unsatisfied}, [], 'negotiation has no unsatisfied requirement');
    is_deeply($first->{negotiation}{native_only}, [], 'negotiation has no native-only requirement');
    is_deeply($first->{negotiation}{required}, $first->{negotiation}{satisfied}, 'every required capability is explicitly satisfied');

    my @expected = qw(
        backends/sv_portable_verilator/backend-manifest.json
        backends/sv_portable_verilator/backend-source-map.json
        backends/sv_portable_verilator/commands/compile-command.json
        backends/sv_portable_verilator/commands/run-command.json
        backends/sv_portable_verilator/evidence/tool-profile.json
        backends/sv_portable_verilator/src/base_output_arbitration_tb.sv
        backends/sv_portable_verilator/src/dut/ahb-lite-subordinate.sv
        backends/sv_portable_verilator/src/fsmgen_vial_runtime_pkg.sv
    );
    is_deeply([map { $_->{relpath} } @{$first->{artifacts}}], \@expected, 'emitter returns the complete sorted version-1 graph');
    ok(!scalar(grep { $_->{relpath} =~ /(?:compile-transcript|run-transcript|runtime-trace|verification-result)/ } @{$first->{artifacts}}), 'emission invents no compile/runtime/result evidence');
    my %artifact = map { $_->{relpath} => $_ } @{$first->{artifacts}};
    my $tb = $artifact{'backends/sv_portable_verilator/src/base_output_arbitration_tb.sv'}{content};
    my $runtime = $artifact{'backends/sv_portable_verilator/src/fsmgen_vial_runtime_pkg.sv'}{content};
    like($runtime, qr{package fsmgen_vial_runtime_pkg;}, 'shared runtime helper is emitted once');
    like($runtime, qr{fsmgen\.vial_sv_runtime_trace\.v1}, 'runtime helper owns the closed trace representation');
    like($tb, qr{module base_output_arbitration_tb;}, 'fixture source has a meaningful plan-derived top');
    like($tb, qr{task automatic vial_inactive_barrier;.*\@\(negedge clk\)}s, 'one inactive-edge scheduler maps the rising-edge DUT domain');
    like($tb, qr{wire \[31:0\] vial_probe_reg_data_q = dut\.reg_data_q;}, 'declared probe becomes one generated hierarchical read alias');
    like($tb, qr{// VIAL operation: operation/}, 'operation identity is readable beside generated tasks');
    like($tb, qr{Child fibers are evaluated by this one scheduler.*while \(!\(}s, 'parallel topology is statically materialized under one scheduler');
    unlike($tb, qr{^\s*fork\s*$}m, 'target fork scheduling is not execution authority');
    like($tb, qr{HSIZE = 3'h7;}, 'selected substitution fault is statically folded into the affected drive');
    unlike($tb . $runtime, qr{(?:uvm_|build_phase|raise_objection|DPI|VPI)}, 'plain source contains no methodology or host escape vocabulary');
    unlike(
        $json->encode($first),
        qr{"(?:relpath|working_directory|staging_identity)":"/},
        'backend graph persists no absolute artifact, work, or staging path',
    );

    is_deeply(
        [sort keys %{$first->{backend_manifest}}],
        [sort @{FSM::VIAL::Backend::SVPortableVerilator->manifest_keys}],
        'backend manifest has the exact selected top-level shape',
    );
    is($first->{backend_manifest}{capability_evidence}{emission}, 'passed', 'manifest records emission evidence');
    is($first->{backend_manifest}{capability_evidence}{compile}, 'not_run', 'manifest does not confuse emission with compile');
    is($first->{backend_manifest}{capability_evidence}{runtime}, 'not_run', 'manifest does not confuse emission with runtime');
    is($first->{backend_manifest}{result}{status}, 'not_produced', 'manifest does not invent a result');
    is($first->{backend_manifest}{cleanup}{state}, 'not_created', 'emission creates no staging tree');
    is($first->{backend_manifest}{tool_profile}{selection_status}, 'selected_not_executed', 'tool profile is selected but not executed');
    my $compile = JSON::PP->new->decode($artifact{'backends/sv_portable_verilator/commands/compile-command.json'}{content});
    is_deeply(
        [@{$compile->{arguments}}[0 .. 12]],
        [qw(--binary --timing --assert -j 1 --threads 1 --x-initial 0 --x-assign 0 --timescale 1ns/1ps)],
        'compile command preserves exact ordered qualification flags',
    );
    ok(scalar(grep { $_ eq '--Mdir' } @{$compile->{arguments}}), 'compile command declares a repository-local object root');
    ok(!scalar(grep { $_ eq '--timescale-override' || $_ eq '-Wno-fatal' } @{$compile->{arguments}}), 'compile command contains no forbidden override/suppression');

    is_deeply(
        [sort keys %{$first->{source_map}}],
        [sort @{FSM::VIAL::Backend::SVPortableVerilator->source_map_keys}],
        'source map has the exact selected shape',
    );
    ok(@{$first->{source_map}{entries}} >= 54, 'source map covers operations and every stateful family');
    for my $entry (@{$first->{source_map}{entries}}) {
        is_deeply(
            [sort keys %$entry],
            [sort @{FSM::VIAL::Backend::SVPortableVerilator->source_map_entry_keys}],
            "$entry->{source_map_id} is closed",
        );
    }
    my %mapped_operation = map {
        map { $_ => 1 } grep { m{\Aoperation/} } @{$_->{semantic_paths}}
    } @{$first->{source_map}{entries}};
    is(scalar(keys %mapped_operation), 21, 'all 21 immutable plan operations are source-mapped');
    my ($probe_adapter) = @{$first->{backend_manifest}{capability_evidence}{probe_adapters}};
    ok(scalar(grep { $_->{source_map_id} eq $probe_adapter->{source_map_id} } @{$first->{source_map}{entries}}), 'probe adapter references an exact source-map record');

    my $second = emit_backend();
    is($json->encode($second), $json->encode($first), 'repeat emission is byte-deterministic');
    $first->{artifacts}[0]{content} = 'mutated';
    isnt($second->{artifacts}[0]{content}, 'mutated', 'emission results are deeply defensive');
};

subtest 'root successor scheduling rolls every backward phase crossing to the next cycle' => sub {
    my $ordinary = emitted_fixture_source($built);
    like(
        $ordinary,
        qr{vial_op_0_reset_[0-9a-f]{12}\(\);\s+// VIAL successor phase rollover: check -> react advances to the next logical cycle\.\s+vial_inactive_barrier\(\);\s+vial_op_1_scoreboard_expect_[0-9a-f]{12}\(\);\s+// VIAL successor phase rollover: react -> drive advances to the next logical cycle\.\s+vial_cycle = vial_cycle \+ 1;\s+vial_op_2_start_[0-9a-f]{12}\(\);}s,
        'blocking reset check-to-react and scoreboard react-to-drive crossings each use their exact rollover',
    );
    like(
        $ordinary,
        qr{vial_op_6_expect_[0-9a-f]{12}\(\);\s+vial_op_7_expect_[0-9a-f]{12}\(\);\s+vial_op_8_expect_[0-9a-f]{12}\(\);\s+vial_op_9_expect_[0-9a-f]{12}\(\);\s+vial_op_10_expect_[0-9a-f]{12}\(\);\s+vial_op_11_scoreboard_check_[0-9a-f]{12}\(\);}s,
        'same-phase check successors retain authored static-rank order without rollover',
    );

    my $check_react_text = slurp_raw(repo_path($vial_id));
    $check_react_text =~ s{
        \(reset\ bus\ 3\)\n
        \s+\(scoreboard_expect\ writes
    }{(reset bus 3)\n              (expect phase_before_scoreboard (same (sample response) #b0))\n              (scoreboard_expect writes}x
        or die 'check-to-react source mutation did not find the success scoreboard';
    my $check_react = build_plan($check_react_text);
    ok($check_react->{ok}, 'check-to-react source builds through immutable ExecutionIR');
    diag($json->encode($check_react->{diagnostics})) unless $check_react->{ok};
    my $check_react_sv = emitted_fixture_source($check_react);
    like(
        $check_react_sv,
        qr{vial_op_1_expect_[0-9a-f]{12}\(\);\s+// VIAL successor phase rollover: check -> react advances to the next logical cycle\.\s+vial_inactive_barrier\(\);\s+vial_op_2_scoreboard_expect_[0-9a-f]{12}\(\);}s,
        'check-to-react successor advances through the inactive-edge next-cycle barrier',
    );

    my $check_drive_text = slurp_raw(repo_path($vial_id));
    $check_drive_text =~ s{
        (\(scoreboard_expect\ writes.*?\(wait_cycles\ \(choice\ success_wait\)\)\)\)\n)
        (\s+\(start\ success_write)
    }{$1              (expect phase_before_start (same (sample response) #b0))\n$2}sx
        or die 'check-to-drive source mutation did not find the success start';
    my $check_drive = build_plan($check_drive_text);
    ok($check_drive->{ok}, 'check-to-drive source builds through immutable ExecutionIR');
    diag($json->encode($check_drive->{diagnostics})) unless $check_drive->{ok};
    my $check_drive_sv = emitted_fixture_source($check_drive);
    like(
        $check_drive_sv,
        qr{vial_op_2_expect_[0-9a-f]{12}\(\);\s+// VIAL successor phase rollover: check -> drive advances to the next logical cycle\.\s+vial_cycle = vial_cycle \+ 1;\s+vial_op_3_start_[0-9a-f]{12}\(\);}s,
        'check-to-drive successor advances directly to the next logical drive phase',
    );
};

subtest 'ordinary direct drive lowers one exact bound endpoint update and record' => sub {
    my $direct = build_plan(direct_drive_source());
    ok($direct->{ok}, 'ordinary direct-drive source builds through immutable ExecutionIR');
    diag($json->encode($direct->{diagnostics})) unless $direct->{ok};

    my ($binding) = grep {
        ($_->{endpoint_id} // '') eq 'endpoint/HSEL'
    } @{$direct->{execution_ir}{data}{bindings}{endpoints} || []};
    ok(defined($binding), 'direct-drive endpoint has one execution binding');
    is($binding->{carrier_direction}, 'input', 'bound carrier is drive-capable');
    is_deeply(
        [map { $_->{direction} } @{$binding->{relations} || []}],
        ['drive'],
        'binding carries one exact drive representation relation',
    );

    my ($drive) = grep {
        ($_->{kind} // '') eq 'drive'
    } @{$direct->{execution_ir}{data}{operation_graph}{operations} || []};
    ok(defined($drive), 'authored drive becomes one immutable drive operation');
    is($drive->{eligible_phase}, 'drive', 'direct operation is eligible in the drive phase');
    is($drive->{effects}[0]{kind}, 'update_driver', 'direct operation retains update-driver intent');
    is(
        $drive->{effects}[0]{target_id},
        $binding->{semantic_id},
        'update-driver effect names the exact semantic endpoint target',
    );

    my $fixture = emitted_fixture_source($direct);
    my ($body) = $fixture =~ m{
        //\ VIAL\ operation:\ \Q$drive->{operation_id}\E\n
        \ \ task\ automatic\ [^;]+;\n
        (.*?)
        \ \ endtask
    }sx;
    ok(defined($body), 'direct-drive operation task is independently recoverable');
    like($body, qr{^\s*HSEL = 1'h1;$}m, 'direct-drive task assigns the exact bound port value');
    like(
        $body,
        qr{vial_emit\("drives".*\\"endpoint_id\\":\\"endpoint/HSEL\\"}s,
        'direct-drive task emits one endpoint-qualified drive record',
    );
    unlike($body, qr{vial_inactive_barrier\(\)}, 'zero-duration direct drive does not consume a sample barrier');
    like(
        $fixture,
        qr{HSEL = '0;\s+\$display\("FSMGEN_VIAL_TRACE_V1\\t%s", vial_trace_record\("scenario_end"}s,
        'scenario finalization restores the direct driver slot to its selected safe zero',
    );
    my $direct_emission = emit_plan($direct);
    ok($direct_emission->{ok}, 'direct-drive finalizer emits with complete provenance');
    ok(
        scalar(grep { $_ eq 'root_fiber_direct_drive_only' }
            @{$direct_emission->{negotiation}{limitations}}),
        'negotiation publishes the exact non-root direct-drive boundary',
    );
    ok(
        scalar(grep { $_ eq 'input_carrier_direct_drive_only' }
            @{$direct_emission->{negotiation}{limitations}}),
        'negotiation publishes the exact input-carrier direct-drive boundary',
    );
    my ($map_artifact) = grep {
        $_->{relpath} eq 'backends/sv_portable_verilator/backend-source-map.json'
    } @{$direct_emission->{artifacts} || []};
    my $direct_map = JSON::PP->new->decode($map_artifact->{content});
    my @finalizer_map = grep {
        ($_->{role} // '') eq 'direct_driver_safe_zero_finalization'
    } @{$direct_map->{entries} || []};
    is(scalar(@finalizer_map), 1, 'direct driver finalization has one dedicated source-map entry');
    is_deeply(
        $finalizer_map[0]{semantic_paths},
        [$binding->{semantic_id}, $drive->{operation_id}],
        'finalizer provenance closes over the exact endpoint and owning operation',
    );
    my $bridge_endpoint = $direct->{bridge_manifest}->get('endpoints');
    my ($bridge_index) = grep {
        $bridge_endpoint->[$_]{endpoint_id} eq $binding->{endpoint_id}
    } 0 .. $#$bridge_endpoint;
    is_deeply(
        $finalizer_map[0]{bridge_fact_paths},
        ["/endpoints/$bridge_index"],
        'finalizer provenance names the exact bridge endpoint fact',
    );

    my $ordered_source = direct_drive_source();
    $ordered_source =~ s{
        \(drive\ select\ \#b1\)
    }{(drive select #b0)\n              (drive select #b1)}x
        or die 'ordered-drive source mutation did not find the direct drive';
    my $ordered = build_plan($ordered_source);
    ok($ordered->{ok}, 'two root-fiber writes to one slot build in authored order');
    diag($json->encode($ordered->{diagnostics})) unless $ordered->{ok};
    my $ordered_fixture = emitted_fixture_source($ordered);
    like(
        $ordered_fixture,
        qr{
            vial_op_1_drive_[0-9a-f]{12}\(\);\s+
            vial_op_2_drive_[0-9a-f]{12}\(\);\s+
            //\ VIAL\ phase\ advance:\ drive\ ->\ react\ traverses\ the\ current\ cycle\ sample\ barrier\.\s+
            vial_inactive_barrier\(\);\s+
            vial_op_3_scoreboard_expect_[0-9a-f]{12}\(\);
        }sx,
        'same-fiber same-phase drives retain static-rank order before one sample barrier',
    );

    my $check_source = direct_drive_source();
    $check_source =~ s{
        (\(drive\ select\ \#b1\)\n)
    }{$1              (expect direct_drive_check (same (sample response) #b0))\n}x
        or die 'drive-to-check source mutation did not find the direct drive';
    my $check = build_plan($check_source);
    ok($check->{ok}, 'direct drive followed by a check-phase operation builds');
    diag($json->encode($check->{diagnostics})) unless $check->{ok};
    my $check_fixture = emitted_fixture_source($check);
    like(
        $check_fixture,
        qr{
            vial_op_1_drive_[0-9a-f]{12}\(\);\s+
            //\ VIAL\ phase\ advance:\ drive\ ->\ check\ traverses\ the\ current\ cycle\ sample\ barrier\.\s+
            vial_inactive_barrier\(\);\s+
            vial_op_2_expect_[0-9a-f]{12}\(\);
        }sx,
        'drive-to-check crosses one real sample barrier before evaluation',
    );
};

subtest 'negotiation and invocation failures emit nothing' => sub {
    my $wrong = emit_backend(backend_profile => 'other_backend');
    backend_failure($wrong, 'VIAL_BACKEND_UNSUPPORTED', 'wrong backend profile');

    my $unsafe = emit_backend(artifact_root => '../outside');
    backend_failure($unsafe, 'VIAL_BACKEND_INVOCATION_ERROR', 'unsafe artifact root');

    my $missing = emit_backend(backend_inputs => {
        dut_systemverilog => [],
        dut_vhdl => $built->{backend_inputs}{dut_vhdl},
    });
    backend_failure($missing, 'VIAL_BACKEND_UNSUPPORTED', 'missing DUT input');

    my $phase_drift_plan = build_plan();
    my $phase_drift_operation =
        $phase_drift_plan->{execution_ir}{data}{operation_graph}{operations}[0];
    $phase_drift_operation->{eligible_phase} = 'react';
    my $phase_drift = emit_backend(
        execution_ir => $phase_drift_plan->{execution_ir},
    );
    backend_failure(
        $phase_drift, 'VIAL_BACKEND_UNSUPPORTED',
        'ExecutionIR operation-phase drift',
    );
    is_deeply(
        $phase_drift->{negotiation}{unsatisfied},
        ["operation-phase:$phase_drift_operation->{operation_id}"],
        'phase drift fails closed at negotiation with the exact operation identity',
    );

    my $wrong_drive_target_plan = build_plan(direct_drive_source());
    my ($wrong_drive_target_operation) = grep {
        ($_->{kind} // '') eq 'drive'
    } @{$wrong_drive_target_plan->{execution_ir}{data}{operation_graph}{operations}};
    $wrong_drive_target_operation->{effects}[0]{target_id} = 'endpoint/forged';
    my $wrong_drive_target = emit_backend(
        execution_ir => $wrong_drive_target_plan->{execution_ir},
        bridge_manifest => $wrong_drive_target_plan->{bridge_manifest},
        backend_inputs => $wrong_drive_target_plan->{backend_inputs},
    );
    backend_failure(
        $wrong_drive_target, 'VIAL_BACKEND_UNSUPPORTED',
        'direct-drive effect-target drift',
    );
    is_deeply(
        $wrong_drive_target->{negotiation}{unsatisfied},
        ["direct-drive:$wrong_drive_target_operation->{operation_id}:effect"],
        'effect-target drift names the exact rejected direct operation',
    );

    my $wrong_drive_relation_plan = build_plan(direct_drive_source());
    my ($wrong_drive_relation_operation) = grep {
        ($_->{kind} // '') eq 'drive'
    } @{$wrong_drive_relation_plan->{execution_ir}{data}{operation_graph}{operations}};
    my ($wrong_drive_binding) = grep {
        ($_->{semantic_id} // '')
            eq $wrong_drive_relation_operation->{effects}[0]{target_id}
    } @{$wrong_drive_relation_plan->{execution_ir}{data}{bindings}{endpoints}};
    $wrong_drive_binding->{relations}[0]{direction} = 'sample';
    my $wrong_drive_relation = emit_backend(
        execution_ir => $wrong_drive_relation_plan->{execution_ir},
        bridge_manifest => $wrong_drive_relation_plan->{bridge_manifest},
        backend_inputs => $wrong_drive_relation_plan->{backend_inputs},
    );
    backend_failure(
        $wrong_drive_relation, 'VIAL_BACKEND_UNSUPPORTED',
        'direct-drive relation drift',
    );
    is_deeply(
        $wrong_drive_relation->{negotiation}{unsatisfied},
        ["direct-drive:$wrong_drive_relation_operation->{operation_id}:drive-relation"],
        'relation drift names the exact rejected direct operation',
    );

    my $inout_drive_plan = build_plan(direct_drive_source());
    my ($inout_drive_operation) = grep {
        ($_->{kind} // '') eq 'drive'
    } @{$inout_drive_plan->{execution_ir}{data}{operation_graph}{operations}};
    my ($inout_drive_binding) = grep {
        ($_->{semantic_id} // '')
            eq $inout_drive_operation->{effects}[0]{target_id}
    } @{$inout_drive_plan->{execution_ir}{data}{bindings}{endpoints}};
    $inout_drive_binding->{carrier_direction} = 'inout';
    my ($inout_bridge_endpoint) = grep {
        ($_->{endpoint_id} // '') eq $inout_drive_binding->{endpoint_id}
    } @{$inout_drive_plan->{bridge_manifest}{data}{endpoints}};
    $inout_bridge_endpoint->{direction} = 'inout';
    my $inout_drive = emit_backend(
        execution_ir => $inout_drive_plan->{execution_ir},
        bridge_manifest => $inout_drive_plan->{bridge_manifest},
        backend_inputs => $inout_drive_plan->{backend_inputs},
    );
    backend_failure(
        $inout_drive, 'VIAL_BACKEND_UNSUPPORTED',
        'direct-drive inout carrier',
    );
    is_deeply(
        $inout_drive->{negotiation}{unsatisfied},
        ["direct-drive:$inout_drive_operation->{operation_id}:carrier-direction"],
        'inout direct drive fails closed at its exact published profile boundary',
    );

    my $wrong_drive_value_plan = build_plan(direct_drive_source());
    my ($wrong_drive_value_operation) = grep {
        ($_->{kind} // '') eq 'drive'
    } @{$wrong_drive_value_plan->{execution_ir}{data}{operation_graph}{operations}};
    my ($wrong_drive_value_input) = grep {
        ($_->{name} // '') eq 'value'
    } @{$wrong_drive_value_operation->{typed_inputs}};
    $wrong_drive_value_input->{value}{type_id} = 'execution-type/forged';
    my $wrong_drive_value = emit_backend(
        execution_ir => $wrong_drive_value_plan->{execution_ir},
        bridge_manifest => $wrong_drive_value_plan->{bridge_manifest},
        backend_inputs => $wrong_drive_value_plan->{backend_inputs},
    );
    backend_failure(
        $wrong_drive_value, 'VIAL_BACKEND_UNSUPPORTED',
        'direct-drive value-type drift',
    );
    is_deeply(
        $wrong_drive_value->{negotiation}{unsatisfied},
        ["direct-drive:$wrong_drive_value_operation->{operation_id}:value"],
        'value-type drift names the exact rejected direct operation',
    );

    my $parallel_drive_plan = build_plan(parallel_direct_drive_source());
    ok($parallel_drive_plan->{ok}, 'target-neutral plan retains parallel direct-drive intent');
    diag($json->encode($parallel_drive_plan->{diagnostics}))
        unless $parallel_drive_plan->{ok};
    my @parallel_drive_operation = grep {
        ($_->{kind} // '') eq 'drive'
    } @{$parallel_drive_plan->{execution_ir}{data}{operation_graph}{operations}};
    my ($parallel_drive_parent) = grep {
        ($_->{kind} // '') eq 'parallel'
    } @{$parallel_drive_plan->{execution_ir}{data}{operation_graph}{operations}};
    my $parallel_drive = emit_backend(
        execution_ir => $parallel_drive_plan->{execution_ir},
        bridge_manifest => $parallel_drive_plan->{bridge_manifest},
        backend_inputs => $parallel_drive_plan->{backend_inputs},
    );
    backend_failure(
        $parallel_drive, 'VIAL_BACKEND_UNSUPPORTED',
        'same-phase parallel direct-drive conflict',
    );
    is_deeply(
        $parallel_drive->{negotiation}{unsatisfied},
        [
            'direct-drive-conflict:'
                . $parallel_drive_operation[0]{scenario_id} . ':'
                . $parallel_drive_operation[0]{effects}[0]{target_id},
            'parallel-child:' . $parallel_drive_parent->{operation_id} . ':'
                . $parallel_drive_operation[0]{operation_id}
                . ':unsupported-kind:drive',
            'parallel-child:' . $parallel_drive_parent->{operation_id} . ':'
                . $parallel_drive_operation[1]{operation_id}
                . ':unsupported-kind:drive',
        ],
        'live sibling writes and both unsupported child operations fail closed without a host-order winner',
    );

    my $invocation = FSM::VIAL::Backend::SVPortableVerilator->emit({});
    backend_failure($invocation, 'VIAL_BACKEND_INVOCATION_ERROR', 'incomplete invocation');
};

subtest 'pure trace validation projects a closed stream without executing semantics' => sub {
    my $trace = valid_trace($built->{execution_ir});
    my $validated = FSM::VIAL::Backend::TraceValidator->validate({
        execution_ir => $built->{execution_ir},
        trace_text => $trace,
        simulator_exit_code => 0,
    });
    ok($validated->{ok}, 'complete caller-supplied trace validates');
    diag($json->encode($validated->{diagnostics})) unless $validated->{ok};
    is_deeply(
        [sort keys %$validated],
        [sort @{FSM::VIAL::Backend::TraceValidator->result_keys}],
        'trace-validation result is closed',
    );
    is($validated->{status}, 'validated', 'validator reports validation only');
    is($validated->{projection}{result_manifest_status}, 'not_produced', 'trace projection does not claim a public result');
    is($validated->{projection}{record_count}, 7, 'trace projection records exact stream size');
    is($validated->{projection}{counts}{events}, 1, 'trace projection preserves semantic family counts');
    like($validated->{projection}{trace_sha256}, qr{\A[0-9a-f]{64}\z}, 'trace projection hashes canonical JSONL');
    my $copy = $validated->{records}[0]{payload}{fixture_id};
    $validated->{records}[0]{payload}{fixture_id} = 'mutated';
    my $again = FSM::VIAL::Backend::TraceValidator->validate({
        execution_ir => $built->{execution_ir}, trace_text => $trace, simulator_exit_code => 0,
    });
    is($again->{records}[0]{payload}{fixture_id}, $copy, 'trace projections are deeply defensive');

    trace_failure($trace, 9, 'VIAL_TRACE_TOOL_EXIT_ERROR', 'nonzero simulator exit');
    my $missing_prefix = $trace;
    $missing_prefix =~ s/\AFSMGEN_VIAL_TRACE_V1\t//;
    trace_failure($missing_prefix, 0, 'VIAL_TRACE_SCHEMA_ERROR', 'missing machine prefix');
    my $noncanonical = $trace;
    $noncanonical =~ s/}\n/ }\n/;
    trace_failure($noncanonical, 0, 'VIAL_TRACE_SCHEMA_ERROR', 'noncanonical JSON');
    my $truncated = $trace;
    $truncated =~ s/FSMGEN_VIAL_TRACE_V1\t[^\n]+\n\z//;
    trace_failure($truncated, 0, 'VIAL_TRACE_SCHEMA_ERROR', 'missing footer');
    my $wrong_sequence = mutate_record($trace, 2, sub { $_[0]{sequence} = 99 });
    trace_failure($wrong_sequence, 0, 'VIAL_TRACE_SEQUENCE_ERROR', 'out-of-order sequence');
    my $forged = mutate_record($trace, 2, sub { $_[0]{record_kind} = 'plausible_display' });
    trace_failure($forged, 0, 'VIAL_TRACE_SCHEMA_ERROR', 'unknown record kind');
    my $bad_counts = mutate_record($trace, 6, sub { $_[0]{payload}{counts}{events} = 2 });
    trace_failure($bad_counts, 0, 'VIAL_TRACE_COUNT_ERROR', 'footer count mismatch');

    my $direct_plan = build_plan(direct_drive_source());
    my $direct_trace = valid_direct_drive_trace($direct_plan->{execution_ir});
    my $direct_validated = FSM::VIAL::Backend::TraceValidator->validate({
        execution_ir => $direct_plan->{execution_ir},
        trace_text => $direct_trace,
        simulator_exit_code => 0,
    });
    ok($direct_validated->{ok}, 'exact direct-drive trace validates');
    diag($json->encode($direct_validated->{diagnostics}))
        unless $direct_validated->{ok};
    is(
        $direct_validated->{projection}{counts}{drives}, 1,
        'direct-drive trace projection retains one genuine drive record',
    );
    my $wrong_direct_endpoint = mutate_record(
        $direct_trace, 2,
        sub { $_[0]{payload}{endpoint_id} = 'endpoint/HRESP' },
    );
    trace_failure_for(
        $direct_plan->{execution_ir}, $wrong_direct_endpoint, 0,
        'VIAL_TRACE_IDENTITY_ERROR', 'forged direct-drive endpoint',
    );
    my $wrong_direct_value = mutate_record(
        $direct_trace, 2,
        sub { $_[0]{payload}{effective_value}{value_hex} = '0' },
    );
    trace_failure_for(
        $direct_plan->{execution_ir}, $wrong_direct_value, 0,
        'VIAL_TRACE_IDENTITY_ERROR', 'forged direct-drive value',
    );
    my $wrong_direct_phase = mutate_record(
        $direct_trace, 2,
        sub { $_[0]{payload}{logical_time}{phase_rank} = 1 },
    );
    trace_failure_for(
        $direct_plan->{execution_ir}, $wrong_direct_phase, 0,
        'VIAL_TRACE_IDENTITY_ERROR', 'forged direct-drive phase',
    );
};

subtest 'portable parallel children fail closed outside the qualified single-await leaf profile' => sub {
    my $reset_child_plan = build_plan(parallel_reset_child_source());
    ok($reset_child_plan->{ok},
        'ordinary source reaches target-neutral ExecutionIR with a reset child');
    diag($json->encode($reset_child_plan->{diagnostics}))
        unless $reset_child_plan->{ok};
    my $execution = $reset_child_plan->{execution_ir}->as_hashref;
    my ($parallel) = grep { ($_->{kind} // '') eq 'parallel' }
        @{$execution->{operation_graph}{operations}};
    my ($reset) = grep {
        ($_->{kind} // '') eq 'reset'
            && ($_->{fiber_id} // '') ne ($execution->{scenarios}[0]{root_fiber_id} // '')
    } @{$execution->{operation_graph}{operations}};
    ok(defined($parallel) && defined($reset),
        'RED retains the exact parent and non-root reset operation identities');

    my $emitted = emit_plan($reset_child_plan);
    backend_failure(
        $emitted, 'VIAL_BACKEND_UNSUPPORTED',
        'ordinary non-await parallel child',
    );
    my $unsatisfied = ref($emitted->{negotiation}) eq 'HASH'
        ? $emitted->{negotiation}{unsatisfied} : [];
    is_deeply(
        $unsatisfied,
        ["parallel-child:$parallel->{operation_id}:$reset->{operation_id}:unsupported-kind:reset"],
        'negotiation names the exact parent, child, and unsupported operation kind',
    );
    my $repeated = emit_plan($reset_child_plan);
    is($json->encode($repeated), $json->encode($emitted),
        'the complete unsupported result repeats byte-identically');

    my $multi_plan = build_plan(parallel_multi_action_child_source());
    ok($multi_plan->{ok},
        'ordinary source reaches target-neutral ExecutionIR with a two-operation child');
    diag($json->encode($multi_plan->{diagnostics})) unless $multi_plan->{ok};
    my $multi_execution = $multi_plan->{execution_ir}->as_hashref;
    my ($multi_parent) = grep { ($_->{kind} // '') eq 'parallel' }
        @{$multi_execution->{operation_graph}{operations}};
    my ($multi_effect) = grep { ($_->{kind} // '') eq 'activate_fibers' }
        @{$multi_parent->{effects}};
    my $multi_child_id = $multi_effect->{child_root_operation_ids}[0];
    my $multi_emitted = emit_plan($multi_plan);
    backend_failure(
        $multi_emitted, 'VIAL_BACKEND_UNSUPPORTED',
        'ordinary multi-operation parallel child',
    );
    is_deeply(
        $multi_emitted->{negotiation}{unsatisfied},
        ["parallel-child:$multi_parent->{operation_id}:$multi_child_id:operation-count:2"],
        'multi-operation child fails at the exact parent and child root before lowering',
    );

    my %phase_for = (
        reset => 'drive', drive => 'drive', start => 'drive',
        parallel => 'react', repeat => 'react', expect => 'check',
        scoreboard_expect => 'react', scoreboard_check => 'check',
        inject => 'react',
    );
    my $inventory_plan = build_plan();
    my $inventory_execution = $inventory_plan->{execution_ir}{data};
    my ($inventory_parent) = grep { ($_->{kind} // '') eq 'parallel' }
        @{$inventory_execution->{operation_graph}{operations}};
    my ($inventory_effect) = grep { ($_->{kind} // '') eq 'activate_fibers' }
        @{$inventory_parent->{effects}};
    my $inventory_child_id = $inventory_effect->{child_root_operation_ids}[0];
    my ($inventory_child) = grep {
        ($_->{operation_id} // '') eq $inventory_child_id
    } @{$inventory_execution->{operation_graph}{operations}};
    for my $kind (sort keys %phase_for) {
        $inventory_child->{kind} = $kind;
        $inventory_child->{eligible_phase} = $phase_for{$kind};
        my $candidate = emit_plan($inventory_plan);
        backend_failure(
            $candidate, 'VIAL_BACKEND_UNSUPPORTED',
            "parallel child kind $kind",
        );
        my $wanted = "parallel-child:$inventory_parent->{operation_id}:"
            . "$inventory_child_id:unsupported-kind:$kind";
        ok(scalar(grep { $_ eq $wanted }
                @{$candidate->{negotiation}{unsatisfied}}),
            "$kind has an exact fail-closed child-profile diagnostic");
    }

    my $duplicate_plan = build_plan();
    my $duplicate_execution = $duplicate_plan->{execution_ir}{data};
    my ($duplicate_parent) = grep { ($_->{kind} // '') eq 'parallel' }
        @{$duplicate_execution->{operation_graph}{operations}};
    my ($duplicate_effect) = grep { ($_->{kind} // '') eq 'activate_fibers' }
        @{$duplicate_parent->{effects}};
    my $duplicate_child_id = $duplicate_effect->{child_root_operation_ids}[0];
    my $unowned_child_id = $duplicate_effect->{child_root_operation_ids}[1];
    my ($unowned_child) = grep {
        ($_->{operation_id} // '') eq $unowned_child_id
    } @{$duplicate_execution->{operation_graph}{operations}};
    $duplicate_effect->{child_root_operation_ids}[1] = $duplicate_child_id;
    my $duplicate = emit_plan($duplicate_plan);
    backend_failure(
        $duplicate, 'VIAL_BACKEND_UNSUPPORTED',
        'duplicate parallel child root',
    );
    ok(
        scalar(grep {
            $_ eq "parallel-child:$duplicate_parent->{operation_id}:"
                . "$duplicate_child_id:duplicate-child-root"
        } @{$duplicate->{negotiation}{unsatisfied}})
            && scalar(grep {
                $_ eq 'parallel-fiber:' . $unowned_child->{scenario_id} . ':'
                    . $unowned_child->{fiber_id} . ':owner-count:0'
            } @{$duplicate->{negotiation}{unsatisfied}}),
        'duplicate roots and the resulting unowned fiber both fail explicitly',
    );

    for my $case (
        ['property input', sub { my ($child) = @_; $child->{typed_inputs} = [] }],
        ['property input container', sub {
            my ($child) = @_;
            $child->{typed_inputs} = {};
        }],
        ['evaluation effect', sub { my ($child) = @_; $child->{effects} = [] }],
        ['evaluation effect container', sub {
            my ($child) = @_;
            $child->{effects} = {};
        }],
        ['terminal successor', sub {
            my ($child) = @_;
            $child->{successor_ids} = ['operation/forged-successor'];
        }],
        ['check deadline', sub {
            my ($child) = @_;
            $child->{deadline}{phase} = 'react';
        }],
    ) {
        my $shape_plan = build_plan();
        my $shape_execution = $shape_plan->{execution_ir}{data};
        my ($shape_parent) = grep { ($_->{kind} // '') eq 'parallel' }
            @{$shape_execution->{operation_graph}{operations}};
        my ($shape_effect) = grep { ($_->{kind} // '') eq 'activate_fibers' }
            @{$shape_parent->{effects}};
        my $shape_child_id = $shape_effect->{child_root_operation_ids}[0];
        my ($shape_child) = grep {
            ($_->{operation_id} // '') eq $shape_child_id
        } @{$shape_execution->{operation_graph}{operations}};
        $case->[1]->($shape_child);
        my $shape = emit_plan($shape_plan);
        backend_failure(
            $shape, 'VIAL_BACKEND_UNSUPPORTED',
            "malformed parallel await $case->[0]",
        );
        ok(
            scalar(grep {
                $_ eq "parallel-child:$shape_parent->{operation_id}:"
                    . "$shape_child_id:await-shape"
            } @{$shape->{negotiation}{unsatisfied}}),
            "malformed await $case->[0] fails at the structural boundary",
        );
    }

    my $effect_plan = build_plan();
    my $effect_execution = $effect_plan->{execution_ir}{data};
    my ($effect_parent) = grep { ($_->{kind} // '') eq 'parallel' }
        @{$effect_execution->{operation_graph}{operations}};
    $effect_parent->{effects} = {};
    my $bad_effect = emit_plan($effect_plan);
    backend_failure(
        $bad_effect, 'VIAL_BACKEND_UNSUPPORTED',
        'parallel parent with malformed effect container',
    );
    ok(
        scalar(grep {
            $_ eq "parallel-child:$effect_parent->{operation_id}:effect"
        } @{$bad_effect->{negotiation}{unsatisfied}}),
        'malformed parent-effect container fails inside negotiation',
    );

    my $parentage_plan = build_plan();
    my $parentage_execution = $parentage_plan->{execution_ir}{data};
    my ($parentage_parent) = grep { ($_->{kind} // '') eq 'parallel' }
        @{$parentage_execution->{operation_graph}{operations}};
    my ($parentage_effect) = grep { ($_->{kind} // '') eq 'activate_fibers' }
        @{$parentage_parent->{effects}};
    my $parentage_child_id = $parentage_effect->{child_root_operation_ids}[0];
    my ($parentage_child) = grep {
        ($_->{operation_id} // '') eq $parentage_child_id
    } @{$parentage_execution->{operation_graph}{operations}};
    my ($parentage_fiber) = grep {
        ($_->{fiber_id} // '') eq ($parentage_child->{fiber_id} // '')
    } @{$parentage_execution->{scenarios}[0]{fibers}};
    $parentage_fiber->{parent_fiber_id} = 'fiber/forged-parent';
    my $parentage = emit_plan($parentage_plan);
    backend_failure(
        $parentage, 'VIAL_BACKEND_UNSUPPORTED',
        'parallel child with forged direct parent',
    );
    ok(
        scalar(grep {
            $_ eq "parallel-child:$parentage_parent->{operation_id}:"
                . "$parentage_child_id:fiber"
        } @{$parentage->{negotiation}{unsatisfied}}),
        'forged direct parent fails with exact parent/child identity',
    );

    my $multi_owner_plan = build_plan();
    my $multi_owner_execution = $multi_owner_plan->{execution_ir}{data};
    my ($owner_parent) = grep { ($_->{kind} // '') eq 'parallel' }
        @{$multi_owner_execution->{operation_graph}{operations}};
    my $forged_owner = $json->decode($json->encode($owner_parent));
    $forged_owner->{operation_id} .= '/forged-owner';
    push @{$multi_owner_execution->{operation_graph}{operations}}, $forged_owner;
    my $multi_owner = emit_plan($multi_owner_plan);
    backend_failure(
        $multi_owner, 'VIAL_BACKEND_UNSUPPORTED',
        'parallel fibers with multiple owners',
    );
    my @owned_fiber = map {
        my $child_id = $_;
        my ($operation) = grep { ($_->{operation_id} // '') eq $child_id }
            @{$multi_owner_execution->{operation_graph}{operations}};
        $operation->{fiber_id}
    } @{$owner_parent->{effects}[0]{child_root_operation_ids}};
    for my $fiber_id (@owned_fiber) {
        ok(
            scalar(grep {
                $_ eq 'parallel-fiber:' . $owner_parent->{scenario_id} . ':'
                    . "$fiber_id:owner-count:2"
            } @{$multi_owner->{negotiation}{unsatisfied}}),
            "multiply owned fiber $fiber_id fails before artifacts",
        );
    }

    my $qualified = emit_backend();
    ok($qualified->{ok}, 'the existing qualified single-await topology still emits');
    ok(
        scalar(grep { $_ eq 'single_await_parallel_children_only' }
            @{$qualified->{negotiation}{limitations}})
            && scalar(grep {
                $_ eq 'parallel child fibers are limited to exactly one await operation'
            } @{$qualified->{backend_manifest}{limitations}}),
        'machine and human manifests publish the exact child-fiber boundary',
    );
};

subtest 'capability discovery distinguishes bounded AHB parity from general parity' => sub {
    my $contract = build_vial_execution_contract();
    is_deeply([sort keys %$contract], [sort @{vial_execution_contract_keys()}], 'private execution/backend contract is closed');
    is($contract->{backend_profile}, 'sv_portable_verilator', 'capability contract names the exact backend');
    is($contract->{backend_stage_status}{emission}, 'shipped_public_run_pipeline', 'emission participates in the public run pipeline');
    is($contract->{backend_stage_status}{trace_validation}, 'shipped_public_run_pipeline', 'trace validation participates in the public run pipeline');
    is($contract->{backend_stage_status}{compile}, 'shipped_exact_verilator_5_046', 'exact Verilator compile is shipped');
    is($contract->{backend_stage_status}{runtime}, 'shipped_known_value_declared_probe_profile', 'bounded runtime is shipped');
    is($contract->{backend_stage_status}{result}, 'shipped_verification_result_manifest_v1', 'result production is shipped');
    is($contract->{backend_stage_status}{parity}, 'shipped_handwritten_ahb_oracle', 'bounded handwritten AHB parity is shipped');
    ok($contract->{writes_files}, 'execution records operation-owned staging and publication');
    ok(
        scalar(grep { $_ eq 'non_root_direct_drive' }
            @{$contract->{explicit_nonclaims}})
            && scalar(grep { $_ eq 'inout_direct_drive' }
                @{$contract->{explicit_nonclaims}})
            && scalar(grep { $_ eq 'general_parallel_child_sequences' }
                @{$contract->{explicit_nonclaims}}),
        'execution support truth denies unqualified direct-drive and parallel-child profiles',
    );
    ok($contract->{public_embedding_api}, 'execution is exposed through the public VIAL tool API');
    my $manifest = build_capability_manifest();
    is_deeply($manifest->{language_surface}{vial_execution}, $contract, 'capability manifest publishes the exact private stage boundary');
};

done_testing();

sub build_plan {
    my ($vial_text) = @_;
    $vial_text //= slurp_raw(repo_path($vial_id));
    my $semantic_ir = FSM::VIAL::Parser->parse_source({
        text => $vial_text,
        source_name => $vial_id,
        source_catalog => {},
    });
    return FSM::VIAL::PlanBuilder->build({
        semantic_ir => $semantic_ir,
        hial_source => {
            source_id => $hial_id,
            text => slurp_raw(repo_path($hial_id)),
            format => 'ppif',
        },
        fixture_id => undef,
        scenario_ids => [],
        execution_profile => 'core_directed_single_clock_execution_v1',
        replay_manifest => undef,
        native_extension_catalog => [],
    });
}

sub emitted_fixture_source {
    my ($plan) = @_;
    my $emitted = emit_plan($plan);
    ok($emitted->{ok}, 'phase-order fixture emits successfully');
    diag($json->encode($emitted->{diagnostics})) unless $emitted->{ok};
    my ($fixture) = grep {
        $_->{relpath} eq 'backends/sv_portable_verilator/src/base_output_arbitration_tb.sv'
    } @{$emitted->{artifacts} || []};
    return defined($fixture) ? $fixture->{content} : '';
}

sub emit_plan {
    my ($plan) = @_;
    return FSM::VIAL::Backend::SVPortableVerilator->emit({
        execution_ir => $plan->{execution_ir},
        bridge_manifest => $plan->{bridge_manifest},
        backend_inputs => $plan->{backend_inputs},
        artifact_root => '.artifacts/test/vial-portable-sv-emission',
        backend_profile => 'sv_portable_verilator',
    });
}

sub emit_backend {
    my (%override) = @_;
    return FSM::VIAL::Backend::SVPortableVerilator->emit({
        execution_ir => $built->{execution_ir},
        bridge_manifest => $built->{bridge_manifest},
        backend_inputs => $built->{backend_inputs},
        artifact_root => '.artifacts/test/vial-portable-sv-emission',
        backend_profile => 'sv_portable_verilator',
        %override,
    });
}

sub valid_trace {
    my ($execution_ir) = @_;
    my $execution = $execution_ir->as_hashref;
    my @scenario_runs = map {{
        scenario_id => $_->{scenario_id},
        run_id => "run/$execution->{plan_id}/$_->{scenario_id}",
    }} @{$execution->{scenarios}};
    my @record;
    push @record, trace_record(
        'header', $execution->{plan_id}, undef,
        {
            fixture_id => $execution->{fixture}{fixture_id},
            execution_profile => $execution->{profile},
            backend_profile => 'sv_portable_verilator',
            scenario_runs => \@scenario_runs,
            decision_digest => sha256_hex($json->encode($execution->{randomness}{decisions})),
        },
    );
    push @record, trace_record(
        'scenario_start', $execution->{plan_id}, $scenario_runs[0]{run_id},
        {scenario_id => $scenario_runs[0]{scenario_id}},
    );
    push @record, trace_record(
        'events', $execution->{plan_id}, $scenario_runs[0]{run_id},
        {
            logical_time => {
                cycle => 1, phase_rank => 1, domain_rank => 0,
                static_operation_rank => 2, local_emission_index => 0,
                semantic_id => 'event/ahb_write/accepted',
            },
            event_id => 'event/ahb_write/accepted',
            event_occurrence_index => 0,
            record_id => 'record/' . $scenario_runs[0]{scenario_id}
                . '/events/event/ahb_write/accepted/0',
            run_id => $scenario_runs[0]{run_id},
            semantic_id => (grep {
                $_->{event_id} eq 'event/ahb_write/accepted'
            } @{$execution->{events}})[0]{semantic_id},
        },
    );
    push @record, trace_record(
        'scenario_end', $execution->{plan_id}, $scenario_runs[0]{run_id},
        {logical_cycle_count => 2, scenario_id => $scenario_runs[0]{scenario_id}, status => 'passed'},
    );
    push @record, trace_record(
        'scenario_start', $execution->{plan_id}, $scenario_runs[1]{run_id},
        {scenario_id => $scenario_runs[1]{scenario_id}},
    );
    push @record, trace_record(
        'scenario_end', $execution->{plan_id}, $scenario_runs[1]{run_id},
        {logical_cycle_count => 1, scenario_id => $scenario_runs[1]{scenario_id}, status => 'passed'},
    );
    my %count;
    $count{$_->{record_kind}}++ for @record;
    $count{footer} = 1;
    push @record, trace_record(
        'footer', $execution->{plan_id}, undef,
        {
            status => 'passed',
            scenario_completion_summaries => [map {{%$_, status => 'passed'}} @scenario_runs],
            counts => {map { $_ => $count{$_} } sort keys %count},
            clean_termination => JSON::PP::true,
        },
    );
    $record[$_]{sequence} = $_ for 0 .. $#record;
    return join('', map { "FSMGEN_VIAL_TRACE_V1\t" . $json->encode($_) . "\n" } @record);
}

sub valid_direct_drive_trace {
    my ($execution_ir) = @_;
    my $execution = $execution_ir->as_hashref;
    my @scenario_runs = map {{
        scenario_id => $_->{scenario_id},
        run_id => "run/$execution->{plan_id}/$_->{scenario_id}",
    }} @{$execution->{scenarios}};
    my ($drive) = grep { ($_->{kind} // '') eq 'drive' }
        @{$execution->{operation_graph}{operations}};
    my %input = map { $_->{name} => $_->{value} } @{$drive->{typed_inputs}};
    my ($binding) = grep {
        ($_->{semantic_id} // '') eq $input{endpoint_id}
    } @{$execution->{bindings}{endpoints}};
    my @record = (
        trace_record(
            'header', $execution->{plan_id}, undef,
            {
                fixture_id => $execution->{fixture}{fixture_id},
                execution_profile => $execution->{profile},
                backend_profile => 'sv_portable_verilator',
                scenario_runs => \@scenario_runs,
                decision_digest => sha256_hex(
                    $json->encode($execution->{randomness}{decisions}),
                ),
            },
        ),
        trace_record(
            'scenario_start', $execution->{plan_id}, $scenario_runs[0]{run_id},
            {scenario_id => $scenario_runs[0]{scenario_id}},
        ),
        trace_record(
            'drives', $execution->{plan_id}, $scenario_runs[0]{run_id},
            {
                effective_value => $input{value}{value},
                endpoint_id => $binding->{endpoint_id},
                logical_time => {
                    cycle => 5,
                    domain_rank => 0,
                    phase_rank => 0,
                    static_operation_rank => $drive->{static_rank},
                    local_emission_index => 0,
                    semantic_id => $binding->{semantic_id},
                },
                operation_id => $drive->{operation_id},
                record_id => 'record/' . $scenario_runs[0]{scenario_id}
                    . '/drives/' . $binding->{semantic_id} . '/0',
                run_id => $scenario_runs[0]{run_id},
                transaction_field_id => undef,
            },
        ),
        trace_record(
            'scenario_end', $execution->{plan_id}, $scenario_runs[0]{run_id},
            {
                logical_cycle_count => 6,
                scenario_id => $scenario_runs[0]{scenario_id},
                status => 'passed',
            },
        ),
    );
    for my $index (1 .. $#scenario_runs) {
        push @record,
            trace_record(
                'scenario_start', $execution->{plan_id},
                $scenario_runs[$index]{run_id},
                {scenario_id => $scenario_runs[$index]{scenario_id}},
            ),
            trace_record(
                'scenario_end', $execution->{plan_id},
                $scenario_runs[$index]{run_id},
                {
                    logical_cycle_count => 1,
                    scenario_id => $scenario_runs[$index]{scenario_id},
                    status => 'passed',
                },
            );
    }
    my %count;
    $count{$_->{record_kind}}++ for @record;
    $count{footer} = 1;
    push @record, trace_record(
        'footer', $execution->{plan_id}, undef,
        {
            status => 'passed',
            scenario_completion_summaries => [
                map {{%$_, status => 'passed'}} @scenario_runs
            ],
            counts => {map { $_ => $count{$_} } sort keys %count},
            clean_termination => JSON::PP::true,
        },
    );
    $record[$_]{sequence} = $_ for 0 .. $#record;
    return join('', map {
        "FSMGEN_VIAL_TRACE_V1\t" . $json->encode($_) . "\n"
    } @record);
}

sub trace_record {
    my ($kind, $plan_id, $run_id, $payload) = @_;
    return {
        schema => 'fsmgen.vial_sv_runtime_trace.v1',
        schema_version => 1,
        record_kind => $kind,
        plan_id => $plan_id,
        run_id => $run_id,
        sequence => 0,
        payload => $payload,
    };
}

sub mutate_record {
    my ($trace, $wanted, $mutate) = @_;
    my @line = split /\n/, $trace;
    my $prefix = "FSMGEN_VIAL_TRACE_V1\t";
    my $record = JSON::PP->new->decode(substr($line[$wanted], length($prefix)));
    $mutate->($record);
    $line[$wanted] = $prefix . $json->encode($record);
    return join("\n", @line) . "\n";
}

sub backend_failure {
    my ($result, $code, $label) = @_;
    ok(!$result->{ok}, "$label fails");
    is($result->{diagnostics}[0]{code}, $code, "$label has exact diagnostic");
    is_deeply($result->{artifacts}, [], "$label emits no partial artifact");
    is($result->{backend_manifest}, undef, "$label emits no backend manifest");
}

sub trace_failure {
    my ($trace, $exit, $code, $label) = @_;
    return trace_failure_for($built->{execution_ir}, $trace, $exit, $code, $label);
}

sub trace_failure_for {
    my ($execution_ir, $trace, $exit, $code, $label) = @_;
    my $result = FSM::VIAL::Backend::TraceValidator->validate({
        execution_ir => $execution_ir,
        trace_text => $trace,
        simulator_exit_code => $exit,
    });
    ok(!$result->{ok}, "$label fails");
    is($result->{diagnostics}[0]{code}, $code, "$label has exact diagnostic");
    is_deeply($result->{records}, [], "$label exposes no partial trace");
    is($result->{projection}, undef, "$label exposes no partial projection");
}

sub repo_path {
    my ($relative) = @_;
    return File::Spec->catfile($FindBin::Bin, '..', split m{/}, $relative);
}

sub slurp_raw {
    my ($path) = @_;
    open my $fh, '<:raw', $path or die "cannot read $path: $!";
    local $/;
    my $text = <$fh>;
    close $fh or die "cannot close $path: $!";
    return $text;
}

sub direct_drive_source {
    my $text = slurp_raw(repo_path($vial_id));
    $text =~ s{
        (\(endpoints\n)
    }{$1            (endpoint select "endpoint/HSEL" (logic 1) public_port)\n}x
        or die 'direct-drive source mutation did not find fixture endpoints';
    $text =~ s{
        (\(reset\ bus\ 3\)\n)
    }{$1              (drive select #b1)\n}x
        or die 'direct-drive source mutation did not find the success reset';
    return $text;
}

sub parallel_direct_drive_source {
    my $text = direct_drive_source();
    $text =~ s{
        \(drive\ select\ \#b1\)
    }{(parallel all
                (fiber direct_zero (drive select #b0))
                (fiber direct_one (drive select #b1)))}x
        or die 'parallel-drive source mutation did not find the direct drive';
    return $text;
}

sub parallel_reset_child_source {
    my $text = slurp_raw(repo_path($vial_id));
    $text =~ s{
        \(await\ \(within\ \(event\ success_write\ completed\)\ 1\ 256\)\)
    }{(reset bus 1)}x
        or die 'parallel-reset source mutation did not find the first child await';
    return $text;
}

sub parallel_multi_action_child_source {
    my $text = slurp_raw(repo_path($vial_id));
    $text =~ s{
        \(await\ \(within\ \(event\ success_write\ completed\)\ 1\ 256\)\)
    }{(await (within (event success_write completed) 1 256))
                  (reset bus 1)}x
        or die 'parallel-multi source mutation did not find the first child await';
    return $text;
}
