---
id: isf-logical-controller-shadow
title: Private logical-controller membership and state consumer inventory
answers:
  - "where is explicit transaction and domain ownership recorded for lowered states?"
  - "which consumers must change before independent ISF controllers can execute?"
  - "how can logical controller membership be checked without changing emission?"
date: 2026-09-27
status: current
tags: [isf, controllers, ownership, state, shadow]
evidence: perl/FSM/Scheduler/ISF/LogicalControllers.pm; perl/FSM/Scheduler/ISF/LoweringIR.pm; perl/FSM/Scheduler/ISF.pm; t/1924-isf-logical-controller-shadow.t; docs/audits/logical-controller-shadow-20260927/capture.pl; docs/decisions/0109-direct-transactions-have-independent-logical-controllers.md
reverify: scripts/run_with_ram_guard.sh prove -Iperl t/1924-isf-logical-controller-shadow.t t/1387-isf-cross-domain-activation-handshake-lowering.t t/1416-isf-trigger-anchor-ref.t; scripts/run_with_ram_guard.sh perl docs/audits/logical-controller-shadow-20260927/capture.pl current
---

LoweringIR attaches `logical_controllers` to parent and generated transaction
child IR after linking and finalization. Library/ATL actor bodies use the parent
path. This private shadow groups only retained states by their explicit
`transaction` field, never by parsing a state-name prefix. Cross-domain caller
request/ready and callee entry/completion states now receive that field too.
Empty or pruned transactions do not acquire fabricated states/controllers.

Each controller records a structured module/domain/transaction identity,
ordered state membership, its first owned state, authored or synthesized entry
states, and clock/reset context. An undefined domain denotes the actor's
unnamed clock context. Domain realizations retain the nominal default domain
through `_scheduled_domain_name` after their clock-domain declaration is
removed. Generated child templates describe their own source module context;
outer composition's separately allocated module/instance names remain in its
realization map. No physical selector or public interface is allocated here.

`LogicalControllers->inventory($ir, $actor)` returns detached membership,
typed state references and issues without changing source admission.
`assert_valid($ir, $actor)` is the explicit qualification gate: it rejects
missing/unknown owners, duplicate states, missing targets and cross-owner
references. Tests qualify actual parent, child and domain models. Arbitrary
state spelling and transaction names resembling scheduler suffixes cannot
alias owner tuples. Executable promotion still needs collision-safe HDL name
allocation against all scoped declarations; the shadow is not that allocator.

The reference inventory retains transition targets, branch and loop entry
fields, switch body starts, and repeat/wait/loop/branch membership metadata.
Metadata is labeled separately from transition records; it is not a new
execution planner. Conditions and signal expressions are not scanned or
rewritten as arbitrary text. Existing ControlFlowEffects remains the source
region/activation-effect model; this model describes its lowered state owners.

## Consumers that executable promotion must preserve

| Consumer | Existing mechanism and migration obligation |
| --- | --- |
| Control emission | Emitter::FSM::_emit_states emits one encoded root; _emit_transitions handles await, repeat, loop, branch, switch and synchronization cases. Materialized branches supersede their alternate metadata. Map effective edges through the owning controller. |
| Initial/terminal behavior | Per-owner first state is recorded, but the emitter still initializes only its existing global root. Preserve explicit return-to-entry versus trailing sync self-hold and implicit no-transition holds. |
| Rule/transaction priority | LoweringIR::_state_active_condition_expr emits logical `(state_active NAME)` predicates. _transaction_data_assignment_refs and _state_assignment_provenance still have legacy name-derived ownership. Replace these consumers with explicit scoped owners before executable promotion; never rewrite arbitrary expression strings. |
| Named points/assertions | _resolve_at_references installs a state-owned combinational point-active assignment; assertions read that signal, potentially across transactions. The future controller guard must preserve its pulse and entry visibility. |
| Wait/loop reports | Emitter::JSON consumes wait_state_names and associated entry/body/backedge metadata. Preserve logical names and ordered source-owned membership. |
| Resets and monitors | Module clock/reset, reset_values, state assignments and DT monitor blocks remain untouched. Future private selectors must use the actual domain reset contract, including no-reset configurations. |
| Public ownership reports | Emitter::JSON::_transaction_summary prefers explicit transaction and retains a legacy fallback for hand-built IR. Assignment provenance, compatibility groups and conflict reports keep their current contract in this slice. |
| Interfaces/composition | Emitter::FSM size/interface/system sections and CompositionTop/domain realization wiring still own physical declarations. Shadow tuples add no ports, storage, selectors or generated names. |

The first qualification found an emitter-ignored phantom timeout transition:
_link_states added one to every await even without a watchdog. It now adds a
timeout edge only when a watchdog name exists. Real watchdog transitions remain
covered; this does not repair the separate external-callee initialization gap.
The retained parity audit compares complete public reports and every emitted
IAL0 file before/after, not only counts or selected fields. Runtime controller
repair remains open under decision 0109.

Owner: SEMANTIC-INTROSPECTION-MCP-FRONTIER.32.1.3.3.1.3.1.
