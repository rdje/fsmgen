package FSM::Support::HDLGeneratorStatisticsContract;

use strict;
use warnings;

use Exporter 'import';
use JSON::PP ();

our @EXPORT_OK = qw(
    build_hdl_generator_statistics_contract
    hdl_generator_statistics_optional_composition_keys
    hdl_generator_statistics_stable_subsurfaces
    hdl_generator_statistics_summary_keys
);

sub build_hdl_generator_statistics_contract {
    return {
        schema_version => 1,
        status => 'bounded_public',
        contract_source => 'FSM::Support::HDLGeneratorStatisticsContract',
        object_name => 'statistics',
        parent_object_name => 'HDLGeneratorResult.statistics',
        report_sources => [
            qw(
                FSM::Pipeline::HDLGenerator
            ),
        ],
        entrypoints => {
            in_process => [
                'FSM::Pipeline::HDLGenerator->new(...)->generate_hdl_from_file($path)->{statistics}',
            ],
        },
        summary_presence_keys => hdl_generator_statistics_summary_keys(),
        optional_composition_summary_keys => hdl_generator_statistics_optional_composition_keys(),
        stable_subsurfaces => hdl_generator_statistics_stable_subsurfaces(),
        full_hash_stable => JSON::PP::false,
        json_safe_as_whole => JSON::PP::false,
        guidance => [
            q{Treat this contract as the bounded nested `statistics` object reused by in-process `HDLGenerator` results.},
            'The bounded public promise covers the current scalar summary keys plus the current composition-only scalar summary keys.',
            'The wider statistics hash remains compatibility-heavy, so callers should target the advertised stable subsurfaces instead of treating the whole hash as public API.',
        ],
    };
}

sub hdl_generator_statistics_summary_keys {
    return [qw(
        factoring_enabled
        global_expressions
        intermediate_signals
    )];
}

sub hdl_generator_statistics_optional_composition_keys {
    return [qw(
        composition_block_count
        composition_child_count
        composition_lane
        composition_net_count
        composition_override_count
        composition_resolved_link_count
        composition_shared_datapath_candidate_count
        composition_top_port_count
    )];
}

sub hdl_generator_statistics_stable_subsurfaces {
    return [
        qw(
            statistics.factoring_enabled
            statistics.global_expressions
            statistics.intermediate_signals
            statistics.composition_block_count
            statistics.composition_child_count
            statistics.composition_lane
            statistics.composition_net_count
            statistics.composition_override_count
            statistics.composition_resolved_link_count
            statistics.composition_shared_datapath_candidate_count
            statistics.composition_top_port_count
        ),
    ];
}

1;
