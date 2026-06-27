---
id: ial2-apb-multi-peripheral-back-to-back-readiness-audit
title: APB multi-peripheral back-to-back propagation is ready for a narrow owner
answers:
  - "what is IAL2-FEATURE-COMPLETENESS-FRONTIER.608?"
  - "is APB multi-peripheral back-to-back propagation ready to implement?"
  - "what comes after APB fixed-composition back-to-back behavior?"
  - "does APB multi-peripheral back-to-back need another contract selection?"
date: 2026-06-28
status: current
tags: [ial2, apb, back-to-back, multi-peripheral, readiness, task-tree]
evidence: docs/IAL2_APB_MULTI_PERIPHERAL_BACK_TO_BACK_READINESS_AUDIT.md; docs/IAL2_APB_BACK_TO_BACK_BEHAVIOR.md; docs/IAL2_APB_BACK_TO_BACK_CONTRACT_SELECTION.md; docs/IAL2_APB_MULTI_PERIPHERAL_INTERCONNECT_BEHAVIOR.md; perl/FSM/IAL2/ProtocolIntent/ApbComposition.pm; perl/FSM/IAL2/ProtocolIntent/ApbRequesterTransfer.pm; perl/FSM/IAL2/ProtocolIntent/ApbCompleter.pm; ppif/apb_composition_multi_peripheral.ppif; ppif/apb_composition_multi_peripheral_sideband_data16_protection.ppif
reverify: rg -n 'IAL2-FEATURE-COMPLETENESS-FRONTIER\.608|IAL2-FEATURE-COMPLETENESS-FRONTIER\.609|multi-peripheral back-to-back|apb_back_to_back_policy_deferred|selected_peripheral_response|PSEL && PENABLE' docs/IAL2_APB_MULTI_PERIPHERAL_BACK_TO_BACK_READINESS_AUDIT.md docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md README.md ROADMAP_V2.md docs/book/src/14-feature-backlog.md MEMORY.md perl/FSM/IAL2/ProtocolIntent/ApbComposition.pm
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.608` audits APB multi-peripheral
back-to-back propagation after `.607` shipped the fixed-composition timing
policy.

The audit selects `.609`, a narrow direct implementation owner. No additional
public timing-policy vocabulary is needed: `.606` already selected requester
`(timing-policy (back-to-back queued) (queue-depth 1) (overflow reject))`,
requester `accepted`, and completer `(timing-policy (setup-admission
adjacent))`.

Current multi-peripheral reports still carry `apb_back_to_back_policy_deferred`
at the top composition, generated interconnect, requester child, and
peripheral child surfaces. The generated interconnect is propagation-only: it
decodes current `PSEL/PADDR`, forwards `PENABLE`, muxes selected responses, and
returns an unmapped error only for active unmapped accesses (`PSEL && PENABLE`).
That is structurally compatible with a queued requester setup cycle driven as
`PSEL=1` and `PENABLE=0`.

The next owner should implement only the 32-bit no-sideband two-peripheral
family, likely `ppif/apb_composition_multi_peripheral_status_back_to_back`
`.ppif/.apb`, and keep sideband/data16/protection variants, deeper queues,
alternate overflow, direct backend, verification-output, backend-language,
AXI, AHB, and VHDL work deferred.
