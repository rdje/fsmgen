---
id: ial2-protocol-generality-guardrail-readiness-audit
title: Public IAL2 surfaces need an explicit AXI-as-first-profile guardrail
answers:
  - "what did IAL2-FEATURE-COMPLETENESS-FRONTIER.526 select?"
  - "what is IAL2-FEATURE-COMPLETENESS-FRONTIER.527?"
  - "where is AXI-overfitting risk in the IAL2 public surface?"
  - "what public cleanup follows the IAL2 generality audit?"
date: 2026-06-26
status: current
tags: [ial2, architecture, protocol-platform, profile, axi, public-surface, task-tree]
evidence: docs/IAL2_PROTOCOL_GENERALITY_GUARDRAIL_READINESS_AUDIT.md; docs/IAL2_PROTOCOL_GENERALITY_GUARDRAIL_READINESS_SELECTION.md; docs/decisions/0014-protocol-platform-intent-surface-and-layered-lowering.md; docs/decisions/0015-ial2-profile-extensions-are-vocabulary-aliases.md; docs/decisions/0016-ppif-is-first-public-ial2-container.md; docs/knowledge/ial2-common-vs-profile-factoring.md; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/TASK_TREE.md; README.md; ROADMAP_V2.md; docs/book/src/14-feature-backlog.md
reverify: rg -n 'IAL2-FEATURE-COMPLETENESS-FRONTIER\\.526|IAL2-FEATURE-COMPLETENESS-FRONTIER\\.527|IAL2_PROTOCOL_GENERALITY_GUARDRAIL_READINESS_AUDIT|AXI is the first shipped IAL2 profile/example|public-surface cleanup' docs/IAL2_PROTOCOL_GENERALITY_GUARDRAIL_READINESS_AUDIT.md docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md docs/TASK_TREE.md README.md ROADMAP_V2.md docs/book/src/14-feature-backlog.md docs/knowledge/ial2-protocol-generality-guardrail-readiness-audit.md
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.526` selected
`IAL2-FEATURE-COMPLETENESS-FRONTIER.527`, public-surface cleanup for the IAL2
protocol/platform generality guardrail.

The audit found the architecture records correct, but the public interface
contract, downstream integration spec, and capability-manifest boundary still
need an explicit leading guardrail: AXI is the first shipped IAL2
profile/example, not the definition of IAL2.

`.527` should update those public surfaces without changing parser, generator,
PPIF sample, support accounting, generated artifacts, HDL/runtime behavior,
non-AXI behavior, common construct promotion, or profile-alias syntax.
