# AXI IAL2 Manager Three-Static Mixed Dynamic/Static Read Recapture Contract Selection

Task-tree owner: `IAL2-FEATURE-COMPLETENESS-FRONTIER.418`

Date: 2026-06-24

## Decision

`IAL2-FEATURE-COMPLETENESS-FRONTIER.418` selects
`IAL2-FEATURE-COMPLETENESS-FRONTIER.419`, direct implementation of
one-dynamic-plus-three-static mixed dynamic/static read single-beat `RID`
same-cycle release-and-recapture for the existing support-accounted public
sample:

```text
ppif/axi_manager_capacity_status_read_mixed_dynamic_static_response_demux_multi_static3.ppif
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
    (response-scope single-beat)
    (transaction-completion generated)))
```

No new public syntax is selected. The implementation is bounded to exactly
one dynamic read transaction, exactly three pairwise-distinct concrete static
read transactions, and `response-scope single-beat`.

## Selected Report Contract

`.419` must preserve:

- top-level and read `mode:
  bounded_multi_mixed_dynamic_static_read_rid_demux_contract`;
- `response_scope: single_beat`;
- `transaction_completion_source:
  generated_multi_mixed_dynamic_static_read_demux`;
- `transaction_completion_semantics:
  matched_dynamic_or_static_concrete_id_single_beat`;
- public source path and support-accounting identity;
- `dynamic_transactions: [r0]`;
- `static_transactions: [r1, r2, r3]`;
- `mixed_transactions: { dynamic: [r0], static: [r1, r2, r3] }`;
- `static_id_reservations` for `r1` at `4'd3`, `r2` at `4'd5`, and `r3` at
  `4'd7`, each with
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
      release_recapture_source: generated_multi_mixed_dynamic_static_read_demux_completion
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
    release_recapture_source: generated_multi_mixed_dynamic_static_read_demux_completion
    release_recapture_transaction: r3
```

## Selected Rule Contract

The response-demux match rules remain single-beat matches over pre-update
state:

```text
axi0_read_complete && axi0_r0_dynamic_busy_q && axi0_rid == axi0_r0_dynamic_id_q
axi0_read_complete && axi0_r1_static_busy_q  && axi0_rid == 4'd3
axi0_read_complete && axi0_r2_static_busy_q  && axi0_rid == 4'd5
axi0_read_complete && axi0_r3_static_busy_q  && axi0_rid == 4'd7
```

The dynamic release-only rule should clear `axi0_r0_dynamic_busy_q` only when:

```text
axi0_r0_complete && axi0_r0_dynamic_busy_q && !axi0_r0_request
```

The dynamic release-recapture rule should:

- require the admitted `r0` dynamic read request;
- require the generated `r0` completion pulse;
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
- require its own generated completion pulse;
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

## Preservation Requirements

`.419` must not alter parser syntax, checked-in PPIF samples,
support-accounting entries, source identity, generated response-demux match
rules, generated completion names, report mode/source/semantics, static ID
reservations, onehot0, static-ID exclusion, response active-match, pairwise
unique-match, or completion-active assertions outside the selected assertion
renames.

The one-dynamic/one-static mixed read recapture report must keep singular
`static_capture`.

The one-dynamic-plus-two-static mixed read single-beat and burst-last
recapture reports must keep their existing selected shapes and release
sources.

The one-dynamic-plus-three-static burst-last read report must remain outside
this owner: no `static_capture`, no release-recapture fields, and
request-not-busy assertions remain there until a later exact owner selects
burst-last recapture.

The two-dynamic-plus-one-static read reports must remain outside this owner.

Three-static read-data/raw-`ARLEN`/runtime/multi-beat consumers must remain
unchanged.

## Validation Requirements

Implementation `.419` should run:

```bash
perl -Iperl -c perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm
perl -c t/1438-axi-ial2-manager-dynamic-transaction-id-focused.t
scripts/run_with_ram_guard.sh -- env -u PERL5LIB ./bin/fsmgen --quiet --emit-schedule-json ppif/axi_manager_capacity_status_read_mixed_dynamic_static_response_demux_multi_static3.ppif
```

Where RAM permits, `.419` should also run guarded strict check JSON,
semantic JSON, SystemVerilog generation, `--verify-hdl`, and focused `t/1438`
coverage for `mixed_dynamic_static_read_demux_multi_static3`. If broad probes
trip the default 88% host RAM cutoff, do not raise the cutoff; record the
guarded stop and rely on smaller direct probes that exercise the selected
contract and adjacent preservation boundaries.

Continuity closeout must cover Knowledge Map generation/check, mdBook build,
memory architecture check, docs relative path check, diff whitespace check,
and doctrine checks.

## Deferred Boundaries

One-dynamic-plus-three-static burst-last read recapture,
two-dynamic-plus-one-static read recapture, layered recapture-specific
consumer changes, static-busy-only recapture outside selected public samples,
request arbitration beyond onehot0, dynamic same-ID queues, scoreboards,
queued/blocking policy, profile aliases, direct backend behavior,
backend-language variants, VHDL, and full AXI manager behavior remain later
exact owners.

## Rollback

Rollback is the `.418` selector commit. Reverting it removes the contract
selection, fact card, task-tree advancement to `.419`, README/ROADMAP/mdBook
status, Memory pointer update, and Knowledge Map entry, restoring `.418` as
the active contract-selection leaf. No generated behavior changes in this
selector.
