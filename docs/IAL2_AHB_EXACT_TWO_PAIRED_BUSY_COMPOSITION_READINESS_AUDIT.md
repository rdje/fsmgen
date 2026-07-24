# IAL2 AHB Exact-Two Paired BUSY Composition Readiness Audit

Task-tree owner:
`IAL2-AHB-EXACT-TWO-PAIRED-BUSY-COMPOSITION-READINESS-AUDIT.1`

Date: 2026-07-24

## Outcome

The shipped exact-two requester and shipped one-subordinate HBURST-aware
byte-lane BUSY-parking aggregate compose correctly through the existing
`IAL2 -> IAL1 -> IAL0 -> SystemVerilog` pipeline. A disposable generated-HDL
proof observes one BUSY episode containing exactly two grant-and-ready-
qualified BUSY events, one resumed pending `SEQ`, four completed byte data
beats, clean status, and final storage `32'h44332211`.

No parser, requester, subordinate, interconnect, composition-top, scheduler,
semantic-introspection, MCP-adapter, or HDL substrate repair is required before
public contract selection. The audit therefore selects
`IAL2-AHB-EXACT-TWO-PAIRED-BUSY-COMPOSITION-READINESS-AUDIT.2`, a separate
no-behavior leaf that must freeze the first generic public source contract
before implementation.

This audit ships no public source, name, syntax, support entry, test, report,
artifact, semantic/MCP API, HDL/runtime behavior, backend, protocol, or
transaction-layer behavior.

## Evidence Boundary

The audit reconciled:

- the exact-one paired generic/alias source family, behavior records, and
  t/1513-t/1516 runtime/parity owners;
- the exact-two requester generic/alias source family, behavior records, and
  t/1521-t/1522 runtime/semantic/MCP owners;
- the PPIF adapter and `AhbRequester`, `AhbSubordinate`, and `AhbInterconnect`
  lowering paths;
- generated requester pending state, subordinate phase/SEQ continuation, and
  interconnect one-hot data-phase ownership;
- support/language/capability, schedule, normalized semantic JSON, and current
  read-only MCP boundaries;
- README, roadmap, mdBook, task trees, Memory, Knowledge Map, and relevant
  decisions; and
- proposed interconnect-selector repair and decision 0020, neither of which is
  activated or absorbed by this work.

## Disposable Candidate

The candidate was derived from the shipped one-subordinate exact-one paired
source without choosing a future public identity. Its only semantic changes
were:

1. embedded requester object `amba_requester_busy_insert` became
   `amba_requester_busy_insert_two`;
2. requester transfer added `(busy-beats 2)` beside
   `(busy-before-beat 2)`; and
3. the aggregate requester child reference selected
   `amba_requester_busy_insert_two`.

Existing lowering produced:

```text
schema:       fsmgen.ial2.protocol_intent.ahb_interconnect.v1
children:     3
HDL module:   ahb_tb

IAL1:
  amba_requester_busy_insert_two.isf
  ahb_lite_subordinate_byte_lane_hburst_seq.isf
  ahb_interconnect.isf

IAL0:
  amba_requester_busy_insert_two.fsm
  ahb_lite_subordinate_byte_lane_hburst_seq.fsm
  ahb_interconnect.fsm
  ahb_tb.fsm
```

The requester child reports `busy_insertion.before_beat=2` and numeric
`busy_insertion.beats=2`. The subordinate child and aggregate propagation both
report `parks_on=[busy]`. This is reuse of the current generators and composed
top, not a new generator architecture.

## Generated-HDL Runtime Proof

The generated `ahb_tb` was compiled with Verilator using the existing paired
`--no-assert` boundary. The harness drove one zero-base byte `INCR4` write with
`cmd_wdata=32'h11111111`, `cmd_wdata_step=32'h11111111`, and zero subordinate
wait cycles.

The harness checked all of the following through the complete BUSY episode:

- presentation order remained
  `NONSEQ(0) -> SEQ(1) -> BUSY(2 held) -> SEQ(2 resumed) -> SEQ(3)`;
- the BUSY transition episode contained two, and only two,
  `HGRANT && HREADY && HTRANS==BUSY` events;
- requester pending address, write, size, burst, protection, write data,
  `beat_index`, and `beats_remaining` stayed stable;
- requester `ahb_busy_remaining_q` was two at the first qualified event, one
  at the second, and zero at resumed `SEQ`;
- subordinate `seq_valid_q`, expected address, remaining SEQ count,
  `ahb_phase_pending_q`, and register storage stayed stable;
- interconnect `ahb_data_owner_0_q` stayed stable;
- BUSY caused no requester data-beat completion;
- the pending transfer resumed as `SEQ` exactly once;
- exactly four byte data beats completed, remaining count reached zero, and
  response/error/retry/split status was clean; and
- final subordinate storage was `32'h44332211`.

Observed result:

```text
PASS transfers=5 beats=4 busy=1 qualified_busy=2 resumed_seq=1 storage=44332211
```

The current public preservation owners also pass together under the 4-GiB
descendant-RSS cap:

```text
t/1513-ial2-ahb-paired-busy-composition.t
t/1521-ial2-ahb-requester-two-busy-insert.t
Files=2, Tests=9, Result=PASS
```

t/1521 remains assertion-enabled and authoritative for exact-two requester
selector safety. The paired aggregate keeps `--no-assert` because the existing
interconnect default/decode output-selector overlap is separately task-tree
owned; the runtime checks above do not hide or reclassify that boundary.

## Readiness Decision

The result selects public contract work, not a repair or deferral. Leaf `.2`
must freeze:

- one generic `.ppif` source before any matching `.ahb` alias;
- exact intent/source-object/support/coverage/test identities;
- reuse of the three-child `ahb_tb` architecture and exact artifact set;
- numeric requester-child `busy_insertion.beats=2` and subordinate plus
  aggregate `parks_on=[busy]` reporting;
- a generated-HDL proof with exactly the runtime invariants above;
- strict check, schedule, normalized semantic JSON, and clean read-only
  `fsmgen_semantic_introspect` MCP exposure through the existing stable API;
- preservation of base, exact-one paired, standalone exact-two, alias, and
  two-subordinate exact-one behavior;
- support-accounting, diagnostics, mdBook, Knowledge Map, resource, and
  rollback gates; and
- separate deferral of the exact-two two-subordinate sibling.

No feature-specific semantic API, raw private lowering payload, or second
generator is selected.

## Deferrals

The matching `.ahb` alias, exact-two two-subordinate composition, counts beyond
two, generalized count width, runtime/policy/random insertion, multiple
insertion points, distinct local bus-BUSY status, larger or indefinite bursts,
optional signals, queues/outstanding transfers, managers, broader fabrics,
interconnect selector repair, AXI/APB expansion, backend variants, VHDL, and
decision 0020 remain separate task-tree-owned work.

## Rollback

Revert this audit record/fact and the `.1` completion/`.2` selection pointers.
The disposable candidate and generated artifacts live outside the repository;
no shipped behavior needs rollback.
