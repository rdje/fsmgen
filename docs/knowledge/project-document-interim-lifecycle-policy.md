---
id: project-document-interim-lifecycle-policy
title: Change history uses task trees and Git; rationale remains conditional
answers:
  - "should a changelog be updated for every slice?"
  - "where does FSMGen record what changed?"
  - "when should DEVELOPMENT_NOTES.md be updated?"
  - "should ROADMAP_STATUS.md be updated now?"
  - "should LIVE_ACHIEVEMENT_STATUS.md be updated now?"
  - "what supersedes the blanket legacy-document freeze?"
  - "what is the long-term project document lifecycle policy?"
date: 2026-08-01
status: current
tags: [workflow, changelog, development-notes, roadmap-status, continuity]
evidence: docs/decisions/0047-changes-history-is-task-trees-and-git.md; docs/decisions/0048-achievement-history-is-task-trees-book-and-git.md; docs/decisions/0049-roadmap-status-is-roadmap-task-trees-memory-and-git.md; docs/LEGACY_CONTINUITY_DOCUMENT_VALUE_AUDIT.md; docs/audits/LIVE_ACHIEVEMENT_STATUS_VALUE_AUDIT.md; docs/audits/ROADMAP_STATUS_VALUE_AUDIT.md; COMMIT.md; AGENTS.md; docs/tasks/LIVE-DOCUMENT-SIZE-CONTAINMENT-ADOPTION.md
reverify: rg -n '0047|0048|0049|DEVELOPMENT_NOTES|former (achievement journal|roadmap-status board)' AGENTS.md COMMIT.md docs/TASK_TREE.md
---

Decision `0047` retires the duplicate per-slice changelog and its mandatory
write. Every completed slice updates its owning task evidence and bounded
Memory pointer, uses the work-unit ID in the Git subject, synchronizes the
mdBook/decisions/facts when warranted, passes doctrines, and commits before the
next slice. Task trees plus Git answer what changed and what proves it.

A slice updates `DEVELOPMENT_NOTES.md` only when it produces durable
engineering rationale, constraints, or working decisions without a better
canonical home. The live file is a bounded post-cutover view;
`DEVELOPMENT_NOTES_INDEX.md` addresses exact ordered history.

Decision `0049` independently retires the former roadmap-status board after
the `.11` audit found no unique current authority. Its exact 15,039-line
March-June 2026 snapshot remains version-retrievable; `ROADMAP_V2.md`, task
trees, bounded Memory, the mdBook, and Git own its current questions. Decision
`0048` likewise retires the former achievement journal after independent
consumer and value proof. Decision `0007` still governs bounded Memory and
canonical routing; `0047`-`0049` supersede only their respective `0025`/`0046`
clauses. The conditional rationale-ledger rule remains separately owned.
