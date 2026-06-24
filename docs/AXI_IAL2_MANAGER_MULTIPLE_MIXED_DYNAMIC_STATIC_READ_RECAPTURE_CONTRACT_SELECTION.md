# AXI IAL2 Manager Multiple Mixed Dynamic/Static Read Recapture Contract Selection

Task-tree owner: `IAL2-FEATURE-COMPLETENESS-FRONTIER.410`

Date: 2026-06-24

## Decision

`IAL2-FEATURE-COMPLETENESS-FRONTIER.410` selects
`IAL2-FEATURE-COMPLETENESS-FRONTIER.411`, direct implementation of
one-dynamic-plus-two-static mixed dynamic/static read single-beat `RID`
same-cycle release-and-recapture for the existing support-accounted public
sample:

```text
ppif/axi_manager_capacity_status_read_mixed_dynamic_static_response_demux_multi_static.ppif
```

This selector changes no parser, generator, PPIF sample, support-accounting
catalog, validation behavior, generated artifact, test, schedule/check or
semantic JSON, HDL, or runtime behavior.

## Baseline Evidence

The selector ran a guarded baseline schedule probe:

```bash
scripts/run_with_ram_guard.sh -- env -u PERL5LIB ./bin/fsmgen --quiet --emit-schedule-json ppif/axi_manager_capacity_status_read_mixed_dynamic_static_response_demux_multi_static.ppif
```

The probe completed below the default cutoff:

```text
host memory at launch: 83.5%
host cutoff: 88%
schedule output: 44021 bytes
```

The live report still has `axi0_r0_dynamic_request_not_busy`,
`axi0_r1_static_request_not_busy`, and
`axi0_r2_static_request_not_busy`, no `static_capture`, and no
release-recapture fields under
`response_demux.read.dynamic_capture.transactions[]`.

## Existing Public Shape

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
    (response-scope single-beat)
    (transaction-completion generated)))
```

The read ID family remains:

```lisp
(id-families
  (read (width 4) (request-id axi0_arid) (response-id axi0_rid)))
```

No new public source syntax is selected. The implementation owner is bounded
to exactly one dynamic read transaction and exactly two pairwise-distinct
concrete static read transactions in the selected public sample.

## Selected Report Contract

`.411` must preserve:

- top-level and read `mode: bounded_multi_mixed_dynamic_static_read_rid_demux_contract`;
- `response_scope: single_beat`;
- `transaction_completion_source: generated_multi_mixed_dynamic_static_read_demux`;
- `transaction_completion_semantics: matched_dynamic_or_static_concrete_id_single_beat`;
- public source path and support-accounting identity;
- `dynamic_transactions: [r0]`;
- `static_transactions: [r1, r2]`;
- `mixed_transactions: { dynamic: [r0], static: [r1, r2] }`;
- `static_id_reservations` for `r1` at concrete ID `3` / `4'd3` and `r2` at
  concrete ID `5` / `4'd5`, each with
  `dynamic_capture_policy: dynamic_id_must_not_equal_static_concrete_id`;
- generated demux rules `axi0_r0_response_demux`,
  `axi0_r1_response_demux`, and `axi0_r2_response_demux`; and
- generated completion signals `axi0_r0_complete`, `axi0_r1_complete`, and
  `axi0_r2_complete`.

The dynamic capture report keeps the existing transaction-list shape and adds
recapture fields to the covered dynamic transaction entry:

```yaml
dynamic_capture:
  request_id_source: axi0_arid
  capture_event_source: admitted_dynamic_read_request
  ownership: multi_mixed_dynamic_static_unique_read_ids
  simultaneous_request_policy: onehot0_mixed_read_request
  static_id_conflict_policy: static_concrete_ids_reserved
  static_id_exclusions: [4'd3, 4'd5]
  transactions:
    - transaction: r0
      selected_id_signal: axi0_r0_dynamic_id_q
      busy_signal: axi0_r0_dynamic_busy_q
      capture_rule: axi0_r0_dynamic_id_capture
      release_rule: axi0_r0_dynamic_id_release
      release_recapture_rule: axi0_r0_dynamic_id_release_recapture
      same_cycle_release_recapture_policy: mixed_dynamic_static_dynamic_read
      release_recapture_source: generated_multi_mixed_dynamic_static_read_demux_completion
      release_recapture_transaction: r0
```

The static concrete-ID busy lifecycle is reported through a new list-shaped
`response_demux.read.static_capture` block ordered like `static_transactions`:

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
    release_recapture_source: generated_multi_mixed_dynamic_static_read_demux_completion
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
    release_recapture_source: generated_multi_mixed_dynamic_static_read_demux_completion
    release_recapture_transaction: r2
```

The selected report shape keeps internal `dynamic_transaction_state` and
`static_transaction_state` as implementation details. The public report should
show the recapture contract through `dynamic_capture.transactions[]` and
`static_capture[]`.

The existing one-dynamic/one-static mixed read recapture report keeps its
singular `static_capture` shape and
`generated_mixed_dynamic_static_read_demux_completion` release-recapture
source. This selector only chooses the list-shaped static capture form for the
multi-mixed one-dynamic/two-static read mode.

## Selected Rule Contract

The dynamic release-only rule should clear `axi0_r0_dynamic_busy_q` only when:

```text
axi0_r0_complete && axi0_r0_dynamic_busy_q && !axi0_r0_request
```

The dynamic release-recapture rule should:

- require the admitted `r0` dynamic read request;
- require `axi0_r0_complete`;
- require `axi0_r0_dynamic_busy_q`;
- require no admitted `r1` static read request;
- require no admitted `r2` static read request;
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
- require `axi0_r1_complete`;
- require `axi0_r1_static_busy_q`;
- require no admitted `r0` dynamic read request;
- require no admitted `r2` static read request; and
- keep `axi0_r1_static_busy_q = 1`.

The `r2` static release-recapture rule should:

- require the admitted `r2` static read request;
- require `axi0_r2_complete`;
- require `axi0_r2_static_busy_q`;
- require no admitted `r0` dynamic read request;
- require no admitted `r1` static read request; and
- keep `axi0_r2_static_busy_q = 1`.

The selected static release-recapture rules are:

```text
axi0_r1_static_busy_release_recapture
axi0_r2_static_busy_release_recapture
```

All response matching continues to use pre-update state in the same cycle; the
recapture updates the next-cycle selected ID or static busy state after the
generated completion pulse has been matched.

## Selected Assertion Contract

The selected implementation replaces these request-not-busy assertions:

```text
axi0_r0_dynamic_request_not_busy
axi0_r1_static_request_not_busy
axi0_r2_static_request_not_busy
```

with:

```text
axi0_r0_dynamic_request_idle_or_releasing
axi0_r1_static_request_idle_or_releasing
axi0_r2_static_request_idle_or_releasing
```

The implementation must preserve:

- `axi0_read_mixed_dynamic_static_request_onehot0`;
- `axi0_r0_r1_read_dynamic_request_not_static_id`;
- `axi0_r0_r1_read_dynamic_active_not_static_id`;
- `axi0_r0_r2_read_dynamic_request_not_static_id`;
- `axi0_r0_r2_read_dynamic_active_not_static_id`;
- `axi0_read_mixed_dynamic_static_response_active_match`;
- `axi0_r0_r1_read_mixed_dynamic_static_response_unique_match`;
- `axi0_r0_r2_read_mixed_dynamic_static_response_unique_match`;
- `axi0_r1_r2_read_mixed_dynamic_static_response_unique_match`; and
- completion-active assertions for `r0`, `r1`, and `r2`.

The dynamic idle-or-releasing assertion should mean:

```text
axi0_r0_request -> (!axi0_r0_dynamic_busy_q || axi0_r0_complete)
```

The static idle-or-releasing assertions should mean:

```text
axi0_r1_request -> (!axi0_r1_static_busy_q || axi0_r1_complete)
axi0_r2_request -> (!axi0_r2_static_busy_q || axi0_r2_complete)
```

The mixed request onehot0, dynamic request/static-ID exclusions, active
dynamic/static-ID exclusions, response active-match, pairwise response
unique-match, and completion-active assertions must remain preserved.

## Read-Data Preservation Contract

The implementation must preserve scalar single-beat read-data consumers over
the same generated multiple mixed read demux completions. In particular,
`ppif/axi_manager_capacity_status_read_mixed_dynamic_static_response_demux_multi_static_read_data.ppif`
must keep:

- `read_data.mode: bounded_single_beat_read_data_contract`;
- `read_data.read.completion_validity:
  generated_multi_mixed_dynamic_static_read_response_demux_completion_pulse`;
- `read_data.read.transactions: [r0, r1, r2]`;
- generated read-data capture rules
  `axi0_r0_read_data_capture`, `axi0_r1_read_data_capture`, and
  `axi0_r2_read_data_capture`; and
- no raw-`ARLEN`, runtime beat-count, multi-beat output-bank, or burst-last
  behavior change.

## Validation Gates

`.411` should run:

- Perl syntax checks for touched generator/test files;
- guarded schedule JSON for the selected one-dynamic/two-static mixed read
  single-beat sample where host RAM permits;
- guarded focused `t/1438` for
  `mixed_dynamic_static_read_demux_multi_static` where host RAM permits;
- guarded preservation probes for the existing one-dynamic/one-static mixed
  read recapture sample and the scalar single-beat multiple mixed read-data
  sample where host RAM permits;
- Knowledge Map generation/check;
- mdBook build;
- memory architecture check;
- diff whitespace check; and
- doctrine checks.

Broader strict check, semantic JSON, generated HDL, and `--verify-hdl` probes
should run under the RAM guard where host memory permits. If the guard stops
them, `.411` should record the cutoff and rely on focused report/IAL1/FSM
probes plus the focused dynamic case. No RAM cutoff increase is selected.

## Deferred Boundaries

`.410` does not implement behavior. One-dynamic plus two-static mixed read
burst-last recapture, one-dynamic plus three-static read recapture,
two-dynamic-plus-one-static read recapture, raw non-final `RID` preservation
for burst-last recapture, read-data/raw-`ARLEN`/runtime/multi-beat behavior
changes, static-busy-only recapture outside selected public mixed samples,
request arbitration beyond onehot0, dynamic same-ID queues, scoreboards,
queued/blocking policy, profile aliases, direct backend behavior,
backend-language variants, VHDL, and full AXI manager behavior remain later
exact owners.

## Rollback

Rollback is the `.410` selector commit. Reverting it restores `.410` as the
active public contract-selection frontier and removes `.411` as the selected
implementation owner.
