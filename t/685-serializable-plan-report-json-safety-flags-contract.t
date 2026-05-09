#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use File::Spec;
use FindBin;
use Scalar::Util qw(blessed);

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::Support::SerializablePlanReportContract qw(build_serializable_plan_report_contract);

subtest 'serializable plan/report JSON-safety flags are explicit JSON booleans' => sub {
    my $contract = build_serializable_plan_report_contract();

    ok(
        is_json_boolean($contract->{current_serializable_surfaces_json_safe}),
        'current_serializable_surfaces_json_safe is a JSON boolean',
    );
    ok(
        is_json_boolean($contract->{raw_hdl_generator_branches_json_safe}),
        'raw_hdl_generator_branches_json_safe is a JSON boolean',
    );
    ok(
        $contract->{current_serializable_surfaces_json_safe},
        'current serializable surfaces are marked JSON-safe',
    );
    ok(
        !$contract->{raw_hdl_generator_branches_json_safe},
        'raw HDLGenerator branches are marked non-JSON-safe',
    );
};

done_testing();

sub is_json_boolean {
    my ($value) = @_;
    return defined(blessed($value)) && blessed($value) eq 'JSON::PP::Boolean';
}
