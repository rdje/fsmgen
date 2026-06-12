# IAL2 Protocol And Platform Intent Evaluation

Status: evaluation complete; first bounded IAL2 implementation and `.ppif`
parser/CLI slices shipped.

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
- IAL2 now has a first bounded shipped surface for one AXI Valid-Ready
  protocol intent object. Broader IAL2 remains protocol/platform-generic and
  should grow only where it owns semantics above individual IAL1 transactions.

ATL remains IAL1 while authors explicitly write actor/network `.isf` syntax.
Compact aliases, wrappers, macros, and nicer spellings are not IAL2 by
themselves.

IAL2 must apply to protocol families such as AXI, CHI, ACE, AHB, APB, ATB,
and future protocols, as well as platform intent above protocol-specific
transactions. A future IAL2 file may select an internal protocol or platform
vocabulary without changing the generic file surface.

Decision [0016](decisions/0016-ppif-is-first-public-ial2-container.md)
selects `.ppif` (Protocol/Platform Intent Format) as the first public generic
IAL2 file suffix. Earlier candidates `.pif` and `.ppi` are not first
implementation suffixes.

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

IAL2 is no longer purely design/probe-only: the first in-process
behavior-bearing slice is
[AXI_IAL2_VALID_READY_GENERATOR_FIRST_SLICE](AXI_IAL2_VALID_READY_GENERATOR_FIRST_SLICE.md).
It accepts one AXI Valid-Ready contract object, emits reviewable `.isf`, lowers
through the existing IAL1 path to reviewable `.fsm`, and returns a
source-anchor/residue report. Decision
[0016](decisions/0016-ppif-is-first-public-ial2-container.md) selects `.ppif`
as the first public generic IAL2 file suffix, and
[IAL2_PPIF_PARSER_CLI_FIRST_SLICE](IAL2_PPIF_PARSER_CLI_FIRST_SLICE.md)
ships the first parser/CLI path for exactly one
`(valid-ready-channel ...)` object per `.ppif` file. The AXI manager
capacity/status shell is now also public through
[AXI_IAL2_MANAGER_CAPACITY_STATUS_PPIF_FIRST_SLICE](AXI_IAL2_MANAGER_CAPACITY_STATUS_PPIF_FIRST_SLICE.md),
and the next selected manager subset is ID-family declaration/static
validation in
[AXI_IAL2_MANAGER_ID_FAMILY_SUBSET_SELECTION](AXI_IAL2_MANAGER_ID_FAMILY_SUBSET_SELECTION.md);
the readiness audit
[AXI_IAL2_MANAGER_ID_FAMILY_READINESS_AUDIT](AXI_IAL2_MANAGER_ID_FAMILY_READINESS_AUDIT.md)
selected an additive optional `id_families` extension to the existing
capacity/status object, and
[AXI_IAL2_MANAGER_ID_FAMILY_FIRST_SLICE](AXI_IAL2_MANAGER_ID_FAMILY_FIRST_SLICE.md)
ships that `.ppif` metadata/report slice without changing generated `.isf`,
generated `.fsm`, or HDL behavior. The next selected manager subset is the
logical read/write transaction envelope and static-validation contract in
[AXI_IAL2_MANAGER_TRANSACTION_ENVELOPE_SELECTION](AXI_IAL2_MANAGER_TRANSACTION_ENVELOPE_SELECTION.md);
the readiness audit
[AXI_IAL2_MANAGER_TRANSACTION_ENVELOPE_READINESS_AUDIT](AXI_IAL2_MANAGER_TRANSACTION_ENVELOPE_READINESS_AUDIT.md)
selects an additive optional `(transactions ...)` static/report metadata
extension under that existing object, with generated `.isf`, generated `.fsm`,
and HDL behavior unchanged for the first implementation. That first
transaction-envelope slice is shipped in
[AXI_IAL2_MANAGER_TRANSACTION_ENVELOPE_FIRST_SLICE](AXI_IAL2_MANAGER_TRANSACTION_ENVELOPE_FIRST_SLICE.md)
with a separate `.ppif` sample, structural report metadata, support
accounting, check JSON, and semantic JSON source identity. The next selected
manager prerequisite is transaction event dispatch and direction fan-in in
[AXI_IAL2_MANAGER_TRANSACTION_EVENT_DISPATCH_SELECTION](AXI_IAL2_MANAGER_TRANSACTION_EVENT_DISPATCH_SELECTION.md),
because ID allocation and response matching need per-transaction request and
completion provenance before generated dynamic behavior is claimed. The
readiness audit
[AXI_IAL2_MANAGER_TRANSACTION_EVENT_DISPATCH_READINESS_AUDIT](AXI_IAL2_MANAGER_TRANSACTION_EVENT_DISPATCH_READINESS_AUDIT.md)
selects an additive implementation boundary under the existing
`manager-capacity-status` object: distinct per-transaction request/completion
events can fan into the current read/write capacity/status rule matrices
through existing IAL1/IAL0/SystemVerilog lowering, with no separate substrate
prerequisite first. The first implementation slice is shipped in
[AXI_IAL2_MANAGER_TRANSACTION_EVENT_DISPATCH_FIRST_SLICE](AXI_IAL2_MANAGER_TRANSACTION_EVENT_DISPATCH_FIRST_SLICE.md):
it declares unique transaction events as generated IAL1 inputs, preserves
scalar one-event compatibility, emits OR fan-in guards for multi-event
direction groups, widens the IAL1 guard-conflict proof for bounded
OR/negated-OR generated guards, reaches SystemVerilog, and additively reports
`transaction_event_dispatch` metadata. The next selected subset is
[AXI_IAL2_MANAGER_ID_RESPONSE_RULE_ENGINE_SELECTION](AXI_IAL2_MANAGER_ID_RESPONSE_RULE_ENGINE_SELECTION.md):
readiness-audit whether the first ID/response behavior can extend the existing
`manager-capacity-status` object through current IAL1/IAL0/SystemVerilog
substrate, or whether a narrower prerequisite is needed first. The readiness
audit
[AXI_IAL2_MANAGER_ID_RESPONSE_RULE_ENGINE_READINESS_AUDIT](AXI_IAL2_MANAGER_ID_RESPONSE_RULE_ENGINE_READINESS_AUDIT.md)
selects additive concrete transaction ID request/response assertions as the
first implementation boundary with no separate IAL1/IAL0/SystemVerilog
prerequisite. The implementation slice is shipped in
[AXI_IAL2_MANAGER_CONCRETE_ID_ASSERTIONS_FIRST_SLICE](AXI_IAL2_MANAGER_CONCRETE_ID_ASSERTIONS_FIRST_SLICE.md):
transactions with concrete requested IDs now declare used ID-family
request/response ID signals as generated IAL1 inputs, lower assertion-only
checks to `.fsm` `+assert` carriers, emit verification-only SystemVerilog
assertions, and report `id_response_rule_engine` metadata. Auto-ID
allocation, ID release, response demux, ordering, bursts, queued/blocking
policy, aliases, full AXI manager behavior, and VHDL remain residue.
Public `.pif`, `.ppi`, `.axi`, protocol-profile aliases, ID allocation,
ordering, response matching, bursts, queued/blocking policy, and full AXI
manager behavior remain unshipped until exact owners select and implement
them.
Decision
[0014](decisions/0014-protocol-platform-intent-surface-and-layered-lowering.md)
records the protocol/platform-generic IAL2 file-surface direction and the
mandatory `IAL2 -> IAL1 -> IAL0` lowering chain. Decision
[0015](decisions/0015-ial2-profile-extensions-are-vocabulary-aliases.md)
refines that model: protocol-specific file extensions can be future
vocabulary/profile aliases, but not separate layers.
