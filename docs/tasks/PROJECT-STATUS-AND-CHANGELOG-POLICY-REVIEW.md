# PROJECT-STATUS-AND-CHANGELOG-POLICY-REVIEW: Review Legacy Project-Document Roles

## Metadata

- Tree ID: `PROJECT-STATUS-AND-CHANGELOG-POLICY-REVIEW`
- Status: `active`
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
  Status: `active`
  Goal: `Select evidence-backed long-term roles for the four legacy project documents without presupposing one shared policy.`
  Children: `PROJECT-STATUS-AND-CHANGELOG-POLICY-REVIEW.1, PROJECT-STATUS-AND-CHANGELOG-POLICY-REVIEW.2`

- ID: `PROJECT-STATUS-AND-CHANGELOG-POLICY-REVIEW.1`
  Status: `active`
  Goal: `Audit the four documents and recommend a bounded lifecycle policy for each.`
  Acceptance: `Complete the content/history/consumer/overlap audit, compare retain/redefine/derive/merge/archive/retire options per file, and present a recommendation plus implementation decomposition without changing current policy or any reviewed file.`
  Verification: `pending audit`
  Commit: `pending`

- ID: `PROJECT-STATUS-AND-CHANGELOG-POLICY-REVIEW.2`
  Status: `done`
  Goal: `Synchronize the director-confirmed interim lifecycle policy before the next ordinary slice.`
  Acceptance: `Checked-in policy requires one concise CHANGES.md entry for every completed slice, requires DEVELOPMENT_NOTES.md only for durable engineering rationale/constraints/working decisions, keeps ROADMAP_STATUS.md and LIVE_ACHIEVEMENT_STATUS.md untouched pending .1, supersedes only the conflicting parts of decision 0007, aligns bootstrap/commit/toolbox/task-tree/mdBook/Memory/Knowledge Map surfaces, and changes no product behavior.`
  Verification: `Decision 0025, COMMIT.md, AGENTS.md, README.md, TOOLBOX.md, docs/TASK_TREE.md, mdBook reference map, Memory, and a new fact card all encode the split interim policy. Knowledge Map generation/check passes at 1066 facts / 5487 question keys; README guard passes at 245 lines / 9871 bytes; docs relative-path audit, memory architecture, full six-doctrine driver, mdBook build, and diff hygiene pass. ROADMAP_STATUS.md, LIVE_ACHIEVEMENT_STATUS.md, and DEVELOPMENT_NOTES.md are byte-untouched; generated docs/book/book was removed. No product behavior changed.`
  Commit: `PROJECT-STATUS-AND-CHANGELOG-POLICY-REVIEW.2: adopt split interim document policy`

## Current Frontier

The bounded interim-policy synchronization is complete. The director resumed
the containment program on `2026-08-01`; from clean commit `8fdd5a22cc`, the
full four-document lifecycle audit `.1` is now active as the required
prerequisite for the retained-ledger schema and `CHANGES.md` migration.

| Order | Leaf | Status | Why next |
| --- | --- | --- | --- |
| 1 | `PROJECT-STATUS-AND-CHANGELOG-POLICY-REVIEW.2` | `done` | Decision 0025 and all active workflow surfaces now carry the director-confirmed interim split. |
| 2 | `PROJECT-STATUS-AND-CHANGELOG-POLICY-REVIEW.1` | `active` | Audit the four long-term roles and select the lifecycle contract required before containment schema `.3`. |

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

- None. Leaf `.2` is complete and leaf `.1` is active for the evidence audit.

## Verification Log

| Date | Leaf | Checks | Result |
| --- | --- | --- | --- |
| `2026-07-30` | `.2` | policy-reference search; `knowledge-map/scripts/gen_knowledge_map.sh`; `knowledge-map/scripts/check_knowledge_map.sh`; `scripts/check_readme_entrypoint.sh`; `scripts/check_docs_relative_paths.sh`; `scripts/check_memory_architecture.sh`; `scripts/check_doctrines.sh`; `mdbook build docs/book`; frozen/conditional-file diff checks; `git diff --check` | `passed`; 1066 facts / 5487 keys; README 245 lines / 9871 bytes; no product change; generated book removed |
| `2026-08-01` | `.1` activation | clean predecessor; task/index/containment/Memory/changelog continuity; task-tree, memory, live-size, diff, mdBook, Knowledge Map, and staged doctrine gates | `passed`; four active trees / 901 nodes / one segment / one index archive / one migration; Memory 42 lines; CHANGES held exactly at 32,299 lines through line-neutral formatting; no reviewed document, policy, archive, generated artifact, or product behavior change |

## Commit Log

| Leaf | Commit subject or reference | Notes |
| --- | --- | --- |
| `.2` | `PROJECT-STATUS-AND-CHANGELOG-POLICY-REVIEW.2: adopt split interim document policy` | Supersedes the blanket freeze prospectively for the changelog and conditional development rationale while leaving both status files untouched. |
| `.1` activation | `PROJECT-STATUS-AND-CHANGELOG-POLICY-REVIEW.1: activate four-document lifecycle audit` | Activates the evidence audit only; the interim split and all four reviewed files remain unchanged. |
