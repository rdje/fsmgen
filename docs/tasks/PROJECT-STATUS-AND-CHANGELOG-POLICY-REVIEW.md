# PROJECT-STATUS-AND-CHANGELOG-POLICY-REVIEW: Review Legacy Project-Document Roles

## Metadata

- Tree ID: `PROJECT-STATUS-AND-CHANGELOG-POLICY-REVIEW`
- Status: `proposed`
- Roadmap lane: `infra/continuity / project-document lifecycle`
- Created: `2026-07-30`
- Last updated: `2026-07-30`
- Owner: repo-local workflow

## Goal

Determine the useful long-term roles and lifecycle policies for `CHANGES.md`,
`DEVELOPMENT_NOTES.md`, `ROADMAP_STATUS.md`, and
`LIVE_ACHIEVEMENT_STATUS.md` from evidence rather than assuming that the four
files should remain frozen, become live again, or share one outcome.

## Origin And Current Boundary

The director requested this deferred review on `2026-07-30`. In particular:

- `CHANGES.md` may need a new changelog policy, but that policy is not to be
  selected now.
- `DEVELOPMENT_NOTES.md` should be considered in terms of when development
  notes are actually warranted, rather than an automatic per-slice write.
- the continuing usefulness of `ROADMAP_STATUS.md` and
  `LIVE_ACHIEVEMENT_STATUS.md` is an open question that requires review.

Decision `0007` and the current doctrine files remain the checked-in policy
until this tree is deliberately activated and a replacement decision is
approved. Recording the review does not endorse that policy permanently and
does not predetermine the review's result.

## Non-Goals

- Do not edit any of the four reviewed files in this proposed-tree capture.
- Do not change decision `0007`, `COMMIT.md`, `README.md`, `TOOLBOX.md`,
  doctrine checks, hooks, CI, or current write routing before the review has
  evidence and an approved outcome.
- Do not assume that all four files need the same lifecycle policy.
- Do not duplicate task-tree state, bounded `MEMORY.md` state, decision
  rationale, Knowledge Map facts, mdBook product contract, or git history
  merely to make a legacy file active.
- Do not turn this deferred review into an interruption of the current roadmap
  frontier.

## Acceptance Criteria

- Audit each file's present contents, size and growth history, last meaningful
  use, incoming references, automated consumers, doctrine checks, and overlap
  with task-trees, `MEMORY.md`, decisions, Knowledge Map facts, the mdBook, and
  git history.
- Identify the actual audience and decisions served by each file. Distinguish
  human release/change communication, engineering rationale, roadmap progress,
  and achievement reporting instead of treating them as one generic status
  stream.
- For `CHANGES.md`, compare bounded changelog policies by source of truth,
  release or work-unit granularity, update trigger, derivation/automation,
  review burden, and drift risk. Do not assume that "before every commit" or
  "never update" is the right policy without this comparison.
- For `DEVELOPMENT_NOTES.md`, define what information—if any—belongs there and
  when it is needed, with a clear boundary against decisions, fact cards,
  task-tree evidence, user documentation, and commit history.
- For `ROADMAP_STATUS.md` and `LIVE_ACHIEVEMENT_STATUS.md`, evaluate whether
  each still answers a distinct useful question. Compare retaining a bounded
  live document, deriving a view from canonical data, merging roles, retaining
  a frozen archive, or retiring the file.
- For every viable option, document authority, update cadence, size/growth
  controls, recovery value, automation feasibility, migration cost, and the
  consequence of stale or missing updates.
- Present an evidence-backed recommendation per file, including alternatives
  and tradeoffs, for director review. Record the selected cross-cutting policy
  in a decision record before changing active doctrine.
- After selection, split implementation into exact task-tree leaves that keep
  workflow docs, doctrine gates, the mdBook, `MEMORY.md`, Knowledge Map facts,
  and git history aligned where warranted.

## Task Tree

- ID: `PROJECT-STATUS-AND-CHANGELOG-POLICY-REVIEW`
  Status: `proposed`
  Goal: `Select evidence-backed long-term roles for the four legacy project documents without presupposing one shared policy.`
  Children: `PROJECT-STATUS-AND-CHANGELOG-POLICY-REVIEW.1`

- ID: `PROJECT-STATUS-AND-CHANGELOG-POLICY-REVIEW.1`
  Status: `proposed`
  Goal: `Audit the four documents and recommend a bounded lifecycle policy for each.`
  Acceptance: `Complete the content/history/consumer/overlap audit, compare retain/redefine/derive/merge/archive/retire options per file, and present a recommendation plus implementation decomposition without changing current policy or any reviewed file.`
  Verification: `pending activation`
  Commit: `pending activation`

## Current Frontier

This tree is proposed and intentionally deferred. It is not PNT-eligible until
the director or a clean-boundary roadmap selector activates it.

| Order | Leaf | Status | Why next |
| --- | --- | --- | --- |
| 1 | `PROJECT-STATUS-AND-CHANGELOG-POLICY-REVIEW.1` | `proposed` | Establish evidence and distinct file roles before selecting or implementing any policy change. |

## Decisions

- `2026-07-30`: Capture one deferred review covering all four files, while
  requiring a distinct evidence-backed outcome for each.
- `2026-07-30`: Do not select a new `CHANGES.md` policy now.
- `2026-07-30`: Treat the usefulness of `ROADMAP_STATUS.md` and
  `LIVE_ACHIEVEMENT_STATUS.md` as open questions, not as settled conclusions.
- `2026-07-30`: Keep the checked-in decision-0007 behavior unchanged until the
  review is activated and a replacement decision is approved; this is a
  continuity boundary, not a judgment that the current policy should persist.

## Open Questions

- Which audiences still need a curated changelog that git history and release
  notes do not already provide?
- Which development observations deserve a narrative home rather than a
  decision record, fact card, task-tree entry, mdBook change, or commit?
- Do roadmap status and achievement status answer distinct current questions,
  and can either useful view be derived instead of hand-maintained?
- What boundedness and automation rules would prevent any reactivated document
  from becoming an append-only historical blob again?

## Blockers

- None. The tree is deliberately proposed for later review.
