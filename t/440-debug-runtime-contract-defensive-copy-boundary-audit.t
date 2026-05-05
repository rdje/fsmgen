#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use File::Spec;
use FindBin;

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::Support::DebugRuntimeContract qw(
    build_debug_runtime_contract
    debug_runtime_emoji_control_names
    debug_runtime_family_map
    debug_runtime_named_trace_verbosity_values
    debug_runtime_numeric_trace_level_range
    debug_runtime_public_top_level_keys
    debug_runtime_snapshot_helper_names
    debug_runtime_snapshot_state_keys
    debug_runtime_state_control_names
    debug_runtime_trace_output_control_names
);

my $sentinel = '__mutated_by_t440__';

subtest 'debug runtime contract builder returns fresh nested structures' => sub {
    my $first = build_debug_runtime_contract();
    mutate_structure($first);

    my $second = build_debug_runtime_contract();
    ok(!contains_sentinel($second), 'fresh debug runtime contract is not affected by prior caller mutation');
    is_deeply(
        sorted($second->{public_top_level_presence_keys}),
        sorted([keys %{$second}]),
        'fresh contract top-level presence list still covers every emitted debug-runtime contract key',
    );
    is_deeply(
        $second->{family_map},
        debug_runtime_family_map(),
        'fresh contract grouped family map matches its helper',
    );
    is_deeply(
        $second->{named_trace_verbosity_values},
        debug_runtime_named_trace_verbosity_values(),
        'fresh contract named trace verbosity values match their helper',
    );
    is_deeply(
        $second->{numeric_trace_level_range},
        debug_runtime_numeric_trace_level_range(),
        'fresh contract numeric trace range matches its helper',
    );
};

subtest 'debug runtime helper builders return fresh nested structures' => sub {
    for my $case (
        {
            label => 'public_top_level_keys',
            build => \&debug_runtime_public_top_level_keys,
        },
        {
            label => 'snapshot_helper_names',
            build => \&debug_runtime_snapshot_helper_names,
        },
        {
            label => 'state_control_names',
            build => \&debug_runtime_state_control_names,
        },
        {
            label => 'trace_output_control_names',
            build => \&debug_runtime_trace_output_control_names,
        },
        {
            label => 'emoji_control_names',
            build => \&debug_runtime_emoji_control_names,
        },
        {
            label => 'snapshot_state_keys',
            build => \&debug_runtime_snapshot_state_keys,
        },
        {
            label => 'family_map',
            build => \&debug_runtime_family_map,
        },
        {
            label => 'named_trace_verbosity_values',
            build => \&debug_runtime_named_trace_verbosity_values,
        },
        {
            label => 'numeric_trace_level_range',
            build => \&debug_runtime_numeric_trace_level_range,
        },
    ) {
        my $first = $case->{build}->();
        mutate_structure($first);

        my $second = $case->{build}->();
        ok(!contains_sentinel($second), "$case->{label} returns fresh nested structures");
    }
};

subtest 'fresh grouped debug runtime map stays aligned with helper families' => sub {
    my $family_map = debug_runtime_family_map();

    is_deeply(
        $family_map->{snapshot_helper_names},
        debug_runtime_snapshot_helper_names(),
        'snapshot helper map entry matches helper',
    );
    is_deeply(
        $family_map->{state_control_names},
        debug_runtime_state_control_names(),
        'state control map entry matches helper',
    );
    is_deeply(
        $family_map->{trace_output_control_names},
        debug_runtime_trace_output_control_names(),
        'trace output map entry matches helper',
    );
    is_deeply(
        $family_map->{emoji_control_names},
        debug_runtime_emoji_control_names(),
        'emoji control map entry matches helper',
    );
    is_deeply(
        $family_map->{snapshot_state_keys},
        debug_runtime_snapshot_state_keys(),
        'snapshot state map entry matches helper',
    );
};

done_testing();

sub mutate_structure {
    my ($value) = @_;
    return unless ref($value);

    if (ref($value) eq 'ARRAY') {
        push @{$value}, $sentinel;
        mutate_structure($_) for @{$value};
        return;
    }

    if (ref($value) eq 'HASH') {
        $value->{$sentinel} = $sentinel;
        mutate_structure($_) for values %{$value};
        return;
    }
}

sub contains_sentinel {
    my ($value) = @_;
    return 1 if defined($value) && !ref($value) && $value eq $sentinel;
    return 0 unless ref($value);

    if (ref($value) eq 'ARRAY') {
        for my $entry (@{$value}) {
            return 1 if contains_sentinel($entry);
        }
        return 0;
    }

    if (ref($value) eq 'HASH') {
        return 1 if exists($value->{$sentinel});
        for my $entry (values %{$value}) {
            return 1 if contains_sentinel($entry);
        }
        return 0;
    }

    return 0;
}

sub sorted {
    my ($values) = @_;
    return [sort @{$values || []}];
}
