---
id: ial2-post-subordinate-arbitration-next-owner-selection
title: Direct IAL0 AHB subordinate arbitration follows the generated endpoint repair
answers:
  - "what comes after assertion-clean generated AHB subordinate arbitration?"
  - "what did IAL2-FEATURE-COMPLETENESS-FRONTIER.815 select?"
  - "why is direct IAL0 AHB subordinate arbitration next?"
  - "which AHB test still uses no-assert after generated endpoint arbitration ships?"
  - "why is exact-three paired AHB composition not next after the subordinate repair?"
date: 2026-07-29
status: current
tags: [ial0, ial2, ahb, subordinate, selector, assertion, arbitration, roadmap]
evidence: docs/IAL2_POST_SUBORDINATE_ARBITRATION_NEXT_OWNER_SELECTION.md; docs/IAL2_AHB_SUBORDINATE_DEFAULT_PHASE_OUTPUT_ARBITRATION_BEHAVIOR.md; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/tasks/IAL0-AHB-DIRECT-SUBORDINATE-OUTPUT-ARBITRATION.md; docs/knowledge/ial0-ahb-direct-subordinate-output-arbitration-gap.md; fsm/ahb_lite_subordinate.fsm; t/1520-ahb-direct-subordinate-pipelined-active-transfer-audit.t; t/1211-isf-runtime-selector-conflict-instrumentation.t; t/1219-isf-rule-transaction-priority.t
reverify: rg -n -- '--no-assert|HREADYOUT>|HRESP>|HRDATA>|IAL0-AHB-DIRECT-SUBORDINATE-OUTPUT-ARBITRATION|IAL2-FEATURE-COMPLETENESS-FRONTIER.815' t/1513-ial2-ahb-paired-busy-composition.t t/1514-ial2-ahb-paired-busy-composition-profile-alias.t t/1515-ial2-ahb-two-subordinate-paired-busy-composition.t t/1516-ial2-ahb-two-subordinate-paired-busy-composition-profile-alias.t t/1519-ial2-ahb-pipelined-active-transfer-audit.t t/1520-ahb-direct-subordinate-pipelined-active-transfer-audit.t t/1523-ial2-ahb-exact-two-paired-busy-composition.t t/1525-ial2-ahb-two-subordinate-exact-two-paired-busy-composition.t fsm/ahb_lite_subordinate.fsm docs/IAL2_POST_SUBORDINATE_ARBITRATION_NEXT_OWNER_SELECTION.md docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.815` selects proposed
`IAL0-AHB-DIRECT-SUBORDINATE-OUTPUT-ARBITRATION.1` after the generated endpoint
repair completed at `1eec6253d` and the HIAL/VIAL architecture was parked at
`64f056b12` without changing IAL2 priority.

Generated direct and paired AHB tests now run with selector assertions enabled.
Only t1520 retains `--no-assert` in the audited family because the hand-written
IAL0 seed authors access defaults plus conditional success/read/ERROR
overrides for HREADYOUT, HRDATA, and HRESP. Generic assertions correctly expose
those non-exclusive modes; focused generic and t1520 preservation tests pass.

Direct-seed correctness is smaller than exact-three paired expansion, larger
counts, runtime/policy/multiple-point BUSY, status, bursts, optional signals,
or generic priority changes. HIAL/VIAL and decision 0020 remain
proposed/inactive.
