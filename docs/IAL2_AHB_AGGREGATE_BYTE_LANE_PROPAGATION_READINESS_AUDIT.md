# IAL2 AHB Aggregate Byte-Lane Propagation Readiness Audit

Task-tree owner: `IAL2-FEATURE-COMPLETENESS-FRONTIER.741`

Date: 2026-06-30

## Outcome

`IAL2-FEATURE-COMPLETENESS-FRONTIER.741` selects
`IAL2-FEATURE-COMPLETENESS-FRONTIER.742`, a no-behavior public contract
selection for a combined bounded generic `.ppif` AHB aggregate byte-lane and
narrow-transfer propagation family.

The selected next owner is a contract selector, not direct implementation,
because current code can already parse and lower byte-lane subordinate objects
inside both selected aggregate topologies, but the public source names,
support identities, report shape, residue movement, and `.ahb` alias
sequencing are not yet selected.

This audit changes no parser behavior, generator behavior, public source
sample, support-accounting catalog, capability manifest, focused test
behavior, schedule/check/semantic JSON behavior, generated artifact,
HDL/runtime behavior, direct backend behavior, verification-output generation,
backend-language variant, AXI behavior, APB behavior, broader AHB behavior, or
VHDL behavior.

## Current Boundary

The endpoint byte-lane/narrow-transfer subordinate is shipped through both
selected public source surfaces:

```text
ppif/ahb_lite_subordinate_byte_lane.ppif
ppif/ahb_lite_subordinate_byte_lane.ahb
```

The selected aggregate/interconnect sources are still word-only at their
subordinate endpoints:

```text
ppif/ahb_interconnect.ppif
ppif/ahb_interconnect.ahb
ppif/ahb_interconnect_two_subordinate.ppif
ppif/ahb_interconnect_two_subordinate.ahb
```

The aggregate generator already forwards every signal the byte-lane
subordinate needs on a selected hit:

```text
HADDR
HTRANS
HWRITE
HSIZE
HWDATA
HRDATA
HREADY
HREADYOUT
HRESP
```

For each subordinate window, the interconnect subtracts the window base before
driving the subordinate-local `HADDR_*` signal. That means the byte/halfword/
word lane policy remains subordinate-owned and is evaluated against local
address zero in the same way as the standalone byte-lane source.

## Current-Code Probe Evidence

Two in-memory current-code probes were rerun without adding repository source
files.

The one-requester/one-subordinate candidate replaced the word-only
`ahb_lite_subordinate` object with a byte-lane subordinate object, preserved
the `regs` child and `REG_BASE=0`/`REG_SIZE=4` window, and added the selected
byte/halfword/word transfer policy. It parsed and emitted:

```text
topology: one_requester_one_subordinate_static_window_interconnect
generated IAL1: amba_requester.isf, ahb_lite_subordinate_byte_lane.isf, ahb_interconnect.isf
generated IAL0: amba_requester.fsm, ahb_lite_subordinate_byte_lane.fsm, ahb_interconnect.fsm, ahb_tb.fsm
```

The subordinate child report included transfer `ahb_lite_byte_lane_access`
with supported sizes `byte`, `halfword`, and `word`.

The one-requester/two-subordinate candidate replaced both subordinate objects
with byte-lane variants, preserved the `status` and `control` children and
the `STATUS_BASE=0`/`CONTROL_BASE=4` static windows, and added the same
selected byte/halfword/word transfer policy to each subordinate. It parsed and
emitted:

```text
topology: one_requester_two_subordinate_static_window_interconnect
generated IAL1: amba_requester.isf, ahb_status_subordinate_byte_lane.isf, ahb_control_subordinate_byte_lane.isf, ahb_interconnect.isf
generated IAL0: amba_requester.fsm, ahb_status_subordinate_byte_lane.fsm, ahb_control_subordinate_byte_lane.fsm, ahb_interconnect.fsm, ahb_tb.fsm
```

Both subordinate child reports included transfer
`ahb_lite_byte_lane_access` with supported sizes `byte`, `halfword`, and
`word`.

## Report Gap

The probes show the parser and generated review-artifact substrate are ready
for a public contract selector, but they also show why direct implementation
should not be selected in this audit:

- the aggregate top-level reports do not yet expose an explicit
  `narrow_transfer_policy` or aggregate byte-lane propagation report block;
- aggregate child reports currently copy subordinate `transfer` metadata but
  do not copy the standalone subordinate report's `narrow_transfer_policy`;
- top-level aggregate residue still describes byte lanes as deferred through
  `ahb_optional_signal_residue`, and the two-subordinate topology also keeps
  byte lanes in `ahb_broader_interconnect_decode_deferred`; and
- existing word-only aggregate `.ppif` and `.ahb` report behavior must remain
  unchanged when new byte-lane aggregate sources are added.

The next contract must therefore settle whether the aggregate report adds a
new `byte_lane_propagation`/`narrow_transfer_propagation` block, copies each
selected subordinate's `narrow_transfer_policy` into child reports, or uses a
combined report shape. It must also define exactly which residue text is
removed only for the new selected byte-lane aggregate sources.

## Readiness Decision

No lower-layer generated-IAL1/IAL0 substrate repair is required before
contract selection. The aggregate interconnect already forwards global
address, transfer, write, size, and write-data fields to selected
subordinates, maps subordinate read data and one-bit OKAY/ERROR response back
to the requester, and emits reviewable requester, subordinate, interconnect,
and aggregate-top artifacts.

The next owner should select a combined bounded generic `.ppif` family rather
than only one topology first. The one-subordinate and two-subordinate shapes
share the same endpoint byte-lane policy, signal forwarding, local-address
policy, generated interconnect object, report schema, and validation pattern.
Selecting both source shapes in one contract keeps the user-facing aggregate
surface aligned with the already shipped word-only aggregate pair while still
deferring `.ahb` aliases to separate follow-on work.

## Selected `.742` Contract Selector

`.742` must select the public contract for a combined generic `.ppif` family.
The likely source names are:

```text
ppif/ahb_interconnect_byte_lane.ppif
ppif/ahb_interconnect_two_subordinate_byte_lane.ppif
```

The likely one-subordinate identity is:

```text
intent_name: ahb_interconnect_byte_lane
source object: fsmgen-ahb-interconnect-byte-lane
subordinate object: ahb_lite_subordinate_byte_lane
child binding: (subordinate regs ahb_lite_subordinate_byte_lane)
window: REG_BASE=0, REG_SIZE=4
generated IAL1: amba_requester.isf, ahb_lite_subordinate_byte_lane.isf, ahb_interconnect.isf
generated IAL0: amba_requester.fsm, ahb_lite_subordinate_byte_lane.fsm, ahb_interconnect.fsm, ahb_tb.fsm
HDL entry: ahb_tb
support identity: intent.ppif_ahb_interconnect_byte_lane
coverage: ial2_ppif_ahb_interconnect_byte_lane_pipeline_cli
```

The likely two-subordinate identity is:

```text
intent_name: ahb_interconnect_two_subordinate_byte_lane
source object: fsmgen-ahb-interconnect-two-subordinate-byte-lane
subordinate objects: ahb_status_subordinate_byte_lane, ahb_control_subordinate_byte_lane
child bindings: (subordinate status ahb_status_subordinate_byte_lane), (subordinate control ahb_control_subordinate_byte_lane)
windows: STATUS_BASE=0/STATUS_SIZE=4, CONTROL_BASE=4/CONTROL_SIZE=4
generated IAL1: amba_requester.isf, ahb_status_subordinate_byte_lane.isf, ahb_control_subordinate_byte_lane.isf, ahb_interconnect.isf
generated IAL0: amba_requester.fsm, ahb_status_subordinate_byte_lane.fsm, ahb_control_subordinate_byte_lane.fsm, ahb_interconnect.fsm, ahb_tb.fsm
HDL entry: ahb_tb
support identity: intent.ppif_ahb_interconnect_two_subordinate_byte_lane
coverage: ial2_ppif_ahb_interconnect_two_subordinate_byte_lane_pipeline_cli
```

`.742` may adjust those names only if it records a stronger exact contract
before selecting implementation.

## Semantics To Select

The future aggregate byte-lane sources should preserve the existing aggregate
decode policy:

- one requester;
- one or two static 32-bit, 4-byte-aligned windows;
- fixed `HGRANT=1`;
- active transfer when `HTRANS != IDLE`;
- local subordinate address equal to `HADDR - window_base`;
- hit response/data muxing from the selected subordinate; and
- interconnect-owned two-cycle ERROR for unmapped active transfers.

On a mapped hit, the selected subordinate owns byte/halfword/word acceptance,
little-endian active lanes, inactive-lane-preserving writes,
inactive-lane-zero-filled reads, unsupported size, unsupported transfer,
unaligned access, crossing access, local unmapped address, wait cycles, and
the two-cycle subordinate ERROR response. The interconnect must continue to
map subordinate one-bit `HRESP=0/1` to requester two-bit `HRESP=2'b00/2'b01`.

The contract must explicitly preserve existing word-only aggregate `.ppif` and
`.ahb` behavior and existing byte-lane endpoint `.ppif` and `.ahb` behavior.

## Alias Sequencing

Matching `.ahb` aliases should remain separate follow-on work after the
generic `.ppif` aggregate byte-lane sources are selected and shipped. That
matches the prior AHB aggregate flow:

```text
generic .ppif source -> no-behavior alias selector -> .ahb alias implementation
```

The contract selector should still reserve likely future alias paths so source
names do not collide:

```text
ppif/ahb_interconnect_byte_lane.ahb
ppif/ahb_interconnect_two_subordinate_byte_lane.ahb
```

## Validation Scope

The future implementation owner selected by `.742` should include focused
coverage for:

- strict check JSON, schedule JSON, semantic JSON, and generated artifact
  probes for both new generic `.ppif` aggregate byte-lane sources;
- preservation probes for `ppif/ahb_interconnect.ppif`,
  `ppif/ahb_interconnect.ahb`, `ppif/ahb_interconnect_two_subordinate.ppif`,
  and `ppif/ahb_interconnect_two_subordinate.ahb`;
- preservation probes for `ppif/ahb_lite_subordinate_byte_lane.ppif` and
  `ppif/ahb_lite_subordinate_byte_lane.ahb`;
- tests that report byte-lane propagation and no longer describe byte lanes
  as deferred for the new aggregate byte-lane sources;
- tests that existing word-only aggregate reports keep their current residue;
- syntax checks for changed Perl modules and focused tests;
- support-accounting and capability-manifest checks if catalog/manifest files
  change; and
- Knowledge Map generation/check, mdBook build, docs path audit,
  memory-architecture check, diff check, and the doctrine driver.

Broad or potentially heavyweight Perl/`prove`/`fsmgen` commands must remain
RAM-guarded.

## Deferred Axes

This audit does not select optional/property-gated AHB signals, burst `SEQ`
continuation beyond existing requester generation and subordinate ERROR
policy, broader subordinate cardinality, multiple requesters, arbitration, bus
matrices, dynamic/programmed windows, legacy two-bit subordinate `HRESP`,
scoreboards, full-manager behavior, direct backend behavior,
verification-output generation, backend-language variants, AXI, APB, broader
AHB behavior, or VHDL behavior.
