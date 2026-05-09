#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use File::Spec;
use FindBin;
use JSON::PP qw(decode_json encode_json);

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::Support::CompositionReportContract qw(
    composition_report_json_fragment_path
    composition_report_public_top_level_keys
);
use FSM::Support::NormalizedSemanticReportContract qw(normalized_semantic_public_top_level_keys);
use FSM::Support::SerializablePlanReportContract qw(build_serializable_plan_report_contract);

subtest 'serializable plan/report public report key metadata survives JSON round trip' => sub {
    my $decoded = decode_json(encode_json(build_serializable_plan_report_contract()));

    is_deeply(
        $decoded->{normalized_semantic_report_public_top_level_keys},
        normalized_semantic_public_top_level_keys(),
        'decoded contract keeps normalized semantic report top-level keys',
    );
    is_deeply(
        $decoded->{composition_report_public_top_level_keys},
        composition_report_public_top_level_keys(),
        'decoded contract keeps composition report top-level keys',
    );
    is(
        $decoded->{composition_report_json_fragment_path},
        composition_report_json_fragment_path(),
        'decoded contract keeps composition report JSON fragment path',
    );
};

done_testing();
