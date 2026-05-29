# ISF-FRONTIER-SPAWN-AWAITANY-BOOK-RUNNABLE-EXAMPLES: Runnable Book Examples for Loop/Deeper Repeat-Body Spawn + Multi-Pending Await_Any

## Metadata

- Tree ID: `ISF-FRONTIER-SPAWN-AWAITANY-BOOK-RUNNABLE-EXAMPLES`
- Status: `done`
- Roadmap lane: `R14`
- Created: `2026-05-30`
- Last updated: `2026-05-30`
- Owner: repo-local workflow

## Goal

The repeat-body-activation nesting frontier shipped six slices. Three already
have runnable `lisp` `(actor …)` examples in `13d-control-flow.md`
(`loop_contained_repeat_do`, `loop_contained_repeat_generated_do`,
`deeper_nested_repeat_do`). The two spawn/await_any slices
([[ISF-LOOP-CONTAINED-AND-DEEPER-NESTED-REPEAT-BODY-SPAWN-LOWERING]],
[[ISF-LOOP-AND-DEEPER-REPEAT-BODY-MULTI-PENDING-AWAITANY-LOWERING]]) are
documented only with prose / `text` blocks. Per the standing directive ("the
book is the only way I can review the project; keep every feature documented
with copy-pasteable examples"), add runnable `lisp` `(actor …)` examples for:

1. Loop-contained repeat-body `spawn` + same-body `(await_all done)`.
2. Loop/deeper repeat-body multi-pending `(await_any done)` + later
   `(await_all done)` drain.

Both lower cleanly (verified), so `t/1376` (book-example lowering audit) gates
them. (`--check-json`/full-HDL is the pre-existing repeat-spawn composition
limitation; `t/1376` checks lowering, which succeeds.)

## Non-Goals

- No code/behavior change; documentation only.
- No new crossing-primitive / CDC work.

## Acceptance Criteria

- `13d-control-flow.md` gains two runnable `lisp` `(actor …)` examples (one
  spawn+await_all, one multi-pending await_any + drain) that `t/1376` lowers.
- `t/1376` fixture count increases by 2 (36 → 38); the `14-feature-backlog.md`
  count note is updated.
- `prove -Iperl t/1376 t/1305 t/1307 t/1304 t/1332 t/1250` passes; mdBook clean;
  `git diff --check` clean.
- Each leaf committed via `COMMIT.md`.

## Task Tree

- ID: `ISF-FRONTIER-SPAWN-AWAITANY-BOOK-RUNNABLE-EXAMPLES`
  Status: `done`
  Goal: `Add runnable book examples for the shipped loop/deeper spawn + multi-pending features.`
  Children: `.1`, `.2`

- ID: `ISF-FRONTIER-SPAWN-AWAITANY-BOOK-RUNNABLE-EXAMPLES.1`
  Status: `done`
  Goal: `Select the slice.`
  Acceptance: `Task tree committed before any doc change.`
  Verification: `mdbook build docs/book; git diff --check`
  Commit: `3036f5ac`

- ID: `ISF-FRONTIER-SPAWN-AWAITANY-BOOK-RUNNABLE-EXAMPLES.2`
  Status: `done`
  Goal: `Add the two runnable examples; update the count; validate.`
  Acceptance: `t/1376 lowers both (count 36 → 38); audits green.`
  Verification: `prove -Iperl t/1376 t/1305 t/1307 t/1304 t/1332 t/1250 (Files=6, Tests=853, PASS); mdbook build docs/book; git diff --check`
  Commit: `ship commit (this slice)`

## Current Frontier

| Order | Leaf | Status | Why next |
| --- | --- | --- | --- |
| 1 | `....1` | `done` | Selection commit `3036f5ac`. |
| 2 | `....2` | `done` | Two runnable examples added (count 36→38); tree closed. |

## Decisions

- `2026-05-30`: After the nesting frontier exhausted its lowering work, the
  next bounded R14 value is book example-coverage of the shipped features (the
  user's primary review surface), not the net-new CDC crossing-primitive lane.

## Open Questions

- None.

## Blockers

- None.

## Verification Log

| Date | Leaf | Checks | Result |
| --- | --- | --- | --- |
| `2026-05-30` | `....1` | `mdbook build docs/book`; `git diff --check` | `PASS` |
| `2026-05-30` | `....2` | `prove -Iperl t/1376 t/1305 t/1307 t/1304 t/1332 t/1250` (Files=6, Tests=853, PASS; t/1376 count 36→38); `mdbook build docs/book`; `git diff --check` | `PASS` |

## Commit Log

| Leaf | Commit subject or reference | Notes |
| --- | --- | --- |
| `....1` | `...1: select frontier spawn/await_any book runnable examples` | `3036f5ac` |
| `....2` | `...2: ship frontier spawn/await_any book runnable examples` | `ship commit (this slice)` |

## Changelog

- `2026-05-30`: Created. Book example-coverage for the shipped loop/deeper
  spawn + multi-pending await_any frontier features.
- `2026-05-30`: `.1` selection committed (`3036f5ac`).
- `2026-05-30`: `.2` shipped. Added `loop_contained_repeat_spawn` and
  `loop_contained_repeat_multi_await_any` runnable `lisp` examples to 13d;
  `t/1376` count 36 → 38; audit set (6 files, 853) PASS. All shipped
  repeat-body-activation frontier shapes now have copy-pasteable book examples.
  Tree closed.
