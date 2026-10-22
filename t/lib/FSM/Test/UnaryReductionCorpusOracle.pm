package FSM::Test::UnaryReductionCorpusOracle;

use strict;
use warnings;
use Exporter 'import';
our @EXPORT_OK = qw(unary_reduction_ports unary_reduction_records unary_reduction_catalog);

# Independently authored expectations for isf/unary_reductions.isf. Do not
# derive these from parser, scheduler, manifest or another transport's output.
sub unary_reduction_ports {
    return [
        {name => 'valid', direction => 'input', width => 1},
        {name => 'data', direction => 'input', width => 8},
        map {{name => $_, direction => 'output', width => 1}}
            qw(parity all_set any_set odd_parity slice_parity selected_bit),
    ];
}
sub unary_reduction_records {
    return [map {
        {owner_kind => 'rule', owner => $_->[0], context => "rule '$_->[0]' action[0] RHS",
            kind => 'unary', operator => $_->[1], operand => $_->[2],
            operand_width => $_->[3], result_width => 1}
    } (
        ['xor_check', '^', 'data', 8], ['all_check', '&', 'data', 8],
        ['any_check', '|', 'data', 8], ['odd_check', '^', 'data', 8],
        ['slice_check', '^', 'data[7:4]', 4], ['bit_check', '&', 'data[3]', 1],
    )];
}
sub unary_reduction_catalog {
    return {
        id => 'feature.isf_unary_reductions', relpath => 'isf/unary_reductions.isf',
        family => 'language_feature_fixture', classification => 'supported_smoke',
        coverage => 'isf_pipeline_cli', source_kind => 'isf', strict_supported => 1,
        expected_module_name => 'unary_reductions', expected_semantic_source_root_kind => 'fsm',
        supported_phases => [qw(parse typecheck lowering check semantic_report schedule_report
            systemverilog_generation verilog_generation)],
        explicit_nonclaims => [qw(vhdl_range_generation hdl_compilation hdl_simulation
            xz_execution external_parameter_overrides grouped_reductions full_consumer_delivery)],
    };
}
1;
