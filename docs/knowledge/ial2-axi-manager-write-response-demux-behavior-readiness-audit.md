---
id: ial2-axi-manager-write-response-demux-behavior-readiness-audit
title: AXI write response-demux behavior needs an IAL1 rule-pulse prerequisite
answers:
  - "what did IAL2-FEATURE-COMPLETENESS-FRONTIER.28 conclude?"
  - "can generated AXI write BID demux be implemented directly now?"
  - "why does response demux need an IAL1 rule-pulse prerequisite?"
  - "what is IAL2-FEATURE-COMPLETENESS-FRONTIER.29?"
  - "what is IAL2-FEATURE-COMPLETENESS-FRONTIER.30?"
date: 2026-06-12
status: current
tags: [ial2, axi, manager, response-demux, ial1, task-tree]
evidence: docs/AXI_IAL2_MANAGER_WRITE_RESPONSE_DEMUX_BEHAVIOR_READINESS_AUDIT.md; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/TASK_TREE.md; docs/book/src/14-feature-backlog.md; docs/AXI_IAL2_MANAGER_WRITE_RESPONSE_DEMUX_METADATA_FIRST_SLICE.md; docs/AXI_IAL2_MANAGER_WRITE_RESPONSE_DEMUX_CONTRACT_SELECTION.md; README.md; ROADMAP_V2.md; perl/FSM/Scheduler/ISF/LoweringIR.pm; perl/FSM/Scheduler/ISF/Emitter/FSM.pm; perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm
reverify: rg -n 'IAL2-FEATURE-COMPLETENESS-FRONTIER\\.30|IAL2-FEATURE-COMPLETENESS-FRONTIER\\.29|rule-pulse|pulse TARGET|sticky flopped|one-cycle pulse|response-demux completion' docs/AXI_IAL2_MANAGER_WRITE_RESPONSE_DEMUX_BEHAVIOR_READINESS_AUDIT.md docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md docs/TASK_TREE.md docs/book/src/14-feature-backlog.md README.md ROADMAP_V2.md
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.28` concluded that generated AXI write
`BID` response-demux behavior should not be implemented directly on top of
the current IAL1 rule action surface.

The shipped parser/report contract already records the response event,
response ID signal, auto-ID write transactions, selected-ID state, and
generated-completion ownership. The missing piece is the public IAL1 action
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

`IAL2-FEATURE-COMPLETENESS-FRONTIER.29` was therefore selected and is now
shipped. It owns a minimal IAL1 rule-owned pulse action:

```text
(rule NAME GUARD
  (pulse TARGET))
```

The shipped first slice keeps the action bounded to scalar actor outputs or
scalar actor storage variables, lowers through the existing delayed-pulse
family, participates in pulse-domain conflict analysis, and updates the
mdBook/spec/tests in the same slice.

After `.29`, `IAL2-FEATURE-COMPLETENESS-FRONTIER.30` owns generated
response-demux behavior: add `axi0_bid` as a generated IAL1 input, emit one
guarded demux pulse rule per auto-ID write transaction, add unmatched/inactive
response assertions, set `response_demux.generated_behavior` to true, and
remove `generated_write_bid_demux` from the report residue.
