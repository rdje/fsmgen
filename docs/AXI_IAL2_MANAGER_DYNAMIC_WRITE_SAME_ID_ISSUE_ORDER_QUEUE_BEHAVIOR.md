# AXI IAL2 Manager Dynamic Write Same-ID Issue-Order Queue Behavior

Task-tree owner: `IAL2-FEATURE-COMPLETENESS-FRONTIER.455`

Date: 2026-06-25

## Outcome

`IAL2-FEATURE-COMPLETENESS-FRONTIER.455` implements the first generated
dynamic same-ID `issue-order-queue` behavior.

The covered public shape is deliberately narrow:

- exactly two write transactions;
- both selected write transactions use `(id dynamic)`;
- `same-id-ordering.write` selects `(dynamic-id-reuse issue-order-queue)`;
- explicit `response-demux.write` owns generated `BID` completions;
- `write-max-pending` is at least `2`;
- write auto-ID lifecycle metadata is absent.

For this shape, FSMGen accepts active dynamic same-ID overlap by generating a
bounded runtime-ID issue-order queue instead of using reject-only active-ID
uniqueness proofs.

## Public Sample

The support-accounted public sample is:

```text
ppif/axi_manager_capacity_status_dynamic_write_same_id_issue_order_queue.ppif
```

The core source shape is:

```lisp
(transactions
  (write w0
    (tag wr0)
    (request axi0_w0_request)
    (completion axi0_w0_complete)
    (id dynamic))
  (write w1
    (tag wr1)
    (request axi0_w1_request)
    (completion axi0_w1_complete)
    (id dynamic)))
(same-id-ordering
  (write (dynamic-id-reuse issue-order-queue)))
(response-demux
  (write
    (response-event axi0_write_complete)
    (transaction-completion generated)))
```

The sample is registered as:

```text
intent.ppif_axi_manager_capacity_status_dynamic_write_same_id_issue_order_queue
```

with coverage bucket:

```text
ial2_ppif_manager_capacity_status_dynamic_write_same_id_issue_order_queue_pipeline_cli
```

It is a strict-supported `supported_smoke` PPIF entry and is covered by check
JSON and semantic JSON support-accounting paths.

## Generated Queue State

The implementation uses the `.454` representation:

```text
queue_state_representation: compact_runtime_id_issue_order_slots
runtime_id_queue_key: captured_request_id
response_demux_strategy: dynamic_issue_order_earliest_matching_slot
first_generated_scope: write_bid_two_dynamic_transactions
```

The generated IAL1 state stores one-hot transaction identity plus one
slot-local captured `AWID` per slot:

```text
axi0_write_dynamic_same_id_issue_order_slot0_w0_q
axi0_write_dynamic_same_id_issue_order_slot0_w1_q
axi0_write_dynamic_same_id_issue_order_slot0_id_q
axi0_write_dynamic_same_id_issue_order_slot1_w0_q
axi0_write_dynamic_same_id_issue_order_slot1_w1_q
axi0_write_dynamic_same_id_issue_order_slot1_id_q
```

The generated input set includes `axi0_awid` and `axi0_bid`. The queue path
does not allocate the legacy per-transaction selected-ID/busy state such as
`axi0_w0_dynamic_id_q` or `axi0_w1_dynamic_busy_q`.

## Response Semantics

Raw `BID` response matching selects the earliest valid queue slot whose
captured runtime ID equals `axi0_bid`:

```text
slot0_raw_match = response_event && slot0_valid && axi0_bid == slot0_id_q
slot1_raw_match = response_event && slot1_valid && axi0_bid == slot1_id_q

slot0_selected_match = slot0_raw_match
slot1_selected_match = slot1_raw_match && !slot0_raw_match
```

If both slots hold the same captured ID, slot0 wins and same-ID order is
preserved. If slot0 holds a different ID and slot1 matches `BID`, slot1 may
complete ahead of slot0. That is the intended AXI per-ID ordering behavior:
same captured IDs are ordered, different captured IDs may complete out of
global issue order.

The generated write response-demux report uses:

```text
mode: bounded_dynamic_write_bid_issue_order_queue_demux_contract
transaction_completion_source: generated_dynamic_issue_order_queue_demux
transaction_completion_semantics: earliest_matching_captured_runtime_id
queue_state_representation: compact_runtime_id_issue_order_slots
runtime_id_queue_key: captured_request_id
response_demux_strategy: dynamic_issue_order_earliest_matching_slot
```

## Queue Transitions

The queue admits at most one selected dynamic write request per cycle:

```text
request_conflict_policy: generated_issue_order_queue_onehot0_enqueue
```

The generated transition rules cover:

- empty enqueue into slot0 with current `axi0_awid` capture;
- enqueue into the tail slot when one entry is already present;
- selected dequeue from either matching slot;
- compaction of retained entries toward slot0;
- same-cycle selected dequeue plus one enqueue;
- release-and-recapture through the queue when the selected-dequeue
  transaction is admitted again in the same cycle;
- clearing an emptied slot's captured-ID register.

The old response match is computed from pre-update slot state. Any same-cycle
enqueue captures the current `AWID` for next-cycle queue state.

## Same-ID Ordering Report

For the covered write family, `same_id_ordering.dynamic_id_reuse_policy.write`
now reports generated behavior:

```yaml
policy: issue_order_queue
implementation_status: generated_dynamic_write_bid_issue_order_queue
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
first_generated_scope: write_bid_two_dynamic_transactions
covered_dynamic_transactions:
  - w0
  - w1
```

Covered transactions report ID matching as:

```text
generated_issue_order_queue_matching
```

The covered same-ID ordering residue is cleared. Future dynamic behavior
residue remains visible for shapes outside this exact owner.

## Assertions

The queue path emits queue-specific assertions rather than reusing
reject-only dynamic same-ID assertions.

Generated queue assertions include:

- slot onehot0 checks for slot0 and slot1;
- compact queue ordering;
- onehot0 admitted write-request policy;
- enqueue requires free space or a same-cycle selected dequeue;
- response requires a nonempty queue;
- response must have a selected captured-ID match;
- selected response match is onehot0;
- selected dequeue requires a nonempty queue;
- each transaction appears in at most one slot;
- an admitted transaction is not already present after selected dequeue;
- each generated transaction completion follows the selected runtime-ID match.

Reject-only `active_dynamic_ids_must_be_unique` evidence remains exclusive to
`dynamic-id-reuse reject` mappings.

## Validation Notes

Focused validation for `.455` passed:

```bash
perl -Iperl -c perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm
perl -Iperl -c t/1436-ial2-ppif-parser-cli.t
perl -Iperl -c t/1437-axi-ial2-manager-capacity-status-generator.t
perl -Iperl -c t/1438-axi-ial2-manager-dynamic-transaction-id-focused.t
perl -Iperl -c t/248-regression-corpus-accounting.t
scripts/run_with_ram_guard.sh -- env -u PERL5LIB prove -Iperl t/248-regression-corpus-accounting.t
scripts/run_with_ram_guard.sh -- env -u PERL5LIB FSMGEN_DYNAMIC_CASE_FILTER=multi_dynamic_read_data FSMGEN_DYNAMIC_SKIP_CLI_JSON=1 prove -Iperl t/1438-axi-ial2-manager-dynamic-transaction-id-focused.t
scripts/run_with_ram_guard.sh -- env -u PERL5LIB ./bin/fsmgen --emit-schedule-json ppif/axi_manager_capacity_status_dynamic_write_same_id_issue_order_queue.ppif
```

Earlier direct adapter/report, strict check JSON, semantic JSON, and
generated-SystemVerilog inspection confirmed the new queue report fields,
support accounting, queue storage, generated update rules, assertions, `AWID`
capture, `BID` inputs, and slot-ID declarations.

Several broad or slow validation attempts are recorded as caveats rather than
passes:

- a guarded closeout rerun of strict check JSON hit the descendant RSS cutoff
  and was terminated by `scripts/run_with_ram_guard.sh`; no unguarded retry
  was run, and the semantic JSON closeout rerun was skipped after that cutoff;
- filtered `t/1438` runs for `multi_static3` and
  `dynamic_write_same_id_issue_order_queue` were stopped after taking too
  long;
- an accidental broad `t/1437` probe reached and passed the new subtest before
  the overall test file was stopped later, so the full file is not claimed as
  passed;
- a `--verify-hdl --output /tmp/...` generation attempt wrote inspectable
  SystemVerilog and exited cleanly after interruption, but external HDL
  validation is not claimed for this slice.

## Non-Goals

This slice does not implement:

- dynamic read `RID` or read burst-last `RID && RLAST` issue-order queues;
- read-data, raw-`ARLEN`, runtime beat-count, or multi-beat output-bank
  behavior over dynamic issue-order queues;
- more than two dynamic write transactions;
- mixed dynamic/static dynamic issue-order queues;
- dynamic `scoreboard`;
- generalized per-runtime-ID maps, scoreboards, modulo pointers, or unbounded
  allocation;
- direct backend behavior, backend-language variants, or VHDL behavior.

Unsupported shapes remain fail-closed or remain selected-not-generated
metadata according to their existing owners.

## Next Slice

`.455` selects `IAL2-FEATURE-COMPLETENESS-FRONTIER.456`, the post dynamic
write same-ID issue-order queue selector. That selector should choose the next
exact owner after reading this shipped behavior, validation caveats, remaining
residue, and the dynamic read, broader write, mixed/static, scoreboard,
direct-backend, backend-language, and VHDL deferrals.
