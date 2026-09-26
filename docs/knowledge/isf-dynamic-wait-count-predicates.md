---
id: isf-dynamic-wait-count-predicates
title: Runtime wait entry tests the entire count for nonzero
answers:
  - "why did even positive ISF runtime wait counts stall?"
  - "how are dynamic wait counts sampled and combined with predecessor guards?"
  - "which independent runtime checks qualify odd and even wait counts?"
date: 2026-09-27
status: current
tags: [isf, timing, wait, count, predicate, runtime]
evidence: perl/FSM/Scheduler/ISF/LoweringIR.pm; t/1909-isf-dynamic-wait-count-predicates.t; t/1908-isf-generated-child-completion-memory.t; t/1244-isf-wait-clause-lowering.t; docs/tasks/SEMANTIC-INTROSPECTION-MCP-FRONTIER.md
reverify: FSMGEN_DARWIN_VERILATOR_TEST_RUNTIME=1 scripts/run_with_ram_guard.sh prove -Iperl t/1909-isf-dynamic-wait-count-predicates.t t/1908-isf-generated-child-completion-memory.t t/1244-isf-wait-clause-lowering.t
---

`_link_dynamic_wait_entry_edge` previously combined the count itself with its
predecessor condition using bitwise `&`. A true scalar condition AND an even
multi-bit count produces zero, so a positive even count could neither enter
nor zero-bypass. The load guard and transition now use `(!= count_source 0)`;
the sampled assignment RHS, counter width and count_source report metadata
remain unchanged. The same helper covers consecutive waits and predecessor
forms including transaction entry, awaits, joins, branches and loop decisions.

T1909 independently checks elapsed clock cycles over the complete declared
four-bit scalar range, consecutive pairs, expression counts, branches, awaits,
and input changes after sampling. After `.45` repairs typed VHDL comparison
operands and results, its GHDL scalar-range/snapshot oracle also passes without
TODOs. See `vhdl-unsigned-comparison-literals.md` for the backend contract. Complete
native/API/newline check, semantic and schedule reports agree. T1908 restores
the original even-count join case. T1244 retains exact scheduled-transition,
zero-bypass, pending-sample and metadata assertions with explicit nonzero
predicates. This evidence does not claim exhaustive arbitrary-width coverage.
