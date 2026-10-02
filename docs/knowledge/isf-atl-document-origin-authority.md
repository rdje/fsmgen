---
id: isf-atl-document-origin-authority
title: Resolved ATL origins retain their actual separate constructor identity
answers:
  - "how do resolved ATL actor clones retain original conditional intent?"
  - "does ATL resolution reuse the same library constructors as use?"
  - "can identical use and ATL actors have different original source intent?"
  - "why must mutation oracles clone opaque JSON export maps?"
date: 2026-10-02
status: current
tags: [isf, atl, source, origins, authority, imports]
evidence: >-
  t/2047-isf-atl-document-origin-authority.t;
  t/lib/FSM/Test/ATLDocumentOriginAuthority.pm;
  docs/audits/conditional-origin-atl-20261002/scope.txt;
  docs/tasks/SEMANTIC-INTROSPECTION-MCP-FRONTIER.md
reverify: >-
  scripts/run_with_ram_guard.sh -- prove -Iperl -It/lib
  t/2047-isf-atl-document-origin-authority.t
  t/2046-isf-library-document-origin-authority.t
---

Canonical ATL type resolution rebuilds library actors separately from use
resolution. A detached observer retains each actual actor constructor, exact
returned export reference and declared import alias. Resolved static instance
metadata selects that actual producer, with explicit document/type/export/name,
declaration ordinal and private resolved-actor path. Full actors, source catalogs,
targets, original scalar kinds and inline call frames survive whole JSON reloads.
Equal complete bodies do not merge constructor identities. In the identical
export fixture, a use selects select-authored intent while ATL selects authored
when intent from another library; their complete normalized actors are identical.

Actual final target/declaration/coverage changes refuse before proof publication.
Missing export association refuses after canonical resolution/cloning still runs.
Consumer comparison against independently supplied complete documents rejects
forged actor/proof products. Returned views and submitted originals remain
detached. The earlier library-only observer still refuses ATL and stays byte-identical.

Independent verification reconstructs complete source partitions, actors,
phase-specific catalogs/exports/clones/types/controls and declined finalizer
products from the immutable source oracle and independent literals. Its first
mutation model retains a Python reference alias between serialized export-map
views: changing one expected map incorrectly changes another. Actual opaque
JSON maps are detached. The diagnostic shows only the expected second library
map changing; use JSON snapshots for the oracle's value contract, preserve the
failed verifier/diagnostic and recheck every complete mutation. Product code
and actual saved controls are unchanged by that oracle correction.

The first two-instance fixture is rejected by the shipped static-network subset
before the observer runs; it is an invalid fixture, not a production defect.
The qualified cohort uses one resolved static ATL instance, supplied non-file
root labels and relative library search. Groups and unresolved external actor
intent remain closed in this private authority. File-backed runtime/relative
identity is next under SEM `.60.4.3.3.5.2.1.5.2.2.2.2.3`, before formal/generated/
domain propagation and adoption. Public parser/scheduler/admission and current
activation/refusal behavior remain unchanged. No HDL or macro runtime is proved.
