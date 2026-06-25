# AXI IAL2 Manager Dynamic Same-ID Issue-Order Queue Policy Readiness Audit

Task-tree owner: `IAL2-FEATURE-COMPLETENESS-FRONTIER.448`

Date: 2026-06-24

## Outcome

`IAL2-FEATURE-COMPLETENESS-FRONTIER.448` selects
`IAL2-FEATURE-COMPLETENESS-FRONTIER.449`, public dynamic same-ID
`issue-order-queue` policy contract selection.

This audit changes no parser, generator, PPIF sample, support-accounting
catalog, validation behavior, generated artifact, test, schedule/check or
semantic JSON, HDL, runtime behavior, direct backend behavior,
backend-language variant, queue, scoreboard, or VHDL behavior.

## Inputs Read

The audit read:

- `.447` post one-dynamic mixed dynamic same-ID reject mapping selector;
- `.446`, `.442`, and `.438` generated dynamic same-ID reject mapping
  behavior records;
- `.436` metadata-first `(dynamic-id-reuse reject)` behavior;
- `.434` public dynamic same-ID policy contract and `.433` dynamic same-ID
  policy readiness audit;
- `.216` dynamic same-ID issue-order readiness audit;
- concrete same-ID `issue-order-queue` contract, metadata-first,
  admitted-request pulse, queue-state, queue-head demux, and generated
  behavior records;
- current PPIF parser diagnostics for unsupported
  `dynamic-id-reuse issue-order-queue` and `dynamic-id-reuse scoreboard`
  values;
- current dynamic same-ID report/residue fields;
- support-accounting detail, README, ROADMAP_V2, mdBook, Memory, task tree,
  and Knowledge Map.

## Current Boundary

The dynamic same-ID `reject` path is now covered for bounded generated
response-demux evidence models:

- multi-active dynamic and two-dynamic-plus-one-static mixed response-demux
  through `.438`;
- single-active dynamic response-demux through `.442`;
- one-dynamic mixed dynamic/static response-demux through `.446`.

Those generated reject mappings all report:

```text
accepted_same_id_reuse: false
generated_queue_behavior: false
generated_scoreboard_behavior: false
```

The parser still supports only `reject` as a `dynamic-id-reuse` value. A
source spelling such as:

```lisp
(same-id-ordering
  (read (dynamic-id-reuse issue-order-queue)))
```

fails closed today with the dynamic policy diagnostic that only `reject` is
supported in this slice. Dynamic `scoreboard` fails closed at the same
unsupported-value boundary.

## Concrete Queue Precedent

Concrete same-ID `issue-order-queue` work used a staged contract:

- a selector chose the public `concrete-id-reuse issue-order-queue` source
  and report vocabulary;
- a metadata-first slice accepted the spelling with
  `implementation_status: selected_not_generated`,
  `accepted_same_id_reuse: false`, and `generated_queue_behavior: false`;
- later slices added admitted request pulses, compact queue state,
  queue-head response demux, and then generated queue behavior for bounded
  concrete-ID groups.

That precedent is useful but not directly reusable. Concrete queue groups are
statically enumerable by response family, concrete ID value, and transaction
inventory. Dynamic request IDs are runtime values, so the eventual queue
contract must define admission, captured request IDs, per-admission identity
state, response matching, ordering guarantees, overflow behavior, ambiguity
assertions, and residue movement before generated behavior can ship.

## Readiness Findings

Direct generated dynamic issue-order queue behavior is not selected. It would
combine new public syntax, request arbitration, per-ID state, response
matching, queue capacity, overflow handling, ambiguity checks, public samples,
support accounting, and HDL behavior in one unsafe slice.

Parser/report implementation is also not selected directly. The source and
report contract needs one explicit selector first so the project can decide
whether metadata-first dynamic `issue-order-queue` should be accepted as
selected-not-generated, or whether the spelling must remain unsupported until
generated queue behavior exists.

Keeping the spelling unsupported forever until generated behavior is possible
is not selected by this audit. The concrete queue precedent suggests a
metadata-first contract may be useful, but dynamic IDs have enough extra
runtime semantics that the exact report fields and diagnostics need a
contract-selection slice before code changes.

Dynamic `scoreboard` is not selected. Scoreboard policy has a different
completion-tracking promise from issue-order queues and should stay a
separate policy/readiness owner after issue-order queue contract decisions.

Report cleanup, direct backend behavior, backend-language variants, VHDL, and
new generated HDL are not selected. Current reports are honest: dynamic same
ID reject is generated for selected bounded shapes, while dynamic queues and
scoreboards are not generated.

## Selected `.449` Boundary

`.449` should select the public contract before any parser or behavior
change. It should decide:

- whether the source spelling is exactly
  `(dynamic-id-reuse issue-order-queue)` under existing
  `same-id-ordering` family arms;
- whether metadata-first parser/report support is allowed before generated
  dynamic queue behavior;
- if metadata-first support is selected, the exact report fields for
  `policy`, `implementation_status`, `enforcement`,
  `accepted_same_id_reuse`, `generated_queue_behavior`,
  `generated_scoreboard_behavior`, and residue;
- whether `accepted_same_id_reuse` must remain false until generated dynamic
  queue behavior ships;
- how dynamic issue-order queue policy coexists with dynamic reject policy,
  concrete issue-order queue policy, and generated dynamic response-demux
  reject mappings;
- diagnostics for unsupported scoreboard, duplicate dynamic policy clauses,
  missing transactions, missing dynamic same-family transactions, and attempts
  to treat concrete policy as dynamic coverage;
- validation gates, rollback, support-accounting impact, docs, mdBook, and
  Knowledge Map updates for later implementation owners.

## Preservation Matrix

`.449` must preserve:

- all generated dynamic reject mappings from `.438`, `.442`, and `.446`;
- metadata-first dynamic reject parser/report behavior from `.436`;
- concrete same-ID reject and issue-order queue parser/report/generated
  behavior;
- dynamic transaction-ID capture, response-demux, read-data, multi-beat, and
  recapture behavior already selected;
- current fail-closed diagnostics for unsupported dynamic policy values until
  a later exact owner changes them;
- support-accounting identities, public sample identities, generated
  artifacts, check JSON, semantic JSON, schedule JSON, and HDL behavior;
- direct backend deferral, VHDL deferral, and backend-language neutrality.

## Non-Goals

- Do not implement parser/report support in `.448`.
- Do not accept `dynamic-id-reuse issue-order-queue` or
  `dynamic-id-reuse scoreboard` in `.448`.
- Do not implement dynamic queue state, enqueue/dequeue rules, queue-head
  demux, accepted dynamic same-ID reuse, overflow/ambiguity assertions, or HDL
  behavior in `.448` or `.449` unless `.449` selects a later exact
  implementation owner.
- Do not reinterpret `concrete-id-reuse issue-order-queue` as covering
  dynamic transaction IDs.
- Do not change direct backend behavior, VHDL behavior, or backend-language
  variants.

## Validation For `.448`

Because `.448` is an audit, validation is documentation and continuity
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

Rollback for `.448` is this docs-only audit commit. Reverting it removes the
`.449` selection, fact card, task-tree advancement, live-doc updates, and
resume pointer update without changing generated behavior.
