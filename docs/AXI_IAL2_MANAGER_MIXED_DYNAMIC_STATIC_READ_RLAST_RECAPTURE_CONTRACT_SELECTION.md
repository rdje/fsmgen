# AXI IAL2 Manager Mixed Dynamic Static Read RLAST Recapture Contract Selection

Task-tree owner: `IAL2-FEATURE-COMPLETENESS-FRONTIER.395`

Date: 2026-06-24

## Decision

`IAL2-FEATURE-COMPLETENESS-FRONTIER.395` selects
`IAL2-FEATURE-COMPLETENESS-FRONTIER.396`, direct implementation of mixed
dynamic/static read burst-last `RID && RLAST` same-cycle
release-and-recapture for the existing support-accounted public sample:

```text
ppif/axi_manager_capacity_status_read_mixed_dynamic_static_response_demux_burst_last.ppif
```

The contract selection changes no parser, generator, PPIF sample,
support-accounting catalog, validation behavior, generated artifact, test,
schedule/check or semantic JSON, HDL, or runtime behavior.

## Public Shape

The selected implementation must preserve the current explicit mixed
dynamic/static read burst-last source shape:

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

No new source syntax is selected. The contract remains bounded to exactly one
dynamic read transaction, exactly one concrete static read transaction,
`response-scope burst-last`, and one one-bit `last-signal`.

## Baseline Evidence

`.394` ran a guarded baseline schedule probe:

```bash
scripts/run_with_ram_guard.sh -- env -u PERL5LIB ./bin/fsmgen --quiet --emit-schedule-json ppif/axi_manager_capacity_status_read_mixed_dynamic_static_response_demux_burst_last.ppif
```

The guard passed at 83.0% host memory against the 88% cutoff. The live report
still shows:

```text
mode=bounded_mixed_dynamic_static_read_rid_rlast_demux_contract
response_scope=burst_last
last_signal=axi0_rlast
transaction_completion_source=generated_mixed_dynamic_static_read_demux_last_beat
transaction_completion_semantics=matched_dynamic_or_static_concrete_id_and_last_signal
generated_assertions=axi0_r0_dynamic_request_not_busy, axi0_r1_static_request_not_busy, axi0_read_mixed_dynamic_static_request_onehot0, axi0_r0_dynamic_request_not_static_id, axi0_r0_dynamic_active_not_static_id, axi0_read_mixed_dynamic_static_response_active_match, axi0_r0_r1_read_mixed_dynamic_static_response_unique_match, axi0_r0_dynamic_completion_active, axi0_r1_static_completion_active
dynamic_release_recapture=none
static_capture=none
```

## Selected Report Contract

`.396` should preserve:

- top-level and read `mode:
  bounded_mixed_dynamic_static_read_rid_rlast_demux_contract`;
- `response_scope: burst_last`;
- `last_signal: axi0_rlast`;
- `last_signal_width: 1`;
- `transaction_completion_source:
  generated_mixed_dynamic_static_read_demux_last_beat`;
- `transaction_completion_semantics:
  matched_dynamic_or_static_concrete_id_and_last_signal`;
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
release_recapture_source: generated_mixed_dynamic_static_read_demux_last_beat_completion
release_recapture_transaction: r0
```

The static concrete-ID busy lifecycle should be reported through
`response_demux.read.static_capture`:

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
  release_recapture_source: generated_mixed_dynamic_static_read_demux_last_beat_completion
  release_recapture_transaction: r1
```

The selected policy names intentionally reuse the `.392` mixed read policy
strings. The last-beat distinction is carried by
`release_recapture_source`, matching the dynamic read `RLAST` contract pattern
where source spelling differentiates final-beat recapture.

## Selected Rule Contract

The response-demux match rules must remain final-beat matches:

```text
axi0_read_complete && axi0_r0_dynamic_busy_q && axi0_rid == axi0_r0_dynamic_id_q && axi0_rlast
axi0_read_complete && axi0_r1_static_busy_q  && axi0_rid == 4'd3                 && axi0_rlast
```

The dynamic release-only rule should clear `axi0_r0_dynamic_busy_q` only when:

```text
axi0_r0_complete && axi0_r0_dynamic_busy_q && !axi0_r0_request
```

The dynamic release-recapture rule should:

- require the admitted dynamic read request;
- require the generated dynamic final `RID && RLAST` completion pulse;
- require `axi0_r0_dynamic_busy_q`;
- require no admitted static read request in the same cycle;
- require `axi0_arid != 4'd3`; and
- update `axi0_r0_dynamic_id_q = axi0_arid` and keep
  `axi0_r0_dynamic_busy_q = 1`.

The static release-only rule should clear `axi0_r1_static_busy_q` only when:

```text
axi0_r1_complete && axi0_r1_static_busy_q && !axi0_r1_request
```

The static release-recapture rule should:

- require the admitted static read request;
- require the generated static final `RID && RLAST` completion pulse;
- require `axi0_r1_static_busy_q`;
- require no admitted dynamic read request in the same cycle; and
- keep `axi0_r1_static_busy_q = 1`.

The response match uses the pre-update selected ID and busy state. The
recapture update owns next-cycle selected-ID or busy state. Matched non-final
`RID` beats are raw-response consumers only; they must not release or
recapture either transaction.

## Selected Assertion Contract

The generated assertion list should replace the first two busy assertions with
idle-or-releasing names and preserve all other mixed read burst-last
assertions:

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

Because `axi0_r0_complete` and `axi0_r1_complete` are generated final-beat
completion pulses, non-final `RID` beats do not satisfy the releasing side of
the assertion. The mixed request onehot0, dynamic request/static-ID exclusion,
active dynamic/static-ID exclusion, raw response active-match, raw response
unique-match, and completion-active assertions must remain preserved.

## Preservation Consumers

`.396` must preserve layered consumers over the generated mixed
dynamic/static read burst-last response-demux:

- scalar last-beat read-data still captures `RDATA`/`RRESP` on the generated
  mixed last-beat completion pulse for the pre-update selected ID or static
  busy slot;
- report-only raw-`ARLEN` still captures request metadata at the admitted
  request;
- runtime beat-count/`RLAST` validation still counts raw matched beats and
  checks the final `RLAST` boundary; and
- multi-beat output banks still capture every raw matched beat while final
  `RID && RLAST` completion owns transaction release.

## Selected .396 Scope

`.396` should implement only this contract for:

```text
ppif/axi_manager_capacity_status_read_mixed_dynamic_static_response_demux_burst_last.ppif
```

It should update focused t/1436/t1437/t1438 expectations, generated report
docs, README, ROADMAP_V2, mdBook, task tree, Memory, and Knowledge Map. It
should run syntax checks, guarded schedule JSON for the affected sample,
guarded focused dynamic validation where host memory permits, guarded HDL or
direct IAL1/FSM probes where useful, and continuity gates. Preservation probes
for scalar last-beat read-data, raw-`ARLEN`, runtime validation, and multi-beat
output banks should run where the RAM guard permits; if host memory blocks
broader checks, `.396` should record the cutoff and rely on direct report/
IAL1/FSM probes plus focused cases.

## Deferred Boundaries

Multiple mixed dynamic/static transaction recapture, static-busy-only
recapture outside the selected mixed read/write samples, request arbitration
beyond onehot0, dynamic same-ID queues, scoreboards, queued/blocking policy,
profile aliases, direct backend behavior, backend-language variants, VHDL, and
full AXI manager behavior remain later exact owners.

## Validation

Selector validation is documentation and continuity only:

```bash
bash knowledge-map/scripts/gen_knowledge_map.sh
bash knowledge-map/scripts/check_knowledge_map.sh
scripts/check_memory_architecture.sh
git --no-pager diff --check
mdbook build docs/book
scripts/check_doctrines.sh
```

No parser, support-accounting, strict check, semantic JSON, HDL, or focused
test rerun is required because this selector changes no behavior.

## Rollback

Rollback for the future implementation is the `.396` implementation commit.
Reverting that commit should remove only the mixed read burst-last
release-recapture rules, report fields, and assertion renames selected here,
restoring the `.280` burst-last behavior and preserving `.392` single-beat
recapture.

Rollback for this selector is the `.395` selector commit. Reverting it
restores `.395` as the active public-contract-selection frontier and removes
`.396` as the selected implementation owner.
