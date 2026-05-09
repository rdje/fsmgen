#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use File::Spec;
use FindBin;

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::Support::SerializableCompositionPlanSnapshot qw(
    build_serializable_composition_plan_snapshot
    build_serializable_composition_plan_snapshot_contract
    serializable_composition_plan_snapshot_contract_source
);
use FSM::Support::SerializableDiagnosticSummary qw(
    build_serializable_diagnostic_summary
    build_serializable_diagnostic_summary_contract
    serializable_diagnostic_summary_contract_source
);
use FSM::Support::SerializableGenerationResultSnapshot qw(
    build_serializable_generation_result_snapshot
    build_serializable_generation_result_snapshot_contract
    serializable_generation_result_snapshot_contract_source
);

subtest 'composition plan snapshot reports owned source metadata' => sub {
    my $source = serializable_composition_plan_snapshot_contract_source();
    assert_contract_owner(build_serializable_composition_plan_snapshot_contract(), $source, 'composition contract');
    assert_report_owner(build_serializable_composition_plan_snapshot(), $source, 'composition snapshot');
};

subtest 'generation result snapshot reports owned source metadata' => sub {
    my $source = serializable_generation_result_snapshot_contract_source();
    assert_contract_owner(build_serializable_generation_result_snapshot_contract(), $source, 'generation contract');
    assert_report_owner(build_serializable_generation_result_snapshot(), $source, 'generation snapshot');
};

subtest 'diagnostic summary reports owned source metadata' => sub {
    my $source = serializable_diagnostic_summary_contract_source();
    assert_contract_owner(build_serializable_diagnostic_summary_contract(), $source, 'diagnostic contract');
    assert_report_owner(
        build_serializable_diagnostic_summary(report => {success => 1, diagnostics => []}),
        $source,
        'diagnostic summary',
    );
};

done_testing();

sub assert_contract_owner {
    my ($contract, $source, $label) = @_;
    is($contract->{contract_source}, $source, "$label contract_source points to owner");
    is($contract->{report_source}, $source, "$label report_source points to owner");
}

sub assert_report_owner {
    my ($payload, $source, $label) = @_;
    is($payload->{contract_source}, $source, "$label contract_source points to owner");
    is($payload->{report_source}, $source, "$label report_source points to owner");
}
