---
id: doctrine-enforcement-adoption-next-task
title: Doctrine enforcement adoption is the next active requested task
answers:
  - "what is the next active requested task?"
  - "what is DOCTRINE-ENFORCEMENT-ADOPTION.1?"
  - "what did the user ask after dynamic write ID behavior?"
  - "where should FSMGEN adopt doctrine enforcement?"
  - "what should TOOLBOX.md contain for FSMGEN?"
date: 2026-06-22
status: current
tags: [doctrine, toolbox, task-tree, continuity, workflow]
evidence: docs/tasks/DOCTRINE-ENFORCEMENT-ADOPTION.md; docs/TASK_TREE.md; README.md; ROADMAP_V2.md; docs/book/src/14-feature-backlog.md; docs/knowledge/ial2-feature-completeness-next-slice.md; docs/knowledge/ial2-feature-completeness-priority.md
reverify: rg -n 'DOCTRINE-ENFORCEMENT-ADOPTION\\.1|DOCTRINE_ENFORCEMENT|TOOLBOX|trace|emit-schedule-json|emit-semantic-json|check_memory_architecture' docs/tasks/DOCTRINE-ENFORCEMENT-ADOPTION.md docs/TASK_TREE.md README.md ROADMAP_V2.md docs/book/src/14-feature-backlog.md
---

After `IAL2-FEATURE-COMPLETENESS-FRONTIER.223`, the next active requested task
is `DOCTRINE-ENFORCEMENT-ADOPTION.1`.

That leaf must read the sibling PGEN checkout's `DOCTRINE_ENFORCEMENT.md` and
`TOOLBOX.md`, adopt the portable doctrine-enforcement model into FSMGEN, and
create an FSMGEN-specific `TOOLBOX.md`.

FSMGEN's toolbox should list issue-pinpointing commands such as trace
verbosity and trace logs, schedule JSON, strict check JSON, semantic JSON,
support-accounting tests, HDL validation, mdBook build, Knowledge Map
generation/checks, docs relative-path audit, memory architecture gate, and
git/diff hygiene.

The adoption leaf must not change parser, generator, HDL, PPIF, or runtime
behavior unless a later exact task-tree owner is selected.
