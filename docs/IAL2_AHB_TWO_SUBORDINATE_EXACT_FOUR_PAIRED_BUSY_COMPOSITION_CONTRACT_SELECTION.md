# IAL2 AHB Two-Subordinate Exact-Four Paired BUSY Composition Contract Selection

Task-tree owner:
`IAL2-AHB-TWO-SUBORDINATE-EXACT-FOUR-PAIRED-BUSY-COMPOSITION-READINESS-AUDIT.2`

Date: 2026-07-30

## Outcome

Select one additive generic public source:

```text
ppif/ahb_interconnect_two_subordinate_requester_busy_insert_four_byte_lane_hburst_seq_busy_park.ppif
```

It composes the shipped exact-four requester with the shipped status and
control byte-lane/HBURST-SEQ/BUSY-parking subordinates through the existing
four-child, two-window `ahb_tb` architecture. Proposed leaf
`IAL2-AHB-TWO-SUBORDINATE-EXACT-FOUR-PAIRED-BUSY-COMPOSITION-READINESS-AUDIT.3`
owns the separate data-only implementation.

This selection adds no source, support entry, test, checked-in artifact,
parser/generator behavior, report or semantic/MCP API, HDL/runtime behavior,
simulator integration, backend, protocol, verification generation, HIAL/VIAL,
VHDL, portability, scale, decision-0020, or transaction behavior.

## Public Identity

The selected identities are:

```text
source:
  ppif/ahb_interconnect_two_subordinate_requester_busy_insert_four_byte_lane_hburst_seq_busy_park.ppif

intent:
  ahb_interconnect_two_subordinate_requester_busy_insert_four_byte_lane_hburst_seq_busy_park

source object:
  fsmgen-ahb-interconnect-two-subordinate-requester-busy-insert-four-byte-lane-hburst-seq-busy-park

anchor:
  document = FSMGEN-AHB-TWO-SUBORDINATE-BYTE-LANE-HBURST-SEQ-CONTRACT
  section  = bounded-ahb-interconnect-two-subordinate-requester-busy-insert-four-byte-lane-hburst-seq-busy-park
  page     = first-public-contract

requester actor:
  amba_requester_busy_insert_four

subordinate actors:
  ahb_status_subordinate_byte_lane_hburst_seq
  ahb_control_subordinate_byte_lane_hburst_seq

interconnect actor:
  ahb_tb

support entry:
  intent.ppif_ahb_interconnect_two_subordinate_requester_busy_insert_four_byte_lane_hburst_seq_busy_park

coverage key:
  ial2_ppif_ahb_interconnect_two_subordinate_requester_busy_insert_four_byte_lane_hburst_seq_busy_park_pipeline_cli

source kind / class / strict:
  ppif / supported_smoke / true

HDL module / semantic root / child count:
  ahb_tb / top / 4
```

The topology-first name keeps the two subordinates distinct from requester
BUSY cardinality. It selects source data through the existing PPIF adapter and
AHB generators, not a new generator, report schema, semantic projection, or
MCP method.

## Source Contract

The new source is the identity/requester/cardinality-only transform of
`ppif/ahb_interconnect_two_subordinate_requester_busy_insert_three_byte_lane_hburst_seq_busy_park.ppif`.
Only these fields change:

1. source, intent, object, and anchor-section identities replace `three` with
   `four`;
2. the requester actor object becomes `amba_requester_busy_insert_four`;
3. requester transfer changes `(busy-beats 3)` to `(busy-beats 4)` beside the
   unchanged `(busy-before-beat 2)`; and
4. the aggregate requester child selects `amba_requester_busy_insert_four`.

Command/status ports, bus bindings, clock/reset, burst encodings, response
actions, both subordinate clauses, byte-lane storage semantics, wait controls,
status window `[0,4)`, control window `[4,8)`, decode policy, and interconnect
wiring remain byte-structurally identical to the exact-three authority.

Only the generic `.ppif` source ships in `.3`. A matching `.ahb` alias requires
its own contract, support identity, parity test, accounting, and cleanup slice.

## Generated Architecture And Reports

Implementation must use the current PPIF adapter plus `AhbRequester`,
`AhbSubordinate`, and `AhbInterconnect` generators and emit exactly:

```text
IAL1:
  amba_requester_busy_insert_four.isf
  ahb_status_subordinate_byte_lane_hburst_seq.isf
  ahb_control_subordinate_byte_lane_hburst_seq.isf
  ahb_interconnect.isf

IAL0:
  amba_requester_busy_insert_four.fsm
  ahb_status_subordinate_byte_lane_hburst_seq.fsm
  ahb_control_subordinate_byte_lane_hburst_seq.fsm
  ahb_interconnect.fsm
  ahb_tb.fsm

HDL entry/module:
  ahb_tb.fsm / ahb_tb
```

The existing aggregate report contract remains:

```text
schema                                            = fsmgen.ial2.protocol_intent.ahb_interconnect.v1
composition.child_instance_count                  = 4
composition.response_mux.data_phase_owner.mode    = one_hot_accepted_subordinate
children[requester].object_name                    = amba_requester_busy_insert_four
children[requester].busy_insertion.before_beat     = 2
children[requester].busy_insertion.beats           = 4
children[status].transfer.seq_policy.parks_on       = [busy]
children[control].transfer.seq_policy.parks_on      = [busy]
composition.seq_policy_propagation[*].parks_on      = [busy]
composition.address_decode.windows                 = [0,4), [4,8)
```

The requester retains width-three `ahb_busy_remaining_q`; rules load four,
decrement greater-than-one qualified BUSY events, clear at one, and resume the
pending `SEQ`, giving `4 -> 3 -> 2 -> 1 -> 0` independently for each command.
No aggregate-level `busy_flow` duplicate is added. Requester state owns BUSY
insertion cardinality; both subordinate and propagated reports own BUSY
parking; the interconnect owns one-hot accepted-subordinate data-phase state.

## Semantic Introspection And MCP Contract

The new support-accounted path must ship through every existing bounded
read-only semantic surface in `.3`:

- strict check JSON reports success, the exact support identity, module
  `ahb_tb`, 29 top-level signals, zero top-level states, and four children;
- schedule JSON exposes the exact source, four IAL1/five IAL0 artifacts,
  numeric `before_beat=2`/`beats=4`, both windows, one-hot ownership, and both
  child/propagated BUSY-parking clauses;
- normalized semantic JSON reports schema version 1, module `ahb_tb`, source
  root `top`, four children, and the exact support entry; and
- real `fsmgen_semantic_introspect` accepts the repo-relative new path, returns
  the same normalized facts, and retains `query_kind=semantic`,
  `read_only=true`, and `shell_access=false`.

No feature-specific MCP method, mutation surface, private raw dump, transport
change, or shell-enabled adapter is selected.

## Focused Test And Runtime Contract

Select:

```text
t/1539-ial2-ahb-two-subordinate-exact-four-paired-busy-composition.t
t/data/ahb_two_subordinate_exact_four_paired_busy_composition_tb.svt
```

t1539 owns exact source identity/delta; strict support and diagnostics;
schedule/report/artifact assertions; width-three requester structure;
normalized semantic JSON; real repo-relative read-only MCP; repository-local
output; public `--verify-hdl`; and one generated-HDL runtime compiled with
Verilator 5.046 `--timing`, `-j 1`, and every generated selector assertion
enabled.

The harness issues a zero-wait byte `INCR4` write to the status window and a
second to the control window. It must require:

```text
per command:
  NONSEQ(0) -> SEQ(1) -> BUSY(2 held for four qualified events)
            -> SEQ(2 resumed once) -> SEQ(3)

commands=2
presentations=10
beats=8
BUSY episodes=2
qualified BUSY events=8
resumed pending SEQ=2
remaining=0 after each command
last response=OKAY
last error/retry/split=0
status storage=32'h44332211
control storage=32'h88776655
```

At each command's qualified BUSY events the requester counter must be four,
three, two, then one and must be zero at the single resumed `SEQ`. Requester
address/control/write-data and beat counters, selected subordinate burst/
phase/storage, unselected subordinate state, and fabric data-phase ownership
remain stable through BUSY. BUSY completes no data beat.

## Diagnostics And Failure Boundary

The contract adds no syntax or accepted literal range. Existing parser and AHB
diagnostics remain authoritative. t1539 must additionally prove a deliberately
unsupported disposable identity reports successful syntax/lowering with an
unmatched support entry before the real support entry is added, then proves
the shipped path matches exactly after implementation. Any unexpected parser,
generator, report, semantic/MCP, assertion, or simulator repair stops `.3` and
opens the smallest separate repair leaf; it must not silently widen this
contract.

## Support And Preservation

At contract selection, current accounting is 330 protocol paths, 371
supported-smoke paths, 371 strict paths, and 54 AHB paths split 27 `.ppif` /
27 `.ahb`. The selected one generic source projects:

```text
protocol paths:          331
supported-smoke paths:   372
strict-supported paths:  372
AHB IAL2 paths:           55
  generic .ppif:          28
  .ahb aliases:           27
```

`.3` must add the selected `RegressionCorpus` entry and synchronize t248,
t297, capability/language surfaces, `docs/REGRESSION_CORPUS.md`, current book
inventory/navigation, README, roadmap, task/index, Memory, and Knowledge Map.

Focused preservation must include t1533/t1534 for the generic/profile
two-window exact-three family and t1537/t1538 for the generic/profile
one-window exact-four family. t248/t297 must prove exact new accounting;
t1518/t1256/t1414 plus Knowledge Map, mdBook, doctrine, locality, resource, and
cleanup gates preserve the current documentation and continuity contract.

All heavy work uses repository-derived same-volume storage plus the authorized
`--host-max-pct 100 --process-max-rss-mb 4096` profile. Capacity is reported
with the exact Stats-compatible Mach formula and kernel pressure separately;
guard occupancy and inverted `memory_pressure -Q` free percentage are never
capacity truth.

## Selection Verification

The selected source, support entry, t1539, and testbench are absent at contract
selection, so public accounting remains 330/371/54 split 27 `.ppif`/27 `.ahb`.
t248 plus t297 reconfirm that current boundary in 2 files / 7,007 tests. The
canonical `.1` audit supplies exact disposable strict/artifact/semantic/real
read-only-MCP/public-verifier and all-assertion 10/8/2/8/2/`44332211`/
`88776655` readiness evidence; selection does not recreate or weaken it.

Focused t1518+t1256+t1414 pass 3 files / 22 tests. The Knowledge Map is valid
and synchronized at 1,045 facts / 5,346 question keys. mdBook renders exactly
72 files / 16,351,883 bytes; that disposable render is removed. MEMORY.md is
58 lines, README.md is 2,329 lines, diff is clean, and all six doctrine gates
pass. The only repository-local temp residue is the pre-existing 491-byte
`.artifacts/tmp/xcrun_db` cache. Canonical Stats-compatible RAM is 54.10%
(12.983/24.000 GiB; 13,940,523,008/25,769,803,776 bytes), with separate macOS
pressure level 1. Guard occupancy is excluded from capacity truth.

## Implementation And Rollback

Leaf `.3` adds only the selected source, support entry, focused t1539 and
testbench, behavior record/fact, and exact docs/accounting updates. Parser and
generator algorithms, existing source bytes, report/semantic/MCP APIs, and
simulator integration are expected to remain byte-identical.

Rollback removes exactly:

```text
ppif/ahb_interconnect_two_subordinate_requester_busy_insert_four_byte_lane_hburst_seq_busy_park.ppif
t/1539-ial2-ahb-two-subordinate-exact-four-paired-busy-composition.t
t/data/ahb_two_subordinate_exact_four_paired_busy_composition_tb.svt
intent.ppif_ahb_interconnect_two_subordinate_requester_busy_insert_four_byte_lane_hburst_seq_busy_park
```

It also removes the `.3` behavior record/fact and restores synchronized
accounting to 330/371/54 split 27 `.ppif`/27 `.ahb`. Existing requester,
subordinate, interconnect, paired, semantic/MCP, simulator, backend,
HIAL/VIAL, and VHDL behavior remains intact.

## Explicit Deferrals

The matching `.ahb` alias, BUSY counts above four, runtime/policy/random/
multiple-point insertion, distinct bus-BUSY status, larger/indefinite bursts,
optional AHB signals, queues/outstanding transfers, managers, wider fabrics,
generic priority changes, direct backends, AXI/APB expansion, HIAL/VIAL
activation and topology selection, verification-output generation, backend
variants, VHDL, large-design scale implementation, portability, and decision
`0020` remain separate task-tree-owned work.

Clean contract commit `4d0cc34bd` activates only selected data-only
implementation `.3`. Activation changes continuity documentation only; the
source, support entry, t1539, and testbench remain absent and public accounting
remains 330/371/54 split 27 `.ppif`/27 `.ahb` until `.3` ships.

## Implementation Outcome

Completed `.3` now ships the selected generic source and exact support entry.
t1539 proves the six-field source delta, strict/report/artifact/normalized-
semantic/repo-relative read-only-MCP/public-verifier/unmatched-neighbor
diagnostic surfaces and assertion-enabled 10/8/2/8/2/`44332211`/`88776655`
runtime through repository-local workspaces. Current accounting is 331/372/55
split 28 `.ppif`/27 `.ahb`. See
`docs/IAL2_AHB_TWO_SUBORDINATE_EXACT_FOUR_PAIRED_BUSY_COMPOSITION_BEHAVIOR.md`.
