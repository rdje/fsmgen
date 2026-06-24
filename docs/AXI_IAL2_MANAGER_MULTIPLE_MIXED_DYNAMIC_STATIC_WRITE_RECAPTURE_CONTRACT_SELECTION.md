# AXI IAL2 Manager Multiple Mixed Dynamic/Static Write Recapture Contract Selection

Task-tree owner: `IAL2-FEATURE-COMPLETENESS-FRONTIER.399`

Date: 2026-06-24

## Decision

`IAL2-FEATURE-COMPLETENESS-FRONTIER.399` selects
`IAL2-FEATURE-COMPLETENESS-FRONTIER.400`, direct implementation of
one-dynamic plus two-static mixed dynamic/static write `BID` same-cycle
release-and-recapture for the existing support-accounted public sample:

```text
ppif/axi_manager_capacity_status_write_mixed_dynamic_static_response_demux_multi_static.ppif
```

The selector changes no parser, generator, PPIF sample, support-accounting
catalog, validation behavior, generated artifact, test, schedule/check or
semantic JSON, HDL, or runtime behavior.

## Existing Public Shape

The selected implementation must preserve the existing source syntax:

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

The write ID family remains:

```lisp
(id-families
  (write (width 4) (request-id axi0_awid) (response-id axi0_bid)))
```

No new public syntax is selected. The implementation owner remains bounded to
exactly one dynamic write transaction and exactly two pairwise-distinct
concrete static write transactions in the selected public sample.

## Selected Report Contract

`.400` must preserve:

- top-level and write `mode: bounded_multi_mixed_dynamic_static_write_bid_demux_contract`;
- `transaction_completion_source: generated_multi_mixed_dynamic_static_demux`;
- `transaction_completion_semantics: matched_dynamic_or_static_concrete_id`;
- public source path and support-accounting identity;
- `dynamic_transactions: [w0]`;
- `static_transactions: [w1, w2]`;
- `mixed_transactions: { dynamic: [w0], static: [w1, w2] }`;
- `static_id_reservations` for `w1` at concrete ID `3` / `4'd3` and `w2` at
  concrete ID `5` / `4'd5`, each with
  `dynamic_capture_policy: dynamic_id_must_not_equal_static_concrete_id`;
- generated demux rules `axi0_w0_response_demux`,
  `axi0_w1_response_demux`, and `axi0_w2_response_demux`; and
- generated completion signals `axi0_w0_complete`, `axi0_w1_complete`, and
  `axi0_w2_complete`.

The dynamic capture report should keep the existing list shape and add
recapture fields to the covered transaction entry:

```yaml
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
      release_recapture_rule: axi0_w0_dynamic_id_release_recapture
      same_cycle_release_recapture_policy: mixed_dynamic_static_dynamic_write
      release_recapture_source: generated_multi_mixed_dynamic_static_demux_completion
      release_recapture_transaction: w0
```

The static concrete-ID busy lifecycle should be reported through a new
list-shaped `response_demux.write.static_capture` block ordered like
`static_transactions`:

```yaml
static_capture:
  - transaction: w1
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
    release_recapture_source: generated_multi_mixed_dynamic_static_demux_completion
    release_recapture_transaction: w1
  - transaction: w2
    concrete_id: 5
    concrete_id_literal: 4'd5
    capture_event_source: admitted_static_write_request
    ownership: mixed_dynamic_static_concrete_write_id
    simultaneous_request_policy: onehot0_mixed_write_request
    busy_signal: axi0_w2_static_busy_q
    capture_rule: axi0_w2_static_busy_capture
    release_rule: axi0_w2_static_busy_release
    release_recapture_rule: axi0_w2_static_busy_release_recapture
    same_cycle_release_recapture_policy: mixed_dynamic_static_static_write
    release_recapture_source: generated_multi_mixed_dynamic_static_demux_completion
    release_recapture_transaction: w2
```

The selected report shape keeps internal `dynamic_transaction_state` and
`static_transaction_state` as implementation details. The public report should
show the recapture contract through `dynamic_capture.transactions[]` and
`static_capture[]`.

## Selected Rule Contract

The dynamic release-only rule should clear `axi0_w0_dynamic_busy_q` only when:

```text
axi0_w0_complete && axi0_w0_dynamic_busy_q && !axi0_w0_request
```

The dynamic release-recapture rule should:

- require the admitted `w0` dynamic write request;
- require `axi0_w0_complete`;
- require `axi0_w0_dynamic_busy_q`;
- require no admitted `w1` static write request;
- require no admitted `w2` static write request;
- require `axi0_awid != 4'd3`;
- require `axi0_awid != 4'd5`; and
- update `axi0_w0_dynamic_id_q = axi0_awid` while keeping
  `axi0_w0_dynamic_busy_q = 1`.

The static release-only rules should clear only the matched static busy slot:

```text
axi0_w1_complete && axi0_w1_static_busy_q && !axi0_w1_request
axi0_w2_complete && axi0_w2_static_busy_q && !axi0_w2_request
```

The `w1` static release-recapture rule should:

- require the admitted `w1` static write request;
- require `axi0_w1_complete`;
- require `axi0_w1_static_busy_q`;
- require no admitted `w0` dynamic write request;
- require no admitted `w2` static write request; and
- keep `axi0_w1_static_busy_q = 1`.

The `w2` static release-recapture rule should:

- require the admitted `w2` static write request;
- require `axi0_w2_complete`;
- require `axi0_w2_static_busy_q`;
- require no admitted `w0` dynamic write request;
- require no admitted `w1` static write request; and
- keep `axi0_w2_static_busy_q = 1`.

All response matching continues to use pre-update state in the same cycle; the
recapture updates the next-cycle selected ID or static busy state after the
generated completion pulse has been matched.

## Selected Assertion Contract

The generated assertion list should replace only the selected request-not-busy
assertions with idle-or-releasing names:

```text
axi0_w0_dynamic_request_idle_or_releasing
axi0_w1_static_request_idle_or_releasing
axi0_w2_static_request_idle_or_releasing
axi0_write_mixed_dynamic_static_request_onehot0
axi0_w0_w1_write_dynamic_request_not_static_id
axi0_w0_w1_write_dynamic_active_not_static_id
axi0_w0_w2_write_dynamic_request_not_static_id
axi0_w0_w2_write_dynamic_active_not_static_id
axi0_write_mixed_dynamic_static_response_active_match
axi0_w0_w1_write_mixed_dynamic_static_response_unique_match
axi0_w0_w2_write_mixed_dynamic_static_response_unique_match
axi0_w1_w2_write_mixed_dynamic_static_response_unique_match
axi0_w0_dynamic_completion_active
axi0_w1_static_completion_active
axi0_w2_static_completion_active
```

The dynamic idle-or-releasing assertion should mean:

```text
axi0_w0_request -> (!axi0_w0_dynamic_busy_q || axi0_w0_complete)
```

The static idle-or-releasing assertions should mean:

```text
axi0_w1_request -> (!axi0_w1_static_busy_q || axi0_w1_complete)
axi0_w2_request -> (!axi0_w2_static_busy_q || axi0_w2_complete)
```

The mixed request onehot0, dynamic request/static-ID exclusions, active
dynamic/static-ID exclusions, response active-match, pairwise response
unique-match, and completion-active assertions must remain preserved.

## Validation For .400

The implementation should run:

```bash
perl -c perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm
perl -c t/1436-ial2-ppif-parser-cli.t
perl -c t/1437-axi-ial2-manager-capacity-status-generator.t
perl -c t/1438-axi-ial2-manager-dynamic-transaction-id-focused.t
scripts/run_with_ram_guard.sh -- env -u PERL5LIB ./bin/fsmgen --quiet --emit-schedule-json ppif/axi_manager_capacity_status_write_mixed_dynamic_static_response_demux_multi_static.ppif
scripts/run_with_ram_guard.sh -- env FSMGEN_DYNAMIC_CASE_FILTER=mixed_dynamic_static_write_demux_multi_static FSMGEN_DYNAMIC_SKIP_CLI_JSON=1 prove -l t/1438-axi-ial2-manager-dynamic-transaction-id-focused.t
bash knowledge-map/scripts/gen_knowledge_map.sh
bash knowledge-map/scripts/check_knowledge_map.sh
mdbook build docs/book
scripts/check_memory_architecture.sh
git --no-pager diff --check
scripts/check_doctrines.sh
```

Broader `t/1436`/`t/1437`, strict check, semantic JSON, generated HDL, and
`--verify-hdl` probes should run under the RAM guard where host memory permits.
If the guard stops them, `.400` should record the cutoff and rely on focused
report/IAL1/FSM probes plus the focused dynamic case.

## Deferred Boundaries

`.399` does not implement behavior. One-dynamic plus three-static recapture,
two-dynamic-plus-one-static recapture, read single-beat broader mixed
recapture, read burst-last broader mixed recapture, read-data/raw-ARLEN/
runtime/multi-beat consumers, static-busy-only recapture outside the selected
mixed sample, request arbitration beyond onehot0, dynamic same-ID queues,
scoreboards, queued/blocking policy, profile aliases, direct backend behavior,
backend-language variants, VHDL, and full AXI manager behavior remain later
exact owners.

## Rollback

Rollback is the `.399` selector commit. Reverting it restores `.399` as the
active public contract-selection frontier and removes `.400` as the selected
implementation owner.
