---
id: composition-explicit-top-input-precedence
title: Explicit whole top-input routes precede unrelated same-name inference
answers:
  - "why did an explicitly wired ready input fail on CDC ready outputs?"
  - "does explicit top-input wiring override same-name composition inference?"
  - "are invalid explicit links still rejected after inference is skipped?"
date: 2026-09-25
status: current
tags: [composition, wiring, inference, isf, cdc, semantics, mcp]
evidence: perl/FSM/Composition/SameNameLinkBuilder.pm; perl/FSM/Composition/LinkedPlanBuilder.pm; t/175-composition-same-name-link-builder.t; t/176-composition-linked-plan-builder.t; t/1896-explicit-top-input-route-precedence.t; docs/book/src/05-composition-basics.md; docs/audits/specforge-rule-admission-20260924/explicit-input-routes.json
reverify: scripts/run_with_ram_guard.sh -- prove -Iperl -It/lib t/175-composition-same-name-link-builder.t t/176-composition-linked-plan-builder.t t/1896-explicit-top-input-route-precedence.t
---

`build_top_input_links` excludes an explicit whole top-input endpoint before
checking a same-name family. Previously it checked unrelated child directions,
widths and types first, then skipped the explicitly owned top input too late.
This rejected an ISF public `ready` input despite its explicit domain route,
because CDC children also expose `ready` outputs. Top-output inference already
used the earlier exclusion.

`LinkedPlanBuilder` still resolves each authored link and validates source and
target roles, width agreement, declared types and duplicate drivers. Unrouted
top inputs retain their ordinary same-name admission checks; a child-only link
does not claim an unrelated top input. Implicit ports and declared-by-name
lanes retain their existing rules. This change does not widen source-expression
ownership or invent partial-port inference semantics.

T175 exercises unrelated direction/width/interface-type/declared-type conflicts
with and without explicit ownership. T176 confirms actual link validation.
T1896 uses strict public ISF/direct-composition sources, independent generated
artifact checks, and complete native/API/newline MCP success/failure equality.
Its Verilog-family oracle holds the authored ready input low, verifies that
completion remains blocked, then releases it and repeats around reset. Runtime
qualification requires a real qualified Verilator provider, using the existing
Darwin qualification switch where applicable; a skip does not qualify behavior.
The audit retains exact baseline failures, repaired reports, unchanged control
HDL, provider/producer identities and the test receipts.

The original body-first `await` actor also fails the independent runtime
oracle with the non-colliding `work_ready` name: `_inj_watchdog` places
initialization in the await state, then external-activation rewriting adds a
synthetic entry without moving it. The zero-valued counter causes an immediate
timeout and premature acknowledgement. `.32.1.3.3.3` owns repair, rearming and
real timeout qualification. The routing regression uses an ordinary explicit
transaction entry and retains the original failing source/HDL; a leading
sample may fold into the await and does not fix this initialization defect.
