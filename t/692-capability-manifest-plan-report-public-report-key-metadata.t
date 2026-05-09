#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use File::Spec;
use FindBin;

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::Support::CapabilityManifest qw(build_capability_manifest);
use FSM::Support::CompositionReportContract qw(
    composition_report_json_fragment_path
    composition_report_public_top_level_keys
);
use FSM::Support::NormalizedSemanticReportContract qw(normalized_semantic_public_top_level_keys);

subtest 'manifest embeds serializable plan/report public report key metadata' => sub {
    my $manifest = build_capability_manifest();
    my $contract = $manifest->{embedding}{serializable_plan_reports};

    is_deeply(
        $contract->{normalized_semantic_report_public_top_level_keys},
        normalized_semantic_public_top_level_keys(),
        'manifest embeds normalized semantic report top-level keys',
    );
    is_deeply(
        $contract->{composition_report_public_top_level_keys},
        composition_report_public_top_level_keys(),
        'manifest embeds composition report top-level keys',
    );
    is(
        $contract->{composition_report_json_fragment_path},
        composition_report_json_fragment_path(),
        'manifest embeds composition report JSON fragment path',
    );
};

done_testing();
