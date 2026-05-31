# FSMGen Response To SPECFORGE Feedback

This document is FSMGen's tracked response to SPECFORGE's feedback in:

- `the external SPECFORGE feedback document`

It exists so SPECFORGE can align its `.fsm` adapter planning with FSMGen's
accepted direction without relying on transient chat context.

For bugs found while calling FSMGen, SPECFORGE should use the strict,
format-agnostic reproduction bundle protocol in
[docs/DOWNSTREAM_ISSUE_REPORTING.md](DOWNSTREAM_ISSUE_REPORTING.md). The
protocol does not require SPECFORGE to classify the root cause as `.fsm`,
`.isf`, lowering, reporting, HDL, or API behavior before filing; it requires
the exact FSMGen-facing artifacts, invocation, outputs, and expected/observed
behavior so FSMGen maintainers can reproduce locally.

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
[t/300-check-json-regression-corpus.t](t/300-check-json-regression-corpus.t).
The accepted side is also covered: supported-smoke entries must succeed through
`--check-json`, and strict-supported entries must succeed through
`--strict --check-json`, as locked by
[t/301-check-json-supported-corpus.t](t/301-check-json-supported-corpus.t).
Failures outside the current support-accounting classifier still emit JSON, but
their code is `null` rather than inventing a false stable identity.

### 3. Stable Diagnostic Codes

FSMGen should introduce stable diagnostic identities before exposing JSON
diagnostics as a public integration surface.

This first ownership slice now exists. The production registry lives in
[perl/FSM/Support/DiagnosticCodes.pm](perl/FSM/Support/DiagnosticCodes.pm),
every current `expected_failure` support-accounting entry carries a known
`FSMGEN_*` code, and the capability manifest exposes the registry plus those
entry-level codes. The requirement is stable machine identity across wording
improvements. Examples of the public shape:

- `FSMGEN_STRICT_INFIX_ASSIGNMENT`
- `FSMGEN_STRICT_LEGACY_FSM_ROOT`
- `FSMGEN_LANGUAGE_BAD_SIZE_ENTRY`
- `FSMGEN_COMPOSITION_MISSING_RTLIF`

Codes are regression-backed by
[t/248-regression-corpus-accounting.t](t/248-regression-corpus-accounting.t),
[t/297-capability-manifest.t](t/297-capability-manifest.t),
and
[t/298-diagnostic-code-registry.t](t/298-diagnostic-code-registry.t).
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

### 5. External HDL Validation

FSMGen now has a bounded generated-SystemVerilog validation lane:

```bash
fsmgen --verify-hdl path/to/file.fsm
```

`--validate-hdl` is the same mode. The command writes generated `.sv`, then
runs Verilator `--lint-only --sv` and ABC-free Yosys structural synthesis
through `read_verilog -sv -noautowire`, `synth -noabc -top`, and `stat` in
`FSM::Support::HDLExternalValidation`. Verilator is the generated-SV validity
gate; Yosys is the “can this become structural logic?” gate. ABC is
deliberately disabled until a later dedicated lane handles ABC-specific
timeout and mapping edge cases. This should be understood as a backend quality
gate for emitted HDL, not as a replacement for FSMGen's semantic, strict-mode,
and pre-generation checks. The lane is SystemVerilog-only for now; VHDL/GHDL
validation waits until FSMGen has a real VHDL backend.

### 6. Reset And Clock Contract Metadata

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
5. Keep generated-SystemVerilog external validation available as a backend
   gate without letting Verilator/Yosys replace internal semantic validation.
6. Keep the typed extension/context contract, sanitized composition-report
   contract, and in-process `HDLGenerator` result contract explicit and bounded
   while raw nested compatibility payloads still contain live Perl objects.
7. Use those surfaces to guide later language additions such as actor roles,
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
- composition provenance now has a bounded sanitized report fragment advertised
  through the capability manifest and exported under
  `semantic.composition.provenance_report`, while raw `composition_report` and
  `composition_plan` remain in-process payloads rather than JSON APIs;
- `fsmgen --verify-hdl path/to/file.fsm` / `--validate-hdl` is the optional
  generated-SystemVerilog backend validation lane using Verilator and Yosys
  when those tools are installed;
- `docs/REGRESSION_CORPUS.md` and `FSM::Support::RegressionCorpus` are the
  current support-accounting source of truth behind that manifest;
- `FSM::Support::DiagnosticCodes` is the current stable diagnostic-code owner
  behind expected-failure corpus entries, the manifest registry, and bounded
  check JSON diagnostics;
- future accepted adapter-facing behavior should be backed by tests before it
  is treated as stable.

## 2026-05-29: Diagnostic-Precision And Book-Coverage Status

This addendum records the diagnostic-precision and book-coverage
work shipped on the `R14` ISF lane this cycle, so a downstream
consumer such as SPECFORGE can read the current rejection surface
without diving into commit history.

### Targeted rejection diagnostics

Each phrase below is the verbatim text the validator emits.

- **`Transaction '<tn>': repeat-body generated do target '<target>'
  is in a different clock domain than the calling transaction;
  cross-domain repeat-body do remains deferred`** — fires when a
  repeat-body `(do TARGET (domain X))` annotation names a domain
  different from the calling transaction's. Same diagnostic with
  `when-body nested repeat` / `switch-branch nested repeat` prefix
  for the nested-repeat sites. Locked by
  [`t/1372-isf-cross-domain-repeat-body-do-diagnostic.t`](../t/1372-isf-cross-domain-repeat-body-do-diagnostic.t).
- **Activation-override sub-axis diagnostics**: the previously
  aggregated "static-timing parameter" gate now splits into four
  sub-axis diagnostics — `repeat-count parameter`, `wait-count
  parameter`, `latency-bound parameter`, and `watchdog-limit
  parameter` — each paired with the matching `... repeat counts
  remain deferred`, `... wait counts remain deferred`, `... latency
  bounds remain deferred`, `... watchdog limits remain deferred`
  phrase. Locked by
  [`t/1373-isf-timing-param-sub-axis-diagnostic.t`](../t/1373-isf-timing-param-sub-axis-diagnostic.t).
- **Loop-contained repeat-body local `do` and same-domain generated `do` are
  now shipped.** A plain local `(do child)` and a same-domain generated
  `(do child (params ...))` (with `(bind ...)`/`(domain NAME)` when static
  params are present) inside a `(repeat ...)` directly in a single
  `(while ...)`/`(until ...)` body lower; a generated `do` instantiates its
  child in the `_top` composition. (The basic `spawn` + same-body drain subset
  is also shipped — see the spawn entry below.) Inside a loop-contained repeat,
  a cross-domain generated `do` fires `Transaction '<tn>':
  repeat-body generated do target '<child>' is in a different clock domain
  than the calling transaction; cross-domain repeat-body do remains deferred`,
  and a repeat reached through an additional branch/loop ancestor fires
  `Transaction '<tn>': loop-contained repeat-body do remains deferred`. Locked
  by
  [`t/1379-isf-loop-contained-repeat-body-local-do.t`](../t/1379-isf-loop-contained-repeat-body-local-do.t),
  [`t/1380-isf-loop-contained-repeat-body-generated-do.t`](../t/1380-isf-loop-contained-repeat-body-generated-do.t),
  and
  [`t/1374-isf-loop-contained-repeat-body-activation-diagnostic.t`](../t/1374-isf-loop-contained-repeat-body-activation-diagnostic.t).
- **Deeper-nested repeat-body local `do` and same-domain generated `do` are
  now shipped.** A plain local `(do child)` and a same-domain generated
  `(do child (params ...))` inside a `(repeat ...)` reached through deeper
  branch nesting (`when⁺ → repeat`, `switch → when⁺ → repeat`) lower; a
  generated `do` instantiates its child in the `_top` composition. (The basic
  `spawn` + same-body drain subset is also shipped at deeper nesting — see the
  spawn entry below.) A deeper-nested cross-domain generated `do` fires
  `cross-domain repeat-body do remains deferred`. Locked by
  [`t/1381-isf-deeper-nested-repeat-body-local-do.t`](../t/1381-isf-deeper-nested-repeat-body-local-do.t),
  [`t/1382-isf-deeper-nested-repeat-body-generated-do.t`](../t/1382-isf-deeper-nested-repeat-body-generated-do.t),
  and
  [`t/1375-isf-deeper-nested-repeat-body-activation-diagnostic.t`](../t/1375-isf-deeper-nested-repeat-body-activation-diagnostic.t).
- **Loop-contained / deeper-nested repeat-body `spawn` (+ same-body drain) is
  now shipped at the lowering + composition level.** The basic `(spawn child as
  inst)` + same-body `(await_all done)` (or single-pending `(await_any done)`)
  drain inside a loop-contained or deeper-nested repeat lowers; the spawn is
  drained before `repeat_check` loops / the loop re-enters, and the child is
  instantiated in the `_top`. This matches the already-shipped top-level
  repeat-body spawn — including its **pre-existing full-HDL limitation**:
  `--check-json` fails for repeat-body spawn at any nesting because the
  composition planner references the repeat-count / loop-condition parent inputs
  as child endpoints (`instance '<inst>' has no port named 'loops'/'cond'`; see
  `docs/COMPOSITION_SCOPE.md`). A multi-pending `(await_any done)` observation
  followed by a later same-body `(await_all done)` drain is also supported in
  these contexts (as at top-level / when-body / switch-branch). An undrained
  spawn fires `... repeat-body spawn requires same-body '(await_all done)' or
  single-pending '(await_any done)'` (a multi-pending `(await_any done)` without
  a later `(await_all done)` trips this same drain requirement), and a
  cross-domain spawn target stays deferred. Locked by
  [`t/1383-isf-loop-and-deeper-repeat-body-spawn.t`](../t/1383-isf-loop-and-deeper-repeat-body-spawn.t)
  and
  [`t/1384-isf-loop-and-deeper-repeat-body-multi-pending-awaitany.t`](../t/1384-isf-loop-and-deeper-repeat-body-multi-pending-awaitany.t).

### Book example correctness build gate

`docs/book/src/12-cookbook.md`, `13*.md`, and
`14-feature-backlog.md` now distinguish `lisp` and `text` code
blocks by intent:

- `lisp` blocks are accept-path fixtures and must parse + lower
  cleanly through `FSM::Adapter::ISF` + `FSM::Scheduler::ISF`.
- `text` blocks are schematics, elided actor bodies, or
  rejected-shape illustrations and are not validated.

The convention is enforced by
[`t/1376-isf-book-example-lowering-audit.t`](../t/1376-isf-book-example-lowering-audit.t),
which extracts every `lisp` block from the 13 ISF book chapters
and verifies parse + lower for any block starting with `(actor`.
Any lowering failure blocks the test suite. Current state: 20
complete fixtures lower cleanly, 236 fragments correctly skipped.

### Cookbook ISF recipes

`docs/book/src/12-cookbook.md` recipes 9-13 cover the core ISF
authoring surface (basic actor, spawn, parameterized blocking do
with same-value override, rule trigger, repeat-body local do).
Each recipe includes a `**Walkthrough.**` paragraph that names
every top-level clause used by the recipe in source order and
explains its contribution to the lowered schedule.

### Audit set

The current ISF book/spec audit family is:

- [`t/1305-isf-book-feature-matrix-audit.t`](../t/1305-isf-book-feature-matrix-audit.t)
  — feature-matrix consistency.
- [`t/1307-isf-loop-body-doc-truth-audit.t`](../t/1307-isf-loop-body-doc-truth-audit.t)
  — loop-body doc truth.
- [`t/1332-isf-atl-doc-status-audit.t`](../t/1332-isf-atl-doc-status-audit.t)
  — ATL doc status.
- [`t/1376-isf-book-example-lowering-audit.t`](../t/1376-isf-book-example-lowering-audit.t)
  — book example lowering.
- [`t/1250-isf-spec-focused-test-index-audit.t`](../t/1250-isf-spec-focused-test-index-audit.t)
  — focused-tests list consistency with the actual `t/*.t` set.

`docs/audits/ISF-MDBOOK-COVERAGE-AUDIT-2026-05-27.md` records the
broader audit plus example-correctness addendum that surfaced
this work.

## 2026-05-29: Actor-Local `(types)`↔`(enums)` Relationship Clarity

This answers the 2026-05-29 clarity request in SPECFORGE's
`docs/FSMGEN_FEEDBACK.md` on whether an enum name is also a scalar type
alias, whether co-declaration is a conflict, and whether unreferenced
declarations are valid. The answers below were established by probing the
live `bin/fsmgen` at HEAD (not read off the docs) and are now locked by
[`t/1378-isf-enum-type-relationship.t`](../t/1378-isf-enum-type-relationship.t),
so the rule is executable.

### Question 1 — does `(enums (NAME ...))` alone establish `(type NAME)`?

**No.** An `(enums (NAME ...))` declaration establishes only the enum
member-value family `NAME`. It does **not** also establish a scalar type
alias named `NAME`. Using `(type NAME)` on a width-bearing interface port,
transaction-local port, or storage variable when only `(enums (NAME ...))`
is declared fails closed before lowering:

```text
Error: actor '<actor>' interface port '<port>' references unknown type 'NAME'
```

### Question 2 — is co-declaring `(type NAME (bits k))` + `(enums (NAME ...))` a conflict?

**Neither a conflict nor mere redundancy — it is the intended and required
mechanism** for using an enum name as a width-bearing type. Co-declaring the
same `NAME` in both `(types ...)` and `(enums ...)` is accepted: the two
occupy distinct declaration roles — `(type NAME (bits k))` is the scalar
width alias consumed by `(type NAME)`, and `(enums (NAME ...))` is the
member-value family consumed by `NAME.MEMBER` references — so it is not a
redeclaration conflict. To make a recovered enum-like symbol usable as a
port/storage type, emit **both**.

Corollary relevant to deterministic emission: the backing `(bits k)` width
is the author's assertion and is **not** cross-validated against enum member
magnitudes (`(type mode (bits 1))` is accepted even with a member value that
needs more bits). SPECFORGE's planned `k = ceil(log2(member_count))` for a
dense `0..N-1` enum is therefore an appropriate, accepted choice.

### Question 3 — must actor-local `(types)`/`(enums)`/`(constants)` be referenced?

**No.** An unreferenced actor-local `(types)`, `(enums)`, or `(constants)`
declaration is contract-valid: it lowers cleanly and is preserved in its
scheduled `.fsm` review section (`+types` / `+enums` / `+constants`).

### Correction to SPECFORGE's pending "enums-standalone" reading

SPECFORGE's *enums-standalone* reading is correct **only** for a recovered
symbol that is never used as a width-bearing type — emitting
`(enums (NAME ...))` alone is fine there. But if a recovered symbol must be
used as `(type NAME)` on a port or storage variable, the emitter **must also**
emit the backing `(type NAME (bits k))`; the enum declaration alone will fail
closed as an unknown type. Co-declaration is safe and is the supported path.

### Where the rule now lives

- [`docs/ISF_PUBLIC_INTERFACE_CONTRACT.md`](ISF_PUBLIC_INTERFACE_CONTRACT.md)
  — actor-local-declarations section.
- [`docs/book/src/13j-type-enum-aggregate.md`](book/src/13j-type-enum-aggregate.md)
  — "Enum names are not type aliases" subsection with a runnable accept-path
  example (gated by `t/1376`).
- [`docs/ISF_DOWNSTREAM_INTEGRATION_SPEC.md`](ISF_DOWNSTREAM_INTEGRATION_SPEC.md)
  — section 11.6.1 Enum, Type, And Aggregate Boundary.

## 2026-05-31: Cross-Domain Activation Via A Declared Crossing (shipped end-to-end)

A blocking cross-domain `(do child)` — where the calling transaction and `child`
run in different clock domains — now lowers end-to-end through a declared
crossing, complementing the shipped event crossing.

Surface:

```lisp
(crossings
  (activation worker (from core) (to bus)))
```

What SPECFORGE can plan around now:

- `(crossings (activation child (from SRC)(to DST)))` owns a top-level blocking
  `(do child)` where `child` is a transaction in domain `DST` and the caller is
  in `SRC`. The start/done handshake signals are compiler-internal; only the
  crossing is declared.
- One activation crossing auto-generates **two** acknowledged single-bit event
  CDC children: a `start` synchronizer (SRC → DST) and a `done` synchronizer
  (DST → SRC). Each reuses the existing `FSMGEN_ISF_CDC_EVENT` primitive,
  generated module shape, and reset metadata.
- Lowering partitions the actor into `<actor>__domain_<SRC>.fsm`,
  `<actor>__domain_<DST>.fsm`, and `<actor>_top.fsm`; plain HDL generation emits
  those two domain modules, both CDC child modules
  (`<actor>__cdc_activation_<child>_{start,done}`), and the top. Per-domain
  modules pass external Verilator lint + yosys synthesis; the composition top
  carries the same pre-existing `shared_dp_export_*` lint characteristic as
  multi-domain event crossings.
- The schedule report (`report(...)` / `--emit-schedule-json`) exposes the
  crossing as a `crossings` entry with `kind: "activation"` carrying `child`,
  `source_domain`, `destination_domain`, `start_signal`, `done_signal`,
  `start_instance`, `start_module`, `done_instance`, `done_module`,
  `outstanding_policy` (`single_outstanding_acknowledged`), `payload` (`none`),
  and `top_fsm`. Each participating domain carries a per-domain endpoint
  `{ activation, role: source|destination, start, done }`.
- Runtime semantics: at most one activation outstanding; the caller awaits the
  start synchronizer's `ready`, pulses a one-cycle request, and blocks on the
  done pulse; the child is gated on the start pulse and acknowledges by pulsing
  done after awaiting the done synchronizer's `ready`. No same-cycle relationship
  is promised; there is no data payload on the activation handshake.

Fail-closed boundaries (unchanged philosophy — a declared crossing must own the
path): a cross-domain `(do)` with no covering activation crossing, a
declared-but-unused crossing, a crossing whose `child` is not in the declared
destination domain, cross-domain `(spawn)`, and nested cross-domain `(do)`
(inside `repeat`/`when`/`switch`) all fail closed.

Verification: [t/1387-isf-cross-domain-activation-handshake-lowering.t](../t/1387-isf-cross-domain-activation-handshake-lowering.t)
(end-to-end lowering through both CDC children, await-ready handshake, schedule
report metadata, and the fail-closed cases); the runnable book example in
[docs/book/src/13a-actor-interface.md](book/src/13a-actor-interface.md) lowers
and generates HDL; full `./bin/ci-regression isf` passes.

Updated documents:

- [`docs/book/src/13a-actor-interface.md`](book/src/13a-actor-interface.md) —
  Activation Crossing section + runnable example.
- [`docs/ISF_DOWNSTREAM_INTEGRATION_SPEC.md`](ISF_DOWNSTREAM_INTEGRATION_SPEC.md)
  — activation crossing primitive rules.
- [`docs/ISF_PUBLIC_INTERFACE_CONTRACT.md`](ISF_PUBLIC_INTERFACE_CONTRACT.md) —
  activation crossing report shape + test reference.
