# IAL2 Post-Direct-Arbitration Next-Owner Selection

Task-tree owner: `IAL2-FEATURE-COMPLETENESS-FRONTIER.816`

Date: 2026-07-29

## Outcome

Select proposed
`IAL2-AHB-EXACT-THREE-PAIRED-BUSY-COMPOSITION-READINESS-AUDIT.1` as the next
exact IAL2 owner after direct IAL0 AHB subordinate arbitration completed at
clean assertion-enabled behavior commit `35a6fbfcf`.

The selected leaf is a no-public-behavior readiness audit for the smallest
generic, one-subordinate composition. It remains proposed until this selector
commits cleanly and then receives a separate activation commit. This selector
does not modify parser, generator, public source, support, test, checked-in
artifact, semantic/MCP API, HDL/runtime, backend, protocol, verification
generation, HIAL/VIAL, or transaction-layer behavior.

## Evidence

The prior interconnect, generated-subordinate, and direct-seed arbitration
trees have removed the complete known `--no-assert` boundary from the audited
base/rich direct and one-/two-window paired AHB family. Existing regressions
therefore provide assertion-enabled ownership beneath the next composition:

- t1528 proves the standalone generic exact-three requester retires remaining
  count `3 -> 2 -> 1 -> 0` under continuous-ready, 32-clock ready-low, and
  32-clock grant-low scenarios;
- t1523 and t1525 prove the generic one-/two-subordinate exact-two paired
  sources, while their focused alias tests preserve source/report/artifact and
  semantic/MCP parity;
- t1530, t1519, the paired family, and t1520 now keep generated selector
  assertions enabled across fabric, generated endpoint, and direct seed; and
- current support accounting is 322 protocol paths, 363 supported+strict
  paths, and 46 AHB paths split 23 `.ppif` / 23 `.ahb`.

No public exact-three paired source or task tree existed. Historical selectors
explicitly deferred it first behind fabric, then generated-endpoint, then
direct-seed ownership repair. Those prerequisites are now complete.

## Disposable Feasibility Boundary

A repository-derived same-volume candidate used the future generic source
identity
`ahb_interconnect_requester_busy_insert_three_byte_lane_hburst_seq_busy_park`
with existing requester `amba_requester_busy_insert_three`, subordinate
`ahb_lite_subordinate_byte_lane_hburst_seq`, fabric `ahb_interconnect`, and top
`ahb_tb`.

The unchanged public lowering path emitted exactly three IAL1 artifacts and
four IAL0 artifacts. Its exact-three actor retained the shipped width-two
remaining counter and `3 -> 2 -> 1 -> 0` rules. Verilator compiled the aggregate
without `--no-assert`; every generated selector assertion remained enabled.
The executable passed the exact runtime contract:

```text
PASS transfers=5 beats=4 busy=1 qualified_busy=3 resumed_seq=1 storage=44332211
```

The canonical guard used `--host-max-pct 100 --process-max-rss-mb 4096`.
The disposable workspace contained 54 files / 53,577,454 bytes and was removed
exactly; residue is absent. This is feasibility evidence, not a shipped source,
support claim, semantic/MCP claim, or implementation decision. The selected
audit must re-establish and freeze those public boundaries before behavior.

After closeout gates, the exact Stats-compatible Mach calculation reported
49.8% capacity (11.94/24.00 GiB) and
`kern.memorystatus_vm_pressure_level=1` (normal). The guard's separate 71.6%
occupancy observation was not used as capacity truth.

## Candidate Comparison

### Selected: generic one-subordinate exact-three paired readiness

This is the smallest adjacent public-capability question because all three
children, the exact-three counter contract, the exact-two paired topology, and
their assertion-enabled lower layers already ship. The disposable run proves
the runtime shape is viable while leaving exact public identity, support,
semantic/MCP, diagnostics, preservation, and rollback to the audit.

### Deferred: aliases and two-subordinate exact-three composition

The existing cadence treats generic implementation, matching `.ahb` alias,
and the larger two-window topology as separate slices. Selecting all three at
once would enlarge both support accounting and regression ownership beyond the
smallest evidence-backed owner.

### Deferred: counts above three, policy, status, bursts, and signals

Counts above three require a separately selected public range and storage-width
contract. Runtime/policy/multiple-point BUSY insertion, distinct local
bus-BUSY status, wider or indefinite bursts, and optional AHB signals introduce
orthogonal semantics not required by the passing exact-three composition.

### Deferred: generic priority and other protocol/platform work

Generic selector-priority enforcement is not required now that audited AHB
owners are mutually exclusive and assertion-clean. No evidence selects an AXI,
APB, other protocol, direct-backend, or backend-language prerequisite ahead of
the smaller adjacent AHB composition.

### Deferred: HIAL/VIAL and decision 0020

`HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE` continues to own the director's
peer hardware/verification intent model, including HIAL synthesizable SV/VHDL
and pure-verification VIAL SV/UVM or VHDL lowering. It remains
proposed/inactive and is not changed by ordinary IAL2 PNT. Decision 0020 also
remains director-owned and inactive.

## Selected Audit Boundary

After this selector commits cleanly, activate only
`IAL2-AHB-EXACT-THREE-PAIRED-BUSY-COMPOSITION-READINESS-AUDIT.1`. It must:

- reconcile the standalone exact-three requester, exact-two paired lineage,
  assertion-clean lower layers, reports/residue, and all current public docs;
- use a repo-local disposable generic one-subordinate candidate to prove strict
  check, schedule, exact review artifacts, assertion-enabled generated HDL, and
  the 5/4/1/3/1/`44332211` runtime boundary;
- audit normalized semantic JSON and real read-only
  `fsmgen_semantic_introspect` parity without adding a feature-specific API or
  exposing raw internals;
- freeze the future source/object/anchor/support/test identities, projected
  323/364/47 accounting split 24 `.ppif` / 23 `.ahb`, diagnostics,
  preservation, residue, cleanup, rollback, and next contract owner only if
  the evidence supports direct implementation;
- keep aliases and the two-subordinate exact-three topology separately owned;
  and
- report Stats-compatible RAM capacity independently from kernel pressure,
  while using the authorized host100/process4096 guard and same-volume
  disposable storage.

## Rollback

Before child activation, rollback removes this selector record/fact and the
proposed child task tree, then restores `.816` as active. After child
activation, rollback follows the child task tree and keeps readiness evidence
separate from any future public contract or implementation.
