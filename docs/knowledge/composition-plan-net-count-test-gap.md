---
id: composition-plan-net-count-test-gap
title: t/84 composition net-count assertion was repaired for documented sink nets
answers:
  - "was the t/84 composition net count gap repaired?"
  - "why did t/84-composition-external-fsm-child-sources.t expect one net but see three?"
  - "does t/84 allow documented shared_dp_unused composition plan nets?"
  - "how was the t/84 composition quick regression repaired?"
date: 2026-06-07
status: current
tags: [composition, shared-datapath, tests, audit]
evidence: t/84-composition-external-fsm-child-sources.t; docs/knowledge/composition-shared-datapath-export-sinks.md; docs/book/src/09-generated-hdl-debugging-and-inspection.md; docs/tasks/MDBOOK-CODEBASE-SYNC-AUDIT-JUN07.md; docs/tasks/COMPOSITION-T84-NET-COUNT-REPAIR.md
reverify: prove -Iperl t/84-composition-external-fsm-child-sources.t
---

`COMPOSITION-T84-NET-COUNT-REPAIR.1` repaired the stale narrow assertion in
`t/84-composition-external-fsm-child-sources.t`. The multi-child external-child
fixture used to expect exactly one `composition_plan->nets` entry, but current
generated-child composition exposes the expected data carrier
`comp_link_producer_output_data` plus deterministic `shared_dp_unused_*`
one-bit sink wires for generated-child shared-datapath export-enable pins.

The repaired test now proves the child-to-child carrier by name, width, source,
and target, then rejects only unexpected extra net families. Documented
`shared_dp_unused_*` sink nets no longer make the quick regression fail, and no
composition behavior or public top interface changed.
