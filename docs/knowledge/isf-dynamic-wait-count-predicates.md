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
evidence: docs/audits/runtime-wait-book-20260927/fixtures.json; docs/audits/runtime-wait-book-20260927/verify.pl; t/1929-isf-wait-carrier-grammar.t; docs/audits/dynamic-wait-carrier-grammar-20260927.json; perl/FSM/Scheduler/ISF/LoweringIR.pm; t/1909-isf-dynamic-wait-count-predicates.t; t/1908-isf-generated-child-completion-memory.t; t/1244-isf-wait-clause-lowering.t; docs/tasks/SEMANTIC-INTROSPECTION-MCP-FRONTIER.md
reverify: FSMGEN_DARWIN_VERILATOR_TEST_RUNTIME=1 scripts/run_with_ram_guard.sh prove -Iperl t/1929-isf-wait-carrier-grammar.t t/1909-isf-dynamic-wait-count-predicates.t t/1908-isf-generated-child-completion-memory.t t/1244-isf-wait-clause-lowering.t
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

The wait-local operator/arity validator now matches the supported carrier
intersection: unary logical-not, binary logical shifts, and multi-operand
arithmetic, bitwise, comparison and concatenation forms. It refuses bitwise-not,
logical conjunction/disjunction spellings and unary concatenation before
serialization. The retained grammar audit shows that those forms formerly
passed scheduling then failed strict carrier parsing; they never had successful
HDL qualification. This repair changes the rejection location, not their meaning.

T1929 checks nested invalid shapes and every retained operator through strict
carrier replay. Check/semantic failures retain complete native/API/newline
reports; schedule refusals follow the existing nonzero-stderr/message-only
adapter contract. A working arithmetic count retains full schedule-report
parity. The quoted-division diagnostic redaction defect is repaired by
SEMANTIC-INTROSPECTION-MCP-FRONTIER.52, qualified by T1930. The lowering-reference fragments are synchronized by .49.2.2.6 against
retained complete sources and generated state mappings. The replay audit
checks all mapped excerpts and prose-only predecessor controls. After .53
repairs the extract carrier and width declarations, its previously failing
extract source must also pass strict replay. See isf-extract-carrier-replay.md.

The wait-book audit's fixtures retain source origins, primary carrier identity
and state-to-fragment mappings. Its verifier requires complete fragment
coverage and exact token order/grouping, ignoring formatting whitespace only;
missing or duplicate identities fail. The baseline-drift record retains old
excerpts. Prose-only predecessor controls replay too. Output and temporary
carriers stay repository-local; the audit never changes the book or source.
This qualifies excerpt fidelity and declared carrier outcomes, not additional
runtime timing, independent-controller behavior or API/MCP completeness.
