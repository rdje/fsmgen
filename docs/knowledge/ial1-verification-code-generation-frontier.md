---
id: ial1-verification-code-generation-frontier
title: IAL1 owns the verification-code generation frontier
answers:
  - "where is IAL1 verification-code generation task-tree tracked?"
  - "where does FSMGEN verification-code generation fit now?"
  - "should verification output be part of the synthesizable RTL lane?"
  - "should verification generation start from IAL1 or IAL2?"
  - "are IAL1 verification-specific features task-tree tracked?"
  - "what owns future SV/UVM verification-code generation?"
  - "what owns future VHDL verification-code generation?"
date: 2026-06-16
status: current
tags: [ial1, isf, verification, sv-uvm, vhdl, task-tree]
evidence: docs/tasks/IAL1-VERIFICATION-CODE-GENERATION-FRONTIER.md; docs/IAL1_VERIFICATION_CODE_GENERATION_SOURCE_READINESS_AUDIT.md; docs/IAL1_VERIFICATION_OBSERVATION_CONTRACT_SELECTION.md; docs/tasks/ISF-VERIFICATION-OBSERVATION-METADATA.md; docs/TASK_TREE.md; README.md; ROADMAP_V2.md; docs/book/src/14-feature-backlog.md; docs/knowledge/ial2-axi-manager-post-rresp-aggregation-next-slice.md
reverify: rg -n 'IAL1-VERIFICATION-CODE-GENERATION-FRONTIER|IAL1 verification-specific|SV/UVM|VHDL-oriented verification|Direct IAL2-to-verification|Verification Code Generation|ISF-VERIFICATION-OBSERVATION-METADATA|observe NAME|verification_observations' docs/tasks/IAL1-VERIFICATION-CODE-GENERATION-FRONTIER.md docs/IAL1_VERIFICATION_CODE_GENERATION_SOURCE_READINESS_AUDIT.md docs/IAL1_VERIFICATION_OBSERVATION_CONTRACT_SELECTION.md docs/tasks/ISF-VERIFICATION-OBSERVATION-METADATA.md docs/TASK_TREE.md README.md ROADMAP_V2.md docs/book/src/14-feature-backlog.md docs/knowledge/ial2-axi-manager-post-rresp-aggregation-next-slice.md
---

FSMGen verification-code generation is now owned by the active
`IAL1-VERIFICATION-CODE-GENERATION-FRONTIER` task tree.

The selected starting stance is IAL1 (`.isf`) to verification code. Frontier
`.2` found the existing IAL1 checks/properties sufficient for inline SV
assertion projection but insufficient for first-class generated verification
artifacts. Frontier `.3` selected actor-level passive observation metadata,
`(observe NAME (role passive_monitor) (signals SIG...))`, as the first IAL1
verification-specific source feature. Implementation
`ISF-VERIFICATION-OBSERVATION-METADATA.1` shipped that report-only source
contract through `verification_observations[]`. Generated verification code
remains deferred until a later output selector chooses an exact target; the
next frontier leaf is `IAL1-VERIFICATION-CODE-GENERATION-FRONTIER.4`, the
first SV/UVM output contract selector.

Future target families are explicitly tracked, not implied: SV/UVM agents,
monitors, scoreboards, protocol checkers, coverage, reusable verification IP,
and VHDL-oriented verification artifacts each require contract-selection
owners before implementation.

Direct IAL2-to-verification generation remains an audit question. It may later
be selected as a direct route, as an IAL2-to-IAL1 verification annotation
handoff, or as unnecessary for the first implementation. No implementation may
assume that answer before the audit completes.
