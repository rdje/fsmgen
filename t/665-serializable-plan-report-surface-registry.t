#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use File::Spec;
use FindBin;
use JSON::PP qw(encode_json);

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::Support::CompositionReportContract qw(composition_report_contract_source);
use FSM::Support::NormalizedSemanticReportContract qw(normalized_semantic_report_contract_source);
use FSM::Support::SerializableCompositionPlanSnapshot qw(serializable_composition_plan_snapshot_contract_source);
use FSM::Support::SerializableDiagnosticSummary qw(serializable_diagnostic_summary_contract_source);
use FSM::Support::SerializableGenerationResultSnapshot qw(serializable_generation_result_snapshot_contract_source);
use FSM::Support::SerializablePlanReportContract qw(
    build_serializable_plan_report_contract
    serializable_plan_report_json_safe_surface_keys
    serializable_plan_report_surface_registry
);

subtest 'surface registry covers every advertised serializable surface' => sub {
    my $registry = serializable_plan_report_surface_registry();
    is_deeply(
        as_set([keys %{$registry}]),
        as_set(serializable_plan_report_json_safe_surface_keys()),
        'registry keys match advertised surface keys',
    );
    ok(length(encode_json($registry)), 'registry encodes as JSON');
};

subtest 'surface registry records stable owners and primary report paths' => sub {
    my $registry = serializable_plan_report_surface_registry();

    is($registry->{normalized_semantic_json}{contract_source}, normalized_semantic_report_contract_source(), 'semantic owner recorded');
    is($registry->{composition_plan_snapshot}{contract_source}, serializable_composition_plan_snapshot_contract_source(), 'composition snapshot owner recorded');
    is($registry->{generation_result_snapshot}{contract_source}, serializable_generation_result_snapshot_contract_source(), 'generation snapshot owner recorded');
    is($registry->{diagnostic_summary}{contract_source}, serializable_diagnostic_summary_contract_source(), 'diagnostic summary owner recorded');
    is($registry->{composition_provenance_report}{contract_source}, composition_report_contract_source(), 'composition provenance owner recorded');

    ok(
        grep { $_ eq 'semantic_exports.normalized_semantic_json.generation_result_snapshot' }
            @{$registry->{generation_result_snapshot}{primary_report_paths}},
        'generation snapshot registry includes semantic JSON report path',
    );
    ok(
        grep { $_ eq 'check_json.diagnostic_summary' }
            @{$registry->{diagnostic_summary}{primary_report_paths}},
        'diagnostic summary registry includes check JSON report path',
    );
};

subtest 'parent contract embeds the canonical surface registry' => sub {
    my $contract = build_serializable_plan_report_contract();
    is_deeply($contract->{surface_registry}, serializable_plan_report_surface_registry(), 'contract embeds canonical registry');
};

done_testing();

sub as_set {
    my ($values) = @_;
    return {map { $_ => 1 } @{$values || []}};
}
