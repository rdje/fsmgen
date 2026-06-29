---
id: ial2-ahb-current-boundary-mdbook-coverage
title: AHB mdBook coverage documents bounded PPIF, .ahb alias, and direct FSM coverage
answers:
  - "where is the AHB current-boundary mdBook chapter?"
  - "is AHB IAL2 shipped?"
  - "is .ahb accepted by fsmgen?"
  - "what AHB support exists today?"
  - "what must happen before AHB guided more-control or raw full-control IAL2 modes ship?"
date: 2026-06-29
status: current
tags: [ial2, ahb, amba, mdbook, protocol-intent, profile-alias, documentation]
evidence: docs/book/src/16c-ial2-ahb.md; docs/book/src/16-ial2-protocol-platform-intent.md; docs/IAL2_AHB_PROFILE_ALIAS_BEHAVIOR.md; docs/IAL2_POST_AHB_PROFILE_ALIAS_NEXT_SLICE_SELECTION.md; docs/IAL2_AHB_COMPLETER_SUBORDINATE_READINESS_AUDIT.md; docs/IAL2_AHB_SUBORDINATE_SEED_PREREQUISITE_SELECTION.md; ppif/ahb_requester.ppif; ppif/ahb_requester.ahb; fsm/amba_requester.fsm; perl/FSM/Support/RegressionCorpus.pm; perl/FSM/IAL2/ProtocolIntent/AhbRequester.pm; bin/fsmgen; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md
reverify: rg -n 'AHB IAL2 Current Boundary|ppif/ahb_requester\.ppif|ppif/ahb_requester\.ahb|intent\.ppif_ahb_requester|intent\.ahb_profile_alias_requester|protocol\.amba_requester|source_kind.*ppif|source_kind.*ial2_profile_alias|source_kind.*fsm|IAL2-FEATURE-COMPLETENESS-FRONTIER\.704|source-reference|16c-ial2-ahb' docs/book/src/16c-ial2-ahb.md docs/book/src/16-ial2-protocol-platform-intent.md docs/book/src/SUMMARY.md docs/IAL2_AHB_PROFILE_ALIAS_BEHAVIOR.md docs/IAL2_POST_AHB_PROFILE_ALIAS_NEXT_SLICE_SELECTION.md docs/IAL2_AHB_COMPLETER_SUBORDINATE_READINESS_AUDIT.md docs/IAL2_AHB_SUBORDINATE_SEED_PREREQUISITE_SELECTION.md docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md perl/FSM/Support/RegressionCorpus.pm ppif/ahb_requester.ppif ppif/ahb_requester.ahb fsm/amba_requester.fsm
---

`docs/book/src/16c-ial2-ahb.md` is the user-facing AHB current-boundary
chapter under the IAL2 protocol/platform intent mdBook section.

The chapter now documents three AHB surfaces: bounded requester IAL2 coverage
via `ppif/ahb_requester.ppif`, support-accounted as
`intent.ppif_ahb_requester` with `source_kind` `ppif`; the selected `.ahb`
profile alias `ppif/ahb_requester.ahb`, support-accounted as
`intent.ahb_profile_alias_requester` with `source_kind` `ial2_profile_alias`;
and the older direct `.fsm` coverage at `fsm/amba_requester.fsm`,
support-accounted as `protocol.amba_requester` with `source_kind` `fsm`.

AHB IAL2 is shipped for the bounded generic `.ppif` requester and the selected
bounded `.ahb` profile alias. Both IAL2 paths lower through generated
`amba_requester.isf` before generated `amba_requester.fsm`.

AHB completers/subordinates, interconnect/decode, scoreboards, full-manager
behavior, direct backend, verification-output generation, backend-language
variants, and VHDL remain task-tree-owned residue.

`IAL2-FEATURE-COMPLETENESS-FRONTIER.703` selected `.704`, AHB subordinate
source-reference and seed-evidence audit, as the next owner before lower-layer
seed contract selection. The selector found no local AHB/AHB-Lite source
reference under `docs/vendor/`, so subordinate signal/timing/storage/response
and error-policy facts must be source-backed before any AHB subordinate source,
parser, generator, support-accounting, or manifest behavior is added.
