---
id: project-document-interim-lifecycle-policy
title: Project documents use a split interim lifecycle
answers:
  - "should CHANGES.md be updated for every slice?"
  - "when should DEVELOPMENT_NOTES.md be updated?"
  - "should ROADMAP_STATUS.md be updated now?"
  - "should LIVE_ACHIEVEMENT_STATUS.md be updated now?"
  - "what supersedes the blanket legacy-document freeze?"
date: 2026-07-30
status: current
tags: [workflow, changelog, development-notes, roadmap-status, continuity]
evidence: docs/decisions/0025-project-document-interim-lifecycle.md; COMMIT.md; AGENTS.md; docs/tasks/PROJECT-STATUS-AND-CHANGELOG-POLICY-REVIEW.md
reverify: rg -n 'CHANGES.md|DEVELOPMENT_NOTES.md|ROADMAP_STATUS.md|LIVE_ACHIEVEMENT_STATUS.md' COMMIT.md AGENTS.md docs/TASK_TREE.md TOOLBOX.md
---

Decision `0025` defines distinct interim roles instead of one blanket policy.
Every completed slice adds one concise `CHANGES.md` entry. A slice updates
`DEVELOPMENT_NOTES.md` only when it produces durable engineering rationale,
constraints, or working decisions without a better canonical home.

`ROADMAP_STATUS.md` and `LIVE_ACHIEVEMENT_STATUS.md` remain untouched pending
the evidence-based lifecycle discussion owned by proposed
`PROJECT-STATUS-AND-CHANGELOG-POLICY-REVIEW.1`. Decision `0007` still governs
bounded Memory and canonical routing, but its blanket freeze is superseded for
prospective changelog and conditional development-note updates.
