#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use File::Spec;
use FindBin;
use Scalar::Util qw(blessed);

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::Support::CapabilityManifest qw(build_capability_manifest);

subtest 'manifest embeds serializable plan/report JSON-safety booleans' => sub {
    my $manifest = build_capability_manifest();
    my $contract = $manifest->{embedding}{serializable_plan_reports};

    ok(
        is_json_boolean($contract->{current_serializable_surfaces_json_safe}),
        'manifest current_serializable_surfaces_json_safe is a JSON boolean',
    );
    ok(
        is_json_boolean($contract->{raw_hdl_generator_branches_json_safe}),
        'manifest raw_hdl_generator_branches_json_safe is a JSON boolean',
    );
    ok(
        $contract->{current_serializable_surfaces_json_safe},
        'manifest marks current serializable surfaces JSON-safe',
    );
    ok(
        !$contract->{raw_hdl_generator_branches_json_safe},
        'manifest marks raw HDLGenerator branches non-JSON-safe',
    );
};

done_testing();

sub is_json_boolean {
    my ($value) = @_;
    return defined(blessed($value)) && blessed($value) eq 'JSON::PP::Boolean';
}
