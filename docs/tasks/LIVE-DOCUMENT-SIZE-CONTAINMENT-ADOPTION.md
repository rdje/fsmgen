# LIVE-DOCUMENT-SIZE-CONTAINMENT-ADOPTION: Bound Every Live Document Family

## Metadata

- Tree ID: `LIVE-DOCUMENT-SIZE-CONTAINMENT-ADOPTION`
- Status: `proposed`
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
  Status: `proposed`
  Goal: `Bound all live document families over durable, addressable storage.`
  Children: `LIVE-DOCUMENT-SIZE-CONTAINMENT-ADOPTION.1, LIVE-DOCUMENT-SIZE-CONTAINMENT-ADOPTION.2, LIVE-DOCUMENT-SIZE-CONTAINMENT-ADOPTION.3, LIVE-DOCUMENT-SIZE-CONTAINMENT-ADOPTION.4, LIVE-DOCUMENT-SIZE-CONTAINMENT-ADOPTION.5, LIVE-DOCUMENT-SIZE-CONTAINMENT-ADOPTION.6, LIVE-DOCUMENT-SIZE-CONTAINMENT-ADOPTION.7, LIVE-DOCUMENT-SIZE-CONTAINMENT-ADOPTION.8, LIVE-DOCUMENT-SIZE-CONTAINMENT-ADOPTION.9, LIVE-DOCUMENT-SIZE-CONTAINMENT-ADOPTION.10, LIVE-DOCUMENT-SIZE-CONTAINMENT-ADOPTION.11, LIVE-DOCUMENT-SIZE-CONTAINMENT-ADOPTION.12`

- ID: `LIVE-DOCUMENT-SIZE-CONTAINMENT-ADOPTION.1`
  Status: `pending`
  Goal: `Activate common enforcement implementation from a clean selection commit.`
  Acceptance: `Only task/index/roadmap/book/fact/Memory/changelog continuity changes; .2 becomes the sole active implementation leaf; no registry, checker, threshold, topology, content, frozen file, or product behavior changes.`
  Verification: `pending`
  Commit: `pending`

- ID: `LIVE-DOCUMENT-SIZE-CONTAINMENT-ADOPTION.2`
  Status: `pending`
  Goal: `Implement the project data registry and neutral lifecycle checker contract.`
  Acceptance: `A data-only registry inventories every governed surface; one unconditional checker enforces classes, routes, relative/same-volume paths, independent budgets and 80/90/100 state, exact-baseline transition debt limited to containment-program continuity, owned warning debt, frozen/sealed identities, generated freshness, and archive descriptors; positive and fail-closed fixtures cover every class; existing family topology and limits do not change.`
  Verification: `pending`
  Commit: `pending`

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
  Goal: `Shard the generated Knowledge Map and add bounded query-first discovery.`
  Acceptance: `Fact cards remain canonical; a small root projection plus deterministic prefix/topic shards cover every fact/key exactly once; freshness, per-shard, aggregate, and query-result parity tests pass; disposable query caches remain repository-local under .artifacts/.`
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

## Open Questions

- None for `.1` activation. Later schema leaves must resolve their exact data
  formats within the accepted doctrine before migrating content; the existing
  four-file review remains authoritative for those files' semantic roles.

## Blockers

- `.3`-`.5` and `.11`: `PROJECT-STATUS-AND-CHANGELOG-POLICY-REVIEW.1` must first
  select the four files' long-term roles. `.1`, `.2`, `.6`-`.10`, and `.12`
  remain independently schedulable subject to their ordinary predecessor
  dependencies.
