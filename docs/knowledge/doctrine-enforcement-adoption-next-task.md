---
id: doctrine-enforcement-adoption-next-task
title: Doctrine enforcement adoption shipped for FSMGEN
answers:
  - "what is DOCTRINE-ENFORCEMENT-ADOPTION.1?"
  - "what did doctrine enforcement adoption ship?"
  - "what is DOCTRINE_ENFORCEMENT.md?"
  - "what is TOOLBOX.md?"
  - "where should FSMGEN adopt doctrine enforcement?"
  - "what should TOOLBOX.md contain for FSMGEN?"
date: 2026-06-22
status: current
tags: [doctrine, toolbox, task-tree, continuity, workflow]
evidence: DOCTRINE_ENFORCEMENT.md; TOOLBOX.md; scripts/check_doctrines.sh; scripts/check_doctrine_bootstrap.sh; scripts/check_docs_relative_paths.sh; .githooks/pre-commit; .github/workflows/regression.yml; docs/tasks/DOCTRINE-ENFORCEMENT-ADOPTION.md; docs/TASK_TREE.md; README.md; ROADMAP_V2.md; docs/book/src/09-generated-hdl-debugging-and-inspection.md; docs/book/src/14-feature-backlog.md; docs/knowledge/ial2-feature-completeness-next-slice.md; docs/knowledge/ial2-feature-completeness-priority.md
reverify: rg -n 'DOCTRINE-ENFORCEMENT-ADOPTION\\.1|DOCTRINE_ENFORCEMENT|TOOLBOX|DOCTRINE-BOOTSTRAP|check_doctrines|check_doctrine_bootstrap|check_docs_relative_paths|trace|emit-schedule-json|emit-semantic-json|support-accounting|verify-hdl' DOCTRINE_ENFORCEMENT.md TOOLBOX.md scripts/check_doctrines.sh scripts/check_doctrine_bootstrap.sh scripts/check_docs_relative_paths.sh .githooks/pre-commit .github/workflows/regression.yml docs/tasks/DOCTRINE-ENFORCEMENT-ADOPTION.md docs/TASK_TREE.md README.md ROADMAP_V2.md docs/book/src/09-generated-hdl-debugging-and-inspection.md docs/book/src/14-feature-backlog.md
---

`DOCTRINE-ENFORCEMENT-ADOPTION.1` shipped the FSMGEN doctrine-enforcement
adoption.

The adopted surfaces are root `DOCTRINE_ENFORCEMENT.md`, root `TOOLBOX.md`,
`scripts/check_doctrines.sh`, `scripts/check_doctrine_bootstrap.sh`, and
`scripts/check_docs_relative_paths.sh`. The local pre-commit hook regenerates
and stages the Knowledge Map, then runs the doctrine driver; hosted regression
CI runs the same driver before broader regression.

The current doctrine registry contains `DOCTRINE-BOOTSTRAP`, `MEMORY-ARCH`,
`KNOWLEDGE-MAP`, and `DOC-PATHS`. `TOOLBOX.md` lists FSMGEN-native issue-pinpointing commands for
trace verbosity/logs, `--emit-schedule-json`, strict `--check --json`,
`--emit-semantic-json`, `--verify-hdl`, support-accounting tests, mdBook,
Knowledge Map generation/checks, docs relative-path audit, doctrine and memory
gates, task-tree lookup, issue bundles, and git/diff hygiene.

The adoption did not change parser, generator, HDL, PPIF, or runtime behavior.
