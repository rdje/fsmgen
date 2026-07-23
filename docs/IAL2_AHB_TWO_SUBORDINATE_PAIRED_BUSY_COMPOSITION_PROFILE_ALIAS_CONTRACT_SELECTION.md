# IAL2 AHB Two-Subordinate Paired BUSY Composition `.ahb` Profile Alias Contract Selection

Task-tree owner: `IAL2-FEATURE-COMPLETENESS-FRONTIER.802`

Date: 2026-07-23

## Outcome

`.802` selects `IAL2-FEATURE-COMPLETENESS-FRONTIER.803`, direct data-only
implementation of the matching bounded two-subordinate paired AHB BUSY
composition `.ahb` profile alias:

```text
ppif/ahb_interconnect_requester_busy_insert_two_subordinate_byte_lane_hburst_seq_busy_park.ahb
```

The alias must be byte-identical to the generic source shipped by `.801`:

```text
ppif/ahb_interconnect_requester_busy_insert_two_subordinate_byte_lane_hburst_seq_busy_park.ppif
```

This is a second public filename/suffix surface over the same IAL2 model. It
does not select another generator, parser path, lowering chain, or bus
behavior. Decision `0020`, its protocol-neutral transaction-layer horizon,
and proposed audits remain inactive until ongoing work explicitly dries out.

## Evidence and Readiness Probe

The selector reconciled `.798`-`.801`, the one-subordinate paired
`.ppif`/`.ahb` precedent, the two-subordinate BUSY-park `.ppif`/`.ahb`
precedent, current PPIF suffix handling, support/language/capability surfaces,
focused tests, README, ROADMAP_V2, mdBook, Knowledge Map, task tree, Memory,
proposed audits, and decision `0020`.

An in-memory adapter probe parsed the shipped `.801` source under the reserved
future `.ahb` label. The existing code produced:

```text
layer:       IAL2
kind:        protocol_intent.ahb_interconnect
child count: 4

IAL1:
  amba_requester_busy_insert.isf
  ahb_status_subordinate_byte_lane_hburst_seq.isf
  ahb_control_subordinate_byte_lane_hburst_seq.isf
  ahb_interconnect.isf

IAL0:
  amba_requester_busy_insert.fsm
  ahb_status_subordinate_byte_lane_hburst_seq.fsm
  ahb_control_subordinate_byte_lane_hburst_seq.fsm
  ahb_interconnect.fsm
  ahb_tb.fsm
```

The probe retained requester-child `busy_insertion.before_beat = 2` and
`parks_on = [busy]` for both status/control children. Existing suffix-keyed
handling removed `ahb_aggregate_profile_alias_deferred`, requester-child
`ahb_profile_alias_deferred`, both subordinate-child
`ahb_subordinate_profile_alias_deferred` occurrences, and `.ahb alias
exposure` wording. It retained `ahb_requester_busy_insert_support` and
`ahb_burst_seq_support_deferred`. No parser, endpoint, interconnect, report,
artifact, top, or HDL prerequisite exists.

## Why the Alias Is Next

The alias is the smallest roadmap-aligned follow-on to `.801`:

1. It completes the established generic-then-alias cadence for the exact
   source whose generated behavior is already proven.
2. It adds only a byte-identical source fixture, support/language accounting,
   parity test, and documentation.
3. t/1515 remains the authoritative status/control generated-HDL runtime
   proof; the alias needs parity and public-surface proof, not a second runtime
   implementation.
4. Multiple/policy BUSY, local bus-BUSY status, larger burst progression,
   boundary-free active-transfer pipelining, and optional signals each open a
   new behavioral contract and are therefore larger.

## Selected `.803` Public Contract

```text
alias path:
  ppif/ahb_interconnect_requester_busy_insert_two_subordinate_byte_lane_hburst_seq_busy_park.ahb

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

`.803` must:

- add the `.ahb` source as a byte-identical mirror of the `.ppif` source;
- add exactly one support entry, moving protocol fixtures `313 -> 314` and
  supported-smoke/strict entries `354 -> 355`;
- extend `LanguageSurfaceSection` and t/297 for the matching alias boundary;
- preserve the exact four IAL1/five IAL0 artifacts, module `ahb_tb`, semantic
  root `top`, four-child/29-signal shape, and `[0,4)`/`[4,8)` windows;
- preserve requester `busy_insertion`, both child and propagated
  `parks_on = [busy]` policies, no top `busy_flow`, and the `.799` report
  truthfulness repair;
- remove only the existing aggregate/requester/two-subordinate alias residue
  and alias-exposure wording through current suffix handling;
- add
  `t/1516-ial2-ahb-two-subordinate-paired-busy-composition-profile-alias.t`
  for byte parity, check/schedule/semantic/outdir/HDL/support/report/residue/
  diagnostic proof and public alias `--verify-hdl`; and
- retain t/1515 as the shared two-window generated-HDL runtime proof.

No new diagnostic is selected. Existing `.ahb` profile/mismatch validation,
requester BUSY validation, subordinate parked-transfer validation, and
interconnect topology/address/wiring validation remain authoritative.

## Preservation, Validation, and Rollback

`.803` must preserve t/1515, the one-subordinate paired t/1513/t/1514 family,
the parked two-subordinate t/1496/t/1497 family, the non-parking
t/1492/t/1493 family, and all existing counts except the exact +1 entry. It
must not change parser/generator algorithms, add a top summary, broaden BUSY,
status, burst, signal, backend, AXI/APB, or VHDL behavior, or activate decision
`0020` or proposed audits.

Focused implementation validation is t/1516 plus retained t/1515, t/1514,
t/1497, t/248, and t/297 as warranted; public strict check, schedule,
semantic, outdir, and `--verify-hdl` run on the alias. Heavy commands retain
direct macOS pressure and descendant-RSS monitoring.

`.802` rollback is documentation-only: remove this selector record/fact and
restore `.802` active. `.803` rollback removes only the alias fixture, its
support/language/test/doc entries, and the +1 counts; `.801` generic behavior
remains untouched.
