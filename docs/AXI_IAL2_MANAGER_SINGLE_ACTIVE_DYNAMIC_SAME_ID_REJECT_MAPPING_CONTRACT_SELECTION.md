# AXI IAL2 Manager Single-Active Dynamic Same-ID Reject Mapping Contract Selection

Task-tree owner: `IAL2-FEATURE-COMPLETENESS-FRONTIER.441`

Date: 2026-06-24

## Outcome

`IAL2-FEATURE-COMPLETENESS-FRONTIER.441` selects
`IAL2-FEATURE-COMPLETENESS-FRONTIER.442`, direct implementation of
single-active dynamic same-ID reject report/acceptance mapping over existing
generated single-active dynamic response-demux assertions.

This contract-selection slice changes no parser, generator acceptance, PPIF
sample, support-accounting catalog, validation behavior, generated artifact,
test, schedule/check or semantic JSON, HDL, runtime behavior, direct backend
behavior, backend-language variant, queue, scoreboard, or VHDL behavior.

## Selected Covered Shapes

`.442` may accept same-family `response-demux.<family>` plus
`same-id-ordering.<family> (dynamic-id-reuse reject)` for exactly these
single-active dynamic response-demux shapes:

- single-active dynamic write `BID`;
- single-active dynamic read single-beat `RID`;
- single-active dynamic read burst-last `RID && RLAST`.

The selected family must already report:

- `dynamic_capture.ownership: single_active_dynamic_write` or
  `single_active_dynamic_read`;
- exactly one covered dynamic transaction;
- a generated `*_dynamic_request_idle_or_releasing` assertion;
- a generated response active-match assertion;
- a generated completion-active assertion;
- generated dynamic demux transaction completion.

## Report Contract

Covered single-active dynamic policy reports should use:

```text
same_id_ordering.dynamic_id_reuse_policy.<family>.implementation_status:
  generated_single_active_reject
same_id_ordering.dynamic_id_reuse_policy.<family>.enforcement:
  generated_idle_or_releasing_assertions
same_id_ordering.dynamic_id_reuse_policy.<family>.assertion_enforcement:
  runtime_assertion
same_id_ordering.dynamic_id_reuse_policy.<family>.response_demux_covered:
  true
same_id_ordering.dynamic_id_reuse_policy.<family>.single_active_covered:
  true
same_id_ordering.dynamic_id_reuse_policy.<family>.single_active_request_policy:
  idle_or_releasing
```

The report should also list:

- `response_demux_mode`;
- `response_demux_transaction_completion_source`;
- `covered_dynamic_transactions`;
- `generated_idle_or_releasing_assertions`;
- `generated_response_active_match_assertions`;
- `generated_completion_active_assertions`.

It must continue to report:

```text
accepted_same_id_reuse: false
request_conflict_policy: no_active_same_id
generated_queue_behavior: false
generated_scoreboard_behavior: false
```

The contract intentionally does not add
`generated_no_active_same_id_assertions` or
`generated_active_id_uniqueness_assertions` to single-active reports, because
those are the `.438` multi-active evidence fields and are not generated for a
one-dynamic-transaction family.

## Residue Movement

Residue movement stays family-local and evidence-based:

- remove `same_id_ordering` from `response_demux.residue` only for the covered
  response-demux family;
- preserve unrelated write/read residues such as `read_response_demux`,
  `read_data_interleaving`, and `bursts`;
- remove `dynamic_id_same_id_ordering` from `same_id_ordering.residue` only
  when every selected dynamic policy family is covered by generated
  single-active or multi-active reject enforcement;
- do not remove queue, scoreboard, direct backend, backend-language, or VHDL
  residue.

## Diagnostics

`.442` should fail closed if a selected single-active family is missing any of
the required report evidence. The new diagnostic should be specific enough to
distinguish this contract from `.438`, for example:

```text
AXI manager capacity/status IAL2 contract response_demux.<family> dynamic-id-reuse reject single-active generated enforcement requires generated idle-or-releasing, active-match, and completion-active assertions in this slice
```

One-dynamic mixed dynamic/static response-demux shapes remain outside this
contract and should keep the existing generated multi-active
no-active-same-ID diagnostic until a later owner selects their boundary.

## Implementation Scope For `.442`

`.442` should change only acceptance/report/residue mapping for the selected
single-active dynamic response-demux shapes. It may add one support-accounted
public PPIF sample before using it as public validation evidence. The preferred
sample is a read single-beat single-active response-demux plus:

```lisp
(same-id-ordering
  (read (dynamic-id-reuse reject)))
```

Focused tests should cover at least:

- write `BID` single-active mapping;
- read single-beat `RID` single-active mapping;
- read burst-last `RID && RLAST` single-active mapping;
- preservation of one-dynamic mixed dynamic/static fail-closed behavior;
- generated IAL1/IAL0/HDL artifact identity versus the base response-demux
  sample for any new public sample.

## Non-Goals

`.442` must not add new generated rules, storage, assertions, HDL behavior,
runtime behavior, direct backend behavior, backend-language variants, queues,
scoreboards, VHDL behavior, dynamic `issue-order-queue` policy values, dynamic
`scoreboard` policy values, or one-dynamic mixed dynamic/static reject mapping.

## Validation For `.441`

Because `.441` is a contract-selection slice, validation is documentation and
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

## Rollback

Rollback for `.441` is this docs-only contract-selection commit. Reverting it
removes the `.442` selection, fact card, task-tree advancement, live-doc
updates, and resume pointer update without changing generated behavior.
