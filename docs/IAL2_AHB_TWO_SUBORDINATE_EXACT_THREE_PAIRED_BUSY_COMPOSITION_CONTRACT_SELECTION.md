# IAL2 AHB Two-Subordinate Exact-Three Paired BUSY Composition Contract Selection

Task-tree owner:
`IAL2-AHB-TWO-SUBORDINATE-EXACT-THREE-PAIRED-BUSY-COMPOSITION-READINESS-AUDIT.2`

Date: 2026-07-29

## Outcome

Select one additive generic public IAL2 source:

```text
ppif/ahb_interconnect_two_subordinate_requester_busy_insert_three_byte_lane_hburst_seq_busy_park.ppif
```

It composes the shipped exact-three requester with the shipped status/control
HBURST-aware byte-lane BUSY-parking subordinates through the existing
four-child `ahb_tb` architecture. Proposed leaf
`IAL2-AHB-TWO-SUBORDINATE-EXACT-THREE-PAIRED-BUSY-COMPOSITION-READINESS-AUDIT.3`
owns separate data-only implementation.

This contract selection adds no source, support entry, test, checked-in
artifact, parser/generator behavior, semantic/MCP API, HDL/runtime behavior,
backend, protocol, verification generation, HIAL/VIAL, VHDL, or
transaction-layer behavior.

## Public Identity

```text
source:
  ppif/ahb_interconnect_two_subordinate_requester_busy_insert_three_byte_lane_hburst_seq_busy_park.ppif

intent:
  ahb_interconnect_two_subordinate_requester_busy_insert_three_byte_lane_hburst_seq_busy_park

source object:
  fsmgen-ahb-interconnect-two-subordinate-requester-busy-insert-three-byte-lane-hburst-seq-busy-park

anchor:
  document = FSMGEN-AHB-TWO-SUBORDINATE-BYTE-LANE-HBURST-SEQ-CONTRACT
  section  = bounded-ahb-interconnect-two-subordinate-requester-busy-insert-three-byte-lane-hburst-seq-busy-park
  page     = first-public-contract

requester actor:
  amba_requester_busy_insert_three

support entry:
  intent.ppif_ahb_interconnect_two_subordinate_requester_busy_insert_three_byte_lane_hburst_seq_busy_park

coverage key:
  ial2_ppif_ahb_interconnect_two_subordinate_requester_busy_insert_three_byte_lane_hburst_seq_busy_park_pipeline_cli

source kind / class / strict:
  ppif / supported_smoke / true

HDL module / semantic root / child count:
  ahb_tb / top / 4
```

Topology-first naming distinguishes the two-subordinate aggregate from
exact-three requester cardinality. It is additive and collision-free; no
existing source is renamed.

## Exact Source Contract

Implementation derives the new file byte-structurally from:

```text
ppif/ahb_interconnect_two_subordinate_requester_busy_insert_two_byte_lane_hburst_seq_busy_park.ppif
```

Only these fields change:

1. intent, object, and anchor-section identities replace exact-two with
   exact-three;
2. embedded requester becomes `amba_requester_busy_insert_three`;
3. `(busy-beats 2)` becomes `(busy-beats 3)` beside unchanged
   `(busy-before-beat 2)`; and
4. the aggregate requester child selects `amba_requester_busy_insert_three`.

Status/control subordinate clauses, wait controls, storage, bus bindings,
HBURST/SEQ/BUSY-park policy, response mapping, address windows, decode, shared
wiring, clocks, resets, and top ports remain byte-equivalent to the exact-two
precedent outside those substitutions.

```text
status window:  base 0, size 4, limit 4
control window: base 4, size 4, limit 8
```

Only generic `.ppif` ships in `.3`. A matching `.ahb` profile alias remains a
separate data/parity slice.

## Generated Architecture And Report Contract

Existing generators must emit exactly:

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

HDL entry/module:
  ahb_tb.fsm / ahb_tb
```

Schedule/report schema remains
`fsmgen.ial2.protocol_intent.ahb_interconnect.v1` and freezes four children,
29 top signals, requester `before_beat=2` / `beats=3`, width-two
`3 -> 2 -> 1 -> 0` retirement, both child and propagated
`parks_on=[busy]`, both static windows, and response owner mode
`one_hot_accepted_subordinate` with existing capture, retirement, and
same-edge replacement rules.

No top-level `busy_flow` duplicate is added. Generic alias residue remains;
substantive AHB residue continues to defer counts above three and broader
policy/status/burst/signal behavior.

## Semantic And MCP Contract

Implementation must ship the selected support-accounted source through every
existing read-only semantic surface:

- strict check JSON reports exact support, `ahb_tb`, four children, 29 signals,
  and zero diagnostics;
- schedule JSON exposes identity, artifacts, windows, numeric BUSY cardinality,
  both parking policies, and response ownership;
- normalized semantic JSON reports module `ahb_tb`, root `top`, four children,
  29 module signals, and exact support; and
- real `fsmgen_semantic_introspect` accepts the repo-relative path, returns the
  same normalized facts, and retains `read_only=true` / `shell_access=false`.

No feature-specific MCP method, mutation surface, raw-private dump, transport
change, or shell-enabled adapter is selected.

## Focused Test And Runtime Contract

Select:

```text
t/1533-ial2-ahb-two-subordinate-exact-three-paired-busy-composition.t
t/data/ahb_two_subordinate_exact_three_paired_busy_composition_tb.svt
```

t1533 owns the exact source delta and identities; strict support; schedule,
report, residue, and artifact checks; width-two counter structure; normalized
semantic JSON; real read-only MCP; repo-local outdir; `--verify-hdl`;
diagnostic and preservation checks; and one generated-HDL runtime compiled
with `--timing` and without `--no-assert`.

The harness issues status-base `0` and control-base `4` byte `INCR4` writes.
Each command requires:

```text
NONSEQ(0) -> SEQ(1) -> BUSY(2 held for three qualified events)
          -> SEQ(2 resumed once) -> SEQ(3)

presentations=5
beats=4
BUSY episodes=1
qualified BUSY events=3
resumed pending SEQ=1
remaining=0
completion=OKAY, no error/retry/split
```

Across BUSY, requester address/control/data and counters, selected subordinate
continuation/phase/storage, unselected subordinate state, and fabric owner bits
must remain stable. Total expected result:

```text
PASS commands=2 transfers=10 beats=8 busy=2 qualified_busy=6 resumed_seq=2 status=44332211 control=88776655
```

## Support And Preservation

Current accounting is 324 protocol, 365 supported-smoke, 365 strict, and 48
AHB paths split 24 `.ppif` / 24 `.ahb`. One generic path projects:

```text
protocol paths:          325
supported-smoke paths:   366
strict-supported paths:  366
AHB IAL2 paths:           49
  generic .ppif:          25
  .ahb aliases:           24
```

`.3` updates RegressionCorpus, LanguageSurfaceSection, t248, t297,
`docs/REGRESSION_CORPUS.md`, README, roadmap, mdBook inventory/examples,
task/index, Memory, behavior/fact records, and Knowledge Map together.

Focused preservation includes t1525/t1526 two-window exact-two,
t1531/t1532 one-window exact-three, source/alias byte identity, support and
capability accounting, current-book truth, normalized semantics/MCP, and
doctrine gates. `.3` may select the smallest evidence-complete subset while
t1533 owns the new runtime.

## Implementation, Cleanup, And Rollback

Leaf `.3` adds only the selected source, support entry, focused test/harness,
behavior record/fact, and exact documentation/accounting updates. Parser and
generator algorithms, report schemas, and semantic/MCP APIs are expected to
remain unchanged. If realization disproves the contract, `.3` stops and
selects the smallest repair rather than widening silently.

All work uses repository-derived same-volume storage and the authorized
`--host-max-pct 100 --process-max-rss-mb 4096` profile. Capacity uses the exact
Stats-compatible Mach formula; kernel pressure remains separate, and guard
occupancy is never capacity truth. Generated output is censused before exact
removal.

Rollback removes the `.3` additions and restores 324/365/48 accounting. All
existing requester, subordinate, interconnect, paired, semantic/MCP, backend,
HIAL/VIAL, and VHDL behavior remains intact.

## Explicit Deferrals

The matching `.ahb` alias, counts above three, counter-width generalization,
runtime/policy/random/multiple-point insertion, distinct bus-BUSY status,
larger/indefinite bursts, optional AHB signals, queues/outstanding transfers,
managers, broader fabrics, generic priority changes, direct backends, other
protocols, HIAL/VIAL activation, verification-output generation, backend
variants, VHDL, and decision `0020` remain separate task-tree-owned work.

## Contract Closeout

Focused t1518/t1256/t1414 pass 3 files / 22 tests. The Knowledge Map contains
1,028 facts / 5,242 question keys. mdBook builds 72 files / 16,184,455 bytes
and that exact output is removed without residue. All doctrine gates pass.
Canonical Stats-compatible capacity is 68.1% (16.342/24 GiB), kernel pressure
is `1` (normal), and the guard's 92.1% heuristic is not capacity truth.
