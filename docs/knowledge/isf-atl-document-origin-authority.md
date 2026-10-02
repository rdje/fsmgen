---
id: isf-atl-document-origin-authority
title: Resolved ATL origins retain their actual separate constructor identity
answers:
  - "what is ATL?"
  - "how do resolved ATL actor clones retain original conditional intent?"
  - "does ATL resolution reuse the same library constructors as use?"
  - "can identical use and ATL actors have different original source intent?"
  - "why must mutation oracles clone opaque JSON export maps?"
date: 2026-10-02
status: current
tags: [isf, atl, source, origins, authority, imports]
evidence: >-
  docs/book/src/13f-composition.md;
  t/2047-isf-atl-document-origin-authority.t;
  t/lib/FSM/Test/ATLDocumentOriginAuthority.pm;
  docs/audits/conditional-origin-atl-20261002/scope.txt;
  docs/tasks/SEMANTIC-INTROSPECTION-MCP-FRONTIER.md
reverify: >-
  scripts/run_with_ram_guard.sh -- prove -Iperl -It/lib
  t/2047-isf-atl-document-origin-authority.t
  t/2046-isf-library-document-origin-authority.t
---

Actor Transfer Level (ATL) describes data/activation transfers among IAL1/ISF
actors. The enclosing actor bounds the network; scheduling lowers it to IAL0.
Composition covers shipped syntax and orchestration/movement boundaries.

Canonical ATL resolution rebuilds library actors separately from use. The
observer binds actual actor constructors, returned export references and aliases
to resolved static instances by document/type/export/name, ordinal and private
actor path. Whole actors, catalogs, targets, scalar kinds and inline call frames
authenticate on JSON reload. Equal bodies never merge constructors: identical
exports select original select for use and authored when for ATL from distinct
libraries. Late target/declaration/coverage changes, missing export associations
and forged complete products refuse; canonical resolution/cloning still runs.
Views/callers detach; the earlier library observer stays byte-identical and
refuses ATL.

Immutable-source/literal verification reconstructs whole actors, partitions,
phase catalogs/exports/clones/types/controls and declined finalizers. The retained
failed Python oracle aliases export maps, changing the expected second library
map; actual JSON detaches. Snapshotting and rechecking all mutations corrects
only the verifier, preserving products/controls.

The invalid two-instance fixture fails the shipped static subset before observing.
This cohort qualifies one resolved instance, non-file roots and relative search. Groups/unresolved
external intent remain private refusals. [File origins](isf-file-document-origin-authority.md)
separately qualify portable identities and retained forms. Preparation/adoption
remain later prerequisites; public parser/scheduler/admission and activation
behavior remain unchanged. No HDL or macro runtime is proved.
