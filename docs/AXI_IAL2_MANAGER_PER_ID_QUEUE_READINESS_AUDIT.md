# AXI IAL2 Manager Per-ID Issue-Order Queue Readiness Audit

Owner: `IAL2-FEATURE-COMPLETENESS-FRONTIER.90`

Date: 2026-06-14

## Purpose

This audit decides the next AXI manager feature-completeness boundary after
`.88` made unsupported same-family concrete-ID reuse fail closed and `.89`
selected the per-ID issue-order queue readiness audit.

It is documentation and task-tree state only. It does not change parser,
generator, `.isf`, `.fsm`, SystemVerilog, sample, support-accounting, check
JSON, semantic JSON, or validation behavior.

## Inputs Read

- `docs/AXI_IAL2_MANAGER_POST_CONCRETE_ID_STATIC_VALIDATION_NEXT_SLICE_SELECTION.md`
- `docs/AXI_IAL2_MANAGER_CONCRETE_ID_SAME_ID_STATIC_VALIDATION_FIRST_SLICE.md`
- `docs/AXI_IAL2_MANAGER_CONCRETE_ID_SAME_ID_ORDERING_READINESS_AUDIT.md`
- `docs/AXI_IAL2_MANAGER_SAME_ID_ORDERING_FIRST_SLICE.md`
- `docs/AXI_MANAGER_RULE_MATRIX_DESIGN_PROBE.md`
- `docs/AXI_ID_ORDERING_RULE_EVIDENCE_PROBE.md`
- capacity/status and auto-ID lifecycle readiness notes
- live schedule JSON for:
  - `ppif/axi_manager_capacity_status_read_data_multi_beat.ppif`
  - `ppif/axi_manager_capacity_status_transaction_envelope.ppif`
  - `ppif/axi_manager_capacity_status_transaction_event_dispatch.ppif`
  - `ppif/axi_manager_capacity_status_response_demux.ppif`
- implementation surfaces:
  - `perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm`
  - `perl/FSM/Adapter/IAL2/PPIF.pm`
  - `perl/FSM/Scheduler/ISF/LoweringIR.pm`
  - `perl/FSM/Scheduler/ISF/Emitter/FSM.pm`
  - `perl/FSM/Scheduler/ISF/Emitter/JSON.pm`
- focused generator and PPIF/CLI tests
- task tree, roadmap, mdBook, Memory, and Knowledge Map fact cards

## Live State

The public generated auto-ID multi-beat sample still reports the remaining
same-ID residue precisely:

```text
read_data.residue: []
response_demux.residue: []
same_id_ordering.residue:
  - concrete_id_same_id_ordering
  - per_id_issue_order_queues
```

Concrete-ID samples still use assertion-only request/response ID equality and
keep `same_id_ordering` under the ID-response rule engine:

```text
id_response_rule_engine.mode: concrete_id_assertions
id_response_rule_engine.residue:
  - auto_id_allocation
  - id_release
  - same_id_ordering
  - response_demux
```

The generated auto-ID response-demux sample proves the existing generated
auto-ID path is different: same-ID ordering is handled by avoiding same-ID
concurrency through allocator free-ID guards and runtime assertions. That is
not accepted same-ID reuse.

## Readiness Findings

AXI evidence says same-ID read responses and same-ID write responses must
return in request issue order within their response families. When two
authored concrete-ID transactions share one `RID` or `BID` value, response
matching by ID alone cannot identify which authored transaction completed
first. A generated behavior slice would therefore need explicit issue-order
state, a per-ID queue or scoreboard, and a selected response-demux rule that
uses the queue head rather than only `RID == constant` or `BID == constant`.

The current public `.ppif` manager-capacity surface does not express that
policy. The parser accepts `id-families`, `transactions`, `auto-id-lifecycle`,
`response-demux`, and `read-data`; there is no same-ID reuse or per-ID queue
clause. The current fail-closed diagnostic intentionally says concrete
same-ID reuse requires a selected same-ID ordering policy or per-ID
issue-order queue.

The lower layers are not the immediate blocker. Existing IAL1/IAL0/SV
substrate can carry scalar generated storage, guarded rules, pulses,
assertions, and bank access metadata. Earlier capacity/status readiness also
proved FIFO-like occupancy/pointer same-cycle update substrate. A bounded
queue could be built from explicit generated scalar or bank state in a later
implementation. What is missing first is the public contract that defines
whether same-ID reuse is rejected, queued, stalled, blocked, accepted with a
scoreboard, or still deferred.

The schedule-report residue is not stale. It correctly says accepted
concrete-ID same-ID ordering behavior and per-ID issue-order queues are still
unimplemented.

## Selection

Select `IAL2-FEATURE-COMPLETENESS-FRONTIER.91`:

```text
Select AXI same-ID reuse policy contract before per-ID queues.
```

The next leaf should choose the public contract and report vocabulary before
parser/report metadata or generated queue behavior. It should decide:

- the additive source spelling for same-ID reuse policy;
- whether the first public policy is explicit `reject` only, or whether it
  also names deferred `issue-order-queue` / `scoreboard` modes;
- the default behavior for omitted policy, preserving today's fail-closed
  concrete-ID same-ID reuse diagnostic;
- how the policy is reported under `same_id_ordering` and
  `id_response_rule_engine`;
- which policy values fail closed until queue/scoreboard behavior is selected;
- how this remains AXI-profile-local until another profile proves compatible
  reuse semantics.

## Why Not Implement Queues Next

Direct queue behavior would define user-visible scheduling and completion
semantics without public syntax. It would also have to change generated IAL1
storage, generated `.fsm` rules, response-demux ownership, diagnostics, and
report contracts in one step. That is too broad and would hide a policy
choice behind generated behavior.

## Why Not Do Response-Demux First

Concrete-ID response demux without issue-order state cannot disambiguate two
same-ID transactions. It would still match the same `RID` or `BID` for both
transactions. The demux rule must be selected together with, or after, the
issue-order policy and queue/scoreboard state.

## Why Not Do Report-Only Alignment First

The current residue is already honest. A report-only slice would not remove
any stale claim. The next useful narrowing is selecting the public policy
contract that controls later parser/report and behavior work.

## Validation For This Audit

Audit gates:

```bash
./bin/fsmgen --emit-schedule-json ppif/axi_manager_capacity_status_read_data_multi_beat.ppif
./bin/fsmgen --emit-schedule-json ppif/axi_manager_capacity_status_transaction_envelope.ppif
./bin/fsmgen --emit-schedule-json ppif/axi_manager_capacity_status_transaction_event_dispatch.ppif
./bin/fsmgen --emit-schedule-json ppif/axi_manager_capacity_status_response_demux.ppif
bash knowledge-map/scripts/gen_knowledge_map.sh
mdbook build docs/book
prove -Iperl t/1414-docs-relative-paths-audit.t
bash knowledge-map/scripts/check_knowledge_map.sh
scripts/check_memory_architecture.sh
git --no-pager diff --check
```

## Rollback Boundary

This audit changes no behavior. If `.91` cannot select a small public policy
contract, it must choose a smaller syntax/readiness prerequisite before any
parser or generator behavior changes.
