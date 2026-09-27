---
id: isf-direct-writer-admission-boundary
title: Direct writer admission needs physical overlap and explicit controller ownership
answers:
  - "does ISF reject competing writes from direct sibling transactions?"
  - "does transaction priority grant independent controller writes?"
  - "which physical targets must shared writer admission compare?"
  - "where are physical writer packed ranges resolved?"
  - "which ISF widths are explicit physical declarations?"
  - "where is the direct writer admission baseline?"
date: 2026-09-27
status: current
tags: [isf, controllers, writers, storage, conflicts, ownership]
evidence: perl/FSM/Scheduler/ISF/PhysicalWriteDeclarations.pm; t/1968-isf-physical-write-declarations.t; perl/FSM/Scheduler/ISF/PhysicalWriteTargets.pm; t/1967-isf-physical-write-targets.t; docs/audits/direct-writer-admission-20260927/manifest.json; docs/audits/direct-writer-admission-20260927/result.json; perl/FSM/Scheduler/ISF/LoweringIR.pm; docs/decisions/0109-direct-transactions-have-independent-logical-controllers.md; docs/knowledge/isf-generated-child-writer-contract-frontier.md
reverify: scripts/run_with_ram_guard.sh perl docs/audits/direct-writer-admission-20260927/reproduce.pl; compare .artifacts/direct-writer-admission/current.json with the retained result.json. This is a dated admission baseline, not an expected future safety contract.
---

At 18b23da3a47a1dce3c084d09c7a29ec48f130dd5, direct siblings writing different
values to the same actor register or output pass strict check with no schedule
compile issue. Declaring transaction/transaction priority adds no resolution.
Rule/rule and unordered rule/transaction controls reject with their existing
message tokens. The check reports those controls as unclassified diagnostics;
this audit does not promote the tokens to stable structured codes.

The actual lowered writer records distinguish these mechanisms:

- Direct formals with the same authored spelling have separate private targets.
- Literal bank stores to the same entry both target ram_0.
- Whole aggregate and member writes name frame and frame.mode; string equality
  alone cannot determine overlap. Distinct leaves retain frame.mode/frame.flag.
- Disjoint authored set-field masks both write the whole value_reg through
  masked read-modify-write expressions. They are not disjoint physical writes.
- Shared named-drive calls write the same put_payload helper before the single
  drive DT writes observed. Reviewing only actor outputs would miss that input
  contention. Completion pulses retain their separate compatible fan-in.

_build_conflict_issues originated in
f657a6c89c9ce1771cc8f02f1d90bd958739203d for rule/rule errors and rule/drive
warnings. It compares equal target strings. The rule/transaction priority pass,
introduced in 49711b6dbee775600d924da3f92819136c52c567, now handles those owner
pairs but does not turn transaction/transaction declarations into grants.
Existing state provenance/priority helpers still derive transaction names from
state spellings, despite the separate explicit state.transaction field.

Owner SEMANTIC-INTROSPECTION-MCP-FRONTIER.32.1.3.3.1.3.3 retains this baseline
in child .1, requires a detached complete writer inventory in .2, and owns
conservative admission in .3 before independent-controller promotion. Inventory
must use actual state/DT assignments after binding and generated handoff wiring,
keep domains/modules separate, resolve physical target structure and explicit
owners, and preserve actual guards/grants. An entry guard does not prove that
whole transaction bodies are mutually exclusive. Generated-child storage
ownership remains governed by decision 0107 and its separately qualified lanes.

No concurrent execution, new arbitration or writer-safety claim follows from
this baseline. The known reachability audit remains canonical; it is not rerun
or reinterpreted as shared-writer qualification here.

The first detached inventory prerequisite is PhysicalWriteTargets. It resolves
actual declared roots and aggregate paths into module/root/packed-range records,
using Package::AggregatePathSupport for type-directed traversal and offsets.
Whole frame covers its mode/flag leaves; distinct leaves do not overlap. Nested
record/list fragments retain their packed positions. Root width/type mismatches,
unknown declarations/paths and malformed range operands are refused. Identically
named roots in separate modules are distinct, and private formal names remain
separate roots. No mask is inferred from an assignment RHS.

T1967 uses every assignment in the admitted baseline plus independent nested
range arithmetic and omission/mutation controls. The helper is detached and is
not called by production lowering or admission yet. Complete declaration/owner
collection and shadow attachment remain .3.2.2/.3.2.3 under the writer parent;
conservative executable admission remains .3.3.

PhysicalWriteDeclarations collects the same explicit sources and precedence as
Emitter::FSM::_emit_size: ports, declared storage signals, counters and eligible
assembly operands. Static constants/parameters are not assembly declarations.
It retains emitted type tokens, resolved widths and detached aggregate layouts.
A signal_widths entry alone is not a declaration: sampled aliases and unrelated
known expressions remain absent from +size. Actual assignment roots lacking
explicit declarations appear in unresolved_targets; no width is guessed and no
completeness claim follows. T1968 compares actual emitted tokens, generated
post-wiring parent/child modules, typed private formals and aggregate ranges;
omission, malformed-contract and detached-mutation controls qualify the boundary.
Reverify with guarded prove on T1968. The next child .3.2.2.2 owns implicit scalar
contracts before explicit producer ownership and shadow attachment.
