---
id: ial2-axi-manager-rresp-aggregation-behavior-readiness-audit
title: AXI scalar RRESP aggregation behavior can be generated directly
answers:
  - "what is IAL2-FEATURE-COMPLETENESS-FRONTIER.78?"
  - "what did IAL2-FEATURE-COMPLETENESS-FRONTIER.78 decide?"
  - "does scalar RRESP aggregation need an IAL1 prerequisite?"
  - "how should generated AXI scalar RRESP aggregation work?"
  - "what comes after IAL2-FEATURE-COMPLETENESS-FRONTIER.78?"
  - "what is IAL2-FEATURE-COMPLETENESS-FRONTIER.79?"
date: 2026-06-14
status: current
tags: [ial2, axi, manager, read-data, multi-beat, rresp, aggregation, readiness, task-tree]
evidence: docs/AXI_IAL2_MANAGER_RRESP_AGGREGATION_BEHAVIOR_READINESS_AUDIT.md; docs/AXI_IAL2_MANAGER_RRESP_AGGREGATION_BEHAVIOR_FIRST_SLICE.md; docs/AXI_IAL2_MANAGER_RRESP_AGGREGATION_METADATA_FIRST_SLICE.md; docs/AXI_IAL2_MANAGER_RRESP_AGGREGATION_CONTRACT_SELECTION.md; perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm; perl/FSM/Scheduler/ISF/LoweringIR.pm; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/TASK_TREE.md; docs/book/src/14-feature-backlog.md; README.md; ROADMAP_V2.md
reverify: rg -n 'IAL2-FEATURE-COMPLETENESS-FRONTIER\\.78|IAL2-FEATURE-COMPLETENESS-FRONTIER\\.79|IAL2-FEATURE-COMPLETENESS-FRONTIER\\.80|generated_rresp_aggregation|status_aggregation_generated_behavior|STATUS_AGGREGATE_OUTPUT|agg < rresp|worst_observed' docs/AXI_IAL2_MANAGER_RRESP_AGGREGATION_BEHAVIOR_READINESS_AUDIT.md docs/AXI_IAL2_MANAGER_RRESP_AGGREGATION_BEHAVIOR_FIRST_SLICE.md docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md docs/TASK_TREE.md docs/book/src/14-feature-backlog.md README.md ROADMAP_V2.md
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.78` audited generated scalar AXI
multi-beat `RRESP` aggregation behavior readiness and found no new IAL1,
IAL0, or SystemVerilog prerequisite for the first width-2 `worst_observed`
behavior.

The selected implementation shape initializes each transaction-local scalar
aggregate output to `OKAY` (`2'd0`) on the transaction request event, then
updates that output on each accepted matched read-data beat when the current
aggregate is less than the current `RRESP` signal. Numeric ordering matches
the selected width-2 severity order: `OKAY < EXOKAY < SLVERR < DECERR`.

The update must keep the same same-cycle boundary as generated output-bank
capture: the guard includes `!request_event`, so request-time initialization
and matched-beat update do not race in the same cycle.

The immediate follow-up leaf was `IAL2-FEATURE-COMPLETENESS-FRONTIER.79`,
generated AXI multi-beat scalar `RRESP` aggregation behavior first slice.
That implementation is now complete; the active leaf is
`IAL2-FEATURE-COMPLETENESS-FRONTIER.80`, the next AXI manager
feature-completeness selector.
