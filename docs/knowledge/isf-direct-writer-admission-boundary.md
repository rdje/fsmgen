---
id: isf-direct-writer-admission-boundary
title: Direct writer admission needs physical overlap and explicit controller ownership
answers:
  - "does ISF reject competing writes from direct sibling transactions?"
  - "does transaction priority grant independent controller writes?"
  - "which physical targets must shared writer admission compare?"
  - "where are physical writer packed ranges resolved?"
  - "which ISF widths are explicit physical declarations?"
  - "how do implicit ISF assignment targets participate in physical overlap?"
  - "where do lowered source-writer identities originate?"
  - "how are exact local and generated named-drive invocation sources retained?"
  - "where is the direct writer admission baseline?"
date: 2026-09-28
status: current
tags: [isf, controllers, writers, storage, conflicts, ownership]
evidence: perl/FSM/Scheduler/ISF/DriveInvocationSources.pm; t/1971-isf-drive-invocation-sources.t; perl/FSM/Scheduler/ISF/SourceWriterOwners.pm; t/1970-isf-source-writer-owners.t; t/1969-isf-implicit-write-targets.t; perl/FSM/Scheduler/ISF/PhysicalWriteDeclarations.pm; t/1968-isf-physical-write-declarations.t; perl/FSM/Scheduler/ISF/PhysicalWriteTargets.pm; t/1967-isf-physical-write-targets.t; docs/audits/direct-writer-admission-20260927/manifest.json; docs/audits/direct-writer-admission-20260927/result.json; perl/FSM/Scheduler/ISF/LoweringIR.pm; docs/decisions/0109-direct-transactions-have-independent-logical-controllers.md; docs/knowledge/isf-generated-child-writer-contract-frontier.md
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
Reverify with guarded prove on T1968.

PhysicalWriteDeclarations::target_contracts now covers actual bare implicit LHS
roots using PhysicalWriteTargets::whole_root. Its coverage is the whole signal,
with no asserted width or packed bounds. Whole-root writes overlap every valid
contract on the same module/root, including a resolved aggregate member; they
cannot prove partial disjointness. Different roots/modules stay separate.
Unresolved member/index paths are refused, not converted to whole-root evidence.
The explicit collection still lists undeclared targets separately so consumers
cannot mistake downstream inferred widths for emitted declarations.

The canonical downstream parser owns width resolution in parse_signal_action
and reconcile_simple_assignment_signal_widths. T1969 proves sampled aliases and
copy chains inherit actual carrier widths, while a bare one-bit assignment has
its downstream scalar width. Complete native/carrier semantic products agree
under width and state-order variants. Mutation, missing-layout and actual sibling
writer controls keep overlap conservative. Reverify with guarded prove on T1969.
Explicit source/generated producer ownership remains .3.2.2.3/.3.2.2.4 before
shadow attachment; no production admission consumer is installed yet.

LoweringIR now attaches private source_owner records at the transaction auxiliary
DT, rule DT and named-drive DT producers. States retain their existing explicit
transaction field. SourceWriterOwners resolves those identities against authored
transaction/rule/drive records and the actual module/domain, rejecting missing,
unknown or malformed owners, unsupported DT families and mixed pre-partition
module views. It returns detached source/container tuples without parsing names.
A transaction-created monitor/latency DT remains a DT; source ownership does not
supply an execution guard or state-exclusion proof. Shared named drives retain
all callers rather than selecting one as their source owner.

T1970 covers private-formal preparation, declaration permutations, renamed
containers, generated children and realized domains, malformed/omitted records,
complete native/API/newline reports and unchanged strict carriers. Reverify with
guarded prove on T1970. Legacy public assignment provenance remains unchanged;
exact activation/per-assignment caller association is .3.2.2.3.2 and generated
handoff/completion/helper ownership is .3.2.2.4 before complete shadow attachment.

_build_drive_dts now attaches private drive_invocation records per assignment
from the actual producer branch. Local records retain the exact caller group,
including empty/multiple sets; generated records retain one actual spawn/do/
trigger descriptor with child, instance, source owner and request signal.
DriveInvocationSources resolves an assignment index and verifies its association
against the DT's explicit drive owner and local/generated source records.
It never recovers owners from helper-name prefixes or borrows local callers for
a generated assignment. The existing broad public invoking_transactions field
is unchanged. These associations are source evidence, not a grant or guard proof.

T1971 qualifies a mixed local/spawn/do/trigger actor, source permutations, renamed
DTs, unused drives, target-local priority guards, omitted/mutated associations,
detached records, complete public report parity and strict exported carriers.
Reverify with guarded prove on T1971. Emitted guard qualification follows under
.3.2.2.3.2.2 before generated helper ownership and complete shadow attachment.

WriterActivation now resolves an explicit state/DT assignment index into separate
container and assignment predicates plus separately labeled state-transition
context. It preserves raw guards and structured expression ASTs with consistency
checks, literal zero/true elision, comparison forms and rule group placement.
Entry bookkeeping does not inherit the entry condition. Actual state decrements
remain unguarded; invented guarded state decrements and DT decrements are refused.
T1973 independently compares real emitted carriers, strict native/carrier semantic
products, omitted/malformed predicates, operator fragments and deep detachment.
The helper is private and detached; it proves neither ownership nor exclusion.
Resource/priority/invocation evidence and complete producer/public parity remain
children .2/.3 of SEM .32.1.3.3.1.3.3.2.2.3.2.2.2. Reverify with guarded T1973.

The P1 baseline from grant evidence collection overwrote a priority condition
when multiple higher writers shared one owner. An admitted transaction writing
out in main_set_1/main_set_2 left the lower rule masked only in the second state,
regardless of write-value order. The single-state control passed;
complete public check/schedule/carrier/selector evidence and a saved verifier are
in docs/audits/priority-contributors-20260927/. Transaction-winner exposure began
at 7a3222a1a465e165d14569f1229f6887d6709f2f; the owner-key storage mechanism is
older. SEM .32.1.3.3.1.3.3.2.2.3.2.2.2.2.2 owns repair before metadata integration.
Child .1 now retains distinct conditions per owner and negates their deterministic
union. T1974 checks multi-state/value/declaration ordering, opposite priority,
compatible values, named drives, resource composition and unrelated targets;
complete native/API/newline/carrier and existing focused controls pass.
The first observed SystemVerilog compile succeeds, then runtime rejects admitted
equal-value overlap through the backend same-value onehot0 assertion. Native
admission and retained stage cleanup succeed; no native failure event occurs.
GeneratedModuleEmitter consumes unconditional same_value_assertion metadata from
LoweredRTLIRBuilder, although the actual data-family enable ORs those sources.
The earlier T1211 only tested emission text. The assertion origin is
fd3317ef93c8ea5901c53fd507ce2f2cf9672b3d. Decision 0111 now tags these families
compatible_fanin under the legacy same_value_assertion key and omits their
invalid source-exclusivity check. Different-value onehot0 and separate ownership
checks remain. Child .2 qualifies that metadata/emission repair; child .3 still
owns observed positive/negative execution and both HDL targets. Its next run
reaches an incorrectly early synchronous-reset bench check, now statically
corrected under .3.1; .3.2 owns actual completion. The exact failed observation,
public reset-contract witness and corrected event model are retained under
docs/audits/priority-reset-oracle-20260928/. Overall signoff remains open.
Verify saved evidence without a runtime with
`python3 -B docs/audits/priority-contributor-repair-20260928/verify.py`.
