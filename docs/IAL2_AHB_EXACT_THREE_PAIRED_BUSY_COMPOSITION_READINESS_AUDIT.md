# IAL2 AHB Exact-Three Paired BUSY Composition Readiness Audit

Task-tree owner:
`IAL2-AHB-EXACT-THREE-PAIRED-BUSY-COMPOSITION-READINESS-AUDIT.1`

Date: 2026-07-29

## Outcome

The shipped exact-three requester composes directly with the shipped
byte-lane/HBURST-SEQ/BUSY-parking subordinate and one-window AHB interconnect
through the existing `IAL2 -> IAL1 -> IAL0 -> SystemVerilog` path. The
generated aggregate compiles and runs with every selector assertion enabled.

No parser, requester, subordinate, interconnect, scheduler, composition-top,
semantic-introspection, MCP-adapter, or HDL repair is required. The audit
selects
`IAL2-AHB-EXACT-THREE-PAIRED-BUSY-COMPOSITION-READINESS-AUDIT.2`, a separate
no-behavior public-contract selector for the first generic one-subordinate
source.

This audit ships no public source, support entry, test, checked-in generated
artifact, semantic/MCP API, HDL/runtime behavior, backend, protocol,
verification-generation, HIAL/VIAL, VHDL, or transaction-layer behavior.

## Reconciled Boundary

The audit read and preserved:

- the standalone exact-three requester `.ppif`/`.ahb` contracts, behavior,
  width-two counter, reports, semantic/MCP exposure, and t1528 runtime;
- generic/alias exact-two paired one-/two-subordinate source, artifact,
  report, semantic/MCP, and t1523-t1526 owners;
- the assertion-clean interconnect, generated-subordinate, and direct-seed
  arbitration repairs, including t1520;
- PPIF parsing plus `AhbRequester`, `AhbSubordinate`, and `AhbInterconnect`
  lowering/report code;
- current RegressionCorpus, strict-support, capability, language-surface,
  normalized-semantic, and read-only MCP contracts at 322 protocol / 363
  supported+strict / 46 AHB paths split 23 `.ppif` / 23 `.ahb`;
- current roadmap, mdBook, task trees, Memory, Knowledge Map, and historical
  selectors that deferred this audit behind assertion repairs; and
- proposed HIAL/VIAL architecture and decision 0020, neither of which is
  activated or changed here.

## Disposable Candidate

The repository-derived same-volume candidate used the future generic identity:

```text
path:    ppif/ahb_interconnect_requester_busy_insert_three_byte_lane_hburst_seq_busy_park.ppif
intent:  ahb_interconnect_requester_busy_insert_three_byte_lane_hburst_seq_busy_park
object:  fsmgen-ahb-interconnect-requester-busy-insert-three-byte-lane-hburst-seq-busy-park
anchor:  ARM-AMBA-AHB-IHI0033-C-2021-09 /
         bounded-ahb-interconnect-requester-busy-insert-three-byte-lane-hburst-seq-busy-park /
         first-public-contract
```

It retained the exact-two paired source architecture and changed only the
aggregate/requester identities plus `(busy-beats 3)`. Existing lowering
reported:

```text
schema:       fsmgen.ial2.protocol_intent.ahb_interconnect.v1
children:     3
HDL module:   ahb_tb
owner mode:   one_hot_accepted_subordinate

IAL1:
  amba_requester_busy_insert_three.isf
  ahb_lite_subordinate_byte_lane_hburst_seq.isf
  ahb_interconnect.isf

IAL0:
  amba_requester_busy_insert_three.fsm
  ahb_lite_subordinate_byte_lane_hburst_seq.fsm
  ahb_interconnect.fsm
  ahb_tb.fsm
```

The requester report exposes `busy_insertion.before_beat=2`, numeric
`busy_insertion.beats=3`, and the existing width-two
`ahb_busy_remaining_q`. Generated rules load three, decrement while greater
than one, clear at one, and resume the pending `SEQ`, giving
`3 -> 2 -> 1 -> 0`. The subordinate and aggregate propagation both report
`parks_on=[busy]`; the aggregate does not duplicate child facts in a top-level
`busy_flow` object.

Strict check succeeds with top `ahb_tb`, three children, and zero diagnostics.
The disposable source correctly reports `support_accounting.matched=false`;
the audit does not pretend the future path is already shipped.

## Semantic and MCP Boundary

Normalized semantic JSON reports module `ahb_tb`, source root `top`, three
children, and unmatched disposable support. A real
`fsmgen_semantic_introspect` call against the same repo-relative source reports
the same module/root/child/support values with:

```text
query_kind:  semantic
read_only:   true
shell_access:false
```

The existing bounded semantic API is sufficient. No feature-specific MCP tool,
raw private lowering payload, or shell-enabled adapter is needed.

## Assertion-Enabled Runtime Proof

Verilator compiled the generated `ahb_tb` and the mechanically extended
exact-two harness without `--no-assert`. The harness drove one zero-base byte
`INCR4` write with four data beats and checked:

- presentation order remained
  `NONSEQ(0) -> SEQ(1) -> BUSY(2 held) -> SEQ(2 resumed) -> SEQ(3)`;
- the one BUSY transition episode contained exactly three
  `HGRANT && HREADY && HTRANS==BUSY` events;
- remaining count was three, two, then one at the qualified BUSY events and
  zero at resumed `SEQ`;
- requester address/control/data and beat counters stayed stable throughout
  BUSY;
- subordinate SEQ continuation, phase ownership, and storage stayed stable;
- interconnect data-phase ownership stayed stable;
- BUSY completed no data beat, the pending transfer resumed exactly once, and
  four byte data beats completed with clean status; and
- final storage was `32'h44332211`.

Observed result:

```text
PASS transfers=5 beats=4 busy=1 qualified_busy=3 resumed_seq=1 storage=44332211
```

## Preservation and Support Projection

Current owners pass:

- t1520 direct seed;
- t1523 generic one-subordinate exact-two pairing;
- t1525 generic two-subordinate exact-two pairing;
- t1528 standalone exact-three requester (1 file / 5 tests / 51 seconds); and
- t248 plus t297 support/capability accounting (2 files / 6,911 tests).

The first combined preservation invocation supplied a nonexistent t1528
filename after t1520/t1523/t1525 had already reported `ok`; it therefore ended
as a harness-source error, not a product/test failure. The exact tracked
`t/1528-ial2-ahb-requester-three-busy-insert.t` was then resolved and passed.

One new generic supported-smoke/strict path projects 323 protocol paths, 364
supported-smoke paths, 364 strict paths, and 47 AHB paths split 24 `.ppif` /
23 `.ahb`. Contract `.2` must reconfirm and freeze:

```text
support id:
  intent.ppif_ahb_interconnect_requester_busy_insert_three_byte_lane_hburst_seq_busy_park
coverage:
  ial2_ppif_ahb_interconnect_requester_busy_insert_three_byte_lane_hburst_seq_busy_park_pipeline_cli
source kind: ppif
class:       supported_smoke
strict:      true
```

## Readiness Decision

Direct data-only public contract selection is ready. Leaf `.2` must freeze the
future source/object/anchor/support/test identities, exact three-child and
artifact sets, report/residue truth, normalized semantic/read-only MCP parity,
assertion-enabled 5/4/1/3/1/`44332211` runtime, preservation gates,
diagnostics, support projection, documentation, cleanup, and rollback before a
separate implementation leaf is selected.

The matching `.ahb` alias and two-subordinate exact-three topology remain
separate future slices. Counts above three, counter-width generalization,
runtime/policy/multiple-point insertion, distinct bus-BUSY status, wider or
indefinite bursts, optional AHB signals, generic priority changes, other
protocols/backends, HIAL/VIAL activation, VHDL, verification generation, and
decision 0020 also remain separate/inactive.

## Resource and Cleanup Boundary

All heavy work used the authorized
`--host-max-pct 100 --process-max-rss-mb 4096` profile. Guard occupancy was not
used as RAM-capacity truth. The exact audit workspace contained 54 files /
53,575,735 bytes and was removed without residue.

After the long preservation and closeout gates, the exact Stats-compatible
Mach calculation reported 86.8% capacity (20.84/24.00 GiB) and kernel pressure
state `2` (warning). No additional heavy work was started at that state; this
real safety reading is separate from the guard's cache-heavy host percentage.

## Rollback

Revert this audit record/fact and the `.1` completion/`.2` selection pointers.
No shipped source, support entry, test, artifact, or behavior requires rollback.
