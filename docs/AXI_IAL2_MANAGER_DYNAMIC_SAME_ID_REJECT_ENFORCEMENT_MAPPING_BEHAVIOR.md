# AXI IAL2 Manager Dynamic Same-ID Reject Enforcement Mapping Behavior

Task-tree owner: `IAL2-FEATURE-COMPLETENESS-FRONTIER.438`

Date: 2026-06-24

## Outcome

FSMGen now maps selected `(dynamic-id-reuse reject)` policy to already
generated multi-active dynamic response-demux assertions for the bounded AXI
manager capacity/status shapes that prove same-ID exclusion at runtime.

This slice does not add generated storage, rules, assertions, HDL behavior,
direct backend behavior, backend-language variants, queues, scoreboards, or
VHDL behavior. It changes acceptance, schedule/check/semantic report metadata,
residue movement, focused tests, and one support-accounted public sample.

## Covered Shapes

The mapping is generated only when the selected same-family response-demux
report already exposes:

- `dynamic_capture.same_id_conflict_policy:
  active_dynamic_ids_must_be_unique`;
- per-dynamic `*_dynamic_request_no_active_same_id` assertion names;
- pairwise `*_dynamic_active_id_unique` assertion names.

The first covered shapes are:

- multiple all-dynamic write `BID` response-demux;
- multiple all-dynamic read `RID` response-demux;
- multiple all-dynamic read `RID && RLAST` response-demux;
- two-dynamic-plus-one-static mixed dynamic/static write `BID`
  response-demux;
- two-dynamic-plus-one-static mixed dynamic/static read `RID`
  response-demux;
- two-dynamic-plus-one-static mixed dynamic/static read `RID && RLAST`
  response-demux.

For those shapes, same-family `response-demux.<family>` may now coexist with
`same-id-ordering.<family> (dynamic-id-reuse reject)`.

## Report Contract

Covered dynamic policy reports now use:

```text
same_id_ordering.dynamic_id_reuse_policy.<family>.implementation_status:
  generated_no_active_same_id_reject
same_id_ordering.dynamic_id_reuse_policy.<family>.enforcement:
  generated_no_active_same_id_assertions
same_id_ordering.dynamic_id_reuse_policy.<family>.assertion_enforcement:
  runtime_assertion
same_id_ordering.dynamic_id_reuse_policy.<family>.response_demux_covered:
  true
```

The report also lists:

- `response_demux_mode`;
- `response_demux_transaction_completion_source`;
- `covered_dynamic_transactions`;
- `generated_no_active_same_id_assertions`;
- `generated_active_id_uniqueness_assertions`.

It still reports:

```text
accepted_same_id_reuse: false
request_conflict_policy: no_active_same_id
generated_queue_behavior: false
generated_scoreboard_behavior: false
```

`same_id_ordering.residue` removes `dynamic_id_same_id_ordering` only when
every selected dynamic policy family is covered. `response_demux.residue`
removes `same_id_ordering` when the selected response-demux family is covered,
while unrelated `read_response_demux`, `read_data_interleaving`, and `bursts`
residue remains visible.

## Public Sample

The new support-accounted PPIF sample is:

```text
ppif/axi_manager_capacity_status_dynamic_read_response_demux_multi_same_id_reject.ppif
```

It combines multiple all-dynamic read single-beat response-demux with:

```text
(same-id-ordering
  (read (dynamic-id-reuse reject)))
```

The generated IAL1/IAL0/HDL artifacts are unchanged from the base
`ppif/axi_manager_capacity_status_dynamic_read_response_demux_multi.ppif`
sample; only the accepted report/residue mapping differs.

## Fail-Closed Boundaries

The following remain deferred or fail closed:

- single-active dynamic write/read response-demux;
- one-dynamic mixed dynamic/static response-demux;
- response-demux families without generated no-active-same-ID and active-ID
  uniqueness assertion names;
- dynamic `issue-order-queue` or `scoreboard` policy values;
- dynamic queues, scoreboards, broader request arbitration, direct backend
  behavior, backend-language variants, and VHDL.
