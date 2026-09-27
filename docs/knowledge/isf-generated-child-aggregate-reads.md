---
id: isf-generated-child-aggregate-reads
title: Generated children read live aggregate storage through typed internal ports
answers:
  - "how do generated child storage reads preserve aggregate types?"
  - "can a child read a parent record or list after spawn?"
  - "where do generated child storage resets and registers live?"
  - "can generated child transactions read actor storage in independent clock domains?"
date: 2026-09-27
status: current
tags: [isf, aggregates, storage, composition, ownership, domains, mcp]
evidence: t/1950-isf-child-read-block-collisions.t; perl/FSM/Scheduler/ISF/ChildStorageOwnership.pm; t/1904-isf-generated-child-storage-reads.t; t/1911-isf-generated-child-aggregate-reads.t; t/1916-isf-domain-child-storage-reads.t; docs/decisions/0107-actor-storage-has-one-owner-across-generated-children.md
reverify: FSMGEN_DARWIN_VERILATOR_TEST_RUNTIME=1 scripts/run_with_ram_guard.sh prove -Iperl t/1911-isf-generated-child-aggregate-reads.t t/1916-isf-domain-child-storage-reads.t
---

Generated transaction children read owner-held record
and list storage through internal typed handoffs. Selection tracks the root of
whole-value and scalar-leaf reads; connection preserves its authored type alias
on the owner output and child input. The owner alone retains storage and reset.
Only referenced storage enters the child interface; authored top ports remain
unchanged. Authored aggregate interface/transaction ports and aggregate banks
remain separate unsupported carriers.

T1911 independently observes post-spawn updates and repeated activation across
single/multiple/nested record/list shapes, scalar leaves, different simultaneous
storage aliases and reused worker instances. It checks exact owner/child/top
interfaces and resets, strict scheduled replay and complete native/API/newline
check/semantic/schedule parity. T1904 retains scalar/bank controls and writer
refusals. The packed-value runtime oracle uses Verilator; this does not qualify
aggregate VHDL composition. T1916 additionally qualifies whole/nested-leaf
aggregate reads alongside signed scalar and dynamic bank reads in independent
domains, including post-activation updates and reset isolation. The generated
child and register owner must share a domain; existing validation rejects
unowned sibling-domain access.

The previous explicit aggregate refusal was a qualification boundary, retained
until module typedef identity, repeated module definitions and completion joins
were repaired. Removing that refusal requires no alternate storage or copying
path. Ownership: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.39.2.2.2.2.2`.

Domain qualification owner: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.39.2.2.2.3.2`.

Read handoff allocation reserves authored states and DTs as well as signal,
port and system names. T1950 checks exact and case-folded block collisions,
shared typed consumer views and ordinary stable names. Its independent HDL
oracle preserves a colliding authored rule's guard, owner value and reset.
The former omission merged an unguarded read DT into a guarded rule in emitted
FSM, making that rule unconditional. Reverify with
`FSMGEN_DARWIN_VERILATOR_TEST_RUNTIME=1 scripts/run_with_ram_guard.sh prove -Iperl t/1950-isf-child-read-block-collisions.t`.
Owner: SEMANTIC-INTROSPECTION-MCP-FRONTIER.49.2.2.3.2.2.2.3.2.2.2.2.2.2.2.2.1.1.
