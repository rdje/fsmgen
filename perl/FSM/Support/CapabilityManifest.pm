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
