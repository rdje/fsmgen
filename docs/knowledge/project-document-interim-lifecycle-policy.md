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
evidence: docs/decisions/0047-changes-history-is-task-trees-and-git.md; docs/decisions/0048-achievement-history-is-task-trees-book-and-git.md; docs/LEGACY_CONTINUITY_DOCUMENT_VALUE_AUDIT.md; docs/audits/LIVE_ACHIEVEMENT_STATUS_VALUE_AUDIT.md; COMMIT.md; AGENTS.md; docs/tasks/LIVE-DOCUMENT-SIZE-CONTAINMENT-ADOPTION.md
reverify: rg -n '0047|0048|DEVELOPMENT_NOTES|ROADMAP_STATUS|achievement journal' AGENTS.md COMMIT.md docs/TASK_TREE.md
---

Decision `0047` retires the duplicate per-slice changelog and its mandatory
write. Every completed slice updates its owning task evidence and bounded
Memory pointer, uses the work-unit ID in the Git subject, synchronizes the
mdBook/decisions/facts when warranted, passes doctrines, and commits before the
next slice. Task trees plus Git answer what changed and what proves it.

A slice updates `DEVELOPMENT_NOTES.md` only when it produces durable
engineering rationale, constraints, or working decisions without a better
canonical home.

`ROADMAP_STATUS.md` remains untouched while its owned work is pending. Decision
`0046` selects its exact archival and live-path retirement plus a bounded form
for the separately reviewed rationale ledger. Decision `0048` independently
retires the former achievement journal after the `.11` audit found no
executable/content consumer or current recovery/status role. Its exact 23-day
digest remains version-retrievable; task evidence, the mdBook, bounded Memory,
and Git own the current questions. Decision `0007` still governs bounded Memory
and canonical routing; `0047` and `0048` supersede only their respective
`0025`/`0046` clauses.
