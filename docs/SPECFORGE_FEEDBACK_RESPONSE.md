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

## 2026-10-22: Request .12 unary source milestone; delivery pending

Decision `0117` selects unary `(^ X)`, `(& X)`, `(| X)` and grouped
`(reduce-groups OP X N)`, with positive literal N, least-significant group
first and an unpadded short final group. Unary declared scalar/slice/bit source
forms now enter canonical IAL0. Successful ISF check/semantic reports expose
`source.reductions`; schedule reports expose `reductions`, with detached
owner/context/operator/operand and exact operand/result widths. Try the
`isf/unary_reductions.isf` fixture using the three commands below with that path.
The supplied fixed-slice parity source now strict-checks locally. Broader
qualification also preserves delegated whole-storage sampling when an unrelated
reduction is added; whole-record port sampling remains refused. Unary forms
also survive formal-port rewriting with their own declared operand widths and
authored report identities. A separately tracked existing compatibility defect
rejects private input-formal assignments when the actor also has a record
interface port; `ISF-REDUCTION-DELIVERY.8` owns the repair before remaining
aggregate consumer signoff. Read-only formal reductions remain supported.
Declared clock/reset samples and their chains also preserve their scalar widths
through actual source, carriers and public reduction records. Runtime reduction
operands also retain their declared actor-pin or nearest-formal widths when a
direct transaction count parameter has the same name. Standalone waits keep
their static count; generated-child parameters retain static expression scope.
The repair reuses canonical placement and preserves authored public records.
Domain validation also preserves standalone static wait/repeat counts after
formal rewriting; those tokens do not read a same-named foreign-domain wire.
Runtime expression counts, guards and body reads retain crossing checks.
Qualified enum/package constants also retain their static identity when a
record input has a matching root/member. Invalid static reductions now refuse
consistently in check, semantic and schedule preview before carrier emission.
Record-field scalar sample chains retain their exact signed/four-state,
unsigned/two-state or unspecified-state types in actual IAL0 and semantic nets.
These checks establish source/type preservation; X/Z execution remains unqualified.

`ISF-REDUCTION-DELIVERY.1.2.2` owns this integration. Broader source/profile,
corpus and actual HDL behavior qualification remain `.1.2.3`–`.1.4`; this is
not complete R1 delivery. Parameter-dependent grouped behavior (R2/R3),
publication and SPECFORGE integration are still pending. No default-width
unroll substitutes for generic behavior. Logical `!` stays Boolean; optional
vector inversion is separately owned. **SPECFORGE `.46.c` remains blocked.**
Requests `.7`/`.8`/`.9`/`.10` retain the boundaries below.

## High-Level Response

### SPECFORGE request handoff — 2026-10-21

FSMGen acknowledges receipt of all five supplied packets, `FSMGEN-REQUESTS.7`–`.10`
and `.12`. Requests `.7`–`.10` already had FSMGen owners; `.12` is now retained
and assigned to SEM `.92`. Forwarding these packets again is not a prerequisite. The SPECFORGE records
still say `signed_off` with `forwarded: null`; that foreign tracking state was
read only and has not been changed here. Receipt, implementation and downstream
integration are separate milestones.

| SPECFORGE request | FSMGen disposition | What SPECFORGE can use / what remains |
| --- | --- | --- |
| `.7` — physical-time durations | Accepted; SEM `.60.1`; implementation open. | Existing cycle-count bounds remain available. Physical units, declared clock-rate conversion and counter-based duration waits are not delivered. Contract selection is `.60.1.2`; FSMGen owns conversion, directed rounding, parameter override/count-width behavior and reports. Do not invent a clock rate or unroll a large duration as an implied substitute. |
| `.8` — named timers | Accepted; SEM `.60.2`; implementation open. | Existing transaction watchdogs retain their error-path meaning. They do not provide concurrent named timers or ordinary expiry conditions. Contract selection is `.60.2.2`; cycle-based timers can be delivered independently of physical-time units. Start/restart/stop, reset/control precedence, concurrent expiry and reports remain required. |
| `.9` — unstated reset | Answered; SEM `.60.3` done. | Omitted legacy reset selects asynchronous active-low `rst_n` and reports `legacy_default`. An explicit reset reports `explicit`. A clock-only named domain has no reset, reports `domain_absent`, and does not guarantee startup state or values. No form leaves reset policy unresolved until instantiation. SPECFORGE must decide whether its adapter may accept the compiler default; details and report locations are in the dated answer below. |
| `.10` — aggregate interface ports | Accepted; SEM `.60.4`; partial delivery. | The qualified packed-record input subset is available locally: local/imported types, scalar field reads, exact-type input-to-storage copies, public reports, and the documented SystemVerilog profile. Whole record outputs/copies have bounded source/carrier/public admission. Generated output handoffs, output member writes and output execution/full consumer signoff remain open; list-root ports and variants remain optional. Do not close the complete request on input delivery alone. |
| `.12` — byte-group reductions | Accepted; SEM `.92`; implementation open. | The unrolled baseline and declared unary XOR slice now pass locally; full unary qualification and parameterized groups remain open. Required unary XOR/AND/OR, parameter-correct grouped reductions (including a short final group), target-width diagnostics, FSM/HDL and public reports are owned by `.92.1`–`.92.4`; optional vector inversion is `.92.5`. SPECFORGE `.46.c` stays blocked until the new form is qualified, published and integrated. |

**Availability:** the reset answer and record-input changes are committed in
this FSMGen checkout. Read-only `git ls-remote` on 2026-10-21 confirms published `main` is still
`54ac1c22d5314943027494f4c270f9c612e62704`; it predates these changes.
The exact receipt is in `docs/audits/specforge-request-status-20261021/`.
An old SPECFORGE pin cannot consume later local commits. A qualified publish followed by SPECFORGE's own
pin refresh and bundle/integration checks is still needed. FSMGen will publish
an exact revision and documented subset; no SPECFORGE pin or repository is
changed here. Required full-CI and historical qualification gates remain owned.

For bounded integration checking after an appropriate revision is available:

```bash
./bin/fsmgen --strict --check --json isf/record_input.isf
./bin/fsmgen --strict --emit-semantic-json isf/record_input.isf
./bin/fsmgen --emit-schedule-json isf/record_input.isf
```

Use `isf/record_input_children.isf` for the documented generated/domain input
subset, and SystemVerilog for its qualified HDL profile. Passing
`isf/record_output.isf` source checking does not establish the outstanding
output execution or generated-output support. Current bounded checks and
complete reports are retained in that audit directory; they do not rerun HDL
behavior or the caller corpus. Request `.12` has its own fresh local baseline in
`docs/audits/specforge-reduction-intake-20261021/`.

**Priority and completion:** the director requests these deliveries at the next
handoff-ready checkpoint on 2026-10-21, followed by a qualified push and a
response here. This supersedes ordinary independent-PNT ordering. Required
reduction contract selection is SEM `.92.1`; durations `.60.1`, named timers
`.60.2` and remaining required aggregate ports `.60.4` retain implementation
ownership. Their exact dependency order must follow the checked contracts,
including generic-width behavior, rather than making packet receipt or optional
extensions a completion condition. The reset question needs no new feature.
Publication remains SEM `.69` with the existing qualification gates; the new
push instruction does not assert those gates have passed.

**Handoff finding:** SPECFORGE's awaiting-forward register and FSMGen's existing
receipt/delivery records disagree for `.7`–`.10`. This response supplies the
FSMGen acknowledgement and exact remaining boundaries. SPECFORGE's owner can
reconcile its register against this response; no additional feature is implied
by that bookkeeping correction.


### Current delivery status — 2026-10-02

The requested feature set is not complete. This is the canonical downstream
response; status answers must be reflected here as well as in the task tree
and book.

- **Unstated reset:** answered in the dated question section below, committed
  in `f6c44aa5a4517967632d25c2a190d2f1c2e22f59`. Omission selects the documented
  legacy default; a clock-only domain means actual hardware without reset and
  no guaranteed initialization. No existing form defers reset policy to
  instantiation. Accepting compiler defaults remains SPECFORGE's decision.
- **Scalar storage access and domain storage reports:** delivered under
  SEM `.38.1` and `.38.3`; optional bank access remains open.
- **Packed record inputs:** local/imported actor input aliases, live scalar
  field reads and exact-type input-to-owned-storage copies are admitted in
  `25c01f0127144922ade78951b91439e1d9221c08`. Accepted nested/imported/shadow
  public sources and strict carrier replay are qualified under `.60.4.3.2.3.6.1`;
  local aliases to imported types are repaired under its child `.1`.
  Contextual public refusals are qualified under `.60.4.3.2.3.6.2`, including
  repair of scalar drive-parameter member access before product publication.
  Frontend closure is qualified under `.60.4.3.2.3.6.3`: unchanged supplied
  whole-copy/field-guard sources, prior scalar/storage products and complete
  public discovery are exercised. Generated/domain carrier structure and strict
  replay are qualified under `.60.4.3.2.4.1`, including reused readers, owned
  whole copies, unused declarations and embedded imported package context.
  Accepted generated/domain public products are qualified under `.60.4.3.2.4.2.1`,
  including complete native/API/newline reports, recursive typed child
  declarations and exact clock/reset provenance. Generated/domain contextual
  qualification has verified scalar named-drive selector identity repair under
  `.60.4.3.2.4.2.2.1` and generated scalar binding identity repair under
  `.60.4.3.2.4.2.2.2`. Contextual refusals and scalar shadows are qualified
  under `.60.4.3.2.4.2.2`; record binding actuals remain refused. Typed
  prior products and complete current declaration/discovery/catalog closure
  are qualified under `.60.4.3.2.4.2.3`. Generated/domain source, carrier and
  public qualification `.60.4.3.2.4` is complete; backend/native execution
  and consumer signoff remain `.60.4.3.2.5`. Its direct public-pin witness is
  prepared under `.5.1`. Corrected fixed observer qualification `.5.2` is
  complete, including fresh finite native controls and sealed independent
  verification. Genuine direct HDL behavior is qualified under `.5.3`: both emitted
  Verilog families pass entry/live/whole-copy, repeated-request and reset/abort
  public-pin checks; an actually compiled unsigned property counterexample
  reaches the expected signed mismatch. Complete sealed evidence is in
  `docs/audits/record-input-direct-observation-20261001/`. Binary execution
  does not establish X/Z behavior or historical native causality.
  Generated/domain runtime is now independently qualified under
  `.5.4.3.3.3`: named-domain spawned and ordinary blocking sources pass both
  Verilog targets, all copied packed leaves, completion-window binding checks,
  reused live reads, repeated requests, reset/abort and idle isolation. The
  actually compiled unsigned counterexample reaches the expected signed mismatch.
  Complete sealed evidence is
  `docs/audits/record-input-generated-observation-complete-20261001/`.
  Original typed-wire compile and blocking late-hold test failures remain
  preserved; their declaration and oracle repairs are qualified before this
  fresh run. Generated execution reconciliation `.5.4.4` is complete: the selected public,
  contextual refusal, package and prior scalar/storage contracts pass current
  checks, with unchanged source/producers and retained direct/generated evidence.
  Backend profile qualification `.5.5.1` retains precise VHDL refusals for the
  selected record inputs and generated tops, with no new destination or partial
  successful product and existing destinations preserved. Scalar VHDL input
  and prior packed-output controls remain admitted; no VHDL analyzer/runtime
  claim follows from emission. Existing bounded VHDL signed-scalar `+`/`-`/`*`
  one-bit operations use `xor`/`and`; division/modulo and mixed-sign scalar
  arithmetic remain refused. The qualified record-input HDL profile is
  SystemVerilog. Both emitter options passed binary behavior with `.sv` inputs
  and Verilator's default SystemVerilog parser. The historical `verilog` emission retained
  packed typedefs; these runs do not qualify IEEE 1364 Verilog-2005. P2 scope
  reconciliation `.5.5.3.2.1` preserves the genuine results and corrects the
  broader claim. `.5.5.3.2.2` now qualifies precise `verilog`/`v` refusal
  for declared ISF record inputs, naming actor/input/type and recommending
  SystemVerilog. Native and public generation preserve destinations and return
  no partial successful product; schedule preview stays target-neutral. Complete
  SystemVerilog RTL is unchanged apart from date banners. Original native
  two-emitter observations remain immutable; any new T2024/T2025 native run
  needs fresh observer qualification. Final public/corpus reconciliation `.5.5.2`
  qualifies supplied sources, all-section discovery, current catalog and JSON
  kinds, with unchanged complete-cohort and prior evidence. The feature matrix's
  stale public/runtime pending wording is corrected. Independent input signoff
  `.5.5.3.2.3` completes the selected R1–R3 input portions by joining the complete
  source, public, profile and original native evidence. Record outputs and their
  field writers are next under `.60.4.3.3` and `.60.4.3.4`; root-list ports and
  variants remain optional. Output ingress `.60.4.3.3.1` has selected the closed
  writer/source/qualification split. The valid imported type-token rejection in
  the preparatory physical-write collector is repaired under `.3.2`, with actual
  direct/generated/domain and scalar controls. Detached writer inventory
  `.3.3.1` now qualifies matching local/imported nested declarations, actual
  packed ranges, explicit state/rule/drive owners, domain realization,
  activation records and caller immutability. Conservative writer admission
  `.3.3.2` now qualifies sole writers, ordinary ordered states of one controller
  and disjoint physical targets. Unproved overlapping independent writers,
  duplicate active-container writes and timed operators refuse; equal values,
  entry conditions or priority declarations do not arbitrate. This is private
  preparation only. Source-context/domain preparation `.3.4.1` now qualifies
  output-only and mixed selection, exact whole-copy identity, typed scalar
  samples, declaration/shadow safety and output-field domain ownership. Its
  mandatory source policy keeps output member writes closed. Unsupported target
  profile preparation `.3.4.2` now qualifies precise prepared output refusals
  for `verilog`/`v` and `vhdl`, with actor/output/type reasons and SystemVerilog
  guidance. Existing input diagnostics, schedule preview and scalar/storage
  controls remain qualified. Declaration/whole-copy integration `.3.4.3` now
  admits local/imported/alias/mixed/unused record outputs, exact-type whole
  copies and scalar reads/samples through mandatory per-module physical writer
  admission. Actual direct/domain carriers strictly replay. Unproved overlapping
  independent writers refuse in both lower and report, including domain-local
  writers; equal values/entry guards/priority do not arbitrate. Output member
  writes and generated handoff mappings retain their separate gates. Complete
  public reconciliation `.3.4.4` is qualified. Its `.1` qualifies complete native,
  in-process API and actual newline check/semantic/schedule products for local,
  imported, forward aliases, mixed/reverse/unused and owning-domain outputs,
  with literal nested signed/state/list layouts and precise no-partial-product
  source/writer refusals. Actual target-profile atomic qualification `.2` now
  covers native/facade Verilog/v/VHDL errors, unchanged existing/absent
  destinations, complete machine failure products, neutral schedules and
  supported SystemVerilog/sv text. Exact predecessor preservation `.3` now
  qualifies the finite complete input/scalar/storage/native/API/newline/carrier
  and SystemVerilog products, retaining all failed capture controls and full
  responses. Its required selected decision-reader inventory blocker is repaired
  under child `.3.1`, with complete Git growth/overflow and authority controls
  inside the existing metadata byte budget. Child `.3.2` reconciles the canonical
  downstream integration/public contracts and rendered book with current typed
  actor ports, precise report/profile/writer boundaries and remaining deferrals.
  Its complete example passes actual public transports and strict carriers.
  Maintained corpus closure `.4` adds `isf/record_output.isf` with its precise
  supported phases and explicit nonclaims. Complete predecessor/current catalog,
  all query cohort applicability and all-section actual public discovery preserve
  existing records and account only that addition. T2037 qualifies independent
  literal recursive types, packing/kinds and shared-corruption refusal; actual
  strict carriers and SystemVerilog/sv text are retained. Canonical downstream
  integration/public parts and rendered book match, including residual stale
  deferral paragraphs. Bounded source/public/profile/corpus `.3.4.4` is complete.
  Generated-output ingress `.3.5.1` qualifies actual local/imported/spawned,
  parameterized blocking, owning-domain, reused-reader, unused-output and scalar
  shadow cases against native/API/newline products. The active record-output
  gate refuses child-bearing owning modules. Actual private products lack an
  owner-to-reader packet input and a child-write-to-owner route; both repairs
  are owned under `.3.5.2.1` and `.3.5.2.2`, followed by complete physical mapping
  admission `.3.5.2.3`. Direct/local `do`, input and scalar-storage controls pass.
  Scalar output siblings have successful schedules but strict realization
  rejects their unconnected ports. No HDL tool runs in this ingress slice.
  [Complete ingress evidence](audits/record-output-generated-ingress-20261002/scope.txt)
  preserves exact sources, callers, domains, transports, raw refusals and hostile
  independent controls. Output execution remains `.3.5.4`; generated output
  mappings, output field writes and full aggregate-interface delivery are open.
  Detached read preparation `.3.5.2.1.1` qualifies private typed input aliases,
  actual emitted operand roles and canonical local/static masking. It preserves
  record types, samples, write targets and one-bit child handshakes even when
  actor outputs are named `start` or `done`; production is not connected yet.
  [Preparation evidence](audits/record-output-owner-read-preparation-20261002/scope.txt)
  retains complete products and precise scalar controls. First-`when` action-loss
  repair (`.2.1.3`) now rejects unsupported entry actions while preserving inline
  samples and later branches. The same selector drops the true-path assignment
  of a first `select`; its conditional-macro source-intent repair (`.2.1.5`) is
  owned before read integration (`.2.1.2`). The independent literal repair
  (`.2.1.4`) preserves typed X/Z width/radix and prevents false operand errors
  or substitution of a declared signal named `x01`. First-operation select remains precisely
  refused until that repair qualifies. This work repairs existing **ISF/IAL1**
  parser expansions and transaction scheduling. Qualification also exposes
  first sample-only bit/field/`cond` shorthand admitted as entry gates and
  unexpanded `cond` in inline procedures. The normalization candidate would
  newly admit a first sample-only procedure `cond` as activation, so production
  stays unchanged and that source stays refused. Explicit source intent (`.5.2`)
  now precedes safe procedure normalization (`.5.4.2`) and branch integration
  (`.5.3`). [Safety qualification](audits/procedure-cond-normalization-20261002/scope.txt)
  retains the complete actual candidate admission and restored refusal.
  Detached parser-origin qualification (`.5.2.1`) preserves original operations
  and inline call sites with ordinary actors unchanged. Identical normalized
  clauses cannot identify authored intent. Local-source reload authenticity
  (`.5.2.2.1`) now requires independently supplied source and reconstructs the
  complete actor and ledger; a matching embedded digest cannot authenticate a
  substituted origin. Imports refuse at this private boundary. Imported
  provenance (`.5.2.2.2`) and formal/generated/domain propagation (`.5.2.2.3`)
  remain open before this becomes a scheduling repair.
  The same-source library producer slice preserves document/export/use
  provenance through actual cloning. Separate private document-set qualification
  now authenticates independently supplied complete root/external library bytes
  through canonical resolution and cloning, including exact repeated-alias
  constructor selection and identical actors with different original intent.
  [Document-set qualification](audits/conditional-origin-documents-20261002/scope.txt)
  retains genuine authentication-bypass failures. Packages, ATL and preparation
  adoption remain open. A reproduced private late-clone publication gap is fixed
  with final whole-edge/target/kind revalidation; the permanent regression and
  [final proof](audits/conditional-origin-documents-finalization-20261002/scope.txt)
  preserve its genuine failure and corrected complete products. Scheduling remains closed.
  The earlier cohort uses a supplied root with a non-file label and relative
  library search roots. Separate private file-backed qualification now reads
  actual roots, authenticates selected source bytes and preserves portable
  document identities across moved workspace roots and search precedence.
  Separate private ATL provenance now qualifies actual rebuilt library
  constructors and resolved static actor clones, including distinct use/ATL
  identities for identical complete actors. Final target/declaration/coverage
  changes refuse. [ATL proof](audits/conditional-origin-atl-20261002/scope.txt)
  retains complete sources/products, real missing-producer and forged-reload
  failures. The cohort covers one resolved static instance; groups and unresolved
  external intent remain closed in this authority. File-backed identity now
  qualifies through a separate observer, including original same-source intent
  across actual use/ATL rebuilding and forged-reload refusal.
  [File-backed proof](audits/conditional-origin-files-20261002/scope.txt) retains
  complete original bytes, portable products and independent counterfactuals.
  Preparation/adoption remain open before scheduling integration. The discovered
  lazy module-location initialization defect has its own repair leaf before
  preparation; private fixture bootstrap is explicit and does not fix production.
  [Origin qualification](audits/conditional-origin-parser-20261002/scope.txt)
  retains the complete parser evidence; public syntax and admission do not change.
  Use explicit activation before conditional shorthand and keep `cond` at the
  procedure call site for now. No new macro
  language/framework, output execution or X/Z runtime claim follows.
- **Physical-time durations and named timers:** baselines are qualified;
  the requested implementations remain open under SEM `.60.1` and `.60.2`.

Decision storage rollover is committed in
`df7f692c8b94b083d2d078d62854d37869fbca6d`. Fixed-commit consumer/question
closure is qualified in `5ef1133c59f6d1814ebe7d1bf95373bdd77cbbc8`; successful
production-cohort birth, malformed-product refusal and post-publication
identity/fact/question floors are also qualified. Rollover closure under
`.51.3.3.3.2` returned work to record-input frontend qualification
`.60.4.3.2.3.6`, which is now qualified. Required
duration/timer deliveries precede optional banks, list ports and variants.
Earlier configuration, verification and phase requests retain their tracked
owners. These statuses do not claim complete SPECFORGE implementation or
external integration signoff; no external checkout, pin or ticket is changed.

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
tool and is not run by `--verify-hdl`; in-process callers can explicitly opt
into ABC-backed Yosys mapping validation with `abc_mapping => 1`. This should
be understood as a backend
quality gate for emitted HDL, not as a replacement for FSMGen's semantic,
strict-mode, and pre-generation checks. The lane is SystemVerilog-only for now;
direct VHDL generation has a scaffold subset, including delayed-pulse
clock-branch lowering, generic-bearing direct-root module headers with typed
scalar/vector sized-literal defaults, scalar bit, signed vector, and
non-signed four-state logic internal declaration lowering, scalar
addition/subtraction/multiplication RHS/chain
lowering, vector numeric-literal addition/subtraction emitted by compound
update/shorthand forms, and same-width
addition/subtraction/multiplication, division/modulo, and XOR RHS/chain
lowering. Scalar division/modulo remains fail-closed in the direct VHDL
scaffold, aggregate-output direct roots remain fail-closed, composition/top
VHDL remains fail-closed after typed composition IR parsing, and VHDL/GHDL
validation waits for a separate GHDL validation lane.

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

## What Downstream Consumers Can Plan Around Now

Downstream consumers, including SPECFORGE, can rely on these FSMGen project
policies:

- strict mode is the preferred target for generated `.fsm`;
- compatibility syntax should not be treated as canonical adapter output;
- mdBook chapters are the public human-facing contract;
- `fsmgen --capability-manifest` is the first machine-readable support surface;
- `language_surface.file_surfaces` in the capability manifest is the
  machine-readable source of truth for shipped `.fsm`/`.isf`/`.ppif` suffixes,
  intent layers, lowering order, supported CLI modes, and per-suffix boundary
  text; the `.ppif` boundary is bounded public IAL2 that lowers through
  generated `.isf` before generated `.fsm`;
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

## 2026-06-16: Transaction Phase Membership Without Fabricated Values Or Order

This answers SPECFORGE's `2026-06-16` question about lowering grounded
transaction phase membership without inventing per-signal drive values or a
total step order.

Short answer: **SPECFORGE should not fabricate either value or order**, and
FSMGen does not need an immediate code change to answer that guidance. The
right future FSMGen feature, if this becomes load-bearing for `.isf`, is
checked transaction phase-group metadata in ISF. It should be selected and
implemented under a new task-tree owner before any parser/report behavior
changes.

### Value-less output participation

Do **not** reinterpret `(drive S)` as a participation marker. In today's ISF,
named `drive` calls are value-bearing behavior: a drive call starts a generated
drive DT and schedules an output update. Accepting a bare output drive, a hidden
don't-care actual, or a fake default value would blur "this source grounded
membership" into "generate behavior that drives something." That would be the
same fabrication SPECFORGE is trying to avoid.

For now, if SPECFORGE knows only that output `S` participates in transaction
`T` but does not know the value driven on `S`, keep that fact in SPECFORGE
IntentIR metadata/residuals and do not lower it as a transaction-body drive.
Only emit a `drive` call when the source grounds both the participation and the
value/behavior.

### Unordered or partial-order transaction facts

Do **not** encode unordered phase membership as transaction-body order. ISF
transaction bodies are intentionally source-ordered implementation steps: one
clause after another means FSMGen may schedule them in that order, and a
multi-pair drive block is same-cycle behavior only when the driven values are
grounded. A transaction body is therefore the wrong container for a set of
membership facts whose cross-phase ordering is not asserted by the source.

If SPECFORGE has only a set, or a partial order that is not yet expressible as
checked FSMGen behavior, it should preserve that fact outside the body until
FSMGen has a selected metadata/constraint surface for it.

### Phase-group metadata is the right future ISF shape

FSMGen agrees with the direction of a protocol-neutral **transaction
phase-group metadata** surface. The first safe version should be checked
metadata, not generated behavior. Conceptually it would carry facts like:

- the transaction name;
- authored phase/group names such as `address`, `data`, `setup`, `access`, or
  `response`;
- member signals per phase/group;
- actor-relative role/direction for each member, such as driven output or
  sampled input;
- optional provenance/residual notes when a phase order or value is not
  grounded.

The important first-slice rule is negative: this metadata must not imply
drive values, a total schedule order, HDL behavior, SV/UVM output, VHDL output,
or a public artifact until those effects have their own selected contracts.
Validation should still be real: signal names should resolve, directions
should match the actor interface, duplicate/malformed groups should fail
closed, and the schedule/report shape should be discoverable through the
public contract.

That future feature is adjacent to, but not the same as, the actor-level
`(observe NAME (role passive_monitor) (signals SIG...))` metadata that now
ships. `observe` is useful as passive public-signal observation input for
future verification tooling; it does not express transaction-specific phase
membership.

### Ordering as constraint versus ordering as body

When the source genuinely grounds executable step order and values, using the
transaction body is appropriate. When the source grounds only an obligation or
temporal relationship, that should be expressed through the verification
family (`assert`/`assume`/`cover`, `after`, `next`, `within`, monitors, and
sampled-value predicates) or through a future checked constraint/report
surface, not by pretending the body is an unordered fact bag.

So the division is:

- body clauses: grounded implementation behavior and source order;
- verification properties/constraints: grounded temporal obligations;
- future phase-group metadata: grounded membership/phase/role facts with no
  generated behavior until a later output contract consumes them.

### `.isf` versus a possible `.val`

`.isf` remains the source of truth for SPECFORGE's synthesizable path:

```text
SPECFORGE IntentIR -> .isf -> FSMGen scheduling -> .fsm -> HDL
```

Do not target `.val` instead of `.isf` for SPECFORGE's synthesizable ISF goal.
The `.val` idea, if FSMGen later selects it at all, is a Verification
Abstraction Layer for generated verification artifacts: a possible
target-neutral review/interchange artifact between `.isf`/schedule reports
and SV/UVM or VHDL-oriented verification output. It is not a replacement for
`.isf`, and it is not needed to answer this SPECFORGE request.

### What SPECFORGE can safely do now

- Keep transaction phase membership as IntentIR metadata/residuals when values
  or order are not grounded.
- Emit ISF transaction-body `drive`/`sample` steps only for facts whose values
  and ordering are grounded.
- Use existing ISF verification properties for genuinely grounded temporal
  obligations.
- Treat future checked transaction phase-group metadata as the right FSMGen
  request if SPECFORGE needs those membership facts to cross the `.isf`
  boundary without becoming behavior.

Implementation note for FSMGen: the response itself required no runtime code
change. Adding the future metadata surface would require a separate task tree,
live spec/book/public-contract updates, support accounting, focused positive
and fail-closed tests, Knowledge Map sync, and the normal commit workflow.

## 2026-06-22: Declarative Field-Structured Storage

This answers SPECFORGE's `2026-06-22` feature request for static, named
bit-field maps on register/CSR-like storage words and related packed
message/packet layouts.

Short answer: **yes, FSMGen accepts this as a real ISF representational gap and
a valid future direction**, but it is not shipped syntax or behavior today.
The right next FSMGen step is
`ISF-FIELD-STRUCTURED-STORAGE-FRONTIER.1`, a readiness/contract audit for the
first checked declarative storage-field surface before parser or lowering code
changes.

### Static field maps are distinct from field operations

Do **not** use existing runtime field operations as a substitute for a static
field-map declaration. Forms such as `set-field`, `when-field`, `extract`, and
`assemble` describe scheduled behavior, guards, or data movement over an
already-declared word. They are not declarations that say "this register word
has source-authored fields named `mode`, `prio`, and `enable`." Emitting those
operations solely to preserve a PDF register table would fabricate behavior in
the same way that a value-less transaction drive would fabricate a driven
value.

Current ISF storage is therefore still opaque at the declaration level:
`(storage (var NAME (width N) ...))` can carry a scalar word and optional reset
value, and aggregate storage can carry selected typed record/list shapes, but
neither is a checked static field map for a register/CSR table.

### Accepted direction

FSMGen agrees with the semantic shape SPECFORGE is asking for: a storage
declaration may need an optional declarative field partition where each field
has at least:

- a field name;
- a bit range inside the storage width;
- optional access metadata such as `ro`, `rw`, `w1c`, or `warl`;
- optional field reset metadata;
- optional enum/value metadata; and
- optional descriptive/provenance metadata when the source carries it.

The first safe version should be checked metadata unless a prior contract
slice explicitly selects generated behavior. Validation should be real:
field ranges must be inside the parent width, overlaps must fail closed, names
must be deterministic and non-conflicting, malformed access/reset/enum entries
must fail closed, and the public report/semantic projection must make the
accepted fields discoverable without parsing comments.

The first audit must settle details before implementation, especially:

- whether fields must tile the full word, or whether explicit reserved/gap
  metadata is allowed without inferring undocumented fields;
- whether field resets are metadata-only at first, cross-validated against an
  existing `(var ... (reset V))`, or allowed to derive the storage reset only
  when the field map is complete and non-conflicting;
- whether enum values are inline field metadata, references to actor-local
  `(enums ...)`, or both;
- whether access-policy vocabulary is metadata-only or eventually feeds
  generated assertions/verification output; and
- whether packet/structure layout generalization ships with scalar storage
  fields or follows as a sibling feature.

### What SPECFORGE can safely do now

- Keep recovered register/CSR and packet/flit field maps in SPECFORGE
  IntentIR metadata/residuals.
- Continue emitting opaque ISF storage variables only when width/reset facts
  are honestly supported by the current contract.
- Do not emit `set-field`, `when-field`, `extract`, `assemble`, fake drives,
  or comments as a replacement for a static declarative field map.
- Treat `ISF-FIELD-STRUCTURED-STORAGE-FRONTIER.1` as the FSMGen-owned next
  step for this feature request.

Implementation note for FSMGen: this response itself does not change parser,
scheduler, lowerer, generated `.fsm`, HDL, support accounting, schedule JSON,
semantic JSON, or public syntax. A future implementation must be task-tree
owned, documented in the mdBook/downstream handoff, support-accounted, covered
by focused positive and fail-closed tests, projected through public reports as
selected, and committed through the normal workflow.

Implementation update (`2026-06-22`): the first bounded FSMGen slice now ships
metadata-only declarative fields on scalar actor-owned storage variables.
Authors may write `(fields (field NAME (bits HI LO) ...))` under a width-based
`(var ...)` / `(variable ...)` entry. FSMGen validates names, literal ranges,
non-overlap, optional access tokens, field reset metadata against an explicit
parent reset, and inline enum values, then publishes the result through
optional `inferred_storage[].fields`. This does not change generated `.fsm`,
HDL, access behavior, reset derivation, banks, aggregate carriers, packet/flit
layouts, or existing runtime field/data operations.

## 2026-09-26: Configuration, Verification And Phase-Metadata Requests

The director supplied the packets under
`../specforge/docs/upstream/fsmgen/sf-isf-*/`. Their README requirements and
minimal ISF sources were read in full. FSMGen reproduced the supplied cases
using exact source copies inside its own repository and the complete current
checkout at `a7bf398ac3c1008b996bf0a92bdd18c9464d9fda`. No SPECFORGE file or
submodule implementation was changed, and no foreign bundle script was run.
Caller corpus-impact counts remain caller claims, not independently measured
FSMGen signoff evidence. Exact inputs, reports and controls are retained in
[the intake audit](audits/specforge-feature-intake-20260926.json).

### Answer: unknown interface-port clauses must not be silently ignored

**No, silent acceptance is not intended support.** The intake parser accepted
`(bogus-clause xyz)` and the unimplemented `(present PROT_Present)` port option,
then dropped them. The captured generated HDL matches the clause-free control
except its date header. At intake, `_parse_interface` skipped malformed
property shapes and lacked rejection after the recognized-option branches.
This validation defect is repaired by `SEMANTIC-INTROSPECTION-MCP-FRONTIER.33.2`.

The `.33.2` repair rejects unsupported and malformed port options through the
shared parser, including strict check, semantic/schedule queries and API/MCP.
It preserves supported `width`, `type`, `domain`, output `reset`/`default`
and their existing validation. Rejecting `present` is not an implementation
of optional ports. Until that feature ships, SPECFORGE should continue emitting
only documented options. Default and strict modes now refuse unknown names,
scalar options, empty lists and nested option names with a port-specific
diagnostic. The original intake evidence remains historical.

### Owned feature work

FSMGen intends to implement all six requested feature families. Required
capabilities are acceptance criteria. Optional extensions have separate
slices, so the first supported subset will not imply that every optional form
already works.

All owners below belong to the
[semantic/API/MCP task tree](tasks/SEMANTIC-INTROSPECTION-MCP-FRONTIER.md).
Each has bounded child slices and requires synchronized public contracts,
capability/diagnostic discovery, semantic/schedule reports, native/API/newline
MCP parity, book examples and appropriate independent HDL evidence.

| Packet | Required work and scope | Owner |
| --- | --- | --- |
| `sf-isf-generic-port-widths` | Preserve authored width dependencies through ports, registers, constants and resets; recompute supported library/activation/top shapes on override. Qualify actual external HDL overrides and illegal settings. | `.33.3` |
| `sf-isf-parameter-value-set` | Validate integer value/range unions at defaults and every supported override; report legal sets. Separate optional recommendations/warnings and HDL legality checks have their own children. | `.33.4` |
| `sf-isf-optional-signal` | Define zero-width/presence and absent-input value rules before lowering; remove absent endpoints and replace permitted reads faithfully. Instance-specialized presence has a separate child. | `.33.5` |
| `sf-isf-actor-level-assertion` | Allow always-on actor `assert`/`assume`/`cover`, including actors without transactions, without invented scheduling. Preserve current transaction-check meaning; explicit multi-domain placement is separately owned. | `.33.6` |
| `sf-isf-known-value-predicate` | Add verification-only knownness, with separate direct-unknown/grouped forms and independent four-state qualification. Knownness means absence of X/Z, not every protocol-specific notion of a valid value. | `.33.7` |
| `sf-isf-transaction-phase-groups` | Check phase/member/role/provenance facts and expose them as metadata without drive values, order or HDL behavior. Declaration-only transactions have a separate contract/implementation child. | `.33.8` |

The generic-width request is **not a duplicate** of the earlier derived-width
request (`.32.3`). Current actor width references resolve to the default before
emission; the module still declares the parameter. The generic foundation must
preserve that dependency before a derived width can truthfully claim to follow
an HDL or use-site override. Current width-dependent HDL remains fixed at the
resolved default until the relevant implementation is qualified.
An independent HDL instantiation with `DATA_WIDTH=64` still observes a
32-bit `WDATA` for the default-32 source; the separately generated default-64
control observes 64 bits. The audit retains both compile/runtime receipts.

The earlier phase-membership guidance remains valid: do not manufacture a
drive value or body order from membership alone. `.33.8` now owns the requested
checked metadata implementation; selection is not a claim that it ships.

### Additional defect in the optional-port positive control

At intake, the packet's positive-width `baseline-good.isf` passed strict check
but its undriven `AWMECID` output was absent from HDL. A literal-width control
also lost it; adding a real assignment preserved it. The captured FSM retained
`+size (AWMECID 16)` without an output role or drive marker, so ordinary signal
inference omitted it. Schedule and realized output inventories differed. The input-role repair
in `a7bf398ac` intentionally covered inputs; it does not repair this output case.

`.33.9` now preserves declared output roles without inventing a drive value.
Ordinary/domain artifacts, generated tops and native/API/MCP inventories retain
these outputs. The separate reset-only gap is repaired under `.35`: an output
with `(reset V)` and no ordinary writer now uses reset-and-hold hardware logic.
Its semantic family exposes reset/feedback values and no data-driver blocks.
Independent timing/polarity and hold behavior is qualified through the bounded
Verilator/GHDL regression, separately from interface-preservation evidence.
Optional-port qualification must independently inventory the realized ports:
comparing two files that both omit a supposedly present output proves nothing
about presence. The original caller fixture remains unchanged in the audit;
literal-width and driven controls are separately identified.

### Execution order

Intake, unknown port options (`.33.2`), declared output loss (`.33.9`), and
reset-only output behavior (`.35`) are repaired. Resume the
already owned watchdog and transaction-reachability
repairs (`.32.1.3.3.3`, `.32.1.3.3.1`) and broader behavior signoff, followed by
bundle provenance and executable interconnect lowering (`.32.2`, `.32.4`).
The feature queue then takes actor-level verification, knownness and checked
phase metadata, followed by the generic-width foundation, derived widths,
parameter constraints and optional interfaces in dependency order. Every
optional request has an explicit leaf; none is silently dropped or declared
complete by this response. Full-source API coverage and historical native
qualification remain live obligations after these repairs and extensions.


## 2026-09-26: Storage-Register Access Metadata

The `sf-isf-storage-register-access` packet is a valid additive feature request.
Current rejection is consistent with the documented storage contract. Native
checks, semantic queries and schedule queries accept the supplied baseline
and whole-word-field control, and reject word-level access both with and
without fields. The unknown-token control is also rejected. In-process API
and newline MCP preserve these outcomes; check/semantic failures keep their
native report while schedule failure keeps its existing message-only envelope.
Exact source bytes, request text, provenance and current results are retained
in `docs/audits/specforge-storage-register-access-intake-20260926.json`.

Required scope is assigned to `.38.1` in the semantic/API/MCP task tree:

- Width-based scalar `var` and `variable` entries may state `(access TOKEN)`
  using exactly the existing field vocabulary: `ro`, `rw`, `wo`, `w1c`, `w0c`,
  `rc`, `rs`, `warl`, `wpri`, `reserved`.
- Word and field access are independent authored facts. Neither is inferred
  from, copied into, or required to agree with the other. No synthetic field
  is needed when the source describes only a register.
- Schedule `inferred_storage[]` carries optional word `access` beside width
  and fields, with applicable domain and API/MCP projections. Metadata changes
  no scheduled FSM, HDL, hardware reset, write permissions or verification logic.
- Unknown, duplicated and malformed metadata fails closed with contextual
  diagnostics. Banks and typed storage remain outside this scalar slice.

The optional bank request has a separate owner, `.38.2`, after scalar
qualification and an explicit bank-report mapping. The intake originally sequenced both leaves after execution repairs; the
2026-09-30 delivery below supersedes that sequence for passive metadata. This intake does
not implement either feature. SPECFORGE retains its separate integration owner
`FSMGEN-REQUESTS.5`; no external repository was modified or message sent.

Caller-wide corpus quantities and historical revision results remain supplied
context: they were not independently re-derived. No completion, support or
capacity decision relies on those quantities. Current bounded reproduction,
accepted controls, unknown-token refusal and retained bytes are the evidence
for this intake. The bundle's `commands.sh` was read but not executed because
it writes into the foreign bundle; current commands used local copies.

**Separate defect found during intake:** the accepted baseline's `status`
variable was reported as actor storage by the scheduler but emitted as a public
HDL input. Its reset metadata survived only in FSM `+size`, without an internal
ownership marker or reset writer. `.39.1` adds the direct internal-role carrier;
`.39.2.1` applies it to
ordinary/domain actor storage, with native/API/MCP interface parity and
independent reset/write/read/hold simulation. The baseline and whole-word-field
controls now retain internal status ownership without changing field metadata.
Generated-child scalar/bank reads in ordinary/single-domain actors now use live
handoffs under `.39.2.2.2.1`, with register/reset ownership retained in the owner.
Packed aggregate and scalar-leaf child reads are also qualified under
`.39.2.2.2.2.2`, preserving type identity, live updates and repeated activation.
Multi-domain generated transaction artifacts and flat internal wiring are now
realized under `.39.2.2.2.3.1`; domain live storage reads are qualified under
`.39.2.2.2.3.2`, with register/reset ownership and private handoffs preserved. Named child completion is qualified under `.46`: authored pulses
retain their edges alongside canonical activation handshakes, including shared
names and independently clocked domains. Library parent interfaces are qualified
under `.47`, including default-domain FIFO behavior and parent readback.
Nondefault library system bindings are qualified under `.48`. Sole scalar and whole-aggregate
child writes, including independent domains, are qualified under `.39.2.2.3` and
`.39.2.2.4.2` with original-edge owner updates. Partial/bank or competing writers
remain owned by `.39.2.2.4`, before watchdog and the metadata queue.
The retained audit includes materialized FSM, HDL and the realized semantic input entry. Future metadata
comparisons must use the corrected baseline; preserving this erroneous input
would not satisfy the actor-storage contract.

Replay current native outcomes without the external checkout:

```bash
scripts/run_with_ram_guard.sh -- python3 -B docs/audits/replay-specforge-feature-intake.py .artifacts/storage-access-recheck-new --storage-access
```

The destination must be fresh, repository-relative and on the repository
volume. A replay captures changed outcomes; future feature tests must decide
whether those changes meet the requested contract.


## 2026-09-30: Unstated Reset — Answer To A Question

Packet: `sf-isf-unstated-reset`; SPECFORGE owner: `FSMGEN-REQUESTS.9`.
FSMGen owner: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.60.3`.
The packet is a question, as the director clarified. No configurable-reset
feature is implied by this answer; the inferred follow-on `.61` is withdrawn.

### Which form should SPECFORGE write?

Use omitted legacy `(reset ...)` when an unstated ISF reset **may select
FSMGen's documented implementation default**. The effective hardware reset is
asynchronous active-low `rst_n`, and the report now says its origin is
`legacy_default`. This records the omission honestly without claiming that the
upstream specification named that reset. SPECFORGE still owns grounding in the
original specification; FSMGen only observes the supplied ISF clauses.

If SPECFORGE requires reset policy to remain unresolved until instantiation,
**neither existing form satisfies that requirement**. Its current refusal to
invent implementation choices should remain until its own policy permits a
compiler default or it requests the missing deferred-choice feature. A
clock-only domain is suitable only when hardware without a reset is intended.
Silence in a specification does not by itself assert that hardware contract.

| Authored source | Effective hardware reset | Provenance entry |
| --- | --- | --- |
| Legacy actor with no reset clause | Asynchronous active-low `rst_n` | `{"domain":null,"origin":"legacy_default"}` |
| `(reset (rst_n async active_low))` | Asynchronous active-low `rst_n` | `{"domain":null,"origin":"explicit"}` |
| `(clock-domains (domain link (clock clk)))` | No reset | `{"domain":"link","origin":"domain_absent"}` |

### Initial state and values in the clock-only form

A standalone named domain is supported; CDC is not required. The supplied
clock-only actor passes strict checking and emits SystemVerilog and Verilog.
It has **no guaranteed initial FSM state or register values**. Generated state
and storage declarations have no initializer, and there is no `initial` block
or reset branch. Ordinary clocked writes can establish later register values;
retaining a value in a feedback path does not initialize it.

Storage `(reset V)` metadata specifies a hardware-reset assignment, not a
power-on initializer. In the clock-only qualification, written storage retains
its ordinary write/hold behavior and read-only storage gains no fabricated
write. Adding an explicit domain reset supplies the corresponding reset
assignments, including the initial FSM state. Clock-only direct VHDL remains
outside the supported reset-bearing process subset, independently owned by
SEM `.36`. This answer does not promise a simulator-dependent startup value.

### Can a report distinguish defaulted and stated reset?

Yes. Successful directly parsed ISF check/semantic reports expose
`source.reset_provenance`; schedule JSON exposes root `reset_provenance`.
The value is an array containing the entries above. Named domains appear in
authored order. `explicit` means that an ISF reset clause exists, not that every
optional operand was written or that an external specification states it.
`explicit_system_contract` continues to describe the lowered carrier's policy.

Capability discovery describes this through
`embedding.isf_public_interface.schedule_report_reset_provenance` and the
check/semantic contracts' `source_optional_fields.reset_provenance`. Native
queries, the API and newline MCP agree. Failed reports and direct FSM/PPIF
source reports acquire no manufactured ISF provenance; unknown caller-built
actor evidence remains null in schedule reporting.

The extension is available in commit `d5c1806c2bf68af97ff7eff103f723cce8f74173`.
Commit `88e593884f783557bf6ec5c82aa272adc13ff2a4` also rejects misspelled,
conflicting, nested or empty reset options instead of silently selecting a
policy. Consumers need a revision containing those commits; no SPECFORGE pin
or external ticket was changed by this work.

### Is an instantiation-selected reset form missing?

Yes. No current ISF form defers reset kind or polarity as an unresolved
implementation choice. The provenance extension reports the default choice;
it does not introduce configurable-reset syntax. This answers the question and
does not open an additional feature request on SPECFORGE's behalf.

### Evidence and expected-outcome disposition

The supplied packet and immutable prior products are retained in
`docs/audits/specforge-unstated-reset-20260930/`. T1978 qualifies the supplied
forms, complete native/API/newline products, capability discovery and unchanged
prior report fields, scheduled FSM and HDL (apart from provenance and generated
date). T1979 qualifies malformed-policy refusal. T1980 adds written/read-only
storage and explicit-reset controls, with full reports and emitted HDL retained
in `docs/audits/specforge-reset-answer-20260930/`.

The packet's requested form and distinct report are satisfied by legacy
omission **only if selecting the documented implementation default is allowed**.
The clock-only alternative's lack of initialization is documented and checked
by emission tests; it is not presented as an unresolved reset policy. Explicit
baseline behavior is preserved, with the additive provenance field. These are
static source/report/emission qualifications, not a new native runtime result.
The remaining decision to accept defaults belongs to SPECFORGE's adapter policy.


## 2026-09-30: Physical-Time Duration Request — Baseline Qualified

`sf-isf-duration-time-units` is an accepted feature request, owned by
`SEMANTIC-INTROSPECTION-MCP-FRONTIER.60.1`; it is not implemented yet.
Its packet, source identities, complete public products and actual scheduled
carrier are preserved in `docs/audits/specforge-duration-intake-20260930/`.
The supplied duration wait, duration watchdog and frequency-bearing clock
remain refused through native/API/newline queries. The cycle-parameter baseline
still uses a static state chain without a wait counter. Its complete schedule
matches the supplied baseline except for the separately delivered reset-origin
metadata. The supplied larger timeout and external corpus measurements were
not rerun or adopted as fresh FSMGen measurements.

Required delivery covers physical-time bounds in waits, watchdogs, latency and
monitors; a declared literal/parameter clock rate; exact directed rounding and
source/conversion reports; and counter-based duration lowering. Existing
cycle-count meanings and the baseline schedule remain compatibility controls.
Optional legal-duration ranges remain explicitly owned contract work.

The contract leaf `.60.1.2` must account for parameter override elaboration as
well as default values: retaining a parameter spelling alone cannot ensure
that an integrator's clock changes both the derived count and its counter
width correctly. Existing runtime-wait counters are relevant prior machinery,
not evidence that duration conversion or instantiation support already ships.
The named-timer and aggregate-interface packets receive their bounded intake
next so delivery can follow demonstrated dependencies.


## 2026-09-30: Named-Timer Request — Baseline Qualified

`sf-isf-named-timers` is an accepted feature request owned by SEM `.60.2`.
The complete packet and current native/API/newline products are preserved in
`docs/audits/specforge-timer-intake-20260930/`. Named timer declarations and
distinct per-await watchdog limits remain refused. The accepted watchdog
baseline retains its complete prior schedule, apart from reset provenance;
its actual carrier loads the limit minus one and sets `last_error` on timeout.
This is a compatibility control, not named-timer support.

Required delivery includes positive cycle limits, declaration/name validation,
start/restart/stop in rules and transactions, ordinary expiry predicates,
concurrent lifetimes across transaction completion and control/use metadata.
Duration limits are conditional on duration support; they do not prevent a
cycle-limit delivery. Optional distinct per-await watchdog limits remain owned
separately. Timer commands need an explicit same-cycle/reset precedence and
writer contract before implementation.

The supplied immediate `when` after `start-timer` illustrates syntax; it cannot
serve as the eventual concurrent expiry test. Qualification must actually wait
for or repeatedly observe expiry while another timer continues, without
changing ordinary `when` into an implicit wait or setting `last_error`.
No native runtime or external corpus remeasurement is claimed by this intake.
Aggregate-port intake is next, followed by the smallest qualified feature
unblocks across the owned requests.


## 2026-09-30: Record Interface Request — Baseline Qualified

`sf-isf-aggregate-interface-ports` is an accepted feature request owned by
SEM `.60.4`. Its complete packet and current native/API/newline products are
preserved in `docs/audits/specforge-aggregate-intake-20260930/`. At that captured
intake revision, both the whole record input copy and input field guard were
refused by the explicit aggregate-carrier boundary. Later bounded record-input
admission is recorded in the current delivery status above; the complete
aggregate-interface request remains open. The storage-only control retains its authored
member order, packed width and scalar leaf assignment. Its complete prior
strict-check report is unchanged after source relocation and reset provenance.

Required delivery covers actor-local and imported packed record types on input
and output ports; input field reads in scalar contexts; output field writes;
whole same-type port/storage copies; and type/layout evidence in schedule and
semantic reports with documented packing. Unknown and unsupported types need
port-specific diagnostics. Optional list ports and variant layouts remain
separate work. Existing generated internal typed handoffs provide useful
machinery, but do not qualify these authored ports or output writer admission.

The supplied corpus counts remain SPECFORGE evidence, not fresh FSMGen
measurements. This intake includes no native simulation. All additional packets
now have a preserved and independently exercised baseline; the reset question
is answered, while the requested feature implementations remain open.


## 2026-09-30: Scalar Storage-Word Access — Required Packet Delivery

The scalar contract from `sf-isf-storage-register-access` is implemented under
SEM `.38.1`. Width-based `var` and `variable` declarations accept `(access TOKEN)`
with the existing lowercase field vocabulary. For example:

```lisp
(var status (width 8) (reset 0) (access ro))
(var control (width 8) (reset 0) (access rw)
  (fields (field enable (bits 0 0) (access ro))))
```

The schedule entry carries optional word `access` beside `width` and `fields`.
Word and field values remain independent: no inheritance, consistency rule or
synthetic whole-word field is imposed. The supplied primary and with-fields
cases pass; the original controls retain their complete public products. The supplied unknown token `sometimes`, duplicate options,
malformed operands, banks and typed storage fail with contextual diagnostics.
No access-policy RTL, write protection, clear behavior or reset is generated.

T1981 compares complete native/API/newline reports and actual scheduled FSM and
SystemVerilog/Verilog against pre-change controls. Only authored access metadata,
exact source relocation and generated date banners are allowed differences.
Both scalar spellings and every accepted token retain identical carriers.
The runnable book example and support-accounted `isf/storage_word_access.isf`
show the new form. Capability discovery advertises the optional storage key.
Evidence is retained in `docs/audits/storage-word-access-20260930/`.

The follow-up `.38.3` also publishes domain-local storage detail through
`clock_domains[].inferred_storage[]`, using the same normalized storage schema.
Word access, field metadata, types, scalarized bank elements and scheduler
storage retain their owning domain. Existing storage-name lists and top-level
empty ownership are preserved. T1982 qualifies complete prior report-field and
FSM/HDL equality, independent ownership/shape, empty domains, nested detachment
and all public transports. Evidence is in
`docs/audits/domain-storage-report-20260930/`. Optional bank access metadata
remains `.38.2`; bank layout reporting does not imply that syntax is accepted. The previous blanket dependency
on controller/runtime repairs is narrowed by decision 0109: this change proves
unchanged hardware and makes no new execution claim. Those repairs remain open.

Current fixed scalar/storage compatibility controls additionally preserve complete
JSON primitive kinds through source relocation and later copies under SEM
`.60.4.3.2.4.2.3.1`. Earlier value comparisons retain their dated evidence limits;
immutable receipt, carrier and HDL bytes are preserved. The maintained
generated-input declaration witness and complete current discovery/catalog
are qualified under `.3.2`, completing generated/domain source/carrier/public
closure. Backend/native behavior and consumer qualification remain open.

SPECFORGE's integration remains its `FSMGEN-REQUESTS.5`; no external checkout,
pin, ticket or message was changed here.
