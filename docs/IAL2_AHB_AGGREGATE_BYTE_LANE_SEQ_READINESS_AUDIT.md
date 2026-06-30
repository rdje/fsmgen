# IAL2 AHB Aggregate Byte-Lane In-Word SEQ Readiness Audit

Task-tree owner: `IAL2-FEATURE-COMPLETENESS-FRONTIER.756`

Date: 2026-06-30

## Outcome

`IAL2-FEATURE-COMPLETENESS-FRONTIER.756` selects
`IAL2-FEATURE-COMPLETENESS-FRONTIER.757`, a no-behavior public contract
selection for a combined bounded generic `.ppif` AHB aggregate byte-lane
in-word `SEQ` propagation family.

The selected next owner is a contract selector, not direct implementation,
because current code can parse and lower likely aggregate `SEQ` shapes through
generated review artifacts, but the public source names, support identities,
aggregate report shape, residue movement, validation matrix, and later `.ahb`
alias sequence are not yet selected.

This audit changes no parser behavior, generator behavior, public source
sample, support-accounting catalog, capability manifest behavior, focused test
behavior, schedule/check/semantic JSON behavior, generated artifact,
HDL/runtime behavior, direct backend behavior, verification-output generation,
backend-language variant, AXI/APB behavior, broader AHB behavior, or VHDL
behavior.

## Current Boundary

The endpoint byte-lane in-word `SEQ` subordinate is shipped through both
selected public source surfaces:

```text
ppif/ahb_lite_subordinate_byte_lane_seq.ppif
ppif/ahb_lite_subordinate_byte_lane_seq.ahb
```

The current aggregate byte-lane sources are still non-`SEQ` at their embedded
subordinate endpoints:

```text
ppif/ahb_interconnect_byte_lane.ppif
ppif/ahb_interconnect_two_subordinate_byte_lane.ppif
ppif/ahb_interconnect_byte_lane.ahb
ppif/ahb_interconnect_two_subordinate_byte_lane.ahb
```

Those aggregate sources instantiate `ahb_lite_byte_lane_access`, not
`ahb_lite_byte_lane_seq_access`, and current aggregate reports still carry
`ahb_burst_seq_support_deferred` at top-level and generated child-report
surfaces.

## Temporary Probe Evidence

Two temporary `/tmp` probes were generated from the shipped aggregate
byte-lane sources. No repository source file was added or changed.

The one-requester/one-subordinate probe used likely future names:

```text
intent: ahb_interconnect_byte_lane_seq
source object: fsmgen-ahb-interconnect-byte-lane-seq
subordinate object: ahb_lite_subordinate_byte_lane_seq
child binding: (subordinate regs ahb_lite_subordinate_byte_lane_seq)
transfer: ahb_lite_byte_lane_seq_access
policy: (seq-policy in-word-progressive)
```

It passed strict check and schedule probing:

```text
success: true
module_name: ahb_tb
composition_child_count: 3
generated child artifacts include ahb_lite_subordinate_byte_lane_seq.isf
generated child artifacts include ahb_lite_subordinate_byte_lane_seq.fsm
child report carries narrow_transfer_policy
child report carries transfer.seq_policy
```

The one-requester/two-subordinate probe used likely future names:

```text
intent: ahb_interconnect_two_subordinate_byte_lane_seq
source object: fsmgen-ahb-interconnect-two-subordinate-byte-lane-seq
subordinate objects: ahb_status_subordinate_byte_lane_seq, ahb_control_subordinate_byte_lane_seq
child bindings: status/control to the matching *_byte_lane_seq objects
transfer: ahb_lite_byte_lane_seq_access on both subordinates
policy: (seq-policy in-word-progressive) on both subordinates
```

It also passed strict check and schedule probing:

```text
success: true
module_name: ahb_tb
composition_child_count: 4
generated child artifacts include ahb_status_subordinate_byte_lane_seq.isf
generated child artifacts include ahb_control_subordinate_byte_lane_seq.isf
generated child artifacts include ahb_status_subordinate_byte_lane_seq.fsm
generated child artifacts include ahb_control_subordinate_byte_lane_seq.fsm
both child reports carry narrow_transfer_policy
both child reports carry transfer.seq_policy
```

Normalized semantic probing for the one-subordinate temporary source also
passed, with `matched_support_accounting: false` as expected for an untracked
temporary source.

## Report Gap

The probes show no lower-layer generated-IAL1/IAL0 blocker for the likely
aggregate `SEQ` family. They also show why the next slice must be a contract
selector:

- the temporary sources are not tracked public fixtures and have no support
  identities;
- current aggregate report recognition does not select a public aggregate
  `SEQ` propagation block for those future names;
- child reports carry `narrow_transfer_policy` and `transfer.seq_policy`, but
  the aggregate top-level report still needs an explicit contract for whether
  it adds `composition.seq_policy_propagation`, extends
  `composition.byte_lane_propagation`, or uses another named block;
- top-level aggregate residue still says burst `SEQ` continuation remains
  future work;
- generated child reports still carry endpoint-style
  `ahb_burst_seq_support_deferred` detail that names aggregate propagation;
  and
- existing word-only aggregate, byte-lane aggregate, endpoint `SEQ`, and
  `.ahb` alias behavior must remain unchanged when new aggregate `SEQ` sources
  are eventually added.

## Readiness Decision

No generated-IAL1/IAL0 substrate repair is required before public contract
selection. The aggregate interconnect already forwards the signals needed by
the selected endpoint policy to mapped subordinates:

```text
HADDR
HTRANS
HWRITE
HSIZE
HWDATA
HREADY
HREADYOUT
HRESP
HRDATA
```

The current generated child reports can carry both `narrow_transfer_policy`
and `transfer.seq_policy` for temporary aggregate `SEQ` shapes. The remaining
work is source/report/support/test/docs contract selection.

The next owner should select a combined bounded generic `.ppif` family rather
than only one topology first. The one-subordinate and two-subordinate shapes
share the same endpoint `SEQ` policy, signal forwarding, local-address policy,
generated interconnect object, report schema, validation pattern, and alias
sequencing. This mirrors the already shipped aggregate byte-lane propagation
flow.

## Selected `.757` Contract Selector

`.757` must select the public contract for a combined generic `.ppif`
aggregate byte-lane in-word `SEQ` propagation family.

The likely source names are:

```text
ppif/ahb_interconnect_byte_lane_seq.ppif
ppif/ahb_interconnect_two_subordinate_byte_lane_seq.ppif
```

The likely one-subordinate identity is:

```text
intent_name: ahb_interconnect_byte_lane_seq
source object: fsmgen-ahb-interconnect-byte-lane-seq
subordinate object: ahb_lite_subordinate_byte_lane_seq
child binding: (subordinate regs ahb_lite_subordinate_byte_lane_seq)
window: REG_BASE=0, REG_SIZE=4
generated IAL1: amba_requester.isf, ahb_lite_subordinate_byte_lane_seq.isf, ahb_interconnect.isf
generated IAL0: amba_requester.fsm, ahb_lite_subordinate_byte_lane_seq.fsm, ahb_interconnect.fsm, ahb_tb.fsm
HDL entry: ahb_tb
```

The likely two-subordinate identity is:

```text
intent_name: ahb_interconnect_two_subordinate_byte_lane_seq
source object: fsmgen-ahb-interconnect-two-subordinate-byte-lane-seq
subordinate objects: ahb_status_subordinate_byte_lane_seq, ahb_control_subordinate_byte_lane_seq
child bindings: (subordinate status ahb_status_subordinate_byte_lane_seq), (subordinate control ahb_control_subordinate_byte_lane_seq)
windows: STATUS_BASE=0/STATUS_SIZE=4, CONTROL_BASE=4/CONTROL_SIZE=4
generated IAL1: amba_requester.isf, ahb_status_subordinate_byte_lane_seq.isf, ahb_control_subordinate_byte_lane_seq.isf, ahb_interconnect.isf
generated IAL0: amba_requester.fsm, ahb_status_subordinate_byte_lane_seq.fsm, ahb_control_subordinate_byte_lane_seq.fsm, ahb_interconnect.fsm, ahb_tb.fsm
HDL entry: ahb_tb
```

`.757` may adjust those names only if it records a stronger exact contract
before selecting implementation.

## Contract Questions For `.757`

The contract selector must settle:

- exact source paths, intent names, source-object anchors, and support
  identities;
- whether one-subordinate and two-subordinate aggregate `SEQ` sources ship in
  one implementation slice;
- generated child artifact names for the selected `*_byte_lane_seq`
  subordinates;
- whether aggregate reports add `composition.seq_policy_propagation`, extend
  `composition.byte_lane_propagation`, or use another report shape;
- whether aggregate child reports copy `transfer.seq_policy` in addition to
  `narrow_transfer_policy`;
- which aggregate top-level residue should remove aggregate-propagation wording
  while retaining HBURST length/wrap, BUSY-in-burst, multi-word/register-bank,
  broader manager, direct backend, verification-output, backend-language,
  AXI/APB, broader AHB, and VHDL residue;
- which child-report residue should remove aggregate-propagation wording while
  keeping true endpoint burst residue;
- how matching aggregate `.ahb` aliases are sequenced after generic `.ppif`
  sources; and
- focused tests and preservation probes for existing word-only aggregate,
  byte-lane aggregate, endpoint `SEQ`, and endpoint alias behavior.

## Explicit Non-Selections

`.756` and `.757` must not add aggregate `SEQ` sources or aliases, change
parser/generator behavior, change support-accounting entries, change
capability-manifest output, change existing source samples, change schedule,
check, or semantic JSON behavior, change generated artifacts, change
HDL/runtime behavior, add HBURST forwarding to subordinates, implement
HBURST-driven length/wrap validation, add BUSY-in-burst parking, add
multi-word/register-bank progression, add optional/property-gated AHB signals,
add legacy two-bit subordinate `HRESP`, broaden interconnect/decode, add
scoreboards, add full-manager behavior, direct backend behavior,
verification-output generation, backend-language variants, AXI/APB behavior,
broader AHB behavior, or VHDL behavior.

## Validation

Closeout for `.756` is documentation-only plus targeted current-state and
temporary-source probes:

```bash
rg -n 'ahb_lite_subordinate_byte_lane_seq|seq-policy|ahb_lite_byte_lane_seq_access|ahb_lite_byte_lane_access|ahb-subordinate' ppif/ahb_interconnect_byte_lane.ppif ppif/ahb_interconnect_two_subordinate_byte_lane.ppif ppif/ahb_interconnect_byte_lane.ahb ppif/ahb_interconnect_two_subordinate_byte_lane.ahb ppif/ahb_lite_subordinate_byte_lane_seq.ppif ppif/ahb_lite_subordinate_byte_lane_seq.ahb
./bin/fsmgen --quiet --strict --check --json /tmp/fsmgen-ahb-interconnect-byte-lane-seq-probe.ppif
./bin/fsmgen --quiet --emit-schedule-json /tmp/fsmgen-ahb-interconnect-byte-lane-seq-probe.ppif
./bin/fsmgen --quiet --strict --emit-semantic-json /tmp/fsmgen-ahb-interconnect-byte-lane-seq-probe.ppif
./bin/fsmgen --quiet --strict --check --json /tmp/fsmgen-ahb-interconnect-two-subordinate-byte-lane-seq-probe.ppif
./bin/fsmgen --quiet --emit-schedule-json /tmp/fsmgen-ahb-interconnect-two-subordinate-byte-lane-seq-probe.ppif
knowledge-map/scripts/gen_knowledge_map.sh
knowledge-map/scripts/check_knowledge_map.sh
mdbook build docs/book
scripts/check_docs_relative_paths.sh
git --no-pager diff --check
scripts/check_doctrines.sh
```

Broad or potentially heavyweight Perl, `prove`, or `fsmgen` commands remain
behind `scripts/run_with_ram_guard.sh` or equivalent monitoring.

## Rollback

Rollback is documentation-only: remove this audit, its Knowledge Map fact
card, task-tree advancement, README/ROADMAP_V2/mdBook sync, Memory pointer
update, and regenerated Knowledge Map entries. No runtime behavior is affected.
