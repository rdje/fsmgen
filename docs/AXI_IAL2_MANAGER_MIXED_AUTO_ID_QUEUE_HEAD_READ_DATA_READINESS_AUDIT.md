# AXI IAL2 Manager Mixed Auto-ID Queue-Head Read-Data Readiness Audit

Status: readiness audit for `IAL2-FEATURE-COMPLETENESS-FRONTIER.196` on
2026-06-21.

Selected next owner:
`IAL2-FEATURE-COMPLETENESS-FRONTIER.197`.

## Decision

Select `.197`, direct bounded implementation of scalar read-data consumption
over same-family mixed auto-ID lifecycle plus concrete same-ID queue-head
response-demux.

The selected implementation should cover the two scalar read families that
already have `.194` response-demux-only mixed behavior:

- read single-beat scalar `RDATA`/`RRESP`;
- read burst-last scalar last-beat `RDATA`/`RRESP`.

No parser, grammar, lower-layer IAL1/IAL0/SystemVerilog prerequisite is needed
before implementation. The blocker is local to AXI manager capacity/status
read-data transaction coverage over the mixed response-demux source.

## Probes

Two temporary PPIF probes were created under `/tmp`:

```text
/tmp/fsmgen_196_mixed_read_single.ppif
/tmp/fsmgen_196_mixed_read_burst_last.ppif
```

Both probes add existing `read-data` syntax to the `.194` mixed read
response-demux-only shapes. The single-beat probe binds scalar
`RDATA`/`RRESP` outputs for `r0`, `r1`, and `r2`; the burst-last probe binds
scalar last-beat `RDATA`/`RRESP` outputs for the same transactions.

Both fail closed at the same local diagnostic:

```text
AXI manager capacity/status IAL2 contract read_data.read transaction 'r1' is not covered by generated read response_demux auto transactions
```

Adjacent preservation probes strict-check cleanly:

```text
./bin/fsmgen --strict --check --json ppif/axi_manager_capacity_status_read_single_beat_mixed_auto_id_same_id_queue_head_response_demux.ppif
./bin/fsmgen --strict --check --json ppif/axi_manager_capacity_status_read_burst_last_mixed_auto_id_same_id_queue_head_response_demux.ppif
./bin/fsmgen --strict --check --json ppif/axi_manager_capacity_status_read_data.ppif
./bin/fsmgen --strict --check --json ppif/axi_manager_capacity_status_read_single_beat_same_id_queue_head_read_data.ppif
```

## Code Findings

The fail-closed boundary is explicit in
`_read_data_response_demux_transaction_coverage`.

For `transaction_completion_source == generated_queue_head_demux`, the helper
consumes `same_id_issue_order_queues`, validates queue-head boundaries, and
returns queue-head transaction coverage plus queue-head completion validity.

For any other generated read response-demux source, the helper consumes only
`auto_transactions`. The `.194` mixed source is
`generated_demux_and_queue_head_demux`, so the current fallback sees only the
auto-ID transaction `r0` and rejects concrete queue-head transactions `r1` and
`r2` when they appear in `read-data` bindings.

The downstream scalar read-data path is otherwise ready once coverage admits
the mixed transaction set:

- `_normalize_read_data_read` builds one normalized transaction per covered
  binding and uses the coverage completion signal for each transaction.
- `_read_data_capture_rule_lines` emits scalar capture rules directly from the
  normalized transaction `completion_signal`, `data_output`, and
  `status_output`.
- The read-data generated-artifact and report helpers iterate the normalized
  transaction list.
- The `.194` response-demux behavior already produces combined completion
  signals for auto-ID and concrete queue-head transactions, with `RLAST`
  already included in burst-last completion pulses.

This means the first behavior slice can stay local to read-data coverage
admission and public sample/test/report/docs surfaces. It does not need new
PPIF syntax or lower-layer scheduler features.

## Selected `.197` Implementation Boundary

`.197` should implement bounded mixed scalar read-data consumption for:

- one selected read family at a time;
- one same-family auto-ID lifecycle transaction;
- one concrete duplicate-ID issue-order-queue group of two read transactions;
- existing `response-demux` syntax with
  `transaction_completion_source: generated_demux_and_queue_head_demux`;
- existing `read-data` syntax with `completion-source response-demux`;
- `capture-scope single-beat` with `interleaving single-beat-by-rid`;
- `capture-scope last-beat` with `status-policy last-beat` and
  `interleaving last-beat-by-rid`.

The implementation should add public support-accounted PPIF samples for the
two temporary probes and focused expectations for:

- read-data report mode and generated behavior;
- generated `RDATA` and `RRESP` inputs;
- per-transaction scalar data/status outputs for both auto-ID and concrete
  queue-head transactions;
- capture rules driven by the combined generated completion signals;
- correct single-beat and burst-last completion validity strings;
- preserved mixed response-demux report mode/source/completion signals;
- empty or expected `read_data`, `response_demux`, `auto_id_lifecycle`,
  `same_id_ordering`, and ID/response residue.

## Non-Goals

- Do not add new `.ppif` syntax.
- Do not implement mixed multi-beat output-bank behavior.
- Do not add burst-length capture or runtime beat-count/`RLAST` validation for
  mixed families.
- Do not widen group-local simultaneous enqueue behavior.
- Do not add write-family read-data behavior.
- Do not introduce packed burst-vector outputs or alternate full burst payload
  assembly.
- Do not change direct backend, verification-output, VHDL, or
  backend-language variant behavior.
- Do not bypass the `IAL2 -> IAL1 -> IAL0 -> SystemVerilog` lowering chain.

## Validation Gates

The `.197` implementation should run focused Perl syntax checks, direct
strict-check/schedule/semantic/HDL probes for the two new public samples,
focused generator and PPIF/CLI expectations, support-accounting corpus gates,
Knowledge Map, mdBook, docs path audit, memory architecture, diff hygiene,
README numbering, and stale/positive frontier scans.

## Rollback Boundary

Rollback for `.196` is limited to this audit document, task-tree frontier
movement, README, roadmap, mdBook, Memory, and Knowledge Map/fact-card updates.
No parser, generator, public sample, support-accounting catalog, generated
artifact, test, or HDL behavior changes in this audit slice.
