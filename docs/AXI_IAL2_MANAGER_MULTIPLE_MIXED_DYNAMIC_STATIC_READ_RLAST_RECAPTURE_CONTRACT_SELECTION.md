# AXI IAL2 Manager Multiple Mixed Dynamic/Static Read RLAST Recapture Contract Selection

Task-tree owner: `IAL2-FEATURE-COMPLETENESS-FRONTIER.414`

Date: 2026-06-24

## Decision

`IAL2-FEATURE-COMPLETENESS-FRONTIER.414` selects
`IAL2-FEATURE-COMPLETENESS-FRONTIER.415`, direct implementation of
one-dynamic-plus-two-static mixed dynamic/static read burst-last `RID &&
RLAST` same-cycle release-and-recapture for the existing support-accounted
public sample:

```text
ppif/axi_manager_capacity_status_read_mixed_dynamic_static_response_demux_multi_static_burst_last.ppif
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
    (id (value 5))))

(response-demux
  (read
    (response-event axi0_read_complete)
    (response-scope burst-last)
    (last-signal axi0_rlast (width 1))
    (transaction-completion generated)))
```

No new public syntax is selected. The implementation is bounded to exactly
one dynamic read transaction, exactly two pairwise-distinct concrete static
read transactions, `response-scope burst-last`, and a one-bit last signal in
the selected public sample.

## Selected Report Contract

`.415` must preserve:

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
- `static_transactions: [r1, r2]`;
- `mixed_transactions: { dynamic: [r0], static: [r1, r2] }`;
- `static_id_reservations` for `r1` at concrete ID `3` / `4'd3` and
  `r2` at concrete ID `5` / `4'd5`, each with
  `dynamic_capture_policy: dynamic_id_must_not_equal_static_concrete_id`;
- generated demux rules `axi0_r0_response_demux`,
  `axi0_r1_response_demux`, and `axi0_r2_response_demux`; and
- generated completion signals `axi0_r0_complete`, `axi0_r1_complete`, and
  `axi0_r2_complete`.

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
```

The selected policy names intentionally reuse the shipped mixed read policy
strings. The final-beat distinction is carried by
`release_recapture_source`, matching the one-dynamic/one-static mixed read
RLAST recapture pattern and the multiple mixed read burst-last completion
source.

## Selected Rule Contract

The response-demux match rules must remain final-beat matches over pre-update
state:

```text
axi0_read_complete && axi0_r0_dynamic_busy_q && axi0_rid == axi0_r0_dynamic_id_q && axi0_rlast
axi0_read_complete && axi0_r1_static_busy_q  && axi0_rid == 4'd3                 && axi0_rlast
axi0_read_complete && axi0_r2_static_busy_q  && axi0_rid == 4'd5                 && axi0_rlast
```

The dynamic release-only rule should clear `axi0_r0_dynamic_busy_q` only when:

```text
axi0_r0_complete && axi0_r0_dynamic_busy_q && !axi0_r0_request
```

The dynamic release-recapture rule should:

- require the admitted `r0` dynamic read request;
- require the generated `r0` final `RID && RLAST` completion pulse;
- require `axi0_r0_dynamic_busy_q`;
- require no admitted `r1` or `r2` static read request;
- require `axi0_arid != 4'd3`;
- require `axi0_arid != 4'd5`; and
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
```

The `r1` static release-recapture rule should:

- require the admitted `r1` static read request;
- require the generated `r1` final `RID && RLAST` completion pulse;
- require `axi0_r1_static_busy_q`;
- require no admitted `r0` dynamic read request;
- require no admitted `r2` static read request; and
- keep `axi0_r1_static_busy_q = 1`.

The `r2` static release-recapture rule should:

- require the admitted `r2` static read request;
- require the generated `r2` final `RID && RLAST` completion pulse;
- require `axi0_r2_static_busy_q`;
- require no admitted `r0` dynamic read request;
- require no admitted `r1` static read request; and
- keep `axi0_r2_static_busy_q = 1`.

The selected static release-recapture rules are:

```text
axi0_r1_static_busy_release_recapture
axi0_r2_static_busy_release_recapture
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
```

with these idle-or-releasing assertions:

```text
axi0_r0_dynamic_request_idle_or_releasing
axi0_r1_static_request_idle_or_releasing
axi0_r2_static_request_idle_or_releasing
```

All other mixed read burst-last assertions remain preserved, including the
mixed request onehot0 assertion, dynamic request/static-ID exclusions, active
dynamic/static-ID exclusions, raw response active-match, pairwise raw
response unique-match assertions, and completion-active assertions.

The idle-or-releasing side must be satisfied only by generated final-beat
completion pulses. Raw non-final `RID` beats must not satisfy the releasing
side.

## Preservation Consumers

`.415` must preserve layered consumers over the generated multiple mixed
dynamic/static read burst-last response-demux:

- `.396` one-dynamic-plus-one-static mixed read burst-last recapture keeps
  singular `static_capture` and
  `generated_mixed_dynamic_static_read_demux_last_beat_completion`;
- `.303` one-dynamic-plus-two-static mixed read burst-last response-demux
  keeps mode, final completion source, raw beat assertions, and generated
  completion rules;
- `.307` scalar last-beat read-data keeps
  `generated_multi_mixed_dynamic_static_read_response_demux_last_beat_completion_pulse`;
- `.310` report-only raw-`ARLEN` capture keeps request-captured ARLEN and no
  runtime assertions;
- `.312` runtime beat-count/`RLAST` validation keeps raw matched-beat
  counters and runtime assertions;
- `.314` multi-beat output banks keep raw matched-beat lane capture and final
  completion/release boundaries;
- `.326` three-static read burst-last response-demux remains no-recapture;
  and
- `.347` two-dynamic-plus-one-static read burst-last response-demux remains
  no-recapture.

## Implementation Owner Requirements

`.415` should only mark the selected two-static burst-last read branch for
recapture. The expected local implementation boundary is the current
multi-mixed burst-last read normalizer plus focused report/test expectations.
It should not add PPIF syntax, support-accounting entries, public samples,
parser behavior, IAL1/IAL0 primitives, direct backend behavior, VHDL, or
broader mixed cardinalities.

The implementation owner should run syntax checks for touched Perl/tests and
guarded selected probes where RAM permits:

```bash
scripts/run_with_ram_guard.sh -- env -u PERL5LIB ./bin/fsmgen --quiet --emit-schedule-json ppif/axi_manager_capacity_status_read_mixed_dynamic_static_response_demux_multi_static_burst_last.ppif
scripts/run_with_ram_guard.sh -- env -u PERL5LIB ./bin/fsmgen --quiet --strict --check --json ppif/axi_manager_capacity_status_read_mixed_dynamic_static_response_demux_multi_static_burst_last.ppif
scripts/run_with_ram_guard.sh -- env -u PERL5LIB ./bin/fsmgen --quiet --strict --emit-semantic-json ppif/axi_manager_capacity_status_read_mixed_dynamic_static_response_demux_multi_static_burst_last.ppif
scripts/run_with_ram_guard.sh -- env -u PERL5LIB ./bin/fsmgen --quiet --output /tmp/fsmgen_multi_static_read_rlast_recapture.sv ppif/axi_manager_capacity_status_read_mixed_dynamic_static_response_demux_multi_static_burst_last.ppif
scripts/run_with_ram_guard.sh -- env -u PERL5LIB ./bin/fsmgen --quiet --verify-hdl --output /tmp/fsmgen_multi_static_read_rlast_recapture_verify.sv ppif/axi_manager_capacity_status_read_mixed_dynamic_static_response_demux_multi_static_burst_last.ppif
```

Focused `t/1438` should use the selected burst-last filter and
`FSMGEN_DYNAMIC_SKIP_CLI_JSON=1` when needed to avoid the known high-memory
CLI JSON path. Direct adapter probes should verify the selected report and
the preservation siblings if the focused suite trips the RAM guard.

## Deferred Boundaries

One-dynamic-plus-three-static read recapture, two-dynamic-plus-one-static
read recapture, static-busy-only recapture outside selected public samples,
request arbitration beyond onehot0, dynamic same-ID queues, scoreboards,
queued/blocking policy, profile aliases, direct backend behavior,
backend-language variants, VHDL, and full AXI manager behavior remain later
exact owners.

## Rollback

Rollback is the `.414` selector commit. Reverting it removes the contract
selection record, fact card, task-tree advancement to `.415`,
README/ROADMAP/mdBook status, Memory pointer update, and Knowledge Map entry,
restoring `.414` as the active contract-selection leaf.
