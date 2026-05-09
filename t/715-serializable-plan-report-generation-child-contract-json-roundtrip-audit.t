#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use File::Spec;
use FindBin;
use JSON::PP qw(decode_json encode_json);

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::Support::SerializableGenerationResultSnapshot qw(
    build_serializable_generation_result_snapshot_contract
    serializable_generation_result_snapshot_contract_source
);
use FSM::Support::SerializablePlanReportContract qw(build_serializable_plan_report_contract);

subtest 'parent generation child contract survives JSON round trip' => sub {
    my $decoded = decode_json(encode_json(build_serializable_plan_report_contract()));
    my $child = $decoded->{generation_result_snapshot_contract};

    is_deeply(
        $child,
        build_serializable_generation_result_snapshot_contract(),
        'decoded parent keeps exact canonical generation child contract',
    );
    is($child->{schema_version}, 1, 'decoded generation child keeps schema version');
    is($child->{status}, 'bounded_public', 'decoded generation child keeps bounded_public status');
    is(
        $child->{contract_source},
        serializable_generation_result_snapshot_contract_source(),
        'decoded generation child keeps canonical owner',
    );
    is($child->{object_name}, 'generation_result_snapshot', 'decoded generation child keeps object name');
};

done_testing();
