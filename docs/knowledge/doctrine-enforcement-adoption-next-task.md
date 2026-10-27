---
id: doctrine-enforcement-adoption-next-task
title: Doctrine enforcement adoption shipped for FSMGEN
answers:
  - "what is DOCTRINE-ENFORCEMENT-ADOPTION.1?"
  - "what did doctrine enforcement adoption ship?"
  - "what is DOCTRINE_ENFORCEMENT.md?"
  - "what is TOOLBOX.md?"
  - "how are repeated live-document verifier executions shared?"
  - "how does the doctrine driver avoid repeating README pressure validation?"
  - "where should FSMGEN adopt doctrine enforcement?"
  - "what should TOOLBOX.md contain for FSMGEN?"
date: 2026-10-27
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

The original adoption registry contained `DOCTRINE-BOOTSTRAP`, `MEMORY-ARCH`,
`KNOWLEDGE-MAP`, and `DOC-PATHS`. `TOOLBOX.md` lists FSMGEN-native issue-pinpointing commands for
trace verbosity/logs, `--emit-schedule-json`, strict `--check --json`,
`--emit-semantic-json`, `--verify-hdl`, support-accounting tests, mdBook,
Knowledge Map generation/checks, docs relative-path audit, doctrine and memory
gates, task-tree lookup, issue bundles, and git/diff hygiene.

The adoption did not change parser, generator, HDL, PPIF, or runtime behavior.
Current registry membership derives from `scripts/check_doctrines.sh --list`.
Decision `0122` makes the final pre-commit hook authoritative; optional local
`--timings --fail-fast` feedback keeps complete success coverage and default CI
diagnostics. No preflight result is cached or reused as hook permission.

The live-document wrapper opts both local adapter and neutral core into
`--share-read-only-verifiers`: exact executable paths share results only within
one process under fixed root/environment/no arguments/null stdin and stable
read-only validation inputs. Each proof role is still required, and failed core
results fail every consumer. Default standalone behavior stays per-role; a new
invocation never reuses success. Contracts: `live-document-size/LIVE_DOCUMENT_SIZE_CHECKER.md`;
implementation: `scripts/run_live_document_adapter_verifiers.pl` and the neutral
checker. Reverify: `prove -Iperl t/1554-live-document-size-doctrine.t t/2159-live-document-adapter-sharing.t`.

The driver requires actual `LIVE-DOCUMENT-SIZE` success within that invocation
before accepting README `--routing-only`; its internal prerequisite begins false.
Missing/failed prerequisites reject the complete run; collect-all still runs
routing diagnostics. Standalone
`scripts/check_readme_entrypoint.sh` still delegates complete pressure validation.
Explicit partial mode never claims pressure success. Reverify:
`prove -Iperl t/1553-readme-routed-destination-pressure.t t/2158-doctrine-driver-execution-modes.t`.
The staged-result test uses the same repository's Git directory, an isolated
project-local alternate index/object store, and no fixture repository commits.
