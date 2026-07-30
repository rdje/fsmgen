# IAL2 Post-Exact-Four Paired Alias Next-Owner Selection

## Selection

`IAL2-FEATURE-COMPLETENESS-FRONTIER.826` selects proposed readiness-audit leaf

`IAL2-AHB-TWO-SUBORDINATE-EXACT-FOUR-PAIRED-BUSY-COMPOSITION-READINESS-AUDIT.1`.

The next clean action is to activate only that audit in a separate
no-behavior commit. This selector adds no public source, support entry, test,
testbench, generated artifact, or runtime claim.

## Reconciled Boundary

Clean behavior commit `40b8ead71` completes the one-subordinate exact-four
paired generic/profile pair. Current accounting is 330 protocol fixtures, 371
supported-smoke plus strict fixtures, and 54 AHB paths split 27 `.ppif` / 27
`.ahb`.

The directly adjacent shipped foundations are:

- standalone exact-one through exact-four requester generic/profile sources,
  including width-three `4 -> 3 -> 2 -> 1 -> 0` retirement;
- one-subordinate exact-one through exact-four paired generic/profile sources,
  with assertion-enabled t1537 exact 5/4/1/4/1/`44332211` runtime for
  exact-four and t1538 alias parity;
- two-subordinate exact-one through exact-three paired generic/profile
  sources, with exact 4 IAL1/5 IAL0 artifacts and assertion-enabled t1533
  two-command 10/8/2/6/2/`44332211`/`88776655` runtime for exact-three; and
- completed interconnect, generated-subordinate, and direct-seed output-
  arbitration repairs, so no known AHB lower-layer selector assertion remains
  disabled on these paths.

Decision `0004` requires direct functional simulation before sequential
behavior is claimed. Decision `0008` keeps verification intent in the unified
property/checking model. Decision `0020` remains a proposed, director-gated
transaction-layer horizon and is not activated here.

## Disposable Two-Window Candidate

A repository-derived same-volume candidate mechanically extended the shipped
two-subordinate exact-three generic source by changing only its intent,
source-object, anchor, requester identities, and `(busy-beats 3)` to
`(busy-beats 4)` under future path

`ppif/ahb_interconnect_two_subordinate_requester_busy_insert_four_byte_lane_hburst_seq_busy_park.ppif`.

The 6,645-byte candidate was not tracked or support-accounted. Public probes
established:

- strict check success with zero diagnostics, module `ahb_tb`, four children,
  29 signals, zero top-local states, and intentionally unmatched support;
- unchanged schema `fsmgen.ial2.protocol_intent.ahb_interconnect.v1`, future
  intent/source-object/anchor identity, two status/control windows, and
  one-hot accepted-subordinate response ownership;
- exact IAL1 artifacts `amba_requester_busy_insert_four.isf`, both existing
  subordinate `.isf` files, and `ahb_interconnect.isf`;
- exact IAL0 artifacts `amba_requester_busy_insert_four.fsm`, both existing
  subordinate `.fsm` files, `ahb_interconnect.fsm`, and `ahb_tb.fsm`;
- requester `before_beat=2`/`beats=4`, width-three counter load `4`, both
  subordinate and aggregate `parks_on=[busy]`, and no duplicate top
  `busy_flow`;
- normalized semantic schema v1 at module `ahb_tb`, root `top`, four children,
  and unmatched support;
- real repo-relative `fsmgen_semantic_introspect` parity with
  `read_only=true` and `shell_access=false`; and
- successful public `--verify-hdl` through the existing SystemVerilog path.

The exact disposable workspace contained 11 files and 2,180,377 bytes. It was
removed completely, leaving only the pre-existing 491-byte repository-local
`xcrun_db` cache.

This proves static composition, introspection, and HDL-tool readiness. It does
not prove the combined sequential boundary. The selected audit must recreate
the candidate, keep every selector assertion enabled, and adapt the
two-command runtime to prove exactly 10 transfer presentations, 8 completed
beats, 2 BUSY episodes, 8 qualified BUSY events, 2 resumed `SEQ` events,
status `0x44332211`, and control `0x88776655`.

## Why This Owner Is Next

The SystemVerilog-backed IAL2 feature-completeness lane remains the active
roadmap priority. The selected audit is the smallest adjacent unit that
combines already-shipped exact-four requester behavior with the already-
shipped two-window topology without inventing syntax or policy:

- direct implementation would be premature because decision `0004` forbids
  inferring two-command runtime from compilation or from separate one-window
  exact-four and two-window exact-three tests;
- counts above four require a new range/accounting decision even though the
  current width-three counter has spare representational capacity;
- runtime-selected, policy-selected, random, or multiple-point BUSY insertion,
  distinct bus-BUSY status, wider/indefinite bursts, and optional signals add
  new semantics;
- generic rule/transaction priority addresses a broader protocol-neutral
  correctness surface that this composition does not depend on; and
- HIAL/VIAL, verification generation, VHDL portability, and large-design
  scalability are strategically required but materially broader architecture
  or qualification lanes.

HIAL/VIAL therefore remains proposed. Verilator remains the event-capable
compiled portable-fast supported-subset profile, not the authoritative full-
language SystemVerilog/UVM simulator; VHDL and mixed-language claims remain
independently qualified.

## Selected Audit Boundary

If direct runtime and introspection evidence pass, the audit may select a
separate generic public-contract leaf with projected:

```text
path:
  ppif/ahb_interconnect_two_subordinate_requester_busy_insert_four_byte_lane_hburst_seq_busy_park.ppif
support id:
  intent.ppif_ahb_interconnect_two_subordinate_requester_busy_insert_four_byte_lane_hburst_seq_busy_park
coverage:
  ial2_ppif_ahb_interconnect_two_subordinate_requester_busy_insert_four_byte_lane_hburst_seq_busy_park_pipeline_cli
source kind:   ppif
classification: supported_smoke
strict:        supported
module:        ahb_tb
semantic root: top
children:      4
accounting:    331 protocol / 372 supported+strict / 55 AHB paths
split:         28 .ppif / 27 .ahb
```

The audit must stop and choose the smallest exact repair if assertion-enabled
runtime, normalized semantics, real MCP, or generated HDL disproves the static
candidate. It keeps the future `.ahb` alias, counts above four, new BUSY
semantics, generic priority, other protocols/backends, HIAL/VIAL activation,
VHDL, verification generation, scalability implementation, and decision
`0020` separate.

## Validation And Resource Boundary

The selector changes documentation and task ownership only. Focused current-
surface, backlog, and path tests plus Knowledge Map, mdBook, Memory, diff, and
all doctrine gates close it. Heavy commands use the authorized
`--host-max-pct 100 --process-max-rss-mb 4096` profile. RAM capacity uses the
canonical Stats-compatible Mach-page formula; kernel pressure is reported
separately and guard occupancy is not capacity truth. Generated data stays
under repository-derived same-volume paths and is counted before deletion.

Clean selector commit `4abb0a357` now activates only selected readiness audit
`.1`; activation changes continuity documentation and no behavior.

Completed audit `.1` directly proves real read-only shell-disabled MCP,
public `--verify-hdl`, and assertion-enabled two-command
10/8/2/8/2/`44332211`/`88776655` runtime. It selects pending generic contract
`.2` at projected 331/372/55 split 28 `.ppif`/27 `.ahb`. Clean audit commit
`a5d162d60` and activation commit `93a7f2089` satisfy its activation boundary;
contract `.2` now freezes the exact source/support/t1539/testbench contract and
selects pending data-only implementation `.3` without shipping behavior.

## Rollback

Rollback removes this selection record/fact, the proposed audit tree, and the
handoff from `.826`. It leaves shipped 330/371/54 behavior, existing tests,
generators, semantic/MCP APIs, HIAL/VIAL proposal, and decision `0020`
unchanged.
