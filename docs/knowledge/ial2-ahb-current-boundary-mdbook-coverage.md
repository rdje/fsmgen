---
id: ial2-ahb-current-boundary-mdbook-coverage
title: AHB mdBook coverage documents bounded PPIF, .ahb alias, interconnect, and direct FSM coverage
answers:
  - "where is the AHB current-boundary mdBook chapter?"
  - "is AHB IAL2 shipped?"
  - "is .ahb accepted by fsmgen?"
  - "what AHB support exists today?"
  - "what must happen before AHB guided more-control or raw full-control IAL2 modes ship?"
date: 2026-06-30
status: current
tags: [ial2, ahb, amba, mdbook, protocol-intent, profile-alias, documentation]
evidence: docs/book/src/16c-ial2-ahb.md; docs/book/src/16-ial2-protocol-platform-intent.md; docs/IAL2_AHB_PROFILE_ALIAS_BEHAVIOR.md; docs/IAL2_AHB_SUBORDINATE_PPIF_BEHAVIOR.md; docs/IAL2_AHB_INTERCONNECT_DECODE_BEHAVIOR.md; docs/IAL2_AHB_INTERCONNECT_PROFILE_ALIAS_BEHAVIOR.md; docs/IAL2_AHB_TWO_SUBORDINATE_BEHAVIOR.md; docs/IAL2_AHB_TWO_SUBORDINATE_PROFILE_ALIAS_BEHAVIOR.md; ppif/ahb_requester.ppif; ppif/ahb_requester.ahb; ppif/ahb_lite_subordinate.ppif; ppif/ahb_lite_subordinate.ahb; ppif/ahb_interconnect.ppif; ppif/ahb_interconnect.ahb; ppif/ahb_interconnect_two_subordinate.ppif; ppif/ahb_interconnect_two_subordinate.ahb; fsm/amba_requester.fsm; fsm/ahb_lite_subordinate.fsm; perl/FSM/Support/RegressionCorpus.pm; bin/fsmgen; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md
reverify: >-
  rg -n 'AHB IAL2 Current Boundary|ppif/ahb_requester\.ppif|ppif/ahb_lite_subordinate\.ppif|ppif/ahb_interconnect\.ppif|ppif/ahb_interconnect_two_subordinate\.ppif|ppif/ahb_requester\.ahb|ppif/ahb_lite_subordinate\.ahb|ppif/ahb_interconnect\.ahb|ppif/ahb_interconnect_two_subordinate\.ahb|intent\.ppif_ahb_requester|intent\.ppif_ahb_lite_subordinate|intent\.ppif_ahb_interconnect|intent\.ppif_ahb_interconnect_two_subordinate|intent\.ahb_profile_alias_requester|intent\.ahb_profile_alias_subordinate|intent\.ahb_profile_alias_interconnect|intent\.ahb_profile_alias_interconnect_two_subordinate|protocol\.amba_requester|source_kind.*ppif|source_kind.*ial2_profile_alias|source_kind.*fsm|16c-ial2-ahb' docs/book/src/16c-ial2-ahb.md docs/book/src/16-ial2-protocol-platform-intent.md docs/book/src/SUMMARY.md
  docs/IAL2_AHB_PROFILE_ALIAS_BEHAVIOR.md docs/IAL2_AHB_SUBORDINATE_PPIF_BEHAVIOR.md docs/IAL2_AHB_INTERCONNECT_DECODE_BEHAVIOR.md docs/IAL2_AHB_INTERCONNECT_PROFILE_ALIAS_BEHAVIOR.md docs/IAL2_AHB_TWO_SUBORDINATE_BEHAVIOR.md docs/IAL2_AHB_TWO_SUBORDINATE_PROFILE_ALIAS_BEHAVIOR.md docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md perl/FSM/Support/RegressionCorpus.pm ppif/ahb_requester.ppif ppif/ahb_requester.ahb ppif/ahb_lite_subordinate.ppif ppif/ahb_lite_subordinate.ahb ppif/ahb_interconnect.ppif ppif/ahb_interconnect.ahb ppif/ahb_interconnect_two_subordinate.ppif ppif/ahb_interconnect_two_subordinate.ahb fsm/amba_requester.fsm fsm/ahb_lite_subordinate.fsm
---

`docs/book/src/16c-ial2-ahb.md` is the user-facing AHB current-boundary
chapter under the IAL2 protocol/platform intent mdBook section.

The chapter documents the shipped bounded AHB IAL2 surfaces:
`ppif/ahb_requester.ppif`, `ppif/ahb_lite_subordinate.ppif`,
`ppif/ahb_interconnect.ppif`, and
`ppif/ahb_interconnect_two_subordinate.ppif`, plus matching selected `.ahb`
profile aliases at `ppif/ahb_requester.ahb`,
`ppif/ahb_lite_subordinate.ahb`, `ppif/ahb_interconnect.ahb`, and
`ppif/ahb_interconnect_two_subordinate.ahb`.

The generic `.ppif` surfaces are support-accounted as
`intent.ppif_ahb_requester`, `intent.ppif_ahb_lite_subordinate`,
`intent.ppif_ahb_interconnect`, and
`intent.ppif_ahb_interconnect_two_subordinate` with `source_kind` `ppif`.
The `.ahb` aliases are support-accounted as
`intent.ahb_profile_alias_requester`,
`intent.ahb_profile_alias_subordinate`,
`intent.ahb_profile_alias_interconnect`, and
`intent.ahb_profile_alias_interconnect_two_subordinate` with `source_kind`
`ial2_profile_alias`.

The older direct `.fsm` coverage remains at `fsm/amba_requester.fsm`,
support-accounted as `protocol.amba_requester` with `source_kind` `fsm`, and
the direct lower-layer subordinate seed remains at
`fsm/ahb_lite_subordinate.fsm`. AHB IAL2 paths lower through generated `.isf`
before generated `.fsm` review artifacts.

AHB completer behavior, broader interconnect/decode beyond the selected
one-subordinate and two-subordinate static-window aggregate shapes,
scoreboards, full-manager behavior, direct backend, verification-output
generation, backend-language variants, and VHDL remain task-tree-owned
residue.
