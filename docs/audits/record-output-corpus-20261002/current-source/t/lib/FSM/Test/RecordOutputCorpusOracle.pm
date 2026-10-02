package FSM::Test::RecordOutputCorpusOracle;

use strict;
use warnings;
use Exporter 'import';
use JSON::PP ();
our @EXPORT_OK = qw(record_output_ports record_output_type record_output_catalog);

# Authored fixture expectations, independent of the parser/layout/report code.
sub record_output_type {
    return {kind => 'record', width => 10, signed => 0, member_order => [qw(kind payload)], members => {
        kind => {kind => 'bits', width => 2, signed => 0},
        payload => {kind => 'record', width => 8, signed => 0, member_order => [qw(data flags)], members => {
            data => {kind => 'bits', width => 5, signed => 1, state_model => 'four_state'},
            flags => {kind => 'list', width => 3, signed => 0, items => [
                {kind => 'bit', width => 1, signed => 0},
                {kind => 'bits', width => 2, signed => 0, state_model => 'two_state'}]},
        }},
    }};
}
sub record_output_ports {
    my $record = sub {return {name => $_[0], direction => $_[1], width => 10,
        type => 'frame', type_kind => 'record', fields => [
            {path => 'kind', width => 2, msb => 9, lsb => 8, signed => 0},
            {path => 'payload.data', width => 5, msb => 7, lsb => 3, signed => 1, state_model => 'four_state'},
            {path => 'payload.flags[0]', width => 1, msb => 2, lsb => 2, signed => 0},
            {path => 'payload.flags[1]', width => 2, msb => 1, lsb => 0, signed => 0, state_model => 'two_state'},
        ]}};
    return [{name => 'start', direction => 'input', width => 1}, $record->('incoming', 'input'),
        $record->('packet', 'output'), {name => 'seen', direction => 'output', width => 5},
        {name => 'done', direction => 'output', width => 1}];
}
sub record_output_catalog {
    return {id => 'feature.isf_record_output', relpath => 'isf/record_output.isf',
        family => 'language_feature_fixture', classification => 'supported_smoke',
        coverage => 'isf_pipeline_cli', source_kind => 'isf', strict_supported => 1,
        expected_module_name => 'record_output', expected_semantic_source_root_kind => 'fsm',
        supported_phases => [qw(parse typecheck lowering check semantic_report schedule_report systemverilog_generation)],
        explicit_nonclaims => [qw(output_simulation generated_output_mapping output_member_writes
            verilog vhdl xz_execution reset_free_initialization full_consumer_delivery)]};
}
1;
