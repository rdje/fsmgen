# LIVE-DOCUMENT-SIZE-CONTAINMENT-ADOPTION: Bound Every Live Document Family

## Metadata

- Tree ID: `LIVE-DOCUMENT-SIZE-CONTAINMENT-ADOPTION`
- Status: `active`
- Roadmap lane: `infra/continuity / project-wide live-document lifecycle`
- Created: `2026-07-31`
- Last updated: `2026-07-31`
- Owner: repo-local workflow
- Selected by: `README-POLICY-ROUTED-DESTINATION-PRESSURE-CLOSURE.2`

## Goal

Implement the project-wide live-document size-containment doctrine: every live
view remains bounded, every retained history stays addressable and provably
retrievable, every collection has aggregate as well as per-part controls, and
no routed destination becomes the next uninstrumented blob.

## Non-Goals

- Do not apply one universal document size or one storage topology to every
  lifecycle.
- Do not move unique user-facing reference material out of the mdBook merely to
  reduce working-tree bytes.
- Do not remove live historical bytes until their canonical duplicate or exact
  archive retrieval has been proved.
- Do not change compiler, runtime, HDL, VIAL, or other product behavior.
- Do not pre-empt the frozen status-file lifecycle review owned by
  `PROJECT-STATUS-AND-CHANGELOG-POLICY-REVIEW.1`.

## Acceptance Criteria

- A data-only registry and one unconditional checker enforce lifecycle class,
  relative/same-volume location, line/byte/file/aggregate budgets,
  warning/rollover/hard milestones, route closure, projection freshness,
  immutable seals, and archive retrieval.
- The high-water and structural outliers recorded in
  `docs/LIVE_DOCUMENT_SIZE_CONTAINMENT_AUDIT.md` migrate through atomic,
  lossless, independently committed leaves.
- Bounded user-facing views and examples remain accurate in the mdBook.
- Frozen legacy records remain byte-identical unless their existing lifecycle
  owner first selects a replacement.
- All focused fail-closed probes, documentation truth, mdBook, task-tree,
  Knowledge Map, and doctrine gates pass after every leaf.
- Every completed leaf commits through `COMMIT.md`; no leaf raises a legacy
  ceiling to avoid its selected transition.

## Task Tree

- ID: `LIVE-DOCUMENT-SIZE-CONTAINMENT-ADOPTION`
  Status: `active`
  Goal: `Bound all live document families over durable, addressable storage.`
  Children: `LIVE-DOCUMENT-SIZE-CONTAINMENT-ADOPTION.1, LIVE-DOCUMENT-SIZE-CONTAINMENT-ADOPTION.2, LIVE-DOCUMENT-SIZE-CONTAINMENT-ADOPTION.3, LIVE-DOCUMENT-SIZE-CONTAINMENT-ADOPTION.4, LIVE-DOCUMENT-SIZE-CONTAINMENT-ADOPTION.5, LIVE-DOCUMENT-SIZE-CONTAINMENT-ADOPTION.6, LIVE-DOCUMENT-SIZE-CONTAINMENT-ADOPTION.7, LIVE-DOCUMENT-SIZE-CONTAINMENT-ADOPTION.8, LIVE-DOCUMENT-SIZE-CONTAINMENT-ADOPTION.9, LIVE-DOCUMENT-SIZE-CONTAINMENT-ADOPTION.10, LIVE-DOCUMENT-SIZE-CONTAINMENT-ADOPTION.11, LIVE-DOCUMENT-SIZE-CONTAINMENT-ADOPTION.12, LIVE-DOCUMENT-SIZE-CONTAINMENT-ADOPTION.13`

- ID: `LIVE-DOCUMENT-SIZE-CONTAINMENT-ADOPTION.1`
  Status: `done`
  Goal: `Activate common enforcement implementation from a clean selection commit.`
  Acceptance: `Only task/index/roadmap/book/fact/Memory/changelog continuity changes; .2 becomes the sole active implementation leaf; no registry, checker, threshold, topology, content, frozen file, or product behavior changes.`
  Verification: `Clean selection commit 139efbf90 activates only the common enforcement implementation frontier. .2 alone becomes active; no registry, checker, test, threshold, topology, document-family content, frozen file, or product behavior changes. All 37 mdBook chapters test and the repository-local 73-file/17,096,423-byte build passes and is removed exactly; Knowledge Map passes at 1,094 facts/5,702 keys; task-tree integrity passes at trees=3/nodes=881; relative paths pass Files=1/Tests=2; Memory is 34 lines; all 15 existing route controls, diff hygiene, and all eight staged doctrine checks pass with docs-only task acceptance.`
  Commit: `LIVE-DOCUMENT-SIZE-CONTAINMENT-ADOPTION.1: activate common enforcement`

- ID: `LIVE-DOCUMENT-SIZE-CONTAINMENT-ADOPTION.2`
  Status: `done`
  Goal: `Implement the project JSONL data registry and neutral lifecycle checker contract.`
  Acceptance: `Named JSONL records inventory every governed surface without positional sentinels; one unconditional checker rejects malformed/unknown schema and enforces classes, routes, relative/same-volume paths, complete tracked-Markdown coverage, independent budgets and 80/90/100 state, non-worsening exact-baseline transition debt, owned warning debt, frozen/sealed identities, generated freshness, and archive descriptors; positive and fail-closed fixtures cover every class; README remains a first-class GitHub landing interface; existing family topology and limits do not change.`
  Verification: `JSONL surface/route/archive registries and the neutral checker package enforce all 20 local surfaces, 80/90/100 pressure state, immutable baselines plus finite owned transition growth, project-relative same-volume non-symlink targets, complete tracked-Markdown coverage, indexes, route closure/cycles, generated/query/archive/external/frozen terminals, SHA/count/digest archive retrieval, and strict malformed/missing/unknown schema rejection. Focused t1553+t1554 pass at Files=2/Tests=15; docs truth passes Files=4/Tests=310 under the RAM guard; relative-path/locality tests pass Files=2/Tests=22; all 37 mdBook chapters test and the 73-file/17,103,035-byte repository-local build passes then is removed exactly; Knowledge Map passes at 1,094 facts/5,706 keys; task integrity reports trees=3/nodes=882; README remains 246 lines/9,952 bytes; the final staged census covers 2,773/2,773 Markdown paths and all nine doctrines pass. Existing family topology, hard limits, frozen identities, product behavior, and README landing content remain unchanged.`
  Commit: `LIVE-DOCUMENT-SIZE-CONTAINMENT-ADOPTION.2: enforce live-document containment`

- ID: `LIVE-DOCUMENT-SIZE-CONTAINMENT-ADOPTION.3`
  Status: `pending`
  Goal: `Consume the four-file lifecycle review and prove the selected rolling-ledger, sealed-segment, and archive-descriptor schema for any retained live ledgers.`
  Acceptance: `Blocked until PROJECT-STATUS-AND-CHANGELOG-POLICY-REVIEW.1 selects each file's role; the resulting schema partitions retained ledgers only at whole-entry boundaries, preserves order and identity, uses bounded current/index views, records range/revision/line/byte/digest/retrieval metadata, proves exact reconstruction, defines aggregate archive transition, and introduces no CHANGES or DEVELOPMENT_NOTES migration yet.`
  Verification: `pending`
  Commit: `pending`
  Blocked by: `PROJECT-STATUS-AND-CHANGELOG-POLICY-REVIEW.1`

- ID: `LIVE-DOCUMENT-SIZE-CONTAINMENT-ADOPTION.4`
  Status: `pending`
  Goal: `Migrate CHANGES.md to the bounded rolling-ledger topology.`
  Acceptance: `Execute only the lifecycle selected by PROJECT-STATUS-AND-CHANGELOG-POLICY-REVIEW.1 and schema proved by .3; if retained as a ledger, every historical entry is accounted for exactly once, the root current/index view is below its derived warning budget, sealed ranges and version-archive descriptors pass order/digest/retrieval proofs, and the selected append/user-facing workflow remains accurate.`
  Verification: `pending`
  Commit: `pending`
  Blocked by: `LIVE-DOCUMENT-SIZE-CONTAINMENT-ADOPTION.3`

- ID: `LIVE-DOCUMENT-SIZE-CONTAINMENT-ADOPTION.5`
  Status: `pending`
  Goal: `Migrate DEVELOPMENT_NOTES.md to the bounded rationale-ledger topology.`
  Acceptance: `Execute only the lifecycle selected by PROJECT-STATUS-AND-CHANGELOG-POLICY-REVIEW.1 and schema proved by .3; if retained as a ledger, whole rationale entries retain order and identity, the root current/index view is below its derived warning budget, sealed ranges and archive descriptors pass exact proofs, decision/fact/task routing remains canonical, and no automatic placeholder growth is introduced.`
  Verification: `pending`
  Commit: `pending`
  Blocked by: `LIVE-DOCUMENT-SIZE-CONTAINMENT-ADOPTION.3`

- ID: `LIVE-DOCUMENT-SIZE-CONTAINMENT-ADOPTION.6`
  Status: `pending`
  Goal: `Extend the task-tree schema and checker for sealed subtree segments and compact completed terminals.`
  Acceptance: `The live root retains metadata plus active ancestor/frontier; bounded manifests address immutable node segments; IDs, parent/child closure, status, verification, and commit evidence validate across files; compact completed terminals require exact revision retrieval proofs; existing trees are not migrated in this contract leaf.`
  Verification: `pending`
  Commit: `pending`

- ID: `LIVE-DOCUMENT-SIZE-CONTAINMENT-ADOPTION.7`
  Status: `pending`
  Goal: `Migrate the active IAL2 task outlier, completed task outliers, and cross-tree index.`
  Acceptance: `The active IAL2 root/frontier stays immediately readable; all completed nodes remain uniquely addressable through sealed segments or proved archive terminals; done-tree history becomes query-first; docs/TASK_TREE.md is a bounded active/proposed view; exact node/commit/retrieval and PNT selection tests pass.`
  Verification: `pending`
  Commit: `pending`

- ID: `LIVE-DOCUMENT-SIZE-CONTAINMENT-ADOPTION.8`
  Status: `pending`
  Goal: `Partition the Chapter 14 feature backlog by stable user-facing topic.`
  Acceptance: `All existing user-facing material remains in navigable mdBook chapters exactly once; SUMMARY and reference links are complete; every part and aggregate fall below derived warning budgets; examples and all book gates pass.`
  Verification: `pending`
  Commit: `pending`

- ID: `LIVE-DOCUMENT-SIZE-CONTAINMENT-ADOPTION.9`
  Status: `pending`
  Goal: `Separate the bounded live roadmap from shipped chronology.`
  Acceptance: `ROADMAP_V2.md retains current/future direction and concise milestone outcomes; every removed historical claim is proved duplicate in maintained book/task/decision homes or covered by an exact archive descriptor; links and roadmap/task alignment pass; the retained roadmap falls below derived warning budgets.`
  Verification: `pending`
  Commit: `pending`

- ID: `LIVE-DOCUMENT-SIZE-CONTAINMENT-ADOPTION.10`
  Status: `pending`
  Goal: `Bound canonical knowledge cards, shard the generated Knowledge Map, and add query-first discovery.`
  Acceptance: `Oversized cards split only on stable fact boundaries without duplicating or losing answers; cards remain canonical; a small root projection plus deterministic prefix/topic shards cover every fact/key exactly once; freshness, per-card, per-shard, aggregate, and query-result parity tests pass; disposable query caches remain repository-local under .artifacts/.`
  Verification: `pending`
  Commit: `pending`

- ID: `LIVE-DOCUMENT-SIZE-CONTAINMENT-ADOPTION.11`
  Status: `pending`
  Goal: `Consume the separately owned frozen status-file lifecycle decision if it selects migration.`
  Acceptance: `Blocked until PROJECT-STATUS-AND-CHANGELOG-POLICY-REVIEW.1 completes; if that decision retains freezing, record no-op closure; if it selects migration, execute only its declared audience/topology with pre/post identity and retrieval proof.`
  Verification: `pending`
  Commit: `pending`
  Blocked by: `PROJECT-STATUS-AND-CHANGELOG-POLICY-REVIEW.1`

- ID: `LIVE-DOCUMENT-SIZE-CONTAINMENT-ADOPTION.12`
  Status: `pending`
  Goal: `Re-audit the steady state and replace legacy ceilings with derived retained-surface budgets.`
  Acceptance: `Every registered surface is remeasured; all live roots and parts are below warning; aggregate transitions and retrieval/reconstruction probes pass; temporary legacy headroom is reduced through a reviewed local registry update; doctrine/book/fact/task/roadmap/Memory agree; no artifact residue remains.`
  Verification: `pending`
  Commit: `pending`
  Blocked by: `LIVE-DOCUMENT-SIZE-CONTAINMENT-ADOPTION.3, LIVE-DOCUMENT-SIZE-CONTAINMENT-ADOPTION.4, LIVE-DOCUMENT-SIZE-CONTAINMENT-ADOPTION.5, LIVE-DOCUMENT-SIZE-CONTAINMENT-ADOPTION.6, LIVE-DOCUMENT-SIZE-CONTAINMENT-ADOPTION.7, LIVE-DOCUMENT-SIZE-CONTAINMENT-ADOPTION.8, LIVE-DOCUMENT-SIZE-CONTAINMENT-ADOPTION.9, LIVE-DOCUMENT-SIZE-CONTAINMENT-ADOPTION.10, LIVE-DOCUMENT-SIZE-CONTAINMENT-ADOPTION.11, LIVE-DOCUMENT-SIZE-CONTAINMENT-ADOPTION.13`

- ID: `LIVE-DOCUMENT-SIZE-CONTAINMENT-ADOPTION.13`
  Status: `pending`
  Goal: `Classify and bound focused root-level and ancillary Markdown collections.`
  Acceptance: `Every docs/*.md and ancillary Markdown surface has an audience/lifecycle owner and bounded complete index; the current 6,254-line focused outlier and any other semantic outliers are partitioned only at stable topic boundaries; unique maintained content remains in an appropriate browsable home; per-part/file-count/aggregate/freshness/link checks pass below warning without changing product behavior.`
  Verification: `pending`
  Commit: `pending`

## Decisions

- `2026-07-31`: Use the project-neutral, project-agnostic, harness-neutral
  doctrine selected by decision 0041; keep all FSMGen values in local data.
- `2026-07-31`: Preserve directly browsable user reference in semantic shards,
  but move rarely read exact chronology out of the working set only after
  digest-verified version retrieval exists.
- `2026-07-31`: Treat per-part and aggregate containment as separate
  obligations; sharding cannot be the final answer for an append ledger.
- `2026-07-31`: Keep frozen status lifecycle authority with the existing
  `PROJECT-STATUS-AND-CHANGELOG-POLICY-REVIEW.1` owner.
- `2026-07-31`: Clean decision/doctrine/audit commit `139efbf90` activates `.1`
  continuity only and leaves `.2` as the sole active implementation frontier.
- `2026-07-31`: Use JSONL for the local registry data plane: named objects,
  path/route arrays, typed budget/baseline objects, strict unknown-key failure,
  and line-oriented streaming avoid the 22-column prototype's positional
  ambiguity without making serialization part of the neutral doctrine.
- `2026-07-31`: Keep adoption baselines immutable. Any program-required
  continuity growth uses a separately owned finite `transition.max_growth`
  object; ownerless or excess growth fails rather than refreshing the baseline.
- `2026-07-31`: Treat `README.md` as the rendered GitHub landing interface as
  well as a bounded route source; containment preserves its direct purpose,
  quick start, architecture summary, and navigation.
- `2026-07-31`: The complete 2,772-path inventory adds `.13` for focused and
  ancillary collections and widens `.10` to own oversized canonical knowledge
  cards as well as the generated map.

## Open Questions

- None. The existing four-file review remains authoritative for those files'
  semantic roles. From the clean `.2` commit, `.6` is the next independent
  contract leaf to activate because `.3` remains blocked by that review.

## Blockers

- `.3`-`.5` and `.11`: `PROJECT-STATUS-AND-CHANGELOG-POLICY-REVIEW.1` must first
  select the four files' long-term roles. `.1`, `.2`, `.6`-`.10`, and `.12`
  remain independently schedulable subject to their ordinary predecessor
  dependencies; newly discovered `.13` is independently schedulable.

## Acceptance Checklist (enforced) — `.2`

- [x] **ROOT CAUSE (WHY + WHERE)** — `git log -S'ROUTE_REGISTRY' --oneline --
  scripts/check_readme_entrypoint.sh` identifies `45fc6631e` as the commit that
  embedded every destination kind, budget, measurement, frozen identity, and
  terminal rule inside the README-specific checker and ten-column route file.
  Direct inspection shows no reusable lifecycle checker or project-wide
  surface registry, while the pre-slice `scripts/check_doctrines.sh --list`
  reports eight
  checks and no `LIVE-DOCUMENT-SIZE` doctrine. The clean census also reveals
  uncovered root/focused/knowledge-card collections, so the current mechanism
  cannot enforce the decision-0041 contract outside README routes.
- [x] **ADDRESSED (verified)** — `perl -c` reports the neutral checker and both
  focused tests `syntax OK`; `prove -Iperl
  t/1553-readme-routed-destination-pressure.t
  t/1554-live-document-size-doctrine.t` reports `All tests successful` at
  `Files=2, Tests=15`. The fixtures cover every lifecycle, JSONL malformed/
  missing/unknown data, locality/symlinks, budgets and 80/90/100 states,
  immutable baselines plus owned bounded transition growth, route closure and
  cycles, generated/query/archive/external/frozen verification, descriptor
  schema/count/digest/path failures, optional NUL coverage, and neutral-package
  identity. The live checker reports 20 surfaces and the final staged census
  reports 2,773/2,773 tracked Markdown paths.
- [x] **NO REGRESSION** — RAM-guarded documentation truth reports `All tests
  successful` at `Files=4, Tests=310`; path/locality proof reports `Files=2,
  Tests=22`; all 37 mdBook chapters test and the repository-local 73-file /
  17,103,035-byte build passes then is removed exactly. Knowledge Map reports
  `knowledge-map: OK` at 1,094 facts / 5,706 keys; task integrity reports
  trees=3/nodes=882; README is unchanged at 246 lines/9,952 bytes; Memory stays
  bounded; staged task acceptance passes; and the nine-check driver ends
  `[doctrine] all doctrine checks passed`. No family topology, hard limit,
  frozen identity, compiler/runtime/generated output, or VIAL behavior changes.

## Verification Log

| Date | Leaf | Checks | Result |
| --- | --- | --- | --- |
| `2026-07-31` | `.1` activation | clean `139efbf90` predecessor; task/index/roadmap/book/fact/Memory/changelog sync; path/mdBook/Knowledge Map/task/Memory/route/diff/staged-doctrine gates; exact cleanup | `passed`; paths Files=1/Tests=2; 37 chapters; build 73 files/17,096,423 bytes; Knowledge Map 1,094 facts/5,702 keys; trees=3/nodes=881; Memory 34 lines; all eight staged doctrines pass with docs-only task acceptance; `.2` alone active; no implementation, threshold, topology, document-family content, frozen-file, or product change |
| `2026-07-31` | `.2` common enforcement | neutral JSONL contract/core; 20-surface local registry; strict lifecycle/debt/route/archive/coverage/neutrality fixtures; README compatibility; docs/path/locality/mdBook/Knowledge Map/task/Memory/diff/staged-acceptance/nine-doctrine gates; exact cleanup | `passed`; focused Files=2/Tests=15; docs Files=4/Tests=310; paths/locality Files=2/Tests=22; 37 chapters; build 73 files/17,103,035 bytes; Knowledge Map 1,094 facts/5,706 keys; trees=3/nodes=882; final staged coverage 2,773/2,773; README 246 lines/9,952 bytes; all nine doctrines pass; no migration, hard-limit, frozen-file, landing-content, or product change |

## Commit Log

| Leaf | Commit subject or reference | Notes |
| --- | --- | --- |
| `.1` activation | `LIVE-DOCUMENT-SIZE-CONTAINMENT-ADOPTION.1: activate common enforcement` | Activate `.2` from the clean doctrine-selection commit without implementing it. |
| `.2` common enforcement | `LIVE-DOCUMENT-SIZE-CONTAINMENT-ADOPTION.2: enforce live-document containment` | Ship neutral JSONL checker contract/core plus FSMGen data and unconditional ninth-doctrine coverage; next clean selection is `.6`. |

## Changelog

- `2026-07-31`: Clean selection commit `139efbf90` activates `.1` continuity;
  `.2` becomes the sole active common-registry/checker implementation leaf.
- `2026-07-31`: `.2` ships strict JSONL common enforcement over 20 surfaces
  and the complete tracked-Markdown inventory while preserving README's
  landing content, all existing hard limits/topologies, frozen identities, and
  product behavior; `.6` is the next clean selection frontier.
