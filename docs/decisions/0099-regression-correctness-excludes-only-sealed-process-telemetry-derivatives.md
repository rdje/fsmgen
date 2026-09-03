# Decision 0099: Exclude only sealed process-telemetry derivatives from regression correctness

- **Status:** Accepted
- **Date:** 2026-09-03
- **Owner:** `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.5.4.4.1`
- **Refines:** [0097](0097-regression-gates-publish-replaceable-observations-without-recalibrating.md)

## Context

The first clean exact-pinned gate reproducibly failed ordinal 10 correctness; isolated ordinal 11 passed. Ordinal 10's fresh and qualified projections were each 165,285 bytes and differed in 116 scalars (29 in each of four records): lifecycle evidence/handle digests, evidence byte sizes, oracle evidence identities, and stage output-byte totals. All other fields agreed.

GHDL/OSVVM evidence embeds fresh monotonic process timings, so derived sizes, hashes, and identities vary. History from capture `155aa22ea3099642eb6b7f5de81ea03633e72bcb` showed no producer drift; recalibration would freeze another timestamp set.

## Decision

1. Raw correctness identity remains every profile's fast path; fallback runs only after mismatch.
2. Caller-sealed Qualification and GateContract seams authenticate both full projections, raw identities, qualification/publication/file-set, ordinal, and selection.
3. Normalization is confined to `runtime_stream_v1` / `gate_candidate_v1` / `runtime_trace_records` / `vhdl_osvvm_qualified`; all other profiles stay byte-exact.
4. It replaces only those 29 telemetry-derived scalars per record. Exact counts, kinds, order, and uniqueness are mandatory; topology drift rejects.
5. All else compares canonically before performance. Success retains the qualified identity; no schema, evidence, qualification, budget, provider, environment, or publication rule changes.

## Rejected alternatives

Recalibration preserves the defect. Removing telemetry changes a broader contract; broader normalization hides semantics; publishing the fresh identity contradicts qualified admission.

## Verification and consequences

- **Re-derive:** task evidence records both sizes/identities and the 4 x 29 partition; t1793 reconstructs all 116 mutations from tracked evidence.
- **Falsify:** ordinal 11 and history exclude aggregate/timing and producer drift. T1793 rejects semantic mutation, hostile topology, and non-OSVVM normalization; t1786 rejects adjacent semantics before timing.
- **Durability:** retain the evidence, sealed seams, comparator, tests, synchronized docs/doctrines, and commit; the next real gate proves admission and residue.

Lifecycle bodies remain authenticated; only telemetry-derived summaries leave cross-run equality. Corpus/qualification, workloads, budgets, providers, publication, and cleanup are unchanged. No capability claim is added. Rollback restores raw-only equality and the known false rejection without editing evidence.
