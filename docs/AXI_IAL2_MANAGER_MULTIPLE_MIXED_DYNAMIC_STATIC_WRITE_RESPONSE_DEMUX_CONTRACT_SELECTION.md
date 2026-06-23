# AXI IAL2 Manager Multiple Mixed Dynamic/Static Write Response-Demux Contract Selection

Task-tree owner: `IAL2-FEATURE-COMPLETENESS-FRONTIER.294`

Date: 2026-06-23

## Decision

Select `IAL2-FEATURE-COMPLETENESS-FRONTIER.295`, direct generated behavior
for bounded multiple mixed dynamic/static write `BID` response-demux.

The selected public contract reuses existing explicit `response-demux.write`
syntax with generated transaction completion. The first behavior owner is
bounded to exactly one dynamic write transaction and exactly two concrete
static write transactions in the selected write family:

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
    (id (value 3)))
  (write w2
    (tag wr2)
    (request axi0_w2_request)
    (completion axi0_w2_complete)
    (id (value 5))))

(response-demux
  (write
    (response-event axi0_write_complete)
    (transaction-completion generated)))
```

The write ID family supplies the shared request ID source and response ID
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

`.295` should implement only this first multiple mixed write contract:

- the selected write family has a positive-width `id-families.write` entry;
- exactly three write transactions are present in the selected write family;
- exactly one write transaction uses `(id dynamic)`;
- exactly two write transactions use concrete `(id (value N))` metadata;
- the two concrete static IDs are in range for the write ID-family width and
  pairwise distinct;
- `response-demux.write.response-event` is the top-level raw accepted write
  response event;
- `response-demux.write.transaction-completion` is `generated`;
- no write `auto-id-lifecycle` metadata is present;
- no `same-id-ordering.write` policy is present; and
- read-family multiple mixed demux, read-data, burst-length/runtime
  validation, multi-beat output banks, two-dynamic plus one-static mixed
  cardinality, broader mixed cardinalities, same-cycle widening,
  release-and-recapture, dynamic same-ID queues, scoreboards, direct backend,
  backend-language variants, and VHDL remain deferred.

Unrelated read transactions and read-side metadata stay report-only unless a
read-family behavior clause explicitly consumes them. The `.295` public
sample should keep the widened write shape minimal.

## Ownership Contract

The dynamic write transaction owns selected-ID and busy state:

```text
axi0_w0_dynamic_id_q
axi0_w0_dynamic_busy_q
```

Each concrete static write transaction owns its own generated busy bit:

```text
axi0_w1_static_busy_q
axi0_w2_static_busy_q
```

The static concrete ID values are reserved for their static transactions. The
dynamic transaction must not capture any selected static concrete ID value,
even when no static transaction is busy. This keeps raw `BID` response
ownership unambiguous without requiring queues or scoreboards.

The first implementation keeps a onehot0 selected-write-request policy across
all three selected write transactions. A later owner may widen same-cycle
dynamic/static requests after it selects queue or scoreboard semantics.

## Capture And Release Contract

The dynamic capture guard is valid only when:

- the dynamic transaction's admitted write request is present;
- the dynamic transaction is not already busy;
- no selected static transaction request is admitted in the same cycle; and
- the dynamic request ID source is not equal to any selected static concrete
  ID value.

Each static busy capture guard is valid only when:

- that static transaction's admitted write request is present;
- that static transaction is not already busy; and
- no selected dynamic or sibling static transaction request is admitted in
  the same cycle.

All transactions release only on their generated completion pulse. A request
in the same cycle as that transaction's completion remains invalid in `.295`,
matching existing dynamic and one-plus-one mixed no-release-and-recapture
behavior.

## Response Matching Contract

Generated write response-demux rules match one raw accepted `BID` response:

```text
response_event && dynamic_busy_q && (BID == dynamic_id_q)
response_event && static_busy_q  && (BID == STATIC_ID)
```

The static ID reservation on dynamic capture, pairwise static-ID uniqueness,
and onehot0 request policy prevent legal states where more than one selected
transaction matches the same raw `BID`. Generated assertions should still
prove active-match and pairwise unique-match over the combined state set.

## Report Vocabulary

`.295` should report a new multiple mixed write mode:

```yaml
response_demux:
  mode: bounded_multi_mixed_dynamic_static_write_bid_demux_contract
  generated_behavior: true
  write:
    mode: bounded_multi_mixed_dynamic_static_write_bid_demux_contract
    response_event: axi0_write_complete
    response_event_role: raw_accepted_write_response
    response_id_signal: axi0_bid
    response_id_direction: generated_input
    transaction_completion_source: generated_multi_mixed_dynamic_static_demux
    transaction_completion_semantics: matched_dynamic_or_static_concrete_id
    dynamic_transactions: [w0]
    static_transactions: [w1, w2]
    mixed_transactions:
      dynamic: [w0]
      static: [w1, w2]
    static_id_reservations:
      - transaction: w1
        concrete_id: 3
        concrete_id_literal: 4'd3
      - transaction: w2
        concrete_id: 5
        concrete_id_literal: 4'd5
    dynamic_capture:
      request_id_source: axi0_awid
      capture_event_source: admitted_dynamic_write_request
      ownership: multi_mixed_dynamic_static_unique_write_ids
      simultaneous_request_policy: onehot0_mixed_write_request
      static_id_conflict_policy: static_concrete_ids_reserved
      static_id_exclusions: [4'd3, 4'd5]
      transactions:
        - transaction: w0
          selected_id_signal: axi0_w0_dynamic_id_q
          busy_signal: axi0_w0_dynamic_busy_q
          capture_rule: axi0_w0_dynamic_id_capture
          release_rule: axi0_w0_dynamic_id_release
```

The existing one-dynamic plus one-static report mode and singular
`static_id_reservation` field must remain unchanged for the `.272` public
sample.

Generated assertion roles should be visible in the report:

- dynamic request not busy;
- static request not busy for each static transaction;
- mixed write request onehot0 across all selected transactions;
- dynamic request not equal to each static concrete ID;
- dynamic active ID not equal to each static concrete ID;
- raw response active match;
- pairwise raw response unique match across all selected states;
- dynamic completion active; and
- static completion active for each static transaction.

## Sample And Support Accounting

`.295` should add one support-accounted public PPIF sample:

```text
ppif/axi_manager_capacity_status_write_mixed_dynamic_static_response_demux_multi_static.ppif
```

The support-accounting entry should be:

```text
intent.ppif_axi_manager_capacity_status_write_mixed_dynamic_static_response_demux_multi_static
```

The coverage key should be:

```text
ial2_ppif_manager_capacity_status_write_mixed_dynamic_static_response_demux_multi_static_pipeline_cli
```

The sample should use the existing `response-demux.write` public syntax, one
dynamic write transaction, two concrete static write transactions with
distinct IDs, positive write/read ID families, distinct request/completion
events, and no read-data, burst, same-ID ordering, auto-ID lifecycle, queues,
or scoreboards.

## Diagnostics

`.295` should keep fail-closed behavior outside the selected contract and
sharpen diagnostics for:

- missing dynamic write transaction in the selected multiple mixed family;
- more than one dynamic write transaction in this first multiple mixed family;
- fewer or more than two concrete static write transactions in this first
  multiple mixed family;
- duplicate static concrete IDs;
- static concrete ID values outside the declared write ID-family width;
- dynamic/static mixed read response-demux;
- write `auto-id-lifecycle` combined with dynamic mixed response-demux;
- `same-id-ordering.write` combined with dynamic mixed response-demux;
- generated completion names colliding with the raw response event; and
- partial write transaction coverage.

## Validation Gates

`.295` should run focused syntax checks, direct RAM-guarded schedule/check,
semantic, generated SystemVerilog, and `--verify-hdl` probes for the new
sample; preservation probes for the `.272` one-plus-one mixed write sample;
focused dynamic/mixed generator and PPIF/CLI tests; support-accounting corpus
gates; mdBook build; Knowledge Map generation/check; memory architecture
check; diff hygiene; and doctrine gates.

## Residue

The following remain future owners:

- two-dynamic plus one-static mixed dynamic/static write cardinality;
- broader mixed write cardinalities;
- multiple mixed dynamic/static read `RID` response-demux;
- multiple mixed dynamic/static read burst-last `RID && RLAST`
  response-demux;
- scalar read-data, burst-length/runtime validation, and multi-beat output
  banks over multiple mixed read demux;
- same-cycle request widening beyond onehot0;
- same-cycle release-and-recapture;
- dynamic same-ID queues and scoreboards;
- direct backend behavior;
- backend-language variants; and
- VHDL.

## Rollback

Rollback is the `.294` contract-selection commit. Reverting it restores
`.294` as the active public contract-selection owner and removes the `.295`
direct implementation handoff.
