# AXI IAL2 Manager Broader Mixed Dynamic/Static Write Response-Demux Behavior

Task-tree owner: `IAL2-FEATURE-COMPLETENESS-FRONTIER.318`

Date: 2026-06-23

## Outcome

`IAL2-FEATURE-COMPLETENESS-FRONTIER.318` ships generated bounded write
`BID` response-demux behavior for the first broader mixed dynamic/static
transaction-cardinality shape: one dynamic write transaction plus three
concrete static write transactions.

The public sample is:

```text
ppif/axi_manager_capacity_status_write_mixed_dynamic_static_response_demux_multi_static3.ppif
```

The sample uses the existing public syntax. It declares `w0` with
`(id dynamic)` and `w1`, `w2`, and `w3` with concrete write IDs `3`, `5`, and
`7`. `response-demux.write` uses `axi0_write_complete` as its response event
and generated transaction-completion outputs for all four transactions.

## Generated Contract

The shipped report mode remains the existing list-shaped multi-mixed write
contract:

```text
bounded_multi_mixed_dynamic_static_write_bid_demux_contract
```

No new report mode is introduced. Cardinality is visible through existing
list fields:

```text
response_demux.write.dynamic_transactions = [w0]
response_demux.write.static_transactions = [w1, w2, w3]
response_demux.write.mixed_transactions.dynamic = [w0]
response_demux.write.mixed_transactions.static = [w1, w2, w3]
```

Generated behavior includes:

- dynamic selected-ID and busy state for `w0`;
- static busy state for `w1`, `w2`, and `w3`;
- response-demux rules and generated completion pulses for all four
  transactions;
- static-ID reservations for `4'd3`, `4'd5`, and `4'd7`;
- dynamic capture exclusions against all three static IDs;
- the existing mixed write request `onehot0` assertion;
- dynamic request/active static-ID exclusion assertions for each static ID;
- response active-match and pairwise unique-match assertions across all four
  transactions; and
- completion-active assertions for the dynamic and static transactions.

## Boundary

This slice is write-family only. Read single-beat response-demux, read
burst-last response-demux, read-data, burst-length/runtime validation,
multi-beat output banks, two-dynamic-plus-static shapes, general capped mixed
sets, same-cycle request widening beyond generated release-and-recapture,
dynamic same-ID queues, scoreboards, direct backend behavior,
backend-language variants, VHDL, profile aliases, queued/blocking policy, and
full-manager behavior remain future exact-owner work.

Mixed dynamic/static write response-demux remains fail-closed outside the
selected bounded shapes: exactly one dynamic write transaction plus one, two,
or three pairwise-distinct concrete static write transactions.

## Same-Cycle Recapture Extension

`IAL2-FEATURE-COMPLETENESS-FRONTIER.403` extends this same public sample with
same-cycle release-and-recapture. Public syntax, support-accounting identity,
mode, response-demux match rules, generated completions, static-ID
reservations, onehot0 policy, static-ID exclusion assertions, response
active-match assertions, pairwise unique-match assertions, and
completion-active assertions remain unchanged.

The extension adds `axi0_w0_dynamic_id_release_recapture`,
`axi0_w1_static_busy_release_recapture`,
`axi0_w2_static_busy_release_recapture`, and
`axi0_w3_static_busy_release_recapture`. Dynamic recapture requires an
admitted `w0` request, generated `w0` completion, active dynamic busy state,
no admitted `w1`/`w2`/`w3` request, and an `axi0_awid` value different from
all three static IDs. Each static recapture requires its own admitted static
request, own generated completion, own active busy state, no admitted dynamic
request, and no sibling static request.

The report adds dynamic recapture fields under
`response_demux.write.dynamic_capture.transactions[0]` and list-shaped
`response_demux.write.static_capture[]` entries for `w1`, `w2`, and `w3`.

## Validation

Validation for this slice covered the public sample, support-accounting entry,
existing one-static/two-static preservation cases, and adjacent read/read-data
preservation cases:

- syntax checks for the touched Perl modules and focused tests passed;
- filtered focused `t/1438` for `multi_static3` passed 86 assertions with CLI
  JSON skipped;
- `t/248-regression-corpus-accounting.t` passed `1..4430`;
- preservation filters passed for the existing one-static write demux,
  two-static write demux, two-static read single-beat demux, and two-static
  read-data multi-beat output-bank samples;
- guarded direct schedule JSON passed and confirmed the expected mode,
  transaction lists, static-ID reservations, generated rules, and generated
  completions; and
- the guarded strict check JSON direct probe stopped at host memory 95.0%
  versus the required 88% cutoff, so heavier direct check/semantic/verify-HDL
  probes were not forced while the host was above the memory danger zone.
- Knowledge Map regeneration/check, mdBook build, docs path audit, memory
  architecture check, diff hygiene, and doctrine checks passed.
