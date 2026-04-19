package FSM::Support::NormalizedSemanticSignalAnalysisContract;

use strict;
use warnings;

use Exporter 'import';

our @EXPORT_OK = qw(
    normalized_semantic_signal_analysis_presence_keys
);

sub normalized_semantic_signal_analysis_presence_keys {
    return [
        qw(
            inputs
            multi_bit
            outputs
            single_bit
        ),
    ];
}

1;
