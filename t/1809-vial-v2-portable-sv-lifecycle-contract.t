#!/usr/bin/env perl

use v5.20;
use strict;
use warnings;

use Digest::SHA qw(sha256_hex);
use File::Spec;
use FindBin;
use JSON::PP ();
use Test::More;

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::Support::VIALSemanticFamilyBackendAdapter qw(
    build_vial_semantic_family_backend_adapter_registry
);
use FSM::Support::VIALSemanticFamilyRegistry qw(
    build_vial_semantic_family_registry
);
use FSM::Support::VIALToolingContract qw(build_vial_tooling_contract_v2);
use FSM::VIAL::Backend::ResultProducer;
use FSM::VIAL::Backend::Runner;
use FSM::VIAL::Backend::SVPortableVerilator;
use FSM::VIAL::Backend::TraceValidator;
use FSM::VIAL::Parser;
use FSM::VIAL::PlanBuilder;

my $repo_root = File::Spec->catdir($FindBin::Bin, '..');
my $v1_name = 'vial/ahb_subordinate_base_output_arbitration.vial';
my $v2_name = 'vial/ahb_subordinate_base_output_arbitration_lifecycle_v2.vial';
my $hial_name = 'ppif/ahb_lite_subordinate.ppif';
my $spec_rel = 'docs/vial-spec/portable-systemverilog-lifecycle-v2.md';
my $decision_rel = 'docs/decisions/0100-portable-systemverilog-lifecycle-uses-a-static-check-seam-controller.md';
my $landing_rel = 'docs/VIAL_SOURCE_AND_SEMANTIC_IR_V2_CONTRACT.md';
my $book_rel = 'docs/book/src/16dg-vial-public-lifecycle-reference.md';
my $artifact_root = '.artifacts/test/vial-v2-portable-lifecycle-contract';
my $json = JSON::PP->new->canonical(1)->utf8(1);

sub repo_path {
    my ($relative) = @_;
    return File::Spec->catfile($repo_root, split m{/}, $relative);
}

sub slurp_raw {
    my ($relative) = @_;
    my $path = repo_path($relative);
    open my $fh, '<:raw', $path or die "cannot read $path: $!\n";
    local $/;
    my $text = <$fh> // '';
    close $fh or die "cannot close $path: $!\n";
    return $text;
}

sub build_plan {
    my ($version, $source_name) = @_;
    my $semantic_ir = FSM::VIAL::Parser->parse_source({
        text => slurp_raw($source_name),
        source_name => $source_name,
        source_catalog => {},
    });
    my $built = FSM::VIAL::PlanBuilder->build({
        semantic_ir => $semantic_ir,
        hial_source => {
            source_id => $hial_name,
            format => 'ppif',
            text => slurp_raw($hial_name),
        },
        fixture_id => undef,
        scenario_ids => [],
        execution_profile => "core_directed_single_clock_execution_v$version",
        replay_manifest => undef,
        native_extension_catalog => [],
    });
    die "v$version contract plan failed: "
        . $json->encode($built->{diagnostics}) . "\n" unless $built->{ok};
    return $built;
}

sub emit_plan {
    my ($built, $root) = @_;
    $root //= $artifact_root;
    return FSM::VIAL::Backend::SVPortableVerilator->emit({
        execution_ir => $built->{execution_ir},
        bridge_manifest => $built->{bridge_manifest},
        backend_inputs => $built->{backend_inputs},
        artifact_root => $root,
        backend_profile => 'sv_portable_verilator',
    });
}

sub contract_json {
    my ($text) = @_;
    my ($encoded) = $text =~ m{
        <!--\ portable-lifecycle-contract-json:start\ -->\s*
        ```json\s*\n(.*?)\n```\s*
        <!--\ portable-lifecycle-contract-json:end\ -->
    }xs;
    die "portable lifecycle machine contract is missing\n"
        unless defined $encoded;
    return JSON::PP->new->decode($encoded);
}

my $spec = slurp_raw($spec_rel);
my $decision = slurp_raw($decision_rel);
my $landing = slurp_raw($landing_rel);
my $book = slurp_raw($book_rel);
my $contract = contract_json($spec);
my $v2 = build_plan(2, $v2_name);

subtest 'bounded references route one accepted mapping decision' => sub {
    like($decision, qr{^# Decision 0100:}m,
        'decision identity is exact');
    like($decision, qr{- \*\*Status:\*\* Accepted},
        'mapping decision is accepted');
    like(
        $landing,
        qr{\[Selected portable-SystemVerilog lifecycle mapping and backend evidence contract\]\(vial-spec/portable-systemverilog-lifecycle-v2[.]md\)},
        'mandatory v2 landing routes the bounded mapping part',
    );
    like(
        $book,
        qr{\[portable-SystemVerilog lifecycle mapping contract\]\(../../vial-spec/portable-systemverilog-lifecycle-v2[.]md\)},
        'mdBook routes the normative mapping part',
    );
    like($book, qr{selected, not implemented},
        'mdBook distinguishes selection from runtime availability');
};

subtest 'machine contract closes schemas, seams, and maturity' => sub {
    is_deeply([sort keys %{$contract}], [sort qw(
        schema schema_version profile_id execution_schema execution_profile
        family_revision backend_schema source_map_schema runtime_trace_schema
        trace_projection_schema result_manifest_schema lifecycle_result_schema
        trace_prefix controller_kind controller_states check_seams
        condition_sources record_mapping lifecycle_trace_payload_keys
        result_added_keys maturity
    )], 'machine selection has one closed top-level shape');
    is_deeply(
        [@{$contract}{qw(
            schema schema_version profile_id execution_schema execution_profile
            family_revision backend_schema source_map_schema runtime_trace_schema
            trace_projection_schema result_manifest_schema lifecycle_result_schema
            trace_prefix controller_kind
        )}],
        [
            'fsmgen.vial_backend_lifecycle_mapping_contract.v1', 1,
            'sv_portable_verilator', 'fsmgen.vial_execution_ir.v2',
            'core_directed_single_clock_execution_v2', 'lifecycle_control@1',
            'fsmgen.vial_backend.sv_portable_verilator.v2',
            'fsmgen.vial_backend_source_map.v2',
            'fsmgen.vial_sv_runtime_trace.v2',
            'fsmgen.vial_sv_trace_projection.v2',
            'fsmgen.verification_result_manifest.v2',
            'fsmgen.vial_lifecycle_result.v1', "FSMGEN_VIAL_TRACE_V2\t",
            'static_fixture_lifecycle_controller_v1',
        ],
        'all content-bearing v2 evidence schemas and controller identity are exact',
    );
    is_deeply($contract->{controller_states}, [qw(entered normal failing sealed)],
        'controller state progression is finite');
    is_deeply($contract->{check_seams}, [qw(
        after_initialization after_inactive_barrier after_scenario_terminal
    )], 'only three compiler-owned check seams can advance lifecycle state');
    is_deeply($contract->{lifecycle_trace_payload_keys}, [qw(
        diagnostic_ids lifecycle_id logical_time record_id state transition
    )], 'lifecycle trace payload is closed');
    is_deeply($contract->{result_added_keys}, ['lifecycle_results'],
        'v2 result adds exactly the family result collection');
    is_deeply($contract->{maturity}, {
        emission => 'unavailable', compile => 'unavailable',
        runtime => 'unavailable', result => 'unavailable',
        parity => 'unavailable',
    }, 'selection promotes no backend maturity');
};

subtest 'typed plan independently derives the selected record-to-control map' => sub {
    my @records = @{$v2->{execution_ir}->as_hashref->{semantic_families}};
    is_deeply([map { $_->{semantic}{node_kind} } @records], [qw(
        dependency dependency service readiness stimulus_start completion
        drain shutdown finalize deadline deadline failure
    )], 'maintained plan retains the exact twelve-record lifecycle topology');

    my @expected = (
        [dependency => [qw(evaluate commit)] => [qw(dependency_satisfied)]],
        [service => [qw(start ready quiescent stop)] => [qw(
            service_started service_ready service_quiescent service_stopped
            service_failed
        )]],
        [readiness => [qw(evaluate commit)] => [qw(readiness_reached)]],
        [stimulus_start => [qw(evaluate commit)] => [qw(stimulus_started)]],
        [completion => [qw(evaluate commit)] => [qw(completion_reached)]],
        [drain => [qw(evaluate commit)] => [qw(
            drain_reached drain_incomplete
        )]],
        [shutdown => [qw(evaluate commit)] => [qw(shutdown_reached)]],
        [finalize => [qw(evaluate commit)] => [qw(finalize_reached)]],
        [deadline => [qw(start check close)] => [qw(
            deadline_started deadline_met deadline_expired deadline_cancelled
        )]],
        [failure => [qw(latch cancel cleanup seal)] => [qw(
            failure_latched scenario_admission_closed record_cancelled
            cleanup_started cleanup_finalized cleanup_expired lifecycle_sealed
        )]],
    );
    my @selected = map {
        [$_->{record_kind}, $_->{controller_steps}, $_->{trace_transitions}]
    } @{$contract->{record_mapping}};
    is_deeply(\@selected, \@expected,
        'normative record, step, and transition map is exact');

    my %derived;
    for my $record (@records) {
        my $kind = $record->{semantic}{node_kind};
        my @steps = map {
            m{/([^/]+)\z} ? $1 : die "malformed lifecycle operation ID\n"
        } @{$record->{operation_ids}};
        if (exists $derived{$kind}) {
            is_deeply(\@steps, $derived{$kind},
                "all $kind records use one operation sequence");
        }
        else {
            $derived{$kind} = \@steps;
        }
    }
    is_deeply(
        [map { [$_->[0], $derived{$_->[0]}] } @expected],
        [map { [$_->[0], $_->[1]] } @expected],
        'every selected controller step is independently present in ExecutionIR',
    );
};

subtest 'current v2 backend boundaries remain unavailable and artifact-free' => sub {
    my $adapters = build_vial_semantic_family_backend_adapter_registry();
    my ($portable) = grep {
        $_->{profile_id} eq 'sv_portable_verilator'
    } @{$adapters->{adapters}};
    is_deeply($portable->{accepted_execution_schemas},
        ['fsmgen.vial_execution_ir.v1'],
        'current common adapter still admits only execution v1');
    is_deeply($portable->{accepted_execution_profiles},
        ['core_directed_single_clock_execution_v1'],
        'current common adapter still admits only the v1 profile');

    my $families = build_vial_semantic_family_registry();
    my ($lifecycle) = grep {
        $_->{family_id} eq 'lifecycle_control' && $_->{revision} == 1
    } @{$families->{families}};
    for my $backend (@{$lifecycle->{backend_profiles}}) {
        is_deeply($backend->{maturity}, {
            emission => 'unavailable', compile => 'unavailable',
            runtime => 'unavailable', result => 'unavailable',
            parity => 'unavailable',
        }, "$backend->{profile_id} lifecycle mapping remains unavailable");
    }

    my $emitted = emit_plan($v2);
    ok(!$emitted->{ok}, 'v2 lifecycle emission is not implemented');
    is($emitted->{diagnostics}[0]{code}, 'VIAL_BACKEND_UNSUPPORTED',
        'emission fails at capability negotiation');
    is_deeply($emitted->{artifacts}, [],
        'rejected v2 emission returns no artifact');
    ok(!defined($emitted->{backend_manifest}),
        'rejected v2 emission returns no mislabeled manifest');
    ok(scalar(grep { $_ eq 'family:lifecycle_control@1' }
            @{$emitted->{negotiation}{unsatisfied}}),
        'emission reports the unavailable lifecycle family');
    ok(!-e repo_path($artifact_root),
        'rejected v2 emission allocates no artifact root');

    my $host_calls = 0;
    my $ran;
    {
        no warnings 'redefine';
        local *FSM::VIAL::Backend::VerilatorLifecycle::execute_atomic = sub {
            $host_calls++;
            die "v2 runner crossed its negotiation boundary\n";
        };
        $ran = FSM::VIAL::Backend::Runner->run({
            execution_ir => $v2->{execution_ir},
        });
    }
    ok(!$ran->{ok}, 'v2 runner remains unavailable');
    is($ran->{diagnostics}[0]{code}, 'VIAL_BACKEND_UNSUPPORTED',
        'runner rejects at semantic-family negotiation');
    is($host_calls, 0,
        'runner rejects v2 before invoking the host-process lifecycle');
    is_deeply($ran->{artifacts}, [],
        'runner rejection returns no partial artifact');
    ok(!defined($ran->{result_manifest}),
        'runner rejection returns no result manifest');

    my $produced = FSM::VIAL::Backend::ResultProducer->produce({
        execution_ir => $v2->{execution_ir},
        trace_validation => {ok => JSON::PP::true, records => []},
        negotiation => {}, tool_profile => {},
        backend_manifest_id => 'backend/v2-selection-boundary',
        compile_id => 'compile/v2-selection-boundary',
        simulation_id => 'simulation/v2-selection-boundary',
        generated_artifact_sha256s => [],
        transcript_sha256 => '0' x 64,
    });
    ok(!$produced->{ok}, 'v1 result producer rejects lifecycle execution v2');
    is($produced->{diagnostics}[0]{code},
        'VIAL_RESULT_VERSION_UNSUPPORTED',
        'result rejection names the exact version boundary');
    ok(!defined($produced->{manifest}),
        'result rejection cannot publish v2 data as a v1 manifest');

    is_deeply(build_vial_tooling_contract_v2()->{unavailable_actions}, ['run'],
        'public v2 run remains unavailable');
};

subtest 'known standalone v1 trace-validator isolation gap is bounded' => sub {
    my $misvalidated = FSM::VIAL::Backend::TraceValidator->validate({
        execution_ir => $v2->{execution_ir},
        trace_text => minimal_v1_trace($v2->{execution_ir}),
        simulator_exit_code => 0,
    });
    ok($misvalidated->{ok},
        'characterization: v1-shaped trace is currently accepted for v2 IR');
    is($misvalidated->{trace_schema}, 'fsmgen.vial_sv_runtime_trace.v1',
        'characterization identifies the wrongly admitted v1 trace envelope');
    ok(@{$misvalidated->{records}} >= 3,
        'characterization proves parsing and projection occurred');
    is($misvalidated->{projection}{schema},
        'fsmgen.vial_sv_trace_projection.v1',
        'characterization identifies the wrongly produced v1 projection');
};

subtest 'v1 emitted graph and normalized result remain byte-exact' => sub {
    my $v1 = build_plan(1, $v1_name);
    my $emitted = emit_plan(
        $v1, '.artifacts/test/vial-portable-sv-emission',
    );
    ok($emitted->{ok}, 'canonical v1 backend still emits');
    diag $json->encode($emitted->{diagnostics}) unless $emitted->{ok};
    is(sha256_hex($json->encode($emitted)),
        '604f4713b6d8126be4d58ec19f77b5c5960f2424c85cd85d4880830ad2d2d823',
        'complete v1 emitted graph retains its frozen byte identity');

    my $validated = FSM::VIAL::Backend::TraceValidator->validate({
        execution_ir => $v1->{execution_ir},
        trace_text => minimal_v1_trace($v1->{execution_ir}),
        simulator_exit_code => 0,
    });
    ok($validated->{ok}, 'canonical synthetic v1 trace validates');
    diag $json->encode($validated->{diagnostics}) unless $validated->{ok};
    my $result = FSM::VIAL::Backend::ResultProducer->produce({
        execution_ir => $v1->{execution_ir},
        trace_validation => $validated,
        negotiation => $emitted->{negotiation},
        tool_profile => $emitted->{backend_manifest}{tool_profile},
        backend_manifest_id => 'backend/v1-contract-watcher',
        compile_id => 'compile/v1-contract-watcher',
        simulation_id => 'simulation/v1-contract-watcher',
        generated_artifact_sha256s => [],
        transcript_sha256 => '0' x 64,
    });
    ok($result->{ok}, 'canonical v1 normalized result still produces');
    diag $json->encode($result->{diagnostics}) unless $result->{ok};
    is(sha256_hex($json->encode($result->{manifest})),
        '0172b3d3f1aa33e9c235cbca2ebf2bf4ecacaef6fe9b76f9ecef9a1babd895d8',
        'complete v1 normalized result retains its frozen byte identity');
};

done_testing;

sub minimal_v1_trace {
    my ($execution_ir) = @_;
    my $execution = $execution_ir->as_hashref;
    my @runs = map {{
        scenario_id => $_->{scenario_id},
        run_id => "run/$execution->{plan_id}/$_->{scenario_id}",
    }} @{$execution->{scenarios}};
    my @record = (trace_record(
        'header', $execution->{plan_id}, undef, {
            fixture_id => $execution->{fixture}{fixture_id},
            execution_profile => $execution->{profile},
            backend_profile => 'sv_portable_verilator',
            scenario_runs => \@runs,
            decision_digest => sha256_hex(
                $json->encode($execution->{randomness}{decisions}),
            ),
        },
    ));
    for my $run (@runs) {
        push @record,
            trace_record('scenario_start', $execution->{plan_id},
                $run->{run_id}, {scenario_id => $run->{scenario_id}}),
            trace_record('scenario_end', $execution->{plan_id},
                $run->{run_id}, {
                    logical_cycle_count => 1,
                    scenario_id => $run->{scenario_id},
                    status => 'passed',
                });
    }
    my %count;
    $count{$_->{record_kind}}++ for @record;
    $count{footer} = 1;
    push @record, trace_record(
        'footer', $execution->{plan_id}, undef, {
            status => 'passed',
            scenario_completion_summaries => [map {
                +{%{$_}, status => 'passed'}
            } @runs],
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
