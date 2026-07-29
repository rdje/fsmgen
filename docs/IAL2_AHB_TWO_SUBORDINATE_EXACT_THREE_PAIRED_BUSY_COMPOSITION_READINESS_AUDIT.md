# IAL2 AHB Two-Subordinate Exact-Three Paired BUSY Composition Readiness Audit

Task-tree owner:
`IAL2-AHB-TWO-SUBORDINATE-EXACT-THREE-PAIRED-BUSY-COMPOSITION-READINESS-AUDIT.1`

Date: 2026-07-29

## Outcome

The shipped exact-three requester composes directly with both shipped
HBURST-aware byte-lane BUSY-parking subordinates and the shipped two-window
AHB fabric through the existing `IAL2 -> IAL1 -> IAL0 -> SystemVerilog` path.
The generated aggregate compiles and runs with every selector assertion
enabled.

No parser, requester, subordinate, interconnect, scheduler, composition-top,
semantic-introspection, MCP-adapter, or HDL repair is required. The audit
selects proposed leaf
`IAL2-AHB-TWO-SUBORDINATE-EXACT-THREE-PAIRED-BUSY-COMPOSITION-READINESS-AUDIT.2`,
a separate no-behavior public-contract selector for the first generic
two-window exact-three paired source. That leaf is not active until this audit
commits cleanly and a separate activation commit follows.

This audit ships no public source, support entry, test, checked-in testbench,
generated artifact, semantic/MCP API, HDL/runtime behavior, backend, protocol,
verification-generation, HIAL/VIAL, VHDL, or transaction-layer behavior.

## Reconciled Boundary

The audit read and preserved:

- the standalone and one-window paired exact-three requester generic/profile
  contracts, width-two `3 -> 2 -> 1 -> 0` retirement, reports, semantic/MCP
  exposure, assertion-enabled t1531 runtime, and t1532 alias parity;
- generic/profile two-window exact-two paired source, artifact, report,
  semantic/MCP, assertion-enabled t1525 runtime, and t1526 alias parity;
- the assertion-clean interconnect, generated-subordinate, and direct-seed
  arbitration repairs;
- PPIF parsing plus `AhbRequester`, `AhbSubordinate`, and `AhbInterconnect`
  lowering/report code;
- current RegressionCorpus, strict-support, capability, language-surface,
  normalized-semantic, and read-only MCP contracts at 324 protocol / 365
  supported+strict / 48 AHB paths split 24 `.ppif` / 24 `.ahb`;
- decisions `0004` and `0008`, roadmap, mdBook, task trees, Memory, and the
  Knowledge Map; and
- proposed HIAL/VIAL architecture, generic rule/transaction priority work,
  and decision `0020`, none of which is activated or changed here.

## Disposable Candidate

The repository-derived same-volume candidate retained every byte of the
shipped two-window exact-two source except the exact identity/requester/count
delta:

```text
path:
  ppif/ahb_interconnect_two_subordinate_requester_busy_insert_three_byte_lane_hburst_seq_busy_park.ppif
intent:
  ahb_interconnect_two_subordinate_requester_busy_insert_three_byte_lane_hburst_seq_busy_park
object:
  fsmgen-ahb-interconnect-two-subordinate-requester-busy-insert-three-byte-lane-hburst-seq-busy-park
anchor document:
  FSMGEN-AHB-TWO-SUBORDINATE-BYTE-LANE-HBURST-SEQ-CONTRACT
anchor section:
  bounded-ahb-interconnect-two-subordinate-requester-busy-insert-three-byte-lane-hburst-seq-busy-park
anchor page: first-public-contract
```

The transform changes `busy_insert_two` / `busy-insert-two` to exact-three and
`(busy-beats 2)` to `(busy-beats 3)`. Existing lowering reports:

```text
schema:       fsmgen.ial2.protocol_intent.ahb_interconnect.v1
children:     4
top signals:  29
HDL module:   ahb_tb
owner mode:   one_hot_accepted_subordinate

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

The requester reports `busy_before_beat=2`, `busy_beats=3`, and the existing
width-two `ahb_busy_remaining_q`. Generated rules load three, decrement while
greater than one, clear at one, and resume the pending `SEQ`. Both status and
control children plus aggregate propagation report `parks_on=[busy]`; the
two static windows remain `[0,4)` and `[4,8)`, and response ownership remains
one-hot over the accepted subordinate.

Strict check succeeds with zero diagnostics, four children, 29 signals, zero
top-local states, and correctly unmatched disposable support. Public
`--verify-hdl` also passes.

## Semantic And MCP Boundary

Normalized semantic schema v1 reports module `ahb_tb`, source root `top`, four
children, 29 module signals, and unmatched support. A real
`fsmgen_semantic_introspect` call against the same repo-relative candidate
agrees on module/root/children/support and reports:

```text
query_kind:   semantic
read_only:    true
shell_access: false
```

The existing bounded semantic API is sufficient. No feature-specific MCP
tool, private lowering payload, or shell-enabled adapter is needed.

## Assertion-Enabled Runtime Proof

Verilator 5.046 compiled generated `ahb_tb` plus a mechanically extended t1525
harness with `--timing` and without `--no-assert`. The harness issued two
four-byte `INCR4` writes, first to status then control, and checked:

- each command retained exactly five distinct transfer presentations and four
  accepted data beats;
- each one-transition BUSY episode contained exactly three
  `HGRANT && HREADY && HTRANS==BUSY` events;
- the remaining counter was three, two, then one at qualified BUSY events and
  zero at the single resumed `SEQ`;
- requester address/control/data and beat counters stayed stable through BUSY;
- selected subordinate burst/phase/storage state stayed stable;
- the unselected subordinate remained unchanged for the entire command;
- fabric data-phase ownership remained stable through BUSY; and
- both commands completed cleanly with final status/control storage
  `32'h44332211` / `32'h88776655`.

Observed result:

```text
PASS commands=2 transfers=10 beats=8 busy=2 qualified_busy=6 resumed_seq=2 status=44332211 control=88776655
```

This is a supported-event timing proof in Verilator's compiled model; it is
not a claim that Verilator implements the full event-driven SystemVerilog/UVM
language runtime. Full-language/UVM, VHDL, and mixed-language qualification
remain separate HIAL/VIAL simulator profiles.

## Preservation And Support Projection

Current shipped owners pass:

- t1525 two-window exact-two plus t1531 one-window exact-three: 2 files / 7
  top-level tests / 964 seconds; and
- t248 plus t297 support/capability accounting: 2 files / 6,935 tests.

One new generic supported-smoke/strict path projects 325 protocol paths, 366
supported-smoke paths, 366 strict paths, and 49 AHB paths split 25 `.ppif` /
24 `.ahb`. Contract `.2` must reconfirm and freeze:

```text
support id:
  intent.ppif_ahb_interconnect_two_subordinate_requester_busy_insert_three_byte_lane_hburst_seq_busy_park
coverage:
  ial2_ppif_ahb_interconnect_two_subordinate_requester_busy_insert_three_byte_lane_hburst_seq_busy_park_pipeline_cli
source kind: ppif
class:       supported_smoke
strict:      true
module:      ahb_tb
root:        top
children:    4
```

## Readiness Decision

Direct data-only public contract selection is ready. Leaf `.2` must freeze the
future source/object/anchor/support/test identities, exact four-child and
artifact sets, report/residue truth, normalized semantic/read-only MCP parity,
assertion-enabled 10/8/2/6/2/`44332211`/`88776655` runtime, preservation gates,
diagnostics, support projection, documentation, cleanup, rollback, and a
separate implementation leaf before any source ships.

The future matching `.ahb` alias remains separate. Counts above three,
counter-width generalization, runtime/policy/random/multiple-point insertion,
distinct bus-BUSY status, wider/indefinite bursts, optional signals, generic
priority changes, other protocols/backends, HIAL/VIAL activation, VHDL,
verification generation, and decision `0020` also remain separate/inactive.

## Resource And Cleanup Boundary

All heavy work used the authorized
`--host-max-pct 100 --process-max-rss-mb 4096` profile. Guard occupancy was not
used as RAM-capacity truth. The exact audit workspace contained 56 files /
57,355,098 bytes and was removed without residue.

After the long preservation gate, the canonical Stats-compatible Mach-page
calculation reported 67.8% capacity (16.277/24 GiB) and kernel pressure state
`1` (normal). Capacity used
`active + inactive + speculative + wired + compressor-occupied - purgeable -
file-backed`; pressure remained a separate safety signal.

## Rollback

Revert this audit record/fact and the `.1` completion/`.2` selection pointers.
No shipped source, support entry, test, artifact, or behavior requires rollback.

Clean audit commit `c2aa63c3e` now activates only `.2` contract selection. The
source and projected 325/366/49 public boundary remain unshipped during
activation.
