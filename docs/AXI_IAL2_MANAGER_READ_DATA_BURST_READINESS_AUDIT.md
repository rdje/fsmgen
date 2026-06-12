# AXI IAL2 Manager Read Data/Burst Readiness Audit

Status: readiness audit complete; no parser/generator/HDL behavior changes in
this slice.

Owner: `IAL2-FEATURE-COMPLETENESS-FRONTIER.43`.

Task tree:
[docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md](tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md).

This audit follows the post-read-demux selector:
[docs/AXI_IAL2_MANAGER_POST_READ_DEMUX_NEXT_SLICE_SELECTION.md](AXI_IAL2_MANAGER_POST_READ_DEMUX_NEXT_SLICE_SELECTION.md).

## Conclusion

Do not implement read-data payload, burst/`RLAST`, or per-ID reassembly
behavior directly in the next slice. The next slice must first select the
public contract.

The selected next owner is:

```text
IAL2-FEATURE-COMPLETENESS-FRONTIER.44
```

`IAL2-FEATURE-COMPLETENESS-FRONTIER.44` must select the bounded public
read-data payload contract before parser/report metadata or generated behavior
changes. The likely first scope is single-beat read-data payload/status
capture layered on the already-shipped generated read `RID` response demux.
Burst/`RLAST`, different-ID interleaving/reassembly, per-ID queues, full
manager behavior, queued/blocking policy, direct backend lowering, and VHDL
remain residue unless that selector explicitly owns a smaller part.

## Evidence Read

- `docs/AXI_IAL2_MANAGER_READ_RESPONSE_DEMUX_BEHAVIOR_FIRST_SLICE.md`
- `docs/AXI_IAL2_MANAGER_POST_READ_DEMUX_NEXT_SLICE_SELECTION.md`
- `docs/AXI_ID_ORDERING_RULE_EVIDENCE_PROBE.md`
- `docs/AXI_MANAGER_RULE_MATRIX_DESIGN_PROBE.md`
- `docs/book/src/13a-actor-interface.md`
- `docs/book/src/13g-rules.md`
- `perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm`
- `perl/FSM/Adapter/IAL2/PPIF.pm`
- `ppif/axi_manager_capacity_status_read_response_demux.ppif`

The post-`.41` read sample reports generated read `RID` response demux with
only these response-demux residues:

```text
read_data_interleaving
bursts
```

The same-ID report still carries:

```text
concrete_id_same_id_ordering
per_id_issue_order_queues
read_data_interleaving
bursts
```

The AXI evidence says read data must match `ARID` through `RID`, different ID
values may interleave, same-ID read responses are ordered, and subordinate
read-data reordering depth is a design-time/environment property rather than
something a manager can discover dynamically.

## Substrate Assessment

The existing `IAL2 -> IAL1 -> IAL0 -> SystemVerilog` substrate can likely carry
a bounded single-beat payload/status subset after a public contract is
selected:

- IAL1 already supports width-bearing inputs, outputs, and variables.
- IAL1 rules already assign width-bearing targets from width-bearing sources.
- Generated read response demux already provides per-transaction completion
  pulses keyed by `RID` and selected-ID state.
- Existing capacity and auto-ID lifecycle rules already consume generated
  transaction completion pulses.

No new substrate prerequisite is selected for the likely single-beat payload
capture shape. The blocker is public contract precision: FSMGen has not yet
selected source syntax, report keys, target binding semantics, or residue
movement for read data, response status, `RLAST`, burst completion, or
interleaving policy.

## Contract Questions For `.44`

The next selector must decide:

- whether the first public source shape is a new clause under
  `manager-capacity-status`, a read arm extension under `response-demux`, or a
  separate read-data clause;
- whether it owns only single-beat `RDATA`/`RRESP` capture or also observes
  `RLAST`;
- whether logical transaction completion remains the generated demux pulse or
  becomes last-beat completion for a burst-aware future contract;
- whether read-data destinations are generated outputs, generated storage,
  report-only structural bindings, or a combination;
- whether interleaving is explicitly unsupported/fail-closed in the first
  data slice or represented as a static capability/assumption;
- how read-data and response-status artifacts are reported per transaction;
- what diagnostics are emitted for missing read response-demux, missing
  positive read ID family, unsupported burst/interleaving fields, width
  mismatches, duplicate data targets, and target/name collisions.

## Explicit Deferrals

The audit does not select behavior for:

- burst or multi-beat assembly;
- `RLAST`-driven completion;
- different-ID read-data reassembly queues;
- same-ID concrete-ID issue-order queues;
- subordinate read-data reordering-depth modeling;
- chunking, atomics, exclusives, or broader B3 transaction classes;
- queued/blocking policy;
- profile aliases or full AXI manager syntax;
- direct backend lowering;
- VHDL.

## Validation Expectations For The Later Implementation

After `.44` selects the public contract, a behavior slice should prove at
least:

- focused generator tests for generated `RDATA`/`RRESP` inputs and
  transaction-bound output/storage updates;
- PPIF parser/CLI tests for accepted syntax and fail-closed diagnostics;
- schedule JSON/report checks for data bindings, unsupported residue, and
  generated artifacts;
- normalized semantic JSON coverage for the checked-in sample;
- `--verify-hdl` on the public read-data sample;
- mdBook examples documenting the source, report, generated IAL1/IAL0 shape,
  HDL reachability, and explicit residue.

## Rollback

This `.43` slice changes only documentation, task-tree, mdBook, roadmap,
Memory, and Knowledge Map state. Rolling it back returns the active frontier
to the post-read-demux readiness audit and leaves shipped generated read
response-demux behavior unchanged.
