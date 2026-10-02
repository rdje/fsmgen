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

The private authority accepts independently supplied complete root/library
source bytes, relative document identities and relative search roots. It runs
actual canonical file resolution and checks the selected complete bytes and
normalized source form against that independent input before associating an
export producer. Actor-local registries use their own document's digest.
This cohort supplies the root through parse_source with a non-file logical
label and resolves external files through relative FSMLIB roots. File-backed
root resolution's runtime absolute candidates need a separately qualified
runtime-to-relative identity boundary before adoption.
The published proof covers exactly the selected document set and complete
canonical actor, exports, import resolutions, use clones and source ledgers.
Opaque reloads must equal the independently reconstructed complete products,
including original JSON scalar kinds. Missing or unused authority documents,
changed selected bytes/forms and forged products refuse.
After canonical finalization, complete final use coverage and retained edge
targets/identities/parameter kinds must still agree before publication. Actual
late mutations refuse, including a reproduced stale-clone target defect fixed
before commit. The initial sealed proof is intermediate; the separately sealed
finalization proof binds the corrected provider and permanent regression.

Two original source documents can yield identical complete actors with
different conditional operations. A fully consistent substituted catalog and
matching embedded digest still cannot replace independently supplied original
bytes. Returned views and caller products remain detached. Actual bypass of
the complete comparison exposes the desired refusal failures while the
canonical producers continue to run.

Canonical same-source selection precedes external search. Reusing an export
preserves distinct use instances. Two aliases of one external library cause
canonical resolution to construct its actors twice; each use binds the exact
actor reference returned for its declared alias. Equal actor bodies do not
merge those separate constructor identities. The fixture source partitioner
uses original tokens: normalized singleton formal lists contain undefined
tails and are not a source serialization format.

This is private qualification, with production parser/scheduler unchanged.
The earlier local-source authority still refuses imports. Packages and ATL
remain closed here. A [separate ATL observer](isf-atl-document-origin-authority.md)
qualifies actual resolved-static producers and source-bound reloads while this
provider remains unchanged. File-backed identity is next under SEM
`.60.4.3.3.5.2.1.5.2.2.2.2.3`.
Formal/generated/domain propagation and metadata adoption remain later owners.
Current activation workarounds/refusals and public contracts still apply. No
new macro language, scheduling admission, HDL or macro runtime is proved.
