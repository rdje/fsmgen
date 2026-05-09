#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use File::Spec;
use FindBin;
use JSON::PP qw(decode_json encode_json);
use Scalar::Util qw(blessed);

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::Support::SerializablePlanReportContract qw(build_serializable_plan_report_contract);

subtest 'serializable plan/report JSON-safety flags survive JSON round trip' => sub {
    my $decoded = decode_json(encode_json(build_serializable_plan_report_contract()));

    ok(
        is_json_boolean($decoded->{current_serializable_surfaces_json_safe}),
        'decoded current_serializable_surfaces_json_safe is a JSON boolean',
    );
    ok(
        is_json_boolean($decoded->{raw_hdl_generator_branches_json_safe}),
        'decoded raw_hdl_generator_branches_json_safe is a JSON boolean',
    );
    ok(
        $decoded->{current_serializable_surfaces_json_safe},
        'decoded contract keeps current serializable surfaces JSON-safe',
    );
    ok(
        !$decoded->{raw_hdl_generator_branches_json_safe},
        'decoded contract keeps raw HDLGenerator branches non-JSON-safe',
    );
};

done_testing();

sub is_json_boolean {
    my ($value) = @_;
    return defined(blessed($value)) && blessed($value) eq 'JSON::PP::Boolean';
}
