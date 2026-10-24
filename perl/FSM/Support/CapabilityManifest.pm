package FSM::Support::CapabilityManifest;

use strict;
use warnings;

use Exporter 'import';
use FSM::Support::BackendValidationSection qw(build_backend_validation_section);
use FSM::Support::CapabilityManifestContract qw(build_capability_manifest_contract);
use FSM::Support::DiagnosticsSection qw(build_diagnostics_section);
use FSM::Support::DocumentationSection qw(build_documentation_section);
use FSM::Support::EmbeddingSection qw(build_embedding_section);
use FSM::Support::LanguageSurfaceSection qw(build_language_surface_section);
use FSM::Support::ProducerSection qw(build_producer_section);
use FSM::Support::SemanticExportsSection qw(build_semantic_exports_section);
use FSM::Support::SemanticIntrospectionSection qw(build_semantic_introspection_section);
use FSM::Support::SupportAccountingSection qw(build_support_accounting_section);
use FSM::Support::VerificationOutputsSection qw(build_verification_outputs_section);

our @EXPORT_OK = qw(build_capability_manifest);

sub build_capability_manifest {
    return {
        manifest_schema_version => 1,
        producer => build_producer_section(),
        support_accounting => build_support_accounting_section(),
        diagnostics => build_diagnostics_section(),
        semantic_exports => build_semantic_exports_section(),
        semantic_introspection => build_semantic_introspection_section(),
        backend_validation => build_backend_validation_section(),
        embedding => build_embedding_section(),
        language_surface => build_language_surface_section(),
        verification_outputs => build_verification_outputs_section(),
        documentation => build_documentation_section(),
        manifest_contract => build_capability_manifest_contract(),
    };
}

1;

__END__

=encoding utf8

=head1 NAME

FSM::Support::CapabilityManifest - Discover FSMGen's published capabilities

=head1 SYNOPSIS

    use FSM::Support::CapabilityManifest qw(build_capability_manifest);
    use JSON::PP;
    my $manifest = build_capability_manifest();
    print JSON::PP->new->canonical->pretty->encode($manifest);

Run examples from the repository root with C<perl -Iperl>.

=head1 FUNCTIONS

=head2 build_capability_manifest()

Explicitly import this function with C<qw(build_capability_manifest)>; nothing
is exported by default. Call without arguments. Returns a plain hash containing
C<manifest_schema_version>, C<producer>, C<support_accounting>, C<diagnostics>,
C<semantic_exports>, C<semantic_introspection>, C<backend_validation>,
C<embedding>, C<language_surface>, C<verification_outputs>, C<documentation>
and C<manifest_contract>.

The manifest is JSON-serializable. Its section contracts describe field
presence, supported versions, entry points and fail-closed boundaries. Discover
supported constructor/method seams through C<embedding>; discover MCP query
shapes through C<semantic_introspection>. Capability advertisement is not proof
that an arbitrary source, backend or simulation profile is supported.

=head1 MANIFEST FIELD GUIDE

The book's C<Manifest shell and producer fields> reference supplies the complete
selected root and producer field/family interpretation. Read the manifest's
C<manifest_contract>, then its C<top_level_contract_source_map> and
C<top_level_section_presence_key_map>. Map keys are section names; owner values
are namespace strings and presence values are arrays of field-name strings.
C<manifest_schema_version> and C<manifest_contract> are outside the section-map
domain. The semantic-introspection family derives from its dedicated public
contract, including C<source_query_kinds>; grouped and legacy presence lists agree. C<language_surface> retains C<surface_contract>; other sections advertise
C<section_contract>. Section payload meaning remains with each dedicated owner.

C<schema_version>, C<status>, C<contract_source> and C<report_source> publish the
dedicated contract's version, bounded scope, owner and manifest producer.
C<public_top_level_presence_keys> lists required fields of the described object,
not the metadata record itself. C<presence_key_family_map> groups named field
arrays equal to their same-named compatibility fields; the shell's legacy
C<*_presence_keys> families also match the grouped section lists. Field presence
is not recursive object closure; widening remains deliberate and owner-backed.
No positional priority or semantic ordering is specified for these lists, the
entrypoint examples or guidance. JSON objects are accessed by field name.

In the shell and producer contracts, C<entrypoints.cli> is a string;
C<cli_aliases> and C<in_process> are arrays of command/API example strings. These
are discovery routes, not MCP tools or permission to execute an advertised API.
Other contracts may have different entrypoint labels/shapes. C<guidance> is an
array of explanatory strings. C<full_manifest_json_safe> and
C<nested_section_contracts_advertised> are Boolean promises about serialization
and dedicated-contract discovery, not raw compiler objects or arbitrary support.

C<producer.name> is tool identity. C<version> is a tool/build string, currently
C<0.1-dev>. C<git_commit> is a best-effort short hash or C<unknown>. C<source>
identifies the manifest builder. This is not a release-management or complete
replay identity contract; schema, protocol and VIAL language versions are separate.
C<section_contract.scalar_string_keys> names C<name>, C<version>, C<git_commit>
and C<source>; C<boolean_keys> names C<contract_authority>. Its grouped map repeats
those families. C<identity_contract> explicitly carries the Boolean promises
C<name_is_tool_identity>, C<git_commit_is_best_effort_short_hash_or_unknown> and
C<source_is_manifest_builder_module>. C<contract_authority> currently emits true,
but stronger meaning is undefined by the producer contract and remains an owned
documentation gap. Do not infer additional trust, release or compatibility promises.

=head2 Section-shell records

The book's C<Section-shell contract records> guide covers the common fields and
owner-specific maps in the backend-validation, diagnostics, documentation,
embedding, language and semantic-export shells. C<nested_presence_key_map> can
describe a result, a report fragment, registry siblings or a contract record;
follow its dedicated owner before choosing the object to validate. In particular,
the backend C<systemverilog_external> family names success-result fields, and the
diagnostic registry family names sibling fields in the diagnostics section.
The generator-result map is a sorted known-key union across common, direct-root
and composition-root families; not every key is required on every result. The
generation-result snapshot family describes snapshot output, not its contract.
Documentation instead publishes C<path_list_contract_map> with repository-relative
tracked Markdown rules and unfrozen exact path lists. The language shell's
C<file_surface_entry_presence_keys> describes each C<file_surfaces.entries> item.
Advertising flags do not enable execution, and false whole-section stability
flags do not remove the named bounded presence promises. Deeper payload semantics
remain with their dedicated contracts; these shells are not a universal schema.

=head2 Enriched identity and routes

The book's C<Enriched contract identity and routes> guide distinguishes report
advertisements from manifest discovery. C<contract_source> names the dedicated
owner; C<report_source> names the backing report/data authority. In particular,
support accounting names C<FSM::Support::RegressionCorpus>, not the manifest
builder. Check, normalized-semantic, diagnostic-registry and external-validation
records retain their respective report owners. Numeric C<schema_version> is the
contract/section version, separate from build, protocol, language and report
version fields.

These selected records use C<bounded_public>, except external validation's
C<optional_when_tools_installed>, which requires Verilator and Yosys. Discovery
does not test their installation or run validation. Report entrypoints describe
check/semantic reports or validation; section entrypoints describe manifest/data
discovery. Verification-output discovery does not generate artifacts.

C<entrypoints.cli> is a string; C<in_process> and, where present,
C<cli_aliases> are arrays of example strings. Verification-output records omit
C<cli_aliases>. Both semantic-introspection projections publish an array
C<entrypoints.mcp_adapter> equal to C<mcp_adapter_entrypoints>: persistent stdio,
one-shot request and in-process launcher examples. These are not MCP tool names;
use C<tools/list> and the published request schemas to discover actual tools.

C<guidance>, where present, is an array of scope/widening advice. It is absent
from the top-level C<semantic_introspection> record and present in its
C<section_contract>. Support and verification sections retain contract guidance.
An absent field must not be synthesized as an empty list or JSON null. Retain
observed array order without inferring positional priority. Named bounded
families require deliberate documented regression-backed widening; deeper key,
query, catalog, artifact and payload semantics remain with their owners.


=head2 Diagnostic report and registry families

The book's C<Diagnostic report and registry families> guide binds the check
metadata lists to report envelopes, success results, failure C<diagnostics[]>
elements and nested objects. C<public_top_level_presence_keys> covers either
outcome; C<success_only_top_level_keys> adds report-level result/support fields
only on success. Failures put support matches inside each diagnostic.
C<matched_success_support_accounting_presence_keys> and
C<matched_failure_diagnostic_support_accounting_presence_keys> are distinct
conditional additions, used only for the corresponding C<matched: true> object.
Unclassified failures retain C<code: null>; required presence is not non-nullness.

C<nested_contract_source_map> identifies dedicated nested owners; the scalar
C<*_contract_source> fields repeat them. C<nested_presence_key_map> uses those
subject labels for base field-name lists. C<failure_diagnostic> means a
C<diagnostics[]> element, not a top-level field. Its C<support_accounting> label
shows the success base family; consult the named failure/matched additions.
C<presence_key_family_map> mirrors same-named check families, including the
object-valued C<source_optional_fields>. That optional-declaration map is not an
array or a guarantee that every source carries every declaration. Optional
artifact fields may carry C<null> when no path was extracted.

C<DiagnosticCodeRegistryContract> instead describes parent diagnostics-section
siblings and each manifest C<stable_codes> entry. C<public_sibling_keys> is not
the contract record's own field list; C<entry_presence_keys> describes catalog
entries. C<key_family_map> mirrors those lists. C<bounded_value_family_map>
mirrors allowed severity, stability and family values, not keys. Those enums do
not classify unregistered diagnostic reports. The manifest catalog is sorted by
code; objects use named lookup, and family-list order promises no priority.

These named families are not a closed schema for all nested report values.
Full diagnostic-schema stability is false; deliberate documented regression-backed
widening remains required. This is a family-subject guide, not complete payload
semantics or an added MCP operation. Deeper fields retain their dedicated owners.


=head2 Normalized report-envelope families

The book's C<Normalized report-envelope families> guide binds the common
C<normalized_semantic_json> families to native report subjects, not the outer
MCP envelope. Both outcomes carry report-level support accounting.
C<success_only_top_level_keys> instead names success-only C<semantic> and
C<generation_result_snapshot>; failures omit both, rather than publishing
partial semantics or the check report's result object.

C<producer_extra_presence_keys> adds C<semantic_layers> on either outcome.
Those advertised projection names do not establish that a failed report has
semantic data. C<source_optional_fields> remains an object of optional declaration
contracts, applicable to qualifying success reports; failure sources use the base
fields. Presence does not imply non-null values or universal declaration support.

C<matched_failure_support_accounting_presence_keys> describes report-level
matched-failure additions, distinct from matched-success source identity.
C<matched_failure_diagnostic_support_accounting_presence_keys> uses the same
field list inside each diagnostic's support object. The current failure producer
uses the first diagnostic's match when available and otherwise keeps an unmatched
report-level object. Check failures instead keep support only inside diagnostics.
Unclassified diagnostics retain a null code; optional artifact values may be null.

Shared C<*_contract_source> identities retain dedicated command, source, producer,
generated-output, support, diagnostic, summary and serializable-snapshot owners.
They do not add callable tools or expose a live generator object. Report schema,
contract schema, build, protocol and language versions are distinct. This is not a closed schema
for all nested values; deeper payload/IR/maps/snapshot meanings retain their owners.


=head2 Normalized payload and IR baseline families

The book's C<Normalized payload and IR baseline families> guide distinguishes
C<public_layers> name values from the child keys of C<semantic.forward_ir>.
C<success_semantic_presence_keys> names the success payload's base fields;
C<success_semantic_optional_child_presence_keys> separately names optional
C<composition>, C<protocol_intent_bundle> and C<symbol_contract> children.
The required C<explicit_system_contract> key can contain null when no authored
system object is preserved. A nested object's advertised fields do not establish
that the object is available or non-null on every report.

Module core/optional metrics, signal buckets/entry fields and effective versus
authored system contracts retain distinct subjects. Intent-HIR and lowered-RTL
optional composition fields belong to their tier, not to a child entry or the
root composition object. Structural fields describe sanitized collections and
summaries; richer entry/value semantics retain their own contracts.

Use the emitted owner labels, including C<explicit_system_contract_source>,
C<system_contract_source> and C<symbol_contract_source>. Appending
C<_contract_source> to every object label invents unsupported field names.
Owner namespaces and IR-tier discovery do not execute simulation or validation,
expose live compiler objects or establish whole-export stability.
The normalized builder preserves C<JSON::PP::Boolean> values, including false
inside nested hashes and arrays, while filtering private/unsupported references.
This preserves value kinds without changing the advertised field families.
Direct-helper controls qualify this repair; native source reachability stays separate.
This is not a closed schema for nested values; deliberate widening and deeper
symbol/composition/control/structural/grouped-model owners remain required.

=head2 Normalized symbol family subjects

The book's C<Normalized symbol family subjects> table pairs each
C<symbol_contract_> suffix with its
C<success_forward_ir_intent_hir_symbol_contract_> counterpart. Apply the former
to C<semantic.symbol_contract> and the latter to
C<semantic.forward_ir.intent_hir.symbol_contract>. Both delegate to
C<FSM::Support::NormalizedSemanticSymbolContract>; equal family values do not
make their payload locations interchangeable.

Constant value keys distinguish C<kind>, scalar C<payload> and recursive list
C<items>. Enum kind labels C<member_payload_map> and C<scalar_payload> describe
values under dynamic names. Recursive types distinguish core keys, scalar and
aggregate kind labels, optional C<state_model>, list C<items> and record
C<member_order>/C<members>. Package imports use C<scalar_package_name> values,
not package-spec objects.

Package-import meaning fields are scalar strings individually and single-element arrays
in grouped maps. The report presence map uses full field names; the semantic
presence map removes the leading C<success_> for intent-HIR counterparts.
This is not a closed schema for arbitrary nested values. Optional object
availability, source models, remaining grouped closure and actual execution
retain their dedicated contracts.

=head2 Normalized composition envelope and shallow children

The book's matching table binds C<composition_presence_keys> to
C<semantic.composition>, C<composition_child_entry_keys> to its C<children[]>,
and C<composition_generated_child_entry_keys> to its C<generated_children[]>.
C<success_forward_ir_intent_hir_composition_child_entry_keys> instead describes
C<semantic.forward_ir.intent_hir.composition_children[]>; the generated-child
counterpart describes C<semantic.forward_ir.intent_hir.composition_generated_children[]>.
Those HIR collections are flattened, not nested under an HIR composition object.

C<FSM::Support::NormalizedSemanticCompositionContract> owns the envelope and
both shallow child families. Report/payload and forward-IR/intent-HIR helpers
republish the corresponding dedicated functions. The envelope's lane/counts,
child collections and C<shared_datapath_candidates> do not recursively define
their entries. C<plan_snapshot> and sanitized C<provenance_report> retain
C<FSM::Support::SerializableCompositionPlanSnapshot> and
C<FSM::Support::CompositionReportContract> ownership respectively.

Ordinary/generated children share identity fields, state/DT/drive/override
metrics, C<parameter_overrides> and child IR summaries. The book lists their
complete shallow keys and exact dedicated functions. Nested overrides and
C<intent_hir>, C<lowered_rtl_ir>, C<structural_rtl_ir> keep their own contracts.
Equal key lists do not prove equal child populations, array-index correspondence
or unconditional source availability. Guard optional objects/collections before
reading an element. Standalone-DT, shared-datapath, grouped-map and deeper value
models remain separately owned; metadata does not promise execution or backend support.

=head2 Normalized composition parameter-override aliases

The book's matching tables pair the C<composition_child_parameter_override_>
and C<composition_generated_child_parameter_override_> prefixes with
C<semantic.composition.children[].parameter_overrides[]> and
C<semantic.composition.generated_children[].parameter_overrides[]>.
Their C<success_forward_ir_intent_hir_> counterparts describe the flattened
C<semantic.forward_ir.intent_hir.composition_children[].parameter_overrides[]>
and C<composition_generated_children[].parameter_overrides[]> locations.

Append C<entry_keys>, C<raw_value_extension_keys> or
C<value_metadata_extension_keys>. CompositionContract owns these aliases and
delegates to StructuralRTLIRContract's
C<normalized_semantic_structural_rtl_ir_instance_parameter_override_>
functions with the same suffix. Report/payload/forward-IR/HIR helpers preserve
the distinct child subjects while republishing those structural value families.

Core keys are C<name>, C<origin_kind>, C<raw_value_ast>, C<value_kind>,
C<value_payload>, C<value_text>. This is not a complete nested AST/value model.
The optional C<raw_value> extension requires a single authored token surviving
validation. The resolver and matched child/interface declaration provide optional
C<declaration_default_value_kind>, C<declaration_default_value_width>,
C<value_type_spec> and C<value_width> metadata; do not require every extension
key on every entry. Equal schemas establish neither matching populations nor
unconditional source availability. No standalone-DT parameter-override alias
is introduced; deeper models, grouped closure and execution remain separate.

=head2 Normalized composition standalone-DT children

The book's matching tables pair C<composition_standalone_dt_> metadata suffixes
with C<semantic.composition.standalone_dt_children[]> and
C<success_forward_ir_intent_hir_composition_standalone_dt_> counterparts with
C<semantic.forward_ir.intent_hir.composition_standalone_dt_children[]>.
These are shallow reusable standalone-DT children, distinct from ordinary or
generated child entries and from nested child IR models.

C<child_entry_keys>, C<enable_family_entry_keys> and
C<module_enable_family_keys> come directly from CompositionContract.
C<multi_drive_target_entry_keys> and C<multi_drive_assertion_keys> delegate to
LoweredRTLIRContract's matching C<normalized_semantic_lowered_rtl_ir_standalone_dt_>
functions. The book lists complete subjects/keys and the report/payload/HIR
republishing boundary.

Per-DT enable families and multi-drive targets are arrays; singular
C<standalone_dt_module_enable_family> and nested C<multi_drive_assertion> are
objects. The assertion family applies inside each target. Module enable
metadata contains arrays of DT names and enable signals. Guard optional
objects/collections and check contents before indexing; HIR child collections
are flattened rather than nested under an HIR composition object.

There are no standalone-DT parameter-override aliases in these families.
Child IR contracts and deeper models stay delegated. Metadata does not prove
execution, emitted/checked assertions, verified arbitration or unconditional
source availability. Full source/backend and broader grouped-map closure remain separate.

=head2 Normalized composition grouped lookups

Under C<semantic_exports.normalized_semantic_json>, the report
C<presence_key_family_map> uses complete metadata field names. For the
documented flattened intent-HIR composition child families,
C<semantic_presence_key_family_map> omits the leading C<success_>.
Root child-family names are unchanged. The report map includes the envelope
C<composition_presence_keys>; the semantic map omits that entry. Check exact
membership rather than assuming the two maps are interchangeable.

The selected child, parameter-override and standalone-DT grouped values retain
their individual ordered key arrays, subjects, dedicated owners and optional
extension rules. They advertise schemas rather than child instances or
source availability. The book gives exact lookup examples and a runnable discovery
command. Equal lists imply neither equal populations nor matching indices;
broader grouped-map/model, shared-datapath and source/backend qualification
remain separate.

=head2 Normalized shared-datapath candidate and contributor subjects

Combine C<composition_shared_datapath_> or
C<success_forward_ir_lowered_rtl_ir_composition_shared_datapath_> with
C<candidate_entry_keys>, C<candidate_declared_type_extension_keys>,
C<candidate_contributor_entry_keys> or
C<candidate_contributor_declared_type_extension_keys>. The first prefix targets
C<semantic.composition.shared_datapath_candidates[]>; the second targets
C<semantic.forward_ir.lowered_rtl_ir.composition_shared_datapath_candidates[]>.
Contributor families describe C<contributors[]> elements inside each candidate.
These are lowered-tier families, not intent-HIR counterparts.

C<FSM::Support::NormalizedSemanticLoweredRTLIRContract> owns the exact lists.
Composition-side aliases delegate to it; forward/payload/report contracts and
this manifest republish the corresponding metadata. The book lists complete
ordered keys and exact subject examples.

C<declared_type_name> and C<declared_type_spec> are independently optional on
their respective candidate/contributor objects: each is emitted only when its
resolved value is defined. Check keys separately. The optional extension list
does not promise both keys, non-null core values or source availability.
Child IR summaries and deeper type/value, binding/drive, aggregate and assertion
models remain delegated. Equal lists imply neither equal populations nor
matching indices, execution or verified arbitration; arrays do not imply priority.

=head2 Normalized shared-datapath binding and drive-intent subjects

Under either C<composition_shared_datapath_> or
C<success_forward_ir_lowered_rtl_ir_composition_shared_datapath_>,
C<bound_connection_expr_keys> describes the contributor's nullable binding
object for the C<signal_ref> variant: C<kind> and C<signal_name>. This is not
the complete expression grammar. The public structured-IR builder preserves
compound nodes such as C<concat> with nested C<operands>; preserve those fields
and inspect kind instead of applying a universal two-key validator. The book
gives a checked public-builder example. Native source availability and deeper
kind-dependent models remain separately qualified.

C<candidate_contributor_drive_intent_entry_keys> describes the singular
C<contributors[].drive_intent> object, which can be empty when no valid drive
family is available. C<candidate_contributor_drive_intent_rhs_enable_family_entry_keys>
describes each nested C<rhs_enable_families[]> element; driver-list values are
arrays. LoweredRTLIRContract owns these families and delegates the RHS family
to its output-drive RHS helper. Composition/forward/payload/report contracts
republish the corresponding root/lowered metadata. Default/reset/RHS values,
complete expression grammar and deeper IR/value models stay delegated. Metadata
does not establish equal populations, execution, arbitration or backend support.

=head2 Normalized shared-datapath aggregate and assertion subjects

Under C<composition_shared_datapath_> and
C<success_forward_ir_lowered_rtl_ir_composition_shared_datapath_>,
C<aggregate_enable_family_entry_keys> describes candidate
C<aggregate_enable_families[]> elements. C<aggregate_enable_contributor_entry_keys>
describes each family's C<contributors[]> element, distinct from candidate-level
contributor objects. LoweredRTLIRContract owns both lists; composition, forward,
payload and report contracts republish the corresponding root/lowered metadata.

Families group available hash-shaped RHS-family records with defined RHS values,
in sorted RHS-key order; the array can be empty. The candidate family count and
each family's contributor count name their respective array lengths. Family
contributors carry endpoint, family/source enable names and copied driver arrays.

C<assertion_keys> describes both the candidate's C<multi_value_assertion> object
and each aggregate family's C<same_value_assertion> object. The former takes
family C<aggregate_enable_signal> values; the latter takes contributor
C<source_enable_signal> values. Their C<result_signal> names the corresponding
multi-value or same-value conflict signal. Both carry C<kind: onehot0> and an
C<input_enable_signals> array filtered to defined, nonempty names in input order;
C<input_count> is that surviving length. Construction returns an object for an
empty input list. A family object exists only with its family entry; optional
candidate/IR availability still applies. Metadata alone does not prove emitted
assertions, arbitration or execution. Complete values/expression/deeper IR models,
source availability and source-query applicability remain separately qualified.

=head1 ERRORS AND EFFECTS

Construction errors propagate as Perl exceptions. This function constructs
capability metadata; it does not generate HDL or run a simulation. Use
C<./bin/fsmgen --capability-manifest> for the corresponding CLI discovery path.

=head1 CONTRACT AND STABILITY

The authoritative schema and compatibility boundaries are carried by the
manifest's contract sections and described in the manual. This POD does not
freeze every implementation helper used to construct those sections. For
generation see L<FSM::Pipeline::HDLGenerator>; for the read-only adapter see
L<FSM::Support::SemanticIntrospectionMCPAdapter>.

=cut
