# AXI IAL2 Manager Mixed Dynamic/Static Read RLAST Response-Demux Contract Selection

Task-tree owner: `IAL2-FEATURE-COMPLETENESS-FRONTIER.279`

Date: 2026-06-23

## Decision

Select `IAL2-FEATURE-COMPLETENESS-FRONTIER.280`, direct generated behavior for
bounded mixed dynamic/static read burst-last `RID && RLAST` response-demux.

The selected public contract composes the shipped `.276` mixed dynamic/static
read single-beat ownership contract with the shipped `.255` all-dynamic
burst-last final-completion contract. It changes no parser, generator, PPIF
sample, support-accounting catalog, validation behavior, generated artifact,
test, schedule/check or semantic JSON, or HDL behavior.

## Public Source Shape

The `.280` implementation should add one support-accounted public PPIF sample:

```text
ppif/axi_manager_capacity_status_read_mixed_dynamic_static_response_demux_burst_last.ppif
```

The source shape reuses existing explicit `response-demux.read` syntax:

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
    (id concrete 3)))

(response-demux
  (read
    (response-event axi0_read_complete)
    (response-scope burst-last)
    (last-signal axi0_rlast (width 1))
    (transaction-completion generated)))
```

The read ID family supplies the shared request ID source and response ID
signal:

```lisp
(id-families
  (read (width 4) (request-id-signal axi0_arid) (response-id-signal axi0_rid)))
```

## Public Boundary

The first implementation is intentionally response-demux-only:

- the read ID family must be present and positive-width;
- exactly two read transactions are present in the selected read family;
- exactly one read transaction uses `(id dynamic)`;
- exactly one read transaction uses a concrete static ID;
- `response-demux.read.response-event` is the raw accepted read response-beat
  event;
- `response-demux.read.response-scope` is `burst-last`;
- `response-demux.read.last-signal` is present, one bit wide, and generated as
  an input;
- `response-demux.read.transaction-completion` is `generated`;
- generated transaction completion signals are distinct from the raw read
  response event;
- no read `auto-id-lifecycle` metadata is present;
- no `same-id-ordering.read` policy is present; and
- `read-data`, `burst-length`, runtime beat-count/`RLAST` validation,
  multi-beat output banks, multiple mixed transactions, same-cycle widening,
  release-and-recapture, dynamic same-ID queues, scoreboards, direct backend
  behavior, backend-language variants, and VHDL remain deferred.

Unrelated write transactions and write-side metadata stay on their existing
paths unless a write-family behavior clause explicitly consumes them. The
`.280` public sample should keep the mixed read burst-last shape minimal.

## Capture And Lifetime

The dynamic read transaction owns selected-ID and busy state:

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
static transaction is not busy. Same-cycle dynamic/static read requests remain
onehot0 in this contract.

The dynamic capture guard is valid only when:

- the dynamic transaction's admitted read request is present;
- the dynamic transaction is not already busy;
- the static transaction request is not admitted in the same cycle; and
- the dynamic request ID source is not equal to the static concrete ID value.

The static busy capture guard is valid only when:

- the static transaction's admitted read request is present;
- the static transaction is not already busy; and
- the dynamic transaction request is not admitted in the same cycle.

Both transactions stay busy across matched non-last read beats. Each releases
only from that transaction's generated final-beat completion pulse. Same-cycle
release-and-recapture remains a later owner.

## Response Matching

The public contract separates raw beat ownership from final-beat completion.

A raw read beat matches the active dynamic transaction when:

```text
response_event && dynamic_busy_q && (RID == dynamic_id_q)
```

A raw read beat matches the active static transaction when:

```text
response_event && static_busy_q && (RID == STATIC_ID)
```

Those raw matches are used by active-match and unique-match assertions. They
intentionally do not include `RLAST`, so matched non-last beats are legal and
mismatched non-last beats are diagnosed.

A generated dynamic completion pulses only on the final matching dynamic beat:

```text
response_event && dynamic_busy_q && (RID == dynamic_id_q) && RLAST
```

A generated static completion pulses only on the final matching static beat:

```text
response_event && static_busy_q && (RID == STATIC_ID) && RLAST
```

The completion pulse releases the owning busy state. Non-last matched beats do
not complete or release either transaction. The `.280` implementation should
make static concrete read completion guards `last_signal`-aware for this mode;
the current single-beat static guard helper is not sufficient by itself.

This contract does not validate beat counts or enforce AXI burst length. It
only uses `RLAST` to choose the generated completion/release beat.

## Report Vocabulary

The `.280` implementation should report a new mode:

```yaml
response_demux:
  mode: bounded_mixed_dynamic_static_read_rid_rlast_demux_contract
  generated_behavior: true
  read:
    mode: bounded_mixed_dynamic_static_read_rid_rlast_demux_contract
    generated_behavior: true
    response_event: axi0_read_complete
    response_event_role: raw_accepted_read_response_beat
    response_scope: burst_last
    response_id_signal: axi0_rid
    response_id_direction: generated_input
    last_signal: axi0_rlast
    last_signal_direction: generated_input
    last_signal_width: 1
    transaction_completion_source: generated_mixed_dynamic_static_read_demux_last_beat
    transaction_completion_semantics: matched_dynamic_or_static_concrete_id_and_last_signal
    beat_valid_output: none
    burst_length_source: rlast_only
    burst_length_validation: not_generated
    mixed_transactions:
      dynamic: r0
      static: r1
    static_id_reservation:
      transaction: r1
      concrete_id: 3
      concrete_id_literal: 4'd3
      dynamic_capture_policy: dynamic_id_must_not_equal_static_concrete_id
    dynamic_capture:
      request_id_source: axi0_arid
      capture_event_source: admitted_dynamic_read_request
      ownership: mixed_dynamic_static_unique_read_ids
      simultaneous_request_policy: onehot0_mixed_read_request
      static_id_conflict_policy: static_concrete_ids_reserved
      selected_id_signal: axi0_r0_dynamic_id_q
      busy_signal: axi0_r0_dynamic_busy_q
      capture_rule: axi0_r0_dynamic_id_capture
      release_rule: axi0_r0_dynamic_id_release
    generated_rules:
      - axi0_r0_response_demux
      - axi0_r1_response_demux
    generated_completion_signals:
      - axi0_r0_complete
      - axi0_r1_complete
```

Generated assertion names should follow the existing local naming convention
and make these roles visible:

- dynamic request not busy;
- static request not busy;
- mixed read request onehot0;
- dynamic request not static concrete ID;
- dynamic active ID not static concrete ID;
- raw response active match;
- raw response unique match;
- dynamic completion active; and
- static completion active.

The generated response-demux residue should remain:

```yaml
residue:
  - same_id_ordering
  - read_data_interleaving
  - bursts
```

Read-data, raw `ARLEN`, runtime validation, and multi-beat output-bank residue
must stay explicit until later owners consume the new mixed burst-last
completion or raw matched-beat boundary.

## Sample And Support Accounting

The support-accounting entry should be:

```text
intent.ppif_axi_manager_capacity_status_read_mixed_dynamic_static_response_demux_burst_last
```

The coverage label should follow the local PPIF naming pattern:

```text
ial2_ppif_manager_capacity_status_read_mixed_dynamic_static_response_demux_burst_last_pipeline_cli
```

## Diagnostics And Fail-Closed Boundaries

`.280` should keep fail-closed behavior outside the selected contract and
sharpen diagnostics for:

- more than one dynamic read transaction in a mixed dynamic/static read
  contract;
- more than one concrete static read transaction in the first mixed read
  contract;
- missing `last-signal` or `last-signal` width when `response-scope` is
  `burst-last`;
- `last-signal` used with `response-scope single-beat`;
- `last-signal_width` other than one bit;
- read-data over mixed dynamic/static read burst-last response-demux;
- burst-length/runtime validation over mixed dynamic/static read burst-last
  response-demux;
- multi-beat output banks over mixed dynamic/static read burst-last
  response-demux;
- read `auto-id-lifecycle` combined with dynamic mixed response-demux;
- `same-id-ordering.read` combined with dynamic mixed response-demux;
- static concrete ID values outside the declared read ID-family width;
- generated completion names colliding with the raw response event; and
- partial read transaction coverage.

## Validation Gates

The `.280` implementation should run focused gates:

```bash
perl -Iperl -c perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm
perl -c t/1437-axi-ial2-manager-capacity-status-generator.t
perl -c t/1438-axi-ial2-manager-dynamic-transaction-id-focused.t
perl -c t/248-regression-corpus-accounting.t
prove -l t/1438-axi-ial2-manager-dynamic-transaction-id-focused.t
prove -l t/248-regression-corpus-accounting.t
./bin/fsmgen --strict --check --json ppif/axi_manager_capacity_status_read_mixed_dynamic_static_response_demux_burst_last.ppif
./bin/fsmgen --strict --emit-semantic-json ppif/axi_manager_capacity_status_read_mixed_dynamic_static_response_demux_burst_last.ppif
./bin/fsmgen --strict --verify-hdl --output /tmp/fsmgen_mixed_read_demux_burst_last.sv ppif/axi_manager_capacity_status_read_mixed_dynamic_static_response_demux_burst_last.ppif
bash knowledge-map/scripts/gen_knowledge_map.sh
bash knowledge-map/scripts/check_knowledge_map.sh
mdbook build docs/book
prove -Iperl t/1414-docs-relative-paths-audit.t
scripts/check_memory_architecture.sh
git --no-pager diff --check
scripts/check_doctrines.sh
```

If broad focused suites remain CPU-bound in the interactive environment,
record the bounded caveat and use direct public-sample schedule/check/semantic
and HDL probes plus focused syntax/support-accounting coverage as the closeout
evidence.

## Rollback

Rollback is the `.279` contract-selection commit. Reverting it restores `.279`
as the active contract selector after `.278`; reverting the future `.280`
implementation should remove only generated mixed read burst-last behavior,
its public sample, support-accounting entry, tests, docs, and fact card.
