---
id: ial2-ahb-interconnect-decode-readiness-audit
title: AHB interconnect/decode is ready for contract selection
answers:
  - "is AHB interconnect decode ready after requester and subordinate entrypoints?"
  - "what does IAL2-FEATURE-COMPLETENESS-FRONTIER.720 select?"
  - "what is the first AHB interconnect topology boundary?"
  - "why not implement AHB interconnect directly?"
  - "which AHB residue key should interconnect decode converge on?"
date: 2026-06-29
status: current
tags: [ial2, ahb, interconnect, decode, readiness, contract-selection, task-tree]
evidence: docs/IAL2_AHB_INTERCONNECT_DECODE_READINESS_AUDIT.md; docs/IAL2_POST_AHB_SUBORDINATE_ALIAS_NEXT_SLICE_SELECTION.md; docs/IAL2_AHB_SUBORDINATE_SOURCE_FACT_INVENTORY.md; docs/IAL2_AHB_REQUESTER_PPIF_BEHAVIOR.md; docs/IAL2_AHB_PROFILE_ALIAS_BEHAVIOR.md; docs/IAL2_AHB_SUBORDINATE_PPIF_BEHAVIOR.md; docs/IAL2_AHB_SUBORDINATE_PROFILE_ALIAS_BEHAVIOR.md; fsm/amba_requester.fsm; fsm/ahb_lite_subordinate.fsm; perl/FSM/IAL2/ProtocolIntent/AhbRequester.pm; perl/FSM/IAL2/ProtocolIntent/AhbSubordinate.pm; docs/book/src/16c-ial2-ahb.md; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/TASK_TREE.md; MEMORY.md; README.md; ROADMAP_V2.md
reverify: ./bin/fsmgen --quiet --strict --check --json ppif/ahb_requester.ppif && ./bin/fsmgen --quiet --strict --check --json ppif/ahb_lite_subordinate.ahb && rg -n 'IAL2-FEATURE-COMPLETENESS-FRONTIER\.720|IAL2-FEATURE-COMPLETENESS-FRONTIER\.721|AHB interconnect/decode is ready|ahb_interconnect_decode_deferred' docs/IAL2_AHB_INTERCONNECT_DECODE_READINESS_AUDIT.md docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md docs/TASK_TREE.md README.md ROADMAP_V2.md docs/book/src/14-feature-backlog.md MEMORY.md
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.720` finds AHB interconnect/decode ready
for public contract selection and selects
`IAL2-FEATURE-COMPLETENESS-FRONTIER.721`.

The first boundary should stay conservative: generic `.ppif`, one requester,
one AHB-Lite/common-AHB subordinate, one static address window, generated
review artifacts before IAL0/HDL, and no multi-subordinate fabric, multiple
managers, bus matrix, optional AHB5 signals, burst `SEQ` continuation,
byte-lane/narrow-transfer behavior, or direct backend behavior.

Direct implementation is rejected because the source vocabulary, generated
artifact names, `HRESP` width-conversion policy, `HREADY` aggregation,
report/support-accounting contract, diagnostics, and residue migration are not
selected yet. The canonical future interconnect residue should converge on
`ahb_interconnect_decode_deferred`; subordinate
`ahb_interconnect_generation_deferred` remains historical until a later
contract and behavior slice migrate it.
