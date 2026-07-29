---
id: ial0-ahb-direct-subordinate-output-arbitration-behavior
title: Direct AHB seed output arbitration is assertion-clean
answers:
  - "is the direct AHB subordinate seed assertion-clean?"
  - "does t1520 still use no-assert?"
  - "which direct AHB seed output writes were removed?"
  - "how does access get zero HREADYOUT HRESP and HRDATA values now?"
  - "are unsupported HREADYOUT and HRDATA zero drives still explicit?"
date: 2026-07-29
status: current
tags: [ial0, ahb, subordinate, selector, assertion, arbitration, behavior]
evidence: docs/IAL0_AHB_DIRECT_SUBORDINATE_OUTPUT_ARBITRATION_BEHAVIOR.md; fsm/ahb_lite_subordinate.fsm; t/1520-ahb-direct-subordinate-pipelined-active-transfer-audit.t; t/data/ahb_direct_subordinate_pipelined_active_transfer_audit_tb.svt
reverify: prove -Iperl t/1520-ahb-direct-subordinate-pipelined-active-transfer-audit.t
---

The direct `fsm/ahb_lite_subordinate.fsm` seed removes exactly four redundant
zero writes: access HREADYOUT/HRESP/HRDATA and unsupported HRESP. The emitted
output mux's zero baselines preserve values where conditional nonzero owners
remain; unsupported HREADYOUT-zero and HRDATA-zero stay explicit.

t1520 compiles without `--no-assert`, retains all generated selector
assertions, and passes the unchanged success, active-ERROR, SEQ-to-ERROR, and
ERROR-to-IDLE scenarios. Its SystemVerilog harness remains handwritten test
infrastructure, not generated VIAL output.
