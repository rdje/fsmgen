# 0069 — Every surface's target pair is derived, not only the ones under pressure

- Date: 2026-08-19
- Type: infra/continuity governance
- Status: selected by `LIVE-DOCUMENT-LINE-TARGET-CALIBRATION.3.1`
- Refines: [0065](0065-live-document-line-and-byte-targets-are-derived-as-a-pair.md)
- Implementation owner: `LIVE-DOCUMENT-LINE-TARGET-CALIBRATION.3.1`
- Ceiling authority: `LIVE-DOCUMENT-LINE-TARGET-CALIBRATION.3.1-ENFORCED-RULES-LINES-EACH`
- Surface: `enforced_rules`
- Dimension: `lines_each`
- Change: `300 -> 576`
- Ceiling authority: `LIVE-DOCUMENT-LINE-TARGET-CALIBRATION.3.1-ENFORCED-RULES-LINES-TOTAL`
- Surface: `enforced_rules`
- Dimension: `lines_total`
- Change: `300 -> 576`

## Context

Decision `0065` established that a surface's `lines_each` and `bytes_each` are
one derivation and fixed the three surfaces that had already reached a
milestone. It also stated that the same defect existed elsewhere and left the
sweep to `LIVE-DOCUMENT-LINE-TARGET-CALIBRATION.3`.

The sweep confirms the defect is systemic rather than incidental. Reading
`git show 18e2dcbc6:doctrine/live_document_size/surfaces.jsonl` — the commit
`git log -S'"lines_each":300' --oneline -- doctrine/live_document_size/surfaces.jsonl`
identifies — the sixteen surfaces declared at first adoption implied bytes per
line from 44.7 to 512.0. No surface's two dimensions were checked against each
other, so which surface reached a milestone first was decided by which round
number happened to be tightest, not by which surface was actually filling up.

Measured across all nineteen surfaces that declare health targets, comparing
each declared pair with its binding member's own bytes per line:

| Surface | Implied B/line | Binding member B/line | Ratio | Line % | Byte % |
| --- | --- | --- | --- | --- | --- |
| `fact_index` | 256.0 | 84.2 | 3.04 | 28.5% | 9.4% |
| `active_index` | 163.8 | 65.8 | 2.49 | 46.7% | 18.7% |
| `high_level_direction` | 102.4 | 47.1 | 2.17 | 51.2% | 23.6% |
| `engineering_rationale` | 131.1 | 61.5 | 2.13 | 13.4% | 6.3% |
| `shipped_behavior` | 104.9 | 51.8 | 2.02 | 70.2% | 39.1% |
| `enforced_rules` | 109.2 | 56.3 | 1.94 | 74.7% | 38.5% |
| `isf_reference` | 104.9 | 69.9 | 1.50 | 49.1% | 32.7% |
| `root_documents` | 87.4 | 60.9 | 1.44 | 4.1% | 2.9% |

`readme_entrypoint` (1.09), `focused_documents` (1.19), `ancillary_documents`
(1.18), `focused_document_index` (1.02), `task_evidence` (1.31),
`knowledge_cards` (0.93), `fact_index_shards` (1.04), `diagnostics` (1.00), and
`live_document_review` (0.97) are already one derivation and are unchanged.
`active_resume` (4.68) and `rationale` (1.99) are the divergences `0066` and
`0065` point 7 deliberately record.

## Decision

1. **The sweep is the unit of work, not the surface under pressure.** A pair is
   audited because it is declared, not because it has started rejecting writes.
   Waiting for a milestone to fire selects surfaces by the accident of which
   round number was tightest, which is how `0065`'s three surfaces were found.
2. **The reviewed dimension follows the surface's information role, and the
   other dimension is derived from the binding member's measured bytes per
   line.** For a mandatory-read chooser the reviewed dimension is bytes,
   because reading cost is the budget. For a browsable bounded snapshot,
   ledger window, or per-part reference bound the reviewed dimension is lines.
3. `enforced_rules` is a mandatory-read chooser and takes the same treatment
   `0065` point 3 gave `diagnostics`. `DOCTRINE_ENFORCEMENT.md` is read on every
   session start and on every doctrine question, so its 32,768-byte reading
   budget is the reviewed statement of its cost and is unchanged. `lines_each`
   becomes `576` — the line count 32 KiB of 56.3-byte lines actually is. It was
   the surface closest to obstruction at 74.7%, sixteen lines from its warning,
   while reporting 38.5% byte pressure.
4. `high_level_direction`, `active_index`, `fact_index`, and
   `engineering_rationale` keep their reviewed line budgets and take a derived
   byte budget: `65,536 -> 32,768`, `196,608 -> 81,920`, `131,072 -> 45,056`,
   and `262,144 -> 131,072`. Each is a lowering, so none needs authority. None
   relieves an obstruction, because none of these surfaces is obstructed; the
   change removes a dead dimension that reported a filling document as nearly
   empty.
5. `root_documents` takes `lines_each 12,000 -> 1,200`, `bytes_each
   1,048,576 -> 81,920`, `lines_total 30,000 -> 8,000`, and `bytes_total
   4,194,304 -> 524,288`. A twelve-thousand-line, one-megabyte bound on a single
   root Markdown file is not a budget the retained surface can reach: the
   largest root document is `LIVE_DOCUMENT_SIZE_CONTAINMENT.md` at 492 lines.
   `1,200` is about 2.4x that document, which keeps roughly thirty further
   adoption notes of headroom before its warning.
6. `shipped_behavior` and `isf_reference` are multi-class collections and are
   derived from the densest part that can actually reach the 5,000-line
   per-part bound — `14g-axi-dynamic-identity.md` at 70.5 and
   `04-reports-fixtures-deferrals.md` at 73.6 — not from the collection mean.
   `bytes_each` becomes `409,600` and `425,984`. Deriving from the mean would
   make a dense chapter fire on bytes before the reviewed line bound, which
   rule 1 of `0065` forbids.
7. `rationale` keeps the per-file exception `0065` point 7 records, but its
   aggregate pair was never derived: `bytes_total 2,097,152` against
   `lines_total 10,000` implies 210 bytes per line where the store measures
   56.8. `bytes_total` becomes `655,360`.
8. **A re-derivation may not create a new warning.** Every value above was
   checked against current usage before it was written; the highest resulting
   pressure among the nine changed surfaces is `shipped_behavior`'s unchanged
   70.2% line peak, and no surface changes containment state.
9. No milestone percentage, ratchet, verifier, authority requirement, decision
   pairing, or debt baseline changes. The single increase carries its own two
   appended `ceiling_increase_authority` rows.

## Consequences

- Every governed pair is now either derived, or a divergence with a written
  reason: `active_resume` under `0066`, `rationale`'s per-file pair and the
  multi-class collections under `0065` point 7.
- `enforced_rules` moves from a 74.7% line peak to a 51.2% peak carried by
  `line_bytes_each`, so an ordinary section added to `DOCTRINE_ENFORCEMENT.md`
  no longer approaches a milestone at 38.5% byte pressure.
- Eight surfaces lose byte headroom they could never use. This tightens
  containment rather than relaxing it, which is the doctrine's own adoption
  checklist item 11, and costs nothing because the reviewed dimension still
  binds first on every one of them.
- The transition-allowance half of the original `.3` finding is not addressed
  here. `LIVE-DOCUMENT-LINE-TARGET-CALIBRATION.3.2` owns it, because a
  `transition.max_growth` shortfall is a different obstruction with different
  owners and a different remedy under decision `0064`.

## Containment

One bounded rationale record under the existing decision collection limits. The
sweep rule joins the calibration procedure already in the local adoption note of
`LIVE_DOCUMENT_SIZE_CONTAINMENT.md`, so a future author finds it without
reading this record.
