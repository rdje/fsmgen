#!/usr/bin/env perl

use strict;
use warnings;

use bytes ();
use Digest::SHA qw(sha256_hex);
use File::Path qw(remove_tree);
use File::Spec;
use FindBin;
use JSON::PP ();
use Test::More;

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::Support::CapabilityManifest qw(build_capability_manifest);
use FSM::VIAL::ArtifactTransaction;
use FSM::VIAL::Backend::VHDLPortableGHDL;
use FSM::VIAL::Backend::VHDLPortableStaticValidator;
use FSM::VIAL::Parser;
use FSM::VIAL::PlanBuilder;

my $json = JSON::PP->new->canonical(1);
my $profile = 'vhdl_portable_ghdl';
my $vial_id = 'vial/ahb_subordinate_base_output_arbitration.vial';
my $hial_id = 'ppif/ahb_lite_subordinate.ppif';
my $artifact_root = '.artifacts/test/vial-vhdl-portable-semantics-publication';
my $built = build_plan();

ok($built->{ok}, 'checked VIAL/HIAL fixture reaches portable VHDL backend inputs');
diag($json->encode($built->{diagnostics})) unless $built->{ok};

subtest 'private HIAL handoff carries deterministic VHDL DUT identity and bytes' => sub {
    is_deeply([sort keys %{$built->{backend_inputs}}],
        [qw(dut_systemverilog dut_vhdl)], 'private handoff is closed over both HDL families');
    is(scalar(@{$built->{backend_inputs}{dut_vhdl}}), 1,
        'one bound HIAL unit supplies one VHDL source');
    my $dut = $built->{backend_inputs}{dut_vhdl}[0];
    is_deeply([sort keys %$dut], [sort qw(
        unit_id entity_name artifact_name source_id text content_sha256 byte_length
    )], 'VHDL DUT record is closed');
    is($dut->{unit_id}, 'unit/ahb_lite_subordinate', 'DUT semantic unit is exact');
    is($dut->{entity_name}, 'ahb_lite_subordinate', 'DUT entity identity is exact');
    is($dut->{artifact_name}, 'ahb_lite_subordinate.vhd', 'DUT filename is deterministic');
    is($dut->{content_sha256}, sha256_hex($dut->{text}), 'DUT digest covers exact bytes');
    is($dut->{byte_length}, bytes::length($dut->{text}), 'DUT byte count covers exact bytes');
    like($dut->{text}, qr/entity ahb_lite_subordinate is/, 'DUT source declares the bound entity');
};

subtest 'emitter produces a deterministic closed unqualified portable VHDL semantic graph' => sub {
    my $first = emit_backend();
    ok($first->{ok}, 'portable VHDL semantic emission succeeds');
    diag($json->encode($first->{diagnostics})) unless $first->{ok};
    is_deeply([sort keys %$first],
        [sort @{FSM::VIAL::Backend::VHDLPortableGHDL->result_keys}],
        'backend result shell is closed');
    is($first->{status}, 'emitted_structurally_reviewed_unqualified',
        'status cannot imply analysis, elaboration, or runtime');
    is($first->{backend_profile}, $profile, 'backend profile is exact');
    like($first->{operation_id}, qr/\Aop-[0-9a-f]{64}\z/,
        'operation identity is deterministic and safe');
    is(scalar(@{$first->{artifacts}}), 17,
        'portable review-closed graph has exactly seventeen artifacts');
    is_deeply([map { $_->{relpath} } @{$first->{artifacts}}],
        [sort map { $_->{relpath} } @{$first->{artifacts}}],
        'artifact graph is repository-relative and sorted');
    is_deeply([sort keys %{$first->{backend_manifest}}],
        [sort @{FSM::VIAL::Backend::VHDLPortableGHDL->manifest_keys}],
        'backend manifest is closed');
    is_deeply([sort keys %{$first->{source_map}}],
        [sort @{FSM::VIAL::Backend::VHDLPortableGHDL->source_map_keys}],
        'source map is closed');
    is(scalar(@{$first->{source_map}{entries}}), 59,
        'portable checking graph has fifty-nine complete source-map entries');
    my %mapped = map { $_->{generated_relpath} => 1 } @{$first->{source_map}{entries}};
    for my $artifact (grep { $_->{language} eq 'vhdl' } @{$first->{artifacts}}) {
        ok($mapped{$artifact->{relpath}}, "'$artifact->{relpath}' is source-mapped");
    }
    for my $entry (@{$first->{source_map}{entries}}) {
        is_deeply([sort keys %$entry],
            [sort @{FSM::VIAL::Backend::VHDLPortableGHDL->source_map_entry_keys}],
            "source-map entry '$entry->{generated_symbol}' is closed");
    }
    is_deeply($first->{negotiation}{unsatisfied}, [],
        'selected portable semantic negotiation is fully satisfied');
    is_deeply($first->{negotiation}{native_only}, [],
        'selected portable semantic negotiation has no native-only residue');
    my $second = emit_backend();
    is_deeply($second, $first, 'identical input reproduces the byte-identical result');
    $first->{artifacts}[0]{content} = 'mutated';
    isnt($second->{artifacts}[0]{content}, 'mutated', 'emission results are defensive');
};

subtest 'portable source emits typed stimulus, scheduling, models, and declared probes' => sub {
    my $emission = emit_backend();
    my $types = artifact_by_role($emission, 'vhdl_types_package')->{content};
    like($types, qr/type vial_value_symbol_t is/, 'typed four-state value symbols are emitted');
    like($types, qr/type vial_phase_t is/, 'logical execution phases are typed');
    like($types, qr/original_symbol : std_logic;/,
        'observation foundation preserves the original std_logic symbol');
    like($types, qr/when 'Z' => return VIAL_VALUE_Z;/, 'high-impedance remains distinct');
    like($types, qr/when others => return VIAL_VALUE_X;/,
        'remaining std_logic meta-values normalize to X');
    like($types, qr/procedure drive_vial_value\s*\(/,
        'typed scalar driver is emitted');
    like($types, qr/procedure drive_vial_vector\s*\(/,
        'typed vector driver is emitted');
    like($types, qr/function observe_vial_vector\s*\(/,
        'typed original-symbol sampler is emitted');
    like($types, qr/vial_value_vector_t\(0 to value'length - 1\)/,
        'typed literal conversion normalizes vectors into left-to-right positional order');
    like($types, qr/source_index := value'left - offset;/,
        'descending source vectors preserve their left-to-right bit order');
    like($types, qr/target_index := target'left - offset;/,
        'descending driven vectors preserve left-to-right semantic positions');
    like($types, qr/value_index := value'left \+ offset;/,
        'ascending semantic values are copied positionally into driven vectors');
    my $runtime = artifact_by_role($emission, 'vhdl_runtime_package')->{content};
    like($runtime, qr/type vial_logical_time_t is record/,
        'runtime package owns typed logical time');
    like($runtime, qr/type vial_fiber_status_t is/,
        'runtime package owns bounded fiber state');
    like($runtime, qr/type vial_scenario_status_t is/,
        'runtime package owns bounded scenario state');
    like($runtime, qr/VIAL_SCOREBOARD_CAPACITY : positive := 4;/,
        'runtime package freezes the bounded scoreboard capacity');
    like($runtime, qr/type vial_diagnostic_record_t is record/,
        'runtime package owns typed diagnostic records');
    like($runtime, qr/type vial_diagnostic_array_t is array/,
        'runtime package owns the bounded diagnostic store');
    my $metadata = artifact_by_role($emission, 'vhdl_fixture_metadata')->{content};
    like($metadata, qr/VIAL_INACTIVE_EDGE : string := "falling";/,
        'metadata freezes the selected inactive edge');
    like($metadata, qr/VIAL_OPERATION_COUNT : natural := 21;/,
        'metadata records all twenty-one exact operations');
    like($metadata, qr/VIAL_SCENARIO_COUNT : natural := 2;/,
        'metadata records both scenarios');
    like($metadata, qr/VIAL_FIBER_COUNT : natural := 4;/,
        'metadata records all four fibers');
    like($metadata, qr/VIAL_MODEL_COUNT : natural := 2;/,
        'metadata records both deterministic models');
    my $top = artifact_by_role($emission, 'vhdl_fixture_top')->{content};
    like($top, qr/dut : entity work\.ahb_lite_subordinate\(rtl\)/,
        'testbench foundation binds the HIAL VHDL entity directly');
    like($top, qr/HADDR => HADDR/, 'testbench uses named bridge-proved port bindings');
    is(scalar(() = $top =~ /^\s*[a-z][a-z0-9_]*\s*:\s*process\b/gmi), 2,
        'top contains only the clock source and semantic scheduler processes');
    is(scalar(() = $top =~ /^\s*vial_scheduler\s*:\s*process\b/gmi), 1,
        'one generated scheduler owns semantic execution');
    is(scalar(() = $top =~ /wait until falling_edge\(clk\);/g), 1,
        'one inactive-edge wait is the stable barrier');
    like($top, qr/drive_vial_vector\(HWDATA,/,
        'scenario stimulus uses the typed vector driver');
    like($top, qr/vial_sample_probe_reg_data_q := observe_vial_vector/,
        'declared probe output is sampled with original-symbol evidence');
    like($top, qr/vial_model_00_count := vial_model_00_count \+ 1;/,
        'event-counter model update is deterministic');
    like($top,
        qr/vial_complete_now := vial_transaction_active\s+and vial_is_known_one\([^\n]+\(0\)\)\s+and \(vial_transaction_accepted or vial_accept_now\);/s,
        'one returning-ready sample closes the accepted AHB transfer exactly as the portable SystemVerilog scheduler does');
    like($top,
        qr/if vial_fiber_03_status = VIAL_FIBER_COMPLETED then\s+if vial_is_known_zero\(vial_sample_hresp\(0\)\) then\s+vial_scenario_done := true;/s,
        'completed ERROR traffic settles until the sampled response returns to OK');
    like($top, qr/procedure vial_scoreboard_compare/,
        'bounded scoreboard comparison is emitted');
    like($top, qr/vial_coverage\.stalled := vial_coverage\.stalled \+ 1;/,
        'portable stalled coverage counter is emitted');
    like($top, qr/VIAL substitution fault preserves the immutable authored field/,
        'fault substitution has an explicit immutable-source seam');
    like($top, qr/VIAL_UNKNOWN_SAMPLE/,
        'procedural checking records unknown-value evidence');
    like($top, qr/vial_emit_trace\("footer"\)/,
        'trace has an explicit closure record');
    unlike($top, qr/\\"/,
        'generated JSON uses VHDL quote doubling rather than C-style escapes');
    like($runtime, qr/fsmgen\.verification_result_manifest\.v1/,
        'normalized result schema is projected into generated VHDL');
    for my $key (qw(
        backend_evidence backend_profile capability_evidence coverage
        diagnostics drives events exclusions execution_profile expectations
        faults fibers fixture_id metrics models native_extensions parity_digest
        parity_projection plan_id portable_parity_eligible random_decisions
        result_id scenario_results schema schema_version scoreboards status
        transactions
    )) {
        like($top, qr/\b\Q$key\E\b/,
            "normalized result projection carries '$key'");
    }
    like($top, qr/sha256_counter_rejection_v1/,
        'normalized result projection preserves the exact plan-time random decision');
    my @phase = map { index($top, "-- FSMGEN VIAL PHASE: $_") }
        qw(SAMPLE REACT CHECK DRIVE);
    ok($phase[0] < $phase[1] && $phase[1] < $phase[2] && $phase[2] < $phase[3],
        'logical phases occur in exact SAMPLE/REACT/CHECK/DRIVE order');
    my $adapter = artifact_by_role($emission, 'vhdl_probe_adapter')->{content};
    like($adapter,
        qr/-- VIAL declared probe probe\/reg_data_q maps to reg_data_q/,
        'probe adapter names the exact bridge-declared probe and target');
    like($adapter,
        qr/<< signal \.base_output_arbitration_tb\.dut\.reg_data_q : std_logic_vector\(31 downto 0\) >>;/,
        'probe hierarchy exists only in the explicit adapter');
    my $vhdl = join('', map { $_->{content} }
        grep { $_->{language} eq 'vhdl' } @{$emission->{artifacts}});
    unlike($vhdl, qr/\b(?:ghdl|osvvm|uvvm|xcelium|nvc|modelsim|questa)\b/i,
        'canonical VHDL has no simulator or methodology-provider branch');
    unlike($vhdl, qr/\bpsl\b/i, 'foundation emits no PSL');
    unlike($vhdl, qr/vhdl-observation-package|observation_vhdl_pkg/i,
        'native VIAL foundation neither consumes nor rewrites the inert legacy package');
};

subtest 'standard, tool, commands, and capability states are exact and honest' => sub {
    my $emission = emit_backend();
    my $manifest = $emission->{backend_manifest};
    is($manifest->{standard_profile}{standard}, 'IEEE 1076-2008',
        'language standard is exact');
    is($manifest->{tool_profile}{tool_name}, 'ghdl', 'selected tool is exact');
    is($manifest->{tool_profile}{qualified_version}, '6.0.0',
        'selected qualification version is exact');
    is($manifest->{tool_profile}{selection_status}, 'selected_not_executed',
        'tool selection is explicitly unexecuted');
    is($manifest->{tool_profile}{provider_library}, 'none',
        'foundation has no methodology provider');
    ok(!$manifest->{tool_profile}{execution_evidence}, 'tool profile carries no execution evidence');
    my $evidence = $manifest->{capability_evidence};
    is($evidence->{emission}, 'passed_portable_semantics',
        'portable semantics emission passes without a runtime claim');
    is($evidence->{static_validation}, 'passed_structural_semantics',
        'static evidence covers the selected semantic structure');
    is($evidence->{drivers}, 'passed_emission_only', 'drivers remain emission-only');
    is($evidence->{samplers}, 'passed_emission_only', 'samplers remain emission-only');
    is($evidence->{scheduler}, 'passed_emission_only', 'scheduler remains emission-only');
    is($evidence->{scenarios}, 'passed_emission_only', 'scenarios remain emission-only');
    is($evidence->{models}, 'passed_emission_only', 'models remain emission-only');
    is($evidence->{probe_adapters}, 'passed_declared_external_name_emission_only',
        'probe adapter remains explicit emission-only evidence');
    is($evidence->{provider_fetch}, 'not_performed', 'ordinary emission fetches no provider');
    is($evidence->{analysis}, 'not_run', 'analysis is not run');
    is($evidence->{elaboration}, 'not_run', 'elaboration is not run');
    is($evidence->{runtime}, 'not_run', 'runtime is not run');
    is($evidence->{result}, 'projection_emitted_not_produced',
        'result projection is emitted without claiming a produced result');
    is($evidence->{parity}, 'not_evaluated', 'parity is not evaluated');
    is($evidence->{psl}, 'not_emitted', 'PSL is not emitted');
    is($evidence->{full_vhdl_2008}, 'not_claimed', 'full VHDL-2008 is not claimed');
    is($evidence->{product_support}, 'not_claimed', 'product support is not claimed');
    is_deeply($manifest->{migration}, {
        legacy_surface => 'vhdl_observation_package_skeleton',
        legacy_state => 'unchanged_not_consumed',
        successor_profile => 'vhdl_portable_ghdl',
        migration_kind => 'parallel_versioned_surface',
    }, 'manifest records the exact parallel migration without consuming the legacy package');
    is_deeply($manifest->{source_order}{sources}, [
        'backends/vhdl_portable_ghdl/src/fsmgen_vial_types_pkg.vhd',
        'backends/vhdl_portable_ghdl/src/fsmgen_vial_runtime_pkg.vhd',
        'backends/vhdl_portable_ghdl/src/base_output_arbitration_metadata_pkg.vhd',
        'backends/vhdl_portable_ghdl/src/dut/ahb_lite_subordinate.vhd',
        'backends/vhdl_portable_ghdl/src/base_output_arbitration_tb.vhd',
        'backends/vhdl_portable_ghdl/src/base_output_arbitration_probe_adapter.vhd',
    ], 'analysis source order is explicit and deterministic');
    for my $role (qw(analyze_command elaborate_command run_command)) {
        my $command = JSON::PP->new->decode(artifact_by_role($emission, $role)->{content});
        is($command->{logical_executable}, 'ghdl', "$role records the selected logical executable");
        is($command->{execution_status}, 'not_run', "$role remains unexecuted evidence");
        ok(scalar(grep { $_ eq '--std=08' } @{$command->{arguments}}),
            "$role fixes the VHDL-2008 option");
        ok(scalar(grep { $_ eq '--work=fsmgen_vial' } @{$command->{arguments}}),
            "$role fixes the work library");
        unlike($json->encode($command), qr{"(?:working_directory|inputs|expected_outputs)":"/},
            "$role contains no absolute project path");
    }
};

subtest 'static validation and negotiation fail closed on malformed inputs' => sub {
    my $emission = emit_backend();
    my $static = $emission->{static_validation};
    ok($static->{ok}, 'selected portable semantics pass structural validation');
    is_deeply([sort keys %$static],
        [sort @{FSM::VIAL::Backend::VHDLPortableStaticValidator->result_keys}],
        'static result is closed');
    ok(!(grep { $_->{status} ne 'passed' } @{$static->{checks}}),
        'every selected structural check passes');
    is(scalar(@{$static->{checks}}), 20,
        'static validator runs the exact twenty semantic checks');

    my @source = map { clone($_) }
        grep { $_->{language} eq 'vhdl' } @{$emission->{artifacts}};
    my @missing = grep { $_->{role} ne 'vhdl_runtime_package' } @source;
    static_failure(\@missing, 'VIAL_VHDL_STATIC_REQUIRED_ROLE_ERROR',
        'missing required VHDL role');
    my @provider = map { clone($_) } @source;
    artifact_in(\@provider, 'vhdl_fixture_top')->{content} .= "-- ghdl-only workaround\n";
    static_failure(\@provider, 'VIAL_VHDL_STATIC_PROVIDER_LEAK',
        'provider-specific source leakage');
    my @placeholder = map { clone($_) } @source;
    artifact_in(\@placeholder, 'vhdl_runtime_package')->{content} .= "-- __FSMGEN_BAD__\n";
    static_failure(\@placeholder, 'VIAL_VHDL_STATIC_TEXT_SHAPE_ERROR',
        'unresolved generation placeholder');

    my @multiple_scheduler = map { clone($_) } @source;
    my $multiple_top = artifact_in(\@multiple_scheduler, 'vhdl_fixture_top');
    $multiple_top->{content} =~ s/end architecture portable_semantics;/  competing_scheduler : process\n  begin\n    wait;\n  end process competing_scheduler;\nend architecture portable_semantics;/;
    static_failure(\@multiple_scheduler, 'VIAL_VHDL_STATIC_SCHEDULER_AUTHORITY_ERROR',
        'multiple semantic scheduler candidates');

    my @delta_authority = map { clone($_) } @source;
    artifact_in(\@delta_authority, 'vhdl_fixture_top')->{content}
        =~ s/wait for 1 ns;/wait for 0 ns;/;
    static_failure(\@delta_authority, 'VIAL_VHDL_STATIC_SCHEDULER_AUTHORITY_ERROR',
        'delta-cycle semantic authority');

    my @phase_order = map { clone($_) } @source;
    my $phase_top = artifact_in(\@phase_order, 'vhdl_fixture_top');
    $phase_top->{content} =~ s/PHASE: SAMPLE/PHASE: TEMP/;
    $phase_top->{content} =~ s/PHASE: REACT/PHASE: SAMPLE/;
    $phase_top->{content} =~ s/PHASE: TEMP/PHASE: REACT/;
    static_failure(\@phase_order, 'VIAL_VHDL_STATIC_PHASE_ORDER_ERROR',
        'unstable phase order');

    my @undeclared_hierarchy = map { clone($_) } @source;
    artifact_in(\@undeclared_hierarchy, 'vhdl_probe_adapter')->{content}
        =~ s/\.dut\.reg_data_q/\.dut\.undeclared_q/;
    static_failure(\@undeclared_hierarchy, 'VIAL_VHDL_STATIC_PROBE_ADAPTER_ERROR',
        'undeclared hierarchy target');

    my @rank_drift = map { clone($_) } @source;
    artifact_in(\@rank_drift, 'vhdl_fixture_metadata')->{content}
        =~ s/VIAL_OPERATION_COUNT : natural := 21;/VIAL_OPERATION_COUNT : natural := 22;/;
    static_failure(\@rank_drift, 'VIAL_VHDL_STATIC_METADATA_ERROR',
        'operation-rank metadata drift');

    my @scoreboard_overflow = map { clone($_) } @source;
    artifact_in(\@scoreboard_overflow, 'vhdl_fixture_top')->{content}
        =~ s/"VIAL_SCOREBOARD_OVERFLOW"/"VIAL_SCOREBOARD_UNBOUNDED"/;
    static_failure(\@scoreboard_overflow, 'VIAL_VHDL_STATIC_SCOREBOARD_ERROR',
        'missing scoreboard overflow oracle');

    my @unknown_evidence = map { clone($_) } @source;
    artifact_in(\@unknown_evidence, 'vhdl_fixture_top')->{content}
        =~ s/VIAL_UNKNOWN_SAMPLE/VIAL_SAMPLE/;
    static_failure(\@unknown_evidence, 'VIAL_VHDL_STATIC_DIAGNOSTIC_ERROR',
        'missing unknown-value evidence');

    my @trace_closure = map { clone($_) } @source;
    artifact_in(\@trace_closure, 'vhdl_fixture_top')->{content}
        =~ s/vial_emit_trace\("footer"\)/vial_emit_trace("open")/;
    static_failure(\@trace_closure, 'VIAL_VHDL_STATIC_TRACE_CLOSURE_ERROR',
        'trace non-closure');

    my @invalid_json_quote = map { clone($_) } @source;
    artifact_in(\@invalid_json_quote, 'vhdl_fixture_top')->{content}
        =~ s/""payload""/\\"payload\\"/;
    static_failure(\@invalid_json_quote, 'VIAL_VHDL_STATIC_TRACE_CLOSURE_ERROR',
        'C-style JSON quote escaping in VHDL');

    my @result_consistency = map { clone($_) } @source;
    artifact_in(\@result_consistency, 'vhdl_fixture_top')->{content}
        =~ s/vial_result_consistent\s*:=/vial_result_unchecked :=/;
    static_failure(\@result_consistency, 'VIAL_VHDL_STATIC_RESULT_ERROR',
        'result inconsistency');

    my @psl_request = map { clone($_) } @source;
    artifact_in(\@psl_request, 'vhdl_fixture_top')->{content} .= "-- psl assert always true\n";
    static_failure(\@psl_request, 'VIAL_VHDL_STATIC_CHECK_ERROR',
        'unsupported PSL request');

    backend_failure(emit_backend(backend_profile => 'vhdl_other'),
        'VIAL_VHDL_BACKEND_UNSUPPORTED', 'substituted backend profile');
    backend_failure(emit_backend(artifact_root => '../outside'),
        'VIAL_VHDL_BACKEND_INVOCATION_ERROR', 'unsafe artifact root');
    my $missing_vhdl = clone($built->{backend_inputs});
    $missing_vhdl->{dut_vhdl} = [];
    backend_failure(emit_backend(backend_inputs => $missing_vhdl),
        'VIAL_VHDL_BACKEND_UNSUPPORTED', 'missing VHDL DUT');
    my $bad_hash = clone($built->{backend_inputs});
    $bad_hash->{dut_vhdl}[0]{text} .= "\n";
    backend_failure(emit_backend(backend_inputs => $bad_hash),
        'VIAL_VHDL_BACKEND_UNSUPPORTED', 'VHDL DUT digest mismatch');

    my $nine_state = $built->{execution_ir}->as_hashref;
    $nine_state->{type_table}[0]{semantic_type}{state_domain} = 'nine_state';
    backend_failure(emit_backend(execution_ir => execution_object($nine_state)),
        'VIAL_VHDL_BACKEND_UNSUPPORTED', 'unsupported nine-state semantic need');

    my $multi_domain = $built->{execution_ir}->as_hashref;
    push @{$multi_domain->{domains}}, clone($multi_domain->{domains}[0]);
    backend_failure(emit_backend(execution_ir => execution_object($multi_domain)),
        'VIAL_VHDL_BACKEND_UNSUPPORTED', 'multiple semantic clock domains');

    my $asynchronous_event = $built->{execution_ir}->as_hashref;
    $asynchronous_event->{events}[1]{phase} = 'asynchronous';
    backend_failure(emit_backend(execution_ir => execution_object($asynchronous_event)),
        'VIAL_VHDL_BACKEND_UNSUPPORTED', 'asynchronous semantic event use');
};

subtest 'artifact publication is atomic, collision-safe, and exactly cleaned' => sub {
    cleanup_artifact_root();
    my $emission = emit_backend();
    my $first = FSM::VIAL::ArtifactTransaction->publish({
        repo_root => repo_path(),
        artifact_root => $artifact_root,
        operation_id => $emission->{operation_id},
        artifacts => $emission->{artifacts},
    });
    ok($first->{ok}, 'first publication succeeds');
    is($first->{status}, 'planned', 'first publication atomically creates the declared tree');
    ok(-d repo_path(split m{/}, $artifact_root), 'published tree exists under the repository');
    my $identical = FSM::VIAL::ArtifactTransaction->publish({
        repo_root => repo_path(),
        artifact_root => $artifact_root,
        operation_id => $emission->{operation_id},
        artifacts => $emission->{artifacts},
    });
    ok($identical->{ok}, 'identical republication succeeds');
    is($identical->{status}, 'unchanged', 'identical tree is not rewritten');
    my @mutated = map { clone($_) } @{$emission->{artifacts}};
    $mutated[0]{content} .= "\n";
    my $collision = FSM::VIAL::ArtifactTransaction->publish({
        repo_root => repo_path(),
        artifact_root => $artifact_root,
        operation_id => $emission->{operation_id},
        artifacts => \@mutated,
    });
    ok(!$collision->{ok}, 'byte-different republication fails');
    is($collision->{diagnostics}[0]{code}, 'VIAL_ARTIFACT_COLLISION',
        'collision has the exact artifact-transaction diagnostic');
    cleanup_artifact_root();
    ok(!-e repo_path(split m{/}, $artifact_root), 'published test tree is removed exactly');
    ok(!-e repo_path('.artifacts', 'tmp', 'vial', $emission->{operation_id}),
        'no operation staging residue remains');
};

subtest 'checked gallery and support discovery remain byte-exact and honest' => sub {
    my $emission = emit_backend(
        artifact_root => '.artifacts/gallery/vial-vhdl-portable-semantics',
    );
    my $gallery = repo_path(qw(vial review_gallery vhdl_portable_ghdl
        ahb_base_output_portable_semantics));
    for my $artifact (@{$emission->{artifacts}}) {
        (my $relative = $artifact->{relpath}) =~ s{\Abackends/vhdl_portable_ghdl/}{};
        is(slurp_raw(File::Spec->catfile($gallery, split m{/}, $relative)),
            $artifact->{content}, "gallery snapshot '$relative' matches exact emitted bytes");
    }
    my $readme = slurp_raw(File::Spec->catfile($gallery, 'README.md'));
    like($readme, qr/plan\/038c968edbd7782d36f49af5092dd4301ca95989914eeba73250f9b609525574/,
        'gallery names its exact deterministic plan');
    like($readme,
        qr/Separately, this snapshot passes\s+analysis, elaboration, bounded execution/,
        'gallery points to the separately qualified exact execution evidence');

    my $contract = build_capability_manifest()->{language_surface}{vial_vhdl_emission};
    is($contract->{profile}, $profile, 'capability manifest discovers the exact private profile');
    is($contract->{backend_stage_status}{emission},
        'shipped_complete_selected_portable_emission',
        'support state advertises complete selected portable emission');
    is($contract->{limits}{generated_vhdl_sources}, 6,
        'support state reports the exact six-source graph');
    is($contract->{limits}{source_map_entries}, 59,
        'support state reports the exact source-map count');
    is($contract->{limits}{static_validation_checks}, 20,
        'support state reports the exact static-check count');
    is($contract->{backend_stage_status}{analysis},
        'passed_exact_ghdl_6_0_0_llvm_jit',
        'support state records the separately checked exact GHDL analysis qualification');
    ok(!$contract->{public_embedding_api}, 'private emitter is not promoted to public embedding API');
};

cleanup_artifact_root();
done_testing();

sub build_plan {
    my $semantic_ir = FSM::VIAL::Parser->parse_source({
        text => slurp_raw(repo_path(split m{/}, $vial_id)),
        source_name => $vial_id,
        source_catalog => {},
    });
    return FSM::VIAL::PlanBuilder->build({
        semantic_ir => $semantic_ir,
        hial_source => {
            source_id => $hial_id,
            text => slurp_raw(repo_path(split m{/}, $hial_id)),
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
    return FSM::VIAL::Backend::VHDLPortableGHDL->emit({
        execution_ir => $built->{execution_ir},
        bridge_manifest => $built->{bridge_manifest},
        backend_inputs => $built->{backend_inputs},
        artifact_root => '.artifacts/test/vial-vhdl-portable-semantics-emission',
        backend_profile => $profile,
        %override,
    });
}

sub static_failure {
    my ($artifacts, $code, $label) = @_;
    my $result = FSM::VIAL::Backend::VHDLPortableStaticValidator->validate({
        backend_profile => $profile,
        artifacts => $artifacts,
    });
    ok(!$result->{ok}, "$label fails static validation");
    ok(scalar(grep { $_->{code} eq $code } @{$result->{diagnostics}}),
        "$label has diagnostic $code");
}

sub backend_failure {
    my ($result, $code, $label) = @_;
    ok(!$result->{ok}, "$label fails backend emission");
    is($result->{diagnostics}[0]{code}, $code, "$label has diagnostic $code");
    is_deeply($result->{artifacts}, [], "$label emits no artifact");
}

sub artifact_by_role {
    my ($emission, $role) = @_;
    my @found = grep { $_->{role} eq $role } @{$emission->{artifacts}};
    die "artifact role '$role' does not occur exactly once\n" unless @found == 1;
    return $found[0];
}

sub artifact_in {
    my ($artifacts, $role) = @_;
    my @found = grep { $_->{role} eq $role } @$artifacts;
    die "artifact role '$role' does not occur exactly once\n" unless @found == 1;
    return $found[0];
}

sub cleanup_artifact_root {
    my $path = repo_path(split m{/}, $artifact_root);
    return unless -e $path;
    my $errors;
    remove_tree($path, {error => \$errors});
    die "cannot remove exact test artifact root '$artifact_root'\n"
        if ref($errors) eq 'ARRAY' && @$errors;
}

sub clone {
    my ($value) = @_;
    return JSON::PP->new->decode($json->encode($value));
}

sub execution_object {
    my ($data) = @_;
    return bless {data => clone($data)}, 'FSM::VIAL::ExecutionIR';
}

sub slurp_raw {
    my ($path) = @_;
    open my $fh, '<:raw', $path or die "cannot read $path: $!\n";
    local $/;
    my $text = <$fh>;
    close $fh or die "cannot close $path: $!\n";
    return $text;
}

sub repo_path {
    return File::Spec->catfile($FindBin::Bin, '..', @_);
}
