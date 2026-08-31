#!/usr/bin/env perl

use strict;
use warnings;

use Digest::SHA qw(sha256_hex);
use File::Spec;
use FindBin;
use JSON::PP ();
use Test::More;

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::VIAL::Backend::GHDLLifecycle;
use FSM::VIAL::Backend::ResultProducer;
use FSM::VIAL::Backend::VHDLResultSchema;

my $json = JSON::PP->new->canonical(1);
my $expected_plan_id = 'plan/' . ('a' x 64);
my $expected_fixture_id = 'fixture/reference';
my $expected_domain_id = 'domain/main';
my @expected_diagnostic_code = qw(VIAL_EXPECT_SUCCESS VIAL_EXPECT_ERROR);
my @scenario_id = qw(fixture::scenario::one fixture::scenario::two);
my @expected_run_id = map { "run/$expected_plan_id/$_" } @scenario_id;
my $manifest = {map { $_ => undef }
    @{FSM::VIAL::Backend::ResultProducer->manifest_keys}};
$manifest->{schema} = 'fsmgen.verification_result_manifest.v1';
$manifest->{schema_version} = 1;
$manifest->{status} = 'pass';
$manifest->{plan_id} = $expected_plan_id;
$manifest->{result_id} = undef;
$manifest->{fixture_id} = $expected_fixture_id;
$manifest->{execution_profile} =
    'core_directed_single_clock_execution_v1';
$manifest->{backend_profile} = {
    capabilities => [
        'vial.backend.vhdl_portable_ghdl.v1',
        'vial.backend.vhdl_portable_ghdl.result_manifest_projection.v1',
    ],
    id => 'vhdl_portable_ghdl',
    methodology => 'plain_vhdl_no_provider',
    target_language => 'VHDL',
    tool_name => undef,
    tool_version => undef,
    uvm_revision => undef,
    vhdl_standard => 'IEEE 1076-2008',
};
$manifest->{portable_parity_eligible} = JSON::PP::false;
$manifest->{capability_evidence} = {
    native_only => [], required => [],
    satisfied => ['portable_checking_projection'], unsatisfied => [],
};
$manifest->{random_decisions} = [];
my $expected_random_decisions_sha256 =
    sha256_hex($json->encode($manifest->{random_decisions}));
$manifest->{$_} = [] for qw(
    events drives samples transactions expectations models fibers
    native_extensions exclusions
);
$manifest->{scoreboards} = [{
    capacity => 4, comparisons => 0, mismatches => 0,
}];
$manifest->{coverage} = [{
    bins => {not_stalled => 2, stalled => 0},
    coverpoint_id => 'coverpoint/stall_seen',
}];
$manifest->{faults} = [{
    applications => 0,
    fault_id => 'fault/unsupported_size',
    kind => 'substitution',
}];
$manifest->{metrics} = {
    coverage_not_stalled => 2,
    coverage_stalled => 0,
    diagnostic_records => 2,
    fault_applications => 0,
    scoreboard_comparisons => 0,
    scoreboard_mismatches => 0,
};
$manifest->{parity_digest} = undef;
$manifest->{backend_evidence} = {
    analysis_status => 'not_run',
    elaboration_status => 'not_run',
    runtime_status => 'projection_only',
};
$manifest->{scenario_results} = [map {
    {
        run_id => $expected_run_id[$_],
        scenario_id => $scenario_id[$_],
        status => 'pass',
        start_time => {
            domain_id => 'domain/main', cycle => 0,
            phase => 'drive', ordinal => 0,
        },
        end_time => {
            domain_id => 'domain/main', cycle => 0,
            phase => 'check', ordinal => 0,
        },
        completion_reason => 'completed',
        expectation_ids => [],
        diagnostic_ids => [],
        cancelled_fiber_ids => [],
        logical_cycle_count => 1,
    }
} 0 .. $#scenario_id];
$manifest->{diagnostics} = [map {
    {
        code => $expected_diagnostic_code[$_],
        logical_time => {
            cycle => $manifest->{scenario_results}[$_]{end_time}{cycle},
            local_index => 0, phase_rank => 3, static_rank => 3,
        },
        outcome => 'pass', severity => 'info',
    }
} 0 .. $#scenario_id];
$manifest->{parity_projection} = {
    plan_id => $expected_plan_id,
    schema => 'fsmgen.vial_vhdl_portable_outcomes.v1',
    schema_version => 1,
    outcomes => [map {{
        bus_accepts => 0,
        final_read_data_bits => '00000000',
        final_ready => 1,
        final_response => 0,
        nonzero_read_data_cycles => 0,
        ready_low_cycles => 0,
        response_error_cycles => 0,
        scenario_id => $_,
        status => 'pass',
        storage_bits => '00000000',
    }} @scenario_id],
};
my $expected_observation_catalog = {
    schema => 'fsmgen.vial_vhdl_observation_catalog.v1',
    catalog_digest => 'sha256/' . ('c' x 64),
    total_width => 18,
    entries => [
        {sample_id => 'sample/endpoint/HRDATA',
            semantic_id => 'endpoint/HRDATA', width => 8},
        {sample_id => 'sample/endpoint/HREADYOUT',
            semantic_id => 'endpoint/HREADYOUT', width => 1},
        {sample_id => 'sample/endpoint/HRESP',
            semantic_id => 'endpoint/HRESP', width => 1},
        {sample_id => 'sample/probe/reg_data_q',
            semantic_id => 'probe/reg_data_q', width => 8},
    ],
};
my $expected_record_counts = {coverage => 2};
my $encoded = $json->encode($manifest);

subtest 'canonical result is admitted at the exact byte boundary' => sub {
    my $decoded = decode_record($encoded, length($encoded));
    is_deeply($decoded, $manifest,
        'exact-boundary canonical result retains its semantic projection');
};

subtest 'one byte beyond the result boundary rejects before decoding' => sub {
    my $error = decode_failure($encoded, length($encoded) - 1);
    is($error->{code}, 'VIAL_GHDL_LIFECYCLE_LIMIT_ERROR',
        'adjacent result excess has the stable lifecycle limit diagnostic');
    is($error->{path}, '/result_produced',
        'adjacent result excess points to result production');
};

subtest 'noncanonical runtime result bytes reject' => sub {
    my $noncanonical = " $encoded";
    my $error = decode_failure($noncanonical, length($noncanonical));
    is($error->{code}, 'VIAL_GHDL_LIFECYCLE_RESULT_ERROR',
        'noncanonical result has the stable result diagnostic');
    is($error->{path}, '/result_produced',
        'noncanonical result points to result production');
};

subtest 'result manifest top-level vocabulary is closed' => sub {
    my $missing = clone($manifest);
    delete $missing->{metrics};
    my $missing_encoded = $json->encode($missing);
    my $missing_error = decode_failure(
        $missing_encoded, length($missing_encoded),
    );
    is($missing_error->{code}, 'VIAL_GHDL_LIFECYCLE_RESULT_ERROR',
        'missing shared manifest key rejects');
    is($missing_error->{path}, '/result_produced',
        'missing shared manifest key points to result production');

    my $foreign = clone($manifest);
    $foreign->{foreign_runtime_field} = 'unowned';
    my $foreign_encoded = $json->encode($foreign);
    my $foreign_error = decode_failure(
        $foreign_encoded, length($foreign_encoded),
    );
    is($foreign_error->{code}, 'VIAL_GHDL_LIFECYCLE_RESULT_ERROR',
        'foreign shared manifest key rejects');
    is($foreign_error->{path}, '/result_produced',
        'foreign shared manifest key points to result production');
};

subtest 'result plan identities match the sealed trace authority' => sub {
    my $top_level = clone($manifest);
    $top_level->{plan_id} = 'plan/' . ('b' x 64);
    my $top_error = identity_failure($top_level);
    is($top_error->{code}, 'VIAL_GHDL_LIFECYCLE_RESULT_ERROR',
        'foreign result plan identity rejects');
    is($top_error->{path}, '/result_produced/plan_id',
        'foreign result plan identity has the exact path');

    my $projection = clone($manifest);
    $projection->{parity_projection}{plan_id} = 'plan/' . ('b' x 64);
    my $projection_error = identity_failure($projection);
    is($projection_error->{code}, 'VIAL_GHDL_LIFECYCLE_RESULT_ERROR',
        'foreign parity-projection plan identity rejects');
    is($projection_error->{path}, '/result_produced/parity_projection/plan_id',
        'foreign parity-projection plan identity has the exact path');

    my $wrong_shape = clone($manifest);
    $wrong_shape->{parity_projection} = [];
    my $shape_error = identity_failure($wrong_shape);
    is($shape_error->{code}, 'VIAL_GHDL_LIFECYCLE_RESULT_ERROR',
        'non-object parity projection rejects');
    is($shape_error->{path}, '/result_produced/parity_projection',
        'non-object parity projection has the exact path');
};

subtest 'result scenario identities match ordered trace runs' => sub {
    my $valid = eval {
        validate_scenario_identities(clone($manifest));
        1;
    };
    ok($valid, 'closed ordered result identities are admitted');

    my $omitted = clone($manifest);
    pop @{$omitted->{scenario_results}};
    is(scenario_failure($omitted)->{path}, '/result_produced/scenario_results',
        'omitted scenario result rejects at the collection');

    my $duplicate = clone($manifest);
    $duplicate->{scenario_results}[1]{run_id} = $expected_run_id[0];
    is(scenario_failure($duplicate)->{path},
        '/result_produced/scenario_results/1/run_id',
        'duplicate run identity rejects at its ordered slot');

    my $reordered = clone($manifest);
    @{$reordered->{scenario_results}} =
        reverse @{$reordered->{scenario_results}};
    is(scenario_failure($reordered)->{path},
        '/result_produced/scenario_results/0/run_id',
        'reordered scenario results reject at the first mismatch');

    my $missing_outcome = clone($manifest);
    pop @{$missing_outcome->{parity_projection}{outcomes}};
    is(scenario_failure($missing_outcome)->{path},
        '/result_produced/parity_projection/outcomes',
        'omitted parity outcome rejects at the collection');

    my $foreign_outcome = clone($manifest);
    $foreign_outcome->{parity_projection}{outcomes}[0]{scenario_id} =
        'fixture::scenario::foreign';
    is(scenario_failure($foreign_outcome)->{path},
        '/result_produced/parity_projection/outcomes/0/scenario_id',
        'foreign parity scenario rejects at its ordered slot');
};

subtest 'VHDL parity vocabulary has one defensive schema authority' => sub {
    is(FSM::VIAL::Backend::VHDLResultSchema->parity_schema,
        'fsmgen.vial_vhdl_portable_outcomes.v1',
        'selected parity schema is exact');
    is(FSM::VIAL::Backend::VHDLResultSchema->parity_schema_version, 1,
        'selected parity schema version is exact');
    is_deeply(
        FSM::VIAL::Backend::VHDLResultSchema->parity_projection_keys,
        [qw(outcomes plan_id schema schema_version)],
        'projection vocabulary is exact');
    my $mutable = FSM::VIAL::Backend::VHDLResultSchema->parity_outcome_keys;
    is_deeply($mutable, [qw(
        bus_accepts final_read_data_bits final_ready final_response
        nonzero_read_data_cycles ready_low_cycles response_error_cycles
        scenario_id status storage_bits
    )], 'outcome vocabulary is exact');
    pop @$mutable;
    is(scalar @{FSM::VIAL::Backend::VHDLResultSchema->parity_outcome_keys}, 10,
        'callers cannot mutate the schema authority');
    my $counter_keys =
        FSM::VIAL::Backend::VHDLResultSchema->parity_counter_keys;
    is_deeply($counter_keys,
        [qw(bus_accepts nonzero_read_data_cycles ready_low_cycles
            response_error_cycles)],
        'counter vocabulary is exact');
    is_deeply(FSM::VIAL::Backend::VHDLResultSchema->parity_scalar_keys,
        [qw(final_ready final_response)],
        'scalar vocabulary is exact');
    is_deeply(FSM::VIAL::Backend::VHDLResultSchema->parity_scalar_catalog_bindings,
        {
            final_ready => 'endpoint/HREADYOUT',
            final_response => 'endpoint/HRESP',
        }, 'scalar fields bind to exact one-bit catalog semantics');
    is_deeply(FSM::VIAL::Backend::VHDLResultSchema->parity_bit_catalog_bindings,
        {
            final_read_data_bits => 'endpoint/HRDATA',
            storage_bits => 'probe/reg_data_q',
        }, 'bit-vector fields bind to exact catalog semantics');
    pop @$counter_keys;
    is(scalar @{FSM::VIAL::Backend::VHDLResultSchema->parity_counter_keys}, 4,
        'callers cannot mutate the counter authority');
    my $scalar_bindings =
        FSM::VIAL::Backend::VHDLResultSchema->parity_scalar_catalog_bindings;
    delete $scalar_bindings->{final_ready};
    is(scalar keys
        %{FSM::VIAL::Backend::VHDLResultSchema->parity_scalar_catalog_bindings},
        2, 'callers cannot mutate the catalog bindings');
    my $contract =
        FSM::VIAL::Backend::VHDLResultSchema->runtime_result_contract;
    is($contract->{schema}, 'fsmgen.verification_result_manifest.v1',
        'runtime-result schema authority is exact');
    is($contract->{backend_profile}{id}, 'vhdl_portable_ghdl',
        'runtime backend-profile authority is exact');
    is_deeply([map { $contract->{$_} } qw(
            diagnostic_local_index diagnostic_phase_rank diagnostic_static_rank
        )], [0, 3, 3], 'runtime diagnostic-time ranks are exact');
    delete $contract->{backend_profile}{id};
    is(FSM::VIAL::Backend::VHDLResultSchema
            ->runtime_result_contract->{backend_profile}{id},
        'vhdl_portable_ghdl',
        'callers cannot mutate the runtime-result contract');
};

subtest 'nested result vocabularies and statuses remain closed' => sub {
    my $valid = eval {
        validate_result_shapes(clone($manifest));
        1;
    };
    ok($valid, 'closed pass-consistent nested result is admitted');

    my $missing_scenario = clone($manifest);
    delete $missing_scenario->{scenario_results}[0]{logical_cycle_count};
    is(shape_failure($missing_scenario)->{path},
        '/result_produced/scenario_results/0/logical_cycle_count',
        'missing shared scenario member rejects at its exact path');

    my $foreign_scenario = clone($manifest);
    $foreign_scenario->{scenario_results}[0]{foreign_runtime_field} = 1;
    is(shape_failure($foreign_scenario)->{path},
        '/result_produced/scenario_results/0/foreign_runtime_field',
        'foreign shared scenario member rejects at its exact path');

    my $failed_scenario = clone($manifest);
    $failed_scenario->{scenario_results}[0]{status} = 'fail';
    is(shape_failure($failed_scenario)->{path},
        '/result_produced/scenario_results/0/status',
        'non-pass scenario rejects beneath a passing result');

    my $foreign_projection = clone($manifest);
    $foreign_projection->{parity_projection}{foreign_runtime_field} = 1;
    is(shape_failure($foreign_projection)->{path},
        '/result_produced/parity_projection/foreign_runtime_field',
        'foreign parity-projection member rejects at its exact path');

    my $missing_projection = clone($manifest);
    delete $missing_projection->{parity_projection}{schema};
    is(shape_failure($missing_projection)->{path},
        '/result_produced/parity_projection/schema',
        'missing parity-projection member rejects at its exact path');

    my $wrong_projection_schema = clone($manifest);
    $wrong_projection_schema->{parity_projection}{schema} =
        'fsmgen.vial_vhdl_portable_outcomes.v2';
    is(shape_failure($wrong_projection_schema)->{path},
        '/result_produced/parity_projection/schema',
        'foreign parity-projection schema rejects at its exact path');

    my $wrong_projection_version = clone($manifest);
    $wrong_projection_version->{parity_projection}{schema_version} = 2;
    is(shape_failure($wrong_projection_version)->{path},
        '/result_produced/parity_projection/schema_version',
        'foreign parity-projection version rejects at its exact path');

    my $missing_outcome = clone($manifest);
    delete $missing_outcome->{parity_projection}{outcomes}[0]{storage_bits};
    is(shape_failure($missing_outcome)->{path},
        '/result_produced/parity_projection/outcomes/0/storage_bits',
        'missing VHDL outcome member rejects at its exact path');

    my $foreign_outcome = clone($manifest);
    $foreign_outcome->{parity_projection}{outcomes}[0]{foreign_runtime_field} = 1;
    is(shape_failure($foreign_outcome)->{path},
        '/result_produced/parity_projection/outcomes/0/foreign_runtime_field',
        'foreign VHDL outcome member rejects at its exact path');

    my $failed_outcome = clone($manifest);
    $failed_outcome->{parity_projection}{outcomes}[0]{status} = 'fail';
    is(shape_failure($failed_outcome)->{path},
        '/result_produced/parity_projection/outcomes/0/status',
        'non-pass parity outcome rejects beneath a passing result');
};

subtest 'scenario values obey the shared passing-result contract' => sub {
    my $valid = eval {
        validate_scenario_values(clone($manifest));
        1;
    };
    ok($valid, 'closed scenario values are admitted');

    my $missing_time = clone($manifest);
    delete $missing_time->{scenario_results}[0]{start_time}{ordinal};
    is(value_failure($missing_time)->{path},
        '/result_produced/scenario_results/0/start_time/ordinal',
        'missing logical-time member rejects at its exact path');

    my $foreign_time = clone($manifest);
    $foreign_time->{scenario_results}[0]{end_time}{host_tick} = 1;
    is(value_failure($foreign_time)->{path},
        '/result_produced/scenario_results/0/end_time/host_tick',
        'foreign logical-time member rejects at its exact path');

    my $domain_drift = clone($manifest);
    $domain_drift->{scenario_results}[0]{end_time}{domain_id} = 'domain/foreign';
    is(value_failure($domain_drift)->{path},
        '/result_produced/scenario_results/0/end_time/domain_id',
        'end domain must equal the scenario start domain');

    my $foreign_domain = clone($manifest);
    $foreign_domain->{scenario_results}[0]{start_time}{domain_id} =
        'domain/foreign';
    $foreign_domain->{scenario_results}[0]{end_time}{domain_id} =
        'domain/foreign';
    is(value_failure($foreign_domain)->{path},
        '/result_produced/scenario_results/0/start_time/domain_id',
        'internally consistent foreign domain rejects against plan authority');

    my $late_start = clone($manifest);
    $late_start->{scenario_results}[0]{start_time}{cycle} = 1;
    is(value_failure($late_start)->{path},
        '/result_produced/scenario_results/0/start_time/cycle',
        'scenario start must retain the zero cycle origin');

    my $wrong_start_phase = clone($manifest);
    $wrong_start_phase->{scenario_results}[0]{start_time}{phase} = 'sample';
    is(value_failure($wrong_start_phase)->{path},
        '/result_produced/scenario_results/0/start_time/phase',
        'scenario start must use the drive phase');

    my $wrong_end_phase = clone($manifest);
    $wrong_end_phase->{scenario_results}[0]{end_time}{phase} = 'react';
    is(value_failure($wrong_end_phase)->{path},
        '/result_produced/scenario_results/0/end_time/phase',
        'scenario end must use the check phase');

    my $foreign_ordinal = clone($manifest);
    $foreign_ordinal->{scenario_results}[0]{end_time}{ordinal} = 1;
    is(value_failure($foreign_ordinal)->{path},
        '/result_produced/scenario_results/0/end_time/ordinal',
        'scenario boundary ordinal must remain zero');

    my $zero_count = clone($manifest);
    $zero_count->{scenario_results}[0]{logical_cycle_count} = 0;
    is(value_failure($zero_count)->{path},
        '/result_produced/scenario_results/0/logical_cycle_count',
        'logical cycle count must be positive');

    my $off_by_one = clone($manifest);
    $off_by_one->{scenario_results}[0]{end_time}{cycle} = 1;
    is(value_failure($off_by_one)->{path},
        '/result_produced/scenario_results/0/end_time/cycle',
        'end cycle must equal logical cycle count minus one');

    my $wrong_completion = clone($manifest);
    $wrong_completion->{scenario_results}[0]{completion_reason} =
        'expectation_failed';
    is(value_failure($wrong_completion)->{path},
        '/result_produced/scenario_results/0/completion_reason',
        'passing scenario must complete normally');

    my $wrong_collection = clone($manifest);
    $wrong_collection->{scenario_results}[0]{expectation_ids} = {};
    is(value_failure($wrong_collection)->{path},
        '/result_produced/scenario_results/0/expectation_ids',
        'scenario ID collection must remain an array');

    for my $case (
        [expectation_ids => 'expectation/foreign'],
        [diagnostic_ids => 'diagnostic/foreign'],
        [cancelled_fiber_ids => 'fiber/foreign'],
    ) {
        my ($collection, $identity) = @$case;
        my $nonempty = clone($manifest);
        $nonempty->{scenario_results}[0]{$collection} = [$identity];
        is(value_failure($nonempty)->{path},
            "/result_produced/scenario_results/0/$collection",
            "non-empty $collection rejects at its exact collection path");
    }
};

subtest 'top-level result values and aggregate totals are closed' => sub {
    my $valid = eval {
        validate_top_level_values(clone($manifest));
        1;
    };
    ok($valid, 'closed top-level result values are admitted');

    my $foreign_schema = clone($manifest);
    $foreign_schema->{schema} = 'fsmgen.verification_result_manifest.v2';
    is(top_level_failure($foreign_schema)->{path},
        '/result_produced/schema',
        'foreign result schema rejects at its exact path');

    my $string_version = clone($manifest);
    $string_version->{schema_version} = '1';
    is(top_level_failure($string_version)->{path},
        '/result_produced/schema_version',
        'numeric-looking string schema version rejects');

    my $assigned_result = clone($manifest);
    $assigned_result->{result_id} = 'result/' . ('d' x 64);
    is(top_level_failure($assigned_result)->{path},
        '/result_produced/result_id',
        'runtime projection cannot claim a finalized result identity');

    my $foreign_fixture = clone($manifest);
    $foreign_fixture->{fixture_id} = 'fixture/foreign';
    is(top_level_failure($foreign_fixture)->{path},
        '/result_produced/fixture_id',
        'fixture identity must equal plan-owned authority');

    my $foreign_backend = clone($manifest);
    $foreign_backend->{backend_profile}{id} = 'vhdl_foreign';
    is(top_level_failure($foreign_backend)->{path},
        '/result_produced/backend_profile',
        'foreign backend profile rejects');

    my $eligible = clone($manifest);
    $eligible->{portable_parity_eligible} = JSON::PP::true;
    is(top_level_failure($eligible)->{path},
        '/result_produced/portable_parity_eligible',
        'VHDL outcome projection cannot claim portable parity eligibility');

    my $digest = clone($manifest);
    $digest->{parity_digest} = 'sha256/' . ('e' x 64);
    is(top_level_failure($digest)->{path},
        '/result_produced/parity_digest',
        'VHDL outcome projection cannot claim a portable parity digest');

    my $capability = clone($manifest);
    push @{$capability->{capability_evidence}{unsatisfied}}, 'foreign';
    is(top_level_failure($capability)->{path},
        '/result_produced/capability_evidence',
        'foreign capability evidence rejects');

    my $non_array = clone($manifest);
    $non_array->{random_decisions} = {};
    is(top_level_failure($non_array)->{path},
        '/result_produced/random_decisions',
        'top-level collection must be an array');

    my $foreign_decision = clone($manifest);
    push @{$foreign_decision->{random_decisions}}, {foreign => 1};
    is(top_level_failure($foreign_decision)->{path},
        '/result_produced/random_decisions',
        'random decisions must equal plan-owned authority');

    my $nonempty = clone($manifest);
    push @{$nonempty->{events}}, {foreign => 1};
    is(top_level_failure($nonempty)->{path},
        '/result_produced/events',
        'projection-empty stream cannot carry records');

    my $negative_metric = clone($manifest);
    $negative_metric->{metrics}{fault_applications} = -1;
    is(top_level_failure($negative_metric)->{path},
        '/result_produced/metrics/fault_applications',
        'negative metric rejects at its exact path');

    my $string_metric = clone($manifest);
    $string_metric->{metrics}{fault_applications} = '0';
    is(top_level_failure($string_metric)->{path},
        '/result_produced/metrics/fault_applications',
        'numeric-looking string metric rejects');

    my $coverage_total = clone($manifest);
    $coverage_total->{coverage}[0]{bins}{not_stalled} = 1;
    $coverage_total->{metrics}{coverage_not_stalled} = 1;
    is(top_level_failure($coverage_total)->{path},
        '/result_produced/metrics',
        'coverage total must equal the authenticated trace record count');

    my $diagnostic_total = clone($manifest);
    $diagnostic_total->{metrics}{diagnostic_records} = 1;
    is(top_level_failure($diagnostic_total)->{path},
        '/result_produced/metrics/diagnostic_records',
        'diagnostic metric must equal collection cardinality');

    my $missing_diagnostic = clone($manifest);
    pop @{$missing_diagnostic->{diagnostics}};
    $missing_diagnostic->{metrics}{diagnostic_records} = 1;
    is(top_level_failure($missing_diagnostic)->{path},
        '/result_produced/diagnostics',
        'missing emitted diagnostic rejects at its collection path');

    my $extra_diagnostic = clone($manifest);
    push @{$extra_diagnostic->{diagnostics}},
        clone($extra_diagnostic->{diagnostics}[0]);
    $extra_diagnostic->{metrics}{diagnostic_records} = 3;
    is(top_level_failure($extra_diagnostic)->{path},
        '/result_produced/diagnostics',
        'extra emitted diagnostic rejects at its collection path');

    my $reordered_diagnostic = clone($manifest);
    @{$reordered_diagnostic->{diagnostics}} =
        reverse @{$reordered_diagnostic->{diagnostics}};
    is(top_level_failure($reordered_diagnostic)->{path},
        '/result_produced/diagnostics/0/code',
        'reordered diagnostic rejects at its first displaced code');

    my $foreign_diagnostic = clone($manifest);
    $foreign_diagnostic->{diagnostics}[0]{code} = 'VIAL_FOREIGN';
    is(top_level_failure($foreign_diagnostic)->{path},
        '/result_produced/diagnostics/0/code',
        'foreign safe diagnostic code rejects at its exact path');

    for my $case (
        [cycle => 1], [local_index => 1],
        [phase_rank => 2], [static_rank => 4],
    ) {
        my ($field, $value) = @$case;
        my $mistimed = clone($manifest);
        $mistimed->{diagnostics}[0]{logical_time}{$field} = $value;
        is(top_level_failure($mistimed)->{path},
            "/result_produced/diagnostics/0/logical_time/$field",
            "mistimed diagnostic $field rejects at its exact path");
    }

    my $fault_total = clone($manifest);
    $fault_total->{faults}[0]{applications} = 1;
    is(top_level_failure($fault_total)->{path},
        '/result_produced/metrics/fault_applications',
        'fault metric must equal the canonical fault record');

    my $scoreboard_total = clone($manifest);
    $scoreboard_total->{scoreboards}[0]{comparisons} = 1;
    is(top_level_failure($scoreboard_total)->{path},
        '/result_produced/metrics/scoreboard_comparisons',
        'scoreboard metric must equal the canonical scoreboard record');

    my $passing_mismatch = clone($manifest);
    $passing_mismatch->{scoreboards}[0]{mismatches} = 1;
    $passing_mismatch->{metrics}{scoreboard_mismatches} = 1;
    is(top_level_failure($passing_mismatch)->{path},
        '/result_produced/metrics/scoreboard_mismatches',
        'passing result cannot retain a scoreboard mismatch');

    my $foreign_evidence = clone($manifest);
    $foreign_evidence->{backend_evidence}{runtime_status} = 'passed';
    is(top_level_failure($foreign_evidence)->{path},
        '/result_produced/backend_evidence',
        'runtime projection evidence cannot claim provider execution');
};

subtest 'parity outcome values bind to cycles and the observation catalog' => sub {
    my $valid = eval {
        validate_outcome_values(clone($manifest));
        1;
    };
    ok($valid, 'closed parity values are admitted');

    my $negative_counter = clone($manifest);
    $negative_counter->{parity_projection}{outcomes}[0]{bus_accepts} = -1;
    is(outcome_failure($negative_counter)->{path},
        '/result_produced/parity_projection/outcomes/0/bus_accepts',
        'negative counter rejects at its exact path');

    my $oversized_counter = clone($manifest);
    $oversized_counter->{parity_projection}{outcomes}[0]{ready_low_cycles} = 2;
    is(outcome_failure($oversized_counter)->{path},
        '/result_produced/parity_projection/outcomes/0/ready_low_cycles',
        'counter cannot exceed its scenario cycle count');

    my $foreign_scalar = clone($manifest);
    $foreign_scalar->{parity_projection}{outcomes}[0]{final_ready} = 2;
    is(outcome_failure($foreign_scalar)->{path},
        '/result_produced/parity_projection/outcomes/0/final_ready',
        'foreign scalar flag rejects at its exact path');

    my $foreign_bits = clone($manifest);
    $foreign_bits->{parity_projection}{outcomes}[0]{storage_bits} = '0000000x';
    is(outcome_failure($foreign_bits)->{path},
        '/result_produced/parity_projection/outcomes/0/storage_bits',
        'foreign normalized-bit alphabet rejects at its exact path');

    my $wrong_read_width = clone($manifest);
    $wrong_read_width->{parity_projection}{outcomes}[0]{final_read_data_bits} =
        '0000000';
    is(outcome_failure($wrong_read_width)->{path},
        '/result_produced/parity_projection/outcomes/0/final_read_data_bits',
        'read-data width must equal its catalog entry');

    my $wrong_storage_width = clone($manifest);
    $wrong_storage_width->{parity_projection}{outcomes}[0]{storage_bits} =
        '000000000';
    is(outcome_failure($wrong_storage_width)->{path},
        '/result_produced/parity_projection/outcomes/0/storage_bits',
        'storage width must equal its catalog entry');

    my $impossible_read_count = clone($manifest);
    $impossible_read_count->{parity_projection}{outcomes}[0]
        {final_read_data_bits} = '00000001';
    is(outcome_failure($impossible_read_count)->{path},
        '/result_produced/parity_projection/outcomes/0/nonzero_read_data_cycles',
        'known nonzero final read data requires a counted nonzero cycle');

    my $impossible_response_count = clone($manifest);
    $impossible_response_count->{parity_projection}{outcomes}[0]
        {final_response} = 1;
    is(outcome_failure($impossible_response_count)->{path},
        '/result_produced/parity_projection/outcomes/0/response_error_cycles',
        'asserted final response requires a counted response-error cycle');

    my $impossible_ready_count = clone($manifest);
    $impossible_ready_count->{parity_projection}{outcomes}[0]{final_ready} = 0;
    is(outcome_failure($impossible_ready_count)->{path},
        '/result_produced/parity_projection/outcomes/0/ready_low_cycles',
        'deasserted final ready requires a counted ready-low cycle');
};

subtest 'record cardinality and JSON shape remain fail closed' => sub {
    my $duplicate = decode_failure(
        "$encoded\nFSMGEN_VIAL_RESULT_V1\t$encoded",
        2 * length($encoded),
    );
    is($duplicate->{code}, 'VIAL_GHDL_LIFECYCLE_RESULT_ERROR',
        'duplicate normalized results still reject');

    my $malformed = decode_failure('{', 1);
    is($malformed->{code}, 'VIAL_GHDL_LIFECYCLE_RESULT_ERROR',
        'malformed normalized result still rejects');
};

done_testing();

sub decode_record {
    my ($content, $limit) = @_;
    return FSM::VIAL::Backend::GHDLLifecycle::_decode_runtime_result_record(
        "FSMGEN_VIAL_RESULT_V1\t$content\n", $limit,
    );
}

sub decode_failure {
    my ($content, $limit) = @_;
    my $ok = eval {
        decode_record($content, $limit);
        1;
    };
    ok(!$ok, 'controlled result record rejects');
    my $error = $@;
    isa_ok($error, 'FSM::VIAL::Backend::GHDLLifecycle::Failure');
    return ref($error) ? $error : {};
}

sub identity_failure {
    my ($candidate) = @_;
    my $ok = eval {
        FSM::VIAL::Backend::GHDLLifecycle::_validate_runtime_result_plan_identity(
            $candidate, $expected_plan_id,
        );
        1;
    };
    ok(!$ok, 'foreign result identity rejects');
    my $error = $@;
    isa_ok($error, 'FSM::VIAL::Backend::GHDLLifecycle::Failure');
    return ref($error) ? $error : {};
}

sub validate_scenario_identities {
    FSM::VIAL::Backend::GHDLLifecycle::_validate_runtime_result_scenario_identities(
        $_[0], $expected_plan_id, \@expected_run_id,
    );
}

sub scenario_failure {
    my ($candidate) = @_;
    my $ok = eval {
        validate_scenario_identities($candidate);
        1;
    };
    ok(!$ok, 'invalid result scenario identity rejects');
    my $error = $@;
    isa_ok($error, 'FSM::VIAL::Backend::GHDLLifecycle::Failure');
    return ref($error) ? $error : {};
}

sub validate_result_shapes {
    FSM::VIAL::Backend::GHDLLifecycle::_validate_runtime_result_shapes($_[0]);
}

sub shape_failure {
    my ($candidate) = @_;
    my $ok = eval {
        validate_result_shapes($candidate);
        1;
    };
    ok(!$ok, 'invalid nested result shape rejects');
    my $error = $@;
    isa_ok($error, 'FSM::VIAL::Backend::GHDLLifecycle::Failure');
    return ref($error) ? $error : {};
}

sub validate_scenario_values {
    FSM::VIAL::Backend::GHDLLifecycle::_validate_runtime_result_scenario_values(
        $_[0], $expected_domain_id,
    );
}

sub value_failure {
    my ($candidate) = @_;
    my $ok = eval {
        validate_scenario_values($candidate);
        1;
    };
    ok(!$ok, 'invalid scenario value rejects');
    my $error = $@;
    isa_ok($error, 'FSM::VIAL::Backend::GHDLLifecycle::Failure');
    return ref($error) ? $error : {};
}

sub validate_outcome_values {
    FSM::VIAL::Backend::GHDLLifecycle::_validate_runtime_result_outcome_values(
        $_[0], $expected_observation_catalog,
    );
}

sub validate_top_level_values {
    FSM::VIAL::Backend::GHDLLifecycle::_validate_runtime_result_top_level_values(
        $_[0], $expected_record_counts, $expected_fixture_id,
        $expected_random_decisions_sha256, \@expected_diagnostic_code,
    );
}

sub top_level_failure {
    my ($candidate) = @_;
    my $ok = eval {
        validate_top_level_values($candidate);
        1;
    };
    ok(!$ok, 'invalid top-level result value rejects');
    my $error = $@;
    isa_ok($error, 'FSM::VIAL::Backend::GHDLLifecycle::Failure');
    return ref($error) ? $error : {};
}

sub outcome_failure {
    my ($candidate) = @_;
    my $ok = eval {
        validate_outcome_values($candidate);
        1;
    };
    ok(!$ok, 'invalid parity outcome value rejects');
    my $error = $@;
    isa_ok($error, 'FSM::VIAL::Backend::GHDLLifecycle::Failure');
    return ref($error) ? $error : {};
}

sub clone {
    return JSON::PP->new->decode(JSON::PP->new->encode($_[0]));
}
