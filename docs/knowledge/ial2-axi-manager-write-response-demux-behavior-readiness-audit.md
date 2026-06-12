---
id: ial2-axi-manager-write-response-demux-behavior-readiness-audit
title: AXI write response-demux readiness selected the IAL1 rule-pulse prerequisite
answers:
  - "what did IAL2-FEATURE-COMPLETENESS-FRONTIER.28 conclude?"
  - "why did response demux need an IAL1 rule-pulse prerequisite?"
  - "what is IAL2-FEATURE-COMPLETENESS-FRONTIER.29?"
  - "what is IAL2-FEATURE-COMPLETENESS-FRONTIER.30?"
date: 2026-06-12
status: current
tags: [ial2, axi, manager, response-demux, ial1, task-tree]
evidence: docs/AXI_IAL2_MANAGER_WRITE_RESPONSE_DEMUX_BEHAVIOR_READINESS_AUDIT.md; docs/AXI_IAL2_MANAGER_WRITE_RESPONSE_DEMUX_BEHAVIOR_FIRST_SLICE.md; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/TASK_TREE.md; docs/book/src/14-feature-backlog.md; docs/AXI_IAL2_MANAGER_WRITE_RESPONSE_DEMUX_METADATA_FIRST_SLICE.md; docs/AXI_IAL2_MANAGER_WRITE_RESPONSE_DEMUX_CONTRACT_SELECTION.md; README.md; ROADMAP_V2.md; perl/FSM/Scheduler/ISF/LoweringIR.pm; perl/FSM/Scheduler/ISF/Emitter/FSM.pm; perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm
reverify: rg -n 'IAL2-FEATURE-COMPLETENESS-FRONTIER\\.28|IAL2-FEATURE-COMPLETENESS-FRONTIER\\.29|IAL2-FEATURE-COMPLETENESS-FRONTIER\\.30|rule-pulse|one-cycle pulse|generated_behavior: true|generated write BID response-demux behavior' docs/AXI_IAL2_MANAGER_WRITE_RESPONSE_DEMUX_BEHAVIOR_READINESS_AUDIT.md docs/AXI_IAL2_MANAGER_WRITE_RESPONSE_DEMUX_BEHAVIOR_FIRST_SLICE.md docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md docs/TASK_TREE.md docs/book/src/14-feature-backlog.md README.md ROADMAP_V2.md
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.28` concluded that generated AXI write
`BID` response-demux behavior needed a small IAL1 prerequisite first.

The shipped parser/report contract already recorded the response event,
response ID signal, auto-ID write transactions, selected-ID state, and
generated-completion ownership. The missing piece was the public IAL1 action
form for a rule to emit a one-cycle completion pulse.

Existing IAL1 rule actions:

```text
(set port expr)
(port expr)
```

lower as sticky flopped assignments. That is correct for data/state writes
but not for response-demux transaction completion names. Completion names must
remain pulse-shaped, matching the existing transaction completion lowering:

```text
(<1 (TARGET> 1))
```

`IAL2-FEATURE-COMPLETENESS-FRONTIER.29` shipped the prerequisite:

```text
(rule NAME GUARD
  (pulse TARGET))
```

The shipped pulse action is bounded to scalar actor outputs or scalar actor
storage variables, lowers through the existing delayed-pulse family,
participates in pulse-domain conflict analysis, and is documented in the ISF
spec and mdBook.

`IAL2-FEATURE-COMPLETENESS-FRONTIER.30` then shipped generated response-demux
behavior: `axi0_bid` is a generated IAL1 input, transaction completion names
are generated pulse outputs, each auto-ID write transaction gets a guarded
demux pulse rule, active/unique match assertions are emitted, and
`response_demux.generated_behavior` reports true.
