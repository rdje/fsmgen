# AXI IAL2 Manager Dynamic Transaction-ID Contract Selection

Status: selector for `IAL2-FEATURE-COMPLETENESS-FRONTIER.217` on 2026-06-22.

Task-tree owner: `IAL2-FEATURE-COMPLETENESS-FRONTIER.217`

## Decision

Select a transaction-local dynamic ID source contract and advance to
`IAL2-FEATURE-COMPLETENESS-FRONTIER.218`, readiness audit for metadata-first
dynamic transaction-ID parser/report support.

The selected public spelling is:

```lisp
(transactions
  (read r0
    (tag rd0)
    (request axi0_r0_request)
    (completion axi0_r0_complete)
    (id dynamic)))
```

`dynamic` means the transaction's request ID is supplied by the family
request-ID signal declared under `id-families` at the transaction's admitted
request point. For reads, that is the selected read `request-id` signal; for
writes, the selected write `request-id` signal. The matching response family
still uses the corresponding `response-id` signal from `id-families`.

This selector changes no parser, generator, PPIF sample, support-accounting
catalog, validation, generated artifact, test, or HDL behavior.

## Why The Contract Is Transaction-Local

The existing public transaction ID contract is already transaction-local:

```lisp
(id auto)
(id (value 3))
```

Adding `dynamic` as a third transaction ID policy keeps the source shape local
to the transaction whose request event observes the runtime ID value. It also
avoids creating a second ID source namespace parallel to `id-families`.

`id-families` remains the signal declaration owner. It already names the AXI
request and response ID signals:

```lisp
(id-families
  (read (width 4) (request-id axi0_arid) (response-id axi0_rid))
  (write (width 4) (request-id axi0_awid) (response-id axi0_bid)))
```

A dynamic transaction therefore does not need a per-transaction ID signal
override in the first contract. Its request ID source is the family request-ID
signal visible when that transaction's request event is admitted.

## Selected Report Vocabulary

The normalized transaction report should use:

```yaml
transactions:
  - name: r0
    kind: read
    tag: rd0
    request_event: axi0_r0_request
    completion_event: axi0_r0_complete
    id:
      policy: dynamic
      family: read
      family_width: 4
      request_id_source: axi0_arid
      response_id_signal: axi0_rid
      ownership: user_supplied
      implementation_status: selected_not_generated
```

The `policy` value is `dynamic`, matching the public spelling. The
`ownership` value is `user_supplied` to distinguish this path from
generator-owned `auto` allocation and static `concrete` IDs. The
`implementation_status` remains `selected_not_generated` until a later owner
generates request-ID capture, outstanding tracking, response matching, and
ordering behavior.

## Initial Semantics

`(id dynamic)` is a source/report contract first. It does not by itself
generate:

- request-ID capture storage;
- selected-ID output drive;
- concrete request/response ID assertions;
- response demux;
- same-ID ordering queues;
- scoreboards;
- read-data routing;
- support-accounted HDL behavior.

The first metadata implementation may accept a dynamic transaction only when
the selected family has a positive-width `id-families` entry with both
request and response ID signals. It must fail closed when downstream behavior
would require generated response matching or ordering that is not selected.

## Interaction With Existing Policies

`auto` remains generator-owned allocation. It is still the only policy
eligible for `auto-id-lifecycle` behavior.

`concrete` remains static value metadata and, when behavior-bearing, concrete
request/response ID assertion or bounded concrete queue-head behavior.

`dynamic` is neither `auto` nor `concrete`. Existing
`same-id-ordering.<family>.concrete-id-reuse` policy does not cover dynamic
transactions. A later owner must select a dynamic same-ID policy surface,
likely under a separate report field or an additive family-local clause, before
generalized per-ID issue-order queues or scoreboards can be generated.

## Diagnostics

The metadata implementation selected by `.218` should fail closed for:

- `(id dynamic)` without `id-families`;
- `(id dynamic)` when the selected family has width `0`;
- missing request or response ID family signals;
- use of a dynamic transaction in `auto-id-lifecycle`;
- generated `response-demux`, `read-data`, or same-ID ordering behavior that
  needs dynamic response matching before request-ID capture and outstanding
  tracking are selected;
- attempts to treat `concrete-id-reuse` as covering dynamic transaction IDs;
- unsupported dynamic ID spellings such as `(id user)`, `(id (signal ...))`,
  or `(id (dynamic ...))` until separately selected.

The existing parser diagnostic that says only `auto` and concrete values are
supported remains the rollback baseline until `.218` or a later implementation
changes parser behavior.

## Why Not Generated Behavior Next

Generated dynamic ID behavior would need to sample the request ID at admitted
request time, store it with transaction/outstanding state, compare response
IDs against stored values, preserve response ordering for equal stored IDs,
and decide how different-ID interleaving interacts with read-data routing.
That is broader than the current bounded concrete queue-head implementation.

The safe next owner is therefore a readiness audit for metadata-first parser
and report behavior. That audit can decide whether to implement the metadata
slice directly or split out a narrower diagnostic/report prerequisite.

## Selected `.218` Boundary

`.218` should audit metadata-first implementation readiness for `(id
dynamic)`. It should decide:

- exact parser changes and diagnostics;
- normalized transaction report fields;
- generated behavior that must remain absent;
- fail-closed interactions with `auto-id-lifecycle`, `response-demux`,
  `same-id-ordering`, `read-data`, strict check JSON, semantic JSON, and HDL;
- whether a public PPIF sample/support-accounting entry belongs in the
  metadata-first implementation or a later behavior owner;
- validation gates, rollback, docs, Knowledge Map impact, and non-goals.

## Preservation Matrix

`.218` must preserve:

- existing `(id auto)` and `(id (value N))` parser/report behavior;
- concrete-ID assertions and duplicate concrete same-ID diagnostics;
- auto-ID lifecycle behavior and generated auto-ID same-ID avoidance;
- bounded concrete same-ID queue-head response-demux/read-data/burst/runtime
  behavior and counted group-local admitted-request guards;
- support-accounting identities, strict check JSON, semantic JSON, and HDL
  generation for public samples;
- direct backend deferral, verification-output deferral, VHDL deferral, and
  backend-language neutrality.

## Non-Goals

- Do not implement `(id dynamic)` parser/report behavior in `.217`.
- Do not implement dynamic ID capture, generalized per-ID queues,
  scoreboards, response demux, read-data routing, or support-accounted HDL in
  `.217` or `.218` unless `.218` selects a later implementation owner.
- Do not add a dynamic same-ID ordering policy in `.217`.
- Do not change direct backend, verification-output generation, VHDL, or
  backend-language variants.

## Validation Gates

For `.217`, documentation and continuity gates are sufficient:

```bash
env -u PERL5LIB ./bin/fsmgen --emit-schedule-json ppif/axi_manager_capacity_status_transaction_envelope.ppif
env -u PERL5LIB ./bin/fsmgen --emit-schedule-json ppif/axi_manager_capacity_status_transaction_event_dispatch.ppif
bash knowledge-map/scripts/gen_knowledge_map.sh
mdbook build docs/book
env -u PERL5LIB prove -Iperl t/1414-docs-relative-paths-audit.t
bash knowledge-map/scripts/check_knowledge_map.sh
scripts/check_memory_architecture.sh
git --no-pager diff --check
```

Any parser, support-accounting, strict check, semantic JSON, generated-HDL, or
focused PPIF/generator suite belongs to a later implementation owner.

## Rollback Boundary

Rollback for `.217` is limited to this selector record, task-tree frontier
movement, Memory, README, roadmap, mdBook, and Knowledge Map/fact-card
updates. No parser, generator, public sample, support-accounting catalog,
generated artifact, test, validation, or HDL behavior is part of this slice.
