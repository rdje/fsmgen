# IAL2 AHB Exact-Four Paired BUSY Composition Readiness Audit

Task-tree owner:
`IAL2-AHB-EXACT-FOUR-PAIRED-BUSY-COMPOSITION-READINESS-AUDIT.1`

Date: 2026-07-29

## Outcome

The shipped exact-four requester composes directly with the shipped
byte-lane/HBURST-SEQ/BUSY-parking subordinate and one-window AHB interconnect
through the existing `IAL2 -> IAL1 -> IAL0 -> SystemVerilog` path. Generated
`ahb_tb` compiles and runs with every selector assertion enabled.

No parser, requester, subordinate, interconnect, scheduler, semantic/MCP,
composition-top, or HDL repair is required. The audit selects separate
no-behavior public-contract leaf
`IAL2-AHB-EXACT-FOUR-PAIRED-BUSY-COMPOSITION-READINESS-AUDIT.2`.

This audit ships no public source, support entry, test, checked-in generated
artifact, semantic/MCP API, HDL/runtime behavior, backend, protocol,
verification-generation, HIAL/VIAL, VHDL, or transaction behavior.

## Reconciled Boundary

The audit preserved:

- exact-four requester generic/alias behavior, width-three state, reports,
  semantic/read-only-MCP surfaces, t1535 runtime, and t1536 alias parity;
- exact-three one-subordinate generic/alias paired behavior, assertion-enabled
  t1531 runtime, and t1532 alias parity;
- assertion-clean requester, subordinate, interconnect, composition-top, and
  direct-seed lower layers;
- current support/language/capability truth at 328 protocol / 369
  supported-smoke plus strict / 52 AHB paths split 26 `.ppif` / 26 `.ahb`;
- current roadmap, mdBook, task trees, Memory, Knowledge Map, proposed
  HIAL/VIAL, scalability, and decisions 0004/0008/0020.

## Disposable Candidate

The repository-derived same-volume candidate used future generic identity:

```text
path:    ppif/ahb_interconnect_requester_busy_insert_four_byte_lane_hburst_seq_busy_park.ppif
intent:  ahb_interconnect_requester_busy_insert_four_byte_lane_hburst_seq_busy_park
object:  fsmgen-ahb-interconnect-requester-busy-insert-four-byte-lane-hburst-seq-busy-park
anchor:  ARM-AMBA-AHB-IHI0033-C-2021-09 /
         bounded-ahb-interconnect-requester-busy-insert-four-byte-lane-hburst-seq-busy-park /
         first-public-contract
```

It retained the tracked exact-three paired architecture and changed only the
intent/object/anchor/requester identities plus `(busy-beats 4)`. Strict check
succeeds at top `ahb_tb`, three children, 28 signals, zero diagnostics, and
correctly unmatched disposable support.

Schedule output preserves schema
`fsmgen.ial2.protocol_intent.ahb_interconnect.v1`, one-hot accepted-subordinate
response ownership, same-edge replacement, requester `before_beat=2` /
`beats=4`, child and propagated `parks_on=[busy]`, and no duplicate top
`busy_flow`. Lowering emits exactly:

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
```

The requester IAL1 declares width-three `ahb_busy_remaining_q`, loads four,
decrements only qualified values greater than one, and clears at one while
resuming the same pending `SEQ`. Public `--verify-hdl` passes.

## Semantic And MCP Boundary

Normalized semantic JSON reports schema 1, module `ahb_tb`, root `top`, three
children, 28 signals, generated SystemVerilog, and unmatched support. A real
`fsmgen_semantic_introspect` call against the repository-relative candidate
agrees on module/root/children/signals/support and reports:

```text
query_kind:   semantic
read_only:    true
shell_access: false
```

No feature-specific MCP tool, raw private payload, or shell-enabled adapter is
required.

## Assertion-Enabled Runtime

Verilator 5.046 compiled generated `ahb_tb` with `--timing`, `-j 1`, and no
`--no-assert`. A mechanically adapted exact-three harness changed only its
module identity, expected internal count sequence, and qualified-event total.
It proved:

- presentation order remained `NONSEQ(0) -> SEQ(1) -> BUSY(2 held) -> SEQ(2
  resumed) -> SEQ(3)`;
- one BUSY transition episode contained exactly four
  `HGRANT && HREADY && HTRANS==BUSY` events;
- internal remaining state retired `4 -> 3 -> 2 -> 1 -> 0`;
- BUSY completed no data beat and held address/control/write-data, requester
  beat counters, subordinate SEQ/phase/storage, and interconnect owner state;
- the pending transfer resumed exactly once as `SEQ`;
- four byte data beats completed with clean response/status; and
- final storage was `32'h44332211`.

Observed result:

```text
PASS transfers=5 beats=4 busy=1 qualified_busy=4 resumed_seq=1 storage=44332211
```

## Preservation And Projection

t1531, t1535, and t1536 pass 3 files / 13 top-level tests in 459 seconds,
covering exact-three paired runtime, standalone exact-four continuous and
32-clock ready-low/grant-low runtime, and exact-four alias parity. t248 plus
t297 pass 2 files / 6,983 assertions at the unchanged 328/369/52 baseline.

One future generic supported-smoke/strict source projects 329 protocol paths,
370 supported-smoke paths, 370 strict paths, and 53 AHB paths split 27 `.ppif`
/ 26 `.ahb`. Contract `.2` must freeze:

```text
support id:
  intent.ppif_ahb_interconnect_requester_busy_insert_four_byte_lane_hburst_seq_busy_park
coverage:
  ial2_ppif_ahb_interconnect_requester_busy_insert_four_byte_lane_hburst_seq_busy_park_pipeline_cli
source kind: ppif
class:       supported_smoke
strict:      true
module/root: ahb_tb / top
children:    3
```

Focused t1537 should own tracked source/report/artifact/semantic/read-only-MCP/
verifier parity and the assertion-enabled 5/4/1/4/1/`44332211` runtime. The
matching `.ahb` alias and two-subordinate exact-four topology remain separate.

Completed `.2` froze those boundaries and selected `.3` data-only
implementation. Completed `.3` now ships the generic source at 329/370/53
split 27 `.ppif` / 26 `.ahb`; focused t1537 carries the exact semantic/MCP and
assertion-enabled runtime proof. See
`docs/IAL2_AHB_EXACT_FOUR_PAIRED_BUSY_COMPOSITION_BEHAVIOR.md`.
See
`docs/IAL2_AHB_EXACT_FOUR_PAIRED_BUSY_COMPOSITION_CONTRACT_SELECTION.md`.

## Resource, Cleanup, And Rollback

All heavy work used authorized `--host-max-pct 100 --process-max-rss-mb 4096`.
The exact audit workspace contained 55 files / 53,570,345 bytes and was removed
without residue. The project-local temp census then retained only the 491-byte
`xcrun_db` tool cache. Capacity truth uses the Stats-compatible Mach formula
with kernel pressure reported separately, never guard occupancy.

Focused t1518+t1256+t1414 pass 3 files / 22 top-level tests. Knowledge Map
generation/check reaches 1,039 facts / 5,309 keys. mdBook builds exactly 72
files / 16,288,180 bytes and its exact render is removed. All doctrine gates
pass. Post-heavy canonical RAM is 74.9% (17.968/24.000 GiB;
19,292,684,288 bytes) with normal kernel pressure level 1; the unrelated
`memory_pressure -Q` free percentage is not inverted into usage.

Rollback removes this audit record/fact and returns `.1` to active while
removing pending `.2`. No shipped source, support entry, test, artifact, or
behavior requires rollback.
