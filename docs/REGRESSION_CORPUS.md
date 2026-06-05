# Regression Corpus

This note is the human-readable companion to the machine-checked regression
catalog in [perl/FSM/Support/RegressionCorpus.pm](perl/FSM/Support/RegressionCorpus.pm).
The older [t/lib/FSM/Test/RegressionCorpus.pm](t/lib/FSM/Test/RegressionCorpus.pm)
path is now only a thin compatibility wrapper for tests or local scripts that
still import the former test package name.

The point of `R12` is not just to collect examples. It is to make support
claims auditable:

- named corpus entries exist,
- each entry has an explicit classification,
- each entry has an explicit coverage bucket,
- and only regression-backed assets count toward support claims.

Catalog entries are contract entries, not necessarily one-to-one file names.
The same repo asset may appear more than once when FSMGen intentionally carries
more than one contract for it, for example:

- default-mode compatibility retention,
- and strict-mode expected rejection.

## Classification buckets

- `supported_smoke`: the asset is counted as supported for the bounded coverage
  actually exercised by the regression suite.
- `expected_failure`: the asset is intentionally rejected, and the rejection is
  part of the supported contract. Each expected-failure entry must record a
  stable `diagnostic_code` from
  [perl/FSM/Support/DiagnosticCodes.pm](perl/FSM/Support/DiagnosticCodes.pm)
  plus a compiled `expected_error_pattern`. Strict-rejection expected failures
  must also record a compiled `expected_hint_pattern` so compatibility cuts keep
  an actionable migration path.
- `legacy_out_of_scope`: the asset is retained as a known historical or
  exploratory input, but it does not count toward current support claims.

## Coverage buckets

Each coverage bucket belongs to exactly one classification. The
catalog-accounting test checks this matrix directly, so a future entry cannot
claim `supported_smoke` while using a legacy or expected-failure coverage bucket,
or claim `expected_failure` while using a default-compatible coverage bucket.

- `direct_root_pipeline_cli`: the entry must compile through both the pipeline
  API and the CLI as a direct root.
- `composition_top_pipeline_cli`: the entry must compile through both the
  pipeline API and the CLI as a composition top, including its realized child
  path.
- `legacy_root_default_pipeline_cli`: the entry is retained as a compatibility
  asset and must still compile through both the pipeline API and the CLI in
  default mode.
- `legacy_section_default_pipeline_cli`: the entry is retained as a
  compatibility residue asset and must still compile through both the pipeline
  API and the CLI in default mode even though it is not part of the preferred
  authored surface.
- `legacy_assignment_default_pipeline_cli`: the entry is retained as an
  assignment-surface compatibility residue asset and must still compile through
  both the pipeline API and the CLI in default mode even though the canonical
  assignment pair form is the preferred authored surface.
- `legacy_child_root_default_pipeline_cli`: the entry is retained as a child-
  realization compatibility residue asset and must still compile through both
  the pipeline API and the CLI in default mode, including any extra source
  search roots needed to realize the child.
- `legacy_composition_default_pipeline_cli`: the entry is retained as a
  composition-surface compatibility residue asset and must still compile
  through both the pipeline API and the CLI in default mode even though the
  canonical composition form is preferred for new authored sources.
- `strict_root_rejection_pipeline_cli`: the entry is intentionally rejected in
  strict mode through both the pipeline API and the CLI, and that rejection is
  part of the supported contract.
- `strict_section_rejection_pipeline_cli`: the entry is intentionally rejected
  in strict mode through both the pipeline API and the CLI because it relies on
  compatibility residue at the section level, and that rejection is part of the
  supported contract.
- `strict_assignment_rejection_pipeline_cli`: the entry is intentionally
  rejected in strict mode through both the pipeline API and the CLI because it
  relies on assignment-surface compatibility residue, and that rejection is part
  of the supported contract.
- `strict_child_root_rejection_pipeline_cli`: the entry is intentionally
  rejected in strict mode through both the pipeline API and the CLI because it
  relies on compatibility residue at the generated-child source-root boundary,
  and that rejection is part of the supported contract.
- `strict_composition_rejection_pipeline_cli`: the entry is intentionally
  rejected in strict mode through both the pipeline API and the CLI because it
  relies on composition-surface compatibility residue, and that rejection is
  part of the supported contract.
- `language_contract_rejection_pipeline_cli`: the entry is intentionally
  rejected by the normal language-contract boundary through both the pipeline
  API and the CLI, and that rejection is part of the supported contract. This
  bucket now includes malformed `+size` entries and non-positive resolved
  `+size` expression widths, plus unresolved or non-scalar symbols inside
  `+size` expressions, divide/modulo-by-zero width arithmetic, unsupported
  width operators or malformed operator arity, unsupported top-level source,
  directive, or body forms, legacy generic/template placeholders, and bare
  condition suffixes. It also covers malformed top-level source roots,
  malformed action and guard forms, malformed test branches, malformed test
  selectors, duplicate default test-selector branches, and malformed `+system`
  sections such as missing clock entries, duplicate clock/reset entries,
  malformed entry structures, invalid clock/reset
  identifiers, malformed direct/composition source names, malformed structured
  `?fsm` root bodies and body items, malformed state or standalone-DT names,
  malformed empty state/standalone-DT bodies, malformed transition targets,
  unknown transition targets, unsupported RHS expression operators, malformed
  RHS expression arity, guard-only tokens in RHS value position, malformed
  guard shorthand payloads, and malformed inline comparison tokens. It also
  covers malformed delayed-pulse RHS values and delayed-pulse LHS targets,
  mixed combinational/sequential assignment families, mixed pulse and
  non-pulse sequential writes, multiple pulse delays for one signal,
  combinational self-dependency, D-input self-dependency, unsupported
  assignment operators, unsupported compact `:=` reset values, malformed `:=`
  directive payloads, unsupported compact `:=` directive shapes, empty
  symbol-definition sections,
  malformed symbol-definition entries, unresolved `+params` value names,
  ambiguous bare bitstring-like `+constants` / `+params` values, cyclic
  `+params` dependency graphs, duplicate `+params` declarations, aggregate
  `+params` expression mixed operands, shape mismatches, overflow, underflow,
  and divide-by-zero, malformed symbol identifiers, non-scalar enum member
  values, malformed legacy `+fsm` root bodies, malformed plain test-signal
  names, malformed computed test selectors, malformed inline compound modifier
  payloads, duplicate inline compound modifiers, malformed update-shorthand
  targets, and malformed update-shorthand tails.

The historical sample `fsm/generic_fifo.fsm` is cataloged as
`contract.generic_fifo_define_template_source` in the language-contract
expected-failure bucket. Its current first stable boundary is the unsupported
top-level `?define:generic_fifo` root; the later `?&generic_fifo` macro
instantiations, bracket placeholders, and `?repeat` forms belong to the same
broader legacy template dialect and are not interpreted by the active parser.

- `direct_generation_contract_rejection_pipeline_cli`: the entry is
  intentionally rejected by the normal direct-generation contract through both
  the pipeline API and the CLI after parsing succeeds but before HDL is emitted,
  and that rejection is part of the supported contract.
- `composition_contract_rejection_pipeline_cli`: the entry is intentionally
  rejected by the normal composition contract through both the pipeline API and
  the CLI, and that rejection is part of the supported contract. This bucket
  now covers malformed child-entry structure, non-string child headers,
  dotted-pair child payloads, unsupported child kinds, legacy `?ports` mapping
  directives, duplicate top ports, duplicate child instance names, missing
  external generated-child source lookup, multiple `?ports` blocks, omitted
  `?ports` outside inferable lanes, empty `?ports` outside inferable lanes,
  unsupported VHDL composition backend targets, missing explicit `?wiring` in
  explicit-link topologies, C1 passthrough missing exposure, unknown top-port,
  width mismatch, and direction mismatch failures, declared same-name on shared
  system ports, child aggregate-member endpoints without declared aggregate
  types, malformed verbose `?ports` declarations, invalid `?ports` tokens,
  non-positive `?ports` widths, malformed `?wiring` list-form endpoints,
  unsupported `?wiring` tokens, malformed top `+constants` identifiers,
  non-literal top `+enums` values, wrong-kind external generated-child source realization for both
  `?fsmc` and `?dtc`, malformed generated-child source counts, malformed
  nested generated-child payload shapes, malformed external RTL child source
  counts, malformed nested external RTL child payload shapes, missing external
  `?rtl` sidecar metadata, invalid `.rtlif` system-role
  directions, duplicate `.rtlif` port
  declarations, unsupported `.rtlif` port types, invalid `.rtlif` port tokens,
  non-positive `.rtlif` port widths, missing `.rtlif` roots, empty `.rtlif`
  roots, unsupported nested `.rtlif` structures, and duplicate embedded
  `.rtlif` roots.

The historical sample `fsm/trial_2.fsm` is cataloged as
`contract.trial_2_ports_mapping_directive` in the composition-contract
expected-failure bucket. Its current first stable boundary is the legacy
`/data_o/{tasu_timestamp, tasu_pl_data}/` mapping directive inside `?ports`;
that keeps it out of the external-validation smoke until a future owner takes
on the broader legacy composition dialect.

The historical sample `fsm/lte_digital_rf.fsm` is cataloged as
`contract.lte_digital_rf_rtl_child_source_count` in the same bucket. Its current
first stable boundary is the legacy `?rtl:lte_dif_iosocket` child carrying 36
flat RTL module references; the active composition parser accepts one semantic
module reference per `?rtl` child instead.

## Supported-success markers

Every `supported_smoke` entry is executable at the catalog level: it must
compile through both the default pipeline API and default `bin/fsmgen`,
preserving the recorded semantic HDL shape. Some `supported_smoke` entries also
carry a `strict_supported` marker in the machine-readable catalog. That marker
is not a replacement coverage bucket. It means the same supported fixture must
also compile through both the strict pipeline API and `bin/fsmgen --strict`.
Both success contracts are run by
[t/296-regression-corpus-supported-behavior.t](t/296-regression-corpus-supported-behavior.t)
regardless of fixture family, so future protocol, language-feature,
composition, or other supported entries cannot rely only on family-specific
tests.

Supported direct language-feature entries have one extra rule: compile success
alone is not enough. Each `language_feature_fixture` / `supported_smoke` /
`direct_root_pipeline_cli` entry must record at least one compiled
`expected_hdl_patterns` regular expression. The catalog-accounting test checks
that shape metadata exists and is well formed, and the behavior tests execute
those patterns against generated HDL. This keeps feature support claims tied to
observable emitted semantics rather than only "the tool did not crash."

## Diagnostic code ownership

Stable diagnostic identities now have a production owner:
[perl/FSM/Support/DiagnosticCodes.pm](perl/FSM/Support/DiagnosticCodes.pm).
Every current `expected_failure` corpus entry carries one `FSMGEN_*`
diagnostic code, and
[t/248-regression-corpus-accounting.t](t/248-regression-corpus-accounting.t)
checks that the code is known and maps to stable error-severity metadata. The
same test also rejects unused registry entries so the public code list stays
exercised by the corpus.

The bounded check-only JSON path now consumes the same registry:

```bash
./bin/fsmgen --strict --check --json path/to/file.fsm
```

That command runs the full pipeline as a check, writes no HDL, emits
schema-versioned JSON to stdout, and exits non-zero on failed checks. When the
failure matches a support-accounting expected-failure entry, the JSON diagnostic
includes the stable `FSMGEN_*` code plus severity/stability/family metadata and
the matched corpus entry. The diagnostic also contains a nested
`support_accounting` object with the matched entry id, corpus family, coverage
bucket, classification, diagnostic code, and migration-hint availability.
Unclassified failures still emit JSON, but with a `null` code rather than
inventing a fake stable identity.

[t/300-check-json-regression-corpus.t](t/300-check-json-regression-corpus.t)
locks this bridge across every current `expected_failure` entry. The classifier
must choose the most specific matching expected-error pattern, so broad boundary
patterns such as generic malformed `+size` failures cannot shadow narrower
stable codes such as divide-by-zero or unsupported-operator diagnostics.

[t/301-check-json-supported-corpus.t](t/301-check-json-supported-corpus.t)
locks the accepted side of the same command surface. Every current
`supported_smoke` entry must succeed through `--check-json`, and every current
`strict_supported` entry must succeed through `--strict --check-json`, while
emitting decodable success JSON, keeping diagnostics empty, writing no HDL, and
preserving the expected checked module/top identity. Corpus-backed successful
reports must also include a report-level `support_accounting` object with the
matched entry id, family, coverage bucket, classification, source kind, and
`strict_supported` marker.

[t/312-check-diagnostics-contract.t](t/312-check-diagnostics-contract.t)
locks the bounded public key-presence promise for that same command surface.
[perl/FSM/Support/CheckDiagnosticsContract.pm](perl/FSM/Support/CheckDiagnosticsContract.pm)
is now the explicit owner for the common top-level keys plus the bounded
success-result, success support-accounting, and failure-diagnostic key lists
advertised through `--capability-manifest`.
[perl/FSM/Support/ReportProducerContract.pm](perl/FSM/Support/ReportProducerContract.pm)
now owns the shared nested `producer` object shape reused by both check JSON
and normalized semantic JSON.
[perl/FSM/Support/ReportSourceContract.pm](perl/FSM/Support/ReportSourceContract.pm)
now owns the shared nested `source` object shape reused by both check JSON and
normalized semantic JSON.
[perl/FSM/Support/ReportCommandContract.pm](perl/FSM/Support/ReportCommandContract.pm)
now owns the shared nested `command` object shape reused by both check JSON
and normalized semantic JSON.
[perl/FSM/Support/ReportGeneratedOutputContract.pm](perl/FSM/Support/ReportGeneratedOutputContract.pm)
now owns the shared nested `generated_output` object shape reused by both
check JSON and normalized semantic JSON.
[perl/FSM/Support/CheckResultContract.pm](perl/FSM/Support/CheckResultContract.pm)
now owns the success-only nested `result` object shape emitted by public check
JSON.
[perl/FSM/Support/CheckFailureDiagnosticContract.pm](perl/FSM/Support/CheckFailureDiagnosticContract.pm)
now owns the shared nested failure `diagnostic` object shape emitted by public
check JSON and public normalized semantic JSON, including the published
matched-only, optional-artifact, and nested support-accounting key lists.
[perl/FSM/Support/NormalizedSemanticPayloadContract.pm](perl/FSM/Support/NormalizedSemanticPayloadContract.pm)
now owns the success-only nested `semantic` object shape emitted by public
normalized semantic JSON, including the published nested
`explicit_system_contract`, `system_contract`, `forward_ir`, and optional
`symbol_contract` plus `composition` key lists.
[perl/FSM/Support/NormalizedSemanticSignalAnalysisContract.pm](perl/FSM/Support/NormalizedSemanticSignalAnalysisContract.pm)
now owns the nested `semantic.signal_analysis` object shape emitted by
successful public normalized semantic JSON, including the published
signal-analysis key family and the shared core signal-entry key family used by
both direct and composition roots.
[perl/FSM/Support/NormalizedSemanticExplicitSystemContract.pm](perl/FSM/Support/NormalizedSemanticExplicitSystemContract.pm)
now owns the nested `semantic.explicit_system_contract` object shape when
successful public normalized semantic JSON preserves the authored explicit
system contract, including the published explicit-system-contract key family.
[perl/FSM/Support/NormalizedSemanticSystemContract.pm](perl/FSM/Support/NormalizedSemanticSystemContract.pm)
now owns the nested `semantic.system_contract` object shape emitted by
successful public normalized semantic JSON, including the published
system-contract key family.
[perl/FSM/Support/NormalizedSemanticForwardIRContract.pm](perl/FSM/Support/NormalizedSemanticForwardIRContract.pm)
now owns the nested `semantic.forward_ir` object shape emitted by successful
public normalized semantic JSON, including the published forward-IR key
family.
[perl/FSM/Support/NormalizedSemanticLoweredRTLIRContract.pm](perl/FSM/Support/NormalizedSemanticLoweredRTLIRContract.pm)
now owns the nested `semantic.forward_ir.lowered_rtl_ir` object shape emitted
by successful public normalized semantic JSON, including the published core
lowered-RTL keys plus the composition-only extension-key family.
[perl/FSM/Support/NormalizedSemanticStructuralRTLIRContract.pm](perl/FSM/Support/NormalizedSemanticStructuralRTLIRContract.pm)
now owns the nested `semantic.forward_ir.structural_rtl_ir` object shape
emitted by successful public normalized semantic JSON, including the published
structural-RTL key family shared by direct and composition roots.
[perl/FSM/Support/NormalizedSemanticIntentHIRContract.pm](perl/FSM/Support/NormalizedSemanticIntentHIRContract.pm)
now owns the nested `semantic.forward_ir.intent_hir` object shape emitted by
successful public normalized semantic JSON, including the published core
intent-hir keys plus the composition-only extension-key family.
[perl/FSM/Support/NormalizedSemanticSymbolContract.pm](perl/FSM/Support/NormalizedSemanticSymbolContract.pm)
now owns the optional nested `semantic.symbol_contract` object shape emitted
by successful public normalized semantic JSON for symbol-rich sources,
including the published symbol-contract key family.
[perl/FSM/Support/NormalizedSemanticModuleContract.pm](perl/FSM/Support/NormalizedSemanticModuleContract.pm)
now owns the nested `semantic.module` object shape emitted by successful
public normalized semantic JSON, including the published core module-summary
keys plus the optional metric-key family.
[perl/FSM/Support/NormalizedSemanticCompositionContract.pm](perl/FSM/Support/NormalizedSemanticCompositionContract.pm)
now owns the nested `semantic.composition` object shape emitted by successful
public normalized semantic JSON composition sources, including the published
composition key family while keeping nested provenance-report ownership split
through [perl/FSM/Support/CompositionReportContract.pm](perl/FSM/Support/CompositionReportContract.pm).
[perl/FSM/Support/SupportAccountingMatchContract.pm](perl/FSM/Support/SupportAccountingMatchContract.pm)
now owns the shared nested `support_accounting` match-object shape reused by
both check JSON and normalized semantic JSON.

The first bounded normalized semantic JSON path reuses the same
support-accounting bridge for accepted corpus sources:

```bash
./bin/fsmgen --strict --emit-semantic-json path/to/file.fsm
```

[t/302-normalized-semantic-json.t](t/302-normalized-semantic-json.t)
locks direct and composition corpus-backed success examples, no-HDL emission,
and strict rejected-source diagnostics for that semantic export. Successful
semantic reports expose sanitized module/system/signal and forward-IR metadata,
while matched corpus sources report the same entry id, family, coverage bucket,
classification, source kind, and `strict_supported` support-accounting bridge.
Those same semantic reports also reuse the shared bounded nested `producer`
object owner in
[perl/FSM/Support/ReportProducerContract.pm](perl/FSM/Support/ReportProducerContract.pm),
so the public producer identity and `semantic_layers` shape stays aligned with
check JSON where the fields overlap.
Those same semantic reports also reuse the shared bounded nested `source`
object owner in
[perl/FSM/Support/ReportSourceContract.pm](perl/FSM/Support/ReportSourceContract.pm),
so the public input/resolved-path shape stays aligned with check JSON.
Those same semantic reports also reuse the shared bounded nested `command`
object owner in
[perl/FSM/Support/ReportCommandContract.pm](perl/FSM/Support/ReportCommandContract.pm),
so the public invocation metadata shape stays aligned with check JSON too.
Those same semantic reports also reuse the shared bounded nested
`generated_output` object owner in
[perl/FSM/Support/ReportGeneratedOutputContract.pm](perl/FSM/Support/ReportGeneratedOutputContract.pm),
so the public “did this report emit HDL” shape stays aligned with check JSON
too.

[t/314-support-accounting-contract.t](t/314-support-accounting-contract.t)
locks the bounded public contract for the manifest's `support_accounting`
section.
[perl/FSM/Support/SupportAccountingContract.pm](perl/FSM/Support/SupportAccountingContract.pm)
is now the explicit owner for the bounded top-level support-accounting keys,
bucket/id-list keys, and sanitized catalog-entry required/optional key lists
advertised through `--capability-manifest`.
That same owner is now also advertised through
`support_accounting.section_contract`, so the manifest keeps one regular
section-contract discovery path without removing the existing inline
support-accounting payload fields.

[t/303-normalized-semantic-json-supported-corpus.t](t/303-normalized-semantic-json-supported-corpus.t)
locks the accepted side across the whole current supported corpus. Every current
`supported_smoke` entry must succeed through `--emit-semantic-json`, and every
current `strict_supported` entry must succeed through
`--strict --emit-semantic-json`, while emitting decodable semantic JSON, keeping
diagnostics empty, writing no HDL, preserving matched support-accounting
identity, omitting generated HDL text/raw ASTs, and exposing the expected
module/top identity through `semantic.module`, `intent_hir`, and
`structural_rtl_ir`.

[t/304-normalized-semantic-json-regression-corpus.t](t/304-normalized-semantic-json-regression-corpus.t)
locks the rejected side across the whole current expected-failure corpus. Every
current `expected_failure` entry must reject through `--emit-semantic-json`,
using the same strict/default routing as check JSON, while emitting decodable
failure JSON, keeping stderr clean, writing no HDL, omitting partial semantic
payloads, and preserving the exact stable diagnostic code plus matched
support-accounting identity promised by the corpus.

The optional external SystemVerilog validation lane is covered by
[t/308-systemverilog-external-validation.t](t/308-systemverilog-external-validation.t).
When `verilator` and `yosys` are installed, that smoke generates
`fsm/lte_dif_pmaster.fsm`, `fsm/mipicsi2_byteserial.fsm`,
`fsm/mipicsi2_configreg.fsm`, `fsm/mipicsi2_fifo_4x8.fsm`,
`fsm/mipicsi2_laned_clog.fsm`, `fsm/mipicsi2_laned_sctrl.fsm`,
`fsm/mipicsi2_pkt_nx4B_fifo.fsm`, `fsm/mipicsi2_rxccore_hs.fsm`,
`fsm/mipicsi2_rxdcore_hs.fsm`, `fsm/mipicsi2_tester_ctrl.fsm`,
`fsm/mipicsi2_txccore_hs.fsm`, `fsm/mipicsi2_txccore_ulp.fsm`,
`fsm/mipicsi2_txdcore_hs.fsm`, `fsm/mipicsi2_txdcore_lp.fsm`,
`fsm/mipicsi2_txtimer.fsm`, and `fsm/mipicsi2_xgamaster.fsm`, the
warning-clean historical direct samples
`fsm/trial_0.fsm` and `fsm/trial_1.fsm`, plus every supported direct protocol
actor from the corpus (`fsm/apb_requester.fsm`, `fsm/apb_completer.fsm`, and
`fsm/amba_requester.fsm` today), and every supported composition protocol
fixture (`fsm/apb_tb.fsm` today), validates the emitted `.sv` files with
Verilator `--lint-only --sv`, validates ABC-free Yosys structural synthesis
with `read_verilog -sv -noautowire`, `synth -noabc -top`, and `stat`, and
proves the CLI `--verify-hdl` lane invokes the same external gates. Verilator
is the generated-SystemVerilog validity gate; Yosys is the structural-netlist
sanity gate. ABC is intentionally disabled until a future lane handles
ABC-specific timeout and mapping edge cases. The support surface can report an
optional ABC mapping executable candidate (`yosys-abc`, `berkeley-abc`, or
`abc`) for contract visibility, but that candidate is not required and is not
run by the external validation smoke. When the required tools are absent, the
test skips rather than making the baseline Perl regression suite depend on
local EDA installs.

[t/313-hdl-external-validation-contract.t](t/313-hdl-external-validation-contract.t)
locks the bounded public contract for that lane.
[perl/FSM/Support/HDLExternalValidationContract.pm](perl/FSM/Support/HDLExternalValidationContract.pm)
is now the explicit owner for the command shape, tool identities, stage names,
and bounded success top-level/step key lists advertised through
`--capability-manifest`.
The manifest's `backend_validation` section now has the same bounded contract
split through
[perl/FSM/Support/BackendValidationContract.pm](perl/FSM/Support/BackendValidationContract.pm).
[t/323-backend-validation-contract.t](t/323-backend-validation-contract.t)
locks the published top-level and nested contract-owner map for both
in-process and CLI manifest output while leaving deeper validation-lane
semantics with the narrower external validation contract.

[t/310-systemverilog-implicit-width-and-truthiness-hardening.t](t/310-systemverilog-implicit-width-and-truthiness-hardening.t)
locks the non-tool-specific side of that hardening: static RHS slices infer
base widths, explicit selectors and guards infer tested/counter widths,
multibit truthiness emits width-safe reductions in one-bit enable expressions,
AST-backed arithmetic intermediates keep recovered result widths instead of
falling back to one bit, and runtime arithmetic rendering preserves
right-nested same-precedence grouping such as modulo over a product.

[t/02-combinational-self-dependency.t](t/02-combinational-self-dependency.t)
now also locks the parser-side safety rail for D-input-named sequential
assignments: `<=` and `<=-` may not read the same LHS name from the RHS or
assignment guard, because that creates combinational feedback before HDL
emission. In default mode, legacy `<=+` is accepted as an alias for `<=-` and
follows the same rule; in strict mode, `<=+` is rejected with a migration hint
toward preferred `<=-`. Q/output-named `<-` loopback remains supported for
ordinary register feedback.

[t/1348-self-dependency-diagnostic-cleanup.t](t/1348-self-dependency-diagnostic-cleanup.t)
locks the user-facing diagnostic shape for
[t/corpus/assignment_comb_self_dependency.fsm](t/corpus/assignment_comb_self_dependency.fsm):
quiet CLI, check JSON, and normalized semantic JSON must reject before HDL
emission while preserving source context, the dependency path, the stable
`FSMGEN_LANGUAGE_COMBINATIONAL_SELF_DEPENDENCY` code, and the remediation hint
without exposing parser implementation names or Perl stack frames.

[t/1349-d-input-self-dependency-diagnostic-cleanup.t](t/1349-d-input-self-dependency-diagnostic-cleanup.t)
locks the same public diagnostic boundary for D-input self-dependency. It
covers the regression-corpus RHS fixture plus a guard-expression fixture across
quiet CLI, check JSON, and normalized semantic JSON, preserving the stable
`FSMGEN_LANGUAGE_D_INPUT_SELF_DEPENDENCY` code and remediation text without
leaking parser implementation names or Perl stack frames.

All current supported protocol fixtures are now `strict_supported`: the APB
requester, APB completer, AMBA requester, and APB composition top use the
canonical `areset rst_n`, `(:= (signal value))`, and assignment-pair surfaces
and must pass both default and strict pipeline/CLI smoke. All current supported
language-feature fixtures are also `strict_supported`. That means strict mode
positively accepts the maintained fixtures for partial LHS writes using
preferred `<=-` dual-output syntax, RHS concat/cat packing, LHS concat/cat
deconstruction, canonical reset spellings, canonical init/default metadata,
expression-backed widths, runtime div/mod expressions, canonical assignment
pairs, update-shorthand `+=` / `-=` variants, regular-state header DTE guards,
guard shorthand, relational operator chains and word aliases, and intent-level
integer literal normalization on both direct and composition paths. Computed
test selectors and relational test-branch selectors are also covered as
supported direct selector surfaces. Legacy `<=+` compatibility is tracked
separately through paired default-compatible and strict-rejected corpus entries.
Legacy composition `?wiring` slash-link tokens follow the same accounting
shape: default mode still compiles `/source/target/`, while strict mode rejects
that token family with a migration hint toward `(source target)` or
`(connect source target)`.

## Capability manifest

Downstream tools can ask FSMGen for the first bounded machine-readable support
surface without providing an input `.fsm` file:

```bash
./bin/fsmgen --capability-manifest
```

That command emits schema-versioned JSON built by
[perl/FSM/Support/CapabilityManifest.pm](perl/FSM/Support/CapabilityManifest.pm)
from the same production corpus owner used by the regression tests. The first
manifest is intentionally bounded: it exposes support-accounting counts,
sanitized corpus entry metadata including expected-failure diagnostic codes,
the stable diagnostic-code registry, the bounded check-JSON command contract,
the check-JSON support-accounting object contracts for matched failures and
matched accepted corpus entries,
the bounded normalized semantic JSON command contract,
the optional external SystemVerilog Verilator/Yosys validation command
contract,
the supported-smoke / strict-supported / expected-failure check-JSON coverage
flags,
the supported-smoke / strict-supported / expected-failure normalized semantic
JSON coverage flags,
the bounded normalized semantic key-presence contract advertised through
[perl/FSM/Support/NormalizedSemanticReportContract.pm](perl/FSM/Support/NormalizedSemanticReportContract.pm),
the bounded in-process `HDLGenerator` result top-level presence contract,
the bounded sanitized composition provenance/report fragment exported through
normalized semantic JSON,
the bounded typed-extension/context contract for explicit object/module/config
loading and the shipped hook/accessor names,
strict-versus-compatibility language surface families, current
assignment/system/expression/declaration/composition families, producer
version/commit identity, documentation pointers, and intentionally blocked or
not-yet-public integration surfaces such as full check-JSON schema
stabilization and broader normalized semantic JSON export beyond the current
bounded slice.
The stable diagnostic-code registry portion of that manifest now has an
explicit public contract owner too:
[perl/FSM/Support/DiagnosticCodeRegistryContract.pm](perl/FSM/Support/DiagnosticCodeRegistryContract.pm).
[t/315-diagnostic-code-registry-contract.t](t/315-diagnostic-code-registry-contract.t)
locks that sibling-key and stable-entry-key promise for both in-process and
CLI manifest output.
The manifest shell itself now has that same explicit public contract owner:
[perl/FSM/Support/CapabilityManifestContract.pm](perl/FSM/Support/CapabilityManifestContract.pm).
[t/316-capability-manifest-contract.t](t/316-capability-manifest-contract.t)
locks the bounded top-level and first nested section key presence for both
in-process and CLI manifest output.
That shell contract now also explicitly includes the first nested
`support_accounting` key list, so the corpus-backed section is covered by the
same manifest-shell discovery promise as the other bounded public sections.
The manifest's `embedding` section now has the same bounded contract split
through
[perl/FSM/Support/EmbeddingContract.pm](perl/FSM/Support/EmbeddingContract.pm).
[t/321-embedding-contract.t](t/321-embedding-contract.t)
locks the published top-level plus nested contract-owner map for both
in-process and CLI manifest output while leaving narrower result/report/typed
extension details with their dedicated contracts.
The manifest's `diagnostics` section now has the same bounded contract split
through
[perl/FSM/Support/DiagnosticsContract.pm](perl/FSM/Support/DiagnosticsContract.pm).
[t/320-diagnostics-contract.t](t/320-diagnostics-contract.t)
locks the published top-level plus stable-code entry families for both
in-process and CLI manifest output while leaving narrower registry/check JSON
details with their dedicated contracts.
The manifest's `producer` section now has the same bounded contract split
through
[perl/FSM/Support/ProducerContract.pm](perl/FSM/Support/ProducerContract.pm).
[t/319-producer-contract.t](t/319-producer-contract.t)
locks the published top-level, scalar-string, and boolean identity/build keys
for both in-process and CLI manifest output without pretending the section is
already a broader release API.
The manifest's `semantic_exports` section now has the same bounded contract
split through
[perl/FSM/Support/SemanticExportsContract.pm](perl/FSM/Support/SemanticExportsContract.pm).
[t/322-semantic-exports-contract.t](t/322-semantic-exports-contract.t)
locks the published top-level and nested contract-owner map for both
in-process and CLI manifest output while leaving deeper semantic payload
meaning with narrower export/report contracts.
The manifest's `language_surface` section now has the same bounded contract
split through
[perl/FSM/Support/LanguageSurfaceContract.pm](perl/FSM/Support/LanguageSurfaceContract.pm).
[t/317-language-surface-contract.t](t/317-language-surface-contract.t)
locks the published top-level and first nested section-key presence for both
in-process and CLI manifest output without claiming the whole authored
language is frozen.
The manifest's `documentation` section now has the same bounded contract split
through
[perl/FSM/Support/DocumentationContract.pm](perl/FSM/Support/DocumentationContract.pm).
[t/318-documentation-contract.t](t/318-documentation-contract.t)
locks the published top-level and path-list fields for both in-process and CLI
manifest output while keeping the exact file lists widenable.

## Current named entries

| ID | File | Classification | Coverage |
| --- | --- | --- | --- |
| `protocol.apb_requester` | [fsm/apb_requester.fsm](fsm/apb_requester.fsm) | `supported_smoke` | `direct_root_pipeline_cli` |
| `protocol.apb_completer` | [fsm/apb_completer.fsm](fsm/apb_completer.fsm) | `supported_smoke` | `direct_root_pipeline_cli` |
| `protocol.amba_requester` | [fsm/amba_requester.fsm](fsm/amba_requester.fsm) | `supported_smoke` | `direct_root_pipeline_cli` |
| `protocol.apb_tb` | [fsm/apb_tb.fsm](fsm/apb_tb.fsm) | `supported_smoke` | `composition_top_pipeline_cli` |
| `feature.partial_lhs_with_size` | [t/corpus/partial_lhs_with_size.fsm](t/corpus/partial_lhs_with_size.fsm) | `supported_smoke` | `direct_root_pipeline_cli` |
| `feature.partial_lhs_inferred_width` | [t/corpus/partial_lhs_inferred_width.fsm](t/corpus/partial_lhs_inferred_width.fsm) | `supported_smoke` | `direct_root_pipeline_cli` |
| `feature.direct_rhs_concat_pack` | [t/corpus/direct_rhs_concat_pack.fsm](t/corpus/direct_rhs_concat_pack.fsm) | `supported_smoke` | `direct_root_pipeline_cli` |
| `feature.direct_rhs_concat_target_autogrowth` | [t/corpus/direct_rhs_concat_target_autogrowth.fsm](t/corpus/direct_rhs_concat_target_autogrowth.fsm) | `supported_smoke` | `direct_root_pipeline_cli` |
| `feature.direct_lhs_deconstruct_pack` | [t/corpus/direct_lhs_deconstruct_pack.fsm](t/corpus/direct_lhs_deconstruct_pack.fsm) | `supported_smoke` | `direct_root_pipeline_cli` |
| `feature.direct_sreset_active_high` | [t/corpus/direct_sreset_active_high.fsm](t/corpus/direct_sreset_active_high.fsm) | `supported_smoke` | `direct_root_pipeline_cli` |
| `feature.custom_system_clock` | [t/corpus/custom_system_clock.fsm](t/corpus/custom_system_clock.fsm) | `supported_smoke` | `direct_root_pipeline_cli` |
| `feature.implicit_system_defaults` | [t/corpus/implicit_system_defaults.fsm](t/corpus/implicit_system_defaults.fsm) | `supported_smoke` | `direct_root_pipeline_cli` |
| `feature.direct_areset_active_low` | [t/corpus/direct_areset_active_low.fsm](t/corpus/direct_areset_active_low.fsm) | `supported_smoke` | `direct_root_pipeline_cli` |
| `feature.reset_state_aliases` | [t/corpus/reset_state_aliases.fsm](t/corpus/reset_state_aliases.fsm) | `supported_smoke` | `direct_root_pipeline_cli` |
| `feature.direct_canonical_init_directive` | [t/corpus/direct_canonical_init_directive.fsm](t/corpus/direct_canonical_init_directive.fsm) | `supported_smoke` | `direct_root_pipeline_cli` |
| `feature.direct_size_expression_widths` | [t/corpus/direct_size_expression_widths.fsm](t/corpus/direct_size_expression_widths.fsm) | `supported_smoke` | `direct_root_pipeline_cli` |
| `feature.declarative_bits_symbol_widths` | [t/corpus/declarative_bits_symbol_widths.fsm](t/corpus/declarative_bits_symbol_widths.fsm) | `supported_smoke` | `direct_root_pipeline_cli` |
| `feature.direct_aggregate_constant_target_autogrowth` | [t/corpus/direct_aggregate_constant_target_autogrowth.fsm](t/corpus/direct_aggregate_constant_target_autogrowth.fsm) | `supported_smoke` | `direct_root_pipeline_cli` |
| `feature.direct_runtime_div_mod` | [t/corpus/direct_runtime_div_mod.fsm](t/corpus/direct_runtime_div_mod.fsm) | `supported_smoke` | `direct_root_pipeline_cli` |
| `feature.params_aggregate_unary_complement` | [t/corpus/params_aggregate_unary_complement.fsm](t/corpus/params_aggregate_unary_complement.fsm) | `supported_smoke` | `direct_root_pipeline_cli` |
| `feature.arithmetic_xor_operator_variants` | [t/corpus/arithmetic_xor_operator_variants.fsm](t/corpus/arithmetic_xor_operator_variants.fsm) | `supported_smoke` | `direct_root_pipeline_cli` |
| `feature.rhs_expression_supported_variants` | [t/corpus/rhs_expression_supported_variants.fsm](t/corpus/rhs_expression_supported_variants.fsm) | `supported_smoke` | `direct_root_pipeline_cli` |
| `feature.direct_assignment_pair_form` | [t/corpus/direct_assignment_pair_form.fsm](t/corpus/direct_assignment_pair_form.fsm) | `supported_smoke` | `direct_root_pipeline_cli` |
| `feature.update_shorthand_variants` | [t/corpus/update_shorthand_variants.fsm](t/corpus/update_shorthand_variants.fsm) | `supported_smoke` | `direct_root_pipeline_cli` |
| `feature.compound_update_variants` | [t/corpus/compound_update_variants.fsm](t/corpus/compound_update_variants.fsm) | `supported_smoke` | `direct_root_pipeline_cli` |
| `feature.state_dte_guards` | [t/corpus/state_dte_guards.fsm](t/corpus/state_dte_guards.fsm) | `supported_smoke` | `direct_root_pipeline_cli` |
| `feature.standalone_dt_guards` | [t/corpus/standalone_dt_guards.fsm](t/corpus/standalone_dt_guards.fsm) | `supported_smoke` | `direct_root_pipeline_cli` |
| `feature.standalone_dt_explicit_system` | [t/corpus/standalone_dt_explicit_system.fsm](t/corpus/standalone_dt_explicit_system.fsm) | `supported_smoke` | `direct_root_pipeline_cli` |
| `feature.guard_shorthand` | [t/corpus/guard_shorthand.fsm](t/corpus/guard_shorthand.fsm) | `supported_smoke` | `direct_root_pipeline_cli` |
| `feature.nested_compound_guards` | [t/corpus/nested_compound_guards.fsm](t/corpus/nested_compound_guards.fsm) | `supported_smoke` | `direct_root_pipeline_cli` |
| `feature.relational_operator_chains` | [t/corpus/relational_operator_chains.fsm](t/corpus/relational_operator_chains.fsm) | `supported_smoke` | `direct_root_pipeline_cli` |
| `feature.computed_test_selector` | [t/corpus/computed_test_selector.fsm](t/corpus/computed_test_selector.fsm) | `supported_smoke` | `direct_root_pipeline_cli` |
| `feature.computed_comparison_selector` | [t/corpus/computed_comparison_selector.fsm](t/corpus/computed_comparison_selector.fsm) | `supported_smoke` | `direct_root_pipeline_cli` |
| `feature.plain_test_signal_selectors` | [t/corpus/plain_test_signal_selectors.fsm](t/corpus/plain_test_signal_selectors.fsm) | `supported_smoke` | `direct_root_pipeline_cli` |
| `feature.test_selector_symbolic_default` | [t/corpus/test_selector_symbolic_default.fsm](t/corpus/test_selector_symbolic_default.fsm) | `supported_smoke` | `direct_root_pipeline_cli` |
| `feature.test_branch_selectors` | [t/corpus/test_branch_selectors.fsm](t/corpus/test_branch_selectors.fsm) | `supported_smoke` | `direct_root_pipeline_cli` |
| `feature.direct_intent_integer_literals` | [t/corpus/direct_intent_integer_literals.fsm](t/corpus/direct_intent_integer_literals.fsm) | `supported_smoke` | `direct_root_pipeline_cli` |
| `feature.composition_intent_integer_literals` | [t/corpus/composition_intent_integer_literals.fsm](t/corpus/composition_intent_integer_literals.fsm) | `supported_smoke` | `composition_top_pipeline_cli` |
| `feature.implicit_composition_system_autowire` | [t/corpus/implicit_composition_system_autowire.fsm](t/corpus/implicit_composition_system_autowire.fsm) | `supported_smoke` | `composition_top_pipeline_cli` |
| `feature.standalone_dtc_explicit_system_autowire` | [t/corpus/standalone_dtc_explicit_system_autowire.fsm](t/corpus/standalone_dtc_explicit_system_autowire.fsm) | `supported_smoke` | `composition_top_pipeline_cli` |
| `legacy.mipicsi2_txccore_ulp.default_compat` | [fsm/mipicsi2_txccore_ulp.fsm](fsm/mipicsi2_txccore_ulp.fsm) | `legacy_out_of_scope` | `legacy_root_default_pipeline_cli` |
| `legacy.mipicsi2_txccore_ulp.strict_rejection` | [fsm/mipicsi2_txccore_ulp.fsm](fsm/mipicsi2_txccore_ulp.fsm) | `expected_failure` | `strict_root_rejection_pipeline_cli` |
| `legacy.empty_size_noop.default_compat` | [t/corpus/legacy_empty_size_noop.fsm](t/corpus/legacy_empty_size_noop.fsm) | `legacy_out_of_scope` | `legacy_section_default_pipeline_cli` |
| `legacy.empty_size_noop.strict_rejection` | [t/corpus/legacy_empty_size_noop.fsm](t/corpus/legacy_empty_size_noop.fsm) | `expected_failure` | `strict_section_rejection_pipeline_cli` |
| `legacy.asreset_rstn.default_compat` | [t/corpus/legacy_asreset_rstn.fsm](t/corpus/legacy_asreset_rstn.fsm) | `legacy_out_of_scope` | `legacy_section_default_pipeline_cli` |
| `legacy.asreset_rstn.strict_rejection` | [t/corpus/legacy_asreset_rstn.fsm](t/corpus/legacy_asreset_rstn.fsm) | `expected_failure` | `strict_section_rejection_pipeline_cli` |
| `legacy.sreset_rstn.default_compat` | [t/corpus/legacy_sreset_rstn.fsm](t/corpus/legacy_sreset_rstn.fsm) | `legacy_out_of_scope` | `legacy_section_default_pipeline_cli` |
| `legacy.sreset_rstn.strict_rejection` | [t/corpus/legacy_sreset_rstn.fsm](t/corpus/legacy_sreset_rstn.fsm) | `expected_failure` | `strict_section_rejection_pipeline_cli` |
| `legacy.compact_init_directive.default_compat` | [t/corpus/legacy_compact_init_directive.fsm](t/corpus/legacy_compact_init_directive.fsm) | `legacy_out_of_scope` | `legacy_section_default_pipeline_cli` |
| `legacy.compact_init_directive.strict_rejection` | [t/corpus/legacy_compact_init_directive.fsm](t/corpus/legacy_compact_init_directive.fsm) | `expected_failure` | `strict_section_rejection_pipeline_cli` |
| `legacy.infix_assignment.default_compat` | [t/corpus/legacy_infix_assignment.fsm](t/corpus/legacy_infix_assignment.fsm) | `legacy_out_of_scope` | `legacy_assignment_default_pipeline_cli` |
| `legacy.infix_assignment.strict_rejection` | [t/corpus/legacy_infix_assignment.fsm](t/corpus/legacy_infix_assignment.fsm) | `expected_failure` | `strict_assignment_rejection_pipeline_cli` |
| `legacy.lteplus_assignment.default_compat` | [t/corpus/legacy_lteplus_assignment.fsm](t/corpus/legacy_lteplus_assignment.fsm) | `legacy_out_of_scope` | `legacy_assignment_default_pipeline_cli` |
| `legacy.lteplus_assignment.strict_rejection` | [t/corpus/legacy_lteplus_assignment.fsm](t/corpus/legacy_lteplus_assignment.fsm) | `expected_failure` | `strict_assignment_rejection_pipeline_cli` |
| `legacy.fsm_child_root.default_compat` | [t/corpus/legacy_fsm_child_root_top.fsm](t/corpus/legacy_fsm_child_root_top.fsm) | `legacy_out_of_scope` | `legacy_child_root_default_pipeline_cli` |
| `legacy.fsm_child_root.strict_rejection` | [t/corpus/legacy_fsm_child_root_top.fsm](t/corpus/legacy_fsm_child_root_top.fsm) | `expected_failure` | `strict_child_root_rejection_pipeline_cli` |
| `legacy.dt_child_root.default_compat` | [t/corpus/legacy_dt_child_root_top.fsm](t/corpus/legacy_dt_child_root_top.fsm) | `legacy_out_of_scope` | `legacy_child_root_default_pipeline_cli` |
| `legacy.dt_child_root.strict_rejection` | [t/corpus/legacy_dt_child_root_top.fsm](t/corpus/legacy_dt_child_root_top.fsm) | `expected_failure` | `strict_child_root_rejection_pipeline_cli` |
| `legacy.composition_wiring_slash.default_compat` | [t/corpus/legacy_composition_wiring_slash_top.fsm](t/corpus/legacy_composition_wiring_slash_top.fsm) | `legacy_out_of_scope` | `legacy_composition_default_pipeline_cli` |
| `legacy.composition_wiring_slash.strict_rejection` | [t/corpus/legacy_composition_wiring_slash_top.fsm](t/corpus/legacy_composition_wiring_slash_top.fsm) | `expected_failure` | `strict_composition_rejection_pipeline_cli` |
| `contract.language_contract_bad_size_entry` | [t/corpus/language_contract_bad_size_entry.fsm](t/corpus/language_contract_bad_size_entry.fsm) | `expected_failure` | `language_contract_rejection_pipeline_cli` |
| `contract.direct_size_expression_non_positive` | [t/corpus/direct_size_expression_non_positive.fsm](t/corpus/direct_size_expression_non_positive.fsm) | `expected_failure` | `language_contract_rejection_pipeline_cli` |
| `contract.direct_size_expression_unknown_symbol` | [t/corpus/direct_size_expression_unknown_symbol.fsm](t/corpus/direct_size_expression_unknown_symbol.fsm) | `expected_failure` | `language_contract_rejection_pipeline_cli` |
| `contract.direct_size_expression_aggregate_symbol` | [t/corpus/direct_size_expression_aggregate_symbol.fsm](t/corpus/direct_size_expression_aggregate_symbol.fsm) | `expected_failure` | `language_contract_rejection_pipeline_cli` |
| `contract.direct_size_expression_divide_by_zero` | [t/corpus/direct_size_expression_divide_by_zero.fsm](t/corpus/direct_size_expression_divide_by_zero.fsm) | `expected_failure` | `language_contract_rejection_pipeline_cli` |
| `contract.direct_size_expression_modulo_by_zero` | [t/corpus/direct_size_expression_modulo_by_zero.fsm](t/corpus/direct_size_expression_modulo_by_zero.fsm) | `expected_failure` | `language_contract_rejection_pipeline_cli` |
| `contract.direct_size_expression_unsupported_operator` | [t/corpus/direct_size_expression_unsupported_operator.fsm](t/corpus/direct_size_expression_unsupported_operator.fsm) | `expected_failure` | `language_contract_rejection_pipeline_cli` |
| `contract.direct_size_expression_bad_arity` | [t/corpus/direct_size_expression_bad_arity.fsm](t/corpus/direct_size_expression_bad_arity.fsm) | `expected_failure` | `language_contract_rejection_pipeline_cli` |
| `contract.direct_runtime_divide_literal_zero` | [t/corpus/direct_runtime_divide_literal_zero.fsm](t/corpus/direct_runtime_divide_literal_zero.fsm) | `expected_failure` | `language_contract_rejection_pipeline_cli` |
| `contract.direct_runtime_modulo_exact_zero` | [t/corpus/direct_runtime_modulo_exact_zero.fsm](t/corpus/direct_runtime_modulo_exact_zero.fsm) | `expected_failure` | `language_contract_rejection_pipeline_cli` |
| `contract.direct_lhs_deconstruct_width_mismatch` | [t/corpus/direct_lhs_deconstruct_width_mismatch.fsm](t/corpus/direct_lhs_deconstruct_width_mismatch.fsm) | `expected_failure` | `language_contract_rejection_pipeline_cli` |
| `contract.unsupported_top_level_define_source` | [t/corpus/unsupported_top_level_define_source.fsm](t/corpus/unsupported_top_level_define_source.fsm) | `expected_failure` | `language_contract_rejection_pipeline_cli` |
| `contract.generic_fifo_define_template_source` | [fsm/generic_fifo.fsm](fsm/generic_fifo.fsm) | `expected_failure` | `language_contract_rejection_pipeline_cli` |
| `contract.unsupported_top_level_clock_directive` | [t/corpus/unsupported_top_level_clock_directive.fsm](t/corpus/unsupported_top_level_clock_directive.fsm) | `expected_failure` | `language_contract_rejection_pipeline_cli` |
| `contract.unsupported_top_level_infix_init_form` | [t/corpus/unsupported_top_level_infix_init_form.fsm](t/corpus/unsupported_top_level_infix_init_form.fsm) | `expected_failure` | `language_contract_rejection_pipeline_cli` |
| `contract.unsupported_top_level_bare_scalar_form` | [t/corpus/unsupported_top_level_bare_scalar_form.fsm](t/corpus/unsupported_top_level_bare_scalar_form.fsm) | `expected_failure` | `language_contract_rejection_pipeline_cli` |
| `contract.generic_placeholder_selector` | [t/corpus/generic_placeholder_selector.fsm](t/corpus/generic_placeholder_selector.fsm) | `expected_failure` | `language_contract_rejection_pipeline_cli` |
| `contract.generic_repeat_macro` | [t/corpus/generic_repeat_macro.fsm](t/corpus/generic_repeat_macro.fsm) | `expected_failure` | `language_contract_rejection_pipeline_cli` |
| `contract.generic_placeholder_token` | [t/corpus/generic_placeholder_token.fsm](t/corpus/generic_placeholder_token.fsm) | `expected_failure` | `language_contract_rejection_pipeline_cli` |
| `contract.bare_assignment_condition_suffix` | [t/corpus/bare_assignment_condition_suffix.fsm](t/corpus/bare_assignment_condition_suffix.fsm) | `expected_failure` | `language_contract_rejection_pipeline_cli` |
| `contract.bare_transition_condition_suffix` | [t/corpus/bare_transition_condition_suffix.fsm](t/corpus/bare_transition_condition_suffix.fsm) | `expected_failure` | `language_contract_rejection_pipeline_cli` |
| `contract.malformed_top_level_system_root` | [t/corpus/malformed_top_level_system_root.fsm](t/corpus/malformed_top_level_system_root.fsm) | `expected_failure` | `language_contract_rejection_pipeline_cli` |
| `contract.malformed_single_token_action` | [t/corpus/malformed_single_token_action.fsm](t/corpus/malformed_single_token_action.fsm) | `expected_failure` | `language_contract_rejection_pipeline_cli` |
| `contract.malformed_empty_guard` | [t/corpus/malformed_empty_guard.fsm](t/corpus/malformed_empty_guard.fsm) | `expected_failure` | `language_contract_rejection_pipeline_cli` |
| `contract.malformed_empty_test_branch` | [t/corpus/malformed_empty_test_branch.fsm](t/corpus/malformed_empty_test_branch.fsm) | `expected_failure` | `language_contract_rejection_pipeline_cli` |
| `contract.malformed_bare_symbolic_test_selector` | [t/corpus/malformed_bare_symbolic_test_selector.fsm](t/corpus/malformed_bare_symbolic_test_selector.fsm) | `expected_failure` | `language_contract_rejection_pipeline_cli` |
| `contract.malformed_bare_numeric_test_selector` | [t/corpus/malformed_bare_numeric_test_selector.fsm](t/corpus/malformed_bare_numeric_test_selector.fsm) | `expected_failure` | `language_contract_rejection_pipeline_cli` |
| `contract.test_selector_duplicate_default` | [t/corpus/test_selector_duplicate_default.fsm](t/corpus/test_selector_duplicate_default.fsm) | `expected_failure` | `language_contract_rejection_pipeline_cli` |
| `contract.system_incomplete_section` | [t/corpus/system_incomplete_section.fsm](t/corpus/system_incomplete_section.fsm) | `expected_failure` | `language_contract_rejection_pipeline_cli` |
| `contract.system_duplicate_clock_entry` | [t/corpus/system_duplicate_clock_entry.fsm](t/corpus/system_duplicate_clock_entry.fsm) | `expected_failure` | `language_contract_rejection_pipeline_cli` |
| `contract.system_duplicate_reset_declaration` | [t/corpus/system_duplicate_reset_declaration.fsm](t/corpus/system_duplicate_reset_declaration.fsm) | `expected_failure` | `language_contract_rejection_pipeline_cli` |
| `contract.system_malformed_entry_structure` | [t/corpus/system_malformed_entry_structure.fsm](t/corpus/system_malformed_entry_structure.fsm) | `expected_failure` | `language_contract_rejection_pipeline_cli` |
| `contract.system_bad_clock_identifier` | [t/corpus/system_bad_clock_identifier.fsm](t/corpus/system_bad_clock_identifier.fsm) | `expected_failure` | `language_contract_rejection_pipeline_cli` |
| `contract.system_bad_reset_identifier` | [t/corpus/system_bad_reset_identifier.fsm](t/corpus/system_bad_reset_identifier.fsm) | `expected_failure` | `language_contract_rejection_pipeline_cli` |
| `contract.malformed_fsm_source_name` | [t/corpus/malformed_fsm_source_name.fsm](t/corpus/malformed_fsm_source_name.fsm) | `expected_failure` | `language_contract_rejection_pipeline_cli` |
| `contract.malformed_empty_fsm_root_body` | [t/corpus/malformed_empty_fsm_root_body.fsm](t/corpus/malformed_empty_fsm_root_body.fsm) | `expected_failure` | `language_contract_rejection_pipeline_cli` |
| `contract.malformed_scalar_fsm_root_body_item` | [t/corpus/malformed_scalar_fsm_root_body_item.fsm](t/corpus/malformed_scalar_fsm_root_body_item.fsm) | `expected_failure` | `language_contract_rejection_pipeline_cli` |
| `contract.malformed_top_source_name` | [t/corpus/malformed_top_source_name.fsm](t/corpus/malformed_top_source_name.fsm) | `expected_failure` | `language_contract_rejection_pipeline_cli` |
| `contract.malformed_state_name` | [t/corpus/malformed_state_name.fsm](t/corpus/malformed_state_name.fsm) | `expected_failure` | `language_contract_rejection_pipeline_cli` |
| `contract.malformed_standalone_dt_name` | [t/corpus/malformed_standalone_dt_name.fsm](t/corpus/malformed_standalone_dt_name.fsm) | `expected_failure` | `language_contract_rejection_pipeline_cli` |
| `contract.malformed_empty_state_body` | [t/corpus/malformed_empty_state_body.fsm](t/corpus/malformed_empty_state_body.fsm) | `expected_failure` | `language_contract_rejection_pipeline_cli` |
| `contract.malformed_empty_standalone_dt_body` | [t/corpus/malformed_empty_standalone_dt_body.fsm](t/corpus/malformed_empty_standalone_dt_body.fsm) | `expected_failure` | `language_contract_rejection_pipeline_cli` |
| `contract.malformed_transition_target` | [t/corpus/malformed_transition_target.fsm](t/corpus/malformed_transition_target.fsm) | `expected_failure` | `language_contract_rejection_pipeline_cli` |
| `contract.unknown_transition_target` | [t/corpus/unknown_transition_target.fsm](t/corpus/unknown_transition_target.fsm) | `expected_failure` | `language_contract_rejection_pipeline_cli` |
| `contract.rhs_expression_unsupported_operator` | [t/corpus/rhs_expression_unsupported_operator.fsm](t/corpus/rhs_expression_unsupported_operator.fsm) | `expected_failure` | `language_contract_rejection_pipeline_cli` |
| `contract.rhs_expression_bad_arity` | [t/corpus/rhs_expression_bad_arity.fsm](t/corpus/rhs_expression_bad_arity.fsm) | `expected_failure` | `language_contract_rejection_pipeline_cli` |
| `contract.rhs_expression_guard_token` | [t/corpus/rhs_expression_guard_token.fsm](t/corpus/rhs_expression_guard_token.fsm) | `expected_failure` | `language_contract_rejection_pipeline_cli` |
| `contract.condition_guard_payload_missing_rhs` | [t/corpus/condition_guard_payload_missing_rhs.fsm](t/corpus/condition_guard_payload_missing_rhs.fsm) | `expected_failure` | `language_contract_rejection_pipeline_cli` |
| `contract.condition_guard_payload_missing_lhs` | [t/corpus/condition_guard_payload_missing_lhs.fsm](t/corpus/condition_guard_payload_missing_lhs.fsm) | `expected_failure` | `language_contract_rejection_pipeline_cli` |
| `contract.condition_inline_comparison_missing_rhs` | [t/corpus/condition_inline_comparison_missing_rhs.fsm](t/corpus/condition_inline_comparison_missing_rhs.fsm) | `expected_failure` | `language_contract_rejection_pipeline_cli` |
| `contract.condition_inline_comparison_missing_lhs` | [t/corpus/condition_inline_comparison_missing_lhs.fsm](t/corpus/condition_inline_comparison_missing_lhs.fsm) | `expected_failure` | `language_contract_rejection_pipeline_cli` |
| `contract.assignment_delayed_pulse_bad_rhs` | [t/corpus/assignment_delayed_pulse_bad_rhs.fsm](t/corpus/assignment_delayed_pulse_bad_rhs.fsm) | `expected_failure` | `language_contract_rejection_pipeline_cli` |
| `contract.delayed_pulse_lhs_index` | [t/corpus/delayed_pulse_lhs_index.fsm](t/corpus/delayed_pulse_lhs_index.fsm) | `expected_failure` | `language_contract_rejection_pipeline_cli` |
| `contract.delayed_pulse_lhs_range` | [t/corpus/delayed_pulse_lhs_range.fsm](t/corpus/delayed_pulse_lhs_range.fsm) | `expected_failure` | `language_contract_rejection_pipeline_cli` |
| `contract.delayed_pulse_lhs_pair_index` | [t/corpus/delayed_pulse_lhs_pair_index.fsm](t/corpus/delayed_pulse_lhs_pair_index.fsm) | `expected_failure` | `language_contract_rejection_pipeline_cli` |
| `contract.assignment_mixed_comb_seq` | [t/corpus/assignment_mixed_comb_seq.fsm](t/corpus/assignment_mixed_comb_seq.fsm) | `expected_failure` | `language_contract_rejection_pipeline_cli` |
| `contract.assignment_mixed_pulse_nonpulse` | [t/corpus/assignment_mixed_pulse_nonpulse.fsm](t/corpus/assignment_mixed_pulse_nonpulse.fsm) | `expected_failure` | `language_contract_rejection_pipeline_cli` |
| `contract.assignment_multiple_pulse_delays` | [t/corpus/assignment_multiple_pulse_delays.fsm](t/corpus/assignment_multiple_pulse_delays.fsm) | `expected_failure` | `language_contract_rejection_pipeline_cli` |
| `contract.assignment_comb_self_dependency` | [t/corpus/assignment_comb_self_dependency.fsm](t/corpus/assignment_comb_self_dependency.fsm) | `expected_failure` | `language_contract_rejection_pipeline_cli` |
| `contract.assignment_d_input_self_dependency` | [t/corpus/assignment_d_input_self_dependency.fsm](t/corpus/assignment_d_input_self_dependency.fsm) | `expected_failure` | `language_contract_rejection_pipeline_cli` |
| `contract.operator_unsupported_qeq` | [t/corpus/operator_unsupported_qeq.fsm](t/corpus/operator_unsupported_qeq.fsm) | `expected_failure` | `language_contract_rejection_pipeline_cli` |
| `contract.operator_unsupported_arrow` | [t/corpus/operator_unsupported_arrow.fsm](t/corpus/operator_unsupported_arrow.fsm) | `expected_failure` | `language_contract_rejection_pipeline_cli` |
| `contract.directive_init_placeholder_value` | [t/corpus/directive_init_placeholder_value.fsm](t/corpus/directive_init_placeholder_value.fsm) | `expected_failure` | `language_contract_rejection_pipeline_cli` |
| `contract.directive_init_guard_value` | [t/corpus/directive_init_guard_value.fsm](t/corpus/directive_init_guard_value.fsm) | `expected_failure` | `language_contract_rejection_pipeline_cli` |
| `contract.init_directive_payload_extra` | [t/corpus/init_directive_payload_extra.fsm](t/corpus/init_directive_payload_extra.fsm) | `expected_failure` | `language_contract_rejection_pipeline_cli` |
| `contract.init_directive_compact_broken` | [t/corpus/init_directive_compact_broken.fsm](t/corpus/init_directive_compact_broken.fsm) | `expected_failure` | `language_contract_rejection_pipeline_cli` |
| `contract.init_directive_canonical_missing_value` | [t/corpus/init_directive_canonical_missing_value.fsm](t/corpus/init_directive_canonical_missing_value.fsm) | `expected_failure` | `language_contract_rejection_pipeline_cli` |
| `contract.symbol_empty_constants_section` | [t/corpus/symbol_empty_constants_section.fsm](t/corpus/symbol_empty_constants_section.fsm) | `expected_failure` | `language_contract_rejection_pipeline_cli` |
| `contract.symbol_empty_define_directive` | [t/corpus/symbol_empty_define_directive.fsm](t/corpus/symbol_empty_define_directive.fsm) | `expected_failure` | `language_contract_rejection_pipeline_cli` |
| `contract.symbol_empty_params_section` | [t/corpus/symbol_empty_params_section.fsm](t/corpus/symbol_empty_params_section.fsm) | `expected_failure` | `language_contract_rejection_pipeline_cli` |
| `contract.symbol_empty_enums_section` | [t/corpus/symbol_empty_enums_section.fsm](t/corpus/symbol_empty_enums_section.fsm) | `expected_failure` | `language_contract_rejection_pipeline_cli` |
| `contract.symbol_bad_constants_entry` | [t/corpus/symbol_bad_constants_entry.fsm](t/corpus/symbol_bad_constants_entry.fsm) | `expected_failure` | `language_contract_rejection_pipeline_cli` |
| `contract.symbol_bad_define_entry` | [t/corpus/symbol_bad_define_entry.fsm](t/corpus/symbol_bad_define_entry.fsm) | `expected_failure` | `language_contract_rejection_pipeline_cli` |
| `contract.symbol_bad_params_entry` | [t/corpus/symbol_bad_params_entry.fsm](t/corpus/symbol_bad_params_entry.fsm) | `expected_failure` | `language_contract_rejection_pipeline_cli` |
| `contract.symbol_bad_enums_member` | [t/corpus/symbol_bad_enums_member.fsm](t/corpus/symbol_bad_enums_member.fsm) | `expected_failure` | `language_contract_rejection_pipeline_cli` |
| `contract.symbol_param_unresolved_value` | [t/corpus/symbol_param_unresolved_value.fsm](t/corpus/symbol_param_unresolved_value.fsm) | `expected_failure` | `language_contract_rejection_pipeline_cli` |
| `contract.symbol_constants_ambiguous_bitstring_value` | [t/corpus/symbol_constants_ambiguous_bitstring_value.fsm](t/corpus/symbol_constants_ambiguous_bitstring_value.fsm) | `expected_failure` | `language_contract_rejection_pipeline_cli` |
| `contract.symbol_params_ambiguous_bitstring_value` | [t/corpus/symbol_params_ambiguous_bitstring_value.fsm](t/corpus/symbol_params_ambiguous_bitstring_value.fsm) | `expected_failure` | `language_contract_rejection_pipeline_cli` |
| `contract.params_dependency_cycle` | [t/corpus/params_dependency_cycle.fsm](t/corpus/params_dependency_cycle.fsm) | `expected_failure` | `language_contract_rejection_pipeline_cli` |
| `contract.params_duplicate_declaration` | [t/corpus/params_duplicate_declaration.fsm](t/corpus/params_duplicate_declaration.fsm) | `expected_failure` | `language_contract_rejection_pipeline_cli` |
| `contract.params_aggregate_arithmetic_mixed_operand` | [t/corpus/params_aggregate_arithmetic_mixed_operand.fsm](t/corpus/params_aggregate_arithmetic_mixed_operand.fsm) | `expected_failure` | `language_contract_rejection_pipeline_cli` |
| `contract.params_aggregate_bitwise_mixed_operand` | [t/corpus/params_aggregate_bitwise_mixed_operand.fsm](t/corpus/params_aggregate_bitwise_mixed_operand.fsm) | `expected_failure` | `language_contract_rejection_pipeline_cli` |
| `contract.params_aggregate_shape_mismatch` | [t/corpus/params_aggregate_shape_mismatch.fsm](t/corpus/params_aggregate_shape_mismatch.fsm) | `expected_failure` | `language_contract_rejection_pipeline_cli` |
| `contract.params_aggregate_overflow` | [t/corpus/params_aggregate_overflow.fsm](t/corpus/params_aggregate_overflow.fsm) | `expected_failure` | `language_contract_rejection_pipeline_cli` |
| `contract.params_aggregate_underflow` | [t/corpus/params_aggregate_underflow.fsm](t/corpus/params_aggregate_underflow.fsm) | `expected_failure` | `language_contract_rejection_pipeline_cli` |
| `contract.params_aggregate_divide_by_zero` | [t/corpus/params_aggregate_divide_by_zero.fsm](t/corpus/params_aggregate_divide_by_zero.fsm) | `expected_failure` | `language_contract_rejection_pipeline_cli` |
| `contract.symbol_bad_constants_identifier` | [t/corpus/symbol_bad_constants_identifier.fsm](t/corpus/symbol_bad_constants_identifier.fsm) | `expected_failure` | `language_contract_rejection_pipeline_cli` |
| `contract.symbol_bad_define_identifier` | [t/corpus/symbol_bad_define_identifier.fsm](t/corpus/symbol_bad_define_identifier.fsm) | `expected_failure` | `language_contract_rejection_pipeline_cli` |
| `contract.symbol_bad_params_identifier` | [t/corpus/symbol_bad_params_identifier.fsm](t/corpus/symbol_bad_params_identifier.fsm) | `expected_failure` | `language_contract_rejection_pipeline_cli` |
| `contract.symbol_bad_enum_member_value` | [t/corpus/symbol_bad_enum_member_value.fsm](t/corpus/symbol_bad_enum_member_value.fsm) | `expected_failure` | `language_contract_rejection_pipeline_cli` |
| `contract.plus_fsm_empty_body` | [t/corpus/plus_fsm_empty_body.fsm](t/corpus/plus_fsm_empty_body.fsm) | `expected_failure` | `language_contract_rejection_pipeline_cli` |
| `contract.plus_fsm_scalar_body_item` | [t/corpus/plus_fsm_scalar_body_item.fsm](t/corpus/plus_fsm_scalar_body_item.fsm) | `expected_failure` | `language_contract_rejection_pipeline_cli` |
| `contract.test_signal_bad_hyphen` | [t/corpus/test_signal_bad_hyphen.fsm](t/corpus/test_signal_bad_hyphen.fsm) | `expected_failure` | `language_contract_rejection_pipeline_cli` |
| `contract.test_signal_numeric` | [t/corpus/test_signal_numeric.fsm](t/corpus/test_signal_numeric.fsm) | `expected_failure` | `language_contract_rejection_pipeline_cli` |
| `contract.computed_test_missing_expr` | [t/corpus/computed_test_missing_expr.fsm](t/corpus/computed_test_missing_expr.fsm) | `expected_failure` | `language_contract_rejection_pipeline_cli` |
| `contract.inline_modifier_malformed_payload` | [t/corpus/inline_modifier_malformed_payload.fsm](t/corpus/inline_modifier_malformed_payload.fsm) | `expected_failure` | `language_contract_rejection_pipeline_cli` |
| `contract.inline_modifier_duplicate` | [t/corpus/inline_modifier_duplicate.fsm](t/corpus/inline_modifier_duplicate.fsm) | `expected_failure` | `language_contract_rejection_pipeline_cli` |
| `contract.update_shorthand_nested_prefix_target` | [t/corpus/update_shorthand_nested_prefix_target.fsm](t/corpus/update_shorthand_nested_prefix_target.fsm) | `expected_failure` | `language_contract_rejection_pipeline_cli` |
| `contract.update_shorthand_nested_separated_target` | [t/corpus/update_shorthand_nested_separated_target.fsm](t/corpus/update_shorthand_nested_separated_target.fsm) | `expected_failure` | `language_contract_rejection_pipeline_cli` |
| `contract.update_shorthand_tail_single` | [t/corpus/update_shorthand_tail_single.fsm](t/corpus/update_shorthand_tail_single.fsm) | `expected_failure` | `language_contract_rejection_pipeline_cli` |
| `contract.update_shorthand_tail_multi` | [t/corpus/update_shorthand_tail_multi.fsm](t/corpus/update_shorthand_tail_multi.fsm) | `expected_failure` | `language_contract_rejection_pipeline_cli` |
| `contract.direct_rhs_concat_width_mismatch` | [t/corpus/direct_rhs_concat_width_mismatch.fsm](t/corpus/direct_rhs_concat_width_mismatch.fsm) | `expected_failure` | `direct_generation_contract_rejection_pipeline_cli` |
| `contract.direct_aggregate_contract_mismatch` | [t/corpus/direct_aggregate_contract_mismatch.fsm](t/corpus/direct_aggregate_contract_mismatch.fsm) | `expected_failure` | `direct_generation_contract_rejection_pipeline_cli` |
| `contract.composition_child_structure_empty_entry` | [t/corpus/composition_child_structure_empty_entry_top.fsm](t/corpus/composition_child_structure_empty_entry_top.fsm) | `expected_failure` | `composition_contract_rejection_pipeline_cli` |
| `contract.composition_child_header_nonstring` | [t/corpus/composition_child_structure_nonstring_header_top.fsm](t/corpus/composition_child_structure_nonstring_header_top.fsm) | `expected_failure` | `composition_contract_rejection_pipeline_cli` |
| `contract.composition_child_item_list_dotted_fsmc` | [t/corpus/composition_child_structure_dotted_fsmc_top.fsm](t/corpus/composition_child_structure_dotted_fsmc_top.fsm) | `expected_failure` | `composition_contract_rejection_pipeline_cli` |
| `contract.composition_child_item_list_dotted_wiring` | [t/corpus/composition_child_structure_dotted_wiring_top.fsm](t/corpus/composition_child_structure_dotted_wiring_top.fsm) | `expected_failure` | `composition_contract_rejection_pipeline_cli` |
| `contract.composition_child_item_list_dotted_ports` | [t/corpus/composition_child_structure_dotted_ports_top.fsm](t/corpus/composition_child_structure_dotted_ports_top.fsm) | `expected_failure` | `composition_contract_rejection_pipeline_cli` |
| `contract.composition_child_item_list_dotted_dtc` | [t/corpus/composition_child_structure_dotted_dtc_top.fsm](t/corpus/composition_child_structure_dotted_dtc_top.fsm) | `expected_failure` | `composition_contract_rejection_pipeline_cli` |
| `contract.composition_child_item_list_dotted_rtl` | [t/corpus/composition_child_structure_dotted_rtl_top.fsm](t/corpus/composition_child_structure_dotted_rtl_top.fsm) | `expected_failure` | `composition_contract_rejection_pipeline_cli` |
| `contract.composition_unsupported_child_kind` | [t/corpus/composition_unsupported_child_kind_top.fsm](t/corpus/composition_unsupported_child_kind_top.fsm) | `expected_failure` | `composition_contract_rejection_pipeline_cli` |
| `contract.composition_ports_mapping_directive` | [t/corpus/composition_ports_mapping_directive_top.fsm](t/corpus/composition_ports_mapping_directive_top.fsm) | `expected_failure` | `composition_contract_rejection_pipeline_cli` |
| `contract.trial_2_ports_mapping_directive` | [fsm/trial_2.fsm](fsm/trial_2.fsm) | `expected_failure` | `composition_contract_rejection_pipeline_cli` |
| `contract.composition_duplicate_top_port` | [t/corpus/composition_duplicate_top_port_top.fsm](t/corpus/composition_duplicate_top_port_top.fsm) | `expected_failure` | `composition_contract_rejection_pipeline_cli` |
| `contract.composition_duplicate_child_instance` | [t/corpus/composition_duplicate_child_instance_top.fsm](t/corpus/composition_duplicate_child_instance_top.fsm) | `expected_failure` | `composition_contract_rejection_pipeline_cli` |
| `contract.composition_ports_shape_multiple_blocks` | [t/corpus/composition_ports_shape_multiple_blocks_top.fsm](t/corpus/composition_ports_shape_multiple_blocks_top.fsm) | `expected_failure` | `composition_contract_rejection_pipeline_cli` |
| `contract.composition_ports_shape_missing_ports` | [t/corpus/composition_ports_shape_missing_ports_top.fsm](t/corpus/composition_ports_shape_missing_ports_top.fsm) | `expected_failure` | `composition_contract_rejection_pipeline_cli` |
| `contract.composition_ports_shape_empty_ports` | [t/corpus/composition_ports_shape_empty_ports_top.fsm](t/corpus/composition_ports_shape_empty_ports_top.fsm) | `expected_failure` | `composition_contract_rejection_pipeline_cli` |
| `contract.composition_target_support_vhdl` | [t/corpus/composition_target_support_vhdl_top.fsm](t/corpus/composition_target_support_vhdl_top.fsm) | `expected_failure` | `composition_contract_rejection_pipeline_cli` |
| `contract.composition_missing_explicit_wiring` | [t/corpus/composition_missing_explicit_wiring_top.fsm](t/corpus/composition_missing_explicit_wiring_top.fsm) | `expected_failure` | `composition_contract_rejection_pipeline_cli` |
| `contract.composition_c1_missing_exposure` | [t/corpus/composition_c1_missing_exposure_top.fsm](t/corpus/composition_c1_missing_exposure_top.fsm) | `expected_failure` | `composition_contract_rejection_pipeline_cli` |
| `contract.composition_c1_unknown_top_port` | [t/corpus/composition_c1_unknown_top_port_top.fsm](t/corpus/composition_c1_unknown_top_port_top.fsm) | `expected_failure` | `composition_contract_rejection_pipeline_cli` |
| `contract.composition_c1_width_mismatch` | [t/corpus/composition_c1_width_mismatch_top.fsm](t/corpus/composition_c1_width_mismatch_top.fsm) | `expected_failure` | `composition_contract_rejection_pipeline_cli` |
| `contract.composition_c1_direction_mismatch` | [t/corpus/composition_c1_direction_mismatch_top.fsm](t/corpus/composition_c1_direction_mismatch_top.fsm) | `expected_failure` | `composition_contract_rejection_pipeline_cli` |
| `contract.composition_system_port_same_name` | [t/corpus/composition_system_port_same_name_top.fsm](t/corpus/composition_system_port_same_name_top.fsm) | `expected_failure` | `composition_contract_rejection_pipeline_cli` |
| `contract.composition_child_endpoint_missing_aggregate_type` | [t/corpus/composition_child_endpoint_missing_aggregate_type_top.fsm](t/corpus/composition_child_endpoint_missing_aggregate_type_top.fsm) | `expected_failure` | `composition_contract_rejection_pipeline_cli` |
| `contract.composition_ports_verbose_declaration_shape` | [t/corpus/composition_ports_verbose_declaration_shape_top.fsm](t/corpus/composition_ports_verbose_declaration_shape_top.fsm) | `expected_failure` | `composition_contract_rejection_pipeline_cli` |
| `contract.composition_ports_invalid_token` | [t/corpus/composition_ports_invalid_token_top.fsm](t/corpus/composition_ports_invalid_token_top.fsm) | `expected_failure` | `composition_contract_rejection_pipeline_cli` |
| `contract.composition_ports_nonpositive_width` | [t/corpus/composition_ports_nonpositive_width_top.fsm](t/corpus/composition_ports_nonpositive_width_top.fsm) | `expected_failure` | `composition_contract_rejection_pipeline_cli` |
| `contract.composition_wiring_wrapped_slash_item` | [t/corpus/composition_wiring_wrapped_slash_item_top.fsm](t/corpus/composition_wiring_wrapped_slash_item_top.fsm) | `expected_failure` | `composition_contract_rejection_pipeline_cli` |
| `contract.composition_wiring_unsupported_token` | [t/corpus/composition_wiring_unsupported_token_top.fsm](t/corpus/composition_wiring_unsupported_token_top.fsm) | `expected_failure` | `composition_contract_rejection_pipeline_cli` |
| `contract.composition_top_constants_bad_identifier` | [t/corpus/composition_top_constants_bad_identifier_top.fsm](t/corpus/composition_top_constants_bad_identifier_top.fsm) | `expected_failure` | `composition_contract_rejection_pipeline_cli` |
| `contract.composition_top_enums_nonliteral_value` | [t/corpus/composition_top_enums_nonliteral_value_top.fsm](t/corpus/composition_top_enums_nonliteral_value_top.fsm) | `expected_failure` | `composition_contract_rejection_pipeline_cli` |
| `contract.missing_rtl_metadata_sidecar` | [t/corpus/missing_rtl_metadata_top.fsm](t/corpus/missing_rtl_metadata_top.fsm) | `expected_failure` | `composition_contract_rejection_pipeline_cli` |
| `contract.missing_fsm_child_source` | [t/corpus/missing_fsm_child_source_top.fsm](t/corpus/missing_fsm_child_source_top.fsm) | `expected_failure` | `composition_contract_rejection_pipeline_cli` |
| `contract.missing_dt_child_source` | [t/corpus/missing_dt_child_source_top.fsm](t/corpus/missing_dt_child_source_top.fsm) | `expected_failure` | `composition_contract_rejection_pipeline_cli` |
| `contract.wrong_kind_fsm_child_source` | [t/corpus/wrong_kind_fsmc_child_source_top.fsm](t/corpus/wrong_kind_fsmc_child_source_top.fsm) | `expected_failure` | `composition_contract_rejection_pipeline_cli` |
| `contract.wrong_kind_dt_child_source` | [t/corpus/wrong_kind_dtc_child_source_top.fsm](t/corpus/wrong_kind_dtc_child_source_top.fsm) | `expected_failure` | `composition_contract_rejection_pipeline_cli` |
| `contract.generated_child_source_count_fsmc` | [t/corpus/generated_child_source_count_fsmc_top.fsm](t/corpus/generated_child_source_count_fsmc_top.fsm) | `expected_failure` | `composition_contract_rejection_pipeline_cli` |
| `contract.generated_child_source_count_dtc` | [t/corpus/generated_child_source_count_dtc_top.fsm](t/corpus/generated_child_source_count_dtc_top.fsm) | `expected_failure` | `composition_contract_rejection_pipeline_cli` |
| `contract.generated_child_source_shape_fsmc` | [t/corpus/generated_child_source_shape_fsmc_top.fsm](t/corpus/generated_child_source_shape_fsmc_top.fsm) | `expected_failure` | `composition_contract_rejection_pipeline_cli` |
| `contract.generated_child_source_shape_dtc` | [t/corpus/generated_child_source_shape_dtc_top.fsm](t/corpus/generated_child_source_shape_dtc_top.fsm) | `expected_failure` | `composition_contract_rejection_pipeline_cli` |
| `contract.rtl_child_source_shape_nested` | [t/corpus/rtl_child_source_shape_nested_top.fsm](t/corpus/rtl_child_source_shape_nested_top.fsm) | `expected_failure` | `composition_contract_rejection_pipeline_cli` |
| `contract.rtl_child_source_count_multi_token` | [t/corpus/rtl_child_source_count_multi_token_top.fsm](t/corpus/rtl_child_source_count_multi_token_top.fsm) | `expected_failure` | `composition_contract_rejection_pipeline_cli` |
| `contract.lte_digital_rf_rtl_child_source_count` | [fsm/lte_digital_rf.fsm](fsm/lte_digital_rf.fsm) | `expected_failure` | `composition_contract_rejection_pipeline_cli` |
| `contract.invalid_rtl_system_port_direction` | [t/corpus/invalid_rtl_system_direction_top.fsm](t/corpus/invalid_rtl_system_direction_top.fsm) | `expected_failure` | `composition_contract_rejection_pipeline_cli` |
| `contract.duplicate_rtlif_port_declaration` | [t/corpus/duplicate_rtlif_port_top.fsm](t/corpus/duplicate_rtlif_port_top.fsm) | `expected_failure` | `composition_contract_rejection_pipeline_cli` |
| `contract.invalid_rtlif_port_type` | [t/corpus/invalid_rtlif_port_type_top.fsm](t/corpus/invalid_rtlif_port_type_top.fsm) | `expected_failure` | `composition_contract_rejection_pipeline_cli` |
| `contract.invalid_rtlif_port_token` | [t/corpus/invalid_rtlif_port_token_top.fsm](t/corpus/invalid_rtlif_port_token_top.fsm) | `expected_failure` | `composition_contract_rejection_pipeline_cli` |
| `contract.invalid_rtlif_port_width` | [t/corpus/invalid_rtlif_port_width_top.fsm](t/corpus/invalid_rtlif_port_width_top.fsm) | `expected_failure` | `composition_contract_rejection_pipeline_cli` |
| `contract.missing_rtlif_root` | [t/corpus/missing_rtlif_root_top.fsm](t/corpus/missing_rtlif_root_top.fsm) | `expected_failure` | `composition_contract_rejection_pipeline_cli` |
| `contract.empty_rtlif_port_declaration` | [t/corpus/empty_rtlif_port_top.fsm](t/corpus/empty_rtlif_port_top.fsm) | `expected_failure` | `composition_contract_rejection_pipeline_cli` |
| `contract.nested_rtlif_port_declaration` | [t/corpus/nested_rtlif_port_top.fsm](t/corpus/nested_rtlif_port_top.fsm) | `expected_failure` | `composition_contract_rejection_pipeline_cli` |
| `contract.duplicate_embedded_rtlif_root` | [t/corpus/duplicate_embedded_rtlif_top.fsm](t/corpus/duplicate_embedded_rtlif_top.fsm) | `expected_failure` | `composition_contract_rejection_pipeline_cli` |

## Current locking tests
- [t/262-composition-structural-actual-wiring-blocks.t](t/262-composition-structural-actual-wiring-blocks.t)
  executes explicit structural direct-actual composition through linked-plan,
  pipeline, and CLI coverage, including unsized numeric actuals, typed literal
  actuals, named composition-root actuals, and FSMGen intent-sized exact-width
  direct actuals such as `=5'23`, `=8'-10`, `=8'-0xA`, and `=20'x1`.
- [t/264-composition-wiring-concat-expressions.t](t/264-composition-wiring-concat-expressions.t)
  executes explicit structural concat composition through linked-plan,
  pipeline, and CLI coverage, including nested/repeat groups, named literal
  actual operands, intrinsic-width numeric operands, and FSMGen intent-sized
  exact-width concat operands such as `=5'23`, `=8'-10`, `=8'-0xA`, and
  `=20'x1`.
- [t/247-protocol-fixture-regression-smoke.t](t/247-protocol-fixture-regression-smoke.t)
  executes the first named protocol slice through pipeline and CLI.
- [t/261-regression-corpus-supported-language-features.t](t/261-regression-corpus-supported-language-features.t)
  executes the named supported language-feature entries through pipeline and
  CLI, and keeps specific HDL-shape expectations instead of compile smoke
  only. The `feature.direct_size_expression_widths` entry now specifically
  proves that direct `+size` expressions support constants, enums, params,
  aggregate scalar leaves, bitwise aliases, `0d` decimal terms, signed based
  negative terms, and unsized based literals before HDL generation. The
  `feature.declarative_bits_symbol_widths` entry proves that direct-root
  `+types` `(bits WIDTH_SYMBOL)` specs resolve positive integer scalar
  constants and enum members before driving downstream `+size` declarations.
  The `feature.direct_aggregate_constant_target_autogrowth` entry proves that
  direct whole-signal targets assigned whole aggregate constant roots preserve
  inferred list/record contracts into generated SystemVerilog typedefs instead
  of flattening the target to width-only metadata.
  The `feature.direct_rhs_concat_target_autogrowth` entry proves that direct
  whole-signal targets assigned RHS concat expressions can preserve generated
  list contracts, including nested list shape, when concat operands have exact
  type evidence.
  The
  `feature.direct_runtime_div_mod` entry proves that runtime RHS `/`, `%`,
  `div`, and `mod` expressions lower through pipeline and CLI, including the
  left-associative n-ary shape for three-operand forms. The paired
  `contract.direct_runtime_divide_literal_zero` and
  `contract.direct_runtime_modulo_exact_zero` entries lock parser-side
  rejection of known literal-zero direct runtime divisors before HDL emission.
  The
  `feature.arithmetic_xor_operator_variants` entry proves n-ary `+`, `-`, `*`,
  `add`, `^`, and `xor` lowering through emitted arithmetic expressions and
  XOR intermediate shapes. The
  `feature.rhs_expression_supported_variants` entry proves inline scalar
  comparisons such as `cnt[2:1]!=2'2` and negated n-ary bitwise RHS forms such
  as `!&`, `!|`, and `xnor` through emitted expression and intermediate
  shapes. The `feature.reset_state_aliases` entry proves that legacy
  reset-state aliases such as `-syncrst` and `-asyncreset` normalize to
  DT-style `syncreset`/`asyncreset` enable regions while ordinary states remain
  the encoded state-register plan. The `feature.custom_system_clock` entry
  proves that direct-root `+system` accepts HDL-compatible authored clock names
  such as `core_clk` under strict mode while the reset spelling remains the
  canonical active-high synchronous `(sreset reset)` form. The
  `feature.implicit_system_defaults` entry proves that direct `?fsm` sources
  that omit `+system` lower through strict mode with implicit `clk` and async
  active-low `rst_n` system ports and reset tests using `!rst_n`. The
  `feature.direct_assignment_pair_form` entry proves that canonical
  `(assign-op (lhs rhs))` syntax reaches the same pipeline and CLI HDL shapes
  as infix compatibility assignments, including guarded nested RHS
  expressions, dual-output assignment families, delayed pulse, and LHS
  deconstruct. The `feature.update_shorthand_variants` entry proves that
  `+=` and `-=` shorthand with implicit and explicit deltas lower to
  register-style update muxes through pipeline and CLI. The
  `feature.compound_update_variants` entry proves `++`, `--`, compact
  `+=N` / `-=N`, and inline `(+= N)` / `(-= N)` modifiers through emitted
  register-style and combinational update shapes. The
  `feature.state_dte_guards` entry proves that regular-state header activation
  guards lower into state enable expressions and still gate assignment and
  transition enables at the DTE boundary. The `feature.standalone_dt_guards`
  entry proves standalone DT classification, always-on DT enables, DTE guard
  lowering, and guarded output-enable boundaries for non-state DT blocks. The
  `feature.standalone_dt_explicit_system` entry proves that direct standalone
  `?dt` sources with explicit `+system` metadata are first-class supported
  direct roots: they keep `dt` source-kind accounting, emit explicit system
  ports and async active-low reset logic, and do not synthesize an encoded
  `current_state` plan. The
  `feature.guard_shorthand` entry proves scalar truthiness, negated
  truthiness, inline comparison, and suffix guard lowering through emitted
  enable expressions. The
  `feature.nested_compound_guards` entry proves nested guarded blocks,
  compound list-form guards, assignment suffix guards, and transition suffix
  guards through emitted nested/compound enable shapes. The
  `feature.relational_operator_chains` entry proves n-ary relational chain
  lowering, word aliases such as `eq` and `ge`, unary `not`, and guarded
  relational chains through emitted HDL comparisons and enables. The
  `feature.computed_test_selector` entry proves that `?(expr)` selectors create
  a computed intermediate and reuse it across explicit and default branch
  enables. The `feature.computed_comparison_selector` entry proves that
  comparison expressions such as `?(== A B)` are selector expressions, not
  branch markers, and lower through a computed intermediate. The
  `feature.plain_test_signal_selectors` entry proves that
  HDL-compatible plain `?SIG` selector names lower equality branches directly
  into branch-local enables. The `feature.test_selector_symbolic_default`
  entry proves named equality selectors and `default` / `_` fallback selector
  lowering through emitted comparison, negation, and fallback enable shapes.
  The `feature.test_branch_selectors` entry proves that relational
  `?SIG` branch selectors such as `!=`, `>`, and `<=` lower through width-safe
  nonzero reduction and factored comparison enables. The
  `feature.direct_intent_integer_literals` and
  `feature.composition_intent_integer_literals` entries prove that FSMGen
  intent-level sized spellings such as `5'23`, `8'-10`, `8'-0xA`, `8'-0b1010`,
  and `20'x1` now belong to the maintained support contract on both direct and
  composition actual paths. The
  `feature.implicit_composition_system_autowire` entry proves that composition
  tops with child FSMs that omit `+system` expose `clk` and `rst_n` at the top
  boundary and auto-wire those implicit child system ports to both generated
  children under strict mode. The
  `feature.standalone_dtc_explicit_system_autowire` entry proves that a
  generated standalone-DT child with explicit `+system` metadata exposes those
  system ports through its `?dtc` interface and receives top-level
  `.clk(clk)` / `.rst_n(rst_n)` bindings under strict mode. Every supported
  language-feature fixture is also
  now a `strict_supported` positive acceptance asset, so this same test runs
  the whole family through both `strict_mode => 1` and `bin/fsmgen --strict`.
- [t/309-intent-integer-literal-normalization.t](t/309-intent-integer-literal-normalization.t)
  locks the shared `.fsm` intent-level integer literal normalizer. It proves
  helper parsing, expression-builder parsing, package/direct constant
  canonicalization, and generated-SystemVerilog emission for source spellings
  such as `5'23`, `8'-10`, `8'-0xA`, `8'-0b1010`, and `20'x1`, using
  [t/corpus/direct_intent_integer_literals.fsm](t/corpus/direct_intent_integer_literals.fsm).
- [t/248-regression-corpus-accounting.t](t/248-regression-corpus-accounting.t)
  checks that the catalog stays named, classified, unique, and pointed at real
  repo assets, that each coverage bucket belongs to its expected classification,
  and also checks that strict-supported markers are only attached to supported
  pipeline/CLI corpus entries, that every supported protocol fixture is
  strict-supported, that every supported language-feature fixture is
  strict-supported, that supported direct language-feature entries carry
  non-empty compiled HDL-shape pattern metadata, and that expected-failure
  diagnostic/hint metadata is compiled-regex metadata rather than loose strings.
- [t/296-regression-corpus-supported-behavior.t](t/296-regression-corpus-supported-behavior.t)
  treats `supported_smoke` and `strict_supported` as executable catalog-level
  contracts. It runs every supported entry through default pipeline/CLI, then
  runs every strict-supported entry through `strict_mode => 1` and
  `bin/fsmgen --strict`, checking expected module/top/child modules and any
  recorded HDL-shape patterns.
- [t/249-regression-corpus-classified-behavior.t](t/249-regression-corpus-classified-behavior.t)
  checks that the current `legacy_out_of_scope` entries and the current
  `expected_failure` entries actually behave according to their recorded
  contract, including assignment-surface strict rejections, child-root
  compatibility residue that depends on explicit search-path realization,
  unsupported top-level source/directive language-contract failures,
  generic/template placeholder failures, bare condition suffix failures, and
  malformed source/body/test-form and `+system` failures.

## Working rule

Imported/example assets become part of FSMGen's support story only after they
appear in the maintained regression corpus with an explicit classification and
live automated coverage.
