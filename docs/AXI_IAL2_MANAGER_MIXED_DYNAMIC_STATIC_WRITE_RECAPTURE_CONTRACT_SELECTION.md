# AXI IAL2 Manager Mixed Dynamic Static Write Recapture Contract Selection

Task-tree owner: `IAL2-FEATURE-COMPLETENESS-FRONTIER.388`

Date: 2026-06-24

## Decision

`IAL2-FEATURE-COMPLETENESS-FRONTIER.388` selects
`IAL2-FEATURE-COMPLETENESS-FRONTIER.389`, direct implementation of mixed
dynamic/static write `BID` same-cycle release-and-recapture for the existing
support-accounted public sample:

```text
ppif/axi_manager_capacity_status_write_mixed_dynamic_static_response_demux.ppif
```

The selector changes no parser, generator, PPIF sample, support-accounting
catalog, validation behavior, generated artifact, test, schedule/check or
semantic JSON, HDL, or runtime behavior.

## Existing Public Shape

The selected implementation must preserve the current explicit mixed write
source shape:

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
    (id (value 3))))

(response-demux
  (write
    (response-event axi0_write_complete)
    (transaction-completion generated)))
```

The write ID family remains:

```lisp
(id-families
  (write (width 4) (request-id axi0_awid) (response-id axi0_bid)))
```

No new source syntax is selected. The contract remains bounded to exactly one
dynamic write transaction and exactly one concrete static write transaction in
the selected public sample.

## Baseline Evidence

The selector ran a guarded baseline schedule probe:

```bash
scripts/run_with_ram_guard.sh -- env -u PERL5LIB ./bin/fsmgen --quiet --emit-schedule-json ppif/axi_manager_capacity_status_write_mixed_dynamic_static_response_demux.ppif
```

The current report still shows:

```text
mode=bounded_mixed_dynamic_static_write_bid_demux_contract
transaction_completion_source=generated_mixed_dynamic_static_demux
generated_assertions=axi0_w0_dynamic_request_not_busy, axi0_w1_static_request_not_busy, axi0_write_mixed_dynamic_static_request_onehot0, axi0_w0_dynamic_request_not_static_id, axi0_w0_dynamic_active_not_static_id, axi0_write_mixed_dynamic_static_response_active_match, axi0_w0_w1_write_mixed_dynamic_static_response_unique_match, axi0_w0_dynamic_completion_active, axi0_w1_static_completion_active
dynamic_capture_keys=busy_signal, capture_event_source, capture_rule, ownership, release_rule, request_id_source, selected_id_signal, simultaneous_request_policy, static_id_conflict_policy
dynamic_release_recapture=none
static_release_recapture=none
```

## Selected Report Contract

`.389` should preserve:

- top-level and write `mode: bounded_mixed_dynamic_static_write_bid_demux_contract`;
- `transaction_completion_source: generated_mixed_dynamic_static_demux`;
- public source path and support-accounting identity;
- `dynamic_transactions: [w0]`;
- `static_transactions: [w1]`;
- `mixed_transactions: { dynamic: w0, static: w1 }`;
- `static_id_reservation` with concrete ID `3`, literal `4'd3`, and
  `dynamic_id_must_not_equal_static_concrete_id`;
- generated demux rules `axi0_w0_response_demux` and
  `axi0_w1_response_demux`; and
- generated completion signals `axi0_w0_complete` and `axi0_w1_complete`.

The dynamic recapture fields should be added under
`response_demux.write.dynamic_capture`:

```yaml
release_recapture_rule: axi0_w0_dynamic_id_release_recapture
same_cycle_release_recapture_policy: mixed_dynamic_static_dynamic_write
release_recapture_source: generated_mixed_dynamic_static_demux_completion
release_recapture_transaction: w0
```

The static concrete-ID busy lifecycle should be reported through a new
`response_demux.write.static_capture` block:

```yaml
static_capture:
  transaction: w1
  concrete_id: 3
  concrete_id_literal: 4'd3
  capture_event_source: admitted_static_write_request
  ownership: mixed_dynamic_static_concrete_write_id
  simultaneous_request_policy: onehot0_mixed_write_request
  busy_signal: axi0_w1_static_busy_q
  capture_rule: axi0_w1_static_busy_capture
  release_rule: axi0_w1_static_busy_release
  release_recapture_rule: axi0_w1_static_busy_release_recapture
  same_cycle_release_recapture_policy: mixed_dynamic_static_static_write
  release_recapture_source: generated_mixed_dynamic_static_demux_completion
  release_recapture_transaction: w1
```

The new `static_capture` block is selected instead of exposing internal
`static_transaction_state` arrays. It keeps the public report shape parallel
to `dynamic_capture` while documenting that static recapture updates only the
concrete busy slot, not a selected ID register.

## Selected Rule Contract

The dynamic release-only rule should clear `axi0_w0_dynamic_busy_q` only when
`axi0_w0_complete && axi0_w0_dynamic_busy_q && !axi0_w0_request`.

The dynamic release-recapture rule should:

- require the admitted dynamic write request;
- require the generated dynamic completion pulse;
- require `axi0_w0_dynamic_busy_q`;
- require no admitted static write request in the same cycle;
- require `axi0_awid != 4'd3`; and
- update `axi0_w0_dynamic_id_q = axi0_awid` and keep
  `axi0_w0_dynamic_busy_q = 1`.

The static release-only rule should clear `axi0_w1_static_busy_q` only when
`axi0_w1_complete && axi0_w1_static_busy_q && !axi0_w1_request`.

The static release-recapture rule should:

- require the admitted static write request;
- require the generated static completion pulse;
- require `axi0_w1_static_busy_q`;
- require no admitted dynamic write request in the same cycle; and
- keep `axi0_w1_static_busy_q = 1`.

The implementation should keep ordinary dynamic capture, static capture, and
dynamic/static cross-transaction request-plus-completion cycles legal where the
existing onehot0 request and static-ID reservation rules allow them. This
selector only widens same-transaction request plus generated completion.

## Selected Assertion Contract

The generated assertion list should replace the first two busy assertions with
idle-or-releasing names and preserve all other mixed write assertions:

```text
axi0_w0_dynamic_request_idle_or_releasing
axi0_w1_static_request_idle_or_releasing
axi0_write_mixed_dynamic_static_request_onehot0
axi0_w0_dynamic_request_not_static_id
axi0_w0_dynamic_active_not_static_id
axi0_write_mixed_dynamic_static_response_active_match
axi0_w0_w1_write_mixed_dynamic_static_response_unique_match
axi0_w0_dynamic_completion_active
axi0_w1_static_completion_active
```

The dynamic idle-or-releasing assertion should mean:

```text
axi0_w0_request -> (!axi0_w0_dynamic_busy_q || axi0_w0_complete)
```

The static idle-or-releasing assertion should mean:

```text
axi0_w1_request -> (!axi0_w1_static_busy_q || axi0_w1_complete)
```

The mixed request onehot0, dynamic request/static-ID exclusion, active
dynamic/static-ID exclusion, response active-match, response unique-match, and
completion-active assertions must remain preserved.

## Validation For .389

The implementation should run:

```bash
perl -c perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm
perl -c t/1436-ial2-ppif-parser-cli.t
perl -c t/1437-axi-ial2-manager-capacity-status-generator.t
perl -c t/1438-axi-ial2-manager-dynamic-transaction-id-focused.t
scripts/run_with_ram_guard.sh -- env -u PERL5LIB ./bin/fsmgen --quiet --emit-schedule-json ppif/axi_manager_capacity_status_write_mixed_dynamic_static_response_demux.ppif
scripts/run_with_ram_guard.sh -- env FSMGEN_DYNAMIC_CASE_FILTER=mixed_dynamic_static_write_demux FSMGEN_DYNAMIC_SKIP_CLI_JSON=1 prove -l t/1438-axi-ial2-manager-dynamic-transaction-id-focused.t
bash knowledge-map/scripts/gen_knowledge_map.sh
bash knowledge-map/scripts/check_knowledge_map.sh
mdbook build docs/book
scripts/check_memory_architecture.sh
git --no-pager diff --check
scripts/check_doctrines.sh
```

Broader t/1436/t1437, strict check, semantic JSON, generated HDL, and
`--verify-hdl` probes should be run under the RAM guard where host memory
permits. If the guard stops them, `.389` should record the cutoff and rely on
direct report/IAL1/FSM probes plus the focused dynamic case.

## Deferred Boundaries

`.388` does not implement behavior. Mixed read single-beat recapture, mixed
read burst-last recapture, multiple mixed dynamic/static transaction
recapture, static-busy-only recapture outside the selected mixed write sample,
request arbitration beyond onehot0, dynamic same-ID queues, scoreboards,
queued/blocking policy, profile aliases, direct backend behavior,
backend-language variants, VHDL, and full AXI manager behavior remain later
exact owners.

## Rollback

Rollback is the `.388` selector commit. Reverting it restores `.388` as the
active public contract-selection frontier and removes `.389` as the selected
implementation owner.
