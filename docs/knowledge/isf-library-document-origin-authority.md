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
  - "what does T1983 metadata helper check?"
date: 2026-10-04
status: current
tags: [isf, library, source, origins, authority, imports, diagnostics]
evidence: >-
  t/2046-isf-library-document-origin-authority.t;
  t/lib/FSM/Test/LibraryDocumentOriginAuthority.pm;
  docs/audits/conditional-origin-documents-20261002/scope.txt;
  docs/audits/constructor-cause-repair-20261002/scope.txt;
  docs/audits/interface-metadata-runtime-20261004/scope.txt;
  docs/tasks/SEMANTIC-INTROSPECTION-MCP-FRONTIER.md
reverify: >-
  python3 -B docs/audits/interface-metadata-writer-cause-repair-20261004/verify.py;
  scripts/run_with_ram_guard.sh -- prove -Iperl -It/lib
  t/2046-isf-library-document-origin-authority.t
  t/2045-isf-same-source-library-origins.t
  t/2054-isf-validator-finalizer-diagnostic-causes.t
---

Document bytes/forms and relative identities/roots authenticate exports for
reload; digests index. parse_source uses relative
FSMLIB; [files](isf-file-document-origin-authority.md)
own portable runtime coordinates.

Actors/exports/resolutions/clones/ledgers bind documents.
Missing/unused/changed documents/forms, forged products/late mutations refuse.
Finalization rechecks uses/targets/identities/parameter kinds. Stale clones repair at finalization; initial seal is intermediate.
Views detach; bypass fails on canonical products.

Reused exports retain distinct uses; external aliases separate constructors. Equal bodies keep constructor/operation identities. Catalogs/hashes cannot replace bytes. Original tokens partition sources; undefined tails cannot serialize them.

Parser/scheduler stay intact; local authority closes imports, this provider packages/ATL.
[ATL](isf-atl-document-origin-authority.md) binds resolved static clones.
Preparation/adoption later; public gates apply. No new macros, scheduling
admission or HDL/macro runtime is proved.

Constructors, library/file helpers and ten validator/finalizer sites bind complete causes and mutations. Caller/argument/source/label echoes reject; prior consumers RED. Guarded readers: [origin](../audits/origin-helper-cause-repair-20261002/verify.py), [validator](../audits/validator-finalizer-cause-repair-20261003/verify.py).
[Names](../audits/named-helper-membership-20261003/scope.txt) owns lexical units;
[cohorts](../audits/residual-named-helper-cohorts-20261003/scope.txt) own review. [Record
plan](../audits/aggregate-record-helper-plan-20261003/scope.txt) splits sources. Private widths may stringify; final numeric facts stay numeric. [ASCII
census](../audits/current-diagnostic-lexical-inventory-20261002/scope.txt) overlaps text; its [kind
reader](../audits/current-diagnostic-lexical-kinds-20261002/verify.py) qualifies numeric forms. Cold review open.

T1983 [copy repair](../audits/interface-metadata-copy-repair-20261004/scope.txt) rejects kind/alias/lossy/projection faults. Complete metadata and writer causes reject wanted-path Storable, caller/argument and parser filename echoes; guard bypasses fail. Products/kinds conserve; diagnostic/outcome joins remain owned.
