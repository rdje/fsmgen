# AXI IAL2 Manager Dynamic Same-ID Policy Contract Selection

Task-tree owner: `IAL2-FEATURE-COMPLETENESS-FRONTIER.434`

Date: 2026-06-24

## Outcome

`IAL2-FEATURE-COMPLETENESS-FRONTIER.434` selects the public dynamic
same-ID policy contract and advances to
`IAL2-FEATURE-COMPLETENESS-FRONTIER.435`, readiness audit for
metadata-first parser/report support of the selected dynamic same-ID reject
policy.

No parser, generator, PPIF sample, support-accounting catalog, validation
behavior, generated artifact, test, schedule/check or semantic JSON, HDL, or
runtime behavior changes in this selector.

## Inputs Read

The selector is based on:

- `.433` dynamic same-ID policy readiness audit;
- `.432` post two-dynamic mixed read burst-last recapture selector and `.431`
  two-dynamic-plus-one-static mixed read burst-last recapture behavior;
- `.216` through `.219`, which selected and shipped transaction-local
  `(id dynamic)` parser/report metadata before generated dynamic behavior;
- generated dynamic and mixed dynamic/static response-demux, read-data,
  raw-`ARLEN`, runtime-validation, multi-beat, and recapture records,
  including the multiple-dynamic read response-demux and two-dynamic-plus-one
  static read burst-last recapture behavior;
- concrete same-ID policy records for `concrete-id-reuse reject`,
  `concrete-id-reuse issue-order-queue`, selected-not-generated
  issue-order-queue metadata, admitted request pulses, queue state,
  queue-head response demux, and generated concrete queue-head behavior;
- current PPIF parser syntax, which only accepts `concrete-id-reuse` under
  `same-id-ordering`;
- current generator normalization/report code, which reports
  `concrete_id_reuse_policy` and rejects dynamic transactions combined with
  `same_id_ordering_policy.<family>`;
- current dynamic response-demux report fields and generated assertions,
  including no-active-same-ID request checks and pairwise active dynamic-ID
  uniqueness;
- support-accounting detail, README, ROADMAP_V2, mdBook, Memory, task tree,
  and Knowledge Map.

## Selected Source Contract

Add one optional family-local clause under each existing `same-id-ordering`
`read` or `write` arm:

```lisp
(same-id-ordering
  (read
    (dynamic-id-reuse reject))
  (write
    (dynamic-id-reuse reject)))
```

The selected clause is distinct from `concrete-id-reuse`. It applies only to
transaction-local `(id dynamic)` transactions whose runtime request ID comes
from the matching `id-families` request-ID signal.

The existing concrete policy remains unchanged and may coexist with the new
dynamic policy in the same family arm:

```lisp
(same-id-ordering
  (read
    (concrete-id-reuse issue-order-queue)
    (dynamic-id-reuse reject)))
```

Each `read` or `write` arm must contain at least one selected policy clause.
Duplicate family arms, duplicate `concrete-id-reuse` clauses, duplicate
`dynamic-id-reuse` clauses, malformed scalar values, and unsupported policy
values fail closed.

## Selected First Policy Value

The first accepted `dynamic-id-reuse` value is only:

```text
reject
```

`reject` means dynamic same-ID concurrency is not accepted. When later
generated behavior owns dynamic selected-ID state for a family, enforcement
is through request-time no-active-same-ID checks and active dynamic-ID
uniqueness assertions, not through a generated queue or scoreboard.

`issue-order-queue` is not selected as a source value in this contract. It
would accept multiple outstanding dynamic transactions with the same runtime
ID and therefore needs an explicit dynamic per-ID queue behavior design,
request arbitration beyond the current onehot0 stance, overflow handling,
and report/residue movement.

`scoreboard` is not selected as a source value in this contract. It has a
different completion-tracking promise from issue-order queues and needs its
own later policy/readiness owner.

Unsupported future spellings such as `dynamic-id-reuse issue-order-queue`,
`dynamic-id-reuse scoreboard`, `dynamic-id-policy`, `user-id-reuse`, or
treating `concrete-id-reuse` as covering dynamic IDs must fail closed until a
later task-tree owner selects them.

## Report Contract

Existing concrete-only reports remain unchanged:

```text
same_id_ordering.mode: concrete_id_reuse_policy
same_id_ordering.concrete_id_reuse_policy.<family>.policy: reject|issue_order_queue
```

The new dynamic policy report uses an additive sibling field:

```text
same_id_ordering.dynamic_id_reuse_policy.<family>.policy: reject
same_id_ordering.dynamic_id_reuse_policy.<family>.implementation_status: selected_not_generated
same_id_ordering.dynamic_id_reuse_policy.<family>.enforcement: not_generated
same_id_ordering.dynamic_id_reuse_policy.<family>.accepted_same_id_reuse: false
same_id_ordering.dynamic_id_reuse_policy.<family>.request_conflict_policy: no_active_same_id
same_id_ordering.dynamic_id_reuse_policy.<family>.generated_queue_behavior: false
same_id_ordering.dynamic_id_reuse_policy.<family>.generated_scoreboard_behavior: false
```

When a later owner wires the policy to already generated dynamic response-demux
state for a covered family, it may change only the covered family fields to:

```text
implementation_status: generated_no_active_same_id_reject
enforcement: generated_no_active_same_id_assertions
assertion_enforcement: runtime_assertion
```

while keeping:

```text
accepted_same_id_reuse: false
generated_queue_behavior: false
generated_scoreboard_behavior: false
```

If dynamic policy is the only same-ID policy in the object, the report mode is
`dynamic_id_reuse_policy`. If concrete and dynamic policies coexist without
auto-ID same-ID avoidance, the report mode is `id_reuse_policy`. Existing
auto-ID same-ID avoidance reports remain valid and may carry the new dynamic
policy as additive metadata.

Residue remains honest. A selected dynamic reject policy does not remove
`same_id_ordering`, `per_id_issue_order_queues`, dynamic queues, or scoreboard
residue unless a later generated behavior owner proves the covered scope.

## Initial Diagnostics

The `.435` audit should decide whether the first parser/report implementation
can directly accept this contract or needs a smaller prerequisite. The target
diagnostics are:

- `dynamic-id-reuse` requires transaction metadata;
- selected family must have at least one `(id dynamic)` transaction;
- selected family must have positive-width matching `id-families` request and
  response ID signals through the existing dynamic-ID validation;
- `dynamic-id-reuse` values other than `reject` fail closed;
- selecting only `concrete-id-reuse` does not select a dynamic policy;
- selecting only `dynamic-id-reuse` does not select a concrete policy;
- same-family dynamic transactions with behavior clauses that do not yet own
  generated dynamic selected-ID state must remain selected-not-generated or
  fail closed as selected by the implementation owner;
- direct queue or scoreboard behavior remains unsupported until a later
  policy owner selects it explicitly.

## Why `.435` Is A Readiness Audit

The public source spelling and report vocabulary are now selected, but the
implementation boundary still needs one focused audit. The code currently has
one `same_id_ordering_policy` normalizer that requires
`concrete_id_reuse`, and a dynamic interaction guard that rejects any
same-family dynamic transaction combined with `same_id_ordering_policy`.

The implementation owner must decide whether to:

- accept `dynamic-id-reuse reject` as metadata-only and report
  `selected_not_generated`;
- report generated reject enforcement for dynamic response-demux shapes that
  already emit no-active-same-ID and active-ID uniqueness assertions;
- keep unsupported dynamic behavior combinations fail-closed until each
  generated family is explicitly mapped;
- add a public sample/support-accounting entry now or defer it until generated
  reject enforcement is reported;
- or split a smaller parser/report restructuring prerequisite before accepting
  the source spelling.

That decision is narrower than a queue or scoreboard behavior owner and
should happen before parser code changes.

## Preservation Matrix

`.435` and later implementation slices must preserve:

- existing `(id dynamic)` transaction-local semantics and metadata reports;
- existing `concrete-id-reuse reject` and `concrete-id-reuse
  issue-order-queue` parser/report behavior;
- generated concrete queue-head behavior, counted request-set capacity-fit
  guards, and group-local request assertions;
- generated dynamic and mixed dynamic/static response-demux/read-data/
  raw-`ARLEN`/runtime-validation/multi-beat/recapture behavior;
- current no-active-same-ID and pairwise active dynamic-ID uniqueness
  assertions until a later queue/scoreboard owner explicitly changes the
  accepted concurrency model;
- auto-ID lifecycle behavior and generated auto-ID same-ID avoidance;
- public sample identities, support-accounting identities, check JSON,
  semantic JSON, schedule JSON, generated artifacts, and HDL behavior until a
  later implementation owner changes them explicitly;
- direct backend deferral, verification-output deferral, VHDL deferral, and
  backend-language neutrality.

## Non-Goals

- Do not implement parser/report support in `.434`.
- Do not accept `dynamic-id-reuse issue-order-queue` or
  `dynamic-id-reuse scoreboard` in `.434` or `.435` unless `.435` selects a
  later exact owner.
- Do not implement dynamic same-ID queues, scoreboards, request arbitration
  beyond current bounded onehot0 shapes, overflow handling, ambiguity
  assertions, or HDL behavior in `.434`.
- Do not reinterpret `concrete-id-reuse` as covering dynamic IDs.
- Do not change generated dynamic/mixed response-demux, read-data, recapture,
  generated artifacts, samples, support accounting, tests, direct backend,
  VHDL, or backend-language variants in `.434`.

## Validation For This Selector

Selector closeout requires:

```bash
bash knowledge-map/scripts/gen_knowledge_map.sh
bash knowledge-map/scripts/check_knowledge_map.sh
scripts/check_memory_architecture.sh
git --no-pager diff --check
mdbook build docs/book
scripts/check_doctrines.sh
```

No behavior-bearing command is required for `.434`.

## Rollback

Rollback is this docs-only selector commit. Reverting it removes only the
dynamic same-ID contract selection record, fact card, task-tree advancement,
live-doc updates, and resume pointer update; generated behavior remains at
`.431` plus the existing dynamic/mixed chain.
