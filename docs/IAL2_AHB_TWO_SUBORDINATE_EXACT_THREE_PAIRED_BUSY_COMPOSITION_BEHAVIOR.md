# IAL2 AHB Two-Subordinate Exact-Three Paired BUSY Composition Behavior

Task-tree owner:
`IAL2-AHB-TWO-SUBORDINATE-EXACT-THREE-PAIRED-BUSY-COMPOSITION-READINESS-AUDIT.3`

Date: 2026-07-29

## Shipped Public Source

FSMGen now ships the generic source:

```text
ppif/ahb_interconnect_two_subordinate_requester_busy_insert_three_byte_lane_hburst_seq_busy_park.ppif
```

It is the exact data-only extension of the shipped two-window exact-two source.
Only intent/object/anchor identity, requester actor, `(busy-beats 3)`, and the
requester child reference differ. Existing PPIF parsing and AHB generators
lower it through four IAL1 actors, five IAL0 artifacts, and top `ahb_tb`.

No parser, generator algorithm, report schema, semantic/MCP API, existing
source byte, backend, protocol, verification-generation, HIAL/VIAL, VHDL, or
transaction-layer behavior changes.

## Support Identity

```text
id:
  intent.ppif_ahb_interconnect_two_subordinate_requester_busy_insert_three_byte_lane_hburst_seq_busy_park
coverage:
  ial2_ppif_ahb_interconnect_two_subordinate_requester_busy_insert_three_byte_lane_hburst_seq_busy_park_pipeline_cli
source kind:    ppif
classification: supported_smoke
strict:         true
module:         ahb_tb
semantic root:  top
children:       4
```

Current accounting is 325 protocol fixtures, 366 supported-smoke fixtures,
366 strict-supported fixtures, and 49 AHB IAL2 paths split 25 generic `.ppif`
sources / 24 `.ahb` aliases.

## Generated Architecture

```text
IAL1:
  amba_requester_busy_insert_three.isf
  ahb_status_subordinate_byte_lane_hburst_seq.isf
  ahb_control_subordinate_byte_lane_hburst_seq.isf
  ahb_interconnect.isf

IAL0:
  amba_requester_busy_insert_three.fsm
  ahb_status_subordinate_byte_lane_hburst_seq.fsm
  ahb_control_subordinate_byte_lane_hburst_seq.fsm
  ahb_interconnect.fsm
  ahb_tb.fsm
```

The two mapped windows remain status `[0,4)` and control `[4,8)`. Response
ownership remains `one_hot_accepted_subordinate`, captured on an accepted
active address, retired on the retained owner's ready-out, and replaced on a
same-edge completion plus accepted active address.

The requester report exposes `before_beat=2` and `beats=3`. Its width-two
`ahb_busy_remaining_q` loads three, decrements at ready-qualified BUSY events,
clears at one, and resumes pending `SEQ`, giving `3 -> 2 -> 1 -> 0`. Both
subordinates and aggregate propagation report `parks_on=[busy]`; no duplicate
top-level `busy_flow` is added.

## Semantic And MCP Behavior

Strict check reports zero diagnostics, module `ahb_tb`, four children, 29 top
signals, zero top-local states, and the exact support identity. Normalized
semantic JSON reports root `top`, the same module/children/support facts, and
the existing schema. Real `fsmgen_semantic_introspect` accepts the repo-relative
source, returns the same report, and retains:

```text
query_kind:   semantic
read_only:    true
shell_access: false
```

Public `--verify-hdl` passes. No feature-specific MCP tool or private lowering
payload is introduced.

## Assertion-Enabled Runtime

t1533 compiles generated `ahb_tb` with Verilator `--timing` and every selector
assertion enabled. It issues one status and one control byte `INCR4` command.
Each command presents:

```text
NONSEQ(0) -> SEQ(1) -> BUSY(2 held for three qualified events)
          -> SEQ(2 resumed once) -> SEQ(3)
```

The harness proves requester address/control/data and counters remain stable
through BUSY, selected subordinate continuation/phase/storage stays parked,
the unselected subordinate does not change, fabric owner bits remain stable,
BUSY completes no beat, and completion is clean. Observed result:

```text
PASS commands=2 transfers=10 beats=8 busy=2 qualified_busy=6 resumed_seq=2 status=44332211 control=88776655
```

This is a supported-event compiled-model proof. It does not claim full
event-driven SystemVerilog/UVM language coverage from Verilator; that remains a
separate HIAL/VIAL simulator-qualification profile.

## Validation And Deferrals

t1533 passes 3 top-level / 83 nested assertions, covering exact source delta,
strict/check/support, schedule/report/residue, exact artifacts, normalized
semantic JSON, real read-only MCP, repository-local output, public
`--verify-hdl`, and assertion-enabled runtime. t248 plus t297 pass 2 files /
6,947 tests at the exact 325/366/49 checkpoint.

The matching `.ahb` alias, counts above three, counter-width generalization,
runtime/policy/random/multiple-point BUSY insertion, distinct bus-BUSY status,
larger/indefinite bursts, optional signals, queues/outstanding transfers,
broader fabrics/managers, generic priority changes, other protocols/backends,
HIAL/VIAL activation, verification-output generation, VHDL, and decision
`0020` remain separate.

## Rollback

Remove the new `.ppif`, RegressionCorpus entry, t1533/harness, behavior
record/fact, and exact documentation/accounting updates. Restore 324/365/48
split 24/24. Existing sources and generator behavior remain intact.
