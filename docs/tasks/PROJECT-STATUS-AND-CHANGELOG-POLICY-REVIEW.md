# PROJECT-STATUS-AND-CHANGELOG-POLICY-REVIEW: Review Legacy Project-Document Roles

## Metadata

- Tree ID: `PROJECT-STATUS-AND-CHANGELOG-POLICY-REVIEW`
- Status: `done`
- Roadmap lane: `infra/continuity / project-document lifecycle`
- Created: `2026-07-30`
- Last updated: `2026-08-01`
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

The director clarified the interim policy later on `2026-07-30`:

- update `CHANGES.md` for every completed slice;
- update `DEVELOPMENT_NOTES.md` only when a slice produces engineering
  rationale, constraints, or working decisions worth preserving;
- do not update `ROADMAP_STATUS.md` or `LIVE_ACHIEVEMENT_STATUS.md` before the
  scheduled lifecycle review.

Leaf `.2` owns the exact doctrine and continuity synchronization needed to
make that clarified boundary durable. The broader evidence-based review in
`.1` remains proposed and does not lose any of its per-file questions.

## Non-Goals

- Do not edit `ROADMAP_STATUS.md` or `LIVE_ACHIEVEMENT_STATUS.md` before their
  scheduled review selects an outcome.
- Do not append development rationale to `DEVELOPMENT_NOTES.md` when the
  task-tree, a decision record, a fact card, the mdBook, or git already owns
  the durable information more precisely.
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
  Status: `done`
  Goal: `Select evidence-backed long-term roles for the four legacy project documents without presupposing one shared policy.`
  Children: `PROJECT-STATUS-AND-CHANGELOG-POLICY-REVIEW.1, PROJECT-STATUS-AND-CHANGELOG-POLICY-REVIEW.2`

- ID: `PROJECT-STATUS-AND-CHANGELOG-POLICY-REVIEW.1`
  Status: `done`
  Goal: `Audit the four documents and recommend a bounded lifecycle policy for each.`
  Acceptance: `Complete the content/history/consumer/overlap audit, compare retain/redefine/derive/merge/archive/retire options per file, and present a recommendation plus implementation decomposition without changing current policy or any reviewed file.`
  Verification: `docs/PROJECT_DOCUMENT_LIFECYCLE_POLICY_AUDIT.md records current/initial/history measurements, audiences, canonical overlap, current and executable consumers, per-file alternatives, tradeoffs, selected outcomes, and exact implementation owners. Decision 0046 retains bounded whole-entry CHANGES and conditional DEVELOPMENT_NOTES ledgers, supersedes both status files with canonical live views plus distinct exact archives, and keeps decision 0025 operational through migration. The audit changes no reviewed document topology or product behavior; CHANGES receives only this workflow-required line-neutral completion entry, while DEVELOPMENT_NOTES and both frozen status files remain byte-identical. Final task, Knowledge Map, mdBook, path, live-size, Memory, diff, and staged doctrine evidence is recorded below.`
  Commit: `PROJECT-STATUS-AND-CHANGELOG-POLICY-REVIEW.1: select bounded project-document lifecycles`

- ID: `PROJECT-STATUS-AND-CHANGELOG-POLICY-REVIEW.2`
  Status: `done`
  Goal: `Synchronize the director-confirmed interim lifecycle policy before the next ordinary slice.`
  Acceptance: `Checked-in policy requires one concise CHANGES.md entry for every completed slice, requires DEVELOPMENT_NOTES.md only for durable engineering rationale/constraints/working decisions, keeps ROADMAP_STATUS.md and LIVE_ACHIEVEMENT_STATUS.md untouched pending .1, supersedes only the conflicting parts of decision 0007, aligns bootstrap/commit/toolbox/task-tree/mdBook/Memory/Knowledge Map surfaces, and changes no product behavior.`
  Verification: `Decision 0025, COMMIT.md, AGENTS.md, README.md, TOOLBOX.md, docs/TASK_TREE.md, mdBook reference map, Memory, and a new fact card all encode the split interim policy. Knowledge Map generation/check passes at 1066 facts / 5487 question keys; README guard passes at 245 lines / 9871 bytes; docs relative-path audit, memory architecture, full six-doctrine driver, mdBook build, and diff hygiene pass. ROADMAP_STATUS.md, LIVE_ACHIEVEMENT_STATUS.md, and DEVELOPMENT_NOTES.md are byte-untouched; generated docs/book/book was removed. No product behavior changed.`
  Commit: `PROJECT-STATUS-AND-CHANGELOG-POLICY-REVIEW.2: adopt split interim document policy`

## Current Frontier

The policy review is complete. Decision `0046` selects bounded change and
conditional-rationale ledgers plus exact archival and live-path retirement for
the two frozen status narratives. Implementation remains in the containment
tree; `.3` is its next clean selection.

| Order | Leaf | Status | Why next |
| --- | --- | --- | --- |
| 1 | `PROJECT-STATUS-AND-CHANGELOG-POLICY-REVIEW.2` | `done` | Decision 0025 and all active workflow surfaces now carry the director-confirmed interim split. |
| 2 | `PROJECT-STATUS-AND-CHANGELOG-POLICY-REVIEW.1` | `done` | Audit and decision `0046` select all four long-term roles without performing a migration. |

## Decisions

- `2026-07-30`: Capture one deferred review covering all four files, while
  requiring a distinct evidence-backed outcome for each.
- `2026-07-30`: Do not select a new `CHANGES.md` policy now.
- `2026-07-30`: Treat the usefulness of `ROADMAP_STATUS.md` and
  `LIVE_ACHIEVEMENT_STATUS.md` as open questions, not as settled conclusions.
- `2026-07-30`: Keep the checked-in decision-0007 behavior unchanged until the
  review is activated and a replacement decision is approved; this is a
  continuity boundary, not a judgment that the current policy should persist.
- `2026-07-30`: Director clarification supersedes that temporary boundary:
  `CHANGES.md` is per-slice, `DEVELOPMENT_NOTES.md` is rationale-only, and
  `ROADMAP_STATUS.md` plus `LIVE_ACHIEVEMENT_STATUS.md` remain untouched until
  the scheduled discussion. Activate `.2` to synchronize the checked-in
  policy before continuing ordinary work; retain `.1` for the later review.
- `2026-08-01`: From clean commit `8fdd5a22cc`, activate `.1` alone after the
  director resumed containment. This transition changes no reviewed document,
  lifecycle policy, doctrine, archive, generated artifact, or product behavior.
- `2026-08-01`: Select two retained bounded ledgers and two superseded live
  status paths under decision `0046`. Keep decision `0025` operational until
  containment `.3`, `.4`, `.5`, and `.11` implement the selection; do not
  migrate a reviewed file in this audit.

## Open Questions

- None for lifecycle selection. Schema and per-file migration proof belong to
  containment `.3`, `.4`, `.5`, and `.11`.

## Blockers

- None. This tree is complete; containment `.3` is the next clean selection.

## Acceptance Checklist (enforced) — `.1` lifecycle audit and selection

- [x] **ROOT CAUSE (WHY + WHERE)** — `git log -S` over the maintained-reference
  aggregate authority identifies its prior introduction at `984448936`;
  decision 0045's one-use contract therefore requires this slice to declare
  the exact pre-edit mdBook aggregate and current delta when it synchronizes
  the reference map with the new lifecycle selection.
- [x] **ADDRESSED (verified)** — the worktree authority checker reports
  `live-doc-reference-authority: all maintained-reference aggregate invariants
  hold (1 reference(s), 1 changed, mode worktree)` against exact baseline
  38 files / 47,418 lines / 2,514,423 bytes plus 0 / +3 / +250.
- [x] **NO REGRESSION** — the complete nine-check worktree driver ends with
  `[doctrine] all doctrine checks passed`; final staged-index execution is
  recorded in the verification row below.

## Verification Log

| Date | Leaf | Checks | Result |
| --- | --- | --- | --- |
| `2026-07-30` | `.2` | policy-reference search; `knowledge-map/scripts/gen_knowledge_map.sh`; `knowledge-map/scripts/check_knowledge_map.sh`; `scripts/check_readme_entrypoint.sh`; `scripts/check_docs_relative_paths.sh`; `scripts/check_memory_architecture.sh`; `scripts/check_doctrines.sh`; `mdbook build docs/book`; frozen/conditional-file diff checks; `git diff --check` | `passed`; 1066 facts / 5487 keys; README 245 lines / 9871 bytes; no product change; generated book removed |
| `2026-08-01` | `.1` activation | clean predecessor; task/index/containment/Memory/changelog continuity; task-tree, memory, live-size, diff, mdBook, Knowledge Map, and staged doctrine gates | `passed`; four active trees / 901 nodes / one segment / one index archive / one migration; Memory 42 lines; CHANGES held exactly at 32,299 lines through line-neutral formatting; no reviewed document, policy, archive, generated artifact, or product behavior change |
| `2026-08-01` | `.1` audit and selection | focused history/size/consumer/overlap audit; decision 0046; Knowledge Map; task/index/Memory/book/changelog synchronization; frozen/conditional identity checks; task-tree, path, live-size, Memory, mdBook, diff, and staged doctrine gates | `passed`; 1,096 facts / 5,760 keys; three trees / 898 nodes; 2,784 staged document paths; README 245 lines / 9,944 bytes; mdBook all 37 chapters and 73 files / 17,284,110 rendered bytes; maintained reference exact 38 / 47,421 / 2,514,673; CHANGES held at 32,299 lines; conditional/frozen files identity-clean; fresh acceptance and all nine doctrines pass; generated build/tools scratch removed; no migration or product behavior change |

## Commit Log

| Leaf | Commit subject or reference | Notes |
| --- | --- | --- |
| `.2` | `PROJECT-STATUS-AND-CHANGELOG-POLICY-REVIEW.2: adopt split interim document policy` | Supersedes the blanket freeze prospectively for the changelog and conditional development rationale while leaving both status files untouched. |
| `.1` activation | `PROJECT-STATUS-AND-CHANGELOG-POLICY-REVIEW.1: activate four-document lifecycle audit` | Activates the evidence audit only; the interim split and all four reviewed files remain unchanged. |
| `.1` | `PROJECT-STATUS-AND-CHANGELOG-POLICY-REVIEW.1: select bounded project-document lifecycles` | Decision 0046 closes the review; containment `.3` becomes the next clean selection. |
