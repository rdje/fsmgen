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
    ok($contract->{public_embedding_api}, 'execution is exposed through the public VIAL tool API');
    my $manifest = build_capability_manifest();
    is_deeply($manifest->{language_surface}{vial_execution}, $contract, 'capability manifest publishes the exact private stage boundary');
};

done_testing();

sub build_plan {
    my $semantic_ir = FSM::VIAL::Parser->parse_source({
        text => slurp_raw(repo_path($vial_id)),
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
    my $result = FSM::VIAL::Backend::TraceValidator->validate({
        execution_ir => $built->{execution_ir},
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
