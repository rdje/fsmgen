# Legacy Continuity Document Value Audit

- Date: `2026-08-01`
- Owner: `LIVE-DOCUMENT-SIZE-CONTAINMENT-ADOPTION.4`
- Evidence revision: `329d7cf1b09319899fb59cc9863cdfffddfa40dc`
- Selected lifecycle in this slice: delete `CHANGES.md`

## Question

Does `CHANGES.md` still answer a current question that is not already answered
more accurately by the enforced Memory/task/decision/fact/mdBook/Git
architecture? The director selected deletion if the answer is no.

Size is not the criterion. Provenance, unique accurate content, live
consumers, canonical overlap, and exact recovery determine the outcome.

## Provenance-derived candidate inventory

The repository history and current bootstrap contracts identify five agent-
era continuity records. Other root Markdown files are current specifications,
workflows, policies, generated indexes, or user/project direction rather than
session-state narration.

| Document | Provenance and original/current question | Current canonical overlap | Outcome/owner |
| --- | --- | --- | --- |
| `MEMORY.md` | Introduced by `a2725c916` as the live continuity document; now asks what a new session must resume | Unique bounded layer-A pointer over task/decision/Git state | retain under memory architecture |
| `CHANGES.md` | Introduced with implementation narration in `574a5af00`; later required as one summary per completed slice | Owning task node, work-unit Git subject/diff, and mdBook already answer change/evidence/user-behavior questions | delete under `.4`, selected by director |
| `DEVELOPMENT_NOTES.md` | Introduced with implementation rationale in `574a5af00`; now conditionally asks why a local engineering choice was made | Decisions/facts/tasks/book cover most content, but non-obvious local rationale may remain distinct | separately reassess/re-form under `.5`; no lifecycle change here |
| `ROADMAP_STATUS.md` | Introduced by `5b161e0c5` as a live status board | `ROADMAP_V2.md`, `docs/TASK_TREE.md`, and `MEMORY.md` are fresher authorities | supersede/archive remains selected under `.11` |
| `LIVE_ACHIEVEMENT_STATUS.md` | Introduced by `d4c8d1a92` for fast recovery from the latest completed slice | Task closure and Git provide exact completion; Memory provides recovery | frozen pending an independent `.11` audit and director selection |

`COMMIT.md`, `AGENTS.md`, `MEMORY_ARCHITECTURE.md`, and
`SESSION_BOOTSTRAP.md` are bounded executable workflow contracts, not mutable
continuity records. `ROADMAP_V2.md` carries direction, not resume state.
Pending `.26` retains authority to widen or revise this inventory with
additional provenance evidence; this slice changes only `CHANGES.md`.

## Exact CHANGES identity

| Evidence | Value |
| --- | --- |
| source revision | `329d7cf1b09319899fb59cc9863cdfffddfa40dc` |
| Git blob | `c11e9a0e825142579ab98f76c0a9a43010c07bba` |
| SHA-256 | `6a1b0819fd44036130324d0a178c9e147e4e41fc91b8faca20ef5a170d6b2f98` |
| lines / bytes / longest line | `32,299` / `2,696,664` / `3,282` |
| date headings / entry headings | `172` / `2,987` |

The initial object at `574a5af00` was 22 lines / 2,141 bytes. The current
object is historical narration accumulated across thousands of task-scoped
commits; it is not an input to product behavior or session recovery.

## Current-value and consumer proof

`git grep -l -F 'CHANGES.md' -- ':!CHANGES.md'` reports 64 tracked referring
files. Classification is:

- executable/content consumers: zero;
- executable policy fixture: one (`t/1553-readme-routed-destination-pressure.t`);
- current author/navigation policy: README, AGENTS, COMMIT, TOOLBOX, the task
  workflow, mdBook reference map, one Knowledge Card, and the route/surface
  registries;
- historical evidence: prior decisions, tasks, audits, facts, frozen records,
  and rationale narration.

The executable fixture validates only the circular policy that the file must
exist. Removing that policy and its route leaves no product, compiler, test,
build, runtime, or reader that requires the content. Current replacement
pointers are:

| Surviving question | Canonical destination |
| --- | --- |
| What changed and what proves it? | owning `docs/tasks/*.md` node plus `git log --grep=<UNIT-ID>` |
| What is active/next after a crash? | `MEMORY.md`, then `docs/TASK_TREE.md` |
| Why was a cross-cutting choice made? | `docs/decisions/INDEX.md` |
| Is a durable fact established? | `KNOWLEDGE_MAP.md` and its fact card |
| What does shipped behavior do? | `docs/book/src/SUMMARY.md` |

## Whole-document residue and negative controls

The deterministic sweep extracts headings, code spans, stable work-unit IDs,
paths, and normalized words of at least five characters. The exact source
contains 18,993 unique tokens. Every historical token remains byte-for-byte in
the retained Git object; current IDs/paths route to task evidence and Git, and
current behavior/rationale routes to the table above. There is no unexplained
live-content residue requiring a second copy.

Adding `fsmgen_orphan_probe_retired_changes_history` to an in-memory fixture
copy changes the token count from 18,993 to 18,994 and reports that exact token.
The focused retirement test also plants `AGENTS.md -> CHANGES.md` in a
repository-local fixture and requires the verifier to reject the unresolved
consumer. Recreating the retired live path, changing the expected digest, or
removing the source revision independently fails.

## Retention and resulting tree

The exact object is retained under `fsmgen_required_history`. The archive
descriptor invokes `scripts/check_retired_changes_history.pl`, which proves
the live path is absent, retrieves the source revision, matches line/byte/
longest-line/SHA-256 identity, and rejects active policy/executable consumers.
The full staged resulting-tree, link/book, Knowledge Map, acceptance, locality,
and doctrine gates remain mandatory before `.4` closes.
