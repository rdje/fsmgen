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
- `.4` generated/bound conditional `(do child (params ...)/(bind ...))` in
  branch/loop bodies.
- `.5` `(spawn ...)` + `await_all`/`await_any` drains in branch/loop bodies.
- `.6` docs/examples sweep + feature-matrix/doc-truth sync (the `13d`/`13b`
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
  Commit: `ship commit (this slice)`

## Current Frontier

| Order | Leaf | Status | Why next |
| --- | --- | --- | --- |
| 1 | `.1` | `done` | Selection/design. |
| 2 | `.2` | `done` | when-body local `(do child)` shipped (allow-list + `_expand_when` do branch + collector + `_wire_do_children` gating); 13d/13b updated; `t/1388`. |
| 3 | `.3` | `done` | local `(do child)` extended to `switch`/`while`/`until` bodies (same pattern; `_expand_switch`/`_expand_loop_body` do branch + allow-list + collector); local conditional activation now complete across all branch/loop bodies; `t/1388`. |
| 4 | `.4` | `pending` | generated/bound conditional `(do child (params ...)/(bind ...))` in branch/loop bodies. |
| 5 | `.5`–`.7` | `pending` | `(spawn)` + `await_all`/`await_any` drains in branch/loop bodies; docs/examples sweep. |

## Decisions

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

## Commit Log

| Leaf | Commit subject or reference | Notes |
| --- | --- | --- |
| `.1` | `ISF-CONDITIONAL-CHILD-ACTIVATION.1: select` | (committed) |
| `.2` | `ISF-CONDITIONAL-CHILD-ACTIVATION.2: when-body local (do child) (conditional one-shot activation)` | `189191cc` |
| `.3` | `ISF-CONDITIONAL-CHILD-ACTIVATION.3: local (do child) in switch/while/until bodies` | `ship commit (this slice)` |

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
