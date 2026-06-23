# AXI IAL2 Manager Multiple Mixed Dynamic/Static Read Response-Demux Contract Selection

Task-tree owner: `IAL2-FEATURE-COMPLETENESS-FRONTIER.298`

Date: 2026-06-23

## Decision

Select `IAL2-FEATURE-COMPLETENESS-FRONTIER.299`, direct generated behavior
for bounded multiple mixed dynamic/static read single-beat `RID`
response-demux.

The selected public contract reuses existing explicit `response-demux.read`
syntax with `response-scope single-beat` and generated transaction
completion. The first behavior owner is bounded to exactly one dynamic read
transaction and exactly two concrete static read transactions in the selected
read family:

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
    (id (value 5))))

(response-demux
  (read
    (response-event axi0_read_complete)
    (response-scope single-beat)
    (transaction-completion generated)))
```

The read ID family supplies the shared request ID source and response ID
signal:

```lisp
(id-families
  (write (width 4) (request-id-signal axi0_awid) (response-id-signal axi0_bid))
  (read  (width 4) (request-id-signal axi0_arid) (response-id-signal axi0_rid)))
```

This selector changes no parser, generator, PPIF sample, support-accounting
catalog, validation behavior, generated artifact, test, schedule/check or
semantic JSON, or HDL behavior.

## Public Boundary

`.299` should implement only this first multiple mixed read contract:

- the selected read family has a positive-width `id-families.read` entry;
- exactly three read transactions are present in the selected read family;
- exactly one read transaction uses `(id dynamic)`;
- exactly two read transactions use concrete `(id (value N))` metadata;
- the two concrete static IDs are in range for the read ID-family width and
  pairwise distinct;
- `response-demux.read.response-event` is the top-level raw accepted read
  response event;
- `response-demux.read.response-scope` is `single-beat`;
- `response-demux.read.transaction-completion` is `generated`;
- no `last-signal` or burst-last metadata is present in this first
  single-beat boundary;
- no read `auto-id-lifecycle` metadata is present;
- no `same-id-ordering.read` policy is present; and
- burst-last `RID && RLAST`, read-data, burst-length/runtime validation,
  multi-beat output banks, two-dynamic plus one-static mixed cardinality,
  broader mixed cardinalities, same-cycle widening, release-and-recapture,
  dynamic same-ID queues, scoreboards, direct backend, backend-language
  variants, and VHDL remain deferred.

Unrelated write transactions and write-side metadata stay report-only unless
a write-family behavior clause explicitly consumes them. The `.299` public
sample should keep the widened read shape minimal.

## Ownership Contract

The dynamic read transaction owns selected-ID and busy state:

```text
axi0_r0_dynamic_id_q
axi0_r0_dynamic_busy_q
```

Each concrete static read transaction owns its own generated busy bit:

```text
axi0_r1_static_busy_q
axi0_r2_static_busy_q
```

The static concrete ID values are reserved for their static transactions. The
dynamic transaction must not capture any selected static concrete ID value,
even when no static transaction is busy. This keeps raw `RID` response
ownership unambiguous without requiring queues or scoreboards.

The first implementation keeps a onehot0 selected-read-request policy across
all three selected read transactions. A later owner may widen same-cycle
dynamic/static requests after it selects queue or scoreboard semantics.

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
in the same cycle as that transaction's completion remains invalid in `.299`,
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

`.299` should report a new multiple mixed read single-beat mode:

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
    static_transactions: [r1, r2]
    mixed_transactions:
      dynamic: [r0]
      static: [r1, r2]
    static_id_reservations:
      - transaction: r1
        concrete_id: 3
        concrete_id_literal: 4'd3
      - transaction: r2
        concrete_id: 5
        concrete_id_literal: 4'd5
    dynamic_capture:
      request_id_source: axi0_arid
      capture_event_source: admitted_dynamic_read_request
      ownership: multi_mixed_dynamic_static_unique_read_ids
      simultaneous_request_policy: onehot0_mixed_read_request
      static_id_conflict_policy: static_concrete_ids_reserved
      static_id_exclusions: [4'd3, 4'd5]
      transactions:
        - transaction: r0
          selected_id_signal: axi0_r0_dynamic_id_q
          busy_signal: axi0_r0_dynamic_busy_q
          capture_rule: axi0_r0_dynamic_id_capture
          release_rule: axi0_r0_dynamic_id_release
```

The existing one-dynamic plus one-static read report mode and singular
`static_id_reservation` field must remain unchanged for the `.276` public
sample.

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

`.299` should add one support-accounted public PPIF sample:

```text
ppif/axi_manager_capacity_status_read_mixed_dynamic_static_response_demux_multi_static.ppif
```

The support-accounting entry should be:

```text
intent.ppif_axi_manager_capacity_status_read_mixed_dynamic_static_response_demux_multi_static
```

The coverage key should be:

```text
ial2_ppif_manager_capacity_status_read_mixed_dynamic_static_response_demux_multi_static_pipeline_cli
```

The sample should use the existing `response-demux.read` public syntax,
`response-scope single-beat`, one dynamic read transaction, two concrete
static read transactions with distinct IDs, positive write/read ID families,
distinct request/completion events, and no read-data, burst, same-ID
ordering, auto-ID lifecycle, queues, or scoreboards.

## Diagnostics

`.299` should keep fail-closed behavior outside the selected contract and
sharpen diagnostics for:

- missing dynamic read transaction in the selected multiple mixed family;
- more than one dynamic read transaction in this first multiple mixed family;
- fewer or more than two concrete static read transactions in this first
  multiple mixed family;
- duplicate static concrete IDs;
- static concrete ID values outside the declared read ID-family width;
- read `response-scope burst-last` combined with multiple mixed read
  response-demux before that contract is selected;
- read-data over multiple mixed read response-demux before that contract is
  selected;
- read `auto-id-lifecycle` combined with dynamic mixed response-demux;
- `same-id-ordering.read` combined with dynamic mixed response-demux;
- generated completion names colliding with the raw response event; and
- partial read transaction coverage.

## Validation Gates

`.299` should run focused syntax checks, direct RAM-guarded schedule/check,
semantic, generated SystemVerilog, and `--verify-hdl` probes for the new
sample; preservation probes for the `.276` one-plus-one mixed read sample;
focused dynamic/mixed generator and PPIF/CLI tests; support-accounting corpus
gates; mdBook build; Knowledge Map generation/check; memory architecture
check; diff hygiene; and doctrine gates.

## Residue

The following remain future owners:

- multiple mixed dynamic/static read burst-last `RID && RLAST`
  response-demux;
- scalar read-data, burst-length/runtime validation, and multi-beat output
  banks over multiple mixed read demux;
- two-dynamic plus one-static mixed dynamic/static write cardinality;
- broader mixed write and read cardinalities;
- same-cycle request widening beyond onehot0;
- same-cycle release-and-recapture;
- dynamic same-ID queues and scoreboards;
- direct backend behavior;
- backend-language variants; and
- VHDL.

## Rollback

Rollback is the `.298` contract-selection commit. Reverting it restores
`.298` as the active public contract-selection owner and removes the `.299`
direct implementation handoff.
