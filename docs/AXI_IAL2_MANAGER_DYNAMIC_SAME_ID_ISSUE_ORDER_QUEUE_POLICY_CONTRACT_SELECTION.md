# AXI IAL2 Manager Dynamic Same-ID Issue-Order Queue Policy Contract Selection

Task-tree owner: `IAL2-FEATURE-COMPLETENESS-FRONTIER.449`

Date: 2026-06-24

## Outcome

`IAL2-FEATURE-COMPLETENESS-FRONTIER.449` selects
`IAL2-FEATURE-COMPLETENESS-FRONTIER.450`, metadata-first parser/report
implementation for dynamic same-ID `issue-order-queue` policy.

This selector changes no parser, generator, PPIF sample, support-accounting
catalog, validation behavior, generated artifact, test, schedule/check or
semantic JSON, HDL, runtime behavior, direct backend behavior,
backend-language variant, queue, scoreboard, or VHDL behavior.

## Selected Source Contract

Add one new family-local `dynamic-id-reuse` value under the existing
`same-id-ordering` read/write family arms:

```lisp
(same-id-ordering
  (read
    (dynamic-id-reuse issue-order-queue))
  (write
    (dynamic-id-reuse issue-order-queue)))
```

The existing `dynamic-id-reuse reject` value remains supported. A family may
select exactly one `dynamic-id-reuse` clause. Duplicate dynamic clauses still
fail closed.

The dynamic policy may coexist with the existing concrete policy in the same
family arm:

```lisp
(same-id-ordering
  (read
    (concrete-id-reuse issue-order-queue)
    (dynamic-id-reuse issue-order-queue)))
```

`dynamic-id-reuse scoreboard` remains unsupported until a later task-tree
owner selects a separate scoreboard policy contract.

## Metadata-First Report Contract

`.450` should accept the selected source spelling as metadata and report it
honestly without accepting dynamic same-ID reuse or generating queue behavior.

For a dynamic-only selected family, the report should use:

```yaml
same_id_ordering:
  mode: dynamic_id_reuse_policy
  generated_behavior: false
  dynamic_id_reuse_policy:
    read:
      policy: issue_order_queue
      implementation_status: selected_not_generated
      enforcement: not_generated
      accepted_same_id_reuse: false
      request_conflict_policy: dynamic_issue_order_queue_selected_not_generated
      generated_queue_behavior: false
      generated_scoreboard_behavior: false
  residue:
    - dynamic_id_same_id_ordering
    - dynamic_per_id_issue_order_queues
```

If concrete and dynamic policies coexist, the report mode remains
`id_reuse_policy` and carries both `concrete_id_reuse_policy.<family>` and
`dynamic_id_reuse_policy.<family>` entries.

The selected dynamic issue-order queue metadata must not use the generated
reject mapping fields from `.438`, `.442`, or `.446`. Those fields apply only
to `dynamic-id-reuse reject`, where accepted same-ID reuse is false by policy.

## Accepted Reuse Boundary

Metadata-first `dynamic-id-reuse issue-order-queue` does not accept dynamic
same-ID reuse:

```text
accepted_same_id_reuse: false
generated_queue_behavior: false
generated_scoreboard_behavior: false
```

Accepted dynamic same-ID reuse becomes true only after a later generated
dynamic queue behavior owner defines admitted-request capture, per-admission
runtime ID state, enqueue/dequeue rules, response matching, ordering
guarantees, overflow handling, ambiguity assertions, and residue movement.

## Diagnostics

`.450` should preserve and refine fail-closed diagnostics:

- `dynamic-id-reuse issue-order-queue` requires transaction metadata;
- the selected family must contain at least one same-family dynamic
  transaction;
- selected dynamic issue-order queue metadata must not be treated as generated
  queue behavior;
- `dynamic-id-reuse scoreboard` remains unsupported;
- selecting only `concrete-id-reuse` does not cover dynamic transaction-ID
  metadata; sources with dynamic transaction IDs must select
  `dynamic-id-reuse reject` or `dynamic-id-reuse issue-order-queue`;
- duplicate same-ID ordering clauses, duplicate family arms, duplicate
  concrete policies, and duplicate dynamic policies remain invalid.

## Public Sample And Support Accounting

`.450` should add one support-accounted metadata-first PPIF sample unless a
more focused implementation owner proves a better validation surface. The
preferred sample is a dynamic read metadata sample using:

```lisp
(same-id-ordering
  (read (dynamic-id-reuse issue-order-queue)))
```

The generated IAL1/IAL0/HDL artifacts should remain identical to the base
dynamic transaction-ID metadata sample. The only expected change is the
capacity/status report, strict check/semantic support-accounting entry, docs,
and Knowledge Map fact.

## Preservation Matrix

`.450` must preserve:

- generated dynamic reject mappings from `.438`, `.442`, and `.446`;
- metadata-first dynamic reject parser/report behavior from `.436`;
- concrete same-ID reject and issue-order queue parser/report/generated
  behavior;
- dynamic transaction-ID capture, response-demux, read-data, multi-beat, and
  recapture behavior already selected;
- existing public sample identities and generated artifacts except for the
  optional new metadata-first dynamic issue-order sample;
- direct backend deferral, VHDL deferral, and backend-language neutrality.

## Non-Goals

- Do not generate dynamic queue state, admitted dynamic queue enqueue/dequeue
  rules, dynamic queue-head response demux, overflow/ambiguity assertions, or
  HDL behavior in `.449`.
- Do not report `accepted_same_id_reuse: true` or
  `generated_queue_behavior: true` for dynamic issue-order queue metadata.
- Do not accept or implement dynamic `scoreboard`.
- Do not reinterpret `concrete-id-reuse issue-order-queue` as covering
  dynamic transaction IDs.
- Do not change direct backend behavior, VHDL behavior, or backend-language
  variants.

## Validation For `.449`

Because `.449` is a contract-selection slice, validation is documentation and
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

No Perl, `prove`, `fsmgen`, HDL, schedule/check/semantic JSON, or generated
artifact behavior is expected to change in this slice.

## Rollback

Rollback for `.449` is this docs-only contract-selection commit. Reverting it
removes the `.450` selection, fact card, task-tree advancement, live-doc
updates, and resume pointer update without changing generated behavior.
