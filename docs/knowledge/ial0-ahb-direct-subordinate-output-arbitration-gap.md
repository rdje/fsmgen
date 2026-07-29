---
id: ial0-ahb-direct-subordinate-output-arbitration-gap
title: Direct AHB subordinate selector gap preceded the four-write repair
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

Completed `IAL0-AHB-DIRECT-SUBORDINATE-OUTPUT-ARBITRATION.1` selected exactly
four redundant zero-write removals. Implementation `.2` now ships that repair:
t1520 no longer uses `--no-assert`, all selector assertions remain enabled,
and exact runtime results are unchanged. The dedicated behavior fact is
current truth; this card preserves why the former boundary existed.
