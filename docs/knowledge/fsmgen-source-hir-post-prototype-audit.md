---
id: fsmgen-source-hir-post-prototype-audit
title: SourceHIR remains private until a concrete-control-to-IAL1 route is proved
answers:
  - "should SourceHIR be public after the valid-ready prototype?"
  - "was the private SourceHIR prototype retired?"
  - "what follows the SourceHIR valid-ready prototype?"
  - "why does SourceHIR remain private?"
  - "what must SourceHIR prove before public promotion?"
date: 2026-07-30
status: current
tags: [source-hir, architecture, promotion, private, ial1, audit]
evidence: docs/FSMGEN_SOURCE_HIR_POST_PROTOTYPE_AUDIT.md; docs/FSMGEN_SOURCE_HIR_CONCRETE_CONTROL_V2_CONTRACT.md; docs/decisions/0029-source-hir-remains-private-through-a-second-lowering-route.md; docs/decisions/0030-source-hir-v2-is-a-semantic-concrete-control-subset.md; docs/tasks/FSMGEN-HIR-ROADMAP-FRONTIER.md; perl/FSM/IR/SourceHIR.pm; perl/FSM/IR/SourceHIRBuilder.pm; perl/FSM/IR/SourceHIRPPIFRenderer.pm; t/1547-source-hir-valid-ready.t; isf/phase_test.isf; docs/tasks/IAL2-HOST-LANGUAGE-BUILDER-FRONTIER.md
reverify: prove -Iperl t/1547-source-hir-valid-ready.t && ./bin/fsmgen --strict --check --json isf/phase_test.isf && ./bin/fsmgen --emit-schedule-json isf/phase_test.isf
---

The post-prototype audit rejects both immediate public promotion and
retirement. SourceHIR stays private while a design-only leaf selects one
bounded concrete-FSM/control-to-canonical-IAL1 route, followed by a separate
private implementation/equivalence leaf and another promotion audit.

The valid-ready prototype is retained because it proves immutable checked
construction, deterministic provenance diagnostics, byte-identical PPIF, and
unchanged existing-parser downstream results. Promotion is premature because
there is only one test producer, one semantic shape, and one IAL2 renderer;
the selected architecture's concrete-control-to-IAL1 half is unproved.

Public host-language choice, packaging, versioning, compatibility, and
diagnostic promises remain owned by proposed
`IAL2-HOST-LANGUAGE-BUILDER-FRONTIER`. A second private route is necessary
evidence for reconsideration, not authorization to publish an API.

Leaf `.6` selects the exact second route as semantic SourceHIR version 2 with
byte-identical `isf/phase_test.isf` rendering and existing ISF adapter/scheduler
re-entry. Implementation remains proposed under `.7`.
