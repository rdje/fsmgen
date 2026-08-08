---
id: ppif-check-json-oversized-summary
title: Oversized PPIF manager-capacity paths keep source and backend work bounded
answers:
  - "how was the t/301 PPIF manager-capacity check-json resource blocker resolved?"
  - "does oversized PPIF manager-capacity check JSON invoke HDL generation?"
  - "what check-json path handles depth-3 PPIF manager-capacity issue-order queue fixtures?"
  - "what verifies oversized PPIF check JSON no longer enters the HDL backend?"
  - "how was t296 PPIF pipeline index 116 resource failure resolved?"
date: 2026-06-26
status: current
tags: [check-json, ppif, ial2, resource-boundary, backend-portability, systemverilog]
evidence: bin/fsmgen; t/1466-ppif-check-json-oversized-summary.t; docs/tasks/BACKEND-LANGUAGE-PORTABILITY-CONTRACT-FRONTIER.md; docs/tasks/SUPPORTED-SMOKE-PPIF-PIPELINE-CLI-ORACLE-SPLIT.md; docs/TASK_TREE.md
reverify: prove -Iperl t/203-enable-graph-factorization-support.t t/1466-ppif-check-json-oversized-summary.t
---

Oversized PPIF manager-capacity check JSON returns from lowered PPIF when its
IAL0 entry exceeds the summary threshold. It preserves source identity,
support match, module/count fields, and `emitted == false` without the HDL
backend; `t/1466-ppif-check-json-oversized-summary.t` proves this while normal
generation and smaller check-json sources retain their existing paths.

For full generation, t296 index 116 bulk-collects intermediate live use and
gates disabled diagnostics. Retained AST roots deduplicate by identity;
temporary parsed assignment RHS roots do not, because Perl may reuse a
reclaimed `refaddr`. `t/203` plus guarded t296 indices 10-13/116 prove
referenced signals stay assigned while the resource repair remains bounded.
