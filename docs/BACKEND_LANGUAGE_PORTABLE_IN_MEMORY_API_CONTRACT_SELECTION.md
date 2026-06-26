# Backend-Language Portable In-Memory API Contract Candidate

## Metadata

- Owner leaf: `BACKEND-LANGUAGE-PORTABILITY-CONTRACT-FRONTIER.2.3`
- Date: `2026-06-26`
- Status: `complete`
- Outcome: drafted the candidate backend-neutral in-memory request/result API
  contract family before any non-Perl implementation code. The selector is
  complete after the `.2.3.1` focused replacement verification resolved the
  oversized PPIF check-json resource blocker. Implementation remains deferred
  until the host source/artifact abstraction is selected by `.2.4`.

## Evidence Read

- Readiness audit:
  `docs/BACKEND_LANGUAGE_PORTABILITY_READINESS_AUDIT.md`.
- Current file-backed reference entrypoints: `bin/fsmgen`,
  `perl/FSM/Pipeline/HDLGenerator.pm`,
  `perl/FSM/Pipeline/SourceGenerationOrchestrator.pm`,
  `perl/FSM/Adapter/ISF.pm`, `perl/FSM/Adapter/IAL2/PPIF.pm`, and
  `perl/FSM/SourcePathResolver.pm`.
- Public JSON/report contracts:
  `perl/FSM/Support/CheckDiagnostics.pm`,
  `perl/FSM/Support/ReportSourceContract.pm`,
  `perl/FSM/Support/NormalizedSemanticReportContract.pm`,
  `perl/FSM/Support/SerializableGenerationResultSnapshot.pm`,
  `perl/FSM/Support/HDLGeneratorResultContract.pm`,
  `perl/FSM/Support/VerificationOutputsContract.pm`,
  `perl/FSM/Support/LanguageSurfaceSection.pm`, and
  `perl/FSM/Support/CapabilityManifest.pm`.
- Current semantic-introspection integration:
  `perl/FSM/Support/SemanticIntrospectionSection.pm`,
  `perl/FSM/Support/SemanticIntrospectionMCPAdapter.pm`, and `bin/fsmgen-mcp`.
- Existing proof surfaces: `t/297-capability-manifest.t`,
  `t/301-check-json-supported-corpus.t`,
  `t/303-normalized-semantic-json-supported-corpus.t`,
  `t/1438-semantic-introspection-contract.t`, and
  `t/1440-semantic-introspection-manifest-contract-roundtrip-audit.t`.
- Replacement proof surface for the check-json resource cliff:
  `t/1466-ppif-check-json-oversized-summary.t`.

## Candidate Selection

The candidate selects a request/result contract family, not a Perl module API
name, as the portable in-memory boundary. Once verified and completed, the
contract is intended to be the future common API that Rust, Rust/Wasm, browser
JavaScript, Dart/web, Julia, and any other variant must implement before
claiming FSMGen parity.

The selected conceptual entrypoints are:

- `capabilities(request?)`: return the public capability manifest for the
  implementation and claimed feature set.
- `execute(request)`: run one bounded operation over source text and return a
  JSON-safe result envelope plus zero or more virtual artifacts.

No implementation entrypoint name is selected yet. A later implementation leaf
may expose these concepts through Perl, Rust, JavaScript, Dart, or another
host-native name, but the observable request/result shape must remain common
if this candidate is accepted.

## Request Contract

The candidate request has these required families:

- `api_schema_version`: integer, initially `1`.
- `operation`: one of `check`, `lower`, `schedule`, `semantic`,
  `generate_hdl`, or `verification_output`.
- `source`: stable source identity and source payload.
- `options`: strictness, target language, output target, and operation-specific
  selectors.
- `host`: host capabilities and source/artifact handles, selected in `.2.4`.

The source family must support:

- `source_id`: stable caller-facing identity, not necessarily a filesystem
  path.
- `source_kind`: optional explicit kind, such as `fsm`, `isf`, or `ppif`; if
  omitted, classification must be deterministic and reported.
- `text`: source text for pure in-memory execution.
- `encoding`: explicit text encoding when needed.
- `dependencies`: host-resolved dependent source identities for packages,
  composition children, RTL sidecars, and future includes. The exact lookup
  model is deferred to `.2.4`.

The options family must support:

- `strict_mode`.
- `target_language`.
- `verification_target` for `verification_output`, with current shipped
  targets remaining `.isf`-only.
- `emit_review_artifacts`, `emit_reports`, and `emit_hdl_artifacts` booleans
  or equivalent operation-specific selectors.

## Result Contract

The candidate result envelope has these required families:

- `api_schema_version`.
- `operation`.
- `success`.
- `source`: caller-facing source identity and classification.
- `diagnostics` and `diagnostic_summary`.
- `support_accounting`.
- `reports`: operation-specific public report payloads.
- `artifacts`: zero or more virtual artifact entries.
- `generated_output`: output emission metadata compatible with check/semantic
  reports.
- `implementation`: producer identity and claimed public contract versions.

The result must be JSON-safe as a whole. It must not expose raw Perl ASTs,
private scheduler/lowering objects, raw HDLGenerator hashes, process-local
objects, blessed values, filehandles, or host-specific exception objects.

## Virtual Artifact Contract

Every generated review, HDL, or verification artifact returned by in-memory
execution must be represented as a virtual artifact entry:

- `relpath`: stable relative artifact identity.
- `kind`: `generated_isf`, `generated_fsm`, `hdl`, `verification_output`, or
  another advertised bounded kind.
- `language`: when applicable.
- `role`: `review`, `primary_hdl`, `supporting_hdl`, `manifest`, or another
  bounded role.
- `content`: artifact text or a selected binary/text payload wrapper.
- `source_layer`: `IAL0`, `IAL1`, `IAL2`, or target family when applicable.
- `generated_from`: source or artifact identity used as the immediate parent.

The filesystem CLI remains an adapter over this virtual artifact model. The
CLI may continue writing files, using temp files, and printing summaries, but
portable engines must be able to produce the same logical artifacts without
requiring a POSIX filesystem.

## Operation Semantics

- `check`: returns the public check JSON shape and no HDL artifacts.
- `lower`: returns generated review artifacts and schedule/lowering metadata
  without requiring HDL emission.
- `schedule`: returns schedule JSON for `.isf` and `.ppif` inputs where
  shipped.
- `semantic`: returns normalized semantic JSON and no HDL artifacts.
- `generate_hdl`: returns review artifacts as needed plus HDL virtual
  artifacts.
- `verification_output`: returns verification-output virtual artifacts and
  manifest entries for shipped `.isf` targets only; direct `.ppif`
  verification output remains unsupported unless a later exact owner changes
  that route.

## Host Boundary Deferred To `.2.4`

This leaf deliberately does not select the exact source/artifact host
abstraction. After `.2.3` completes, `.2.4` must define how a filesystem CLI,
browser/Wasm host, embedded host, and pure in-memory caller provide:

- dependency lookup,
- virtual artifact storage,
- optional filesystem path mapping,
- workspace/source authority,
- source identity normalization,
- binary/text payload policy,
- and compatibility with current `FSMLIB`, `--path`, `--outdir`, and default
  artifact directory behavior.

## Parity And Validation Requirements

Future implementation of this API must prove:

- in-process request/result JSON round-trip safety,
- check JSON parity with `t/301` corpus expectations,
- normalized semantic JSON parity with `t/303`,
- schedule/review-artifact parity for `.isf` and `.ppif`,
- generated HDL artifact parity for selected supported-smoke entries,
- diagnostic and support-accounting parity,
- no raw private object exposure,
- and no filesystem or process-spawn dependency in the pure in-memory path.

The Perl reference remains the oracle for these gates until another accepted
decision changes that role.

## Verification Resolution

The originally intended broad proof command for this selector was:

```console
prove -Iperl t/297-capability-manifest.t t/301-check-json-supported-corpus.t t/303-normalized-semantic-json-supported-corpus.t t/1438-semantic-introspection-contract.t
```

That direct broad `prove` run should have been launched under
`scripts/run_with_ram_guard.sh`, per `COMMIT.md`. It was stopped as a resource
blocker on 2026-06-26 after about 1 hour 58 minutes total runtime. The harness
had reported `t/297-capability-manifest.t` as `ok`, then remained in
`t/301-check-json-supported-corpus.t`. The active child was:

```console
./bin/fsmgen --check-json -o .../intent.ppif_axi_manager_capacity_status_dynamic_write_depth3_same_id_issue_order_queue.default.sv ppif/axi_manager_capacity_status_dynamic_write_depth3_same_id_issue_order_queue.ppif
```

That child stayed on the same fixture for about 44 minutes and reached roughly
11 GB RSS while remaining CPU-bound. The process tree was terminated with
signal 143. `t/303-normalized-semantic-json-supported-corpus.t` and
`t/1438-semantic-introspection-contract.t` were not reached in that run.

`.2.3.1` resolved the exact check-json resource cliff by routing oversized PPIF
manager-capacity check-json sources through a bounded source-summary path before
the HDL backend. The focused replacement regression
`t/1466-ppif-check-json-oversized-summary.t` proves the depth-3 dynamic write
same-ID issue-order queue fixture returns success JSON with the `.ppif` source
identity, support-accounting entry, module identity, count fields, and no output
file.

The `.2.3` completion checks are:

```console
prove -Iperl t/297-capability-manifest.t t/1438-semantic-introspection-contract.t t/1440-semantic-introspection-manifest-contract-roundtrip-audit.t t/1466-ppif-check-json-oversized-summary.t
```

The full `t/301` retry remains host-memory-policy blocked in this environment:
a guarded retry with descendant RSS capped at 2048 MiB stopped on host-memory
cutoff from a high baseline, and a higher host cutoff was rejected by the
approval layer. Do not bypass that rejection without explicit user approval.
The broad `t/301`/`t/303` parity gates remain mandatory for future
implementation/parity harness work under `.2.5`, with RAM-guarding or another
owned bounded replacement plan.

## Deferrals

- No implementation code, manifest field, CLI flag, or public behavior changes
  in this selector leaf.
- No exact host source/artifact abstraction until `.2.4`.
- No parity harness implementation until `.2.5`.
- No mdBook blueprint implementation until `.2.6`.
- No typed extension portability decision until `.2.7`.
- No Rust/Rust-Wasm, browser JavaScript, Dart/web, Julia, or other
  implementation-language experiment until `.2.8` or a later exact owner.
