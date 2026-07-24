# IAL2 AHB Two-Subordinate Exact-Two Paired BUSY Composition Readiness Audit

Task-tree owner:
`IAL2-AHB-EXACT-TWO-PAIRED-BUSY-COMPOSITION-READINESS-AUDIT.6`

Date: 2026-07-24

## Outcome

The shipped exact-two requester safely composes with both existing
HBURST-aware byte-lane BUSY-parking subordinate windows through FSMGen's
current four-child `IAL2 -> IAL1 -> IAL0 -> SystemVerilog` architecture. A
disposable generated-HDL proof ran one byte `INCR4` command through each
window. Each command observed exactly two grant-and-ready-qualified BUSY
events in one held presentation, one resumed pending `SEQ`, four completed
data beats, stable selected and unselected subordinate state, stable
interconnect data-phase ownership, clean status, and correct final storage.

No parser, requester, subordinate, interconnect, composition-top, scheduler,
normalized-semantic, MCP-adapter, or HDL repair is required. The audit selects
proposed leaf
`IAL2-AHB-EXACT-TWO-PAIRED-BUSY-COMPOSITION-READINESS-AUDIT.7` for a separate
no-behavior public-contract selection. That leaf must freeze an unambiguous
generic source identity, support/report/test contract, and rollback boundary
before any source or behavior is added.

This audit adds no public source, support entry, test, syntax, generator,
semantic/MCP API, HDL/runtime behavior, backend, protocol, or transaction-layer
feature.

## Reconciled Shipped Precedents

The proof composes two already-shipped axes:

- the exact-two requester and its generic/alias sources, actor-owned
  `ahb_busy_remaining_q`, numeric `busy_insertion.beats=2`, and
  assertion-enabled t/1521 runtime;
- the one-subordinate exact-two paired generic/alias sources and shared t/1523
  runtime;
- the two-subordinate exact-one paired generic/alias sources, four-child
  status/control architecture, and t/1515 runtime; and
- current requester, subordinate, interconnect, and composition-top lowering,
  including accepted address/control phase storage, one-hot retained
  data-phase response ownership, static windows, generated review artifacts,
  schedule JSON, normalized semantic JSON, and read-only MCP adaptation.

The proposed interconnect default/decode selector repair remains a separate
owner. The generated-HDL audit therefore retains the established paired
`--no-assert` boundary while directly checking every ownership invariant.
Decision 0020 and its transaction-layer horizon remain proposed and inactive.

## Disposable Candidate And Static Proof

The candidate was derived from the shipped generic two-subordinate exact-one
paired source. Its only semantic changes were:

1. requester object and aggregate child reference changed from
   `amba_requester_busy_insert` to `amba_requester_busy_insert_two`; and
2. requester transfer added `(busy-beats 2)` beside
   `(busy-before-beat 2)`.

No future public filename, support id, coverage key, or test number was
selected. Existing lowering reported:

```text
schema:       fsmgen.ial2.protocol_intent.ahb_interconnect.v1
children:     4
HDL module:   ahb_tb
signals:      29
semantic root: top

address windows:
  status:  [0, 4)
  control: [4, 8)

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
```

The requester child reports `busy_insertion.before_beat=2` and numeric
`busy_insertion.beats=2`. Both subordinate children and both aggregate
propagation entries report `parks_on=[busy]`. The composition retains
`one_hot_accepted_subordinate` response ownership with retirement on the
retained owner's ready-out and same-edge owner replacement.

Strict check and normalized semantic JSON both succeeded with module `ahb_tb`,
root `top`, and four children. Support accounting truthfully reported
`matched=false` because the candidate was disposable rather than catalogued.
A real `fsmgen_semantic_introspect` MCP call against the disposable workspace
returned the same normalized summary and unmatched support state with
workspace-relative identity, `read_only=true`, and `shell_access=false`. This
proves that a future support-accounted source needs no feature-specific MCP
route: it must extend the existing normalized semantic surface and preserve
MCP parity.

## Generated-HDL Runtime Proof

The generated `ahb_tb` and disposable harness were compiled with Verilator
under the 4-GiB descendant-RSS cap. The harness issued:

```text
status command:  base 0, first byte 0x11 -> final status  0x44332211
control command: base 4, first byte 0x55 -> final control 0x88776655
```

For each command it checked:

- presentation order
  `NONSEQ(0) -> SEQ(1) -> BUSY(2 held) -> SEQ(2 resumed) -> SEQ(3)`;
- exactly two `HGRANT && HREADY && HTRANS==BUSY` events and no third event;
- requester address, write, size, burst, protection, write data, beat index,
  and remaining count stayed stable through BUSY;
- requester `ahb_busy_remaining_q` was two at the first qualified event, one
  at the second, and zero at resumed `SEQ`;
- the selected subordinate's SEQ continuation, expected address, remaining
  burst count, pending phase, and storage stayed stable;
- the unselected subordinate's continuation, pending state, and storage never
  changed;
- both interconnect data-owner bits stayed stable;
- BUSY completed no data beat, and the held pending transfer resumed as `SEQ`
  exactly once;
- four data beats completed per command with zero remaining and clean
  OKAY/error/retry/split status; and
- the control window preserved global-to-local address subtraction while the
  status result remained unchanged.

Observed result:

```text
PASS commands=2 transfers=10 beats=8 busy=2 qualified_busy=4 resumed_seq=2 status=44332211 control=88776655
```

The disposable candidate, harness, generated HDL, and Verilator build tree
were removed after the proof.

The two authoritative shipped preservation owners pass together under the
same 4-GiB cap:

```text
t/1515-ial2-ahb-two-subordinate-paired-busy-composition.t
t/1523-ial2-ahb-exact-two-paired-busy-composition.t
Files=2, Tests=7, Result=PASS
```

t/1515 preserves the two-window exact-one baseline; t/1523 preserves the
one-window exact-two baseline, including normalized semantic JSON, real
read-only MCP introspection, exact review artifacts, and generated-HDL
runtime behavior.

## Follow-On Contract Boundary

Leaf `.7` now selects one topology-first generic `.ppif` public contract after
clean `.6`:

```text
ppif/ahb_interconnect_two_subordinate_requester_busy_insert_two_byte_lane_hburst_seq_busy_park.ppif
```

The selected contract freezes:

- an unambiguous exact-two-requester/two-subordinate intent, source-object,
  filename, support id, coverage key, and focused test identity;
- reuse of the current four-child `ahb_tb`, status/control windows, retained
  response-owner policy, and exact IAL1/IAL0 artifact set;
- numeric requester-child `before_beat=2`/`beats=2`, both child and propagated
  `parks_on=[busy]`, and no duplicate top `busy_flow`;
- one generated-HDL runtime covering both windows with the invariants and
  exact totals above;
- strict check, schedule JSON, normalized semantic JSON, and real read-only
  `fsmgen_semantic_introspect` parity through the existing API;
- preservation of base, exact-one, one-subordinate exact-two, matching aliases,
  current accounting, diagnostics, docs, Knowledge Map, resource caps, and
  rollback; and
- a later, separate matching `.ahb` alias, if selected from evidence.

No additional generator, feature-specific MCP method, raw parser/lowering
payload, selector repair, generalized BUSY count/policy, broader fabric, or
transaction-layer activation is selected.

## Deferrals

Implementation of the selected generic source, its possible matching `.ahb`
alias, BUSY counts beyond two, generalized count width, multiple insertion
points, runtime/policy/random throttling, distinct local bus-BUSY status,
larger/indefinite or multi-word bursts, optional signals, queues/outstanding
transfers, multiple requesters/managers, broader fabrics, selector repairs,
AXI/APB changes, backend variants, VHDL, and decision 0020 remain separately
owned or inactive.

## Rollback

Revert only this audit record/fact and the `.6` completion/`.7` proposal
pointers. All disposable runtime material was removed, so no shipped source,
support entry, test, generator, semantic/MCP surface, or behavior needs
rollback.
