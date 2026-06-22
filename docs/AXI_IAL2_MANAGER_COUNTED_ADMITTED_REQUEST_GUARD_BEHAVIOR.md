# AXI IAL2 Manager Counted Admitted-Request Guard Behavior

Status: shipped by `IAL2-FEATURE-COMPLETENESS-FRONTIER.214` on 2026-06-22.

Task-tree owner: `IAL2-FEATURE-COMPLETENESS-FRONTIER.214`

## Summary

Generated same-ID queue-head families with more than one concrete-ID queue
group now align admitted-request pulses with the counted capacity/status
matrix before enqueueing. The generated admitted-request boundary uses a
current-request-set fit expression derived from the same occupancy,
completion, request-count, and max-pending cases as the counted matrix.

For those counted multi-group families, the previous family-wide request
onehot assertion is replaced by one request onehot assertion per concrete-ID
queue group. This permits distinct concrete-ID groups in the same generated
read or write family to request in the same cycle when the counted request set
fits the current capacity state, while same-group simultaneous requests remain
asserted and do not produce a queue transition.

Boolean directions and same-family mixed auto-ID plus one concrete same-ID
queue group remain on the existing family-wide request assertion and scalar
capacity-storage guard.

## Report Surface

Counted multi-group admitted boundaries now report:

```text
guard_source=counted_request_set_capacity_fit
accounting_mode=counted_capacity_storage_and_completion_fanin
request_assertion_scope=concrete_id_group
request_count_expression=(+ <group0-request-fanin> <group1-request-fanin> ...)
request_count_evaluation_terms=(<zero-extended group0-request-fanin> ...)
request_count_evaluation_expression=(+ <zero-extended group terms> ...)
request_count_evaluation_width=<exact comparison width>
request_set_fit_expression=(| <occupancy/completion/request-count cases> ...)
generated_assertions=<one *_request_onehot0 per concrete-ID group>
```

The existing counted capacity/status fields from `.211` remain stable:

- `request_accounting.mode: counted_same_id_selected_requests`
- `counted_request_events`
- `counted_request_terms`
- `counted_request_groups`
- `request_count_expression`
- `request_count_evaluation_terms`
- `request_count_evaluation_expression`
- `request_count_evaluation_width`
- `maximum_request_count`
- `over_capacity_policy: reject_current_request_set`
- capacity matrix `accounting_mode: counted_submit`

The `request_count_expression` field remains the user-facing selected group
fan-in shape. The `request_count_evaluation_*` fields are the exact-width
expression used by generated admitted-request guards and capacity rules. For
two one-bit group terms with a two-bit count, the evaluation terms are
zero-extended, for example:

```lisp
(+ (concat 1'b0 (| axi0_r0_request axi0_r1_request))
   (concat 1'b0 (| axi0_r2_request axi0_r3_request)))
```

The public read and write multi-group samples now report group-local assertion
names such as:

```text
axi0_read_id3_same_id_issue_order_request_onehot0
axi0_read_id5_same_id_issue_order_request_onehot0
axi0_write_id3_same_id_issue_order_request_onehot0
axi0_write_id5_same_id_issue_order_request_onehot0
```

## Guard Semantics

The request-set fit expression mirrors the counted capacity matrix:

- completion credits at most one slot;
- completion credits only when occupancy is greater than zero;
- the current request set is accepted only when the counted request count fits
  the resulting capacity;
- request-count comparisons use the exact-width evaluation expression and
  matching sized decimal literals;
- an over-capacity current request set produces no admitted-request pulse, so
  queue state does not diverge from the shared pending/status matrix.

For a low-capacity `max_pending=3` two-group sample, occupancy `2` without a
completion admits at most one request; occupancy `2` with a completion admits
at most two; full occupancy `3` without a completion admits zero; and full
occupancy `3` with a completion admits at most one.

## Preservation

`.214` does not add PPIF syntax, new public samples, new queue depth coverage,
packed outputs, alternate payload assembly, direct backend behavior,
verification-output generation, VHDL behavior, or backend-language variants.

Existing generated queue-head response-demux, read-data, burst-length,
runtime-validation, multi-beat output-bank, strict check JSON, semantic JSON,
support-accounting identities, and HDL generation remain on the same bounded
public sample set.
