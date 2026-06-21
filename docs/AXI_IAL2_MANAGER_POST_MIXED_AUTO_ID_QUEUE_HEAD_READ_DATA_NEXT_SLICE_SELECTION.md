# AXI IAL2 Manager Post Mixed Auto-ID Queue-Head Read-Data Next Slice Selection

Work unit: `IAL2-FEATURE-COMPLETENESS-FRONTIER.198`

Date: 2026-06-21

## Decision

Select `IAL2-FEATURE-COMPLETENESS-FRONTIER.199`, readiness audit for generated
report-only raw-`ARLEN` burst-length capture over the same-family mixed auto-ID
lifecycle plus concrete same-ID queue-head read burst-last scalar last-beat
read-data shape.

This selector changes no parser, generator, PPIF sample, support-accounting
catalog, validation, generated-artifact, test, or HDL behavior. It records the
next owned IAL2 feature-completeness leaf after `.197` shipped scalar
read-data over the mixed auto-ID plus concrete queue-head read response-demux
boundary.

## Evidence Read

- `.197` shipped behavior:
  `docs/AXI_IAL2_MANAGER_MIXED_AUTO_ID_QUEUE_HEAD_READ_DATA_BEHAVIOR.md`.
- `.196` readiness audit:
  `docs/AXI_IAL2_MANAGER_MIXED_AUTO_ID_QUEUE_HEAD_READ_DATA_READINESS_AUDIT.md`.
- `.195` selector and `.194` mixed response-demux behavior:
  `docs/AXI_IAL2_MANAGER_POST_MIXED_AUTO_ID_QUEUE_HEAD_RESPONSE_DEMUX_NEXT_SLICE_SELECTION.md`
  and
  `docs/AXI_IAL2_MANAGER_MIXED_AUTO_ID_QUEUE_HEAD_RESPONSE_DEMUX_BEHAVIOR.md`.
- Adjacent generated auto-ID read-data, concrete queue-head read-data,
  report-only raw-`ARLEN` burst-length, runtime-validation, multi-beat
  output-bank, support/residue, report, README, ROADMAP_V2, mdBook, task tree,
  Memory, and Knowledge Map surfaces.
- Current implementation entrypoints:
  `perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm`, especially
  `_read_data_response_demux_transaction_coverage`,
  `_normalize_read_data_read`, `_normalize_read_data_burst_length`,
  `_read_data_burst_length_storage_lines`,
  `_read_data_burst_length_capture_rule_lines`, and
  `_read_data_capture_rule_lines`.
- Current PPIF parser surface:
  `perl/FSM/Adapter/IAL2/PPIF.pm`, where the existing `read-data` /
  `burst-length` syntax already covers report-only raw `ARLEN` metadata.

## Current Boundary

`.197` admits read-data transaction coverage for the mixed
`generated_demux_and_queue_head_demux` source only for scalar single-beat and
scalar last-beat read-data. The mixed branch is intentionally bounded to one
auto-ID read transaction plus one depth-2 concrete same-ID queue-head read
group. It maps `r0`, `r1`, and `r2` to the combined generated completion
signals and reports the selected mixed completion-validity strings.

The raw-`ARLEN` burst-length helpers are already transaction-list driven once
the coverage helper admits a last-beat transaction set:

- `_normalize_read_data_burst_length` accepts existing `source arlen`,
  `signal width 8`, `encoding axlen-plus-one`, `capture request`, and
  `validation report-only` metadata.
- `_normalize_read_data_read` attaches per-transaction burst-length storage
  and request-time capture metadata when the normalized coverage admits the
  read-data shape.
- The generated storage, capture-rule, report, and artifact helpers iterate
  the normalized read-data transactions.

The next slice should audit whether the mixed burst-last scalar last-beat
read-data shape can safely reuse those existing helpers by widening only the
local coverage gate in a later implementation leaf.

## Candidate Comparison

Report-only raw-`ARLEN` burst-length is the smallest next readiness audit
because it is the established prerequisite after scalar last-beat read-data and
before runtime beat-count/`RLAST` validation or multi-beat output banks. It
also applies only to the burst-last read family, so it avoids widening the
single-beat mixed read-data shape.

Runtime beat-count/`RLAST` validation is not first because it depends on the
request-captured raw burst length and expected-beat storage being selected for
the mixed burst-last family.

Mixed multi-beat output-bank behavior is not first because it depends on the
runtime-validation boundary for burst tracking, as in the prior concrete
queue-head progression.

Group-local simultaneous enqueue widening is larger because it changes request
acceptance semantics inside duplicate-ID groups.

Write-family read-data remains a diagnostic/public-contract question because
AXI write responses do not carry `RDATA`; it is not the next direct generated
read-data behavior.

Packed burst-vector outputs, alternate full burst payload assembly, direct
backend prerequisites, verification-output generation, VHDL, and
backend-language variants remain separately owned by their roadmap/task-tree
lanes.

## Selected `.199` Audit Boundary

`.199` must audit generated report-only raw-`ARLEN` burst-length capture over
the `.197` mixed read burst-last scalar last-beat read-data boundary:

- read family only;
- existing read burst-last response-demux syntax;
- same-family mixed auto-ID lifecycle plus one concrete same-ID queue-head
  group of depth 2;
- one auto-ID read transaction plus two concrete same-ID queue-head read
  transactions;
- existing read-data syntax with `capture-scope last-beat`,
  `status-policy last-beat`, and `completion-source response-demux`;
- existing burst-length syntax with `source arlen`, `signal width 8`,
  `encoding axlen-plus-one`, `capture request`, bounded `max-beats`, and
  `validation report-only`;
- no single-beat burst-length behavior;
- no runtime beat-count/`RLAST` validation;
- no multi-beat output banks;
- no group-local simultaneous enqueue widening;
- no packed output, direct backend, verification-output, VHDL, or
  backend-language behavior.

The audit should determine whether the first implementation can directly ship
one public support-accounted PPIF sample, likely a burst-last mixed
auto-ID/queue-head read-data sample extended with existing report-only
`burst-length` metadata. It must record generated artifact expectations,
report fields, support-accounting impact, preservation matrix, rollback,
docs/contracts, Knowledge Map impact, and validation gates before behavior
changes.

## Preservation Matrix

| Surface | `.199` audit must preserve |
| --- | --- |
| Parser and public `.ppif` grammar | No syntax change in the audit. |
| `.197` mixed scalar read-data | Existing read single-beat and read burst-last mixed read-data samples remain unchanged. |
| `.194` mixed response-demux | Mixed response-demux-only reports, completion outputs, request-ID ownership, assertions, and HDL remain unchanged. |
| Existing auto-ID read-data and burst-length | Existing auto-ID read-data and burst-length report behavior remains unchanged. |
| Existing concrete queue-head read-data, burst-length, runtime, and multi-beat | Existing one-group, multi-group, and multiple/mixed depth-3 concrete queue-head samples remain unchanged. |
| Support accounting | No new supported sample in `.199`; existing identities remain stable. |
| mdBook and roadmap | Must state that mixed report-only raw-`ARLEN` burst-length is under audit and not yet shipped. |

## Non-Goals

- Do not implement mixed burst-length behavior in `.199`.
- Do not add new `.ppif` syntax.
- Do not add public PPIF samples in `.199`.
- Do not add runtime beat-count/`RLAST` validation for mixed families.
- Do not implement mixed multi-beat output-bank behavior.
- Do not widen group-local simultaneous enqueue behavior.
- Do not add write-family read-data behavior.
- Do not introduce packed burst-vector outputs or alternate full burst payload
  assembly.
- Do not change direct backend, verification-output, VHDL, or
  backend-language variant behavior.
- Do not bypass the `IAL2 -> IAL1 -> IAL0 -> SystemVerilog` lowering chain.

## Validation Gates

For `.198`, the required gates are documentation and continuity gates:

- regenerate and check the Knowledge Map;
- build the mdBook;
- run the docs relative-path audit;
- run the memory-architecture check;
- run diff hygiene;
- run README live-doc numbering and stale/positive frontier scans.

`.199` may add temporary burst-last mixed read-data plus report-only
`burst-length` probes under `/tmp`, but it must remain audit-only unless it
selects a later implementation leaf.

## Rollback Boundary

Rollback for `.198` is limited to this selector record, task-tree frontier
movement, Memory, README, roadmap, mdBook, public contract/handoff wording,
and Knowledge Map/fact-card updates. No parser, generator, public sample,
support-accounting catalog, generated artifact, test, or HDL behavior is part
of this slice.
