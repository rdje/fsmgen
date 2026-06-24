# AXI IAL2 Manager One-Dynamic Mixed Dynamic Same-ID Reject Mapping Contract Selection

Task-tree owner: `IAL2-FEATURE-COMPLETENESS-FRONTIER.445`

Date: 2026-06-24

## Outcome

`IAL2-FEATURE-COMPLETENESS-FRONTIER.445` selects
`IAL2-FEATURE-COMPLETENESS-FRONTIER.446`, direct implementation of
one-dynamic mixed dynamic/static dynamic same-ID reject report/acceptance
mapping.

This contract-selection slice changes no parser, generator acceptance, PPIF
sample, support-accounting catalog, validation behavior, generated artifact,
test, schedule/check or semantic JSON, HDL, runtime behavior, direct backend
behavior, backend-language variant, queue, scoreboard, or VHDL behavior.

## Selected Covered Shapes

`.446` may accept same-family `response-demux.<family>` plus
`same-id-ordering.<family> (dynamic-id-reuse reject)` for generated
one-dynamic mixed dynamic/static response-demux shapes that already report all
required mixed evidence.

The selected covered shapes are:

- write `BID`;
- read single-beat `RID`;
- read burst-last `RID && RLAST`;
- exactly one dynamic transaction plus one, two, or three pairwise-distinct
  concrete static transactions in the selected family.

The selected family must already report:

- one covered dynamic transaction;
- one or more covered static transactions;
- `dynamic_capture.ownership` equal to
  `mixed_dynamic_static_unique_<family>_ids` or
  `multi_mixed_dynamic_static_unique_<family>_ids`;
- `dynamic_capture.static_id_conflict_policy:
  static_concrete_ids_reserved`;
- static ID reservations or static ID exclusions;
- generated dynamic request-not-static-ID assertions;
- generated dynamic active-not-static-ID assertions;
- a generated mixed dynamic/static request onehot assertion;
- generated response active-match and response unique-match assertions; and
- generated completion-active assertions for the selected dynamic and static
  transactions.

## Report Contract

Covered one-dynamic mixed policy reports should use:

```text
same_id_ordering.dynamic_id_reuse_policy.<family>.implementation_status:
  generated_mixed_static_id_exclusion_reject
same_id_ordering.dynamic_id_reuse_policy.<family>.enforcement:
  generated_static_id_exclusion_assertions
same_id_ordering.dynamic_id_reuse_policy.<family>.assertion_enforcement:
  runtime_assertion
same_id_ordering.dynamic_id_reuse_policy.<family>.response_demux_covered:
  true
same_id_ordering.dynamic_id_reuse_policy.<family>.mixed_dynamic_static_covered:
  true
same_id_ordering.dynamic_id_reuse_policy.<family>.mixed_dynamic_static_request_policy:
  onehot0_mixed_request
same_id_ordering.dynamic_id_reuse_policy.<family>.static_id_conflict_policy:
  static_concrete_ids_reserved
same_id_ordering.dynamic_id_reuse_policy.<family>.static_id_exclusion_policy:
  dynamic_id_must_not_equal_static_concrete_id
```

The report should also list:

- `response_demux_mode`;
- `response_demux_transaction_completion_source`;
- `covered_dynamic_transactions`;
- `covered_static_transactions`;
- `static_id_reservations`;
- `generated_request_availability_assertions`;
- `generated_mixed_request_onehot_assertions`;
- `generated_dynamic_request_static_id_exclusion_assertions`;
- `generated_dynamic_active_static_id_exclusion_assertions`;
- `generated_response_active_match_assertions`;
- `generated_response_unique_match_assertions`;
- `generated_completion_active_assertions`.

It must continue to report:

```text
policy: reject
accepted_same_id_reuse: false
request_conflict_policy: no_active_same_id
generated_queue_behavior: false
generated_scoreboard_behavior: false
```

The contract intentionally does not reuse `.438` fields
`generated_no_active_same_id_assertions` or
`generated_active_id_uniqueness_assertions`, because one-dynamic mixed shapes
have no sibling dynamic transaction. It also does not reuse the `.442`
`generated_idle_or_releasing_assertions` and `single_active_covered` fields,
because mixed dynamic/static coverage depends on static-ID exclusion and mixed
request/response evidence.

## Residue Movement

Residue movement stays family-local and evidence-based:

- remove `same_id_ordering` from `response_demux.residue` only for the covered
  response-demux family;
- preserve unrelated residues such as `read_response_demux`,
  `read_data_interleaving`, and `bursts`;
- remove `dynamic_id_same_id_ordering` from `same_id_ordering.residue` only
  when every selected dynamic policy family is covered by generated
  multi-active, single-active, or mixed static-ID-exclusion reject
  enforcement;
- do not remove queue, scoreboard, direct backend, backend-language, VHDL, or
  new generated HDL residue.

## Diagnostics

`.446` should fail closed if a selected one-dynamic mixed family is missing
any required mixed evidence. The diagnostic should distinguish the contract
from `.438` and `.442`, for example:

```text
AXI manager capacity/status IAL2 contract response_demux.<family> dynamic-id-reuse reject mixed dynamic/static generated enforcement requires static-ID exclusion, mixed request onehot, response active/unique-match, and completion-active assertions in this slice
```

The previous generated multi-active no-active-same-ID diagnostic remains
valid for shapes that are neither covered by `.438`, `.442`, nor the selected
mixed dynamic/static contract.

## Implementation Scope For `.446`

`.446` should change only acceptance/report/residue mapping for the selected
one-dynamic mixed dynamic/static response-demux shapes. It may add one
support-accounted public PPIF sample before using it as public validation
evidence. The preferred sample is a read single-beat mixed response-demux plus:

```lisp
(same-id-ordering
  (read (dynamic-id-reuse reject)))
```

Focused tests should cover at least:

- write `BID` one-dynamic mixed mapping;
- read single-beat `RID` one-dynamic mixed mapping;
- read burst-last `RID && RLAST` one-dynamic mixed mapping;
- at least one multi-static one-dynamic mixed mapping;
- preservation of `.438` multi-active report fields;
- preservation of `.442` single-active report fields;
- generated IAL1/IAL0/HDL artifact identity versus the base response-demux
  sample for any new public sample.

## Non-Goals

`.446` must not add new generated rules, storage, assertions, HDL behavior,
runtime behavior, direct backend behavior, backend-language variants, queues,
scoreboards, VHDL behavior, dynamic `issue-order-queue` policy values, dynamic
`scoreboard` policy values, accepted dynamic same-ID reuse, or behavior
outside the selected one-dynamic mixed response-demux report/acceptance
mapping.

## Validation For `.445`

Because `.445` is a contract-selection slice, validation is documentation and
continuity focused:

```bash
knowledge-map/scripts/gen_knowledge_map.sh
knowledge-map/scripts/check_knowledge_map.sh
mdbook build docs/book
scripts/check_docs_relative_paths.sh
scripts/check_memory_architecture.sh
git --no-pager diff --check
scripts/check_doctrines.sh
```

No behavior-bearing command is required for `.445`.

## Rollback

Rollback for `.445` is this docs-only contract-selection commit. Reverting it
removes the `.446` selection, fact card, task-tree advancement, live-doc
updates, and resume pointer update without changing generated behavior.
