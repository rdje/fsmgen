# AXI IAL2 Manager Multiple Dynamic Read Response-Demux Contract Selection

Task-tree owner: `IAL2-FEATURE-COMPLETENESS-FRONTIER.250`

Date: 2026-06-22

## Decision

Select `IAL2-FEATURE-COMPLETENESS-FRONTIER.251`, direct generated behavior for
bounded multiple dynamic read single-beat response-demux.

The selected public contract reuses existing explicit `response-demux.read`
syntax with `response-scope single-beat`, generated transaction completion,
and two or more read transactions whose IDs are transaction-local dynamic IDs:

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

(response-demux
  (read
    (response-event axi0_read_complete)
    (response-scope single-beat)
    (transaction-completion generated)))
```

This selector changes no parser, generator, PPIF sample, support-accounting
catalog, validation behavior, generated artifact, test, schedule/check or
semantic JSON, or HDL behavior.

## Public Boundary

The first multiple-dynamic read demux implementation owner is intentionally
bounded:

- the selected read family has a positive-width `id-families.read` entry with
  one request ID source, such as `ARID`, and one response ID signal, such as
  `RID`;
- `response-demux.read.response-scope` is `single-beat`;
- `response-demux.read.last-signal` is absent;
- at least two read transactions are present and every read transaction in
  the selected read family uses `(id dynamic)`;
- each dynamic read transaction has a unique request event and a generated
  completion event distinct from the raw read response event;
- `response-demux.read.transaction-completion` is `generated`;
- read-data is absent in the first multiple-dynamic read implementation
  sample; and
- same-family concrete/static read demux, mixed dynamic/static read demux,
  read auto-ID lifecycle, `same-id-ordering.read`, burst-last/`RLAST`
  multiple dynamic read demux, dynamic read-data over multiple dynamic reads,
  queues, scoreboards, and same-cycle release-and-recapture remain deferred.

Unrelated write-family dynamic behavior remains unchanged. Existing
single-active dynamic read single-beat and burst-last samples remain supported
with their current report modes.

## Capture And Ownership Contract

Each dynamic read transaction owns generated selected-ID and busy storage:

```text
<transaction>_dynamic_id_q
<transaction>_dynamic_busy_q
```

The capture point is the admitted read request. A capture is valid only when:

- the transaction's admitted read request is present;
- the transaction is not already busy;
- no sibling dynamic read request is admitted in the same cycle; and
- no busy sibling dynamic read has the same captured ID as the current
  request ID source.

The first implementation keeps the existing no-recapture rule: a transaction
request in the same cycle as its own generated completion remains invalid
because the busy bit is observed before release. Release-and-recapture is a
future exact owner.

## Response Matching Contract

Generated read response-demux rules match the raw accepted single-beat read
response for each transaction:

```text
response_event && dynamic_busy_q && (RID == dynamic_id_q)
```

The public contract prevents ambiguity through generated assertions rather
than queues:

- a raw read response must match at least one active captured dynamic read;
- a raw read response must match at most one active captured dynamic read;
- two busy dynamic read transactions must not hold the same captured ID; and
- a new admitted dynamic read request must not reuse an ID held by an active
  sibling dynamic read transaction.

This makes multiple outstanding single-beat dynamic reads deterministic only
for unique active IDs. Same-ID dynamic reads, response ordering by ID, per-ID
queues, scoreboards, and burst-last `RLAST` ordering remain future work.

## Report Vocabulary

The `.251` implementation should report a new multiple-dynamic read mode while
preserving existing single-active read modes:

```yaml
response_demux:
  mode: bounded_multi_dynamic_read_rid_demux_contract
  generated_behavior: true
  read:
    mode: bounded_multi_dynamic_read_rid_demux_contract
    response_event: axi0_read_complete
    response_event_role: raw_accepted_read_response
    response_scope: single_beat
    response_id_signal: axi0_rid
    response_id_direction: generated_input
    transaction_completion_source: generated_dynamic_demux
    transaction_completion_semantics: matched_dynamic_id_single_beat
    dynamic_transactions: [r0, r1]
    dynamic_capture:
      request_id_source: axi0_arid
      capture_event_source: admitted_dynamic_read_request
      ownership: multi_active_unique_dynamic_read_ids
      simultaneous_request_policy: onehot0_dynamic_read_request
      same_id_conflict_policy: active_dynamic_ids_must_be_unique
      transactions:
        - transaction: r0
          selected_id_signal: axi0_r0_dynamic_id_q
          busy_signal: axi0_r0_dynamic_busy_q
          capture_rule: axi0_r0_dynamic_id_capture
          release_rule: axi0_r0_dynamic_id_release
        - transaction: r1
          selected_id_signal: axi0_r1_dynamic_id_q
          busy_signal: axi0_r1_dynamic_busy_q
          capture_rule: axi0_r1_dynamic_id_capture
          release_rule: axi0_r1_dynamic_id_release
    generated_rules:
      - axi0_r0_response_demux
      - axi0_r1_response_demux
    generated_completion_signals:
      - axi0_r0_complete
      - axi0_r1_complete
```

Generated assertions should include existing per-transaction dynamic
assertions plus multiple-state assertions:

```text
axi0_r0_dynamic_request_not_busy
axi0_r1_dynamic_request_not_busy
axi0_read_dynamic_request_onehot0
axi0_r0_r1_read_dynamic_active_id_unique
axi0_r0_dynamic_request_no_active_same_id
axi0_r1_dynamic_request_no_active_same_id
axi0_read_dynamic_response_active_match
axi0_r0_r1_read_dynamic_response_unique_match
axi0_r0_dynamic_completion_active
axi0_r1_dynamic_completion_active
```

Exact names may follow the local helper naming convention, but the report must
make the active-match, unique-match, active-ID uniqueness, request onehot0, and
no-active-same-ID assertion roles visible.

## Sample And Support Accounting

`.251` should add one support-accounted public PPIF sample, tentatively:

```text
ppif/axi_manager_capacity_status_dynamic_read_response_demux_multi.ppif
```

The sample should keep the shape minimal: two dynamic read transactions,
shared read request/response ID family signals, generated single-beat read
demux completion, no `last-signal`, no `read-data`, no same-ID ordering, no
queues, and no scoreboards.

Focused validation should extend
`t/1438-axi-ial2-manager-dynamic-transaction-id-focused.t` and preserve the
existing `.227` single-active dynamic read sample and `.231` burst-last
single-active dynamic read sample unchanged. Support accounting should cover
strict check JSON and semantic JSON for the new sample.

## Explicit Residue

The `.251` implementation should move only the all-dynamic read-family
multiple-transaction single-beat response-demux-only shape out of dynamic
residue. These remain fail-closed or unshipped:

- multiple dynamic read burst-last/`RLAST` response-demux;
- dynamic read-data over multiple dynamic read response-demux;
- dynamic burst-length/runtime validation over multiple dynamic read demux;
- dynamic multi-beat output banks over multiple dynamic read demux;
- mixed dynamic/static write or read response-demux;
- same-cycle dynamic read request widening beyond onehot0;
- same-cycle release-and-recapture;
- dynamic same-ID ordering;
- dynamic same-ID queues and scoreboards;
- direct backend behavior outside the selected generated SystemVerilog path;
- backend-language variants; and
- VHDL.

## Validation Gates

For this selector, documentation and continuity gates are sufficient:

```bash
bash knowledge-map/scripts/gen_knowledge_map.sh
mdbook build docs/book
bash knowledge-map/scripts/check_knowledge_map.sh
scripts/check_memory_architecture.sh
git --no-pager diff --check
scripts/check_doctrines.sh
```

## Rollback

Rollback is the `.250` selector commit. Reverting it restores `.250` as the
active contract-selection owner and removes the `.251` direct-implementation
selection record.
