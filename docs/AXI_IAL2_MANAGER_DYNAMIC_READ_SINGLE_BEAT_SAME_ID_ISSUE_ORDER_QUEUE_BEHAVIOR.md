# AXI IAL2 Manager Dynamic Read Single-Beat Same-ID Issue-Order Queue Behavior

Task-tree owner: `IAL2-FEATURE-COMPLETENESS-FRONTIER.459`

Date: 2026-06-25

## Outcome

`IAL2-FEATURE-COMPLETENESS-FRONTIER.459` implements the first generated
dynamic read same-ID `issue-order-queue` behavior.

The covered public shape is deliberately narrow:

- exactly two read transactions;
- both selected read transactions use `(id dynamic)`;
- `same-id-ordering.read` selects `(dynamic-id-reuse issue-order-queue)`;
- explicit `response-demux.read` owns generated single-beat `RID`
  completions;
- `response-demux.read.response-scope` is `single-beat`;
- `read-max-pending` is at least `2`;
- read auto-ID lifecycle metadata, read burst-last `RID && RLAST`, read-data,
  raw `ARLEN`, runtime beat-count validation, multi-beat output banks, mixed
  dynamic/static read queues, broader queue cardinality, scoreboards, direct
  backend behavior, backend-language variants, and VHDL are outside this
  owner.

For this shape, FSMGen accepts active dynamic same-ID overlap by generating a
bounded runtime-ID issue-order queue instead of using reject-only active-ID
uniqueness proofs.

## Public Sample

The support-accounted public sample is:

```text
ppif/axi_manager_capacity_status_dynamic_read_same_id_issue_order_queue.ppif
```

The core source shape is:

```lisp
(transactions
  (read r0
    (tag rd0)
    (request axi0_r0_request)
    (completion axi0_r0_complete)
    (id dynamic))
  (read r1
    (tag rd1)
    (request axi0_r1_request)
    (completion axi0_r1_complete)
    (id dynamic)))
(same-id-ordering
  (read (dynamic-id-reuse issue-order-queue)))
(response-demux
  (read
    (response-event axi0_read_complete)
    (response-scope single-beat)
    (transaction-completion generated)))
```

The read ID-family metadata supplies the runtime request and response IDs:

```lisp
(id-families
  (read (width 4) (request-id axi0_arid) (response-id axi0_rid)))
```

The sample is registered as:

```text
intent.ppif_axi_manager_capacity_status_dynamic_read_same_id_issue_order_queue
```

with coverage bucket:

```text
ial2_ppif_manager_capacity_status_dynamic_read_same_id_issue_order_queue_pipeline_cli
```

It is a strict-supported `supported_smoke` PPIF entry.

## Generated Queue State

The implementation uses the compact runtime-ID slot representation:

```text
queue_state_representation: compact_runtime_id_issue_order_slots
runtime_id_queue_key: captured_request_id
response_demux_strategy: dynamic_issue_order_earliest_matching_slot
first_generated_scope: read_rid_two_dynamic_transactions
```

The generated IAL1 state stores one-hot transaction identity plus one
slot-local captured `ARID` per slot:

```text
axi0_read_dynamic_same_id_issue_order_slot0_r0_q
axi0_read_dynamic_same_id_issue_order_slot0_r1_q
axi0_read_dynamic_same_id_issue_order_slot0_id_q
axi0_read_dynamic_same_id_issue_order_slot1_r0_q
axi0_read_dynamic_same_id_issue_order_slot1_r1_q
axi0_read_dynamic_same_id_issue_order_slot1_id_q
```

The generated input set includes `axi0_arid` and `axi0_rid`. The queue path
does not allocate the legacy per-transaction selected-ID/busy state such as
`axi0_r0_dynamic_id_q` or `axi0_r1_dynamic_busy_q`.

## Response Semantics

Raw `RID` response matching selects the earliest valid queue slot whose
captured runtime ID equals `axi0_rid`:

```text
slot0_raw_match = response_event && slot0_valid && axi0_rid == slot0_id_q
slot1_raw_match = response_event && slot1_valid && axi0_rid == slot1_id_q

slot0_selected_match = slot0_raw_match
slot1_selected_match = slot1_raw_match && !slot0_raw_match
```

If both slots hold the same captured ID, slot0 wins and same-ID order is
preserved. If slot0 holds a different ID and slot1 matches `RID`, slot1 may
complete ahead of slot0. That is the intended AXI per-ID ordering behavior:
same captured IDs are ordered, different captured IDs may complete out of
global issue order.

The generated read response-demux report uses:

```text
mode: bounded_dynamic_read_rid_issue_order_queue_demux_contract
response_scope: single_beat
transaction_completion_source: generated_dynamic_issue_order_queue_demux
transaction_completion_semantics: earliest_matching_captured_runtime_id
queue_state_representation: compact_runtime_id_issue_order_slots
runtime_id_queue_key: captured_request_id
response_demux_strategy: dynamic_issue_order_earliest_matching_slot
```

## Queue Transitions

The queue admits at most one selected dynamic read request per cycle:

```text
request_conflict_policy: generated_issue_order_queue_onehot0_enqueue
```

The generated transition rules cover:

- empty enqueue into slot0 with current `axi0_arid` capture;
- enqueue into the tail slot when one entry is already present;
- selected dequeue from either matching slot;
- compaction of retained entries toward slot0;
- same-cycle selected dequeue plus one enqueue;
- release-and-recapture through the queue when the selected-dequeue
  transaction is admitted again in the same cycle;
- clearing an emptied slot's captured-ID register.

The old response match is computed from pre-update slot state. Any same-cycle
enqueue captures the current `ARID` for next-cycle queue state.

## Same-ID Ordering Report

For the covered read family, `same_id_ordering.dynamic_id_reuse_policy.read`
now reports generated behavior:

```yaml
policy: issue_order_queue
implementation_status: generated_dynamic_read_rid_issue_order_queue
enforcement: generated_dynamic_issue_order_queue
accepted_same_id_reuse: true
generated_queue_behavior: true
generated_scoreboard_behavior: false
response_demux_covered: true
dynamic_issue_order_queue_covered: true
queue_state_representation: compact_runtime_id_issue_order_slots
runtime_id_queue_key: captured_request_id
response_demux_strategy: dynamic_issue_order_earliest_matching_slot
same_id_overlap_policy: allowed_by_issue_order_queue
multi_match_policy: earliest_matching_slot
active_id_uniqueness_policy: not_required_for_issue_order_queue
first_generated_scope: read_rid_two_dynamic_transactions
covered_dynamic_transactions:
  - r0
  - r1
```

Covered transactions report ID matching as:

```text
generated_issue_order_queue_matching
```

The covered same-ID ordering residue is cleared. `response_demux.residue`
continues to expose `read_data_interleaving` and `bursts`; future dynamic
behavior residue remains visible for shapes outside this exact owner.

## Assertions

The queue path emits queue-specific assertions rather than reusing
reject-only dynamic same-ID assertions.

Generated queue assertions include:

- slot onehot0 checks for slot0 and slot1;
- compact queue ordering;
- onehot0 admitted read-request policy;
- enqueue requires free space or a same-cycle selected dequeue;
- response requires a nonempty queue;
- response must have a selected captured-ID match;
- selected response match is onehot0;
- selected dequeue requires a nonempty queue;
- each transaction appears in at most one slot;
- an admitted transaction is not already present after selected dequeue;
- each generated transaction completion follows the selected runtime-ID match.

Reject-only `active_dynamic_ids_must_be_unique` evidence remains exclusive to
`dynamic-id-reuse reject` mappings and non-queue demux shapes that intentionally
require unique active dynamic IDs.

## Validation Notes

Focused validation for `.459` passed:

```bash
perl -Iperl -c perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm
perl -Iperl -c perl/FSM/Support/RegressionCorpus.pm
perl -Iperl -c t/1436-ial2-ppif-parser-cli.t
perl -Iperl -c t/1437-axi-ial2-manager-capacity-status-generator.t
perl -Iperl -c t/1438-axi-ial2-manager-dynamic-transaction-id-focused.t
perl -Iperl -c t/248-regression-corpus-accounting.t
scripts/run_with_ram_guard.sh -- env -u PERL5LIB prove -Iperl t/248-regression-corpus-accounting.t
scripts/run_with_ram_guard.sh --host-max-pct 96 -- env -u PERL5LIB perl -Iperl -MFSM::Adapter::IAL2::PPIF ...
```

The direct guarded adapter/report probe confirmed
`bounded_dynamic_read_rid_issue_order_queue_demux_contract`,
`generated_dynamic_read_rid_issue_order_queue`,
`read_rid_two_dynamic_transactions`, `compact_runtime_id_issue_order_slots`,
slot-local `ARID` storage, `RID` matching, generated completion signals,
queue update rules, and generated queue assertions.

The direct guarded ISF/FSM/report probe confirmed the public sample emits
`axi0_arid`, `axi0_rid`, generated `r0`/`r1` completion outputs, no legacy
dynamic selected-ID/busy state, slot-local `ARID` capture, same-cycle selected
dequeue plus enqueue, earliest matching `RID` response-demux rules, and the
expected report vocabulary.

Several broader or heavier validation attempts are recorded as caveats rather
than passes:

- a filtered `t/1438` run for
  `dynamic_read_same_id_issue_order_queue` was stopped by the RAM guard at
  the default host-memory cutoff before reporting a test failure;
- guarded CLI `--strict --check --json` probes for the new read queue and the
  existing write queue both exceeded the default process RSS cap on this host,
  showing the memory profile is not read-queue-specific; no unguarded retry was
  run;
- a direct HDL lowering probe for the read queue exceeded the current host
  memory cutoff, so HDL lowering is not claimed as revalidated in this slice;
- full `t/1436`, `t/1437`, and `t/1438` execution was not claimed under the
  current host memory pressure.

## Next Boundary

`.459` selects `IAL2-FEATURE-COMPLETENESS-FRONTIER.460`, a post dynamic read
single-beat same-ID issue-order queue selector. That selector should choose
between read burst-last queue readiness, read-data over generated dynamic read
queues, broader dynamic queue cardinality, mixed dynamic/static queues,
dynamic scoreboards, validation/memory follow-up, direct backend behavior,
backend-language variants, and VHDL without changing behavior itself.
