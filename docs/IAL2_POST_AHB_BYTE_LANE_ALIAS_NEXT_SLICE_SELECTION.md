# IAL2 Post-AHB Byte-Lane Alias Next Slice Selection

Task-tree owner: `IAL2-FEATURE-COMPLETENESS-FRONTIER.740`

Date: 2026-06-30

## Outcome

`IAL2-FEATURE-COMPLETENESS-FRONTIER.740` selects
`IAL2-FEATURE-COMPLETENESS-FRONTIER.741`, a no-behavior readiness audit for
AHB aggregate/interconnect byte-lane and narrow-transfer propagation.

The selector changes no parser behavior, generator behavior, public source
sample, support-accounting catalog, capability manifest, focused test
behavior, schedule/check/semantic JSON behavior, generated artifact,
HDL/runtime behavior, direct backend behavior, verification-output generation,
backend-language variant, AXI behavior, APB behavior, broader AHB behavior, or
VHDL behavior.

## Current Boundary

The endpoint byte-lane/narrow-transfer subordinate now ships through both
bounded public source surfaces:

```text
ppif/ahb_lite_subordinate_byte_lane.ppif
ppif/ahb_lite_subordinate_byte_lane.ahb
```

Both lower through generated `ahb_lite_subordinate_byte_lane.isf` before
generated `ahb_lite_subordinate_byte_lane.fsm`, emit HDL module
`ahb_lite_subordinate_byte_lane`, and report `narrow_transfer_policy`.

The shipped aggregate/interconnect sources still bind word-only subordinate
objects:

```text
ppif/ahb_interconnect.ppif
ppif/ahb_interconnect.ahb
ppif/ahb_interconnect_two_subordinate.ppif
ppif/ahb_interconnect_two_subordinate.ahb
```

They already forward the AHB fields needed by the byte-lane subordinate:

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

Current aggregate reports still keep byte lanes in deferred residue, either
as part of `ahb_optional_signal_residue` or, for the two-subordinate family,
inside `ahb_broader_interconnect_decode_deferred`.

## Current-Code Probe

Two in-memory current-code probes were run without adding repo sources.

The one-subordinate aggregate candidate replaced the shipped word-only
subordinate with a byte-lane subordinate and added the selected byte/halfword/
word transfer policy. It parsed successfully and produced:

```text
amba_requester.isf
ahb_lite_subordinate_byte_lane.isf
ahb_interconnect.isf
```

The two-subordinate aggregate candidate replaced both shipped word-only
subordinates with byte-lane subordinate objects and added the same selected
transfer policy to each. It parsed successfully and produced:

```text
amba_requester.isf
ahb_status_subordinate_byte_lane.isf
ahb_control_subordinate_byte_lane.isf
ahb_interconnect.isf
```

Those probes show that the endpoint generator substrate is likely reusable,
but they also show the aggregate report/residue layer is not yet selected:
both candidate reports still say byte lanes are deferred. A readiness audit is
therefore the correct next owner before any public aggregate source is added.

## Why Aggregate Byte-Lane Propagation Comes Next

Aggregate byte-lane propagation is the narrowest AHB follow-on after the
endpoint `.ppif` and `.ahb` byte-lane sources shipped. It closes the next
directly adjacent residue without introducing new optional AHB signals, burst
address progression, more-than-two subordinate cardinality, multiple
requesters, arbitration, bus matrices, scoreboards, direct backend behavior,
verification outputs, backend-language variants, or VHDL.

The audit must decide whether the first public aggregate byte-lane source is:

- a one-requester/one-subordinate `.ppif` aggregate;
- a one-requester/two-subordinate `.ppif` aggregate;
- both generic `.ppif` aggregates in one implementation family;
- a staged source-shape/report cleanup before public source addition; or
- direct contract selection if the current substrate proves complete enough.

It must also decide whether matching `.ahb` aliases are selected immediately
after generic `.ppif` behavior, or deferred as separate follow-on slices as in
the prior AHB aggregate flow.

## Deferred Alternatives

Optional/property-gated AHB signals remain deferred because `HBURST`, `HPROT`,
`HMASTLOCK`, AHB5 additions, exclusive access, protection-policy effects, and
security/user/parity-style metadata need their own policy boundary.

Burst `SEQ` continuation remains deferred because it requires address
progression, wrapping/incrementing semantics, and manager/subordinate
coordination beyond the selected single-transfer subordinate behavior.

Broader interconnect/decode remains deferred because more-than-two
subordinate cardinality, multiple requesters, arbitration, bus matrices, and
dynamic/programmed windows are topology work, not a byte-lane propagation
closure.

Legacy two-bit subordinate `HRESP`, scoreboards, full AHB manager behavior,
direct backend behavior, verification-output generation, backend-language
variants, AXI, APB, and VHDL remain future task-tree-owned work.

## Selected `.741` Readiness Audit

`.741` must audit aggregate/interconnect byte-lane propagation readiness and
select the next exact owner. It should answer:

- which aggregate source shape comes first;
- whether one-subordinate and two-subordinate byte-lane propagation should be
  separate source families or one bounded family;
- exact public source names, object names, child instance names, address-map
  windows, local-address rules, support identities, coverage names, and
  generated artifact names;
- whether aggregate reports need a new explicit byte-lane propagation field
  or only residue movement;
- whether the current aggregate interconnect generator already forwards every
  signal needed for byte/halfword/word subordinate behavior;
- how unmapped, unsupported transfer, unsupported size, unaligned, crossing,
  and subordinate-owned ERROR responses interact through the interconnect;
- focused tests and direct CLI probes for schedule/check/semantic JSON,
  generated review artifacts, and preservation of word-only aggregate
  behavior;
- matching `.ahb` alias sequencing;
- rollback; and
- docs, mdBook, Knowledge Map, task-tree, Memory, and closeout gates.

## Validation

`.740` validates current state only. Useful current probes are:

```text
./bin/fsmgen --quiet --emit-schedule-json ppif/ahb_lite_subordinate_byte_lane.ahb
./bin/fsmgen --quiet --emit-schedule-json ppif/ahb_interconnect.ahb
./bin/fsmgen --quiet --emit-schedule-json ppif/ahb_interconnect_two_subordinate.ahb
```

Closeout must run Knowledge Map generation/check, mdBook build, docs path
audit, memory architecture check, diff check, and the doctrine driver. Broad or
potentially heavyweight Perl/`prove`/`fsmgen` commands must remain RAM-guarded.

## Non-Goals

`.740` and `.741` must not add parser/generator/source
sample/support-accounting/manifest/test behavior. They must not implement
aggregate byte-lane propagation, optional signals, burst `SEQ` continuation,
legacy two-bit subordinate `HRESP`, broader interconnect cardinality, multiple
requesters, arbitration, bus matrices, scoreboards, full-manager behavior,
direct backend behavior, verification-output generation, backend-language
variants, AXI, APB, broader AHB behavior, or VHDL behavior.
