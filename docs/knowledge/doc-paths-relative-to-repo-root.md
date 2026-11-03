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
  - "how are audit producer source paths made portable?"
date: 2026-11-03
status: current
tags: [documentation, knowledge-map, workflow, paths]
evidence: docs/decisions/0011-doc-file-paths-relative-to-repo-root.md; docs/decisions/0012-knowledge-map-paths-relative-to-repo-root.md; t/1414-docs-relative-paths-audit.t; docs/audits/push-readiness-20261025/verify_audit_source_paths.py
reverify: prove -Iperl t/1414-docs-relative-paths-audit.t && python3 -B docs/audits/push-readiness-20261025/verify_audit_source_paths.py
---

Docs/book/task trees/cards/`KNOWLEDGE_MAP.md`: repository-relative file references, e.g. `docs/tasks/DOC-PATH-RELATIVE-KNOWLEDGE-MAP.md`, `perl/FSM/Debug.pm`; no machine-local checkout paths.

T1414 scans `docs/**/*.md` and root `KNOWLEDGE_MAP.md` for home paths; excludes URLs/non-local system paths.

Audit `path` fields are relative: normalize Python `__file__`; preserve snapshot text/hashes. The scoped reader checks relocation.
