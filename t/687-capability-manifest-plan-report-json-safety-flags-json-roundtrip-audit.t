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

subtest 'manifest plan/report JSON-safety flags survive JSON round trip' => sub {
    my $decoded = decode_json(encode_json(build_capability_manifest()));
    my $contract = $decoded->{embedding}{serializable_plan_reports};

    ok(
        is_json_boolean($contract->{current_serializable_surfaces_json_safe}),
        'decoded current_serializable_surfaces_json_safe is a JSON boolean',
    );
    ok(
        is_json_boolean($contract->{raw_hdl_generator_branches_json_safe}),
        'decoded raw_hdl_generator_branches_json_safe is a JSON boolean',
    );
    ok(
        $contract->{current_serializable_surfaces_json_safe},
        'decoded manifest keeps current serializable surfaces JSON-safe',
    );
    ok(
        !$contract->{raw_hdl_generator_branches_json_safe},
        'decoded manifest keeps raw HDLGenerator branches non-JSON-safe',
    );
};

done_testing();

sub is_json_boolean {
    my ($value) = @_;
    return defined(blessed($value)) && blessed($value) eq 'JSON::PP::Boolean';
}
