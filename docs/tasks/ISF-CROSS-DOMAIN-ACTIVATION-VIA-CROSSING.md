# ISF-CROSS-DOMAIN-ACTIVATION-VIA-CROSSING: Cross-Domain `(do)`/`(spawn)` Through a Declared Activation Crossing

## Metadata

- Tree ID: `ISF-CROSS-DOMAIN-ACTIVATION-VIA-CROSSING`
- Status: `done`
- Roadmap lane: `R14` (ISF Multi-Clock And CDC Semantics — richer crossing primitives)
- Created: `2026-05-30`
- Last updated: `2026-05-31`
- Owner: repo-local workflow

## Goal

Allow a blocking cross-domain `(do child)` (and `(spawn child as inst)`) — where
`child` runs in a different clock domain than the calling transaction — to lower
through a **declared crossing** that owns the activation start/done handshake,
with correct CDC synchronization. Today this fails closed: `ISF clock-domain
violation: ... do target '<child>' references transaction in domain '<d>' from
domain '<o>' without a crossing primitive`.

User-selected direction (`2026-05-30`): "cross-domain activation via a declared
crossing", reusing the shipped acknowledged-event CDC child.

## Ground truth (investigated `2026-05-30`)

Crossing infrastructure that exists today (the `(crossings (event ...))`
primitive):
- Parse: `FSM/Adapter/ISF/Parser.pm` `_parse_crossings()` (~L6673),
  `_finalize_actor_crossings()` (~L5461). Record: `{kind=>'event', name,
  from=>{domain,signal}, to=>{domain,signal}, ready=>{signal,domain}}`.
- Lowering: `FSM/Scheduler/ISF.pm` partitions the actor into per-domain
  `<actor>__domain_<d>.fsm` modules, exposes crossing endpoints as domain ports
  (`_add_crossing_endpoint_ports` ~L227), and the `<actor>_top.fsm` instantiates
  a CDC child `<name>_cdc` (`<actor>__cdc_event_<name>`) wiring
  `request`/`ready`/`pulse` (`_emit_multi_domain_wiring` ~L334,
  `_emit_crossing_rtlif` ~L368). The CDC child RTL is emitted by
  `FSM/Composition/ISFEventCDCModuleEmitter.pm` (acknowledged single-bit,
  single-outstanding, no payload).
- The activation fail-closed: `_validate_same_domain_target()`
  (LoweringIR.pm ~L2572) hard-fails when target domain ≠ owner domain, with NO
  consultation of `$actor->{crossings}`. Called from
  `_validate_transaction_clause_domain_refs()` do/spawn branch (~L2481-2504).
- Same-domain activation wiring: `<instance>_start` (output) / `<instance>_done`
  (input) handoff ports created in the owner domain module
  (LoweringIR.pm ~L1338-1357).

## SAFETY CONSTRAINT (non-negotiable)

A blocking cross-domain `do` needs a **bidirectional** handshake: parent's
`<inst>_start` (source domain) must reach the child's start (dest domain), and
the child's `done` (dest domain) must return to the parent (source domain).
The shipped event crossing is **unidirectional** (source→dest pulse + source
ready-ack), so one event crossing is insufficient — two are needed (start
source→dest, done dest→source).

**Therefore a validator-only relaxation is forbidden:** accepting a cross-domain
activation without routing `<inst>_start`/`<inst>_done` through CDC
synchronizers would emit an unsynchronized cross-clock handoff — a metastability
bug, exactly what the fail-closed rule prevents. Validator acceptance and the
CDC routing **must ship in the same slice**.

## Design

Add a new crossing kind `(crossings (activation child (from SRC) (to DEST)))`
(child names a declared transaction in domain `DEST`; the calling transaction is
in `SRC`). Lowering auto-generates the activation's start/done handshake through
**two** acknowledged-event CDC children (reusing `ISFEventCDCModuleEmitter`):
- start: source `<inst>_start` request → CDC → dest child start pulse.
- done:  dest child `done` request → CDC → source `<inst>_done` pulse.
The validator accepts a cross-domain `(do child)`/`(spawn child)` exactly when an
`activation` crossing covering `(SRC → DEST, child)` is declared.

(Rejected alternative: requiring the author to hand-declare two raw `(event ...)`
crossings — the `<inst>_start`/`<inst>_done` signals are compiler-internal, so
authors cannot name them; the `activation` kind is the right abstraction.)

## Slice plan

- `.1` select: scope + the investigated ground truth + the safe design (this
  doc). No code.
- `.2` parser + declaration validation for `(crossings (activation ...))`: parse
  the new kind onto `$actor->{crossings}`; validate domains/child exist and
  SRC≠DEST; cross-domain `(do)`/`(spawn)` STILL fails closed at lowering (the
  declaration is parsed but not yet honored — "parser-acceptance ≠ support").
  Safe (fail-closed) and bounded.
- `.3` cross-domain activation handshake-port lowering machinery (safe, behind
  the fail-closed guard): `_wire_external_activations` consumes
  `$actor->{external_activations}` (only ever set by the multi-domain partition)
  and promotes the SIBLING-model `(do child)` handshake to per-domain MODULE
  ports — caller (SRC) `<start>`→output/`<done>`→input; callee (DEST)
  `<start>`→input/`<done>`→output with `child`'s entry gated on `<start>`
  (synthesizing a start-gated entry for a body-only transaction) and `<done>`
  asserted at its terminal. `_validate_child_transaction_refs` accepts a caller
  target that lowers in the other domain's module. Built + unit-tested in
  isolation; the `lower()` guard + `_validate_same_domain_target` stay
  FAIL-CLOSED.
- `.4` CDC routing structure (safe, behind the guard): (a) the cross-domain
  CALLER emits a ONE-CYCLE `<start>` request (a sequential request state, like a
  spawn start, followed by the await-on-`<done>` state) — the acknowledged-event
  CDC re-pulses while `request` is held, so a held level would re-trigger `child`;
  (b) `_emit_multi_domain_top` emits the two acknowledged-event CDC children for an
  `activation` crossing and wires start (SRC→DEST) and done (DEST→SRC), with the
  CDC `ready` outputs left open (single outstanding by construction; the `<done>`
  pulse is the acknowledgement). Both unit-tested in isolation; guard stays
  FAIL-CLOSED.
- `.5` integration — the correctness-critical slice (validator-accept + CDC
  routing SHIP TOGETHER): `_validate_transaction_clause_domain_refs` accepts a
  top-level cross-domain `(do child)` covered by an `activation` crossing
  (`_activation_crossing_covers`); `_build_domain_partition` validates the
  crossing owns a real activation (child in DEST, a SRC transaction performs the
  `(do)`) and fails closed on a declared-but-unused or mis-placed crossing;
  `_domain_actor_for_scheduled_artifact` injects `external_activations` (caller
  into SRC, callee into DEST); the `lower()` guard is removed. The handshake
  consumes the CDC `ready` outputs via the event-crossing idiom — the caller
  `(await <start>_ready)` before its one-cycle `<start>` pulse and the callee
  `(await <done>_ready)` before pulsing `<done>` (correcting `.4`'s ready-open,
  which the composition rejects as an unconsumed child output). End-to-end the
  actor lowers to per-domain modules + a top routing start SRC→DEST and done
  DEST→SRC through the two CDC children; per-domain modules pass Verilator lint +
  yosys synthesis; the composition emits complete HDL (the only residual warnings
  are the pre-existing `shared_dp_export_*` PINMISSING, at parity with the shipped
  event-crossing multi-domain HDL). Uncovered cross-domain `(do)` and
  declared-but-unused crossings still fail closed.
- `.6` book documentation + runnable example: `13a` Activation Crossing section
  (surface + dual-CDC routing + await-ready handshake + fail-closed boundaries)
  with a full runnable `(actor ...)` example that lowers + generates HDL; `13b`
  cross-reference from the `(do)` surface; `13k` feature-matrix row; `14`
  backlog/count updates. Gated by `t/1376` (book examples lower) + `t/1305`
  (feature-matrix audit) + doc-truth audits.
- `.7` schedule-report metadata for activation crossings + downstream specs: add
  the activation crossing to the schedule report (a shape distinct from the event
  endpoint summary) with its report audits, then sync
  `ISF_DOWNSTREAM_INTEGRATION_SPEC.md`, `ISF_PUBLIC_INTERFACE_CONTRACT.md`, and
  the dated `SPECFORGE_FEEDBACK_RESPONSE.md` entry.

## Non-Goals

- No data-payload crossing (separate primitive).
- No auto-generation of the crossing without an explicit declaration (per the
  "fail closed unless a declared crossing owns the path" principle).

## Acceptance Criteria

- `(crossings (activation child (from SRC)(to DEST)))` parses and validates.
- A cross-domain `(do child)` covered by such a crossing lowers, partitions
  across domains, and routes `<inst>_start`/`<inst>_done` through two event CDC
  children in the `_top`; HDL emits (and passes Verilator lint where available).
- Cross-domain activation WITHOUT a covering activation crossing still fails
  closed.
- New `t/138x` golden(s); docs synced; audits + broad regression pass.
- Each leaf committed via `COMMIT.md`.

## Task Tree

- ID: `ISF-CROSS-DOMAIN-ACTIVATION-VIA-CROSSING`
  Status: `active`
  Goal: `Cross-domain (do)/(spawn) through a declared (crossings (activation ...)) with CDC-synchronized start/done.`
  Children: `.1` (select), `.2` (parse+declare-validate, fail-closed), `.3` (handshake-port lowering machinery, behind guard), `.4` (dual-CDC top emission, behind guard), `.5` (integration: validator-accept + CDC routing + remove guard, together), `.6` (book docs + runnable example), `.7` (schedule-report metadata + downstream/contract/SPECFORGE)

- ID: `ISF-CROSS-DOMAIN-ACTIVATION-VIA-CROSSING.1`
  Status: `done`
  Goal: `Select; record investigated ground truth + safe design + slice plan.`
  Acceptance: `Task tree committed before any code change.`
  Verification: `mdbook build docs/book; git diff --check`
  Commit: `dbbe6bce`

- ID: `ISF-CROSS-DOMAIN-ACTIVATION-VIA-CROSSING.2`
  Status: `done`
  Goal: `Parse + structurally validate (crossings (activation child (from SRC)(to DEST))); lowering fails closed (not yet supported).`
  Acceptance: `Construct parses + validates; malformed rejected at parse; well-formed fails closed at lower; event crossings unaffected.`
  Verification: `prove -Iperl t/1386 t/1247 t/1372; broad clock-domain/crossing regression; mdbook build docs/book; git diff --check`
  Commit: `ffffc2a0`

- ID: `ISF-CROSS-DOMAIN-ACTIVATION-VIA-CROSSING.3`
  Status: `done`
  Goal: `Cross-domain activation handshake-port lowering machinery (SIBLING model), behind the fail-closed guard.`
  Acceptance: `_wire_external_activations promotes the (do child) handshake to per-domain module ports (caller start->output/done->input; callee start->input/done->output, child gated on start with a synthesized start-gated entry when needed, done asserted at terminal); validator accepts a caller target absent from the per-domain module; uncovered cross-domain do and any activation-crossing lower() STILL fail closed.`
  Verification: `prove -Iperl t/1387 t/1250 t/1386 t/1247 t/1372; broad activation/do/spawn/clock-domain regression (39 files, 246) PASS; perl -c; mdbook build docs/book; git diff --check`
  Commit: `77f447c9`

- ID: `ISF-CROSS-DOMAIN-ACTIVATION-VIA-CROSSING.4`
  Status: `done`
  Goal: `CDC routing structure (behind the guard): one-cycle cross-domain caller start request + dual-CDC top emission/wiring.`
  Acceptance: `The cross-domain caller emits a one-cycle <start> request state then awaits <done>; _emit_multi_domain_top emits two acknowledged-event CDC children for an activation crossing wiring start (SRC->DEST) + done (DEST->SRC) with ready open; event-crossing emission is unchanged (rtlif refactor); guard + _validate_same_domain_target stay fail-closed.`
  Verification: `prove -Iperl t/1387 (5 subtests) t/1247 t/1255 t/1116 t/1305; broad composition/crossing/domain/child regression (13 files, 449) PASS; perl -c ISF.pm + LoweringIR.pm; mdbook build docs/book; git diff --check`
  Commit: `93e4e73e`

- ID: `ISF-CROSS-DOMAIN-ACTIVATION-VIA-CROSSING.5`
  Status: `done`
  Goal: `Integration (validator-accept + CDC routing ship together): cross-domain (do) covered by an activation crossing lowers end-to-end through two CDC synchronizers; guard removed.`
  Acceptance: `Validator accepts a top-level cross-domain (do child) covered by an (activation ...) crossing (else fail closed); declared-but-unused / mis-placed crossings fail closed; per-domain actors get external_activations injected; the handshake consumes the CDC ready outputs (caller awaits <start>_ready, callee awaits <done>_ready); end-to-end lowering emits per-domain modules + a top routing start SRC->DEST and done DEST->SRC; per-domain modules pass Verilator lint + yosys; composition emits complete HDL (only pre-existing shared_dp_export_* PINMISSING remain).`
  Verification: `prove -Iperl t/1387 (7 subtests) t/1386 t/1247 t/1372 t/1374 t/1375 t/1250 t/1116 t/1255 t/1305 + composition/spawn regression (16 files, 557) PASS; full ./bin/ci-regression isf --no-book PASS; per-domain --verify-hdl (verilator_lint + yosys_synthesis PASS); full composition HDL generation (5 modules) exit 0; perl -c; mdbook; git diff --check`
  Commit: `13cbceeb`

- ID: `ISF-CROSS-DOMAIN-ACTIVATION-VIA-CROSSING.6`
  Status: `done`
  Goal: `Book documentation + a runnable cross-domain activation example (the user-facing review surface).`
  Acceptance: `13a gains an Activation Crossing section (surface + dual-CDC routing + await-ready handshake + fail-closed boundaries) with a full runnable (actor ...) example that lowers + generates HDL; 13b cross-references it from the (do) surface; 13k feature matrix gains a row; 14 backlog/count updated; book examples still lower (t/1376 now 39), feature-matrix + doc-truth audits pass.`
  Verification: `mdbook build docs/book; prove -Iperl t/1376 (39 examples) t/1305 t/1304 t/1307 t/1332 PASS; git diff --check`
  Commit: `eda950e5`

- ID: `ISF-CROSS-DOMAIN-ACTIVATION-VIA-CROSSING.7`
  Status: `done`
  Goal: `Activation crossing schedule-report metadata + downstream/contract/SPECFORGE sync (closes the tree).`
  Acceptance: `_build_domain_partition records an activation crossing summary + per-domain endpoints; the JSON report emits kind:"activation" (child, source/destination_domain, start/done signal+instance+module, outstanding_policy, payload, top_fsm) and per-domain { activation, role, start, done }; report audits pass; ISF_DOWNSTREAM_INTEGRATION_SPEC / ISF_PUBLIC_INTERFACE_CONTRACT / SPECFORGE_FEEDBACK_RESPONSE document the activation crossing.`
  Verification: `prove -Iperl t/1387 (8 subtests, incl. report shape) t/1116 t/1255 t/1247 t/1217 t/1305 t/1304 t/1307 t/1332 t/1250 t/1386 PASS (11 files, 880); full ./bin/ci-regression isf --no-book PASS; perl -c; git diff --check`
  Commit: `ship commit (this slice)`

## Current Frontier

The tree is complete — all leaves `.1`–`.7` are `done`. Cross-domain blocking
`(do child)` through `(crossings (activation child (from SRC)(to DST)))` parses,
validates, lowers end-to-end through two CDC synchronizers, generates HDL, is
documented with a runnable book example, and is exposed in the schedule report.
Follow-ups (separate trees): cross-domain `(spawn)`, nested cross-domain `(do)`
(inside `repeat`/`when`/`switch`).

| Order | Leaf | Status | Why next |
| --- | --- | --- | --- |
| 1 | `.1` | `done` | Selection/design commit `dbbe6bce`. |
| 2 | `.2` | `done` | Parser + structural validation shipped; lowering fail-closed (`t/1386`). |
| 3 | `.3` | `done` | Handshake-port lowering machinery (`_wire_external_activations`) built + unit-tested behind the guard (`t/1387`); guard + `_validate_same_domain_target` stay fail-closed. |
| 4 | `.4` | `done` | One-cycle cross-domain caller request + dual-CDC top emission/wiring, unit-tested behind the guard (`t/1387`); event-crossing emission unchanged. |
| 5 | `.5` | `done` | Integration shipped: validator accepts a covered cross-domain `(do)`, `external_activations` injected, guard removed, CDC `ready` consumed via await-handshake; end-to-end HDL (5 modules), per-domain Verilator+yosys PASS (`t/1387`, full `ci-regression isf`). |
| 6 | `.6` | `done` | Book documentation shipped: `13a` Activation Crossing section + runnable example (lowers + HDL), `13b` cross-ref, `13k` matrix row, `14` updates; `t/1376` (39 examples) + matrix/doc-truth audits PASS. |
| 7 | `.7` | `done` | Activation crossing schedule-report metadata (`kind:"activation"` + per-domain endpoints, `t/1387` 8 subtests) + downstream/contract/SPECFORGE sync; report audits (`t/1116`/`t/1255`) PASS. Tree complete. |

## Decisions

- `2026-05-30`: New `(crossings (activation ...))` kind (not hand-declared raw
  event pairs) because activation start/done signals are compiler-internal.
- `2026-05-30`: Validator acceptance and CDC routing MUST ship together (now `.5`)
  to avoid emitting an unsynchronized cross-domain handoff. `.2`–`.4` are safe
  because lowering stays fail-closed until `.5`.
- `2026-05-30` (`.3` investigation): chose the **SIBLING** lowering model over the
  generated-do model. Generated-do gives clean dedicated `<inst>_start`/`<inst>_done`
  ports but realizes `child` as a `?fsmc` child, which is BLOCKED for full HDL by
  the pre-existing multi-domain generated-child composition-scope limitation
  (`docs/COMPOSITION_SCOPE.md` — the same boundary already documented for
  repeat-body spawn; confirmed empirically: a same-domain multi-domain generated-do
  fails `--check-json` with `instance 'core' has no port named ...`). The sibling
  model promotes the `_wire_do_children` `<child>_start`/`<child>_done` handshake to
  per-domain MODULE ports, so the top wires module-to-module and sidesteps that
  limitation — the best path to full HDL.
- `2026-05-30` (`.3` investigation): "recognition" is NOT an independently
  observable slice — `report()` runs the partition validator
  (`_validate_same_domain_target`), which fail-closes on the cross-domain `(do)`.
  So partition recognition, validator acceptance, and CDC routing are one atomic
  seam (and the safety constraint already bundles validator+routing). The
  decomposition therefore builds + unit-tests the lowering (`.3`) and top-emission
  (`.4`) machinery behind the still-fail-closed guard, and flips the guard + the
  validator + the partition together in `.5`.
- `2026-05-30` (`.3` decision): the dual CDC children are AUTO-generated from the
  single `activation` crossing (resolving the prior open question) — the
  `<child>_start`/`<child>_done` handshake signals are compiler-internal, so the
  author declares one `(activation ...)` and lowering wires the two synchronizers.
- `2026-05-30` (`.4` decision): the cross-domain caller issues a ONE-CYCLE
  `<start>` request, not a held level. The acknowledged-event CDC toggles on
  `request && ready` and re-arms after every round-trip ack, so a held `request`
  would re-pulse the destination and re-trigger `child`. The done side is already
  one-cycle (the callee terminal is transient). With single-outstanding requests
  guaranteed by the blocking-do structure, the CDC `ready` back-pressure is
  unnecessary and its output is left open (the `<done>` pulse is the
  application-level acknowledgement). To be confirmed by Verilator simulation in
  `.5`/`.6`.
- `2026-05-30` (`.5` decision, CORRECTS the `.4` ready-open): the CDC `ready`
  outputs are NOT left open — the composition rejects an unconsumed child output
  ("several same-name child outputs remain unconsumed"). Instead the handshake
  consumes `ready` via the shipped event-crossing idiom: the caller
  `(await <start>_ready)` before its one-cycle `<start>` pulse, and the callee
  `(await <done>_ready)` before pulsing `<done>`. This both satisfies the
  composition and is more robust (the request is issued only when the CDC is
  actually ready). Verified: end-to-end the composition emits complete HDL and
  the per-domain modules pass Verilator lint + yosys synthesis.
- `2026-05-30` (`.5` decision): a declared activation crossing must own a REAL
  cross-domain activation — the child must be in DEST and some SRC transaction
  must perform a top-level `(do child)`. A declared-but-unused or mis-placed
  crossing fails closed (it would otherwise emit dead/unsynchronized CDC logic).

## Open Questions

- `.6`/follow-up: cross-domain `spawn` (non-blocking) and nested cross-domain
  `(do)` (repeat/when/switch body) remain fail-closed — the `.5` acceptance is
  restricted to a top-level blocking `(do)`. Extending to those is future work.
- `.6`/follow-up: the activation crossing's schedule-report metadata (a distinct
  shape from the event endpoint summary) is not yet surfaced (`_crossing_summary`
  stays event-only); add it with the report-contract audits in `.6` or a
  dedicated slice.
- Handshake signal naming (`<child>_start`/`<child>_done`): a collision with a
  `child` output literally named `<child>_done` is still theoretically possible;
  `external_activations` carries explicit `start_signal`/`done_signal` so a
  collision-free policy can be introduced without reworking the lowering.

## Blockers

- None. `.5` (the correctness-critical integration) shipped and reaches complete
  HDL; the only residual composition warnings are the pre-existing
  `shared_dp_export_*` PINMISSING (parity with the shipped event-crossing
  multi-domain HDL, `docs/COMPOSITION_SCOPE.md`), not specific to activation.

## Verification Log

| Date | Leaf | Checks | Result |
| --- | --- | --- | --- |
| `2026-05-30` | `.1` | `mdbook build docs/book`; `git diff --check` | `PASS` |
| `2026-05-30` | `.2` | `prove -Iperl t/1386 t/1247 t/1372` (Files=3, Tests=19, PASS); broad clock-domain/crossing/parser regression (12 files, 147) PASS; `mdbook build docs/book`; `git diff --check` | `PASS` |
| `2026-05-30` | `.3` | `prove -Iperl t/1387 t/1250 t/1386 t/1247 t/1372 t/1110 t/1382 t/1383` PASS; broad activation/do/spawn/clock-domain regression (39 files, 246) PASS; `perl -c LoweringIR.pm`; `mdbook build docs/book`; `git diff --check` | `PASS` |
| `2026-05-30` | `.4` | `prove -Iperl t/1387` (5 subtests) PASS; broad composition/crossing/domain/child regression with event-crossing goldens (13 files, 449) PASS; `perl -c ISF.pm`+`LoweringIR.pm`; `mdbook build docs/book`; `git diff --check` | `PASS` |
| `2026-05-30` | `.5` | `prove -Iperl t/1387` (7 subtests) + clock-domain/crossing/composition/report-audit sweep (16 files, 557) PASS; full `./bin/ci-regression isf --no-book` PASS; per-domain `--verify-hdl` → `verilator_lint`+`yosys_synthesis` PASS; full composition HDL generation emits 5 modules (exit 0); `perl -c`; `mdbook build docs/book`; `git diff --check` | `PASS` |
| `2026-05-31` | `.6` | `mdbook build docs/book`; `prove -Iperl t/1376` (39 examples lower cleanly) `t/1305 t/1304 t/1307 t/1332` PASS; the runnable example lowers (3 artifacts) + generates HDL (5 modules); `git diff --check` | `PASS` |
| `2026-05-31` | `.7` | `prove -Iperl t/1387` (8 subtests incl. report shape) `t/1116 t/1255 t/1247 t/1217 t/1305 t/1304 t/1307 t/1332 t/1250 t/1386` PASS (11 files, 880); full `./bin/ci-regression isf --no-book` PASS; `perl -c`; `git diff --check` | `PASS` |

## Commit Log

| Leaf | Commit subject or reference | Notes |
| --- | --- | --- |
| `.1` | `ISF-CROSS-DOMAIN-ACTIVATION-VIA-CROSSING.1: select cross-domain activation via crossing` | `dbbe6bce` |
| `.2` | `ISF-CROSS-DOMAIN-ACTIVATION-VIA-CROSSING.2: parse + validate activation crossing (lowering fail-closed)` | `ffffc2a0` |
| `.3` | `ISF-CROSS-DOMAIN-ACTIVATION-VIA-CROSSING.3: cross-domain activation handshake-port lowering machinery (behind guard)` | `77f447c9` |
| `.4` | `ISF-CROSS-DOMAIN-ACTIVATION-VIA-CROSSING.4: one-cycle caller request + dual-CDC top emission (behind guard)` | `93e4e73e` |
| `.5` | `ISF-CROSS-DOMAIN-ACTIVATION-VIA-CROSSING.5: integration — cross-domain activation lowers end-to-end through two CDC synchronizers` | `13cbceeb` |
| `.6` | `ISF-CROSS-DOMAIN-ACTIVATION-VIA-CROSSING.6: book documentation + runnable cross-domain activation example` | `eda950e5` |
| `.7` | `ISF-CROSS-DOMAIN-ACTIVATION-VIA-CROSSING.7: activation crossing schedule-report metadata + downstream/contract/SPECFORGE sync (closes tree)` | `ship commit (this slice)` |

## Changelog

- `2026-05-30`: Created. User-selected CDC lane direction (cross-domain
  activation via a declared crossing). Recorded the investigated infrastructure,
  the bidirectional-handshake safety constraint (validator+lowering ship
  together), the `(crossings (activation ...))` design, and the slice plan.
- `2026-05-30`: `.1` selection/design committed (`dbbe6bce`).
- `2026-05-30`: `.2` shipped. Parser (`_parse_crossings` dispatch +
  `_parse_activation_crossing`) accepts `(crossings (activation child (from SRC)
  (to DEST)))`; `_finalize_actor_crossings` validates domains declared, SRC≠DEST,
  and child is a declared transaction. Lowering fails closed for any actor
  declaring an activation crossing ("cross-domain activation lowering is not yet
  supported") — parser-acceptance ≠ support; CDC routing ships in `.3`. Event
  crossings unaffected. Locked by `t/1386`; regression PASS.
- `2026-05-30`: `.3` shipped, and the slice plan re-scoped (`.3`/`.4`/`.5`/`.6`)
  after a deep lowering investigation. Chose the **SIBLING** lowering model
  (generated-do is blocked for full HDL by the multi-domain generated-child
  composition-scope limitation, `docs/COMPOSITION_SCOPE.md`); established that
  partition recognition + validator acceptance + CDC routing are one atomic seam
  (`report()` runs the partition validator), so the machinery is built behind the
  still-fail-closed guard and the seam flips in `.5`. Shipped
  `_wire_external_activations` (LoweringIR) which, driven by
  `$actor->{external_activations}` (only the multi-domain partition sets it),
  promotes the `(do child)` handshake to per-domain module ports: caller (SRC)
  `<start>`→output/`<done>`→input; callee (DEST) `<start>`→input/`<done>`→output,
  gating `child`'s entry on `<start>` (synthesizing a start-gated `<child>_idle_ext`
  for a body-only transaction) and asserting `<done>` at its terminal.
  `_validate_child_transaction_refs` accepts a caller target absent from the
  per-domain module. Uncovered cross-domain `(do)` and any activation-crossing
  `lower()` STILL fail closed. Locked by `t/1387`; broad regression (39 files,
  246) PASS.
- `2026-05-30`: `.4` shipped — the CDC routing structure, behind the guard.
  (a) The cross-domain caller now emits a ONE-CYCLE `<start>` request (a
  sequential request state, asserted on entry like a spawn start, then the
  await-on-`<done>` state); a held level would re-pulse the acknowledged-event CDC
  (which toggles on `request && ready` and re-arms after each round trip) and
  re-trigger `child`. (b) `_emit_multi_domain_top` emits the two acknowledged-event
  CDC children (`<actor>__cdc_activation_<child>_{start,done}`) and wires start
  SRC→DEST (`SRC.<child>_start`→request, pulse→`DEST.<child>_start`) and done
  DEST→SRC (`DEST.<child>_done`→request, pulse→`SRC.<child>_done`), reusing a
  shared `_emit_cdc_event_rtlif` (the event rtlif refactored to delegate to it, so
  event-crossing output is unchanged). The CDC `ready` outputs are left open —
  one outstanding by construction, with the `<done>` pulse as the acknowledgement.
  All exercised only via direct unit calls (behind the still-fail-closed guard);
  `t/1387` (5 subtests) + event-crossing goldens (`t/1247`/`t/1255`/`t/1116`)
  regression (13 files, 449) PASS.
- `2026-05-30`: `.5` shipped — the correctness-critical integration; cross-domain
  activation now lowers end-to-end. `_validate_transaction_clause_domain_refs`
  accepts a top-level cross-domain `(do child)` covered by an `(activation ...)`
  crossing (`_activation_crossing_covers`); `_build_domain_partition` validates the
  crossing owns a real activation (child in DEST + a SRC transaction performs the
  `(do)`) and fails closed otherwise; `_domain_actor_for_scheduled_artifact`
  injects `external_activations` (caller→SRC, callee→DEST); the `lower()` guard is
  removed. The handshake CONSUMES the CDC `ready` outputs (correcting `.4`'s
  ready-open, which the composition rejects): the caller `(await <start>_ready)`
  before its one-cycle `<start>` pulse and the callee `(await <done>_ready)` before
  pulsing `<done>` (the event-crossing idiom). End-to-end the actor lowers to
  per-domain modules + a top routing start SRC→DEST and done DEST→SRC through the
  two CDC children; per-domain modules pass Verilator lint + yosys synthesis and
  the composition emits complete HDL (5 modules); the only residual warnings are
  the pre-existing `shared_dp_export_*` PINMISSING (parity with the shipped
  event-crossing multi-domain HDL). Uncovered cross-domain `(do)` and
  declared-but-unused crossings still fail closed. `t/1387` (7 subtests) + sweep
  (16 files, 557) + full `ci-regression isf` PASS. (Cross-domain `spawn`, nested
  cross-domain `(do)`, and the activation report metadata remain follow-ups.)
- `2026-05-31`: `.6` shipped — the feature is now reviewable in the book. Added an
  Activation Crossing section to `13a-actor-interface.md` (surface, dual-CDC
  routing, await-ready handshake, generated artifacts, fail-closed boundaries) with
  a full runnable `(actor cross_domain_activation ...)` example that lowers to the
  three artifacts and generates complete HDL (5 modules); a cross-reference from
  the `(do)` surface in `13b-transactions.md`; a "Cross-domain activation crossing"
  row in the `13k` feature-support matrix; and `14-feature-backlog.md` updates
  (book-example count 38→39, top-level cross-domain activation moved from "needs a
  CDC contract" to shipped while repeat-body/nested + `spawn` stay deferred). The
  book gates pass: `t/1376` now lowers 39 complete examples, `t/1305` feature-matrix
  audit + `t/1304`/`t/1307`/`t/1332` doc-truth audits PASS, `mdbook build` clean.
  Report metadata + downstream/contract/SPECFORGE sync moved to `.7`.
- `2026-05-31`: `.7` shipped — closes the tree. The schedule report now exposes
  the activation crossing: `_build_domain_partition` records an activation summary
  (`kind:"activation"` with `child`, `source_domain`/`destination_domain`,
  `start_signal`/`done_signal`, `start_instance`/`start_module`,
  `done_instance`/`done_module`, `outstanding_policy`, `payload`) plus per-domain
  endpoints `{ activation, role, start, done }`; `Emitter::JSON` branches
  `_crossing_event_summary`/`_clock_domain_crossing_endpoint_summary` on kind (the
  event shape is unchanged). Synced `ISF_DOWNSTREAM_INTEGRATION_SPEC.md`
  (activation crossing primitive rules), `ISF_PUBLIC_INTERFACE_CONTRACT.md`
  (report shape + `t/1387` reference), and a dated `SPECFORGE_FEEDBACK_RESPONSE.md`
  entry. `t/1387` gains a report-shape subtest (now 8). Report audits
  (`t/1116`/`t/1255`) + doc-truth audits + full `ci-regression isf` PASS. The whole
  `ISF-CROSS-DOMAIN-ACTIVATION-VIA-CROSSING` tree is complete; cross-domain
  `(spawn)` and nested cross-domain `(do)` remain as separate follow-up trees.
