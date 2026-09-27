---
id: isf-generated-domain-identities
title: ISF logical domains retain identity through portable generated names and case-safe artifacts
answers:
  - "can an ISF clock domain be named bus or another HDL keyword?"
  - "how are domain and CDC child naming collisions resolved?"
  - "can case-only ISF domain names overwrite exported files?"
  - "how do agents join logical domains to generated children through semantic API and MCP?"
  - "does outer domain emission add declarations to a formal module scope?"
  - "are ATL actor event waits allowed in multi-domain actors?"
date: 2026-09-27
status: current
tags: [isf, clock-domains, composition, naming, artifacts, semantics, mcp]
evidence: perl/FSM/Scheduler/ISF/LoweringIR.pm; perl/FSM/Scheduler/ISF.pm; t/1895-isf-generated-domain-names.t; t/1956-isf-formal-domain-outer-namespace.t; docs/book/src/13a-actor-interface.md; docs/audits/specforge-rule-admission-20260924/generated-domain-names.json
reverify: scripts/run_with_ram_guard.sh -- prove -Iperl -It/lib t/1956-isf-formal-domain-outer-namespace.t t/1895-isf-generated-domain-names.t
---

The domain partition allocates physical identities once. Domain names and
public clock/reset/interface pins remain authored. Child labels reserve those
pins, then allocate domains in declaration order, event CDC children, and
activation start/done CDC children through the shared portable keyword and
case-fold collision policy. Module identifiers use a separate namespace;
domain filenames follow the allocated module identity. This prevents case-only
logical domains from replacing one another during filesystem materialization.
Generated transaction child definitions and flat instances are allocated
afterward by the scheduler; see
[domain child realization](isf-multi-domain-generated-children.md).

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

Negative controls exposed independent defects beyond naming. Unused actor
inputs are now preserved by `.32.1.3.4.3`; see
`isf-declared-input-preservation.md` for ordinary/domain artifact and public
query qualification. `.32.1.3.3.1` still owns unreachable independent event
consumers beside an external activation callee. The original mixed-destination
oracle fails without a naming collision. The naming regression's separate
callee domain isolates naming qualification from that unresolved behavior.
Exact original failing sources, state components and runtime/control receipts
remain in the naming audit.

T1956 observes actual outer realization and emission through public lowering.
File materialization and top emission leave complete domain/child IR unchanged.
The emitted FSM children, CDC children/interfaces, wiring labels and module files
match the real allocated metadata; each domain's declarations remain covered by
its local preparation. Detached formal projection preserves those outer
identities and public ports through generated/reused children, library/empty
siblings, event/activation crossings, reset absence, keyword/case domains and
real public-pin/module collisions. Outer names belong to separate composition
or module scopes; no extra local reservation producer is needed for this stage.
Complete reservation integration remains a later gate. The initial focused
qualification passes; broader naming/runtime/public-report results are owned
by the active task until consumed.

Multi-domain ATL event composition is an explicit refusal control: canonical
parsing reports that ATL actor event waits require a single-clock actor in the
current subset. This audit does not widen ATL admission or qualify multi-domain
ATL execution. T1956 preserves that refusal before source preparation.
Owner: SEMANTIC-INTROSPECTION-MCP-FRONTIER.49.2.2.3.2.2.2.3.2.2.2.2.2.2.2.2.2.3.2.2.
