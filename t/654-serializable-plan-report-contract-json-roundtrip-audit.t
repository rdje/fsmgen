#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use File::Spec;
use FindBin;
use JSON::PP qw(decode_json encode_json);
use Scalar::Util qw(blessed);

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::Support::CompositionReportContract qw(
    composition_report_json_fragment_path
    composition_report_public_top_level_keys
);
use FSM::Support::NormalizedSemanticReportContract qw(normalized_semantic_public_top_level_keys);
use FSM::Support::SerializablePlanReportContract qw(
    build_serializable_plan_report_contract
    serializable_plan_report_json_safe_surface_keys
    serializable_plan_report_nested_contract_source_map
    serializable_plan_report_raw_shell_replacement_keys
    serializable_plan_report_raw_shell_replacement_map
);

subtest 'serializable plan/report contract remains plain data after JSON round trip' => sub {
    my $contract = build_serializable_plan_report_contract();
    ok(length(encode_json($contract)), 'contract encodes as JSON');
    my $decoded = decode_json(encode_json($contract));

    ok(!contains_blessed($decoded), 'decoded contract contains no unexpected blessed values');
    is($decoded->{schema_version}, 1, 'round-trip contract keeps schema version 1');
    is($decoded->{status}, 'bounded_public', 'round-trip contract keeps bounded_public status');
    is(
        $decoded->{contract_source},
        'FSM::Support::SerializablePlanReportContract',
        'round-trip contract keeps contract source',
    );
    ok(
        defined($decoded->{purpose}) && !ref($decoded->{purpose}) && length($decoded->{purpose}),
        'round-trip contract keeps non-empty scalar purpose',
    );
    like(
        $decoded->{purpose},
        qr/JSON-safe plan\/report surfaces/,
        'round-trip purpose describes JSON-safe plan/report surfaces',
    );
    is_deeply(
        $decoded->{json_safe_surface_keys},
        serializable_plan_report_json_safe_surface_keys(),
        'round-trip contract keeps JSON-safe surface key list',
    );
    is(
        scalar(@{$decoded->{json_safe_surface_keys}}),
        scalar(keys %{as_set($decoded->{json_safe_surface_keys})}),
        'round-trip JSON-safe surface key list remains unique',
    );
    is_deeply(
        $decoded->{nested_contract_source_map},
        serializable_plan_report_nested_contract_source_map(),
        'round-trip contract keeps nested contract source map',
    );
    is_deeply(
        $decoded->{raw_shell_replacement_map},
        serializable_plan_report_raw_shell_replacement_map(),
        'round-trip contract keeps raw-shell replacement map',
    );
    is_deeply(
        $decoded->{raw_shell_replacement_keys},
        serializable_plan_report_raw_shell_replacement_keys(),
        'round-trip contract keeps raw-shell replacement key list',
    );
    is_deeply(
        as_set([keys %{$decoded->{raw_shell_replacement_map}}]),
        as_set($decoded->{raw_shell_replacement_keys}),
        'round-trip replacement map keys match decoded key list',
    );
    ok(ref($decoded->{guidance}) eq 'ARRAY', 'round-trip contract keeps guidance as an array');
    ok(@{$decoded->{guidance}} > 0, 'round-trip contract keeps non-empty guidance');
    is(
        scalar(@{$decoded->{guidance}}),
        scalar(keys %{as_set($decoded->{guidance})}),
        'round-trip guidance entries remain unique',
    );
    ok(
        grep({ /JSON-safe report surfaces/ } @{$decoded->{guidance}}),
        'round-trip guidance still points to JSON-safe surfaces',
    );
    ok(
        grep({ /raw HDLGenerator branches/ } @{$decoded->{guidance}}),
        'round-trip guidance still warns about raw HDLGenerator branches',
    );
    is_deeply(
        $decoded->{normalized_semantic_report_public_top_level_keys},
        normalized_semantic_public_top_level_keys(),
        'round-trip contract keeps normalized semantic report top-level keys',
    );
    is_deeply(
        $decoded->{composition_report_public_top_level_keys},
        composition_report_public_top_level_keys(),
        'round-trip contract keeps composition report top-level keys',
    );
    is(
        $decoded->{composition_report_json_fragment_path},
        composition_report_json_fragment_path(),
        'round-trip contract keeps composition report JSON fragment path',
    );
    is(
        $decoded->{composition_plan_snapshot_contract}{object_name},
        'composition_plan_snapshot',
        'round-trip contract keeps composition child contract',
    );
    is(
        $decoded->{generation_result_snapshot_contract}{object_name},
        'generation_result_snapshot',
        'round-trip contract keeps generation child contract',
    );
    is(
        $decoded->{diagnostic_summary_contract}{object_name},
        'diagnostic_summary',
        'round-trip contract keeps diagnostic child contract',
    );
};

done_testing();

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

sub as_set {
    my ($values) = @_;
    return {map { $_ => 1 } @{$values || []}};
}
