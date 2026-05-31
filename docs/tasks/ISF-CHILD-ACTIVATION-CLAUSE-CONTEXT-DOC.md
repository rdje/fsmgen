# ISF-CHILD-ACTIVATION-CLAUSE-CONTEXT-DOC: Document Where `(do)` / `(spawn)` Are Allowed

## Metadata

- Tree ID: `ISF-CHILD-ACTIVATION-CLAUSE-CONTEXT-DOC`
- Status: `done`
- Roadmap lane: `R14` (ISF — book ↔ codebase truth)
- Created: `2026-05-31`
- Last updated: `2026-05-31`
- Owner: repo-local workflow

## Goal

Document clearly in the mdBook the clause-context limitation for child-activation
clauses (`do`, `spawn`, `await_all`, `await_any`): they are supported only as
top-level transaction clauses or inside a `repeat` body — not directly inside a
`when` / `switch` / `while` / `until` body. Per the user directive (2026-05-31)
and the doctrine that the mdBook must reflect what the codebase actually does.

## Ground truth (investigated `2026-05-31`)

- `%SUPPORTED_TRANSACTION_CLAUSES` (`FSM/Scheduler/ISF/LoweringIR.pm`) is the
  per-context allow-list checked by `_validate_supported_transaction_clauses`.
  `do` / `spawn` / `await_all` / `await_any` appear only in the `transaction`
  (top-level) and `repeat` contexts. The `when` / `switch` / `while` / `until`
  contexts allow `repeat` (which can in turn contain `do`/`spawn`) but not `do` /
  `spawn` directly.
- Confirmed empirically: a plain `(do worker)` directly in a `(when cond ...)`
  body is rejected with `Transaction '<tn>': unsupported '(do ...)' clause in
  when body`.

## Rationale (objective assessment)

There is **no fundamental semantic rationale** for the limitation. A `(do)` is a
blocking activation, and a blocking construct is not the obstacle: `(await ...)`
(also blocking) IS allowed in `when`/`switch`/`while`/`until` bodies. The
restriction is an **implementation-scoping deferral** — the child-activation
lowering was wired into the top-level and `repeat`-body paths (single activation;
looped activation, the priority use cases), but not into the conditional
branch-body lowering (`_expand_when` / `_expand_switch`). A conditional one-shot
`(do)` in a branch body is sensible and could be supported; lifting the
limitation is tracked as possible future language-richness work (it aligns with
the goal of ISF feeling like a rich high-level language), separate from this
documentation tree.

## Design

- `.1` select (this doc).
- `.2` book documentation: add a clear "Where child activations are allowed"
  note to `13d-control-flow.md` (the contexts where `do`/`spawn`/`await_all`/
  `await_any` are/aren't supported, with the implementation-scoping rationale and
  the `(repeat (do ...))` workaround), and a cross-reference from `13b`'s
  activation surface. Keep all `lisp`-tagged `(actor ...)` examples lowering
  cleanly (`t/1376`) — describe the rejected form in prose / inline code, not a
  full `(actor ...)` block.

## Non-Goals

- Lifting the limitation (supporting `(do)`/`(spawn)` directly in when/switch/
  while/until bodies) — a separate future feature tree.

## Acceptance Criteria

- `13d` clearly states where `do`/`spawn`/`await_all`/`await_any` are supported
  and where they are not, with the rationale and the `repeat` workaround; `13b`
  cross-references it; book gates (`t/1376`/`t/1305`/`t/1304`/`t/1307`/`t/1332`)
  pass; `mdbook build` clean.

## Task Tree

- ID: `ISF-CHILD-ACTIVATION-CLAUSE-CONTEXT-DOC`
  Status: `active`
  Goal: `Document the do/spawn clause-context limitation + rationale in the mdBook.`
  Children: `.1` (select), `.2` (book note + cross-ref)

- ID: `ISF-CHILD-ACTIVATION-CLAUSE-CONTEXT-DOC.1`
  Status: `done`
  Goal: `Select; record ground truth + objective rationale + doc plan.`
  Acceptance: `Task tree committed before the doc change.`
  Verification: `git diff --check`
  Commit: `ship commit (this slice)`

## Current Frontier

The tree is complete (`.1`/`.2` done).

| Order | Leaf | Status | Why next |
| --- | --- | --- | --- |
| 1 | `.1` | `done` | Selection/design. |
| 2 | `.2` | `done` | Book note ("Where Child Activations Are Allowed" in `13d`) + `13b` cross-reference shipped; workaround verified to lower; book gates PASS. |

## Decisions

- `2026-05-31`: documenting the limitation is split from lifting it. The mdBook
  must reflect current behavior now (user directive); lifting the limitation is a
  separate, larger language feature.

## Open Questions

- None for the documentation. (Whether/when to lift the limitation is a separate
  product/roadmap decision.)

## Blockers

- None.

## Verification Log

| Date | Leaf | Checks | Result |
| --- | --- | --- | --- |
| `2026-05-31` | `.1` | `git diff --check` | `PASS` |
| `2026-05-31` | `.2` | `mdbook build docs/book`; `prove -Iperl t/1376 t/1305 t/1304 t/1307 t/1332 t/1303` (6 files, 874) PASS; workaround `(when cond (repeat 1 (do worker)))` verified to lower; `git diff --check` | `PASS` |

## Commit Log

| Leaf | Commit subject or reference | Notes |
| --- | --- | --- |
| `.1` | `ISF-CHILD-ACTIVATION-CLAUSE-CONTEXT-DOC.1: select` | (committed) |
| `.2` | `ISF-CHILD-ACTIVATION-CLAUSE-CONTEXT-DOC.2: document (do)/(spawn) clause-context limitation in mdBook` | `ship commit (this slice)` |

## Changelog

- `2026-05-31`: Created in response to the user's directive to document the
  `(do)`/`(spawn)` clause-context limitation in the mdBook, and the question of
  its rationale. Recorded the ground truth (`%SUPPORTED_TRANSACTION_CLAUSES`),
  the objective rationale (no fundamental reason — implementation-scoping
  deferral; blocking `await` is allowed in those contexts), and the doc plan.
- `2026-05-31`: `.2` shipped; tree complete. Added a "Where Child Activations Are
  Allowed" section to `13d-control-flow.md` (the supported/unsupported contexts
  for `do`/`spawn`/`await_all`/`await_any`, the `(repeat ...)` workaround verified
  to lower, the implementation-scoping rationale, and the cross-domain corollary)
  and a cross-reference from the `13b` activation surface. Book gates pass.
