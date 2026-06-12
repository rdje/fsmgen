# ISF-BOOK-EXAMPLE-LOWERING-BUILD-GATE: Build-Gate Test For Book Example Lowering

## Metadata

- Tree ID: `ISF-BOOK-EXAMPLE-LOWERING-BUILD-GATE`
- Status: `done`
- Roadmap lane: `R14`
- Created: `2026-05-29`
- Last updated: `2026-05-29`
- Owner: repo-local workflow

## Goal

Address the user's directive that examples in the book must lower
properly because users copy-paste them, and that any failure to
lower should block the build.

Add a focused regression test `t/1376-isf-book-example-lowering-audit.t`
that:

1. Extracts every `lisp` block from the ISF book chapters
   (`12-cookbook.md`, `13*.md`, and `14-feature-backlog.md`).
2. For each block that starts with `(actor`, attempts parse via
   `FSM::Adapter::ISF` and lower via `FSM::Scheduler::ISF`.
3. Fails any block that does not lower cleanly.
4. Allows blocks tagged `text` to be excluded by virtue of not
   being scanned (the test only reads `lisp` blocks).

The test joins `t/1305`, `t/1307`, `t/1332` as part of the doc
audit set and runs under `./bin/ci-regression isf`.

## Non-Goals

- Do not add a separate audit for `text` blocks.
- Do not modify the existing book content in this slice. The
  prior `ISF-BOOK-EXAMPLE-CORRECTNESS-FIX` and
  `ISF-DIAGNOSTIC-EXAMPLES-G3` slices already moved rejection
  shapes out of `lisp` blocks.
- Do not change validator behavior.

## Acceptance Criteria

- New `t/1376-isf-book-example-lowering-audit.t` exists and
  passes on the current book state (20 complete fixtures all
  lower cleanly).
- Test registers in `docs/ISF_SPEC.md` focused-tests list.
- `prove -Iperl t/1376` reports zero failures.
- `./bin/ci-regression isf --no-book` includes `t/1376` and
  passes.
- mdBook builds clean; `git diff --check` clean.
- The slice is committed through `COMMIT.md`.

## Task Tree

- ID: `ISF-BOOK-EXAMPLE-LOWERING-BUILD-GATE`
  Status: `done`
  Goal: `Add build-gate regression for book lisp-block lowering.`
  Children:
    `ISF-BOOK-EXAMPLE-LOWERING-BUILD-GATE.1`,
    `ISF-BOOK-EXAMPLE-LOWERING-BUILD-GATE.2`

- ID: `ISF-BOOK-EXAMPLE-LOWERING-BUILD-GATE.1`
  Status: `done`
  Goal: `Select the slice.`
  Acceptance: `Task tree exists.`
  Verification: `mdbook build docs/book; git diff --check`
  Commit: `pending`

- ID: `ISF-BOOK-EXAMPLE-LOWERING-BUILD-GATE.2`
  Status: `done`
  Goal: `Ship the audit test plus focused-tests registration plus live-doc updates.`
  Acceptance: `t/1376 passes; full ISF CI includes it; audits still pass.`
  Verification: `prove -Iperl t/1376 t/1305 t/1307 t/1332; ./bin/ci-regression isf --no-book; mdbook build docs/book; git diff --check`
  Commit: `pending`

## Current Frontier

| Order | Leaf | Status | Why next |
| --- | --- | --- | --- |
| 1 | `closed` | `done` | Both leaves shipped. `.2` added t/1376 + spec registration. 20 fixtures lower cleanly, 0 failures. |

## Decisions

- `2026-05-29`: Test scans `lisp` blocks only. `text` blocks are
  considered illustrative and not required to lower. This matches
  the convention adopted in `ISF-DIAGNOSTIC-EXAMPLES-G3.2`.
- `2026-05-29`: Number the test `t/1376` to slot into the existing
  ISF audit-test family (1305 / 1307 / 1332 / 1369-1375).

## Open Questions

- None.

## Blockers

- None.

## Verification Log

| Date | Leaf | Checks | Result |
| --- | --- | --- | --- |
| `2026-05-29` | `ISF-BOOK-EXAMPLE-LOWERING-BUILD-GATE.1` | `mdbook build docs/book`; `git diff --check` | `PASS`; selection-only commit |
| `2026-05-29` | `ISF-BOOK-EXAMPLE-LOWERING-BUILD-GATE.2` | `prove -Iperl t/1376 t/1305 t/1307 t/1332 t/1250` (Files=5, Tests=713); `mdbook build docs/book`; `git diff --check` | `PASS` (20 fixtures lowered cleanly, 236 fragments skipped) |

## Commit Log

| Leaf | Commit subject or reference | Notes |
| --- | --- | --- |
| `ISF-BOOK-EXAMPLE-LOWERING-BUILD-GATE.1` | `e524fcd3 ISF-BOOK-EXAMPLE-LOWERING-BUILD-GATE.1: select book-example lowering build gate` | Selection commit. |
| `ISF-BOOK-EXAMPLE-LOWERING-BUILD-GATE.2` | `ISF-BOOK-EXAMPLE-LOWERING-BUILD-GATE.2: ship book-example lowering build gate` | `pending` |

## Changelog

- `2026-05-29`: Created task tree per user directive that book
  examples must lower properly and failures should block the
  build.
- `2026-05-29`: Shipped `.2`. Added
  `t/1376-isf-book-example-lowering-audit.t` that walks 13 book
  chapters, extracts every `lisp` block, and verifies parse+lower
  for each block starting with `(actor`. Registered the test in
  `docs/ISF_SPEC.md` focused-tests list. Current state: 20
  complete fixtures lower cleanly, 236 fragments skipped, 0
  failures. ISF audit family `t/1305`, `t/1307`, `t/1332`, and
  `t/1250` all still pass.
