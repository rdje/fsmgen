---
id: live-document-transition-allowance-headroom
title: A transition allowance is re-declared to the measured actual plus one ratchet step, and its owner must be live
answers:
  - "why does adding one file under docs/ fail the live-document checker?"
  - "surface focused_documents transition debt exceeded its owned allowance"
  - "how much headroom does a live-document debt surface actually have?"
  - "how do I raise transition.max_growth without a ceiling increase?"
  - "why did raising the allowance to the actual not unblock the next write?"
  - "who owns a live-document transition allowance?"
  - "can I widen the allowance on a rollover_debt surface?"
  - "how long can a fact card line be?"
  - "card line width exceeds 819"
  - "why does a long reverify line fail even though knowledge_cards is normal?"
date: 2026-10-27
status: current
evidence: docs/decisions/0070-transition-allowances-carry-one-declared-step-and-a-live-owner.md; doctrine/live_document_size/surfaces.jsonl; LIVE_DOCUMENT_SIZE_CONTAINMENT.md; docs/audits/task-evidence-growth-band-20261027/measure.py; docs/audits/task-evidence-growth-band-20261027/measurement.json; docs/tasks/LIVE-DOCUMENT-SIZE-CONTAINMENT-ADOPTION.md
reverify: >-
  python3 -B docs/audits/knowledge-card-rollover-kinds-20261005/verify.py --current && python3 -B docs/audits/task-evidence-growth-band-20261027/measure.py --current
tags: [live-document-size, containment, doctrine, transition-debt, task-trees]
---

A surface in `warning_debt`, `rollover_debt`, or `structural_debt` is bounded by
`actual <= baseline + transition.max_growth` for every dimension whose baseline
is positive. That allowance is separate from the enforcement ceiling and from
the warning milestone, so a surface can be well under its target and still
reject an ordinary write.

Decision `0070` sets the procedure:

- **Re-declare to the measured actual plus one `transition.ratchet_step`**, not
  to the actual. Raising only to the actual leaves zero headroom, so the next
  write fails the same gate.
- **Clamp at the enforcement ceiling.** If `measured actual + step` would exceed the
  ceiling, the allowance stops there and the ceiling is the finding. An
  allowance may never reach past a quarantine boundary.
- **Never widen a `rollover_debt` surface.** At rollover the remedy is the
  declared rollover. Decision `0070`'s ancillary occupancy is a dated
  adoption observation; derive current pressure from the registry and checker.
- **The `transition.owner` must be a live node** — an active tree, or a leaf
  that is not yet `done`. Two allowances named completed leaves in a tree that
  is not in the active index; a completed leaf satisfies the string and not the
  requirement.
- **A zero allowance can be deliberate.** `readme_entrypoint` is pinned at its
  baseline by the README policy.

Raising the allowance this way is a declared measurement, so
`scripts/check_live_document_ceiling_authority.pl` still reports zero increases
and no decision record or authority row is required. Raising the *ceiling* is
the reviewed act that does need both — see
[[live-document-surface-growth-procedure]] and
[[live-document-target-pair-calibration]].

Task-evidence growth-band derivation, protected controls and rollover ownership
are retained in containment task `.31` / `.32` and the measured evidence above.

A related bound lives outside containment: the default fact-card content-line
width is 819 bytes. Containment's line-width target and the card checker's bound
are distinct authorities; a compliant line does not establish whole-surface
health. The predecessor's line-width census is historical, not a current count.
A long `reverify:` line fails the card checker, and increasing a containment
target cannot admit it. Query [[knowledge-card-sizing-and-partition]] and derive
current collection pressure with the public checkers.

Retrieve the complete dated predecessor from the repository root:

```sh
python3 -B docs/audits/knowledge-card-rollover-selection-20261005/read_source.py live-document-transition-allowance-headroom
```
