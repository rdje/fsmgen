# 0071 — A bound pinned at the current actual is not a reviewed bound

- Date: 2026-08-19
- Type: infra/continuity governance
- Status: selected by `LIVE-DOCUMENT-LINE-TARGET-CALIBRATION.3.3`
- Refines: [0064](0064-live-document-growth-is-declared-measurement-with-paired-decisions.md), [0069](0069-live-document-target-pairs-are-swept-not-fixed-under-pressure.md), [0070](0070-transition-allowances-carry-one-declared-step-and-a-live-owner.md)
- Implementation owner: `LIVE-DOCUMENT-LINE-TARGET-CALIBRATION.3.3`
- Ceiling authority: `LIVE-DOCUMENT-LINE-TARGET-CALIBRATION.3.3-FOCUSED-DOCUMENTS-FILES`
- Surface: `focused_documents`
- Dimension: `files`
- Change: `1007 -> 1280`
- Ceiling authority: `LIVE-DOCUMENT-LINE-TARGET-CALIBRATION.3.3-ROOT-DOCUMENTS-FILES`
- Surface: `root_documents`
- Dimension: `files`
- Change: `18 -> 24`
- Ceiling authority: `LIVE-DOCUMENT-LINE-TARGET-CALIBRATION.3.3-ANCILLARY-DOCUMENTS-FILES`
- Surface: `ancillary_documents`
- Dimension: `files`
- Change: `16 -> 32`

## Context

`0069` derived the target pairs and `0070` fixed the allowances. The audit under
`0070` left one class untouched: a bound whose value is the surface's own
current measurement. Four of them were live.

| Surface | Dimension | Bound | Actual | Reviewed health target |
| --- | --- | --- | --- | --- |
| `focused_documents` | `files` ceiling | 1007 | 1007 | 1280 |
| `root_documents` | `files` ceiling | 18 | 18 | 24 |
| `ancillary_documents` | `files` ceiling and target | 16 | 16 | 16 |

A bound equal to the actual is not a statement about the surface's healthy
size; it is a photograph of the day it was written. All three reject the next
member outright.

A fourth candidate did not survive the probe, and the correction is the more
useful half of this record. `knowledge_cards.line_bytes_each` is 1,024 against
a widest retained card line of exactly 819, with 107 of 1,122 cards clustered
in the top 20 bytes — the signature of a milestone that has become the
authoring cap, since 80% of 1,024 is 819.2. Writing a 900-byte card line and
rerunning the checker refuted that reading: containment passed and
`knowledge-map/scripts/check_knowledge_map.sh` failed instead.
`knowledge-map/scripts/knowledge_map.pl:27` holds the real authority,
`KM_CARD_MAX_LINE_BYTES` defaulting to **819**. Containment was not pinning
that dimension; it was correctly aligned to a cap another doctrine owns, in
exactly the shape `0065`'s first exception and `0066` describe. The value stays
at 1,024, and the cluster is authors writing up to the Knowledge Map's cap
rather than evidence of a containment defect.

Decision `0064` already answered this shape once. It raised the
`knowledge_cards` collection ceilings to that surface's own reviewed health
targets so an ordinary fact card costs no decision record, authority row, or
ceiling edit. The same reasoning applies to any bound sitting on its actual.

## Decision

1. **A bound is derived from the retained surface or it is not a bound.**
   Where a reviewed health target already exists and the ceiling was merely
   pinned lower at the then-actual, raise the ceiling to that reviewed target:
   `focused_documents.files` `1007 -> 1280` and `root_documents.files`
   `18 -> 24`.
2. **Where the target is itself pinned at the actual, review the target first.**
   `ancillary_documents.files` is `16` against sixteen members, so the target
   said "full" without ever having said "how big". Its ten glob patterns include
   two per-artifact accumulators — `docs/audits/*.md` and
   `vial/review_gallery/*/*/*.md` — so the reviewed steady state is `32`, at the
   upper end of the 1.27x-1.83x factor the other collections carry because those
   two patterns grow with the work rather than with the documentation.
3. **A bound that merely looks pinned must be probed before it is moved.**
   `knowledge_cards.line_bytes_each` stays at `1,024`, because its 80% warning
   at 819.2 is an alignment to `KM_CARD_MAX_LINE_BYTES` = 819 and not a
   coincidence. Arithmetic alone could not tell the two apart; executing the
   write did. Where a dimension is externally owned, containment keeps its
   warning on that owner's cap, never above and never below it.
4. **Reopening a bound never clears a debt.** `focused_documents` stays in
   `warning_debt` at 80.8% of its line target, and `ancillary_documents` stays
   in `rollover_debt` because `lines_total` is at 90.8% — which is also why
   raising its `files` bound does not reopen it. Under `0070` rule 4 a
   rollover-debt surface is not widened by an allowance, so that surface remains
   closed to new members until its declared rollover lands. That is the doctrine
   working, not a defect, and the rollover stays owned by
   `LIVE-DOCUMENT-SIZE-CONTAINMENT-ADOPTION`.
5. No milestone percentage, ratchet step, verifier, authority requirement,
   decision pairing, or debt baseline changes. Each of the four increases
   carries its own appended `ceiling_increase_authority` row.

## Consequences

- One new `docs/*.md` file is an ordinary write again, and so is one new root
  document. The probe that failed three containment invariants under `0070` now
  leaves only the ordinary generated-index regeneration a new focused document
  has always required.
- `focused_documents.files` moves to 78.7% of a reviewed target, so the next
  documents are budgeted rather than rationed; its transition allowance still
  costs a one-number declared measurement per step while the surface is honestly
  in debt.
- `ancillary_documents` is measurably reopened and operationally unchanged. That
  is stated rather than hidden: its unblock condition is the `lines_total`
  rollover, not this record.
- Members bunched just under a milestone are a signal to investigate, not a
  verdict. The `knowledge_cards` cluster at 817-819 bytes looked exactly like a
  milestone that had become an authoring cap and was in fact a correctly aligned
  bound over an externally owned one. The distinguishing test is cheap: perform
  the write and read which checker rejects it.
- `KM_CARD_MAX_LINE_BYTES` is a real bound on an ordinary write that no live
  document states. It is recorded in fact card
  `live-document-transition-allowance-headroom` so the next author meets it
  before the checker does.

## Containment

One bounded rationale record under the existing decision collection limits. The
pinned-bound test joins the calibration and allowance procedures already in the
local adoption note of `LIVE_DOCUMENT_SIZE_CONTAINMENT.md`.
