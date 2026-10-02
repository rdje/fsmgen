---
id: protocol-platform-intent-surface-layered-lowering
title: Protocol/platform intent lowers through reviewable IAL1
answers:
  - "what file extension should future IAL2 use?"
  - "should IAL2 use .axi?"
  - "what does .pif mean?"
  - "what does .ppi mean?"
  - "what does .ppif mean?"
  - "can IAL2 lower directly to IAL0?"
  - "what is the required IAL2 lowering chain?"
  - "should multi-actor IAL2 lowering generate ATL?"
  - "does fixed APB composition emit an ATL network ISF?"
date: 2026-10-02
status: current
tags: [ial2, protocol-intent, platform-intent, lowering, atl]
evidence: docs/decisions/0014-protocol-platform-intent-surface-and-layered-lowering.md; docs/decisions/0016-ppif-is-first-public-ial2-container.md; docs/audits/ial2-atl-contract-20261002/scope.txt
reverify: scripts/decision_records.py read 0014 0016 0115
---

`.ppif` (Protocol/Platform Intent Format) is the generic IAL2 suffix selected
by 0016. Earlier candidates `.pif` (Protocol Intent Format) and `.ppi`
(Protocol/Platform Intent) remain historical. Profile aliases such as `.axi`
share this layer (0015); they cannot bypass `IAL2 -> IAL1/.isf -> IAL0/.fsm -> HDL`.

Multi-actor IAL2 must emit ATL network intent inside IAL1 (0115). Current fixed
APB emits child ISF only; its structural top is built in IAL0. Integration owns
that gap. Continuous protocol wiring differs from temporal ATL drive routes.
