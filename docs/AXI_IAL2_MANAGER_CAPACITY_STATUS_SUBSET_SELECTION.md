# AXI IAL2 Manager Capacity/Status Subset Selection

Status: first post-Valid-Ready AXI manager subset selected; no behavior
implemented by this note.

Task tree:
[docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md](tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md).

Inputs:

- [docs/AXI_MANAGER_RULE_MATRIX_DESIGN_PROBE.md](AXI_MANAGER_RULE_MATRIX_DESIGN_PROBE.md)
- [docs/AXI_MANAGER_USER_API_BRAINSTORM.md](AXI_MANAGER_USER_API_BRAINSTORM.md)
- [docs/AXI_ID_ORDERING_RULE_EVIDENCE_PROBE.md](AXI_ID_ORDERING_RULE_EVIDENCE_PROBE.md)
- [docs/AXI_IAL2_FIRST_IMPLEMENTATION_SUBSET_SELECTION.md](AXI_IAL2_FIRST_IMPLEMENTATION_SUBSET_SELECTION.md)
- [docs/AXI_IAL2_VALID_READY_GENERATOR_FIRST_SLICE.md](AXI_IAL2_VALID_READY_GENERATOR_FIRST_SLICE.md)

## Purpose

This note selects the first AXI manager rule subset after the shipped
Valid-Ready IAL2 single/bundle surfaces.

It does not implement syntax, parser behavior, generated `.isf`, generated
`.fsm`, HDL, tests, or public CLI behavior. The next task-tree leaf is a
readiness audit that must map the exact code/test/report owners before any
manager behavior changes.

## Selected Subset

The selected first manager subset is outstanding transaction capacity plus
acceptance/status feedback.

The source anchors are:

- `A1.1`
- `A1.2`
- `A5.1`

This subset owns:

- explicit read and write pending-capacity configuration,
- acceptance feedback for read and write submissions,
- read/write full status,
- read/write pending counters,
- read/write available-slot status,
- a capacity-only blocked-reason vocabulary,
- report metadata tying those rules back to the source anchors,
- and explicit residue for all unowned AXI manager families.

The first behavior-bearing implementation should support a bounded `try`
submission policy first: a submit event returns or exposes accepted/full
status immediately. `blocking` and `queued` remain future policy owners unless
the readiness audit proves they can be implemented without widening the slice.

## Why This Subset First

Outstanding capacity is the dependency underneath the rest of the manager.
ID allocation, same-ID ordering, different-ID interleaving, response matching,
write-data sequencing, and read-data collection all need a defined admission
model and a way to report when the manager cannot accept more work.

This selection also preserves the Easy-mode requirement: Easy mode must not
silently degrade into one transaction at a time. A configuration with more
than one read or write slot must be representable. A configuration with one
slot may serialize because the user explicitly selected one slot.

The selected subset is still not the full AXI manager. It should model the
manager's admission/status shell over abstract read/write submit and
completion events before it claims actual AXI channel expansion, ID ownership,
or response matching.

## Authored Surface Expectations

The eventual public `.ppif` shape should stay protocol/profile generic and
should lower through reviewable `.isf` before `.fsm`.

The selected semantic shape is equivalent to:

```text
(protocol-platform-intent axi_manager_capacity_status
  (profile axi4)
  (source
    (object axi-manager-capacity-status)
    (anchor (document IHI0022_L_2025-08) (section A1.1))
    (anchor (document IHI0022_L_2025-08) (section A1.2))
    (anchor (document IHI0022_L_2025-08) (section A5.1)))
  (axi-manager axi0
    (clock clk)
    (reset (rst_n active_low async))
    (read-window  (max-pending 4))
    (write-window (max-pending 2))
    (submit-policy try)
    (status
      (read-can-accept axi0_read_can_accept)
      (write-can-accept axi0_write_can_accept)
      (read-full axi0_read_full)
      (write-full axi0_write_full)
      (pending-reads axi0_pending_reads)
      (pending-writes axi0_pending_writes)
      (read-slots-available axi0_read_slots_available)
      (write-slots-available axi0_write_slots_available)
      (read-blocked-reason axi0_read_blocked_reason)
      (write-blocked-reason axi0_write_blocked_reason))))
```

This spelling is a pre-code expectation, not shipped syntax. The readiness
audit must decide the exact parser shape and whether the first implementation
starts as an in-process generator or public `.ppif` object.

No default pending depth is selected here. A future implementation must reject
ambiguous defaults rather than claiming concurrency accidentally.

Generated status names must be namespaced. The first implementation must not
emit a bare `can_accept` storage or output name that collides with the current
IAL1 scheduler's generated transaction acceptance signal.

## Generated IAL1 Artifact Shape

The generated IAL1 `.isf` review artifact should expose a manager-capacity
shell before IAL0 generation. It should show:

- clock and reset binding,
- abstract read-submit and write-submit events,
- abstract read-complete and write-complete events,
- generated read/write pending counters,
- capacity comparisons against configured read/write depths,
- namespaced status outputs for can-accept/full/pending/available-slots,
- optional capacity-only blocked-reason outputs or report-only metadata,
- assertions or diagnostics for overflow/underflow behavior if selected,
- and a report block or generated metadata that maps the rules back to the
  source anchors.

The abstract completion events are only capacity-shell hooks in this subset.
They do not claim `BID`/`RID` matching, burst completion, read-data
collection, or write-response policy.

The generated `.isf` must remain IAL1. New IAL2 source forms must not be added
to `.isf` by accident.

## Generated IAL0 And HDL Expectations

The generated IAL0 `.fsm` review artifact should make the capacity/status
logic cycle-explicit. It should contain:

- read/write pending counter storage,
- increment points for accepted abstract submit events,
- decrement points for abstract completion events,
- combinational status outputs or explicit state/output assignments for
  can-accept, full, pending, and available slots,
- capacity-only blocked-reason encoding if the implementation selects an HDL
  output for that status,
- no AXI channel choreography beyond the already shipped Valid-Ready
  substrate,
- no transaction ID allocation or validation,
- no response matching,
- and no ordering or interleaving queues.

The SystemVerilog HDL path should be generated from that `.fsm` review
artifact. The first implementation must continue to emit the `.isf` and `.fsm`
review artifacts before HDL.

## Required Readiness Audit

The next task-tree leaf must inspect whether current code can express this
subset without unsafe widening. It must read:

- `.ppif` parser and CLI entry surfaces,
- the existing IAL2 Valid-Ready generator and report surface,
- IAL1 parser/lowerer/report emitters,
- IAL0 `.fsm` emission and SystemVerilog output behavior,
- public contract/capability metadata,
- and focused tests around PPIF, generated review artifacts, scheduler
  reports, semantic JSON, and HDL verification.

The audit must decide whether existing IAL1 can represent generated counters,
numeric/vector status outputs, capacity comparisons, and namespaced generated
signals. If not, the missing IAL1 or IAL0/SystemVerilog support becomes an
explicit prerequisite leaf before the manager behavior leaf.

## Diagnostics And Report Contract

A future implementation must fail closed for at least:

- missing clock or reset binding,
- missing read and write capacity configuration when the object claims both
  directions,
- non-positive pending depth,
- duplicate status signal names,
- status names colliding with generated scheduler names,
- unsupported `blocking` or `queued` policy if the first implementation owns
  only `try`,
- attempts to claim ID/order/response behavior in the capacity/status subset,
- and direct IAL2-to-IAL0 lowering.

The IAL2 report should expose:

- `rule_subset`: `axi_manager_capacity_status`,
- source anchors,
- read/write maximum pending depth,
- selected submit policy,
- generated status bindings,
- generated IAL1 artifact name or text reference,
- generated IAL0 artifact names,
- static rule classifications,
- scheduler rule classifications,
- diagnostics or block-reason vocabulary,
- and explicit residue.

The capacity-only blocked-reason vocabulary for this subset is:

- `none`
- `max_pending_reached`
- `unsupported_transaction_kind`

`id_busy`, `unique_id_required`, `same_id_required`,
`ordering_wait_required`, and `read_interleaving_disabled` remain visible as
future manager vocabulary, not implemented capacity/status behavior.

## Focused Validation Expected Later

The first implementation leaf selected after the readiness audit should add
focused coverage for:

- `max-pending` values of one and more than one,
- accepted submit increments pending count,
- full status blocks acceptance at configured depth,
- completion decrements pending count,
- available slots match `max-pending - pending`,
- namespaced status outputs avoid `can_accept` collisions,
- unsupported policies fail closed,
- generated `.isf` exists before generated `.fsm`,
- generated `.fsm` is used before SystemVerilog HDL,
- source anchors and residue appear in schedule/report JSON,
- semantic JSON/check JSON preserve public `.ppif` source identity if the
  first implementation is public `.ppif`,
- and `--verify-hdl` passes for the selected SystemVerilog fixture if HDL is
  emitted.

## Explicit Residue

This subset deliberately excludes:

- ID width and ID presence policy,
- ID allocation,
- user-specified ID validation,
- same-ID ordering queues,
- different-ID concurrency/interleaving policy,
- ordering-required gaps,
- write-response matching through `BID`,
- read-data matching through `RID`,
- burst length/size/last-beat assembly,
- write-data sequencing across multiple transactions,
- subordinate capability assumptions,
- read-data reordering depth,
- interconnect ID remapping,
- transaction-class constraints beyond reporting unsupported transaction
  kinds,
- full Easy/Power/supervised Raw mode APIs,
- `blocking` and `queued` submission policy behavior unless a later owner
  selects them,
- public `.axi` or other profile suffix aliases,
- and VHDL backend or VHDL rerouting behavior.

## Rollback Boundary

The rollback boundary for this selector is documentation-only: revert this
note, the task-tree frontier update, README/roadmap/mdBook sync, Memory
pointer update, and Knowledge Map fact/map changes.

No parser, generator, IAL1, IAL0, HDL, test, or CLI behavior is changed by
this selector.

## Current Conclusion

The first post-Valid-Ready AXI manager subset is the capacity/status shell:
configured read/write pending windows plus acceptance, full, pending, slots,
and capacity-only blocked-reason feedback.

The next safe action is a readiness audit before implementation. That audit
must decide the exact implementation boundary and any IAL1 or
IAL0/SystemVerilog prerequisites needed to keep the mandatory
`IAL2 -> IAL1 -> IAL0 -> SystemVerilog` chain reviewable.
