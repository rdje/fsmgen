# AXI IAL2 Manager Three-Static Mixed Dynamic/Static Read RLAST Response-Demux Contract Selection

Task-tree owner: `IAL2-FEATURE-COMPLETENESS-FRONTIER.325`

Date: 2026-06-23

## Decision

Select `IAL2-FEATURE-COMPLETENESS-FRONTIER.326`, direct generated behavior
for bounded one-dynamic plus three-concrete-static mixed dynamic/static read
burst-last `RID && RLAST` response-demux.

The selected public contract composes the shipped `.322` one-dynamic plus
three-static single-beat `RID` ownership/report contract with the shipped
`.303` one-dynamic plus two-static burst-last final-completion contract.

This selector changes no parser, generator, PPIF sample, support-accounting
catalog, validation behavior, generated artifact, test, schedule/check or
semantic JSON, or HDL behavior.

## Public Source Shape

The `.326` implementation should add one support-accounted public PPIF
sample:

```text
ppif/axi_manager_capacity_status_read_mixed_dynamic_static_response_demux_multi_static3_burst_last.ppif
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
    (response-scope burst-last)
    (last-signal axi0_rlast (width 1))
    (transaction-completion generated)))
```

The read ID family supplies the shared request ID source and response ID
signal:

```lisp
(id-families
  (write (width 4) (request-id axi0_awid) (response-id axi0_bid))
  (read  (width 4) (request-id axi0_arid) (response-id axi0_rid)))
```

## Public Boundary

`.326` should implement only this bounded three-static mixed read burst-last
contract:

- the selected read family has a positive-width `id-families.read` entry;
- exactly four read transactions are present in the selected read family;
- exactly one read transaction uses `(id dynamic)`;
- exactly three read transactions use concrete `(id (value N))` metadata;
- the three concrete static IDs are in range for the read ID-family width and
  pairwise distinct;
- `response-demux.read.response-event` is the raw accepted read response-beat
  event;
- `response-demux.read.response-scope` is `burst-last`;
- `response-demux.read.last-signal` is present, one bit wide, and generated
  as an input;
- `response-demux.read.transaction-completion` is `generated`;
- generated transaction completion signals are distinct from the raw read
  response event;
- no read `auto-id-lifecycle` metadata is present;
- no `same-id-ordering.read` policy is present; and
- read-data, raw `ARLEN` burst-length capture, runtime beat-count/`RLAST`
  validation, multi-beat output banks, two-dynamic plus one-static mixed
  cardinality, broader mixed cardinalities, same-cycle widening, release and
  recapture, dynamic same-ID queues, scoreboards, direct backend,
  backend-language variants, and VHDL remain deferred.

Unrelated write transactions and write-side metadata stay report-only unless
a write-family behavior clause explicitly consumes them. The `.326` public
sample should keep the widened read burst-last shape minimal.

## Ownership And Lifetime

The dynamic read transaction owns selected-ID and busy state:

```text
axi0_r0_dynamic_id_q
axi0_r0_dynamic_busy_q
```

Each concrete static read transaction owns its own generated busy bit:

```text
axi0_r1_static_busy_q
axi0_r2_static_busy_q
axi0_r3_static_busy_q
```

The static concrete ID values are reserved for their static transactions. The
dynamic transaction must not capture any selected static concrete ID value,
even when no static transaction is busy. This keeps raw `RID` response
ownership unambiguous without requiring queues or scoreboards.

The selected contract keeps a onehot0 selected-read-request policy across all
four selected read transactions. A later owner may widen same-cycle
dynamic/static requests after it selects queue or scoreboard semantics.

The dynamic capture guard is valid only when:

- the dynamic transaction's admitted read request is present;
- the dynamic transaction is not already busy;
- no selected static transaction request is admitted in the same cycle; and
- the dynamic request ID source is not equal to any selected static concrete
  ID value.

Each static busy capture guard is valid only when:

- that static transaction's admitted read request is present;
- that static transaction is not already busy; and
- no selected dynamic or sibling static transaction request is admitted in the
  same cycle.

All selected transactions stay busy across matched non-last read beats. Each
releases only from that transaction's generated final-beat completion pulse.
A request in the same cycle as that transaction's completion remains invalid
in `.326`, matching existing dynamic and mixed no-release-and-recapture
behavior.

## Response Matching

The public contract separates raw beat ownership from final-beat completion.

A raw read beat matches the active dynamic transaction when:

```text
response_event && dynamic_busy_q && (RID == dynamic_id_q)
```

A raw read beat matches an active static transaction when:

```text
response_event && static_busy_q && (RID == STATIC_ID)
```

Those raw matches are used by active-match and pairwise unique-match
assertions. They intentionally do not include `RLAST`, so matched non-final
beats are legal and mismatched non-final beats are diagnosed.

A generated dynamic completion pulses only on the final matching dynamic
beat:

```text
response_event && dynamic_busy_q && (RID == dynamic_id_q) && RLAST
```

A generated static completion pulses only on the final matching static beat:

```text
response_event && static_busy_q && (RID == STATIC_ID) && RLAST
```

The completion pulse releases the owning busy state. Non-last matched beats
do not complete or release any selected transaction. This contract does not
validate beat counts or enforce AXI burst length; it uses `RLAST` only to
choose the generated completion/release beat.

## Report Vocabulary

`.326` should keep the existing multiple mixed read burst-last mode:

```yaml
response_demux:
  mode: bounded_multi_mixed_dynamic_static_read_rid_rlast_demux_contract
  generated_behavior: true
  read:
    mode: bounded_multi_mixed_dynamic_static_read_rid_rlast_demux_contract
    generated_behavior: true
    response_event: axi0_read_complete
    response_event_role: raw_accepted_read_response_beat
    response_scope: burst_last
    response_id_signal: axi0_rid
    response_id_direction: generated_input
    last_signal: axi0_rlast
    last_signal_direction: generated_input
    last_signal_width: 1
    transaction_completion_source: generated_multi_mixed_dynamic_static_read_demux_last_beat
    transaction_completion_semantics: matched_dynamic_or_static_concrete_id_and_last_signal
    beat_valid_output: none
    burst_length_source: rlast_only
    burst_length_validation: not_generated
    dynamic_transactions: [r0]
    static_transactions: [r1, r2, r3]
    mixed_transactions:
      dynamic: [r0]
      static: [r1, r2, r3]
    static_id_reservations:
      - transaction: r1
        concrete_id: 3
        concrete_id_literal: 4'd3
        dynamic_capture_policy: dynamic_id_must_not_equal_static_concrete_id
      - transaction: r2
        concrete_id: 5
        concrete_id_literal: 4'd5
        dynamic_capture_policy: dynamic_id_must_not_equal_static_concrete_id
      - transaction: r3
        concrete_id: 7
        concrete_id_literal: 4'd7
        dynamic_capture_policy: dynamic_id_must_not_equal_static_concrete_id
    dynamic_capture:
      request_id_source: axi0_arid
      capture_event_source: admitted_dynamic_read_request
      ownership: multi_mixed_dynamic_static_unique_read_ids
      simultaneous_request_policy: onehot0_mixed_read_request
      static_id_conflict_policy: static_concrete_ids_reserved
      static_id_exclusions: [4'd3, 4'd5, 4'd7]
      transactions:
        - transaction: r0
          selected_id_signal: axi0_r0_dynamic_id_q
          busy_signal: axi0_r0_dynamic_busy_q
          capture_rule: axi0_r0_dynamic_id_capture
          release_rule: axi0_r0_dynamic_id_release
    generated_rules:
      - axi0_r0_response_demux
      - axi0_r1_response_demux
      - axi0_r2_response_demux
      - axi0_r3_response_demux
    generated_completion_signals:
      - axi0_r0_complete
      - axi0_r1_complete
      - axi0_r2_complete
      - axi0_r3_complete
```

The existing `.280` one-dynamic plus one-static burst-last read mode and
`.303` one-dynamic plus two-static burst-last read mode must remain
unchanged.

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

The expected assertion names are:

```text
axi0_r0_dynamic_request_not_busy
axi0_r1_static_request_not_busy
axi0_r2_static_request_not_busy
axi0_r3_static_request_not_busy
axi0_read_mixed_dynamic_static_request_onehot0
axi0_r0_r1_read_dynamic_request_not_static_id
axi0_r0_r1_read_dynamic_active_not_static_id
axi0_r0_r2_read_dynamic_request_not_static_id
axi0_r0_r2_read_dynamic_active_not_static_id
axi0_r0_r3_read_dynamic_request_not_static_id
axi0_r0_r3_read_dynamic_active_not_static_id
axi0_read_mixed_dynamic_static_response_active_match
axi0_r0_r1_read_mixed_dynamic_static_response_unique_match
axi0_r0_r2_read_mixed_dynamic_static_response_unique_match
axi0_r0_r3_read_mixed_dynamic_static_response_unique_match
axi0_r1_r2_read_mixed_dynamic_static_response_unique_match
axi0_r1_r3_read_mixed_dynamic_static_response_unique_match
axi0_r2_r3_read_mixed_dynamic_static_response_unique_match
axi0_r0_dynamic_completion_active
axi0_r1_static_completion_active
axi0_r2_static_completion_active
axi0_r3_static_completion_active
```

The generated response-demux residue should remain:

```yaml
residue:
  - same_id_ordering
  - read_data_interleaving
  - bursts
```

Read-data, raw `ARLEN`, runtime validation, and multi-beat output-bank
residue must stay explicit until later owners consume the new three-static
mixed burst-last completion or raw matched-beat boundary.

## Sample And Support Accounting

The support-accounting entry should be:

```text
intent.ppif_axi_manager_capacity_status_read_mixed_dynamic_static_response_demux_multi_static3_burst_last
```

The coverage label should follow the local PPIF naming pattern:

```text
ial2_ppif_manager_capacity_status_read_mixed_dynamic_static_response_demux_multi_static3_burst_last_pipeline_cli
```

The focused dynamic test behavior label should be:

```text
mixed_dynamic_static_read_rlast_demux_multi_static3
```

## Diagnostics And Fail-Closed Boundaries

`.326` should keep fail-closed behavior outside the selected contract and
sharpen diagnostics for:

- missing dynamic read transaction in the selected three-static burst-last
  family;
- more than one dynamic read transaction in this first three-static
  burst-last family;
- fewer or more than three concrete static read transactions in this first
  three-static burst-last family;
- duplicate static concrete IDs;
- static concrete ID values outside the declared read ID-family width;
- missing `last-signal` or `last-signal` width when `response-scope` is
  `burst-last`;
- `last-signal` used with `response-scope single-beat`;
- `last_signal_width` other than one bit;
- read-data over three-static mixed read burst-last response-demux before
  that contract is selected;
- burst-length/runtime validation over three-static mixed read burst-last
  response-demux before that contract is selected;
- multi-beat output banks over three-static mixed read burst-last
  response-demux before that contract is selected;
- read `auto-id-lifecycle` combined with dynamic mixed response-demux;
- `same-id-ordering.read` combined with dynamic mixed response-demux;
- generated completion names colliding with the raw response event; and
- partial read transaction coverage.

## Validation Gates

The `.326` implementation should run focused gates:

```bash
perl -Iperl -c perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm
perl -c perl/FSM/Support/RegressionCorpus.pm
perl -c t/1438-axi-ial2-manager-dynamic-transaction-id-focused.t
perl -c t/248-regression-corpus-accounting.t
env FSMGEN_DYNAMIC_CASE_FILTER=mixed_dynamic_static_read_rlast_demux_multi_static3 FSMGEN_DYNAMIC_SKIP_CLI_JSON=1 prove -Iperl t/1438-axi-ial2-manager-dynamic-transaction-id-focused.t
prove -Iperl t/248-regression-corpus-accounting.t
scripts/run_with_ram_guard.sh --host-max-pct 88 --process-max-rss-mb 4096 -- ./bin/fsmgen --quiet --emit-schedule-json ppif/axi_manager_capacity_status_read_mixed_dynamic_static_response_demux_multi_static3_burst_last.ppif
scripts/run_with_ram_guard.sh --host-max-pct 88 --process-max-rss-mb 4096 -- ./bin/fsmgen --strict --check --json ppif/axi_manager_capacity_status_read_mixed_dynamic_static_response_demux_multi_static3_burst_last.ppif
scripts/run_with_ram_guard.sh --host-max-pct 88 --process-max-rss-mb 4096 -- ./bin/fsmgen --strict --emit-semantic-json ppif/axi_manager_capacity_status_read_mixed_dynamic_static_response_demux_multi_static3_burst_last.ppif
scripts/run_with_ram_guard.sh --host-max-pct 88 --process-max-rss-mb 4096 -- ./bin/fsmgen --quiet --verify-hdl ppif/axi_manager_capacity_status_read_mixed_dynamic_static_response_demux_multi_static3_burst_last.ppif
bash knowledge-map/scripts/gen_knowledge_map.sh
bash knowledge-map/scripts/check_knowledge_map.sh
mdbook build docs/book
scripts/check_memory_architecture.sh
git --no-pager diff --check
scripts/check_doctrines.sh
```

The implementation should also preserve the existing one-static burst-last,
two-static burst-last, three-static single-beat, and two-static read-data
boundaries. If broad focused suites are CPU- or memory-bound in the
interactive environment, record the bounded caveat and use direct public
sample schedule/check/semantic and HDL probes plus focused syntax and
support-accounting coverage as the closeout evidence.

For `.325`, documentation-only validation is Knowledge Map generation/check,
mdBook build, memory architecture check, diff whitespace check, and doctrine
gate. No positive generator or HDL probe is required because behavior remains
unchanged and the fail-closed boundary was already audited in `.324`.

## Explicit Residue

The following remain future owners:

- direct implementation of the selected `.326` one-dynamic plus three-static
  mixed dynamic/static read burst-last `RID && RLAST` response-demux
  contract;
- scalar read-data over three-static mixed read demux;
- burst-length/runtime validation and multi-beat output banks over
  three-static mixed read demux;
- two-dynamic plus one-static mixed dynamic/static cardinality;
- broader mixed write and read cardinalities;
- same-cycle request widening beyond onehot0;
- same-cycle release and recapture;
- dynamic same-ID queues and scoreboards;
- direct backend behavior;
- backend-language variants; and
- VHDL.

## Rollback

Rollback is the `.325` contract-selection commit. Reverting it restores
`.325` as the active contract selector after `.324`; reverting the future
`.326` implementation should remove only generated three-static mixed read
burst-last behavior, its public sample, support-accounting entry, tests,
docs, and fact card.
