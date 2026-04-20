package FSM::Support::HDLGeneratorRawASTContract;

use strict;
use warnings;

use Exporter 'import';
use JSON::PP ();

our @EXPORT_OK = qw(
    build_hdl_generator_raw_ast_contract
    hdl_generator_raw_ast_value_shape
    hdl_generator_raw_ast_summary_surfaces
);

sub build_hdl_generator_raw_ast_contract {
    return {
        schema_version => 1,
        status => 'bounded_public',
        contract_source => 'FSM::Support::HDLGeneratorRawASTContract',
        object_name => 'raw_ast',
        parent_object_name => 'HDLGeneratorResult.raw_ast',
        report_sources => [
            qw(
                FSM::Pipeline::HDLGenerator
            ),
        ],
        entrypoints => {
            in_process => [
                'FSM::Pipeline::HDLGenerator->new(...)->generate_hdl_from_file($path)->{raw_ast}',
            ],
        },
        shell_only => JSON::PP::true,
        raw_value_shape => hdl_generator_raw_ast_value_shape(),
        summary_surfaces => hdl_generator_raw_ast_summary_surfaces(),
        full_hash_stable => JSON::PP::false,
        json_safe_as_whole => JSON::PP::false,
        guidance => [
            q{Treat this contract as the bounded shell-only `raw_ast` branch reused by in-process `HDLGenerator` results.},
            'The branch remains a parser/debug ARRAY artifact kept for in-process compatibility rather than a JSON-safe public interchange payload.',
            'Use intent_hir or normalized semantic JSON for structured downstream inspection instead of binding to parser-level AST arrays as public API.',
        ],
    };
}

sub hdl_generator_raw_ast_value_shape {
    return 'ARRAY';
}

sub hdl_generator_raw_ast_summary_surfaces {
    return [
        'intent_hir',
    ];
}

1;
