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
evidence: docs/decisions/0047-changes-history-is-task-trees-and-git.md; docs/LEGACY_CONTINUITY_DOCUMENT_VALUE_AUDIT.md; docs/audits/LIVE_ACHIEVEMENT_STATUS_VALUE_AUDIT.md; COMMIT.md; AGENTS.md; docs/tasks/LIVE-DOCUMENT-SIZE-CONTAINMENT-ADOPTION.md
reverify: rg -n '0047|DEVELOPMENT_NOTES|ROADMAP_STATUS|LIVE_ACHIEVEMENT_STATUS' AGENTS.md COMMIT.md docs/TASK_TREE.md
---

Decision `0047` retires the duplicate per-slice changelog and its mandatory
write. Every completed slice updates its owning task evidence and bounded
Memory pointer, uses the work-unit ID in the Git subject, synchronizes the
mdBook/decisions/facts when warranted, passes doctrines, and commits before the
next slice. Task trees plus Git answer what changed and what proves it.

A slice updates `DEVELOPMENT_NOTES.md` only when it produces durable
engineering rationale, constraints, or working decisions without a better
canonical home.

`ROADMAP_STATUS.md` and `LIVE_ACHIEVEMENT_STATUS.md` remain untouched while
their owned work is pending. Decision `0046` selects exact archival and
live-path retirement for roadmap status plus a bounded form for the separately
reviewed rationale ledger. The independent `.11` audit finds no executable or
content consumer for achievement status and no current recovery/status role;
its sole distinct value is direct browsing of a frozen 23-day historical
digest. The file, README route, and surface remain unchanged while the director
selects retirement, frozen retention, or a new bounded projection. Decision
`0007` still governs bounded Memory and canonical routing; `0047` supersedes
the `0025`/`0046` changelog clauses only.
