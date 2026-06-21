# AXI IAL2 Manager Post Mixed Auto-ID Queue-Head Multi-Beat Next Slice Selection

Status: selector for `IAL2-FEATURE-COMPLETENESS-FRONTIER.208` on
2026-06-21.

Task-tree owner: `IAL2-FEATURE-COMPLETENESS-FRONTIER.208`

## Decision

Select `IAL2-FEATURE-COMPLETENESS-FRONTIER.209`, readiness audit for
group-local simultaneous enqueue widening across generated concrete same-ID
queue-head families.

This selector changes no parser, generator, PPIF sample, support-accounting
catalog, validation, generated artifact, test, or HDL behavior. It records the
next owned IAL2 feature-completeness leaf after `.207` shipped generated mixed
multi-beat output-bank behavior.

## Evidence Read

The selector read:

- `.207` mixed multi-beat behavior:
  `docs/AXI_IAL2_MANAGER_MIXED_AUTO_ID_QUEUE_HEAD_MULTI_BEAT_READ_DATA_BEHAVIOR.md`.
- `.206` mixed multi-beat readiness audit:
  `docs/AXI_IAL2_MANAGER_MIXED_AUTO_ID_QUEUE_HEAD_MULTI_BEAT_READINESS_AUDIT.md`.
- `.202`, `.200`, `.197`, and `.194` mixed auto-ID plus concrete queue-head
  runtime-validation, burst-length, scalar read-data, and response-demux
  behavior notes.
- Adjacent concrete queue-head precedents for one-group, multi-group,
  depth-3, multiple/mixed depth-3, and mixed auto-ID multi-beat behavior.
- Earlier same-ID admitted enqueue and admitted request boundary notes:
  `docs/AXI_IAL2_MANAGER_SAME_ID_ISSUE_ORDER_QUEUE_ADMITTED_ENQUEUE_BOUNDARY_AUDIT.md`
  and
  `docs/AXI_IAL2_MANAGER_SAME_ID_ISSUE_ORDER_QUEUE_ADMITTED_REQUEST_PULSES_FIRST_SLICE.md`.
- Current generator/report code around admitted request pulses, queue-head
  queue construction, transition enumeration, response states, read-data
  coverage, support detail, and focused generator/PPIF expectations.
- README, `ROADMAP_V2.md`, mdBook, downstream integration spec, public
  interface contract, task tree, Memory, and Knowledge Map.

## Current Boundary

Generated concrete same-ID queue-head behavior now covers the selected read
single-beat, read burst-last, write, depth-2 multi-group, depth-3,
multiple/mixed depth-3, and same-family mixed auto-ID plus queue-head
read-data/runtime/multi-beat families.

The admission boundary is still family-wide. Live schedule probes for the
representative multi-group read, multi-group write, and `.207` mixed
multi-beat samples show one generated request mutual-exclusion assertion per
selected family:

```text
ppif/axi_manager_capacity_status_read_multi_group_same_id_queue_head_response_demux.ppif
  family=read
  boundary=generated_read_burst_last_queue_head_demux
  groups=3:r0/r1:d2,5:r2/r3:d2
  admitted_assertions=axi0_read_issue_order_queue_request_onehot0

ppif/axi_manager_capacity_status_write_multi_group_same_id_queue_head_response_demux.ppif
  family=write
  boundary=generated_write_bid_queue_head_demux
  groups=3:w0/w1:d2,5:w2/w3:d2
  admitted_assertions=axi0_write_issue_order_queue_request_onehot0

ppif/axi_manager_capacity_status_read_burst_last_mixed_auto_id_same_id_queue_head_multi_beat_read_data.ppif
  family=read
  boundary=generated_read_burst_last_queue_head_demux
  groups=3:r1/r2:d2
  admitted_assertions=axi0_read_issue_order_queue_request_onehot0
```

The current `_build_same_id_admitted_request_boundary` builds that assertion
across all selected concrete request events in the read or write family.
`_same_id_issue_order_queue_transition_specs` can enumerate per-group queue
states and transitions, but it assumes at most one admitted enqueue within a
group because each transition chooses either no enqueue or one transaction.
The generated capacity/status counters also still count one direction-level
request per cycle through request fan-in.

## Candidate Comparison

Group-local simultaneous enqueue widening is the next exact IAL2 frontier. It
is the remaining local queue-semantics boundary after the response-demux,
read-data, burst-length, runtime-validation, multi-beat, depth-3, multi-group,
and mixed auto-ID queue-head surfaces have shipped. It needs an audit before
implementation because the safe contract must reconcile per-group admission,
family-level pending counters, request mutual-exclusion assertions, transition
generation, overflow/underflow checks, generated reports, and preservation of
existing one-admitted-request behavior.

Broader concrete same-ID queues beyond the shipped depth-2/depth-3 families
are not selected first because they would build on the same admission and
transition assumptions. Widening queue depth again before resolving the
group-local admission contract would preserve the current family-wide onehot
limit in a larger surface.

Write-family read-data is not selected because AXI write responses carry no
`RDATA`; that remains a diagnostic/public-contract cleanup question rather
than a direct generated read-data feature.

Packed burst-vector outputs and alternate full burst payload assembly are
larger output-shape work. The current supported multi-beat contract is
per-transaction, per-beat output banks with valid masks, length outputs, and
scalar status aggregation.

Direct backend lowering, verification-output generation, VHDL, and
backend-language variants are owned by separate roadmap/task-tree lanes or
remain deferred until the SystemVerilog-backed IAL path is feature complete.

## Selected `.209` Audit Boundary

`.209` must audit group-local simultaneous enqueue widening for generated
same-ID issue-order queue-head families:

- read and write concrete same-ID queue-head families that already generate
  queue-head behavior;
- representative depth-2 multi-group read and write samples;
- representative depth-3 and multiple/mixed depth-3 queue-head samples;
- the `.207` same-family mixed auto-ID plus depth-2 concrete queue-head
  runtime multi-beat sample;
- current admitted request pulse metadata and family-wide request onehot
  assertions;
- queue transition generation and assertions for one enqueue per group versus
  more than one admitted request in the family in the same cycle.

The audit must decide whether the next behavior can safely replace or narrow
the family-wide request onehot into group-local request mutual exclusion,
whether the direction-level capacity counter needs a smaller prerequisite,
and whether transition-rule generation needs a prerequisite for multiple
same-cycle enqueues into distinct concrete-ID groups.

No behavior change belongs in `.209` unless the audit first selects a later
implementation or prerequisite leaf.

## Preservation Matrix

`.209` must preserve:

- existing queue-head generated behavior for read single-beat, read burst-last,
  and write families;
- depth-2 multi-group, depth-3, multiple/mixed depth-3, and mixed auto-ID plus
  concrete queue-head generated behavior;
- generated read-data, burst-length, runtime-validation, and multi-beat output
  bank behavior;
- current support-accounting identities, strict check JSON, semantic JSON, and
  HDL output for public samples;
- parser syntax and PPIF sample set.

## Non-Goals

- Do not implement group-local simultaneous enqueue behavior in `.209`.
- Do not add PPIF syntax or public samples in `.209`.
- Do not add packed burst-vector outputs or alternate full burst payload
  assembly.
- Do not add write-family read-data behavior.
- Do not change direct backend, verification-output, VHDL, or
  backend-language variant behavior.
- Do not bypass the `IAL2 -> IAL1 -> IAL0 -> SystemVerilog` lowering path.

## Validation Gates

For `.208`, the required gates are documentation and continuity gates:

```bash
bash knowledge-map/scripts/gen_knowledge_map.sh
mdbook build docs/book
env -u PERL5LIB prove -Iperl t/1414-docs-relative-paths-audit.t
bash knowledge-map/scripts/check_knowledge_map.sh
scripts/check_memory_architecture.sh
git --no-pager diff --check
```

`.209` may add compact live schedule probes and temporary `/tmp` PPIF
mutations, but it must remain audit-only unless it selects a later
implementation leaf.

## Rollback Boundary

Rollback for `.208` is limited to this selector record, task-tree frontier
movement, Memory, README, roadmap, mdBook, and Knowledge Map/fact-card
updates. No parser, generator, public sample, support-accounting catalog,
generated artifact, test, or HDL behavior is part of this slice.
