#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use File::Spec;
use FindBin;

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::Support::NormalizedSemanticSystemContract qw(
    build_normalized_semantic_system_contract
    normalized_semantic_system_contract_behavior_keys
    normalized_semantic_system_contract_clock_keys
    normalized_semantic_system_contract_presence_key_family_map
    normalized_semantic_system_contract_reset_identity_keys
    normalized_semantic_system_contract_reset_metadata_keys
    normalized_semantic_system_contract_source
    normalized_semantic_system_contract_presence_keys
);

subtest 'contract exposes the bounded semantic.system_contract surface' => sub {
    my $contract = build_normalized_semantic_system_contract();

    is($contract->{schema_version}, 1, 'contract exposes schema version');
    is($contract->{status}, 'bounded_public', 'contract marks semantic.system_contract as bounded public');
    is(
        $contract->{contract_source},
        normalized_semantic_system_contract_source(),
        'contract records its own owner',
    );
    is($contract->{object_name}, 'system_contract', 'contract records the nested object name');
    is($contract->{parent_object_name}, 'semantic.system_contract', 'contract records the nested parent path');
    is_deeply(
        $contract->{public_presence_keys},
        normalized_semantic_system_contract_presence_keys(),
        'contract publishes the bounded system-contract keys',
    );
    is_deeply(
        $contract->{clock_keys},
        normalized_semantic_system_contract_clock_keys(),
        'contract publishes the bounded system-contract clock key family',
    );
    is_deeply(
        $contract->{reset_identity_keys},
        normalized_semantic_system_contract_reset_identity_keys(),
        'contract publishes the bounded system-contract reset identity key family',
    );
    is_deeply(
        $contract->{reset_metadata_keys},
        normalized_semantic_system_contract_reset_metadata_keys(),
        'contract publishes the bounded system-contract reset metadata key family',
    );
    is_deeply(
        $contract->{behavior_keys},
        normalized_semantic_system_contract_behavior_keys(),
        'contract publishes the bounded system-contract behavior key family',
    );
    is_deeply(
        $contract->{presence_key_family_map},
        normalized_semantic_system_contract_presence_key_family_map(),
        'contract publishes the grouped system-contract key-family map',
    );
    ok($contract->{json_safe_when_embedded_in_public_reports}, 'contract says the nested object stays JSON-safe in public reports');
};

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

is_deeply(
    normalized_semantic_system_contract_clock_keys(),
    [qw(clock)],
    'normalized semantic system-contract clock key family stays bounded',
);

is_deeply(
    normalized_semantic_system_contract_reset_identity_keys(),
    [qw(reset)],
    'normalized semantic system-contract reset identity key family stays bounded',
);

is_deeply(
    normalized_semantic_system_contract_reset_metadata_keys(),
    [qw(reset_active_level reset_keyword reset_kind)],
    'normalized semantic system-contract reset metadata key family stays bounded',
);

is_deeply(
    normalized_semantic_system_contract_behavior_keys(),
    [qw(declare_ports implicit)],
    'normalized semantic system-contract behavior key family stays bounded',
);

is_deeply(
    normalized_semantic_system_contract_presence_key_family_map(),
    {
        clock_keys => [qw(clock)],
        reset_identity_keys => [qw(reset)],
        reset_metadata_keys => [qw(reset_active_level reset_keyword reset_kind)],
        behavior_keys => [qw(declare_ports implicit)],
    },
    'normalized semantic system-contract grouped key-family map stays bounded',
);

done_testing();
