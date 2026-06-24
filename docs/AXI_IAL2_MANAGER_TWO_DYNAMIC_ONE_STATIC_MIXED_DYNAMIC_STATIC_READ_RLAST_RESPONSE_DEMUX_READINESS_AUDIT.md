# AXI IAL2 Manager Two-Dynamic/One-Static Mixed Dynamic/Static Read RLAST Response-Demux Readiness Audit

Task-tree owner: `IAL2-FEATURE-COMPLETENESS-FRONTIER.345`

Date: 2026-06-24

## Decision

`IAL2-FEATURE-COMPLETENESS-FRONTIER.345` selects
`IAL2-FEATURE-COMPLETENESS-FRONTIER.346`, public contract selection for
bounded two-dynamic-plus-one-static mixed dynamic/static read burst-last
`RID`/`RLAST` response-demux.

Direct implementation is close but intentionally not selected yet. The
single-beat `.344` behavior now supplies the two-dynamic-plus-one-static
mixed selected-ID/busy-state substrate, and the existing `.303`/`.326`
burst-last mixed dynamic/static read paths already define final-beat
completion semantics. The exact public contract still needs one owned
selector before code changes, because it combines both axes:

- multiple active dynamic selected IDs that must remain pairwise unique; and
- static concrete-ID reservation/exclusion plus final `RID && RLAST`
  completion.

This audit changes no parser, generator, PPIF sample, support-accounting
catalog, validation behavior, generated artifact, test, schedule/check or
semantic JSON, or HDL behavior.

## Current Boundary

`.344` ships exactly two dynamic read transactions plus one concrete static
read transaction for `response-demux.read` with `response-scope single-beat`.
The public sample is:

```text
ppif/axi_manager_capacity_status_read_mixed_dynamic_static_response_demux_multi_dynamic.ppif
```

The shipped single-beat report mode and completion source are:

```text
bounded_multi_mixed_dynamic_static_read_rid_demux_contract
generated_multi_mixed_dynamic_static_read_demux
```

The burst-last mixed read path remains capped to one dynamic read transaction
plus one, two, or three concrete static read transactions. A scratch
RAM-guarded strict-check probe for the proposed two-dynamic-plus-one-static
burst-last shape failed closed with the current diagnostic:

```text
AXI manager capacity/status IAL2 contract response_demux.read mixed dynamic/static burst-last ID matching supports exactly one dynamic read transaction plus one, two, or three pairwise-distinct concrete static read transactions in this slice
```

That diagnostic confirms `.345` is a selection/audit slice, not an
already-shipped behavior slice.

## Prior Contracts Read

The audit used these prior behavior and selector records:

- `.344` two-dynamic-plus-one-static mixed dynamic/static read single-beat
  behavior;
- `.343` public single-beat contract selection;
- `.341` two-dynamic-plus-one-static mixed dynamic/static write `BID`
  behavior;
- `.251` multiple all-dynamic read single-beat behavior;
- `.255` multiple all-dynamic read burst-last behavior;
- `.299` one-dynamic plus two-static mixed read single-beat behavior;
- `.303` one-dynamic plus two-static mixed read burst-last behavior;
- `.322` one-dynamic plus three-static mixed read single-beat behavior; and
- `.326` one-dynamic plus three-static mixed read burst-last behavior.

The code audit covered read response-demux normalization, generated
completion-source selection, last-signal validation, read-data coverage
predicates, support-accounting shape, focused `t/1438` cost, and RAM-guard
caveats recorded by the recent `.341` and `.344` slices.

## Candidate Contract For `.346`

`.346` should select, but not implement, the exact public contract for one
support-accounted sample:

```text
ppif/axi_manager_capacity_status_read_mixed_dynamic_static_response_demux_multi_dynamic_burst_last.ppif
```

The candidate support-accounting identity is:

```text
intent.ppif_axi_manager_capacity_status_read_mixed_dynamic_static_response_demux_multi_dynamic_burst_last
```

The candidate focused coverage key is:

```text
ial2_ppif_manager_capacity_status_read_mixed_dynamic_static_response_demux_multi_dynamic_burst_last_pipeline_cli
```

The candidate focused behavior label is:

```text
mixed_dynamic_static_read_rlast_demux_multi_dynamic
```

The source shape should use dynamic reads `r0`/`r1`, static read `r2` with
concrete ID `3`, `response-scope burst-last`, one one-bit `last-signal`
`axi0_rlast`, and generated transaction completions:

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
    (id dynamic))
  (read r2
    (tag rd2)
    (request axi0_r2_request)
    (completion axi0_r2_complete)
    (id (value 3))))

(response-demux
  (read
    (response-event axi0_read_complete)
    (response-scope burst-last)
    (last-signal axi0_rlast (width 1))
    (transaction-completion generated)))
```

The candidate report mode and completion source should reuse the existing
multi-mixed burst-last vocabulary:

```text
bounded_multi_mixed_dynamic_static_read_rid_rlast_demux_contract
generated_multi_mixed_dynamic_static_read_demux_last_beat
```

The selected contract should carry these report roles:

- `response_event_role: raw_accepted_read_response_beat`;
- `response_scope: burst_last`;
- `response_id_signal: axi0_rid`;
- `last_signal: axi0_rlast`;
- `last_signal_width: 1`;
- `transaction_completion_semantics:
  matched_dynamic_or_static_concrete_id_and_last_signal`;
- `beat_valid_output: none`;
- `burst_length_source: rlast_only`;
- `burst_length_validation: not_generated`;
- `dynamic_transactions: [r0, r1]`;
- `static_transactions: [r2]`;
- `mixed_transactions.dynamic: [r0, r1]`;
- `mixed_transactions.static: [r2]`;
- static ID reservation/exclusion for `4'd3`;
- dynamic capture ownership `multi_mixed_dynamic_static_unique_read_ids`;
- same-cycle request policy `onehot0_mixed_read_request`; and
- same-ID conflict policy `active_dynamic_ids_must_be_unique`.

## Behavioral Contract To Select

The implementation owner after `.346` should emit the same state as `.344`:

```text
axi0_r0_dynamic_id_q
axi0_r0_dynamic_busy_q
axi0_r1_dynamic_id_q
axi0_r1_dynamic_busy_q
axi0_r2_static_busy_q
```

Dynamic capture should keep the `.344` guards: request admission, not busy,
no sibling selected request in the same cycle, no active sibling dynamic with
the requested `ARID`, and `ARID != 4'd3`.

Static capture should remain request admission, not busy, and no selected
dynamic request in the same cycle.

Raw `RID` beat ownership assertions should not include `RLAST`; they should
prove that every accepted read response beat matches exactly one active
selected dynamic/static owner by `RID`. Generated completions and busy release
should additionally require `RLAST`:

```text
axi0_read_complete && axi0_r0_dynamic_busy_q && axi0_rid == axi0_r0_dynamic_id_q && axi0_rlast
axi0_read_complete && axi0_r1_dynamic_busy_q && axi0_rid == axi0_r1_dynamic_id_q && axi0_rlast
axi0_read_complete && axi0_r2_static_busy_q  && axi0_rid == 4'd3                 && axi0_rlast
```

The assertion names should extend the `.344` list without renaming existing
single-beat assertions:

```text
axi0_r0_dynamic_request_not_busy
axi0_r1_dynamic_request_not_busy
axi0_r2_static_request_not_busy
axi0_read_mixed_dynamic_static_request_onehot0
axi0_r0_dynamic_request_no_active_same_id
axi0_r1_dynamic_request_no_active_same_id
axi0_r0_r1_read_dynamic_active_id_unique
axi0_r0_r2_read_dynamic_request_not_static_id
axi0_r0_r2_read_dynamic_active_not_static_id
axi0_r1_r2_read_dynamic_request_not_static_id
axi0_r1_r2_read_dynamic_active_not_static_id
axi0_read_mixed_dynamic_static_response_active_match
axi0_r0_r1_read_mixed_dynamic_static_response_unique_match
axi0_r0_r2_read_mixed_dynamic_static_response_unique_match
axi0_r1_r2_read_mixed_dynamic_static_response_unique_match
axi0_r0_dynamic_completion_active
axi0_r1_dynamic_completion_active
axi0_r2_static_completion_active
```

## Residue

The selected next owner should keep all non-selected behavior fail-closed or
unchanged:

- read-data over the new two-dynamic/one-static burst-last demux;
- raw `ARLEN` burst-length capture over the new shape;
- runtime beat-count/`RLAST` validation over the new shape;
- multi-beat output banks over the new shape;
- broader capped mixed dynamic/static sets;
- same-cycle request widening beyond onehot0;
- same-cycle release-and-recapture;
- dynamic same-ID queues and scoreboards;
- direct backend behavior outside the selected generated SystemVerilog path;
- backend-language variants;
- VHDL;
- profile aliases;
- queued/blocking policy; and
- full-manager behavior.

## Validation Plan

`.346` should be doc-only and should validate with Knowledge Map generation
and check, mdBook build, memory architecture check, diff whitespace check, and
the doctrine gate.

The implementation owner after `.346` should validate syntax for touched Perl
modules/tests, direct guarded schedule/check/semantic/default-HDL/`--verify-hdl`
probes for the new sample where memory permits, focused `t/1438` behavior
coverage, support-accounting `t/248`, and preservation probes for `.344`,
`.255`, `.303`, `.326`, and adjacent read-data samples. Broad focused tests
should stay under the RAM guard; if the default 88% host cutoff trips, record
the caveat and narrow the probe instead of running unbounded.

## Rollback

Rollback for this audit is the `.345` documentation commit. Reverting it
removes only the readiness audit, task-tree frontier movement, docs, Memory,
and Knowledge Map fact, restoring `.345` as the active readiness frontier.
