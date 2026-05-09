#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use File::Spec;
use FindBin;
use JSON::PP qw(decode_json encode_json);
use Scalar::Util qw(blessed);

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::Support::SerializableDiagnosticSummary qw(serializable_diagnostic_summary_contract_source);
use FSM::Support::SerializableGenerationResultSnapshot qw(serializable_generation_result_snapshot_contract_source);
use FSM::Support::SerializablePlanReportContract qw(serializable_plan_report_surface_registry);

subtest 'surface registry remains plain data after JSON round trip' => sub {
    my $registry = serializable_plan_report_surface_registry();
    ok(length(encode_json($registry)), 'registry encodes as JSON');
    my $decoded = decode_json(encode_json($registry));

    ok(!contains_blessed($decoded), 'decoded registry contains no unexpected blessed values');
    is(
        $decoded->{generation_result_snapshot}{contract_source},
        serializable_generation_result_snapshot_contract_source(),
        'round-trip registry keeps generation owner',
    );
    ok(
        grep { $_ eq 'semantic_exports.normalized_semantic_json.generation_result_snapshot' }
            @{$decoded->{generation_result_snapshot}{primary_report_paths}},
        'round-trip registry keeps generation semantic JSON path',
    );
    is(
        $decoded->{diagnostic_summary}{contract_source},
        serializable_diagnostic_summary_contract_source(),
        'round-trip registry keeps diagnostic owner',
    );
    ok(
        grep { $_ eq 'check_json.diagnostic_summary' }
            @{$decoded->{diagnostic_summary}{primary_report_paths}},
        'round-trip registry keeps check JSON diagnostic path',
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
