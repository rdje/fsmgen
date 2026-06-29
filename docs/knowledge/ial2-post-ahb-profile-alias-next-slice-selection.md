---
id: ial2-post-ahb-profile-alias-next-slice-selection
title: AHB completer/subordinate readiness follows shipped AHB requester alias
answers:
  - "what did IAL2-FEATURE-COMPLETENESS-FRONTIER.701 select?"
  - "what comes after AHB .ahb profile alias shipped?"
  - "which AHB residue is next after .700?"
  - "is AHB completer/subordinate readiness next after the AHB requester alias?"
  - "why not AHB interconnect/decode after .700?"
date: 2026-06-29
status: current
tags: [ial2, ahb, profile-alias, completer, subordinate, readiness, task-tree]
evidence: docs/IAL2_POST_AHB_PROFILE_ALIAS_NEXT_SLICE_SELECTION.md; docs/IAL2_AHB_COMPLETER_SUBORDINATE_READINESS_AUDIT.md; docs/IAL2_AHB_PROFILE_ALIAS_BEHAVIOR.md; docs/IAL2_AHB_REQUESTER_PPIF_BEHAVIOR.md; docs/book/src/16c-ial2-ahb.md; ppif/ahb_requester.ppif; ppif/ahb_requester.ahb; fsm/amba_requester.fsm; perl/FSM/Adapter/IAL2/PPIF.pm; perl/FSM/IAL2/ProtocolIntent/AhbRequester.pm; perl/FSM/Support/RegressionCorpus.pm; perl/FSM/Support/LanguageSurfaceSection.pm; t/1473-ial2-ahb-requester.t; t/1474-ial2-ahb-profile-alias.t; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/TASK_TREE.md; MEMORY.md; README.md; ROADMAP_V2.md
reverify: ./bin/fsmgen --quiet --emit-schedule-json ppif/ahb_requester.ppif && ./bin/fsmgen --quiet --emit-schedule-json ppif/ahb_requester.ahb && rg -n 'ahb_completer_subordinate_deferred|ahb_interconnect_decode_deferred|AHB completer/subordinate generation|AHB interconnect/decode generation|IAL2-FEATURE-COMPLETENESS-FRONTIER\.703' docs/IAL2_POST_AHB_PROFILE_ALIAS_NEXT_SLICE_SELECTION.md docs/IAL2_AHB_COMPLETER_SUBORDINATE_READINESS_AUDIT.md docs/IAL2_AHB_REQUESTER_PPIF_BEHAVIOR.md docs/IAL2_AHB_PROFILE_ALIAS_BEHAVIOR.md docs/book/src/16c-ial2-ahb.md
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.701` selects
`IAL2-FEATURE-COMPLETENESS-FRONTIER.702`, AHB completer/subordinate readiness
audit after bounded AHB requester `.ppif` and `.ahb` profile-alias support
both shipped.

The next owner is a readiness-audit leaf, not immediate behavior. `.702` must
audit lower-layer evidence, source vocabulary, generated `.isf` and `.fsm`
review-artifact expectations, report schema, residue, support-accounting
identity, diagnostics, validation, and rollback before any AHB
completer/subordinate parser/generator/source behavior is added.

The current AHB IAL2 surface is requester-only: `ppif/ahb_requester.ppif`,
`ppif/ahb_requester.ahb`, and direct seed `fsm/amba_requester.fsm`. Both AHB
IAL2 reports keep `ahb_completer_subordinate_deferred` and
`ahb_interconnect_decode_deferred` explicit. Interconnect/decode is later
because it needs at least one selected subordinate endpoint shape first.

Later status: `.702` found that current AHB evidence is requester-only and
selected `.703`, lower-layer AHB subordinate seed contract selection, before
any IAL2 AHB completer/subordinate contract selection.

Full AHB manager behavior, scoreboards, direct backend, verification-output,
backend-language variants, AXI, APB, and VHDL remain future owners.
