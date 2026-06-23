# AXI IAL2 Manager Broader Mixed Dynamic/Static Cardinality Contract Selection

Task-tree owner: `IAL2-FEATURE-COMPLETENESS-FRONTIER.317`

Date: 2026-06-23

## Outcome

`IAL2-FEATURE-COMPLETENESS-FRONTIER.317` selects
`IAL2-FEATURE-COMPLETENESS-FRONTIER.318`, direct generated behavior for
bounded one-dynamic plus three-concrete-static write `BID` response-demux.

This is the first broader mixed dynamic/static transaction-cardinality step
after the one-dynamic plus one- or two-static mixed response-demux/read-data
ladder reached multi-beat output banks.

No parser, generator, PPIF sample, support-accounting catalog, validation
behavior, generated artifact, test, schedule/check/semantic JSON, or HDL
behavior changes in `.317`.

## Selected Public Shape

The selected `.318` public sample stem is:

```text
ppif/axi_manager_capacity_status_write_mixed_dynamic_static_response_demux_multi_static3.ppif
```

The shape is intentionally narrow:

- write family only;
- exactly one dynamic write transaction, `w0`;
- exactly three concrete static write transactions, `w1`, `w2`, and `w3`;
- pairwise-distinct concrete static write IDs, proposed as `4'd3`, `4'd5`,
  and `4'd7`;
- generated write response-demux with raw `BID` response matching;
- generated transaction completions for all four transactions; and
- no read response-demux, read-data, burst-length/runtime validation,
  multi-beat output-bank, same-cycle widening, queue, scoreboard, direct
  backend, backend-language variant, or VHDL behavior.

The source syntax should be the existing public syntax: no new parser form is
selected. `.318` should only add the new sample, support-accounting entry,
and bounded admission/report/generation support for the selected shape.

## Report Contract

`.318` should reuse the existing multiple mixed report vocabulary:

```text
response_demux.mode = bounded_multi_mixed_dynamic_static_write_bid_demux_contract
response_demux.write.mode = bounded_multi_mixed_dynamic_static_write_bid_demux_contract
response_demux.write.transaction_completion_source =
  generated_multi_mixed_dynamic_static_demux
response_demux.write.transaction_completion_semantics =
  matched_dynamic_or_static_concrete_id
response_demux.write.dynamic_transactions = [w0]
response_demux.write.static_transactions = [w1, w2, w3]
response_demux.write.mixed_transactions.dynamic = [w0]
response_demux.write.mixed_transactions.static = [w1, w2, w3]
```

The three-static cardinality should be machine-readable through the list
fields rather than through a new mode name. `static_id_reservations`,
`generated_rules`, `generated_completion_signals`, generated assertions, and
`dynamic_capture.static_id_exclusions` should likewise expand to cover all
three concrete static transactions.

Expected generated completion signals and response-demux rules are:

```text
axi0_w0_complete
axi0_w1_complete
axi0_w2_complete
axi0_w3_complete

axi0_w0_response_demux
axi0_w1_response_demux
axi0_w2_response_demux
axi0_w3_response_demux
```

The existing mixed dynamic/static request onehot and response active/unique
assertion vocabulary should be reused, with pairwise dynamic-vs-static
exclusion assertions for `w0` against each static ID and pairwise response
unique-match assertions across all four transactions.

## Why This Shape First

One dynamic plus three static write transactions is the smallest broader
cardinality step because it extends the current multi-static branch without
introducing multiple dynamic captured-ID interactions. The current code
already loops over static states for static busy state, static ID
reservations, static ID exclusions, response-demux rules, generated
completion signals, and pairwise response assertions. The main implementation
question is therefore a bounded admission/report/test widening, not a new
dynamic ID policy.

Two dynamic plus one static is deliberately deferred. It needs a selected
policy for dynamic-vs-dynamic selected-ID uniqueness, simultaneous dynamic
request handling, dynamic capture ordering, and report vocabulary before it
can be implemented safely.

## Diagnostics

`.318` should fail closed with explicit diagnostics for:

- any broader write mixed shape other than one dynamic plus one, two, or the
  selected three concrete static transactions;
- duplicate concrete static write IDs;
- missing or malformed write ID family metadata;
- mixed dynamic/static response-demux combined with write auto-ID lifecycle or
  same-ID ordering policy, preserving the current exclusions; and
- unsupported read-side or read-data attempts for the three-static shape.

## Validation Strategy

`.318` should run:

- syntax checks for touched Perl modules and focused tests;
- filtered `t/1438-axi-ial2-manager-dynamic-transaction-id-focused.t` coverage
  for the new `multi_static3` write-demux case;
- `t/248-regression-corpus-accounting.t` after adding the support-accounted
  public sample;
- direct schedule/check/semantic/verify-HDL probes for the new public sample
  under the RAM guard where host memory permits;
- preservation filters for the existing one-static and two-static mixed write
  demux samples and adjacent read/read-data samples; and
- mdBook, Knowledge Map, memory, diff, and doctrine gates.

## Explicit Residue

Read single-beat response-demux, read burst-last response-demux, scalar
read-data, burst-length/runtime validation, and multi-beat output banks for
the three-static shape remain future owners. Two dynamic plus one static,
general capped mixed dynamic/static sets, same-cycle request widening,
release-and-recapture, dynamic same-ID queues, scoreboards, direct backend
behavior, backend-language variants, VHDL, profile aliases, queued/blocking
policy, and full-manager behavior remain separate exact owners.

## Rollback

Rollback is documentation-only for `.317`: remove this contract note, remove
its Knowledge Map fact card, restore `.317` to pending, and restore Memory,
README, ROADMAP_V2, mdBook, and task-tree frontier pointers to the
post-`.316` state.
