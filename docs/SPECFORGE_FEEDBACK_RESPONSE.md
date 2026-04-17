# FSMGen Response To SPECFORGE Feedback

This document is FSMGen's tracked response to SPECFORGE's feedback in:

- `/Users/richarddje/Documents/github/specforge/docs/FSMGEN_FEEDBACK.md`

It exists so SPECFORGE can align its `.fsm` adapter planning with FSMGen's
accepted direction without relying on transient chat context.

## High-Level Response

FSMGen agrees with the core SPECFORGE framing:

- `.fsm` should remain precise rather than permissive.
- Strict mode should define the canonical future-facing authoring surface.
- Compatibility syntax may remain useful, but it must stay labeled as
  compatibility residue.
- The mdBook should remain the public human-facing language contract.
- Tool-to-tool consumers need machine-readable contracts in addition to prose.
- FSMGen should not become SPECFORGE's PDF/spec extraction engine or canonical
  `IntentIR`.

The most important shared direction is that FSMGen should become a reliable
`.fsm` contract authority: parser, validator, normalizer, support-accounting
source, and HDL generator.

## Accepted Near-Term Direction

FSMGen accepts the following as the highest-leverage integration direction for
SPECFORGE and similar downstream tools.

### 1. Capability Manifest

FSMGen should provide a versioned machine-readable capability manifest.

The intended first owner should be the same support-accounting source used by
the regression corpus and docs, so the manifest does not drift away from tests.

The first manifest should expose at least:

- FSMGen version or commit identity
- supported root kinds
- strict-mode canonical syntax families
- compatibility-only syntax families
- supported assignment forms
- supported reset/system forms
- supported expression families
- supported aggregate/type/package/composition families
- intentionally blocked forms
- links or identifiers for corpus fixtures and mdBook chapters

The first bounded implementation now exists as:

```bash
fsmgen --capability-manifest
```

It is schema-versioned JSON built from
`FSM::Support::RegressionCorpus` through `FSM::Support::CapabilityManifest`.
It includes a producer version string and best-effort git commit identity. This
is still the first slice, not the final public API. It belongs to `R12` support
accounting now and should be widened/stabilized under `R13` as the rest of the
public embedding surface matures.

### 2. JSON Check Diagnostics

FSMGen should grow a check-only command shape such as:

```bash
fsmgen --strict --check --json path/to/file.fsm
```

The first useful contract is not full elaboration perfection. It is stable
machine-readable success/failure data:

- success/failure
- diagnostic code
- severity
- source/context path
- root or composition context
- strict versus compatibility classification
- migration hint where available

This first bounded surface now exists. `bin/fsmgen` accepts `--check --json`
and the alias `--check-json`; it runs the full pipeline, emits schema-versioned
JSON to stdout, exits non-zero for failed checks, and does not write HDL files.
Expected-failure diagnostics that match the support-accounting corpus carry the
stable `FSMGEN_*` code, severity, stability, family, source file, matched corpus
entry, and migration-hint availability. They also include a nested
`support_accounting` object with the matched entry id, corpus family, coverage,
classification, diagnostic code, and migration-hint availability. The classifier
chooses the most specific matching expected-error pattern, and the current
expected-failure corpus is covered end-to-end by
[t/300-check-json-regression-corpus.t](/Users/richarddje/Documents/github/fsmgen/t/300-check-json-regression-corpus.t).
The accepted side is also covered: supported-smoke entries must succeed through
`--check-json`, and strict-supported entries must succeed through
`--strict --check-json`, as locked by
[t/301-check-json-supported-corpus.t](/Users/richarddje/Documents/github/fsmgen/t/301-check-json-supported-corpus.t).
Failures outside the current support-accounting classifier still emit JSON, but
their code is `null` rather than inventing a false stable identity.

### 3. Stable Diagnostic Codes

FSMGen should introduce stable diagnostic identities before exposing JSON
diagnostics as a public integration surface.

This first ownership slice now exists. The production registry lives in
[perl/FSM/Support/DiagnosticCodes.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Support/DiagnosticCodes.pm),
every current `expected_failure` support-accounting entry carries a known
`FSMGEN_*` code, and the capability manifest exposes the registry plus those
entry-level codes. The requirement is stable machine identity across wording
improvements. Examples of the public shape:

- `FSMGEN_STRICT_INFIX_ASSIGNMENT`
- `FSMGEN_STRICT_LEGACY_FSM_ROOT`
- `FSMGEN_LANGUAGE_BAD_SIZE_ENTRY`
- `FSMGEN_COMPOSITION_MISSING_RTLIF`

Codes are regression-backed by
[t/248-regression-corpus-accounting.t](/Users/richarddje/Documents/github/fsmgen/t/248-regression-corpus-accounting.t),
[t/297-capability-manifest.t](/Users/richarddje/Documents/github/fsmgen/t/297-capability-manifest.t),
and
[t/298-diagnostic-code-registry.t](/Users/richarddje/Documents/github/fsmgen/t/298-diagnostic-code-registry.t).
They are cataloged for manifest/corpus integration and emitted by the bounded
check-only JSON path now. The bounded path now also regression-locks the exact
stable code for every current expected-failure corpus entry and clean success
JSON for every current supported-smoke / strict-supported entry. Successful
corpus-backed check reports now also include a report-level
`support_accounting` object with the matched entry id, family, coverage,
classification, source kind, and `strict_supported` marker; ad-hoc successes
report `matched: false`. Full diagnostic schema stabilization remains a later
public API widening step.

### 4. Normalized Semantic Export

FSMGen should expose a normalized JSON projection of accepted `.fsm` semantics,
for example:

```bash
fsmgen --strict --emit-semantic-json path/to/file.fsm
```

The first stable export should be intentionally bounded. It should not expose
every private Perl structure. It should expose enough for downstream tools to
compare emitted `.fsm` text against FSMGen's recovered semantics:

- root kind and name
- system/reset contract
- ports/signals/types/packages
- state/decision-tree control shape
- assignments and guards
- composition children and links
- normalized expressions
- compatibility residue, if any

This belongs to `R13`. It should build on existing `Intent HIR`,
`Lowered RTL IR`, and `Structural RTL IR` surfaces rather than inventing a
separate unrelated public model.

The first bounded implementation now exists. `bin/fsmgen` accepts
`--emit-semantic-json` plus the alias `--semantic-json`; compatibility aliases
`--emit-normalized-json` and `--normalized-json` are also accepted. The command
runs the full pipeline, emits `normalized_semantic_schema_version: 1` JSON to
stdout, writes no HDL files even when `-o` is present, and returns non-zero on
rejected sources. Successful reports expose a sanitized `semantic` payload with
module/root metadata, system/reset contract metadata, signal analysis, and the
three forward layers `intent_hir`, `lowered_rtl_ir`, and `structural_rtl_ir`.
They also include the same report-level support-accounting bridge used by
successful `--check-json`. Rejected semantic exports reuse the stable
diagnostic-code classifier from check JSON and do not expose partial semantics.
The accepted side is now corpus-covered too: every current supported-smoke
entry must succeed through `--emit-semantic-json`, and every current
strict-supported entry must succeed through `--strict --emit-semantic-json`,
with matched support-accounting identity, expected module/top identity,
sanitized forward-IR projections, and no HDL emission.
The rejected side is now corpus-covered too: every current expected-failure
entry must reject through `--emit-semantic-json`, with stable diagnostic code
metadata, matched support-accounting identity, no HDL emission, and no partial
semantic payload.
The implementation deliberately strips private live Perl objects and generated
HDL text from the public report.

### 5. Reset And Clock Contract Metadata

FSMGen agrees that clock/reset truth deserves first-class treatment.

The already-shipped `sreset reset` and `areset rst_n` strict-mode direction is
only the first slice. Future work should clarify and, where feasible, preserve:

- clock identity
- reset identity
- reset polarity
- synchronous versus asynchronous reset behavior
- asynchronous assertion / synchronous release intent
- reset target information where FSMGen can prove it
- documented limits where `.fsm` cannot yet express a recovered source fact

This spans `R8`, `R9`, `R10`, and `R13`, with implementation staged carefully.

## Accepted Longer-Term Language Direction

FSMGen agrees that these language features are directionally valuable:

- actor-relative port semantics
- interface/channel grouping
- semantic signal roles
- temporal and stability contracts
- assumptions/residual/provenance metadata
- contract-aware composition across child boundaries
- a better-defined canonical direct-module root shape, if `?mod` graduates
  from compatibility-oriented surface to stable language surface

FSMGen should not rush these as decorative syntax. They should land only when
they can be:

- parsed
- validated
- represented in normalized semantics
- documented in the mdBook
- covered by support-accounting fixtures
- either lowered honestly to HDL or preserved honestly as checked metadata

This is important: unchecked annotations would be worse than no annotations,
because downstream tools could mistake them for enforced intent.

## Explicit Non-Goals Confirmed

FSMGen confirms that this response does not make FSMGen responsible for:

- PDF parsing
- prose-to-intent recovery
- SPECFORGE's canonical `IntentIR`
- arbitrary target-text generation for incomplete facts
- permissive acceptance of unsafe compatibility syntax
- hiding backend or language limitations behind loose parsing

SPECFORGE remains responsible for deciding whether its canonical facts justify
emitting `.fsm`. FSMGen remains responsible for making the `.fsm` contract
precise, documented, testable, and machine-checkable.

## Proposed Sync Contract Between The Projects

The preferred collaboration shape is:

- SPECFORGE records downstream needs and adapter blockers in its tracked
  feedback document.
- FSMGen records accepted, deferred, or rejected responses in this document and
  the relevant roadmap/docs.
- FSMGen publishes machine-readable capability/check/normalized surfaces only
  after they are regression-backed.
- SPECFORGE should target strict-mode canonical `.fsm` by default.
- SPECFORGE should treat compatibility syntax as adapter-blocked unless FSMGen
  explicitly marks a compatibility lane as safe for generated output.

This dependency direction can be asymmetric. It is reasonable for SPECFORGE to
keep FSMGen as a submodule or otherwise pinned dependency when SPECFORGE needs
local access to the `.fsm` syntax, semantic contract, examples, or future
machine-readable manifests. FSMGen should not need SPECFORGE as a reciprocal
submodule unless a concrete cross-project conformance workflow requires it. That
keeps FSMGen the upstream contract authority and SPECFORGE the downstream
consumer/adapter without creating circular ownership.

## Current Priority Order From FSMGen

The current FSMGen-side priority order is:

1. Keep the first `--capability-manifest` schema conservative while widening
   only from regression-backed support-accounting truth.
2. Continue widening stable diagnostic-code ownership only from
   regression-backed failures.
3. Stabilize and widen check-only JSON diagnostics from the bounded surface now
   shipped.
4. Widen normalized semantic JSON only from regression-backed public facts.
5. Keep the typed extension/context contract and in-process `HDLGenerator`
   result contract explicit and bounded
   while raw nested compatibility payloads still contain live Perl objects.
6. Use those surfaces to guide later language additions such as actor roles,
   channel grouping, semantic signal roles, temporal/stability contracts, and
   provenance/residual metadata.

## What SPECFORGE Can Plan Around Now

Until the machine surfaces exist, SPECFORGE can already rely on these FSMGen
project policies:

- strict mode is the preferred target for generated `.fsm`;
- compatibility syntax should not be treated as canonical adapter output;
- mdBook chapters are the public human-facing contract;
- `fsmgen --capability-manifest` is the first machine-readable support surface;
- `fsmgen --strict --check --json path/to/file.fsm` is the first bounded
  machine-readable check/diagnostic surface, including a nested
  `support_accounting` object for matched expected failures, a report-level
  `support_accounting` object for successful checks, and corpus-backed success
  coverage for supported entries;
- `fsmgen --strict --emit-semantic-json path/to/file.fsm` is the first bounded
  normalized semantic export surface, including sanitized module/system/signal
  metadata, sanitized forward IR projections, no HDL emission, failure-side
  stable diagnostics, and report-level support accounting where the accepted
  source matches the corpus, with accepted-side corpus coverage for current
  supported-smoke and strict-supported entries plus rejected-side coverage for
  current expected-failure entries;
- `FSM::Pipeline::HDLGenerator->generate_hdl_from_file(...)` now has a bounded
  top-level result-presence contract advertised through the capability
  manifest, while the raw result hash is explicitly not a JSON-safe interchange
  document;
- typed extensions now have a bounded hook/context contract advertised through
  the capability manifest, covering explicit object/module/config loading,
  `after_parse_source`, `after_generate_result`, and the current context
  accessors without reviving legacy `.plg` discovery;
- `docs/REGRESSION_CORPUS.md` and `FSM::Support::RegressionCorpus` are the
  current support-accounting source of truth behind that manifest;
- `FSM::Support::DiagnosticCodes` is the current stable diagnostic-code owner
  behind expected-failure corpus entries, the manifest registry, and bounded
  check JSON diagnostics;
- future accepted adapter-facing behavior should be backed by tests before it
  is treated as stable.
