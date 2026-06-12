---
id: protocol-platform-intent-surface-layered-lowering
title: Protocol/platform intent surface and layered lowering for future IAL2
answers:
  - "what file extension should future IAL2 use?"
  - "should IAL2 use .axi?"
  - "what does .pif mean?"
  - "what does .ppi mean?"
  - "what does .ppif mean?"
  - "can IAL2 lower directly to IAL0?"
  - "what is the required IAL2 lowering chain?"
date: 2026-06-12
status: current
tags: [ial2, protocol-intent, platform-intent, layering, lowering]
evidence: docs/decisions/0014-protocol-platform-intent-surface-and-layered-lowering.md; docs/IAL2_PROTOCOL_PLATFORM_INTENT_EVALUATION.md; docs/tasks/IAL2-PROTOCOL-PLATFORM-SURFACE-DECISION-CAPTURE.md
reverify: rg -n "Protocol/Platform Intent|Direct IAL2-to-IAL0 lowering is forbidden|.pif|.ppi|.ppif|0015" docs/decisions/0014-protocol-platform-intent-surface-and-layered-lowering.md
---

Future IAL2 must use a protocol/platform-generic file surface. Generic
containers are tracked by decision `0014`; protocol-specific profile aliases
are refined by decision `0015`.

The exact extension name remains open among `.pif` (Protocol Intent Format),
`.ppi` (Protocol/Platform Intent), `.ppif` (Protocol/Platform Intent Format),
or a future explicitly accepted generic variant.

The required lowering chain is `IAL2 -> IAL1/.isf -> IAL0/.fsm -> HDL`.
Direct IAL2-to-IAL0 or direct IAL2-to-`.fsm` lowering is forbidden.
