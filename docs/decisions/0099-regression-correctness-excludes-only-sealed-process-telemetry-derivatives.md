# Decision 0099: Exclude only sealed process-telemetry derivatives from regression correctness

- **Status:** Accepted
- **Date:** 2026-09-03
- **Owner:** `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.5.4.4.1` + `.2.1` + `.2.2.1`
- **Refines:** [0097](0097-regression-gates-publish-replaceable-observations-without-recalibrating.md)

## Context

Clean gates failed ordinal 10 (4 x 29 fields/165,285-byte projections), 8
(4 x 24/77,952), and 9 (4 x 29/81,709). Only lifecycle evidence/handle digests,
evidence sizes, oracle identities, and stage byte totals changed; ordinal 11 passed.

GHDL/OSVVM, portable-Verilator, and portable-VHDL/GHDL lifecycle evidence embed
fresh process timing; portable emit precedes capture and stays exact. History
from capture `155aa22ea` found no relevant producer change, so recalibration
would only freeze new timing.

## Decision

1. Raw identity remains the fast path; fallback runs only after mismatch.
2. Caller-sealed seams authenticate both projections and every qualification coordinate.
3. Only exact runtime-stream/gate-candidate/runtime-records pairs normalize: OSVVM + `vhdl_osvvm_qualified`, portable + `sv_portable_verilator`, and portable VHDL + `vhdl_portable_ghdl`; eight profiles stay byte-exact.
4. OSVVM and portable VHDL replace 29 per-record derivatives across compile/elaborate/run/trace/result/publish; portable Verilator replaces 24 across compile/run/trace/result/publish. Portable VHDL's distinct publish kind is explicit. Scalar/digest shape, count, kind, order, and uniqueness remain exact.
5. All else compares canonically before performance; success retains the qualified identity. Evidence, qualification, budgets, providers, environment, and publication do not change.

## Rejected alternatives

Recalibration preserves the defect; producer changes are broader; general normalization hides semantics; a fresh identity contradicts qualified admission.

## Verification and consequences

- **Re-derive:** task evidence records all three comparisons; t1793 reconstructs the 116/96/116 partitions.
- **Falsify:** history and ordinal 11 exclude producer/aggregate drift. T1793 rejects semantic, topology, shape, order, and foreign-profile changes; t1786 rejects adjacent semantics before timing.
- **Durability:** retain all repair leaves, sealed seams, comparator, tests, synchronized surfaces, and Git. Clean `ef59330ab` passed eleven pinned profiles and published `c7787a02...02f2`; task `.17.5.4.4.2.2.2` retains independent joins and residue census.

Lifecycle bodies stay authenticated; only derived summaries leave cross-run equality. No capability claim is added. Rollback restores raw-only equality and its known false rejection without editing evidence.
