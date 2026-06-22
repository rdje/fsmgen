# AXI IAL2 Manager Dynamic Same-ID Issue-Order Readiness Audit

Status: audit for `IAL2-FEATURE-COMPLETENESS-FRONTIER.216` on 2026-06-22.

Task-tree owner: `IAL2-FEATURE-COMPLETENESS-FRONTIER.216`

## Decision

Select `IAL2-FEATURE-COMPLETENESS-FRONTIER.217`, public contract selection
for dynamic/user transaction IDs before generalized per-ID issue-order queues.

The current generated AXI manager same-ID queue-head behavior is deliberately
bounded around statically enumerable concrete-ID transaction groups. It can
generate compact one-hot queue slots, admitted-request enqueue pulses,
queue-head response demux, read-data, burst-length, runtime-validation, and
multi-beat output-bank behavior because every generated queue group has a
compile-time concrete ID value and a finite transaction inventory.

That representation does not directly generalize to dynamic/user request IDs.
The public PPIF transaction surface currently accepts only `(id auto)` and
`(id (value N))`; there is no source spelling for a transaction whose request
ID is supplied dynamically by a user signal. As a result, generalized per-ID
queues or scoreboards would need a public source/report contract first, not a
direct behavior implementation.

This audit changes no parser, generator, PPIF sample, support-accounting
catalog, validation, generated artifact, test, or HDL behavior.

## Evidence Read

The audit read:

- `.215` post counted group-local enqueue selector.
- `.214` counted admitted-request guard behavior, `.213` admitted guard audit,
  `.211` counted capacity substrate, and `.209`/`.210` group-local enqueue
  and counted admission audits.
- The same-ID issue-order queue contract, metadata, admitted-pulse, state
  representation, queue-head demux, write/read queue-head behavior, and
  concrete-ID assertion docs.
- Current PPIF transaction-ID parsing and AXI manager transaction
  normalization, which accept only `auto` and concrete values.
- Current generator paths for same-ID ordering reports, admitted boundaries,
  counted request accounting, queue behavior, response-demux integration, and
  support/unsupported-residue prose.
- Focused generator and PPIF/CLI expectations around
  `per_id_issue_order_queues`, `selected_not_generated`,
  `counted_request_set_capacity_fit`, and `request_assertion_scope`.
- Public queue-head samples, support accounting, README, `ROADMAP_V2.md`,
  mdBook, task tree, Memory, and Knowledge Map.

## Live Report Probes

Compact live probes confirm the current boundary:

```text
ppif/axi_manager_capacity_status_same_id_issue_order_queue_policy.ppif
  same_id_ordering.generated_behavior=0
  read policy=issue_order_queue
  enforcement=admitted_request_boundary
  accepted_same_id_reuse=0
  generated_queue_behavior=0
  residue=[concrete_id_same_id_ordering, per_id_issue_order_queues]

ppif/axi_manager_capacity_status_read_multi_group_same_id_queue_head_response_demux.ppif
  same_id_ordering.generated_behavior=1
  implementation_status=generated_read_burst_last_queue_head_demux
  generated_groups=2
  same_id_ordering.residue=[per_id_issue_order_queues]
  response_demux.residue=[read_data_interleaving, bursts]
  admitted guard_source=counted_request_set_capacity_fit
  request_assertion_scope=concrete_id_group

ppif/axi_manager_capacity_status_write_multi_group_same_id_queue_head_response_demux.ppif
  same_id_ordering.generated_behavior=1
  implementation_status=generated_write_bid_queue_head_demux
  generated_groups=2
  same_id_ordering.residue=[per_id_issue_order_queues]
  response_demux.residue=[read_response_demux, read_data_interleaving, bursts]
  admitted guard_source=counted_request_set_capacity_fit
  request_assertion_scope=concrete_id_group

ppif/axi_manager_capacity_status_read_single_beat_multi_group_same_id_queue_head_response_demux.ppif
  same_id_ordering.generated_behavior=1
  implementation_status=generated_read_single_beat_queue_head_demux
  generated_groups=2
  same_id_ordering.residue=[per_id_issue_order_queues]
  response_demux.residue=[read_data_interleaving, bursts]
  admitted guard_source=counted_request_set_capacity_fit
  request_assertion_scope=concrete_id_group
```

The live unsupported-residue detail already distinguishes the supported
bounded concrete queue-head surface from the remaining dynamic boundary:

```text
dynamic user-ID arbitration beyond selected counted concrete-ID queue-head groups
```

No stale support/detail cleanup is required before the next owner.

## Readiness Findings

The shipped concrete queue-head representation is finite by construction:

- queue grouping key is response family plus concrete ID value;
- queue depth is statically bounded by selected transaction inventory and
  family max-pending;
- storage names include concrete ID values and transaction names;
- queue-head response demux checks the raw response event, concrete response
  ID, and a static queue-head transaction bit;
- counted multi-group request admission now shares the same request-set fit
  guard as the capacity/status matrix.

Dynamic/user ID arbitration would need a different public contract. At
minimum, it must define how a transaction binds to a runtime request-ID
source, how that source is captured at admitted request time, whether the ID
is user-authored or generated, what outstanding state is stored per admitted
transaction, what response ID matching means, and how same-ID response order
is preserved when the ID value is not known at compile time.

The lower IAL1/IAL0/SystemVerilog path is not the first blocker. Existing
generated behavior already uses scalar storage, guarded rules, pulses,
assertions, comparisons, one-hot slot state, and generated response-demux
signals. The missing durable boundary is public contract and report shape for
dynamic/user transaction IDs and the arbitration policy that follows from it.

## Candidate Comparison

A direct generated per-ID queue implementation is not selected. It would need
to introduce dynamic ID capture, per-admission outstanding identity state,
response matching against stored IDs, same-ID ordering guarantees, overflow
and ambiguity assertions, report/residue movement, support accounting, and
public examples in one slice.

A scoreboard implementation is not selected. `scoreboard` is still an
unsupported policy value, and a scoreboard policy would still need the same
dynamic transaction-ID source contract before generated behavior could be
reviewed.

A fail-closed diagnostic/report cleanup is not selected. The current parser
already rejects unsupported transaction ID forms, the support detail already
names dynamic user-ID arbitration as unsupported, and live reports keep
`per_id_issue_order_queues` residue where bounded concrete queue-head behavior
is otherwise generated.

A lower-layer prerequisite is not selected. No evidence shows a missing
IAL1/IAL0/SystemVerilog primitive as the immediate blocker; the missing piece
is the source/report contract.

## Selected `.217` Boundary

`.217` should select the public dynamic/user transaction-ID contract before
any parser or generator behavior changes. It should decide:

- whether the first dynamic ID source spelling belongs under
  `(transactions ... (id ...))`, `id-families`, `same-id-ordering`, or a new
  AXI-profile-local clause;
- how to distinguish `auto`, concrete constant IDs, user-supplied dynamic
  IDs, and generated allocator-owned IDs in normalized reports;
- whether dynamic/user IDs can initially be report-only and fail-closed, or
  whether the first accepted spelling must also carry a selected arbitration
  policy;
- whether the first dynamic same-ID policy is issue-order queue,
  scoreboard, explicit reject, or selected-not-generated metadata;
- what diagnostics prevent users from assuming generated behavior before
  request-ID capture, outstanding tracking, response matching, and ordering
  checks exist;
- how support accounting, strict check JSON, semantic JSON, HDL generation,
  mdBook examples, and Knowledge Map facts would validate any later behavior
  owner.

## Preservation Matrix

`.217` must preserve:

- counted request-set capacity-fit guards and concrete-ID group request
  assertions from `.214`;
- counted capacity/status and over-capacity semantics from `.211`;
- generated concrete queue-head response-demux, read-data, burst-length,
  runtime-validation, multi-beat output-bank, scalar aggregation, and mixed
  auto-ID plus concrete queue-head behavior for selected public samples;
- existing PPIF `auto` and `(value N)` transaction ID semantics;
- existing fail-closed diagnostics for unsupported transaction ID forms and
  unsupported same-ID policy values;
- support-accounting identities, strict check JSON, semantic JSON, and HDL
  generation for public samples;
- direct backend deferral, verification-output deferral, VHDL deferral, and
  backend-language neutrality.

## Non-Goals

- Do not implement dynamic ID capture, generalized per-ID queues, or
  scoreboards in `.216` or `.217`.
- Do not add parser behavior, public PPIF samples, support-accounting entries,
  tests, generated artifacts, validation behavior, or HDL behavior in `.216`.
- Do not broaden concrete queue depth or queue-head read/write coverage in
  `.216`.
- Do not add packed burst-vector outputs or alternate full burst payload
  assembly.
- Do not change direct backend, verification-output generation, VHDL, or
  backend-language variants.

## Validation Gates

For `.216`, documentation and continuity gates are sufficient:

```bash
env -u PERL5LIB ./bin/fsmgen --emit-schedule-json ppif/axi_manager_capacity_status_same_id_issue_order_queue_policy.ppif
env -u PERL5LIB ./bin/fsmgen --emit-schedule-json ppif/axi_manager_capacity_status_read_multi_group_same_id_queue_head_response_demux.ppif
env -u PERL5LIB ./bin/fsmgen --emit-schedule-json ppif/axi_manager_capacity_status_write_multi_group_same_id_queue_head_response_demux.ppif
env -u PERL5LIB ./bin/fsmgen --emit-schedule-json ppif/axi_manager_capacity_status_read_single_beat_multi_group_same_id_queue_head_response_demux.ppif
bash knowledge-map/scripts/gen_knowledge_map.sh
mdbook build docs/book
env -u PERL5LIB prove -Iperl t/1414-docs-relative-paths-audit.t
bash knowledge-map/scripts/check_knowledge_map.sh
scripts/check_memory_architecture.sh
git --no-pager diff --check
```

Any broad `prove`, supported-corpus, semantic JSON, or `--verify-hdl` gate
remains RAM-guarded and should be selected only by a behavior owner.

## Rollback Boundary

Rollback for `.216` is limited to this audit record, task-tree frontier
movement, Memory, README, roadmap, mdBook, and Knowledge Map/fact-card
updates. No parser, generator, public sample, support-accounting catalog,
generated artifact, test, validation, or HDL behavior is part of this slice.
