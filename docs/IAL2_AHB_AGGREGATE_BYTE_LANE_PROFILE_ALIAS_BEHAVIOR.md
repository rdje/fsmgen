# IAL2 AHB Aggregate Byte-Lane Profile-Alias Behavior

Task-tree owner: `IAL2-FEATURE-COMPLETENESS-FRONTIER.745`

Date: 2026-06-30

## Outcome

`IAL2-FEATURE-COMPLETENESS-FRONTIER.745` ships the matching bounded public AHB
aggregate byte-lane `.ahb` profile-alias sources:

```text
ppif/ahb_interconnect_byte_lane.ahb
ppif/ahb_interconnect_two_subordinate_byte_lane.ahb
```

They mirror the generic aggregate byte-lane sources:

```text
ppif/ahb_interconnect_byte_lane.ppif
ppif/ahb_interconnect_two_subordinate_byte_lane.ppif
```

Both aliases use the same `protocol-platform-intent` form, keep explicit
`(profile ahb)`, and remain IAL2 sources. They do not add direct backend
lowering, broader AHB topology, optional signals, burst continuation, or VHDL
behavior.

Support accounting records the aliases as:

```text
entry_id: intent.ahb_profile_alias_interconnect_byte_lane
source_kind: ial2_profile_alias
coverage: ial2_ahb_profile_alias_interconnect_byte_lane_pipeline_cli
module_name: ahb_tb
composition_child_count: 3

entry_id: intent.ahb_profile_alias_interconnect_two_subordinate_byte_lane
source_kind: ial2_profile_alias
coverage: ial2_ahb_profile_alias_interconnect_two_subordinate_byte_lane_pipeline_cli
module_name: ahb_tb
composition_child_count: 4
```

## Lowering And Reports

The one-subordinate alias lowers through:

```text
.ahb / IAL2
  -> generated amba_requester.isf
  -> generated ahb_lite_subordinate_byte_lane.isf
  -> generated ahb_interconnect.isf
  -> generated amba_requester.fsm
  -> generated ahb_lite_subordinate_byte_lane.fsm
  -> generated ahb_interconnect.fsm
  -> generated ahb_tb.fsm
  -> HDL module ahb_tb
```

The two-subordinate alias lowers through:

```text
.ahb / IAL2
  -> generated amba_requester.isf
  -> generated ahb_status_subordinate_byte_lane.isf
  -> generated ahb_control_subordinate_byte_lane.isf
  -> generated ahb_interconnect.isf
  -> generated amba_requester.fsm
  -> generated ahb_status_subordinate_byte_lane.fsm
  -> generated ahb_control_subordinate_byte_lane.fsm
  -> generated ahb_interconnect.fsm
  -> generated ahb_tb.fsm
  -> HDL module ahb_tb
```

Both use report schema:

```text
fsmgen.ial2.protocol_intent.ahb_interconnect.v1
```

The one-subordinate topology remains
`one_requester_one_subordinate_static_window_interconnect`. The
two-subordinate topology remains
`one_requester_two_subordinate_static_window_interconnect`.

## Byte-Lane Propagation

The aliases preserve the same aggregate byte-lane propagation report block as
the generic `.ppif` sources:

```text
composition.byte_lane_propagation
```

The block records subordinate-owned narrow-transfer policy, subtract-window-base
local-address policy before subordinate lane selection, mapped-hit ownership by
the selected subordinate, interconnect-owned unmapped ERROR behavior, and one
subordinate entry per embedded byte-lane endpoint. Child reports preserve
`narrow_transfer_policy`.

Mapped hits still forward `HTRANS`, `HWRITE`, `HSIZE`, `HWDATA`, and `HREADY`
to the selected byte-lane subordinate. The selected subordinate owns
byte/halfword/word acceptance, little-endian active-lane selection,
inactive-lane-preserving writes, inactive-lane-zero-filled reads, and mapped-hit
ERROR behavior for unsupported size, unsupported transfer, unmapped local
address, unaligned access, and crossing access. Unmapped active transfers
remain interconnect-owned two-cycle ERROR responses.

## Residue

The `.ahb` alias reports remove:

```text
ahb_aggregate_profile_alias_deferred
```

The generic aggregate byte-lane `.ppif` reports keep that residue as a
source-surface distinction. Existing word-only aggregate `.ppif/.ahb` and
endpoint byte-lane `.ppif/.ahb` behavior remains unchanged.

Remaining AHB work stays task-tree-owned future work: optional/property-gated
signals, burst `SEQ` continuation, broader interconnect/decode cardinality,
legacy two-bit subordinate `HRESP`, scoreboards, full-manager behavior, direct
backend behavior, verification-output generation, backend-language variants,
AXI/APB behavior, and VHDL behavior.

## Validation

Focused validation for the slice:

```bash
perl -Iperl -c perl/FSM/Support/RegressionCorpus.pm
perl -Iperl -c perl/FSM/Support/LanguageSurfaceSection.pm
perl -Iperl -c t/1485-ial2-ahb-interconnect-byte-lane-profile-alias.t
perl -Iperl -c t/297-capability-manifest.t
prove -Iperl t/1485-ial2-ahb-interconnect-byte-lane-profile-alias.t
prove -Iperl t/297-capability-manifest.t
./bin/fsmgen --quiet --strict --check --json ppif/ahb_interconnect_byte_lane.ahb
./bin/fsmgen --quiet --strict --check --json ppif/ahb_interconnect_two_subordinate_byte_lane.ahb
```

The RAM-guarded `t/248-regression-corpus-accounting.t` attempt stopped before
TAP because pre-existing host memory was 95.6% against the 88% cutoff; the
cutoff was not bypassed.
