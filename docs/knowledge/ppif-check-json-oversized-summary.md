---
id: ppif-check-json-oversized-summary
title: Oversized PPIF manager-capacity work stays bounded
answers:
  - "how was the t/301 oversized PPIF check-json blocker resolved?"
  - "does oversized PPIF manager-capacity check JSON invoke HDL generation?"
  - "what check-json path handles depth-3 PPIF capacity fixtures?"
  - "what verifies oversized PPIF check JSON no longer enters the HDL backend?"
  - "how was t296 PPIF pipeline index 116 resource failure resolved?"
  - "how does the long t296 supported-smoke matrix resume after a RAM-guard interruption?"
date: 2026-06-26
status: current
tags: [check-json, ppif, ial2, resource-boundary]
evidence: bin/fsmgen; t/203-enable-graph-factorization-support.t; t/1466-ppif-check-json-oversized-summary.t; t/1597-t296-checkpoint.t; docs/tasks/SUPPORTED-SMOKE-PPIF-PIPELINE-CLI-ORACLE-SPLIT.md
reverify: prove -Iperl -It/lib t/203-enable-graph-factorization-support.t t/1466-ppif-check-json-oversized-summary.t t/1597-t296-checkpoint.t
---

Oversized manager-capacity check JSON stops after PPIF lowering when IAL0
exceeds the summary threshold. It reports source, support, module/count, and
`emitted == false` without the backend; t1466 proves this and the unchanged
normal/smaller paths.

Full generation index 116 bulk-collects live use and gates disabled diagnostics.
Owned AST roots deduplicate by identity; temporary parsed RHS roots scan
independently because Perl may reuse `refaddr`. t203 and guarded indices
10-13/116 prove correctness and boundedness.

The full t296 matrix can opt into an atomic `.artifacts/t296` checkpoint bound
to its clean Git revision and contract version. Unsafe, malformed, or stale
state fails closed; a green complete parent removes it.
