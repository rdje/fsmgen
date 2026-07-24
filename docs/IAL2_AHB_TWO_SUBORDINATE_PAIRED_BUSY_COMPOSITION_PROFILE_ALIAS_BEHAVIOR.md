# IAL2 AHB Two-Subordinate Paired BUSY Composition `.ahb` Profile Alias Behavior

Task-tree owner: `IAL2-FEATURE-COMPLETENESS-FRONTIER.803`

Date: 2026-07-23

## Outcome

FSMGen ships the bounded two-subordinate paired AHB BUSY composition through
both public IAL2 source surfaces:

```text
ppif/ahb_interconnect_requester_busy_insert_two_subordinate_byte_lane_hburst_seq_busy_park.ppif
ppif/ahb_interconnect_requester_busy_insert_two_subordinate_byte_lane_hburst_seq_busy_park.ahb
```

The files are byte-identical. `.ppif` is the generic Protocol/Platform Intent
container; `.ahb` is the AHB profile alias. They are not separate generators:
both enter the same adapter and reuse the same requester, status/control
subordinate, interconnect, top, and HDL generators.

```text
IAL2 source (.ppif or .ahb)
  -> amba_requester_busy_insert.isf
   + ahb_status_subordinate_byte_lane_hburst_seq.isf
   + ahb_control_subordinate_byte_lane_hburst_seq.isf
   + ahb_interconnect.isf
  -> amba_requester_busy_insert.fsm
   + ahb_status_subordinate_byte_lane_hburst_seq.fsm
   + ahb_control_subordinate_byte_lane_hburst_seq.fsm
   + ahb_interconnect.fsm
   + ahb_tb.fsm
  -> SystemVerilog module ahb_tb
```

## Shared Behavior and Report

Both surfaces describe one BUSY-inserting requester and two static
BUSY-parking subordinate windows:

```text
status:  global [0,4), local HADDR
control: global [4,8), local HADDR - 4
```

Strict check reports module `ahb_tb`, four children, 29 top signals, and
semantic root `top`. Schedule/report JSON exposes requester-child
`busy_insertion` with `2'b01`, before-beat two, and one bounded presentation.
Both status/control child SEQ policies and both propagated composition entries
retain `parks_on = [busy]`. There is no duplicate top-level `busy_flow`.

t/1515 remains the shared generated-HDL runtime proof. It drives status-base-0
and control-base-4 byte `INCR4` commands, each observing:

```text
NONSEQ(0) -> SEQ(1) -> BUSY(2 held) -> SEQ(2 resumed) -> SEQ(3)
```

The proof establishes selected-child parking, unselected-child
non-interference, control local-address subtraction, OKAY/zero completion,
and retained status/control storage `32'h44332211`/`32'h88776655`.

## Alias-Only Difference

The `.ahb` suffix requires explicit `(profile ahb)` and activates existing
suffix-keyed report cleanup. Relative to the generic `.ppif` report, the alias
removes only:

- top `ahb_aggregate_profile_alias_deferred`;
- requester-child `ahb_profile_alias_deferred`;
- each subordinate child's `ahb_subordinate_profile_alias_deferred`; and
- `.ahb alias exposure` wording inside retained residue.

It preserves requester `ahb_requester_busy_insert_support`, the bounded burst
support residue, the `.799` parked-source report truthfulness, generated
artifacts, address map, module, and runtime behavior. Non-AHB profiles and
missing explicit profiles still fail closed.

## Support and Verification

```text
support id:
  intent.ahb_profile_alias_interconnect_requester_busy_insert_two_subordinate_byte_lane_hburst_seq_busy_park
coverage:
  ial2_ahb_profile_alias_interconnect_requester_busy_insert_two_subordinate_byte_lane_hburst_seq_busy_park_pipeline_cli
family:         protocol_fixture
classification: supported_smoke
source kind:    ial2_profile_alias
strict:         true
HDL module:     ahb_tb
child count:    4
semantic root:  top
```

The support corpus now contains 314 protocol fixtures and 355
supported-smoke/strict entries. The AHB mdBook inventory contains 38 public
bounded IAL2 source paths.

t/1516 proves byte parity, check/schedule/semantic/outdir/HDL/support/report
surfaces, exact artifacts/windows/BUSY metadata, alias-only residue cleanup,
malformed profile diagnostics, generic-source preservation, and clean public
alias `--verify-hdl`.

```bash
./bin/fsmgen --quiet --strict --check --json \
  ppif/ahb_interconnect_requester_busy_insert_two_subordinate_byte_lane_hburst_seq_busy_park.ahb
./bin/fsmgen --quiet --emit-schedule-json \
  ppif/ahb_interconnect_requester_busy_insert_two_subordinate_byte_lane_hburst_seq_busy_park.ahb
./bin/fsmgen --quiet --strict --emit-semantic-json \
  ppif/ahb_interconnect_requester_busy_insert_two_subordinate_byte_lane_hburst_seq_busy_park.ahb
./bin/fsmgen --quiet --strict --verify-hdl \
  ppif/ahb_interconnect_requester_busy_insert_two_subordinate_byte_lane_hburst_seq_busy_park.ahb
prove -Iperl t/1516-ial2-ahb-two-subordinate-paired-busy-composition-profile-alias.t
```

## Explicit Deferrals

Policy-driven or multiple BUSY insertion, distinct local bus-BUSY status,
general/deeper request or response queues, multiple outstanding transfers,
halfword/word or wider/
indefinite burst progression, multi-word/register-bank behavior, optional AHB
signals, legacy two-bit subordinate `HRESP`, broader manager/interconnect
behavior, direct backend, verification-output generation, backend-language
variants, AXI/APB behavior changes, VHDL, decision `0020`, and proposed audits
remain deferred/inactive.

The alias shares the depth-one active-phase pipeline documented in
`docs/IAL2_AHB_PIPELINED_ACTIVE_TRANSFER_REPAIR.md`; it is not a separate
generator.
