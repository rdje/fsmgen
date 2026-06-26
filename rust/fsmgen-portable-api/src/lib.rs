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
pub const DIRECT_FSM_CHECK_SMOKE_ENTRY_ID: &str = "feature.direct_sreset_active_high";

const DIRECT_FSM_CHECK_SMOKE_SOURCE: &str = r#"(?fsm:direct_sreset_active_high
  (+system
    (clock clk)
    (sreset reset)
  )

  (+size
    (START 1)
    (DONE 1)
  )

  (idle
    (<START
      (<= (DONE 1'b1))
    )
  )
)"#;

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

    pub fn unsupported_check_source() -> Self {
        Self {
            severity: DiagnosticSeverity::Error,
            code: "E_PORTABLE_RUST_UNSUPPORTED_CHECK_SOURCE".to_string(),
            message: "Rust portable API smoke only supports the direct_sreset_active_high .fsm check fixture".to_string(),
        }
    }
}

#[derive(Clone, Debug, Eq, PartialEq)]
pub struct SupportAccounting {
    pub matched: bool,
    pub classification: String,
    pub source_kind: Option<String>,
    pub entry_id: Option<String>,
    pub family: Option<String>,
    pub coverage: Option<String>,
    pub strict_supported: Option<bool>,
}

impl SupportAccounting {
    pub fn unsupported(source_kind: Option<&SourceKind>) -> Self {
        Self {
            matched: false,
            classification: "unsupported_experiment_scaffold".to_string(),
            source_kind: source_kind.map(|kind| kind.as_str().to_string()),
            entry_id: None,
            family: None,
            coverage: None,
            strict_supported: None,
        }
    }

    pub fn unsupported_check_source(source_kind: Option<&SourceKind>) -> Self {
        Self {
            matched: false,
            classification: "unsupported_direct_fsm_check_smoke".to_string(),
            source_kind: source_kind.map(|kind| kind.as_str().to_string()),
            entry_id: None,
            family: None,
            coverage: None,
            strict_supported: None,
        }
    }

    pub fn supported_direct_fsm_check_smoke() -> Self {
        Self {
            matched: true,
            classification: "supported_smoke".to_string(),
            source_kind: Some("fsm".to_string()),
            entry_id: Some(DIRECT_FSM_CHECK_SMOKE_ENTRY_ID.to_string()),
            family: Some("language_feature_fixture".to_string()),
            coverage: Some("direct_root_pipeline_cli".to_string()),
            strict_supported: Some(true),
        }
    }

    fn to_report_json(&self) -> JsonValue {
        let mut object = BTreeMap::new();
        object.insert("matched".to_string(), JsonValue::Bool(self.matched));
        object.insert(
            "classification".to_string(),
            JsonValue::String(self.classification.clone()),
        );

        if let Some(source_kind) = &self.source_kind {
            object.insert(
                "source_kind".to_string(),
                JsonValue::String(source_kind.clone()),
            );
        }
        if let Some(entry_id) = &self.entry_id {
            object.insert("entry_id".to_string(), JsonValue::String(entry_id.clone()));
        }
        if let Some(family) = &self.family {
            object.insert("family".to_string(), JsonValue::String(family.clone()));
        }
        if let Some(coverage) = &self.coverage {
            object.insert("coverage".to_string(), JsonValue::String(coverage.clone()));
        }
        if let Some(strict_supported) = self.strict_supported {
            object.insert(
                "strict_supported".to_string(),
                JsonValue::Bool(strict_supported),
            );
        }

        JsonValue::Object(object)
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

    pub fn unsupported_check_source(request: &Request) -> Self {
        Self {
            api_schema_version: API_SCHEMA_VERSION,
            operation: request.operation.clone(),
            success: false,
            source_id: request.source.source_id.clone(),
            source_kind: request.source.source_kind.clone(),
            diagnostics: vec![Diagnostic::unsupported_check_source()],
            support_accounting: SupportAccounting::unsupported_check_source(
                request.source.source_kind.as_ref(),
            ),
            reports: BTreeMap::new(),
            artifacts: Vec::new(),
            generated_output: GeneratedOutput::none(),
            implementation: ImplementationProfile::current(),
        }
    }

    pub fn check_success(request: &Request, summary: CheckSummary) -> Self {
        let support_accounting = SupportAccounting::supported_direct_fsm_check_smoke();
        let mut reports = BTreeMap::new();
        reports.insert(
            "check_json".to_string(),
            build_check_json_report(request, &summary, &support_accounting),
        );

        Self {
            api_schema_version: API_SCHEMA_VERSION,
            operation: request.operation.clone(),
            success: true,
            source_id: request.source.source_id.clone(),
            source_kind: request.source.source_kind.clone().or(Some(SourceKind::Fsm)),
            diagnostics: Vec::new(),
            support_accounting,
            reports,
            artifacts: Vec::new(),
            generated_output: GeneratedOutput::none(),
            implementation: ImplementationProfile::current(),
        }
    }
}

#[derive(Clone, Debug, Eq, PartialEq)]
pub struct CheckSummary {
    pub module_name: String,
    pub state_count: u32,
    pub signal_count: u32,
    pub composition_child_count: Option<u32>,
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
        implemented_operations: vec![Operation::Check.as_str().to_string()],
        host_profiles: vec!["memory".to_string()],
        extension_support: false,
    }
}

pub fn execute(request: Request) -> ResultEnvelope {
    match &request.operation {
        Operation::Check => execute_check(&request),
        _ => ResultEnvelope::unsupported(&request),
    }
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

fn execute_check(request: &Request) -> ResultEnvelope {
    if !is_fsm_source(&request.source) {
        return ResultEnvelope::unsupported_check_source(request);
    }

    match recognize_direct_fsm_check_smoke(&request.source.text) {
        Some(summary) => ResultEnvelope::check_success(request, summary),
        None => ResultEnvelope::unsupported_check_source(request),
    }
}

fn is_fsm_source(source: &SourceEnvelope) -> bool {
    matches!(source.source_kind.as_ref(), Some(SourceKind::Fsm))
        || (source.source_kind.is_none() && source.source_id.ends_with(".fsm"))
}

fn recognize_direct_fsm_check_smoke(text: &str) -> Option<CheckSummary> {
    let candidate = normalize_lispish_source(text);
    let expected = normalize_lispish_source(DIRECT_FSM_CHECK_SMOKE_SOURCE);

    if candidate == expected {
        Some(CheckSummary {
            module_name: "direct_sreset_active_high".to_string(),
            state_count: 1,
            signal_count: 1,
            composition_child_count: None,
        })
    } else {
        None
    }
}

fn normalize_lispish_source(text: &str) -> String {
    text.lines()
        .map(|line| line.split_once(';').map_or(line, |(before, _)| before))
        .flat_map(|line| line.split_whitespace())
        .collect::<Vec<_>>()
        .join(" ")
}

fn build_check_json_report(
    request: &Request,
    summary: &CheckSummary,
    support_accounting: &SupportAccounting,
) -> JsonValue {
    json_object([
        ("check_schema_version", JsonValue::Number(1)),
        ("success", JsonValue::Bool(true)),
        ("diagnostics", JsonValue::Array(Vec::new())),
        (
            "diagnostic_summary",
            json_object([
                ("diagnostic_count", JsonValue::Number(0)),
                ("has_diagnostics", JsonValue::Bool(false)),
                ("success", JsonValue::Bool(true)),
            ]),
        ),
        (
            "generated_output",
            json_object([("emitted", JsonValue::Bool(false))]),
        ),
        (
            "producer",
            json_object([
                ("name", JsonValue::String("FSMGen".to_string())),
                (
                    "report_source",
                    JsonValue::String(IMPLEMENTATION_ID.to_string()),
                ),
            ]),
        ),
        (
            "command",
            json_object([
                ("mode", JsonValue::String("check".to_string())),
                ("json", JsonValue::Bool(true)),
                ("strict_mode", JsonValue::Bool(request.options.strict_mode)),
                (
                    "target_language",
                    JsonValue::String(
                        request
                            .options
                            .target_language
                            .clone()
                            .unwrap_or_else(|| "systemverilog".to_string()),
                    ),
                ),
            ]),
        ),
        (
            "source",
            json_object([
                ("input", JsonValue::String(request.source.source_id.clone())),
                ("source_kind", JsonValue::String("fsm".to_string())),
            ]),
        ),
        (
            "result",
            json_object([
                (
                    "module_name",
                    JsonValue::String(summary.module_name.clone()),
                ),
                ("state_count", JsonValue::Number(summary.state_count as i64)),
                (
                    "signal_count",
                    JsonValue::Number(summary.signal_count as i64),
                ),
                (
                    "composition_child_count",
                    summary
                        .composition_child_count
                        .map(|count| JsonValue::Number(count as i64))
                        .unwrap_or(JsonValue::Null),
                ),
            ]),
        ),
        ("support_accounting", support_accounting.to_report_json()),
    ])
}

fn json_object<const N: usize>(entries: [(&str, JsonValue); N]) -> JsonValue {
    let mut object = BTreeMap::new();
    for (key, value) in entries {
        object.insert(key.to_string(), value);
    }
    JsonValue::Object(object)
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
        assert_eq!(profile.implemented_operations, vec!["check"]);
        assert_eq!(profile.host_profiles, vec!["memory"]);
        assert!(!profile.extension_support);
    }

    #[test]
    fn execute_succeeds_for_direct_sreset_active_high_check_smoke() {
        let request = Request::new(
            Operation::Check,
            SourceEnvelope::new(
                "t/corpus/direct_sreset_active_high.fsm",
                Some(SourceKind::Fsm),
                DIRECT_FSM_CHECK_SMOKE_SOURCE,
            ),
        );

        let result = execute(request);

        assert_eq!(result.api_schema_version, API_SCHEMA_VERSION);
        assert_eq!(result.operation, Operation::Check);
        assert!(result.success);
        assert_eq!(result.source_id, "t/corpus/direct_sreset_active_high.fsm");
        assert_eq!(result.source_kind, Some(SourceKind::Fsm));
        assert!(result.diagnostics.is_empty());
        assert!(result.support_accounting.matched);
        assert_eq!(
            result.support_accounting.entry_id.as_deref(),
            Some(DIRECT_FSM_CHECK_SMOKE_ENTRY_ID)
        );
        assert_eq!(result.support_accounting.classification, "supported_smoke");
        assert_eq!(
            result.support_accounting.coverage.as_deref(),
            Some("direct_root_pipeline_cli")
        );
        assert_eq!(
            result.support_accounting.source_kind.as_deref(),
            Some("fsm")
        );
        assert_eq!(result.support_accounting.strict_supported, Some(true));
        assert!(result.artifacts.is_empty());
        assert!(!result.generated_output.emitted);
        assert!(result.generated_output.artifacts.is_empty());

        let check_report = report_object(&result, "check_json");
        assert_eq!(check_report.get("success"), Some(&JsonValue::Bool(true)));
        assert_eq!(
            nested_string(check_report, "result", "module_name"),
            Some("direct_sreset_active_high")
        );
        assert_eq!(
            nested_number(check_report, "result", "state_count"),
            Some(1)
        );
        assert_eq!(
            nested_number(check_report, "result", "signal_count"),
            Some(1)
        );
        assert_eq!(
            nested_bool(check_report, "generated_output", "emitted"),
            Some(false)
        );
        assert_eq!(
            nested_string(check_report, "support_accounting", "entry_id"),
            Some(DIRECT_FSM_CHECK_SMOKE_ENTRY_ID)
        );
    }

    #[test]
    fn execute_fails_closed_for_unsupported_check_source() {
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
            "E_PORTABLE_RUST_UNSUPPORTED_CHECK_SOURCE"
        );
        assert_eq!(result.diagnostics[0].severity, DiagnosticSeverity::Error);
        assert_eq!(
            result.support_accounting.classification,
            "unsupported_direct_fsm_check_smoke"
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
    fn execute_fails_closed_for_unimplemented_lower_operation() {
        let request = Request::new(
            Operation::Lower,
            SourceEnvelope::new(
                "t/corpus/direct_sreset_active_high.fsm",
                Some(SourceKind::Fsm),
                DIRECT_FSM_CHECK_SMOKE_SOURCE,
            ),
        );

        let result = execute(request);

        assert_eq!(result.operation, Operation::Lower);
        assert!(!result.success);
        assert_eq!(result.diagnostics.len(), 1);
        assert_eq!(
            result.diagnostics[0].code,
            "E_PORTABLE_RUST_UNIMPLEMENTED_OPERATION"
        );
        assert_eq!(
            result.support_accounting.classification,
            "unsupported_experiment_scaffold"
        );
        assert!(result.reports.is_empty());
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

    fn report_object<'a>(
        result: &'a ResultEnvelope,
        report_name: &str,
    ) -> &'a BTreeMap<String, JsonValue> {
        match result.reports.get(report_name) {
            Some(JsonValue::Object(object)) => object,
            other => panic!("expected object report {report_name}, got {other:?}"),
        }
    }

    fn nested_object<'a>(
        object: &'a BTreeMap<String, JsonValue>,
        key: &str,
    ) -> Option<&'a BTreeMap<String, JsonValue>> {
        match object.get(key) {
            Some(JsonValue::Object(nested)) => Some(nested),
            _ => None,
        }
    }

    fn nested_string<'a>(
        object: &'a BTreeMap<String, JsonValue>,
        key: &str,
        nested_key: &str,
    ) -> Option<&'a str> {
        nested_object(object, key).and_then(|nested| match nested.get(nested_key) {
            Some(JsonValue::String(value)) => Some(value.as_str()),
            _ => None,
        })
    }

    fn nested_number(
        object: &BTreeMap<String, JsonValue>,
        key: &str,
        nested_key: &str,
    ) -> Option<i64> {
        nested_object(object, key).and_then(|nested| match nested.get(nested_key) {
            Some(JsonValue::Number(value)) => Some(*value),
            _ => None,
        })
    }

    fn nested_bool(
        object: &BTreeMap<String, JsonValue>,
        key: &str,
        nested_key: &str,
    ) -> Option<bool> {
        nested_object(object, key).and_then(|nested| match nested.get(nested_key) {
            Some(JsonValue::Bool(value)) => Some(*value),
            _ => None,
        })
    }
}
