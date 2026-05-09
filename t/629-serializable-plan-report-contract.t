#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use File::Spec;
use FindBin;
use IPC::Cmd qw(run);
use JSON::PP qw(decode_json);

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::Support::CapabilityManifest qw(build_capability_manifest);
use FSM::Support::CompositionReportContract qw(composition_report_contract_source);
use FSM::Support::EmbeddingContract qw(
    embedding_nested_contract_keys
    embedding_nested_presence_key_map
);
use FSM::Support::NormalizedSemanticReportContract qw(normalized_semantic_report_contract_source);
use FSM::Support::SerializableCompositionPlanSnapshot qw(
    serializable_composition_plan_snapshot_contract_source
);
use FSM::Support::SerializableGenerationResultSnapshot qw(
    serializable_generation_result_snapshot_contract_source
);
use FSM::Support::SerializableDiagnosticSummary qw(
    serializable_diagnostic_summary_contract_source
);
use FSM::Support::SerializablePlanReportContract qw(
    build_serializable_plan_report_contract
    serializable_plan_report_contract_source
    serializable_plan_report_json_safe_surface_keys
    serializable_plan_report_nested_contract_source_map
    serializable_plan_report_public_top_level_keys
    serializable_plan_report_raw_shell_replacement_map
);

subtest 'serializable plan/report contract advertises JSON-safe surface families' => sub {
    my $contract = build_serializable_plan_report_contract();

    is($contract->{schema_version}, 1, 'contract exposes schema version');
    is($contract->{status}, 'bounded_public', 'contract marks surface as bounded public');
    is(
        $contract->{contract_source},
        serializable_plan_report_contract_source(),
        'contract records its own owner',
    );
    is_deeply(
        $contract->{public_top_level_presence_keys},
        serializable_plan_report_public_top_level_keys(),
        'contract publishes its bounded top-level keys',
    );
    is_deeply(
        $contract->{json_safe_surface_keys},
        serializable_plan_report_json_safe_surface_keys(),
        'contract publishes the JSON-safe surface families',
    );
    is_deeply(
        $contract->{nested_contract_source_map},
        serializable_plan_report_nested_contract_source_map(),
        'contract publishes child contract owners',
    );
    is(
        $contract->{nested_contract_source_map}{normalized_semantic_json},
        normalized_semantic_report_contract_source(),
        'normalized semantic JSON is the semantic report contract',
    );
    is(
        $contract->{nested_contract_source_map}{composition_plan_snapshot},
        serializable_composition_plan_snapshot_contract_source(),
        'composition plan snapshot is the serializable plan snapshot contract',
    );
    is(
        $contract->{nested_contract_source_map}{generation_result_snapshot},
        serializable_generation_result_snapshot_contract_source(),
        'generation result snapshot is the serializable report snapshot contract',
    );
    is(
        $contract->{nested_contract_source_map}{diagnostic_summary},
        serializable_diagnostic_summary_contract_source(),
        'diagnostic summary is the serializable diagnostic report contract',
    );
    is(
        $contract->{nested_contract_source_map}{composition_provenance_report},
        composition_report_contract_source(),
        'composition provenance report is the composition report contract',
    );
    is_deeply(
        $contract->{raw_shell_replacement_map},
        serializable_plan_report_raw_shell_replacement_map(),
        'contract publishes raw-shell replacement guidance',
    );
    ok($contract->{current_serializable_surfaces_json_safe}, 'contract marks current surfaces JSON-safe');
    ok(!$contract->{raw_hdl_generator_branches_json_safe}, 'contract keeps raw HDLGenerator branches non-JSON-safe');
};

subtest 'capability manifest embeds the serializable plan/report contract' => sub {
    my $manifest = build_capability_manifest();
    my $contract = build_serializable_plan_report_contract();

    ok(
        (grep { $_ eq 'serializable_plan_reports' } @{embedding_nested_contract_keys()}),
        'embedding contract includes serializable_plan_reports as a nested contract',
    );
    is_deeply(
        $manifest->{embedding}{serializable_plan_reports},
        $contract,
        'manifest embeds the serializable plan/report contract',
    );
    is_deeply(
        $manifest->{embedding}{section_contract}{nested_presence_key_map}{serializable_plan_reports},
        embedding_nested_presence_key_map()->{serializable_plan_reports},
        'embedding section contract exposes the serializable plan/report key family',
    );
};

subtest 'CLI capability manifest exposes the serializable plan/report contract' => sub {
    my ($success, $error_message, $full_buf, $stdout_buf, $stderr_buf) = run(
        command => ['./bin/fsmgen', '--capability-manifest'],
    );

    ok($success, 'capability manifest CLI succeeds');
    is(join('', @{$stderr_buf || []}), '', 'capability manifest CLI keeps stderr clean');

    my $decoded = eval { decode_json(join('', @{$stdout_buf || []})) };
    ok($decoded, 'capability manifest CLI emits decodable JSON');

    is_deeply(
        $decoded->{embedding}{serializable_plan_reports},
        build_serializable_plan_report_contract(),
        'CLI manifest exposes the serializable plan/report contract',
    );
};

done_testing();
