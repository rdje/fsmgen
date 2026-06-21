# AXI IAL2 Manager Post Mixed Auto-ID Queue-Head Response-Demux Next Slice Selection

Work unit: `IAL2-FEATURE-COMPLETENESS-FRONTIER.195`

Date: 2026-06-21

## Decision

Select `IAL2-FEATURE-COMPLETENESS-FRONTIER.196`, readiness audit for mixed
read-data consumption over same-family mixed auto-ID lifecycle plus concrete
same-ID queue-head response-demux.

This selector changes no parser, generator, PPIF sample, support-accounting
catalog, validation, generated-artifact, test, or HDL behavior. It records the
next owned IAL2 feature-completeness leaf after `.194` shipped response-demux
only for the mixed auto-ID plus concrete queue-head family boundary.

## Evidence Read

- `.194` shipped behavior:
  `docs/AXI_IAL2_MANAGER_MIXED_AUTO_ID_QUEUE_HEAD_RESPONSE_DEMUX_BEHAVIOR.md`.
- `.193` readiness audit:
  `docs/AXI_IAL2_MANAGER_MIXED_AUTO_ID_QUEUE_HEAD_RESPONSE_DEMUX_READINESS_AUDIT.md`.
- Existing generated auto-ID response-demux, concrete queue-head response-demux,
  scalar read-data, burst-length, runtime-validation, multi-beat output-bank,
  support/residue, report, README, ROADMAP_V2, mdBook, task tree, Memory, and
  Knowledge Map surfaces.
- Current implementation entrypoints:
  `perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm`,
  especially `_normalize_read_data`,
  `_read_data_response_demux_transaction_coverage`,
  `_read_data_response_states_by_transaction`, and
  `_read_data_capture_rule_lines`.

## Live Report Evidence

The `.194` public mixed response-demux samples now report the combined
response-demux source:

| Sample family | Report mode/source | Completion coverage |
| --- | --- | --- |
| read single-beat | `bounded_read_rid_mixed_auto_id_queue_head_demux_contract` / `generated_demux_and_queue_head_demux` | `axi0_r0_complete`, `axi0_r1_complete`, `axi0_r2_complete` |
| read burst-last | `bounded_read_rid_mixed_auto_id_queue_head_demux_contract` / `generated_demux_and_queue_head_demux` | `axi0_r0_complete`, `axi0_r1_complete`, `axi0_r2_complete` |
| write | `bounded_write_bid_mixed_auto_id_queue_head_demux_contract` / `generated_demux_and_queue_head_demux` | `axi0_w0_complete`, `axi0_w1_complete`, `axi0_w2_complete` |

For read burst-last, the report semantics include both matched auto-ID or
concrete queue-head response ID and `RLAST`. For read single-beat and write,
the semantics are matched auto-ID or concrete queue-head response ID.

Preservation probes for adjacent shipped read-data and auto-ID samples passed:

```text
./bin/fsmgen --strict --check --json ppif/axi_manager_capacity_status_read_single_beat_same_id_queue_head_read_data.ppif
./bin/fsmgen --strict --check --json ppif/axi_manager_capacity_status_read_burst_last_depth3_same_id_queue_head_read_data.ppif
./bin/fsmgen --strict --check --json ppif/axi_manager_capacity_status_read_response_demux.ppif
```

## Current Boundary

`.194` proves that one selected response family can combine generated auto-ID
response-demux state with concrete same-ID queue-head response-demux state. The
read-data path is not yet admitted for that mixed source.

The current read-data coverage helper still has separate branches:

- `generated_queue_head_demux` consumes
  `same_id_issue_order_queues` and queue-head completion signals, with bounded
  coverage for selected single-beat, last-beat, and multi-beat queue-head
  shapes.
- the auto-ID path consumes `auto_transactions` and
  `generated_completion_signals`.

The mixed response-demux source is `generated_demux_and_queue_head_demux`.
Because the current read-data coverage logic does not yet select an explicit
combined transaction/completion binding for that source, the next step should
be an audit, not a behavior change.

## Candidate Comparison

Mixed read-data consumption is the next smallest exact frontier because `.194`
shipped mixed response-demux-only read families and the adjacent read-data
families already exist on both sides: generated auto-ID read-data and concrete
queue-head read-data. The remaining question is the exact coverage contract for
combining auto transactions and concrete queue-head transactions under one read
response-demux family.

Group-local simultaneous enqueue widening is larger because it changes request
acceptance semantics inside duplicate-ID groups.

Write-family read-data remains a diagnostic/public-contract question because
AXI write responses do not carry `RDATA`; it is not the next direct generated
read-data behavior.

Packed burst-vector outputs and alternate full burst payload assembly are
larger output-shape changes. Direct backend prerequisites, verification-output
generation, VHDL, and backend-language variants remain separately owned by
their roadmap/task-tree lanes.

## Selected `.196` Audit Boundary

`.196` must audit mixed read-data consumption over one selected read family at
a time after `.194`:

- same-family mixed auto-ID lifecycle plus concrete same-ID queue-head
  response-demux;
- existing read-data syntax only;
- read single-beat scalar `RDATA`/`RRESP` as the smallest likely candidate;
- read burst-last scalar last-beat `RDATA`/`RRESP` as the adjacent likely
  candidate;
- no multi-beat, burst-length, runtime-validation, packed output, or alternate
  payload behavior unless the audit selects them for a later owner.

The audit should determine whether the first implementation can directly use
existing `read-data` syntax and whether it should cover single-beat scalar,
burst-last scalar, both, or a prerequisite first. It must record generated
artifact expectations, report fields, support-accounting impact, preservation
matrix, rollback, docs/contracts, Knowledge Map impact, and validation gates.

## Preservation Matrix

| Surface | `.196` audit must preserve |
| --- | --- |
| Parser and public `.ppif` grammar | No syntax change in the audit. |
| `.194` mixed response-demux | Mixed response-demux-only reports, completion outputs, request-ID ownership, assertions, and HDL remain unchanged. |
| Existing auto-ID read-data | Existing auto-ID read-data samples and report fields remain unchanged. |
| Existing concrete queue-head read-data | Existing single-beat, last-beat, burst-length, runtime-validation, and multi-beat queue-head samples remain unchanged. |
| Support accounting | No new supported sample in `.196`; existing identities remain stable. |
| mdBook and roadmap | Must state that mixed read-data is under audit and not yet shipped. |

## Non-Goals

- Do not implement mixed read-data consumption in `.196`.
- Do not add new `.ppif` syntax.
- Do not add public PPIF samples in `.196`.
- Do not widen group-local simultaneous enqueue behavior.
- Do not add write-family read-data behavior.
- Do not introduce packed burst-vector outputs or alternate full burst payload
  assembly.
- Do not change direct backend, verification-output, VHDL, or
  backend-language variant behavior.
- Do not bypass the `IAL2 -> IAL1 -> IAL0 -> SystemVerilog` lowering chain.

## Validation Gates

For `.195`, the required gates are documentation and continuity gates:

- regenerate and check the Knowledge Map;
- build the mdBook;
- run the docs relative-path audit;
- run the memory-architecture check;
- run diff hygiene;
- run README live-doc numbering and stale/positive frontier scans.

`.196` may add temporary read single-beat and read burst-last mixed read-data
probes under `/tmp`, but it must remain audit-only unless it selects a later
implementation leaf.

## Rollback Boundary

Rollback for `.195` is limited to this selector record, task-tree frontier
movement, Memory, README, roadmap, mdBook, and Knowledge Map/fact-card updates.
No parser, generator, public sample, support-accounting catalog, generated
artifact, test, or HDL behavior is part of this slice.
