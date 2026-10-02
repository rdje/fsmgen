---
id: isf-file-document-origin-authority
title: File-backed origins authenticate selected bytes before portable projection
answers:
  - "how are file-backed root and library origins authenticated?"
  - "can conditional provenance survive moving the workspace root?"
  - "why must same-source ATL rebuilding retain original form identity?"
  - "which file search precedence does private origin qualification cover?"
  - "why does PathSearch survive chdir after a relative module load?"
  - "why is legacy HUtils work deferred from the FSMGEN frontier?"
date: 2026-10-02
status: current
tags: [isf, atl, source, origins, authority, files, locality]
evidence: >-
  t/2048-isf-file-document-origin-authority.t;
  t/lib/FSM/Test/FileDocumentOriginAuthority.pm;
  docs/audits/conditional-origin-files-20261002/scope.txt;
  docs/audits/file-origin-diagnostic-correction-20261002/verify.py;
  t/2049-pathsearch-module-origin.t;
  docs/audits/pathsearch-origin-20261002/recipe.txt;
  docs/audits/global-origin-20261002/diagnostic.json;
  docs/tasks/SEMANTIC-INTROSPECTION-MCP-FRONTIER.md
reverify: >-
  scripts/run_with_ram_guard.sh -- prove -Iperl -It/lib
  t/2048-isf-file-document-origin-authority.t
  t/2049-pathsearch-module-origin.t
---

Private canonical parse_file authenticates whole root/library bytes/forms against
independent documents before construction. Chosen workspaces project only
declared actor/proof origins and rebind digests; authored values/forms/kinds stay
unchanged. Paths, filenames and embedded hashes supply no authority.

Immutable predecessor products independently reconstruct whole actors/catalogs,
calls, use/ATL constructors and ledgers in adjacent/relative/dotted layouts
across moved local roots. Adjacent files precede ordered FSMLIB and cwd; flat
dotted candidates precede pathish ones. Same-source declarations precede external
shadows. Missing/changed bytes, symlinks and unused/substituted authority refuse.
Reloads reject forged source/target/producer/scope/coverage/kind; callers stay
unchanged and views detach. Cause checks use the first diagnostic line.

Canonical same-source ATL rebuilding reuses source forms: first parsing coerces
two width strings to numbers, preserving actors/conditional operations.
Strong actual form references authenticate the exact prior producer-mutated
state. Comparing it afresh to original source falsely refuses; removing retained
association demonstrates that refusal. Canonical constructors still determine
whole catalogs/kinds; equal bodies cannot select origins.

Origin providers/parser stay unchanged; packages/groups/unresolved external
intent refuse. Preparation/adoption/scheduling remain later owners. Fixture includes resolve before chdir. PathSearch now binds its module tree at
load time, preserving lazy first-search cwd, retained extras, extensions and
missing-file warnings. Fresh relative/absolute loads in moved roots qualify the
repair; retained original production gives genuine RED. Legacy Global/HUtils defects and an unadopted HLinkSubst candidate are archived.
They were found by added legacy tests; no current FSMGEN dependency was proved.
They are deferred outside the modern frontier, not preparation prerequisites.
No HDL/macro runtime is proved.
