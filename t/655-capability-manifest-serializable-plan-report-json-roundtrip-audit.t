#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use File::Spec;
use FindBin;
use JSON::PP qw(decode_json encode_json);
use Scalar::Util qw(blessed);

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::Support::CapabilityManifest qw(build_capability_manifest);
use FSM::Support::CompositionReportContract qw(
    composition_report_json_fragment_path
    composition_report_public_top_level_keys
);
use FSM::Support::NormalizedSemanticReportContract qw(normalized_semantic_public_top_level_keys);
use FSM::Support::SerializablePlanReportContract qw(
    serializable_plan_report_json_safe_surface_keys
    serializable_plan_report_nested_contract_source_map
    serializable_plan_report_raw_shell_replacement_keys
    serializable_plan_report_raw_shell_replacement_map
    serializable_plan_report_surface_registry
    serializable_plan_report_surface_registry_entry_keys
);

subtest 'capability manifest serializable_plan_reports branch survives JSON round trip' => sub {
    my $manifest = build_capability_manifest();
    ok(length(encode_json($manifest)), 'manifest encodes as JSON');
    my $decoded = decode_json(encode_json($manifest));
    my $branch = $decoded->{embedding}{serializable_plan_reports};

    ok(!contains_blessed($branch), 'round-tripped manifest branch contains no unexpected blessed values');
    is(
        $branch->{contract_source},
        'FSM::Support::SerializablePlanReportContract',
        'round-trip manifest keeps serializable plan/report contract owner',
    );
    is_deeply(
        $branch->{nested_contract_source_map},
        serializable_plan_report_nested_contract_source_map(),
        'round-trip manifest keeps serializable nested contract owner map',
    );
    is_deeply(
        as_set([keys %{$branch->{nested_contract_source_map}}]),
        as_set($branch->{json_safe_surface_keys}),
        'round-trip manifest source map covers decoded JSON-safe surfaces',
    );
    is_deeply(
        $branch->{surface_registry},
        serializable_plan_report_surface_registry(),
        'round-trip manifest keeps serializable surface registry',
    );
    is_deeply(
        $branch->{surface_registry_entry_keys},
        serializable_plan_report_surface_registry_entry_keys(),
        'round-trip manifest keeps surface registry entry key list',
    );
    for my $surface (sort keys %{$branch->{surface_registry}}) {
        is_deeply(
            as_set([keys %{$branch->{surface_registry}{$surface}}]),
            as_set($branch->{surface_registry_entry_keys}),
            "$surface round-trip manifest registry entry keys match decoded shape",
        );
    }
    is_deeply(
        as_set([keys %{$branch->{surface_registry}}]),
        as_set(serializable_plan_report_json_safe_surface_keys()),
        'round-trip manifest registry covers JSON-safe surfaces',
    );
    is_deeply(
        $branch->{raw_shell_replacement_map},
        serializable_plan_report_raw_shell_replacement_map(),
        'round-trip manifest keeps raw-shell replacement map',
    );
    is_deeply(
        $branch->{raw_shell_replacement_keys},
        serializable_plan_report_raw_shell_replacement_keys(),
        'round-trip manifest keeps raw-shell replacement key list',
    );
    is_deeply(
        as_set([keys %{$branch->{raw_shell_replacement_map}}]),
        as_set($branch->{raw_shell_replacement_keys}),
        'round-trip manifest replacement map keys match decoded key list',
    );
    is_deeply(
        $branch->{guidance},
        $manifest->{embedding}{serializable_plan_reports}{guidance},
        'round-trip manifest keeps exact guidance list',
    );
    is_deeply(
        $branch->{normalized_semantic_report_public_top_level_keys},
        normalized_semantic_public_top_level_keys(),
        'round-trip manifest keeps normalized semantic report top-level keys',
    );
    is_deeply(
        $branch->{composition_report_public_top_level_keys},
        composition_report_public_top_level_keys(),
        'round-trip manifest keeps composition report top-level keys',
    );
    is(
        $branch->{composition_report_json_fragment_path},
        composition_report_json_fragment_path(),
        'round-trip manifest keeps composition report JSON fragment path',
    );
    is_deeply(
        $branch->{composition_plan_snapshot_contract},
        $manifest->{embedding}{serializable_plan_reports}{composition_plan_snapshot_contract},
        'round-trip manifest keeps exact composition child contract',
    );
    is(
        $branch->{composition_plan_snapshot_contract}{object_name},
        'composition_plan_snapshot',
        'round-trip manifest keeps composition snapshot child contract',
    );
    is_deeply(
        $branch->{generation_result_snapshot_contract},
        $manifest->{embedding}{serializable_plan_reports}{generation_result_snapshot_contract},
        'round-trip manifest keeps exact generation child contract',
    );
    is(
        $branch->{generation_result_snapshot_contract}{object_name},
        'generation_result_snapshot',
        'round-trip manifest keeps generation snapshot child contract',
    );
    is_deeply(
        $branch->{diagnostic_summary_contract},
        $manifest->{embedding}{serializable_plan_reports}{diagnostic_summary_contract},
        'round-trip manifest keeps exact diagnostic child contract',
    );
    is(
        $branch->{diagnostic_summary_contract}{object_name},
        'diagnostic_summary',
        'round-trip manifest keeps diagnostic summary child contract',
    );
    ok(
        is_json_boolean($branch->{current_serializable_surfaces_json_safe}),
        'round-trip manifest keeps current surface JSON-safe flag as JSON boolean',
    );
    ok(
        is_json_boolean($branch->{raw_hdl_generator_branches_json_safe}),
        'round-trip manifest keeps raw HDLGenerator JSON-safe flag as JSON boolean',
    );
    ok($branch->{current_serializable_surfaces_json_safe}, 'round-trip manifest keeps current surfaces JSON-safe');
    ok(!$branch->{raw_hdl_generator_branches_json_safe}, 'round-trip manifest keeps raw HDLGenerator branches non-JSON-safe');
};

done_testing();

sub as_set {
    my ($values) = @_;
    return {map { $_ => 1 } @{$values || []}};
}

sub contains_blessed {
    my ($value) = @_;
    return 0 if blessed($value) && blessed($value) eq 'JSON::PP::Boolean';
    return 1 if blessed($value);
    return 0 unless ref($value);

    if (ref($value) eq 'ARRAY') {
        return 1 if grep { contains_blessed($_) } @$value;
        return 0;
    }

    if (ref($value) eq 'HASH') {
        return 1 if grep { contains_blessed($_) } values %$value;
        return 0;
    }

    return 0;
}

sub is_json_boolean {
    my ($value) = @_;
    return defined(blessed($value)) && blessed($value) eq 'JSON::PP::Boolean';
}
