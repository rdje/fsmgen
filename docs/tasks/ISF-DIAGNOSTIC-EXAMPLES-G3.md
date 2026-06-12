# ISF-DIAGNOSTIC-EXAMPLES-G3: Add Book Examples For Remaining `remains deferred` Diagnostics

## Metadata

- Tree ID: `ISF-DIAGNOSTIC-EXAMPLES-G3`
- Status: `done`
- Roadmap lane: `R14`
- Created: `2026-05-29`
- Last updated: `2026-05-29`
- Owner: repo-local workflow

## Goal

Address audit gap G3 from
[`docs/audits/ISF-MDBOOK-COVERAGE-AUDIT-2026-05-27.md`](../audits/ISF-MDBOOK-COVERAGE-AUDIT-2026-05-27.md):
extend the targeted-diagnostic example coverage to the remaining
`remains deferred` template families that the prior
`ISF-DIAGNOSTIC-EXAMPLES-BOOK-COVERAGE` slice did not cover.

Three template families remain:

1. **Package-constant aggregate/member path** (9 sub-axis variants
   across activation override, actor default, transaction default,
   data-op width, contract window, repeat count, wait count,
   latency, watchdog). All emit a `remains deferred; <axis> accept
   only qualified package scalar constants in this slice`
   diagnostic. One representative example covers the family
   because the rejection mechanic is identical.
2. **Two-child data route** (4 sub-cases: repeated activation,
   cross-transaction route continuation, interleaved parent work,
   pre/post route parent work). Each emits a different `... in the
   current subset; <case> remains deferred` diagnostic. Two
   representative examples (repeated activation + pre/post parent
   work) capture the family.
3. **await_any after the (later) do/spawn** (4 sub-cases varying
   by do vs spawn-after vs local vs generated kind). All emit the
   `'(await_any done)' after the (later) do/spawn remains
   deferred` phrase. One representative example covers the family.

Total: 4 new examples (1 + 2 + 1).

## Non-Goals

- Do not add complete actors that fail to lower. The rejection
  fragments live in non-`(actor ...)` `lisp` blocks (audit script
  classifies them as fragments).
- Do not change validator behavior, tests, or runtime.
- Do not extend coverage to fail-closed diagnostics outside the
  three template families above.

## Acceptance Criteria

- New rejection-fragment examples appear in the relevant chapters:
    * Package-constant aggregate in `13j-type-enum-aggregate.md`
      (the chapter that already discusses aggregate package
      constants).
    * Two-child data route examples in `13g-rules.md` (the chapter
      that introduces rule-driven data routes).
    * await_any-after-do/spawn in `13b-transactions.md` (near the
      existing missing-drain section).
- Each example shows: the rejected source fragment, the verbatim
  diagnostic text, and a one-sentence note naming the deferred
  lane.
- The example-correctness audit re-run reports zero new failing
  blocks.
- Audits `t/1305`, `t/1307`, `t/1332` continue to pass.
- mdBook builds clean; `git diff --check` clean.
- The slice is committed through `COMMIT.md`.

## Task Tree

- ID: `ISF-DIAGNOSTIC-EXAMPLES-G3`
  Status: `done`
  Goal: `Address audit gap G3 by adding examples for the three remaining "remains deferred" template families.`
  Children: `ISF-DIAGNOSTIC-EXAMPLES-G3.1`, `ISF-DIAGNOSTIC-EXAMPLES-G3.2`

- ID: `ISF-DIAGNOSTIC-EXAMPLES-G3.1`
  Status: `done`
  Goal: `Select the slice.`
  Acceptance: `Task tree exists.`
  Verification: `mdbook build docs/book; git diff --check`
  Commit: `pending`

- ID: `ISF-DIAGNOSTIC-EXAMPLES-G3.2`
  Status: `done`
  Goal: `Ship the four representative examples plus live-doc updates.`
  Acceptance: `Each family is exampled; audits still pass.`
  Verification: `audit script; prove -Iperl t/1305 t/1307 t/1332; mdbook build docs/book; git diff --check`
  Commit: `pending`

## Current Frontier

| Order | Leaf | Status | Why next |
| --- | --- | --- | --- |
| 1 | `closed` | `done` | Both leaves shipped. `.2` added the 4 examples; audit and `t/1307` reverified clean. |

## Decisions

- `2026-05-29`: One representative example per family is sufficient
  for the package-constant and await_any families because the
  rejection mechanic is uniform across sub-axes. Two-child data
  route gets two examples because its sub-cases (repeated
  activation vs pre/post parent work) are visually distinct.

## Open Questions

- None.

## Blockers

- None.

## Verification Log

| Date | Leaf | Checks | Result |
| --- | --- | --- | --- |
| `2026-05-29` | `ISF-DIAGNOSTIC-EXAMPLES-G3.1` | `mdbook build docs/book`; `git diff --check` | `PASS`; selection-only commit |
| `2026-05-29` | `ISF-DIAGNOSTIC-EXAMPLES-G3.2` | re-audit (0 failures); `prove -Iperl t/1305 t/1307 t/1332` (Files=3, Tests=709); `mdbook build docs/book`; `git diff --check` | `PASS` (await_any example placed in 13d after `t/1307` failed initial placement in 13b) |

## Commit Log

| Leaf | Commit subject or reference | Notes |
| --- | --- | --- |
| `ISF-DIAGNOSTIC-EXAMPLES-G3.1` | `b8ff20f5 ISF-DIAGNOSTIC-EXAMPLES-G3.1: select remaining-deferred diagnostic examples` | Selection commit. |
| `ISF-DIAGNOSTIC-EXAMPLES-G3.2` | `ISF-DIAGNOSTIC-EXAMPLES-G3.2: ship remaining-deferred diagnostic examples` | `pending` |

## Changelog

- `2026-05-29`: Created task tree for audit gap G3.
- `2026-05-29`: Shipped `.2`. Added 4 representative examples
  (13j package-constant aggregate, 13f two-child route × 2, 13d
  await_any-after-do/spawn). The 13d placement was deliberate —
  initial 13b placement broke the t/1307 anchored-distance audit
  windows. During the slice the user reiterated that examples
  must lower properly; adopted convention `lisp` blocks reserved
  for accept-path fixtures only, `text` blocks for schematics and
  rejected-shape illustrations. Converted 11 prior rejection-
  fragment blocks across 13b/13d/13f/13j accordingly. Audit
  reports 20 complete fixtures lower cleanly + 0 failures.
