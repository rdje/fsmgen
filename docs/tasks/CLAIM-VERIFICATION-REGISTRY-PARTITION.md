# CLAIM-VERIFICATION-REGISTRY-PARTITION: Preserve Bounded Claim Publication Capacity

## Metadata

- Tree ID: `CLAIM-VERIFICATION-REGISTRY-PARTITION`
- Status: `active`
- Roadmap lane: `infra/evidence governance`
- Created: `2026-09-01`
- Last updated: `2026-09-01`
- Owner: repo-local workflow

## Goal

Replace the saturated single-file claim-record boundary with a finite,
repository-local partition contract that preserves bounded checking, global
claim identity, exact source-marker ownership, and future publication capacity
without silently raising the existing 65,536-byte file ceiling.

## Non-Goals

- Do not weaken or reinterpret re-derivation, falsification, durability,
  source-marker, tracked-path, or claim-classification requirements.
- Do not reclassify, rewrite, or drop an existing published claim merely to
  make the current registry smaller.
- Do not add a project-wide unbounded file discovery mechanism or move any
  registry data off the repository volume.
- Do not resume the blocked HIAL quantitative frontier until the partition is
  implemented, migrated, documented, and committed cleanly.

## Acceptance Criteria

- The current 65,381-byte registry pressure and inability to admit one further
  complete independent claim record are independently reproduced and
  durably owned.
- One finite closed contract bounds registry files, records, per-file bytes,
  per-record bytes, and aggregate discovery while preserving deterministic
  global claim-ID/order/source-marker validation.
- The exact existing claim set migrates without loss, duplication, semantic
  rewrite, source-marker drift, disposition drift, or containment-ceiling
  inflation.
- Positive, boundary, and hostile mutations prove the partition rejects
  missing, extra, reordered, duplicated, foreign, oversized, or ambiguous
  registry state.
- `CLAIM_VERIFICATION.md`, the mdBook, Knowledge Map, task/index/Memory state,
  claim inventory, live containment, and all registered doctrines agree.
- Each completed leaf is committed through `COMMIT.md`; full CI remains for
  the normal pre-push boundary.

## Task Tree

- ID: `CLAIM-VERIFICATION-REGISTRY-PARTITION`
  Status: `active`
  Goal: `Restore bounded future claim-publication capacity without weakening three-leg evidence.`
  Children: `CLAIM-VERIFICATION-REGISTRY-PARTITION.1, CLAIM-VERIFICATION-REGISTRY-PARTITION.2, CLAIM-VERIFICATION-REGISTRY-PARTITION.3`

- ID: `CLAIM-VERIFICATION-REGISTRY-PARTITION.1`
  Status: `done`
  Goal: `Reproduce saturation and select the smallest finite partition contract before implementation.`
  Acceptance: `Measured current bytes and a canonical complete-record lower bound prove the pressure; the selected contract names bounded discovery, global invariants, exact migration, compatibility, watcher, documentation, and implementation leaves without changing checker or registry behavior.`
  Verification: `PASS — the current registry is 26 lines/65,381 bytes at SHA-256 38b77b69f5fdad6350e665e0aa4abbf19c89ed94097e7b3ad424a0d3179170bc; only 155 bytes remain under the unchanged 65,536-byte cap; deliberately optimistic canonical missing/available-leg shapes are still 477/498 bytes; checker reports 25 records; the selected three-leaf graph passes task integrity with five active trees and 1,035 nodes; decision 0094 selects the finite contract.`
  Commit: `CLAIM-VERIFICATION-REGISTRY-PARTITION.1: select finite claim registry set`

- ID: `CLAIM-VERIFICATION-REGISTRY-PARTITION.2`
  Status: `in_progress`
  Goal: `Implement the optional finite registry-set checker contract and focused hostile fixtures.`
  Acceptance: `The checker accepts explicit single-registry or registry-set input, validates manifest and aggregate bounds plus exact tracked shard closure, preserves all existing record/marker invariants globally, and a pre-repair RED watcher turns green without changing the production default registry.`
  Verification: `pending`
  Commit: `pending`

- ID: `CLAIM-VERIFICATION-REGISTRY-PARTITION.3`
  Status: `pending`
  Goal: `Migrate the default claim doctrine to two bounded shards and close all documentation and governance surfaces.`
  Acceptance: `The original 65,381-byte shard remains byte-identical, one empty bounded shard restores capacity, the finite set becomes the default, and policy/book/Knowledge Map/bootstrap/inventory/containment/task/Memory/doctrine surfaces agree with zero claim/disposition drift or ceiling increase.`
  Verification: `pending`
  Commit: `pending`

## Decisions

- `2026-09-01`: Use a separate operational repair tree rather than reopen the
  completed `CLAIM-VERIFICATION-ADOPTION` history. The active HIAL frontier
  explicitly selects this repair before any further independent quantitative
  claim.
- `2026-09-01`: The existing 65,536-byte registry ceiling is a safety boundary,
  not a growth target. Contract selection must recover capacity through finite
  partitioning or rollover and may not disguise saturation by raising it.
- `2026-09-01`: Decision `0094` selects one finite ordered registry set with
  hard manifest/aggregate/per-shard bounds, global identity and marker closure,
  exact tracked sibling census, explicit single-file fixture compatibility,
  byte-identical first-shard retention, and one fresh rollover shard.
- `2026-09-01`: Adding the required decision exposed that the rationale
  collection had consumed its exact baseline-plus-transition allowance. The
  collection remains below its reviewed health target and enforcement ceiling;
  leaf `.1` therefore applies the existing containment formula only to the
  three exceeded transition dimensions: actual minus immutable baseline plus
  one existing ratchet step. No health target or ceiling changes.

## Open Questions

- None. Decision `0094` closes the contract question; `.2` implements the
  optional checker path before `.3` changes production discovery.

## Blockers

- None.

## Acceptance Checklist (enforced for implementation changes)

- [x] **ROOT CAUSE (WHY + WHERE)** — `git log -S '"surface_id":"rationale"' --oneline -- doctrine/live_document_size/surfaces.jsonl` traces the governed collection to `18e2dcbc6`; after adding decision `0094`, `scripts/check_live_document_size.sh` reported exact transition excess at 95 files, 8,768 lines, and 512,787 bytes because the old 89-file/7,996-line/467,401-byte baseline plus 5-file/730-line/43,802-byte allowance was fully consumed.
- [x] **ADDRESSED (verified)** — decision `0094` records the 65,381/65,536-byte saturation and selects a finite registry set. The existing containment formula sets only the exceeded rationale transition dimensions to actual minus baseline plus one unchanged ratchet step: files 7, total lines 822, and total bytes 49,482; the owner becomes `.1`, while all health targets and enforcement ceilings remain unchanged.
- [x] **NO REGRESSION** — the documentation-path audit reports `All tests successful` at `Files=1, Tests=2`; task integrity accepts five active trees and 1,035 nodes; Memory architecture passes at 16 lines; the claim checker remains green at 25 records, inventory/disposition remains complete at 1,704/1,704 candidates with 172 claim-record, 939 gate, and 593 reviewed outcomes, and live containment accepts all 22 surfaces with zero ceiling increase. Staged task acceptance and all 12 registered doctrines pass.

## Changelog

- `2026-09-01`: Activated from the clean HIAL `.17.4.7` handoff after the
  bounded claim registry reached 65,381 of 65,536 bytes.
- `2026-09-01`: Leaf `.1` proved a 477-byte conservative record lower bound,
  selected decision `0094`, and handed implementation to `.2` without changing
  checker or registry behavior.
