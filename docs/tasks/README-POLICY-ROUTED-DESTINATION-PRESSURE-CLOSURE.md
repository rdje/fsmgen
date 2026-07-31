# README-POLICY-ROUTED-DESTINATION-PRESSURE-CLOSURE: Bound Routed Documentation Pressure

## Metadata

- Tree ID: `README-POLICY-ROUTED-DESTINATION-PRESSURE-CLOSURE`
- Status: `active`
- Roadmap lane: `infra/continuity / entry-point documentation`
- Created: `2026-07-31`
- Last updated: `2026-07-31`
- Owner: repo-local workflow
- Activation: director supplied PGEN's measured fifth README-policy lesson on
  `2026-07-31`, while the repository was clean at `b23cde1bb`.

## Goal

Close the README policy's pressure-routing hole: moving excluded detail out of
the landing page must not silently turn an uninstrumented neighboring surface
into the next append-log sink.

## Non-Goals

- Do not copy PGEN-specific paths or project state into the neutral reusable
  policy body.
- Do not require every canonical destination to use the README's exact line/
  byte mechanism; partitioned manuals, generated indexes, archival histories,
  and external systems need controls appropriate to their lifecycle.
- Do not delete, rewrite, or silently bless FSMGen's large historical stores.
- Do not change compiler, runtime, generated HDL, VIAL, or product behavior.

## Acceptance Criteria

- `README_POLICY.md` requires transitive routing closure: every destination
  named by the README, policy, or failure hint has an owner, lifecycle class,
  pressure control, and mechanically checked or explicitly external/archive
  terminal; cycles and unclassified sinks fail adoption.
- Hot/live files have derived line and byte ceilings; partitioned collections
  have bounded indexes and per-part/aggregate thresholds; generated indexes
  have size and freshness controls; append-only history has a shard/rotation
  threshold and query-first access; frozen legacy files cannot receive new
  routed content.
- FSMGen tracks every actual README destination in a project-owned data-only
  registry and `scripts/check_readme_entrypoint.sh` enforces that registry on
  every commit/CI tree, independent of changed paths.
- Current measurements are recorded as ceilings or explicit debt boundaries,
  never presented as ideal reusable defaults. A threshold increase requires a
  reviewed decision; reaching one requires routing, partitioning, compaction,
  or a separately owned remediation.
- Decision, doctrine, mdBook, fact, task index, roadmap, Memory, and changelog
  remain synchronized; focused positive/negative probes and broader gates pass.

## Task Tree

- ID: `README-POLICY-ROUTED-DESTINATION-PRESSURE-CLOSURE`
  Status: `active`
  Goal: `Make README overflow routing pressure-closed rather than displacement-only.`
  Children: `README-POLICY-ROUTED-DESTINATION-PRESSURE-CLOSURE.1, README-POLICY-ROUTED-DESTINATION-PRESSURE-CLOSURE.2`

- ID: `README-POLICY-ROUTED-DESTINATION-PRESSURE-CLOSURE.1`
  Status: `done`
  Goal: `Integrate PGEN's measured destination-overflow lesson into neutral policy and FSMGen enforcement.`
  Acceptance: `Policy, registry, checker/tests, decision, doctrine, book, fact, task/roadmap/live-doc continuity, and exact positive/negative evidence agree; README and product behavior remain unchanged.`
  Verification: `Decision 0040, the neutral routing-pressure policy, and FSMGen's 15-route data registry/checker close the destination-displacement hole. Live files and collections have exact line/byte/file/aggregate ceilings; generated, query, archive, append-ledger, and frozen terminals retain class-specific controls. Focused positive and negative evidence passes at Files=1/Tests=7; combined checker/path evidence passes at Files=2/Tests=9; docs truth passes at Files=4/Tests=314; all 37 mdBook chapters and the repository-local 73-file/17,087,147-byte build pass; Knowledge Map passes at 1,093 facts/5,693 keys; final task/doctrine/Memory evidence is recorded below. README.md, compiler/runtime, generated product artifacts, and VIAL behavior are unchanged; exact book output is removed.`
  Commit: `README-POLICY-ROUTED-DESTINATION-PRESSURE-CLOSURE.1: close routed documentation pressure`

- ID: `README-POLICY-ROUTED-DESTINATION-PRESSURE-CLOSURE.2`
  Status: `proposed`
  Goal: `Select a project-wide live-document size-containment doctrine and exact partition, shard, rotation, or archival owners before a hard ceiling is reached.`
  Acceptance: `The audit remeasures every registered destination, identifies all per-file or aggregate surfaces at or above 80% of a ceiling plus structural outliers, and selects one shared doctrine for bounded live views, deterministic rollover, sharded durable stores, generated bounded indexes, archival retrieval proofs, frozen terminals, and unconditional data-registry enforcement. It proves why each current outlier is live debt or an acceptable terminal and creates/selects the smallest exact family migrations without rewriting or deleting historical content in this leaf.`
  Verification: `pending`
  Commit: `pending activation`

## Decisions

- `2026-07-31`: Treat PGEN's 1,547,057-byte destination, including 94.7%
  dated changelog content, as empirical policy evidence that routing without a
  destination control displaces rather than removes documentation pressure.
- `2026-07-31`: The director asks `.2` to find sustainable offloading for
  mechanically growing files. Audit the common pattern “bounded live view over
  repository-local sharded durable storage,” with deterministic rollover,
  generated bounded indexes, hashes/retrieval proofs, and no next-door blob.
- `2026-07-31`: Name the common architecture a project-wide live-document
  size-containment doctrine. Memory architecture is one specialized consumer;
  all live docs, indexes, ledgers, and archives must share the broader rule.

## Open Questions

- None. The feedback identifies the policy defect and FSMGen has exact local
  routing, doctrine, and data-registry seams.

## Blockers

- None.

## Acceptance Checklist (enforced) — `.1`

- [x] **ROOT CAUSE (WHY + WHERE)** — Before policy/checker edits, PGEN's
  supplied measurement showed one routed status file at 1,547,057 bytes with
  94.7% dated changelog content. `git log -S` traces the generic routing table
  to `b03d7666e` and the local “move per-leaf detail” diagnostic to
  `2efd79375`. Direct `rg` located those unchecked routes at
  `README_POLICY.md:56-62` and `scripts/check_readme_entrypoint.sh:52-64`, while
  `wc -l -c` showed local destinations ranging from 47-line `MEMORY.md` to
  multi-megabyte `CHANGES.md`/`KNOWLEDGE_MAP.md`. The checker enforced only
  README size/narration; it had no destination registry, lifecycle kind,
  budget, frozen identity, or closure failure.
- [x] **ADDRESSED (verified)** — `bash -n` accepts both shell drivers;
  `scripts/check_readme_entrypoint.sh` reports all 15 declared routes and ends
  with `readme-entrypoint: all README entry-point invariants hold` plus the new
  routed-pressure invariant. `prove -Iperl
  t/1553-readme-routed-destination-pressure.t` reports `All tests successful`
  at `Files=1, Tests=7`; its subtests prove the live registry, a minimal valid
  fixture, missing route, stale README marker, independent per-file/aggregate
  overflow, frozen SHA drift, repository escape, and malformed query-budget
  cases.
- [x] **NO REGRESSION** — Focused checker plus relative paths report
  `All tests successful` at `Files=2, Tests=9`; documentation truth reports
  `Files=4, Tests=314`; all 37 mdBook chapters test and the repository-local
  73-file / 17,087,147-byte build passes and is removed exactly. Knowledge Map
  validation reports `knowledge-map: OK` at 1,093 facts / 5,693 keys. Task-tree
  integrity, bounded Memory, staged implementation acceptance, and all eight
  doctrines complete in the final commit gate; README.md and all product
  behavior remain unchanged.

## Verification Log

| Date | Leaf | Checks | Result |
| --- | --- | --- | --- |
| `2026-07-31` | `.1` | policy/decision/registry/checker/test/doctrine/book/fact/live-doc synchronization; positive and fail-closed route fixtures; docs/path/mdBook/Knowledge Map/Memory/diff/staged implementation acceptance/doctrines; exact cleanup | `passed`; decision 0040; 15 routes; focused Files=1/Tests=7; combined Files=2/Tests=9; docs Files=4/Tests=314; trees=3/nodes=871; 37 chapters; build 73 files/17,087,147 bytes; Knowledge Map 1,093 facts/5,693 keys; Memory 49 lines; staged acceptance identifies root=git_history/no-regression=prove_summary; all eight doctrines pass; README and product behavior unchanged; output removed |

## Commit Log

| Leaf | Commit subject or reference | Notes |
| --- | --- | --- |
| `.1` | `README-POLICY-ROUTED-DESTINATION-PRESSURE-CLOSURE.1: close routed documentation pressure` | Integrate the fifth cross-project lesson and enforce local routing closure. |

## Changelog

- `2026-07-31`: Director supplied PGEN's measured fifth policy lesson and
  activated `.1` from clean commit `b23cde1bb`; no policy, checker, registry,
  or other repository change preceded task-tree ownership.
- `2026-07-31`: `.1` accepts decision `0040`, adds neutral transitive routing-
  pressure requirements plus FSMGen's 15-route registry and fail-closed guard,
  and closes without changing README.md or product behavior. Measured local
  high-water debt is retained visibly in proposed `.2`; the decision owns the
  durable rationale, so no duplicate development-note entry is added.
