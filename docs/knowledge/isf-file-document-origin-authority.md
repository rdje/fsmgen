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
  docs/audits/origin-helper-cause-repair-20261002/verify.py;
  t/2049-pathsearch-module-origin.t;
  docs/audits/pathsearch-origin-20261002/recipe.txt;
  docs/audits/global-origin-20261002/diagnostic.json;
  docs/tasks/SEMANTIC-INTROSPECTION-MCP-FRONTIER.md
reverify: >-
  scripts/run_with_ram_guard.sh -- prove -Iperl -It/lib
  t/2048-isf-file-document-origin-authority.t
  t/2049-pathsearch-module-origin.t
---

Private canonical parse_file authenticates whole root/library bytes/forms before
construction. Workspace projection rebinds declared origins/digests, preserving authored
values/forms/kinds. Paths/names/embedded hashes confer no authority.

Immutable products reconstruct actors/catalogs/calls/use/ATL constructors/ledgers
in adjacent/relative/dotted layouts across moved local roots.
Adjacent files precede ordered FSMLIB and cwd; flat dotted precedes pathish;
same-source precedes external shadows. Missing/changed bytes, symlinks,
unused/substituted authority and forged source/target/producer/scope/coverage/kind
refuse. Callers stay intact, views detach. Helpers compare complete first causes;
real caller and primary-label echo controls qualify, with exact boundary reasons.

Same-source ATL rebuilding retains exact source-form references: first parsing
coerces two width strings to numbers without changing actors/operations. Fresh
original-source comparison falsely refuses that legitimate mutation; loss of
retained association reproduces refusal. Canonical constructors determine whole
catalogs/kinds; equal bodies cannot select origins.

Providers/parser stay intact; packages/groups/unresolved external intent refuse.
Preparation/adoption/scheduling remain later owners. Fixture includes resolve
before chdir. PathSearch binds its module tree at load, retaining lazy first-search
cwd, extras, extensions and missing-file warnings. Moved relative/absolute loads
qualify; original production is genuine RED. Legacy Global/HUtils defects and
unadopted HLinkSubst are archived/deferred outside modern work. Added legacy tests
did not prove a current FSMGEN dependency. No HDL/macro runtime is proved.
