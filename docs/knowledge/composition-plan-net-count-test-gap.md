---
id: composition-plan-net-count-test-gap
title: t/84 quick regression still counts only child-to-child composition nets
answers:
  - "why does ./bin/ci-regression quick --no-book fail in t/84?"
  - "why does t/84-composition-external-fsm-child-sources.t expect one net but see three?"
  - "are shared_dp_unused composition plan nets documented?"
  - "what is the current t/84 composition net count audit gap?"
date: 2026-06-07
status: current
tags: [composition, shared-datapath, tests, audit]
evidence: t/84-composition-external-fsm-child-sources.t; docs/knowledge/composition-shared-datapath-export-sinks.md; docs/book/src/09-generated-hdl-debugging-and-inspection.md; docs/tasks/MDBOOK-CODEBASE-SYNC-AUDIT-JUN07.md
reverify: prove -Iperl t/84-composition-external-fsm-child-sources.t
---

The quick regression currently reproduces a stale narrow assertion in
`t/84-composition-external-fsm-child-sources.t`: the multi-child external-child
fixture still expects exactly one `composition_plan->nets` entry, but current
generated-child composition exposes three entries. The expected data carrier is
`comp_link_producer_output_data`; the two additional entries are deterministic
`shared_dp_unused_*` one-bit sink wires for generated-child shared-datapath
export-enable pins.

The extra sink wires are documented behavior, not a new public top-interface
surface. The current repair needs a separate exact owner to make the regression
assert the child-to-child carrier semantics without treating documented unused
shared-datapath export sinks as a failure.
