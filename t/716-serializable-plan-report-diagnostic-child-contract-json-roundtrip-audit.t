#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use File::Spec;
use FindBin;
use JSON::PP qw(decode_json encode_json);

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::Support::SerializableDiagnosticSummary qw(
    build_serializable_diagnostic_summary_contract
    serializable_diagnostic_summary_contract_source
);
use FSM::Support::SerializablePlanReportContract qw(build_serializable_plan_report_contract);

subtest 'parent diagnostic child contract survives JSON round trip' => sub {
    my $decoded = decode_json(encode_json(build_serializable_plan_report_contract()));
    my $child = $decoded->{diagnostic_summary_contract};

    is_deeply(
        $child,
        build_serializable_diagnostic_summary_contract(),
        'decoded parent keeps exact canonical diagnostic child contract',
    );
    is($child->{schema_version}, 1, 'decoded diagnostic child keeps schema version');
    is($child->{status}, 'bounded_public', 'decoded diagnostic child keeps bounded_public status');
    is(
        $child->{contract_source},
        serializable_diagnostic_summary_contract_source(),
        'decoded diagnostic child keeps canonical owner',
    );
    is($child->{object_name}, 'diagnostic_summary', 'decoded diagnostic child keeps object name');
};

done_testing();
