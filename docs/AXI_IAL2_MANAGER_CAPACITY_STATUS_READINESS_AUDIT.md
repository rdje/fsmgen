# AXI IAL2 Manager Capacity/Status Readiness Audit

Status: readiness audited; no parser, generator, IAL1, IAL0, HDL, CLI, or
test behavior implemented by this note.

Task tree:
[docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md](tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md).

Inputs:

- [docs/AXI_IAL2_MANAGER_CAPACITY_STATUS_SUBSET_SELECTION.md](AXI_IAL2_MANAGER_CAPACITY_STATUS_SUBSET_SELECTION.md)
- [docs/AXI_MANAGER_RULE_MATRIX_DESIGN_PROBE.md](AXI_MANAGER_RULE_MATRIX_DESIGN_PROBE.md)
- [docs/AXI_MANAGER_USER_API_BRAINSTORM.md](AXI_MANAGER_USER_API_BRAINSTORM.md)
- [docs/AXI_IAL2_VALID_READY_READINESS_AUDIT.md](AXI_IAL2_VALID_READY_READINESS_AUDIT.md)
- [docs/AXI_IAL2_VALID_READY_GENERATOR_FIRST_SLICE.md](AXI_IAL2_VALID_READY_GENERATOR_FIRST_SLICE.md)
- [docs/IAL2_PPIF_PARSER_CLI_FIRST_SLICE.md](IAL2_PPIF_PARSER_CLI_FIRST_SLICE.md)
- [docs/IAL2_PPIF_VALID_READY_BUNDLE_FIRST_SLICE.md](IAL2_PPIF_VALID_READY_BUNDLE_FIRST_SLICE.md)
- [docs/IAL2_PPIF_BUNDLE_HDL_ENTRY_FIRST_SLICE.md](IAL2_PPIF_BUNDLE_HDL_ENTRY_FIRST_SLICE.md)
- `perl/FSM/Adapter/IAL2/PPIF.pm`
- `perl/FSM/IAL2/ProtocolIntent/ValidReadyChannel.pm`
- `bin/fsmgen`
- `perl/FSM/Adapter/ISF/Parser.pm`
- `perl/FSM/Scheduler/ISF/LoweringIR.pm`
- `perl/FSM/Scheduler/ISF/Emitter/FSM.pm`
- `perl/FSM/Scheduler/ISF/Emitter/JSON.pm`
- `perl/FSM/Support/RegressionCorpus.pm`
- `perl/FSM/Support/LanguageSurfaceSection.pm`
- `t/1232-isf-actor-storage-declarations.t`
- `t/1235-isf-fifo-same-cycle-update-matrix.t`
- `t/1435-axi-ial2-valid-ready-generator.t`
- `t/1436-ial2-ppif-parser-cli.t`
- `docs/book/src/13a-actor-interface.md`
- `docs/book/src/13k-isf-feature-support-matrix.md`
- `docs/book/src/14-feature-backlog.md`
- `docs/ISF_SPEC.md`

## Purpose

This audit checks whether the selected AXI manager outstanding-capacity and
acceptance/status subset can be implemented as the next IAL2 behavior slice
without first widening IAL1 or IAL0/SystemVerilog.

It also chooses the safest first implementation boundary before any behavior
changes.

## Current PPIF Surface Findings

The public `.ppif` parser is still shaped around Valid-Ready objects. It
accepts a single `protocol-platform-intent` root plus `profile`, `source`, and
one or more `valid-ready-channel` clauses. Unsupported top-level clauses fail
closed, and duplicate Valid-Ready object names fail closed.

The multi-object path is specific to Valid-Ready bundles. It builds an
aggregate Valid-Ready bundle report, per-channel generated `.isf` and `.fsm`
review artifacts, and a bundle wrapper/top `.fsm` for the tracked aggregate HDL
entry.

`bin/fsmgen` has two `.ppif` execution shapes today:

- a Valid-Ready bundle branch keyed by `protocol_intent.valid_ready_bundle`,
  with aggregate semantic JSON and aggregate wrapper/top HDL behavior,
- and a single-object branch that assumes a Valid-Ready-like result containing
  `generated_ial1`, `generated_ial0`, a generated IAL1 schedule report, and an
  IAL2 report.

A future public `.ppif` capacity/status object can fit the single-object result
shape, but making it public immediately would widen parser grammar, CLI
diagnostics, support accounting, manifest language-surface metadata, semantic
JSON/check JSON expectations, samples, and mdBook examples in the same slice as
the new manager behavior.

That is a larger blast radius than needed for the first capacity/status proof.

## Existing IAL2 Generator Pattern

`FSM::IAL2::ProtocolIntent::ValidReadyChannel` is the right implementation
pattern for the first capacity/status behavior slice:

- validate an in-process contract hash,
- emit reviewable generated `.isf`,
- parse through `FSM::Adapter::ISF`,
- lower through `FSM::Scheduler::ISF`,
- return generated `.fsm` artifacts,
- and publish an IAL2 report with source anchors, generated artifacts,
  enforced static rules, generated scheduler/assertion behavior, assumptions,
  and explicit residue.

It does not lower directly to `.fsm`. Its report records
`direct_ial2_to_ial0: 0`, which preserves the required
`IAL2 -> IAL1 -> IAL0` chain.

The capacity/status generator should follow that shape first, before becoming
public `.ppif` syntax.

## IAL1 And IAL0 Substrate Findings

Existing IAL1 can represent the selected first capacity/status shell.

Actor-owned scalar storage supports generated counters with positive integer
widths. The parser rejects storage names that collide with interface ports,
clock/reset, crossings, or the scheduler-generated `can_accept` signal. The
lowerer projects declared actor storage into the internal lowering IR, emits
declared storage into scheduled `.fsm +size`, and reports it as
`role: actor_storage`. Used actor storage reaches SystemVerilog through the
normal scalar assignment path.

The current scheduler also creates an implicit `can_accept` signal for
transaction acceptance, so generated user-facing status names must be
namespaced, for example `axi0_read_can_accept`, rather than reusing bare
`can_accept`.

The FIFO same-cycle update matrix fixture proves the needed substrate for this
manager shell:

- actor-owned `occupancy`, `wr_ptr`, and `rd_ptr` storage,
- `full` and `empty` status outputs derived from occupancy,
- push-only, pop-only, idle, and push+pop cases,
- full-depth preservation when push and pop are simultaneous,
- schedule-report actor-storage metadata,
- scheduled `.fsm` review artifacts,
- and SystemVerilog generation.

The capacity/status shell can use the same kind of explicit update matrix for
read and write pending counters. No new IAL1 parser feature and no new IAL0 or
SystemVerilog backend feature is required for the first in-process slice, as
long as the slice stays inside abstract submit/complete events, counters, and
status outputs.

## Public Contract Findings

The shipped support-accounting corpus currently has two `.ppif` entries:

- `intent.ppif_axi_aw_valid_ready`
- `intent.ppif_axi_aw_w_valid_ready_bundle`

The language-surface manifest advertises `.ppif` as a shipped first slice for
Valid-Ready single/bundle behavior. It does not yet advertise an AXI manager
capacity/status object.

Therefore the first capacity/status behavior slice should not update public
`.ppif` samples or manifest metadata. Those become an exact later leaf after
the in-process generator proves the generated `.isf`, `.fsm`, report, and
SystemVerilog behavior.

## Readiness Conclusion

There is no implementation blocker for the first in-process AXI manager
capacity/status generator.

Existing IAL1 plus IAL0/SystemVerilog can carry:

- configured read/write pending counters,
- capacity comparisons,
- `try`-style acceptance status,
- full status,
- pending count status,
- available-slot status,
- namespaced generated outputs,
- and same-cycle submit+complete counter behavior.

The safe first implementation boundary is an in-process generator, not public
`.ppif` syntax. Public parser/CLI support remains a later exact owner after the
capacity/status shell is proven.

## Selected First Implementation Boundary

The next implementation leaf should add an in-process generator, tentatively:

```perl
FSM::IAL2::ProtocolIntent::AxiManagerCapacityStatus
```

The exact module name can still be finalized by the implementation leaf, but
the behavior boundary is fixed by this audit.

The generator should accept a structured contract hash, not a raw source line
string and not public `.ppif` syntax. Required fields should include:

- manager name,
- protocol/profile, initially `axi4`,
- clock and reset,
- explicit `read_max_pending`,
- explicit `write_max_pending`,
- `submit_policy => try`,
- abstract read/write submit event names,
- abstract read/write completion event names,
- optional namespaced status output names,
- and source object/anchor metadata for `A1.1`, `A1.2`, and `A5.1`.

No default pending depth is selected. A missing or non-positive depth must fail
closed.

## Generated IAL1 Artifact Boundary

The generated `.isf` should expose one manager-capacity actor with:

- inputs for abstract read/write submit events,
- inputs for abstract read/write completion events,
- outputs for `read_can_accept` and `write_can_accept` using namespaced signal
  names,
- outputs for read/write full status,
- outputs for read/write pending counts,
- outputs for read/write available-slot counts,
- actor storage for read/write pending counters,
- explicit update logic for submit-only, complete-only, submit+complete, and
  idle cases per direction,
- and no IAL2 source forms embedded into `.isf`.

The generated `.isf` should be parseable by the existing IAL1 parser and
lowerable by the existing scheduler without private shortcuts.

Capacity-only blocked reasons should be report metadata in the first
implementation. HDL blocked-reason outputs can be selected by a later exact
leaf after the counter/status shell is proven.

## Generated IAL0 And HDL Boundary

The generated `.fsm` should show:

- read/write pending counter storage in `+size`,
- increment/decrement/hold behavior in explicit states or rules,
- status output assignments,
- no bare generated storage or output named `can_accept`,
- no AXI channel choreography beyond abstract event pins,
- no ID allocation,
- no response matching,
- no burst/last-beat tracking,
- and no VHDL backend behavior.

SystemVerilog should be generated from the scheduled `.fsm` review artifact.

## Report Schema Boundary

The generator should publish:

```text
fsmgen.ial2.protocol_intent.axi_manager_capacity_status.v1
```

The report should include:

- `mode`,
- `layering`,
- `source_object`,
- `manager`,
- `capacity`,
- `status_outputs`,
- `abstract_events`,
- `submit_policy`,
- `generated_artifacts`,
- generated scheduler/status rule summaries,
- capacity-only blocked-reason vocabulary,
- `assumptions`,
- `enforced_static_rules`,
- and `unsupported_residue`.

The blocked-reason vocabulary for the first in-process slice is report-only:

- `none`
- `max_pending_reached`
- `unsupported_transaction_kind`

ID/order reasons remain future residue.

## Fail-Closed Boundary

The implementation leaf should reject:

- missing or unsupported protocol/profile,
- missing clock or reset,
- non-positive read/write max-pending depths,
- missing depths when read or write direction is claimed,
- duplicate generated status names,
- status/storage/event names that collide with `can_accept`, clock, reset, or
  each other,
- unsupported `blocking` or `queued` submit policies,
- requested IDs, ordering, response matching, burst tracking, or channel
  expansion,
- public `.ppif` syntax for this object,
- and any direct IAL2-to-IAL0 lowering path.

## Focused Test Boundary

The next implementation leaf should add a focused generator test, likely:

```text
t/1437-axi-ial2-manager-capacity-status-generator.t
```

The test should verify:

- report schema and source anchors,
- `direct_ial2_to_ial0` remains false in the layering metadata,
- generated `.isf` text exists before generated `.fsm` artifacts,
- generated `.isf` parses through `FSM::Adapter::ISF`,
- generated `.isf` lowers through `FSM::Scheduler::ISF`,
- generated `.fsm` contains read/write pending counter storage,
- generated status outputs are namespaced and avoid bare `can_accept`,
- `max_pending = 1` and `max_pending > 1` cases,
- accepted submit increments pending,
- completion decrements pending,
- full status blocks new acceptance at depth,
- available slots equal max minus pending,
- same-cycle submit+complete preserves count when both are legal,
- unsupported policies fail closed,
- unsupported ID/order/response/burst options fail closed,
- and generated SystemVerilog includes the counter/status surface.

The first test does not need public `.ppif` source identity checks because the
first behavior slice is in-process only.

## mdBook And Public Docs Boundary

The implementation leaf must update the mdBook in the same slice because the
in-process API is user-visible behavior. The book should document:

- that the first capacity/status shell is in-process only,
- the structured contract hash,
- the generated `.isf` and `.fsm` review-artifact path,
- SystemVerilog-only backend status,
- `try` policy,
- explicit depth requirements,
- status outputs,
- and residue for IDs, ordering, response matching, bursts, public `.ppif`,
  profile aliases, and VHDL.

Public `.ppif` syntax examples must not be documented as shipped until the
parser/CLI leaf exists.

## Explicit Residue

Still out of scope after the first implementation leaf:

- public `.ppif` capacity/status syntax,
- `.axi` or other profile suffix aliases,
- public samples and support-accounting entries for capacity/status `.ppif`,
- capacity/status semantic JSON and check JSON public source-identity coverage,
- HDL blocked-reason output encoding,
- `blocking` submission policy,
- `queued` submission policy,
- ID allocation,
- user ID validation,
- same-ID ordering,
- different-ID interleaving,
- response matching through `BID`/`RID`,
- burst length/size/last-beat tracking,
- write-data sequencing,
- channel expansion,
- full Easy/Power/supervised Raw APIs,
- platform placement/resource mapping,
- and VHDL backend/reroute behavior.

## Rollback Boundary

This audit is documentation-only. Rollback is limited to this note, the
task-tree frontier update, README/roadmap/mdBook synchronization, the Knowledge
Map card/map updates, and the layer-A `MEMORY.md` pointer update.

No runtime behavior is changed by this audit.

## Current Conclusion

Proceed with an in-process AXI manager capacity/status generator as the next
owned implementation leaf. Use existing IAL1 storage/status/rule machinery and
the existing IAL0/SystemVerilog path. Keep public `.ppif` capacity/status
syntax behind a later exact owner.
