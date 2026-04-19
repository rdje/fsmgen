#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use File::Spec;
use FindBin;

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::Support::NormalizedSemanticSignalAnalysisContract qw(
    build_normalized_semantic_signal_analysis_contract
    normalized_semantic_signal_analysis_entry_presence_keys
    normalized_semantic_signal_analysis_presence_keys
);

subtest 'contract exposes the bounded normalized semantic signal-analysis object' => sub {
    my $contract = build_normalized_semantic_signal_analysis_contract();

    is($contract->{schema_version}, 1, 'contract exposes schema version');
    is($contract->{status}, 'bounded_public', 'contract marks the nested signal-analysis object as bounded public');
    is(
        $contract->{contract_source},
        'FSM::Support::NormalizedSemanticSignalAnalysisContract',
        'contract records its own owner',
    );
    is($contract->{object_name}, 'signal_analysis', 'contract records the nested object name');
    is($contract->{parent_object_name}, 'semantic.signal_analysis', 'contract records the nested parent path');
    ok(
        $contract->{bucket_entries_share_one_core_shape},
        'contract says the published signal-analysis buckets share one core entry shape',
    );
    ok(
        $contract->{json_safe_when_embedded_in_public_reports},
        'contract says the nested signal-analysis object is JSON-safe when embedded in public reports',
    );
    is_deeply(
        $contract->{public_presence_keys},
        normalized_semantic_signal_analysis_presence_keys(),
        'contract publishes the bounded signal-analysis bucket keys',
    );
    is_deeply(
        $contract->{entry_presence_keys},
        normalized_semantic_signal_analysis_entry_presence_keys(),
        'contract publishes the bounded signal-analysis entry keys',
    );
};

done_testing();
