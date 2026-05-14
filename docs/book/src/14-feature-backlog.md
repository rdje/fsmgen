# Feature Backlog

This chapter is the canonical book-facing backlog for user-visible features
that are discussed elsewhere as future work, deferred, not fully shipped, or
not yet a fully frozen public contract.

When another chapter mentions a limitation of that kind, the item must also be
listed here. Local chapters may keep short contextual notes, but this chapter
is the consolidated review list.

## Language Ergonomics

### Inference-First Scalar Authoring

Status: partially shipped; broader resource kinds and arbiters remain backlog.

Goal: make scalar declarations optional across the whole language whenever a
safe type and width can be recovered from authored usage.

Current boundary: FSMGen already infers widths from explicit `+size`, scalar
type aliases, positive integer scalar symbols, slices, selectors, guards, and
other bounded evidence. It does not yet promise "never declare scalar types
unless you want to" across every source position.

### Dynamic Divisor Safety Proofs

Status: backlog.

Goal: reject or prove safe runtime division/modulo expressions whose divisors
could be zero.

Current boundary: constant-expression domains reject divide/modulo-by-zero
before HDL emission. Runtime RHS expressions with dynamic divisors are emitted
as expressions; FSMGen does not yet prove every dynamic divisor nonzero.

## Aggregate Types And Data

### Automatic Aggregate Growth From Usage

Status: backlog.

Goal: infer aggregate record/list shapes from member/index usage when no
explicit aggregate type anchor is present.

Current boundary: aggregate aliases, aggregate constants, declared aggregate
types, direct-root aggregate member/list expressions, and partial aggregate
LHS writes are supported on the current SystemVerilog path. Broad automatic
aggregate type growth from arbitrary usage is not fully shipped.

### Backend-Owned Struct/Record Default Lowering

Status: backlog.

Goal: make backend-owned structured `struct`/record emission the default
lowering where it is portable and synthesizable.

Current boundary: generated-module and composition-top packed typedef emission
exists for aggregate aliases on the current SystemVerilog path. Structured
record lowering is not the default for all aggregate data.

### Richer Aggregate Operators

Status: backlog.

Goal: widen aggregate operators beyond the shipped matching-shape leafwise
numeric and bitwise families.

Current boundary: matching list/record aggregate shapes support leafwise
`+`, `-`, `*`, `/`, `%`, `&`, `|`, `^` plus word aliases before HDL lowering.
Additional aggregate operators remain deferred until each operator has a
defined type/shape/result contract and validation path.

### VHDL Aggregate Lowering

Status: backlog, behind active VHDL backend work.

Goal: lower aggregate types and values into portable VHDL record/array forms
for the subset that can be validated as synthesizable.

Current boundary: VHDL is recognized as a target family, but the full backend
is not implemented. Aggregate lowering beyond scalar/width-safe surfaces is
therefore not shipped.

### Public Type And Export Surfaces

Status: backlog.

Goal: expose richer type/export information to embedders without leaking
unstable internal objects.

Current boundary: bounded semantic and manifest surfaces exist, but richer
public type/export APIs remain under the broader public embedding/API lane.

## Composition

### VHDL Generic-Map Lowering

Status: backlog, behind active VHDL backend work.

Goal: lower validated composition parameter/generic overrides into VHDL
generic maps.

Current boundary: the Verilog-family backend lowers validated parameters and
aggregate overrides to SystemVerilog `#(...)` instance parameters. VHDL
generic-map lowering is not shipped.

### Broader Generated-Child Top Instantiation

Status: partially shipped; generalized surfaces remain backlog.

Goal: instantiate generated child FSM/DT artifacts from higher-level ISF or
composition flows without manual wiring gaps.

Current boundary: generated-child parameterization exists for bounded
composition paths, and ISF spawned-child fixtures now emit a generated
`<actor>_top.fsm` that wires the scheduled parent, scheduled children,
start/done handoffs, named-drive handoffs, and per-instance spawn parameter
overrides through the existing composition pipeline. Broader generated-child
top surfaces beyond the covered ISF spawn pattern remain backlog.

### Spawn Parameter Binding

Status: partially shipped; broader parameter/value surfaces remain backlog.

Goal: bind parameters through spawned child instances in ISF-generated
multi-file scheduled designs.

Current boundary: spawn emits child files, a parent scheduled `.fsm`, and a
generated composition top for covered spawned-child fixtures. The ISF lowerer
now accepts one optional nested `(params (NAME value) ...)` block on
`(spawn child as instance ...)`, accepts spawned child transaction parameters
from a transaction-local `params` clause, emits child defaults as scheduled
child `+params`, validates duplicates/unknown overrides/value shapes, rejects
parameter declarations on non-spawned transactions, preserves per-instance
override lists in the parent lowerer IR, and applies those overrides through
the generated top. The first value domain is scalar/exact-width literals plus
compatible aggregate/list literals; symbolic constants wait for an explicit
ISF symbol surface.

### Spawn Inside Repeat Bodies

Status: backlog.

Goal: allow `(spawn child as name)` inside `(repeat count body...)` without
implying dynamic hardware creation.

Required contract: the lexical spawn name denotes one static child instance in
the generated top. The repeat loop may activate that instance multiple times,
but it must not elaborate one instance per iteration. The scheduler needs a
busy/re-entry rule before this can ship: either prove or insert sequencing so
each later iteration observes the child's fresh done pulse before starting it
again, or reject the loop with a targeted diagnostic.

Dynamic repeat counts are compatible with this model because `count` is a
runtime counter load value, not an elaboration count. They do make loop latency
data-dependent, and the repeat contract still needs an explicit zero-count
policy for the fully general case.

## Intent Scheduling Format

### IAL2 Protocol And Platform Intent Exploration

Status: backlog.

Goal: decide whether an intent layer above current ISF has enough independent
semantic value to exist.

Current boundary: FSMGen names `.fsm` as Intent Abstraction Layer 0 (`IAL0`)
and current `.isf` as Intent Abstraction Layer 1 (`IAL1`). A future `IAL2`
would need to justify itself with semantics above individual transactions, not
only syntax convenience. The first worthwhile areas to investigate are
reusable protocol-level intent objects, such as APB/AXI transaction templates,
and platform/resource mapping decisions that choose among legal ISF schedules
or resource allocations. Aliases, macros, wrappers, and sugar without a
distinct runtime model should stay inside IAL1 or remain out of the language.

### Enforced Resource Arbitration

Status: backlog.

Goal: lower `(resources ...)` metadata into scheduler-enforced mutual
exclusion and arbiter behavior.

Current boundary: resource metadata is structurally validated, including
supported arbiter names, resource kinds, duplicate resource rejection, and
resource-user validation for `rule_slot`. The scheduler now enforces the first
resource kind: `rule_slot`, a one-cycle mutual-exclusion slot where each bound
rule requests when its guard is true, the priority graph chooses a unique
active winner, and the generated grant gates the whole rule DT DTE without
adding a cycle.

Current resource kind catalog:

| Kind | Status | Meaning |
| --- | --- | --- |
| `rule_slot` | shipped for `priority` arbitration | One-cycle mutual exclusion for rule users under the `priority` arbiter. |
| `output_bundle` | backlog | One-cycle ownership of a group of actor outputs or LHS targets. |
| `interface_bundle` | backlog | Ownership of a protocol-facing interface or bus bundle. |
| `named_drive` | backlog | Ownership of a reusable actor `(drive ...)` body or drive-call path. |
| `transaction_start` | backlog | Arbitration for start/request fan-in into one transaction. |
| `child_instance` | backlog | Re-entry control for a spawned child instance. |
| `storage_port` | backlog | Arbitration for shared state, register, memory, or storage-port access. |

Remaining backlog: non-`rule_slot` resource kinds, `round_robin`, transaction
lifetime ownership, named-drive users, output-target users, multi-capacity
resources, and dynamic resource names remain backlog until their reset,
hold/release, fairness, and diagnostic contracts are explicit.

### Priority Resolution

Status: partially shipped; broader cases remain backlog.

Goal: enforce actor-level and rule-local priorities when multiple rules or
transactions conflict.

Current boundary: priority declarations are structurally validated and targets
must resolve to declared rules or transactions. Same-target rule/rule data
conflicts can now be resolved by rule-local or actor-level rule priority, with
the lower-priority assignment guarded off by the higher-priority rule
condition. Actor-level rule-over-transaction priority can now resolve the
covered same-target data case by guarding the transaction-state assignment
with the inverse active rule condition. Priority cycles, incomparable rule
conflicts, unordered rule/transaction conflicts, and mixed timing conflicts
fail closed.
Rule/drive overlap is still tracked because compile-time proof is not doable.
Generated SystemVerilog now includes verification-only selector assertions
derived from backend assignment analysis: same-value source selectors and
whole-mux value selectors are checked with `$onehot0` under
`` `ifndef SYNTHESIS``. Transaction-over-rule priority, drive/rule arbitration
policy, and broader resource arbitration remain backlog items.

### Expression-Valued Rule Assignments

Status: backlog.

Goal: allow rule actions to assign expression values, not only scalar
`(port value)` pairs.

Current boundary: rule actions accept `(port value)`, `(trigger transaction)`,
and `(priority over other_rule)`. Expression-valued rule assignments are
deferred.

### Transaction Stage Lowering

Status: backlog.

Goal: lower transaction `(stage ...)` clauses into valid/ready pipeline-stage
logic.

Current boundary: transaction stage clauses are parsed and fail closed during
lowering with a targeted diagnostic.

### Temporal Contract Lowering

Status: backlog.

Goal: lower transaction `(contract ...)` temporal assertions into generated
checks or equivalent scheduled artifacts.

Current boundary: authored transaction contract clauses fail closed during
lowering instead of being silently dropped.

### Legacy Handshake Semantics

Status: backlog or removal candidate.

Goal: decide whether old `(handshake ...)` metadata should gain real lowering
semantics or remain validated ignored compatibility input only.

Current boundary: deprecated handshake metadata is structurally validated and
ignored. Direct `(on port ...)` activation plus generated `can_accept` is the
current model.

### Removed Assign Keyword

Status: removal/deferred compatibility item.

Goal: decide whether the removed `(assign ...)` transaction keyword should
stay unsupported or be replaced by a different explicit construct.

Current boundary: authored uses fail closed as unsupported transaction clauses.

### Full Width Inference For Data Operations

Status: backlog.

Goal: infer widths for `extract` and `shift_right` in more cases without
requiring explicit width options.

Current boundary: `shift_right` accepts `(width N)` and `extract` accepts
`(widths N...)` as explicit anchors. Unknown-width cases still use placeholder
width/slice expressions.

### Richer Schedule-Report Storage Classes

Status: backlog.

Goal: classify inferred storage more precisely in schedule reports.

Current boundary: schedule reports expose bounded storage metadata, but rich
storage-class optimization is not shipped.

### Fully Frozen Schedule JSON Schema

Status: backlog.

Goal: freeze the whole schedule JSON schema as a public contract.

Current boundary: schedule JSON is public only through bounded key families
advertised by `embedding.isf_public_interface`. The whole JSON tree is not yet
promised as permanently frozen. The conflict/fan-in projection boundary is now
defined. Nonfatal conflict issues project into `compile_issues`, and accepted
fan-in groups project into `compatible_fanin_groups`, both with bounded
summary shapes. Successful priority/resource decisions project into
`priority_resolutions` and `resource_arbitration` as bounded static lowering
summaries.

## Backends And Validation

### Full VHDL Backend

Status: backlog.

Goal: implement VHDL as a full HDL backend.

Current boundary: the CLI recognizes VHDL target spelling, but explicit VHDL
generation is not implemented.

### GHDL Validation

Status: backlog, behind active VHDL backend work.

Goal: add GHDL validation once there is an active VHDL backend.

Current boundary: validation focuses on SystemVerilog using Verilator and
Yosys.

### Warning-Clean External Validation For Every Historical Sample

Status: backlog.

Goal: make every intended sample under `fsm/` externally warning-clean under
the supported Verilog-family validation tools.

Current boundary: the regression gate uses a focused SystemVerilog smoke set.
It does not claim every historical sample in `fsm/` is externally
warning-clean.

### ABC Mapping Hardening

Status: backlog.

Goal: decide whether and how to add ABC-backed Yosys optimization/mapping
validation without timeout-sensitive noise.

Current boundary: the Yosys lane intentionally uses `synth -noabc`.

### Structured Non-Flattened Generation

Status: backlog.

Goal: support a structured/non-flattened generation path where useful without
weakening the debug-first flattened contract.

Current boundary: flattened decision-tree generation is the shipped default
path.

## Embedding And Public APIs

### Fully Frozen Programmatic Embedding API

Status: backlog under `R13`.

Goal: graduate useful in-process seams into a fully frozen public embedding
API.

Current boundary: programmatic embedding exists and many bounded contracts are
advertised, but the whole API is not promised as permanently stable.

### Full Normalized Semantic Export

Status: backlog under `R13`.

Goal: provide a full normalized semantic export format for downstream tools.

Current boundary: the capability manifest and normalized semantic JSON expose
bounded, audited public surfaces. The manifest is not yet a full normalized
semantic export.
