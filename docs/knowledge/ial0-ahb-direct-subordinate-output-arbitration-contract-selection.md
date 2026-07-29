---
id: ial0-ahb-direct-subordinate-output-arbitration-contract-selection
title: Direct AHB seed arbitration removes four redundant zero writes
answers:
  - "what direct AHB subordinate output-arbitration contract was selected?"
  - "which writes should be removed from fsm/ahb_lite_subordinate.fsm?"
  - "why does the direct AHB seed rely on implicit zero outputs?"
  - "does unsupported keep explicit HREADYOUT and HRDATA zero drives?"
  - "what owns removal of no-assert from t1520?"
date: 2026-07-29
status: current
tags: [ial0, ahb, subordinate, selector, assertion, arbitration, contract]
evidence: docs/IAL0_AHB_DIRECT_SUBORDINATE_OUTPUT_ARBITRATION_CONTRACT_SELECTION.md; docs/tasks/IAL0-AHB-DIRECT-SUBORDINATE-OUTPUT-ARBITRATION.md; docs/IAL2_AHB_SUBORDINATE_DEFAULT_PHASE_OUTPUT_ARBITRATION_AUDIT.md; fsm/ahb_lite_subordinate.fsm; t/1520-ahb-direct-subordinate-pipelined-active-transfer-audit.t; t/data/ahb_direct_subordinate_pipelined_active_transfer_audit_tb.svt
reverify: rg -n -- 'Selected Four Writes|access.*HREADYOUT|access.*HRESP|access.*HRDATA|unsupported.*HRESP|unsupported.*HREADYOUT|unsupported.*HRDATA|--no-assert|IAL0-AHB-DIRECT-SUBORDINATE-OUTPUT-ARBITRATION.2' docs/IAL0_AHB_DIRECT_SUBORDINATE_OUTPUT_ARBITRATION_CONTRACT_SELECTION.md docs/tasks/IAL0-AHB-DIRECT-SUBORDINATE-OUTPUT-ARBITRATION.md fsm/ahb_lite_subordinate.fsm t/1520-ahb-direct-subordinate-pipelined-active-transfer-audit.t
---

`IAL0-AHB-DIRECT-SUBORDINATE-OUTPUT-ARBITRATION.1` selects removal of exactly
four redundant zero writes: HREADYOUT, HRESP, and HRDATA from `access`, plus
HRESP from `unsupported`. The existing IAL0 HDL emitter's zero combinational
baseline preserves values for access wait/error/write paths and unsupported
wait cycles.

Unsupported HREADYOUT-zero and HRDATA-zero remain explicit because they are
already exclusive. A repository-local candidate passed the complete t1520
harness with all selector assertions enabled and unchanged exact
success/ERROR/SEQ/IDLE results. Clean contract commit `454767c15` activated
implementation `.2`; that leaf now ships the selected repair and assertion-
enabled t1520 behavior. The separate behavior fact is current runtime truth.
