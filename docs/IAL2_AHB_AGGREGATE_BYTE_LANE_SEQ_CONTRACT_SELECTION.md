# IAL2 AHB Aggregate Byte-Lane In-Word SEQ Contract Selection

Task-tree owner: `IAL2-FEATURE-COMPLETENESS-FRONTIER.757`

Date: 2026-06-30

## Outcome

`IAL2-FEATURE-COMPLETENESS-FRONTIER.757` selects
`IAL2-FEATURE-COMPLETENESS-FRONTIER.758`, direct implementation of the
combined bounded generic `.ppif` AHB aggregate byte-lane in-word `SEQ`
propagation family.

The selected implementation must add exactly these generic public sources:

```text
ppif/ahb_interconnect_byte_lane_seq.ppif
ppif/ahb_interconnect_two_subordinate_byte_lane_seq.ppif
```

Matching aggregate `.ahb` aliases are not part of `.758`. They remain
separate follow-on work after the generic `.ppif` behavior, reports, support
accounting, tests, and docs ship.

This selector changes no parser behavior, generator behavior, public source
sample, support-accounting catalog, capability manifest behavior, focused test
behavior, schedule/check/semantic JSON behavior, generated artifact,
HDL/runtime behavior, direct backend behavior, verification-output generation,
backend-language variant, AXI/APB behavior, broader AHB behavior, or VHDL
behavior.

## Selected Source Family

The selected family reuses the shipped aggregate AHB interconnect topologies
and replaces only the embedded subordinate endpoint objects with selected
byte-lane in-word `SEQ` subordinate objects.

The one-subordinate source is:

```text
path: ppif/ahb_interconnect_byte_lane_seq.ppif
intent_name: ahb_interconnect_byte_lane_seq
source object: fsmgen-ahb-interconnect-byte-lane-seq
anchor: ARM-AMBA-AHB-IHI0033-C-2021-09 / bounded-ahb-interconnect-byte-lane-seq-propagation / first-public-contract
requester object: amba_requester
subordinate object: ahb_lite_subordinate_byte_lane_seq
interconnect object: ahb_tb
child binding: (subordinate regs ahb_lite_subordinate_byte_lane_seq)
window: REG_BASE=0, REG_SIZE=4
```

The two-subordinate source is:

```text
path: ppif/ahb_interconnect_two_subordinate_byte_lane_seq.ppif
intent_name: ahb_interconnect_two_subordinate_byte_lane_seq
source object: fsmgen-ahb-interconnect-two-subordinate-byte-lane-seq
anchor: FSMGEN-AHB-TWO-SUBORDINATE-BYTE-LANE-SEQ-CONTRACT / bounded-two-subordinate-byte-lane-seq-propagation / first-public-contract
requester object: amba_requester
subordinate objects: ahb_status_subordinate_byte_lane_seq, ahb_control_subordinate_byte_lane_seq
interconnect object: ahb_tb
child bindings: (subordinate status ahb_status_subordinate_byte_lane_seq), (subordinate control ahb_control_subordinate_byte_lane_seq)
windows: STATUS_BASE=0/STATUS_SIZE=4, CONTROL_BASE=4/CONTROL_SIZE=4
```

Both sources keep explicit `(profile ahb)` and keep the same AHB requester,
interconnect, address-map, decode, and wiring vocabulary as the shipped
aggregate byte-lane sources.

## Selected Subordinate Policy

Every embedded subordinate in the selected sources uses the shipped byte-lane
in-word `SEQ` transfer contract:

```text
(supported-transfer nonseq)
(supported-size byte)
(supported-size halfword)
(supported-size word)
(lane-order little-endian)
(narrow-write preserve-inactive-lanes)
(narrow-read zero-fill-inactive-lanes)
(unaligned-access error)
(crossing-access error)
(seq-policy in-word-progressive)
```

The selected transfer name is:

```text
ahb_lite_byte_lane_seq_access
```

The embedded subordinates keep `supported-transfer nonseq` for compatibility
and add structured `transfer.seq_policy` in reports. Accepted `SEQ` completion
remains subordinate-owned and bounded to byte/halfword in-word progression
after prior OKAY `NONSEQ` or valid `SEQ` history, expected next local address,
and stable `HWRITE`/`HSIZE`.

## Selected Aggregate Semantics

The selected aggregate `SEQ` sources do not add a new interconnect transfer
engine. They propagate the existing aggregate signals to selected subordinates
and leave byte-lane/narrow-transfer and in-word `SEQ` acceptance to the
selected subordinate endpoint.

The aggregate decode policy remains:

- exactly one requester;
- exactly one or two subordinate endpoints, matching the selected source;
- static 32-bit, 4-byte-aligned windows;
- fixed `HGRANT=1`;
- active transfer when `HTRANS != IDLE`;
- selected subordinate local address `HADDR_* = HADDR - window_base`;
- unselected subordinate selects low and local addresses zero;
- selected subordinate `HREADYOUT_*`, `HRDATA_*`, and one-bit `HRESP_*`
  muxed back to the requester; and
- interconnect-owned two-cycle ERROR for unmapped active transfers.

On a mapped hit, the selected subordinate owns byte/halfword/word acceptance,
alignment, crossing, unsupported size, unsupported transfer, local unmapped
address, wait cycles, reads, writes, subordinate ERROR timing, and selected
in-word `SEQ` history/progression. The interconnect maps subordinate one-bit
`HRESP=0/1` to requester two-bit `HRESP=2'b00/2'b01`.

## Generated Artifacts

The selected one-subordinate source must emit generated IAL1 review artifacts:

```text
amba_requester.isf
ahb_lite_subordinate_byte_lane_seq.isf
ahb_interconnect.isf
```

Generated IAL0 artifacts:

```text
amba_requester.fsm
ahb_lite_subordinate_byte_lane_seq.fsm
ahb_interconnect.fsm
ahb_tb.fsm
```

The selected two-subordinate source must emit generated IAL1 review artifacts:

```text
amba_requester.isf
ahb_status_subordinate_byte_lane_seq.isf
ahb_control_subordinate_byte_lane_seq.isf
ahb_interconnect.isf
```

Generated IAL0 artifacts:

```text
amba_requester.fsm
ahb_status_subordinate_byte_lane_seq.fsm
ahb_control_subordinate_byte_lane_seq.fsm
ahb_interconnect.fsm
ahb_tb.fsm
```

The HDL entry for both selected sources is:

```text
ahb_tb
```

Direct IAL2-to-IAL0 and direct IAL2-to-HDL lowering remain forbidden.

## Support Accounting

The selected one-subordinate source must support-account as:

```text
entry_id: intent.ppif_ahb_interconnect_byte_lane_seq
source_kind: ppif
coverage: ial2_ppif_ahb_interconnect_byte_lane_seq_pipeline_cli
classification: supported_smoke
strict_supported: true
module_name: ahb_tb
composition_child_count: 3
```

The selected two-subordinate source must support-account as:

```text
entry_id: intent.ppif_ahb_interconnect_two_subordinate_byte_lane_seq
source_kind: ppif
coverage: ial2_ppif_ahb_interconnect_two_subordinate_byte_lane_seq_pipeline_cli
classification: supported_smoke
strict_supported: true
module_name: ahb_tb
composition_child_count: 4
```

## Report Contract

The report schema remains:

```text
fsmgen.ial2.protocol_intent.ahb_interconnect.v1
```

The selected implementation must preserve `composition.byte_lane_propagation`
and add an explicit aggregate `SEQ` propagation report block under
`composition`:

```text
composition.seq_policy_propagation
```

The selected shape is:

```text
selected: true
mode: subordinate_owned_in_word_seq_policy
policy: in_word_progressive
forwarded_signals: HADDR, HTRANS, HWRITE, HSIZE, HWDATA, HRDATA, HREADY, HREADYOUT, HRESP
local_address_policy: subtract_window_base_before_subordinate_seq_policy
unmapped_error_owner: interconnect
mapped_error_owner: selected_subordinate
history_owner: selected_subordinate
subordinates: one entry per selected byte-lane SEQ subordinate child
```

Each subordinate propagation entry must identify:

- child instance name;
- subordinate object name;
- address window;
- local address signal;
- transfer name `ahb_lite_byte_lane_seq_access`;
- supported `SEQ` sizes `byte` and `halfword`;
- selected mode `in_word_progressive`; and
- selected `transfer.seq_policy` copied from the generated subordinate report.

Aggregate child reports must carry `narrow_transfer_policy` and
`transfer.seq_policy` whenever an embedded subordinate report provides those
blocks. Existing word-only aggregate and non-`SEQ` byte-lane aggregate child
reports remain unchanged.

## Residue Movement

For the two new generic aggregate `SEQ` `.ppif` reports only:

- keep `ahb_aggregate_profile_alias_deferred`;
- keep topology residue for broader interconnect/decode beyond the selected
  one-subordinate and two-subordinate static-window shapes;
- remove aggregate-propagation wording from top-level
  `ahb_burst_seq_support_deferred`;
- keep HBURST-driven length/wrap, BUSY-in-burst parking,
  multi-word/register-bank progression, broader manager/subordinate behavior,
  direct backend, verification-output, backend-language variants, AXI/APB,
  broader AHB, and VHDL as explicit residue;
- copy child `transfer.seq_policy` into generated child reports; and
- remove aggregate-propagation wording from generated child
  `ahb_burst_seq_support_deferred` detail while preserving true endpoint
  residue, including `.ahb` alias exposure for the generic aggregate source
  surface.

Existing word-only aggregate `.ppif/.ahb`, byte-lane aggregate `.ppif/.ahb`,
endpoint byte-lane `SEQ` `.ppif/.ahb`, requester, interconnect, support
accounting, capability manifest, generated artifacts, and HDL behavior must
remain unchanged except for additive catalog/language-surface/docs entries for
the new generic aggregate `SEQ` sources.

## Alias Sequencing

Matching aggregate `.ahb` aliases remain separate follow-on work after `.758`.
The reserved likely future alias paths are:

```text
ppif/ahb_interconnect_byte_lane_seq.ahb
ppif/ahb_interconnect_two_subordinate_byte_lane_seq.ahb
```

The `.758` implementation must not add those aliases, their support identities,
or alias-only residue cleanup.

## Validation

The selected implementation should add focused coverage, expected as:

```text
t/1488-ial2-ahb-interconnect-byte-lane-seq.t
```

That coverage must prove:

- both new generic `.ppif` sources parse and support-account;
- generated IAL1 and IAL0 artifacts match the selected names;
- HDL entry remains `ahb_tb`;
- schedule JSON carries `composition.byte_lane_propagation` and
  `composition.seq_policy_propagation`;
- generated child reports carry `narrow_transfer_policy` and
  `transfer.seq_policy`;
- top-level and child residue movement matches this contract;
- check JSON and semantic JSON preserve public source identity;
- `--outdir` writes the expected generated review artifacts;
- existing word-only aggregate, non-`SEQ` byte-lane aggregate, endpoint `SEQ`,
  and endpoint `.ahb` alias behavior remain preserved; and
- malformed aggregate `SEQ` source shapes fail closed.

Closeout must also update RegressionCorpus, LanguageSurfaceSection/capability
manifest expectations, README, ROADMAP_V2, mdBook, behavior docs, Knowledge
Map, task tree, and Memory, then run focused syntax/probe/tests plus doctrine
closeout.

## Explicit Non-Selections

`.757` and `.758` must not add matching aggregate `.ahb` aliases, HBURST
forwarding to subordinates, HBURST-driven length/wrap validation,
BUSY-in-burst parking, multi-word/register-bank progression,
optional/property-gated AHB signals, legacy two-bit subordinate `HRESP`,
broader interconnect/decode, scoreboards, full-manager behavior, direct
backend behavior, verification-output generation, backend-language variants,
AXI/APB behavior, broader AHB behavior, or VHDL behavior.

## Rollback

Rollback for `.757` is documentation-only: remove this selector, its Knowledge
Map fact card, task-tree advancement, README/ROADMAP_V2/mdBook sync, Memory
pointer update, and regenerated Knowledge Map entries. `.758` will define its
own implementation rollback if it proceeds.
