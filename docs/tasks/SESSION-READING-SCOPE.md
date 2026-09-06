# SESSION-READING-SCOPE: Preserve task-directed startup reading

## Metadata

- Tree ID: `SESSION-READING-SCOPE`
- Status: `done`
- Roadmap lane: `infra/continuity`
- Created: `2026-09-06`
- Last updated: `2026-09-06`
- Owner: repo-local workflow

## Goal

Durably record the director's selection of the repository's task-directed
bootstrap so future sessions do not reopen the same reading-scope question.

## Non-Goals

- Change product behavior, verification policy, or the active repair frontier.

## Acceptance Criteria

- The decision is tracked and discoverable through the canonical bootstrap.
- Startup guidance states the selected scope and when deeper reading is needed.
- Doctrine and diff checks pass, and the documentation slice is committed.

## Task Tree

- ID: `SESSION-READING-SCOPE`
  Status: `done`
  Goal: `Preserve the director-selected task-directed startup reading scope.`
  Children: `SESSION-READING-SCOPE.1`

- ID: `SESSION-READING-SCOPE.1`
  Status: `done`
  Goal: `Record and route the standing startup reading decision.`
  Acceptance: `The canonical bootstrap and its linked task decision preserve task-directed reading without claiming an exhaustive codebase or book review; all required documentation checks pass and the slice is committed.`
  Verification: `The guarded staged doctrine driver exits zero and reports all doctrine checks passed; the bootstrap-to-task link and explicit scope were reviewed in the staged diff. Task integrity passed while this tree was active, the direct and independent claim censuses agree, generated inventory changes only census metadata, and git diff --cached --check passes. Evidence is in .artifacts/logs/session-reading-scope/staged-doctrines.log. Product behavior and mdBook contracts are unchanged; MEMORY.md retains the existing nested-supervision frontier.`
  Commit: `SESSION-READING-SCOPE.1: preserve task-directed bootstrap decision`

## Decisions

- The director explicitly selected the repository's task-directed bootstrap
  and requested durable memory of that selection on 2026-09-06.
- Exact instruction: "For the reading-scope go with the repository’s
  task-directed bootstrap", followed by "please durabily memorize this
  decision". This resolves the earlier exhaustive-reading ambiguity.
- `SESSION_BOOTSTRAP.md` is the canonical operating rule. Read mandatory
  entrypoints, the roadmap, resume pointer, task index and active owner,
  relevant decisions/facts, mdBook contents and relevant chapters. Analyze the
  CLI import architecture and deepen source/test reading along dependencies.
  Do not claim an exhaustive review or reopen the settled scope absent a
  later explicit director change.
- Keep the active HIAL/VIAL repair in `MEMORY.md`; this standing preference
  belongs in the bootstrap and this task, not in the bounded resume pointer.
- Initial doctrine validation rejected additional decision/fact copies at
  their existing transition allowances. Retain the decision here and directly
  in its canonical operating document, with a bootstrap-to-task link; discard
  only the uncommitted duplicate representations after preserving their full
  decision content. No containment limit is changed.

## Open Questions

- None.

## Blockers

- None; the repository was clean before selecting this documentation slice.

## Acceptance Checklist (enforced for generated inventory metadata)

- [x] **ROOT CAUSE (WHY + WHERE)** — `git log -S 'book chapters' -- SESSION_BOOTSTRAP.md`
  locates the existing startup procedure; its relevant-chapter instruction
  left the generic prompt's exhaustive-reading scope ambiguous. The director
  resolved that ambiguity explicitly. The claim inventory check also rejected
  stale census identity after the bootstrap line positions changed.
- [x] **ADDRESSED (verified)** — `SESSION_BOOTSTRAP.md` now states the selected
  scope and links to the exact director instruction retained here. Running
  `scripts/check_claim_verification_inventory.pl --write` refreshes only its
  census metadata; candidate and constant records remain byte-identical.
- [x] **NO REGRESSION** — `knowledge-map: OK` and the task-tree integrity
  checker passed during the first doctrine run. The claim inventory's direct
  and independent Git censuses agree after regeneration. The guarded staged
  driver exits zero with `[doctrine] all doctrine checks passed`.
