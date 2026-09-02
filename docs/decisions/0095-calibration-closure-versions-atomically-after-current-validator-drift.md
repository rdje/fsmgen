# 0095 — Calibration closure versions atomically after current-validator drift

- Date: 2026-09-02
- Type: verification evidence/versioning
- Status: accepted
- Refines: [0056](0056-vial-scale-measurements-use-pinned-evidence-and-bounded-failure.md), [0093](0093-architecture-scale-caps-are-component-ceilings-with-explicit-route-authority.md)
- Implementation owner: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.4.8`

## Context

The complete cap-consistency authority independently verifies all 23 selected
groups and all 161 required dimensions. That unlocks explicit calibration
revalidation; it does not make the older measurement closure current.

The immutable store contains 256 files/32,007,521 bytes. Its published closure
selects 232 files/28,398,586 bytes, a separately superseded backend-emission-v1
lineage owns 22 files/2,232,452 bytes, and the closure publication owns two
files/1,376,483 bytes. Those sets are disjoint and exhaust the store.

The first guarded current-validator revalidation rejects the atomic closure.
Six of the 52 bridge-fanout reports retain pre-hardening source-map diagnostics:
configurations limit, types qualification/limit, endpoints limit, and backend-
bindings qualification/limit. Each historical report records the fully
materialized source-map count; current code stops before constructing record
65,537. For example, configurations limit changes only from count 114,909 and
a 1,230-byte bridge projection to count 65,537 and 1,229 bytes. All 56 semantic-
catalog profiles validate. Commit `4834873a8` introduced the intentional early
source-map admission after the measurement publication was sealed.

A guarded census of the other six closure authorities establishes a second,
distinct drift family. Execution/checking, portable-SystemVerilog runtime, and
balanced-portable matrices still validate. Backend emission rejects its first
portable-VHDL reference profile because canonical evaluation changed; portable-
VHDL and OSVVM runtime matrices reject their corresponding first reference
profiles because materialization evidence changed. The closure's VHDL backend
reference predates both the 127-byte scenario-cycle repair in `460df366e` and
the later 112-byte boundary-time repair in `0b6e83979`. Fresh derivation proves
that only `base_output_arbitration_tb.vhd` changes, from 46,264 to 46,503 bytes:
total portable source moves 118,064 to 118,303 bytes while 59 source maps remain
unchanged. Artifact-graph, evaluation, portable-VHDL materialization, and OSVVM
materialization identities therefore change exactly as expected.

The mismatch is not artifact corruption or a current cap defect. It is an
expected version boundary between authentic historical measurement and safer
current behavior. Treating unchanged constituent files as current would break
the closure's atomic identity; weakening the current validator would erase the
admission-order repair.

## Decision

1. Calibration closure v1 is one atomic evidence version. Any expected mismatch
   between a selected report and current derivation versions the complete
   232-file selected lineage as historical. No constituent is advertised as a
   current closure merely because its individual bytes still validate.
2. The immutable closure report and manifest remain authenticated under their
   original identities. Versioning changes their disposition, never their
   bytes, paths, hashes, publisher revision, statistics, or candidate budgets.
3. The disposition authority runs all 108 selected semantic/bridge reports
   through current validation, requires 102 exact matches (all 56 semantic and
   46 of 52 bridge), and binds the other six profiles to current derivation and
   full commit `4834873a887e742c76157faa2d50c3fd1375a38a`. Every historical/current
   diagnostic and bridge-projection byte count is sealed; missing, extra,
   reordered, or differently changed drift fails closed.
4. The disposition authority independently derives the VHDL reference graph,
   requires the exact 127+112=239 fixed-byte lineage, one changed source, stable
   59-map count and rerun identity, changed artifact/evaluation identities, and
   exact historical/current portable-VHDL and OSVVM materialization identities.
5. The 232 selected files, 22 separately superseded backend-emission-v1 files,
   and two closure-publication files must remain pairwise disjoint and exactly
   equal the 256-file store, including path, byte count, and SHA-256 identity.
6. The resulting evidence role remains `historical_measurement_only` and its
   candidate budgets remain `candidate_only`. Recapture is required before any
   future use as current performance evidence, but it is not a dependency of
   cap closeout: the current 23-group/161-dimension proof is independent.
7. No stale publication may be overwritten, silently patched, accepted through
   a compatibility exception, or relabelled as cap implementation, performance
   enforcement, support, capacity, or reached-resource-boundary evidence.
8. `FSM::VIAL::ArchitectureScaleCalibrationDisposition` is the caller-sealed
   implementation. It accepts only the repository root, rebuilds cap authority,
   authenticates the immutable publication, derives both exact drift families,
   validates the two historical lineages, and returns only a compact defensive
   report from its bounded worker.

## Alternatives rejected

- **Call the unchanged members current:** rejected because the published
  closure identity covers the complete ordered authority/profile set.
- **Relax current validators to accept historical full counts:** rejected
  because it would undo verified pre-materialization admission and conflate two
  semantics.
- **Overwrite or edit immutable measurement files:** rejected because immutable
  bytes and their identities are the evidence being dispositioned.
- **Recapture before cap closeout:** rejected as an unnecessary dependency;
  current cap correctness is already independently proved and calibration is
  not cap implementation.
- **Promote historical candidate budgets:** rejected because neither authentic
  historical bytes nor a successful recapture automatically establishes public
  budgets, performance enforcement, support, or capacity.

## Claim verification

- **Re-derive:** rebuild the sealed cap-consistency prerequisite; authenticate
  the immutable closure; reconstruct all 108 semantic/bridge outcomes, the
  portable-VHDL backend reference and both VHDL-derived materializations; run
  the separate six-authority current-validator census; and independently census
  the three exact store partitions.
- **Falsify:** make one cap dimension pending; mutate one historical/current
  diagnostic, byte count, source identity, graph identity, or materialization
  identity; remove, add, reorder, or overlap a drift/profile/artifact; or inject
  one extra store path. Each control must reject.
- **Durability:** retain this decision, the owning task-tree evidence, the
  caller-sealed module, t1764, synchronized mdBook/Knowledge Map truth, bounded
  claim dispositions, and the work-unit Git commit.

## Consequences and nonclaims

- Calibration closure v1 stays authentic and reproducible as historical
  measurement while current semantics remain uncompromised.
- A later recapture must use a new immutable namespace and its own task/decision
  authority; it cannot replace v1 in place.
- This decision changes no product cap, accepted route, source, IR, emitted
  artifact, runtime result, support statement, public budget, or capacity claim.
