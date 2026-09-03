# Decision 0099: Exclude only sealed process-telemetry derivatives from regression correctness

- **Status:** Accepted
- **Date:** 2026-09-03
- **Owner:** `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.5.4.4.1` + `.2.1`
- **Refines:** [0097](0097-regression-gates-publish-replaceable-observations-without-recalibrating.md)

## Context

The clean gate failed ordinal 10 at 4 x 29 fields, then ordinal 8 at 4 x 24; fresh/qualified projection sizes were respectively 165,285 and 77,952 bytes. Only lifecycle evidence/handle digests, evidence sizes, oracle identities, and stage byte totals changed. Ordinal 11 passed.

GHDL/OSVVM and portable-Verilator lifecycle evidence embed fresh process timings; portable emit precedes them and stays exact. Source/history comparison from capture `155aa22ea` found no relevant producer change. Recalibration would freeze another timing set.

## Decision

1. Raw identity remains the fast path; fallback runs only after mismatch.
2. Caller-sealed seams authenticate both projections and every qualification coordinate.
3. Only exact runtime-stream/gate-candidate/runtime-records schema/backend pairs normalize: OSVVM + `vhdl_osvvm_qualified`, and portable + `sv_portable_verilator`. The other nine profiles stay byte-exact.
4. OSVVM replaces 29 derivatives per record across compile/elaborate/run/trace/result/publish; portable replaces 24 across compile/run/trace/result/publish. Scalar shape, digest form, count, kind, order, and uniqueness remain exact.
5. All else compares canonically before performance; success retains the qualified identity. Evidence, qualification, budgets, providers, environment, and publication do not change.

## Rejected alternatives

Recalibration preserves the defect; changing producer evidence is broader; general normalization hides semantics; publishing a fresh identity contradicts qualified admission.

## Verification and consequences

- **Re-derive:** task evidence records both comparisons; t1793 reconstructs the 116/96 partitions.
- **Falsify:** history and ordinal 11 exclude producer/aggregate drift. T1793 rejects semantic, topology, shape, order, and foreign-profile changes; t1786 rejects adjacent semantics before timing.
- **Durability:** retain both leaves, sealed seams, comparator, tests, synchronized surfaces, and Git; the next real gate proves production admission.

Lifecycle bodies stay authenticated; only derived summaries leave cross-run equality. No capability claim is added. Rollback restores raw-only equality and its known false rejection without editing evidence.
