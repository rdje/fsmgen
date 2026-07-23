# IAL2 AHB Pipelined Active-Transfer Runtime Audit

Task-tree owner: `IAL2-AHB-PIPELINED-ACTIVE-TRANSFER-AUDIT.1`

Date: 2026-07-23

## Outcome

Generated-HDL audit t/1519 proves that the current public AHB subordinate can
silently drop a distinct selected `SEQ` address phase that follows a completed
`NONSEQ` phase without an unselected, `IDLE`, or `BUSY` boundary.

The bus observes two accepted active address phases, but the generated
subordinate records only one internal admission and one internal completion:

```text
bus_accepts=2
internal_admits=1
internal_completions=1
captured_addr=0
captured_trans=NONSEQ
storage=0x00000011
```

The required second lane-one write would have produced `0x00002211`. It does
not occur. The audit changes no generator, public source, support entry,
report, artifact contract, port, or runtime behavior. It selects explicit
completion-boundary phase recapture/tracking for contract selection in
`IAL2-AHB-PIPELINED-ACTIVE-TRANSFER-AUDIT.2`.

## Probe Shape

The focused audit generates SystemVerilog from the shipped public source:

```text
ppif/ahb_lite_subordinate_byte_lane_hburst_seq_busy_park.ppif
```

The Verilator harness connects the single subordinate's combined ready input
to `HREADYOUT` and presents this legal two-phase stream:

```text
NONSEQ address 0, INCR4 byte write
SEQ    address 1, INCR4 byte write
IDLE
```

The second address phase is presented immediately after the first is accepted
and remains stable while `HREADY/HREADYOUT` is low. Thus it is not a duplicate
sample of the held first phase: it has a distinct address and `HTRANS=SEQ`.
The harness counts ready-low cycles, requires the second acceptance to follow
the first, requires `HRESP` to remain OKAY, records the generated ownership and
sample registers, counts the delayed internal completion pulse, and inspects
final storage.

## Generated-State Root Cause

The generated IAL1 admits and samples only while phase ownership is clear:

```text
!ahb_access_active_q && HSEL && HREADY &&
HTRANS in {NONSEQ, SEQ}
```

Admission sets `ahb_access_active_q=1` and `HREADYOUT=0`. The only release
condition is:

```text
ahb_access_active_q &&
(!HSEL || HTRANS == IDLE || HTRANS == BUSY)
```

Generated IAL0 preserves those as separate `-ahb_access_admit` and
`-ahb_access_release` owner blocks. When the first data phase later raises
`HREADYOUT`, the next selected `SEQ` address phase is accepted by the bus. Its
address/control values are not sampled because `ahb_access_active_q` remains
set. The public interface nevertheless presents an OKAY/ready completion, so
the loss is neither an explicit error nor a visible stall.

This ownership state was introduced for a valid reason: it prevents repeated
admission of one active address phase held during a wait state. The defect is
that the state does not distinguish that held phase from a new phase accepted
on the completion boundary.

## Why Boundary Insertion Or Fail-Closed Handling Is Insufficient

The shipped generated requester supplies an `IDLE`/`BUSY` boundary, so the
paired t/1513 and t/1515 proofs remain valid for that bounded composition.
Requester-only boundary insertion cannot protect the public subordinate from
another conforming AHB requester.

An endpoint-only rule that waits for the requester to insert a boundary is not
a safe fail-closed contract. While the next active address phase is held under
`HREADYOUT=0`, the requester must keep it stable. If the subordinate never
raises ready, the current data phase cannot complete and the interface
deadlocks. If it raises ready, that same completion boundary accepts the held
next address phase. Merely clearing ownership later also misses that acceptance
edge.

The bounded repair direction therefore needs an atomic completion-boundary
recapture path: complete the current data phase, capture the distinct next
address/control phase on the same accepted-ready boundary, and relaunch it
exactly once. `.1` does not choose the internal encoding or implement it.

## Selected Follow-On Contract Boundary

`IAL2-AHB-PIPELINED-ACTIVE-TRANSFER-AUDIT.2` must select, without behavior
changes, the smallest explicit one-next-phase contract. It must freeze:

- the precise generated event that means the current data phase completed and
  a new active address phase was accepted;
- atomic sampling of `HADDR`, `HTRANS`, `HBURST`, `HWRITE`, `HSIZE`, and
  `wait_cycles` for the new phase while current data-phase `HWDATA` remains
  correctly owned;
- held-phase suppression versus accepted-phase recapture;
- ready/response timing, success/error completion, `SEQ` policy continuity,
  and one internal completion per bus acceptance;
- compatibility with boundary-bearing requester, BUSY parking, WRAP repair,
  one-/two-subordinate aggregates and aliases; and
- exact implementation and generated-HDL regression owners in later leaves.

This is a depth-one phase-recapture boundary, not a general outstanding queue,
multi-manager fabric, or decision-0020 transaction-layer implementation.

## Verification And Resources

Focused t/1519 proves the generated IAL1/IAL0 predicates and the generated-HDL
runtime result. The clean evidence rerun passes two top-level subtests. During
the run, direct `memory_pressure -Q` reported 78% memory free and the observed
generator RSS remained below 1.5 GiB, inside the 4-GiB descendant limit.

Preservation remains owned by the existing subordinate, BUSY, paired, alias,
truth-surface, and WRAP tests. The audit adds no support-accounting entry and
does not alter decision 0020 or its proposed transaction-layer horizon.

## Rollback

Rollback removes t/1519, its testbench, this record/fact, and the `.2`
selection, then restores the audit tree to proposed status. It does not repair
the runtime defect. Any later repair rollback must restore generator behavior,
direct/generated evidence, task state, and user-facing documentation together;
it must not leave a ready/OKAY path that silently drops an accepted phase.
