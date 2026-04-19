package FSM::Support::NormalizedSemanticExplicitSystemContract;

use strict;
use warnings;

use Exporter 'import';

our @EXPORT_OK = qw(
    normalized_semantic_explicit_system_contract_presence_keys
);

sub normalized_semantic_explicit_system_contract_presence_keys {
    return [
        qw(
            clock
            reset
            reset_active_level
            reset_keyword
            reset_kind
        ),
    ];
}

1;
