---
id: mdbook-build-destination-locality
title: mdBook custom destinations resolve from the invocation working directory
answers:
  - "where does mdbook build resolve a relative dest-dir?"
  - "how do book verification scripts keep output inside the repository?"
  - "what caused the reset-slice book output locality recovery?"
date: 2026-09-25
status: current
tags: [mdbook, documentation, artifacts, locality, verification]
evidence: docs/audits/specforge-rule-admission-20260924/book-output-recovery.json; docs/audits/specforge-rule-admission-20260924/isf-reset-polarity.json; docs/tasks/SEMANTIC-INTROSPECTION-MCP-FRONTIER.md
reverify: scripts/run_with_ram_guard.sh -- python3 -B docs/audits/specforge-rule-admission-20260924/verify-book-output-locality.py
---

`mdbook build docs/book --dest-dir DEST` resolves relative `DEST` against the
invocation working directory, not `docs/book`. Therefore `../../.artifacts/`
from the repository root escapes the repository. The reset-slice publisher
exposed that mistaken assumption when it could not find fresh local HTML.

Custom-output automation must derive an absolute destination from the current
repository root at runtime, check it remains inside the root and on its volume,
and start with a fresh destination. Persist its repository-relative identity;
never change the actual tool argument merely to avoid recording an absolute
path. Build success alone does not identify the output consumed by validation.

The owning reset slice copied and hash-verified both exact misplaced books,
consumed their recovered HTML, deleted only those old roots, and recorded the
residue census. The first carrier build had been valid and local; the later
relative-destination check reused that earlier render. Its historical receipt
now explicitly records the correction. No compiler or HDL test result changes.
The tracked probe builds a miniature book from another source directory,
checks relative and absolute destinations against the invocation directory,
requires fresh marker-bearing HTML and same-volume local paths, then removes
its owned temporary workspace. The manifest retains the actual recovery.
