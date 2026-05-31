# ISF-CONDITIONAL-CHILD-ACTIVATION: `(do)`/`(spawn)` Directly In `when`/`switch`/`while`/`until` Bodies

## Metadata

- Tree ID: `ISF-CONDITIONAL-CHILD-ACTIVATION`
- Status: `active`
- Roadmap lane: `R14` (ISF — high-level language richness)
- Created: `2026-05-31`
- Last updated: `2026-05-31`
- Owner: repo-local workflow

## Goal

Make conditional child activation a first-class language construct: support a
blocking `(do child)` (and `(spawn child)`, and the `await_all`/`await_any`
drains) **directly inside a `when` body, a `switch` branch, a `while` body, and an
`until` body** — without the `(repeat 1 (do ...))` wrapping required today. This
removes a place where ISF leaks its FSM substrate and is one of the four
sanctioned "ISF as a rich high-level language" frontier themes (see
`isf-language-richness-frontier` memory). It also unblocks nested cross-domain
activation in branch bodies (`ISF-NESTED-CROSS-DOMAIN-ACTIVATION`).

## Ground truth (investigated `2026-05-31`)

- `%SUPPORTED_TRANSACTION_CLAUSES` (`FSM/Scheduler/ISF/LoweringIR.pm`) allows
  `do`/`spawn`/`await_all`/`await_any` only in the `transaction` and `repeat`
  contexts; `when`/`switch`/`while`/`until` reject them
  (`_validate_supported_transaction_clauses`: "unsupported '(do ...)' clause in
  when body").
- `_expand_when` / `_expand_switch` / `_expand_loop_body` dispatch body clauses
  for `drive`/`await`/`sample`/`wait`/`complete`/`repeat`/`when` + data-ops +
  `store`/`load`, but have **no** `do`/`spawn` branch.
- Activation registration: a top-level `(do)`/`(spawn)` is realized via
  `_ir_do`/`_ir_spawn` plus `_register_generated_activation_instance` (generated)
  or `_wire_do_children` (sibling). The activation-ref collectors
  (`_child_action_refs_from_transaction_clauses` /
  `_live_child_action_refs_from_transaction_clauses`) currently surface
  repeat-body do/spawn refs but **not** when/switch/loop-body refs — so those
  collectors must learn the branch/loop contexts too.
- No fundamental obstacle: `(await ...)` (also blocking) is already allowed in
  these bodies, so blocking activation is not the blocker — only the lowering
  wiring is missing.

## Design

- Per supported context, add `do`/`spawn` (and the `await_all`/`await_any` drains
  where a `(spawn)` appears) to the `%SUPPORTED_TRANSACTION_CLAUSES` allow-list.
- Add `do`/`spawn` handling to `_expand_when` / `_expand_switch` /
  `_expand_loop_body`: emit the `_ir_do` await-state (or `_ir_spawn` sequential
  state) inside the branch/loop region, threading the same
  `$spawn_refs`/`$constant_values`/`$generated_children`/`$repeat_do_ordinal_ref`
  params already plumbed through those expanders for repeat bodies.
- Extend the activation-ref collectors to surface when/switch/loop-body do/spawn
  refs (with a context label) so registration, `_wire_do_children`, and the
  child-ref validation see them.
- Reuse the repeat-body activation-subset validation pattern
  (`_validate_repeat_body_spawn_subset`) for branch/loop bodies, or add the
  analogous gate, so unsupported sub-shapes still fail closed with targeted
  diagnostics.
- Verify end-to-end: golden `.fsm` + HDL (`--verify-hdl` per domain) for each
  context; book examples that lower; doc-truth + feature-matrix audits updated.

## Slice plan

- `.1` select (this doc) — scope, ground truth, design.
- `.2` when-body local `(do child)` (sibling) — the simplest concrete context
  (done).
- `.3` local `(do child)` in `switch` branches + `while`/`until` bodies (same
  pattern as `.2`; consolidated because the three expanders share dispatch) —
  done. Local conditional activation now complete across all branch/loop bodies.
- `.4` BOUND local `(do child (bind ...))` in all branch/loop bodies (allow
  `(bind ...)`; `_ir_do`'s non-generated path emits the bindings) — done.
- `.5` generated `(do child (params ...))` in branch/loop bodies — the
  generated-child instance machinery in branch regions. DESIGN (investigated
  `2026-05-31`): mirror the repeat-body precedent. In `_ir_repeat` a body `(do)`
  builds `_repeat_do_ref_from_clause` (which sets `generated_child`/`instance` via
  `_generated_repeat_do_instance_name` + a `repeat_do_ordinal`), pushes the ref to
  `$spawn_refs` when generated, and calls `_ir_do($do_ref,'repeat body')`. The
  branch expanders (`_expand_when`/`_expand_switch`/`_expand_loop_body`) already
  receive `$spawn_refs`/`$constant_values`/`$generated_children`/
  `$repeat_do_ordinal_ref`, so a branch generated-do needs: (a) a branch do-ref
  builder + a branch instance-naming scheme/ordinal (new, analogous to the repeat
  one); (b) the expander `do` branch to build the ref, push to `$spawn_refs`, and
  `_ir_do($do_ref,$label)`; and the LABEL-special-cased functions extended for the
  branch contexts — (c) `_generated_child_transaction_refs` (marks generated only
  at `transaction body`/`repeat body`); (d) `_build_domain_partition`
  child-instance grouping + instance naming (~L2160); (e)
  `_validate_child_transaction_refs` (~L2766) instance naming; (f) the composition
  top wiring (reads `spawn_instances`, should be generic). Because the
  instance-naming/ordinals are load-bearing (read at several sites), this is a
  multi-function, multi-slice sub-frontier (the same-domain repeat-body
  generated-do equivalent shipped as several trees), to be sub-sliced:
  `.5a` when-body (done), `.5b` switch-branch + `.5c` while/until (done — taken
  together once `.5a` proved the expander-owns-the-instance pattern; the dead
  `_assert_when_body_local_do` deferral helper was removed). Generated conditional
  activation is now complete across all four branch/loop bodies (local + bound +
  generated). Each shipped with golden evidence + per-context fail-closed for
  deeper shapes.
- `.6` `(spawn ...)` + `await_all`/`await_any` drains in branch/loop bodies.
  DESIGN NOTE (`2026-05-31`): spawn and the drains are a coupled producer/consumer
  pair — at top level a `(spawn child as inst)` builds `_spawn_ref_from_clause`,
  emits `_ir_spawn`, and pushes `"<inst>_done"` onto a body-local done-port
  accumulator (`@dps`); a following `(await_all)`/`(await_any)` emits
  `_ir_sync_all`/`_ir_sync_any` draining that accumulator and resetting it. A spawn
  in a branch/loop body therefore needs the drain in the SAME body (the accumulator
  is body-local), so `.6` ships spawn + drains together. `when`/`switch` (single
  entry) is the tractable case (spawn-then-drain reads exactly like the top-level
  idiom under a guard); `while`/`until` adds loop-reentry semantics (a spawn inside
  the loop re-starts the same instance each iteration, drained per-iteration) — the
  repeat-body spawn/await precedent (`_ir_repeat`) is the model. Allow-list: add
  `spawn await_all await_any` to the when/switch/while/until contexts; expander:
  add `spawn`/`await_all`/`await_any` branches threading a `@dps` accumulator
  through `_expand_when`/`_expand_switch`/`_expand_loop_body`; the collector already
  surfaces branch-body spawn refs (`.2`/`.3`).
- `.7` docs/examples sweep + feature-matrix/doc-truth sync (the `13d`/`13b`
  surface is kept truthful per-slice; this consolidates any remaining examples).

## Non-Goals

- Cross-domain conditional activation (owned by
  `ISF-NESTED-CROSS-DOMAIN-ACTIVATION`; this tree is the same-domain enabler).
- Changing the existing top-level / repeat-body activation behavior.

## Acceptance Criteria

- `(do child)`/`(spawn child)` lower correctly when placed directly in a `when` /
  `switch` / `while` / `until` body (per shipped sub-slice), with golden `.fsm` +
  HDL evidence; unsupported sub-shapes fail closed with targeted diagnostics; the
  `13d` limitation note becomes a shipped-surface description; book examples lower;
  audits pass. Each leaf committed via `COMMIT.md`.

## Task Tree

- ID: `ISF-CONDITIONAL-CHILD-ACTIVATION`
  Status: `active`
  Goal: `(do)/(spawn) directly in when/switch/while/until bodies (conditional one-shot activation).`
  Children: `.1` (select), `.2`–`.6` (per-context lowering), `.7` (docs+examples)

- ID: `ISF-CONDITIONAL-CHILD-ACTIVATION.1`
  Status: `done`
  Goal: `Select; record ground truth (allow-list + expander gap + collector gap) + design + slice plan.`
  Acceptance: `Task tree committed before any code change.`
  Verification: `git diff --check`
  Commit: (committed)

- ID: `ISF-CONDITIONAL-CHILD-ACTIVATION.2`
  Status: `done`
  Goal: `Support a plain local (do child) directly in a when body (conditional one-shot activation).`
  Acceptance: `(do child) accepted in the when allow-list; _expand_when emits the do-state (asserting <child>_start, blocking on <child>_done) and the collector surfaces the when-body do so _wire_do_children gates the sibling; generated/bound when-body do and switch/while/until-body do still fail closed; HDL generates (verilator+yosys); book reflects the new surface (13d/13b updated, runnable example lowers); t/1388 + book gates pass.`
  Verification: `prove -Iperl t/1388 (3 subtests) t/1376 (40) t/1305 t/1304 t/1307 + when/clock-domain/do/spawn sweep (12 files, 551) PASS; full ./bin/ci-regression isf --no-book PASS; per-actor --verify-hdl (verilator_lint+yosys_synthesis PASS); perl -c; mdbook build; git diff --check`
  Commit: `189191cc`

- ID: `ISF-CONDITIONAL-CHILD-ACTIVATION.3`
  Status: `done`
  Goal: `Extend the plain local (do child) conditional activation to switch branches, while bodies, and until bodies (same pattern as .2).`
  Acceptance: `do added to the switch/while/until clause-context allow-lists; _expand_switch + _expand_loop_body emit the do-state (generated/bound deferred via _assert_when_body_local_do); the collector surfaces direct switch/while/until-body (do)/(spawn) so the sibling is gated; local conditional activation now lowers in all branch/loop bodies; generated/bound forms still fail closed per context; 13d/13b updated; t/1388 covers all contexts.`
  Verification: `prove -Iperl t/1388 (4 subtests) t/1376 t/1305 + clock-domain/repeat sweep PASS; full ./bin/ci-regression isf --no-book PASS; per-context lower + sibling-gate verified; perl -c; mdbook build; git diff --check`
  Commit: `e93f7883`

- ID: `ISF-CONDITIONAL-CHILD-ACTIVATION.4`
  Status: `done`
  Goal: `Accept a BOUND local (do child (bind ...)) in all branch/loop bodies (defer only the generated (params ...) form).`
  Acceptance: `_assert_when_body_local_do allows (bind ...) (defers only on (params ...) or a generated target); _ir_do's non-generated path emits the binding assignments + start in the branch/loop region; a bound local (do) lowers in when/switch/while/until and drives the bound child ports; a generated (params) (do) still fails closed with the "generated ... not yet supported" diagnostic; 13d/13b updated; t/1388 + t/1245 repointed (bound->generated deferral cascade).`
  Verification: `prove -Iperl t/1388 (5 subtests) t/1245 t/1376 t/1305 PASS; full ./bin/ci-regression isf --no-book PASS; bound lower + binding-emit verified; generated deferral verified; perl -c; mdbook build; git diff --check`
  Commit: `a2567839`

- ID: `ISF-CONDITIONAL-CHILD-ACTIVATION.5a`
  Status: `done`
  Goal: `when-body generated `(do child (params ...))` lowers to a generated child instance (conditional generated activation).`
  Acceptance: `_generated_child_transaction_refs marks a when-body do-with-params child generated; _expand_when builds a conditional do-ref (cond_do instance name, ordinal from the spawn-ref count) via _conditional_do_ref_from_clause, pushes it to spawn_refs, and _ir_do($do_ref) asserts the instance start handoff; the generated child module is built, instantiated in the top, and wired; parity with a top-level generated do (same composition-scope --check-json boundary); t/1388 asserts the lowered schedule + top.`
  Verification: `prove -Iperl t/1388 t/1245 t/1376 t/1305 t/1304 t/1307 PASS; lower + cond_do instance + top instantiation/wiring verified; parity with top-level generated do confirmed (both share the COMPOSITION_SCOPE --check-json boundary); full ./bin/ci-regression isf --no-book PASS; perl -c; mdbook build; git diff --check`
  Commit: `bf7a26e8`

- ID: `ISF-CONDITIONAL-CHILD-ACTIVATION.5b`
  Status: `done`
  Goal: `generated `(do child (params ...))` lowers to a generated child instance directly in switch/while/until bodies too (completing generated conditional activation across all four branch/loop bodies).`
  Acceptance: `_generated_child_transaction_refs marks switch-branch/while-body/until-body do-with-params children generated (label set extended); _expand_switch and _expand_loop_body do branches route generated do through the same _conditional_do_ref_from_clause + spawn-ref-push + _ir_do($do_ref) path as _expand_when (.5a); the now-dead _assert_when_body_local_do helper removed; the generated child is built + instantiated (cond_do_<n>) + wired in the top for each of switch/while/until; parity with .5a and the top-level generated do; t/1388 flips the switch-deferral subtest to a switch/while/until lowers-to-instance subtest; t/1245's generated-do-loop rejection repointed to the still-deferred (spawn ...) boundary.`
  Verification: `prove -Iperl t/1388 t/1245 t/1376 t/1305 t/1304 t/1307 PASS; per-context (switch/while/until) lower + cond_do instance + top instantiation/wiring verified; full ./bin/ci-regression isf --no-book PASS; perl -c; mdbook build; git diff --check`
  Commit: `ship commit (this slice)`

## Current Frontier

| Order | Leaf | Status | Why next |
| --- | --- | --- | --- |
| 1 | `.1` | `done` | Selection/design. |
| 2 | `.2` | `done` | when-body local `(do child)` shipped (allow-list + `_expand_when` do branch + collector + `_wire_do_children` gating); 13d/13b updated; `t/1388`. |
| 3 | `.3` | `done` | local `(do child)` extended to `switch`/`while`/`until` bodies (same pattern; `_expand_switch`/`_expand_loop_body` do branch + allow-list + collector); local conditional activation now complete across all branch/loop bodies; `t/1388`. |
| 4 | `.4` | `done` | BOUND local `(do child (bind ...))` accepted in all branch/loop bodies (relaxed `_assert_when_body_local_do` to allow `(bind ...)`; `_ir_do`'s non-generated path emits the bindings). Only the GENERATED `(params ...)` form still defers. `t/1388`/`t/1245` updated. |
| 5 | `.5a` | `done` | when-body GENERATED `(do child (params ...))` lowers to a `cond_do` generated child instance (instantiated + wired in the top, conditionally activated); parity with a top-level generated do (same composition-scope `--check-json` boundary). `t/1388`. |
| 6 | `.5b` | `done` | switch-branch + while/until GENERATED `(do child (params ...))` lower to `cond_do` instances (same `_conditional_do_ref_from_clause` path as `.5a`, routed through `_expand_switch`/`_expand_loop_body`; label set extended; dead `_assert_when_body_local_do` removed). Generated conditional activation now complete across all four branch/loop bodies. `t/1388`/`t/1245`. |
| 7 | `.6`–`.7` | `pending` | `(spawn)` + `await_all`/`await_any` drains in branch/loop bodies; docs/examples sweep. |

## Decisions

- `2026-05-31` (`.5` design): generated conditional `(do child (params ...))` is
  a multi-function, load-bearing slice (new branch do-ref builder + instance
  naming/ordinal; plus label-special-cased extensions to
  `_generated_child_transaction_refs`, the partition child-instance grouping,
  validation, and instance naming). Mirroring the repeat-body generated-do
  precedent, it is sub-sliced by context (`.5a` when, `.5b` switch, `.5c`
  while/until) and taken with fresh focus rather than rushed, per the quality bar.

- `2026-05-31`: pursue this as one of the four sanctioned language-richness
  themes (user, any order). Start with when-body local `(do)` because it is the
  smallest concrete context and exercises the full path (allow-list → expander →
  activation registration → wiring → HDL) that the other contexts reuse.

## Open Questions

- Whether `_expand_when`/`_expand_switch`/`_expand_loop_body` can share one
  `do`/`spawn` handling helper, or each context needs bespoke merge/branch-exit
  handling (resolve in `.2`).

## Blockers

- None.

## Verification Log

| Date | Leaf | Checks | Result |
| --- | --- | --- | --- |
| `2026-05-31` | `.1` | `git diff --check` | `PASS` |
| `2026-05-31` | `.2` | `prove -Iperl t/1388` (3 subtests) `t/1376` (40 examples) `t/1305 t/1304 t/1307` + when/clock-domain/do/spawn sweep (12 files, 551) PASS; full `./bin/ci-regression isf --no-book` PASS; `--verify-hdl` (verilator_lint+yosys_synthesis PASS); `perl -c`; `mdbook build`; `git diff --check` | `PASS` |
| `2026-05-31` | `.3` | `prove -Iperl t/1388` (4 subtests) `t/1376 t/1305` + clock-domain/repeat sweep PASS; full `./bin/ci-regression isf --no-book` PASS; per-context (switch/while/until) lower + sibling-gate verified; `perl -c`; `mdbook build`; `git diff --check` | `PASS` |
| `2026-05-31` | `.4` | `prove -Iperl t/1388` (5 subtests) `t/1245 t/1376 t/1305` PASS; full `./bin/ci-regression isf --no-book` PASS; bound lower + binding-emit + generated-deferral verified; `perl -c`; `mdbook build`; `git diff --check` | `PASS` |
| `2026-05-31` | `.5a` | `prove -Iperl t/1388 t/1245 t/1376 t/1305 t/1304 t/1307` PASS; lower + cond_do instance + top instantiation/wiring verified; parity with top-level generated do (shared COMPOSITION_SCOPE --check-json boundary); full `./bin/ci-regression isf --no-book` PASS; `perl -c`; `mdbook build`; `git diff --check` | `PASS` |
| `2026-05-31` | `.5b` | `prove -Iperl t/1388 t/1245 t/1376 t/1305 t/1304 t/1307` PASS; per-context (switch/while/until) lower + `cond_do` instance + top instantiation/wiring verified; full `./bin/ci-regression isf --no-book` PASS; `perl -c`; `mdbook build`; `git diff --check` | `PASS` |

## Commit Log

| Leaf | Commit subject or reference | Notes |
| --- | --- | --- |
| `.1` | `ISF-CONDITIONAL-CHILD-ACTIVATION.1: select` | (committed) |
| `.2` | `ISF-CONDITIONAL-CHILD-ACTIVATION.2: when-body local (do child) (conditional one-shot activation)` | `189191cc` |
| `.3` | `ISF-CONDITIONAL-CHILD-ACTIVATION.3: local (do child) in switch/while/until bodies` | `e93f7883` |
| `.4` | `ISF-CONDITIONAL-CHILD-ACTIVATION.4: bound local (do child) in branch/loop bodies` | `a2567839` |
| `.5a` | `ISF-CONDITIONAL-CHILD-ACTIVATION.5a: when-body generated (do child (params ...)) -> conditional generated child instance` | `bf7a26e8` |
| `.5b` | `ISF-CONDITIONAL-CHILD-ACTIVATION.5b: generated (do child (params ...)) in switch/while/until bodies` | `ship commit (this slice)` |

## Changelog

- `2026-05-31`: Created as sanctioned language-richness theme #1 (lift the
  `(do)`/`(spawn)` clause-context limitation documented by
  `ISF-CHILD-ACTIVATION-CLAUSE-CONTEXT-DOC`). Recorded the allow-list/expander/
  collector gaps and the per-context slice plan.
- `2026-05-31`: `.2` shipped — a plain local `(do child)` now lowers directly in a
  `when` body. Added `do` to the `when` clause-context allow-list; added a `do`
  branch to `_expand_when` (emits the `_ir_do` state in the branch region, with
  `_assert_when_body_local_do` deferring generated/bound forms); extended
  `_push_nested_branch_repeat_refs` to surface a direct branch-body `(do)`/`(spawn)`
  so `_wire_do_children` gates the sibling child and `_validate_child_transaction_refs`
  sees it. The when branch guards the do-state (`?cond (=1 -> do)`), which asserts
  `<child>_start` and blocks on `<child>_done`; the sibling child is gated on its
  start handshake (when it has an entry state) — same semantics as a top-level
  local `(do)`. Generated/bound when-body `(do)` and `(do)` in switch/while/until
  bodies still fail closed (deferred to later slices). Updated `13d`/`13b` (the
  limitation note becomes the supported-surface description + a runnable example)
  and bumped the book-example count (39→40). `t/1388` locks it; full
  `ci-regression isf` + `--verify-hdl` (verilator+yosys) PASS.
- `2026-05-31`: `.3` shipped — local `(do child)` extended to `switch` branches,
  `while` bodies, and `until` bodies (same pattern as `.2`). Added `do` to those
  three clause-context allow-lists; added a `do` branch to `_expand_switch` and
  `_expand_loop_body` (reusing `_assert_when_body_local_do` for the
  generated/bound deferral); extended the collector's while/until branch to
  surface a direct `(do)`/`(spawn)` (switch was already covered). Local
  conditional activation now lowers in all branch/loop bodies and gates the
  sibling child; generated/bound forms still fail closed with per-context
  diagnostics. `13d`/`13b` updated (switch/while/until local do moved to the
  supported surface; only generated/bound conditional forms remain deferred).
  `t/1388` extended to cover all four contexts (now 4 subtests). Updated `t/1245-isf-transaction-loop-lowering.t` (deferral-lift cascade): its `(while keep (do child))` "unsupported (do) in while body" rejection is now a supported local conditional activation, so the case was repointed to a generated/bound while-body do (which still defers).
- `2026-05-31`: `.4` shipped — a BOUND local `(do child (bind ...))` now lowers in
  all branch/loop bodies. `_assert_when_body_local_do` now defers only on a
  `(params ...)` override or a generated target (it allows `(bind ...)`); the
  branch/loop `do` branches already route through `_ir_do`'s non-generated path,
  which emits the binding input/output assignments alongside the start handshake.
  A bound conditional `(do worker (bind (input addr req)))` drives the child's
  bound ports and gates the sibling. The generated `(params ...)` form still fails
  closed ("generated '(do ...)' is not yet supported"). Deferral-lift cascade: the
  bound-deferral cases in `t/1388` and `t/1245` were repointed to generated
  `(params ...)` dos (still deferred); `13d`/`13b` updated (bound local do moved to
  the supported surface; only the generated form remains deferred).
- `2026-05-31`: `.5a` shipped — a when-body GENERATED `(do child (params ...))`
  now lowers to a generated child instance. `_generated_child_transaction_refs`
  marks a when-body do-with-params child generated (added `when body` to the label
  set); new `_conditional_do_ref_from_clause` builds the do-ref with a
  `_generated_conditional_do_instance_name` (`<owner>_<child>_cond_do_<n>`, ordinal
  = count of branch-do refs already in `$spawn_refs`, so the name is unique per
  owner and OWNED by the expander); the `_expand_when` do branch builds the ref,
  pushes it to `$spawn_refs`, and calls `_ir_do($do_ref,'when body')`. Because the
  expander's spawn-ref drives `_register_generated_activation_instance` and the top
  wiring, the instance identity is consistent by construction (no cross-traversal
  ordinal match needed). The generated child module is built, instantiated
  (`?fsmc:<owner>_<child>_cond_do_0 <child>`), and wired in the top; the do is
  guarded by the when branch. This is at PARITY with a top-level generated do —
  both lower + compose, and both hit the same pre-existing generated-child
  composition-scope `--check-json` boundary (`docs/COMPOSITION_SCOPE.md`), so
  `t/1388` asserts the lowered schedule + top (not `--check-json`). Generated do in
  `switch`/`while`/`until` bodies stays deferred (`.5b`/`.5c`). 13d/13b updated.
- `2026-05-31`: `.5b` shipped — generated `(do child (params ...))` now lowers to a
  `cond_do` generated child instance directly in `switch` branches, `while` bodies,
  and `until` bodies too, completing generated conditional activation across all
  four branch/loop bodies (`.5b`+`.5c` taken together since they share one pattern).
  Extended `_generated_child_transaction_refs`'s label set with `switch branch` /
  `while body` / `until body`, and routed the `_expand_switch` and
  `_expand_loop_body` `do` branches through the same `_conditional_do_ref_from_clause`
  + spawn-ref-push + `_ir_do($do_ref)` path as `_expand_when` (`.5a`). Removed the
  now-dead `_assert_when_body_local_do` helper (its deferral was the only thing the
  three branch/loop `do` branches still relied on it for). Each context builds +
  instantiates (`?fsmc:<owner>_<child>_cond_do_0 <child>`) + wires the generated
  child; parity with `.5a` and the top-level generated do (shared composition-scope
  `--check-json` boundary). `t/1388` flips the switch-deferral subtest to a
  switch/while/until lowers-to-instance subtest; `t/1245`'s generated-do-loop
  rejection is repointed to the still-deferred `(spawn ...)`-in-loop-body boundary
  (deferral-lift cascade). 13d/13b updated (generated do moved onto the supported
  surface for all four bodies; only `(spawn)`/`await_all`/`await_any` directly in
  branch/loop bodies remain deferred to top-level/`repeat`).
