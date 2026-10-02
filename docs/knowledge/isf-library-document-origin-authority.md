---
id: isf-library-document-origin-authority
title: Library origin reloads require an independent complete document set
answers:
  - "how are imported conditional origins authenticated?"
  - "can matching document digests authenticate substituted origins?"
  - "do repeated external import aliases share one actor constructor?"
  - "does the private document authority qualify ATL or preparation?"
  - "where is the current refusal consumer census?"
  - "does diagnostic discovery qualify refusal causes?"
date: 2026-10-02
status: current
tags: [isf, library, source, origins, authority, imports, diagnostics]
evidence: >-
  t/2046-isf-library-document-origin-authority.t;
  t/lib/FSM/Test/LibraryDocumentOriginAuthority.pm;
  docs/audits/conditional-origin-documents-20261002/scope.txt;
  docs/audits/library-origin-diagnostic-correction-20261002/scope.txt;
  docs/audits/current-diagnostic-lexical-inventory-20261002/scope.txt;
  docs/tasks/SEMANTIC-INTROSPECTION-MCP-FRONTIER.md
reverify: >-
  scripts/run_with_ram_guard.sh -- prove -Iperl -It/lib
  t/2046-isf-library-document-origin-authority.t
  t/2045-isf-same-source-library-origins.t
---

Whole independent root/library documents and relative identities/search roots
authenticate bytes/forms before exports. Registries use each document's digest.
This parse_source/non-file cohort uses relative FSMLIB;
[file roots](isf-file-document-origin-authority.md) own portable runtime coordinates.

Proofs bind exact selected documents, complete actors/exports/resolutions/clones
and source ledgers. Reload compares whole products and primitive kinds against
independent bytes. Missing/unused/changed documents/forms and forged products
refuse. Finalization rechecks whole use coverage and retained targets/identities/
parameter kinds; late mutations refuse. The stale-clone target defect was fixed.
Initial seal is intermediate; finalization binds that fix, current diagnostic
seal qualifies first-line causes and real caller echoes. Callers/views detach;
comparison bypass genuinely fails refusals while canonical producers run.

Same-source precedes external search; reused exports retain distinct uses. Two
external aliases bind exact separate constructors; equal bodies never merge
constructors or operation identities. Forged catalogs/matching hashes
cannot replace bytes. Original tokens partition sources; normalized singleton
formal tails are undefined and cannot serialize original source.

Parser/scheduler stay intact. Local authority refuses imports; this provider
refuses packages/ATL. [ATL](isf-atl-document-origin-authority.md) owns resolved
static clones; file origins own root reads/same-source use/ATL form association.
Preparation/adoption remain later owners. Public activation/refusals apply;
no new macros, scheduling admission or HDL/macro runtime is proved.

Current [diagnostic census](../audits/current-diagnostic-lexical-inventory-20261002/scope.txt)
binds ASCII Perl token/call populations to Git bytes. Comments, strings,
declarations and overlaps remain candidates. Actual context/producer controls
and cold consumers stay separately owned in the semantic task tree; discovery
proves no cause safety. Cold reverify: `python3 docs/audits/current-diagnostic-lexical-inventory-20261002/verify.py`.
