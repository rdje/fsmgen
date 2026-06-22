# AXI IAL2 Manager Counted Admitted-Request Guard Readiness Audit

Status: readiness audit for `IAL2-FEATURE-COMPLETENESS-FRONTIER.213` on
2026-06-22.

Task-tree owner: `IAL2-FEATURE-COMPLETENESS-FRONTIER.213`

## Decision

Select `IAL2-FEATURE-COMPLETENESS-FRONTIER.214`, direct bounded
implementation of counted admitted-request guard alignment and group-local
same-ID request assertions for generated multi-group queue-head families.

The existing substrate has enough lower-layer support for the next behavior
slice. The IAL1 parser/lowerer already accepts arithmetic and comparison
expressions such as `+`, `-`, `<`, `<=`, `>`, and `>=` in rule guards and wait
expressions. The remaining work is local to the AXI manager IAL2 generator:
derive a counted current-request-set fit expression from the same accounting
metadata that drives the capacity/status matrix, gate admitted-request pulses
with that fit expression, and narrow the request mutual-exclusion assertions
from family-wide to concrete-ID group-local only for counted multi-group
families.

This audit changes no parser, generator, PPIF sample, support-accounting
catalog, validation, generated artifact, test, or HDL behavior.

## Evidence Read

The audit read:

- `.212` selector:
  `docs/AXI_IAL2_MANAGER_POST_COUNTED_CAPACITY_NEXT_SLICE_SELECTION.md`.
- `.211` counted substrate behavior:
  `docs/AXI_IAL2_MANAGER_COUNTED_SAME_ID_CAPACITY_SUBSTRATE_BEHAVIOR.md`.
- `.210` counted admission/capacity audit and `.209` group-local enqueue
  audit.
- Generator code around `_build_same_id_admitted_request_boundary`,
  `_same_id_admitted_request_guard_expr`,
  `_apply_counted_request_accounting`,
  `_counted_direction_rules`,
  `_counted_rule_assignments`, `_capacity_matrix_report_entry`,
  `_same_id_issue_order_queue_transition_specs`, and expression helpers.
- IAL1 parser/lowerer expression support in `perl/FSM/Adapter/ISF/Parser.pm`
  and `perl/FSM/Scheduler/ISF/LoweringIR.pm`.
- Focused generator and PPIF/CLI tests around same-ID request onehot
  assertions, counted accounting, generated queue transitions, and
  low-capacity behavior.
- Public PPIF samples for read multi-group, write multi-group, and mixed
  auto-ID plus concrete same-ID queue-head behavior.
- README, `ROADMAP_V2.md`, mdBook, downstream handoff, public interface
  contract, task tree, Memory, and Knowledge Map.

## Live Probe Findings

The read multi-group public sample reports counted read accounting and Boolean
write accounting:

```text
read:
  request_accounting.mode=counted_same_id_selected_requests
  request_count_expression=(+ (| axi0_r0_request axi0_r1_request)
                              (| axi0_r2_request axi0_r3_request))
  maximum_request_count=2
  capacity_owner=generated_scheduler_or_status_rules.read_capacity_matrix
  generated_scheduler_or_status_rules.accounting_mode=counted_submit

write:
  request_accounting.mode=boolean_fanin
  generated_scheduler_or_status_rules.accounting_mode=boolean_submit
```

The write multi-group public sample is symmetric: write is counted-submit and
read stays Boolean.

The same-family mixed auto-ID plus one concrete same-ID queue-head sample
stays Boolean for both directions because there is only one concrete-ID queue
group to count. It should therefore preserve the existing family-wide request
onehot behavior in `.214`.

The admitted request boundary still publishes:

```text
guard_source=capacity_storage_and_completion_fanin
generated_assertions=axi0_read_issue_order_queue_request_onehot0
first_guard=(& axi0_r0_request
               (| (< axi0_pending_reads_q 4)
                  (| axi0_r0_complete axi0_r1_complete
                     axi0_r2_complete axi0_r3_complete)))
```

For the write sample the shape is identical over `pending_writes_q`,
`w0..w3`, and `axi0_write_issue_order_queue_request_onehot0`.

This is the exact boundary `.214` must change for counted multi-group
families only.

## Code Findings

`_same_id_admitted_request_guard_expr` currently accepts a request when the
raw request event is true and either the scalar pending counter is below
`max_pending` or any same-direction completion is present.

That Boolean guard is intentionally conservative under the current family-wide
request onehot assertion, but it is not aligned with the `.211` counted
capacity matrix once distinct concrete-ID groups can request in the same
cycle. With two selected request groups and only one slot available, the
counted matrix rejects the current request set while each request's admitted
pulse would still satisfy the scalar guard.

`_counted_rule_assignments` already defines the executable public-status
semantics:

- completion credits at most one slot;
- completion credits only when the current occupancy is greater than zero;
- the current request set is accepted only when `request_count <= capacity`;
- over-capacity request sets leave pending/status at the post-completion base
  occupancy and report `can_accept=0`.

The safest `.214` guard contract is to generate a current-request-set fit
expression that mirrors those same occupancy/completion cases, instead of
using a simpler arithmetic expression that would accidentally credit a
completion when occupancy is zero. An enumerated guard can be built from the
same `max_pending`, pending storage, completion fan-in, and
`request_count_expression` metadata as the capacity matrix:

```lisp
(|
  (& (== pending_q 0) (! completion) (<= request_count max_pending))
  (& (== pending_q 0) completion    (<= request_count max_pending))
  (& (== pending_q 1) (! completion) (<= request_count (- max_pending 1)))
  (& (== pending_q 1) completion    (<= request_count max_pending))
  ...)
```

The generator lacks local `_le_expr` and subtraction helper functions today,
but the IAL1 expression substrate supports those operators. Adding local
string helpers in the AXI generator is a bounded implementation detail, not a
lower-layer prerequisite.

`_same_id_issue_order_queue_transition_specs` remains structurally ready for
distinct-group simultaneous enqueue. It builds transitions per concrete-ID
group, excludes competing enqueues only inside the same group, and emits
separate rule sets for separate groups.

## Selected `.214` Implementation Boundary

`.214` should implement exactly the counted multi-group behavior boundary:

- apply only to generated same-ID queue-head families whose direction reports
  `request_accounting.mode: counted_same_id_selected_requests`;
- derive a counted current-request-set fit expression from the capacity
  matrix's request-count expression, pending storage, max-pending bound, and
  completion fan-in;
- gate each counted family's admitted-request pulse with that fit expression;
- report the admitted-boundary guard source as counted capacity/status
  request-set fit, additively exposing the fit expression if needed for
  review;
- replace the family-wide request onehot assertion for counted multi-group
  families with one request onehot assertion per concrete-ID queue group;
- keep same-group simultaneous requests rejected or asserted by those
  group-local request assertions;
- allow distinct concrete-ID group requests only when the counted request set
  fits the current capacity state;
- preserve Boolean admission and existing family-wide request assertions for
  non-counted directions and mixed auto-ID plus one concrete-ID queue group.

No PPIF syntax or new public sample is required for `.214`; the existing
read/write multi-group public samples are sufficient to prove the generated
behavior, report, check JSON, semantic JSON, and HDL deltas.

## Expected Report Impact

The existing `.211` counted fields should remain stable:

- `transaction_event_dispatch.directions[].request_accounting.mode`
- `counted_request_events`
- `counted_request_terms`
- `counted_request_groups`
- `request_count_expression`
- `maximum_request_count`
- `over_capacity_policy`
- `generated_scheduler_or_status_rules[].accounting_mode`

`.214` may add admitted-boundary metadata such as:

- `admitted_request_boundary.accounting_mode:
  counted_capacity_storage_and_completion_fanin`
- `admitted_request_boundary.guard_source:
  counted_request_set_capacity_fit`
- `admitted_request_boundary.request_set_fit_expression`
- per-group request assertion names under `generated_assertions` or a new
  grouped assertion field.

It must not remove the counted capacity/status metadata introduced by `.211`.

## Validation Gates For `.214`

Focused implementation gates should include:

```bash
env -u PERL5LIB perl -Iperl -c perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm
env -u PERL5LIB perl -c t/1437-axi-ial2-manager-capacity-status-generator.t
env -u PERL5LIB perl -c t/1436-ial2-ppif-parser-cli.t
env -u PERL5LIB ./bin/fsmgen --emit-schedule-json ppif/axi_manager_capacity_status_read_multi_group_same_id_queue_head_response_demux.ppif
env -u PERL5LIB ./bin/fsmgen --emit-schedule-json ppif/axi_manager_capacity_status_write_multi_group_same_id_queue_head_response_demux.ppif
```

The implementation should also add low-capacity read/write probes that prove
over-capacity distinct-group request sets do not produce admitted pulses, and
preservation probes for the mixed auto-ID single concrete-group sample and
non-counted Boolean directions.

Closeout gates should include Knowledge Map generation/check, mdBook build,
docs path audit, memory architecture check, README docs-index numbering scan,
and diff hygiene. Any broad `prove` or supported-corpus gate must use the RAM
guard.

## Preservation Matrix

`.214` must preserve:

- existing PPIF syntax and public sample set;
- counted capacity/status matrix semantics from `.211`;
- Boolean admission for ordinary directions and mixed auto-ID plus one
  concrete same-ID queue group;
- generated queue-head response-demux, read-data, burst-length,
  runtime-validation, multi-beat output-bank, and scalar aggregation behavior
  other than the admitted request guard/assertion boundary;
- support-accounting identities, strict check JSON, semantic JSON, and HDL
  generation for existing public samples;
- the required `IAL2 -> IAL1 -> IAL0 -> SystemVerilog` lowering path.

## Non-Goals

- Do not add PPIF syntax or new public samples in `.214`.
- Do not broaden queue depth or queue family coverage.
- Do not add packed burst-vector outputs or alternate payload assembly.
- Do not change direct backend, verification-output generation, VHDL, or
  backend-language behavior.
- Do not introduce a separate same-ID-only capacity overlay outside the shared
  capacity/status matrix.

## Rollback Boundary

Rollback for `.213` is documentation-only. Rollback for the later `.214`
implementation should revert the admitted-request guard/assertion changes,
focused expectations, report/docs updates, and task/memory/fact-card updates,
returning the legal public behavior to the `.211` family-wide request onehot
boundary.
