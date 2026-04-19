#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use File::Spec;
use FindBin;

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::Support::NormalizedSemanticExplicitSystemContract qw(
    normalized_semantic_explicit_system_contract_presence_keys
);

is_deeply(
    normalized_semantic_explicit_system_contract_presence_keys(),
    [
        qw(
            clock
            reset
            reset_active_level
            reset_keyword
            reset_kind
        )
    ],
    'normalized semantic explicit-system-contract keys stay bounded and ordered',
);

done_testing();
