# IAL2 AHB Paired BUSY Composition Contract Selection

Task-tree owner: `IAL2-FEATURE-COMPLETENESS-FRONTIER.793`

Date: 2026-07-23

## Outcome

`IAL2-FEATURE-COMPLETENESS-FRONTIER.793` selects
`IAL2-FEATURE-COMPLETENESS-FRONTIER.794`, direct implementation of one additive
generic IAL2 AHB aggregate:

```text
source:
  ppif/ahb_interconnect_requester_busy_insert_byte_lane_hburst_seq_busy_park.ppif

intent:
  ahb_interconnect_requester_busy_insert_byte_lane_hburst_seq_busy_park

source object:
  fsmgen-ahb-interconnect-requester-busy-insert-byte-lane-hburst-seq-busy-park

support id:
  intent.ppif_ahb_interconnect_requester_busy_insert_byte_lane_hburst_seq_busy_park

coverage:
  ial2_ppif_ahb_interconnect_requester_busy_insert_byte_lane_hburst_seq_busy_park_pipeline_cli

expected HDL module: ahb_tb
semantic root:       top
```

The first slice composes exactly one shipped BUSY-inserting requester with one
shipped HBURST-aware byte-lane BUSY-parking subordinate. It ships generic
`.ppif` only. The matching `.ahb` alias and a two-subordinate sibling remain
separate later slices.

This contract-selection leaf changes no parser, generator, public source,
support-accounting, test, generated artifact, HDL/runtime, direct-backend,
verification-output, backend-language, AXI/APB, broader AHB, or VHDL behavior.
Decision `0020` and the protocol-neutral transaction-layer horizon remain
proposed/inactive until ongoing work dries out.

## Selected Source Contract

The source is an additive copy of
`ppif/ahb_interconnect_byte_lane_hburst_seq_busy_park.ppif`. It changes only
identity plus the requester selection:

```text
(protocol-platform-intent
  ahb_interconnect_requester_busy_insert_byte_lane_hburst_seq_busy_park
  (profile ahb)
  (source
    (object
      fsmgen-ahb-interconnect-requester-busy-insert-byte-lane-hburst-seq-busy-park)
    ...)
  (ahb-requester amba_requester_busy_insert
    ...
    (transfer
      (idle 2'b00)
      (busy 2'b01)
      (nonseq 2'b10)
      (seq 2'b11)
      (first-beat nonseq)
      (later-beats seq)
      (advance-on ready)
      (busy-before-beat 2))
    ...)
  (ahb-subordinate ahb_lite_subordinate_byte_lane_hburst_seq
    ...
    (transfer ahb_lite_byte_lane_hburst_seq_access
      ...
      (seq-policy hburst-in-word-progressive)
      (ignored-transfer idle)
      (parked-transfer busy)
      ...))
  (ahb-interconnect ahb_tb
    ...
    (children
      (requester requester amba_requester_busy_insert)
      (subordinate regs ahb_lite_subordinate_byte_lane_hburst_seq))
    ...))
```

All local-command, local-status, bus, burst, response, subordinate storage,
decode, address-map, and wiring fields remain identical to the two shipped
endpoint/aggregate contracts. The source stays inside byte-only `WRAP4`/
`INCR4`, the zero-base four-byte window, one register, one requester, one
subordinate, and the existing two-bit requester/one-bit subordinate response
mapping.

The base aggregate BUSY-park source, requester BUSY source, all aliases, and all
other AHB sources remain unchanged.

## Generated Artifacts

The selected source must lower through:

```text
generated IAL1:
  amba_requester_busy_insert.isf
  ahb_lite_subordinate_byte_lane_hburst_seq.isf
  ahb_interconnect.isf

generated IAL0:
  amba_requester_busy_insert.fsm
  ahb_lite_subordinate_byte_lane_hburst_seq.fsm
  ahb_interconnect.fsm
  ahb_tb.fsm

selected HDL entry/module:
  ahb_tb.fsm / ahb_tb
```

No new endpoint, interconnect, composition-top, or HDL generation algorithm is
selected.

## Selected Report Contract

`AhbInterconnect::_child_report` gains one additive conditional field copy:

```text
child.busy_insertion = clone(endpoint.busy_insertion)
    when endpoint.busy_insertion exists
```

For the selected aggregate:

- `children[0]` (requester) exposes `transfer.busy = 2'b01`,
  `transfer.busy_before_beat = 2`, the full `busy_insertion` block, and
  `ahb_requester_busy_insert_support`;
- `children[2]` (subordinate) exposes
  `transfer.seq_policy.parks_on = [busy]` and BUSY-free `clears_on`;
- `composition.seq_policy_propagation.subordinates[0]` preserves the same
  `parks_on = [busy]`; and
- the generated artifact/topology report uses the artifact set above and
  `child_instance_count = 3`.

No new composition-level `busy_flow` summary is selected. The two child-owned
facts are canonical and non-duplicative: requester child `busy_insertion`
states what is driven, while subordinate/aggregate `parks_on` states how it is
received. A higher-level duplicated summary would introduce another surface
that could drift without adding first-slice capability.

Base-requester aggregate reports remain byte-for-byte structurally unchanged:
the conditional field is absent when the endpoint report does not define it.

## Residue Contract

No new top-level residue id is selected.

- The requester child keeps `ahb_requester_busy_insert_support`, recording the
  shipped one-held-presentation subset and deferring broader BUSY policies.
- The subordinate child and aggregate top keep their existing narrowed
  `ahb_burst_seq_support_deferred` text for byte-only `WRAP4`/`INCR4` in-word
  `SEQ` with BUSY parking while deferring halfword/word, wider/indefinite, and
  multi-word progression.
- Generic source-surface alias residue stays present until a later matching
  `.ahb` slice.

The behavior document must explain that the paired proof is read from the
requester child `busy_insertion` together with aggregate `parks_on`, not from a
new top summary.

## Support and Public-Surface Contract

`RegressionCorpus` gains exactly one `supported_smoke` entry:

```text
id:           intent.ppif_ahb_interconnect_requester_busy_insert_byte_lane_hburst_seq_busy_park
relpath:      ppif/ahb_interconnect_requester_busy_insert_byte_lane_hburst_seq_busy_park.ppif
family:       protocol_fixture
coverage:     ial2_ppif_ahb_interconnect_requester_busy_insert_byte_lane_hburst_seq_busy_park_pipeline_cli
source_kind:  ppif
strict:       true
module:       ahb_tb
semantic root: top
```

`t/248` moves from 310 to 311 protocol fixtures and from 351 to 352
supported-smoke/strict entries. `LanguageSurfaceSection` and `t/297` add the
new generic `.ppif` aggregate boundary. No `.ahb` support entry is added.

## Focused Validation Contract

`.794` adds:

```text
t/1513-ial2-ahb-paired-busy-composition.t
t/data/ahb_paired_busy_composition_tb.svt
```

The Perl test must prove:

- tracked source shape and identity;
- exact generated IAL1/IAL0 artifacts and top module;
- requester child transfer/BUSY metadata and residue;
- subordinate child and aggregate `parks_on = [busy]` propagation;
- absence of the optional child field from base-requester aggregate reports;
- strict check JSON, schedule JSON, semantic JSON, outdir artifacts, HDL
  generation, support identity, and `--verify-hdl`; and
- preservation through focused `t/1496` (aggregate BUSY park) and `t/1498`
  (standalone requester BUSY insertion), plus relevant `t/248`/`t/297` gates.

The Verilator harness drives one byte `INCR4` write with:

```text
cmd_addr       = 0
cmd_burst      = 3'b011
cmd_len        = 4
cmd_size       = 0
cmd_write      = 1
wait_cycles    = 0
cmd_wdata      = 32'h11111111
cmd_wdata_step = 32'h11111111
```

It must observe:

```text
NONSEQ(0) -> SEQ(1) -> BUSY(2 held) -> SEQ(2 resumed) -> SEQ(3)
```

and prove:

- exactly one BUSY presentation and four accepted data beats;
- requester address/control/data, `beat_index`, and `beats_remaining` hold
  from BUSY through resumed `SEQ`;
- `dut.regs.seq_valid_q`, `seq_expected_addr_q`, and
  `seq_beats_remaining_q` hold across BUSY;
- `dut.regs.reg_data_q` does not change on BUSY;
- completion has OKAY status, zero remaining beats, no error/retry/split; and
- final register storage is `32'h44332211`.

The harness may observe deterministic generated internal nets/state for focused
proof (`dut.comp_link_requester_*`, `dut.comp_link_interconnect_*`, and
`dut.regs.*`); no new public debug ports are selected.

## Documentation and Continuity

`.794` must add a canonical behavior record and Knowledge Map fact, update
README, ROADMAP_V2, AHB mdBook chapter, feature backlog, language/capability
surface, task tree, and Memory, then regenerate the Knowledge Map. It must run
the focused tests, strict/check/schedule/semantic/outdir paths, generated-HDL
runtime proof, `--verify-hdl`, mdBook build, relative-path, memory, Knowledge
Map, diff, and doctrine gates.

## Explicit Deferrals

The matching `.ahb` alias, two-subordinate paired composition, multi-beat/
policy/runtime BUSY, distinct local bus-BUSY status, halfword/word or wider/
indefinite bursts, multi-word/register-bank progression, optional AHB signals,
legacy two-bit subordinate `HRESP`, broader manager/interconnect behavior,
scoreboards, direct backend, verification output, backend variants, AXI/APB,
and VHDL remain deferred.

## Rollback

`.793` is documentation-only. Rollback removes this contract record and its
Knowledge Map fact, restores `.793` as the active frontier, and reverts README,
roadmap, mdBook, task-tree, Memory, and generated Knowledge Map entries. No
runtime behavior is affected.
