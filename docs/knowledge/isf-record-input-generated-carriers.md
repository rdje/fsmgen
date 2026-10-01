---
id: isf-record-input-generated-carriers
title: Authored packed record inputs retain generated and named-domain carriers
answers:
  - "how are generated and named-domain record-input carriers qualified?"
  - "where does a generated record-input copy store and reset its target?"
  - "are unused record inputs retained in the top or inherited child?"
  - "where do generated-top semantic reports retain authored record declarations?"
  - "does ordinary ISF reset provenance omit the domain key?"
date: 2026-10-01
status: current
tags: [isf, record-ports, domains, composition, storage]
evidence: t/2019-isf-record-input-generated-carriers.t; t/2020-composition-child-embedded-packages.t; isf/record_input_children.isf; isf/record_input_types.fsm; perl/FSM/Scheduler/ISF/DomainSource.pm; perl/FSM/Composition/GeneratedChildRealizer.pm; docs/book/src/13j-type-enum-aggregate.md; docs/tasks/SEMANTIC-INTROSPECTION-MCP-FRONTIER.md
reverify: scripts/run_with_ram_guard.sh -- prove -Iperl -It/lib t/2019-isf-record-input-generated-carriers.t t/2020-composition-child-embedded-packages.t
---

T2019 starts from authored sources, including local/imported nested record
aliases, ordinary and named-domain reused readers, unused declarations and
sole generated input-to-storage writers through spawn and blocking calls.
It does not replace storage facts with prepared input facts. Literal recursive
types and ordered packed ranges are independent of metadata/layout producers.

The explicit top retains exactly the declared pins plus owning clocks and
declared resets. Reused instances share a typed child definition but have
distinct start/done/result wiring and live packed input endpoints. Unread
inherited inputs are absent from children while the declared top/owning-domain
input remains. Registers and authored reset values stay in their actor/domain
owner; sole generated writes use typed private data and an explicit enable.
Complete child roles, artifact membership and public/private endpoints are
compared independently, and every actual artifact strictly replays.

The maintained imported example is isf/record_input_children.isf. Its clock-only
idle domain owns an unused record input; io owns the live input, packed storage
and reused readers. The ordinary imported-top package-context defect is repaired
under child .1.1; see composition-embedded-child-package-context.md.

Actual source/lowering/report/carrier products re-derive the structural facts.
Literal layouts, roles, wiring endpoints and missing/external package controls
are independent oracles; exact predecessor package failure supplies historical
falsification. Tests, producer paths, maintained source/package, this fact and
Git preserve durability. Complete generated/domain transport and refusal
closure belongs to .2.4.2. Its .1 qualifies accepted complete native/API/newline
check/semantic/schedule products, literal declarations/domain snapshots, exact
physical top pins, recursive child HIR/structural ports and clock/reset provenance.
Outer composition HIR pins are physical vectors; source.interface_ports retains
authored record aliases/layout, and composition_children retains complete typed
module declarations. Shared corrupted ownership/layout/type projections retain
transport parity but fail the independent literal witnesses. Named producers
and exact source/package bytes stay unchanged. Ordinary reset provenance retains
the required domain:null entry; named entries preserve authored domain order
and explicit versus domain_absent origin. The draft oracle's omitted null field
is corrected against ISFResetProvenance's closed schema, not removed from reports.
Contextual refusals and scalar shadows are qualified under .2, including
selector and binding-identity repairs. Typed prior scalar/storage products are
qualified under .3.1; the missing maintained-source declaration witness and final
prior/discovery closure remain .3.2. Backend/native behavior and consumer completion
remain .2.5. Structural reset ownership is not executed reset behavior.
Owner: SEMANTIC-INTROSPECTION-MCP-FRONTIER.60.4.3.2.4.1.
