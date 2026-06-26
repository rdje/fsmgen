//! Rust/Rust-Wasm portable API smoke scaffold for FSMGen.
//!
//! This crate is deliberately not wired into the shipped Perl implementation.
//! It models the first request/result and host/artifact contract shell so later
//! slices can add behavior behind task-tree ownership and Perl-oracle parity.

#![forbid(unsafe_code)]

use std::collections::BTreeMap;

pub const API_SCHEMA_VERSION: u32 = 1;
pub const IMPLEMENTATION_ID: &str = "fsmgen-portable-rust-experiment";
pub const IMPLEMENTATION_STATUS: &str = "experimental_incomplete";

#[derive(Clone, Debug, Eq, PartialEq)]
pub enum Operation {
    Check,
    Lower,
    Schedule,
    Semantic,
    GenerateHdl,
    VerificationOutput,
}

impl Operation {
    pub fn as_str(&self) -> &'static str {
        match self {
            Self::Check => "check",
            Self::Lower => "lower",
            Self::Schedule => "schedule",
            Self::Semantic => "semantic",
            Self::GenerateHdl => "generate_hdl",
            Self::VerificationOutput => "verification_output",
        }
    }

    pub fn all() -> [Self; 6] {
        [
            Self::Check,
            Self::Lower,
            Self::Schedule,
            Self::Semantic,
            Self::GenerateHdl,
            Self::VerificationOutput,
        ]
    }
}

#[derive(Clone, Debug, Eq, PartialEq)]
pub enum SourceKind {
    Fsm,
    Isf,
    Ppif,
    Package,
    Unknown(String),
}

impl SourceKind {
    pub fn as_str(&self) -> &str {
        match self {
            Self::Fsm => "fsm",
            Self::Isf => "isf",
            Self::Ppif => "ppif",
            Self::Package => "package",
            Self::Unknown(kind) => kind.as_str(),
        }
    }
}

#[derive(Clone, Debug, Eq, PartialEq)]
pub enum HostOrigin {
    Memory,
    Filesystem,
    Workspace,
    Embedded,
    Other(String),
}

impl HostOrigin {
    pub fn as_str(&self) -> &str {
        match self {
            Self::Memory => "memory",
            Self::Filesystem => "filesystem",
            Self::Workspace => "workspace",
            Self::Embedded => "embedded",
            Self::Other(origin) => origin.as_str(),
        }
    }
}

#[derive(Clone, Debug, Eq, PartialEq)]
pub struct SourceEnvelope {
    pub source_id: String,
    pub source_kind: Option<SourceKind>,
    pub text: String,
    pub encoding: String,
}

impl SourceEnvelope {
    pub fn new(
        source_id: impl Into<String>,
        source_kind: Option<SourceKind>,
        text: impl Into<String>,
    ) -> Self {
        Self {
            source_id: source_id.into(),
            source_kind,
            text: text.into(),
            encoding: "UTF-8".to_string(),
        }
    }
}

#[derive(Clone, Debug, Eq, PartialEq)]
pub struct HostProfile {
    pub origin: HostOrigin,
    pub source_catalog: bool,
    pub artifact_sink: bool,
}

impl HostProfile {
    pub fn in_memory() -> Self {
        Self {
            origin: HostOrigin::Memory,
            source_catalog: true,
            artifact_sink: true,
        }
    }
}

#[derive(Clone, Debug, Eq, PartialEq)]
pub struct RequestOptions {
    pub strict_mode: bool,
    pub target_language: Option<String>,
    pub emit_review_artifacts: bool,
    pub emit_reports: bool,
    pub emit_hdl_artifacts: bool,
}

impl Default for RequestOptions {
    fn default() -> Self {
        Self {
            strict_mode: false,
            target_language: None,
            emit_review_artifacts: false,
            emit_reports: true,
            emit_hdl_artifacts: false,
        }
    }
}

#[derive(Clone, Debug, Eq, PartialEq)]
pub struct Request {
    pub api_schema_version: u32,
    pub operation: Operation,
    pub source: SourceEnvelope,
    pub options: RequestOptions,
    pub host: HostProfile,
}

impl Request {
    pub fn new(operation: Operation, source: SourceEnvelope) -> Self {
        Self {
            api_schema_version: API_SCHEMA_VERSION,
            operation,
            source,
            options: RequestOptions::default(),
            host: HostProfile::in_memory(),
        }
    }
}

#[derive(Clone, Debug, Eq, PartialEq)]
pub enum DiagnosticSeverity {
    Error,
    Warning,
    Info,
}

impl DiagnosticSeverity {
    pub fn as_str(&self) -> &'static str {
        match self {
            Self::Error => "error",
            Self::Warning => "warning",
            Self::Info => "info",
        }
    }
}

#[derive(Clone, Debug, Eq, PartialEq)]
pub struct Diagnostic {
    pub severity: DiagnosticSeverity,
    pub code: String,
    pub message: String,
}

impl Diagnostic {
    pub fn unsupported(operation: &Operation) -> Self {
        Self {
            severity: DiagnosticSeverity::Error,
            code: "E_PORTABLE_RUST_UNIMPLEMENTED_OPERATION".to_string(),
            message: format!(
                "Rust portable API smoke does not yet implement '{}' operation",
                operation.as_str()
            ),
        }
    }
}

#[derive(Clone, Debug, Eq, PartialEq)]
pub struct SupportAccounting {
    pub matched: bool,
    pub classification: String,
    pub source_kind: Option<String>,
}

impl SupportAccounting {
    pub fn unsupported(source_kind: Option<&SourceKind>) -> Self {
        Self {
            matched: false,
            classification: "unsupported_experiment_scaffold".to_string(),
            source_kind: source_kind.map(|kind| kind.as_str().to_string()),
        }
    }
}

#[derive(Clone, Debug, Eq, PartialEq)]
pub struct VirtualArtifact {
    pub relpath: String,
    pub kind: String,
    pub language: Option<String>,
    pub role: String,
    pub content: String,
    pub source_layer: Option<String>,
    pub generated_from: String,
}

#[derive(Clone, Debug, Eq, PartialEq)]
pub struct GeneratedOutput {
    pub emitted: bool,
    pub artifacts: Vec<VirtualArtifact>,
}

impl GeneratedOutput {
    pub fn none() -> Self {
        Self {
            emitted: false,
            artifacts: Vec::new(),
        }
    }
}

#[derive(Clone, Debug, Eq, PartialEq)]
pub struct ResultEnvelope {
    pub api_schema_version: u32,
    pub operation: Operation,
    pub success: bool,
    pub source_id: String,
    pub source_kind: Option<SourceKind>,
    pub diagnostics: Vec<Diagnostic>,
    pub support_accounting: SupportAccounting,
    pub reports: BTreeMap<String, JsonValue>,
    pub artifacts: Vec<VirtualArtifact>,
    pub generated_output: GeneratedOutput,
    pub implementation: ImplementationProfile,
}

impl ResultEnvelope {
    pub fn unsupported(request: &Request) -> Self {
        Self {
            api_schema_version: API_SCHEMA_VERSION,
            operation: request.operation.clone(),
            success: false,
            source_id: request.source.source_id.clone(),
            source_kind: request.source.source_kind.clone(),
            diagnostics: vec![Diagnostic::unsupported(&request.operation)],
            support_accounting: SupportAccounting::unsupported(request.source.source_kind.as_ref()),
            reports: BTreeMap::new(),
            artifacts: Vec::new(),
            generated_output: GeneratedOutput::none(),
            implementation: ImplementationProfile::current(),
        }
    }
}

#[derive(Clone, Debug, Eq, PartialEq)]
pub struct ImplementationProfile {
    pub implementation_id: String,
    pub status: String,
    pub api_schema_version: u32,
}

impl ImplementationProfile {
    pub fn current() -> Self {
        Self {
            implementation_id: IMPLEMENTATION_ID.to_string(),
            status: IMPLEMENTATION_STATUS.to_string(),
            api_schema_version: API_SCHEMA_VERSION,
        }
    }
}

#[derive(Clone, Debug, Eq, PartialEq)]
pub struct CapabilityProfile {
    pub implementation: ImplementationProfile,
    pub known_operations: Vec<String>,
    pub implemented_operations: Vec<String>,
    pub host_profiles: Vec<String>,
    pub extension_support: bool,
}

pub fn capabilities() -> CapabilityProfile {
    CapabilityProfile {
        implementation: ImplementationProfile::current(),
        known_operations: Operation::all()
            .iter()
            .map(|operation| operation.as_str().to_string())
            .collect(),
        implemented_operations: Vec::new(),
        host_profiles: vec!["memory".to_string()],
        extension_support: false,
    }
}

pub fn execute(request: Request) -> ResultEnvelope {
    ResultEnvelope::unsupported(&request)
}

#[derive(Clone, Debug, Eq, PartialEq)]
pub enum JsonValue {
    Null,
    Bool(bool),
    Number(i64),
    String(String),
    Array(Vec<JsonValue>),
    Object(BTreeMap<String, JsonValue>),
}

impl JsonValue {
    pub fn string(value: impl Into<String>) -> Self {
        Self::String(value.into())
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn capability_profile_is_explicitly_incomplete() {
        let profile = capabilities();

        assert_eq!(
            profile.implementation.api_schema_version,
            API_SCHEMA_VERSION
        );
        assert_eq!(profile.implementation.implementation_id, IMPLEMENTATION_ID);
        assert_eq!(profile.implementation.status, IMPLEMENTATION_STATUS);
        assert_eq!(
            profile.known_operations,
            vec![
                "check",
                "lower",
                "schedule",
                "semantic",
                "generate_hdl",
                "verification_output",
            ]
        );
        assert!(profile.implemented_operations.is_empty());
        assert_eq!(profile.host_profiles, vec!["memory"]);
        assert!(!profile.extension_support);
    }

    #[test]
    fn execute_fails_closed_for_unimplemented_check_operation() {
        let request = Request::new(
            Operation::Check,
            SourceEnvelope::new(
                "memory://trial_0.fsm",
                Some(SourceKind::Fsm),
                "(?fsm:trial_0)",
            ),
        );

        let result = execute(request);

        assert_eq!(result.api_schema_version, API_SCHEMA_VERSION);
        assert_eq!(result.operation, Operation::Check);
        assert!(!result.success);
        assert_eq!(result.source_id, "memory://trial_0.fsm");
        assert_eq!(result.source_kind, Some(SourceKind::Fsm));
        assert_eq!(result.diagnostics.len(), 1);
        assert_eq!(
            result.diagnostics[0].code,
            "E_PORTABLE_RUST_UNIMPLEMENTED_OPERATION"
        );
        assert_eq!(result.diagnostics[0].severity, DiagnosticSeverity::Error);
        assert_eq!(
            result.support_accounting.classification,
            "unsupported_experiment_scaffold"
        );
        assert!(!result.support_accounting.matched);
        assert_eq!(
            result.support_accounting.source_kind.as_deref(),
            Some("fsm")
        );
        assert!(result.reports.is_empty());
        assert!(result.artifacts.is_empty());
        assert!(!result.generated_output.emitted);
        assert!(result.generated_output.artifacts.is_empty());
    }

    #[test]
    fn source_and_host_defaults_are_in_memory_and_utf8() {
        let request = Request::new(
            Operation::Semantic,
            SourceEnvelope::new("source-id", None, "(?fsm:placeholder)"),
        );

        assert_eq!(request.api_schema_version, API_SCHEMA_VERSION);
        assert_eq!(request.source.encoding, "UTF-8");
        assert_eq!(request.host.origin, HostOrigin::Memory);
        assert!(request.host.source_catalog);
        assert!(request.host.artifact_sink);
        assert!(request.options.emit_reports);
        assert!(!request.options.emit_hdl_artifacts);
    }

    #[test]
    fn virtual_artifact_shape_matches_portable_contract_names() {
        let artifact = VirtualArtifact {
            relpath: "generated/example.fsm".to_string(),
            kind: "generated_fsm".to_string(),
            language: Some("fsm".to_string()),
            role: "review".to_string(),
            content: "(?fsm:example)".to_string(),
            source_layer: Some("IAL0".to_string()),
            generated_from: "memory://example.isf".to_string(),
        };

        assert_eq!(artifact.relpath, "generated/example.fsm");
        assert_eq!(artifact.kind, "generated_fsm");
        assert_eq!(artifact.language.as_deref(), Some("fsm"));
        assert_eq!(artifact.role, "review");
        assert_eq!(artifact.source_layer.as_deref(), Some("IAL0"));
        assert_eq!(artifact.generated_from, "memory://example.isf");
    }
}
