---
id: isf-library-document-origin-authority
title: Library origin reloads require an independent complete document set
answers:
  - "how are imported conditional origins authenticated?"
  - "can matching document digests authenticate substituted origins?"
  - "do repeated external import aliases share one actor constructor?"
  - "does the private document authority qualify ATL or preparation?"
date: 2026-10-02
status: current
tags: [isf, library, source, origins, authority, imports]
evidence: >-
  t/2046-isf-library-document-origin-authority.t;
  t/lib/FSM/Test/LibraryDocumentOriginAuthority.pm;
  docs/audits/conditional-origin-documents-20261002/scope.txt;
  docs/audits/conditional-origin-documents-finalization-20261002/scope.txt;
  docs/tasks/SEMANTIC-INTROSPECTION-MCP-FRONTIER.md
reverify: >-
  scripts/run_with_ram_guard.sh -- prove -Iperl -It/lib
  t/2046-isf-library-document-origin-authority.t
  t/2045-isf-same-source-library-origins.t
---

Independent whole root/library documents and relative identities/search roots
authenticate selected bytes/forms before export association. Registries use their
own document digest. This cohort uses parse_source/non-file roots and relative
FSMLIB; [file roots](isf-file-document-origin-authority.md) separately qualify
portable runtime coordinates before adoption.

The proof binds exactly the selected documents and complete canonical actor,
exports, resolutions, clones and source ledgers. JSON reload requires independent
whole-product equality, including primitive kinds. Missing/unused documents,
changed bytes/forms and forged products refuse. Finalization rechecks whole use
coverage, retained edge targets/identities/parameter kinds. Late mutations refuse;
a reproduced stale-clone target defect was fixed before commit. The initial seal
is intermediate; the separate finalization seal binds the corrected provider and
permanent regression.

Identical actors can retain different original operations. Consistently forged
catalogs and matching embedded digests cannot replace independent bytes. Caller
and returned views detach. Bypassing complete comparison yields genuine refusal
failures while canonical producers run.

Same-source declarations precede external search. Reused exports keep distinct
use instances; two external aliases construct actors twice and bind their exact
returned references. Equal bodies never merge constructors. Source partitioning
uses original tokens: normalized singleton formal lists have undefined tails and
cannot serialize original source.

Production parser/scheduler is unchanged. The earlier local authority refuses
imports; this provider refuses packages/ATL. [ATL](isf-atl-document-origin-authority.md)
separately qualifies resolved static clones; file origins qualify actual root
reads and same-source use/ATL form association. Preparation/adoption remain
later owners. Current public activation/refusal contracts apply; no new macro
language, scheduling admission, HDL or macro runtime is proved.
