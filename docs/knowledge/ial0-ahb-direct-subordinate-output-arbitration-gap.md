---
id: ial0-ahb-direct-subordinate-output-arbitration-gap
title: Direct AHB subordinate seed has intentional conditional output overrides
answers:
  - "why does t1520 use no-assert for the direct AHB subordinate?"
  - "which selector assertions fail in fsm/ahb_lite_subordinate.fsm?"
  - "does the hand-authored AHB subordinate share the generated phase-rule defect?"
  - "which task owns direct AHB subordinate output arbitration?"
date: 2026-07-29
status: current
tags: [ial0, ahb, subordinate, direct-seed, selector, assertion, arbitration, gap]
evidence: docs/IAL2_AHB_SUBORDINATE_DEFAULT_PHASE_OUTPUT_ARBITRATION_AUDIT.md; docs/tasks/IAL0-AHB-DIRECT-SUBORDINATE-OUTPUT-ARBITRATION.md; fsm/ahb_lite_subordinate.fsm; t/1520-ahb-direct-subordinate-pipelined-active-transfer-audit.t
reverify: rg -n 'HREADYOUT>|HRESP>|HRDATA>|--no-assert' fsm/ahb_lite_subordinate.fsm t/1520-ahb-direct-subordinate-pipelined-active-transfer-audit.t docs/IAL2_AHB_SUBORDINATE_DEFAULT_PHASE_OUTPUT_ARBITRATION_AUDIT.md
---

The hand-authored `fsm/ahb_lite_subordinate.fsm` has a distinct
output-arbitration gap from generated `AhbSubordinate.pm` endpoints. With all
assertions enabled, the existing t1520 harness first stops on an HREADYOUT
multi-value conflict.

Disposable diagnostic logging with every internal assertion retained proves
three actual conditional overrides: access default HREADYOUT zero plus
successful HREADYOUT one, access default HRDATA zero plus read data, and
access/unsupported default HRESP zero plus ERROR one. The functional success,
active-ERROR continuation, SEQ-to-ERROR, and ERROR-to-IDLE scenarios complete
when only those bus assertions log.

Proposed `IAL0-AHB-DIRECT-SUBORDINATE-OUTPUT-ARBITRATION` owns a later direct
seed contract. It remains inactive and does not pivot the active generated
endpoint repair.
