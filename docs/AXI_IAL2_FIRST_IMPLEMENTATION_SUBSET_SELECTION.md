# AXI IAL2 First Implementation Subset Selection

Status: first implementation subset selected; first in-process generator slice
shipped in
[docs/AXI_IAL2_VALID_READY_GENERATOR_FIRST_SLICE.md](AXI_IAL2_VALID_READY_GENERATOR_FIRST_SLICE.md).

Task tree:
[docs/tasks/AXI-IAL2-FIRST-IMPLEMENTATION-SUBSET-SELECTION.md](tasks/AXI-IAL2-FIRST-IMPLEMENTATION-SUBSET-SELECTION.md).

Inputs:

- [docs/IAL2_PROTOCOL_PLATFORM_INTENT_EVALUATION.md](IAL2_PROTOCOL_PLATFORM_INTENT_EVALUATION.md)
- [docs/AXI_VALID_READY_INTENT_PROBE.md](AXI_VALID_READY_INTENT_PROBE.md)
- [docs/AXI_MANAGER_USER_API_BRAINSTORM.md](AXI_MANAGER_USER_API_BRAINSTORM.md)
- [docs/AXI_ID_ORDERING_RULE_EVIDENCE_PROBE.md](AXI_ID_ORDERING_RULE_EVIDENCE_PROBE.md)
- [docs/AXI_MANAGER_RULE_MATRIX_DESIGN_PROBE.md](AXI_MANAGER_RULE_MATRIX_DESIGN_PROBE.md)

## Purpose

This note selects the first safe AXI-derived IAL2 implementation subset and
defined the pre-code contract for the first implementation leaf.

This selection note itself did not implement behavior. The follow-on first
slice implements an in-process generator while public syntax spelling, parser
internals, CLI behavior, and full AXI manager behavior remain later work.

## Selected First Subset

The first implementation subset should be an AXI Valid-Ready channel contract
object with generated monitor/report behavior.

This is intentionally not the full AXI manager. It is the smallest AXI-derived
IAL2 object that can prove the required layering:

```text
IAL2 protocol intent -> reviewable IAL1 .isf -> reviewable IAL0 .fsm -> HDL
```

The subset should model one named channel contract at a time. It should carry:

- protocol/profile identity, such as `axi4`,
- channel family, such as `AW`, `W`, `B`, `AR`, or `R`,
- `VALID` and `READY` signal names,
- payload/control fields guarded by the transfer,
- clock and reset binding,
- endpoint role metadata,
- source anchors and generated-rule report metadata,
- explicit unsupported residue.

## Why This Subset First

The full future AXI manager remains the target user-facing direction: Easy
mode as conventions over configuration, Power mode as structured override, and
supervised Raw mode with rule-engine protections.

However, the first implementation must prove the new layer boundary before it
tries to own all AXI concurrency. The Valid-Ready channel contract is the best
first subset because:

- it is already source-anchored in the tracked AXI reference,
- it is shared by all five AXI channel families,
- it has real protocol semantics rather than syntax sugar,
- it can produce useful generated assertions and reports,
- it avoids prematurely selecting ID allocation, outstanding windows,
  response matching, burst assembly, and interconnect behavior,
- and it can still become a reusable building block inside the later AXI
  manager.

This choice does not weaken the Easy-mode requirement. It only says the first
implementation slice should prove the transport-contract substrate before
attempting the full concurrent manager.

## Minimum Future Source Surface

The first implementation leaf must choose exact syntax, but the semantic shape
must be equivalent to:

```text
(protocol-contract axi4.valid-ready aw_addr
  (channel AW)
  (clock clk)
  (reset reset)
  (valid awvalid)
  (ready awready)
  (payload awaddr awlen awsize awburst)
  (role manager-to-subordinate))
```

The syntax may live in a future generic IAL2 container such as `.pif`, `.ppi`,
or `.ppif`, or in a future profile alias such as `.axi`. Either way, it must
lower through IAL1 before IAL0 and must not lower directly to `.fsm`.

## Required IAL1 Artifact Shape

The generated IAL1 `.isf` review artifact should expose a small monitor actor
or actor pair that makes the channel contract explicit. The exact syntax is a
future implementation detail, but the artifact must be reviewable and must
show:

- the bound clock/reset,
- the valid/ready fire event,
- the payload/control bundle,
- reset behavior obligations,
- valid-hold and payload-stability checks,
- a rule/report block that maps generated checks back to source anchors,
- explicit assumptions and residue.

The IAL1 output must not be a hidden internal IR. The user must be able to
inspect it before IAL0 generation.

## Required IAL0 Artifact Shape

The generated IAL0 `.fsm` review artifact should make the monitor behavior
cycle-explicit. It should expose:

- a transfer/fire condition equivalent to `VALID && READY`,
- state or storage needed to remember that `VALID` is pending while `READY` is
  low,
- payload snapshot storage when stability checks need it,
- generated assertion carriers for the owned safety checks,
- no transaction ID, burst, manager queue, or response-matching behavior.

## Report Contract

The readiness audit
[docs/AXI_IAL2_VALID_READY_READINESS_AUDIT.md](AXI_IAL2_VALID_READY_READINESS_AUDIT.md)
maps the current code and report owners that must implement this contract.
The first in-process implementation slice
[docs/AXI_IAL2_VALID_READY_GENERATOR_FIRST_SLICE.md](AXI_IAL2_VALID_READY_GENERATOR_FIRST_SLICE.md)
ships this report surface for one AXI Valid-Ready contract object.

The implementation report emits:

- source object identity,
- source PDF anchor list,
- generated IAL1 path,
- generated IAL0 path,
- target channel family,
- valid/ready/payload bindings,
- enforced static rules,
- generated scheduler or monitor rules,
- generated runtime assertions,
- environment assumptions,
- unsupported residue,
- and whether the result is monitor-only, assertion-only, or behavior-bearing.

## Focused Validation

The first implementation leaf adds focused tests for:

- `VALID && READY` reported as the transfer/fire condition,
- `VALID` held after a prior-cycle stall,
- payload/control stability after a prior-cycle stall,
- reset-low valid behavior reported as explicit unsupported residue,
- generated IAL1 before generated IAL0,
- report source anchors and residue,
- fail-closed missing `VALID`, `READY`, clock, reset, or payload bindings,
- and proof that direct IAL2-to-`.fsm` lowering is not available.

## Explicit Residue

The first subset deliberately excludes:

- AXI transaction ID allocation or validation,
- outstanding read/write windows,
- same-ID ordering queues,
- different-ID interleaving,
- `BID`/`RID` response matching,
- burst length, size, and last-beat tracking,
- write-data sequencing across multiple transactions,
- read-data chunking,
- Resource Plane credited transport,
- Atomics, exclusives, cacheability, protection, QoS, regions, wake-up, ACE,
  CHI, and interconnect ID remapping,
- full Easy/Power/supervised Raw manager APIs.

Those remain future exact-owner work. The completed rule matrix stays the
source of the broader target.

## Current Conclusion

The first shipped AXI-derived IAL2 subset is a source-anchored in-process
Valid-Ready channel contract/monitor generator, not the full AXI manager. This
first implementation proves the IAL2 layer, the mandatory
`IAL2 -> IAL1 -> IAL0` lowering chain, and the source-anchor/report discipline
with a small enough blast radius to validate thoroughly.

The full AXI manager remains a later implementation family. It must build on
this substrate and the rule matrix rather than replacing them.
