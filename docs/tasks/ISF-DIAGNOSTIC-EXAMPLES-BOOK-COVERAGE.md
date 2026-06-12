# ISF-DIAGNOSTIC-EXAMPLES-BOOK-COVERAGE: Add Book Examples For Targeted Diagnostics

## Metadata

- Tree ID: `ISF-DIAGNOSTIC-EXAMPLES-BOOK-COVERAGE`
- Status: `done`
- Roadmap lane: `R14`
- Created: `2026-05-27`
- Last updated: `2026-05-27`
- Owner: repo-local workflow

## Goal

Add focused `.fsm` source examples to the appropriate book chapters
showing the exact shape that triggers each of the seven targeted
diagnostics shipped this session. The recent diagnostic-precision
slices added deferral wording to `14-feature-backlog.md` and brief
prose to `13b-transactions.md`, `13d-control-flow.md`,
`13h-lowering-reference.md`, and `13k-isf-feature-support-matrix.md`,
but no user-facing example exists in the book that says "here is the
input that triggers this, here is the diagnostic, here is the
deferred lane it names." The slice closes that gap so an author can
identify the rejection cause from book content alone.

Targeted diagnostics covered by this slice:

1. `cross-domain repeat-body do remains deferred`
2. `repeat-count parameter ... repeat counts remain deferred`
3. `wait-count parameter ... wait counts remain deferred`
4. `latency-bound parameter ... latency bounds remain deferred`
5. `watchdog-limit parameter ... watchdog limits remain deferred`
6. `loop-contained repeat-body <do|spawn> remains deferred`
7. `deeper-nested repeat-body <do|spawn> remains deferred`

## Non-Goals

- Do not change validator behavior, lowering, schedule reports,
  generated HDL, manifests, public API, tests, or runtime behavior.
- Do not audit every shipped feature for example coverage — that is
  a broader follow-on. This slice covers only the seven diagnostics
  shipped this session.
- Do not add executable test fixtures from these examples — the
  examples are illustrative book content, not regressions.
  Regressions are already locked in `t/1369`, `t/1370`, `t/1372`,
  `t/1373`, `t/1374`, `t/1375`.

## Acceptance Criteria

- For each of the seven targeted diagnostics, the book contains:
    * a minimal `.fsm` source fragment showing the rejected shape,
    * the verbatim diagnostic text, and
    * a brief sentence naming the deferred lane.
- The examples land in chapters where the relevant feature is
  already discussed:
    * cross-domain repeat-body do → `13b-transactions.md`
    * activation-override sub-axis gates (repeat-count, wait-count,
      latency-bound, watchdog-limit) → `13b-transactions.md`
    * loop-contained repeat-body → `13d-control-flow.md`
    * deeper-nested repeat-body → `13d-control-flow.md`
- Audits `t/1305-isf-book-feature-matrix-audit.t`,
  `t/1307-isf-loop-body-doc-truth-audit.t`, and
  `t/1332-isf-atl-doc-status-audit.t` continue to pass.
- mdBook builds clean; `git diff --check` clean.
- Live docs (MEMORY.md, ROADMAP_STATUS.md, CHANGES.md,
  DEVELOPMENT_NOTES.md, LIVE_ACHIEVEMENT_STATUS.md, README.md,
  docs/TASK_TREE.md) reflect the coverage.
- The slice is committed through `COMMIT.md`.

## Task Tree

- ID: `ISF-DIAGNOSTIC-EXAMPLES-BOOK-COVERAGE`
  Status: `done`
  Goal: `Add user-facing book examples for the seven targeted diagnostics shipped this session.`
  Children:
    `ISF-DIAGNOSTIC-EXAMPLES-BOOK-COVERAGE.1`,
    `ISF-DIAGNOSTIC-EXAMPLES-BOOK-COVERAGE.2`

- ID: `ISF-DIAGNOSTIC-EXAMPLES-BOOK-COVERAGE.1`
  Status: `done`
  Goal: `Select the coverage slice; record scope and target chapters.`
  Acceptance: `Task tree exists and is committed before any book change.`
  Verification: `mdbook build docs/book; git diff --check`
  Commit: `pending`

- ID: `ISF-DIAGNOSTIC-EXAMPLES-BOOK-COVERAGE.2`
  Status: `done`
  Goal: `Ship the seven book examples plus live-doc updates.`
  Acceptance: `Each diagnostic has a source-shape example, verbatim diagnostic, and deferred-lane sentence in the appropriate chapter; audits still pass.`
  Verification: `prove -Iperl t/1305 t/1307 t/1332; mdbook build docs/book; git diff --check`
  Commit: `pending`

## Current Frontier

| Order | Leaf | Status | Why next |
| --- | --- | --- | --- |
| 1 | `closed` | `done` | Both leaves shipped. `.2` added seven examples to 13b (five) and 13d (two), each with rejected `.fsm` shape, verbatim diagnostic, and deferred-lane note. Audits reverified clean. |

## Decisions

- `2026-05-27`: Picked after the user noted the recent slices
  synced deferral prose but did not add user-facing examples. The
  book currently mentions "loop-contained repeat-body" and
  "deeper-nested repeat-body" diagnostics in passing in 13b/13d/13h/
  13k but contains no `.fsm` source fragment that an author can
  point to as "this is the shape that triggers the rejection".
  Cross-domain repeat-body do and the four activation-override
  sub-axis diagnostics have no chapter mention at all.
- `2026-05-27`: Place activation-override examples in
  `13b-transactions.md` next to the existing
  "Generated child activation overrides for repeat-count transaction
  parameters must preserve the child default value" paragraphs.
  Place cross-domain example in the same chapter near the existing
  clock-domain partition discussion. Place loop-contained and
  deeper-nested examples in `13d-control-flow.md` next to the
  existing "deeper branch nesting and loop-contained repeats remain
  outside both nested subsets" sentence so readers find them where
  they look up control-flow nesting.

## Open Questions

- None blocking this slice. A broader audit of feature-example
  coverage across the book is a future task tree.

## Blockers

- None.

## Verification Log

| Date | Leaf | Checks | Result |
| --- | --- | --- | --- |
| `2026-05-27` | `ISF-DIAGNOSTIC-EXAMPLES-BOOK-COVERAGE.1` | `mdbook build docs/book`; `git diff --check` | `PASS`; selection-only commit |
| `2026-05-27` | `ISF-DIAGNOSTIC-EXAMPLES-BOOK-COVERAGE.2` | `prove -Iperl t/1305 t/1307 t/1332` (Files=3, Tests=709); `mdbook build docs/book`; `git diff --check` | `PASS` |

## Commit Log

| Leaf | Commit subject or reference | Notes |
| --- | --- | --- |
| `ISF-DIAGNOSTIC-EXAMPLES-BOOK-COVERAGE.1` | `0662a08e ISF-DIAGNOSTIC-EXAMPLES-BOOK-COVERAGE.1: select book examples for new targeted diagnostics` | Selection commit. |
| `ISF-DIAGNOSTIC-EXAMPLES-BOOK-COVERAGE.2` | `ISF-DIAGNOSTIC-EXAMPLES-BOOK-COVERAGE.2: ship book examples for new targeted diagnostics` | `pending commit hash` |

## Changelog

- `2026-05-27`: Created doc-only coverage task tree to add
  user-facing book examples for the seven targeted diagnostics
  shipped this session. The slice closes the gap between the
  validator (which emits the diagnostics) and the book (which
  currently only paraphrases the deferrals without showing the
  source shape that triggers each one).
- `2026-05-27`: Shipped `.2`. Added five examples to
  `13b-transactions.md` (cross-domain repeat-body do, repeat-count
  override gate, wait-count override gate, latency-bound override
  gate, watchdog-limit override gate) and two examples to
  `13d-control-flow.md` (loop-contained repeat-body, deeper-nested
  repeat-body). Each example shows the rejected `.fsm` shape,
  verbatim diagnostic text, and a one-sentence note naming the
  deferred lane. Audits `t/1305`, `t/1307`, `t/1332` reverified at
  `Files=3, Tests=709`.
