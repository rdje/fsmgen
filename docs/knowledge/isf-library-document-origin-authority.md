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
date: 2026-10-03
status: current
tags: [isf, library, source, origins, authority, imports, diagnostics]
evidence: >-
  t/2046-isf-library-document-origin-authority.t;
  t/lib/FSM/Test/LibraryDocumentOriginAuthority.pm;
  docs/audits/conditional-origin-documents-20261002/scope.txt;
  docs/audits/origin-helper-cause-repair-20261002/scope.txt;
  docs/audits/current-diagnostic-lexical-inventory-20261002/scope.txt;
  docs/audits/constructor-cause-repair-20261002/scope.txt;
  docs/audits/validator-finalizer-cause-repair-20261003/scope.txt;
  docs/tasks/SEMANTIC-INTROSPECTION-MCP-FRONTIER.md
reverify: >-
  scripts/run_with_ram_guard.sh -- prove -Iperl -It/lib
  t/2046-isf-library-document-origin-authority.t
  t/2045-isf-same-source-library-origins.t
  t/2054-isf-validator-finalizer-diagnostic-causes.t
---

Complete documents, relative identities/roots and source bytes/forms authenticate
exports before reload; registries use document digests. parse_source uses relative
FSMLIB; [files](isf-file-document-origin-authority.md)
own portable runtime coordinates.

Whole actors, exports, resolutions, clones and ledgers bind selected documents.
Missing/unused/changed documents/forms and forged products refuse. Finalization
rechecks use coverage, targets, identities and parameter kinds; late mutations
refuse. The stale-clone fix is finalization-bound; initial seal is intermediate.
Views detach; real comparison bypass fails refusals while canonical producers run.

Same-source precedes external search. Reused exports retain distinct uses;
two external aliases have separate constructors. Equal bodies cannot merge
constructor/operation identities. Catalogs/hashes cannot replace bytes. Original
tokens partition sources; undefined normalized singleton tails cannot serialize them.

Parser/scheduler stay intact. Local authority closes imports; this provider
closes packages/ATL. [ATL](isf-atl-document-origin-authority.md) owns resolved
static clones. Preparation/adoption remain later; public gates apply. No new macros, scheduling
admission or HDL/macro runtime is proved.

Constructors, library/file helpers and ten validator/finalizer sites compare complete causes, including generic mutations. Caller/argument/source/label echoes reject; prior consumers give RED. Guarded readers: [origin](../audits/origin-helper-cause-repair-20261002/verify.py), [validator](../audits/validator-finalizer-cause-repair-20261003/verify.py).
[Named membership](../audits/named-helper-membership-20261003/scope.txt) owns lexical units; [cohorts](../audits/residual-named-helper-cohorts-20261003/scope.txt) own review. The [record plan](../audits/aggregate-record-helper-plan-20261003/scope.txt) splits source reviews; causes/native eligibility stay open. [ASCII census](../audits/current-diagnostic-lexical-inventory-20261002/scope.txt) overlaps comments/strings/declarations; its [kind reader](../audits/current-diagnostic-lexical-kinds-20261002/verify.py) qualifies numeric forms. Broader cold review stays open.
