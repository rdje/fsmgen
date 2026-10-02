---
id: isf-same-source-library-conditional-origins
title: Same-source library conditionals retain explicit export and clone provenance
answers:
  - "how do same-source library clones retain conditional origins?"
  - "can identical exported actor bodies identify conditional source intent?"
  - "does library origin producer qualification authenticate external documents?"
  - "why are raw ISF interface widths sometimes strings?"
date: 2026-10-02
status: current
tags: [isf, library, source, origins, macros, cloning]
evidence: >-
  t/2045-isf-same-source-library-origins.t;
  t/lib/FSM/Test/SameSourceLibraryOriginParser.pm;
  perl/FSM/Adapter/ISF/Parser.pm;
  docs/tasks/SEMANTIC-INTROSPECTION-MCP-FRONTIER.md
reverify: >-
  scripts/run_with_ram_guard.sh -- prove -Iperl -It/lib
  t/2045-isf-same-source-library-origins.t
  t/2044-isf-conditional-origin-source-authority.t
---

The detached observer gives each actual canonical _build_actor its own source
origin registry. It freezes original operations/forms, owner and inline call
context before the registry expires. Actual _parse_library_form export
references select the producer record. Actual _resolve_library_uses metadata
selects the declared library/export/use edge, and the complete canonical cloned
actor must equal that original product. Plain source ledgers follow that edge
with exact conditional paths/targets and original primitive JSON kinds.
Root clause coverage and complete target identity are revalidated after
canonical finalization; a changed target cannot publish a stale origin proof.
In this fixture's private parsed ports, default width 1 is a JSON number and
authored literal width 3 remains a JSON string. _parse_interface retains the
literal token and _finalize_actor_interface_widths accepts that token without
coercion. Complete ordinary products and canonical clones preserve those
original kinds. This is private AST behavior, not a public report schema.

The parent and exported actors retain separate origin catalogs even when their
transaction names and path offsets overlap. Two instances may select one export
while retaining distinct bindings, parameters, instance and module identities.
Two different libraries may export identically named, completely identical
normalized actors with different source intent; explicit producer linkage keeps
their origins distinct. No generated-name or normalized-body inference selects
an original operation.

This bounded proof covers same-source library roots. External documents,
package imports and ATL refuse explicitly in this private observer. The local
reload authority still refuses all imports: producer linkage is not imported
consumer authentication. Independent document-set authenticity and ATL remain
owned by SEM `.60.4.3.3.5.2.1.5.2.2.2.2`; formal/generated/domain propagation
and adoption follow. Production parser, scheduler, public schemas and existing
activation/refusal behavior remain unchanged. No HDL or macro runtime is proved.
