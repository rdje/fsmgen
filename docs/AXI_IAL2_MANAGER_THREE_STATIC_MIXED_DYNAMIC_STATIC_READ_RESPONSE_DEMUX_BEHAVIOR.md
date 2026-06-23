# AXI IAL2 Manager Three-Static Mixed Dynamic/Static Read Response-Demux Behavior

Task-tree owner: `IAL2-FEATURE-COMPLETENESS-FRONTIER.322`

Date: 2026-06-23

## Outcome

`IAL2-FEATURE-COMPLETENESS-FRONTIER.322` ships generated bounded read
single-beat `RID` response-demux behavior for one dynamic read transaction
plus three concrete static read transactions.

The public support-accounted sample is:

```text
ppif/axi_manager_capacity_status_read_mixed_dynamic_static_response_demux_multi_static3.ppif
```

The sample uses existing public syntax. It declares `r0` with `(id dynamic)`
and `r1`, `r2`, and `r3` with concrete read IDs `3`, `5`, and `7`.
`response-demux.read` uses `axi0_read_complete` as the raw accepted read
response event, `response-scope single-beat`, and generated
transaction-completion outputs for all four read transactions.

## Generated Contract

The shipped report mode remains the existing list-shaped multi-mixed read
single-beat contract:

```text
bounded_multi_mixed_dynamic_static_read_rid_demux_contract
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
- single-beat `RID` response-demux rules and generated completion pulses for
  all four read transactions;
- static-ID reservations for `4'd3`, `4'd5`, and `4'd7`;
- dynamic capture exclusions against all three static IDs;
- the existing mixed read request `onehot0` assertion;
- dynamic request/active static-ID exclusion assertions for each static ID;
- response active-match and pairwise unique-match assertions across all four
  read transactions; and
- completion-active assertions for the dynamic and static transactions.

## Boundary

This slice is read single-beat only. The existing burst-last mixed
dynamic/static read boundary still admits only one dynamic read plus one or
two concrete static reads. Read-data over the three-static boundary,
burst-length/runtime validation, multi-beat output banks, two-dynamic-plus
static shapes, general capped mixed sets, same-cycle request widening,
release-and-recapture, dynamic same-ID queues, scoreboards, direct backend
behavior, backend-language variants, VHDL, profile aliases, queued/blocking
policy, and full-manager behavior remain future exact-owner work.

Mixed dynamic/static read single-beat response-demux remains fail-closed
outside the selected bounded shapes: exactly one dynamic read transaction plus
one, two, or three pairwise-distinct concrete static read transactions.

## Validation

Validation for this slice covered the public sample, support-accounting entry,
existing one-static/two-static preservation cases, and adjacent burst-last and
read-data preservation cases:

- syntax checks for `AxiManagerCapacityStatus.pm`, `RegressionCorpus.pm`,
  `t/1438`, and `t/248` passed;
- filtered focused `t/1438` for `mixed_dynamic_static_read_demux_multi_static3`
  passed with CLI JSON skipped;
- preservation filters passed for the existing one-static read demux,
  two-static read demux, two-static read burst-last demux, and two-static
  read-data single-beat capture samples;
- `t/248-regression-corpus-accounting.t` passed `1..4442`;
- guarded direct schedule JSON passed and confirmed the expected mode,
  transaction lists, static-ID reservations, generated rules, and generated
  completions;
- guarded strict check JSON passed and matched support accounting entry
  `intent.ppif_axi_manager_capacity_status_read_mixed_dynamic_static_response_demux_multi_static3`;
- guarded strict semantic JSON passed and matched the same support-accounting
  entry; and
- guarded `--verify-hdl` passed for the public sample.
