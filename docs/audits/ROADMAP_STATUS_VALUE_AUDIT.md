# `ROADMAP_STATUS.md` Present-Value Audit

- Date: `2026-08-01`
- Owner: `LIVE-DOCUMENT-SIZE-CONTAINMENT-ADOPTION.11`
- Audited revision: `d0c0e18309713b89388a498421c30080cea2f227`
- Lifecycle outcome: pending an independent director selection
- Frozen file changed by this audit: no

## Question

Does `ROADMAP_STATUS.md` still answer a present reader question that the
current roadmap, task-tree, bounded Memory, mdBook, and Git layers do not
answer well enough? This assessment is independent of the retired achievement
journal and changelog; neither retirement determines this file's outcome.

Size alone does not decide the result. This audit measures provenance, current
accuracy, unique presentation, consumers, canonical overlap, and exact
recovery before asking the director to retain, retire, or re-form the file.

## Exact identity and provenance

| Evidence | Value |
| --- | --- |
| introduced by | `5b161e0c5e564d05f6eaeabed42d6e4c6003ef3a` on `2026-03-14` |
| last changed by / recovery revision | `b4d07fee5ffd6621503007958dcac3af8d44b345` on `2026-06-01` |
| current Git blob | `ebab468fe434a76a500c4a1b45b48d156f4ab6a9` |
| SHA-256 | `0f8db932c57d883d97f1f92fec8a576795b5b367157d9846088501c52aeb22d8` |
| lines / bytes / longest line | `15,039` / `1,638,574` / `5,716` |
| commits that touched the path | `2,760` |
| commits after the freeze through the audited revision | `1,786` |

The initial object was 123 lines / 5,757 bytes. The final object is
byte-identical at the last-changing revision and the audited revision. Exact
recovery is:

```sh
git show b4d07fee5ffd6621503007958dcac3af8d44b345:ROADMAP_STATUS.md \
  | shasum -a 256
```

The expected digest is the SHA-256 above. This reconstruction reads the
project's required Git history and writes no off-volume project data.

## What the file actually contains

The opening contract calls the file the canonical live roadmap status board
and says it answers what is done, what remains, and which lane is active. Its
first live fields instead say `none` for the active lane, active task tree, and
current frontier while the repository has active task trees and an active
`.11` frontier.

The file combines three different products:

- lines 1-9,046 are accumulated `Current`, `Previous`, and decision-point
  slice narration;
- lines 9,047-10,025 contain the former update/status rules and a long frozen
  active-lane snapshot;
- lines 10,026-15,039 contain R0-R14 workstream plans, shipped-state summaries,
  and remaining-work snapshots as of `2026-06-01`.

The R8-R14 direction is also represented in the maintained `ROADMAP_V2.md`,
which has continued to evolve. R0-R7 and the combined former status narrative
retain historical context, but a 1,786-commit-old snapshot cannot safely answer
a current roadmap or execution-state question.

## Current consumers

This deterministic census reports 70 tracked referring files:

```sh
rg -l 'ROADMAP_STATUS\.md' --glob '!ROADMAP_STATUS.md' | sort
```

Classification of every result is:

- product, compiler, runtime, or build content consumers: zero;
- current executable consumers: one stale negative assertion in
  `t/1332-isf-atl-doc-status-audit.t`;
- current policy/navigation references: bootstrap and commit contracts, README
  route, `ROADMAP_V2.md`, mdBook navigation, current decisions/audits/fact
  cards, and live-document route/surface registries;
- one inaccurate current-content link:
  `docs/COMPOSITION_LEGACY_MAPPING.md` names the frozen file as an active source
  of truth;
- historical evidence references: prior workflow, task, decision, audit,
  continuity, and sealed-task records.

The `t/1332` assertion only proves that one obsolete ATL label is absent from
the frozen text. The same test's positive ATL state already comes from the
maintained feature backlog and design proposal, so this negative scan is a
migration hazard rather than a present-value content dependency. The README
route still gives readers direct access to the historical combined snapshot;
the frozen-surface verifier checks only its digest.

## Canonical overlap and distinct value

| Reader question | Current authority |
| --- | --- |
| What is the high-level direction? | `ROADMAP_V2.md` |
| What is active and what is next? | `MEMORY.md`, then `docs/TASK_TREE.md` and the owning task node |
| What completed, and with what evidence? | the owning `docs/tasks/*.md` node plus its work-unit Git commit |
| What does shipped behavior do? | `docs/book/src/SUMMARY.md` and the linked feature chapters |
| Why was a roadmap or architecture choice made? | `docs/decisions/INDEX.md` and the selected decision |
| What exactly did the former board say? | `git show` at the exact retained revision |

No unique current direction, live state, completion evidence, or user-facing
behavior authority was found. The distinct retention case is presentation: one
root-level, directly browsable March-June 2026 combined chronology and
R0-R14 status/roadmap snapshot. That historical presentation is substantial,
but it is neither complete through the present nor safe as a current board.

## Options for director selection

1. **Retire the live path (audit recommendation).** Preserve the exact object
   with a checked revision/digest retrieval contract; migrate the stale test,
   composition link, and current policy/navigation/registry consumers; leave
   historical evidence intact. This removes a false current authority while
   retaining exact history.
2. **Retain it frozen.** Keep the direct historical browse path and SHA-256
   guard, but rename every current route and description so it is unmistakably
   a partial March-June 2026 snapshot. It remains a 1.6 MB root-level artifact
   whose content is intentionally stale.
3. **Re-form a bounded current view.** Define a genuinely distinct reader
   query, then generate a bounded projection from `ROADMAP_V2.md`, task trees,
   and Memory. This adds a second maintained view and should be selected only
   if its reader benefit outweighs generation, freshness, and drift controls.

## Lifecycle outcome

The director independently selected option 1 after reviewing this audit.
Decision `0049` owns the atomic retirement: exact Git retrieval and identity,
consumer closure, canonical route migration, live-path absence, and planted
negative controls must all pass together. No replacement status projection is
introduced.
