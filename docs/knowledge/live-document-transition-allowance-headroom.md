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
date: 2026-08-19
status: current
evidence: docs/decisions/0070-transition-allowances-carry-one-declared-step-and-a-live-owner.md; docs/decisions/0064-live-document-growth-is-declared-measurement-with-paired-decisions.md; doctrine/live_document_size/surfaces.jsonl; LIVE_DOCUMENT_SIZE_CONTAINMENT.md; docs/tasks/LIVE-DOCUMENT-LINE-TARGET-CALIBRATION.md
reverify: scripts/check_live_document_size.sh 2>&1 | grep -E 'surface (focused_documents|ancillary_documents|readme_entrypoint|shipped_behavior):'
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
- **Clamp at the enforcement ceiling.** If `baseline + step` would exceed the
  ceiling, the allowance stops there and the ceiling is the finding. An
  allowance may never reach past a quarantine boundary.
- **Never widen a `rollover_debt` surface.** At rollover the remedy is the
  declared rollover. `ancillary_documents` sits at 100% of its `files` target
  and is left alone for that reason.
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
