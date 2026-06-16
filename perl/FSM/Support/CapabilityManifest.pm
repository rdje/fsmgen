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
        documentation => build_documentation_section(),
        manifest_contract => build_capability_manifest_contract(),
    };
}

1;
