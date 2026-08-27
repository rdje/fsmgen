# Decision 0088: Provider-backed hosted tests use explicit dedicated coordinates

- **Status:** Accepted
- **Date:** 2026-08-27
- **Owner:** `DARWIN-INLINE-VERILATOR-RUNTIME-QUALIFICATION.3.2.2.1`
- **Refines:** [0063](0063-hosted-regression-uses-closed-non-cancelling-partitions.md)

## Context

Decision `0063` isolated the then-existing provider-backed test `t/1598` and
materialized exact OSVVM 2026.05 only for its dedicated job. Later scale-proof
slices added `t/1648`, whose OSVVM profile verifies the same provider, and
`t/1650`, whose family qualification evaluates that profile. Both remained in
ordinary file shards because the closed dedicated inventory was not widened
with the new dependency.

Exact pushed revision `c7a222ac41db7b28d502accbb75fcdc6ed579754`
falsified that routing: ordinary shard 8 ran `t/1650` without the provider and
failed at `/dependency_root` with
`VIAL_OSVVM_PROVIDER_MATERIALIZATION_ERROR`. A source/call-path census separates
the three default provider-backed tests from `t/1642`'s mocked verifier,
`t/1599`'s installed-tool conditional replay, and the explicitly opt-in
measurement paths in `t/1661` and `t/1662`.

## Decision

1. Refine the closed hosted partition to five dedicated coordinates:
   `t/1436`, `t/1437`, `t/1598`, `t/1648`, and `t/1650`. The last three are
   the complete current default provider-backed OSVVM set.
2. Represent prerequisites as explicit Boolean fields in the workflow matrix.
   Only coordinate 0 installs the pinned Verilator/Yosys pair. Exactly
   coordinates 2, 3, and 4 materialize repository-local OSVVM 2026.05 and
   verify root commit `2f7c391051dfb11890fa4bdbda9918d1db492250` before
   their test starts.
3. Keep the driver authoritative for coordinate-to-test mapping and the
   workflow authoritative for ephemeral prerequisite provisioning. The
   focused watcher closes both representations together, the complete tracked
   test partition, out-of-range behavior, and wrong-cardinality rejection.
4. Preserve 16 ordinary file shards, 48 corpus-entry shards, 68 dynamic-case
   shards, non-cancelling matrices, five-hour ceilings, and the always-run
   required aggregate. Local full regression remains unsharded.
5. Any future default test that crosses a provider or external-tool boundary
   must update its explicit dedicated ownership, prerequisite flag, watcher,
   Knowledge Map fact, and user-facing CI documentation in the same slice.

## Rationale

Provider materialization is a test prerequisite, not ambient runner state.
Attaching it explicitly to each owning coordinate keeps ordinary jobs minimal,
makes dependency failures local and reviewable, and avoids downloading a
recursive provider graph into all 16 ordinary shards. Boolean matrix metadata
states why each job receives a dependency instead of hiding policy in numeric
condition expressions.

Dedicated ownership also gives each large scale proof its own five-hour budget
and terminal result. This changes CI scheduling only; it does not widen VIAL,
backend, qualification, product-support, or runtime claims.

## Alternatives rejected

- **Materialize OSVVM in every ordinary shard.** This duplicates network and
  storage work in 16 jobs and makes undeclared provider dependencies ambient.
- **Skip provider-backed scale tests when the provider is absent.** This would
  convert an exact required qualification into concealed missing coverage.
- **Make one dedicated coordinate run all provider tests.** One failure or
  timeout would hide later tests and weaken per-test attribution.
- **Infer prerequisites from shard numbers in step conditions.** Numeric
  coupling is less reviewable than explicit per-coordinate capability flags.

## Claim verification

- **Re-derivation:** enumerate all 1,656 tracked `t/*.t` paths; trace direct and
  family OSVVM evaluation call paths; dry-run all five dedicated coordinates
  and all 16 ordinary coordinates; independently recompute 1,647 ordinary plus
  nine separately hosted paths.
- **Falsification:** retain exact-SHA hosted job `98359601960` and its missing-
  provider diagnostic; prove wrong-count and out-of-range coordinates fail;
  assert the two non-provider dedicated coordinates carry false provider flags.
- **Durability:** retain this decision, the owning task evidence, the canonical
  Knowledge Map card, workflow documentation, mdBook, and `t/1183`; the watcher
  re-closes driver, workflow, prerequisite, and complete-inventory truth on
  every focused or complete regression.
