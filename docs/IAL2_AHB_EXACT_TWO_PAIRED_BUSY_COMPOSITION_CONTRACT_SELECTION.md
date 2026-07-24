# IAL2 AHB Exact-Two Paired BUSY Composition Contract Selection

Task-tree owner:
`IAL2-AHB-EXACT-TWO-PAIRED-BUSY-COMPOSITION-READINESS-AUDIT.2`

Date: 2026-07-24

## Outcome

Select one additive generic public source:

```text
ppif/ahb_interconnect_requester_busy_insert_two_byte_lane_hburst_seq_busy_park.ppif
```

It composes the shipped exact-two requester with the shipped one-subordinate
HBURST-aware byte-lane BUSY-parking endpoint through the existing three-child
`ahb_tb` architecture. The implementation owner is proposed leaf
`IAL2-AHB-EXACT-TWO-PAIRED-BUSY-COMPOSITION-READINESS-AUDIT.3`.

This contract selection changes no parser, generator, public source, support
catalog, test, report, artifact, semantic/MCP API, HDL/runtime behavior,
backend, protocol, or transaction-layer behavior.

## Public Identity

The selected identities are:

```text
source:
  ppif/ahb_interconnect_requester_busy_insert_two_byte_lane_hburst_seq_busy_park.ppif

intent:
  ahb_interconnect_requester_busy_insert_two_byte_lane_hburst_seq_busy_park

source object:
  fsmgen-ahb-interconnect-requester-busy-insert-two-byte-lane-hburst-seq-busy-park

anchor:
  document = ARM-AMBA-AHB-IHI0033-C-2021-09
  section  = bounded-ahb-interconnect-requester-busy-insert-two-byte-lane-hburst-seq-busy-park
  page     = first-public-contract

requester actor:
  amba_requester_busy_insert_two

support entry:
  intent.ppif_ahb_interconnect_requester_busy_insert_two_byte_lane_hburst_seq_busy_park

coverage key:
  ial2_ppif_ahb_interconnect_requester_busy_insert_two_byte_lane_hburst_seq_busy_park_pipeline_cli

source kind:
  ppif

HDL module / semantic root:
  ahb_tb / top
```

The long name is intentional: it distinguishes exact-two requester BUSY
cardinality from the already-shipped exact-one paired source and from the
already-shipped exact-one two-subordinate topology. It does not imply a second
generator.

## Source Contract

The new source is derived from
`ppif/ahb_interconnect_requester_busy_insert_byte_lane_hburst_seq_busy_park.ppif`.
Only these data fields change:

1. source/intent/anchor identity gains `busy-insert-two`;
2. embedded requester object becomes `amba_requester_busy_insert_two`;
3. requester transfer adds `(busy-beats 2)` beside
   `(busy-before-beat 2)`; and
4. the aggregate requester child selects
   `amba_requester_busy_insert_two`.

All command/status ports, bus bindings, burst encodings, response actions,
subordinate storage/transfer policy, zero-base four-byte address window,
decode, interconnect wiring, clock, and reset remain byte-for-byte equivalent
to the corresponding exact-one paired clauses.

The generic source ships first. A matching `.ahb` alias is a separate later
contract and implementation so suffix-specific residue, accounting, and parity
remain independently reviewable.

## Generated Architecture And Reports

The implementation must use the existing PPIF adapter plus `AhbRequester`,
`AhbSubordinate`, and `AhbInterconnect` generators. It must emit exactly:

```text
IAL1:
  amba_requester_busy_insert_two.isf
  ahb_lite_subordinate_byte_lane_hburst_seq.isf
  ahb_interconnect.isf

IAL0:
  amba_requester_busy_insert_two.fsm
  ahb_lite_subordinate_byte_lane_hburst_seq.fsm
  ahb_interconnect.fsm
  ahb_tb.fsm

HDL entry/module:
  ahb_tb.fsm / ahb_tb
```

The aggregate report contract is additive through source selection, not a new
schema:

```text
schema                                      = fsmgen.ial2.protocol_intent.ahb_interconnect.v1
composition.child_instance_count            = 3
children[requester].object_name              = amba_requester_busy_insert_two
children[requester].busy_insertion.before_beat = 2
children[requester].busy_insertion.beats     = 2
children[subordinate].transfer.seq_policy.parks_on = [busy]
composition.seq_policy_propagation...parks_on      = [busy]
```

No duplicate composition-level `busy_flow` summary is selected. The requester
child owns insertion cardinality; the subordinate child plus composition
propagation own parking. Existing top, interconnect, and subordinate residue
remains structurally unchanged. The requester child keeps its exact-two
`ahb_requester_busy_insert_support` detail, including counts/policy/points
beyond the selected behavior. The generic aggregate keeps its existing
profile-alias residue until a later alias slice.

## Semantic Introspection And MCP Contract

The new support-accounted source must be visible through every existing bounded
read-only semantic surface in the same implementation slice:

- strict check JSON reports the exact support identity, `ahb_tb`, and three
  composition children;
- schedule JSON exposes numeric requester-child `busy_insertion.beats=2`, the
  exact generated artifacts, and subordinate/propagated `parks_on=[busy]`;
- normalized semantic JSON reports module `ahb_tb`, source root `top`, support
  identity, and three semantic composition children; and
- real `fsmgen_semantic_introspect` MCP dispatch accepts the repo-relative new
  source path, returns the same normalized semantic facts, and preserves
  `read_only=true` plus `shell_access=false` provenance.

No feature-specific MCP method, mutation tool, transport change, unbounded
dump, or raw private parser/lowering payload is selected. This is the ongoing
semantic-introspection architecture applied to the new feature, not an
optional documentation extra.

## Runtime Contract

Select focused test:

```text
t/1523-ial2-ahb-exact-two-paired-busy-composition.t
t/data/ahb_exact_two_paired_busy_composition_tb.svt
```

The test owns source structure, adapter/report/artifact assertions, strict
check, schedule JSON, normalized semantic JSON, real read-only MCP, outdir,
`--verify-hdl`, and one generated-HDL runtime. The runtime uses Verilator
`--no-assert`, matching the current paired boundary, while standalone t/1521
remains assertion-enabled.

The runtime must drive a zero-base byte `INCR4` write with
`cmd_wdata=32'h11111111`, `cmd_wdata_step=32'h11111111`, and zero waits, then
require:

```text
NONSEQ(0) -> SEQ(1) -> BUSY(2 held for two qualified events)
          -> SEQ(2 resumed once) -> SEQ(3)

transfers=5
beats=4
busy episodes=1
qualified BUSY events=2
resumed pending SEQ=1
remaining=0
last response=OKAY
last error/retry/split=0
storage=32'h44332211
```

Across both BUSY events, the harness must hold requester
address/control/write-data and beat counters, verify
`ahb_busy_remaining_q=2 -> 1 -> 0`, retain subordinate SEQ continuation,
phase ownership and storage, retain interconnect data ownership, and reject a
BUSY-caused requester data-beat completion.

## Support And Preservation

Current accounting is 316 protocol fixtures, 357 supported-smoke/strict
fixtures, and 40 AHB IAL2 paths split 20 generic `.ppif` / 20 `.ahb`. The
selected generic source projects:

```text
protocol fixtures:        317
supported-smoke fixtures: 358
strict-supported fixtures:358
AHB IAL2 paths:           41
  generic .ppif:          21
  .ahb aliases:           20
```

Implementation must update the regression corpus, t/248 accounting,
capability/language surfaces and t/297, current mdBook inventory/navigation,
README, roadmap, task tree, Memory, and Knowledge Map in the same slice.

Preservation includes base requester/aggregate, exact-one requester and paired
generic/alias one-/two-subordinate families, exact-two requester generic/alias,
HBURST/BUSY-parking endpoint and aggregate families, active-transfer phase
repair, and current surface-truth tests. Focused owners include t/1494,
t/1496, t/1498, t/1512-t/1522, t/248, and t/297; the implementation may choose
the smallest evidence-complete subset while retaining t/1513 and t/1521 as the
direct paired/requester runtime precedents.

Heavy generation and Verilator runs stay under the 4-GiB descendant-RSS cap
with attached monitoring.

## Implementation And Rollback

Leaf `.3` is selected to add only the new source/support/test/docs data. Parser
and generator algorithms are expected to remain unchanged. If implementation
exposes a new substrate failure, `.3` must stop, record it, and select a
separate repair rather than silently widening this contract.

Rollback removes the new source, support entry, focused test/testbench,
behavior record/fact, and exact associated docs/accounting updates. All
existing requester, subordinate, interconnect, paired, semantic/MCP, and
backend behavior remains intact.

## Explicit Deferrals

The matching `.ahb` alias, exact-two two-subordinate composition, counts beyond
two, generalized width, policy/runtime/random throttling, multiple insertion
points, distinct local bus-BUSY status, larger/indefinite bursts, optional AHB
signals, queues/outstanding transfers, managers, broader fabrics, separate
interconnect-selector repair, direct backends, verification-output generation,
AXI/APB expansion, backend variants, VHDL, and decision 0020 remain separate
task-tree-owned work.
