#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use File::Spec;
use FindBin;

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::Support::NormalizedSemanticSignalAnalysisContract qw(
    normalized_semantic_signal_analysis_presence_keys
);

is_deeply(
    normalized_semantic_signal_analysis_presence_keys(),
    [
        qw(
            inputs
            multi_bit
            outputs
            single_bit
        )
    ],
    'normalized semantic signal-analysis keys stay bounded and ordered',
);

done_testing();
