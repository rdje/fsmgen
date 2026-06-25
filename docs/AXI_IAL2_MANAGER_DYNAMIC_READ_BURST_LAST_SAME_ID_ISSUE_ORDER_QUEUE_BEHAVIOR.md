# AXI IAL2 Manager Dynamic Read Burst-Last Same-ID Issue-Order Queue Behavior

Task-tree owner: `IAL2-FEATURE-COMPLETENESS-FRONTIER.463`

Date: 2026-06-25

## Outcome

`IAL2-FEATURE-COMPLETENESS-FRONTIER.463` implements generated dynamic read
same-ID `issue-order-queue` behavior for the first burst-last `RID && RLAST`
shape.

The covered public shape is deliberately narrow:

- exactly two read transactions;
- both selected read transactions use `(id dynamic)`;
- `same-id-ordering.read` selects `(dynamic-id-reuse issue-order-queue)`;
- explicit `response-demux.read` owns generated burst-last response
  completions;
- `response-demux.read.response-scope` is `burst-last`;
- `response-demux.read.last-signal` is present and one bit wide;
- `read-max-pending` is at least `2`;
- read auto-ID lifecycle metadata, read-data over generated dynamic read
  queues, raw `ARLEN`, runtime beat-count validation, multi-beat output banks,
  broader queue cardinality, mixed dynamic/static read queues, scoreboards,
  direct backend behavior, backend-language variants, and VHDL are outside
  this owner.

For this shape, FSMGen accepts active dynamic same-ID overlap by generating a
bounded runtime-ID issue-order queue. Raw read response beats may match a
captured runtime ID without completing the transaction; the queue completes and
dequeues only on the selected earliest captured runtime-ID match plus `RLAST`.

## Public Sample

The support-accounted public sample is:

```text
ppif/axi_manager_capacity_status_dynamic_read_burst_last_same_id_issue_order_queue.ppif
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
    (response-scope burst-last)
    (last-signal axi0_rlast (width 1))
    (transaction-completion generated)))
```

The read ID-family metadata supplies the runtime request and response IDs:

```lisp
(id-families
  (read (width 4) (request-id axi0_arid) (response-id axi0_rid)))
```

The sample is registered as:

```text
intent.ppif_axi_manager_capacity_status_dynamic_read_burst_last_same_id_issue_order_queue
```

with coverage bucket:

```text
ial2_ppif_manager_capacity_status_dynamic_read_burst_last_same_id_issue_order_queue_pipeline_cli
```

It is a strict-supported `supported_smoke` PPIF entry.

## Generated Queue State

The implementation uses the compact runtime-ID slot representation:

```text
queue_state_representation: compact_runtime_id_issue_order_slots
runtime_id_queue_key: captured_request_id
response_demux_strategy: dynamic_issue_order_earliest_matching_slot
first_generated_scope: read_rid_rlast_two_dynamic_transactions
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

The generated input set includes `axi0_arid`, `axi0_rid`, and `axi0_rlast`.
The queue path does not allocate the legacy per-transaction selected-ID/busy
state such as `axi0_r0_dynamic_id_q` or `axi0_r1_dynamic_busy_q`.

## Response Semantics

Raw `RID` response matching selects the earliest valid queue slot whose
captured runtime ID equals `axi0_rid`:

```text
slot0_raw_match = response_event && slot0_valid && axi0_rid == slot0_id_q
slot1_raw_match = response_event && slot1_valid && axi0_rid == slot1_id_q

slot0_selected_match = slot0_raw_match
slot1_selected_match = slot1_raw_match && !slot0_raw_match
```

`RLAST` is deliberately not part of raw matching. Non-final matching beats are
valid for assertions and response ownership checks, but they do not generate a
transaction completion and do not dequeue a queue slot.

Final selected matching adds `axi0_rlast`:

```text
slotN_final_selected_match = slotN_selected_match && axi0_rlast
```

If both slots hold the same captured ID, slot0 wins and same-ID order is
preserved. If slot0 holds a different ID and slot1 matches `RID`, slot1 may
complete ahead of slot0 on its final beat. That is the intended AXI per-ID
ordering behavior: same captured IDs are ordered, different captured IDs may
complete out of global issue order.

The generated read response-demux report uses:

```text
mode: bounded_dynamic_read_rid_rlast_issue_order_queue_demux_contract
response_event_role: raw_accepted_read_response_beat
response_scope: burst_last
last_signal: axi0_rlast
last_signal_width: 1
transaction_completion_source: generated_dynamic_issue_order_queue_demux_last_beat
transaction_completion_semantics: earliest_matching_captured_runtime_id_and_last_signal
beat_valid_output: none
burst_length_source: rlast_only
burst_length_validation: not_generated
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
- selected final dequeue from either matching slot only when `axi0_rlast` is
  high;
- no dequeue on matching non-final response beats;
- compaction of retained entries toward slot0;
- same-cycle selected final dequeue plus one enqueue;
- release-and-recapture through the queue when the selected-dequeue
  transaction is admitted again in the same cycle;
- clearing an emptied slot's captured-ID register.

The old response match is computed from pre-update slot state. Any same-cycle
enqueue captures the current `ARID` for next-cycle queue state.

## Same-ID Ordering Report

For the covered read family, `same_id_ordering.dynamic_id_reuse_policy.read`
reports generated behavior:

```yaml
policy: issue_order_queue
implementation_status: generated_dynamic_read_rid_rlast_issue_order_queue
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
first_generated_scope: read_rid_rlast_two_dynamic_transactions
response_demux_transaction_completion_source: generated_dynamic_issue_order_queue_demux_last_beat
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
- enqueue requires free space or a same-cycle selected final dequeue;
- response requires a nonempty queue;
- raw response must have a selected captured-ID match;
- selected raw response match is onehot0;
- selected final dequeue requires a nonempty queue;
- a matching non-final beat does not dequeue;
- each transaction appears in at most one slot;
- an admitted transaction is not already present after selected final dequeue;
- each generated transaction completion follows the selected runtime-ID match
  plus `RLAST`.

Reject-only `active_dynamic_ids_must_be_unique` evidence remains exclusive to
`dynamic-id-reuse reject` mappings and non-queue demux shapes that intentionally
require unique active dynamic IDs.

## Validation Notes

Focused validation for `.463` passed for syntax, support accounting, and the
direct guarded schedule/report probe:

```bash
perl -Iperl -c perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm
perl -Iperl -c perl/FSM/Support/RegressionCorpus.pm
perl -Iperl -c t/1436-ial2-ppif-parser-cli.t
perl -Iperl -c t/1437-axi-ial2-manager-capacity-status-generator.t
perl -Iperl -c t/1438-axi-ial2-manager-dynamic-transaction-id-focused.t
perl -Iperl -c t/248-regression-corpus-accounting.t
scripts/run_with_ram_guard.sh -- env -u PERL5LIB prove -Iperl t/248-regression-corpus-accounting.t
scripts/run_with_ram_guard.sh -- env -u PERL5LIB ./bin/fsmgen --emit-schedule-json ppif/axi_manager_capacity_status_dynamic_read_burst_last_same_id_issue_order_queue.ppif
```

The direct report path must confirm
`bounded_dynamic_read_rid_rlast_issue_order_queue_demux_contract`,
`generated_dynamic_read_rid_rlast_issue_order_queue`,
`read_rid_rlast_two_dynamic_transactions`,
`generated_dynamic_issue_order_queue_demux_last_beat`,
`earliest_matching_captured_runtime_id_and_last_signal`,
`axi0_read_dynamic_same_id_issue_order_nonlast_no_dequeue`, and the
support-accounting ID
`intent.ppif_axi_manager_capacity_status_dynamic_read_burst_last_same_id_issue_order_queue`.

Guarded focused `t/1438`, strict check JSON, and semantic JSON closeout probes
were stopped by the RAM guard when host memory exceeded the 88% cutoff. Broad
`t/1436`, `t/1437`, `t/1438`, strict/semantic closeout, HDL validation, direct
backend behavior, backend-language variants, and VHDL are not claimed for this
slice.

## Rollback

Rollback removes only this exact owner:

- the public PPIF sample and its support-accounting entry;
- parser/CLI/generator/focused expectations for the burst-last dynamic read
  queue sample;
- dynamic issue-order queue handling for the
  `generated_dynamic_issue_order_queue_demux_last_beat` completion source;
- RLAST-gated selected final queue dequeue/completion and non-final
  no-dequeue assertions;
- the `.463` docs, fact card, roadmap/book/task-tree/memory entries.

The existing dynamic write queue, dynamic read single-beat queue, dynamic
reject mappings, dynamic response-demux/read-data behavior, concrete queue-head
behavior, and metadata-only dynamic issue-order queue behavior remain intact.
