# ISF-BOOK-EXAMPLE-CORRECTNESS-FIX: Fix Broken ISF Examples In Book Chapters

## Metadata

- Tree ID: `ISF-BOOK-EXAMPLE-CORRECTNESS-FIX`
- Status: `pending`
- Roadmap lane: `R14`
- Created: `2026-05-29`
- Last updated: `2026-05-29`
- Owner: repo-local workflow

## Goal

Address the 14 parse-fail and 1 lower-fail issues identified in the
example-correctness audit addendum
(`docs/audits/ISF-MDBOOK-COVERAGE-AUDIT-2026-05-27.md` §
Addendum 2026-05-29). The user requires every `.isf` example in
the book to lower cleanly to FSM.

## Non-Goals

- Do not touch the 243 fragments that are not framed as complete
  actors. They are clause-level illustrations and serve their
  purpose.
- Do not modify the 17 already-correct complete fixtures.
- Do not preserve `(actor name ...)` ellipsis shorthand in `lisp`
  blocks. Either expand the fixture or rewrite the block.
- Do not modify the 1 intentional fail-closed illustration in
  `14-feature-backlog.md` block #2 (drive `feed_crc` arity); that
  block documents a validator constraint and is expected to fail.

## Acceptance Criteria

- Every `lisp` block in `12-cookbook.md`, `13*.md`, and
  `14-feature-backlog.md` that begins with `(actor` and is meant
  to be a complete fixture parses and lowers cleanly via
  `FSM::Adapter::ISF` and `FSM::Scheduler::ISF`.
- Blocks that show clause-level fragments do not start with
  `(actor` (the fragment becomes the entire block content).
- Multi-file examples (library imports, package imports, multiple
  actors) either embed all required pieces in the same block using
  a `;; ---` separator or are converted to `text` blocks with a
  one-line lead-in naming the missing piece.
- The intentional fail-closed illustration at
  `14-feature-backlog.md` block #2 is annotated with a one-line
  `;; FAIL-CLOSED EXAMPLE` marker so future audits classify it
  correctly.
- A re-run of the audit script reports zero unintended parse
  failures.
- mdBook builds clean; `git diff --check` clean. Audits `t/1305`,
  `t/1307`, `t/1332` continue to pass.
- The slice is committed through `COMMIT.md`.

## Task Tree

- ID: `ISF-BOOK-EXAMPLE-CORRECTNESS-FIX`
  Status: `pending`
  Goal: `Fix the 14 broken ISF examples identified in the audit addendum.`
  Children:
    `ISF-BOOK-EXAMPLE-CORRECTNESS-FIX.1`,
    `ISF-BOOK-EXAMPLE-CORRECTNESS-FIX.2`

- ID: `ISF-BOOK-EXAMPLE-CORRECTNESS-FIX.1`
  Status: `pending`
  Goal: `Select the example-correctness fix slice.`
  Acceptance: `Task tree exists.`
  Verification: `mdbook build docs/book; git diff --check`
  Commit: `pending`

- ID: `ISF-BOOK-EXAMPLE-CORRECTNESS-FIX.2`
  Status: `pending`
  Goal: `Ship the fixes for all 14 broken blocks plus the intentional fail-closed marker.`
  Acceptance: `Re-run audit reports zero unintended parse failures; audits still pass.`
  Verification: `prove -Iperl t/1305 t/1307 t/1332; mdbook build docs/book; git diff --check`
  Commit: `pending`

## Current Frontier

| Order | Leaf | Status | Why next |
| --- | --- | --- | --- |
| 1 | `ISF-BOOK-EXAMPLE-CORRECTNESS-FIX.1` | `pending` | Selection commit must land first. |
| 2 | `ISF-BOOK-EXAMPLE-CORRECTNESS-FIX.2` | `pending` | Ship the 14 fixes. |

## Decisions

- `2026-05-29`: Prefer "convert to text block" for clause-level
  fragments — the `lisp` block tag advertises a parseable shape,
  so a fragment that uses ellipsis violates the user's correctness
  standard. The fragment becomes a text block (no syntax highlight,
  but honest).
- `2026-05-29`: Prefer "expand to complete fixture" for blocks
  that aim to teach a complete actor shape but currently truncate
  it with `...)`. The expanded fixture is more useful and more
  honest.
- `2026-05-29`: For multi-file examples (library/package),
  prefer "embed inline with `;; ---`" because it keeps the example
  copy-pasteable. The `;; ---` separator is a Lisp comment so it
  does not affect parse if the embed is correct.

## Open Questions

- None.

## Blockers

- None.

## Verification Log

| Date | Leaf | Checks | Result |
| --- | --- | --- | --- |
| `2026-05-29` | `ISF-BOOK-EXAMPLE-CORRECTNESS-FIX.1` | `mdbook build docs/book`; `git diff --check` | `pending` |
| `2026-05-29` | `ISF-BOOK-EXAMPLE-CORRECTNESS-FIX.2` | re-run audit; `prove -Iperl t/1305 t/1307 t/1332`; `mdbook build docs/book`; `git diff --check` | `pending` |

## Commit Log

| Leaf | Commit subject or reference | Notes |
| --- | --- | --- |
| `ISF-BOOK-EXAMPLE-CORRECTNESS-FIX.1` | `ISF-BOOK-EXAMPLE-CORRECTNESS-FIX.1: select example-correctness fix` | `pending` |
| `ISF-BOOK-EXAMPLE-CORRECTNESS-FIX.2` | `ISF-BOOK-EXAMPLE-CORRECTNESS-FIX.2: ship example-correctness fix` | `pending` |

## Changelog

- `2026-05-29`: Created task tree to fix the 14 broken examples
  identified by the audit addendum. Plan: convert ellipsis
  fragments to text blocks; expand truncated actors; embed
  library/package fixtures inline; supply missing drive in the
  real-bug case; annotate the intentional fail-closed
  illustration.
