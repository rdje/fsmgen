# AXI IAL2 Manager Mixed Dynamic Static Read Recapture Contract Selection

Task-tree owner: `IAL2-FEATURE-COMPLETENESS-FRONTIER.391`

Date: 2026-06-24

## Decision

`IAL2-FEATURE-COMPLETENESS-FRONTIER.391` selects
`IAL2-FEATURE-COMPLETENESS-FRONTIER.392`, direct implementation of mixed
dynamic/static read single-beat `RID` same-cycle release-and-recapture for the
existing support-accounted public sample:

```text
ppif/axi_manager_capacity_status_read_mixed_dynamic_static_response_demux.ppif
```

The selector changes no parser, generator, PPIF sample, support-accounting
catalog, validation behavior, generated artifact, test, schedule/check or
semantic JSON, HDL, or runtime behavior.

## Existing Public Shape

The selected implementation must preserve the current explicit mixed read
single-beat source shape:

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
    (response-scope single-beat)
    (transaction-completion generated)))
```

The read ID family remains:

```lisp
(id-families
  (read (width 4) (request-id-signal axi0_arid) (response-id-signal axi0_rid)))
```

No new source syntax is selected. The contract remains bounded to exactly one
dynamic read transaction, exactly one concrete static read transaction, and
`response-scope single-beat`.

## Baseline Evidence

The selector ran a guarded baseline schedule probe:

```bash
scripts/run_with_ram_guard.sh -- env -u PERL5LIB ./bin/fsmgen --quiet --emit-schedule-json ppif/axi_manager_capacity_status_read_mixed_dynamic_static_response_demux.ppif
```

The current report still shows:

```text
mode=bounded_mixed_dynamic_static_read_rid_demux_contract
response_scope=single_beat
transaction_completion_source=generated_mixed_dynamic_static_read_demux
transaction_completion_semantics=matched_dynamic_or_static_concrete_id_single_beat
generated_assertions=axi0_r0_dynamic_request_not_busy, axi0_r1_static_request_not_busy, axi0_read_mixed_dynamic_static_request_onehot0, axi0_r0_dynamic_request_not_static_id, axi0_r0_dynamic_active_not_static_id, axi0_read_mixed_dynamic_static_response_active_match, axi0_r0_r1_read_mixed_dynamic_static_response_unique_match, axi0_r0_dynamic_completion_active, axi0_r1_static_completion_active
dynamic_capture_keys=busy_signal, capture_event_source, capture_rule, ownership, release_rule, request_id_source, selected_id_signal, simultaneous_request_policy, static_id_conflict_policy
dynamic_release_recapture=none
static_capture=none
```

## Selected Report Contract

`.392` should preserve:

- top-level and read `mode: bounded_mixed_dynamic_static_read_rid_demux_contract`;
- `response_scope: single_beat`;
- `transaction_completion_source: generated_mixed_dynamic_static_read_demux`;
- `transaction_completion_semantics:
  matched_dynamic_or_static_concrete_id_single_beat`;
- public source path and support-accounting identity;
- `dynamic_transactions: [r0]`;
- `static_transactions: [r1]`;
- `mixed_transactions: { dynamic: r0, static: r1 }`;
- `static_id_reservation` with concrete ID `3`, literal `4'd3`, and
  `dynamic_id_must_not_equal_static_concrete_id`;
- generated demux rules `axi0_r0_response_demux` and
  `axi0_r1_response_demux`; and
- generated completion signals `axi0_r0_complete` and `axi0_r1_complete`.

The dynamic recapture fields should be added under
`response_demux.read.dynamic_capture`:

```yaml
release_recapture_rule: axi0_r0_dynamic_id_release_recapture
same_cycle_release_recapture_policy: mixed_dynamic_static_dynamic_read
release_recapture_source: generated_mixed_dynamic_static_read_demux_completion
release_recapture_transaction: r0
```

The static concrete-ID busy lifecycle should be reported through a new
`response_demux.read.static_capture` block:

```yaml
static_capture:
  transaction: r1
  concrete_id: 3
  concrete_id_literal: 4'd3
  capture_event_source: admitted_static_read_request
  ownership: mixed_dynamic_static_concrete_read_id
  simultaneous_request_policy: onehot0_mixed_read_request
  busy_signal: axi0_r1_static_busy_q
  capture_rule: axi0_r1_static_busy_capture
  release_rule: axi0_r1_static_busy_release
  release_recapture_rule: axi0_r1_static_busy_release_recapture
  same_cycle_release_recapture_policy: mixed_dynamic_static_static_read
  release_recapture_source: generated_mixed_dynamic_static_read_demux_completion
  release_recapture_transaction: r1
```

The `static_capture` block is selected for parity with `.389` write recapture.
It keeps the public report shape parallel to `dynamic_capture` while
documenting that static read recapture updates only the concrete busy slot, not
a selected ID register.

## Selected Rule Contract

The dynamic release-only rule should clear `axi0_r0_dynamic_busy_q` only when
`axi0_r0_complete && axi0_r0_dynamic_busy_q && !axi0_r0_request`.

The dynamic release-recapture rule should:

- require the admitted dynamic read request;
- require the generated dynamic completion pulse;
- require `axi0_r0_dynamic_busy_q`;
- require no admitted static read request in the same cycle;
- require `axi0_arid != 4'd3`; and
- update `axi0_r0_dynamic_id_q = axi0_arid` and keep
  `axi0_r0_dynamic_busy_q = 1`.

The static release-only rule should clear `axi0_r1_static_busy_q` only when
`axi0_r1_complete && axi0_r1_static_busy_q && !axi0_r1_request`.

The static release-recapture rule should:

- require the admitted static read request;
- require the generated static completion pulse;
- require `axi0_r1_static_busy_q`;
- require no admitted dynamic read request in the same cycle; and
- keep `axi0_r1_static_busy_q = 1`.

The implementation should keep ordinary dynamic capture, static capture, and
dynamic/static cross-transaction request-plus-completion cycles legal where the
existing onehot0 request and static-ID reservation rules allow them. This
selector only widens same-transaction request plus generated completion for
the selected single-beat read sample.

## Selected Assertion Contract

The generated assertion list should replace the first two busy assertions with
idle-or-releasing names and preserve all other mixed read assertions:

```text
axi0_r0_dynamic_request_idle_or_releasing
axi0_r1_static_request_idle_or_releasing
axi0_read_mixed_dynamic_static_request_onehot0
axi0_r0_dynamic_request_not_static_id
axi0_r0_dynamic_active_not_static_id
axi0_read_mixed_dynamic_static_response_active_match
axi0_r0_r1_read_mixed_dynamic_static_response_unique_match
axi0_r0_dynamic_completion_active
axi0_r1_static_completion_active
```

The dynamic idle-or-releasing assertion should mean:

```text
axi0_r0_request -> (!axi0_r0_dynamic_busy_q || axi0_r0_complete)
```

The static idle-or-releasing assertion should mean:

```text
axi0_r1_request -> (!axi0_r1_static_busy_q || axi0_r1_complete)
```

The mixed request onehot0, dynamic request/static-ID exclusion, active
dynamic/static-ID exclusion, response active-match, response unique-match, and
completion-active assertions must remain preserved.

## Validation For .392

The implementation should run:

```bash
perl -Iperl -c perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm
perl -c t/1436-ial2-ppif-parser-cli.t
perl -c t/1437-axi-ial2-manager-capacity-status-generator.t
perl -c t/1438-axi-ial2-manager-dynamic-transaction-id-focused.t
scripts/run_with_ram_guard.sh -- env -u PERL5LIB ./bin/fsmgen --quiet --emit-schedule-json ppif/axi_manager_capacity_status_read_mixed_dynamic_static_response_demux.ppif
scripts/run_with_ram_guard.sh -- env FSMGEN_DYNAMIC_CASE_FILTER=mixed_dynamic_static_read_demux FSMGEN_DYNAMIC_SKIP_CLI_JSON=1 prove -l t/1438-axi-ial2-manager-dynamic-transaction-id-focused.t
bash knowledge-map/scripts/gen_knowledge_map.sh
bash knowledge-map/scripts/check_knowledge_map.sh
mdbook build docs/book
scripts/check_memory_architecture.sh
git --no-pager diff --check
scripts/check_doctrines.sh
```

Broader t/1436/t1437, strict check, semantic JSON, generated HDL, and
`--verify-hdl` probes should be run under the RAM guard where host memory
permits. If the guard stops them, `.392` should record the cutoff and rely on
direct report/IAL1/FSM probes plus the focused dynamic case.

## Deferred Boundaries

`.391` does not implement behavior. Mixed read burst-last recapture, multiple
mixed dynamic/static transaction recapture, static-busy-only recapture outside
the selected public samples, request arbitration beyond onehot0, dynamic
same-ID queues, scoreboards, queued/blocking policy, profile aliases, direct
backend behavior, backend-language variants, VHDL, and full AXI manager
behavior remain later exact owners.

## Validation

Selector validation is the guarded baseline schedule probe above plus
continuity gates:

```bash
bash knowledge-map/scripts/gen_knowledge_map.sh
bash knowledge-map/scripts/check_knowledge_map.sh
mdbook build docs/book
scripts/check_memory_architecture.sh
git --no-pager diff --check
scripts/check_doctrines.sh
```

No focused generator, parser, support-accounting, strict check, semantic JSON,
or HDL probes are required because this selector changes no behavior.

## Rollback

Rollback is the `.391` selector commit. Reverting it restores `.391` as the
active public contract-selection frontier and removes `.392` as the selected
implementation owner.
