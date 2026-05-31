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
- `.2` when-body local `(do child)` (sibling) — the simplest concrete context.
- `.3` when-body generated `(do child (params ...))`.
- `.4` switch-branch `(do child)` (local + generated).
- `.5` `while`/`until` body `(do child)`.
- `.6` `(spawn ...)` + `await_all`/`await_any` drains in branch/loop bodies.
- `.7` docs (13d "Where Child Activations Are Allowed" updated from limitation to
  shipped surface; 13b) + runnable book examples + feature-matrix/doc-truth sync.
  (Consolidate slices where the expander handling generalizes across contexts.)

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
  Commit: `ship commit (this slice)`

## Current Frontier

| Order | Leaf | Status | Why next |
| --- | --- | --- | --- |
| 1 | `.1` | `done` | Selection/design (this commit). |
| 2 | `.2` | `pending` | when-body local `(do child)` — the simplest concrete context; establishes the expander + collector + validation pattern the later contexts reuse. |
| 3 | `.3`–`.7` | `pending` | generated do, switch, while/until, spawn+drain, docs+examples. |

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

## Commit Log

| Leaf | Commit subject or reference | Notes |
| --- | --- | --- |
| `.1` | `ISF-CONDITIONAL-CHILD-ACTIVATION.1: select` | `ship commit (this slice)` |

## Changelog

- `2026-05-31`: Created as sanctioned language-richness theme #1 (lift the
  `(do)`/`(spawn)` clause-context limitation documented by
  `ISF-CHILD-ACTIVATION-CLAUSE-CONTEXT-DOC`). Recorded the allow-list/expander/
  collector gaps and the per-context slice plan.
