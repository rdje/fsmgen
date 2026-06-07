---
id: doc-paths-relative-to-repo-root
title: Documentation and Knowledge Map file paths are repo-root-relative
answers:
  - "should documentation paths be absolute or relative?"
  - "can docs mention /Users paths?"
  - "can the Knowledge Map contain absolute local paths?"
  - "how should docs and task trees refer to files?"
  - "are file paths in docs relative to the repo root?"
  - "does the docs relative path guard scan KNOWLEDGE_MAP.md?"
date: 2026-06-07
status: current
tags: [documentation, knowledge-map, workflow, paths]
evidence: docs/decisions/0011-doc-file-paths-relative-to-repo-root.md; docs/decisions/0012-knowledge-map-paths-relative-to-repo-root.md; t/1414-docs-relative-paths-audit.t
reverify: prove -Iperl t/1414-docs-relative-paths-audit.t
---

File references in live docs, mdBook source, task trees, knowledge cards, and the
generated `KNOWLEDGE_MAP.md` are relative to the git repository root. Use paths such as
`docs/tasks/DOC-PATH-RELATIVE-KNOWLEDGE-MAP.md` or `perl/FSM/Debug.pm`; do not write
machine-local home-directory checkout paths.

The focused guard is `t/1414-docs-relative-paths-audit.t`. It scans `docs/**/*.md` and
root `KNOWLEDGE_MAP.md` for local home-directory absolute paths, while leaving ordinary
URLs and non-local system paths out of scope.
