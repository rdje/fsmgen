# Regression Corpus

This note is the human-readable companion to the machine-checked regression
catalog in [perl/FSM/Support/RegressionCorpus.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Support/RegressionCorpus.pm).
The older [t/lib/FSM/Test/RegressionCorpus.pm](/Users/richarddje/Documents/github/fsmgen/t/lib/FSM/Test/RegressionCorpus.pm)
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
  [perl/FSM/Support/DiagnosticCodes.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Support/DiagnosticCodes.pm)
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
- `language_contract_rejection_pipeline_cli`: the entry is intentionally
  rejected by the normal language-contract boundary through both the pipeline
  API and the CLI, and that rejection is part of the supported contract. This
  bucket now includes malformed `+size` entries and non-positive resolved
  `+size` expression widths, plus unresolved or non-scalar symbols inside
  `+size` expressions, divide/modulo-by-zero width arithmetic, and unsupported
  width operators or malformed operator arity.
- `direct_generation_contract_rejection_pipeline_cli`: the entry is
  intentionally rejected by the normal direct-generation contract through both
  the pipeline API and the CLI after parsing succeeds but before HDL is emitted,
  and that rejection is part of the supported contract.
- `composition_contract_rejection_pipeline_cli`: the entry is intentionally
  rejected by the normal composition contract through both the pipeline API and
  the CLI, and that rejection is part of the supported contract. This bucket
  now covers missing external generated-child source lookup, missing external
  `?rtl` sidecar metadata, invalid `.rtlif` system-role directions, and
  duplicate `.rtlif` port declarations, unsupported `.rtlif` port types,
  invalid `.rtlif` port tokens, non-positive `.rtlif` port widths, missing
  `.rtlif` roots, empty `.rtlif` roots, unsupported nested `.rtlif` structures, and
  duplicate embedded `.rtlif` roots.

## Supported-success markers

Every `supported_smoke` entry is executable at the catalog level: it must
compile through both the default pipeline API and default `bin/fsmgen`,
preserving the recorded semantic HDL shape. Some `supported_smoke` entries also
carry a `strict_supported` marker in the machine-readable catalog. That marker
is not a replacement coverage bucket. It means the same supported fixture must
also compile through both the strict pipeline API and `bin/fsmgen --strict`.
Both success contracts are run by
[t/296-regression-corpus-supported-behavior.t](/Users/richarddje/Documents/github/fsmgen/t/296-regression-corpus-supported-behavior.t)
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
[perl/FSM/Support/DiagnosticCodes.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Support/DiagnosticCodes.pm).
Every current `expected_failure` corpus entry carries one `FSMGEN_*`
diagnostic code, and
[t/248-regression-corpus-accounting.t](/Users/richarddje/Documents/github/fsmgen/t/248-regression-corpus-accounting.t)
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

[t/300-check-json-regression-corpus.t](/Users/richarddje/Documents/github/fsmgen/t/300-check-json-regression-corpus.t)
locks this bridge across every current `expected_failure` entry. The classifier
must choose the most specific matching expected-error pattern, so broad boundary
patterns such as generic malformed `+size` failures cannot shadow narrower
stable codes such as divide-by-zero or unsupported-operator diagnostics.

[t/301-check-json-supported-corpus.t](/Users/richarddje/Documents/github/fsmgen/t/301-check-json-supported-corpus.t)
locks the accepted side of the same command surface. Every current
`supported_smoke` entry must succeed through `--check-json`, and every current
`strict_supported` entry must succeed through `--strict --check-json`, while
emitting decodable success JSON, keeping diagnostics empty, writing no HDL, and
preserving the expected checked module/top identity. Corpus-backed successful
reports must also include a report-level `support_accounting` object with the
matched entry id, family, coverage bucket, classification, source kind, and
`strict_supported` marker.

[t/312-check-diagnostics-contract.t](/Users/richarddje/Documents/github/fsmgen/t/312-check-diagnostics-contract.t)
locks the bounded public key-presence promise for that same command surface.
[perl/FSM/Support/CheckDiagnosticsContract.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Support/CheckDiagnosticsContract.pm)
is now the explicit owner for the common top-level keys plus the bounded
success-result, success support-accounting, and failure-diagnostic key lists
advertised through `--capability-manifest`.
[perl/FSM/Support/ReportProducerContract.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Support/ReportProducerContract.pm)
now owns the shared nested `producer` object shape reused by both check JSON
and normalized semantic JSON.
[perl/FSM/Support/ReportSourceContract.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Support/ReportSourceContract.pm)
now owns the shared nested `source` object shape reused by both check JSON and
normalized semantic JSON.
[perl/FSM/Support/ReportCommandContract.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Support/ReportCommandContract.pm)
now owns the shared nested `command` object shape reused by both check JSON
and normalized semantic JSON.
[perl/FSM/Support/ReportGeneratedOutputContract.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Support/ReportGeneratedOutputContract.pm)
now owns the shared nested `generated_output` object shape reused by both
check JSON and normalized semantic JSON.
[perl/FSM/Support/SupportAccountingMatchContract.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Support/SupportAccountingMatchContract.pm)
now owns the shared nested `support_accounting` match-object shape reused by
both check JSON and normalized semantic JSON.

The first bounded normalized semantic JSON path reuses the same
support-accounting bridge for accepted corpus sources:

```bash
./bin/fsmgen --strict --emit-semantic-json path/to/file.fsm
```

[t/302-normalized-semantic-json.t](/Users/richarddje/Documents/github/fsmgen/t/302-normalized-semantic-json.t)
locks direct and composition corpus-backed success examples, no-HDL emission,
and strict rejected-source diagnostics for that semantic export. Successful
semantic reports expose sanitized module/system/signal and forward-IR metadata,
while matched corpus sources report the same entry id, family, coverage bucket,
classification, source kind, and `strict_supported` support-accounting bridge.
Those same semantic reports also reuse the shared bounded nested `producer`
object owner in
[perl/FSM/Support/ReportProducerContract.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Support/ReportProducerContract.pm),
so the public producer identity and `semantic_layers` shape stays aligned with
check JSON where the fields overlap.
Those same semantic reports also reuse the shared bounded nested `source`
object owner in
[perl/FSM/Support/ReportSourceContract.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Support/ReportSourceContract.pm),
so the public input/resolved-path shape stays aligned with check JSON.
Those same semantic reports also reuse the shared bounded nested `command`
object owner in
[perl/FSM/Support/ReportCommandContract.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Support/ReportCommandContract.pm),
so the public invocation metadata shape stays aligned with check JSON too.
Those same semantic reports also reuse the shared bounded nested
`generated_output` object owner in
[perl/FSM/Support/ReportGeneratedOutputContract.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Support/ReportGeneratedOutputContract.pm),
so the public “did this report emit HDL” shape stays aligned with check JSON
too.

[t/314-support-accounting-contract.t](/Users/richarddje/Documents/github/fsmgen/t/314-support-accounting-contract.t)
locks the bounded public contract for the manifest's `support_accounting`
section.
[perl/FSM/Support/SupportAccountingContract.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Support/SupportAccountingContract.pm)
is now the explicit owner for the bounded top-level support-accounting keys,
bucket/id-list keys, and sanitized catalog-entry required/optional key lists
advertised through `--capability-manifest`.
That same owner is now also advertised through
`support_accounting.section_contract`, so the manifest keeps one regular
section-contract discovery path without removing the existing inline
support-accounting payload fields.

[t/303-normalized-semantic-json-supported-corpus.t](/Users/richarddje/Documents/github/fsmgen/t/303-normalized-semantic-json-supported-corpus.t)
locks the accepted side across the whole current supported corpus. Every current
`supported_smoke` entry must succeed through `--emit-semantic-json`, and every
current `strict_supported` entry must succeed through
`--strict --emit-semantic-json`, while emitting decodable semantic JSON, keeping
diagnostics empty, writing no HDL, preserving matched support-accounting
identity, omitting generated HDL text/raw ASTs, and exposing the expected
module/top identity through `semantic.module`, `intent_hir`, and
`structural_rtl_ir`.

[t/304-normalized-semantic-json-regression-corpus.t](/Users/richarddje/Documents/github/fsmgen/t/304-normalized-semantic-json-regression-corpus.t)
locks the rejected side across the whole current expected-failure corpus. Every
current `expected_failure` entry must reject through `--emit-semantic-json`,
using the same strict/default routing as check JSON, while emitting decodable
failure JSON, keeping stderr clean, writing no HDL, omitting partial semantic
payloads, and preserving the exact stable diagnostic code plus matched
support-accounting identity promised by the corpus.

The optional external SystemVerilog validation lane is covered by
[t/308-systemverilog-external-validation.t](/Users/richarddje/Documents/github/fsmgen/t/308-systemverilog-external-validation.t).
When `verilator` and `yosys` are installed, that smoke generates
`fsm/lte_dif_pmaster.fsm`, `fsm/mipicsi2_byteserial.fsm`,
`fsm/mipicsi2_pkt_nx4B_fifo.fsm`, `fsm/mipicsi2_tester_ctrl.fsm`, and
`fsm/mipicsi2_txtimer.fsm`, the cleaned historical direct sample
`fsm/trial_1.fsm`, plus every supported direct protocol actor from
the corpus (`fsm/apb_requester.fsm`, `fsm/apb_completer.fsm`, and
`fsm/amba_requester.fsm` today), validates the emitted `.sv` files with
Verilator `--lint-only --sv`, validates ABC-free Yosys structural synthesis
with `read_verilog -sv -noautowire`, `synth -noabc -top`, and `stat`, and
proves the CLI `--verify-hdl` lane invokes the same external gates. Verilator
is the generated-SystemVerilog validity gate; Yosys is the structural-netlist
sanity gate. ABC is intentionally disabled until a future lane handles
ABC-specific timeout and mapping edge cases. When the tools are absent, the
test skips rather than making the baseline Perl regression suite depend on
local EDA installs.

[t/313-hdl-external-validation-contract.t](/Users/richarddje/Documents/github/fsmgen/t/313-hdl-external-validation-contract.t)
locks the bounded public contract for that lane.
[perl/FSM/Support/HDLExternalValidationContract.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Support/HDLExternalValidationContract.pm)
is now the explicit owner for the command shape, tool identities, stage names,
and bounded success top-level/step key lists advertised through
`--capability-manifest`.
The manifest's `backend_validation` section now has the same bounded contract
split through
[perl/FSM/Support/BackendValidationContract.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Support/BackendValidationContract.pm).
[t/323-backend-validation-contract.t](/Users/richarddje/Documents/github/fsmgen/t/323-backend-validation-contract.t)
locks the published top-level and nested contract-owner map for both
in-process and CLI manifest output while leaving deeper validation-lane
semantics with the narrower external validation contract.

[t/310-systemverilog-implicit-width-and-truthiness-hardening.t](/Users/richarddje/Documents/github/fsmgen/t/310-systemverilog-implicit-width-and-truthiness-hardening.t)
locks the non-tool-specific side of that hardening: static RHS slices infer
base widths, explicit selectors and guards infer tested/counter widths,
multibit truthiness emits width-safe reductions in one-bit enable expressions,
AST-backed arithmetic intermediates keep recovered result widths instead of
falling back to one bit, and runtime arithmetic rendering preserves
right-nested same-precedence grouping such as modulo over a product.

[t/02-combinational-self-dependency.t](/Users/richarddje/Documents/github/fsmgen/t/02-combinational-self-dependency.t)
now also locks the parser-side safety rail for D-input-named sequential
assignments: `<=` and `<=+` may not read the same LHS name from the RHS or
assignment guard, because that creates combinational feedback before HDL
emission. Q/output-named `<-` loopback remains supported for ordinary register
feedback.

All current supported protocol fixtures are now `strict_supported`: the APB
requester, APB completer, AMBA requester, and APB composition top use the
canonical `areset rst_n`, `(:= (signal value))`, and assignment-pair surfaces
and must pass both default and strict pipeline/CLI smoke. All current supported
language-feature fixtures are also `strict_supported`. That means strict mode
positively accepts the maintained fixtures for partial LHS writes, RHS
concat/cat packing, LHS concat/cat deconstruction, canonical reset spellings,
canonical init/default metadata, expression-backed widths, runtime div/mod
expressions, canonical assignment pairs, and intent-level integer literal
normalization on both direct and composition paths.

## Capability manifest

Downstream tools can ask FSMGen for the first bounded machine-readable support
surface without providing an input `.fsm` file:

```bash
./bin/fsmgen --capability-manifest
```

That command emits schema-versioned JSON built by
[perl/FSM/Support/CapabilityManifest.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Support/CapabilityManifest.pm)
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
[perl/FSM/Support/NormalizedSemanticReportContract.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Support/NormalizedSemanticReportContract.pm),
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
[perl/FSM/Support/DiagnosticCodeRegistryContract.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Support/DiagnosticCodeRegistryContract.pm).
[t/315-diagnostic-code-registry-contract.t](/Users/richarddje/Documents/github/fsmgen/t/315-diagnostic-code-registry-contract.t)
locks that sibling-key and stable-entry-key promise for both in-process and
CLI manifest output.
The manifest shell itself now has that same explicit public contract owner:
[perl/FSM/Support/CapabilityManifestContract.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Support/CapabilityManifestContract.pm).
[t/316-capability-manifest-contract.t](/Users/richarddje/Documents/github/fsmgen/t/316-capability-manifest-contract.t)
locks the bounded top-level and first nested section key presence for both
in-process and CLI manifest output.
That shell contract now also explicitly includes the first nested
`support_accounting` key list, so the corpus-backed section is covered by the
same manifest-shell discovery promise as the other bounded public sections.
The manifest's `embedding` section now has the same bounded contract split
through
[perl/FSM/Support/EmbeddingContract.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Support/EmbeddingContract.pm).
[t/321-embedding-contract.t](/Users/richarddje/Documents/github/fsmgen/t/321-embedding-contract.t)
locks the published top-level plus nested contract-owner map for both
in-process and CLI manifest output while leaving narrower result/report/typed
extension details with their dedicated contracts.
The manifest's `diagnostics` section now has the same bounded contract split
through
[perl/FSM/Support/DiagnosticsContract.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Support/DiagnosticsContract.pm).
[t/320-diagnostics-contract.t](/Users/richarddje/Documents/github/fsmgen/t/320-diagnostics-contract.t)
locks the published top-level plus stable-code entry families for both
in-process and CLI manifest output while leaving narrower registry/check JSON
details with their dedicated contracts.
The manifest's `producer` section now has the same bounded contract split
through
[perl/FSM/Support/ProducerContract.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Support/ProducerContract.pm).
[t/319-producer-contract.t](/Users/richarddje/Documents/github/fsmgen/t/319-producer-contract.t)
locks the published top-level, scalar-string, and boolean identity/build keys
for both in-process and CLI manifest output without pretending the section is
already a broader release API.
The manifest's `semantic_exports` section now has the same bounded contract
split through
[perl/FSM/Support/SemanticExportsContract.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Support/SemanticExportsContract.pm).
[t/322-semantic-exports-contract.t](/Users/richarddje/Documents/github/fsmgen/t/322-semantic-exports-contract.t)
locks the published top-level and nested contract-owner map for both
in-process and CLI manifest output while leaving deeper semantic payload
meaning with narrower export/report contracts.
The manifest's `language_surface` section now has the same bounded contract
split through
[perl/FSM/Support/LanguageSurfaceContract.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Support/LanguageSurfaceContract.pm).
[t/317-language-surface-contract.t](/Users/richarddje/Documents/github/fsmgen/t/317-language-surface-contract.t)
locks the published top-level and first nested section-key presence for both
in-process and CLI manifest output without claiming the whole authored
language is frozen.
The manifest's `documentation` section now has the same bounded contract split
through
[perl/FSM/Support/DocumentationContract.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Support/DocumentationContract.pm).
[t/318-documentation-contract.t](/Users/richarddje/Documents/github/fsmgen/t/318-documentation-contract.t)
locks the published top-level and path-list fields for both in-process and CLI
manifest output while keeping the exact file lists widenable.

## Current named entries

| ID | File | Classification | Coverage |
| --- | --- | --- | --- |
| `protocol.apb_requester` | [fsm/apb_requester.fsm](/Users/richarddje/Documents/github/fsmgen/fsm/apb_requester.fsm) | `supported_smoke` | `direct_root_pipeline_cli` |
| `protocol.apb_completer` | [fsm/apb_completer.fsm](/Users/richarddje/Documents/github/fsmgen/fsm/apb_completer.fsm) | `supported_smoke` | `direct_root_pipeline_cli` |
| `protocol.amba_requester` | [fsm/amba_requester.fsm](/Users/richarddje/Documents/github/fsmgen/fsm/amba_requester.fsm) | `supported_smoke` | `direct_root_pipeline_cli` |
| `protocol.apb_tb` | [fsm/apb_tb.fsm](/Users/richarddje/Documents/github/fsmgen/fsm/apb_tb.fsm) | `supported_smoke` | `composition_top_pipeline_cli` |
| `feature.partial_lhs_with_size` | [t/corpus/partial_lhs_with_size.fsm](/Users/richarddje/Documents/github/fsmgen/t/corpus/partial_lhs_with_size.fsm) | `supported_smoke` | `direct_root_pipeline_cli` |
| `feature.partial_lhs_inferred_width` | [t/corpus/partial_lhs_inferred_width.fsm](/Users/richarddje/Documents/github/fsmgen/t/corpus/partial_lhs_inferred_width.fsm) | `supported_smoke` | `direct_root_pipeline_cli` |
| `feature.direct_rhs_concat_pack` | [t/corpus/direct_rhs_concat_pack.fsm](/Users/richarddje/Documents/github/fsmgen/t/corpus/direct_rhs_concat_pack.fsm) | `supported_smoke` | `direct_root_pipeline_cli` |
| `feature.direct_lhs_deconstruct_pack` | [t/corpus/direct_lhs_deconstruct_pack.fsm](/Users/richarddje/Documents/github/fsmgen/t/corpus/direct_lhs_deconstruct_pack.fsm) | `supported_smoke` | `direct_root_pipeline_cli` |
| `feature.direct_sreset_active_high` | [t/corpus/direct_sreset_active_high.fsm](/Users/richarddje/Documents/github/fsmgen/t/corpus/direct_sreset_active_high.fsm) | `supported_smoke` | `direct_root_pipeline_cli` |
| `feature.direct_areset_active_low` | [t/corpus/direct_areset_active_low.fsm](/Users/richarddje/Documents/github/fsmgen/t/corpus/direct_areset_active_low.fsm) | `supported_smoke` | `direct_root_pipeline_cli` |
| `feature.direct_canonical_init_directive` | [t/corpus/direct_canonical_init_directive.fsm](/Users/richarddje/Documents/github/fsmgen/t/corpus/direct_canonical_init_directive.fsm) | `supported_smoke` | `direct_root_pipeline_cli` |
| `feature.direct_size_expression_widths` | [t/corpus/direct_size_expression_widths.fsm](/Users/richarddje/Documents/github/fsmgen/t/corpus/direct_size_expression_widths.fsm) | `supported_smoke` | `direct_root_pipeline_cli` |
| `feature.direct_runtime_div_mod` | [t/corpus/direct_runtime_div_mod.fsm](/Users/richarddje/Documents/github/fsmgen/t/corpus/direct_runtime_div_mod.fsm) | `supported_smoke` | `direct_root_pipeline_cli` |
| `feature.direct_assignment_pair_form` | [t/corpus/direct_assignment_pair_form.fsm](/Users/richarddje/Documents/github/fsmgen/t/corpus/direct_assignment_pair_form.fsm) | `supported_smoke` | `direct_root_pipeline_cli` |
| `feature.direct_intent_integer_literals` | [t/corpus/direct_intent_integer_literals.fsm](/Users/richarddje/Documents/github/fsmgen/t/corpus/direct_intent_integer_literals.fsm) | `supported_smoke` | `direct_root_pipeline_cli` |
| `feature.composition_intent_integer_literals` | [t/corpus/composition_intent_integer_literals.fsm](/Users/richarddje/Documents/github/fsmgen/t/corpus/composition_intent_integer_literals.fsm) | `supported_smoke` | `composition_top_pipeline_cli` |
| `legacy.mipicsi2_txccore_ulp.default_compat` | [fsm/mipicsi2_txccore_ulp.fsm](/Users/richarddje/Documents/github/fsmgen/fsm/mipicsi2_txccore_ulp.fsm) | `legacy_out_of_scope` | `legacy_root_default_pipeline_cli` |
| `legacy.mipicsi2_txccore_ulp.strict_rejection` | [fsm/mipicsi2_txccore_ulp.fsm](/Users/richarddje/Documents/github/fsmgen/fsm/mipicsi2_txccore_ulp.fsm) | `expected_failure` | `strict_root_rejection_pipeline_cli` |
| `legacy.empty_size_noop.default_compat` | [t/corpus/legacy_empty_size_noop.fsm](/Users/richarddje/Documents/github/fsmgen/t/corpus/legacy_empty_size_noop.fsm) | `legacy_out_of_scope` | `legacy_section_default_pipeline_cli` |
| `legacy.empty_size_noop.strict_rejection` | [t/corpus/legacy_empty_size_noop.fsm](/Users/richarddje/Documents/github/fsmgen/t/corpus/legacy_empty_size_noop.fsm) | `expected_failure` | `strict_section_rejection_pipeline_cli` |
| `legacy.asreset_rstn.default_compat` | [t/corpus/legacy_asreset_rstn.fsm](/Users/richarddje/Documents/github/fsmgen/t/corpus/legacy_asreset_rstn.fsm) | `legacy_out_of_scope` | `legacy_section_default_pipeline_cli` |
| `legacy.asreset_rstn.strict_rejection` | [t/corpus/legacy_asreset_rstn.fsm](/Users/richarddje/Documents/github/fsmgen/t/corpus/legacy_asreset_rstn.fsm) | `expected_failure` | `strict_section_rejection_pipeline_cli` |
| `legacy.sreset_rstn.default_compat` | [t/corpus/legacy_sreset_rstn.fsm](/Users/richarddje/Documents/github/fsmgen/t/corpus/legacy_sreset_rstn.fsm) | `legacy_out_of_scope` | `legacy_section_default_pipeline_cli` |
| `legacy.sreset_rstn.strict_rejection` | [t/corpus/legacy_sreset_rstn.fsm](/Users/richarddje/Documents/github/fsmgen/t/corpus/legacy_sreset_rstn.fsm) | `expected_failure` | `strict_section_rejection_pipeline_cli` |
| `legacy.compact_init_directive.default_compat` | [t/corpus/legacy_compact_init_directive.fsm](/Users/richarddje/Documents/github/fsmgen/t/corpus/legacy_compact_init_directive.fsm) | `legacy_out_of_scope` | `legacy_section_default_pipeline_cli` |
| `legacy.compact_init_directive.strict_rejection` | [t/corpus/legacy_compact_init_directive.fsm](/Users/richarddje/Documents/github/fsmgen/t/corpus/legacy_compact_init_directive.fsm) | `expected_failure` | `strict_section_rejection_pipeline_cli` |
| `legacy.infix_assignment.default_compat` | [t/corpus/legacy_infix_assignment.fsm](/Users/richarddje/Documents/github/fsmgen/t/corpus/legacy_infix_assignment.fsm) | `legacy_out_of_scope` | `legacy_assignment_default_pipeline_cli` |
| `legacy.infix_assignment.strict_rejection` | [t/corpus/legacy_infix_assignment.fsm](/Users/richarddje/Documents/github/fsmgen/t/corpus/legacy_infix_assignment.fsm) | `expected_failure` | `strict_assignment_rejection_pipeline_cli` |
| `legacy.fsm_child_root.default_compat` | [t/corpus/legacy_fsm_child_root_top.fsm](/Users/richarddje/Documents/github/fsmgen/t/corpus/legacy_fsm_child_root_top.fsm) | `legacy_out_of_scope` | `legacy_child_root_default_pipeline_cli` |
| `legacy.fsm_child_root.strict_rejection` | [t/corpus/legacy_fsm_child_root_top.fsm](/Users/richarddje/Documents/github/fsmgen/t/corpus/legacy_fsm_child_root_top.fsm) | `expected_failure` | `strict_child_root_rejection_pipeline_cli` |
| `legacy.dt_child_root.default_compat` | [t/corpus/legacy_dt_child_root_top.fsm](/Users/richarddje/Documents/github/fsmgen/t/corpus/legacy_dt_child_root_top.fsm) | `legacy_out_of_scope` | `legacy_child_root_default_pipeline_cli` |
| `legacy.dt_child_root.strict_rejection` | [t/corpus/legacy_dt_child_root_top.fsm](/Users/richarddje/Documents/github/fsmgen/t/corpus/legacy_dt_child_root_top.fsm) | `expected_failure` | `strict_child_root_rejection_pipeline_cli` |
| `contract.language_contract_bad_size_entry` | [t/corpus/language_contract_bad_size_entry.fsm](/Users/richarddje/Documents/github/fsmgen/t/corpus/language_contract_bad_size_entry.fsm) | `expected_failure` | `language_contract_rejection_pipeline_cli` |
| `contract.direct_size_expression_non_positive` | [t/corpus/direct_size_expression_non_positive.fsm](/Users/richarddje/Documents/github/fsmgen/t/corpus/direct_size_expression_non_positive.fsm) | `expected_failure` | `language_contract_rejection_pipeline_cli` |
| `contract.direct_size_expression_unknown_symbol` | [t/corpus/direct_size_expression_unknown_symbol.fsm](/Users/richarddje/Documents/github/fsmgen/t/corpus/direct_size_expression_unknown_symbol.fsm) | `expected_failure` | `language_contract_rejection_pipeline_cli` |
| `contract.direct_size_expression_aggregate_symbol` | [t/corpus/direct_size_expression_aggregate_symbol.fsm](/Users/richarddje/Documents/github/fsmgen/t/corpus/direct_size_expression_aggregate_symbol.fsm) | `expected_failure` | `language_contract_rejection_pipeline_cli` |
| `contract.direct_size_expression_divide_by_zero` | [t/corpus/direct_size_expression_divide_by_zero.fsm](/Users/richarddje/Documents/github/fsmgen/t/corpus/direct_size_expression_divide_by_zero.fsm) | `expected_failure` | `language_contract_rejection_pipeline_cli` |
| `contract.direct_size_expression_modulo_by_zero` | [t/corpus/direct_size_expression_modulo_by_zero.fsm](/Users/richarddje/Documents/github/fsmgen/t/corpus/direct_size_expression_modulo_by_zero.fsm) | `expected_failure` | `language_contract_rejection_pipeline_cli` |
| `contract.direct_size_expression_unsupported_operator` | [t/corpus/direct_size_expression_unsupported_operator.fsm](/Users/richarddje/Documents/github/fsmgen/t/corpus/direct_size_expression_unsupported_operator.fsm) | `expected_failure` | `language_contract_rejection_pipeline_cli` |
| `contract.direct_size_expression_bad_arity` | [t/corpus/direct_size_expression_bad_arity.fsm](/Users/richarddje/Documents/github/fsmgen/t/corpus/direct_size_expression_bad_arity.fsm) | `expected_failure` | `language_contract_rejection_pipeline_cli` |
| `contract.direct_lhs_deconstruct_width_mismatch` | [t/corpus/direct_lhs_deconstruct_width_mismatch.fsm](/Users/richarddje/Documents/github/fsmgen/t/corpus/direct_lhs_deconstruct_width_mismatch.fsm) | `expected_failure` | `language_contract_rejection_pipeline_cli` |
| `contract.direct_rhs_concat_width_mismatch` | [t/corpus/direct_rhs_concat_width_mismatch.fsm](/Users/richarddje/Documents/github/fsmgen/t/corpus/direct_rhs_concat_width_mismatch.fsm) | `expected_failure` | `direct_generation_contract_rejection_pipeline_cli` |
| `contract.direct_aggregate_contract_mismatch` | [t/corpus/direct_aggregate_contract_mismatch.fsm](/Users/richarddje/Documents/github/fsmgen/t/corpus/direct_aggregate_contract_mismatch.fsm) | `expected_failure` | `direct_generation_contract_rejection_pipeline_cli` |
| `contract.missing_rtl_metadata_sidecar` | [t/corpus/missing_rtl_metadata_top.fsm](/Users/richarddje/Documents/github/fsmgen/t/corpus/missing_rtl_metadata_top.fsm) | `expected_failure` | `composition_contract_rejection_pipeline_cli` |
| `contract.missing_fsm_child_source` | [t/corpus/missing_fsm_child_source_top.fsm](/Users/richarddje/Documents/github/fsmgen/t/corpus/missing_fsm_child_source_top.fsm) | `expected_failure` | `composition_contract_rejection_pipeline_cli` |
| `contract.missing_dt_child_source` | [t/corpus/missing_dt_child_source_top.fsm](/Users/richarddje/Documents/github/fsmgen/t/corpus/missing_dt_child_source_top.fsm) | `expected_failure` | `composition_contract_rejection_pipeline_cli` |
| `contract.invalid_rtl_system_port_direction` | [t/corpus/invalid_rtl_system_direction_top.fsm](/Users/richarddje/Documents/github/fsmgen/t/corpus/invalid_rtl_system_direction_top.fsm) | `expected_failure` | `composition_contract_rejection_pipeline_cli` |
| `contract.duplicate_rtlif_port_declaration` | [t/corpus/duplicate_rtlif_port_top.fsm](/Users/richarddje/Documents/github/fsmgen/t/corpus/duplicate_rtlif_port_top.fsm) | `expected_failure` | `composition_contract_rejection_pipeline_cli` |
| `contract.invalid_rtlif_port_type` | [t/corpus/invalid_rtlif_port_type_top.fsm](/Users/richarddje/Documents/github/fsmgen/t/corpus/invalid_rtlif_port_type_top.fsm) | `expected_failure` | `composition_contract_rejection_pipeline_cli` |
| `contract.invalid_rtlif_port_token` | [t/corpus/invalid_rtlif_port_token_top.fsm](/Users/richarddje/Documents/github/fsmgen/t/corpus/invalid_rtlif_port_token_top.fsm) | `expected_failure` | `composition_contract_rejection_pipeline_cli` |
| `contract.invalid_rtlif_port_width` | [t/corpus/invalid_rtlif_port_width_top.fsm](/Users/richarddje/Documents/github/fsmgen/t/corpus/invalid_rtlif_port_width_top.fsm) | `expected_failure` | `composition_contract_rejection_pipeline_cli` |
| `contract.missing_rtlif_root` | [t/corpus/missing_rtlif_root_top.fsm](/Users/richarddje/Documents/github/fsmgen/t/corpus/missing_rtlif_root_top.fsm) | `expected_failure` | `composition_contract_rejection_pipeline_cli` |
| `contract.empty_rtlif_port_declaration` | [t/corpus/empty_rtlif_port_top.fsm](/Users/richarddje/Documents/github/fsmgen/t/corpus/empty_rtlif_port_top.fsm) | `expected_failure` | `composition_contract_rejection_pipeline_cli` |
| `contract.nested_rtlif_port_declaration` | [t/corpus/nested_rtlif_port_top.fsm](/Users/richarddje/Documents/github/fsmgen/t/corpus/nested_rtlif_port_top.fsm) | `expected_failure` | `composition_contract_rejection_pipeline_cli` |
| `contract.duplicate_embedded_rtlif_root` | [t/corpus/duplicate_embedded_rtlif_top.fsm](/Users/richarddje/Documents/github/fsmgen/t/corpus/duplicate_embedded_rtlif_top.fsm) | `expected_failure` | `composition_contract_rejection_pipeline_cli` |

## Current locking tests
- [t/262-composition-structural-actual-toplinks.t](/Users/richarddje/Documents/github/fsmgen/t/262-composition-structural-actual-toplinks.t)
  executes explicit structural direct-actual composition through linked-plan,
  pipeline, and CLI coverage, including unsized numeric actuals, typed literal
  actuals, named composition-root actuals, and FSMGen intent-sized exact-width
  direct actuals such as `=5'23`, `=8'-10`, `=8'-0xA`, and `=20'x1`.
- [t/264-composition-toplink-concat-expressions.t](/Users/richarddje/Documents/github/fsmgen/t/264-composition-toplink-concat-expressions.t)
  executes explicit structural concat composition through linked-plan,
  pipeline, and CLI coverage, including nested/repeat groups, named literal
  actual operands, intrinsic-width numeric operands, and FSMGen intent-sized
  exact-width concat operands such as `=5'23`, `=8'-10`, `=8'-0xA`, and
  `=20'x1`.
- [t/247-protocol-fixture-regression-smoke.t](/Users/richarddje/Documents/github/fsmgen/t/247-protocol-fixture-regression-smoke.t)
  executes the first named protocol slice through pipeline and CLI.
- [t/261-regression-corpus-supported-language-features.t](/Users/richarddje/Documents/github/fsmgen/t/261-regression-corpus-supported-language-features.t)
  executes the named supported language-feature entries through pipeline and
  CLI, and keeps specific HDL-shape expectations instead of compile smoke
  only. The `feature.direct_size_expression_widths` entry now specifically
  proves that direct `+size` expressions support constants, enums, params,
  aggregate scalar leaves, bitwise aliases, `0d` decimal terms, signed based
  negative terms, and unsized based literals before HDL generation. The
  `feature.direct_runtime_div_mod` entry proves that runtime RHS `/`, `%`,
  `div`, and `mod` expressions lower through pipeline and CLI, including the
  left-associative n-ary shape for three-operand forms. The
  `feature.direct_assignment_pair_form` entry proves that canonical
  `(assign-op (lhs rhs))` syntax reaches the same pipeline and CLI HDL shapes
  as infix compatibility assignments, including guarded nested RHS
  expressions, dual-output assignment families, delayed pulse, and LHS
  deconstruct. The `feature.direct_intent_integer_literals` and
  `feature.composition_intent_integer_literals` entries prove that FSMGen
  intent-level sized spellings such as `5'23`, `8'-10`, `8'-0xA`, `8'-0b1010`,
  and `20'x1` now belong to the maintained support contract on both direct and
  composition actual paths. Every supported language-feature fixture is also
  now a `strict_supported` positive acceptance asset, so this same test runs
  the whole family through both `strict_mode => 1` and `bin/fsmgen --strict`.
- [t/309-intent-integer-literal-normalization.t](/Users/richarddje/Documents/github/fsmgen/t/309-intent-integer-literal-normalization.t)
  locks the shared `.fsm` intent-level integer literal normalizer. It proves
  helper parsing, expression-builder parsing, package/direct constant
  canonicalization, and generated-SystemVerilog emission for source spellings
  such as `5'23`, `8'-10`, `8'-0xA`, `8'-0b1010`, and `20'x1`, using
  [t/corpus/direct_intent_integer_literals.fsm](/Users/richarddje/Documents/github/fsmgen/t/corpus/direct_intent_integer_literals.fsm).
- [t/248-regression-corpus-accounting.t](/Users/richarddje/Documents/github/fsmgen/t/248-regression-corpus-accounting.t)
  checks that the catalog stays named, classified, unique, and pointed at real
  repo assets, that each coverage bucket belongs to its expected classification,
  and also checks that strict-supported markers are only attached to supported
  pipeline/CLI corpus entries, that every supported protocol fixture is
  strict-supported, that every supported language-feature fixture is
  strict-supported, that supported direct language-feature entries carry
  non-empty compiled HDL-shape pattern metadata, and that expected-failure
  diagnostic/hint metadata is compiled-regex metadata rather than loose strings.
- [t/296-regression-corpus-supported-behavior.t](/Users/richarddje/Documents/github/fsmgen/t/296-regression-corpus-supported-behavior.t)
  treats `supported_smoke` and `strict_supported` as executable catalog-level
  contracts. It runs every supported entry through default pipeline/CLI, then
  runs every strict-supported entry through `strict_mode => 1` and
  `bin/fsmgen --strict`, checking expected module/top/child modules and any
  recorded HDL-shape patterns.
- [t/249-regression-corpus-classified-behavior.t](/Users/richarddje/Documents/github/fsmgen/t/249-regression-corpus-classified-behavior.t)
  checks that the current `legacy_out_of_scope` entries and the current
  `expected_failure` entries actually behave according to their recorded
  contract, including assignment-surface strict rejections and child-root
  compatibility residue that depends on explicit search-path realization.

## Working rule

Imported/example assets become part of FSMGen's support story only after they
appear in the maintained regression corpus with an explicit classification and
live automated coverage.
