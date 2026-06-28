---
id: ial2-apb-generalized-multi-peripheral-multi-register-broader-cardinality-readiness-audit
title: APB broader generalized cardinality readiness selects six-register contract
answers:
  - "what is IAL2-FEATURE-COMPLETENESS-FRONTIER.683?"
  - "which APB broader cardinality owner was selected after five-register siblings shipped?"
  - "is APB generalized cardinality ready beyond five registers?"
  - "why is APB six-register no-policy contract selection next?"
date: 2026-06-28
status: current
tags: [ial2, apb, source-shape, timing, multi-peripheral, multi-register, cardinality, audit, task-tree]
evidence: docs/IAL2_APB_GENERALIZED_MULTI_PERIPHERAL_MULTI_REGISTER_BROADER_CARDINALITY_READINESS_AUDIT.md; docs/IAL2_POST_APB_DATA16_PROTECTION_GENERALIZED_MULTI_PERIPHERAL_MULTI_REGISTER_CARDINALITY_NEXT_SLICE_SELECTION.md; docs/IAL2_APB_DATA16_PROTECTION_GENERALIZED_MULTI_PERIPHERAL_MULTI_REGISTER_CARDINALITY_BEHAVIOR.md; docs/IAL2_APB_PROTECTION_GENERALIZED_MULTI_PERIPHERAL_MULTI_REGISTER_CARDINALITY_BEHAVIOR.md; docs/IAL2_APB_DATA16_GENERALIZED_MULTI_PERIPHERAL_MULTI_REGISTER_CARDINALITY_BEHAVIOR.md; docs/IAL2_APB_GENERALIZED_MULTI_PERIPHERAL_MULTI_REGISTER_CARDINALITY_BEHAVIOR.md; perl/FSM/IAL2/ProtocolIntent/ApbCompleter.pm; perl/FSM/IAL2/ProtocolIntent/ApbComposition.pm; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; README.md; ROADMAP_V2.md; docs/book/src/14-feature-backlog.md; MEMORY.md
reverify: rg -n 'IAL2-FEATURE-COMPLETENESS-FRONTIER\.683|IAL2-FEATURE-COMPLETENESS-FRONTIER\.684|six-register|reg0/reg1/reg2/reg3/reg4/reg5|0/4/8/12/16/20|maximum_count = 6|only two peripheral completers|No parser, generator, public source' docs/IAL2_APB_GENERALIZED_MULTI_PERIPHERAL_MULTI_REGISTER_BROADER_CARDINALITY_READINESS_AUDIT.md docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md README.md ROADMAP_V2.md docs/book/src/14-feature-backlog.md MEMORY.md perl/FSM/IAL2/ProtocolIntent/ApbCompleter.pm perl/FSM/IAL2/ProtocolIntent/ApbComposition.pm
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.683` audits broader APB generalized
register-set cardinality after all selected five-register siblings shipped.

The audit selects `IAL2-FEATURE-COMPLETENESS-FRONTIER.684`, public contract
selection for the bounded APB sideband-aware 32-bit no-policy six-register
generalized `reg0..regN` register-set multi-peripheral timing family.

The six-register owner is next because it is the smallest public step beyond
the current `maximum_count = 5` boundary, keeps exactly two peripheral
completers, avoids data16 stride/strobe changes, and avoids protection-policy
matrix changes. A temporary six-register probe fails closed at the storage
shape boundary; a temporary three-peripheral probe fails closed with the
explicit two-peripheral diagnostic.

Data16 six-register, protected six-register, more than six registers,
more-than-two peripheral completers, deeper queues, alternate overflow,
accepted-less timing, multiple active transfers, alternate access policies,
interconnect-owned protection policy, bus matrices, scoreboards, direct
backend behavior, verification-output generation, backend-language variants,
AXI, AHB, and VHDL remain deferred.
