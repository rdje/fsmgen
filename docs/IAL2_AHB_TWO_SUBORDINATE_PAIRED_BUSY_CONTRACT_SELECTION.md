# IAL2 AHB Two-Subordinate Paired BUSY Contract Selection

Task-tree owner: `IAL2-FEATURE-COMPLETENESS-FRONTIER.800`

Date: 2026-07-23

## Outcome

`.800` selects `IAL2-FEATURE-COMPLETENESS-FRONTIER.801`, direct implementation
of one additive generic IAL2 AHB aggregate:

```text
source:
  ppif/ahb_interconnect_requester_busy_insert_two_subordinate_byte_lane_hburst_seq_busy_park.ppif

intent:
  ahb_interconnect_requester_busy_insert_two_subordinate_byte_lane_hburst_seq_busy_park

source object:
  fsmgen-ahb-interconnect-requester-busy-insert-two-subordinate-byte-lane-hburst-seq-busy-park

support id:
  intent.ppif_ahb_interconnect_requester_busy_insert_two_subordinate_byte_lane_hburst_seq_busy_park

coverage:
  ial2_ppif_ahb_interconnect_requester_busy_insert_two_subordinate_byte_lane_hburst_seq_busy_park_pipeline_cli

source kind:       ppif
expected module:   ahb_tb
child count:       4
semantic root:     top
module signals:    29
```

The slice composes the shipped one-BUSY requester with both shipped
status/control BUSY-parking subordinates in the existing two-window aggregate.
It ships generic `.ppif` only. A matching `.ahb` alias remains a separate
post-implementation selection so generic behavior and runtime proof land first.

This contract-selection leaf changes no parser, generator, report, public
source, support accounting, test, artifact, HDL/runtime behavior, backend,
AXI/APB, or VHDL behavior. Decision `0020`, its transaction-layer horizon, and
proposed audits remain inactive.

## Exact Source Contract

The new source is an additive copy of:

```text
ppif/ahb_interconnect_two_subordinate_byte_lane_hburst_seq_busy_park.ppif
```

Its only allowed source differences are:

1. intent name;
2. source-object id and anchor section;
3. requester object `amba_requester` → `amba_requester_busy_insert`;
4. requester transfer adds `(busy 2'b01)` and `(busy-before-beat 2)`; and
5. the interconnect requester child reference uses
   `amba_requester_busy_insert`.

The selected source anchor is:

```text
document: FSMGEN-AHB-TWO-SUBORDINATE-BYTE-LANE-HBURST-SEQ-CONTRACT
section:  bounded-ahb-interconnect-requester-busy-insert-two-subordinate-byte-lane-hburst-seq-busy-park
page:     first-public-contract
```

Status/control subordinates, storage, wait controls, bus bindings, HBURST and
BUSY-park clauses, address map, decode, response mux, global wiring, and all
other requester fields remain byte-identical to the base source. In particular:

```text
status window:  base 0, size 4, limit 4
control window: base 4, size 4, limit 8

status local address:  HADDR
control local address: HADDR - 4
```

The bounded behavior remains byte transfers within one word, HBURST `WRAP4` or
`INCR4`, one requester, two static windows, one register per subordinate, and
the shipped requester/subordinate response mapping.

## Generated Artifact Contract

The source must lower through exactly:

```text
generated IAL1:
  amba_requester_busy_insert.isf
  ahb_status_subordinate_byte_lane_hburst_seq.isf
  ahb_control_subordinate_byte_lane_hburst_seq.isf
  ahb_interconnect.isf

generated IAL0:
  amba_requester_busy_insert.fsm
  ahb_status_subordinate_byte_lane_hburst_seq.fsm
  ahb_control_subordinate_byte_lane_hburst_seq.fsm
  ahb_interconnect.fsm
  ahb_tb.fsm

HDL entry/module:
  ahb_tb.fsm / ahb_tb
```

No endpoint, interconnect, top, or HDL generation algorithm is added. `.798`
already proved this exact four-child shape through check, schedule, semantic,
outdir, SystemVerilog, and Yosys surfaces.

## Report and Residue Contract

Schedule/report JSON retains schema
`fsmgen.ial2.protocol_intent.ahb_interconnect.v1` and must expose:

- source object and intent selected above;
- `composition.child_instance_count = 4`;
- `children[0].object_name = amba_requester_busy_insert`;
- requester transfer `busy = 2'b01`, `busy_before_beat = 2`, and the complete
  shipped `busy_insertion` block;
- status/control child `transfer.seq_policy.parks_on = [busy]` and BUSY-free
  `clears_on` at child indices 2 and 3;
- both status/control entries in
  `composition.seq_policy_propagation.subordinates`, preserving
  `parks_on = [busy]`;
- exact `[0,4)` and `[4,8)` address-map entries; and
- the artifact and HDL entry set above.

No duplicated composition-level `busy_flow` is added. Requester child
`busy_insertion` remains the canonical driven-policy fact; the two child and
propagated `parks_on` fields remain the canonical receive-policy facts.

After `.799`, the generic top residue must be internally consistent:

- `ahb_broader_interconnect_decode_deferred` positively records shipped
  byte-only `WRAP4`/`INCR4` in-word `SEQ` propagation with BUSY-in-burst
  parking and does not defer BUSY continuation;
- `ahb_burst_seq_support_deferred` retains the same shipped BUSY-parking claim;
- requester child `ahb_requester_busy_insert_support` retains the bounded
  single held BUSY-presentation claim; and
- generic aggregate/requester/subordinate profile-alias residue remains until
  a later `.ahb` slice.

No residue id or structure changes in `.801`.

## Support and Public-Surface Contract

`RegressionCorpus` gains exactly one `supported_smoke` entry using the identity
above, `strict_supported = 1`, expected module `ahb_tb`, semantic root `top`,
and check/semantic child count 4.

Accounting moves exactly:

```text
protocol fixtures:       312 -> 313
supported-smoke entries: 353 -> 354
strict positive entries: 353 -> 354
```

`LanguageSurfaceSection` adds the generic two-subordinate paired source to the
bounded `.ppif` list. `t/297` locks that public boundary; `t/248` locks the new
entry, coverage classification, counts, source kind, strict support, module,
semantic root, and child counts. No `.ahb` support entry or alias wording is
added.

## Focused Runtime Contract

`.801` adds:

```text
t/1515-ial2-ahb-two-subordinate-paired-busy-composition.t
t/data/ahb_two_subordinate_paired_busy_composition_tb.svt
```

The Perl test must prove source identity/delta, exact IAL1/IAL0 artifacts,
module/child/signal shape, requester `busy_insertion`, both child and propagated
BUSY parks, corrected broader/burst residue, support identity, strict check,
schedule, semantic, outdir, generated HDL, and `--verify-hdl`.

The Verilator harness uses zero wait cycles and issues two sequential byte
`INCR4` writes:

| Command | Address | Initial data | Step | Expected final storage |
|---|---:|---:|---:|---:|
| status | `0` | `32'h11111111` | `32'h11111111` | `status_data_q = 32'h44332211` |
| control | `4` | `32'h55555555` | `32'h11111111` | `control_data_q = 32'h88776655` |

Each command must observe exactly:

```text
NONSEQ(0) -> SEQ(1) -> BUSY(2 held) -> SEQ(2 resumed) -> SEQ(3)
```

For each command, the harness proves:

- one BUSY presentation, four accepted data beats, and no extra transfer;
- requester address/control/data plus beat index and remaining count hold from
  BUSY through resumed `SEQ`;
- only the selected subordinate is selected;
- selected-child `seq_valid_q`, `seq_expected_addr_q`,
  `seq_beats_remaining_q`, and storage hold across BUSY;
- the unselected child's context/storage remain unchanged throughout;
- status local addresses progress `0,1,2,2,3` for the five presentations;
- control global addresses progress `4,5,6,6,7` while `HADDR_CONTROL`
  progresses locally `0,1,2,2,3`;
- completion reports OKAY, zero remaining beats, and no error/retry/split; and
- after the second command, status remains `32'h44332211` while control is
  `32'h88776655`.

The harness may observe deterministic generated nets/state under
`dut.comp_link_requester_*`, `dut.comp_link_fabric_*`, `dut.status.*`, and
`dut.control.*`. No public debug port is added.

## Diagnostics and Preservation

No new diagnostic is selected. Existing requester validation owns malformed
BUSY encodings/insertion indices; subordinate validation owns malformed
ignored/parked transfer combinations; interconnect validation owns child,
address-map, binding, and topology mismatches. The additive tracked source must
pass those unchanged validators.

`.801` must preserve:

- the one-subordinate paired generic/alias source and t/1513/t/1514 runtime and
  parity proof;
- the two-subordinate BUSY-park generic/alias source and t/1496/t/1497;
- the non-parking generic/alias deferral locked by t/1492/t/1493;
- the `.799` broader-residue repair;
- all existing sources, support ids/counts other than the exact +1 entry,
  generated artifact names, report schema/shape, and runtime behavior; and
- direct-backend, verification-output, backend-language, AXI/APB, and VHDL
  boundaries.

Focused implementation validation runs t/1515 plus t/1513, t/1514, t/1492,
t/1493, t/1496, t/1497, t/248, and t/297 as warranted. Heavy commands use
direct macOS `memory_pressure -Q` plus descendant RSS observation because the
known repository wrapper host-percentage metric over-counts inactive cache.

## Documentation and Continuity

`.801` must add the public behavior page and Knowledge Map fact, sync README,
ROADMAP_V2, AHB mdBook chapter, backlog, language/capability surfaces, task
tree, and bounded Memory, then run Knowledge Map, mdBook, relative-path,
Memory, diff, and doctrine gates.

## Alias Sequencing and Explicit Deferrals

The matching `.ahb` alias is not bundled. After `.801` ships the generic source
and runtime proof, the next selector may choose a byte-identical profile alias
with alias-only residue cleanup and no new generator. Until then, that alias,
broader BUSY policies/status, halfword/word or wider/indefinite bursts,
multi-word/register-bank progression, optional AHB signals, broader
manager/interconnect behavior, scoreboards, direct backend, verification
output, backend variants, AXI/APB, and VHDL remain deferred.

Decision `0020` and the protocol-neutral transaction-layer horizon remain
proposed/inactive until ongoing work dries out or the director explicitly
activates them.

## Rollback

`.800` is documentation-only. Rollback removes this contract/fact, restores
`.800` active, removes `.801`, and reverts README, roadmap, mdBook, task-tree,
Memory, and generated Knowledge Map entries. No runtime behavior is affected.
