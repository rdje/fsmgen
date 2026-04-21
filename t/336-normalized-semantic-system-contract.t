#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use File::Spec;
use FindBin;

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::Support::NormalizedSemanticSystemContract qw(
    normalized_semantic_system_contract_source
    normalized_semantic_system_contract_presence_keys
);

is(
    normalized_semantic_system_contract_source(),
    'FSM::Support::NormalizedSemanticSystemContract',
    'normalized semantic system-contract owner stays canonical',
);

is_deeply(
    normalized_semantic_system_contract_presence_keys(),
    [
        qw(
            clock
            declare_ports
            implicit
            reset
            reset_active_level
            reset_keyword
            reset_kind
        )
    ],
    'normalized semantic system-contract keys stay bounded and ordered',
);

done_testing();
