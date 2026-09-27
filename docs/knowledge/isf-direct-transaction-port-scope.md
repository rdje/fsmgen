---
id: isf-direct-transaction-port-scope
title: Direct transaction formal identity plan and remaining scope integration
answers:
  - "can direct transaction ports share actor storage names?"
  - "why does a caller local port bind with the actor storage width?"
  - "do different direct transactions have independent same-named formal ports?"
  - "what must precede direct transaction port scope repair?"
  - "how are private direct formal identities planned without changing execution?"
  - "how does detached expression resolution distinguish caller and callee formal names?"
  - "why do bit helpers use an actor width instead of a shadowing formal width?"
date: 2026-09-27
status: current
tags: [isf, transactions, ports, scope, storage, bindings, control-flow]
evidence: t/1936-isf-formal-source-context.t; t/1935-isf-local-declaration-admission.t; t/1933-isf-caller-formal-binding-scope.t; perl/FSM/Scheduler/ISF/FormalClauseResolver.pm; t/1928-isf-formal-clause-resolver.t; perl/FSM/Scheduler/ISF/FormalOperandResolver.pm; t/1927-isf-formal-operand-resolver.t; perl/FSM/Scheduler/ISF/FormalIdentityPlan.pm; t/1925-isf-formal-identity-plan.t; docs/audits/direct-formal-bit-width-scope-20260927.json; perl/FSM/Scheduler/ISF/LoweringIR.pm; perl/FSM/Scheduler/ISF/Emitter/FSM.pm; docs/tasks/SEMANTIC-INTROSPECTION-MCP-FRONTIER.md; t/1241-isf-transaction-port-bindings.t; t/1243-isf-port-binding-schedule-report.t
reverify: scripts/run_with_ram_guard.sh prove -Iperl t/1936-isf-formal-source-context.t t/1935-isf-local-declaration-admission.t t/1933-isf-caller-formal-binding-scope.t t/1928-isf-formal-clause-resolver.t t/1927-isf-formal-operand-resolver.t t/1925-isf-formal-identity-plan.t t/1241-isf-transaction-port-bindings.t t/1243-isf-port-binding-schedule-report.t; rerun the tracked direct-formal-bit-width-scope parser sources before classifying the parser boundary.
---

Generated children have separately qualified local port metadata under .49.1.
Direct transactions still merge into the actor module under raw formal names.
_build_parent_ir seeds actor storage maps, then merges _build_transaction maps;
same-name actor/local roles or widths conflict. Separate direct transactions
with equal-width same-named formal ports can instead share one emitted storage
identity. That admission is not independent local state.

_binding_signal_info now resolves an explicit caller formal before actor
interface/storage, using the formal's declared width and transaction-variable
role. T1933 qualifies scalar/expression reads and output actuals against actor
input/output/storage shadows, width mismatch controls, callee directions,
timing and static-zero pruning. Actor-scope restrictions remain intact; rules
cannot borrow transaction formals. This is source binding validation only:
_build_parent_ir still fails conflicting physical merges until .49.2.2.3.3.
Direct formal/actor-pin collisions now fail before merging, including equal
widths that previously passed strict checking while sharing one physical name.
Generated-child interfaces and statically pruned targets do not enter this gate.
Generated pin shadows are separately repaired under .3.1.3: child formals
own their declarations and explicit spawn bindings exclude duplicate automatic
same-name actor wiring. T1934 and the generated-shadow card qualify that path;
T1933's retained equal-width reproduction now passes. These generated modules
do not establish direct physical separation. Explicit-local/static context
preparation is supplied by .3.1.2. Its .1 child repairs explicit-local admission:
_parse_local_decl requires exact known options, one width, one initialization
across default/init and one reset, plus a scalar HDL identifier. Previously it
ignored malformed options and let later duplicates overwrite earlier values.
T1935 covers those failures, valid reorderings/reset/init, existing collisions,
zero-pruned versus live targets, strict carriers and complete public reports.
This does not establish separate physical ownership for explicit locals.

The audit reproduction uses actor status width 8 and reset 19, a worker status
input or output width 8, and a narrower input control width 4. Role/width merges
fail. The historical parent status input width 4 bound to worker payload width 4
was wrongly validated as actor status width 8; .3.1.1 repairs that lookup. Separate first/second transactions with
status output width 4 assign 3/5; public reports admit them but emit one status
register and disconnected state loops inside one FSM root.

Scope repair must distinguish caller and callee endpoints, declaration metadata,
typed operands, rule payload fan-in destinations and authored report names.
Global textual replacement can corrupt state/type/member names or messages.
.49.2.2 owns collision-safe private identities and lexical binding lookup;
.49.2.3 owns local-call runtime signoff. The prerequisite .32.1.3.3.1 owns the
already reproduced unreachable local caller and independently triggered
consumer. Its leaves separate terminal synchronization, controller contract
selection and executable repair. Existing binding tests prove artifact/report
shape, not completion of that runtime prerequisite.

FormalIdentityPlan now provides a detached declaration plan. Owner identities
are structured actor/transaction/formal tuples. Each direct formal receives a
separate proposed physical name; generated child formals retain their public
name in their own module. Allocation is deterministic under source declaration
permutation and checks case-folded collisions through the existing portable
identifier allocator. Source names and complete local declaration metadata
remain separate from physical names; no actor reset/type/width is inherited.
Lookup stays within the requested owner and returns a detached value.

The caller must supply generated-child membership and a complete additional
physical reservation set. Source identifiers are conservatively reserved too.
This is a planner contract, not proof that the current lowerer supplies that
complete set: production integration has not happened. Private selectors,
monitor/counter names, named drives, handoffs and implicit samples must be
accounted at integration; unsupported grammar cannot be rewritten by guessing.
.49.2.2.2 owns typed operand/binding rewriting and .3 owns production integration
and source-facing report preservation. Existing public lowering is unchanged.

The paired parser audit retains the former width-lookup defect: a wider formal
was rejected and a narrower formal admitted an out-of-range bit against an
actor's same-name width. .49.2.2.4 now fixes literal formal precedence and keeps
unresolved formal/type widths from borrowing actor widths or using placeholder
values. The canonical [bit-helper card](isf-bit-helper-literal-width-precedence.md) and T1926
qualify that repair separately from this still-unintegrated identity planner.
Typed operand rewriting cannot substitute for parser validation.

FormalOperandResolver adds detached expression and binding resolution over
normalized ISF arrays, not formatted prefix strings or Lispish packed arrays.
Its constructor requires explicit owner (undefined for actor scope), local-name
and resolved static-symbol sets. It snapshots these and the plan; callers must
supply complete scope facts. Exact resolved static tokens keep expression
precedence; explicit locals shield formals. Other runtime references rename
only a matching owner-local formal root. Type-directed aggregate paths use
AggregatePathSupport; scalar bit/slice bounds use the formal declaration.
Nonformal references are preserved, not checked for declaration existence.

Carrier operator aliases/arity families come from ExpressionBuilder's pure
policy methods. State-active and point leaves retain source identities; sampled
past operands require explicit property context and keep literal depths.
Binding records contain detached source and physical entries plus a callee
identity/declaration. Inputs rewrite caller expressions; outputs require scalar
caller targets. Generated endpoints retain public names. Timing syntax stays
unchanged; admission, timing legality, width compatibility, static-symbol
completeness and generated placement are still the caller/lowerer's obligations.
This helper does not infer activation grants or repair runtime timing.

T1927 covers role preservation, operators, aggregate suffixes, malformed grammar,
context/source isolation and the still-failing production merge boundary.
FormalClauseResolver now supplies the detached normalized clause walker.
It rewrites explicit runtime roles in nested statements and check properties,
retaining source/physical binding records with structural paths. Source labels,
messages, static parameter structures and opaque phase annotations are preserved.
Actor-owned bank names, stage ready/valid endpoints, monitor observations and
parser-generated ATL wiring are preserved even under same-name formal shadows.
Named drive calls rewrite actuals; their names and actor-owned bodies are unchanged.

The walker consumes parsed, source-validated records and explicit complete
scope contexts. LoweringIR::prepare_formal_source now clones source and reuses
production module admission plus per-transaction lowering validation without
requiring conflicting parent merges. It derives explicit locals only, actor
parameters/constants, exact resolved enum members and canonical imported
constant leaf/aggregate paths through Package::Symbols. Inferred sample
destinations are not explicit-local shielding names. Unknown members and
parameter index spellings are not invented as runtime static symbols.

Standalone wait/repeat counts have a separate static_count_symbols context.
Direct transaction parameters belong there, but not in runtime static_symbols;
generated child parameters also belong in that child's expression scope.
T1936 retains the decisive same-named count parameter/formal case: scalar wait
uses the parameter, dynamic-expression wait and set RHS use the runtime formal.
A single global static set either renames both or preserves both incorrectly.
Other static options already retain their source spelling in the clause walker.

Preparation records structurally addressed zero repeats after existing source
checks; the walker preserves those dead source subtrees without resolving their
semantically pruned bindings. Malformed activation shapes and unknown targets
still fail in source admission, and a zero-only child's body remains unlowered.
Missing context maps, unmatched paths and non-repeat pruning paths fail closed.
Source snapshots and contexts are detached. Duplicate local/formal declarations
fail before rewriting. Production initial admission is factored through the same
helper; production does not yet invoke formal preparation or rewriting. Full
parent wiring, backend validation and physical reservations remain separate.
T1928 compares role arrays and independently strict-replays transformed carriers
from parsed helpers and the tracked controller cohort. That is detached helper
qualification, not a production runtime or report migration.

The dynamic-wait operator discrepancy is repaired under .49.2.2.5: unsupported
carrier shapes now fail before serialization. The canonical
[wait card](isf-dynamic-wait-count-predicates.md) owns that grammar and its audit.
Quoted-division diagnostics .52, wait examples .49.2.2.6 and extract replay .53
are qualified. .49.2.2.3 connects the resolvers and must still prove complete
physical reservations and source-report preservation. Source preparation is
qualified by T1936; .3.2 owns complete physical reservations next.

Owner: SEMANTIC-INTROSPECTION-MCP-FRONTIER.49.2.2.2.2.
