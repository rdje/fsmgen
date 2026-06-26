# Backend-Language Portability Readiness Audit

## Metadata

- Owner leaf: `BACKEND-LANGUAGE-PORTABILITY-CONTRACT-FRONTIER.2.2`
- Date: `2026-06-26`
- Status: `complete`
- Outcome: public contracts and parity surfaces are strong enough to select
  future portability leaves, but the portable in-memory API and host
  abstraction contract are not selected yet.

## Evidence Read

- Doctrine and task ownership:
  `docs/decisions/0018-ial-contracts-are-backend-language-neutral.md`,
  `docs/tasks/BACKEND-LANGUAGE-PORTABILITY-CONTRACT-FRONTIER.md`,
  `docs/TASK_TREE.md`, `README.md`, `ROADMAP_V2.md`, and
  `docs/book/src/14-feature-backlog.md`.
- Public source and lowering surfaces: `bin/fsmgen`,
  `perl/FSM/Support/LanguageSurfaceSection.pm`,
  `perl/FSM/Adapter/ISF.pm`, `perl/FSM/Adapter/IAL2/PPIF.pm`,
  `perl/FSM/Pipeline/HDLGenerator.pm`,
  `perl/FSM/Pipeline/SourceGenerationOrchestrator.pm`,
  `perl/FSM/SourcePathResolver.pm`, `docs/ISF_PUBLIC_INTERFACE_CONTRACT.md`,
  and `docs/ISF_DOWNSTREAM_INTEGRATION_SPEC.md`.
- Manifest, report, semantic, support-accounting, and embedding surfaces:
  `perl/FSM/Support/CapabilityManifest.pm`,
  `perl/FSM/Support/LanguageSurfaceSection.pm`,
  `perl/FSM/Support/EmbeddingSection.pm`,
  `perl/FSM/Support/HDLGeneratorFacadeContract.pm`,
  `perl/FSM/Support/ReportSourceContract.pm`,
  `perl/FSM/Support/SemanticExportsSection.pm`,
  `perl/FSM/Support/NormalizedSemanticReportContract.pm`,
  `perl/FSM/Support/SupportAccountingSection.pm`, and
  `perl/FSM/Support/RegressionCorpus.pm`.
- Semantic-introspection/MCP surfaces:
  `docs/tasks/SEMANTIC-INTROSPECTION-MCP-FRONTIER.md`,
  `perl/FSM/Support/SemanticIntrospectionSection.pm`,
  `perl/FSM/Support/SemanticIntrospectionMCPAdapter.pm`, and
  `bin/fsmgen-mcp`.
- Test/proof surfaces: `t/297-capability-manifest.t`,
  `t/301-check-json-supported-corpus.t`,
  `t/303-normalized-semantic-json-supported-corpus.t`,
  `t/296-regression-corpus-supported-behavior.t`,
  `t/249-regression-corpus-classified-behavior.t`,
  `t/1438-semantic-introspection-contract.t`,
  `t/1440-semantic-introspection-manifest-contract-roundtrip-audit.t`,
  `t/1442-fsmgen-mcp-jsonrpc-cli.t`, MCP boundary tests in `t/145*.t` and
  `t/146*.t`, and the existing capability/embedding/semantic/support
  defensive-copy and JSON-round-trip audit families.

## Public Contract Boundary

The portable contract is the observable FSMGen behavior, not the Perl module
layout. The current backend-neutral public boundary is:

- Authored source syntax for `.fsm`, `.isf`, and `.ppif`.
- Lowering order and generated review artifacts: `.ppif -> generated .isf ->
  generated .fsm`, `.isf -> generated .fsm`, and direct `.fsm`.
- CLI modes advertised by `language_surface.file_surfaces`: HDL generation,
  `--outdir`, `--emit-schedule-json`, `--check-json`, `--emit-semantic-json`,
  `--verify-hdl`, and the `.isf`-only verification-output modes.
- Machine-readable reports: check JSON, schedule JSON, normalized semantic
  JSON, capability manifest, support-accounting catalog, diagnostic registry,
  and read-only semantic-introspection/MCP payloads.
- Generated outputs: review artifacts, SystemVerilog/Verilog/VHDL HDL outputs
  where shipped, verification-output artifacts where shipped, and manifests.
- The regression corpus and mdBook examples that prove user-visible behavior.

## Perl Implementation Details

These details are current reference implementation mechanics, not portable IAL
contract requirements:

- Perl package names, blessed hash/object receivers, constructor option-list
  mechanics, `confess` stack behavior, and owner-injection constructor seams.
- `FindBin`, `File::Spec`, `File::Temp`, `File::Path`, `Cwd`, `opendir`,
  POSIX-like readability checks, `FSMLIB`, `HOME` expansion, and current
  working-directory search.
- Process spawning through `IPC::Cmd` in tests and the MCP adapter's source
  query path.
- Perl module loading for typed extensions.
- Process-global debug state and trace-log file behavior.
- Raw private AST, scheduler, lowering, IR, and HDLGenerator result hashes
  that are explicitly not JSON-safe as whole objects.
- Temporary intermediate files used by the CLI when lowering `.isf` or `.ppif`
  without `--outdir`.

Future implementations may use any host-native representation for these
mechanics if the public source/report/diagnostic/artifact semantics match the
Perl reference.

## Readiness Findings

Ready for cross-implementation parity now:

- The capability manifest already groups public contract discovery under
  `language_surface`, `embedding`, `semantic_exports`,
  `semantic_introspection`, `support_accounting`, `diagnostics`,
  `backend_validation`, `verification_outputs`, and `documentation`.
- `t/297-capability-manifest.t` and the surrounding round-trip/defensive-copy
  test families prove large parts of the public JSON discovery surface.
- `t/301` and `t/303` prove check JSON and normalized semantic JSON over the
  supported corpus, including source identity and support-accounting matches.
- The semantic-introspection/MCP lane already selected stable semantic API
  first and read-only MCP adapter second.

Not ready without future exact leaves:

- There is no backend-neutral in-memory API contract yet. The current public
  facade is `FSM::Pipeline::HDLGenerator->generate_hdl_from_file($path)`,
  which is file-path based and Perl-specific.
- There is no selected virtual source/artifact store abstraction for browser,
  Wasm, embedded, or pure in-memory hosts.
- `.isf` and `.ppif` have `parse_source(...)` facades in Perl, but there is no
  unified language-neutral source-text-to-result contract spanning parse,
  check, lower, schedule, semantic export, HDL generation, and artifact
  capture.
- The MCP adapter is a read-only integration surface, not the portable core
  API. Source-bound MCP tools are intentionally workspace-root/file based and
  may shell out through the current reference implementation.
- Extension loading is a Perl module-loading contract today and needs a
  backend-neutral plugin/extension boundary before being portable.
- The mdBook is not yet a complete language-X implementation blueprint.

## Selected Future Contract Shape

The next portability work must define an in-memory execution contract before a
Rust/Rust-Wasm, browser JavaScript, Dart/web, Julia, or other non-Perl
implementation begins. That contract should cover:

- Input: source text bytes/string, a stable source identity, explicit source
  kind or deterministic source-kind classification, options for strict mode,
  target language, output selection, and host-provided dependency lookup.
- Host abstraction: virtual source catalog, virtual artifact sink, optional
  filesystem adapter for the CLI, and explicit absence of mandatory POSIX
  filesystem or process-spawn semantics.
- Results: structured success/failure envelopes, diagnostics, support
  accounting, generated review artifacts, schedule/check/semantic reports,
  HDL/verification artifacts, provenance, and manifest references.
- Error behavior: stable diagnostic codes and sanitized messages for public
  failures, with implementation-stack detail outside the public contract.
- Serialization: JSON-safe public report subsets with no raw private object
  exposure.

## Parity Harness Requirements

The Perl implementation remains the reference/oracle. Every future variant
must prove parity against it through at least:

- Capability-manifest section parity for the public sections a variant claims.
- Regression-corpus acceptance/failure parity, including supported smoke,
  strict-supported, and expected-failure entries.
- Check JSON and normalized semantic JSON parity after normalizing
  implementation-specific source paths where needed.
- Schedule JSON and generated review-artifact parity for `.isf` and `.ppif`.
- HDL output parity for selected language targets through stable formatting or
  normalized structural comparison.
- Diagnostic-code, support-accounting, and example-discovery parity.
- MCP/read-only semantic-introspection parity only where a variant ships that
  adapter surface.

## mdBook Blueprint Gaps

The mdBook needs a future language-independent implementation blueprint before
non-Perl work starts. The blueprint should document:

- Source grammars and layer order for IAL0/IAL1/IAL2 without relying on Perl
  parser internals.
- Public report schemas and generated artifact semantics.
- The selected in-memory API and host abstraction model.
- The Perl reference/oracle parity harness and expected normalization rules.
- Backend target responsibilities and validation boundaries.
- Extension/plugin portability rules.
- A language-X implementer checklist that does not require reading Perl as the
  only source of truth.

## SystemVerilog-To-Verilog Dependency Stance

The `.2.2` audit preserves the existing stance: FSMGen-owned generation and
lowering are the default. External converters such as `sv2v` remain optional
future validation candidates only, or selected dependencies only if a later
owned audit proves exceptional quality and coverage.

## Selected Future Leaves

- `BACKEND-LANGUAGE-PORTABILITY-CONTRACT-FRONTIER.2.3`: select the portable
  in-memory API contract before any non-Perl implementation code.
- `BACKEND-LANGUAGE-PORTABILITY-CONTRACT-FRONTIER.2.4`: select the host
  source/artifact abstraction for filesystem, browser, Wasm, embedded, and
  pure in-memory hosts.
- `BACKEND-LANGUAGE-PORTABILITY-CONTRACT-FRONTIER.2.5`: select the Perl-oracle
  parity harness and normalization rules.
- `BACKEND-LANGUAGE-PORTABILITY-CONTRACT-FRONTIER.2.6`: select the mdBook
  language-X implementation blueprint structure.
- `BACKEND-LANGUAGE-PORTABILITY-CONTRACT-FRONTIER.2.7`: audit typed extension
  and plugin portability before any non-Perl extension API is selected.
- `BACKEND-LANGUAGE-PORTABILITY-CONTRACT-FRONTIER.2.8`: select the first
  implementation-language experiment only after `.2.3` through `.2.7` have
  bounded the API, host abstraction, parity, docs, and extension risks.

This audit changes documentation and task routing only. It does not change
source syntax, parser behavior, lowering, generated artifacts, CLI behavior,
manifest content, support accounting, semantic JSON, MCP behavior, tests, or
HDL output.
