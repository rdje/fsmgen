---
id: ial2-new-protocol-support-workflow
title: IAL2 new protocol support workflow
answers:
  - "how do we add a new IAL2 protocol?"
  - "what is the process for adding protocol support to IAL2?"
  - "what steps are required before implementing a new IAL2 protocol?"
  - "how should new protocol support be validated and documented?"
  - "where is the AXI and APB protocol onboarding process captured?"
date: 2026-06-28
status: current
tags: [ial2, protocol, workflow, ppif, mdbook, support-accounting, task-tree]
evidence: docs/IAL2_NEW_PROTOCOL_SUPPORT_WORKFLOW.md; docs/book/src/15a-ial2-new-protocol-support.md; docs/tasks/IAL2-NEW-PROTOCOL-SUPPORT-WORKFLOW-CAPTURE.md; docs/TASK_TREE.md; README.md; ROADMAP_V2.md; MEMORY.md
reverify: scripts/check_doctrines.sh
---

`docs/IAL2_NEW_PROTOCOL_SUPPORT_WORKFLOW.md` is the canonical workflow for
adding future IAL2 protocol or protocol-profile support.

The workflow requires task-tree ownership before behavior changes, evidence
capture, readiness audit, public contract selection, bounded implementation
through generated `.isf` and `.fsm` review artifacts, runnable samples,
support accounting, fail-closed diagnostics, mdBook coverage, Knowledge Map
continuity, doctrine gates, and a per-slice commit.

The AXI and APB lesson is to add protocols by exact bounded families, not by
attempting a full-protocol implementation in one slice.
