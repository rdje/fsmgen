# AXI IAL2 Manager Mixed Dynamic/Static Read Response-Demux Contract Selection

Task-tree owner: `IAL2-FEATURE-COMPLETENESS-FRONTIER.275`

Date: 2026-06-23

## Decision

Select `IAL2-FEATURE-COMPLETENESS-FRONTIER.276`, direct generated behavior for
bounded mixed dynamic/static read single-beat `RID` response-demux.

The selected public contract reuses existing explicit `response-demux.read`
syntax with `response-scope single-beat` and generated transaction completion.
The first behavior owner is bounded to exactly one dynamic read transaction and
exactly one concrete static read transaction in the selected read family:

```lisp
(transactions
  (read r_dynamic
    (tag rd_dynamic)
    (request axi0_r_dynamic_request)
    (completion axi0_r_dynamic_complete)
    (id dynamic))
  (read r_static
    (tag rd_static)
    (request axi0_r_static_request)
    (completion axi0_r_static_complete)
    (id (value 3))))

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

`.276` should implement only the first mixed dynamic/static read contract:

- the selected read family has a positive-width `id-families.read` entry;
- exactly two read transactions are present in the selected read family;
- exactly one read transaction uses `(id dynamic)`;
- exactly one read transaction uses a concrete `(id (value N))`;
- `response-demux.read.response-event` is the top-level raw accepted read
  response event;
- `response-demux.read.response-scope` is `single-beat`;
- `response-demux.read.transaction-completion` is `generated`;
- no read `auto-id-lifecycle` metadata is present;
- no `same-id-ordering.read` policy is present; and
- burst-last `RID && RLAST`, read-data, burst-length/runtime validation,
  multi-beat output banks, multiple mixed transactions, queues, scoreboards,
  same-cycle widening, same-cycle release-and-recapture, direct backend
  behavior, backend-language variants, and VHDL remain deferred.

Unrelated write transactions and write-side metadata stay on their existing
paths unless a write-family behavior clause explicitly consumes them. The `.276`
public sample should keep the mixed read shape minimal.

## Ownership Contract

The dynamic read transaction owns selected-ID and busy state exactly like the
single-active and all-dynamic read response-demux contracts:

```text
<dynamic_transaction>_dynamic_id_q
<dynamic_transaction>_dynamic_busy_q
```

The concrete static read transaction owns a generated busy bit:

```text
<static_transaction>_static_busy_q
```

The static concrete ID value is reserved for the static transaction. The
dynamic transaction must not capture that concrete ID value, even when the
static transaction is not busy. This keeps raw `RID` response ownership
unambiguous without requiring queues or scoreboards.

The first implementation keeps a onehot0 selected-read-request policy across
the dynamic and static transactions. A later owner may widen same-cycle
dynamic/static requests after it selects queue or scoreboard semantics.

## Capture And Release Contract

The dynamic capture guard is valid only when:

- the dynamic transaction's admitted read request is present;
- the dynamic transaction is not already busy;
- the static transaction request is not admitted in the same cycle; and
- the dynamic request ID source is not equal to the static concrete ID value.

The static busy capture guard is valid only when:

- the static transaction's admitted read request is present;
- the static transaction is not already busy; and
- the dynamic transaction request is not admitted in the same cycle.

Both transactions release only on their generated completion pulse. A request
in the same cycle as that transaction's completion remains invalid in `.276`,
matching existing dynamic no-release-and-recapture behavior.

## Response Matching Contract

Generated read response-demux rules match one raw accepted single-beat `RID`
response:

```text
response_event && dynamic_busy_q && (RID == dynamic_id_q)
response_event && static_busy_q && (RID == STATIC_ID)
```

The static ID reservation on dynamic capture prevents legal states where both
matches are true. Generated assertions should still prove active-match and
unique-match over the combined read state set so a malformed environment or
future refactor cannot silently introduce ambiguous ownership.

## Report Vocabulary

`.276` should report a new mixed read single-beat mode:

```yaml
response_demux:
  mode: bounded_mixed_dynamic_static_read_rid_demux_contract
  generated_behavior: true
  read:
    mode: bounded_mixed_dynamic_static_read_rid_demux_contract
    response_event: axi0_read_complete
    response_event_role: raw_accepted_read_response
    response_scope: single_beat
    response_id_signal: axi0_rid
    response_id_direction: generated_input
    transaction_completion_source: generated_mixed_dynamic_static_read_demux
    transaction_completion_semantics: matched_dynamic_or_static_concrete_id_single_beat
    mixed_transactions:
      dynamic: r_dynamic
      static: r_static
    static_id_reservation:
      transaction: r_static
      concrete_id: 3
      dynamic_capture_policy: dynamic_id_must_not_equal_static_concrete_id
    dynamic_capture:
      request_id_source: axi0_arid
      capture_event_source: admitted_dynamic_read_request
      ownership: mixed_dynamic_static_unique_read_ids
      simultaneous_request_policy: onehot0_mixed_read_request
      static_id_conflict_policy: static_concrete_ids_reserved
```

Generated assertion roles should be visible in the report:

- dynamic request not busy;
- static request not busy;
- mixed read request onehot0;
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

`.276` should add one support-accounted public PPIF sample:

```text
ppif/axi_manager_capacity_status_read_mixed_dynamic_static_response_demux.ppif
```

The support-accounting entry should be:

```text
intent.ppif_axi_manager_capacity_status_read_mixed_dynamic_static_response_demux
```

The sample should use the existing `response-demux.read` public syntax,
`response-scope single-beat`, one dynamic read transaction, one concrete static
read transaction, positive write/read ID families, distinct request/completion
events, and no read-data, burst, same-ID ordering, auto-ID lifecycle, queues,
or scoreboards.

## Diagnostics

`.276` should keep fail-closed behavior outside the selected contract and
sharpen diagnostics for:

- more than one dynamic read transaction in a mixed dynamic/static read
  contract;
- more than one concrete static read transaction in the first mixed read
  contract;
- mixed dynamic/static read `response-scope burst-last`;
- read-data over mixed dynamic/static read response-demux;
- burst-length/runtime validation over mixed dynamic/static read response-demux;
- multi-beat output banks over mixed dynamic/static read response-demux;
- read `auto-id-lifecycle` combined with dynamic mixed response-demux;
- `same-id-ordering.read` combined with dynamic mixed response-demux;
- static concrete ID values outside the declared read ID-family width;
- generated completion names colliding with the raw response event; and
- partial read transaction coverage.

## Validation Gates

`.276` should run focused syntax checks, direct guarded schedule/check,
semantic, generated SystemVerilog, and `--verify-hdl` probes for the new sample;
focused generator and PPIF/CLI tests; support-accounting corpus gates; mdBook
build; docs path audit; Knowledge Map generation/check; memory architecture
check; diff hygiene; and doctrine gates.

## Residue

The following remain future owners:

- mixed dynamic/static read burst-last/`RLAST` response-demux;
- scalar read-data over mixed dynamic/static read response-demux;
- burst-length/runtime validation over mixed dynamic/static read response-demux;
- multi-beat output banks over mixed dynamic/static read response-demux;
- multiple dynamic plus multiple static transactions in one mixed family;
- same-cycle request widening beyond onehot0;
- same-cycle release-and-recapture;
- dynamic same-ID queues and scoreboards;
- direct backend behavior outside the selected generated SystemVerilog path;
- backend-language variants; and
- VHDL.

## Rollback

Rollback is the `.275` selector commit. Reverting it restores `.275` as the
active public contract-selection owner and removes the `.276` direct behavior
handoff.
