# IAL2-AHB-REQUESTER-GENERALIZED-BUSY-COUNT-RANGE-READINESS-AUDIT: Generalized Literal BUSY Count Readiness

## Metadata

- Tree ID: `IAL2-AHB-REQUESTER-GENERALIZED-BUSY-COUNT-RANGE-READINESS-AUDIT`
- Status: `active`
- Roadmap lane: `IAL2 / AHB requester BUSY insertion`
- Created: `2026-07-30`
- Last updated: `2026-07-30`
- Owner: repo-local workflow

## Goal

Determine the safe reusable public literal-count range above four for AHB
requester BUSY insertion, and the minimum verification contract needed to widen
that range without continuing an unbounded exact-count fixture cadence.

## Current Boundary

The shipped requester accepts absence as exact-one and literal `busy-beats`
values `2..4`. Exact-one through exact-four generic/profile requester sources
and one-/two-window paired generic/profile sources ship at 332 protocol
fixtures, 373 supported-smoke plus strict fixtures, and 56 AHB paths split 28
`.ppif` / 28 `.ahb`.

An in-memory exact-five transform fails only at the current literal `2..4`
normalization diagnostic. The lowerer already derives minimum unsigned counter
width by integer iteration: 5 and 7 map to width 3, 8 and 15 to width 4, and 16
and 31 to width 5. The existing retirement rules compare `> 1` and `== 1` and
do not special-case four. Report residue and focused diagnostics still encode
the exact-four ceiling and therefore require deliberate contract work.

## Non-Goals

- Do not assume the final upper bound before evidence compares protocol,
  source-width, runtime-cost, diagnostic, and verification constraints.
- Do not add an exact-five public fixture merely to extend the existing
  one-count-at-a-time sequence.
- Do not introduce runtime-selected, random, policy-driven, or symbolic BUSY
  counts, multiple insertion points, distinct bus-BUSY status, new burst modes,
  optional AHB signals, or new topology.
- Do not activate the protocol-neutral rule/transaction output-priority repair,
  HIAL/VIAL, verification generation, VHDL, mixed-language portability,
  large-design scalability, another protocol/backend, or decision `0020`.
- Do not change parser, generator, public source, support, test, artifact,
  report, semantic/MCP API, HDL/runtime, or simulator behavior during audit
  leaf `.1`.

## Task Tree

- ID: `IAL2-AHB-REQUESTER-GENERALIZED-BUSY-COUNT-RANGE-READINESS-AUDIT`
  Status: `active`
  Goal: `Select and prove a reusable bounded literal BUSY-count range above four before any public widening.`
  Children: `IAL2-AHB-REQUESTER-GENERALIZED-BUSY-COUNT-RANGE-READINESS-AUDIT.1`

- ID: `IAL2-AHB-REQUESTER-GENERALIZED-BUSY-COUNT-RANGE-READINESS-AUDIT.1`
  Status: `active`
  Goal: `Audit generalized literal AHB requester BUSY-count readiness and select one exact next owner.`
  Acceptance: `Activate only after clean parent selector IAL2-FEATURE-COMPLETENESS-FRONTIER.829 commit. Reconcile exact-one-through-four generic/profile requester and one-/two-window paired behavior, current 332/373/56 split 28/28 support/language/capability surfaces, AhbRequester normalization/minimum-width lowering/qualified retirement/report/residue, PPIF scalar parsing, exact-four diagnostics and assertion runtime, roadmap, mdBook, Knowledge Map, decisions 0004/0008/0020, generic selector priority, HIAL/VIAL, VHDL/portability, and scale. Compare candidate upper bounds using repository-derived same-volume disposable lowerings at every counter-width transition and assertion-enabled representative runtimes, including the first admitted value above four, ready-low and grant-low non-retirement, exact qualified-event count, one resumed SEQ, unchanged data-beat completion, zero final counter, deterministic artifact/report/semantic/read-only-MCP behavior, and fail-closed zero/one/above-bound/non-literal diagnostics. Decide whether one reusable literal range can ship without new catalog fixtures, whether a smaller exact bounded increment is required, or whether a lower-layer repair is needed. Freeze the public range, minimum-width rule, report/residue wording, focused and broader validation, preservation, support-accounting impact, documentation, cleanup, rollback, and next implementation owner before behavior changes. Keep runtime/policy/random/symbolic counts, multiple insertion points, bus-BUSY status, new burst/signal/topology semantics, generic rule/transaction priority, other protocols/backends, HIAL/VIAL, VHDL, verification generation, portability implementation, scale implementation, and decision 0020 separate. Use authorized host100/process4096, canonical Stats-compatible capacity plus separate kernel pressure, exact same-volume cleanup, and COMMIT.md.`
  Verification: `Activated only after clean parent selector commit a2750d8a6. Activation changes task/index/Memory/roadmap/mdBook/selector/fact continuity only; the current literal 2..4 contract, 332/373/56 split 28/28 accounting, parser, generator, sources, support, tests, artifacts, reports, semantic/MCP APIs, HDL/runtime, simulator profiles, HIAL/VIAL, VHDL, portability, scale, decision 0020, and transaction behavior remain unchanged. Focused current-surface/backlog/relative-path gates pass 3 files/22 tests. Knowledge Map generation/check passes at 1,048 facts/5,370 question keys. mdBook builds to exactly 72 files/16,392,819 bytes and the exact ignored repository-local render is removed. MEMORY.md is 60 lines, README.md is 2,332 lines, .artifacts/tmp/tests is empty, and only the pre-existing 491-byte xcrun_db cache remains. Diff hygiene, memory architecture, and all six doctrine gates pass, including project-data locality. Final canonical Stats-compatible capacity is 13,678,051,328/25,769,803,776 bytes = 12.739/24.000 GiB = 53.08%, with separate macOS kernel pressure level 1; guard occupancy is excluded from capacity truth. Audit investigation is active with no background job.`
  Commit: `IAL2-AHB-REQUESTER-GENERALIZED-BUSY-COUNT-RANGE-READINESS-AUDIT.1: audit generalized AHB BUSY count range`

## Dependencies

- `IAL2-FEATURE-COMPLETENESS-FRONTIER.829`
- `IAL2-AHB-REQUESTER-EXACT-FOUR-BUSY-INSERTION-READINESS-AUDIT`
- `IAL2-AHB-TWO-SUBORDINATE-EXACT-FOUR-PAIRED-BUSY-COMPOSITION-READINESS-AUDIT`
- decisions `0004`, `0008`, and `0020`

## Activation Gate

Active from clean parent selector commit `a2750d8a6`. Activation itself changes
continuity pointers only; all public and generated behavior remains unchanged.

## Current Frontier

Audit `.1` must now compare finite public maxima and representative
counter-width/runtime gates, then select exactly one separate contract,
prerequisite, narrower bounded increment, or explicit fail-closed deferral.

## Rollback

Before activation, rollback removes this proposed tree plus its selector/fact
references. After activation, rollback retains the current literal `2..4`
public boundary and all shipped exact-one-through-four sources until a separate
contract and implementation prove a wider range.
