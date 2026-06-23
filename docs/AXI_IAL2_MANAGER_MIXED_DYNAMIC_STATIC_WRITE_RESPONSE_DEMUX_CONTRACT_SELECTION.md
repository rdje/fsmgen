# AXI IAL2 Manager Mixed Dynamic/Static Write Response-Demux Contract Selection

Task-tree owner: `IAL2-FEATURE-COMPLETENESS-FRONTIER.271`

Date: 2026-06-23

## Decision

Select `IAL2-FEATURE-COMPLETENESS-FRONTIER.272`, direct generated behavior
for bounded mixed dynamic/static write `BID` response-demux.

The selected public contract reuses existing explicit `response-demux.write`
syntax with generated transaction completion. The first behavior owner is
bounded to exactly one dynamic write transaction and exactly one concrete
static write transaction in the selected write family:

```lisp
(transactions
  (write w_dynamic
    (tag wr_dynamic)
    (request axi0_w_dynamic_request)
    (completion axi0_w_dynamic_complete)
    (id dynamic))
  (write w_static
    (tag wr_static)
    (request axi0_w_static_request)
    (completion axi0_w_static_complete)
    (id (value 3))))

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

`.272` should implement only the first mixed dynamic/static write contract:

- the selected write family has a positive-width `id-families.write` entry;
- exactly two write transactions are present in the selected write family;
- exactly one write transaction uses `(id dynamic)`;
- exactly one write transaction uses a concrete `(id (value N))`;
- `response-demux.write.response-event` is the top-level raw accepted write
  response event;
- `response-demux.write.transaction-completion` is `generated`;
- no write `auto-id-lifecycle` metadata is present;
- no `same-id-ordering.write` policy is present; and
- read-family dynamic/static demux, multiple mixed transactions, queues,
  scoreboards, same-cycle widening, same-cycle release-and-recapture, direct
  backend behavior, backend-language variants, and VHDL remain deferred.

Unrelated read transactions and read-side metadata stay report-only unless a
read-family behavior clause explicitly consumes them. The `.272` public
sample should keep the mixed write shape minimal.

## Ownership Contract

The dynamic write transaction owns selected-ID and busy state exactly like the
single-active and all-dynamic write response-demux contracts:

```text
<dynamic_transaction>_dynamic_id_q
<dynamic_transaction>_dynamic_busy_q
```

The concrete static write transaction owns a generated busy bit:

```text
<static_transaction>_static_busy_q
```

The static concrete ID value is reserved for the static transaction. The
dynamic transaction must not capture that concrete ID value, even when the
static transaction is not busy. This keeps response ownership unambiguous
without requiring queues or scoreboards.

The first implementation keeps a onehot0 selected-write-request policy across
the dynamic and static transactions. A later owner may widen same-cycle
dynamic/static requests after it selects queue or scoreboard semantics.

## Capture And Release Contract

The dynamic capture guard is valid only when:

- the dynamic transaction's admitted write request is present;
- the dynamic transaction is not already busy;
- the static transaction request is not admitted in the same cycle; and
- the dynamic request ID source is not equal to the static concrete ID value.

The static busy capture guard is valid only when:

- the static transaction's admitted write request is present;
- the static transaction is not already busy; and
- the dynamic transaction request is not admitted in the same cycle.

Both transactions release only on their generated completion pulse. A request
in the same cycle as that transaction's completion remains invalid in `.272`,
matching existing dynamic no-release-and-recapture behavior.

## Response Matching Contract

Generated write response-demux rules match one raw accepted `BID` response:

```text
response_event && dynamic_busy_q && (BID == dynamic_id_q)
response_event && static_busy_q && (BID == STATIC_ID)
```

The static ID reservation on dynamic capture prevents legal states where both
matches are true. Generated assertions should still prove active-match and
unique-match over the combined state set so a malformed environment or future
refactor cannot silently introduce ambiguous ownership.

## Report Vocabulary

`.272` should report a new mixed write mode:

```yaml
response_demux:
  mode: bounded_mixed_dynamic_static_write_bid_demux_contract
  generated_behavior: true
  write:
    mode: bounded_mixed_dynamic_static_write_bid_demux_contract
    response_event: axi0_write_complete
    response_event_role: raw_accepted_write_response
    response_id_signal: axi0_bid
    response_id_direction: generated_input
    transaction_completion_source: generated_mixed_dynamic_static_demux
    transaction_completion_semantics: matched_dynamic_or_static_concrete_id
    mixed_transactions:
      dynamic: w_dynamic
      static: w_static
    static_id_reservation:
      transaction: w_static
      concrete_id: 3
      dynamic_capture_policy: dynamic_id_must_not_equal_static_concrete_id
    dynamic_capture:
      request_id_source: axi0_awid
      capture_event_source: admitted_dynamic_write_request
      ownership: mixed_dynamic_static_unique_write_ids
      simultaneous_request_policy: onehot0_mixed_write_request
      static_id_conflict_policy: static_concrete_ids_reserved
```

Generated assertion roles should be visible in the report:

- dynamic request not busy;
- static request not busy;
- mixed write request onehot0;
- dynamic request not static concrete ID;
- dynamic active ID not static concrete ID;
- raw response active match;
- raw response unique match;
- dynamic completion active; and
- static completion active.

Exact generated names may follow local helper conventions, but the roles must
be machine-readable enough for schedule JSON tests and future support
accounting.

## Sample And Support Accounting

`.272` should add one support-accounted public PPIF sample:

```text
ppif/axi_manager_capacity_status_write_mixed_dynamic_static_response_demux.ppif
```

The support-accounting entry should be:

```text
intent.ppif_axi_manager_capacity_status_write_mixed_dynamic_static_response_demux
```

The sample should use the existing `response-demux.write` public syntax, one
dynamic write transaction, one concrete static write transaction, positive
write/read ID families, distinct request/completion events, and no read-data,
burst, same-ID ordering, auto-ID lifecycle, queues, or scoreboards.

## Diagnostics

`.272` should keep the existing fail-closed behavior outside the selected
contract and sharpen diagnostics for:

- more than one dynamic write transaction in a mixed dynamic/static write
  contract;
- more than one concrete static write transaction in the first mixed write
  contract;
- dynamic/static mixed read response-demux;
- write `auto-id-lifecycle` combined with dynamic mixed response-demux;
- `same-id-ordering.write` combined with dynamic mixed response-demux;
- static concrete ID values outside the declared write ID-family width;
- generated completion names colliding with the raw response event; and
- partial write transaction coverage.

## Validation Gates

`.272` should run focused syntax checks, direct guarded schedule/check,
semantic, generated SystemVerilog, and `--verify-hdl` probes for the new
sample; focused generator and PPIF/CLI tests; support-accounting corpus gates;
mdBook build; docs path audit; Knowledge Map generation/check; memory
architecture check; diff hygiene; and doctrine gates.

## Residue

The following remain future owners:

- mixed dynamic/static read single-beat response-demux;
- mixed dynamic/static read burst-last/`RLAST` response-demux;
- scalar read-data over mixed dynamic/static response-demux;
- burst-length/runtime validation over mixed dynamic/static response-demux;
- multi-beat output banks over mixed dynamic/static response-demux;
- multiple dynamic plus multiple static transactions in one mixed family;
- same-cycle request widening beyond onehot0;
- same-cycle release-and-recapture;
- dynamic same-ID queues and scoreboards;
- direct backend behavior outside the selected generated SystemVerilog path;
- backend-language variants; and
- VHDL.

## Rollback

Rollback is the `.271` selector commit. Reverting it restores `.271` as the
active public contract-selection owner and removes the `.272` direct behavior
handoff.
