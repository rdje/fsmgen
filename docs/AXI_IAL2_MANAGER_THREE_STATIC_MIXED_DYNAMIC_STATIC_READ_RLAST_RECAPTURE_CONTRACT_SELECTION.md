# AXI IAL2 Manager Three-Static Mixed Dynamic/Static Read RLAST Recapture Contract Selection

Task-tree owner: `IAL2-FEATURE-COMPLETENESS-FRONTIER.422`

Date: 2026-06-24

## Decision

`IAL2-FEATURE-COMPLETENESS-FRONTIER.422` selects
`IAL2-FEATURE-COMPLETENESS-FRONTIER.423`, direct implementation of
one-dynamic-plus-three-static mixed dynamic/static read burst-last `RID &&
RLAST` same-cycle release-and-recapture for the existing support-accounted
public sample:

```text
ppif/axi_manager_capacity_status_read_mixed_dynamic_static_response_demux_multi_static3_burst_last.ppif
```

This selector changes no parser, generator, PPIF sample, support-accounting
catalog, validation behavior, generated artifact, test expectation,
schedule/check or semantic JSON, HDL, or runtime behavior.

## Public Shape

The selected implementation must preserve the existing source syntax:

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

No new public syntax is selected. The implementation is bounded to exactly
one dynamic read transaction, exactly three pairwise-distinct concrete static
read transactions, `response-scope burst-last`, and a one-bit last signal in
the selected public sample.

## Selected Report Contract

`.423` must preserve:

- top-level and read `mode:
  bounded_multi_mixed_dynamic_static_read_rid_rlast_demux_contract`;
- `response_scope: burst_last`;
- `last_signal: axi0_rlast`;
- `last_signal_width: 1`;
- `transaction_completion_source:
  generated_multi_mixed_dynamic_static_read_demux_last_beat`;
- `transaction_completion_semantics:
  matched_dynamic_or_static_concrete_id_and_last_signal`;
- public source path and support-accounting identity;
- `dynamic_transactions: [r0]`;
- `static_transactions: [r1, r2, r3]`;
- `mixed_transactions: { dynamic: [r0], static: [r1, r2, r3] }`;
- `static_id_reservations` for `r1` at concrete ID `3` / `4'd3`, `r2` at
  concrete ID `5` / `4'd5`, and `r3` at concrete ID `7` / `4'd7`, each with
  `dynamic_capture_policy: dynamic_id_must_not_equal_static_concrete_id`;
- generated demux rules `axi0_r0_response_demux`,
  `axi0_r1_response_demux`, `axi0_r2_response_demux`, and
  `axi0_r3_response_demux`; and
- generated completion signals `axi0_r0_complete`, `axi0_r1_complete`,
  `axi0_r2_complete`, and `axi0_r3_complete`.

The dynamic capture report keeps the transaction-list shape and adds
recapture fields to `response_demux.read.dynamic_capture.transactions[0]`:

```yaml
dynamic_capture:
  transactions:
    - transaction: r0
      selected_id_signal: axi0_r0_dynamic_id_q
      busy_signal: axi0_r0_dynamic_busy_q
      capture_rule: axi0_r0_dynamic_id_capture
      release_rule: axi0_r0_dynamic_id_release
      release_recapture_rule: axi0_r0_dynamic_id_release_recapture
      same_cycle_release_recapture_policy: mixed_dynamic_static_dynamic_read
      release_recapture_source: generated_multi_mixed_dynamic_static_read_demux_last_beat_completion
      release_recapture_transaction: r0
```

The static concrete-ID busy lifecycle is reported through list-shaped
`response_demux.read.static_capture[]` entries ordered like
`static_transactions`:

```yaml
static_capture:
  - transaction: r1
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
    release_recapture_source: generated_multi_mixed_dynamic_static_read_demux_last_beat_completion
    release_recapture_transaction: r1
  - transaction: r2
    concrete_id: 5
    concrete_id_literal: 4'd5
    capture_event_source: admitted_static_read_request
    ownership: mixed_dynamic_static_concrete_read_id
    simultaneous_request_policy: onehot0_mixed_read_request
    busy_signal: axi0_r2_static_busy_q
    capture_rule: axi0_r2_static_busy_capture
    release_rule: axi0_r2_static_busy_release
    release_recapture_rule: axi0_r2_static_busy_release_recapture
    same_cycle_release_recapture_policy: mixed_dynamic_static_static_read
    release_recapture_source: generated_multi_mixed_dynamic_static_read_demux_last_beat_completion
    release_recapture_transaction: r2
  - transaction: r3
    concrete_id: 7
    concrete_id_literal: 4'd7
    capture_event_source: admitted_static_read_request
    ownership: mixed_dynamic_static_concrete_read_id
    simultaneous_request_policy: onehot0_mixed_read_request
    busy_signal: axi0_r3_static_busy_q
    capture_rule: axi0_r3_static_busy_capture
    release_rule: axi0_r3_static_busy_release
    release_recapture_rule: axi0_r3_static_busy_release_recapture
    same_cycle_release_recapture_policy: mixed_dynamic_static_static_read
    release_recapture_source: generated_multi_mixed_dynamic_static_read_demux_last_beat_completion
    release_recapture_transaction: r3
```

The selected policy names intentionally reuse the shipped mixed read policy
strings. The final-beat distinction is carried by
`release_recapture_source`, matching the shipped one-static and two-static
mixed read RLAST recapture patterns.

## Selected Rule Contract

The response-demux match rules must remain final-beat matches over pre-update
state:

```text
axi0_read_complete && axi0_r0_dynamic_busy_q && axi0_rid == axi0_r0_dynamic_id_q && axi0_rlast
axi0_read_complete && axi0_r1_static_busy_q  && axi0_rid == 4'd3                 && axi0_rlast
axi0_read_complete && axi0_r2_static_busy_q  && axi0_rid == 4'd5                 && axi0_rlast
axi0_read_complete && axi0_r3_static_busy_q  && axi0_rid == 4'd7                 && axi0_rlast
```

The dynamic release-only rule should clear `axi0_r0_dynamic_busy_q` only when:

```text
axi0_r0_complete && axi0_r0_dynamic_busy_q && !axi0_r0_request
```

The dynamic release-recapture rule should:

- require the admitted `r0` dynamic read request;
- require the generated `r0` final `RID && RLAST` completion pulse;
- require `axi0_r0_dynamic_busy_q`;
- require no admitted `r1`, `r2`, or `r3` static read request;
- require `axi0_arid != 4'd3`;
- require `axi0_arid != 4'd5`;
- require `axi0_arid != 4'd7`; and
- update `axi0_r0_dynamic_id_q = axi0_arid` while keeping
  `axi0_r0_dynamic_busy_q = 1`.

The selected dynamic release-recapture rule is:

```text
axi0_r0_dynamic_id_release_recapture
```

The static release-only rules should clear only the matched static busy slot:

```text
axi0_r1_complete && axi0_r1_static_busy_q && !axi0_r1_request
axi0_r2_complete && axi0_r2_static_busy_q && !axi0_r2_request
axi0_r3_complete && axi0_r3_static_busy_q && !axi0_r3_request
```

Each static release-recapture rule should:

- require its own admitted static read request;
- require its own generated final `RID && RLAST` completion pulse;
- require its own static busy bit;
- require no admitted `r0` dynamic read request;
- require no admitted sibling static read request; and
- keep its own static busy bit asserted.

The selected static release-recapture rules are:

```text
axi0_r1_static_busy_release_recapture
axi0_r2_static_busy_release_recapture
axi0_r3_static_busy_release_recapture
```

Matched non-final `RID` beats remain raw ownership evidence only. They must
not release or recapture any transaction before the generated final-beat
completion pulse fires.

## Selected Assertion Contract

The generated assertion list should replace these request-not-busy assertions:

```text
axi0_r0_dynamic_request_not_busy
axi0_r1_static_request_not_busy
axi0_r2_static_request_not_busy
axi0_r3_static_request_not_busy
```

with these idle-or-releasing assertions:

```text
axi0_r0_dynamic_request_idle_or_releasing
axi0_r1_static_request_idle_or_releasing
axi0_r2_static_request_idle_or_releasing
axi0_r3_static_request_idle_or_releasing
```

The following assertions must remain:

```text
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

The idle-or-releasing side must be satisfied only by generated final-beat
completion pulses. Raw non-final `RID` beats must not satisfy the releasing
side.

## Preservation Requirements

`.423` must not alter parser syntax, checked-in PPIF samples,
support-accounting entries, source identity, generated response-demux match
rules, generated completion names, report mode/source/semantics, static ID
reservations, onehot0, static-ID exclusion, response active-match, pairwise
unique-match, or completion-active assertions outside the selected assertion
renames.

The following sibling contracts must remain unchanged:

- `.396` one-dynamic-plus-one-static mixed read burst-last recapture keeps
  singular `static_capture` and
  `generated_mixed_dynamic_static_read_demux_last_beat_completion`;
- `.415` one-dynamic-plus-two-static mixed read burst-last recapture keeps
  list-shaped `static_capture[]` for `r1`/`r2` and
  `generated_multi_mixed_dynamic_static_read_demux_last_beat_completion`;
- `.419` one-dynamic-plus-three-static mixed read single-beat recapture keeps
  `generated_multi_mixed_dynamic_static_read_demux_completion`;
- `.326` three-static read burst-last response-demux keeps mode, final
  completion source, raw beat assertions, and generated completion rules
  except for the selected same-cycle recapture additions;
- `.330`, `.333`, `.335`, and `.337` three-static read-data/raw-`ARLEN`/
  runtime/multi-beat consumers keep raw matched-beat ownership and
  final-completion release boundaries; and
- `.347` two-dynamic-plus-one-static read burst-last response-demux remains
  no-recapture.

## Implementation Boundary

The behavior-bearing `.423` owner should be intentionally small:

- widen only the burst-last multi-mixed read recapture selection from exactly
  one dynamic plus two static states to exactly one dynamic plus two or three
  static states;
- update the focused RLAST report expectation helper so three-static RLAST
  recapture is expected only for the selected one-dynamic-plus-three-static
  public sample;
- preserve the existing single-beat three-static recapture behavior; and
- keep two-dynamic-plus-one-static read recapture and all broader cardinalities
  deferred.

No parser, PPIF sample, support-accounting, direct backend, VHDL, queue,
scoreboard, or full-manager behavior is selected.

## Validation Plan For `.423`

The implementation owner should run syntax checks for the generator and
focused tests, then guarded selected probes where RAM permits:

```bash
perl -Iperl -c perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm
perl -Iperl -c t/1438-axi-ial2-manager-dynamic-transaction-id-focused.t
scripts/run_with_ram_guard.sh -- env -u PERL5LIB ./bin/fsmgen --quiet --emit-schedule-json ppif/axi_manager_capacity_status_read_mixed_dynamic_static_response_demux_multi_static3_burst_last.ppif
scripts/run_with_ram_guard.sh -- env -u PERL5LIB ./bin/fsmgen --quiet --strict --check --json ppif/axi_manager_capacity_status_read_mixed_dynamic_static_response_demux_multi_static3_burst_last.ppif
scripts/run_with_ram_guard.sh -- env -u PERL5LIB ./bin/fsmgen --quiet --strict --emit-semantic-json ppif/axi_manager_capacity_status_read_mixed_dynamic_static_response_demux_multi_static3_burst_last.ppif
scripts/run_with_ram_guard.sh -- env -u PERL5LIB ./bin/fsmgen --quiet --output /tmp/fsmgen_three_static_read_rlast_recapture.sv ppif/axi_manager_capacity_status_read_mixed_dynamic_static_response_demux_multi_static3_burst_last.ppif
scripts/run_with_ram_guard.sh -- env -u PERL5LIB ./bin/fsmgen --quiet --verify-hdl --output /tmp/fsmgen_three_static_read_rlast_recapture_verify.sv ppif/axi_manager_capacity_status_read_mixed_dynamic_static_response_demux_multi_static3_burst_last.ppif
```

Focused `t/1438` should use the selected burst-last filter and
`FSMGEN_DYNAMIC_SKIP_CLI_JSON=1` when needed to avoid the known high-memory
CLI JSON path. Direct adapter or normalizer probes should verify the selected
report and the one-static, two-static, single-beat three-static,
two-dynamic-plus-one-static, and read-data/raw-`ARLEN`/runtime/multi-beat
preservation boundaries if full focused validation trips the RAM guard.

## Deferred Boundaries

Two-dynamic-plus-one-static read recapture, layered recapture-specific
consumer changes, static-busy-only recapture outside selected public mixed
samples, request arbitration beyond onehot0, dynamic same-ID queues,
scoreboards, queued/blocking policy, profile aliases, direct backend
behavior, backend-language variants, VHDL, and full AXI manager behavior
remain later exact owners.

## Rollback

Rollback is the `.422` selector commit. Reverting it removes the contract
selection record, fact card, task-tree advancement to `.423`,
README/ROADMAP/mdBook status, Memory pointer update, and Knowledge Map entry.
No generated behavior changes in this selector.
