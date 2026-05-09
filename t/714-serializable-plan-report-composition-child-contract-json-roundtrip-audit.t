#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use File::Spec;
use FindBin;
use JSON::PP qw(decode_json encode_json);

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::Support::SerializableCompositionPlanSnapshot qw(
    build_serializable_composition_plan_snapshot_contract
    serializable_composition_plan_snapshot_contract_source
);
use FSM::Support::SerializablePlanReportContract qw(build_serializable_plan_report_contract);

subtest 'parent composition child contract survives JSON round trip' => sub {
    my $decoded = decode_json(encode_json(build_serializable_plan_report_contract()));
    my $child = $decoded->{composition_plan_snapshot_contract};

    is_deeply(
        $child,
        build_serializable_composition_plan_snapshot_contract(),
        'decoded parent keeps exact canonical composition child contract',
    );
    is($child->{schema_version}, 1, 'decoded composition child keeps schema version');
    is($child->{status}, 'bounded_public', 'decoded composition child keeps bounded_public status');
    is(
        $child->{contract_source},
        serializable_composition_plan_snapshot_contract_source(),
        'decoded composition child keeps canonical owner',
    );
    is($child->{object_name}, 'composition_plan_snapshot', 'decoded composition child keeps object name');
};

done_testing();
