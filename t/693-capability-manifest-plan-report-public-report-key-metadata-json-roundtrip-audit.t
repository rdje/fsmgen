#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use File::Spec;
use FindBin;
use JSON::PP qw(decode_json encode_json);

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::Support::CapabilityManifest qw(build_capability_manifest);
use FSM::Support::CompositionReportContract qw(
    composition_report_json_fragment_path
    composition_report_public_top_level_keys
);
use FSM::Support::NormalizedSemanticReportContract qw(normalized_semantic_public_top_level_keys);

subtest 'manifest public report key metadata survives JSON round trip' => sub {
    my $decoded = decode_json(encode_json(build_capability_manifest()));
    my $contract = $decoded->{embedding}{serializable_plan_reports};

    is_deeply(
        $contract->{normalized_semantic_report_public_top_level_keys},
        normalized_semantic_public_top_level_keys(),
        'decoded manifest keeps normalized semantic report top-level keys',
    );
    is_deeply(
        $contract->{composition_report_public_top_level_keys},
        composition_report_public_top_level_keys(),
        'decoded manifest keeps composition report top-level keys',
    );
    is(
        $contract->{composition_report_json_fragment_path},
        composition_report_json_fragment_path(),
        'decoded manifest keeps composition report JSON fragment path',
    );
};

done_testing();
