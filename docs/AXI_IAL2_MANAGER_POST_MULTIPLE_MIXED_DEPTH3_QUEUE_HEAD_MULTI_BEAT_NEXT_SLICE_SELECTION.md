# AXI IAL2 Manager Post Multiple/Mixed Depth-3 Queue-Head Multi-Beat Next Slice Selection

Status: selector for `IAL2-FEATURE-COMPLETENESS-FRONTIER.192` on
2026-06-21.

Task-tree owner:
`docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md`.

## Decision

Select `IAL2-FEATURE-COMPLETENESS-FRONTIER.193`, readiness audit for
same-family mixed auto-ID lifecycle plus concrete same-ID queue-head
response-demux.

This selector changes no parser, generator, PPIF sample, support-accounting
catalog, validation, generated-artifact, test, or HDL behavior. It only records
the next owned IAL2 feature-completeness leaf and fixes public documentation
drift after `.191`.

## Evidence Read

- `.191` behavior:
  `docs/AXI_IAL2_MANAGER_MULTIPLE_MIXED_DEPTH3_QUEUE_HEAD_MULTI_BEAT_READ_DATA_BEHAVIOR.md`.
- `.190` readiness audit:
  `docs/AXI_IAL2_MANAGER_MULTIPLE_MIXED_DEPTH3_QUEUE_HEAD_MULTI_BEAT_READINESS_AUDIT.md`.
- `.188` support/residue cleanup:
  `docs/AXI_IAL2_MANAGER_MULTIPLE_MIXED_DEPTH3_QUEUE_HEAD_RUNTIME_VALIDATION_SUPPORT_RESIDUE_CLEANUP.md`.
- `.186` runtime-validation behavior:
  `docs/AXI_IAL2_MANAGER_MULTIPLE_MIXED_DEPTH3_QUEUE_HEAD_RUNTIME_VALIDATION_BEHAVIOR.md`.
- One-depth-3 and depth-2 multi-group precedents:
  `docs/AXI_IAL2_MANAGER_READ_BURST_LAST_DEPTH3_QUEUE_HEAD_MULTI_BEAT_READ_DATA_BEHAVIOR.md`
  and `docs/AXI_IAL2_MANAGER_MULTI_GROUP_QUEUE_HEAD_READ_DATA_BEHAVIOR.md`.
- Active task-tree, roadmap, Memory, Knowledge Map, README, and mdBook
  IAL2/embedding surfaces.
- Code and support surfaces:
  `perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm`,
  `perl/FSM/Adapter/IAL2/PPIF.pm`, and
  `perl/FSM/Support/RegressionCorpus.pm`.

## Current Boundary

The concrete same-ID queue-head response-demux path is now broad across
selected read single-beat, read burst-last, and write shapes:

- one concrete duplicate group at depth 2 or depth 3;
- multiple or mixed depth-3/depth-2 concrete duplicate groups;
- read single-beat scalar read-data over multiple/mixed depth-3 groups;
- read burst-last scalar last-beat read-data, raw `ARLEN` capture,
  runtime beat-count/`RLAST` validation, and generated multi-beat output banks
  over the selected multiple/mixed depth-3 groups.

The same-family mixed auto-ID plus concrete queue-head combination is still an
explicit fail-closed boundary. `_response_demux_queue_head_plan_for_family`
rejects a family that combines an auto-ID lifecycle with a concrete same-ID
queue-head demux group in the same response family. That guard keeps the
existing generated auto-ID response-demux completion ownership separate from
the concrete queue-head completion ownership.

## Candidate Comparison

Write-family read-data is not the next behavior owner. AXI write responses do
not carry `RDATA`, so that path is a public-contract and diagnostic question
rather than the next direct generated read-data behavior.

Same-family mixed auto-ID plus concrete queue-head response-demux is the next
smallest exact IAL2 frontier because it is a current local fail-closed
boundary with shipped adjacent behavior on both sides: bounded auto-ID
response-demux already exists, and concrete queue-head response-demux already
exists across the selected depth and family sets. It needs an audit before
implementation because the safe contract depends on response-event fanout,
completion signal ownership, report/residue shape, and same-family source
matching.

Group-local simultaneous enqueue widening is larger. It changes transition
semantics for queue groups rather than only the response-demux ownership
contract at the existing one-request-per-family admission boundary.

Packed burst-vector outputs and alternate full burst payload assembly are
larger output-shape work. `.191` established per-transaction, per-beat output
banks as the current shipped multi-beat output contract.

Direct backend lowering, VHDL, and backend-language variants remain deferred
by the roadmap and decisions until the SystemVerilog-backed IAL path is
feature complete. Verification-output generation is owned by the separate
IAL1 verification-code task tree.

## Selected `.193` Audit Boundary

`.193` must audit the first safe route for one response family that combines:

- at least one same-family auto-ID lifecycle transaction set;
- at least one concrete duplicate-ID queue-head group;
- explicit response-demux for the same read or write family.

The audit should inspect current fail-closed diagnostics, auto-ID
response-demux generation, concrete queue-head queue-state generation,
completion validity, response-event matching, support report shape, residue
ownership, and whether a smaller prerequisite is needed before behavior can
ship.

Temporary in-memory PPIF probes are allowed for read single-beat, read
burst-last, and write families. No public sample or generated behavior belongs
in `.193`.

## Preservation Matrix

| Surface | `.193` audit must preserve |
| --- | --- |
| Parser and public `.ppif` grammar | No syntax change. |
| Existing auto-ID behavior | Existing bounded generated auto-ID request-ID drive and response-demux remain unchanged. |
| Existing concrete queue-head behavior | Existing depth-2, depth-3, multiple/mixed depth-3 queue-head samples remain unchanged. |
| Existing `.191` multi-beat output banks | Per-beat banks, valid masks, length outputs, scalar `RRESP`, runtime assertions, and empty residues remain unchanged. |
| Support accounting and catalog | No new supported sample in `.193`; existing identities remain stable. |
| mdBook and roadmap | Must name `.193` as audit-only and keep deferred work explicit. |

## Non-Goals

- Do not implement mixed auto-ID plus concrete queue-head generated behavior in
  `.193`.
- Do not add public PPIF samples in `.193`.
- Do not widen group-local simultaneous enqueue behavior.
- Do not introduce packed burst-vector outputs or alternate full burst payload
  assembly.
- Do not change direct backend, verification-output, VHDL, or backend-language
  variant behavior.
- Do not bypass the `IAL2 -> IAL1 -> IAL0 -> SystemVerilog` lowering chain.

## Validation Gates

For `.192`, the required gates are documentation and continuity gates:

- regenerate and check the Knowledge Map;
- build the mdBook;
- run the docs relative-path audit;
- run the memory-architecture check;
- run diff hygiene and stale/positive frontier scans;
- run the README live-doc numbering check.

`.193` may add focused temporary probes and code inspections, but must remain
audit-only unless it explicitly selects a later implementation leaf.

## Rollback Boundary

Rollback for `.192` is limited to this selector record, task-tree frontier
movement, Memory, README, roadmap, mdBook, and Knowledge Map/fact-card
updates. No code, generated artifact, public sample, or HDL behavior is part
of the slice.
