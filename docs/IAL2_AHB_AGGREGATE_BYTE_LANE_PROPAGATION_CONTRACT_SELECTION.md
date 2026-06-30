# IAL2 AHB Aggregate Byte-Lane Propagation Contract Selection

Task-tree owner: `IAL2-FEATURE-COMPLETENESS-FRONTIER.742`

Date: 2026-06-30

## Outcome

`IAL2-FEATURE-COMPLETENESS-FRONTIER.742` selects
`IAL2-FEATURE-COMPLETENESS-FRONTIER.743`, direct implementation of the
combined bounded generic `.ppif` AHB aggregate byte-lane and narrow-transfer
propagation family.

The selected implementation must add exactly these generic public sources:

```text
ppif/ahb_interconnect_byte_lane.ppif
ppif/ahb_interconnect_two_subordinate_byte_lane.ppif
```

Matching `.ahb` aliases are not part of `.743`. They remain separate
follow-on work after the generic `.ppif` behavior, reports, support
accounting, tests, and docs ship.

This selector changes no parser behavior, generator behavior, public source
sample, support-accounting catalog, capability manifest, focused test
behavior, schedule/check/semantic JSON behavior, generated artifact,
HDL/runtime behavior, direct backend behavior, verification-output generation,
backend-language variant, AXI behavior, APB behavior, broader AHB behavior, or
VHDL behavior.

## Selected Source Family

The selected family reuses the shipped aggregate interconnect topologies and
replaces only the embedded subordinate endpoint objects with selected
byte-lane/narrow-transfer subordinate objects.

The one-subordinate source is:

```text
path: ppif/ahb_interconnect_byte_lane.ppif
intent_name: ahb_interconnect_byte_lane
source object: fsmgen-ahb-interconnect-byte-lane
anchor: ARM-AMBA-AHB-IHI0033-C-2021-09 / bounded-ahb-interconnect-byte-lane-propagation / first-public-contract
requester object: amba_requester
subordinate object: ahb_lite_subordinate_byte_lane
interconnect object: ahb_tb
child binding: (subordinate regs ahb_lite_subordinate_byte_lane)
window: REG_BASE=0, REG_SIZE=4
```

The two-subordinate source is:

```text
path: ppif/ahb_interconnect_two_subordinate_byte_lane.ppif
intent_name: ahb_interconnect_two_subordinate_byte_lane
source object: fsmgen-ahb-interconnect-two-subordinate-byte-lane
anchor: FSMGEN-AHB-TWO-SUBORDINATE-BYTE-LANE-CONTRACT / bounded-two-subordinate-byte-lane-propagation / first-public-contract
requester object: amba_requester
subordinate objects: ahb_status_subordinate_byte_lane, ahb_control_subordinate_byte_lane
interconnect object: ahb_tb
child bindings: (subordinate status ahb_status_subordinate_byte_lane), (subordinate control ahb_control_subordinate_byte_lane)
windows: STATUS_BASE=0/STATUS_SIZE=4, CONTROL_BASE=4/CONTROL_SIZE=4
```

Both sources keep explicit `(profile ahb)` and keep the same AHB requester,
interconnect, address-map, decode, and wiring vocabulary as the shipped
word-only aggregate sources. They are not cross-file compositions and do not
bind to pre-existing generated artifacts.

## Selected Subordinate Policy

Every embedded subordinate in the selected sources uses the shipped byte-lane
transfer contract:

```text
(supported-size byte)
(supported-size halfword)
(supported-size word)
(lane-order little-endian)
(narrow-write preserve-inactive-lanes)
(narrow-read zero-fill-inactive-lanes)
(unaligned-access error)
(crossing-access error)
```

The selected transfer name is:

```text
ahb_lite_byte_lane_access
```

Accepted sizes remain byte (`HSIZE == 3'b000`), halfword
(`HSIZE == 3'b001`), and word (`HSIZE == 3'b010`). The active-lane and ERROR
policy is exactly the shipped endpoint byte-lane policy: little-endian lanes,
inactive-lane-preserving writes, inactive-lane-zero-filled reads, and
two-cycle ERROR for unsupported size, unsupported transfer, unmapped,
unaligned, and crossing accesses.

## Selected Aggregate Semantics

The selected aggregate byte-lane sources do not add a new interconnect
transfer policy. They propagate the existing aggregate signals to selected
subordinates and leave narrow-transfer acceptance to the selected subordinate
endpoint.

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
address, wait cycles, reads, writes, and subordinate ERROR timing. The
interconnect maps subordinate one-bit `HRESP=0/1` to requester two-bit
`HRESP=2'b00/2'b01`.

## Generated Artifacts

The selected one-subordinate source must emit generated IAL1 review artifacts:

```text
amba_requester.isf
ahb_lite_subordinate_byte_lane.isf
ahb_interconnect.isf
```

Generated IAL0 artifacts:

```text
amba_requester.fsm
ahb_lite_subordinate_byte_lane.fsm
ahb_interconnect.fsm
ahb_tb.fsm
```

The selected two-subordinate source must emit generated IAL1 review artifacts:

```text
amba_requester.isf
ahb_status_subordinate_byte_lane.isf
ahb_control_subordinate_byte_lane.isf
ahb_interconnect.isf
```

Generated IAL0 artifacts:

```text
amba_requester.fsm
ahb_status_subordinate_byte_lane.fsm
ahb_control_subordinate_byte_lane.fsm
ahb_interconnect.fsm
ahb_tb.fsm
```

The HDL entry for both selected sources is:

```text
ahb_tb
```

Direct IAL2-to-IAL0 and direct IAL2-to-HDL lowering remain forbidden.

## Report Contract

The report schema remains:

```text
fsmgen.ial2.protocol_intent.ahb_interconnect.v1
```

The selected implementation must add an explicit aggregate propagation report
block under `composition`:

```text
composition.byte_lane_propagation
```

The selected shape is:

```text
selected: true
policy: subordinate_owned_narrow_transfer
forwarded_signals: HADDR, HTRANS, HWRITE, HSIZE, HWDATA, HRDATA, HREADY, HREADYOUT, HRESP
local_address_policy: subtract_window_base_before_subordinate_lane_policy
unmapped_error_owner: interconnect
mapped_error_owner: selected_subordinate
subordinates: one entry per selected byte-lane subordinate child
```

Each subordinate propagation entry must identify:

- child instance name;
- subordinate object name;
- address window;
- local address signal;
- transfer name `ahb_lite_byte_lane_access`;
- supported sizes `byte`, `halfword`, and `word`; and
- selected `narrow_transfer_policy` copied from the generated subordinate
  report.

Aggregate child reports must also carry `narrow_transfer_policy` whenever an
embedded subordinate report provides it. Existing word-only aggregate child
reports remain unchanged because their subordinate reports do not provide that
block.

## Residue Movement

For the two new generic byte-lane aggregate `.ppif` reports only:

- keep `ahb_aggregate_profile_alias_deferred`;
- keep the existing topology residue (`ahb_multi_subordinate_decode_deferred`
  for the one-subordinate source and `ahb_broader_interconnect_decode_deferred`
  for the two-subordinate source), but remove byte-lane/narrow-transfer
  wording from the two-subordinate broader residue detail;
- keep `ahb_optional_signal_residue`, but remove byte-lane wording from its
  detail;
- keep `ahb_burst_seq_support_deferred`;
- keep `ahb_direct_backend_deferred`; and
- keep `ahb_verification_output_deferred`.

Existing word-only aggregate `.ppif` and `.ahb` reports must keep their
current residue. Existing endpoint byte-lane `.ppif` and `.ahb` reports must
keep their current behavior and residue.

## Support Accounting

The selected support-accounting entries are:

```text
entry_id: intent.ppif_ahb_interconnect_byte_lane
relpath: ppif/ahb_interconnect_byte_lane.ppif
source_kind: ppif
coverage: ial2_ppif_ahb_interconnect_byte_lane_pipeline_cli
expected_module_name: ahb_tb
expected_composition_child_count: 3
expected_semantic_source_root_kind: top
```

```text
entry_id: intent.ppif_ahb_interconnect_two_subordinate_byte_lane
relpath: ppif/ahb_interconnect_two_subordinate_byte_lane.ppif
source_kind: ppif
coverage: ial2_ppif_ahb_interconnect_two_subordinate_byte_lane_pipeline_cli
expected_module_name: ahb_tb
expected_composition_child_count: 4
expected_semantic_source_root_kind: top
```

The selected focused test file is:

```text
t/1484-ial2-ahb-interconnect-byte-lane.t
```

## Alias Sequencing

`.743` must not add matching `.ahb` aliases. The reserved future alias paths
are:

```text
ppif/ahb_interconnect_byte_lane.ahb
ppif/ahb_interconnect_two_subordinate_byte_lane.ahb
```

The likely future alias support identities are:

```text
intent.ahb_profile_alias_interconnect_byte_lane
intent.ahb_profile_alias_interconnect_two_subordinate_byte_lane
```

The likely future alias coverage keys are:

```text
ial2_ahb_profile_alias_interconnect_byte_lane_pipeline_cli
ial2_ahb_profile_alias_interconnect_two_subordinate_byte_lane_pipeline_cli
```

Those aliases require a later selector after the generic `.ppif` family ships.

## Implementation Owner

`.743` owns implementation of exactly this contract:

- add the two selected generic `.ppif` sources;
- extend only the AHB aggregate report/residue path needed for
  `composition.byte_lane_propagation` and child `narrow_transfer_policy`
  propagation;
- preserve generated interconnect behavior and existing endpoint byte-lane
  behavior;
- add the two selected support-accounting entries and capability-manifest text
  needed for the new public sources;
- add focused coverage in `t/1484-ial2-ahb-interconnect-byte-lane.t`;
- preserve existing word-only aggregate `.ppif`/`.ahb` behavior and existing
  endpoint byte-lane `.ppif`/`.ahb` behavior;
- add direct strict-check, schedule JSON, semantic JSON, and outdir probes for
  both new generic sources;
- update behavior docs, mdBook, README, ROADMAP_V2, task tree, MEMORY,
  Knowledge Map, and doctrine gates.

`.743` must not add `.ahb` alias support for the new aggregate byte-lane
sources, mutate existing word-only aggregate sources, add optional/property-
gated signals, add burst `SEQ` continuation, add broader interconnect/decode,
add legacy two-bit subordinate `HRESP`, add scoreboards, add full-manager
behavior, add direct backend behavior, add verification-output generation, add
backend-language variants, add AXI/APB behavior, or add VHDL behavior.

## Validation

The implementation leaf must run at least:

```text
perl -Iperl -c perl/FSM/Adapter/IAL2/PPIF.pm
perl -Iperl -c perl/FSM/IAL2/ProtocolIntent/AhbInterconnect.pm
perl -Iperl -c perl/FSM/Support/RegressionCorpus.pm
perl -Iperl -c perl/FSM/Support/LanguageSurfaceSection.pm
perl -c t/1484-ial2-ahb-interconnect-byte-lane.t
prove -v t/1484-ial2-ahb-interconnect-byte-lane.t
prove -v t/1478-ial2-ahb-interconnect.t
prove -v t/1480-ial2-ahb-interconnect-two-subordinate.t
prove -v t/1482-ial2-ahb-subordinate-byte-lane.t
prove -v t/248-regression-corpus-accounting.t
prove -v t/297-capability-manifest.t
./bin/fsmgen --quiet --strict --check --json ppif/ahb_interconnect_byte_lane.ppif
./bin/fsmgen --quiet --emit-schedule-json ppif/ahb_interconnect_byte_lane.ppif
./bin/fsmgen --quiet --strict --emit-semantic-json ppif/ahb_interconnect_byte_lane.ppif
./bin/fsmgen --quiet --strict --check --json ppif/ahb_interconnect_two_subordinate_byte_lane.ppif
./bin/fsmgen --quiet --emit-schedule-json ppif/ahb_interconnect_two_subordinate_byte_lane.ppif
./bin/fsmgen --quiet --strict --emit-semantic-json ppif/ahb_interconnect_two_subordinate_byte_lane.ppif
```

Closeout must run Knowledge Map generation/check, mdBook build, docs path
audit, memory architecture check, diff check, and the doctrine driver. Broad
or potentially heavyweight Perl/`prove`/`fsmgen` commands must remain
RAM-guarded.
