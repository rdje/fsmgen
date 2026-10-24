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
domain. C<language_surface> retains C<surface_contract>; other sections advertise
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
