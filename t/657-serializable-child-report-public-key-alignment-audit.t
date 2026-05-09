#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use File::Spec;
use FindBin;

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::Support::SerializableCompositionPlanSnapshot qw(
    build_serializable_composition_plan_snapshot
    serializable_composition_plan_snapshot_public_top_level_keys
);
use FSM::Support::SerializableDiagnosticSummary qw(
    build_serializable_diagnostic_summary
    serializable_diagnostic_summary_public_top_level_keys
);
use FSM::Support::SerializableGenerationResultSnapshot qw(
    build_serializable_generation_result_snapshot
    serializable_generation_result_snapshot_public_top_level_keys
);

subtest 'composition plan snapshot public key list matches emitted keys' => sub {
    assert_key_alignment(
        build_serializable_composition_plan_snapshot(),
        serializable_composition_plan_snapshot_public_top_level_keys(),
        'composition plan snapshot',
    );
};

subtest 'generation result snapshot public key list matches emitted keys' => sub {
    assert_key_alignment(
        build_serializable_generation_result_snapshot(),
        serializable_generation_result_snapshot_public_top_level_keys(),
        'generation result snapshot',
    );
};

subtest 'diagnostic summary public key list matches emitted keys' => sub {
    assert_key_alignment(
        build_serializable_diagnostic_summary(report => {success => 1, diagnostics => []}),
        serializable_diagnostic_summary_public_top_level_keys(),
        'diagnostic summary',
    );
};

done_testing();

sub assert_key_alignment {
    my ($payload, $advertised, $label) = @_;
    is_deeply(as_set([keys %{$payload}]), as_set($advertised), "$label emitted keys match advertised public top-level keys");
}

sub as_set {
    my ($values) = @_;
    return {map { $_ => 1 } @{$values || []}};
}
