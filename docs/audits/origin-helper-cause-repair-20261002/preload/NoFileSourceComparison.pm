package NoFileSourceComparison;
use strict;
use warnings;
use parent 'FSM::Test::FileDocumentOriginAuthority';

# Genuine actual source-comparison counterfactual. Canonical construction and
# complete actor/proof getters still run; only the reload consumer is bypassed.
sub validate {return 1}
1;
