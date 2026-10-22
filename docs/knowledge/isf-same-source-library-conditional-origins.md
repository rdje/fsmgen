---
id: isf-same-source-library-conditional-origins
title: Same-source library normalization and conditional origins
answers:
  - "how do same-source library clones retain conditional origins?"
  - "can identical exported actor bodies identify conditional source intent?"
  - "does library origin producer qualification authenticate external documents?"
  - "why are raw ISF interface widths sometimes strings?"
  - "why did an ISF nested aggregate first row retain an extra list?"
  - "what qualifies nested library override list normalization?"
date: 2026-10-02
status: current
tags: [isf, library, source, origins, macros, cloning]
evidence: >-
  t/lib/FSM/Test/SameSourceLibraryOriginParser.pm;
  perl/FSM/Adapter/ISF/Parser.pm;
  docs/tasks/SEMANTIC-INTROSPECTION-MCP-FRONTIER.md
reverify: >-
  scripts/run_with_ram_guard.sh -- prove -Iperl -It/lib
  t/2045-isf-same-source-library-origins.t
  t/2044-isf-conditional-origin-source-authority.t
  t/1092-isf-lispish-adapter.t t/2097-isf-nested-aggregate-normalization.t
---

The observer assigns each actual canonical _build_actor its own source-origin
registry, freezing original operations/forms, owner and inline call context
before expiry. _parse_library_form export references select the producer;
_resolve_library_uses metadata selects the declared library/export/use edge.
The entire canonical clone must equal the original product. Plain ledgers
follow that edge with exact conditional paths/targets and original primitive
JSON kinds. Canonical finalization rechecks root clause coverage and complete
target identity; changed targets cannot publish stale origin proofs.

Private fixture ports: default width 1 is numeric; authored literal width 3 is
a string. _parse_interface retains the token; _finalize_actor_interface_widths
accepts it without coercion. Complete ordinary products/canonical clones
preserve kinds; this is private AST behavior, not a public schema.

Parent/exported catalogs stay separate despite overlapping transaction names
and path offsets. Shared exports retain distinct instance bindings, parameters,
instance/module identities. Different libraries may export identically named,
identical normalized actors with different source intent; explicit producer
linkage separates origins. Generated names/normalized bodies never select
original operations.

The same-source-root observer refuses external documents, package imports and
ATL. Local reload refuses all imports; producer linkage is not imported consumer
authentication. [Document-set authority](isf-library-document-origin-authority.md)
qualifies independently supplied root/library bytes and complete consumer
reloads. [ATL authority](isf-atl-document-origin-authority.md) qualifies
resolved-static constructor/clone origins; file-backed identity remains SEM
`.60.4.3.3.5.2.1.5.2.2.2.2.3`. Formal/generated/domain propagation and adoption
follow. The origin proof changes no production parser/scheduler/public schema or
activation/refusals; HDL/macro runtime is unproved.

2026-10-22: T1092/T2097 qualify recursive LispishAdapter heads in actor
defaults/library overrides, detached raw callers and unchanged scalar kinds.
Authored override source retention stays pending. Evidence:
`docs/audits/nested-normalization-qualification-20261022.py`.
