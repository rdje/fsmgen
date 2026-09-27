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
evidence: t/1939-isf-formal-helper-identity.t; t/1938-isf-formal-parent-products.t; t/1937-isf-formal-reservation-products.t; t/1936-isf-formal-source-context.t; t/1935-isf-local-declaration-admission.t; t/1933-isf-caller-formal-binding-scope.t; perl/FSM/Scheduler/ISF/FormalClauseResolver.pm; t/1928-isf-formal-clause-resolver.t; perl/FSM/Scheduler/ISF/FormalOperandResolver.pm; t/1927-isf-formal-operand-resolver.t; perl/FSM/Scheduler/ISF/FormalIdentityPlan.pm; t/1925-isf-formal-identity-plan.t; docs/audits/direct-formal-bit-width-scope-20260927.json; perl/FSM/Scheduler/ISF/LoweringIR.pm; perl/FSM/Scheduler/ISF/Emitter/FSM.pm; docs/tasks/SEMANTIC-INTROSPECTION-MCP-FRONTIER.md; t/1241-isf-transaction-port-bindings.t; t/1243-isf-port-binding-schedule-report.t
reverify: scripts/run_with_ram_guard.sh prove -Iperl t/1939-isf-formal-helper-identity.t t/1938-isf-formal-parent-products.t t/1937-isf-formal-reservation-products.t t/1936-isf-formal-source-context.t t/1935-isf-local-declaration-admission.t t/1933-isf-caller-formal-binding-scope.t t/1928-isf-formal-clause-resolver.t t/1927-isf-formal-operand-resolver.t t/1925-isf-formal-identity-plan.t t/1241-isf-transaction-port-bindings.t t/1243-isf-port-binding-schedule-report.t; rerun the tracked direct-formal-bit-width-scope parser sources before classifying the parser boundary.
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

prepare_formal_source retains detached transaction_products alongside source and
resolver contexts. Each transaction contains the actual states, counters, DTs,
local/spawn references, contracts, widths, roles, bank accesses, resets and
assertions returned by _build_transaction. FormalReservationInventory collects
conservative identifier tokens from keys and scalar values, including formatted
expressions; origins use escaped JSON pointers plus key/value position. It rejects
unsupported references and cycles, permits shared acyclic data and sorts hash
traversal. Extra tokens are reservations, not semantic operand classification.
T1937 proves the source-only candidate isf_port_main_payload collides with an
actual named-drive payload and that product reservations avoid exact/case-folded
collisions; rewritten carriers strict-replay. Counter/monitor/wait/sample/call
products, detached snapshots and malformed-input controls qualify this partial
boundary. Remaining module/child/domain producers and helper identity stability under
rewriting remain .3.2.2; transaction products are not a complete reservation set.

The .3.2.2.1 continuation retains parent_activation_products from the existing
generated-activation registration, rule and shared-drive producers. It supplies
their actual ports, counters, roles, DTs, bank accesses and registered instance
metadata without merging transaction width/role maps or finalizing an IR.
Registration receives cloned transaction activation records because it replaces
source bindings with handoff metadata. T1938 compares these products with actual
production parent declarations/assignments/instances and rule bank metadata.
It proves a local rule payload can collide with a planned formal even when the
transaction inventory has no such name; exact/case-folded and permutation
controls qualify the extended partial reservation set. Generated spawn, do and
parameterized trigger paths include real child shared-drive handoffs. Invalid
rule-bank source still fails in the canonical producer. Child storage/completion
connections, later module processing, library/ATL/domain closure and stable
source-derived helper names remain .3.2.2.2; completeness is gated by .3.2.2.3.

Rule payload helper identity is now retained under .3.2.2.2.1. Detached rewritten
formal declarations carry a private _isf_formal_identity record containing the
typed source actor/transaction/formal tuple and the physical declaration name.
_transaction_port_map checks its shape, source owner, physical-name agreement
and duplicate source identities. Rule payload producers and binding metadata use
the source name for helper generation; data destinations continue to use the
physical name. Existing source actors without a projection retain prior behavior.
Generated public formals keep their names, and the private record is absent from
the public schedule schema. The clause resolver refuses reprojecting a declaration
that already carries this record. It is internal provenance, not ISF syntax.
T1939 retains the pre-repair helper change from isf_port_main_payload to
isf_port_main_isf_port_main_payload_formal, absent from the original reservations.
It qualifies stable helper names under different physical allocations, generated
interfaces, malformed/stale records, duplicate identities, source isolation,
schedule provenance and strict carriers. Raw generated-child terminal static
waits exposed a separate empty-state carrier defect, repaired under .55; see
[terminal-state carriers](isf-empty-terminal-state-carriers.md). Pre-allocation helper collision admission is qualified by the linked contract
below. Actual local/external activation wiring is now retained under
.3.2.2.2.3.1; see [wiring products](isf-formal-wiring-products.md). Later
priority/resource, child ownership and library/ATL/domain composition remain
.3.2.2.2.3.2.2.2. Parent point/default products are separately retained by
.3.2.2.2.3.2.1; see [point products](isf-formal-point-products.md). Potential
resource pointer declarations now use the shared actual producer; see the
[resource product boundary](isf-formal-resource-products.md). Independently
built generated children now supply their actual module products; see
[child products](isf-formal-child-products.md) and [parent completion products](isf-formal-completion-products.md). Parent connection and final
composition remain separate. [Reusable child products](isf-formal-reusable-products.md)
now retain actual library/ATL modules and selected child-interface records; this
still does not close parent connections or outer domain composition.

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
requiring conflicting parent merges. Monitor collisions solely with raw direct
formals may now be retained as deferred physical obligations; the precise
[pre-allocation admission contract](isf-formal-preallocation-admission.md) keeps
executable validation strict. It derives explicit locals only, actor
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
