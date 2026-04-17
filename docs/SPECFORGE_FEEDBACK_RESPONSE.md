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
entry, and migration-hint availability. Failures outside the current
support-accounting classifier still emit JSON, but their code is `null` rather
than inventing a false stable identity.

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
check-only JSON path now. Full diagnostic schema stabilization remains a later
public API widening step.

### 4. Normalized Semantic Export

FSMGen should eventually expose a normalized JSON projection of accepted `.fsm`
semantics, for example:

```bash
fsmgen --strict --emit-normalized-json path/to/file.fsm
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
4. Add normalized semantic JSON export.
5. Use those surfaces to guide later language additions such as actor roles,
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
  machine-readable check/diagnostic surface;
- `docs/REGRESSION_CORPUS.md` and `FSM::Support::RegressionCorpus` are the
  current support-accounting source of truth behind that manifest;
- `FSM::Support::DiagnosticCodes` is the current stable diagnostic-code owner
  behind expected-failure corpus entries, the manifest registry, and bounded
  check JSON diagnostics;
- future accepted adapter-facing behavior should be backed by tests before it
  is treated as stable.
