---
id: isf-formal-point-products
title: Parent point-reference and entry-default products remain distinct during formal preparation
answers:
  - "are named point active signals reserved before direct formal allocation?"
  - "what does parent_point_products retain in formal source preparation?"
  - "do output defaults keep actor ownership when a formal shadows the output?"
date: 2026-09-27
status: current
tags: [isf, formals, reservations, points, defaults, scope]
evidence: perl/FSM/Scheduler/ISF/LoweringIR.pm; t/1943-isf-formal-point-products.t; t/1416-isf-trigger-anchor-ref.t; t/1476-isf-output-default-reset.t
reverify: scripts/run_with_ram_guard.sh prove -Iperl t/1943-isf-formal-point-products.t t/1416-isf-trigger-anchor-ref.t t/1476-isf-output-default-reset.t
---
Current integration: [production formal scope](isf-production-formal-scope.md)
now consumes the qualified preparation products. The producer-specific account
below records its original qualification boundary; pending global integration
statements are historical. Independent-controller and local-call execution
remain separately gated.


Actual parent point resolution runs after transaction lowering and activation
wiring. It lazily creates driven active signals for referenced named points or
activation labels. Earlier transaction/wiring products retain unresolved checks
and omit those helpers. The T1943 fixture derives isf_port_main_point_1_active
from actual production assignments; the earlier plan selects the same name for
main.point_1_active until the real point product joins its reservations.

prepare_formal_source retains parent_point_products by running canonical point
resolution and actor output-default insertion on detached parent states/checks.
It uses the actual module-wide parent point bindings; generated child scopes and
pruned bodies remain separate. The result contains states, resolved assertions,
point counter additions, source bindings and actor output defaults. No unresolved
formal declaration maps are merged, and the result is not executable IR.

T1943 compares production products and strict projected carriers, including
point/on-as labels, cross-transaction lookup, lazy unused-point behavior,
exact/case-folded helper collisions, declaration permutation and source/product
mutation controls. Output defaults keep the actor output identity under a
same-name direct formal; raw executable aliases still fail and the projected
formal has separate storage. Unknown and duplicate parent anchors fail through
the canonical checks. These products follow
[wiring products](isf-formal-wiring-products.md) and precede arbitration, child
ownership and final composition coverage. Production rewriting and independent
controller runtime support remain unimplemented.

Owner: SEMANTIC-INTROSPECTION-MCP-FRONTIER.49.2.2.3.2.2.2.3.2.1.
