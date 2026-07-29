# IAL2 AHB Exact-Four Paired BUSY Composition Contract Selection

Task-tree owner:
`IAL2-AHB-EXACT-FOUR-PAIRED-BUSY-COMPOSITION-READINESS-AUDIT.2`

Date: 2026-07-29

## Outcome

Select one additive generic public source:

```text
ppif/ahb_interconnect_requester_busy_insert_four_byte_lane_hburst_seq_busy_park.ppif
```

It composes the shipped exact-four requester with the shipped one-subordinate
byte-lane/HBURST-SEQ/BUSY-parking endpoint through the existing three-child
`ahb_tb` architecture. Proposed leaf
`IAL2-AHB-EXACT-FOUR-PAIRED-BUSY-COMPOSITION-READINESS-AUDIT.3` owns the
separate data-only implementation.

This contract selection adds no source, support entry, test, checked-in
artifact, parser/generator behavior, semantic/MCP API, HDL/runtime behavior,
simulator integration, backend, protocol, verification generation, HIAL/VIAL,
VHDL, or transaction behavior.

## Public Identity

The selected identities are:

```text
source:
  ppif/ahb_interconnect_requester_busy_insert_four_byte_lane_hburst_seq_busy_park.ppif

intent:
  ahb_interconnect_requester_busy_insert_four_byte_lane_hburst_seq_busy_park

source object:
  fsmgen-ahb-interconnect-requester-busy-insert-four-byte-lane-hburst-seq-busy-park

anchor:
  document = ARM-AMBA-AHB-IHI0033-C-2021-09
  section  = bounded-ahb-interconnect-requester-busy-insert-four-byte-lane-hburst-seq-busy-park
  page     = first-public-contract

requester actor:
  amba_requester_busy_insert_four

support entry:
  intent.ppif_ahb_interconnect_requester_busy_insert_four_byte_lane_hburst_seq_busy_park

coverage key:
  ial2_ppif_ahb_interconnect_requester_busy_insert_four_byte_lane_hburst_seq_busy_park_pipeline_cli

source kind / class / strict:
  ppif / supported_smoke / true

HDL module / semantic root / child count:
  ahb_tb / top / 3
```

The long identity distinguishes exact-four requester cardinality from the
existing exact-one, exact-two, and exact-three pairings. It selects source data
through the existing generators, not a fourth AHB generator or a new report
schema.

## Source Contract

The new source is derived byte-structurally from
`ppif/ahb_interconnect_requester_busy_insert_three_byte_lane_hburst_seq_busy_park.ppif`.
Only these fields change:

1. source, intent, object, and anchor identities replace `three` with `four`;
2. embedded requester object becomes `amba_requester_busy_insert_four`;
3. requester transfer uses `(busy-beats 4)` beside the unchanged
   `(busy-before-beat 2)`; and
4. the aggregate requester child selects `amba_requester_busy_insert_four`.

Command/status ports, bus bindings, clock/reset, burst encodings, response
actions, subordinate storage and transfer policy, zero-base four-byte address
window, decode policy, and interconnect wiring remain identical to the
corresponding exact-three clauses.

Only the generic `.ppif` source ships in `.3`. A matching `.ahb` alias and the
two-subordinate exact-four topology require separate contract, accounting,
parity, and runtime slices.

## Generated Architecture and Reports

The implementation must use the current PPIF adapter plus `AhbRequester`,
`AhbSubordinate`, and `AhbInterconnect` generators and emit exactly:

```text
IAL1:
  amba_requester_busy_insert_four.isf
  ahb_lite_subordinate_byte_lane_hburst_seq.isf
  ahb_interconnect.isf

IAL0:
  amba_requester_busy_insert_four.fsm
  ahb_lite_subordinate_byte_lane_hburst_seq.fsm
  ahb_interconnect.fsm
  ahb_tb.fsm

HDL entry/module:
  ahb_tb.fsm / ahb_tb
```

The existing aggregate report schema remains:

```text
schema                                           = fsmgen.ial2.protocol_intent.ahb_interconnect.v1
composition.child_instance_count                 = 3
composition.response_mux.data_phase_owner.mode   = one_hot_accepted_subordinate
children[requester].object_name                   = amba_requester_busy_insert_four
children[requester].busy_insertion.before_beat    = 2
children[requester].busy_insertion.beats          = 4
children[subordinate].transfer.seq_policy.parks_on = [busy]
composition.seq_policy_propagation...parks_on      = [busy]
```

The requester retains a width-three `ahb_busy_remaining_q`; rules load four,
decrement greater-than-one events, clear at one, and resume pending `SEQ`,
giving `4 -> 3 -> 2 -> 1 -> 0`. No aggregate-level `busy_flow` duplicate is
added. The requester owns insertion cardinality; the subordinate and
propagation reports own BUSY parking. Existing generic alias residue and
substantive AHB residue remain truthful until their own slices.

## Semantic Introspection and MCP Contract

The new support-accounted path must ship through every existing bounded
read-only semantic surface in `.3`:

- strict check JSON reports success, exact support identity, module `ahb_tb`,
  and three composition children;
- schedule JSON exposes the source identity, exact artifacts, numeric
  `before_beat=2`/`beats=4`, one-hot response ownership, and child/propagated
  BUSY parking;
- normalized semantic JSON reports module `ahb_tb`, source root `top`, three
  children, and the exact support entry; and
- real `fsmgen_semantic_introspect` accepts the repo-relative new path, returns
  the same normalized facts, and retains `read_only=true` and
  `shell_access=false`.

No feature-specific MCP method, mutation surface, raw-private dump, transport
change, or shell-enabled adapter is selected.

## Focused Test and Runtime Contract

Select:

```text
t/1537-ial2-ahb-exact-four-paired-busy-composition.t
t/data/ahb_exact_four_paired_busy_composition_tb.svt
```

t1537 owns source identity and structure; strict check and exact support;
schedule/report/artifact assertions; width-three counter structure; normalized
semantic JSON; real read-only MCP; repository-local output; `--verify-hdl`;
and one generated-HDL runtime compiled with Verilator 5.046 `--timing` and
without `--no-assert`.

The harness drives a zero-base byte `INCR4` write with
`cmd_wdata=32'h11111111`, `cmd_wdata_step=32'h11111111`, and zero waits. It
must require:

```text
NONSEQ(0) -> SEQ(1) -> BUSY(2 held for four qualified events)
          -> SEQ(2 resumed once) -> SEQ(3)

transfers=5
beats=4
BUSY episodes=1
qualified BUSY events=4
resumed pending SEQ=1
remaining=0
last response=OKAY
last error/retry/split=0
storage=32'h44332211
```

At qualified BUSY events the requester counter must be 4, 3, 2, then 1 and
must be zero at resumed `SEQ`. Address/control/write-data and beat counters,
subordinate continuation/phase/storage, and fabric data ownership remain
stable; BUSY completes no data beat. Every generated selector assertion stays
enabled.

## Support and Preservation

Current accounting is 328 protocol paths, 369 supported-smoke paths, 369
strict paths, and 52 AHB paths split 26 `.ppif` / 26 `.ahb`. The selected one
generic source projects:

```text
protocol paths:          329
supported-smoke paths:   370
strict-supported paths:  370
AHB IAL2 paths:           53
  generic .ppif:          27
  .ahb aliases:           26
```

`.3` must add the selected RegressionCorpus entry and synchronize t248, t297,
capability/language surfaces, `docs/REGRESSION_CORPUS.md`, current book
inventory/navigation, README, roadmap, task/index, Memory, and Knowledge Map.
Existing parser diagnostics remain authoritative because syntax and accepted
`busy-beats` range do not change.

Focused preservation must include the generic and alias exact-three paired
family, standalone exact-four requester and alias, fabric/endpoint arbitration
owners, current-book truth, support/capability, normalized semantic/MCP, and
doctrine gates. Existing owners t1531, t1535, and t1536 remain unchanged;
`.3` may choose the smallest evidence-complete subset while t1537 owns the new
runtime.

All heavy work uses repository-derived same-volume storage plus the authorized
`--host-max-pct 100 --process-max-rss-mb 4096` profile. Capacity is reported
with the exact Stats-compatible Mach formula and kernel pressure separately;
guard occupancy and inverted `memory_pressure -Q` free percentage are never
capacity truth.

Contract selection reconfirms the current support/capability boundary through
t248 plus t297 (2 files / 6,983 assertions). Focused t1518+t1256+t1414 pass
3 files / 22 top-level tests. The synchronized Knowledge Map contains 1,040
facts / 5,314 question keys. mdBook generates exactly 72 files / 16,292,545
bytes in a repository-local disposable workspace; that exact render is removed
without residue, leaving only the pre-existing 491-byte `xcrun_db` cache under
`.artifacts/tmp`. Pre-closeout canonical Stats-compatible RAM is 71.8%
(17.242/24.000 GiB; 18,513,608,704 bytes) with separate kernel pressure level
1 (normal). Diff and all six doctrine gates pass. Post-gate capacity is 67.9%
(16.303/24.000 GiB; 17,504,862,208 bytes), still with kernel pressure level 1.

## Implementation and Rollback

Leaf `.3` adds only the selected source, support entry, focused test/testbench,
behavior record/fact, and exact docs/accounting updates. Parser and generator
algorithms are expected to remain byte-identical. If implementation exposes a
substrate failure, `.3` must stop and select a separate repair rather than
silently widen this contract.

Rollback removes those exact additions and restores 328/369/52 accounting.
All existing requester, subordinate, interconnect, paired, semantic/MCP,
simulator, backend, HIAL/VIAL, and VHDL behavior remains intact.

## Explicit Deferrals

The matching `.ahb` alias, two-subordinate exact-four composition, BUSY counts
above four, runtime/policy/random/multiple-point insertion, distinct bus-BUSY
status, larger/indefinite bursts, optional AHB signals, queues/outstanding
transfers, managers, broader fabrics, generic priority changes, direct
backends, AXI/APB expansion, HIAL/VIAL activation and topology selection,
verification-output generation, backend variants, VHDL, large-design scale
implementation, and decision 0020 remain separate task-tree-owned work.
