package FSM::Support::CompositionParameterContract;

use strict;
use warnings;
use Exporter 'import';
use JSON::PP ();
use FSM::Support::NormalizedSemanticSignalAnalysisContract qw(normalized_semantic_signal_analysis_presence_keys);

our @EXPORT_OK = qw(build_composition_parameter_contract);

sub build_composition_parameter_contract {
    return {
        schema_version => 1,
        status => 'bounded_public',
        discovery_query_family => 'capability_query',
        discovery_manifest_path => [qw(semantic_exports normalized_semantic_json composition_parameter_contract)],
        contract_source => 'FSM::Support::CompositionParameterContract',
        producer_sources => [qw(FSM::Composition::Top FSM::Composition::Plan FSM::Composition::ParameterBindingSupport FSM::Composition::Port FSM::Composition::PortWidthResolver)],
        environment_paths => [
            'semantic.forward_ir.intent_hir.parameter_environment',
            'semantic.forward_ir.structural_rtl_ir.parameter_environment',
            'semantic.composition.plan_snapshot.parameter_environment',
        ],
        binding_paths => [
            'semantic.forward_ir.structural_rtl_ir.instances[].parameter_overrides[].binding_expression',
            'semantic.forward_ir.intent_hir.composition_children[].parameter_overrides[].binding_expression',
            'semantic.forward_ir.intent_hir.composition_generated_children[].parameter_overrides[].binding_expression',
            'semantic.composition.children[].parameter_overrides[].binding_expression',
            'semantic.composition.generated_children[].parameter_overrides[].binding_expression',
        ],
        width_contract_paths => [
            'semantic.forward_ir.structural_rtl_ir.ports[].width_contract',
            'semantic.forward_ir.intent_hir.signal_analysis.*[].width_contract',
            'semantic.signal_analysis.*[].width_contract',
            'semantic.composition.plan_snapshot.top_ports[].width_contract',
        ],
        width_contract_keys => [qw(scope expression references)],
        width_reference_keys => {
            parameter => [qw(kind token)], static_symbol => [qw(kind token value_payload)],
        },
        width_analysis_buckets => normalized_semantic_signal_analysis_presence_keys(),
        environment_keys => [qw(scope declaration_order parameters default_sources default_bindings)],
        scope_keys => [qw(kind owner)],
        scope_kind => 'composition_top',
        parameter_value_keys => [qw(value_kind value_payload value_text)],
        parameter_value_optional_keys => [qw(value_width value_type_spec)],
        parameter_value_kinds => [qw(scalar list map)],
        declaration_default_value_keys => [qw(declaration_default_value_kind declaration_default_value_payload declaration_default_value_text)],
        declaration_default_optional_keys => [qw(declaration_default_value_width declaration_default_value_type_spec declaration_default_source_expression)],
        default_source_keys => [qw(parameter source_module expression references)],
        reference_keys => [qw(parameter token suffix)],
        binding_node_keys => {
            literal => [qw(kind token)],
            parameter => [qw(kind scope parameter token suffix)],
            static_symbol => [qw(kind scope token value_payload)],
            payload => [qw(kind value)],
            operator => [qw(kind operator source_operator operands)],
            list => [qw(kind items)],
            map => [qw(kind member_order members)],
        },
        payload_node_keys => {
            scalar => [qw(kind payload)], scalar_expr => [qw(kind payload)],
            list => [qw(kind items)], map => [qw(kind member_order members)],
        },
        type_node_keys => {
            bit => [qw(kind width signed)], bits => [qw(kind width signed)],
            list => [qw(kind width signed items)],
            record => [qw(kind width signed member_order members)],
        },
        optional_when_inapplicable => JSON::PP::true,
        public_source_planning_supported => JSON::PP::false,
        hdl_emission_supported => JSON::PP::false,
        prepared_scalar_emission => {
            targets => [qw(systemverilog sv verilog v)],
            top_defaults => JSON::PP::true, child_actuals => JSON::PP::true,
            symbolic_port_widths => JSON::PP::true, typed_top_parameters => JSON::PP::false,
            source_admission => JSON::PP::false,
        },
        guidance => [
            'Optional width_contract records preserve the captured top scope, authored frontend expression tree and ordered actual parameter/static lookups beside numeric width caches. Width-analysis path wildcards expand only to width_analysis_buckets.',
            'Width references use width_reference_keys by kind; static value_payload uses payload_node_keys. Explicit (param NAME) selects declared parameters, while bare width operands select static symbols. Equal defaults do not merge lookup identities.',
            'These optional fields describe detached products assembled from resolved composition Plan and forward IR objects by the in-process report builders. They do not enable successful parameter-bearing source queries.',
            'The enclosing report and this discovery contract retain schema version 1; the environment and binding records have no separate version or source envelope.',
            'Scope owner is the actual composition-top name. Declaration order is authored order; parameters, default_sources and default_bindings are maps keyed by those declared names.',
            'Parameter values are resolved validation caches. Scalar payloads carry normalized text; recursive list/map payloads retain items or ordered members. Optional widths and type records describe those caches, not symbolic interface specialization.',
            'Default source expression retains the authored frontend JSON scalar/array/hash tree. Ordered references contain only actual declared parameter selections; static lookups do not acquire parameter identity from equal values.',
            'Default bindings and optional instance binding_expression use binding_node_keys by kind. Operands, items and members recurse through the same node family; payload values and static_symbol value_payload use payload_node_keys.',
            'Parameter token is the declared root plus suffix; aliases retain immediate declaration identity. Static symbols retain scope, source token and selected payload. Operator is canonical, while source_operator retains the authored alias.',
            'Type items and members recurse through type_node_keys; signed is the canonical numeric flag. Missing optional fields are omitted, never inferred from a cached number.',
            'Validated child overrides retain declaration_default_value_keys and applicable declaration_default_optional_keys. These describe the child default independently of the actual value cache: payload/type use payload_node_keys/type_node_keys; source_expression is an authored frontend tree, omitted when no source record exists. Kind and width alone cannot distinguish decimal integer from sized bit/vector generic declarations.',
            'Unparameterized environments and static overrides keep their existing report shapes. prepared_scalar_emission names only direct Verilog-family structural emission with a captured matching environment: untyped scalar defaults, scalar child actuals and captured scalar port ranges. Typed tops, symbolic aggregate bindings, VHDL parameter emission and source admission remain unqualified. Existing static aggregate profiles are unchanged.',
        ],
    };
}

1;

=head1 NAME

FSM::Support::CompositionParameterContract - Optional composition parameter report schemas

=head1 DESCRIPTION

C<build_composition_parameter_contract()> returns a fresh JSON-safe discovery
record for actual composition environments, scoped instance bindings and
captured port width dependencies. Width contracts describe optional structural
ports, IntentHIR/common signal analysis and serialized top-port records. It
names exact optional report paths, source owners, recursive key families,
version semantics and the pending source/complete-HDL boundary. The separate
C<prepared_scalar_emission> record names the direct Verilog-family emitter's
untyped scalar top-default/child-actual and captured scalar port-range subset,
excluding typed tops and source admission. It describes producer
contracts; it neither resolves input nor attests the provenance of caller-made
hashes. Follow the actual Top/Plan/IR producers for semantic provenance.

C<declaration_default_value_keys> and C<declaration_default_optional_keys>
describe matched child declaration evidence in override records. Default
payload/type use the existing recursive schemas; the optional source expression
is an authored frontend tree. These fields do not qualify symbolic VHDL maps.

=cut
