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
  docs/audits/constructor-cause-repair-20261002/scope.txt;
  docs/tasks/SEMANTIC-INTROSPECTION-MCP-FRONTIER.md
reverify: >-
  scripts/run_with_ram_guard.sh -- prove -Iperl -It/lib
  t/2046-isf-library-document-origin-authority.t
  t/2045-isf-same-source-library-origins.t
---

Whole independent documents and relative labels/roots authenticate bytes/forms
before exports; registries use each document digest.
This parse_source cohort uses relative FSMLIB;
[file roots](isf-file-document-origin-authority.md) own portable runtime coordinates.

Proofs bind whole selected documents, actors/exports/resolutions/clones and
source ledgers. Reload compares products and primitive kinds against independent
bytes. Missing/unused/changed documents/forms and forged products refuse.
Finalization rechecks use coverage, retained targets/identities/parameter kinds;
late mutations refuse. The stale-clone defect was fixed. Initial seal is
intermediate; finalization binds that fix. Callers/views detach; comparison
bypass fails refusals while canonical producers run.

Same-source precedes external search; reused exports retain distinct uses. Two
external aliases bind separate constructors; equal bodies never merge constructor
or operation identities. Forged catalogs/matching hashes cannot replace bytes.
Original tokens partition sources; normalized singleton formal tails are
undefined and cannot serialize original source.

Parser/scheduler stay intact. Local authority refuses imports; this provider
refuses packages/ATL. [ATL](isf-atl-document-origin-authority.md) owns resolved
static clones; file origins own reads/same-source use/ATL associations.
Preparation/adoption remain later owners. Public activation/refusals apply;
no new macros, scheduling admission or HDL/macro runtime is proved.

Constructor assertions now compare complete first causes and reject real label
echo. Library/file first-line substrings remain P2 repairs. Reverify: `python3 docs/audits/constructor-cause-repair-20261002/verify.py`.
The [lexical census](../audits/current-diagnostic-lexical-inventory-20261002/scope.txt)
binds ASCII Perl tokens/calls to Git bytes. Comments/strings/declarations and
overlaps are candidates, not cause safety. Context/producer/cold controls remain
owned. Exact kinds/numeric forms: `python3 docs/audits/current-diagnostic-lexical-kinds-20261002/verify.py`.
