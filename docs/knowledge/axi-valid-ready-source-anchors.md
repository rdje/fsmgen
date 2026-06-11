---
id: axi-valid-ready-source-anchors
title: AXI Valid-Ready source-anchor evidence inventory
answers:
  - "where is the AXI valid/ready source-anchor evidence?"
  - "what AXI spec anchors define valid/ready transport?"
  - "is AXI valid/ready implemented as IAL2?"
  - "what is the smallest AXI-derived IAL2 evidence object?"
  - "what AXI valid/ready residue is out of scope?"
date: 2026-06-12
status: current
tags: [axi, ial2, valid-ready, protocol-intent, source-anchors]
evidence: docs/AXI_VALID_READY_INTENT_PROBE.md; docs/vendor/arm/amba/axi/IHI0022_L_2025-08_AMBA_AXI_Protocol_Specification.pdf; docs/tasks/AXI-VALID-READY-INTENT-PROBE.md
reverify: rg -n "A2\\.3|A2\\.3\\.1|A2\\.3\\.2\\.1|A2\\.3\\.2\\.2" docs/AXI_VALID_READY_INTENT_PROBE.md
---

`docs/AXI_VALID_READY_INTENT_PROBE.md` is the canonical repo-local evidence
inventory for the first AXI Valid-Ready IAL2 probe. It anchors the minimal
candidate to AXI spec sections `A2.3`, `A2.3.1`, `A2.3.2.1`, `A2.3.2.2`, and
related residue sections.

The fact established by the card is intentionally narrow: AXI Valid-Ready is
evidence for a future IAL2 protocol-intent object, not a shipped IAL2
implementation. Parser, lowering, generated `.fsm`, HDL, wake-up, snoop,
credited transport, and full transaction-ordering behavior all remain outside
the completed evidence slice.
