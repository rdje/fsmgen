# AXI IAL2 Manager Mixed Auto-ID Queue-Head Response-Demux Readiness Audit

Status: readiness audit for `IAL2-FEATURE-COMPLETENESS-FRONTIER.193` on
2026-06-21.

Selected next owner:
`IAL2-FEATURE-COMPLETENESS-FRONTIER.194`.

## Decision

Select `.194`, direct bounded implementation of same-family mixed auto-ID
lifecycle plus concrete same-ID queue-head response-demux for response-demux
only.

No parser, grammar, lower-layer IAL1/IAL0/SystemVerilog prerequisite is needed
before implementation. The blocker is local to AXI manager capacity/status
response-demux normalization and generated response-demux state/report/assertion
ownership.

## Probes

Three temporary PPIF probes were created under `/tmp`:

```text
/tmp/fsmgen_ial2_193_read_single_mixed_auto_queue_head.ppif
/tmp/fsmgen_ial2_193_read_burst_mixed_auto_queue_head.ppif
/tmp/fsmgen_ial2_193_write_mixed_auto_queue_head.ppif
```

Each probe combines one auto-ID transaction set with one duplicate concrete-ID
issue-order-queue group in the same response-demux family.

All three fail closed at the current local diagnostic:

```text
AXI manager capacity/status IAL2 contract response_demux.<family> does not support same-family auto_id_lifecycle plus concrete same-ID queue-head demux in this slice
```

The adjacent shipped samples still strict-check cleanly:

```text
./bin/fsmgen --strict --check --json ppif/axi_manager_capacity_status_read_response_demux.ppif
./bin/fsmgen --strict --check --json ppif/axi_manager_capacity_status_read_single_beat_same_id_queue_head_response_demux.ppif
./bin/fsmgen --strict --check --json ppif/axi_manager_capacity_status_write_same_id_queue_head_response_demux.ppif
./bin/fsmgen --strict --check --json ppif/axi_manager_capacity_status_response_demux.ppif
```

## Code Findings

The fail-closed boundary is explicit in
`_response_demux_queue_head_plan_for_family`: when an issue-order-queue policy
and a duplicate concrete-ID group are present, the planner rejects the family
if it also has auto-ID lifecycle transactions.

The downstream generated behavior is already split into reusable pieces:

- auto-ID lifecycle state and request-ID drive are generated independently;
- concrete same-ID admitted-request pulses are generated independently;
- concrete queue-head queue state and completion pulse generation are
  transaction-list driven for bounded depth-2/depth-3 read single-beat, read
  burst-last, and write groups;
- response-demux rules are generated from
  `_response_demux_transaction_states_for_family`;
- report artifacts are generated from the same response-demux state and
  assertion helpers.

The current remaining exclusivity is also local:

- `_normalize_response_demux_write` and `_normalize_response_demux_read` return
  either an auto-ID response-demux contract or a queue-head selected contract;
- `_response_demux_with_same_id_issue_order_queue_behavior` currently promotes
  only selected queue-head completion signals into generated completion
  signals;
- `_response_demux_transaction_states_for_family` returns queue-head states
  before auto-ID states, so a mixed generated family would currently drop the
  auto-ID response-demux states;
- `_response_demux_assertion_specs_for_family` chooses queue-head-only
  assertion antecedents/messages when any queue-head state is present.

Those are implementation details inside the IAL2 AXI manager generator. They do
not require new `.ppif` syntax or lower-layer scheduler features.

## Selected `.194` Implementation Boundary

`.194` should implement a bounded same-family mixed response-demux contract for
response-demux-only shapes:

- one selected response-demux family at a time;
- at least one auto-ID lifecycle transaction in that family;
- at least one duplicate concrete-ID issue-order-queue group in that family;
- generated completion outputs for both auto-ID transactions and concrete
  queue-head transactions;
- read single-beat, read burst-last, and write families, because the same
  normalizer/state/report path owns all three and the probes fail at the same
  local boundary.

The implementation should add public support-accounted PPIF samples for the
three probe families and focused generator/PPIF assertions for:

- combined response-demux report mode and generated behavior;
- preserved `auto_transactions`;
- preserved `same_id_issue_order_queues`;
- generated completion signals for both auto-ID and queue-head transactions;
- generated response-demux rules for both auto-ID and queue-head states;
- active/unique-match assertions over the combined state set;
- empty or expected residue in response-demux, auto-ID lifecycle, same-ID
  ordering, and ID/response reports.

## Required Implementation Shape

The direct implementation should:

1. Normalize a mixed family as a combined response-demux family rather than
   choosing auto-ID or queue-head exclusively.
2. Preserve the existing generated auto-ID lifecycle behavior.
3. Build concrete same-ID queue-head behavior from the same selected queue
   metadata.
4. Promote generated completion signals for both auto-ID transactions and
   queue-head transactions.
5. Merge auto-ID response-demux states and queue-head response-demux states in
   the generated rule/artifact/assertion path.
6. Use assertion antecedents/messages that remain correct for mixed state sets:
   auto-ID responses still use the raw accepted response event, while
   queue-head-specific nonempty/head assertions remain owned by the queue
   behavior.

## Non-Goals

- Do not add new `.ppif` syntax.
- Do not add read-data consumption for mixed auto-ID plus concrete queue-head
  response-demux in `.194`.
- Do not widen group-local simultaneous enqueue behavior.
- Do not introduce packed burst-vector outputs or alternate full burst payload
  assembly.
- Do not change direct backend, verification-output, VHDL, or backend-language
  variant behavior.
- Do not bypass the `IAL2 -> IAL1 -> IAL0 -> SystemVerilog` lowering chain.

## Validation Gates

The `.194` implementation should run focused syntax checks, direct
schedule/check/semantic/HDL probes for the three new public samples, focused
generator and PPIF/CLI suites, support-accounting corpus gates, Knowledge Map,
mdBook, docs path audit, memory architecture, diff hygiene, README numbering,
and stale/positive frontier scans.

## Rollback Boundary

Rollback for `.193` is limited to this audit document, task-tree frontier
movement, README, roadmap, mdBook, Memory, and Knowledge Map/fact-card updates.
No parser, generator, sample, support-accounting catalog, generated artifact,
test, or HDL behavior changes in this audit slice.
