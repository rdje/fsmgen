# IAL2 Post-AHB Two-Subordinate PPIF Next Slice Selection

Task-tree owner: `IAL2-FEATURE-COMPLETENESS-FRONTIER.731`

Date: 2026-06-30

## Outcome

`IAL2-FEATURE-COMPLETENESS-FRONTIER.731` selects
`IAL2-FEATURE-COMPLETENESS-FRONTIER.732`, direct implementation of the
matching bounded public AHB two-subordinate `.ahb` profile alias:

```text
ppif/ahb_interconnect_two_subordinate.ahb
```

The selector changes no parser behavior, generator behavior, public source
sample, support-accounting catalog, capability manifest, focused test
behavior, schedule/check/semantic JSON behavior, generated artifact,
HDL/runtime behavior, direct backend behavior, verification-output generation,
backend-language variant, AXI behavior, APB behavior, broader AHB behavior, or
VHDL behavior.

## Current Boundary

The generic two-subordinate AHB interconnect/decode source now ships:

```text
ppif/ahb_interconnect_two_subordinate.ppif
```

It support-accounts as:

```text
entry_id: intent.ppif_ahb_interconnect_two_subordinate
source_kind: ppif
coverage: ial2_ppif_ahb_interconnect_two_subordinate_pipeline_cli
module_name: ahb_tb
composition_child_count: 4
```

The shipped one-subordinate aggregate profile alias remains supported:

```text
ppif/ahb_interconnect.ahb
entry_id: intent.ahb_profile_alias_interconnect
source_kind: ial2_profile_alias
coverage: ial2_ahb_profile_alias_interconnect_pipeline_cli
composition_child_count: 3
```

The selected two-subordinate source under an `.ahb` label still fails closed at
the profile-alias guard:

```text
Error: .ahb source 'ppif/ahb_interconnect_two_subordinate.ahb' profile ahb
requires exactly one (ahb-requester ...) object, exactly one
(ahb-subordinate ...) object, or the selected aggregate
one-requester/one-subordinate (ahb-interconnect ...) shape in this slice
```

That failure is now the next exact AHB surface gap: the generic behavior is
proven, and decision `0015` requires protocol-profile suffixes to remain
aliases over the same IAL2 model and generated review chain.

## Selected `.732` Contract

`.732` must add the matching profile-alias source:

```text
ppif/ahb_interconnect_two_subordinate.ahb
```

The alias must mirror the shipped generic source:

```text
ppif/ahb_interconnect_two_subordinate.ppif
```

It keeps explicit `(profile ahb)`, the same one requester, the same two unique
subordinate objects, the same two subordinate child bindings, the same two
non-overlapping static windows, the same requester/global interconnect wiring,
and the same per-subordinate bus names from each subordinate object.

The generated review chain remains:

```text
.ahb / IAL2
  -> generated amba_requester.isf
  -> generated ahb_status_subordinate.isf
  -> generated ahb_control_subordinate.isf
  -> generated ahb_interconnect.isf
  -> generated amba_requester.fsm
  -> generated ahb_status_subordinate.fsm
  -> generated ahb_control_subordinate.fsm
  -> generated ahb_interconnect.fsm
  -> generated ahb_tb.fsm
  -> HDL module ahb_tb
```

The report schema and topology remain:

```text
schema: fsmgen.ial2.protocol_intent.ahb_interconnect.v1
topology: one_requester_two_subordinate_static_window_interconnect
composition_child_count: 4
```

The selected alias support-accounting identity is:

```text
entry_id: intent.ahb_profile_alias_interconnect_two_subordinate
source_kind: ial2_profile_alias
coverage: ial2_ahb_profile_alias_interconnect_two_subordinate_pipeline_cli
```

The alias report must remove only `ahb_aggregate_profile_alias_deferred` from
the two-subordinate alias report. The generic `.ppif` two-subordinate report
must keep that residue. Both the generic `.ppif` and the new `.ahb` alias must
keep `ahb_broader_interconnect_decode_deferred` for broader AHB work.

## Validation And Diagnostics

`.732` should add focused profile-alias coverage, likely:

```text
t/1481-ial2-ahb-interconnect-two-subordinate-profile-alias.t
```

The focused test should verify:

- `ppif/ahb_interconnect_two_subordinate.ahb` strict check succeeds;
- check JSON reports `intent.ahb_profile_alias_interconnect_two_subordinate`,
  `source_kind ial2_profile_alias`, selected coverage, module `ahb_tb`, and
  `composition_child_count: 4`;
- schedule and semantic JSON preserve authored `.ahb` source identity and the
  generated `top` root;
- generated artifacts match the generic two-subordinate review chain;
- the alias report removes `ahb_aggregate_profile_alias_deferred` only for the
  `.ahb` source;
- the generic `ppif/ahb_interconnect_two_subordinate.ppif` report still keeps
  the profile-alias residue;
- existing `ppif/ahb_interconnect.ahb`, `ppif/ahb_interconnect.ppif`, and
  `ppif/ahb_interconnect_two_subordinate.ppif` behavior remains unchanged; and
- malformed two-subordinate alias inputs still fail closed for non-AHB
  profiles, wrong cardinality, duplicate subordinate objects, duplicate child
  instances, duplicate child object references, missing/wrong/overlapping
  windows, scalar subordinate wiring, and broader unsupported shapes.

Support-accounting and capability-manifest checks must be updated alongside the
new alias row. Closeout must run focused AHB tests, direct lightweight
accounting/manifest tests, mdBook build, docs path audit, Knowledge Map
generation/check, memory architecture check, diff check, and the doctrine
driver. Broad or potentially heavyweight Perl/`prove`/`fsmgen` commands must
remain RAM-guarded.

## Rollback And Residue

Rollback for `.732` is bounded: remove the new `.ahb` fixture, restore the
`.ahb` aggregate profile-alias guard to one-subordinate interconnects only,
remove the alias support-accounting/capability rows and focused tests, and
restore docs to the `.731` deferred state.

`.732` must not add two-or-more public cardinality beyond the selected
two-subordinate fixture, multiple requesters, arbitration, bus matrices,
optional signals, burst `SEQ` continuation, byte-lane/narrow-transfer
behavior, legacy two-bit subordinate `HRESP` compatibility, direct backend
behavior, verification-output generation, backend-language variants, AXI, APB,
broader AHB interconnect/decode behavior, or VHDL behavior.
