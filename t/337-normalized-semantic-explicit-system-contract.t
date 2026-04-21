#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use File::Spec;
use FindBin;

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::Support::NormalizedSemanticExplicitSystemContract qw(
    normalized_semantic_explicit_system_contract_clock_keys
    normalized_semantic_explicit_system_contract_presence_key_family_map
    normalized_semantic_explicit_system_contract_reset_identity_keys
    normalized_semantic_explicit_system_contract_reset_metadata_keys
    normalized_semantic_explicit_system_contract_source
    normalized_semantic_explicit_system_contract_presence_keys
);

is(
    normalized_semantic_explicit_system_contract_source(),
    'FSM::Support::NormalizedSemanticExplicitSystemContract',
    'normalized semantic explicit-system-contract owner stays canonical',
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

is_deeply(
    normalized_semantic_explicit_system_contract_clock_keys(),
    [qw(clock)],
    'normalized semantic explicit-system-contract clock key family stays bounded',
);

is_deeply(
    normalized_semantic_explicit_system_contract_reset_identity_keys(),
    [qw(reset)],
    'normalized semantic explicit-system-contract reset identity key family stays bounded',
);

is_deeply(
    normalized_semantic_explicit_system_contract_reset_metadata_keys(),
    [qw(reset_active_level reset_keyword reset_kind)],
    'normalized semantic explicit-system-contract reset metadata key family stays bounded',
);

is_deeply(
    normalized_semantic_explicit_system_contract_presence_key_family_map(),
    {
        clock_keys => [qw(clock)],
        reset_identity_keys => [qw(reset)],
        reset_metadata_keys => [qw(reset_active_level reset_keyword reset_kind)],
    },
    'normalized semantic explicit-system-contract grouped key-family map stays bounded',
);

done_testing();
