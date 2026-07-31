#!/usr/bin/env perl

use strict;
use warnings;

use bytes ();
use Digest::SHA qw(sha256_hex);
use File::Basename qw(basename);
use File::Spec;
use FindBin;
use JSON::PP ();
use Test::More;

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::Adapter::IAL2::PPIF;
use FSM::Adapter::ISF;
use FSM::HIAL::VIALBridge::Builder;
use FSM::Support::CapabilityManifest qw(build_capability_manifest);
use FSM::Support::VIALExecutionContract qw(
    build_vial_execution_contract
    vial_execution_contract_keys
);
use FSM::VIAL::ExecutionBuilder;
use FSM::VIAL::ExecutionIR;
use FSM::VIAL::ExecutionRandom;
use FSM::VIAL::ExecutionReport;
use FSM::VIAL::Parser;

my $json = JSON::PP->new->canonical(1);
my $vial_source_name = 'vial/ahb_subordinate_base_output_arbitration.vial';
my $vial_text = slurp_raw(repo_path($vial_source_name));
my $semantic_ir = parse_vial($vial_text);
my $semantic_data = $semantic_ir->as_hashref;
my $fixture = $semantic_data->{packages}[0]{fixtures}[0];
my @scenario_ids = map { $_->{semantic_id} } @{$fixture->{scenarios}};
my $bridge_manifest = build_ahb_bridge();

sub build_args {
    my (%override) = @_;
    return {
        semantic_ir => $semantic_ir,
        bridge_manifest => $bridge_manifest,
        fixture_id => $fixture->{semantic_id},
        scenario_ids => [@scenario_ids],
        execution_profile => 'core_directed_single_clock_execution_v1',
        replay_manifest => undef,
        native_extension_catalog => [],
        %override,
    };
}

subtest 'checked AHB fixture binds into immutable target-neutral execution IR and plan' => sub {
    my $result = FSM::VIAL::ExecutionBuilder->build(build_args());
    ok($result->{ok}, 'bounded execution build succeeds');
    diag($json->encode($result->{diagnostics})) unless $result->{ok};
    isa_ok($result->{execution_ir}, 'FSM::VIAL::ExecutionIR');
    is_deeply($result->{diagnostics}, [], 'success has no diagnostics');
    is_deeply(
        [sort keys %{$result->{execution_ir}->as_hashref}],
        [sort @{FSM::VIAL::ExecutionIR->top_level_keys}],
        'private ExecutionIR has exactly the selected top-level keys',
    );
    is_deeply(
        [sort keys %{$result->{plan}}],
        [sort @{FSM::VIAL::ExecutionReport->top_level_keys}],
        'sanitized plan has exactly the selected top-level keys',
    );
    is($result->{execution_ir}->schema, 'fsmgen.vial_execution_ir.v1', 'ExecutionIR schema is exact');
    is($result->{plan}{schema}, 'fsmgen.vial_plan.v1', 'plan schema is exact');
    is($result->{plan}{status}, 'bound_target_neutral', 'plan is target-neutral');
    like($result->{plan}{plan_id}, qr{\Aplan/[0-9a-f]{64}\z}, 'plan identity is content-addressed');
    like($result->{plan}{semantic_identity}{semantic_ir_id}, qr{\Asemantic/[0-9a-f]{64}\z}, 'semantic identity is content-addressed');
    is($result->{plan}{bridge_identity}{manifest_id}, $bridge_manifest->manifest_id, 'plan records the exact bridge identity');
    is_deeply($result->{plan}{logical_time}{phase_order}, [qw(drive sample react check)], 'logical phases are exact');
    is_deeply(
        $result->{plan}{logical_time}{tie_break_order},
        [qw(domain_rank static_operation_rank local_emission_index semantic_id)],
        'logical tie order is exact',
    );
    ok($result->{plan}{logical_time}{timeout_last_cycle_inclusive}, 'timeout last cycle is inclusive');
    is($result->{execution_ir}->operation_graph->{total_operation_count}, 21, 'both selected scenarios expand to 21 static operations');
    is($result->{execution_ir}->operation_graph->{total_fiber_count}, 4, 'two roots and two child fibers are explicit');
    is($result->{execution_ir}->operation_graph->{maximum_simultaneous_live_fibers}, 3, 'maximum simultaneous live fibers is computed structurally');
    ok(!contains_non_json_reference($result->{execution_ir}->as_hashref), 'ExecutionIR contains only JSON-safe data');
    ok(!contains_non_json_reference($result->{plan}), 'plan contains only JSON-safe data');
    unlike($json->encode($result->{plan}), qr{(?:systemverilog|uvm|vhdl|target_name|build_phase|objection)}, 'plan contains no target or methodology spelling');
    my $execution_json = $json->encode($result->{execution_ir}->as_hashref);
    unlike($execution_json, qr{(?:ahb_phase_pending_q|[0-9]+'[sS]?[bBoOdDhH])}, 'ExecutionIR contains no raw actor-storage or HDL-literal spelling');
};

subtest 'all ten directional type relations carry exact kinds, proofs, and enum encodings' => sub {
    my $result = FSM::VIAL::ExecutionBuilder->build(build_args());
    my $bindings = $result->{execution_ir}->bindings;
    my %relation;
    for my $endpoint (@{$bindings->{endpoints}}) {
        $relation{$endpoint->{endpoint_id}} = $endpoint->{relations}[0];
    }
    for my $probe (@{$bindings->{probes}}) {
        $relation{$probe->{probe_id}} = $probe->{relations}[0];
    }
    for my $field (@{$bindings->{transactions}[0]{fields}}) {
        $relation{$field->{name}} = $field->{relation};
    }
    is(scalar(keys %relation), 10, 'exactly ten checked directional relations are recorded');
    my %expected_kind = (
        address => 'bit_domain_identity_v1',
        transfer => 'enum_encoding_injection_v1',
        write => 'known_value_injection_v1',
        size => 'bit_domain_identity_v1',
        data => 'bit_domain_identity_v1',
        wait_cycles => 'known_value_injection_v1',
        'endpoint/HREADYOUT' => 'bit_domain_identity_v1',
        'endpoint/HRESP' => 'bit_domain_identity_v1',
        'endpoint/HRDATA' => 'bit_domain_identity_v1',
        'probe/reg_data_q' => 'bit_domain_identity_v1',
    );
    is($relation{$_}{kind}, $expected_kind{$_}, "$_ uses the selected relation kind")
        for sort keys %expected_kind;
    is_deeply(
        $relation{write}{proof_ids},
        [qw(semantic_two_state carrier_four_state signedness_equal width_equal value_bits_preserved all_carrier_bits_known no_carrier_z)],
        'Boolean drive carries every known-value proof in fixed order',
    );
    is_deeply(
        [map { [$_->{name}, $_->{value}{value_hex}] } @{$relation{transfer}{enum_encoding}}],
        [[idle => '0'], [nonseq => '2']],
        'enum injection preserves idle/nonseq encodings in authored order',
    );
    is_deeply(
        [map { $_->{direction} } @{$bindings->{endpoints}[0]{relations}}],
        ['sample'],
        'sampled public output is directionally explicit',
    );
    for my $item (values %relation) {
        like($item->{relation_id}, qr{\Atype-relation/binding/}, 'relation has a stable binding-derived identity');
        like($item->{semantic_type_id}, qr{\Aexecution-type/[0-9a-f]{64}\z}, 'semantic type has a stable normalized identity');
        unlike($item->{relation_id}, qr{(?:cast|coerc)}, 'relation identity does not encode a target cast');
    }
    my ($probe_capability) = grep {
        $_->{capability_id} eq 'hial_vial.bridge_probe.equivalent_adapter_required'
    } @{$result->{plan}{capability_ledger}};
    is($probe_capability->{classification}, 'required_from_backend', 'probe adapter remains independently required');
    is($probe_capability->{portable_class}, 'portable_with_equivalent_adapter', 'probe is portable only with an equivalent adapter');
};

subtest 'operation graph, decisions, source maps, and hashes are deterministic and defensive' => sub {
    my $first = FSM::VIAL::ExecutionBuilder->build(build_args());
    my $second = FSM::VIAL::ExecutionBuilder->build({
        native_extension_catalog => [],
        replay_manifest => undef,
        execution_profile => 'core_directed_single_clock_execution_v1',
        scenario_ids => [@scenario_ids],
        fixture_id => $fixture->{semantic_id},
        bridge_manifest => $bridge_manifest,
        semantic_ir => $semantic_ir,
    });
    is($json->encode($first->{plan}), $json->encode($second->{plan}), 'argument hash insertion order does not change canonical plan bytes');
    is($first->{plan}{plan_id}, $second->{plan}{plan_id}, 'argument hash insertion order does not change plan identity');
    is(scalar(@{$first->{plan}{random_decisions}}), 1, 'scenario-scoped choice produces one occurrence only');
    is($first->{plan}{random_decisions}[0]{algorithm}, 'sha256_counter_rejection_v1', 'decision records the exact algorithm');
    is($first->{plan}{random_decisions}[0]{origin}, 'generated', 'first plan records generated origin');
    is_deeply(
        [map { $_->{static_rank} } @{$first->{execution_ir}->operation_graph->{operations}}],
        [0 .. 11, 0 .. 8],
        'static ranks are depth-first and scenario-local',
    );
    ok(scalar(@{$first->{plan}{source_map}}) >= 31, 'plan carries relation, operation, and decision source maps');

    my @executable_references = grep {
        ($_->{op} // '') =~ /\A(?:sample|event|event_count)\z/
    } collect_hashes($first->{execution_ir}->as_hashref);
    ok(@executable_references > 0, 'fixture contains executable endpoint/event references');
    ok(!scalar(grep { !defined($_->{binding_id}) } @executable_references), 'every executable endpoint/event reference has one binding ID');
    my @unresolved_symbolic_values = grep {
        ($_->{kind} // '') eq 'reference'
            && ($_->{op} // '') =~ /\A(?:choice|enum_member)\z/
    } collect_hashes($first->{execution_ir}->operation_graph);
    is(scalar(@unresolved_symbolic_values), 0, 'operation graph resolves choices and enum members before execution');
    my @decision_references = grep {
        ($_->{kind} // '') eq 'decision_reference'
    } collect_hashes($first->{execution_ir}->operation_graph);
    is(scalar(@decision_references), 2, 'both authored success-wait uses share resolved decision records');
    is($decision_references[0]{occurrence_id}, $decision_references[1]{occurrence_id}, 'scenario-scoped decision identity is shared');

    my $execution_bindings = $first->{execution_ir}->bindings;
    is_deeply(
        [map { $_->{endpoint_id} } @{$execution_bindings->{transactions}[0]{event_input_bindings}}],
        [qw(endpoint/HREADY endpoint/HSEL)],
        'bridge-only event inputs receive explicit transaction-adapter bindings',
    );
    my ($captured) = grep { $_->{name} eq 'captured' } @{$execution_bindings->{events}};
    is(scalar(@{$captured->{adapter_state_binding_ids}}), 1, 'captured event abstracts bridge storage behind one adapter-state binding');

    is_deeply(
        {map { $_ => $first->{execution_ir}->resource_summary->{$_} } qw(
            bindings simultaneous_live_fibers scalar_state_cells
            scoreboard_declared_capacity coverage_bins_and_cross_tuples
        )},
        {
            bindings => 22,
            simultaneous_live_fibers => 3,
            scalar_state_cells => 2,
            scoreboard_declared_capacity => 4,
            coverage_bins_and_cross_tuples => 2,
        },
        'resource summary counts every enforced nested execution resource',
    );

    my $plan_copy = $first->{plan};
    $plan_copy->{bindings}{unit}{unit_id} = 'mutated';
    isnt(FSM::VIAL::ExecutionReport->build($first->{execution_ir})->{bindings}{unit}{unit_id}, 'mutated', 'returned plan does not share ExecutionIR storage');
    my $ir_copy = $first->{execution_ir}->as_hashref;
    $ir_copy->{type_table}[0]{semantic_type}{kind} = 'mutated';
    isnt($first->{execution_ir}->type_table->[0]{semantic_type}{kind}, 'mutated', 'ExecutionIR accessors are deeply defensive');
};

subtest 'random algorithm has fixed vectors and strict replay round trip' => sub {
    my @vector = (
        [1, 0, 'vector/one', 0, 1, undef, undef],
        [4, 1, 'vector/four', 1, 9, undef, undef],
        [257, 7, 'vector/wide', 0, 10, undef, undef],
    );
    for my $case (@vector) {
        my ($width, $seed, $occurrence, $low, $high) = @$case;
        my $value = FSM::VIAL::ExecutionRandom->generate({
            width => $width, seed => $seed, occurrence_id => $occurrence,
            low => $low, high => $high,
        });
        ok($value, "random vector width $width resolves");
        $case->[5] = $value->{value}->bstr;
        $case->[6] = $value->{attempt};
    }
    is_deeply(
        [map { [$_->[5], $_->[6]] } @vector],
        [[1, 0], [7, 1], [5, 0]],
        'SHA-256 counter/rejection vectors are fixed across narrow and multi-block widths',
    );

    my $generated = FSM::VIAL::ExecutionBuilder->build(build_args());
    my $decision = $generated->{plan}{random_decisions}[0];
    my %replay_decision = map { $_ => clone_json($decision->{$_}) } qw(
        occurrence_id declaration_semantic_id decision_id scenario_id algorithm
        seed type_id distribution value attempt
    );
    my $replay = {
        schema => 'fsmgen.vial_replay.v1',
        schema_version => 1,
        replay_id => undef,
        semantic_ir_id => $generated->{plan}{semantic_identity}{semantic_ir_id},
        bridge_manifest_id => $generated->{plan}{bridge_identity}{manifest_id},
        fixture_id => $fixture->{semantic_id},
        scenario_ids => [@scenario_ids],
        algorithm => 'sha256_counter_rejection_v1',
        decisions => [\%replay_decision],
    };
    my $digest = clone_json($replay);
    delete $digest->{replay_id};
    $replay->{replay_id} = 'replay/' . sha256_hex($json->encode($digest));
    my $replayed = FSM::VIAL::ExecutionBuilder->build(build_args(replay_manifest => $replay));
    ok($replayed->{ok}, 'strict replay round trip succeeds');
    diag($json->encode($replayed->{diagnostics})) unless $replayed->{ok};
    is($replayed->{plan}{random_decisions}[0]{origin}, 'replayed', 'replayed decision records its origin');
    is_deeply($replayed->{plan}{random_decisions}[0]{value}, $decision->{value}, 'replay preserves the normalized value exactly');

    my $bad_replay = clone_json($replay);
    $bad_replay->{decisions}[0]{value}{value_hex} = '0';
    my $bad_digest = clone_json($bad_replay);
    delete $bad_digest->{replay_id};
    $bad_replay->{replay_id} = 'replay/' . sha256_hex($json->encode($bad_digest));
    execution_failure('constraint-violating replay', 'VIAL_REPLAY_ERROR',
        FSM::VIAL::ExecutionBuilder->build(build_args(replay_manifest => $bad_replay)));
};

subtest 'reference, access, type direction, event, invocation, and native boundaries fail closed' => sub {
    execution_failure('empty invocation', 'VIAL_EXECUTION_INVOCATION_ERROR',
        FSM::VIAL::ExecutionBuilder->build({}));
    execution_failure('reversed scenario order', 'VIAL_EXECUTION_INVOCATION_ERROR',
        FSM::VIAL::ExecutionBuilder->build(build_args(scenario_ids => [reverse @scenario_ids])));
    execution_failure('native catalog remains absent', 'VIAL_NATIVE_EXTENSION_ERROR',
        FSM::VIAL::ExecutionBuilder->build(build_args(native_extension_catalog => [{}])));

    my $missing_unit = changed($vial_text, '"unit/ahb_lite_subordinate"', '"unit/missing"', 'missing unit');
    execution_failure('missing unit reference', 'VIAL_BIND_REFERENCE_ERROR',
        FSM::VIAL::ExecutionBuilder->build(build_args(semantic_ir => parse_vial($missing_unit))));

    my $sampled_input = changed($vial_text, '"endpoint/HRDATA"', '"endpoint/HADDR"', 'sampled input');
    execution_failure('sampled input access misuse', 'VIAL_BIND_ACCESS_ERROR',
        FSM::VIAL::ExecutionBuilder->build(build_args(semantic_ir => parse_vial($sampled_input))));

    my $two_state_sample = changed($vial_text,
        '(endpoint response "endpoint/HRESP" (logic 1) public_port)',
        '(endpoint response "endpoint/HRESP" bool public_port)', 'two-state response');
    $two_state_sample =~ s{\(same \(sample response\) #b0\)}{(same (sample response) false)}g;
    execution_failure('four-state to two-state sample', 'VIAL_BIND_TYPE_ERROR',
        FSM::VIAL::ExecutionBuilder->build(build_args(semantic_ir => parse_vial($two_state_sample))));

    my $missing_event = changed($vial_text,
        '(events requested accepted captured held completed error)',
        '(events requested accepted captured held completed faulted)', 'missing event declaration');
    $missing_event =~ s{\(event_count error_write error\)}{(event_count error_write faulted)}g;
    execution_failure('missing carrier event', 'VIAL_BIND_EVENT_ERROR',
        FSM::VIAL::ExecutionBuilder->build(build_args(semantic_ir => parse_vial($missing_event))));
};

subtest 'private capability/support accounting distinguishes emission from runtime' => sub {
    my $execution_result = FSM::VIAL::ExecutionBuilder->build(build_args());
    ok($execution_result->{ok}, 'execution plan remains available for capability-ledger checks');
    my $contract = build_vial_execution_contract();
    is_deeply([sort keys %$contract], [sort @{vial_execution_contract_keys()}], 'execution capability contract is closed');
    is($contract->{status}, 'shipped_private_execution_and_portable_sv_emission', 'execution support includes private portable-SystemVerilog emission');
    ok(!$contract->{writes_files}, 'execution contract writes no file');
    ok(!$contract->{public_embedding_api}, 'execution contract exposes no supported public embedding API');
    is_deeply(
        $contract->{selected_future_schemas},
        {
            result_manifest => {
                schema => 'fsmgen.verification_result_manifest.v1',
                status => 'selected_not_implemented',
                implementation_owner => 'HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.10',
            },
            parity_report => {
                schema => 'fsmgen.vial_parity_report.v1',
                status => 'selected_not_implemented',
                implementation_owner => 'HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.11',
            },
        },
        'selected result/parity schemas retain explicit later implementation owners',
    );
    my %shipped_capability = map { $_ => 1 } @{$contract->{capabilities}};
    ok($shipped_capability{'vial.backend.sv_portable_verilator.emission.v1'}, 'private emission capability is explicit');
    ok($shipped_capability{'vial.backend.sv_portable_verilator.trace_validation.v1'}, 'private trace-validation capability is explicit');
    ok(!$shipped_capability{'vial.result_manifest.v1'}, 'private plan support does not claim result-manifest implementation');
    ok(!$shipped_capability{'vial.parity_projection.v1'}, 'private plan support does not claim parity-projection implementation');
    my %plan_capability = map { $_->{capability_id} => $_ } @{$execution_result->{plan}{capability_ledger}};
    ok(!$plan_capability{'vial.result_manifest.v1'}, 'plan ledger does not mark future result support satisfied');
    ok(!$plan_capability{'vial.parity_projection.v1'}, 'plan ledger does not mark future parity support satisfied');
    my %nonclaim = map { $_ => 1 } @{$contract->{explicit_nonclaims}};
    ok($nonclaim{public_backend_action} && $nonclaim{compile} && $nonclaim{runtime} && $nonclaim{result} && $nonclaim{parity_pass} && $nonclaim{uvm} && $nonclaim{vhdl_methodology}, 'public/runtime/methodology nonclaims remain explicit');
    my $manifest = build_capability_manifest();
    is_deeply($manifest->{language_surface}{vial_execution}, $contract, 'capability manifest publishes the exact private execution contract');
    my ($surface) = grep { $_->{suffix} eq '.vial' } @{$manifest->{language_surface}{file_surfaces}{entries}};
    is($surface->{status}, 'shipped_bounded_public_planning_private_execution_and_sv_emission', '.vial status composes public planning with private execution/emission');
    is_deeply(
        $surface->{supported_cli_modes},
        [
            'fsmgen vial capabilities [--json]',
            'fsmgen vial check [--style auto|normal|terse] [--json] SOURCE.vial',
            'fsmgen vial format --style normal|terse SOURCE.vial',
            'fsmgen vial plan --dut HIAL_SOURCE [PLAN_OPTIONS] SOURCE.vial',
        ],
        '.vial advertises the shipped public source and planning CLI modes',
    );
};

done_testing();

sub parse_vial {
    my ($text) = @_;
    return FSM::VIAL::Parser->parse_source({
        text => $text,
        source_name => $vial_source_name,
        source_catalog => {},
    });
}

sub build_ahb_bridge {
    my $ial2_source_name = 'ppif/ahb_lite_subordinate.ppif';
    my $ial2_text = slurp_raw(repo_path($ial2_source_name));
    my $ial2_result = FSM::Adapter::IAL2::PPIF->new()->parse_source($ial2_text, $ial2_source_name);
    my $generated_ial1_text = $ial2_result->{generated_ial1}{text};
    my $isf_adapter = FSM::Adapter::ISF->new();
    my $generated_ial1_actor = $isf_adapter->parse_source(
        $generated_ial1_text,
        $ial2_result->{generated_ial1}{name},
    );
    my $generated_ial0_text = $ial2_result->{generated_ial0}{files}{'ahb_lite_subordinate.fsm'};
    my $result = FSM::HIAL::VIALBridge::Builder->build_ial2_via_ial1({
        profile => 'core_single_unit_v1',
        authored_source => source_record($ial2_text, $ial2_source_name),
        generated_ial1 => {
            source => source_record($generated_ial1_text, undef, 'ahb_lite_subordinate.isf'),
            actor => $generated_ial1_actor,
            schedule_report => $ial2_result->{generated_ial1_schedule_report},
        },
        generated_ial0 => source_record($generated_ial0_text, undef, 'ahb_lite_subordinate.fsm'),
        backend_names => backend_names(
            'ahb_lite_subordinate',
            [qw(clk rst_n HSEL HREADY HADDR HTRANS HWRITE HSIZE HWDATA wait_cycles HREADYOUT HRESP HRDATA)],
            [],
            ['reg_data_q'],
        ),
    });
    die $json->encode($result->{diagnostics}) unless $result->{ok};
    return $result->{manifest};
}

sub repo_path {
    my ($relative) = @_;
    return File::Spec->catfile($FindBin::Bin, '..', split m{/}, $relative);
}

sub slurp_raw {
    my ($path) = @_;
    open my $fh, '<:raw', $path or die "Cannot read $path: $!";
    local $/;
    my $text = <$fh>;
    close $fh or die "Cannot close $path: $!";
    return $text;
}

sub source_record {
    my ($text, $repository_path, $artifact_name) = @_;
    $artifact_name //= basename($repository_path);
    my $line_count = length($text) ? (() = $text =~ /\n/g) + ($text =~ /\n\z/ ? 0 : 1) : 0;
    return {
        text => $text,
        repository_path => $repository_path,
        artifact_name => $artifact_name,
        content_sha256 => sha256_hex($text),
        byte_length => bytes::length($text),
        line_count => $line_count,
    };
}

sub backend_names {
    my ($unit, $endpoints, $configurations, $probes) = @_;
    my %endpoint = map { $_ => $_ } @$endpoints;
    my %configuration = map { $_ => $_ } @$configurations;
    my %probe = map { $_ => $_ } @$probes;
    return {
        map {
            $_ => {
                unit => $unit,
                endpoints => {%endpoint},
                configurations => {%configuration},
                probes => {%probe},
            }
        } qw(systemverilog vhdl)
    };
}

sub changed {
    my ($text, $from, $to, $label) = @_;
    my $copy = $text;
    my $count = ($copy =~ s/\Q$from\E/$to/);
    die "Test mutation '$label' did not match exactly once" unless $count == 1;
    return $copy;
}

sub clone_json {
    my ($value) = @_;
    return $json->decode($json->encode($value));
}

sub contains_non_json_reference {
    my ($value) = @_;
    return 0 unless ref($value);
    return 0 if ref($value) eq 'JSON::PP::Boolean';
    return scalar grep { contains_non_json_reference($value->{$_}) } keys %$value
        if ref($value) eq 'HASH';
    return scalar grep { contains_non_json_reference($_) } @$value
        if ref($value) eq 'ARRAY';
    return 1;
}

sub collect_hashes {
    my ($value) = @_;
    return () unless ref($value);
    return map { collect_hashes($_) } @$value if ref($value) eq 'ARRAY';
    return () unless ref($value) eq 'HASH';
    return ($value, map { collect_hashes($value->{$_}) } sort keys %$value);
}

sub execution_failure {
    my ($label, $code, $result) = @_;
    ok(!$result->{ok}, "$label fails closed");
    is($result->{execution_ir}, undef, "$label returns no partial ExecutionIR");
    is($result->{plan}, undef, "$label returns no partial plan");
    is(scalar(@{$result->{diagnostics}}), 1, "$label returns one stable diagnostic");
    is($result->{diagnostics}[0]{code}, $code, "$label uses $code");
    is_deeply(
        [sort keys %{$result->{diagnostics}[0]}],
        [sort qw(schema_version severity code phase message semantic_path source_location bridge_fact_paths related)],
        "$label diagnostic shape is closed",
    );
    unlike($result->{diagnostics}[0]{message}, qr{(?:/Volumes/|/private/| at \S+\.pm line |stack)}, "$label diagnostic leaks no machine path or Perl stack");
}
