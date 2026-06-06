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
The lowered-RTL layer now advertises bounded output-drive family entry schemas
and selector-conflict entry schemas instead of leaving those payloads only
sample-implied.
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
timeout and mapping edge cases. The bounded support/manifest surface now also
reports optional ABC executable discovery candidates (`yosys-abc`,
`berkeley-abc`, and `abc`) for planning visibility, but ABC is not a required
tool and is not run by `--verify-hdl`. This should be understood as a backend
quality gate for emitted HDL, not as a replacement for FSMGen's semantic,
strict-mode, and pre-generation checks. The lane is SystemVerilog-only for now;
direct VHDL generation has a scaffold subset, including delayed-pulse
clock-branch lowering, generic-bearing direct-root module headers with typed
scalar/vector sized-literal defaults, binary scalar addition/subtraction RHS
lowering, and same-width addition/subtraction/multiplication, division/modulo, and XOR
RHS/chain lowering, but VHDL/GHDL validation waits for a separate GHDL
validation lane.

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
  current expected-failure entries; its contract now also advertises explicit
  optional semantic success children for `semantic.composition` and
  `semantic.symbol_contract`, plus lowered-RTL selector-conflict target
  count/list metadata and bounded `selector_conflict_targets[]` /
  `rhs_enable_families[]` entry and selector assertion metadata keys, and
  structural-RTL `auxiliary_assignments[]` scalar-string assignment-line
  entries, `ports[]` core plus composition-top extension entry keys and
  `nets[]`, `declared_links[]`, `resolved_links[]`, and shallow
  `instances[]` plus nested `instances[].interface_ports[]`,
  `instances[].parameter_overrides[]` core/raw-value/value-metadata entry keys,
  and `instances[].port_bindings[]` core/typed-extension entry keys;
- `FSM::Pipeline::HDLGenerator->generate_hdl_from_file(...)` now has a bounded
  top-level result-presence contract advertised through the capability
  manifest, while the raw result hash is explicitly not a JSON-safe interchange
  document;
- `embedding.serializable_generation_result_snapshot` now advertises the
  JSON-safe `HDLGenerator` result summary contract directly while preserving
  the existing
  `embedding.serializable_plan_reports.generation_result_snapshot_contract`
  reference for plan/report compatibility;
- `embedding.hdl_generator_facade` now advertises the current
  `flattened_debug_first` generation mode and keeps `generation_mode` out of
  the public constructor options until a real non-flattened backend path is
  implemented and regression-backed;
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

## 2026-06-04: First-Class LTL/MTL Temporal Properties — Already Generalized In The Verification Family

This answers the 2026-06-04 suggestion in SPECFORGE's `docs/FSMGEN_FEEDBACK.md`
("first-class LTL/MTL temporal properties in ISF"), which asks whether FSMGEN
would generalize the `(contract <n> (eventually <signal> (within <N>)))` special
case into the full `G(antecedent -> [X | F[min,max]] consequent)` template so
SPECFORGE can lower mined `temporal_rules` directly into ISF.

**Short answer: yes — and it already shipped, as a generalization rather than a new
named construct.** The suggestion reviews the `88a7af9c` pin, where the only temporal
form was the standalone `(contract … (eventually s (within N)))` clause. Since then
FSMGEN has **removed that clause** and replaced it with a *compositional temporal-
property language* inside the unified verification family `(assert/assume/cover …)`,
plus trigger anchors and a synthesizable-monitor output mode (decisions
`docs/decisions/0008` headline + `docs/decisions/0009`; documented and test-gated in
`docs/book/src/13d-control-flow.md`). That surface expresses the requested
`G(ante -> X|F[min,max] cons)` template directly, and is strictly **more general**
than SPECFORGE's per-rule template because the antecedent and consequent are
arbitrary boolean expressions (so any predicate conjunction), not a fixed predicate
list. The spec→checkable-property loop therefore already closes inside
`IntentIR → .isf → FSMGEN`; the FSMGEN-native option SPECFORGE was weighing against
its own `TEMPORAL-RULE-SVA-RENDER` PSL/SVA export **exists today**, which likely makes
that export unnecessary.

### The `G` tick domain is the actor clock

A verification clause lowers to a **clocked concurrent** SV property sampled at the
actor's declared clock with reset-gating:
`<kind> property (@(posedge clk) disable iff (!rst_n) (<prop>))`. So the universal
`G` ranges over the actor's clock edges automatically — there is no per-rule
`(clock …)`/`(edge …)` to emit. The tick domain is whatever the actor's `(clock)` /
`(reset)` declare; the sampling edge is the rising edge (`posedge`). Multi-clock
intent is partitioned by clock domain and bridged with declared `(crossings …)`
(see the 2026-05-31 activation-crossing addendum), not by per-property clocks.

### 1:1 mapping — SPECFORGE template → ISF spelling

`A`, `B` below are ordinary ISF boolean expressions; a **predicate conjunction** is
just `(& p1 p2 …)`. "Sim" = verilator-simulable (emitted under `` `ifndef SYNTHESIS ``);
"Formal" = formal-only delayed-sequence consequent (emitted under `` `ifdef FORMAL ``);
"HW-sim" = lowered to synthesizable monitor hardware and therefore verilator-simulable.

| LTL/MTL | ISF spelling | Generated SVA (inside the clocked property) | Checkability |
| --- | --- | --- | --- |
| `G(A)` plain invariant | `(assert A)` | `(A)` | Sim |
| `G(A -> B)` overlap implication | `(assert (=> A B))` | `(A) \|-> (B)` | Sim |
| `G(A -> X B)` next | `(assert (=> A (next B)))` | `(A) \|-> ##1 (B)` | Formal |
| `G(A -> F[1,N] B)` bounded eventually | `(assert (=> A (within B N)))` | `(A) \|-> ##[1:N] (B)` | Formal |
| `G($rose(S) -> …)` event-anchored | `(assert (after S …))` | `$rose(S) \|-> (…)` | Sim if `…` same-cycle, else Formal |
| `F[0,N] S` from an anchor (the old `eventually`) | `(assert (monitor (within S N)))` | arm/age/fail monitor; property becomes `(!(<…>_fail))` | HW-sim |

The former `(contract … (eventually s (within N)))` (empty antecedent, `F[0,N] s`) is
the bottom row: `(assert (monitor (within s N)))`, anchored inline (its body position),
by event (`(after …)`), or by a named anchor (`(point …)` / `(at …)`). The monitor
accepts the same window sources the old clause did (positive literal, transaction/actor
scalar parameter, actor constant, qualified package scalar constant).

### Predicate sugar maps to ordinary boolean expressions

SPECFORGE's proposed `<pred>` kinds need no new ISF keywords — they are ordinary
boolean expressions today:

- `(value <sig> HIGH)` → `<sig>`; `(value <sig> LOW)` → `(! <sig>)`;
  `(value <sig> <VAL>)` → `(== <sig> <VAL>)` (including an enum member `NAME.MEMBER`).
- `(handshake <valid> <ready>)` → `(& <valid> <ready>)`.
- An antecedent/consequent **conjunction** → `(& p1 p2 …)`.

So `G((sel & !err) -> F[1,4] ack)` is `(assert (=> (& sel (! err)) (within ack 4)))`.

### Two honest deltas (candidate slices, only if SPECFORGE actually mines them)

These are the only places the current surface is *narrower* than the fully general
`F[min,max]` + the proposed `<pred>` set. Neither is shipped; each would be its own
task-tree-owned slice (parsed, validated, normalized, documented, support-accounted,
lowered honestly), per this document's standing "no unchecked annotations" rule:

1. **Arbitrary lower bound `min > 1`.** ISF spells `##1` (`next`) and `##[1:N]`
   (`within`) — i.e. `F[1,N]` — plus the `F[0,N]`-from-anchor monitor. A general
   `##[min:max]` with `min > 1` (e.g. `F[2,5]`) has no spelling yet. If SPECFORGE's
   mined `cycle_window` ever carries a non-trivial `min`, that is a concrete, bounded
   operator to add (a `(within B (min M) (max N))` form, say); if `min ∈ {0,1}` covers
   the mined corpus, nothing is needed.
2. **`(stable <sig>)`.** A `$stable`-style "unchanged across the tick" predicate is not
   yet an ISF property primitive. Today a stability obligation either stays a SPECFORGE
   residual or is expressed indirectly (e.g. equality against a sampled prior value).
   If SPECFORGE needs stability obligations *as ISF properties*, that motivates adding a
   `stable` leaf to the property expression language — again, its own verified slice.

### What SPECFORGE can plan around now

- Lower mined `TemporalRuleRecord`s into `(assert (=> <ante> <cons>))` /
  `(assert (after <S> <cons>))` / `(assert (monitor (within <S> <N>)))` using the
  mapping above; drop the standalone `(contract …)` / `(eventually …)` spelling (removed).
- Re-pin past `88a7af9c` to pick up the verification-family generalization (the
  `(contract …)` clause is gone at the current tip; the property language + triggers +
  monitor are its replacement).
- Treat the delayed-consequent forms (`next` / `within` inside `=>` / `after`) as
  **formal-only**, and prefer `(assert (monitor (within S N)))` when a verilator-simulable
  bounded-eventually is wanted.
- This is a **feature suggestion, not a bug report**: no SPECFORGE `.isf` is broken, and
  SPECFORGE does not emit temporal rules into ISF today. If the two deltas above turn out
  to be load-bearing for SPECFORGE's mined corpus, file them (a short note here or a
  reproduction per `docs/DOWNSTREAM_ISSUE_REPORTING.md`) and FSMGEN will scope each as an
  owned slice.

Where the surface lives: `docs/book/src/13d-control-flow.md` (the `(assert …)`,
"Temporal properties", "Trigger anchors", "Synthesizable-monitor output mode", and
"Named anchors" sections), gated by `t/1376-isf-book-example-lowering-audit.t`;
decisions `docs/decisions/0008` and `docs/decisions/0009`.

## 2026-06-04 (follow-up): the two flagged deltas — `(stable …)` shipped, `min > 1` windows proposed

The 2026-06-04 LTL/MTL response above flagged two spots where ISF was narrower than the
fully general `F[min,max]` + predicate set, as candidate slices "only if SPECFORGE
actually mines them." SPECFORGE confirmed (in `FSMGEN_FEEDBACK.md`) it mines **both** and
asked FSMGEN to add the primitives. Status of each:

### (1) `(stable …)` and the sampled-value predicates — **shipped** (re-pin to pick them up)

FSMGEN shipped the SystemVerilog sampled-value functions as property leaves in
`ISF-PROPERTY-SAMPLED-VALUE.2` (commit `6700fbb4`, **after** the `43b29f5c` pin SPECFORGE
re-pinned to), so they are not yet in SPECFORGE's tree:

| ISF | SystemVerilog | SPECFORGE `<pred>` |
| --- | --- | --- |
| `(stable SIG)`  | `$stable(SIG)`  | `(stable <signal>)` — exact match |
| `(changed SIG)` | `$changed(SIG)` | (the negation; also mined) |
| `(rose SIG)`    | `$rose(SIG)`    | edge form of `(value … ASSERTED)` |
| `(fell SIG)`    | `$fell(SIG)`    | edge form of `(value … DEASSERTED)` |

They are property leaves usable standalone or as an `=>`/`after` antecedent/consequent —
`(assert (=> valid (stable data)))` → `(valid) |-> ($stable(data))` — verilator-simulable
(not a `##` sequence), operand kept alive, and **property-only** (fail closed in a
synthesizable expression position). With this, SPECFORGE's full `<pred>` set lowers to ISF:
`(value sig HIGH/LOW/V)` → `sig` / `(! sig)` / `(== sig V)`, `(stable sig)` → `(stable sig)`,
`(handshake v r)` → `(& v r)`. **Action for SPECFORGE:** re-pin `subs/fsmgen` past `6700fbb4`
and migrate the mined stability obligations off residuals into
`(assert (=> <ante> (stable <sig>)))`. Documented in `docs/book/src/13d-control-flow.md`
("Sampled-value predicates"), gated by `t/1417-isf-property-sampled-value.t`.

### (2) `min > 1` windows (`F[min,max]`, `min > 1`) — proposed shape, FSMGEN will own it

This remains the one genuine open delta. Today ISF spells the lower bound implicitly:
`(within B N)` → `##[1:N]` (= `F[1,N]`), `(next B)` → `##1` (= exactly the next cycle), and
the `(monitor (within S N))` mode covers `F[0,N]` from an anchor. There is no spelling for
`##[min:max]` with `min > 1` (e.g. `F[2,5]` — "between 2 and 5 cycles later").

Proposed ISF shape — a backward-compatible **third operand** on the existing `within`
(which is SPECFORGE's `(window <min> <max>)` modifier):

```text
(within B N)        -> ##[1:N]      (unchanged; F[1,N])
(within B MIN MAX)  -> ##[MIN:MAX]  (new; F[MIN,MAX], literal 1 <= MIN <= MAX)
```

So `G(req -> F[2,5] ack)` is `(assert (=> req (within ack 2 5)))` → `(req) |-> ##[2:5] (ack)`.
Like every `##` sequence it is **formal-only** (emitted under `` `ifdef FORMAL ``;
verilator/yosys skip it, so `--verify-hdl` stays green). FSMGEN will own this as a bounded
slice (parser arity extension in `parse_check_property` + the `##[MIN:MAX]` render, with the
existing aliveness/checkability walks already covering the leaf). **One confirmation before
we lock the form:** are SPECFORGE's mined `cycle_window` bounds always integer literals with
`MIN >= 1`, or can `MIN` be `0` (which is the `(monitor …)` / anchored-`F[0,N]` case, not a
`|-> ##` consequent)? That determines whether `(within B 0 MAX)` should be accepted or
redirected to the monitor form.

**Update — `min > 1` shipped (`ISF-PROPERTY-WINDOW-RANGE.2`).** SPECFORGE confirmed
(`FSMGEN_FEEDBACK.md`, "Answer (2026-06-04)") that mined `cycle_window` bounds are integer
literals and guaranteed `1 <= MIN <= MAX` for the `|-> ##` consequent (a `MIN = 0` is
resolved SPECFORGE-side — `[0,0]` → residual, `[0,N]` → the `(monitor …)` form). FSMGEN
locked the form to that range and shipped it: `(within B MIN MAX)` → `##[MIN:MAX]` (the
existing `(within B N)` = `##[1:N]` is unchanged); `MIN = 0`, `MIN > MAX`, non-literal
bounds, and the wrong arity all fail closed. It is formal-only (`` `ifdef FORMAL ``).
Documented in `docs/book/src/13d-control-flow.md` (the "Delayed consequents" part, with a
runnable `delayed_ack` example) and `13k`; locked by `t/1418-isf-property-window-range.t`.

Net: **both** flagged deltas are now shipped in FSMGEN. **Action for SPECFORGE:** re-pin
`subs/fsmgen` past the `min > 1` commit and migrate the mined stability + `min > 1`
obligations off residuals into `(assert (=> <ante> (stable <sig>)))` and
`(assert (=> <ante> (within <cons> MIN MAX)))`. The `IntentIR → .isf → FSMGEN` loop now
carries the full mined temporal-rule surface.
