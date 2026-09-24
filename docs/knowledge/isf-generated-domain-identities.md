---
id: isf-generated-domain-identities
title: ISF logical domains retain identity through portable generated names and case-safe artifacts
answers:
  - "can an ISF clock domain be named bus or another HDL keyword?"
  - "how are domain and CDC child naming collisions resolved?"
  - "can case-only ISF domain names overwrite exported files?"
  - "how do agents join logical domains to generated children through semantic API and MCP?"
date: 2026-09-25
status: current
tags: [isf, clock-domains, composition, naming, artifacts, semantics, mcp]
evidence: perl/FSM/Scheduler/ISF/LoweringIR.pm; perl/FSM/Scheduler/ISF.pm; t/1895-isf-generated-domain-names.t; docs/book/src/13a-actor-interface.md; docs/audits/specforge-rule-admission-20260924/generated-domain-names.json
reverify: scripts/run_with_ram_guard.sh -- prove -Iperl -It/lib t/1895-isf-generated-domain-names.t
---

The domain partition allocates physical identities once. Domain names and
public clock/reset/interface pins remain authored. Child labels reserve those
pins, then allocate domains in declaration order, event CDC children, and
activation start/done CDC children through the shared portable keyword and
case-fold collision policy. Module identifiers use a separate namespace;
domain filenames follow the allocated module identity. This prevents case-only
logical domains from replacing one another during filesystem materialization.

The scheduler consumes those identities for child declarations, event and
activation routes, and CDC interfaces. Schedule crossings expose the allocated
module/instance pairs. Domain entries keep logical `name` and expose physical
`scheduled_fsm`; its stem joins to semantic
`forward_ir.intent_hir.composition_children[].module_name`, whose
`instance_name` and `source_name` identify the child. The private domain label
map is not added to the public schema. Native reports, the clean adapter API
and actual newline MCP carry the same identity contract.

At the recorded baseline, `bus`/`BUS`/`interconnect` domains fail portable
admission and a domain named `byte_ready_cdc` conflicts with its event child.
`CORE` and `core` return distinct public lowering keys, but the CLI replaces
one file with the other on the case-insensitive repository volume. The audit
retains exact baseline reports, materialized contents and repaired results.

The regression independently strict-checks every exported artifact and joins
public schedule/semantic identities. Its HDL oracle uses only public event
pins and expected behavior. Runtime qualification requires an available,
qualified Verilator provider; on Darwin the existing qualification is selected
with `FSMGEN_DARWIN_VERILATOR_TEST_RUNTIME=1`. A skipped runtime subtest does
not qualify behavior. Explicit whole top-input `ready` route precedence is qualified separately
under `.32.1.3.4.2`; see `composition-explicit-top-input-precedence.md`.
Generated-name allocation alone does not establish that routing contract.

Negative controls exposed two independent defects with owned repair leaves:
`.32.1.3.4.3` preserves currently omitted unused domain inputs, and
`.32.1.3.3.1` repairs unreachable independent event consumers beside an external
activation callee. The initial mixed-destination oracle fails even without a
naming collision. The naming test consumes its suffix-reserving inputs and
places the callee in a separate domain; this isolates naming qualification
without claiming either independent defect fixed. Exact failing sources,
generated state components and runtime/control receipts remain in the audit.
