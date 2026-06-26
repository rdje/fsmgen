---
id: ial2-protocol-generality-guardrail-public-surface-sync
title: Public PPIF surfaces now state AXI is the first IAL2 profile, not IAL2 itself
answers:
  - "what did IAL2-FEATURE-COMPLETENESS-FRONTIER.527 change?"
  - "does the public PPIF boundary say AXI is only the first IAL2 profile?"
  - "what is IAL2-FEATURE-COMPLETENESS-FRONTIER.528?"
  - "where is the IAL2 protocol generality guardrail enforced in public surfaces?"
date: 2026-06-26
status: current
tags: [ial2, ppif, protocol-platform, profile, axi, public-surface, capability-manifest]
evidence: docs/IAL2_PROTOCOL_GENERALITY_GUARDRAIL_PUBLIC_SURFACE_SYNC.md; docs/ISF_PUBLIC_INTERFACE_CONTRACT.md; docs/ISF_DOWNSTREAM_INTEGRATION_SPEC.md; perl/FSM/Support/LanguageSurfaceSection.pm; t/297-capability-manifest.t; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/TASK_TREE.md; README.md; ROADMAP_V2.md; docs/book/src/14-feature-backlog.md
reverify: rg -n 'IAL2-FEATURE-COMPLETENESS-FRONTIER\\.527|IAL2-FEATURE-COMPLETENESS-FRONTIER\\.528|AXI is the first shipped IAL2 profile/example, not the definition of IAL2|future protocol-specific suffixes|common IAL2 constructs stay small' docs/IAL2_PROTOCOL_GENERALITY_GUARDRAIL_PUBLIC_SURFACE_SYNC.md docs/ISF_PUBLIC_INTERFACE_CONTRACT.md docs/ISF_DOWNSTREAM_INTEGRATION_SPEC.md perl/FSM/Support/LanguageSurfaceSection.pm t/297-capability-manifest.t docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md docs/TASK_TREE.md README.md ROADMAP_V2.md docs/book/src/14-feature-backlog.md
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.527` synchronized the public `.ppif`
surface with the IAL2 protocol/platform generality guardrail.

The public contract, downstream integration handoff, and capability-manifest
language-surface boundary now say AXI is the first shipped IAL2
profile/example, not the definition of IAL2. They also state that future
protocol-specific suffixes are profile aliases over IAL2 and that common IAL2
constructs stay small until compatible reuse is proven across profiles.

`.527` selected `IAL2-FEATURE-COMPLETENESS-FRONTIER.528`, post-guardrail IAL2
next-slice selection without treating AXI as the whole roadmap.
