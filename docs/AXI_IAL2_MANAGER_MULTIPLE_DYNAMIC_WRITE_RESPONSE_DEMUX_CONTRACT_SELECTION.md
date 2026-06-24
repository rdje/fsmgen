# AXI IAL2 Manager Multiple Dynamic Write Response-Demux Contract Selection

Task-tree owner: `IAL2-FEATURE-COMPLETENESS-FRONTIER.246`

Date: 2026-06-22

## Decision

Select `IAL2-FEATURE-COMPLETENESS-FRONTIER.247`, direct generated behavior for
bounded multiple dynamic write response-demux.

The selected public contract reuses the existing explicit
`response-demux.write` syntax with generated transaction completion and two or
more write transactions whose IDs are transaction-local dynamic IDs:

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

(response-demux
  (write
    (response-event axi0_write_complete)
    (transaction-completion generated)))
```

This selector changes no parser, generator, PPIF sample, support-accounting
catalog, validation behavior, generated artifact, test, schedule/check or
semantic JSON, or HDL behavior.

## Public Boundary

The first multiple-dynamic write demux implementation owner is intentionally
bounded:

- the selected write family has a positive-width `id-families.write` entry
  with one request ID source, such as `AWID`, and one response ID signal, such
  as `BID`;
- at least two write transactions are present and every write transaction in
  the selected write family uses `(id dynamic)`;
- each dynamic write transaction has a unique request event and a generated
  completion event distinct from the raw write response event;
- `response-demux.write.transaction-completion` is `generated`;
- same-cycle dynamic write requests are mutually exclusive in the first
  implementation slice, even when their request IDs differ;
- active captured dynamic write IDs must be pairwise unique; and
- same-family concrete/static write demux, mixed dynamic/static write demux,
  write auto-ID lifecycle, `same-id-ordering.write`, queues, scoreboards, and
  same-cycle release-and-recapture remain deferred.

Unrelated read-family dynamic ID metadata remains metadata-only when no
read-family behavior clause consumes it, but the public `.247` sample should
keep the write shape minimal.

## Capture And Ownership Contract

Each dynamic write transaction owns generated selected-ID and busy storage:

```text
<transaction>_dynamic_id_q
<transaction>_dynamic_busy_q
```

The capture point remains the admitted write request. A capture is valid only
when:

- the transaction's admitted write request is present;
- the transaction is not already busy;
- no sibling dynamic write request is admitted in the same cycle; and
- no busy sibling dynamic write has the same captured ID as the current
  request ID source.

The first implementation should keep the existing no-recapture rule: a
transaction request in the same cycle as its own generated completion is still
invalid because the busy bit is observed before release. A later owner may
select release-and-recapture semantics after queue or scoreboard behavior is
explicit.

## Response Matching Contract

Generated write response-demux rules keep the existing dynamic match form for
each transaction:

```text
response_event && dynamic_busy_q && (BID == dynamic_id_q)
```

The public contract prevents ambiguity through generated assertions rather
than queues:

- a raw write response must match at least one active captured dynamic write;
- a raw write response must match at most one active captured dynamic write;
- two busy dynamic write transactions must not hold the same captured ID; and
- a new admitted dynamic write request must not reuse an ID held by an active
  sibling dynamic write transaction.

This makes multiple outstanding dynamic write transactions deterministic only
for unique active IDs. Same-ID dynamic writes, response ordering by ID,
per-ID queues, and scoreboards remain future work.

## Report Vocabulary

The `.247` implementation should report a new multiple-dynamic mode while
preserving the existing single-active mode for the `.223` public sample:

```yaml
response_demux:
  mode: bounded_multi_dynamic_write_bid_demux_contract
  generated_behavior: true
  write:
    mode: bounded_multi_dynamic_write_bid_demux_contract
    response_event: axi0_write_complete
    response_event_role: raw_accepted_write_response
    response_id_signal: axi0_bid
    response_id_direction: generated_input
    transaction_completion_source: generated_dynamic_demux
    transaction_completion_semantics: matched_dynamic_id
    dynamic_transactions: [w0, w1]
    dynamic_capture:
      request_id_source: axi0_awid
      capture_event_source: admitted_dynamic_write_request
      ownership: multi_active_unique_dynamic_write_ids
      simultaneous_request_policy: onehot0_dynamic_write_request
      same_id_conflict_policy: active_dynamic_ids_must_be_unique
      transactions:
        - transaction: w0
          selected_id_signal: axi0_w0_dynamic_id_q
          busy_signal: axi0_w0_dynamic_busy_q
          capture_rule: axi0_w0_dynamic_id_capture
          release_rule: axi0_w0_dynamic_id_release
        - transaction: w1
          selected_id_signal: axi0_w1_dynamic_id_q
          busy_signal: axi0_w1_dynamic_busy_q
          capture_rule: axi0_w1_dynamic_id_capture
          release_rule: axi0_w1_dynamic_id_release
    generated_rules:
      - axi0_w0_response_demux
      - axi0_w1_response_demux
    generated_completion_signals:
      - axi0_w0_complete
      - axi0_w1_complete
```

Generated assertions should include the existing per-transaction dynamic
assertions plus multiple-state assertions:

```text
axi0_w0_dynamic_request_not_busy
axi0_w1_dynamic_request_not_busy
axi0_write_dynamic_request_onehot0
axi0_w0_w1_write_dynamic_active_id_unique
axi0_w0_dynamic_request_no_active_same_id
axi0_w1_dynamic_request_no_active_same_id
axi0_write_dynamic_response_active_match
axi0_w0_w1_write_dynamic_response_unique_match
axi0_w0_dynamic_completion_active
axi0_w1_dynamic_completion_active
```

Exact names may follow the local helper naming convention, but the report must
make the active-match, unique-match, active-ID uniqueness, request onehot, and
no-active-same-ID assertion roles visible.

## Sample And Support Accounting

`.247` should add one support-accounted public PPIF sample, tentatively:

```text
ppif/axi_manager_capacity_status_dynamic_write_response_demux_multi.ppif
```

The sample should keep the shape minimal: two dynamic write transactions,
shared write request/response ID family signals, generated write demux
completion, no read response demux, no same-ID ordering, no queues, and no
scoreboards.

Focused validation should extend
`t/1438-axi-ial2-manager-dynamic-transaction-id-focused.t` and preserve the
existing `.223` single-active dynamic write sample unchanged. Support
accounting should cover strict check JSON and semantic JSON for the new
sample.

## Explicit Residue

The `.247` implementation should move only the all-dynamic write-family
multiple-transaction shape out of dynamic residue. These remain fail-closed or
unshipped:

- multiple dynamic read response-demux;
- mixed dynamic/static write response-demux;
- mixed dynamic/static read response-demux;
- same-cycle dynamic write request widening beyond onehot0;
- same-cycle release-and-recapture;
- dynamic same-ID ordering;
- dynamic same-ID queues and scoreboards;
- direct backend behavior outside the selected generated SystemVerilog path;
- backend-language variants; and
- VHDL.

Later note: `.378` ships same-cycle release-and-recapture for this same
multiple all-dynamic write public sample. Multiple dynamic read recapture,
mixed dynamic/static recapture, request widening beyond onehot0, queues,
scoreboards, direct backend behavior, backend-language variants, and VHDL
remain separate exact-owner work.

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

For `.247`, focused behavior validation should include syntax checks for
touched Perl modules/tests, direct schedule JSON, strict check JSON, semantic
JSON, default HDL, and `--verify-hdl` probes for the new public PPIF sample,
focused dynamic-family validation, support-accounting validation, docs,
Knowledge Map, Memory, diff, and doctrine gates.

## Rollback

Rollback is the `.246` selector commit. Reverting it restores `.246` as the
active contract-selection leaf and removes the `.247` implementation owner.
