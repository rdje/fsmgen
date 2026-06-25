# AXI IAL2 Manager Post Dynamic Same-ID Issue-Order Queue Metadata Next Slice Selection

Task-tree owner: `IAL2-FEATURE-COMPLETENESS-FRONTIER.451`

Date: 2026-06-24

## Outcome

`IAL2-FEATURE-COMPLETENESS-FRONTIER.451` selects
`IAL2-FEATURE-COMPLETENESS-FRONTIER.452`, readiness audit for generated
dynamic same-ID `issue-order-queue` behavior after metadata-first support.

This selector changes no parser, generator, PPIF sample, support-accounting
catalog, validation behavior, generated artifact, test, schedule/check or
semantic JSON, HDL, runtime behavior, direct backend behavior,
backend-language variant, queue, scoreboard, or VHDL behavior.

## Inputs Read

The selector read:

- `.450` metadata-first dynamic same-ID `issue-order-queue` behavior;
- `.449` public dynamic same-ID `issue-order-queue` policy contract;
- `.448` dynamic issue-order policy readiness audit;
- `.446`, `.442`, and `.438` generated dynamic same-ID `reject` mapping
  behavior records;
- `.436` metadata-first `(dynamic-id-reuse reject)` behavior;
- `.434` public dynamic same-ID policy contract;
- concrete same-ID `issue-order-queue` behavior readiness, admitted-request,
  queue-state representation, and queue-head demux records;
- dynamic scoreboard deferral notes and the current unsupported
  `dynamic-id-reuse scoreboard` boundary;
- current PPIF parser, capacity/status report, support-accounting, and
  focused test surfaces touched by `.450`;
- the `.450` broad-generator validation caveat;
- README, ROADMAP_V2, mdBook, Memory, task tree, and Knowledge Map fact
  cards.

## Current Boundary

Public PPIF may now select family-local dynamic same-ID issue-order metadata:

```lisp
(same-id-ordering
  (read (dynamic-id-reuse issue-order-queue)))
```

The report is intentionally selected-not-generated:

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

Generated dynamic same-ID `reject` mappings remain separate and reject-only:
they prove bounded exclusion assertions for selected generated dynamic or
mixed response-demux shapes, but they do not admit same-ID reuse and do not
provide queue behavior.

## Why Generated Queue Readiness Is Next

The new residue `dynamic_per_id_issue_order_queues` is now explicit and
user-visible. The next useful owner is therefore not another metadata cleanup
slice, but an audit that decides whether generated dynamic queue behavior can
be scoped safely.

Dynamic queues are not the same as concrete same-ID queue-head groups.
Concrete queues can group transactions by static family plus concrete ID
value. Dynamic queues must define at least:

- the admitted dynamic request capture boundary;
- which runtime request ID value is stored for each admitted transaction;
- per-admitted-transaction or per-runtime-ID queue state;
- enqueue/dequeue semantics and same-cycle enqueue/dequeue policy;
- response matching for write `BID`, read single-beat `RID`, and read
  burst-last `RID && RLAST` shapes;
- ordering guarantees across selected dynamic transactions;
- overflow, duplicate-admission, empty-response, and ambiguous-response
  assertions;
- report fields and residue movement that distinguish generated dynamic
  queue behavior from selected-not-generated metadata.

Those questions must be audited before any public contract selection or
behavior implementation can honestly set `accepted_same_id_reuse: true` or
`generated_queue_behavior: true`.

## Why Not Scoreboard Next

Dynamic `scoreboard` remains a separate unsupported policy. It has a
different completion-tracking promise from issue-order queues: scoreboards
track outstanding runtime IDs and completions without promising the same FIFO
head-of-queue response routing semantics selected by `issue-order-queue`.

Selecting scoreboard now would mix two unresolved policy families. The
issue-order metadata was just accepted and exposes the queue residue
directly, so `.452` should audit that queue path first. A later exact owner
can return to dynamic scoreboard readiness or contract selection after the
queue readiness boundary is understood.

## Why Not Report Cleanup, Direct Backend, Or VHDL

Current reports are honest: dynamic issue-order metadata is accepted but not
generated, dynamic same-ID reuse remains false, generated queue and
scoreboard behavior remain false, and residue names the missing dynamic
per-ID issue-order queue work.

Report cleanup would not unlock behavior. Direct backend, backend-language
variants, and VHDL remain downstream of the SystemVerilog-backed
`IAL2 -> IAL1 -> IAL0` behavior contract and are not selected from this
dynamic same-ID policy lane.

## Selected `.452` Boundary

`.452` should be a documentation and readiness audit before behavior changes.
It should decide whether the next owner should:

- select a generated dynamic same-ID issue-order queue public contract;
- select a narrower prerequisite, such as dynamic admitted-request capture or
  runtime-ID queue-state representation;
- keep generated dynamic queues deferred and choose another exact owner.

The audit must define the expected diagnostics, report fields, support/sample
impact, validation gates, rollback boundary, residue movement, and non-goals
before parser, generator, HDL, support-accounting, or runtime behavior is
changed.

## Preservation Matrix

`.452` must preserve:

- metadata-first `dynamic-id-reuse issue-order-queue` support from `.450`;
- metadata-first and generated-mapping `dynamic-id-reuse reject` behavior
  from `.436`, `.438`, `.442`, and `.446`;
- concrete same-ID `reject` and `issue-order-queue` behavior;
- dynamic transaction-ID capture, response-demux, read-data, multi-beat, and
  recapture behavior already selected;
- current support-accounting identities and public PPIF sample identities;
- direct backend deferral, VHDL deferral, and backend-language neutrality.

## Non-Goals

- Do not implement generated dynamic queue state, enqueue/dequeue rules,
  response-demux rules, assertions, HDL, or accepted same-ID reuse in `.451`.
- Do not select or implement dynamic `scoreboard` in `.451`.
- Do not reinterpret generated dynamic `reject` mappings as queue behavior.
- Do not change direct backend behavior, VHDL behavior, or backend-language
  variants.

## Validation For `.451`

Because `.451` is a selector, validation is documentation and continuity
focused:

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

Rollback for `.451` is this docs-only selector commit. Reverting it removes
the `.452` selection, fact card, task-tree advancement, live-doc updates, and
resume pointer update without changing generated behavior.
