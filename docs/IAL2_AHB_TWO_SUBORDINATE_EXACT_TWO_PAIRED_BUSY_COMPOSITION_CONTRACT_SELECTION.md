# IAL2 AHB Two-Subordinate Exact-Two Paired BUSY Composition Contract Selection

Task-tree owner:
`IAL2-AHB-EXACT-TWO-PAIRED-BUSY-COMPOSITION-READINESS-AUDIT.7`

Date: 2026-07-24

## Outcome

Select one additive generic public IAL2 source:

```text
ppif/ahb_interconnect_two_subordinate_requester_busy_insert_two_byte_lane_hburst_seq_busy_park.ppif
```

It combines the shipped exact-two requester with the shipped status/control
HBURST-aware byte-lane BUSY-parking subordinates through the existing
four-child `ahb_tb` architecture. Proposed leaf
`IAL2-AHB-EXACT-TWO-PAIRED-BUSY-COMPOSITION-READINESS-AUDIT.8` owns direct
implementation of this frozen data/support/test/documentation contract.

This selection changes no parser, generator, source, support entry, test,
report, normalized-semantic/MCP API, HDL/runtime behavior, backend, protocol,
or transaction-layer behavior.

## Why The Name Is Topology-First

Two existing names use the token `two` for different dimensions:

```text
...requester_busy_insert_two_byte_lane...              # two BUSY events
...requester_busy_insert_two_subordinate_byte_lane...  # two subordinates
```

Blindly combining them would produce
`...requester_busy_insert_two_two_subordinate...`, which is mechanically
decodable but easy to misread in filenames, support ids, logs, and MCP source
identity. The selected name states topology first and requester policy second:

```text
ahb_interconnect_two_subordinate    # topology
requester_busy_insert_two           # requester BUSY cardinality
byte_lane_hburst_seq_busy_park      # subordinate transfer policy
```

This is additive and collision-free. It does not rename either shipped
precedent or imply a new generator. A later matching `.ahb` alias can use the
same basename without ambiguity.

## Public Identity

```text
source:
  ppif/ahb_interconnect_two_subordinate_requester_busy_insert_two_byte_lane_hburst_seq_busy_park.ppif

intent:
  ahb_interconnect_two_subordinate_requester_busy_insert_two_byte_lane_hburst_seq_busy_park

source object:
  fsmgen-ahb-interconnect-two-subordinate-requester-busy-insert-two-byte-lane-hburst-seq-busy-park

anchor:
  document = FSMGEN-AHB-TWO-SUBORDINATE-BYTE-LANE-HBURST-SEQ-CONTRACT
  section  = bounded-ahb-interconnect-two-subordinate-requester-busy-insert-two-byte-lane-hburst-seq-busy-park
  page     = first-public-contract

requester actor:
  amba_requester_busy_insert_two

support entry:
  intent.ppif_ahb_interconnect_two_subordinate_requester_busy_insert_two_byte_lane_hburst_seq_busy_park

coverage key:
  ial2_ppif_ahb_interconnect_two_subordinate_requester_busy_insert_two_byte_lane_hburst_seq_busy_park_pipeline_cli

source kind / classification / strict:
  ppif / supported_smoke / supported

HDL module / semantic root / child count:
  ahb_tb / top / 4
```

## Exact Source Delta

The implementation copies the shipped generic two-subordinate exact-one paired
source:

```text
ppif/ahb_interconnect_requester_busy_insert_two_subordinate_byte_lane_hburst_seq_busy_park.ppif
```

Only these source fields may change:

1. intent, source-object, and anchor-section identity become the selected
   topology-first values above;
2. embedded requester object becomes `amba_requester_busy_insert_two`;
3. requester transfer adds `(busy-beats 2)` beside
   `(busy-before-beat 2)`; and
4. aggregate requester child selects `amba_requester_busy_insert_two`.

Status/control subordinate clauses, local wait controls, storage, bus
bindings, HBURST/SEQ/BUSY-park policy, response mapping, address windows,
decode, shared wiring, clocks, and resets remain equivalent to the shipped
two-subordinate exact-one source.

```text
status window:  base 0, size 4, limit 4
control window: base 4, size 4, limit 8

status local address:  HADDR
control local address: HADDR - 4
```

The generic `.ppif` ships first. A byte-identical `.ahb` profile alias remains
a later, separately selected data/parity slice.

## Generated Architecture And Report Contract

The existing PPIF adapter, `AhbRequester`, `AhbSubordinate`, and
`AhbInterconnect` generators must emit exactly:

```text
IAL1:
  amba_requester_busy_insert_two.isf
  ahb_status_subordinate_byte_lane_hburst_seq.isf
  ahb_control_subordinate_byte_lane_hburst_seq.isf
  ahb_interconnect.isf

IAL0:
  amba_requester_busy_insert_two.fsm
  ahb_status_subordinate_byte_lane_hburst_seq.fsm
  ahb_control_subordinate_byte_lane_hburst_seq.fsm
  ahb_interconnect.fsm
  ahb_tb.fsm

HDL entry/module:
  ahb_tb.fsm / ahb_tb
```

Schedule/report JSON keeps schema
`fsmgen.ial2.protocol_intent.ahb_interconnect.v1` and freezes:

```text
composition.child_instance_count                         = 4
children[requester].object_name                           = amba_requester_busy_insert_two
children[requester].busy_insertion.before_beat            = 2
children[requester].busy_insertion.beats                  = 2
children[status].transfer.seq_policy.parks_on             = [busy]
children[control].transfer.seq_policy.parks_on            = [busy]
composition.seq_policy_propagation.status.parks_on        = [busy]
composition.seq_policy_propagation.control.parks_on       = [busy]
composition.response_mux.data_phase_owner.mode            = one_hot_accepted_subordinate
composition.response_mux.data_phase_owner.retire_event    = retained_owner_ready_out
composition.response_mux.data_phase_owner.same_edge_replacement
  = completion_with_accepted_active_address_replaces_owner
```

No top-level `busy_flow` summary is added. Requester-child `busy_insertion`
owns driven cardinality; child and propagated SEQ policy own received BUSY
parking. The generic source keeps existing aggregate/requester/subordinate
profile-alias residue. Existing broader/burst residue continues to state that
bounded byte `WRAP4`/`INCR4` SEQ with BUSY parking ships while broader AHB
behavior remains deferred.

## Semantic Introspection And MCP Contract

Implementation must make the support-accounted source available through the
existing clean semantic architecture in the same slice:

- strict check JSON reports the selected support id, `ahb_tb`, and four
  children;
- schedule JSON exposes exact identity, artifacts, windows, requester numeric
  BUSY cardinality, both parking policies, and response ownership;
- normalized semantic JSON reports module `ahb_tb`, semantic root `top`, four
  semantic composition children, and the selected support identity; and
- a real `fsmgen_semantic_introspect` MCP call accepts the repo-relative source
  path, returns the same normalized semantic facts, and retains
  `read_only=true` and `shell_access=false` provenance.

The reserved-name probe already passes strict check, schedule, normalized
semantic generation through the real MCP adapter, and path sanitization while
truthfully reporting `support_accounting.matched=false` before implementation.

No feature-specific MCP method, write tool, transport change, raw private
parser/lowering dump, or second semantic schema is selected. New semantics
extend the normalized source of truth; MCP remains its read-only adapter.

## Focused Test And Runtime Contract

Select:

```text
t/1525-ial2-ahb-two-subordinate-exact-two-paired-busy-composition.t
t/data/ahb_two_subordinate_exact_two_paired_busy_composition_tb.svt
```

t/1525 must prove source delta/identity, exact schedule/report/residue and
artifact shape, strict support identity, normalized semantic JSON, a real
read-only MCP call, outdir generation, `--verify-hdl`, and one generated-HDL
runtime. It may adapt the disposable `.6` harness; it must not add public debug
ports or compile a redundant second runtime.

The Verilator runtime retains the paired `--no-assert` boundary and issues two
zero-wait byte `INCR4` commands:

| Command | Global base | First data | Step | Final storage |
| --- | ---: | ---: | ---: | ---: |
| status | `0` | `32'h11111111` | `32'h11111111` | `status_data_q=32'h44332211` |
| control | `4` | `32'h55555555` | `32'h11111111` | `control_data_q=32'h88776655` |

Each command must require:

```text
NONSEQ(0) -> SEQ(1) -> BUSY(2 held for two qualified events)
          -> SEQ(2 resumed once) -> SEQ(3)

transfer presentations = 5
data beats             = 4
BUSY episodes          = 1
qualified BUSY events  = 2
resumed pending SEQ    = 1
remaining              = 0
completion             = OKAY, no error/retry/split
```

Across BUSY, the harness must prove requester address/control/write-data and
beat counters stay stable; `ahb_busy_remaining_q` reports `2 -> 1 -> 0`; BUSY
completes no data beat; selected-subordinate SEQ continuation, pending phase,
and storage stay stable; the unselected subordinate never changes; both
interconnect owner bits stay stable; and exactly one pending `SEQ` resumes.
The control command must prove global `4,5,6,6,7` becomes local
`0,1,2,2,3` while status storage remains unchanged.

Expected total runtime line:

```text
PASS commands=2 transfers=10 beats=8 busy=2 qualified_busy=4 resumed_seq=2 status=44332211 control=88776655
```

Standalone t/1521 remains assertion-enabled and authoritative for exact-two
requester selectors. The paired runtime stays `--no-assert` because the
pre-existing interconnect default/decode selector overlap is owned by a
separate inactive repair tree, not by this feature.

## Support Accounting And Preservation

Current accounting is:

```text
protocol fixtures:         318
supported-smoke fixtures:  359
strict-supported fixtures: 359
AHB IAL2 paths:             42
  generic .ppif:            21
  .ahb aliases:             21
```

The selected generic source projects exactly:

```text
protocol fixtures:         319
supported-smoke fixtures:  360
strict-supported fixtures: 360
AHB IAL2 paths:             43
  generic .ppif:            22
  .ahb aliases:             21
```

Implementation must update `RegressionCorpus`, `LanguageSurfaceSection`,
t/248, t/297, the current README/roadmap/task surfaces, mdBook inventory and
examples, Memory, behavior/fact records, and Knowledge Map together.

Preservation includes base, exact-one, and exact-two requester generic/alias;
one-subordinate exact-one/exact-two paired generic/alias; two-subordinate
exact-one paired generic/alias; HBURST/SEQ/BUSY-parking endpoint and aggregate
families; active-transfer phase ownership; malformed existing sources; and
current-surface truth. Focused owners include t/1513-t/1524, t/248, t/297, and
t/1518; `.8` may choose the smallest evidence-complete subset while retaining
t/1515 and t/1523 as the direct orthogonal precedents.

Heavy generation and Verilator commands remain under the 4-GiB descendant-RSS
cap with attached completion polling.

## Implementation, Deferrals, And Rollback

Proposed `.8` adds only the selected generic source, one support entry, focused
test/runtime, behavior/fact documentation, and synchronized public accounting.
No parser or generator algorithm is expected to change. If implementation
reveals a substrate contradiction, `.8` must stop and select a separate repair
rather than widening this contract silently.

The matching `.ahb` alias, BUSY counts beyond two, generalized count width,
multiple insertion points, runtime/policy/random throttling, distinct local
bus-BUSY status, larger/indefinite or multi-word bursts, optional signals,
queues/outstanding transfers, multiple requesters/managers, broader fabrics,
selector repairs, AXI/APB changes, direct backends, verification-output
generation, backend variants, VHDL, and decision 0020 remain separate or
inactive.

Rollback removes the new generic source, support entry, t/1525/testbench,
behavior/fact, and exact accounting/public-doc updates. All shipped requester,
subordinate, interconnect, paired, semantic/MCP, and backend behavior remains
unchanged.
