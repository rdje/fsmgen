# IAL2 AHB Aggregate BUSY-Park Propagation Behavior

Task-tree owner: `IAL2-FEATURE-COMPLETENESS-FRONTIER.782`

Date: 2026-07-12

## Outcome

`IAL2-FEATURE-COMPLETENESS-FRONTIER.782` ships both selected bounded generic
`.ppif` AHB aggregate HBURST-aware byte-lane `SEQ` propagation sources with
BUSY-in-burst parking:

```text
ppif/ahb_interconnect_byte_lane_hburst_seq_busy_park.ppif
ppif/ahb_interconnect_two_subordinate_byte_lane_hburst_seq_busy_park.ppif
```

They support-account as:

```text
entry_id: intent.ppif_ahb_interconnect_byte_lane_hburst_seq_busy_park
source_kind: ppif
coverage: ial2_ppif_ahb_interconnect_byte_lane_hburst_seq_busy_park_pipeline_cli
module_name: ahb_tb
composition_child_count: 3

entry_id: intent.ppif_ahb_interconnect_two_subordinate_byte_lane_hburst_seq_busy_park
source_kind: ppif
coverage: ial2_ppif_ahb_interconnect_two_subordinate_byte_lane_hburst_seq_busy_park_pipeline_cli
module_name: ahb_tb
composition_child_count: 4
```

Both stems ship in one slice, mirroring `.770`, which shipped both non-parking
aggregate HBURST `SEQ` stems. The matching aggregate BUSY-park `.ahb` aliases are
not shipped by `.782`; they are routed to a later slice, as `.771`/`.772` routed
the aggregate HBURST aliases.

## Public Source Contract

Each source is a byte-for-byte copy of the shipped aggregate HBURST-aware
byte-lane `SEQ` source
(`ppif/ahb_interconnect_byte_lane_hburst_seq.ppif` and
`ppif/ahb_interconnect_two_subordinate_byte_lane_hburst_seq.ppif`), with only
three fields changed:

- the `(protocol-platform-intent ...)` intent name gains the `_busy_park` suffix;
- the `(source (object ...) (anchor (section ...)))` object and section gain the
  `busy-park` marker; and
- every inlined child subordinate transfer replaces `(ignored-transfer busy)`
  with `(parked-transfer busy)`, keeping `(ignored-transfer idle)`.

The one-subordinate source embeds
`ahb_lite_subordinate_byte_lane_hburst_seq` at window `REG_BASE=0`/`REG_SIZE=4`;
the two-subordinate source embeds
`ahb_status_subordinate_byte_lane_hburst_seq` at `STATUS_BASE=0`/`STATUS_SIZE=4`
and `ahb_control_subordinate_byte_lane_hburst_seq` at
`CONTROL_BASE=4`/`CONTROL_SIZE=4`. Every embedded subordinate keeps transfer
`ahb_lite_byte_lane_hburst_seq_access`, byte/halfword/word `supported-size`,
little-endian lane order, inactive-lane-preserving narrow writes,
inactive-lane-zero-filled narrow reads, ERROR policy for unaligned/crossing
accesses, a child-local `(burst ... width 3)` binding, and
`(seq-policy hburst-in-word-progressive)`.

## BUSY-Park Behavior Delta

`(ignored-transfer idle)` still clears the in-word `SEQ` burst history on an
accepted `IDLE`. `(parked-transfer busy)` now holds that history across an
accepted `HTRANS=BUSY` beat instead of clearing it, so an armed byte-only
`WRAP4`/`INCR4` burst resumes cleanly on the next accepted `SEQ`.

This is entirely the shipped endpoint machinery: `AhbSubordinate` already
implements the `(parked-transfer busy)` vocabulary, the `parked_transfer` field,
and the relaxed `{idle}`-ignored + `{busy}`-parked validation on the child
subordinate role (`AhbSubordinate.pm:214`–`281`). The interconnect composes each
child FSM verbatim, so no interconnect parser, generator, or report code path
changed.

The child `seq_ok_base` `SEQ`-beat validation remains the fail-closed path for a
BUSY beat whose control signals drift from the armed burst, and it propagates
through the composition unchanged.

## Generated Review Artifacts

The one-subordinate source lowers through:

```text
amba_requester.isf
ahb_lite_subordinate_byte_lane_hburst_seq.isf
ahb_interconnect.isf
amba_requester.fsm
ahb_lite_subordinate_byte_lane_hburst_seq.fsm
ahb_interconnect.fsm
ahb_tb.fsm
```

The two-subordinate source lowers through:

```text
amba_requester.isf
ahb_status_subordinate_byte_lane_hburst_seq.isf
ahb_control_subordinate_byte_lane_hburst_seq.isf
ahb_interconnect.isf
amba_requester.fsm
ahb_status_subordinate_byte_lane_hburst_seq.fsm
ahb_control_subordinate_byte_lane_hburst_seq.fsm
ahb_interconnect.fsm
ahb_tb.fsm
```

Both select HDL entry module `ahb_tb`. The generated topology and HDL are
identical to the non-parking aggregate HBURST sources; the delta is the child
clear-on-BUSY versus park-on-BUSY policy inside the embedded subordinate FSMs.

## Reports And Residue

The report schema remains
`fsmgen.ial2.protocol_intent.ahb_interconnect.v1`. Reports preserve
`composition.byte_lane_propagation` and reuse
`composition.seq_policy_propagation` with
`subordinate_owned_hburst_in_word_seq_policy`, `length_source: HBURST`,
request-forwarding `burst`, child `bindings.bus.burst`, child
`transfer.seq_policy`, `supported_hburst_modes`, and `fail_closed_hburst_modes`.

Because `_seq_policy_propagation_report` clones each child `seq_policy` verbatim
(`AhbInterconnect.pm:1177`, `:1207`), every child entry and each subordinate in
`composition.seq_policy_propagation` now carries the child park automatically:

```text
subordinates[*].seq_policy.parks_on  = [busy]
subordinates[*].seq_policy.clears_on = [reset, idle, error, new_nonseq, final_beat]
```

For these aggregate BUSY-park sources, `.782` narrows only the aggregate
`ahb_burst_seq_support_deferred` HBURST residue at `AhbInterconnect.pm:1401`: it
records that byte-only `WRAP4`/`INCR4` aggregate HBURST propagation *with
BUSY-in-burst parking* is shipped, and drops `BUSY-in-burst handling` from the
deferred list. The narrowing is gated on `_all_subordinates_park_busy($contract)`,
so the non-parking aggregate HBURST sources keep `BUSY-in-burst handling`
deferred, and the base non-HBURST aggregate `SEQ` residue at `:1403` is untouched.

Each embedded subordinate child residue flows through the shipped
`AhbSubordinate` endpoint residue, so the child
`ahb_burst_seq_support_deferred` detail records `with BUSY-in-burst parking is
shipped` (with `aggregate propagation` stripped by the interconnect's child
residue projection).

`.799` also makes the two-subordinate topology residue agree with that shipped
policy. When all HBURST children park BUSY,
`ahb_broader_interconnect_decode_deferred` now records byte-only
`WRAP4`/`INCR4` in-word `SEQ` propagation **with BUSY-in-burst parking** as
shipped and no longer lists BUSY continuation as deferred. The branch uses the
same `_all_subordinates_park_busy($contract)` predicate as the dedicated burst
residue. Two-subordinate non-parking HBURST sources retain their existing
`BUSY-in-burst continuation` deferral, and one-subordinate topology residue is
unchanged.

True remaining residue includes the matching aggregate BUSY-park `.ahb` aliases,
requester-side BUSY insertion, halfword/word burst `SEQ`, wider or indefinite
bursts, multi-word/register-bank progression, optional/property-gated AHB
signals, broader AHB behavior, direct backend behavior, verification-output
generation, backend-language variants, AXI/APB behavior, and VHDL.

## Preservation

`.782` preserves the shipped aggregate HBURST `SEQ` sources and their
`t/1492`/`t/1493` assertions (the new stems are additive copies, not edits), the
endpoint BUSY-park `.ppif`/`.ahb` sources and `t/1494`/`t/1495`, and all shipped
AHB requester/subordinate/interconnect/byte-lane/`SEQ`/HBURST/BUSY-park/aggregate/
`.ahb` behavior, including the base non-HBURST aggregate `SEQ` residue.

`.799` is report-only. Focused `t/1496` locks the corrected parked generic
wording, `t/1497` locks the matching alias wording, and `t/1492`/`t/1493` lock
the unchanged non-parking generic/alias deferral.

## Validation

Focused validation:

```bash
perl -Iperl -c perl/FSM/IAL2/ProtocolIntent/AhbInterconnect.pm
perl -Iperl -c perl/FSM/Support/RegressionCorpus.pm
perl -Iperl -c perl/FSM/Support/LanguageSurfaceSection.pm
prove -Iperl t/1496-ial2-ahb-interconnect-byte-lane-hburst-seq-busy-park.t
prove -Iperl t/1492-ial2-ahb-interconnect-byte-lane-hburst-seq.t t/1493-ial2-ahb-interconnect-byte-lane-hburst-seq-profile-alias.t t/1494-ial2-ahb-subordinate-byte-lane-hburst-seq-busy-park.t t/248-regression-corpus-accounting.t t/297-capability-manifest.t
./bin/fsmgen --quiet --strict --check --json ppif/ahb_interconnect_byte_lane_hburst_seq_busy_park.ppif
./bin/fsmgen --quiet --strict --check --json ppif/ahb_interconnect_two_subordinate_byte_lane_hburst_seq_busy_park.ppif
./bin/fsmgen --quiet --emit-schedule-json ppif/ahb_interconnect_byte_lane_hburst_seq_busy_park.ppif
```

The two-subordinate `--check` is slow (~63s); run heavy `prove`/`fsmgen` under
`scripts/run_with_ram_guard.sh` or equivalent monitoring.
