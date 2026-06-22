# AXI IAL2 Manager Post Counted Capacity Next Slice Selection

Status: selector for `IAL2-FEATURE-COMPLETENESS-FRONTIER.212` on
2026-06-22.

Task-tree owner: `IAL2-FEATURE-COMPLETENESS-FRONTIER.212`

## Decision

Select `IAL2-FEATURE-COMPLETENESS-FRONTIER.213`, readiness audit for aligning
same-ID admitted-request pulses with counted request-set capacity before any
group-local simultaneous enqueue behavior change.

The counted capacity substrate from `.211` is necessary but not sufficient for
group-local same-ID enqueue widening. The capacity/status matrix can now count
selected concrete-ID request groups and reject an over-capacity current
request set, but the admitted-request pulse guards still use only scalar
pending storage plus Boolean completion fan-in. If the family-wide request
onehot assertion were narrowed directly, distinct concrete-ID groups could
produce admitted pulses in a cycle that the counted capacity matrix rejects.

This selector changes no parser, generator, PPIF sample, support-accounting
catalog, validation, generated artifact, test, or HDL behavior.

## Evidence Read

The selector read:

- `.211` counted substrate behavior:
  `docs/AXI_IAL2_MANAGER_COUNTED_SAME_ID_CAPACITY_SUBSTRATE_BEHAVIOR.md`.
- `.210` counted admission/capacity audit:
  `docs/AXI_IAL2_MANAGER_COUNTED_ADMISSION_CAPACITY_READINESS_AUDIT.md`.
- `.209` group-local same-ID enqueue audit:
  `docs/AXI_IAL2_MANAGER_GROUP_LOCAL_SAME_ID_ENQUEUE_READINESS_AUDIT.md`.
- Current generator code around `_build_same_id_admitted_request_boundary`,
  `_apply_counted_request_accounting`,
  `_build_same_id_issue_order_queue_behavior`,
  `_same_id_issue_order_queue_transition_specs`,
  `_same_id_admitted_request_assertion_specs`, and `_direction_rules`.
- Focused generator and PPIF/CLI expectations for counted accounting,
  family-wide request onehot assertions, generated queue transitions, and
  low-capacity probes.
- Public PPIF samples for read multi-group, write multi-group, and mixed
  auto-ID plus concrete same-ID queue-head behavior.
- Support accounting, README, `ROADMAP_V2.md`, mdBook, downstream handoff,
  public interface contract, task tree, Memory, and Knowledge Map.

## Current Boundary

Generated same-ID queue-head families with multiple concrete-ID groups now
report counted selected-request accounting in the shared capacity/status
matrix:

```text
request_accounting.mode = counted_same_id_selected_requests
generated_scheduler_or_status_rules.accounting_mode = counted_submit
over_capacity_policy = reject_current_request_set
```

The read and write multi-group reports count one request term per concrete-ID
queue group. Low-capacity probes in `.211` prove that a two-group request set
at occupancy 2 with max-pending 3 is rejected without changing the public
pending/status outputs.

The admitted-request boundary remains family-wide. It still emits
`axi0_read_issue_order_queue_request_onehot0` or
`axi0_write_issue_order_queue_request_onehot0`, and the admitted-pulse guard
for each concrete transaction still has the shape:

```lisp
(& <transaction_request>
   (| (< <pending_storage> <max_pending>)
      <completion_fanin>))
```

That guard is safe only while the family-wide onehot keeps legal public inputs
to one selected same-direction request per cycle. With group-local onehot
assertions, two distinct concrete-ID groups could both satisfy the guard when
only one slot is available, even though the counted capacity matrix's
`reject_current_request_set` policy rejects the pair.

Queue transition generation is not the first remaining blocker for distinct
groups. `_same_id_issue_order_queue_transition_specs` is scoped to a single
concrete-ID group, selects at most one enqueue within that group, and excludes
only the other admitted pulses in the same group. Separate concrete-ID groups
already produce separate transition-rule sets.

## Candidate Comparison

A direct group-local enqueue implementation is not selected yet because it
would need to update both the assertion boundary and admitted-pulse acceptance
in one behavior-bearing slice. The acceptance expression must be audited
first: admitted pulses must not enqueue into issue-order queues when the
counted capacity matrix rejects the current request set.

A report-only cleanup is not selected first because `.211` already exposes the
counted capacity owner, request groups, request-count expression, maximum
request count, counted-submit capacity matrix, and over-capacity policy. The
remaining risk is executable acceptance semantics rather than stale public
wording.

Broader concrete same-ID queues, deeper queues, packed burst-vector outputs,
alternate full burst payload assembly, direct backend lowering,
verification-output generation, VHDL, and backend-language variants remain
deferred. They would either build on the same admission boundary or belong to
separate roadmap lanes.

## Selected `.213` Audit Boundary

`.213` must audit the bounded behavior prerequisite for group-local same-ID
enqueue widening:

- derive or select the exact expression that means the current counted request
  set fits the public pending/status capacity matrix;
- decide whether admitted-request pulse guards should consume that expression
  directly, reuse a generated helper signal, or be generated from the same
  counted-accounting metadata as the capacity matrix;
- define how the family-wide request onehot assertion narrows to per
  concrete-ID group onehots while keeping same-group simultaneous requests
  fail-closed or asserted;
- preserve Boolean admission for non-counted directions and mixed auto-ID
  plus a single concrete same-ID queue group;
- define additive report fields if the admitted boundary needs to publish
  `accepted_request_set` or guard-source metadata beyond the existing
  `request_count_expression`;
- select either the direct `.214` behavior owner or a smaller prerequisite if
  the audit finds an IAL1/IAL0/SystemVerilog lowering gap.

No behavior change belongs in `.213` unless that audit explicitly selects a
later implementation owner first.

## Preservation Matrix

`.213` and any later implementation must preserve:

- current family-wide one-request-per-direction public behavior until the
  owning behavior leaf intentionally narrows the assertion;
- counted capacity/status reports and low-capacity semantics from `.211`;
- read/write multi-group, depth-3, multiple/mixed depth-3, and mixed auto-ID
  plus concrete queue-head response-demux behavior;
- read-data, burst-length, runtime-validation, multi-beat output-bank, and
  scalar aggregation behavior built on generated queue-head completions;
- support-accounting identities, strict check JSON, semantic JSON, and HDL
  generation for all public samples;
- parser syntax, PPIF sample set, and the required
  `IAL2 -> IAL1 -> IAL0 -> SystemVerilog` lowering path.

## Non-Goals

- Do not implement group-local simultaneous enqueue behavior in `.213`.
- Do not remove or narrow the family-wide request onehot before the
  admitted-pulse acceptance guard is owned.
- Do not add PPIF syntax or public samples in `.213`.
- Do not add packed burst-vector outputs, alternate payload assembly, direct
  backend behavior, verification-output generation, VHDL, or
  backend-language variants.
- Do not bypass generated IAL1 and IAL0 review artifacts.

## Validation Gates

For `.212`, the required gates are documentation and continuity gates:

```bash
bash knowledge-map/scripts/gen_knowledge_map.sh
mdbook build docs/book
env -u PERL5LIB prove -Iperl t/1414-docs-relative-paths-audit.t
bash knowledge-map/scripts/check_knowledge_map.sh
scripts/check_memory_architecture.sh
git --no-pager diff --check
```

`.213` should add compact schedule/report probes over the read/write
multi-group public samples, the `.211` low-capacity shape, and a temporary
distinct-group request-set scenario before selecting implementation.

## Rollback Boundary

Rollback for `.212` is limited to this selector record, task-tree frontier
movement, Memory, README, roadmap, mdBook, and Knowledge Map updates. No
parser, generator, public sample, support-accounting catalog, generated
artifact, test, or HDL behavior is part of this slice.
