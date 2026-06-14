---
id: ial2-axi-manager-rresp-aggregation-contract-selection
title: AXI scalar RRESP aggregation contract uses worst-observed policy
answers:
  - "what is IAL2-FEATURE-COMPLETENESS-FRONTIER.76?"
  - "what did IAL2-FEATURE-COMPLETENESS-FRONTIER.76 select?"
  - "what comes after IAL2-FEATURE-COMPLETENESS-FRONTIER.76?"
  - "what RRESP aggregation policy was selected?"
  - "how should AXI multi-beat RRESP be aggregated?"
  - "should scalar RRESP aggregation replace per-beat status lanes?"
date: 2026-06-14
status: current
tags: [ial2, axi, manager, read-data, multi-beat, rresp, aggregation, selector, task-tree]
evidence: docs/AXI_IAL2_MANAGER_RRESP_AGGREGATION_CONTRACT_SELECTION.md; docs/vendor/arm/amba/axi/IHI0022_L_2025-08_AMBA_AXI_Protocol_Specification.pdf; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/TASK_TREE.md; docs/book/src/14-feature-backlog.md; README.md; ROADMAP_V2.md
reverify: rg -n 'IAL2-FEATURE-COMPLETENESS-FRONTIER\\.76|status-aggregation|worst-observed|status_aggregation: worst_observed|status-aggregate-output' docs/AXI_IAL2_MANAGER_RRESP_AGGREGATION_CONTRACT_SELECTION.md docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md docs/book/src/14-feature-backlog.md README.md ROADMAP_V2.md
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.76` selected an additive scalar
`RRESP` aggregation source/report contract for the public AXI multi-beat
read-data output-bank shape.

The selected public syntax adds a read-level
`(status-aggregation (policy worst-observed))` clause and one
transaction-local `(status-aggregate-output NAME)` binding per read
transaction. Per-beat `status-output-prefix` lanes stay mandatory because the
scalar aggregate is intentionally lossy.

The selected policy is `worst-observed`, reported as `worst_observed`. For
the first width-2 contract, the ordering is
`OKAY < EXOKAY < SLVERR < DECERR`; generated behavior later should initialize
the aggregate to `OKAY` on request and update it on every accepted matched
read-data beat.

The immediate implementation owner after `.76` was
`IAL2-FEATURE-COMPLETENESS-FRONTIER.77`, parser/report metadata and static
validation for this selected contract. Generated scalar aggregation behavior,
width-3 AXI responses, direct backend lowering, and VHDL remain deferred.
