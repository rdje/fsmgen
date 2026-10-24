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
