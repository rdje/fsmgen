# IAL2 Post-Exact-Three Paired Alias Next-Owner Selection

## Selection

`IAL2-FEATURE-COMPLETENESS-FRONTIER.819` selects proposed readiness-audit leaf

`IAL2-AHB-TWO-SUBORDINATE-EXACT-THREE-PAIRED-BUSY-COMPOSITION-READINESS-AUDIT.1`.

The next clean action is to activate that audit in a separate no-behavior
commit. The selector does not add a two-subordinate source, support entry,
test, testbench, generated artifact, or runtime claim.

## Reconciled Boundary

Clean behavior commit `d94f303d8` completes the one-subordinate exact-three
generic/profile pair through existing lowering and introspection machinery.
Current accounting is 324 protocol fixtures, 365 supported-smoke plus strict
fixtures, and 48 AHB paths split 24 `.ppif` / 24 `.ahb`.

The directly adjacent shipped foundations are:

- standalone exact-three requester generic/profile sources with width-two
  `3 -> 2 -> 1 -> 0` qualified retirement;
- one-subordinate exact-three paired generic/profile sources, exact 3 IAL1/4
  IAL0 artifacts, t1531 assertion-enabled 5/4/1/3/1/`44332211` runtime, and
  t1532 alias parity;
- two-subordinate exact-two paired generic/profile sources, exact 4 IAL1/5
  IAL0 artifacts, t1525 assertion-enabled two-command runtime, and t1526 alias
  parity; and
- completed interconnect, generated-subordinate, and direct-seed output-
  arbitration repairs, so no known AHB lower-layer selector assertion remains
  disabled on these paths.

Decision `0004` requires direct functional simulation before control-flow or
sequential behavior is claimed. Decision `0008` keeps verification intent in
the unified property/checking model. Decision `0020` remains a future,
director-gated transaction-layer horizon and is not PNT-eligible.

## Disposable Two-Window Candidate

A repository-derived same-volume candidate mechanically extended the shipped
two-subordinate exact-two generic source by selecting
`amba_requester_busy_insert_three` and `(busy-beats 3)` under future path

`ppif/ahb_interconnect_two_subordinate_requester_busy_insert_three_byte_lane_hburst_seq_busy_park.ppif`.

The 6,650-byte candidate itself was not tracked or support-accounted. Public
probes established:

- strict check success with zero diagnostics, module `ahb_tb`, four children,
  29 signals, and intentionally unmatched support accounting;
- unchanged schema `fsmgen.ial2.protocol_intent.ahb_interconnect.v1`, future
  intent/source-object/anchor identity, and requester-subordinate-interconnect
  mode;
- exact IAL1 artifacts `amba_requester_busy_insert_three.isf`,
  `ahb_status_subordinate_byte_lane_hburst_seq.isf`,
  `ahb_control_subordinate_byte_lane_hburst_seq.isf`, and
  `ahb_interconnect.isf`;
- exact IAL0 artifacts `amba_requester_busy_insert_three.fsm`, both
  subordinate `.fsm` files, `ahb_interconnect.fsm`, and `ahb_tb.fsm`;
- requester `before_beat=2`/`beats=3`, both subordinate contexts and aggregate
  propagation at `parks_on=[busy]`, and one-hot accepted-subordinate response
  ownership;
- normalized semantic schema v1 with generated snapshot `ahb_tb`, root `top`,
  four children, 29 signals, no diagnostics, and unmatched support; and
- successful `--verify-hdl` through the current SystemVerilog path.

The exact disposable workspace contained three files and 62,001,772 bytes:
the candidate, normalized-semantic JSON, and generated SystemVerilog. It was
removed completely and residue is zero.

This evidence proves static composition and HDL-tool readiness. It does not
prove the combined sequential boundary. The selected audit must recreate the
candidate, use the real read-only shell-disabled MCP path, keep every selector
assertion enabled, and adapt the two-command runtime to prove exactly 10
transfer presentations, 8 completed beats, 2 BUSY episodes, 6 qualified BUSY
events, 2 resumed `SEQ` events, status `0x44332211`, and control `0x88776655`.

## Why This Owner Is Next

The SystemVerilog-backed IAL2 feature-completeness lane remains the active
roadmap priority. The selected readiness audit is the smallest adjacent unit
that combines already-shipped behavior without inventing new syntax or policy:

- direct implementation would be premature because decision `0004` forbids
  inferring two-command runtime from compilation or from separate one-window
  exact-three and two-window exact-two tests;
- counts above three require a counter-width/range contract and new diagnostics;
- runtime-selected, policy-selected, random, or multiple-point BUSY insertion,
  distinct bus-BUSY status, wider/indefinite bursts, and optional signals add
  new semantics;
- the proposed generic rule/transaction output-priority repair addresses a
  real protocol-neutral correctness gap, but current AHB paired sources avoid
  that conflicting authoring route and the two-window audit does not depend on
  it; and
- HIAL/VIAL is strategically important but remains a broad architecture audit
  spanning layer topology, typed bridge, portable/native semantics, backend
  parity, simulator qualification, migration, and large-design gates. The
  bounded AHB audit is smaller and directly closes the active IAL2 family.

HIAL/VIAL therefore remains proposed. Verilator remains the event-capable
compiled portable-fast subset profile, not the authoritative full-language
SystemVerilog/UVM simulator; VHDL and mixed-language claims remain separately
qualified. See the prior
[`IAL2_POST_EXACT_THREE_PAIRED_COMPOSITION_NEXT_OWNER_SELECTION`](IAL2_POST_EXACT_THREE_PAIRED_COMPOSITION_NEXT_OWNER_SELECTION.md)
for the official-tool evidence and precise simulator distinction.

## Selected Audit Boundary

If the direct runtime and introspection evidence pass, the audit may select a
separate generic public-contract leaf with projected:

```text
path:
  ppif/ahb_interconnect_two_subordinate_requester_busy_insert_three_byte_lane_hburst_seq_busy_park.ppif
support id:
  intent.ppif_ahb_interconnect_two_subordinate_requester_busy_insert_three_byte_lane_hburst_seq_busy_park
coverage:
  ial2_ppif_ahb_interconnect_two_subordinate_requester_busy_insert_three_byte_lane_hburst_seq_busy_park_pipeline_cli
source kind:   ppif
classification: supported_smoke
strict:        supported
module:        ahb_tb
semantic root: top
children:      4
accounting:    325 protocol / 366 supported+strict / 49 AHB paths
split:         25 .ppif / 24 .ahb
```

The audit must stop and choose the smallest exact repair if assertion-enabled
runtime, normalized semantics, real MCP, or generated HDL disproves the static
candidate. It must keep the future `.ahb` alias, counts above three, new BUSY
semantics, generic priority, other protocols/backends, HIAL/VIAL activation,
VHDL, verification generation, and decision `0020` separate.

## Validation And Resource Boundary

The selector itself changes documentation and task ownership only. Focused
current-surface, backlog, and path tests plus Knowledge Map, mdBook, Memory,
diff, and all doctrine gates close it. Heavy commands use the authorized
`--host-max-pct 100 --process-max-rss-mb 4096` profile. RAM capacity uses the
canonical Stats-compatible Mach-page formula; kernel pressure is reported
separately and guard occupancy is not capacity truth. All generated data stays
under repository-derived same-volume paths and is counted before deletion.

## Rollback

Rollback removes this selection record/fact, the proposed audit tree, and the
pending handoff from `.819`. It leaves the shipped 324/365/48 generic/profile
behavior, existing tests, generators, semantic/MCP APIs, HIAL/VIAL proposal,
and decision `0020` unchanged.
