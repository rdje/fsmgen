---
id: composition-embedded-child-package-context
title: Embedded generated composition children retain sibling package context
answers:
  - "why did a generated imported ISF record-input top fail isolated replay?"
  - "how do embedded FSM and DT children resolve sibling package roots?"
  - "can a composition package override an external child's package source?"
date: 2026-10-01
status: current
tags: [composition, packages, imports, isf, generated-children]
evidence: perl/FSM/Composition/GeneratedChildRealizer.pm; perl/FSM/Pipeline/SourceFrontend.pm; t/2020-composition-child-embedded-packages.t; t/2019-isf-record-input-generated-carriers.t; docs/tasks/SEMANTIC-INTROSPECTION-MCP-FRONTIER.md
reverify: scripts/run_with_ram_guard.sh -- prove -Iperl -It/lib t/2020-composition-child-embedded-packages.t t/2019-isf-record-input-generated-carriers.t
---

Ordinary ISF generated tops already emit imported package roots alongside
their embedded parent and worker modules. The old GeneratedChildRealizer
selects only the child's single AST, discarding sibling packages before
SourceFrontend collects them. An isolated imported record-input carrier
therefore refuses even though its individual module artifacts strictly replay.
The extraction starts in d008a23278f58c4875427f09a087082558f4012d; subsequent
strict-boundary work also passes the selected child AST to the frontend.

Embedded FSM and DT realization now combines the detached child root with
the composition's detached package roots. Existing strict source validation,
package import declarations and the normal resolver retain admission. This
adds no package imports or symbols to a child that does not declare them.
External child files bypass this handoff and retain their own source-relative
package lookup; a same-name top package cannot replace or fill that dependency.

T2020 uses actual strict embedded FSM/DT realization and full composition
pipelines, reused definitions, independently expected recursive record types
and packed struct member widths, missing/undeclared-package refusals and external local
package precedence. Complete composition facts and source bytes stay unchanged.
The final canonical witnesses fail against the exact committed predecessor
9aaa27bbb7c072dab52b486b64f93309e55cfa99 while external controls pass.
Early draft infix syntax, context-prefix diagnostic extraction, one-child C2
selection, bit-vector HDL syntax and resolver-message capitalization expectations are corrected oracle limits,
not product qualification. T2019 qualifies actual authored ISF carriers.

Re-derivation uses actual compiler/realizer products and literal type/wiring
expectations. Exact predecessor failures and missing/external package controls
provide distinct falsification. Tracked producers, tests, maintained source,
this fact, its owner and Git preserve durability. Native HDL execution and
complete generated/domain public closure remain separate obligations.
Owner: SEMANTIC-INTROSPECTION-MCP-FRONTIER.60.4.3.2.4.1.1.
