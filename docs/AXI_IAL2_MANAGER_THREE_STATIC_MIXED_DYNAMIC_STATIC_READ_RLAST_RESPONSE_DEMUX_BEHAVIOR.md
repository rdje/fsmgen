# AXI IAL2 Manager Three-Static Mixed Dynamic/Static Read RLAST Response-Demux Behavior

Task-tree owner: `IAL2-FEATURE-COMPLETENESS-FRONTIER.326`

Date: 2026-06-23

## Outcome

`IAL2-FEATURE-COMPLETENESS-FRONTIER.326` ships generated bounded read
burst-last `RID && RLAST` response-demux behavior for one dynamic read
transaction plus three concrete static read transactions.

The public support-accounted sample is:

```text
ppif/axi_manager_capacity_status_read_mixed_dynamic_static_response_demux_multi_static3_burst_last.ppif
```

The sample uses existing public syntax. It declares dynamic read transaction
`r0` and concrete static read transactions `r1`, `r2`, and `r3` with concrete
read IDs `3`, `5`, and `7`. `response-demux.read` uses
`axi0_read_complete` as the raw accepted read response-beat event,
`response-scope burst-last`, one one-bit `last-signal` named `axi0_rlast`,
and generated transaction-completion outputs for all four read transactions.

## Generated Contract

The shipped report mode remains the existing list-shaped multi-mixed read
burst-last contract:

```text
bounded_multi_mixed_dynamic_static_read_rid_rlast_demux_contract
```

No new report mode is introduced. Cardinality is visible through existing
list fields:

```text
response_demux.read.dynamic_transactions = [r0]
response_demux.read.static_transactions = [r1, r2, r3]
response_demux.read.mixed_transactions.dynamic = [r0]
response_demux.read.mixed_transactions.static = [r1, r2, r3]
```

Generated behavior includes:

- dynamic selected-ID and busy state for `r0`;
- static busy state for `r1`, `r2`, and `r3`;
- generated response-demux completion rules for all four transactions gated
  by both raw `RID` ownership and `RLAST`;
- static-ID reservations for `4'd3`, `4'd5`, and `4'd7`;
- dynamic capture exclusions against all three static IDs;
- the existing mixed read request `onehot0` assertion;
- dynamic request/active static-ID exclusion assertions for each static ID;
- raw `RID` response active-match and pairwise unique-match assertions across
  all four read transactions; and
- completion-active assertions for the dynamic and static transactions.

Raw read-beat ownership assertions intentionally do not include `RLAST`.
They prove that every accepted response beat belongs to one active selected
transaction by `RID`. The generated completion pulses additionally require
`RLAST`, so non-final matching beats do not release any transaction.

The completion source is:

```text
generated_multi_mixed_dynamic_static_read_demux_last_beat
```

and the completion semantics are:

```text
matched_dynamic_or_static_concrete_id_and_last_signal
```

## Boundary

This slice is response-demux only. It widens the generated mixed
dynamic/static read burst-last demux boundary from one dynamic plus one or two
static reads to one dynamic plus one, two, or three pairwise-distinct concrete
static reads.

Read-data over the three-static boundary, raw `ARLEN` burst-length capture,
runtime beat-count/`RLAST` validation, multi-beat output banks,
two-dynamic-plus-static shapes, general capped mixed sets, same-cycle request
widening, release-and-recapture, dynamic same-ID queues, scoreboards, direct
backend behavior, backend-language variants, VHDL, profile aliases,
queued/blocking policy, and full-manager behavior remain future exact-owner
work.

Mixed dynamic/static read-data remains capped to the previously selected
one-dynamic plus one- or two-concrete-static generated demux shapes. The
three-static read-data boundary remains fail-closed until a later owner
selects it explicitly.

## Validation

Validation for this slice covered the new public sample, support-accounting
entry, existing two-static burst-last behavior, three-static single-beat
behavior, and the two-static last-beat read-data boundary:

- syntax checks passed for `AxiManagerCapacityStatus.pm`,
  `RegressionCorpus.pm`, `t/1438`, and `t/248`;
- filtered focused `t/1438` for
  `mixed_dynamic_static_read_rlast_demux_multi_static3` passed with CLI JSON
  skipped;
- preservation filters passed for the existing three-static single-beat read
  demux, two-static burst-last read demux, and two-static last-beat read-data
  samples;
- `t/248-regression-corpus-accounting.t` passed `1..4454`;
- guarded direct schedule JSON passed for the new sample;
- guarded strict check JSON passed and matched support accounting entry
  `intent.ppif_axi_manager_capacity_status_read_mixed_dynamic_static_response_demux_multi_static3_burst_last`;
- guarded strict semantic JSON passed and matched the same support-accounting
  entry; and
- guarded `--verify-hdl` passed for the public sample.

## Rollback

Rollback is the `.326` implementation commit. Reverting it removes the
public three-static mixed read burst-last PPIF sample, support-accounting
entry, generated admission widening, focused coverage, docs, and fact card,
restoring `.326` as the active frontier.
