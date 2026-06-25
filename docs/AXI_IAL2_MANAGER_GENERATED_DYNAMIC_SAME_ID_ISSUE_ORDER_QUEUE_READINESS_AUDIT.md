# AXI IAL2 Manager Generated Dynamic Same-ID Issue-Order Queue Readiness Audit

Task-tree owner: `IAL2-FEATURE-COMPLETENESS-FRONTIER.452`

Date: 2026-06-24

## Outcome

`IAL2-FEATURE-COMPLETENESS-FRONTIER.452` selects
`IAL2-FEATURE-COMPLETENESS-FRONTIER.453`, public contract selection for
generated dynamic same-ID `issue-order-queue` behavior.

This audit changes no parser, generator, PPIF sample, support-accounting
catalog, validation behavior, generated artifact, test, schedule/check or
semantic JSON, HDL, runtime behavior, direct backend behavior,
backend-language variant, queue, scoreboard, or VHDL behavior.

## Inputs Read

The audit read:

- `.451` post dynamic issue-order metadata selector;
- `.450` metadata-first dynamic same-ID `issue-order-queue` behavior;
- `.449` public dynamic same-ID `issue-order-queue` policy contract;
- `.448` dynamic issue-order policy readiness audit;
- `.446`, `.442`, and `.438` generated dynamic same-ID `reject` mapping
  behavior records;
- `.436` metadata-first `(dynamic-id-reuse reject)` behavior and `.434`
  dynamic same-ID policy contract;
- `.216` dynamic same-ID issue-order readiness audit and `.217` dynamic
  transaction-ID public contract selection;
- generated dynamic write/read/read-burst-last response-demux, read-data,
  multi-beat, and recapture behavior records;
- concrete same-ID `issue-order-queue` admitted-request, queue-state
  representation, queue-head demux, and generated behavior records;
- current PPIF parser/report/support-accounting surfaces and `.450`
  validation caveat;
- README, ROADMAP_V2, mdBook, Memory, task tree, and Knowledge Map.

## Current Boundary

Dynamic issue-order metadata is now accepted and honestly reported:

```text
dynamic_id_reuse_policy.<family>.policy: issue_order_queue
implementation_status: selected_not_generated
enforcement: not_generated
accepted_same_id_reuse: false
generated_queue_behavior: false
generated_scoreboard_behavior: false
residue: dynamic_per_id_issue_order_queues
```

Generated dynamic response-demux behavior already covers bounded runtime-ID
capture and matching for selected shapes:

- single-active write `BID`, read single-beat `RID`, and read burst-last
  `RID && RLAST`;
- multiple all-dynamic write `BID`, read single-beat `RID`, and read
  burst-last `RID && RLAST`;
- selected mixed dynamic/static write and read response-demux shapes;
- selected read-data, burst-length, runtime-validation, multi-beat output-bank,
  and same-cycle release-and-recapture consumers over those dynamic demuxes.

Those generated dynamic demux contracts deliberately keep same-ID reuse out:
multiple dynamic contracts use onehot0 same-family request assertions and
active dynamic ID uniqueness assertions, and generated reject mappings only
map `(dynamic-id-reuse reject)` to those exclusion proofs.

## Readiness Findings

The lower `IAL2 -> IAL1 -> IAL0 -> SystemVerilog` substrate is not the first
blocker. Existing shipped behavior already generates scalar selected-ID
storage, busy bits, admitted request capture guards, guarded response-ID
comparisons, pulse completions, release and release-recapture rules,
onehot0 assertions, active-ID uniqueness assertions, and completion-active
assertions.

Concrete same-ID `issue-order-queue` behavior provides a useful precedent for
staged queue work: metadata first, admitted request boundary, queue-state
representation, queue-head demux contract, generated queue state/demux, then
read-data/burst/runtime consumers. That precedent cannot be copied directly
because concrete queue groups are static `(family, concrete ID value)` groups,
while dynamic queues must group by a runtime ID sampled at admission.

Direct generated dynamic queue behavior is not ready. It would need to decide
public and generated semantics for too many surfaces in one slice:

- whether generated dynamic queue behavior requires explicit
  `response-demux.<family>` and which first family/scope is covered;
- whether the first covered shape is single-active, all-dynamic multiple,
  mixed dynamic/static, write-only, read single-beat, or read burst-last;
- how the generated queue key is represented when the ID value is captured at
  runtime instead of known at compile time;
- whether queue entries store transaction identity, captured ID value, busy
  state, or a selected combination;
- how enqueue/dequeue and same-cycle enqueue/dequeue interact with existing
  release-recapture behavior;
- how responses match a queue head for `BID`, `RID`, and `RID && RLAST`;
- which existing no-active-same-ID and active-ID uniqueness assertions are
  replaced, preserved, or moved to policy-specific overflow/ambiguity
  assertions;
- how report fields and residue move from selected-not-generated metadata to
  generated queue behavior.

## Candidate Comparison

A generated implementation slice is rejected as too broad. It would combine a
new public contract, queue representation, generated rules, assertion policy,
sample/support accounting, diagnostics, and HDL behavior.

A narrower prerequisite such as admitted-request capture or runtime-ID state
representation is plausible, but the project first needs a public contract
selector to decide whether that narrower prerequisite is the correct first
behavior owner. Selecting a prerequisite without the public queue contract
would risk naming internal state before the supported family/scope and report
contract are fixed.

Keeping generated dynamic queues deferred with no next owner is not selected.
The user-visible metadata now exposes `dynamic_per_id_issue_order_queues`
residue, and the generated dynamic demux substrate is mature enough to support
a contract-selection pass.

Dynamic `scoreboard` is not selected. It remains a separate unsupported policy
with different completion-tracking semantics from FIFO issue-order queue
behavior.

Report cleanup, direct backend behavior, backend-language variants, and VHDL
are not selected. Current reports are honest, and downstream backend work must
wait for the SystemVerilog-backed public behavior contract.

## Selected `.453` Boundary

`.453` should select the public contract for generated dynamic same-ID
`issue-order-queue` behavior before implementation. It should decide:

- the first generated behavior scope: write `BID`, read single-beat `RID`,
  read burst-last `RID && RLAST`, or a narrower prerequisite;
- whether the first shape is all-dynamic only, single-active only, or mixed
  dynamic/static;
- whether explicit `response-demux.<family>` is required for generated
  dynamic queue behavior;
- generated queue key, entry state, and representation vocabulary for runtime
  ID values;
- admitted request capture source and queue enqueue rules;
- dequeue and same-cycle enqueue/dequeue policy;
- response matching and completion-pulse ownership;
- overflow, duplicate-admission, empty-response, inactive-response,
  no-match, multi-match, and ambiguous-response assertions;
- report fields for `implementation_status`, `enforcement`,
  `accepted_same_id_reuse`, `generated_queue_behavior`, generated rules,
  generated assertions, covered transactions, and residue movement;
- diagnostics, public sample/support-accounting impact, validation gates,
  rollback, and non-goals.

`.453` may decide that the first implementation owner should instead be a
narrower prerequisite, such as dynamic admitted-request queue-entry capture or
runtime-ID queue-state representation. It should make that split explicit.

## Preservation Matrix

`.453` must preserve:

- metadata-first `dynamic-id-reuse issue-order-queue` behavior from `.450`;
- generated dynamic same-ID `reject` mapping behavior from `.438`, `.442`,
  and `.446`;
- generated dynamic response-demux/read-data/burst/runtime/multi-beat and
  recapture behavior already selected;
- concrete same-ID issue-order queue behavior and report contracts;
- current support-accounting identities and public PPIF sample identities
  unless `.453` explicitly selects a later implementation sample;
- direct backend deferral, VHDL deferral, and backend-language neutrality.

## Non-Goals

- Do not implement parser, generator, PPIF sample, support-accounting, test,
  schedule/check/semantic JSON, HDL, or runtime behavior in `.452`.
- Do not accept dynamic same-ID reuse or report generated dynamic queue
  behavior in `.452`.
- Do not select or implement dynamic `scoreboard`.
- Do not reinterpret generated dynamic `reject` mappings as queue behavior.
- Do not change direct backend behavior, VHDL behavior, or backend-language
  variants.

## Validation For `.452`

Because `.452` is a readiness audit, validation is documentation and
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

Rollback for `.452` is this docs-only audit commit. Reverting it removes the
`.453` selection, fact card, task-tree advancement, live-doc updates, and
resume pointer update without changing generated behavior.
