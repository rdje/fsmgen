# IAL2 AHB Two-Subordinate Exact-Four Paired BUSY Composition Readiness Audit

Task-tree owner:
`IAL2-AHB-TWO-SUBORDINATE-EXACT-FOUR-PAIRED-BUSY-COMPOSITION-READINESS-AUDIT.1`

Date: 2026-07-30

## Outcome

The shipped exact-four requester composes directly with both shipped
HBURST-aware byte-lane BUSY-parking subordinates and the shipped two-window
AHB fabric through the existing `IAL2 -> IAL1 -> IAL0 -> SystemVerilog` path.
Generated `ahb_tb` compiles and runs with every selector assertion enabled.

No parser, requester, subordinate, interconnect, scheduler, composition-top,
semantic-introspection, MCP-adapter, or HDL repair is required. The audit
selects pending leaf
`IAL2-AHB-TWO-SUBORDINATE-EXACT-FOUR-PAIRED-BUSY-COMPOSITION-READINESS-AUDIT.2`,
a separate no-behavior public-contract selector for the first generic
two-window exact-four paired source. `.2` remains inactive until this audit
commits cleanly and a separate activation commit follows.

This audit ships no public source, support entry, test, checked-in testbench,
generated artifact, semantic/MCP API, HDL/runtime behavior, backend, protocol,
verification-generation, HIAL/VIAL, VHDL, portability, scale, decision-0020,
or transaction-layer behavior.

## Reconciled Boundary

The audit read and preserved:

- standalone exact-four requester and one-window exact-four paired generic/
  profile contracts, width-three `4 -> 3 -> 2 -> 1 -> 0` retirement,
  reports, semantic/MCP exposure, assertion-enabled t1537 runtime, and t1538
  alias parity;
- generic/profile two-window exact-three paired source, artifact, report,
  semantic/MCP, assertion-enabled t1533 runtime, and t1534 alias parity;
- assertion-clean interconnect, generated-subordinate, and direct-seed
  arbitration repairs;
- PPIF parsing plus `AhbRequester`, `AhbSubordinate`, and `AhbInterconnect`
  lowering/report code;
- current RegressionCorpus, strict-support, capability, language-surface,
  normalized-semantic, and read-only MCP contracts at 330 protocol / 371
  supported+strict / 54 AHB paths split 27 `.ppif` / 27 `.ahb`;
- decisions `0004` and `0008`, roadmap, mdBook, task trees, Memory, and the
  Knowledge Map; and
- proposed HIAL/VIAL architecture, generic rule/transaction priority,
  scalability, VHDL/portability, and decision `0020`, none activated here.

## Disposable Candidate

The repository-derived same-volume candidate retained every byte of the
shipped two-window exact-three source except this identity/requester/count
delta:

```text
path:
  ppif/ahb_interconnect_two_subordinate_requester_busy_insert_four_byte_lane_hburst_seq_busy_park.ppif
intent:
  ahb_interconnect_two_subordinate_requester_busy_insert_four_byte_lane_hburst_seq_busy_park
object:
  fsmgen-ahb-interconnect-two-subordinate-requester-busy-insert-four-byte-lane-hburst-seq-busy-park
anchor document:
  FSMGEN-AHB-TWO-SUBORDINATE-BYTE-LANE-HBURST-SEQ-CONTRACT
anchor section:
  bounded-ahb-interconnect-two-subordinate-requester-busy-insert-four-byte-lane-hburst-seq-busy-park
anchor page: first-public-contract
```

The transform changes `busy_insert_three` / `busy-insert-three` to exact-four
and `(busy-beats 3)` to `(busy-beats 4)`. Existing lowering reports:

```text
schema:       fsmgen.ial2.protocol_intent.ahb_interconnect.v1
children:     4
top signals:  29
HDL module:   ahb_tb
owner mode:   one_hot_accepted_subordinate

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
```

The requester reports `busy_before_beat=2`, `busy_beats=4`, and width-three
`ahb_busy_remaining_q`. Generated rules load four, decrement while greater
than one, clear at one, and resume pending `SEQ`. Both status/control children
and aggregate propagation report `parks_on=[busy]`; static windows remain
`[0,4)` and `[4,8)`, response ownership remains one-hot over the accepted
subordinate, and no duplicate top `busy_flow` appears.

Strict check succeeds with zero diagnostics, four children, 29 signals, zero
top-local states, and correctly unmatched support. The schedule exposes the
exact artifacts above, and public `--verify-hdl` passes.

## Semantic And MCP Boundary

Normalized semantic schema v1 reports module `ahb_tb`, source root `top`, four
children, and unmatched support. A real repo-relative
`fsmgen_semantic_introspect` call agrees on module/root/children/support and
reports:

```text
query_kind:   semantic
read_only:    true
shell_access: false
```

The bounded semantic API is sufficient. No feature-specific MCP tool, private
lowering payload, or shell-enabled adapter is required.

## Assertion-Enabled Runtime Proof

Verilator 5.046 compiled generated `ahb_tb` plus a mechanically adapted t1533
harness with `--timing`, `-j 1`, and without `--no-assert`. The harness issued
two four-byte `INCR4` writes, first to status then control, and checked:

- each command retained exactly five distinct transfer presentations and four
  accepted data beats;
- each one-transition BUSY episode contained exactly four
  `HGRANT && HREADY && HTRANS==BUSY` events;
- the remaining counter was four, three, two, then one at qualified BUSY
  events and zero at the single resumed `SEQ`;
- requester address/control/data and beat counters stayed stable through BUSY;
- selected subordinate burst/phase/storage state stayed stable;
- the unselected subordinate remained unchanged for the entire command;
- fabric data-phase ownership remained stable through BUSY; and
- both commands completed cleanly with final status/control storage
  `32'h44332211` / `32'h88776655`.

Observed result:

```text
PASS commands=2 transfers=10 beats=8 busy=2 qualified_busy=8 resumed_seq=2 status=44332211 control=88776655
```

This is a supported-event timing proof in Verilator's compiled model; it is
not a claim that Verilator implements the full event-driven SystemVerilog/UVM
language runtime. Full-language/UVM, VHDL, and mixed-language qualification
remain separate HIAL/VIAL simulator profiles.

## Preservation And Support Projection

The shipped direct adjacent owners pass together:

- t1533 two-window exact-three plus t1537 one-window exact-four: 2 files / 7
  top-level tests / 973 seconds, including 83 and 72 nested assertions; and
- t248 plus t297 support/capability accounting: 2 files / 7,007 tests.

One new generic supported-smoke/strict path projects 331 protocol paths, 372
supported-smoke paths, 372 strict paths, and 55 AHB paths split 28 `.ppif` /
27 `.ahb`. Contract `.2` must reconfirm and freeze:

```text
support id:
  intent.ppif_ahb_interconnect_two_subordinate_requester_busy_insert_four_byte_lane_hburst_seq_busy_park
coverage:
  ial2_ppif_ahb_interconnect_two_subordinate_requester_busy_insert_four_byte_lane_hburst_seq_busy_park_pipeline_cli
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
assertion-enabled 10/8/2/8/2/`44332211`/`88776655` runtime, preservation gates,
diagnostics, support projection, documentation, cleanup, rollback, and a
separate implementation leaf before any source ships.

Clean audit commit `a5d162d60` activates only contract selector `.2`.
Activation changes continuity documentation only: public accounting remains
330/371/54 split 27 `.ppif`/27 `.ahb`, and the future generic source, support
entry, t1539, and testbench remain absent until a separately selected
implementation leaf ships them.

Contract `.2` now freezes that exact generic source, support/coverage identity,
four-IAL1/five-IAL0 architecture, semantic/read-only-MCP surface, all-assertion
t1539 10/8/2/8/2/`44332211`/`88776655` runtime, preservation set, projected
331/372/55 split 28 `.ppif`/27 `.ahb`, and exact rollback. Pending data-only
implementation `.3` is separate; selection itself ships no source or behavior.
See
`docs/IAL2_AHB_TWO_SUBORDINATE_EXACT_FOUR_PAIRED_BUSY_COMPOSITION_CONTRACT_SELECTION.md`.

The future matching `.ahb` alias remains separate. Counts above four,
runtime/policy/random/multiple-point insertion, distinct bus-BUSY status,
wider/indefinite bursts, optional signals, generic priority changes, other
protocols/backends, HIAL/VIAL, VHDL, verification generation, portability,
scale implementation, and decision `0020` remain separate/inactive.

## Resource And Cleanup Boundary

All heavy work used authorized
`--host-max-pct 100 --process-max-rss-mb 4096`. Guard occupancy was not used as
RAM-capacity truth. The exact audit workspace contained 47 files / 56,921,569
bytes and was removed without residue; only the pre-existing repository-local
491-byte `xcrun_db` cache remains.

Capacity uses the canonical Stats-compatible Mach-page calculation
`active + inactive + speculative + wired + compressor-occupied - purgeable -
file-backed`; kernel pressure remains a separate safety signal.

## Rollback

Revert this audit record/fact and the `.1` completion/`.2` selection pointers.
No shipped source, support entry, test, artifact, or behavior requires
rollback.
