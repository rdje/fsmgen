---
id: ial2-post-ahb-subordinate-ppif-next-slice-selection
title: AHB subordinate .ahb contract selection follows shipped subordinate PPIF
answers:
  - "what did IAL2-FEATURE-COMPLETENESS-FRONTIER.716 select?"
  - "what comes after AHB subordinate PPIF shipped?"
  - "which AHB residue is next after .715?"
  - "is AHB subordinate .ahb alias exposure next after subordinate PPIF?"
  - "why not AHB interconnect/decode after .715?"
date: 2026-06-29
status: current
tags: [ial2, ahb, subordinate, ppif, profile-alias, task-tree]
evidence: docs/IAL2_POST_AHB_SUBORDINATE_PPIF_NEXT_SLICE_SELECTION.md; docs/IAL2_AHB_SUBORDINATE_PPIF_BEHAVIOR.md; docs/IAL2_AHB_SUBORDINATE_PUBLIC_CONTRACT_SELECTION.md; docs/IAL2_AHB_SUBORDINATE_GENERATED_IAL1_SUBSTRATE_AUDIT.md; docs/IAL2_GENERATED_IAL1_OUTPUT_DEFAULT_RESET_BEHAVIOR.md; docs/IAL2_AHB_PROFILE_ALIAS_BEHAVIOR.md; ppif/ahb_lite_subordinate.ppif; ppif/ahb_requester.ahb; fsm/ahb_lite_subordinate.fsm; perl/FSM/Adapter/IAL2/PPIF.pm; perl/FSM/IAL2/ProtocolIntent/AhbSubordinate.pm; perl/FSM/Support/RegressionCorpus.pm; perl/FSM/Support/LanguageSurfaceSection.pm; t/1474-ial2-ahb-profile-alias.t; t/1475-ial2-ahb-subordinate.t; docs/book/src/16c-ial2-ahb.md; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/TASK_TREE.md; MEMORY.md; README.md; ROADMAP_V2.md
reverify: ./bin/fsmgen --quiet --strict --check --json ppif/ahb_lite_subordinate.ppif && ./bin/fsmgen --quiet --emit-schedule-json ppif/ahb_lite_subordinate.ppif && ./bin/fsmgen --quiet --strict --check --json ppif/ahb_requester.ahb && rg -n 'IAL2-FEATURE-COMPLETENESS-FRONTIER\.716|IAL2-FEATURE-COMPLETENESS-FRONTIER\.717|ahb_subordinate_profile_alias_deferred|AHB subordinate \.ahb profile-alias' docs/IAL2_POST_AHB_SUBORDINATE_PPIF_NEXT_SLICE_SELECTION.md docs/IAL2_AHB_SUBORDINATE_PPIF_BEHAVIOR.md docs/book/src/16c-ial2-ahb.md docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md docs/TASK_TREE.md MEMORY.md README.md ROADMAP_V2.md
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.716` selects
`IAL2-FEATURE-COMPLETENESS-FRONTIER.717`, public AHB subordinate `.ahb`
profile-alias contract selection after the public subordinate `.ppif` path
shipped.

The next owner is a no-behavior contract selector, not immediate
implementation. `.717` must select the future subordinate `.ahb` alias path,
explicit `(profile ahb)` policy, exactly-one `(ahb-subordinate
ahb_lite_subordinate ...)` object boundary, generated `ahb_lite_subordinate.isf`
before `ahb_lite_subordinate.fsm`, report/source-path semantics,
support-accounting identity, diagnostics, residue movement, validation, docs,
rollback, and VHDL deferral before behavior changes.

Current behavior remains unchanged: `ppif/ahb_lite_subordinate.ppif` is the
public subordinate IAL2 source with support identity
`intent.ppif_ahb_lite_subordinate`, while `.ahb` is still requester-only at
`ppif/ahb_requester.ahb`.

AHB interconnect/decode, optional signals, burst `SEQ`, byte-lane/narrow
transfers, legacy two-bit `HRESP`, direct backend behavior, verification-output
generation, backend-language variants, AXI, APB, and VHDL remain future
owners.
