# IAL2 Protocol And Platform Intent Evaluation

Status: evaluation complete; no IAL2 implementation selected.

Task tree:
[docs/tasks/IAL2-PROTOCOL-PLATFORM-INTENT-EXPLORATION.md](tasks/IAL2-PROTOCOL-PLATFORM-INTENT-EXPLORATION.md).

## Purpose

This note records the first non-code evaluation of whether FSMGen should grow
an intent layer above current `.isf` / IAL1.

The question is not whether another syntax would be convenient. The question
is whether an IAL2 layer would carry independent hardware semantics that are
not already expressible as explicit IAL1 actor/network scheduling.

## Layer Boundary

FSMGen currently uses these intent-layer meanings:

- IAL0 is `.fsm`: explicit cycle-authored hardware intent and the semantic
  audit artifact before HDL.
- IAL1 is `.isf`: scheduling intent over actors, transactions, rules, waits,
  drives, resources, generated children, constraints, and selected clock-domain
  metadata, lowered into reviewable IAL0 `.fsm`.
- IAL2 is not shipped. Its future file surface must be protocol/platform
  generic. It should exist only if it owns semantics above individual IAL1
  transactions.

ATL remains IAL1 while authors explicitly write actor/network `.isf` syntax.
Compact aliases, wrappers, macros, and nicer spellings are not IAL2 by
themselves.

IAL2 must apply to protocol families such as AXI, CHI, ACE, AHB, APB, ATB,
and future protocols, as well as platform intent above protocol-specific
transactions. A future IAL2 file may select an internal protocol or platform
vocabulary without changing the generic file surface.

The exact extension spelling remains open. Current candidates are `.pif`
for Protocol Intent Format, `.ppi` for Protocol/Platform Intent, and `.ppif`
for Protocol/Platform Intent Format.

Protocol-specific extensions such as `.axi`, `.chi`, `.ace`, `.ahb`, `.apb`,
`.atb`, `.smbus`, or `.i2s` may also be accepted later as vocabulary/profile
aliases over the same IAL2 model. They are not separate semantic layers and
do not get direct-lowering privileges.

The required lowering chain is:

```text
IAL2 -> IAL1 / .isf -> IAL0 / .fsm -> HDL
```

Direct `IAL2 -> IAL0` lowering is forbidden.

## Minimum IAL2 Semantic Contract

An IAL2 candidate must provide all of these before implementation work is
justified:

- A named protocol/platform intent object whose meaning is larger than one
  explicit actor transaction.
- Source identity and source anchors when the object came from a protocol,
  TRM, design note, or platform contract.
- A role model: participating actors, endpoints, transport channels, and
  hierarchy boundaries.
- Interface and phase facts before generated states are chosen.
- Persistent-state requirements justified by protocol/platform rules.
- Scheduler-visible choices that IAL1 source would otherwise require the user
  to spell manually, such as arbitration, buffering, legal ordering, resource
  placement, or selected schedule families.
- Invariants, gates, assertions, and liveness assumptions captured with the
  implementation intent.
- An abstraction/residue log that distinguishes confident recovery, heuristic
  inference, explicit simplification, unresolved ambiguity, and unsupported
  behavior.
- A lowering report that maps the IAL2 object into IAL1 and IAL0 artifacts so
  the chosen cycle behavior remains reviewable.

If a proposed feature cannot satisfy that contract, it should stay IAL1 or
remain out of the language.

## First Evidence To Inspect

The AXI intent-capture case study is the strongest available evidence because
it already has a staged method, an actor-first decomposition, assertion-ledger
discipline, explicit abstraction logging, and a first emitted reusable
`valid_ready_channel_tx_rx`-style transport actor.

The current repo-local raw reference artifact for that evidence is
`docs/vendor/arm/amba/axi/IHI0022_L_2025-08_AMBA_AXI_Protocol_Specification.pdf`
with SHA-256
`20aa5f946df5fa97053689d705959b1ef6a90a88f845fa3b686a53311f680ac1`.

The first curated repo-local source-anchor inventory is
[docs/AXI_VALID_READY_INTENT_PROBE.md](AXI_VALID_READY_INTENT_PROBE.md). It
records the AXI Valid-Ready anchors, inferred candidate model, explicit
abstractions, unsupported residue, and current no-implementation status.

The first captured user-facing AXI manager API brainstorm is
[docs/AXI_MANAGER_USER_API_BRAINSTORM.md](AXI_MANAGER_USER_API_BRAINSTORM.md).
It shapes the possible IAL2 surface around a protocol-aware AXI transaction
manager: Easy mode as conventions over configuration rather than a reduced
subset, Power mode as structured override capability, and supervised Raw mode
as lower-level channel control that still normally passes through the same
AXI rule engine.

The first curated AXI ID/order/concurrency source-anchor inventory is
[docs/AXI_ID_ORDERING_RULE_EVIDENCE_PROBE.md](AXI_ID_ORDERING_RULE_EVIDENCE_PROBE.md).
It records the first source anchors for IDs, outstanding concurrency,
same-ID ordering, response matching, read-data interleaving, write-data
sequencing, interconnect ID remapping, and explicit residue. It confirms that
a future Easy-mode AXI manager can remain concurrent only if a source-anchored
rule engine owns ID allocation/validation, per-ID outstanding scoreboards,
response matching, interleaving policy, and clear capacity or ordering
feedback.

The first bounded AXI manager rule responsibility matrix is
[docs/AXI_MANAGER_RULE_MATRIX_DESIGN_PROBE.md](AXI_MANAGER_RULE_MATRIX_DESIGN_PROBE.md).
It maps the captured Valid-Ready and ID/order evidence to future rule-engine
responsibility classes: static checks, generated scheduler/scoreboard
behavior, runtime assertions, environment assumptions, and unsupported
residue. It remains design/probe evidence only.

The selected first AXI-derived IAL2 implementation subset is
[docs/AXI_IAL2_FIRST_IMPLEMENTATION_SUBSET_SELECTION.md](AXI_IAL2_FIRST_IMPLEMENTATION_SUBSET_SELECTION.md):
a source-anchored AXI Valid-Ready channel contract/monitor. That future
implementation is intentionally smaller than the full manager so it can prove
the mandatory `IAL2 -> IAL1 -> IAL0` lowering chain, source-anchor reporting,
and residue discipline first.

The first bounded IAL2 probe should not start with a full AXI manager or an
interconnect. It should inspect the reusable valid/ready transport contract
because that is the smallest candidate with real protocol semantics:

- It has channel roles rather than only local signals.
- It has phase and gate structure around valid/ready firing.
- It carries stability, causality, and liveness-with-assumptions obligations.
- It can lower into an IAL1 actor or actor pair plus IAL0 `.fsm` artifacts.
- It can produce a capture/residue report from the same source evidence.

If the valid/ready contract only becomes a hand-written reusable `.fsm`
library, that is useful but not IAL2. It becomes an IAL2 candidate only if a
source intent object can generate or configure the IAL1/IAL0 artifacts while
preserving source anchors, semantic roles, assertions, abstractions, and
residue.

## Go Criteria For A Future Implementation Leaf

A future IAL2 implementation leaf is justified only if a bounded candidate can
prove all of the following:

- One source intent object lowers to reviewable IAL1 `.isf` before any IAL0
  `.fsm` exists.
- The same source object emits a capture/evaluation report with source anchors,
  abstractions, residue, and generated artifact links.
- At least one scheduler-visible choice is made from the protocol/platform
  semantics rather than copied from explicit IAL1 syntax.
- The generated artifacts are small enough to validate with focused tests.
- The user-facing mdBook can explain the behavior without asking users to read
  internal Perl code.

## No-Go Criteria

IAL2 should stay deferred if the candidate is only:

- a macro expansion for existing `.isf` syntax,
- a compact alias for explicit ATL forms,
- a wrapper around one transaction with no independent runtime model,
- a prompt-only spec-to-code workflow without source anchoring and residue,
- or a reusable `.fsm`/`.isf` library asset that does not preserve a higher
  protocol/platform contract.

## Current Conclusion

IAL2 is design/probe ready, not implementation ready.

The next implementation must be another exact task-tree leaf, and it should
start with a bounded valid/ready protocol-intent object only if the source
contract, report contract, lowering artifacts, and validation gates are all
specified first. The completed AXI Valid-Ready evidence inventory is enough to
justify a later design/probe leaf, but it still does not select IAL2 syntax,
parser behavior, lowering behavior, generated `.fsm`, HDL, or reusable library
artifacts. The completed AXI ID/order/concurrency evidence inventory, rule
matrix, first-subset selection, and
[AXI_IAL2_VALID_READY_READINESS_AUDIT](AXI_IAL2_VALID_READY_READINESS_AUDIT.md)
are enough to justify a later narrow Valid-Ready generator implementation
leaf. That future leaf should emit reviewable `.isf` before `.fsm` and should
not add public IAL2 CLI suffixes or full AXI manager behavior in the same
slice.
Decision
[0014](decisions/0014-protocol-platform-intent-surface-and-layered-lowering.md)
records the protocol/platform-generic IAL2 file-surface direction, the open
`.pif`/`.ppi`/`.ppif` extension candidates, and the mandatory
`IAL2 -> IAL1 -> IAL0` lowering chain. Decision
[0015](decisions/0015-ial2-profile-extensions-are-vocabulary-aliases.md)
refines that model: protocol-specific file extensions can be future
vocabulary/profile aliases, but not separate layers.
