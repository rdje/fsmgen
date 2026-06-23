# AXI IAL2 Manager Three-Static Mixed Dynamic/Static Read Response-Demux Contract Selection

Task-tree owner: `IAL2-FEATURE-COMPLETENESS-FRONTIER.321`

Date: 2026-06-23

## Decision

Select `IAL2-FEATURE-COMPLETENESS-FRONTIER.322`, direct generated behavior
for bounded one-dynamic plus three-concrete-static mixed dynamic/static read
single-beat `RID` response-demux.

The selected public contract reuses existing explicit `response-demux.read`
syntax with `response-scope single-beat` and generated transaction
completion. The first behavior owner is bounded to exactly one dynamic read
transaction and exactly three pairwise-distinct concrete static read
transactions in the selected read family:

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
    (id (value 3)))
  (read r2
    (tag rd2)
    (request axi0_r2_request)
    (completion axi0_r2_complete)
    (id (value 5)))
  (read r3
    (tag rd3)
    (request axi0_r3_request)
    (completion axi0_r3_complete)
    (id (value 7))))

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

`.322` should implement only this read single-beat contract:

- the selected read family has a positive-width `id-families.read` entry;
- exactly four read transactions are present in the selected read family;
- exactly one read transaction uses `(id dynamic)`;
- exactly three read transactions use concrete `(id (value N))` metadata;
- the three concrete static IDs are in range for the read ID-family width and
  pairwise distinct;
- `response-demux.read.response-event` is the top-level raw accepted read
  response event;
- `response-demux.read.response-scope` is `single-beat`;
- `response-demux.read.transaction-completion` is `generated`;
- no `last-signal` or burst-last metadata is present in this first
  three-static read boundary;
- no read `auto-id-lifecycle` metadata is present;
- no `same-id-ordering.read` policy is present; and
- burst-last `RID && RLAST`, read-data, burst-length/runtime validation,
  multi-beat output banks, two-dynamic-plus-static mixed cardinality,
  generalized capped mixed cardinalities, same-cycle widening,
  release-and-recapture, dynamic same-ID queues, scoreboards, direct backend,
  backend-language variants, and VHDL remain deferred.

Unrelated write transactions and write-side metadata stay report-only unless
a write-family behavior clause explicitly consumes them.

## Ownership Contract

The dynamic read transaction owns selected-ID and busy state:

```text
axi0_r0_dynamic_id_q
axi0_r0_dynamic_busy_q
```

Each concrete static read transaction owns a generated busy bit:

```text
axi0_r1_static_busy_q
axi0_r2_static_busy_q
axi0_r3_static_busy_q
```

The static concrete ID values are reserved for their static transactions. The
dynamic transaction must not capture any selected static concrete ID value,
even when no static transaction is busy. The first implementation keeps the
existing onehot0 selected-read-request policy across all four selected read
transactions.

## Capture And Release Contract

The dynamic capture guard is valid only when:

- the dynamic transaction's admitted read request is present;
- the dynamic transaction is not already busy;
- no selected static transaction request is admitted in the same cycle; and
- the dynamic request ID source is not equal to any selected static concrete
  ID value.

Each static busy capture guard is valid only when:

- that static transaction's admitted read request is present;
- that static transaction is not already busy; and
- no selected dynamic or sibling static transaction request is admitted in
  the same cycle.

All transactions release only on their generated completion pulse. A request
in the same cycle as that transaction's completion remains invalid in `.322`,
matching existing dynamic and mixed no-release-and-recapture behavior.

## Response Matching Contract

Generated read response-demux rules match one raw accepted single-beat `RID`
response:

```text
response_event && dynamic_busy_q && (RID == dynamic_id_q)
response_event && static_busy_q  && (RID == STATIC_ID)
```

The static ID reservation on dynamic capture, pairwise static-ID uniqueness,
and onehot0 request policy prevent legal states where more than one selected
transaction matches the same raw `RID`. Generated assertions should still
prove active-match and pairwise unique-match over the combined state set.

## Report Vocabulary

`.322` should keep the existing multiple mixed read single-beat mode:

```yaml
response_demux:
  mode: bounded_multi_mixed_dynamic_static_read_rid_demux_contract
  generated_behavior: true
  read:
    mode: bounded_multi_mixed_dynamic_static_read_rid_demux_contract
    response_event: axi0_read_complete
    response_event_role: raw_accepted_read_response
    response_scope: single_beat
    response_id_signal: axi0_rid
    response_id_direction: generated_input
    transaction_completion_source: generated_multi_mixed_dynamic_static_read_demux
    transaction_completion_semantics: matched_dynamic_or_static_concrete_id_single_beat
    dynamic_transactions: [r0]
    static_transactions: [r1, r2, r3]
    mixed_transactions:
      dynamic: [r0]
      static: [r1, r2, r3]
    static_id_reservations:
      - transaction: r1
        concrete_id: 3
        concrete_id_literal: 4'd3
      - transaction: r2
        concrete_id: 5
        concrete_id_literal: 4'd5
      - transaction: r3
        concrete_id: 7
        concrete_id_literal: 4'd7
    dynamic_capture:
      request_id_source: axi0_arid
      capture_event_source: admitted_dynamic_read_request
      ownership: multi_mixed_dynamic_static_unique_read_ids
      simultaneous_request_policy: onehot0_mixed_read_request
      static_id_conflict_policy: static_concrete_ids_reserved
      static_id_exclusions: [4'd3, 4'd5, 4'd7]
```

The existing one-dynamic plus one-static and one-dynamic plus two-static read
report contracts must remain unchanged.

Generated assertion roles should be visible in the report:

- dynamic request not busy;
- static request not busy for each static transaction;
- mixed read request onehot0 across all selected transactions;
- dynamic request not equal to each static concrete ID;
- dynamic active ID not equal to each static concrete ID;
- raw response active match;
- pairwise raw response unique match across all selected states;
- dynamic completion active; and
- static completion active for each static transaction.

## Sample And Support Accounting

`.322` should add one support-accounted public PPIF sample:

```text
ppif/axi_manager_capacity_status_read_mixed_dynamic_static_response_demux_multi_static3.ppif
```

The support-accounting entry should be:

```text
intent.ppif_axi_manager_capacity_status_read_mixed_dynamic_static_response_demux_multi_static3
```

The coverage key should be:

```text
ial2_ppif_manager_capacity_status_read_mixed_dynamic_static_response_demux_multi_static3_pipeline_cli
```

## Validation Strategy

The implementation owner should run:

- syntax checks for touched Perl modules and focused tests;
- filtered focused `t/1438` coverage for the new `multi_static3` read case,
  with CLI JSON skipped if host memory is above the guard cutoff;
- `t/248-regression-corpus-accounting.t`;
- guarded direct schedule/check/semantic/verify-HDL probes where host memory
  permits;
- preservation filters for one-static read demux, two-static read demux,
  two-static read burst-last demux, and adjacent read-data samples;
- Knowledge Map generation/check;
- `mdbook build docs/book`;
- memory architecture check;
- `git --no-pager diff --check`; and
- `scripts/check_doctrines.sh`.

## Explicit Residue

The following remain future owners:

- three-static mixed dynamic/static read burst-last `RID && RLAST`
  response-demux;
- scalar read-data, burst-length/runtime validation, and multi-beat output
  banks over the three-static read demux;
- two-dynamic plus one-static write or read response-demux;
- generalized capped mixed dynamic/static sets;
- same-cycle request widening beyond onehot0;
- same-cycle release-and-recapture;
- dynamic same-ID queues and scoreboards;
- direct backend behavior;
- backend-language variants; and
- VHDL.

## Rollback

Rollback is the `.321` selector commit. Reverting it restores `.321` as the
active public-contract-selection owner and removes the `.322` direct behavior
handoff.
