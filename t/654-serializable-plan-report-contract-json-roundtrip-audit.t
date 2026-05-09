#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use File::Spec;
use FindBin;
use JSON::PP qw(decode_json encode_json);
use Scalar::Util qw(blessed);

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::Support::SerializablePlanReportContract qw(
    build_serializable_plan_report_contract
    serializable_plan_report_nested_contract_source_map
    serializable_plan_report_raw_shell_replacement_map
);

subtest 'serializable plan/report contract remains plain data after JSON round trip' => sub {
    my $contract = build_serializable_plan_report_contract();
    ok(length(encode_json($contract)), 'contract encodes as JSON');
    my $decoded = decode_json(encode_json($contract));

    ok(!contains_blessed($decoded), 'decoded contract contains no unexpected blessed values');
    is(
        $decoded->{contract_source},
        'FSM::Support::SerializablePlanReportContract',
        'round-trip contract keeps contract source',
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
